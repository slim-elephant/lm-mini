import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/audio_session_busy_error.dart';

void main() {
  group('AudioSessionBusyError', () {
    test('matches the iOS just_audio CannotInterruptOthers failure', () {
      const raw =
          'PlatformException(561017449, The operation couldn’t be completed. '
          '(OSStatus error 561017449.), null, null)';
      expect(AudioSessionBusyError.matches(raw), isTrue);
    });

    test('does not match an unrelated platform exception', () {
      expect(
        AudioSessionBusyError.matches(
            'PlatformException(error, boom, null, null)'),
        isFalse,
      );
    });
  });
}
