import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/network_status_service.dart';
import 'package:lm_mini/utils/network_preflight_error.dart';
import 'package:lm_mini/utils/server_reachability.dart';
import 'package:lm_mini/utils/streaming_phase.dart';

void main() {
  group('classifyHost', () {
    final cases = <String, HostScope>{
      'http://192.168.1.5:1234': HostScope.localNetwork,
      '192.168.1.5': HostScope.localNetwork,
      'http://10.0.0.2:1234': HostScope.localNetwork,
      '10.0.0.2:1234': HostScope.localNetwork,
      'http://172.20.1.1:11434': HostScope.localNetwork,
      'http://172.16.0.1': HostScope.localNetwork,
      'http://172.31.255.255': HostScope.localNetwork,
      'http://172.32.0.1': HostScope.public,
      'http://172.15.0.1': HostScope.public,
      'http://169.254.10.20:1234': HostScope.localNetwork,
      'http://100.101.1.1:1234': HostScope.vpnRange,
      'http://100.64.0.1': HostScope.vpnRange,
      'http://100.128.0.1': HostScope.public,
      'http://my-pc.ts.net:1234': HostScope.vpnRange,
      'http://my-pc.local:1234': HostScope.localNetwork,
      'http://mypc:1234': HostScope.localNetwork,
      'mypc': HostScope.localNetwork,
      'http://localhost:1234': HostScope.loopback,
      'http://127.0.0.1:1234': HostScope.loopback,
      'http://127.8.9.1': HostScope.loopback,
      'http://[::1]:1234': HostScope.loopback,
      'http://[fd00::1]:1234': HostScope.localNetwork,
      'http://[fc12:3456::1]': HostScope.localNetwork,
      'http://[fe80::1]:1234': HostScope.localNetwork,
      'http://[fd7a:115c:a1e0::1]:1234': HostScope.vpnRange,
      'http://[2001:db8::1]:1234': HostScope.public,
      'https://api.openai.com': HostScope.public,
      'https://relay.lmmini.com/s/abc': HostScope.public,
      'https://openrouter.ai/api': HostScope.public,
      '': HostScope.public,
    };
    cases.forEach((url, expected) {
      test('$url → ${expected.name}', () {
        expect(classifyHost(url), expected);
      });
    });
  });

  group('decide', () {
    PreflightDecision d(
      HostScope s, {
      bool offline = false,
      bool lan = false,
      bool vpn = false,
    }) =>
        decide(
          hostScope: s,
          isOffline: offline,
          hasLocalNetwork: lan,
          hasVpn: vpn,
        );

    test('loopback always proceeds (USB / on-device), even offline', () {
      expect(d(HostScope.loopback, offline: true), PreflightDecision.proceed);
      expect(d(HostScope.loopback), PreflightDecision.proceed);
      expect(d(HostScope.loopback, lan: true), PreflightDecision.proceed);
    });

    test('offline blocks every non-loopback scope', () {
      for (final s in [
        HostScope.localNetwork,
        HostScope.vpnRange,
        HostScope.public,
      ]) {
        expect(d(s, offline: true), PreflightDecision.blockOffline);
        expect(
          d(s, offline: true, lan: true, vpn: true),
          PreflightDecision.blockOffline,
        );
      }
    });

    test('public proceeds when online on any link', () {
      expect(d(HostScope.public), PreflightDecision.proceed);
      expect(d(HostScope.public, lan: true), PreflightDecision.proceed);
      expect(d(HostScope.public, vpn: true), PreflightDecision.proceed);
    });

    test('vpnRange probes — never blocked on mobile data', () {
      expect(d(HostScope.vpnRange), PreflightDecision.probe);
      expect(d(HostScope.vpnRange, lan: true), PreflightDecision.probe);
      expect(d(HostScope.vpnRange, vpn: true), PreflightDecision.probe);
    });

    test('localNetwork: probe on Wi‑Fi or VPN, needs Wi‑Fi on mobile only',
        () {
      expect(d(HostScope.localNetwork, lan: true), PreflightDecision.probe);
      expect(d(HostScope.localNetwork, vpn: true), PreflightDecision.probe);
      expect(
        d(HostScope.localNetwork, lan: true, vpn: true),
        PreflightDecision.probe,
      );
      expect(d(HostScope.localNetwork), PreflightDecision.blockNeedsWifi);
    });
  });

  group('NetworkSnapshot', () {
    test('unknown never blocks', () {
      const s = NetworkSnapshot.unknown;
      expect(s.isOffline, isFalse);
      expect(s.hasLocalNetwork, isTrue);
      expect(s.hasVpn, isFalse);
    });

    test('none is offline', () {
      const s = NetworkSnapshot([ConnectivityResult.none]);
      expect(s.isOffline, isTrue);
    });

    test('mobile only has no LAN', () {
      const s = NetworkSnapshot([ConnectivityResult.mobile]);
      expect(s.isOffline, isFalse);
      expect(s.hasLocalNetwork, isFalse);
      expect(s.hasMobile, isTrue);
      expect(s.hasVpn, isFalse);
    });

    test('iOS VPN shows as other', () {
      const s = NetworkSnapshot(
          [ConnectivityResult.mobile, ConnectivityResult.other]);
      expect(s.hasVpn, isTrue);
    });

    test('wifi and ethernet are LAN', () {
      expect(
        const NetworkSnapshot([ConnectivityResult.wifi]).hasLocalNetwork,
        isTrue,
      );
      expect(
        const NetworkSnapshot([ConnectivityResult.ethernet]).hasLocalNetwork,
        isTrue,
      );
    });
  });

  group('probe', () {
    setUp(ServerReachability.clearCache);

    test('closed local port → refused, fast', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close();
      final sw = Stopwatch()..start();
      final r = await ServerReachability.probe(
        Uri.parse('http://127.0.0.1:$port'),
        timeout: const Duration(seconds: 2),
      );
      expect(r, ProbeResult.refused);
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('listening port → ok, then cached', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sub = server.listen((s) => s.destroy());
      final uri = Uri.parse('http://127.0.0.1:${server.port}');
      expect(await ServerReachability.probe(uri), ProbeResult.ok);
      expect(ServerReachability.isCachedOk(uri), isTrue);
      await sub.cancel();
      await server.close();
      // Cached success survives the server closing (~20 s TTL).
      expect(await ServerReachability.probe(uri), ProbeResult.ok);
    });

    test('unroutable address fails within the timeout', () async {
      // TEST-NET-1 is never routed: either a timeout or an immediate
      // "no route" depending on the machine. Both must be fast failures.
      final sw = Stopwatch()..start();
      final r = await ServerReachability.probe(
        Uri.parse('http://192.0.2.1:9'),
        timeout: const Duration(milliseconds: 400),
      );
      expect(r, isNot(ProbeResult.ok));
      expect(r, anyOf(ProbeResult.timeout, ProbeResult.unreachable));
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('probeResultForError mapping', () {
      expect(
        probeResultForError(
            const SocketException('x', osError: OSError('refused', 61))),
        ProbeResult.refused,
      );
      expect(
        probeResultForError(
            const SocketException('x', osError: OSError('', 111))),
        ProbeResult.refused,
      );
      expect(
        probeResultForError(const SocketException('Connection timed out')),
        ProbeResult.timeout,
      );
      expect(
        probeResultForError(
            const SocketException('x', osError: OSError('No route', 65))),
        ProbeResult.unreachable,
      );
      expect(
        probeResultForError(
            const SocketException('x', osError: OSError('Host is down', 64))),
        ProbeResult.unreachable,
      );
    });

    test('portFor defaults', () {
      expect(portFor(Uri.parse('http://a')), 80);
      expect(portFor(Uri.parse('https://a')), 443);
      expect(portFor(Uri.parse('http://a:1234')), 1234);
    });
  });

  group('NetworkPreflightError', () {
    test('offline round-trips', () {
      final i = NetworkPreflightError.parse(NetworkPreflightError.offlineMessage);
      expect(i?.kind, NetworkIssueKind.offline);
    });

    test('needs Wi‑Fi round-trips provider + host', () {
      final msg =
          NetworkPreflightError.needsWifiMessage('LM Studio', '192.168.1.5');
      final i = NetworkPreflightError.parse(msg);
      expect(i?.kind, NetworkIssueKind.needsWifi);
      expect(i?.provider, 'LM Studio');
      expect(i?.host, '192.168.1.5');
    });

    test('lost Wi‑Fi round-trips provider', () {
      final i = NetworkPreflightError.parse(
          NetworkPreflightError.lostWifiMessage('Ollama'));
      expect(i?.kind, NetworkIssueKind.lostWifi);
      expect(i?.provider, 'Ollama');
    });

    test('detail tag matches, unrelated text does not', () {
      expect(
        NetworkPreflightError.matches(
            'Something\n\nNetwork check: no answer from 1.2.3.4:80'),
        isTrue,
      );
      expect(NetworkPreflightError.matches('Model not found'), isFalse);
      expect(NetworkPreflightError.matches(null), isFalse);
    });
  });

  group('proactiveNetworkIssue', () {
    NetworkIssueKind? p({
      String kind = 'lmStudio',
      String url = 'http://192.168.1.5:1234',
      bool remote = false,
      bool usb = false,
      bool offline = false,
      bool lan = false,
      bool vpn = false,
      bool lanCheck = true,
    }) =>
        proactiveNetworkIssue(
          providerKind: kind,
          serverUrl: url,
          isRemoteActive: remote,
          usbModeEnabled: usb,
          isOffline: offline,
          hasLocalNetwork: lan,
          hasVpn: vpn,
          lanCheck: lanCheck,
        );

    test('LAN provider on mobile data → needsWifi', () {
      expect(p(), NetworkIssueKind.needsWifi);
    });
    test('Wi‑Fi, VPN or Remote Access → nothing', () {
      expect(p(lan: true), isNull);
      expect(p(vpn: true), isNull);
      expect(p(remote: true), isNull);
    });
    test('offline → offline for server providers', () {
      expect(p(offline: true), NetworkIssueKind.offline);
      expect(
        p(kind: 'cloud', url: 'https://api.openai.com', offline: true),
        NetworkIssueKind.offline,
      );
    });
    test('on-device / USB / localhost → never', () {
      expect(p(kind: 'onDeviceGguf', offline: true), isNull);
      expect(p(kind: 'appleIntelligence', offline: true), isNull);
      expect(p(usb: true, offline: true), isNull);
      expect(p(url: 'http://localhost:1234', offline: true), isNull);
    });
    test('group chats only get the offline banner', () {
      expect(p(lanCheck: false), isNull);
      expect(p(lanCheck: false, offline: true), NetworkIssueKind.offline);
    });
  });

  group('StreamingPhase connecting', () {
    test('kept verbatim and replaced by the next stage', () {
      const s = 'Connecting to LM Studio…';
      expect(StreamingPhase.isConnecting(s), isTrue);
      expect(StreamingPhase.isConnecting('Connecting to MCP...'), isFalse);
      expect(StreamingPhase.canonical(s), s);
      expect(StreamingPhase.connectingTarget(s), 'LM Studio');

      final log = <String>[];
      StreamingPhase.record(log, StreamingPhase.canonical(s)!);
      expect(log, [s]);
      StreamingPhase.record(
          log, StreamingPhase.canonical('Sending request...')!);
      expect(log, [StreamingPhase.processingPrompt]);
    });
  });
}
