import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../desktop/desktop_platform.dart';

/// Result of requesting microphone (+ speech recognition on Apple platforms).
class VoiceCapturePermissionResult {
  final bool microphoneGranted;

  /// macOS/iOS Speech Recognition TCC status string, or null on other platforms.
  final String? speechRecognitionStatus;

  const VoiceCapturePermissionResult({
    required this.microphoneGranted,
    this.speechRecognitionStatus,
  });

  bool get speechRecognitionAuthorized =>
      speechRecognitionStatus == null ||
      speechRecognitionStatus == 'authorized' ||
      speechRecognitionStatus == 'skipped';
}

/// Requests the OS privacy prompts that App Store Review expects when the
/// user taps the microphone for voice input.
///
/// On macOS (especially Mac App Store / sandboxed builds) we must call the
/// native AVFoundation APIs — `permission_handler` has no macOS
/// implementation and will not surface [NSMicrophoneUsageDescription].
///
/// Speech Recognition is requested only when [requestSpeechRecognition] is
/// true (system STT). Sandboxed Mac uses Whisper and must not touch
/// `SFSpeechRecognizer` — calling it while launched from Cursor/VS Code
/// SIGABRTs because the IDE is the TCC responsible process and lacks
/// [NSSpeechRecognitionUsageDescription].
class VoiceCapturePermissions {
  VoiceCapturePermissions._();

  static const _macosChannel = MethodChannel('lm_mini/macos_privacy');

  /// Shows system permission dialogs when status is undetermined.
  /// Returns whether the microphone was granted (required to listen).
  static Future<bool> ensureForVoiceInput({
    bool requestSpeechRecognition = false,
  }) async {
    final result = await requestForVoiceInput(
      requestSpeechRecognition: requestSpeechRecognition,
    );
    return result.microphoneGranted;
  }

  static Future<VoiceCapturePermissionResult> requestForVoiceInput({
    bool requestSpeechRecognition = false,
  }) async {
    if (kIsWeb) {
      return const VoiceCapturePermissionResult(microphoneGranted: true);
    }

    if (Platform.isMacOS) {
      // Sandboxed MAS / Runner builds listen via Whisper only — never prompt
      // for Speech Recognition (and never call the Speech framework).
      final wantSpeech = requestSpeechRecognition &&
          !DesktopPlatform.macListeningRequiresWhisper;
      final native = await _invokeMacosVoicePermissions(
        requestSpeech: wantSpeech,
      );
      if (native != null) return native;
      debugPrint(
        '🎙️ macOS privacy channel unavailable — cannot request mic',
      );
      return const VoiceCapturePermissionResult(microphoneGranted: false);
    }

    if (Platform.isIOS || Platform.isAndroid) {
      try {
        var mic = await Permission.microphone.status;
        if (!mic.isGranted) {
          mic = await Permission.microphone.request();
        }
        // iOS system STT also needs speech recognition.
        if (Platform.isIOS) {
          var speech = await Permission.speech.status;
          if (!speech.isGranted) {
            speech = await Permission.speech.request();
          }
          return VoiceCapturePermissionResult(
            microphoneGranted: mic.isGranted,
            speechRecognitionStatus:
                speech.isGranted ? 'authorized' : speech.toString(),
          );
        }
        return VoiceCapturePermissionResult(microphoneGranted: mic.isGranted);
      } on MissingPluginException {
        debugPrint('🎙️ permission_handler unavailable for mic request');
      } catch (e) {
        debugPrint('🎙️ Mic permission request failed: $e');
      }
    }

    // Desktop Linux/Windows or plugin failure — let the recorder fail later.
    return VoiceCapturePermissionResult(
      microphoneGranted: !DesktopPlatform.isMacOS,
    );
  }

  /// Retries briefly so a race with MainFlutterWindow channel registration
  /// does not permanently skip the system permission dialogs.
  static Future<VoiceCapturePermissionResult?> _invokeMacosVoicePermissions({
    required bool requestSpeech,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final raw = await _macosChannel.invokeMethod<dynamic>(
          'requestVoicePermissions',
          <String, dynamic>{'requestSpeech': requestSpeech},
        );
        if (raw is Map) {
          final mic = raw['microphone'] == true;
          final speech = raw['speechRecognition']?.toString();
          debugPrint(
            '🎙️ macOS privacy: microphone=$mic speechRecognition=$speech '
            '(requestedSpeech=$requestSpeech)',
          );
          return VoiceCapturePermissionResult(
            microphoneGranted: mic,
            speechRecognitionStatus: speech,
          );
        }
        return null;
      } on MissingPluginException {
        await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
      } catch (e) {
        debugPrint('🎙️ macOS privacy request failed: $e');
        return null;
      }
    }
    return null;
  }
}

/// Camera permission for QR scan / photo capture on macOS and mobile.
class CameraCapturePermissions {
  CameraCapturePermissions._();

  static const _macosChannel = MethodChannel('lm_mini/macos_privacy');

  /// Shows the system camera dialog when undetermined. Returns whether access
  /// was granted.
  static Future<bool> ensureForCamera() async {
    if (kIsWeb) return true;

    if (Platform.isMacOS) {
      for (var attempt = 0; attempt < 8; attempt++) {
        try {
          final raw = await _macosChannel.invokeMethod<dynamic>(
            'requestCameraPermission',
          );
          if (raw is Map) {
            final granted = raw['camera'] == true;
            debugPrint(
              '📷 macOS privacy: camera=$granted status=${raw['status']}',
            );
            return granted;
          }
          return false;
        } on MissingPluginException {
          await Future<void>.delayed(
            Duration(milliseconds: 50 * (attempt + 1)),
          );
        } catch (e) {
          debugPrint('📷 macOS camera permission request failed: $e');
          return false;
        }
      }
      return false;
    }

    if (Platform.isIOS || Platform.isAndroid) {
      try {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
        }
        return status.isGranted;
      } on MissingPluginException {
        debugPrint('📷 permission_handler unavailable for camera request');
      } catch (e) {
        debugPrint('📷 Camera permission request failed: $e');
      }
    }

    // Other desktops — let the picker/scanner fail with a clear error later.
    return true;
  }
}
