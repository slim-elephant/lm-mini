import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/stt_recognition_result.dart';
import 'package:lm_mini/utils/voice_stt_send_logic.dart';

void main() {
  group('VoiceSttSendLogic', () {
    late List<String> sent;
    late String display;
    late VoiceSttSendLogic logic;

    setUp(() {
      sent = [];
      display = '';
      logic = VoiceSttSendLogic(
        onSend: sent.add,
        onDisplayTextChanged: (text) => display = text,
      );
    });

    tearDown(() => logic.dispose());

    SttRecognitionResult interim(String text) =>
        SttRecognitionResult(recognizedWords: text, finalResult: false);
    SttRecognitionResult finalResult(String text) =>
        SttRecognitionResult(recognizedWords: text, finalResult: true);

    test('sends single phrase once after silence', () {
      fakeAsync((async) {
        logic.handleResult(interim('Hello, how are you'), 2);
        logic.handleResult(finalResult('Hello, how are you doing?'), 2);
        async.elapse(const Duration(seconds: 3));
        expect(sent, ['Hello, how are you doing?']);
      });
    });

    test('does not duplicate identical re-decoded final', () {
      fakeAsync((async) {
        logic.handleResult(finalResult('Hello.'), 2);
        logic.handleResult(finalResult('Hello.'), 2);
        logic.handleResult(finalResult('hello'), 2);
        async.elapse(const Duration(seconds: 3));
        expect(sent, ['Hello.']);
      });
    });

    test('does not duplicate phrase across commit + session restart', () {
      fakeAsync((async) {
        logic.handleResult(interim('Hello, how are you doing?'), 2);
        logic.commitSession();
        // New mic session re-decodes overlapping audio.
        logic.handleResult(interim('Hello, how are you doing?'), 2);
        async.elapse(const Duration(seconds: 3));
        expect(sent, ['Hello, how are you doing?']);
        expect(display, 'Hello, how are you doing?');
      });
    });

    test('collapses repeated hallucinated finals when merging', () {
      fakeAsync((async) {
        logic.handleResult(finalResult('Your message appears repeated.'), 2);
        logic.handleResult(finalResult('Your message appears repeated!'), 2);
        async.elapse(const Duration(seconds: 3));
        expect(sent, ['Your message appears repeated.']);
      });
    });

    test('still appends genuinely new speech', () {
      fakeAsync((async) {
        logic.handleResult(finalResult('Hello.'), 2);
        logic.handleResult(finalResult('What is the weather today?'), 2);
        async.elapse(const Duration(seconds: 3));
        expect(sent, ['Hello. What is the weather today?']);
      });
    });

    test('notifySpeechActivity keeps send timer alive', () {
      fakeAsync((async) {
        logic.handleResult(finalResult('Hello, how are you doing?'), 3);
        // 2 seconds later the user is still talking (amplitude activity)
        // but no new text has been decoded yet.
        async.elapse(const Duration(seconds: 2));
        expect(sent, isEmpty, reason: 'should not send yet');
        logic.notifySpeechActivity(3);
        // Another 2 seconds — still within 3s of the activity notification.
        async.elapse(const Duration(seconds: 2));
        expect(sent, isEmpty, reason: 'activity reset the timer');
        // Now let the full 3s silence elapse with no more activity.
        async.elapse(const Duration(seconds: 3));
        expect(sent, ['Hello, how are you doing?']);
      });
    });

    test('multi-sentence turn sends as one message after silence', () {
      fakeAsync((async) {
        logic.handleResult(interim('Hello'), 3);
        async.elapse(const Duration(milliseconds: 1500));
        logic.handleResult(interim('Hello, how are you'), 3);
        async.elapse(const Duration(milliseconds: 1500));
        // Silence timer from Whisper fires — emits final but buffer stays
        logic.handleResult(finalResult('Hello, how are you doing?'), 3);
        // Simulate the user pausing 2s then continuing
        async.elapse(const Duration(seconds: 2));
        logic.notifySpeechActivity(3); // amplitude detected
        async.elapse(const Duration(milliseconds: 1500));
        // New sentence decoded
        logic.handleResult(
          interim('Hello, how are you doing? I need help with something.'),
          3,
        );
        // Let silence timer expire — should send the full multi-sentence turn
        async.elapse(const Duration(seconds: 4));
        expect(sent, hasLength(1));
        expect(sent.first, contains('Hello'));
        expect(sent.first, contains('help with something'));
      });
    });
  });
}
