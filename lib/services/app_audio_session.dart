import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The one place that decides how the iPhone's shared audio session is set
/// up (native side: `AppDelegate.swift`, "Audio session (single owner)").
///
/// Two modes: listening (read aloud) and voice (mic + replies). Keeping a
/// voice session on one setup for its whole length, and returning to
/// listening afterwards, stops iOS from renegotiating the Bluetooth profile
/// every turn, which could move the reply to the loudspeaker while AirPods
/// stayed connected. No-ops off iOS.
class AppAudioSession {
  AppAudioSession._();
  static final AppAudioSession instance = AppAudioSession._();

  static const _channel = MethodChannel('net.neuro9.lmmini/audio_session');

  /// Test seam: treat this platform as iOS.
  @visibleForTesting
  static bool? debugIsIos;
  static bool get _isIos => debugIsIos ?? (!kIsWeb && Platform.isIOS);

  /// True while the mic is capturing. Set by the speech services, so
  /// playback never switches the session to listening-only mid-recording.
  bool Function()? isMicActive;

  bool _voiceMode = false;
  bool _logAttached = false;

  /// A voice chat is open (set by [enterVoiceMode], cleared by
  /// [leaveVoiceMode]).
  bool get inVoiceMode => _voiceMode;

  void _attachLog() {
    if (_logAttached) return;
    _logAttached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'log') debugPrint('🎧 Audio: ${call.arguments}');
    });
  }

  Future<bool> _invoke(String method) async {
    if (!_isIos) return true;
    _attachLog();
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      debugPrint('🎧 Audio: $method failed: $e');
      return false;
    }
  }

  /// Start (or switch) a voice chat. [callMode] adds echo cancellation.
  Future<bool> enterVoiceMode({required bool callMode}) {
    _voiceMode = true;
    return _invoke(
        callMode ? 'configureForVoiceChat' : 'configureForDictation');
  }

  /// The voice chat closed: other apps may resume, and the session returns
  /// to listening mode.
  Future<void> leaveVoiceMode() async {
    _voiceMode = false;
    await _invoke('deactivate');
  }

  /// Before the mic starts. Keeps the current voice mode, or uses dictation
  /// mode for a one-off recording outside a voice chat.
  Future<bool> prepareForRecording() => _invoke('activateForRecording');

  /// Before a spoken reply plays.
  ///
  /// In a voice chat the session stays in voice mode (re-asserted, which is
  /// free when nothing changed). Outside one, it is put in listening mode,
  /// unless the mic is capturing right now.
  Future<void> prepareForPlayback() async {
    if (!_isIos) return;
    if (_voiceMode) {
      await _invoke('reassert');
      return;
    }
    if (isMicActive?.call() ?? false) return;
    await _invoke('configureForPlayback');
  }
}
