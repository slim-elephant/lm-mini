import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/remote_connection_info.dart';

void main() {
  test('desktop host pairing probes host-status, not LM Studio REST', () {
    expect(
      RemoteRelayHttp.probePathForBackend('lmMiniDesktop'),
      '/lm-mini/host-status',
    );
    expect(
      RemoteRelayHttp.probePathForBackend('lmStudio'),
      '/api/v1/models',
    );
    expect(RemoteRelayHttp.probePathForBackend('ollama'), '/api/tags');
    expect(RemoteRelayHttp.probePathForBackend('jan'), '/v1/models');
    expect(RemoteRelayHttp.probePathForBackend('unsloth'), '/v1/models');
  });

  test('httpErrorMessage prefers relay JSON over a bare 502', () {
    expect(
      RemoteRelayHttp.httpErrorMessage(
        502,
        '{"error":{"message":"Desktop is not connected. Open LM Mini Connect on your computer."}}',
      ),
      contains('LM Mini Home'),
    );
    expect(
      RemoteRelayHttp.httpErrorMessage(502, 'not-json'),
      contains('Share with phone'),
    );
  });

  test('timeout becomes a Mac-reachable message, not Future not completed', () {
    final message = RemoteRelayHttp.friendlyConnectionError(
      TimeoutException('Future not completed', const Duration(seconds: 15)),
    );
    expect(message.toLowerCase(), contains('did not answer'));
    expect(message, isNot(contains('Future not completed')));
  });

  test('parseRelayUrl reads token and backends from the fragment', () {
    final info = RemoteRelayHttp.parseRelayUrl(
      'https://relay.lmmini.com/s/97ccb0f8d53aa387a01c9051611ff711'
      '#t=secret-token&ek=enc-key&b=lmMiniDesktop,lmStudio&kokoro=1',
    );
    expect(info, isNotNull);
    expect(info!.url,
        'https://relay.lmmini.com/s/97ccb0f8d53aa387a01c9051611ff711');
    expect(info.token, 'secret-token');
    expect(info.encryptionKey, 'enc-key');
    expect(info.backends, ['lmMiniDesktop', 'lmStudio']);
    expect(info.kokoroReady, isTrue);
    expect(info.hostPlatform, isNull);
  });

  test('parseRelayUrl reads host platform from the fragment', () {
    final info = RemoteRelayHttp.parseRelayUrl(
      'https://relay.lmmini.com/s/97ccb0f8d53aa387a01c9051611ff711'
      '#t=secret-token&ek=enc-key&b=lmMiniDesktop&platform=windows',
    );
    expect(info, isNotNull);
    expect(info!.hostPlatform, 'windows');
  });

  test('parseRelayUrl falls back to session id when token is omitted', () {
    final info = RemoteRelayHttp.parseRelayUrl(
      'https://relay.lmmini.com/s/97ccb0f8d53aa387a01c9051611ff711',
    );
    expect(info, isNotNull);
    expect(info!.token, '97ccb0f8d53aa387a01c9051611ff711');
    expect(info.backends, isEmpty);
  });
}
