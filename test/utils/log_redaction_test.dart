import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/log_redaction.dart';

const _fakeJwt =
    'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.fakesig';

void main() {
  group('redactLogSecrets', () {
    test('strips JSON Authorization Bearer JWT', () {
      final raw = jsonEncode({
        'integrations': [
          {
            'headers': {'Authorization': 'Bearer $_fakeJwt'},
          }
        ],
      });
      final out = redactLogSecrets(raw);
      expect(out, isNot(contains(_fakeJwt)));
      expect(out, isNot(contains('eyJ')));
      expect(out, contains('[redacted]'));
    });

    test('strips HTTP header style', () {
      final out = redactLogSecrets('Authorization: Bearer $_fakeJwt');
      expect(out, isNot(contains(_fakeJwt)));
      expect(out, contains('Authorization: [redacted]'));
    });

    test('strips a bare JWT', () {
      final out = redactLogSecrets('token=$_fakeJwt done');
      expect(out, isNot(contains(_fakeJwt)));
      expect(out, contains('[redacted-jwt]'));
    });

    test('truncates a huge non-JSON line', () {
      final huge = 'prefix ${'x' * 8000} suffix';
      final out = redactLogSecrets(huge);
      expect(out.length, lessThan(400));
      expect(out, contains('chars trimmed'));
      expect(out, isNot(contains('x' * 500)));
    });
  });

  group('jsonEncodeForLog', () {
    test('keeps model and trims 99% of system_prompt', () {
      final prompt = 'You are Mini. ${'A' * 5000} END';
      final out = jsonEncodeForLog({
        'model': 'google/gemma-4-12b',
        'input': 'are you there ?',
        'system_prompt': prompt,
      });
      expect(out, contains('google/gemma-4-12b'));
      expect(out, contains('are you there ?'));
      expect(out, contains('chars trimmed'));
      expect(out, isNot(contains('A' * 200)));
      expect(out.length, lessThan(prompt.length));
    });

    test('omits base64 image payloads', () {
      final out = jsonEncodeForLog({
        'content': 'data:image/png;base64,${'iVBORw0KGgo' * 400}',
      });
      expect(out, contains('data:image/png;base64,[omitted'));
      expect(out, isNot(contains('iVBORw0KGgo' * 10)));
    });
  });

  group('redactSecretsInJson', () {
    test('redacts MCP integration Authorization and keeps URL', () {
      final redacted = redactSecretsInJson({
        'model': 'google/gemma-4-e2b',
        'integrations': [
          {
            'type': 'ephemeral_mcp',
            'server_label': 'lmmini-search',
            'server_url': 'https://mcp.example.run.app',
            'headers': {
              'Authorization': 'Bearer $_fakeJwt',
              'Content-Type': 'application/json',
            },
          }
        ],
      }) as Map<String, dynamic>;

      final encoded = jsonEncode(redacted);
      expect(encoded, isNot(contains(_fakeJwt)));
      expect(encoded, contains('https://mcp.example.run.app'));
      expect(
        ((redacted['integrations'] as List).first as Map)['headers']
            ['Authorization'],
        '[redacted]',
      );
      expect(
        ((redacted['integrations'] as List).first as Map)['headers']
            ['Content-Type'],
        'application/json',
      );
    });
  });
}
