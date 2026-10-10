import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';

void main() {
  const relay = 'https://relay.example.com/s/abc123';

  AppSettings remote({String? kokoroUrl}) => AppSettings(
        serverUrl: relay,
        remoteServerUrl: relay,
        remoteAuthToken: 'relay-secret',
        isRemoteActive: true,
        customHeadersEnabled: true,
        cfAccessClientId: 'cf-id',
        cfAccessClientSecret: 'cf-secret',
        imageGenServerUrl: 'https://my-a1111.example',
        voiceRemoteKokoroUrl: kokoroUrl,
      );

  group('imageGenRelayHeaders', () {
    test('relay active: token + LM Studio headers go to the relay', () {
      final s = remote();
      expect(s.effectiveImageGenUrl, relay);
      final h = s.imageGenRelayHeaders!;
      expect(h['X-LM-Mini-Token'], 'relay-secret');
      expect(h['CF-Access-Client-Secret'], 'cf-secret');
    });

    test('relay URL comes from the pairing, not a cloud-patched serverUrl',
        () {
      final s = remote().copyWith(serverUrl: 'https://api.openai.com/v1');
      expect(s.effectiveImageGenUrl, relay);
    });

    test('direct image host never gets the token or custom headers', () {
      final s = remote().copyWith(isRemoteActive: false);
      expect(s.effectiveImageGenUrl, 'https://my-a1111.example');
      expect(s.imageGenRelayHeaders, isNull);
    });
  });

  group('voiceRemoteKokoroHeaders', () {
    test('relay Kokoro gets the token', () {
      expect(remote().voiceRemoteKokoroHeaders,
          {'X-LM-Mini-Token': 'relay-secret'});
    });

    test('custom Kokoro URL never gets the relay token', () {
      final s = remote(kokoroUrl: 'http://192.168.1.9:9998');
      expect(s.voiceRemoteKokoroHeaders, isNull);
    });
  });
}
