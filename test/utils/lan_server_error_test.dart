import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/lan_server_error.dart';
import 'package:lm_mini/utils/localhost_connection_error.dart';

void main() {
  group('LanServerError', () {
    const refused = 'ClientException with SocketException: Connection refused '
        '(OS Error: Connection refused, errno = 61), address = 10.20.30.160, '
        'uri=http://10.20.30.160:1234/api/v1/models';
    const hostDown = 'ClientException with SocketException: Host is down '
        '(OS Error: Host is down, errno = 64), address = 192.168.0.2, '
        'uri=http://192.168.0.2:1234/api/v1/models';

    test('classifies iOS connection refused as LAN not served', () {
      expect(
        LanServerError.classify(refused),
        LanServerErrorKind.connectionRefused,
      );
    });

    test('classifies iOS host is down', () {
      expect(LanServerError.classify(hostDown), LanServerErrorKind.hostDown);
    });

    test('does not classify an LM Studio API error', () {
      expect(
        LanServerError.classify(
          '{"error":{"message":"File Not Found","type":"not_found_error"}}',
        ),
        isNull,
      );
    });

    test('shows LMS screenshot help on a LAN IP, not localhost', () {
      expect(
        LanServerError.shouldShowLmStudioLanHelp(
          error: refused,
          serverUrl: 'http://10.20.30.160:1234',
          providerKind: 'lmStudio',
        ),
        isTrue,
      );
      expect(
        LocalhostConnectionError.matches(
          refused,
          serverUrl: 'http://10.20.30.160:1234',
        ),
        isFalse,
      );
      expect(
        LanServerError.shouldShowLmStudioLanHelp(
          error: refused,
          serverUrl: 'http://127.0.0.1:1234',
          providerKind: 'lmStudio',
        ),
        isFalse,
      );
      expect(
        LanServerError.shouldShowLmStudioLanHelp(
          error: refused,
          serverUrl: 'http://10.20.30.160:1234',
          providerKind: 'ollama',
        ),
        isFalse,
      );
    });
  });
}
