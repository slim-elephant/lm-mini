import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/desktop/host/desktop_relay_client.dart';

void main() {
  group('desktopRelayBackoff', () {
    test('grows then caps at 15s', () {
      expect(desktopRelayBackoff(0), const Duration(seconds: 1));
      expect(desktopRelayBackoff(1), const Duration(seconds: 2));
      expect(desktopRelayBackoff(2), const Duration(seconds: 4));
      expect(desktopRelayBackoff(3), const Duration(seconds: 8));
      expect(desktopRelayBackoff(4), const Duration(seconds: 15));
      expect(desktopRelayBackoff(9), const Duration(seconds: 15));
    });
  });

  group('desktopRelayShouldReplaceSocket', () {
    final now = DateTime.utc(2026, 9, 16, 15);

    test('force always replaces (laptop wake)', () {
      expect(
        desktopRelayShouldReplaceSocket(
          force: true,
          connected: true,
          socketOpen: true,
          lastMessageAt: now.subtract(const Duration(seconds: 2)),
          now: now,
        ),
        isTrue,
      );
    });

    test('replaces a socket that is down or not open', () {
      expect(
        desktopRelayShouldReplaceSocket(
          force: false,
          connected: false,
          socketOpen: false,
          lastMessageAt: now,
          now: now,
        ),
        isTrue,
      );
      expect(
        desktopRelayShouldReplaceSocket(
          force: false,
          connected: true,
          socketOpen: false,
          lastMessageAt: now,
          now: now,
        ),
        isTrue,
      );
    });

    test('replaces a half-open socket that has gone silent', () {
      expect(
        desktopRelayShouldReplaceSocket(
          force: false,
          connected: true,
          socketOpen: true,
          lastMessageAt: now.subtract(const Duration(seconds: 61)),
          now: now,
        ),
        isTrue,
      );
    });

    test('keeps a live socket that still receives traffic', () {
      expect(
        desktopRelayShouldReplaceSocket(
          force: false,
          connected: true,
          socketOpen: true,
          lastMessageAt: now.subtract(const Duration(seconds: 20)),
          now: now,
        ),
        isFalse,
      );
    });

    test('replaces when there has never been a message', () {
      expect(
        desktopRelayShouldReplaceSocket(
          force: false,
          connected: true,
          socketOpen: true,
          lastMessageAt: null,
          now: now,
        ),
        isTrue,
      );
    });
  });
}
