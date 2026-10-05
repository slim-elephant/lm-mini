import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/unsloth_load.dart';

void main() {
  const id = 'unsloth/gemma-4-e2b-it-GGUF:UD-Q4_K_XL';

  test('quant is the suffix after the last colon', () {
    expect(UnslothLoad.quantFromModelId(id), 'UD-Q4_K_XL');
    expect(UnslothLoad.modelPath(id), 'unsloth/gemma-4-e2b-it-GGUF');
    expect(UnslothLoad.quantFromModelId('no-colon'), isEmpty);
    expect(UnslothLoad.modelPath('no-colon'), 'no-colon');
  });

  test('load body sends path, quant, and context length', () {
    expect(
      UnslothLoad.loadBody(modelId: id, maxSeqLength: 8192),
      {
        'model_path': 'unsloth/gemma-4-e2b-it-GGUF',
        'gguf_variant': 'UD-Q4_K_XL',
        'max_seq_length': 8192,
      },
    );
  });

  test('api root drops a trailing /v1', () {
    expect(
      UnslothLoad.apiRoot('http://localhost:8888/v1/'),
      'http://localhost:8888',
    );
    expect(
        UnslothLoad.apiRoot('http://localhost:8888'), 'http://localhost:8888');
  });

  test('status match requires the same model and context', () {
    final status = {
      'loaded': true,
      'model_identifier': 'unsloth/gemma-4-e2b-it-GGUF',
      'gguf_variant': 'UD-Q4_K_XL',
      'context_length': 8192,
    };
    expect(UnslothLoad.alreadyLoaded(status, id, 8192), isTrue);
    expect(UnslothLoad.alreadyLoaded(status, id, 16384), isFalse);
    expect(
      UnslothLoad.alreadyLoaded(status, 'other/repo:Q4_K_M', 8192),
      isFalse,
    );
    expect(
      UnslothLoad.loadedContextLength(
          {'loaded': false, 'context_length': 8192}),
      isNull,
    );
  });

  test('catalog marks only models Unsloth reports as loaded', () {
    final status = {
      'active_model': 'unsloth/gemma-4-e2b-it-GGUF',
      'model_identifier': 'unsloth/gemma-4-e2b-it-GGUF',
      'gguf_variant': 'UD-Q4_K_XL',
      'loaded': ['unsloth/gemma-4-e2b-it-GGUF'],
      'context_length': 8192,
    };
    expect(UnslothLoad.catalogModelIsLoaded(status, id), isTrue);
    expect(
      UnslothLoad.catalogModelIsLoaded(
        status,
        'unsloth/gemma-4-e2b-it-GGUF:Q8_0',
      ),
      isFalse,
    );
    expect(
      UnslothLoad.catalogModelIsLoaded(status, 'unsloth/other:Q4_K_M'),
      isFalse,
    );
    expect(
      UnslothLoad.catalogModelIsLoaded(
        {'loaded': false, 'active_model': 'unsloth/gemma-4-e2b-it-GGUF'},
        id,
      ),
      isFalse,
    );
  });

  test('auth failure copy depends on whether a key was sent', () {
    expect(
      UnslothLoad.connectionNeedsApiKey(
        'Authentication failed (HTTP 401). Check your API key.',
      ),
      isTrue,
    );
    expect(UnslothLoad.connectionNeedsApiKey('Connection timed out'), isFalse);
    expect(
      UnslothLoad.authFailureMessage(hadKey: false),
      UnslothLoad.apiKeyRequiredMessage,
    );
    expect(
      UnslothLoad.authFailureMessage(hadKey: true),
      UnslothLoad.apiKeyRejectedMessage,
    );
  });
}
