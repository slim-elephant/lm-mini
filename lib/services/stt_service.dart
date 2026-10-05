import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../desktop/desktop_platform.dart';
import '../models/stt_recognition_result.dart';
import 'call_service.dart';
import 'mac_system_stt_service.dart';
import 'macos_media_permissions.dart';
import 'whisper_model_manager.dart';
import 'whisper_stt_service.dart';

/// Speech-to-text facade routing to either OS-native recognition or on-device
/// Whisper via sherpa-onnx.
class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final SpeechToText _speech = SpeechToText();
  final WhisperSttService _whisper = WhisperSttService.instance;

  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _isListening = false;
  String _activeProvider = 'whisper';
  /// Which backend was successfully initialized. Prevents returning early
  /// with Whisper readiness when the caller asked for system STT.
  String? _readyProvider;
  String _currentLocaleId = 'en_US';
  double _soundLevel = 0.0;
  List<LocaleName> _availableLocales = [];

  StreamSubscription<String>? _whisperStatusSub;
  StreamSubscription<double>? _whisperSoundSub;
  StreamSubscription<String>? _whisperErrorSub;

  /// True when system STT is served by the native macOS SFSpeechRecognizer
  /// bridge (installed builds) rather than the `speech_to_text` plugin.
  bool _macNative = false;
  StreamSubscription<String>? _macStatusSub;
  StreamSubscription<double>? _macSoundSub;
  StreamSubscription<String>? _macErrorSub;

  final _resultController =
      StreamController<SttRecognitionResult>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _soundLevelController = StreamController<double>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  double get soundLevel => _soundLevel;
  String get currentLocaleId => _currentLocaleId;
  String get activeProvider => _activeProvider;
  List<LocaleName> get availableLocales => _availableLocales;

  Stream<SttRecognitionResult> get resultStream => _resultController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Future<bool> isWhisperModelReady() => WhisperModelManager.instance.isModelReady();

  static bool isBenignSystemSttError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('error_no_match') ||
        lower.contains('error_speech_timeout') ||
        lower.contains('error_client');
  }

  Future<bool> initialize({
    String sttProvider = 'whisper',
    String? localeId,
  }) async {
    if (localeId != null && localeId.isNotEmpty) {
      _currentLocaleId = localeId;
    }

    if (sttProvider == 'whisper') {
      if (_readyProvider == 'whisper' && _whisper.isAvailable) {
        _activeProvider = 'whisper';
        _isAvailable = true;
        _isInitialized = true;
        _attachWhisperStreams();
        return true;
      }

      if (_readyProvider == 'system') {
        await stopListening();
        await _detachMacNativeStreams();
      }

      final whisperReady = await WhisperModelManager.instance.isModelReady();
      if (whisperReady) {
        final language = _whisperLanguageFromLocale(_currentLocaleId);
        _isAvailable =
            await _whisper.initialize(language: language);
        if (_isAvailable) {
          _isInitialized = true;
          _activeProvider = 'whisper';
          _readyProvider = 'whisper';
          _attachWhisperStreams();
          return true;
        }
        // Whisper model is present but the engine could not start (e.g. the
        // Silero VAD model could not be downloaded while offline). Fall back
        // to system recognition so voice still works — except on sandboxed Mac,
        // where speech_to_text initialize() can hard-crash the process.
        if (DesktopPlatform.macListeningRequiresWhisper) {
          debugPrint(
              '🎙️ Whisper engine unavailable — system STT skipped (sandboxed Mac)');
          _isAvailable = false;
          _isInitialized = true;
          _readyProvider = null;
          _activeProvider = 'whisper';
          return false;
        }
        debugPrint('🎙️ Whisper engine unavailable — falling back to system STT');
        return initialize(sttProvider: 'system', localeId: localeId);
      }
      // Selected id may be an empty placeholder dir — try any downloaded model.
      final fallbackId =
          await WhisperModelManager.instance.resolveUsableModelId();
      if (fallbackId != null) {
        debugPrint('🎙️ Whisper: retrying initialize with ready model $fallbackId');
        return initialize(sttProvider: 'whisper', localeId: localeId);
      }
      if (DesktopPlatform.macListeningRequiresWhisper) {
        debugPrint(
            '🎙️ Whisper model missing — system STT skipped (sandboxed Mac; download Whisper)');
        _isAvailable = false;
        _isInitialized = true;
        _readyProvider = null;
        _activeProvider = 'whisper';
        return false;
      }
      debugPrint('🎙️ Whisper model missing — falling back to system STT');
      return initialize(sttProvider: 'system', localeId: localeId);
    }

    if (_readyProvider == 'system' && _isAvailable) {
      _activeProvider = 'system';
      _isInitialized = true;
      return true;
    }

    if (_readyProvider == 'whisper') {
      await stopListening();
      await _whisper.releaseCapture();
      await _detachWhisperStreams();
    }

    // macOS: prefer our native SFSpeechRecognizer bridge when it reports itself
    // safe/available (real installed .app). It returns false under
    // `flutter run` / Xcode (responsible-process TCC would SIGABRT), so we fall
    // back to Whisper there instead of crashing — no separate sandbox check
    // needed because the bridge already gates on the launch context.
    if (!kIsWeb && Platform.isMacOS) {
      final nativeOk = await MacSystemSttService.instance.isAvailable();
      if (nativeOk) {
        _attachMacNativeStreams();
        _macNative = true;
        _activeProvider = 'system';
        _readyProvider = 'system';
        _isAvailable = true;
        _isInitialized = true;
        debugPrint('🎙️ System STT: using native macOS speech recognizer');
        return true;
      }
      debugPrint(
          '🎙️ Native macOS speech unavailable (dev/sandboxed launch) — '
          'switching to Whisper');
      return initialize(sttProvider: 'whisper', localeId: localeId);
    }

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          _isListening = _speech.isListening;
          _statusController.add(status);
          debugPrint('🎙️ STT status: $status');
        },
        onError: (error) {
          _isListening = false;
          final msg = error.errorMsg;
          if (isBenignSystemSttError(msg)) {
            debugPrint('🎙️ STT benign: $msg');
            return;
          }
          _errorController.add(msg);
          debugPrint('🎙️ STT error: $msg');
        },
        debugLogging: kDebugMode,
      );

      if (_isAvailable) {
        _availableLocales = await _speech.locales();
        final systemLocale = await _speech.systemLocale();
        if (systemLocale != null && (localeId == null || localeId.isEmpty)) {
          _currentLocaleId = systemLocale.localeId;
        }
      }

      _activeProvider = 'system';
      _readyProvider = _isAvailable ? 'system' : null;
      _isInitialized = true;
      debugPrint(
          '🎙️ System STT initialized: available=$_isAvailable, locale=$_currentLocaleId');
    } catch (e) {
      debugPrint('🎙️ System STT initialization failed: $e');
      _isAvailable = false;
      _readyProvider = null;
      _isInitialized = true;
    }

    return _isAvailable;
  }

  Future<bool> startListening({
    Function(SttRecognitionResult)? onResult,
    Duration listenFor = const Duration(seconds: 30),
    Duration? pauseFor,
    String? localeId,
    String sttProvider = 'whisper',
    int pauseForSeconds = 3,
  }) async {
    if (!_isInitialized ||
        _activeProvider != sttProvider ||
        !_isAvailable) {
      final available = await initialize(
        sttProvider: sttProvider,
        localeId: localeId ?? _currentLocaleId,
      );
      if (!available) return false;
    }

    if (!_isAvailable) return false;

    if (_isListening) {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 200));
    } else if (sttProvider == 'system') {
      // Whisper may still hold the mic even when our facade thinks we're idle.
      await _whisper.releaseCapture();
      if (_speech.isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    if (_activeProvider == 'whisper') {
      _isListening = true;
      return _whisper.startListening(
        onResult: (result) {
          _resultController.add(result);
          onResult?.call(result);
        },
        listenFor: listenFor,
        pauseForSeconds: pauseForSeconds,
        localeId: localeId ?? _currentLocaleId,
      );
    }

    if (_macNative) {
      // Native macOS SFSpeechRecognizer. Mic + Speech TCC is requested inside
      // the bridge; status/level/error arrive on the attached streams.
      final ok = await MacSystemSttService.instance.startListening(
        onResult: (result) {
          _resultController.add(result);
          onResult?.call(result);
        },
        localeId: localeId ?? _currentLocaleId,
      );
      _isListening = ok;
      if (!ok) _readyProvider = null;
      return ok;
    }

    if (!_speech.isAvailable) {
      debugPrint('🎙️ System STT not available — re-initializing');
      final ok = await initialize(
        sttProvider: 'system',
        localeId: localeId ?? _currentLocaleId,
      );
      if (!ok) {
        _isListening = false;
        return false;
      }
    }

    try {
      if (_speech.isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        final micOk = await VoiceCapturePermissions.ensureForVoiceInput(
          // System STT needs Speech Recognition TCC on Apple platforms.
          requestSpeechRecognition: true,
        );
        if (!micOk) {
          debugPrint('🎙️ System STT: microphone permission denied');
          _isListening = false;
          return false;
        }
        if (Platform.isIOS) {
          final sessionOk =
              await CallService.instance.activateAudioSessionForRecording();
          if (!sessionOk) {
            debugPrint('🎙️ System STT: audio session activation failed');
          }
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      final osPauseFor = pauseFor ?? listenFor;
      // listen() returns void — success is reflected in isListening afterward.
      await _speech.listen(
        onResult: (result) {
          final mapped = SttRecognitionResult(
            recognizedWords: result.recognizedWords,
            finalResult: result.finalResult,
          );
          _resultController.add(mapped);
          onResult?.call(mapped);
        },
        listenFor: listenFor,
        pauseFor: osPauseFor,
        localeId: localeId ?? _currentLocaleId,
        onSoundLevelChange: (level) {
          _soundLevel = level;
          _soundLevelController.add(level);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          sampleRate: !kIsWeb && Platform.isIOS ? 44100 : 0,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 80));
      final started = _speech.isListening;
      _isListening = started;
      if (!started) {
        debugPrint('🎙️ System STT listen() did not start (isListening=false)');
        _readyProvider = null;
      }
      return started;
    } catch (e) {
      debugPrint('🎙️ Failed to start listening: $e');
      _isListening = false;
      _readyProvider = null;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_activeProvider == 'whisper') {
      if (_whisper.isListening) {
        await _whisper.stopListening();
      } else {
        await _whisper.releaseCapture();
      }
    } else if (_macNative) {
      await MacSystemSttService.instance.stopListening();
    } else if (_speech.isListening) {
      await _speech.stop();
    }
    _isListening = false;
    _soundLevel = 0;
  }

  Future<void> cancelListening() async {
    if (_activeProvider == 'whisper') {
      if (_whisper.isListening) {
        await _whisper.cancelListening();
      } else {
        await _whisper.releaseCapture();
      }
    } else if (_macNative) {
      await MacSystemSttService.instance.cancelListening();
    } else if (_speech.isListening) {
      await _speech.cancel();
    }
    _isListening = false;
    _soundLevel = 0;
  }

  void setLocale(String localeId) {
    _currentLocaleId = localeId;
  }

  List<LocaleName> getLocalesForLanguage(String langCode) {
    return _availableLocales.where((l) {
      return l.localeId.toLowerCase().startsWith(langCode.toLowerCase());
    }).toList();
  }

  Future<void> dispose() async {
    await stopListening();
    await _detachWhisperStreams();
    await _detachMacNativeStreams();
    await _whisper.resetEngine();
    if (!_resultController.isClosed) await _resultController.close();
    if (!_statusController.isClosed) await _statusController.close();
    if (!_soundLevelController.isClosed) await _soundLevelController.close();
    if (!_errorController.isClosed) await _errorController.close();
  }

  void _attachWhisperStreams() {
    _whisperStatusSub ??= _whisper.statusStream.listen((status) {
      _isListening = status == 'listening';
      _statusController.add(status);
    });
    _whisperSoundSub ??= _whisper.soundLevelStream.listen((level) {
      _soundLevel = level;
      _soundLevelController.add(level);
    });
    _whisperErrorSub ??= _whisper.errorStream.listen(_errorController.add);
  }

  Future<void> _detachWhisperStreams() async {
    await _whisperStatusSub?.cancel();
    await _whisperSoundSub?.cancel();
    await _whisperErrorSub?.cancel();
    _whisperStatusSub = null;
    _whisperSoundSub = null;
    _whisperErrorSub = null;
  }

  void _attachMacNativeStreams() {
    final svc = MacSystemSttService.instance;
    _macStatusSub ??= svc.statusStream.listen((status) {
      _isListening = status == 'listening';
      _statusController.add(status);
    });
    _macSoundSub ??= svc.soundLevelStream.listen((level) {
      _soundLevel = level;
      _soundLevelController.add(level);
    });
    _macErrorSub ??= svc.errorStream.listen(_errorController.add);
  }

  Future<void> _detachMacNativeStreams() async {
    await _macStatusSub?.cancel();
    await _macSoundSub?.cancel();
    await _macErrorSub?.cancel();
    _macStatusSub = null;
    _macSoundSub = null;
    _macErrorSub = null;
    _macNative = false;
  }

  static String _whisperLanguageFromLocale(String localeId) {
    return localeId.split(RegExp('[-_]')).first.toLowerCase();
  }
}
