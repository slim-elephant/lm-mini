import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/context_usage.dart';

void main() {
  test('counts thinking text while the reply has no server stats yet', () {
    final thinking = 'x' * 400;
    final used = ContextUsage.used(
      messages: [
        ContextUsageMessage(content: 'Hello'),
        ContextUsageMessage(content: '<think>$thinking</think>'),
      ],
    );
    // 5 chars of "Hello" plus 400 of thinking. The old meter skipped thinking.
    expect(used, greaterThan(100));
  });

  test('uses LM Studio tokens for a thinking-heavy reply', () {
    final used = ContextUsage.used(
      messages: [
        const ContextUsageMessage(content: 'What is 17 times 23?'),
        const ContextUsageMessage(
          content: '',
          inputTokens: 35,
          outputTokens: 255,
        ),
      ],
    );
    expect(used, 290);
  });

  test('continuation adds new prompt tokens and every output', () {
    final used = ContextUsage.used(
      messages: [
        const ContextUsageMessage(
          content: 'first',
          inputTokens: 35,
          outputTokens: 255,
        ),
        const ContextUsageMessage(
          content: '401',
          inputTokens: 58,
          outputTokens: 84,
        ),
      ],
    );
    // 290 + (58 - 35) + 84
    expect(used, 397);
  });

  test('full history resend replaces the running total', () {
    final used = ContextUsage.used(
      messages: [
        const ContextUsageMessage(
          content: 'a',
          inputTokens: 100,
          outputTokens: 20,
        ),
        const ContextUsageMessage(
          content: 'b',
          inputTokens: 130,
          outputTokens: 10,
        ),
      ],
    );
    expect(used, 140);
  });

  test('a smaller prompt starts a new count', () {
    final used = ContextUsage.used(
      messages: [
        const ContextUsageMessage(
          content: 'a',
          inputTokens: 35,
          outputTokens: 255,
        ),
        const ContextUsageMessage(
          content: 'b',
          inputTokens: 12,
          outputTokens: 4,
        ),
      ],
    );
    expect(used, 16);
  });

  test('draft and an in-progress reply sit on top of the server total', () {
    final used = ContextUsage.used(
      messages: [
        const ContextUsageMessage(
          content: 'done',
          inputTokens: 35,
          outputTokens: 255,
        ),
        ContextUsageMessage(content: '<think>${'y' * 40}'),
      ],
      draft: 'zzzz',
    );
    // 290 + 10 thinking tokens + 1 draft token
    expect(used, 301);
  });
}
