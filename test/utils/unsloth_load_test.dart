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

  // Shapes recorded from Unsloth Studio 0.1.810 with LM Studio's folder.
  const qwen = 'unsloth/Qwen3-0.6B-GGUF';
  final local = <String, dynamic>{
    'models': [
      {'id': qwen, 'source': 'hf_cache', 'model_id': qwen, 'partial': true},
      {
        'id': 'ref:7bb532994a2ccfdd4a9b1c5279c5c9eb',
        'source': 'lmstudio',
        'model_id': qwen,
        'partial': false,
      },
      {
        'id': 'ref:42ca35fbc14e0ab3dee5ebef03d25ea7',
        'source': 'lmstudio',
        'model_id': 'lmstudio-community/Qwen3.5-4B-GGUF',
        'partial': false,
      },
    ],
  };

  test('candidates are the repo, then on-disk copies elsewhere', () {
    expect(UnslothLoad.localCandidates(local, '$qwen:Q8_0'), [
      qwen,
      'ref:7bb532994a2ccfdd4a9b1c5279c5c9eb',
    ]);
    expect(UnslothLoad.localCandidates(null, qwen), [qwen]);
  });

  test('variant comes only from downloaded files', () {
    final variants = <String, dynamic>{
      'default_variant': 'Q4_K_M',
      'variants': [
        {'quant': 'Q4_K_M', 'downloaded': false},
        {'quant': 'Q8_0', 'downloaded': true, 'partial': false},
        {'quant': 'UD-Q6_K_XL', 'downloaded': true, 'partial': true},
      ],
    };
    // The default is not on disk, so the downloaded quant wins.
    expect(UnslothLoad.downloadedVariant(variants, ''), 'Q8_0');
    expect(UnslothLoad.downloadedVariant(variants, 'q8_0'), 'Q8_0');
    expect(UnslothLoad.downloadedVariant(variants, 'Q4_K_M'), isNull);
    expect(UnslothLoad.downloadedVariant(variants, 'UD-Q6_K_XL'), isNull);
    expect(UnslothLoad.downloadedVariant(null, ''), isNull);
  });

  test('downloaded default is preferred over other quants', () {
    final variants = <String, dynamic>{
      'default_variant': 'Q8_0',
      'variants': [
        {'quant': 'BF16', 'downloaded': true},
        {'quant': 'Q8_0', 'downloaded': true},
      ],
    };
    expect(UnslothLoad.downloadedVariant(variants, ''), 'Q8_0');
  });

  test('resolved load body sends the handle and variant', () {
    expect(
      UnslothLoad.resolvedLoadBody(
        modelPath: 'ref:7bb5',
        variant: 'Q8_0',
        maxSeqLength: 4096,
      ),
      {'model_path': 'ref:7bb5', 'gguf_variant': 'Q8_0', 'max_seq_length': 4096},
    );
  });

  test('a model loaded by ref matches its repo by bare name', () {
    final status = <String, dynamic>{
      'active_model': 'Qwen3-0.6B-GGUF',
      'model_identifier': 'ref:7bb532994a2ccfdd4a9b1c5279c5c9eb',
      'gguf_variant': 'Q8_0',
      'loaded': ['Qwen3-0.6B-GGUF'],
      'context_length': 4096,
    };
    expect(UnslothLoad.statusIsModel(status, qwen), isTrue);
    expect(UnslothLoad.statusIsModel(status, '$qwen:Q8_0'), isTrue);
    expect(UnslothLoad.statusIsModel(status, '$qwen:Q4_K_M'), isFalse);
    expect(UnslothLoad.catalogModelIsLoaded(status, qwen), isTrue);
    expect(UnslothLoad.alreadyLoaded(status, qwen, 4096), isTrue);
    expect(
      UnslothLoad.catalogModelIsLoaded(status, 'unsloth/Qwen3-4B-GGUF'),
      isFalse,
    );
  });
}
