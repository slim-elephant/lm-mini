import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini_premium/src/cloud_model_capabilities.dart';

void main() {
  group('capabilitiesFromOpenAiEntry', () {
    test('oMLX /v1/models payload without capabilities is not vision', () {
      final caps = capabilitiesFromOpenAiEntry({
        'id': 'Llama-3.2-1B-Instruct-4bit',
        'object': 'model',
        'owned_by': 'omlx',
        'max_model_len': 131072,
      });
      expect(caps.vision, isFalse);
    });

    test('reads model_type vlm when present', () {
      final caps = capabilitiesFromOpenAiEntry({
        'id': 'some-custom-name',
        'model_type': 'vlm',
      });
      expect(caps.vision, isTrue);
    });

    test('treats gemma-3-4b as vision by name', () {
      final caps = capabilitiesFromOpenAiEntry({
        'id': 'gemma-3-4b-it-qat-4bit',
      });
      expect(caps.vision, isTrue);
    });

    test('does not treat gemma-3-1b as vision', () {
      final caps = capabilitiesFromOpenAiEntry({
        'id': 'gemma-3-1b-it',
      });
      expect(caps.vision, isFalse);
    });
  });

  group('capabilitiesFromOmlxStatus', () {
    test('maps model_type llm to no vision', () {
      final caps = capabilitiesFromOmlxStatus({
        'id': 'Llama-3.2-1B-Instruct-4bit',
        'model_type': 'llm',
        'engine_type': 'batched',
      });
      expect(caps.vision, isFalse);
    });

    test('maps model_type vlm to vision', () {
      final caps = capabilitiesFromOmlxStatus({
        'id': 'gemma-3-4b-it-qat-4bit',
        'model_type': 'vlm',
        'engine_type': 'vlm',
      });
      expect(caps.vision, isTrue);
    });
  });
}
