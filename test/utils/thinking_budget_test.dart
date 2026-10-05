import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/thinking_budget.dart';

void main() {
  const lengthStats = {
    'stop_reason': 'max_output_tokens',
    'reasoning_output_tokens': 2000,
    'total_output_tokens': 2048,
  };

  group('ThinkingBudget.shouldRetryWithLowEffort', () {
    test('retries when high thinking hits the output cap', () {
      expect(
        ThinkingBudget.shouldRetryWithLowEffort(
          reasoning: 'high',
          stats: lengthStats,
          maxTokens: 2048,
          answerEmpty: true,
          hadReasoning: true,
        ),
        isTrue,
      );
    });

    test('treats On as high effort', () {
      expect(
        ThinkingBudget.shouldRetryWithLowEffort(
          reasoning: 'on',
          stats: lengthStats,
          maxTokens: 2048,
          answerEmpty: true,
          hadReasoning: true,
        ),
        isTrue,
      );
    });

    test('does not retry medium or low effort', () {
      for (final effort in ['medium', 'low', 'off']) {
        expect(
          ThinkingBudget.shouldRetryWithLowEffort(
            reasoning: effort,
            stats: lengthStats,
            maxTokens: 2048,
            answerEmpty: true,
            hadReasoning: true,
          ),
          isFalse,
          reason: effort,
        );
      }
    });

    test('does not retry a normal end after a short trace', () {
      expect(
        ThinkingBudget.shouldRetryWithLowEffort(
          reasoning: 'high',
          stats: const {
            'stop_reason': 'eos',
            'reasoning_output_tokens': 40,
            'total_output_tokens': 40,
          },
          maxTokens: 2048,
          answerEmpty: true,
          hadReasoning: true,
        ),
        isFalse,
      );
    });

    test('does not retry without stats or when an answer exists', () {
      expect(
        ThinkingBudget.shouldRetryWithLowEffort(
          reasoning: 'high',
          stats: null,
          maxTokens: 2048,
          answerEmpty: true,
          hadReasoning: true,
        ),
        isFalse,
      );
      expect(
        ThinkingBudget.shouldRetryWithLowEffort(
          reasoning: 'high',
          stats: lengthStats,
          maxTokens: 2048,
          answerEmpty: false,
          hadReasoning: true,
        ),
        isFalse,
      );
    });

    test('on/off models retry with off instead of low', () {
      expect(
        ThinkingBudget.retryEffort('high', const ['off', 'on']),
        'off',
      );
      expect(
        ThinkingBudget.retryEffort('on', const ['on']),
        isNull,
      );
    });

    test('retries when reasoning tokens fill the configured cap', () {
      expect(
        ThinkingBudget.consumedByThinking(
          stats: const {
            'reasoning_output_tokens': 1900,
            'total_output_tokens': 1980,
          },
          maxTokens: 2048,
          hadReasoning: true,
        ),
        isTrue,
      );
    });
  });
}
