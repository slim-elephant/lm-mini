import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/lm_studio_service.dart';

/// Ticket cm1td006: a non-LM-Studio server picked as LM Studio answers
/// `/api/v1/chat` with `404 {"error":{"message":"not found"}}`.
void main() {
  late HttpServer server;
  late String body;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      await req.drain<void>();
      req.response
        ..statusCode = 404
        ..headers.contentType = ContentType.json
        ..write(body);
      await req.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  Future<Map<String, dynamic>> firstEvent() => LMStudioService()
      .streamStatefulChat(
        baseUrl: 'http://127.0.0.1:${server.port}',
        modelId: 'some-model',
        input: 'hello',
      )
      .first;

  test('plain 404 is flagged so the caller can resend over /v1', () async {
    body = jsonEncode({
      'error': {'message': 'not found'}
    });
    final e = await firstEvent();
    expect(e['type'], 'error');
    expect(LMStudioService.isV1ChatUnavailable(e), isTrue);
  });

  test('404 for a missing model is still a missing-model error', () async {
    body = jsonEncode({
      'error': {'message': 'Model "some-model" not found'}
    });
    final e = await firstEvent();
    expect(LMStudioService.isV1ChatUnavailable(e), isFalse);
  });
}
