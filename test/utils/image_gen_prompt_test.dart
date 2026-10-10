import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/image_gen_prompt.dart';
import 'package:lm_mini/utils/response_parser.dart';

void main() {
  group('image gen prompt helpers', () {
    test('appends turn reminder once', () {
      const user = 'Hello there';
      final once = appendImageGenTurnReminder(user, enabled: true);
      expect(once, contains('[IMAGE_GEN_INSTRUCTION]'));
      expect(once, contains('[IMG_PROMPT:'));
      final twice = appendImageGenTurnReminder(once, enabled: true);
      expect(twice, once);
      expect(appendImageGenTurnReminder(user, enabled: false), user);
    });

    test('appends reminder to vision text part', () {
      final input = [
        {'type': 'text', 'content': 'a photo'},
        {'type': 'image', 'data_url': 'data:image/png;base64,xx'},
      ];
      final updated = withImageGenTurnReminder(input, enabled: true) as List;
      expect(updated[0]['content'], contains('[IMAGE_GEN_INSTRUCTION]'));
      expect(updated[1]['data_url'], 'data:image/png;base64,xx');
    });

    test('re-attaches stored image prompt at the start of history turns', () {
      expect(
        assistantTurnForHistory('Nice sunset.', 'sunset, ocean, cinematic'),
        '[IMG_PROMPT: sunset, ocean, cinematic]\nNice sunset.',
      );
      expect(
        assistantTurnForHistory(
          '[IMG_PROMPT: already]\nNice sunset.',
          'sunset',
        ),
        '[IMG_PROMPT: already]\nNice sunset.',
      );
    });

    test('extracts tag from reasoning when the message has none', () {
      final result = extractImagePromptFromAssistant(
        message: 'Here is the scene.',
        reasoning: 'I should hide [IMG_PROMPT: cat, sitting, window]',
      );
      expect(result.imagePrompt, 'cat, sitting, window');
      expect(result.cleanContent, 'Here is the scene.');
    });

    test('prefers the tag in the visible message', () {
      final result = extractImagePromptFromAssistant(
        message: '[IMG_PROMPT: dog, park]\nCute dog.',
        reasoning: '[IMG_PROMPT: ignored]',
      );
      expect(result.imagePrompt, 'dog, park');
      expect(result.cleanContent, 'Cute dog.');
    });

    test('system instruction asks for the tag at the start', () {
      final sys = applyImageGenInstructionToSystem(
        'You are helpful.',
        enabled: true,
      );
      expect(sys, contains('start your written answer'));
      expect(extractImagePrompt('[IMG_PROMPT: a, b]\nHello').imagePrompt, 'a, b');
    });

    test('instructions let the model call tools before the tag', () {
      // A model that starts writing the tag has committed to text and will
      // never call web search, so tools must be allowed first.
      expect(
        applyImageGenInstructionToSystem('You are helpful.', enabled: true),
        contains('call it first'),
      );
      expect(
        appendImageGenTurnReminder('check solana price', enabled: true),
        contains('Use any tool you need first'),
      );
    });

    test('does not inject instruction when image generation is off', () {
      expect(
        applyImageGenInstructionToSystem('You are helpful.', enabled: false),
        'You are helpful.',
      );
      expect(
        withImageGenTurnReminder('Hello', enabled: false),
        'Hello',
      );
    });
  });
}
