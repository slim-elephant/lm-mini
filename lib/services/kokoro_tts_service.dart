import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/just_audio_play.dart';
import '../utils/tts_language_catalog.dart';
import 'kokoro_model_manager.dart';

/// On-device TTS using Kokoro (en/es/fr/zh) and Piper (de/ru) via sherpa-onnx.
class KokoroTtsService {
  static final KokoroTtsService _instance = KokoroTtsService._internal();
  factory KokoroTtsService() => _instance;
  KokoroTtsService._internal();

  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  final AudioPlayer _player = AudioPlayer();
  bool _playerBusy = false; // guard against re-entrant play calls
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _tempDir;

  // Callbacks — matching TtsService interface
  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onError;
  VoidCallback? onPlaybackStart; // Called when first audio chunk starts playing

  // Settings
  int _speakerId = 0;
  double _speed = 1.0; // 0.5 - 2.0
  String? _preferredLanguage;
  String? _workerEngineGroup;
  bool _playerListenerReady = false;
  String? lastError;

  // Streaming TTS state
  bool _isStreaming = false;
  bool _streamingFinished = false;
  String _sentenceBuffer = '';
  final List<String> _pendingSentences = [];
  final List<String> _audioQueue = []; // WAV paths to play
  final List<String> _streamWavFiles = []; // all WAV paths for cleanup
  bool _isGeneratingChunk = false;
  bool _isPlayingFromQueue = false;
  int _streamChunkIndex = 0;
  int _chunksGenerated = 0; // Track how many chunks generated for batching
  StreamSubscription? _playerCompleteSub;
  Timer? _playbackSafetyTimer; // Watchdog in case onPlayerComplete doesn't fire

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isStreaming => _isStreaming;
  int get speakerId => _speakerId;
  double get speed => _speed;

  /// Available Kokoro speakers (English UI ids 0–10; mapped per language pack).
  static const List<Map<String, dynamic>> speakers =
      TtsLanguageCatalog.englishSpeakers;

  void setPreferredLanguage(String? language) {
    _preferredLanguage = language;
  }

  /// Initialize on-device TTS. Returns false if no language pack is downloaded.
  ///
  /// Does **not** load sherpa-onnx. Native `OfflineTts` init can SIGABRT the
  /// whole Flutter process (especially the iOS Simulator), which shows up as
  /// "Lost connection to device" with no Dart stack. The worker starts on the
  /// first [speak] / [synthesizeWav] call.
  Future<bool> initialize({String? language}) async {
    if (language != null) _preferredLanguage = language;

    final manager = KokoroModelManager();
    final readyMap = await manager.languageReadyMap();
    final readyIds = {
      for (final e in readyMap.entries)
        if (e.value) e.key,
    };
    if (readyIds.isEmpty) {
      debugPrint('KokoroTtsService: No TTS language pack downloaded yet');
      return false;
    }

    final pref = TtsLanguageCatalog.pickReadyLanguage(
      preferred: _preferredLanguage,
      readyIds: readyIds,
    )!;
    _preferredLanguage = pref;

    try {
      if (!_isInitialized) {
        _tempDir = (await getTemporaryDirectory()).path;
        _ensurePlayerListener();
      }
      _isInitialized = true;
      debugPrint(
          'KokoroTtsService: Ready (preferred=$pref, worker deferred until speak)');
      return true;
    } catch (e) {
      debugPrint('KokoroTtsService: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  void _ensurePlayerListener() {
    if (_playerListenerReady) return;
    _playerListenerReady = true;
    _playerCompleteSub?.cancel();
    _playerCompleteSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playbackSafetyTimer?.cancel();
        _playbackSafetyTimer = null;
        _playerBusy = false;
        if (_isStreaming || _audioQueue.isNotEmpty || _streamingFinished) {
          _isPlayingFromQueue = false;
          _playNextFromQueue();
        } else if (_isSpeaking) {
          _isSpeaking = false;
          _disableWakeLock();
          onComplete?.call();
        }
      }
    });
  }

  Future<void> _killWorker() async {
    try {
      _workerSendPort?.send('dispose');
    } catch (_) {}
    _workerIsolate?.kill(priority: Isolate.immediate);
    _workerIsolate = null;
    _workerSendPort = null;
    _workerEngineGroup = null;
  }

  Future<Map<String, String>?> _workerConfigFor(String langId) async {
    final manager = KokoroModelManager();
    final resolved = await manager.resolveAssetId(langId);
    if (resolved == null) return null;
    final spec = TtsLanguageCatalog.assetById(resolved);
    if (spec == null) return null;
    final modelPath = await manager.getAssetPath(resolved);
    final usingLegacy = resolved == TtsLanguageCatalog.englishId;
    final group = TtsLanguageCatalog.engineGroup(
      langId,
      usingLegacyEnglish: usingLegacy,
    );

    if (spec.engine == TtsEngineKind.vits) {
      final onnx = TtsLanguageCatalog.findOnnxFile(modelPath);
      if (onnx == null) return null;
      return {
        'engine': 'vits',
        'model': onnx,
        'voices': '',
        'tokens': p.join(modelPath, 'tokens.txt'),
        'dataDir': p.join(modelPath, 'espeak-ng-data'),
        'lexicon': '',
        'lang': '',
        'ruleFsts': '',
        'group': group,
      };
    }

    var lexicon = '';
    var lang = '';
    var ruleFsts = '';
    if (!usingLegacy) {
      lang = TtsLanguageCatalog.kokoroEspeakVoice(langId);
      if (TtsLanguageCatalog.kokoroUsesEmptyLexicon(langId)) {
        lexicon = await manager.emptyLexiconPath();
      } else {
        lexicon = TtsLanguageCatalog.joinExisting(
          modelPath,
          spec.lexiconFiles,
        );
        if (TtsLanguageCatalog.kokoroUsesChineseRuleFsts(langId)) {
          ruleFsts = TtsLanguageCatalog.joinExisting(
            modelPath,
            spec.ruleFstFiles,
          );
        }
      }
    }

    return {
      'engine': 'kokoro',
      'model': p.join(modelPath, 'model.onnx'),
      'voices': p.join(modelPath, 'voices.bin'),
      'tokens': p.join(modelPath, 'tokens.txt'),
      'dataDir': p.join(modelPath, 'espeak-ng-data'),
      'lexicon': lexicon,
      'lang': lang,
      'ruleFsts': ruleFsts,
      'group': group,
    };
  }

  /// sherpa-onnx FFI on the iOS Simulator kills the process during model
  /// load — same class of crash as MLX. Fail in Dart instead.
  static Future<bool> _iosSimulatorBlocksSherpa() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      return !info.isPhysicalDevice;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _ensureWorkerForLanguage(String langId) async {
    if (await _iosSimulatorBlocksSherpa()) {
      const msg = 'On-device voice is not available in the iOS Simulator. '
          'Test on a real iPhone, or switch Speaking voice to Built-in.';
      debugPrint('KokoroTtsService: $msg');
      throw StateError(msg);
    }

    final config = await _workerConfigFor(langId);
    if (config == null) {
      debugPrint('KokoroTtsService: Language pack not ready: $langId');
      return false;
    }
    final group = config['group']!;
    if (_workerEngineGroup == group && _workerSendPort != null) {
      return true;
    }

    await _killWorker();
    final numThreads = Platform.numberOfProcessors > 4 ? 4 : 2;
    final initPort = ReceivePort();
    debugPrint(
        'KokoroTtsService: Spawning sherpa worker lang=$langId group=$group '
        'espeak=${config['lang']} fsts=${(config['ruleFsts'] ?? '').isEmpty ? 'none' : 'zh'}');
    try {
      _workerIsolate = await Isolate.spawn(
        _ttsWorkerEntryPoint,
        [initPort.sendPort, config, numThreads],
      );
    } catch (e) {
      initPort.close();
      await _killWorker();
      final msg = 'KokoroTtsService: Isolate.spawn failed: $e';
      debugPrint(msg);
      throw Exception(msg);
    }

    // Give the worker up to 30 s to report ready; native sherpa-onnx model
    // loading can take a while on lower-end devices, but a hang is worse.
    List<dynamic> initResult;
    try {
      initResult =
          await initPort.first.timeout(const Duration(seconds: 30)) as List;
    } on TimeoutException {
      initPort.close();
      await _killWorker();
      const msg = 'KokoroTtsService: Worker timed out during initialisation';
      debugPrint(msg);
      throw Exception(msg);
    } catch (e) {
      initPort.close();
      await _killWorker();
      final msg = 'KokoroTtsService: Worker init receive error: $e';
      debugPrint(msg);
      throw Exception(msg);
    }
    initPort.close();

    if (initResult[0] != 'ready') {
      final reason = initResult.length > 1 ? initResult[1] : 'unknown';
      await _killWorker();
      final msg = 'KokoroTtsService: Worker init failed: $reason';
      debugPrint(msg);
      throw Exception(msg);
    }
    _workerSendPort = initResult[1] as SendPort;
    _workerEngineGroup = group;
    debugPrint('KokoroTtsService: Worker ready group=$group lang=$langId');
    return true;
  }

  Future<String?> _prepareLanguage(String text) async {
    final manager = KokoroModelManager();
    final readyMap = await manager.languageReadyMap();
    final readyIds = {
      for (final e in readyMap.entries)
        if (e.value) e.key,
    };
    final lang = TtsLanguageCatalog.pickReadyLanguage(
      preferred: _preferredLanguage,
      detected: TtsLanguageCatalog.detect(text),
      readyIds: readyIds,
    );
    if (lang == null) {
      debugPrint('KokoroTtsService: No language pack ready');
      return null;
    }
    final ok = await _ensureWorkerForLanguage(lang);
    if (!ok) return null;
    return lang;
  }

  /// Generate WAV bytes without playing (used by the Mac QR TTS server).
  Future<Uint8List?> synthesizeWav({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
    String? language,
  }) async {
    if (language != null) _preferredLanguage = language;
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return null;
    }
    final cleaned = _cleanForTts(text);
    if (cleaned.isEmpty) return null;
    final lang = await _prepareLanguage(cleaned);
    if (lang == null) return null;
    final sid = TtsLanguageCatalog.mapSpeakerId(lang, speakerId);
    final dir = _tempDir ?? (await getTemporaryDirectory()).path;
    final wavPath = p.join(
      dir,
      'kokoro_http_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    final result = await _generateInWorker(
      cleaned,
      sid,
      speed.clamp(0.5, 2.0),
      wavPath,
    );
    if (result == null) return null;
    try {
      final bytes = await File(wavPath).readAsBytes();
      try {
        await File(wavPath).delete();
      } catch (_) {}
      return bytes;
    } catch (e) {
      debugPrint('KokoroTtsService: synthesizeWav read failed: $e');
      return null;
    }
  }

  /// Generate speech and play it.
  /// Returns true if playback started successfully.
  ///
  /// [onProgress] reports phase updates. [progress] is 0–1 when known, or null
  /// for indeterminate steps (engine init / neural generation).
  /// Set [awaitCompletion] to block until playback finishes (used by test UI).
  Future<bool> speak(
    String text, {
    void Function(String phase, double? progress)? onProgress,
    bool awaitCompletion = false,
    String? language,
  }) async {
    if (language != null) _preferredLanguage = language;
    if (!_isInitialized) {
      onProgress?.call('initializing', null);
      final ok = await initialize();
      if (!ok) {
        onError?.call();
        onProgress?.call('error', null);
        return false;
      }
      onProgress?.call('initializing', 1.0);
    }

    final cleaned = _cleanForTts(text);
    if (cleaned.isEmpty) return false;
    late final String lang;
    try {
      final prepared = await _prepareLanguage(cleaned);
      if (prepared == null) {
        onError?.call();
        onProgress?.call('error', null);
        return false;
      }
      lang = prepared;
    } catch (e) {
      lastError = e is StateError ? e.message : e.toString();
      debugPrint('KokoroTtsService: Speak prepare failed: $e');
      onError?.call();
      onProgress?.call('error', null);
      return false;
    }
    final sid = TtsLanguageCatalog.mapSpeakerId(lang, _speakerId);

    // Stop any current playback
    await stop();

    StreamSubscription<Duration>? playbackProgressSub;
    try {
      _isSpeaking = true;
      _enableWakeLock();
      onStart?.call();

      onProgress?.call('generating', null);
      // Generate audio in background isolate (non-blocking)
      final wavPath = p.join(
          _tempDir!, 'kokoro_tts_${DateTime.now().millisecondsSinceEpoch}.wav');
      final result = await _generateInWorker(cleaned, sid, _speed, wavPath);

      // Check if cancelled via stop() while worker was generating
      if (!_isSpeaking) return false;

      if (result == null) {
        debugPrint('KokoroTtsService: Generated empty audio');
        _isSpeaking = false;
        _disableWakeLock();
        onError?.call();
        onProgress?.call('error', null);
        return false;
      }

      onProgress?.call('generating', 1.0);
      onProgress?.call('preparing', 0.9);

      // Play via just_audio — setFilePath loads, play() starts
      await _player.setFilePath(wavPath);
      onProgress?.call('playing', 0.0);

      playbackProgressSub = _player.positionStream.listen((position) {
        final duration = _player.duration;
        if (duration == null || duration.inMilliseconds <= 0) return;
        final fraction = position.inMilliseconds / duration.inMilliseconds;
        onProgress?.call('playing', fraction.clamp(0.0, 1.0));
      });

      if (awaitCompletion) {
        await playTtsClip(_player);
        await _player.processingStateStream.firstWhere(
          (state) => state == ProcessingState.completed,
        );
        onProgress?.call('complete', 1.0);
      } else {
        unawaited(playTtsClip(_player));
      }

      // Clean up old temp files (keep current one)
      _cleanupTempFiles(wavPath);

      return true;
    } catch (e) {
      debugPrint('KokoroTtsService: Speak failed: $e');
      _isSpeaking = false;
      _disableWakeLock();
      onError?.call();
      onProgress?.call('error', null);
      return false;
    } finally {
      await playbackProgressSub?.cancel();
    }
  }

  /// Stop current playback and cancel any streaming session.
  Future<void> stop() async {
    final wasStreaming = _isStreaming;
    _isStreaming = false;
    _streamingFinished = false;
    _sentenceBuffer = '';
    _pendingSentences.clear();
    _audioQueue.clear();
    _isGeneratingChunk = false;
    _isPlayingFromQueue = false;
    _chunksGenerated = 0;
    _playbackSafetyTimer?.cancel();
    _playbackSafetyTimer = null;
    _playerBusy = false;

    if (_isSpeaking) {
      await _player.stop();
      _isSpeaking = false;
    }

    _disableWakeLock();

    if (wasStreaming) {
      _cleanupStreamFiles();
    }
  }

  // ──────────────────────────────────────────────────────────
  // Streaming TTS — speak sentence-by-sentence as text arrives
  // ──────────────────────────────────────────────────────────

  /// Start a streaming TTS session. Call [feedText] as text chunks arrive,
  /// then [finishStreaming] when the response is complete.
  void startStreaming() {
    if (_isSpeaking || _isPlayingFromQueue) {
      _player.stop(); // fire-and-forget stop
    }
    _isStreaming = true;
    _streamingFinished = false;
    _sentenceBuffer = '';
    _pendingSentences.clear();
    _audioQueue.clear();
    for (final f in _streamWavFiles) {
      try {
        File(f).deleteSync();
      } catch (_) {}
    }
    _streamWavFiles.clear();
    _isGeneratingChunk = false;
    _isPlayingFromQueue = false;
    _streamChunkIndex = 0;
    _chunksGenerated = 0;
    _isSpeaking = true;
    _enableWakeLock();
    onStart?.call();
    debugPrint('KokoroTTS: 🎬 Streaming session started');
  }

  /// Feed a text chunk from the streaming response.
  /// Sentences are extracted and queued for TTS generation automatically.
  void feedText(String chunk) {
    if (!_isStreaming || !_isInitialized) return;
    _sentenceBuffer += chunk;
    _processSentenceBuffer();
  }

  /// Signal that streaming is complete. Any remaining buffered text
  /// will be appended to the last pending sentence (for natural prosody)
  /// or queued as a new sentence if nothing is pending.
  void finishStreaming() {
    if (!_isStreaming) return;
    _isStreaming = false;
    final remaining = _sentenceBuffer.trim();
    _sentenceBuffer = '';
    if (remaining.isNotEmpty) {
      if (_pendingSentences.isNotEmpty) {
        // Append to last pending sentence for better prosody
        final last = _pendingSentences.removeLast();
        _pendingSentences.add('$last $remaining');
        debugPrint(
            'KokoroTTS: 🔚 Appended remaining (${remaining.length} chars) to last pending sentence');
      } else {
        // Nothing pending — queue as a new sentence
        debugPrint(
            'KokoroTTS: 🔚 Queuing remaining buffer as sentence (${remaining.length} chars): "${remaining.length > 60 ? '${remaining.substring(0, 60)}...' : remaining}"');
        _pendingSentences.add(remaining);
      }
      _processGenerationQueue();
    }
    _streamingFinished = true;
    debugPrint(
        'KokoroTTS: 🏁 Streaming finished (pending=${_pendingSentences.length}, queue=${_audioQueue.length}, generating=$_isGeneratingChunk, playing=$_isPlayingFromQueue)');
    _checkStreamingComplete();
  }

  /// Extract complete sentences from the buffer and queue for generation.
  void _processSentenceBuffer() {
    bool extracted = false;
    while (true) {
      final idx = _findSentenceEnd(_sentenceBuffer);
      if (idx < 0) break;
      final sentence = _sentenceBuffer.substring(0, idx + 1).trim();
      _sentenceBuffer = _sentenceBuffer.substring(idx + 1);
      if (sentence.isNotEmpty) {
        _pendingSentences.add(sentence);
        extracted = true;
        debugPrint(
            'KokoroTTS: ✂️ Extracted sentence (${sentence.length} chars): "${sentence.length > 60 ? '${sentence.substring(0, 60)}...' : sentence}"');
      }
    }
    if (extracted) {
      _processGenerationQueue();
    }
  }

  /// Find the end index of the first complete sentence.
  /// Returns -1 if no sentence boundary found yet.
  /// Splits aggressively on punctuation for low-latency streaming.
  int _findSentenceEnd(String text) {
    // First pass: look for strong sentence endings (.!?) with low minimum
    for (int i = 0; i < text.length - 1; i++) {
      final c = text[i];
      final next = text[i + 1];
      // Sentence-ending punctuation followed by whitespace
      if ((c == '.' || c == '!' || c == '?') &&
          i >= 20 &&
          (next == ' ' || next == '\n' || next == '\r')) {
        return i;
      }
      // Line break — split on any newline if we have enough text
      if (c == '\n' && i >= 20) {
        return i;
      }
    }
    // Check if text ends with sentence-ending punctuation (no trailing space)
    // This handles complete sentences that arrive without a trailing whitespace
    if (text.length >= 20) {
      final last = text[text.length - 1];
      if (last == '.' || last == '!' || last == '?') {
        return text.length - 1;
      }
    }
    // Force split if buffer is getting very long (no sentence boundary found)
    if (text.length > 160) {
      // Try to split at a period or newline first
      for (int i = 100; i < text.length; i++) {
        if (text[i] == '.' || text[i] == '\n') return i;
      }
      // Otherwise split at a space
      for (int i = 100; i < text.length; i++) {
        if (text[i] == ' ') return i;
      }
    }
    return -1;
  }

  /// Process pending sentences with adaptive batching:
  /// - First 2 chunks: one sentence each (low latency for quick start)
  /// - After that: batch 2-3 sentences together (better rhythm & prosody)
  Future<void> _processGenerationQueue() async {
    if (_isGeneratingChunk) return;
    _isGeneratingChunk = true;
    while (_pendingSentences.isNotEmpty) {
      if (!_isStreaming && !_streamingFinished) break; // cancelled

      String textToGenerate;
      if (_chunksGenerated < 2) {
        // First 2 chunks: single sentence for quick start
        textToGenerate = _pendingSentences.removeAt(0);
      } else {
        // After first 2: batch up to 3 sentences for better flow
        final batchSize = _pendingSentences.length.clamp(1, 3);
        final batch = _pendingSentences.take(batchSize).toList();
        _pendingSentences.removeRange(0, batchSize);
        textToGenerate = batch.join(' ');
        if (batchSize > 1) {
          debugPrint(
              'KokoroTTS: 📦 Batched $batchSize sentences (${textToGenerate.length} chars)');
        }
      }
      _chunksGenerated++;
      await _generateAndQueueChunk(textToGenerate);
    }
    _isGeneratingChunk = false;
    _checkStreamingComplete();
  }

  /// Generate audio for a single sentence and add to the playback queue.
  Future<void> _generateAndQueueChunk(String sentence) async {
    final cleaned = _cleanForTts(sentence);
    if (cleaned.isEmpty) return;
    try {
      final lang = await _prepareLanguage(cleaned);
      if (lang == null) return;
      final sid = TtsLanguageCatalog.mapSpeakerId(lang, _speakerId);
      final sw = Stopwatch()..start();
      final wavPath = p.join(
        _tempDir!,
        'kokoro_stream_$_streamChunkIndex.wav',
      );

      // Generate audio in background isolate (non-blocking)
      final result = await _generateInWorker(cleaned, sid, _speed, wavPath);
      sw.stop();

      // Check if session was cancelled while worker was generating
      if (!_isStreaming && !_streamingFinished) return;
      if (result == null) return;

      final (sampleCount, sampleRate, durationMs) = result;
      debugPrint(
          'KokoroTTS: 🔊 Generated chunk #$_streamChunkIndex in ${sw.elapsedMilliseconds}ms ($sampleCount samples, ${durationMs}ms audio)');

      _streamChunkIndex++;
      _streamWavFiles.add(wavPath);
      _audioQueue.add(wavPath);

      // Start playback if not already playing
      if (!_isPlayingFromQueue) {
        _playNextFromQueue();
      }
    } catch (e) {
      debugPrint('KokoroTtsService: Chunk generation failed: $e');
    }
  }

  /// Play the next WAV file from the playback queue.
  Future<void> _playNextFromQueue() async {
    _playbackSafetyTimer?.cancel();
    _playbackSafetyTimer = null;

    if (_audioQueue.isEmpty) {
      _isPlayingFromQueue = false;
      _checkStreamingComplete();
      return;
    }
    _isPlayingFromQueue = true;
    final wavPath = _audioQueue.removeAt(0);
    debugPrint(
        'KokoroTTS: ▶️ Playing chunk (${_audioQueue.length} remaining in queue)');

    // Calculate safety timer duration BEFORE play attempt so it works
    // even if setFilePath/play hangs (a real issue on some iOS devices).
    int estimatedMs = 10000; // default 10s fallback
    try {
      final file = File(wavPath);
      if (file.existsSync()) {
        // Estimate duration from WAV file size:
        // size = 44 (header) + samples*2, sampleRate=24000, so
        // duration ≈ (fileSize - 44) / 2 / 24000 * 1000
        final fileSize = file.lengthSync();
        estimatedMs = ((fileSize - 44) / 2 / 24000 * 1000).round();
      }
    } catch (_) {}
    final safetyDuration = Duration(milliseconds: estimatedMs + 3000);
    _playbackSafetyTimer = Timer(safetyDuration, () {
      debugPrint(
          'KokoroTTS: ⚠️ Safety timer fired — playback may have stalled');
      _playerBusy = false;
      if (_isPlayingFromQueue) {
        _isPlayingFromQueue = false;
        _playNextFromQueue();
      }
    });

    try {
      // Stop previous playback (just_audio requires this before loading new source)
      if (_playerBusy) {
        await _player
            .stop()
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      }
      _playerBusy = true;

      // Load and play — setFilePath is fast, play() returns a Future that
      // completes when playback ends, but we don't await it.
      await _player.setFilePath(wavPath).timeout(const Duration(seconds: 5),
          onTimeout: () {
        debugPrint('KokoroTTS: ⚠️ setFilePath timed out');
        return null;
      });
      onPlaybackStart?.call();
      unawaited(playTtsClip(_player));
    } catch (e) {
      debugPrint('KokoroTtsService: Chunk playback failed: $e');
      _playbackSafetyTimer?.cancel();
      _playerBusy = false;
      _isPlayingFromQueue = false;
      if (_audioQueue.isNotEmpty) {
        _playNextFromQueue();
      } else {
        _checkStreamingComplete();
      }
    }
  }

  /// Check if all streaming audio has finished playing.
  void _checkStreamingComplete() {
    if (_streamingFinished &&
        _pendingSentences.isEmpty &&
        _audioQueue.isEmpty &&
        !_isPlayingFromQueue &&
        !_isGeneratingChunk) {
      debugPrint('KokoroTTS: ✅ Streaming session complete');
      _isSpeaking = false;
      _streamingFinished = false;
      _disableWakeLock();
      onComplete?.call();
      _cleanupStreamFiles();
    }
  }

  // ──────────────────────────────────────────────────────────
  // Background isolate for non-blocking TTS generation
  // ──────────────────────────────────────────────────────────

  /// Worker isolate entry point. Initialises sherpa-onnx in its own isolate
  /// so that generate() calls don't block the main (UI) thread.
  static void _ttsWorkerEntryPoint(List<dynamic> initArgs) {
    final mainSendPort = initArgs[0] as SendPort;
    final config = Map<String, String>.from(initArgs[1] as Map);
    final numThreads = initArgs[2] as int;

    try {
      sherpa.initBindings();

      final engine = config['engine'] ?? 'kokoro';
      late final sherpa.OfflineTtsModelConfig modelConfig;
      if (engine == 'vits') {
        modelConfig = sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: config['model'] ?? '',
            tokens: config['tokens'] ?? '',
            dataDir: config['dataDir'] ?? '',
          ),
          numThreads: numThreads,
          debug: false,
        );
      } else {
        modelConfig = sherpa.OfflineTtsModelConfig(
          kokoro: sherpa.OfflineTtsKokoroModelConfig(
            model: config['model'] ?? '',
            voices: config['voices'] ?? '',
            tokens: config['tokens'] ?? '',
            dataDir: config['dataDir'] ?? '',
            lexicon: config['lexicon'] ?? '',
            lang: config['lang'] ?? '',
            lengthScale: 1.0,
          ),
          numThreads: numThreads,
          debug: false,
        );
      }

      final tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
        model: modelConfig,
        ruleFsts: config['ruleFsts'] ?? '',
      ));

      final workerPort = ReceivePort();
      mainSendPort.send(['ready', workerPort.sendPort]);

      workerPort.listen((message) {
        if (message == 'dispose') {
          tts.free();
          workerPort.close();
          Isolate.exit();
        }

        if (message is List && message.length >= 5) {
          final replyPort = message[0] as SendPort;
          final text = message[1] as String;
          final sid = message[2] as int;
          final speed = message[3] as double;
          final wavPath = message[4] as String;

          try {
            if (text.trim().isEmpty) {
              replyPort.send([false, 'Empty text']);
              return;
            }
            final audio = tts.generate(text: text, sid: sid, speed: speed);
            if (audio.samples.isEmpty) {
              replyPort.send([
                false,
                'Empty audio (chars=${text.length})',
              ]);
              return;
            }
            _writeWav(wavPath, audio.samples, audio.sampleRate);
            final durationMs =
                (audio.samples.length / audio.sampleRate * 1000).round();
            replyPort.send(
                [true, audio.samples.length, audio.sampleRate, durationMs]);
          } catch (e) {
            replyPort.send([false, e.toString()]);
          }
        }
      });
    } catch (e) {
      mainSendPort.send(['error', e.toString()]);
    }
  }

  /// Send a generation request to the background worker and wait for the result.
  /// Returns (sampleCount, sampleRate, durationMs) on success, null on failure.
  Future<(int, int, int)?> _generateInWorker(
    String text,
    int sid,
    double speed,
    String wavPath,
  ) async {
    if (_workerSendPort == null) return null;

    final replyPort = ReceivePort();
    _workerSendPort!.send([replyPort.sendPort, text, sid, speed, wavPath]);

    try {
      final result = await replyPort.first.timeout(
        const Duration(seconds: 60),
      ) as List;
      replyPort.close();

      if (result[0] == true) {
        return (result[1] as int, result[2] as int, result[3] as int);
      }
      lastError = result[1].toString();
      debugPrint(
          'KokoroTTS: Worker generation failed: ${result[1]} (sent ${text.length} chars)');
      return null;
    } catch (e) {
      replyPort.close();
      debugPrint('KokoroTTS: Worker communication failed: $e');
      return null;
    }
  }

  /// Strip markdown formatting and non-speakable characters for cleaner TTS output.
  static String _cleanForTts(String text) {
    var result = text;
    // Remove fenced code blocks
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    // Remove inline code
    result = result.replaceAll(RegExp(r'`[^`]+`'), '');
    // Remove bold/italic markers
    result = result.replaceAll(RegExp(r'\*{1,3}'), '');
    // Remove heading markers
    result = result.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    // Simplify links: [text](url) → text
    result = result.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    // Remove images
    result = result.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), '');
    // Remove horizontal rules
    result = result.replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '');
    // Remove hidden image generation prompts [IMG_PROMPT: ...]
    result =
        result.replaceAll(RegExp(r'\[IMG_PROMPT:\s*.+?\]', dotAll: true), '');
    // Remove hidden tags the model may emit
    result = result.replaceAll(
        RegExp(r'\[(?:MEMORY_SAVE|MEMORY|TOOL|ACTION|FUNCTION_CALL):[^\]]*\]',
            dotAll: true),
        '');
    // Strip emoji / pictographs; keep Latin, CJK, Cyrillic, and other letters.
    result = result.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}\u{200D}]',
        unicode: true,
      ),
      ' ',
    );
    // Collapse whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result.trim();
  }

  /// Set the speaker voice by ID (English UI 0–10; multilingual ids allowed).
  void setSpeakerId(int id) {
    _speakerId = id.clamp(0, 52);
  }

  /// Set the speech speed (0.5 - 2.0).
  /// Speed is applied per-generate() call, no reinit needed.
  void setSpeed(double speed) {
    _speed = speed.clamp(0.5, 2.0);
  }

  /// Write PCM Float32 samples to a WAV file.
  static void _writeWav(String path, Float32List samples, int sampleRate) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;

    // Convert float32 [-1.0, 1.0] to int16
    final int16Data = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      int16Data[i] = (clamped * 32767).round();
    }

    final dataSize = int16Data.length * 2;
    const headerSize = 44;
    final fileSize = headerSize + dataSize;

    final buffer = ByteData(fileSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // (space)
    buffer.setUint32(offset, 16, Endian.little); // chunk size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM format
    offset += 2;
    buffer.setUint16(offset, numChannels, Endian.little);
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    buffer.setUint16(offset, blockAlign, Endian.little);
    offset += 2;
    buffer.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;

    // data chunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Write PCM data
    for (int i = 0; i < int16Data.length; i++) {
      buffer.setInt16(offset, int16Data[i], Endian.little);
      offset += 2;
    }

    File(path).writeAsBytesSync(buffer.buffer.asUint8List());
  }

  /// Remove old temp WAV files to save space.
  void _cleanupTempFiles(String keepPath) {
    try {
      final dir = Directory(_tempDir!);
      for (final entity in dir.listSync()) {
        if (entity is File &&
            entity.path.contains('kokoro_tts_') &&
            entity.path.endsWith('.wav') &&
            entity.path != keepPath) {
          entity.deleteSync();
        }
      }
    } catch (_) {}
  }

  /// Remove streaming WAV files after a streaming session.
  void _cleanupStreamFiles() {
    for (final path in _streamWavFiles) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    _streamWavFiles.clear();
  }

  // ---------------------------------------------------------------------------
  // Wake lock helpers — keep screen on while speaking
  // ---------------------------------------------------------------------------

  Future<void> _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
      debugPrint('🔒 Kokoro TTS wake lock enabled');
    } catch (e) {
      debugPrint('⚠️ Kokoro TTS could not enable wake lock: $e');
    }
  }

  Future<void> _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
      debugPrint('🔓 Kokoro TTS wake lock disabled');
    } catch (e) {
      debugPrint('⚠️ Kokoro TTS could not disable wake lock: $e');
    }
  }

  /// Release resources.
  Future<void> dispose() async {
    await stop();
    _playbackSafetyTimer?.cancel();
    _playbackSafetyTimer = null;
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    await _player.dispose();
    try {
      _workerSendPort?.send('dispose');
    } catch (_) {}
    _workerIsolate?.kill(priority: Isolate.immediate);
    _workerIsolate = null;
    _workerSendPort = null;
    _workerEngineGroup = null;
    _isInitialized = false;
    _playerListenerReady = false;
  }
}
