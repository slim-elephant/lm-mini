import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/relay_url.dart';

void main() {
  group('isRelayRequestUrl', () {
    const relay = 'https://relay.example.com/s/abc123';

    test('matches the relay URL and paths under it', () {
      expect(isRelayRequestUrl(relay, relay), isTrue);
      expect(isRelayRequestUrl('$relay/api/v1/chat', relay), isTrue);
      expect(isRelayRequestUrl('$relay/', '$relay/'), isTrue);
      expect(
        isRelayRequestUrl('HTTPS://Relay.Example.com/s/abc123/v1/models', relay),
        isTrue,
      );
    });

    test('rejects other hosts, sessions and schemes', () {
      expect(isRelayRequestUrl('https://api.openai.com/v1', relay), isFalse);
      expect(
        isRelayRequestUrl('https://relay.example.com/s/other/api', relay),
        isFalse,
      );
      expect(
        isRelayRequestUrl('https://relay.example.com/s/abc1234/api', relay),
        isFalse,
      );
      expect(isRelayRequestUrl('http://relay.example.com/s/abc123', relay),
          isFalse);
      expect(
        isRelayRequestUrl('https://relay.example.com.evil.io/s/abc123', relay),
        isFalse,
      );
    });

    test('LAN pairing URL with port', () {
      const lan = 'http://192.168.1.20:8765';
      expect(isRelayRequestUrl('$lan/api/v1/chat', lan), isTrue);
      expect(isRelayRequestUrl('http://192.168.1.20:1234/api', lan), isFalse);
    });

    test('missing relay or request URL never matches', () {
      expect(isRelayRequestUrl('https://relay.example.com/s/x', null), isFalse);
      expect(isRelayRequestUrl(null, relay), isFalse);
      expect(isRelayRequestUrl('not a url', relay), isFalse);
    });
  });
}
