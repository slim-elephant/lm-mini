import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/lm_studio_model.dart';

void main() {
  group('looksLikeEmbeddingModel', () {
    test('matches names with embed', () {
      expect(
        LMStudioModel.looksLikeEmbeddingModel('text-embedding-nomic-embed-text-v1.5'),
        isTrue,
      );
      expect(
        LMStudioModel.looksLikeEmbeddingModel('nomic-embed-text:latest'),
        isTrue,
      );
      expect(
        LMStudioModel.looksLikeEmbeddingModel('text-embedding-3-small'),
        isTrue,
      );
      expect(
        LMStudioModel.looksLikeEmbeddingModel('qwen3-embedding-8b'),
        isTrue,
      );
    });

    test('matches common families that omit the word embed', () {
      expect(LMStudioModel.looksLikeEmbeddingModel('bge-m3'), isTrue);
      expect(LMStudioModel.looksLikeEmbeddingModel('BAAI/bge-large-en-v1.5'), isTrue);
      expect(LMStudioModel.looksLikeEmbeddingModel('all-minilm'), isTrue);
      expect(LMStudioModel.looksLikeEmbeddingModel('multilingual-e5-large'), isTrue);
      expect(LMStudioModel.looksLikeEmbeddingModel('gte-Qwen2-7B-instruct'), isTrue);
    });

    test('does not match chat models', () {
      expect(LMStudioModel.looksLikeEmbeddingModel('qwen2.5-7b-instruct'), isFalse);
      expect(LMStudioModel.looksLikeEmbeddingModel('llama-3.1-8b-instruct'), isFalse);
      expect(LMStudioModel.looksLikeEmbeddingModel('gpt-4o'), isFalse);
      expect(LMStudioModel.looksLikeEmbeddingModel('codegeex4-all-9b'), isFalse);
    });
  });

  group('LMStudioModel.isEmbedding', () {
    test('uses V1 type embedding', () {
      final models = LMStudioModel.parseListResponse({
        'models': [
          {
            'key': 'text-embedding-nomic-embed-text-v1.5',
            'type': 'embedding',
            'publisher': 'nomic-ai',
            'architecture': 'nomic-bert',
            'format': 'gguf',
            'quantization': <String, dynamic>{},
            'capabilities': <String, dynamic>{},
            'loaded_instances': <dynamic>[],
          },
          {
            'key': 'qwen/qwen3-8b',
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
      expect(models, hasLength(2));
      expect(models.first.isEmbedding, isTrue);
      expect(models.first.isLLM, isFalse);
      expect(models.last.isEmbedding, isFalse);
      expect(models.last.isLLM, isTrue);
    });

    test('detects OpenAI-compat embedding ids typed as llm', () {
      final models = LMStudioModel.parseListResponse({
        'object': 'list',
        'data': [
          {
            'id': 'nomic-embed-text:latest',
            'object': 'model',
            'owned_by': 'ollama',
          },
          {
            'id': 'llama3.1:8b',
            'object': 'model',
            'owned_by': 'ollama',
          },
        ],
      });
      expect(models.where((m) => m.isEmbedding).map((m) => m.id).toList(),
          ['nomic-embed-text:latest']);
      expect(models.where((m) => m.isLLM).map((m) => m.id).toList(),
          ['llama3.1:8b']);
    });

    test('chatModelIds drops embeddings', () {
      expect(
        LMStudioModel.chatModelIds([
          'gpt-4o',
          'text-embedding-3-small',
          'llama3.1:8b',
        ]),
        ['gpt-4o', 'llama3.1:8b'],
      );
    });
  });
}
