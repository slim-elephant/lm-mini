import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Voice-call session helper (CallKit on iOS when restored).
///
/// **Disabled for App Store / China MIIT:** `flutter_callkit_incoming` is not
/// in pubspec (so the IPA does not link CallKit.framework). Restore:
/// **agent.md** → “Restore CallKit”.
///
/// When restored, also hide in mainland China (`CN`; not TW/HK).
///
/// Usage:
///   await CallService.instance.startCall();
///   await CallService.instance.endCall();
class CallService {
  CallService._();
  static final CallService instance = CallService._();

  static const _audioChannel = MethodChannel('net.neuro9.lmmini/audio_session');

  /// Master switch. Keep `false` until native CallKit is restored.
  static const bool callKitFeatureEnabled = false;

  String? _currentCallId;

  /// Fires when the user (or system) ends the call from outside the app.
  VoidCallback? onCallEnded;

  static bool get _callKitSupported => Platform.isIOS || Platform.isAndroid;

  /// Whether the call-mode control should be shown and sessions may start.
  static bool get isOffered =>
      callKitFeatureEnabled && _callKitSupported && !isMainlandChina;

  /// Device region is mainland China (`CN`), not TW/HK or language-only `zh`.
  static bool get isMainlandChina {
    if (kIsWeb) return false;
    return mainlandChinaFromLocales(
      PlatformDispatcher.instance.locales,
      Platform.localeName,
    );
  }

  @visibleForTesting
  static bool mainlandChinaFromLocales(
    Iterable<Locale> locales,
    String localeName,
  ) {
    for (final locale in locales) {
      if (locale.countryCode?.toUpperCase() == 'CN') return true;
    }
    final name = localeName.toUpperCase().replaceAll('-', '_');
    return name == 'ZH_CN' || name.endsWith('_CN') || name.startsWith('ZH_CN_');
  }

  bool get isCallActive => _currentCallId != null;

  /// No-op until CallKit is restored (`call_service_callkit.dart`).
  Future<void> startCall({String callerName = 'AI Voice Chat'}) async {
    if (!isOffered) return;
  }

  Future<void> endCall() async {
    _currentCallId = null;
  }

  Future<void> endAllCalls() async {
    _currentCallId = null;
  }

  /// Configure the native AVAudioSession for voice chat.
  Future<bool> configureAudioSessionForVoiceChat() async {
    if (!Platform.isIOS) return true;
    try {
      final result =
          await _audioChannel.invokeMethod<bool>('configureForVoiceChat');
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: configureAudioSession error: $e');
      return false;
    }
  }

  /// Dictation-quality recognition (`.default` mode, not `.voiceChat`).
  Future<bool> configureAudioSessionForDictation() async {
    if (!Platform.isIOS) return true;
    try {
      final result =
          await _audioChannel.invokeMethod<bool>('configureForDictation');
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: configureForDictation error: $e');
      return false;
    }
  }

  Future<bool> activateAudioSessionForRecording() async {
    if (!Platform.isIOS) return true;
    try {
      final result =
          await _audioChannel.invokeMethod<bool>('activateForRecording');
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: activateForRecording error: $e');
      return false;
    }
  }

  Future<void> deactivateAudioSession() async {
    if (!Platform.isIOS) return;
    try {
      await _audioChannel.invokeMethod<bool>('deactivate');
    } catch (e) {
      debugPrint('CallService: deactivateAudioSession error: $e');
    }
  }

  void dispose() {
    _currentCallId = null;
  }
}
