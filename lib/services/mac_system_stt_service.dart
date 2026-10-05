import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../models/stt_recognition_result.dart';

/// Dart client for the native macOS `SFSpeechRecognizer` bridge
/// (macos/Runner/MacSpeechBridge.swift).
///
/// This is the "System (macOS Speech)" path — Apple's on-device recognizer,
/// which is fast and accurate like iPhone dictation. The native side only
/// reports itself [available] for real launched apps (never under
/// `flutter run` / Xcode), so [SttService] can safely fall back to Whisper in
/// dev/sandboxed-IDE runs where SFSpeechRecognizer would crash the process.
class MacSystemSttService {
  MacSystemSttService._();
  static final MacSystemSttService instance = MacSystemSttService._();

  static const MethodChannel _channel = MethodChannel('lm_mini/macos_stt');
  static const EventChannel _events = EventChannel('lm_mini/macos_stt/events');

  StreamSubscription<dynamic>? _eventSub;
  bool _listening = false;
  bool? _availableCache;

  final _resultController = StreamController<SttRecognitionResult>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _levelController = StreamController<double>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<SttRecognitionResult> get resultStream => _resultController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<double> get soundLevelStream => _levelController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isListening => _listening;

  /// Whether the native bridge considers itself safe + usable right now.
  /// Cached because the answer is stable for a process launch.
  Future<bool> isAvailable() async {
    if (!Platform.isMacOS) return false;
    if (_availableCache != null) return _availableCache!;
    try {
      final ok = await _channel.invokeMethod<bool>('isAvailable');
      // Only cache a definitive answer from the native bridge. A
      // MissingPluginException means the channel isn't wired yet (very early
      // startup) — don't poison the cache; let a later call retry.
      _availableCache = ok ?? false;
      return _availableCache!;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> authStatus() async {
    try {
      return await _channel.invokeMethod<String>('authStatus') ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Triggers the Speech Recognition TCC prompt. Safe: the native side no-ops
  /// (returns "unavailable") when it can't request without crashing.
  Future<String> requestAuthorization() async {
    try {
      return await _channel.invokeMethod<String>('requestAuth') ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<List<String>> supportedLocales() async {
    try {
      final list = await _channel.invokeMethod<List<dynamic>>('locales');
      return list?.map((e) => e.toString()).toList() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<bool> startListening({
    required void Function(SttRecognitionResult) onResult,
    String localeId = 'en_US',
    bool onDevice = true,
  }) async {
    if (!await isAvailable()) return false;

    final auth = await authStatus();
    if (auth == 'notDetermined') {
      final result = await requestAuthorization();
      if (result != 'authorized') return false;
    } else if (auth != 'authorized') {
      return false;
    }

    await _eventSub?.cancel();
    _listening = true;
    _eventSub = _events
        .receiveBroadcastStream(<String, dynamic>{
          'localeId': localeId,
          'onDevice': onDevice,
        })
        .listen(
          (dynamic event) => _handleEvent(event, onResult),
          onError: (Object e) {
            _errorController.add(e.toString());
            _listening = false;
          },
          onDone: () {
            _listening = false;
          },
        );
    return true;
  }

  void _handleEvent(
      dynamic event, void Function(SttRecognitionResult) onResult) {
    if (event is! Map) return;
    final type = event['event'] as String?;
    switch (type) {
      case 'result':
        final mapped = SttRecognitionResult(
          recognizedWords: (event['text'] as String?) ?? '',
          finalResult: (event['isFinal'] as bool?) ?? false,
        );
        _resultController.add(mapped);
        onResult(mapped);
        break;
      case 'status':
        final status = (event['status'] as String?) ?? '';
        _statusController.add(status);
        if (status == 'done') _listening = false;
        break;
      case 'level':
        final level = (event['level'] as num?)?.toDouble() ?? 0.0;
        _levelController.add(level);
        break;
      case 'error':
        _errorController.add((event['message'] as String?) ?? 'speech_error');
        _listening = false;
        break;
    }
  }

  Future<void> stopListening() async {
    _listening = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {/* best-effort */}
    await _eventSub?.cancel();
    _eventSub = null;
  }

  Future<void> cancelListening() async {
    _listening = false;
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {/* best-effort */}
    await _eventSub?.cancel();
    _eventSub = null;
  }
}
