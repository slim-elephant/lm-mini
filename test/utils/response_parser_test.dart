import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/response_parser.dart';

void main() {
  group('ResponseParser Gemma 4 channel', () {
    test('splits <|channel>thought … <channel|> from answer', () {
      const raw = '''
<|channel>thought
The user asked about Paris. Capital of France.
<channel|>
Paris is the capital of France.
''';
      final parsed = ResponseParser.parse(raw);
      expect(parsed.thinking, contains('Capital of France'));
      expect(parsed.answer, contains('Paris is the capital'));
      expect(parsed.answer, isNot(contains('<|channel>')));
      expect(parsed.answer, isNot(contains('<channel|>')));
    });

    test('handles open channel while streaming', () {
      const raw = '''
<|channel>thought
Still thinking about the problem
''';
      final parsed = ResponseParser.parse(raw);
      expect(parsed.thinking, contains('Still thinking'));
      expect(parsed.answer, isEmpty);
    });

    test('answerOnly strips Gemma thinking', () {
      const raw = '<|channel>thought\nsecret plan\n<channel|>\nVisible answer';
      expect(ResponseParser.answerOnly(raw), 'Visible answer');
    });

    test('stripHiddenModelTags removes IMG_PROMPT from list text', () {
      expect(
        ResponseParser.stripHiddenModelTags(
          '[IMG_PROMPT: Pakistani woman in a car]\nDrive safe',
        ),
        'Drive safe',
      );
      expect(
        ResponseParser.stripHiddenModelTags('[IMG_PROMPT: Pakistani woma...'),
        isEmpty,
      );
      final both = ResponseParser.stripHiddenModelTags(
        'Hello [IMG_PROMPT: one]\n[IMG_PROMPT: two] there',
      );
      expect(both.contains('IMG_PROMPT'), isFalse);
      expect(both, contains('Hello'));
      expect(both, contains('there'));
    });
  });

  group('ResponseParser classic tags', () {
    test('parses <think> blocks', () {
      final parsed =
          ResponseParser.parse('<think>step one</think>\nHello there');
      expect(parsed.thinking, 'step one');
      expect(parsed.answer, 'Hello there');
    });
  });
}
