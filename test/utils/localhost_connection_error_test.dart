import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/localhost_connection_error.dart';

void main() {
  group('LocalhostConnectionError', () {
    test('matches the iOS phone-to-localhost SocketException', () {
      const raw = 'ClientException with SocketException: Connection refused '
          '(OS Error: Connection refused, errno = 61), address = localhost, '
          'port = 54224, uri=http://localhost:1234/api/v1/models';
      expect(LocalhostConnectionError.matches(raw), isTrue);
    });

    test('matches connection refused when the saved URL is loopback', () {
      expect(
        LocalhostConnectionError.matches(
          'SocketException: Connection refused',
          serverUrl: 'http://127.0.0.1:11434',
        ),
        isTrue,
      );
    });

    test('does not match a real LM Studio API error on a LAN IP', () {
      expect(
        LocalhostConnectionError.matches(
          'Model returned empty response. Try disabling tools.',
          serverUrl: 'http://192.168.1.10:1234',
        ),
        isFalse,
      );
    });

    test('does not match connection refused to a LAN IP', () {
      expect(
        LocalhostConnectionError.matches(
          'ClientException with SocketException: Connection refused, '
          'address = 192.168.1.10, uri=http://192.168.1.10:1234/api/v1/models',
          serverUrl: 'http://192.168.1.10:1234',
        ),
        isFalse,
      );
    });

    test('matches the friendly copy so rewritten banners stay gated', () {
      expect(
        LocalhostConnectionError.matches(LocalhostConnectionError.userMessage),
        isTrue,
      );
    });
  });
}
