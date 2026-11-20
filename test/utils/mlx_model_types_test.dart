import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/mlx_model_types.dart';

void main() {
  test('supported model types pass', () {
    expect(mlxConfigProblem('{"model_type": "qwen3"}'), isNull);
    expect(mlxConfigProblem('{"model_type": "LFM2"}'), isNull);
    expect(mlxConfigProblem('{"model_type": "gemma3_text", "x": 1}'), isNull);
  });

  test('newer families the bundled engine lacks are named in the message', () {
    final msg = mlxConfigProblem('{"model_type": "qwen3_5"}');
    expect(msg, contains('"qwen3_5"'));
    expect(msg, contains('GGUF'));
    expect(mlxConfigProblem('{"model_type": "gemma4"}'), isNotNull);
  });

  test('missing or broken config.json is explained', () {
    expect(mlxConfigProblem(null), contains('no config.json'));
    expect(mlxConfigProblem('  '), contains('no config.json'));
    expect(mlxConfigProblem('{not json'), contains('could not be read'));
    expect(mlxConfigProblem('{"architectures": ["X"]}'), contains('model_type'));
    expect(mlxConfigProblem('[1, 2]'), contains('model_type'));
  });
}
