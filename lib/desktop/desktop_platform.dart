import 'dart:io';

import 'package:flutter/foundation.dart';

/// Desktop-only gates. Phone builds never enable host / sidecar code paths.
class DesktopPlatform {
  DesktopPlatform._();

  /// True on macOS or Windows desktop (not iOS/Android/web).
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// User-facing noun for this machine in host UI copy.
  static String get thisMachine {
    if (isWindows) return 'this PC';
    if (!kIsWeb && Platform.isLinux) return 'this computer';
    return 'this Mac';
  }

  /// Host mode (Share with phone) on Mac and Windows Home.
  static bool get supportsHostMode => isMacOS || isWindows;

  /// Desktop-class sidecar inference (not phone fllama).
  static bool get supportsSidecarRuntime => isMacOS || isWindows;

  /// True under App Sandbox (Mac App Store / Xcode Runner entitlements).
  /// Direct-download builds re-sign with [Distribution.entitlements] (no sandbox).
  static bool get isMacAppSandboxed {
    if (!isMacOS) return false;
    return Platform.environment.containsKey('APP_SANDBOX_CONTAINER_ID');
  }

  /// Sandboxed Mac builds must use Whisper for listening — system STT can
  /// hard-crash via `speech_to_text`. Unsandboxed Mac allows system STT.
  static bool get macListeningRequiresWhisper => isMacAppSandboxed;
}
