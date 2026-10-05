import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/lm_studio_model.dart';

void main() {
  group('parseReasoningAllowedOptions', () {
    test('keeps off/on from LM Studio 0.4.8+ capabilities', () {
      expect(
        LMStudioModel.parseReasoningAllowedOptions({
          'trained_for_tool_use': true,
          'reasoning': {
            'allowed_options': ['off', 'on'],
            'default': 'on',
          },
        }),
        ['off', 'on'],
      );
    });

    test('keeps effort levels when the model lists them', () {
      expect(
        LMStudioModel.parseReasoningAllowedOptions({
          'reasoning': {
            'allowed_options': ['off', 'low', 'medium', 'high'],
          },
        }),
        ['off', 'low', 'medium', 'high'],
      );
    });

    test('treats modern V1 caps without a reasoning key as no API', () {
      expect(
        LMStudioModel.parseReasoningAllowedOptions({
          'trained_for_tool_use': false,
          'vision': false,
        }),
        isEmpty,
      );
    });

    test('leaves older servers without capabilities as unknown', () {
      expect(LMStudioModel.parseReasoningAllowedOptions(null), isNull);
      expect(LMStudioModel.parseReasoningAllowedOptions({}), isNull);
    });
  });

  test('fromV1Json stores allowed_options on the model', () {
    final model = LMStudioModel.fromV1Json({
      'key': 'qwen3.5-4b',
      'type': 'llm',
      'capabilities': {
        'trained_for_tool_use': true,
        'reasoning': {
          'allowed_options': ['off', 'on'],
          'default': 'on',
        },
      },
    });
    expect(model.reasoningAllowedOptions, ['off', 'on']);
    expect(model.isReasoningModel, isTrue);
  });

  test('fromV1Json marks Gemma-style V1 models as no reasoning API', () {
    final model = LMStudioModel.fromV1Json({
      'key': 'google/gemma-3-4b',
      'type': 'llm',
      'capabilities': {
        'trained_for_tool_use': false,
        'vision': false,
      },
    });
    expect(model.reasoningAllowedOptions, isEmpty);
    expect(model.isReasoningModel, isFalse);
  });
}
