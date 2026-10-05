import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/arena_models.dart';
import 'package:lm_mini/models/lm_studio_model.dart';

void main() {
  group('looksLikeReasoningModel', () {
    test('detects Qwen 3 / 3.5 / 3.6 including llama-server path ids', () {
      const path = '/Users/me/.lmstudio/models/DavidAU/'
          'Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF/'
          'Qwen3.6-27B-Fable-Fus-711-UnHeretic-NM-DAU-NEO-MAX-NEO-MTP-Q5_K_S.gguf';
      expect(ArenaContestant.looksLikeReasoningModel(path), isTrue);
      expect(
        ArenaContestant.looksLikeReasoningModel('qwen3.5-4b-instruct'),
        isTrue,
      );
      expect(ArenaContestant.looksLikeReasoningModel('Qwen3-8B'), isTrue);
      expect(
        ArenaContestant.looksLikeReasoningModel('lmstudio-community/qwen3-14b'),
        isTrue,
      );
    });

    test('does not treat Qwen2.5 or generic instruct as thinking', () {
      expect(
        ArenaContestant.looksLikeReasoningModel('qwen2.5-7b-instruct'),
        isFalse,
      );
      expect(
        ArenaContestant.looksLikeReasoningModel('llama-3.1-8b-instruct'),
        isFalse,
      );
    });

    test('still matches explicit thinking names and o-series', () {
      expect(
        ArenaContestant.looksLikeReasoningModel('deepseek-r1-distill-qwen-7b'),
        isTrue,
      );
      expect(ArenaContestant.looksLikeReasoningModel('o3-mini'), isTrue);
      expect(ArenaContestant.looksLikeReasoningModel('gpt-oss-20b'), isTrue);
    });
  });

  group('LMStudioModel.parseListResponse', () {
    test('parses llama.cpp OpenAI /v1/models payloads', () {
      final models = LMStudioModel.parseListResponse({
        'object': 'list',
        'data': [
          {
            'id':
                'Qwen3.6-27B-Fable-Fus-711-UnHeretic-NM-DAU-NEO-MAX-NEO-MTP-Q5_K_S.gguf',
            'object': 'model',
            'owned_by': 'llamacpp',
          },
        ],
      });
      expect(models, hasLength(1));
      expect(models.first.id, contains('Qwen3.6'));
      expect(
        ArenaContestant.looksLikeReasoningModel(
          models.first.id,
          models.first.displayName,
        ),
        isTrue,
      );
    });

    test('parses llama.cpp dual models+data payload and vision caps', () {
      final models = LMStudioModel.parseListResponse({
        'models': [
          {
            'name': '/models/Qwen3.6-27B.gguf',
            'capabilities': ['completion', 'multimodal'],
          },
        ],
        'object': 'list',
        'data': [
          {
            'id': '/models/Qwen3.6-27B.gguf',
            'object': 'model',
            'owned_by': 'llamacpp',
          },
        ],
      });
      expect(models, hasLength(1));
      expect(models.single.supportsVision, isTrue);
    });

    test('parses LM Studio V1 {models:[{key}]} payloads', () {
      final models = LMStudioModel.parseListResponse({
        'models': [
          {
            'key': 'qwen/qwen3.6-27b',
            'type': 'llm',
            'publisher': 'qwen',
            'architecture': 'qwen3',
            'format': 'gguf',
            'quantization': <String, dynamic>{},
            'capabilities': <String, dynamic>{},
            'loaded_instances': <dynamic>[],
          },
        ],
      });
      expect(models.single.id, 'qwen/qwen3.6-27b');
      expect(models.single.supportsVision, isFalse);
    });

    test('visionFromProps reads llama.cpp modalities', () {
      expect(
        LMStudioModel.visionFromProps({
          'modalities': {'vision': true, 'audio': false},
        }),
        isTrue,
      );
      expect(
        LMStudioModel.visionFromProps({
          'modalities': {'vision': false},
        }),
        isFalse,
      );
    });

    test('isNativeLmStudioModelsPayload skips llama-server V1 shims', () {
      expect(
        LMStudioModel.isNativeLmStudioModelsPayload({
          'models': [
            {
              'key': 'qwen/qwen3.6-27b',
              'architecture': 'qwen3',
              'publisher': 'qwen',
            },
          ],
        }),
        isTrue,
      );
      expect(
        LMStudioModel.isNativeLmStudioModelsPayload({
          'models': [
            {
              'key': '/models/Qwen3.6-27B.gguf',
              'architecture': '',
              'publisher': 'llamacpp',
            },
          ],
        }),
        isFalse,
      );
      expect(
        LMStudioModel.isNativeLmStudioModelsPayload({
          'object': 'list',
          'data': [
            {'id': 'Qwen3.6-27B.gguf', 'owned_by': 'llamacpp'},
          ],
        }),
        isFalse,
      );
    });
  });

  group('looksLikeVisionModel', () {
    test('matches VL family names, not this Qwen3.6 text id', () {
      expect(
        ArenaContestant.looksLikeVisionModel('qwen2.5-vl-7b-instruct'),
        isTrue,
      );
      expect(ArenaContestant.looksLikeVisionModel('llava-v1.6-34b'), isTrue);
      expect(
        ArenaContestant.looksLikeVisionModel(
          'Qwen3.6-27B-Fable-Fus-711-UnHeretic-NM-DAU-NEO-MAX-NEO-MTP-Q5_K_S.gguf',
        ),
        isFalse,
      );
    });
  });
}
