import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/lm_studio_service.dart';
import 'package:lm_mini/utils/model_not_found_error.dart';

void main() {
  group('ModelNotFoundError', () {
    const lms404 =
        '{"error":{"message":"File Not Found","type":"not_found_error","code":404}}';
    const openai =
        '{"error":{"message":"The model qwen3-1.7b-Q6_K does not exist",'
        '"type":"invalid_request_error","code":"model_not_found"}}';
    const ollama = '{"error":"model \'qwen3-1.7b\' not found"}';

    test('matches LM Studio File Not Found 404', () {
      expect(ModelNotFoundError.matches(lms404), isTrue);
    });

    test('matches OpenAI-compat model_not_found', () {
      expect(ModelNotFoundError.matches(openai), isTrue);
    });

    test('matches Ollama model not found', () {
      expect(ModelNotFoundError.matches(ollama), isTrue);
    });

    test('matches the in-app catalog-miss copy', () {
      expect(
        ModelNotFoundError.matches(
          'Model "qwen3-1.7b-Q6_K" is not downloaded in LM Studio. '
          'Pick an installed model in Model Management.',
        ),
        isTrue,
      );
    });

    test('does not match a stale previous_response_id 404', () {
      const stale = '{"error":{"message":'
          '"Could not find stored response for previous_response_id",'
          '"param":"previous_response_id"}}';
      expect(LMStudioService.isStalePreviousResponseId(stale), isTrue);
      expect(ModelNotFoundError.matches(stale), isFalse);
    });

    test('matches LM Studio invalid model identifier wording', () {
      const body = 'Invalid model identifier '
          '"gemma4-26b-a4b-uncensored-hauhaucs-balanced". '
          'Please specify a valid downloaded model '
          '(e.g., google/gemma-4-e2b@4bit, google/gemma-4-e2b).';
      expect(ModelNotFoundError.matches(body), isTrue);
      final chunk = LMStudioService.modelNotFoundErrorFromHttpBody(
        '{"error":"$body","error_type":"model_not_found"}',
      );
      expect(chunk?['error_type'], ModelNotFoundError.type);
    });

    test('does not match a generic socket failure', () {
      expect(
        ModelNotFoundError.matches(
          'ClientException with SocketException: Connection refused',
        ),
        isFalse,
      );
    });

    test('LM Studio HTTP helper tags the stream chunk', () {
      final chunk = LMStudioService.modelNotFoundErrorFromHttpBody(lms404);
      expect(chunk, isNotNull);
      expect(chunk!['error_type'], ModelNotFoundError.type);
      expect(chunk['error'].toString().toLowerCase(), contains('file not found'));
    });
  });
}
