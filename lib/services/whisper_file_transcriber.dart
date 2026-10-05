import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../models/transcription_segment.dart';
import '../utils/whisper_languages.dart';
import '../utils/whisper_transcript_stabilizer.dart';
import 'whisper_model_manager.dart';

typedef TranscriptionProgressCallback = void Function(
  double progress,
  String label,
);

class _DecodeResult {
  final String text;
  final List<String> tokens;
  final List<double> timestamps;

  const _DecodeResult({
    required this.text,
    this.tokens = const [],
    this.timestamps = const [],
  });
}

/// Offline file transcription via Whisper + optional Silero VAD segments.
class WhisperFileTranscriber {
  WhisperFileTranscriber._();
  static final WhisperFileTranscriber instance = WhisperFileTranscriber._();

  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  sherpa.VoiceActivityDetector? _vad;
  static bool _bindingsReady = false;
  String? _workerLanguage;
  bool _workerWordTimestamps = false;
  String? _workerModelId;

  Future<bool> ensureReady({
    required String language,
    required bool wordTimestamps,
  }) async {
    if (!await WhisperModelManager.instance.isModelReady()) return false;
    if (!await WhisperModelManager.instance.ensureVadModel()) return false;

    if (!_bindingsReady) {
      sherpa.initBindings();
      _bindingsReady = true;
    }

    final sherpaLang = WhisperLanguage.sherpaLanguageCode(language);
    final modelId = WhisperModelManager.instance.selectedModelId;
    if (_workerSendPort == null ||
        _workerLanguage != sherpaLang ||
        _workerWordTimestamps != wordTimestamps ||
        _workerModelId != modelId) {
      await _disposeWorker();
      final ok = await _spawnWorker(
        language: sherpaLang,
        wordTimestamps: wordTimestamps,
      );
      if (!ok) return false;
      _workerLanguage = sherpaLang;
      _workerWordTimestamps = wordTimestamps;
      _workerModelId = modelId;
    }

    if (_vad == null) {
      final vadPath = await WhisperModelManager.instance.resolveVadModelPath();
      if (vadPath == null) return false;
      _vad = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: vadPath,
            threshold: 0.5,
            minSilenceDuration: 0.5,
            minSpeechDuration: 0.25,
            windowSize: 512,
            maxSpeechDuration: 30.0,
          ),
          sampleRate: 16000,
          numThreads: 1,
          provider: 'cpu',
          debug: false,
        ),
        bufferSizeInSeconds: 120,
      );
    }
    return true;
  }

  Future<void> _disposeWorker() async {
    if (_workerSendPort != null) {
      _workerSendPort!.send(['', 'dispose']);
    }
    _workerIsolate?.kill(priority: Isolate.immediate);
    _workerIsolate = null;
    _workerSendPort = null;
    _workerModelId = null;
  }

  /// Called when the user switches Whisper size so the next job reloads weights.
  Future<void> disposeWorkerForModelChange() async {
    await _disposeWorker();
    _workerLanguage = null;
  }

  Future<List<TranscriptionSegment>> transcribeSamples({
    required Float32List samples,
    required String language,
    required bool includeTimestamps,
    required String timestampGranularity,
    TranscriptionProgressCallback? onProgress,
  }) async {
    final wordMode =
        includeTimestamps && timestampGranularity == 'word';
    if (!await ensureReady(language: language, wordTimestamps: wordMode)) {
      throw Exception('Whisper model is not ready');
    }

    if (!includeTimestamps) {
      onProgress?.call(0.1, 'Transcribing…');
      final text = WhisperTranscriptStabilizer.collapseRepeats(
        (await _decode(samples)).text,
      );
      onProgress?.call(1.0, 'Complete');
      if (text.trim().isEmpty) return const [];
      return [
        TranscriptionSegment(
          startMs: 0,
          endMs: (samples.length / 16).round(),
          text: text.trim(),
        ),
      ];
    }

    if (wordMode) {
      return _transcribeWithWordTimestamps(samples, onProgress: onProgress);
    }

    return _transcribeWithVad(samples, onProgress: onProgress);
  }

  Future<List<TranscriptionSegment>> _transcribeWithWordTimestamps(
    Float32List samples, {
    TranscriptionProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.2, 'Transcribing with word timestamps…');
    final result = await _decode(samples);
    final words = _tokensToWordSegments(
      result.tokens,
      result.timestamps,
    );
    onProgress?.call(1.0, 'Complete');
    if (words.isNotEmpty) return words;

    final text = WhisperTranscriptStabilizer.collapseRepeats(result.text);
    if (text.trim().isEmpty) return const [];
    return [
      TranscriptionSegment(
        startMs: 0,
        endMs: (samples.length / 16).round(),
        text: text.trim(),
      ),
    ];
  }

  Future<List<TranscriptionSegment>> _transcribeWithVad(
    Float32List samples, {
    TranscriptionProgressCallback? onProgress,
  }) async {
    _vad!.clear();
    const window = 512;
    var offset = 0;
    while (offset < samples.length) {
      final end =
          (offset + window > samples.length) ? samples.length : offset + window;
      _vad!.acceptWaveform(Float32List.sublistView(samples, offset, end));
      offset = end;
    }
    _vad!.flush();

    final segments = <TranscriptionSegment>[];
    var processed = 0;

    while (!_vad!.isEmpty()) {
      final seg = _vad!.front();
      _vad!.pop();
      if (seg.samples.isEmpty) continue;
      processed++;
      onProgress?.call(
        0.05 + (processed * 0.9) / (processed + 2),
        'Transcribing segment $processed…',
      );
      final text = WhisperTranscriptStabilizer.collapseRepeats(
        (await _decode(seg.samples)).text,
      );
      if (text.trim().isEmpty) continue;
      final startMs = (seg.start / 16).round();
      final endMs = startMs + (seg.samples.length / 16).round();
      segments.add(
        TranscriptionSegment(
          startMs: startMs,
          endMs: endMs,
          text: text.trim(),
        ),
      );
    }

    if (segments.isEmpty) {
      onProgress?.call(0.5, 'Transcribing full clip…');
      final text = WhisperTranscriptStabilizer.collapseRepeats(
        (await _decode(samples)).text,
      );
      if (text.trim().isNotEmpty) {
        segments.add(TranscriptionSegment(
          startMs: 0,
          endMs: (samples.length / 16).round(),
          text: text.trim(),
        ));
      }
    }

    onProgress?.call(1.0, 'Complete');
    return segments;
  }

  static List<TranscriptionSegment> _tokensToWordSegments(
    List<String> tokens,
    List<double> timestamps, {
    int timeOffsetMs = 0,
  }) {
    if (tokens.isEmpty || timestamps.isEmpty) return const [];

    final segments = <TranscriptionSegment>[];
    final buf = StringBuffer();
    double? wordStartSec;
    double lastEndSec = 0;

    void flushWord({required double endSec}) {
      final text = buf.toString().trim();
      if (text.isEmpty || wordStartSec == null) {
        buf.clear();
        wordStartSec = null;
        return;
      }
      final endMs = (endSec * 1000).round() + timeOffsetMs;
      final startMs = (wordStartSec! * 1000).round() + timeOffsetMs;
      segments.add(
        TranscriptionSegment(
          startMs: startMs,
          endMs: endMs > startMs ? endMs : startMs + 200,
          text: text,
        ),
      );
      buf.clear();
      wordStartSec = null;
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.isEmpty) continue;
      final t = i < timestamps.length ? timestamps[i] : lastEndSec;
      lastEndSec = t;
      final nextSec = i + 1 < timestamps.length ? timestamps[i + 1] : t + 0.35;

      final startsNewWord = buf.isEmpty ||
          token.startsWith(' ') ||
          _isCjk(token.trimLeft());

      if (startsNewWord && buf.isNotEmpty) {
        flushWord(endSec: t);
      }

      if (buf.isEmpty) wordStartSec = t;
      buf.write(token);

      final isLast = i == tokens.length - 1;
      if (isLast) flushWord(endSec: nextSec);
    }
    return segments;
  }

  static bool _isCjk(String s) {
    if (s.isEmpty) return false;
    final c = s.codeUnitAt(0);
    return (c >= 0x4E00 && c <= 0x9FFF) ||
        (c >= 0x3040 && c <= 0x30FF) ||
        (c >= 0xAC00 && c <= 0xD7AF);
  }

  Future<_DecodeResult> _decode(Float32List samples) async {
    if (_workerSendPort == null || samples.isEmpty) {
      return const _DecodeResult(text: '');
    }
    final replyPort = ReceivePort();
    _workerSendPort!.send([replyPort.sendPort, 'decode', samples]);
    final response = await replyPort.first as List<dynamic>;
    replyPort.close();
    if (response.first == 'ok') {
      final text = (response[1] as String).trim();
      final tokens = response.length > 2
          ? List<String>.from(response[2] as List)
          : const <String>[];
      final timestamps = response.length > 3
          ? List<double>.from((response[3] as List).map((e) => (e as num).toDouble()))
          : const <double>[];
      return _DecodeResult(
        text: text,
        tokens: tokens,
        timestamps: timestamps,
      );
    }
    debugPrint('WhisperFileTranscriber decode error: ${response[1]}');
    return const _DecodeResult(text: '');
  }

  Future<bool> _spawnWorker({
    required String language,
    required bool wordTimestamps,
  }) async {
    final paths = await WhisperModelManager.instance.resolveModelPaths();
    if (paths == null) return false;

    final initPort = ReceivePort();
    _workerIsolate = await Isolate.spawn(
      _workerEntryPoint,
      [
        initPort.sendPort,
        paths.encoder,
        paths.decoder,
        paths.tokens,
        2,
        language,
        wordTimestamps,
      ],
    );
    final initResult = await initPort.first as List<dynamic>;
    initPort.close();
    _workerSendPort = initResult[0] as SendPort;
    return true;
  }

  static void _workerEntryPoint(List<dynamic> initArgs) {
    final initPort = initArgs[0] as SendPort;
    final encoderPath = initArgs[1] as String;
    final decoderPath = initArgs[2] as String;
    final tokensPath = initArgs[3] as String;
    final numThreads = initArgs[4] as int;
    final language = initArgs[5] as String;
    final wordTimestamps = initArgs[6] as bool;

    sherpa.initBindings();
    final recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: encoderPath,
            decoder: decoderPath,
            language: language,
            task: 'transcribe',
            enableTokenTimestamps: wordTimestamps,
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
          stream.acceptWaveform(samples: samples, sampleRate: 16000);
          recognizer.decode(stream);
          final result = recognizer.getResult(stream);
          replyPort.send([
            'ok',
            result.text.trim(),
            result.tokens,
            result.timestamps,
          ]);
        } catch (e) {
          replyPort.send(['err', e.toString()]);
        } finally {
          stream?.free();
        }
      }
    });
  }
}
