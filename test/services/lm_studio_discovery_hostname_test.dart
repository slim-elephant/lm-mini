import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/lm_studio_discovery_service.dart';

void main() {
  group('LmStudioDiscoveryService.sanitizePtrName', () {
    test('keeps a LAN hostname', () {
      expect(
        LmStudioDiscoveryService.sanitizePtrName(
          '192.168.1.42',
          'studio.local',
        ),
        'studio.local',
      );
    });

    test('strips a trailing DNS dot', () {
      expect(
        LmStudioDiscoveryService.sanitizePtrName(
          '192.168.1.42',
          'mini.lan.',
        ),
        'mini.lan',
      );
    });

    test('drops PTR that is just the IP', () {
      expect(
        LmStudioDiscoveryService.sanitizePtrName(
          '192.168.1.42',
          '192.168.1.42',
        ),
        isNull,
      );
    });

    test('drops in-addr.arpa leftovers', () {
      expect(
        LmStudioDiscoveryService.sanitizePtrName(
          '192.168.1.42',
          '42.1.168.192.in-addr.arpa',
        ),
        isNull,
      );
    });
  });

  group('LmStudioDiscoveryService.interfaceScanScore', () {
    test('prefers Wi-Fi over VPN tunnels', () {
      expect(LmStudioDiscoveryService.interfaceScanScore('en0'), 0);
      expect(LmStudioDiscoveryService.interfaceScanScore('wlan0'), 0);
      expect(
        LmStudioDiscoveryService.interfaceScanScore('en0') <
            LmStudioDiscoveryService.interfaceScanScore('utun2'),
        isTrue,
      );
      expect(
        LmStudioDiscoveryService.interfaceScanScore('en0') <
            LmStudioDiscoveryService.interfaceScanScore('ipsec0'),
        isTrue,
      );
    });
  });

  group('DiscoveredLmStudioServer labels', () {
    test('lists hostname then URL when PTR exists', () {
      const s = DiscoveredLmStudioServer(
        host: '192.168.1.42',
        port: 1234,
        hostname: 'Users-Mac.local',
      );
      expect(s.hasHostname, isTrue);
      expect(s.listTitle, 'Users-Mac.local');
      expect(s.listSubtitle, contains('192.168.1.42:1234'));
      expect(s.listSubtitle, contains('LM Studio'));
    });

    test('falls back to URL when there is no hostname', () {
      const s = DiscoveredLmStudioServer(
        host: '192.168.1.42',
        port: 11434,
        kind: DiscoveredServerKind.ollama,
      );
      expect(s.listTitle, 'http://192.168.1.42:11434');
      expect(s.listSubtitle, 'Ollama');
    });

    test('names an Unsloth hit', () {
      const s = DiscoveredLmStudioServer(
        host: '127.0.0.1',
        port: 8888,
        kind: DiscoveredServerKind.unsloth,
        requiresApiKey: true,
        thisMachine: true,
      );
      expect(s.kindLabel, 'Unsloth');
      expect(s.listSubtitle, contains('Needs API key'));
    });
  });

  test('Unsloth health body is the studio service name', () {
    expect(
      LmStudioDiscoveryService.isUnslothHealthBody({
        'status': 'healthy',
        'service': 'Unsloth UI Backend',
      }),
      isTrue,
    );
    expect(
      LmStudioDiscoveryService.isUnslothHealthBody({
        'data': [],
      }),
      isFalse,
    );
  });
}
