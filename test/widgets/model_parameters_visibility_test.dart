import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/widgets/model_parameters_form.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

void main() {
  group('ModelParametersVisibility.reasoning', () {
    test('llama.cpp OpenAI-compat Qwen shows reasoning on Global params', () {
      const id = '/Users/me/.lmstudio/models/lmstudio-community/'
          'Qwen3.5-4B-GGUF/Qwen3.5-4B-Q4_K_M.gguf';
      final v = ModelParametersVisibility.resolve(
        providerKind: 'cloud',
        providerType: CloudApiType.openaiCompatible,
        isCloudRouted: true,
        modelId: id,
      );
      expect(v.showReasoning, isTrue);
      expect(v.useOnOffReasoning, isTrue);
      expect(v.isCloudReasoning, isFalse);
    });

    test('OpenAI-compat llama 3.1 does not show thinking controls', () {
      final v = ModelParametersVisibility.resolve(
        providerKind: 'cloud',
        providerType: CloudApiType.openaiCompatible,
        isCloudRouted: true,
        modelId: 'llama-3.1-8b-instruct',
      );
      expect(v.showReasoning, isFalse);
    });

    test('GPT-5 OpenAI provider still uses effort dropdown, not on/off', () {
      final v = ModelParametersVisibility.resolve(
        providerKind: 'cloud',
        providerType: CloudApiType.openai,
        isCloudRouted: true,
        modelId: 'gpt-5',
      );
      expect(v.showReasoning, isTrue);
      expect(v.isCloudReasoning, isTrue);
      expect(v.useOnOffReasoning, isFalse);
    });

    test('LM Studio / llama-server URL still shows reasoning', () {
      final v = ModelParametersVisibility.resolve(
        providerKind: 'lmStudio',
        providerType: null,
        isCloudRouted: false,
        modelId: 'Qwen3.6-27B',
      );
      expect(v.showReasoning, isTrue);
      expect(v.useOnOffReasoning, isFalse);
    });

    test('Ollama Qwen shows on/off think (not LM Studio levels)', () {
      final v = ModelParametersVisibility.resolve(
        providerKind: 'ollama',
        providerType: CloudApiType.ollama,
        isCloudRouted: true,
        modelId: 'qwen3.5:4b',
      );
      expect(v.showReasoning, isTrue);
      expect(v.useOnOffReasoning, isTrue);
    });

    test('Home sidecar llama-server uses on/off think', () {
      final v = ModelParametersVisibility.resolve(
        providerKind: 'lmMiniDesktop',
        providerType: null,
        isCloudRouted: false,
        modelId: 'Qwen3.5-4B',
      );
      expect(v.showReasoning, isTrue);
      expect(v.useOnOffReasoning, isTrue);
    });
  });
}
