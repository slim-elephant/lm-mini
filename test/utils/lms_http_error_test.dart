import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/lms_http_error.dart';

void main() {
  group('missingRequiredFieldFromHttpBody', () {
    test('reads OpenAI param model', () {
      expect(
        missingRequiredFieldFromHttpBody(
          '{"error":{"message":"Required","type":"invalid_request",'
          '"code":"missing_required_parameter","param":"model"}}',
        ),
        'model',
      );
    });

    test('reads LM Studio missing field message', () {
      expect(
        missingRequiredFieldFromHttpBody(
          '{"error":{"message":"Missing required field \'model\'"}}',
        ),
        'model',
      );
    });

    test('reads messages field is required', () {
      expect(
        missingRequiredFieldFromHttpBody(
          '{"error":"\'messages\' field is required"}',
        ),
        'messages',
      );
    });
  });

  group('DroppedRequestBodyError', () {
    test('matches the ticket fingerprint', () {
      expect(
        DroppedRequestBodyError.matches(
            '{"error":"\'messages\' field is required"}'),
        isTrue,
      );
      expect(
        DroppedRequestBodyError.matches(DroppedRequestBodyError.userMessage),
        isTrue,
      );
    });

    test('does not match a real missing-input or model-not-found', () {
      expect(
        DroppedRequestBodyError.matches("'input' is required"),
        isFalse,
      );
      expect(
        DroppedRequestBodyError.matches(
          '{"error":{"message":"Invalid model","code":"model_not_found"}}',
        ),
        isFalse,
      );
    });
  });

  group('requestJsonHasField', () {
    test('true when model is non-empty', () {
      expect(requestJsonHasField({'model': 'google/gemma-4-12b'}, 'model'),
          isTrue);
    });

    test('false when model is empty', () {
      expect(requestJsonHasField({'model': ''}, 'model'), isFalse);
    });

    test('true when messages is a non-empty list', () {
      expect(
        requestJsonHasField({
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ]
        }, 'messages'),
        isTrue,
      );
    });
  });
}
