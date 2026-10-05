import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/connect_host_error.dart';
import 'package:lm_mini/utils/lan_server_error.dart';

void main() {
  group('ConnectHostError', () {
    const loadModels502 = 'Exception: Failed to load models: 502';
    const cloudflare = 'error code: 502';
    const homeSync = 'HomeSync: HTTP 502';
    const friendly =
        "Can't reach your Mac (502). Open Share with phone in LM Mini Home "
        'and wait until it says Connected.';

    test('matches Cloudflare-style model-list 502', () {
      expect(ConnectHostError.matches(loadModels502), isTrue);
      expect(ConnectHostError.matches(cloudflare), isTrue);
      expect(ConnectHostError.matches(homeSync), isTrue);
      expect(ConnectHostError.matches(friendly), isTrue);
    });

    test('does not match other HTTP failures', () {
      expect(ConnectHostError.matches('Failed to load models: 404'), isFalse);
      expect(ConnectHostError.matches('Failed to load models: 500'), isFalse);
      expect(
        ConnectHostError.matches(
          'ClientException with SocketException: Connection refused',
        ),
        isFalse,
      );
    });

    test('Share with phone help on Connect / relay URLs', () {
      expect(
        ConnectHostError.classify(
          error: loadModels502,
          serverUrl: 'https://connect.lmmini.com/s/abc',
          isRemoteActive: true,
        ),
        ConnectHostErrorKind.shareWithPhone,
      );
      expect(
        ConnectHostError.classify(
          error: cloudflare,
          serverUrl: 'https://relay.lmmini.com/s/xyz',
        ),
        ConnectHostErrorKind.shareWithPhone,
      );
    });

    test('USB waiting copy when USB mode is on', () {
      expect(
        ConnectHostError.classify(
          error: loadModels502,
          serverUrl: 'http://127.0.0.1:1234',
          usbModeEnabled: true,
        ),
        ConnectHostErrorKind.usb,
      );
      expect(
        ConnectHostError.userMessageFor(
          loadModels502,
          usbModeEnabled: true,
        ),
        ConnectHostError.usbUserMessage,
      );
    });

    test('LAN IP 502 uses host-down LMS copy', () {
      expect(
        ConnectHostError.classify(
          error: loadModels502,
          serverUrl: 'http://192.168.1.10:1234',
        ),
        ConnectHostErrorKind.lanHostDown,
      );
      expect(
        ConnectHostError.userMessageFor(
          loadModels502,
          serverUrl: 'http://192.168.1.10:1234',
        ),
        LanServerError.hostDownUserMessage,
      );
    });

    test('rewrites model-list 502 to Share with phone copy', () {
      expect(
        ConnectHostError.userMessageFor(
          loadModels502,
          serverUrl: 'https://connect.lmmini.com/s/abc',
          isRemoteActive: true,
        ),
        ConnectHostError.userMessage,
      );
    });
  });
}
