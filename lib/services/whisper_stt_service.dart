import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../models/stt_recognition_result.dart';
import '../utils/whisper_transcript_stabilizer.dart';
import 'macos_media_permissions.dart';
import 'whisper_model_manager.dart';

/// On-device speech-to-text using sherpa-onnx Whisper, driven by a Silero
/// Voice Activity Detector (VAD).
///
/// ChatGPT-style capture: the microphone streams continuously into the VAD,
/// which hands back ONE complete speech segment per utterance (endpointed by
/// trailing silence). Each segment is decoded by Whisper exactly once. This
/// removes the old "re-decode a growing buffer every 1.5 s" design that caused
/// duplicated/fragmented sends ("hello hello hello …") and mid-sentence stops.
///
///  mic → VAD.acceptWaveform → VAD segment (utterance) → Whisper decode → final
class WhisperSttService {
  WhisperSttService._();
  static final WhisperSttService instance = WhisperSttService._();

  final AudioRecorder _recorder = AudioRecorder();

  // Whisper decode runs in a background isolate (synchronous FFI).
  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  String? _workerModelId;

  // Silero VAD runs on the main isolate (cheap) and does endpointing.
  sherpa.VoiceActivityDetector? _vad;

  /// sherpa-onnx FFI bindings only need initializing once per isolate.
  static bool _bindingsReady = false;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  /// True once the recorder has delivered its first audio buffer for the
  /// current session — i.e. the mic is genuinely capturing.
  bool _micHot = false;
  String _language = 'en';
  double _soundLevel = 0;

  StreamSubscription<List<int>>? _audioSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _interimTimer;
  Timer? _captureRotateTimer;

  void Function(SttRecognitionResult result)? _onResult;

  static const int _sampleRate = 16000;
  static const int _vadWindow = 512; // Silero window size at 16 kHz

  /// Samples pending until we have a full VAD window.
  final List<double> _vadFeed = [];

  /// Rolling audio of the current utterance, used only for interim display
  /// decodes. Authoritative text always comes from the VAD segment.
  final List<double> _liveBuffer = [];
  static const int _liveBufferCap = 30 * _sampleRate; // 30 s safety cap

  String _lastInterimText = '';
  bool _speechActive = false;
  bool _draining = false;
  bool _interimInFlight = false;
  bool _finalizeInFlight = false;
  bool _captureRotateInFlight = false;

  /// Incremented whenever we reset/stop so stale async decodes are dropped.
  int _epoch = 0;

  /// iOS can stall long-lived record streams; rotate capture periodically
  /// while keeping the VAD state so endpointing stays continuous.
  static const Duration _captureRotateInterval = Duration(seconds: 15);

  final _resultController =
      StreamController<SttRecognitionResult>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _soundLevelController = StreamController<double>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  double get soundLevel => _soundLevel;

  Stream<SttRecognitionResult> get resultStream => _resultController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Future<bool> initialize({String language = 'en'}) async {
    final normalized = _normalizeLanguage(language);
    final modelId = WhisperModelManager.instance.selectedModelId;
    if (_isInitialized &&
        _isAvailable &&
        _vad != null &&
        _workerModelId == modelId) {
      if (normalized != _language) {
        // Language changed — rebuild the ASR worker for the new language.
        _language = normalized;
        await _shutdownWorker();
        return _spawnWorker();
      }
      return true;
    }
    if (_isInitialized && _workerModelId != modelId) {
      await resetEngine();
    }
    _language = normalized;

    final ready = await WhisperModelManager.instance.isModelReady();
    if (!ready) {
      _isInitialized = true;
      _isAvailable = false;
      return false;
    }

    try {
      // FFI bindings must be initialized on the main isolate to use VAD here.
      if (!_bindingsReady) {
        sherpa.initBindings();
        _bindingsReady = true;
      }

      final vadReady = await _ensureVad();
      if (!vadReady) {
        _isInitialized = true;
        _isAvailable = false;
        _errorController.add('Voice detector model unavailable');
        return false;
      }

      final ok = await _spawnWorker();
      _isInitialized = true;
      _isAvailable = ok;
      if (ok) {
        debugPrint('🎙️ Whisper STT initialized with VAD (language=$_language)');
      }
      return ok;
    } catch (e, st) {
      debugPrint('🎙️ Whisper STT init failed: $e\n$st');
      _isInitialized = true;
      _isAvailable = false;
      return false;
    }
  }

  Future<bool> _ensureVad() async {
    if (_vad != null) return true;
    final ok = await WhisperModelManager.instance.ensureVadModel();
    if (!ok) return false;
    final vadPath = await WhisperModelManager.instance.resolveVadModelPath();
    if (vadPath == null) return false;

    _vad = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: vadPath,
          threshold: 0.5,
          // End-of-turn: how long of a pause ends the utterance. Kept short
          // and natural (ChatGPT-like) instead of the old 3 s blind timer.
          minSilenceDuration: 0.8,
          minSpeechDuration: 0.25,
          windowSize: _vadWindow,
          // Allow long sentences before force-cutting a segment.
          maxSpeechDuration: 20.0,
        ),
        sampleRate: _sampleRate,
        numThreads: 1,
        provider: 'cpu',
        debug: false,
      ),
      bufferSizeInSeconds: 30,
    );
    return true;
  }

  Future<bool> _spawnWorker() async {
    final paths = await WhisperModelManager.instance.resolveModelPaths();
    if (paths == null) return false;

    if (_workerIsolate != null) {
      await _shutdownWorker();
    }

    final initPort = ReceivePort();
    final numThreads = Platform.numberOfProcessors > 4 ? 4 : 2;
    _workerIsolate = await Isolate.spawn(
      _workerEntryPoint,
      [
        initPort.sendPort,
        paths.encoder,
        paths.decoder,
        paths.tokens,
        numThreads,
        _language,
      ],
    );

    final initResult = await initPort.first as List<dynamic>;
    initPort.close();
    _workerSendPort = initResult[0] as SendPort;
    _workerModelId = WhisperModelManager.instance.selectedModelId;
    return true;
  }

  Future<bool> startListening({
    required void Function(SttRecognitionResult result) onResult,
    Duration listenFor = const Duration(seconds: 60),
    int pauseForSeconds = 3,
    String? localeId,
  }) async {
    if (!_isInitialized || !_isAvailable || _vad == null) {
      final ok = await initialize(language: localeId ?? _language);
      if (!ok) return false;
    }

    final language = _normalizeLanguage(localeId ?? _language);
    if (language != _language) {
      final ok = await initialize(language: language);
      if (!ok) return false;
    }

    if (_isListening) {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!await _ensureMicPermission()) return false;

    try {
      _onResult = onResult;
      _resetBuffers();
      _epoch++;
      _isListening = true;
      // Do NOT announce 'listening' yet — the AVAudioEngine/mic takes a moment
      // to actually start delivering audio. Telling the UI "I'm listening"
      // before capture is hot makes users speak into a dead mic and lose their
      // first words. We flip to 'listening' from _startCaptureStream once the
      // first audio buffer arrives (mic genuinely hot).
      _micHot = false;
      _statusController.add('starting');

      await _startCaptureStream();

      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amp) {
        final level = max(0.0, min(1.0, (amp.current + 45) / 45.0));
        _soundLevel = level;
        _soundLevelController.add(level);
      });

      _interimTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        unawaited(_emitInterim());
      });

      _captureRotateTimer = Timer.periodic(_captureRotateInterval, (_) {
        unawaited(_rotateCaptureSession());
      });

      return true;
    } catch (e, st) {
      debugPrint('🎙️ Whisper startListening failed: $e\n$st');
      _errorController.add(e.toString());
      _isListening = false;
      return false;
    }
  }

  Future<void> releaseCapture() async {
    _onResult = null;
    await _stopCapture();
    _isListening = false;
    _soundLevel = 0;
  }

  /// Stop listening. Flushes any in-progress speech through the VAD so a
  /// manual stop still finalizes the current utterance.
  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    _interimTimer?.cancel();
    _interimTimer = null;

    final callback = _onResult;
    try {
      _vad?.flush();
      if (callback != null) {
        await _drainSegments(callback, force: true);
      }
    } catch (e) {
      debugPrint('🎙️ Whisper flush on stop failed: $e');
    }

    _epoch++;
    _onResult = null;
    await _stopCapture();
    _soundLevel = 0;
    _statusController.add('notListening');
  }

  /// Stop listening WITHOUT decoding/emitting the in-progress utterance.
  /// Used when the caller already has the text (e.g. moving to a review step)
  /// or wants to discard the current turn.
  Future<void> cancelListening() async {
    if (!_isListening) {
      await _stopCapture();
      return;
    }
    _isListening = false;
    _epoch++;
    _onResult = null;
    _resetBuffers();
    _vad?.clear();
    await _stopCapture();
    _soundLevel = 0;
    _statusController.add('notListening');
  }

  Future<void> resetEngine() async {
    await stopListening();
    await _shutdownWorker();
    _vad?.free();
    _vad = null;
    _isInitialized = false;
    _isAvailable = false;
  }

  Future<void> dispose() async {
    await resetEngine();
    await _recorder.dispose();
  }

  // ── Capture & VAD pipeline ─────────────────────────────────────────────

  Future<void> _startCaptureStream() async {
    // On macOS, echoCancel/autoGain (Voice Processing) often yields silent
    // PCM buffers even when Mic permission is granted — UI "listens" with
    // zero levels and VAD never fires. Keep capture plain on desktop.
    final useVoiceProcessing = !Platform.isMacOS && !Platform.isLinux;
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        autoGain: useVoiceProcessing,
        echoCancel: useVoiceProcessing,
        noiseSuppress: useVoiceProcessing,
      ),
    );
    var chunks = 0;
    var nonSilent = 0;
    var windowPeak = 0; // max |int16| across the first ~1 s
    _audioSub = stream.listen((bytes) {
      chunks++;
      if (!_micHot && _isListening) {
        // First real audio buffer — the mic is now hot. Announce 'listening'
        // here (not at startListening) so the UI only invites the user to
        // speak once capture is genuinely flowing.
        _micHot = true;
        _statusController.add('listening');
      }
      if (bytes.any((b) => b != 0)) nonSilent++;
      final peak = _peakAbsInt16(bytes);
      if (peak > windowPeak) windowPeak = peak;
      if (chunks == 40) {
        // ~ after first second of audio callbacks
        final peakDb = windowPeak <= 0
            ? -160.0
            : 20 * (log(windowPeak / 32767.0) / ln10);
        debugPrint(
          '🎙️ Whisper capture: chunks=$chunks nonSilent=$nonSilent '
          'peak=$windowPeak (${peakDb.toStringAsFixed(1)} dBFS) '
          'sampleRate=$_sampleRate',
        );
        if (nonSilent == 0) {
          debugPrint(
            '🎙️ Whisper capture is silent — check Mic permission for LM Mini '
            'and that no other app holds the mic exclusively',
          );
          _errorController.add(
            'Microphone is open but no audio is arriving. '
            'Quit other apps using the mic, confirm LM Mini is allowed in '
            'System Settings → Privacy & Security → Microphone, then try again.',
          );
        } else if (peakDb < -55) {
          // Audio bytes arrive but at near-inaudible levels — VAD will never
          // endpoint. Usually the wrong input device or a muted/low input gain.
          debugPrint(
            '🎙️ Whisper capture level very low (${peakDb.toStringAsFixed(1)} '
            'dBFS) — VAD may never trigger. Check the selected microphone and '
            'input volume in System Settings → Sound → Input.',
          );
        }
      }
      _onAudioChunk(bytes);
    });
  }

  /// Peak absolute 16-bit sample magnitude in a little-endian PCM byte chunk.
  static int _peakAbsInt16(List<int> bytes) {
    if (bytes.length < 2) return 0;
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    var peak = 0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little).abs();
      if (sample > peak) peak = sample;
    }
    return peak;
  }

  void _onAudioChunk(List<int> bytes) {
    if (!_isListening || _vad == null) return;
    if (bytes.length < 2) return;

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little) / 32768.0;
      _vadFeed.add(sample);
      _liveBuffer.add(sample);
    }
    if (_liveBuffer.length > _liveBufferCap) {
      _liveBuffer.removeRange(0, _liveBuffer.length - _liveBufferCap);
    }

    // Feed the VAD in fixed windows.
    while (_vadFeed.length >= _vadWindow) {
      final window = Float32List.fromList(_vadFeed.sublist(0, _vadWindow));
      _vadFeed.removeRange(0, _vadWindow);
      try {
        _vad!.acceptWaveform(window);
      } catch (e) {
        debugPrint('🎙️ VAD acceptWaveform error: $e');
      }
    }

    final nowActive = _vad!.isDetected();
    if (nowActive != _speechActive) {
      debugPrint(nowActive
          ? '🎙️ VAD: speech detected'
          : '🎙️ VAD: speech ended (segment pending)');
    }
    _speechActive = nowActive;

    final callback = _onResult;
    if (callback != null) {
      unawaited(_drainSegments(callback));
    }
  }

  /// Decode every complete VAD segment once and emit it as a final result.
  Future<void> _drainSegments(
    void Function(SttRecognitionResult result) onResult, {
    bool force = false,
  }) async {
    if (_draining || _vad == null) return;
    if (!_isListening && !force) return;
    _draining = true;
    final epoch = _epoch;
    try {
      while (!_vad!.isEmpty()) {
        final segment = _vad!.front();
        _vad!.pop();
        final samples = segment.samples;
        if (samples.isEmpty) continue;

        _finalizeInFlight = true;
        String text;
        try {
          text = WhisperTranscriptStabilizer.collapseRepeats(
            await _decodeInWorker(samples),
          );
        } finally {
          _finalizeInFlight = false;
        }
        debugPrint(
          '🎙️ Whisper segment decoded: ${samples.length} samples '
          '(${(samples.length / _sampleRate).toStringAsFixed(1)}s) → '
          '"${text.length > 60 ? '${text.substring(0, 60)}…' : text}"',
        );
        if (epoch != _epoch && !force) return;
        if (text.isEmpty) continue;

        // A finalized utterance resets the interim/live state.
        _liveBuffer.clear();
        _lastInterimText = '';

        final result = SttRecognitionResult(
          recognizedWords: text,
          finalResult: true,
        );
        _resultController.add(result);
        onResult(result);
      }
    } finally {
      _draining = false;
    }
  }

  /// Decode the in-progress utterance for live display only. Never sends —
  /// only VAD segments (finalResult:true) drive sending, so no duplication.
  Future<void> _emitInterim() async {
    if (!_isListening || !_speechActive) return;
    if (_interimInFlight || _finalizeInFlight) return;
    if (_liveBuffer.length < _sampleRate ~/ 2) return; // need ≥0.5 s
    final callback = _onResult;
    if (callback == null) return;

    _interimInFlight = true;
    final epoch = _epoch;
    try {
      final samples = _copyLiveTail();
      final text =
          WhisperTranscriptStabilizer.collapseRepeats(await _decodeInWorker(samples));
      if (epoch != _epoch || !_isListening) return;
      if (text.isEmpty) return;
      if (!WhisperTranscriptStabilizer.shouldAcceptInterimUpdate(
        _lastInterimText,
        text,
      )) {
        return;
      }
      _lastInterimText = text;
      final result = SttRecognitionResult(
        recognizedWords: text,
        finalResult: false,
      );
      _resultController.add(result);
      callback(result);
    } finally {
      _interimInFlight = false;
    }
  }

  /// Max samples to decode for an interim pass (~20 s tail).
  static const int _maxInterimSamples = 20 * _sampleRate;

  Float32List _copyLiveTail() {
    if (_liveBuffer.length <= _maxInterimSamples) {
      return Float32List.fromList(_liveBuffer);
    }
    return Float32List.fromList(
      _liveBuffer.sublist(_liveBuffer.length - _maxInterimSamples),
    );
  }

  Future<String> _decodeInWorker(Float32List samples) async {
    if (_workerSendPort == null || samples.isEmpty) return '';
    final replyPort = ReceivePort();
    _workerSendPort!.send([replyPort.sendPort, 'decode', samples]);
    final response = await replyPort.first as List<dynamic>;
    replyPort.close();
    if (response.first == 'ok') {
      return (response[1] as String).trim();
    }
    debugPrint('🎙️ Whisper decode error: ${response[1]}');
    return '';
  }

  Future<void> _rotateCaptureSession() async {
    if (!_isListening || _captureRotateInFlight) return;
    _captureRotateInFlight = true;
    try {
      await _audioSub?.cancel();
      _audioSub = null;
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      await Future.delayed(const Duration(milliseconds: 80));
      if (!_isListening) return;
      await _startCaptureStream();
    } catch (e, st) {
      debugPrint('🎙️ Whisper capture rotate failed: $e\n$st');
    } finally {
      _captureRotateInFlight = false;
    }
  }

  void _resetBuffers() {
    _vadFeed.clear();
    _liveBuffer.clear();
    _lastInterimText = '';
    _speechActive = false;
    _vad?.reset();
  }

  Future<bool> _ensureMicPermission() async {
    // Prefer native TCC prompts on macOS (purpose strings for App Review).
    return VoiceCapturePermissions.ensureForVoiceInput();
  }

  Future<void> _stopCapture() async {
    _micHot = false;
    _interimTimer?.cancel();
    _interimTimer = null;
    _captureRotateTimer?.cancel();
    _captureRotateTimer = null;
    await _audioSub?.cancel();
    _audioSub = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> _shutdownWorker() async {
    if (_workerSendPort != null) {
      _workerSendPort!.send([null, 'dispose']);
    }
    _workerIsolate?.kill(priority: Isolate.immediate);
    _workerIsolate = null;
    _workerSendPort = null;
    _workerModelId = null;
  }

  static String _normalizeLanguage(String? localeId) {
    if (localeId == null || localeId.trim().isEmpty) return 'en';
    return localeId.split(RegExp('[-_]')).first.toLowerCase();
  }

  static void _workerEntryPoint(List<dynamic> initArgs) {
    final initPort = initArgs[0] as SendPort;
    final encoderPath = initArgs[1] as String;
    final decoderPath = initArgs[2] as String;
    final tokensPath = initArgs[3] as String;
    final numThreads = initArgs[4] as int;
    final language = initArgs[5] as String;

    sherpa.initBindings();

    final recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: encoderPath,
            decoder: decoderPath,
            language: language,
            task: 'transcribe',
          ),
          tokens: tokensPath,
          numThreads: numThreads,
          debug: false,
        ),
      ),
    );

    final workerPort = ReceivePort();
    initPort.send([workerPort.sendPort]);

    workerPort.listen((message) async {
      if (message is! List) return;
      final replyPort = message[0] as SendPort?;
      final command = message[1] as String;

      if (command == 'dispose') {
        recognizer.free();
        workerPort.close();
        return;
      }

      if (command == 'decode' && replyPort != null) {
        final samples = message[2] as Float32List;
        sherpa.OfflineStream? stream;
        try {
          stream = recognizer.createStream();
          stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
          recognizer.decode(stream);
          final result = recognizer.getResult(stream);
          replyPort.send(['ok', result.text.trim()]);
        } catch (e) {
          replyPort.send(['err', e.toString()]);
        } finally {
          stream?.free();
        }
      }
    });
  }
}
