import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/server_unreachable_error.dart';

void main() {
  group('ServerUnreachableError', () {
    test('matches the iOS LAN EBADF model-list failure', () {
      const raw = 'ClientException with SocketException: Bad file descriptor '
          '(OS Error: Bad file descriptor, errno = 9), address = 192.168.0.2, '
          'port = 1234, uri=http://192.168.0.2:1234/api/v1/models';
      expect(ServerUnreachableError.matches(raw), isTrue);
    });

    test('matches connection refused to a LAN IP', () {
      expect(
        ServerUnreachableError.matches(
          'ClientException with SocketException: Connection refused, '
          'address = 192.168.1.10, uri=http://192.168.1.10:1234/api/v1/models',
        ),
        isTrue,
      );
    });

    test('matches host is down on a LAN IP', () {
      expect(
        ServerUnreachableError.matches(
          'ClientException with SocketException: Host is down '
          '(OS Error: Host is down, errno = 64), address = 192.168.0.2, '
          'uri=http://192.168.0.2:1234/api/v1/models',
        ),
        isTrue,
      );
    });

    test('does not match an LM Studio API / empty-response error', () {
      expect(
        ServerUnreachableError.matches(
          'Context ran out. This prompt is larger than the loaded window '
          '(32768 tokens).',
        ),
        isFalse,
      );
    });
  });
}
