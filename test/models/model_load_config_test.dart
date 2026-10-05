import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/lm_studio_model.dart';
import 'package:lm_mini/models/model_load_config.dart';

LMStudioModel _model({
  String state = 'loaded',
  int? loadedContextLength = 7680,
}) {
  return LMStudioModel(
    id: 'gemma-4-e2b-it',
    object: 'model',
    type: 'llm',
    publisher: 'google',
    arch: 'gemma',
    compatibilityType: 'gguf',
    quantization: 'Q4',
    state: state,
    maxContextLength: 131072,
    loadedContextLength: loadedContextLength,
  );
}

void main() {
  group('formatTokenCount', () {
    test('keeps small counts raw', () {
      expect(ModelLoadConfigHelper.formatTokenCount(512), '512');
    });

    test('uses one decimal under 10K', () {
      expect(ModelLoadConfigHelper.formatTokenCount(7680), '7.5K');
    });

    test('rounds whole K at 10K+', () {
      expect(ModelLoadConfigHelper.formatTokenCount(131072), '128K');
    });
  });

  group('shouldOfferContextReload', () {
    test('offers when LM Studio loaded n_ctx differs from Mini', () {
      expect(
        ModelLoadConfigHelper.shouldOfferContextReload(
          providerKind: 'lmStudio',
          model: _model(loadedContextLength: 7680),
          desiredContextLength: 32768,
        ),
        isTrue,
      );
    });

    test('skips when loaded n_ctx already matches', () {
      expect(
        ModelLoadConfigHelper.shouldOfferContextReload(
          providerKind: 'lmStudio',
          model: _model(loadedContextLength: 7680),
          desiredContextLength: 7680,
        ),
        isFalse,
      );
    });

    test('skips when the model is not loaded', () {
      expect(
        ModelLoadConfigHelper.shouldOfferContextReload(
          providerKind: 'lmStudio',
          model: _model(state: 'not-loaded', loadedContextLength: null),
          desiredContextLength: 32768,
        ),
        isFalse,
      );
    });

    test('skips Ollama / cloud / on-device', () {
      expect(
        ModelLoadConfigHelper.shouldOfferContextReload(
          providerKind: 'ollama',
          model: _model(),
          desiredContextLength: 32768,
        ),
        isFalse,
      );
    });

    test('skips when LM Studio did not echo loaded context', () {
      expect(
        ModelLoadConfigHelper.shouldOfferContextReload(
          providerKind: 'lmStudio',
          model: _model(loadedContextLength: null),
          desiredContextLength: 32768,
        ),
        isFalse,
      );
    });
  });
}
