import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/error_report_service.dart';
import 'package:lm_mini/utils/model_not_found_error.dart';
import 'package:lm_mini/utils/wrong_server_type_error.dart';

void main() {
  test('a bare 404 means the server is not Ollama', () {
    for (final body in [
      '{"error":"not found"}',
      '{"error":{"message":"not found","type":"invalid_request_error"}}',
      '{"detail":"Not Found"}',
      '404 page not found',
      'Not Found',
      '',
      '<html><body>404</body></html>',
    ]) {
      expect(WrongServerTypeError.isBareNotFound(404, body), isTrue,
          reason: body);
    }
  });

  test('a real Ollama missing-model 404 is left alone', () {
    for (final body in [
      '{"error":"model \\"qwen3:4b\\" not found, try pulling it first"}',
      '{"error":"model \'x\' not found"}',
    ]) {
      expect(WrongServerTypeError.isBareNotFound(404, body), isFalse,
          reason: body);
    }
    expect(WrongServerTypeError.isBareNotFound(500, '{"error":"not found"}'),
        isFalse);
    expect(WrongServerTypeError.isBareNotFound(200, ''), isFalse);
  });

  test('message names the server type and the fallback, and is recognised', () {
    final msg = WrongServerTypeError.userMessageFor('Ollama');
    expect(msg, contains('Ollama'));
    expect(msg, contains('correct server type'));
    expect(msg, contains('A.I Compatible API'));
    expect(WrongServerTypeError.matches(msg), isTrue);
    expect(WrongServerTypeError.matches('Exception: $msg'), isTrue);
    expect(WrongServerTypeError.matches('not found'), isFalse);
    expect(WrongServerTypeError.matches(null), isFalse);
    // Setup guidance, not a bug: no support ticket, and not "model missing".
    expect(ErrorReportService.isIgnorable(msg), isTrue);
    expect(ModelNotFoundError.matches(msg), isFalse);
  });
}
