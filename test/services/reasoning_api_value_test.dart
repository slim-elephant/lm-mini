import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/lm_studio_model.dart';
import 'package:lm_mini/services/lm_studio_service.dart';
import 'package:lm_mini/services/reasoning_support_service.dart';

void main() {
  void clearReasoningMemory() {
    ReasoningSupportService.instance.ingestCatalog([]);
  }

  group('reasoningApiValue', () {
    setUp(clearReasoningMemory);
    tearDown(clearReasoningMemory);

    test('sends off when user setting is off', () {
      final settings = AppSettings(
        reasoning: 'off',
        selectedModel: 'qwen3-0.6b',
      );
      expect(
        LMStudioService.reasoningApiValue(settings, 'qwen3-0.6b'),
        'off',
      );
    });

    test('sends off even on reasoning-style model names', () {
      final settings = AppSettings(
        reasoning: 'off',
        selectedModel: 'qwq-32b',
      );
      expect(
        LMStudioService.reasoningApiValue(settings, 'qwq-32b'),
        'off',
      );
    });

    test('sends level when user enabled reasoning', () {
      final settings = AppSettings(
        reasoning: 'medium',
        selectedModel: 'deepseek-r1-distill',
      );
      expect(
        LMStudioService.reasoningApiValue(settings, 'deepseek-r1-distill'),
        'medium',
      );
    });

    test('sends on when chat toggle enables reasoning', () {
      final settings = AppSettings(
        reasoning: 'on',
        selectedModel: 'gemma-4-e4b',
      );
      expect(
        LMStudioService.reasoningApiValue(settings, 'gemma-4-e4b'),
        'on',
      );
    });

    test('catalog off/on-only maps medium to on without a 400', () {
      ReasoningSupportService.instance.ingestCatalog([
        LMStudioModel(
          id: 'qwen3.5-4b',
          object: 'model',
          type: 'llm',
          publisher: '',
          arch: '',
          compatibilityType: 'gguf',
          quantization: '',
          state: 'not-loaded',
          maxContextLength: 4096,
          reasoningAllowedOptions: const ['off', 'on'],
        ),
      ]);
      addTearDown(() => ReasoningSupportService.instance.ingestCatalog([]));
      final settings = AppSettings(
        reasoning: 'medium',
        selectedModel: 'qwen3.5-4b',
      );
      expect(
        LMStudioService.reasoningApiValue(settings, 'qwen3.5-4b'),
        'on',
      );
      expect(
        LMStudioService.reasoningApiValue(
          settings.copyWith(reasoning: 'off'),
          'qwen3.5-4b',
        ),
        'off',
      );
    });

    test('catalog with no reasoning API omits the field', () {
      ReasoningSupportService.instance.ingestCatalog([
        LMStudioModel(
          id: 'google/gemma-3-4b',
          object: 'model',
          type: 'llm',
          publisher: '',
          arch: '',
          compatibilityType: 'gguf',
          quantization: '',
          state: 'not-loaded',
          maxContextLength: 8192,
          reasoningAllowedOptions: const [],
        ),
      ]);
      addTearDown(() => ReasoningSupportService.instance.ingestCatalog([]));
      final settings = AppSettings(
        reasoning: 'off',
        selectedModel: 'google/gemma-3-4b',
      );
      expect(
        LMStudioService.reasoningApiValue(settings, 'google/gemma-3-4b'),
        isNull,
      );
    });
  });

  group('ReasoningSupportService retry', () {
    const offOnError =
        "Reasoning setting 'medium' is not supported. Supported settings: 'off', 'on'.";
    const exposeError =
        'The model does not expose reasoning configuration.';

    test('detects off/on-only 400s that omit invalid/param', () {
      expect(
        ReasoningSupportService.isReasoningConfigError(offOnError),
        isTrue,
      );
    });

    test('detects does-not-expose 400s', () {
      expect(
        ReasoningSupportService.isReasoningConfigError(exposeError),
        isTrue,
      );
    });

    test('parses Supported settings from the 400 message', () {
      expect(
        ReasoningSupportService.parseSupportedSettings(offOnError),
        ['off', 'on'],
      );
    });

    test('maps medium to on when the model only lists off/on', () {
      expect(
        ReasoningSupportService.retryApiValue('medium', offOnError),
        'on',
      );
      expect(
        ReasoningSupportService.retryApiValue('low', offOnError),
        'on',
      );
      expect(
        ReasoningSupportService.retryApiValue('off', offOnError),
        'off',
      );
    });

    test('omits the field when the model has no reasoning API', () {
      expect(
        ReasoningSupportService.retryApiValue('off', exposeError),
        isNull,
      );
      expect(
        ReasoningSupportService.retryApiValue('on', exposeError),
        isNull,
      );
    });

    test('reads Supported settings from nested HTTP error maps', () {
      final error = {
        'error': {
          'message':
              "Reasoning setting 'low' is not supported. Supported settings: 'off', 'on'.",
        },
      };
      expect(
        ReasoningSupportService.retryApiValue('low', error),
        'on',
      );
    });

    test('treats off/on lists as on-off-only', () {
      expect(
        ReasoningSupportService.isOnOffOnlyList(['off', 'on']),
        isTrue,
      );
      expect(
        ReasoningSupportService.isOnOffOnlyList(['off', 'on', 'low']),
        isFalse,
      );
    });
  });
}
