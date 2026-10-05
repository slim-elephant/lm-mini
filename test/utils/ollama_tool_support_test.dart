import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/ollama_tool_support.dart';

void main() {
  group('OllamaToolSupport.heuristic', () {
    test('known tool families are allowed', () {
      expect(OllamaToolSupport.heuristic('qwen2.5:7b'), isTrue);
      expect(OllamaToolSupport.heuristic('llama3.1:8b'), isTrue);
      expect(OllamaToolSupport.heuristic('mistral:latest'), isTrue);
      expect(OllamaToolSupport.heuristic('deepseek-r1:7b'), isTrue);
    });

    test('coder and vision models are denied', () {
      expect(OllamaToolSupport.heuristic('deepseek-coder:6.7b'), isFalse);
      expect(OllamaToolSupport.heuristic('codellama:13b'), isFalse);
      expect(OllamaToolSupport.heuristic('llava:7b'), isFalse);
      expect(OllamaToolSupport.heuristic('codegemma:7b'), isFalse);
    });

    test('unknown models default off', () {
      expect(OllamaToolSupport.heuristic('tinyllama:1.1b'), isFalse);
      expect(OllamaToolSupport.heuristic('phi:2.7b'), isFalse);
      expect(OllamaToolSupport.heuristic(null), isFalse);
      expect(OllamaToolSupport.heuristic(''), isFalse);
    });
  });

  group('OllamaToolSupport.fromShowCapabilities', () {
    test('trusts a non-empty capabilities list even when heuristic would allow',
        () {
      expect(
        OllamaToolSupport.fromShowCapabilities(
          capabilities: const ['completion', 'insert'],
          modelId: 'qwen2.5:7b',
        ),
        isFalse,
      );
    });

    test('tools capability wins', () {
      expect(
        OllamaToolSupport.fromShowCapabilities(
          capabilities: const ['completion', 'tools'],
          modelId: 'deepseek-coder:6.7b',
        ),
        isTrue,
      );
    });

    test('empty capabilities fall back to the name heuristic', () {
      expect(
        OllamaToolSupport.fromShowCapabilities(
          capabilities: const [],
          modelId: 'deepseek-coder:6.7b',
        ),
        isFalse,
      );
      expect(
        OllamaToolSupport.fromShowCapabilities(
          capabilities: const [],
          modelId: 'qwen2.5:7b',
        ),
        isTrue,
      );
    });
  });
}
