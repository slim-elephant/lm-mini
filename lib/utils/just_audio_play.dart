import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_session_busy_error.dart';

/// Play a TTS clip. If the mic still holds the iOS session, skip instead of
/// throwing an uncaught [PlatformException] from an unawaited `play()`.
Future<void> playTtsClip(AudioPlayer player) async {
  try {
    await player.play();
  } catch (e) {
    if (AudioSessionBusyError.matches(e)) {
      debugPrint(
        '⚠️ TTS play skipped — audio session busy (mic still active)',
      );
      return;
    }
    rethrow;
  }
}
