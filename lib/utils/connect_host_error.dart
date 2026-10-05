import '../services/local_network_service.dart';
import 'lan_server_error.dart';
import 'localhost_connection_error.dart';

/// Why a 502/503 from Connect / Share with phone happened.
enum ConnectHostErrorKind { shareWithPhone, usb, lanHostDown }

/// Cloudflare / relay 502 when the Mac is not on Share with phone.
///
/// Mini reached the internet, but the Mac was not Connected on the relay.
/// That is setup help, not a Mini crash. Do not Send to support.
abstract final class ConnectHostError {
  static const userMessage =
      "Can't reach your Mac. Open Share with phone in LM Mini Home "
      'and wait until it says Connected.';

  static const usbUserMessage =
      'Connect your iPhone to your Mac with a USB cable, then open LM Mini '
      'on Mac and enable Share with phone (USB bridge).';

  static final _gatewayStatus = RegExp(
    r'(?:failed to load models|failed to load model|'
    r'server returned|homesync:\s*http|error code|'
    r'status(?:\s*code)?|bad gateway|http)[:\s]*50[23]\b',
    caseSensitive: false,
  );

  static bool isRelayUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.contains('lm-mini-relay') ||
        lower.contains('connect.lmmini.com') ||
        lower.contains('relay.lmmini.com') ||
        RegExp(r'run\.app/s/').hasMatch(lower);
  }

  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    if (s.contains("can't reach your mac") ||
        s.contains('cannot reach your mac') ||
        s.contains('cant reach your mac')) {
      return true;
    }
    if (s.contains('open share with phone in lm mini home')) return true;
    if (s.contains('usb bridge')) return true;
    if (s.contains('error code: 502') || s.contains('error code: 503')) {
      return true;
    }
    if (s.contains('bad gateway') || s.contains('cloudflare')) {
      return s.contains('502') || s.contains('503');
    }
    return _gatewayStatus.hasMatch(s);
  }

  static ConnectHostErrorKind? classify({
    required Object? error,
    String? serverUrl,
    bool isRemoteActive = false,
    bool usbModeEnabled = false,
  }) {
    if (!matches(error)) return null;
    if (usbModeEnabled) return ConnectHostErrorKind.usb;
    if (isRemoteActive || isRelayUrl(serverUrl)) {
      return ConnectHostErrorKind.shareWithPhone;
    }
    if (serverUrl != null &&
        serverUrl.isNotEmpty &&
        LocalNetworkService.isLocalNetworkUrl(serverUrl) &&
        !LocalhostConnectionError.isLoopbackHost(
          Uri.tryParse(serverUrl)?.host,
        )) {
      return ConnectHostErrorKind.lanHostDown;
    }
    return ConnectHostErrorKind.shareWithPhone;
  }

  static String? userMessageFor(
    Object? error, {
    String? serverUrl,
    bool isRemoteActive = false,
    bool usbModeEnabled = false,
  }) {
    final kind = classify(
      error: error,
      serverUrl: serverUrl,
      isRemoteActive: isRemoteActive,
      usbModeEnabled: usbModeEnabled,
    );
    return switch (kind) {
      ConnectHostErrorKind.shareWithPhone => userMessage,
      ConnectHostErrorKind.usb => usbUserMessage,
      ConnectHostErrorKind.lanHostDown => LanServerError.hostDownUserMessage,
      null => null,
    };
  }
}
