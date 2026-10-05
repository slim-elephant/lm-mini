import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/json_list.dart';

void main() {
  group('jsonAsList', () {
    test('passes through a JSON array', () {
      expect(jsonAsList([1, 2]), [1, 2]);
    });

    test('unwraps common object wrappers', () {
      expect(
          jsonAsList({
            'data': ['a']
          }),
          ['a']);
      expect(jsonAsList({'models': []}), []);
    });

    test('returns null for error objects', () {
      expect(jsonAsList({'error': 'not found'}), isNull);
      expect(jsonAsList(null), isNull);
    });
  });

  group('looksLikeA1111Options', () {
    test('matches AUTOMATIC1111 options', () {
      expect(
        looksLikeA1111Options({'sd_model_checkpoint': 'sdxl.safetensors'}),
        isTrue,
      );
    });

    test('rejects LM Studio / generic JSON errors', () {
      expect(looksLikeA1111Options({'error': 'Invalid URL', 'code': 404}),
          isFalse);
      expect(looksLikeA1111Options({'data': []}), isFalse);
    });
  });
}
