import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lm_mini/services/lm_studio_service.dart';

const _sampleLmStudioBody = '''
{
  "error": {
    "message": "Could not find stored response for previous_response_id 'resp_deadbeef'. Please ensure the ID is correct. Current previous response auto-deletion policy: Responses older than 30 days are automatically deleted.",
    "type": "invalid_request",
    "param": "previous_response_id",
    "code": "invalid_value"
  }
}
''';

void main() {
  group('isStalePreviousResponseId', () {
    test('matches LM Studio HTTP 400 body', () {
      expect(LMStudioService.isStalePreviousResponseId(_sampleLmStudioBody), isTrue);
      expect(
        LMStudioService.stalePreviousResponseErrorFromHttpBody(_sampleLmStudioBody),
        isNotNull,
      );
    });

    test('matches param + code on the error object', () {
      expect(
        LMStudioService.isStalePreviousResponseId({
          'message': 'gone',
          'type': 'invalid_request',
          'param': 'previous_response_id',
          'code': 'invalid_value',
        }),
        isTrue,
      );
    });

    test('matches tagged stream chunks', () {
      expect(
        LMStudioService.isStalePreviousResponseId({
          'error': 'Could not find stored response',
          'error_type': LMStudioService.stalePreviousResponseIdType,
          'stale_previous_response_id': true,
        }),
        isTrue,
      );
    });

    test('ignores unrelated errors', () {
      expect(LMStudioService.isStalePreviousResponseId(null), isFalse);
      expect(
        LMStudioService.isStalePreviousResponseId({
          'error': {'message': 'context overflow', 'type': 'invalid_request'},
        }),
        isFalse,
      );
      expect(
        LMStudioService.stalePreviousResponseErrorFromHttpBody(
          '{"error":{"message":"boom"}}',
        ),
        isNull,
      );
    });
  });

  test('live LM Studio: dead id 400 then history retry succeeds', () async {
    final base = Platform.environment['LM_STUDIO_URL'] ?? 'http://localhost:1234';
    final token = Platform.environment['LM_STUDIO_TOKEN'];
    if (token == null || token.isEmpty) {
      markTestSkipped('Set LM_STUDIO_TOKEN to run the live LM Studio check.');
      return;
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    late http.Response models;
    try {
      models = await http
          .get(Uri.parse('$base/api/v1/models'), headers: headers)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      markTestSkipped('LM Studio is not reachable at $base');
      return;
    }
    if (models.statusCode != 200) {
      markTestSkipped('LM Studio models endpoint returned ${models.statusCode}');
      return;
    }

    const model = 'qwen3-0.6b';
    Future<http.Response> chat(Map<String, dynamic> body) {
      return http
          .post(
            Uri.parse('$base/api/v1/chat'),
            headers: headers,
            body: jsonEncode({
              'model': model,
              'stream': false,
              'max_output_tokens': 64,
              'reasoning': 'off',
              ...body,
            }),
          )
          .timeout(const Duration(seconds: 60));
    }

    final dead = await chat({
      'input': 'What is the secret?',
      'previous_response_id': 'resp_does_not_exist_at_all',
    });
    expect(dead.statusCode, 400);
    expect(LMStudioService.isStalePreviousResponseId(dead.body), isTrue);

    final retry = await chat({
      'input':
          '[Previous conversation context — continue from here]\n\n'
          'User: The secret code is ALPHA-42.\n\n'
          '[End of previous context]\n\n'
          'User: What is the secret code? Reply with only the code.',
    });
    expect(retry.statusCode, 200, reason: retry.body);
    final decoded = jsonDecode(retry.body) as Map<String, dynamic>;
    expect(decoded['response_id'], isNotNull);
    final output = decoded['output'] as List<dynamic>? ?? const [];
    final text = output
        .whereType<Map>()
        .where((item) => item['type'] == 'message')
        .map((item) => item['content']?.toString() ?? '')
        .join();
    expect(text.toUpperCase(), contains('ALPHA-42'));
  });
}
