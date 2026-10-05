import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/chat_message_normalizer.dart';

void main() {
  group('ChatMessageNormalizer', () {
    test('coalesce merges mid-history system into a single leading system', () {
      final out = ChatMessageNormalizer.coalesceSystemMessages([
        {'role': 'system', 'content': 'You are helpful.'},
        {'role': 'user', 'content': 'Weather?'},
        {'role': 'assistant', 'content': 'Searching...'},
        {
          'role': 'system',
          'content': 'Here are the web search results:\n\nBangkok 32C'
        },
        {'role': 'user', 'content': 'Answer based on results.'},
      ]);

      expect(out.first['role'], 'system');
      expect(out.where((m) => m['role'] == 'system').length, 1);
      expect(
        out.first['content'],
        contains('Here are the web search results'),
      );
      expect(out.map((m) => m['role']).toList(), [
        'system',
        'user',
        'assistant',
        'user',
      ]);
    });

    test('injectMemoryContext never creates a second system role', () {
      final out = ChatMessageNormalizer.injectMemoryContext([
        {'role': 'system', 'content': 'You are helpful.'},
        {'role': 'user', 'content': 'Where do I live?'},
      ], '--- User Memory ---\n- Lives in Bangkok');

      expect(out.where((m) => m['role'] == 'system').length, 1);
      expect(out.first['role'], 'system');
      expect(out.first['content'], contains('You are helpful.'));
      expect(out.first['content'], contains('Lives in Bangkok'));
    });

    test('strictTurnOrder merges consecutive turns of the same role', () {
      final out = ChatMessageNormalizer.strictTurnOrder([
        (role: 'system', content: 'You are helpful.'),
        (role: 'user', content: 'First'),
        (role: 'user', content: 'Second'),
        (role: 'assistant', content: 'Reply'),
        (role: 'tool', content: 'tool output'),
        (role: 'assistant', content: 'Starts the chat'),
        (role: 'user', content: 'Next'),
      ]);

      expect(out.map((m) => m.role).toList(), [
        'system',
        'user',
        'assistant',
        'user',
      ]);
      expect(out[1].content, 'First\n\nSecond');
      expect(out[2].content, contains('tool output'));
      expect(out[2].content, contains('Starts the chat'));
    });

    test(
        'strictTurnOrder inserts a user turn when history starts with assistant',
        () {
      final out = ChatMessageNormalizer.strictTurnOrder([
        (role: 'assistant', content: 'Welcome'),
        (role: 'user', content: 'Hi'),
      ]);

      expect(out.map((m) => m.role).toList(), ['user', 'assistant', 'user']);
      expect(out.first.content.trim(), isEmpty);
    });

    test('strictTurnOrder leaves a normal system plus user chat alone', () {
      final out = ChatMessageNormalizer.strictTurnOrder([
        (role: 'system', content: 'You are helpful.'),
        (role: 'user', content: 'Hi'),
      ]);

      expect(out.map((m) => m.role).toList(), ['system', 'user']);
      expect(out.last.content, 'Hi');
    });

    test('detects Qwen system-order error strings', () {
      expect(
        ChatMessageNormalizer.isSystemMessageOrderError(
          'Unable to generate parser... System message must be at the beginning.',
        ),
        isTrue,
      );
      expect(
        ChatMessageNormalizer.isSystemMessageOrderError('context overflow'),
        isFalse,
      );
    });
  });
}
