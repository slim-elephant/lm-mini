import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/url_host.dart';

void main() {
  group('urlHost', () {
    test('parses host from full URL', () {
      expect(urlHost('http://192.168.1.10:1234'), '192.168.1.10');
      expect(urlHost('https://pc.local:8188/path'), 'pc.local');
    });

    test('adds http when scheme is missing', () {
      expect(urlHost('192.168.1.10:11434'), '192.168.1.10');
    });

    test('returns null for empty', () {
      expect(urlHost(''), isNull);
      expect(urlHost(null), isNull);
    });
  });

  group('replaceUrlHost', () {
    test('keeps port and scheme', () {
      expect(
        replaceUrlHost('http://192.168.1.10:8188', '192.168.1.20'),
        'http://192.168.1.20:8188',
      );
    });

    test('keeps path', () {
      expect(
        replaceUrlHost('http://192.168.1.10:8188/api', '10.0.0.2'),
        'http://10.0.0.2:8188/api',
      );
    });
  });

  group('sharedHostUpdate', () {
    test('offers ComfyUI move when chat IP changes and hosts matched', () {
      final change = sharedHostUpdate(
        previousChangedUrl: 'http://192.168.1.10:1234',
        newChangedUrl: 'http://192.168.1.20:1234',
        peerUrl: 'http://192.168.1.10:8188',
        peer: SharedHostPeer.imageGen,
      );
      expect(change, isNotNull);
      expect(change!.suggestedPeerUrl, 'http://192.168.1.20:8188');
      expect(change.oldHost, '192.168.1.10');
      expect(change.newHost, '192.168.1.20');
    });

    test('offers chat move when ComfyUI IP changes and hosts matched', () {
      final change = sharedHostUpdate(
        previousChangedUrl: 'http://192.168.1.10:8188',
        newChangedUrl: 'http://192.168.1.30:8188',
        peerUrl: 'http://192.168.1.10:11434',
        peer: SharedHostPeer.chat,
      );
      expect(change!.suggestedPeerUrl, 'http://192.168.1.30:11434');
    });

    test('does not offer when peer was on a different host', () {
      expect(
        sharedHostUpdate(
          previousChangedUrl: 'http://192.168.1.10:1234',
          newChangedUrl: 'http://192.168.1.20:1234',
          peerUrl: 'http://10.0.0.5:8188',
          peer: SharedHostPeer.imageGen,
        ),
        isNull,
      );
    });

    test('does not offer localhost', () {
      expect(
        sharedHostUpdate(
          previousChangedUrl: 'http://127.0.0.1:1234',
          newChangedUrl: 'http://192.168.1.20:1234',
          peerUrl: 'http://127.0.0.1:8188',
          peer: SharedHostPeer.imageGen,
        ),
        isNull,
      );
    });

    test('does not offer when only the port changed', () {
      expect(
        sharedHostUpdate(
          previousChangedUrl: 'http://192.168.1.10:1234',
          newChangedUrl: 'http://192.168.1.10:1235',
          peerUrl: 'http://192.168.1.10:8188',
          peer: SharedHostPeer.imageGen,
        ),
        isNull,
      );
    });

    test('does not offer public cloud API hosts', () {
      expect(isOfferableLanHost('api.openai.com'), isFalse);
      expect(isOfferableLanHost('192.168.1.10'), isTrue);
      expect(isOfferableLanHost('studio.local'), isTrue);
    });
  });
}
