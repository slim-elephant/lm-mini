import 'server_reachability.dart';

/// Phone-side network problems found before (or during) a chat request:
/// offline, on mobile data with a home-LAN server, or Wi‑Fi lost mid-reply.
///
/// These are not Mini crashes. Do not Send to support.
enum NetworkIssueKind { offline, needsWifi, lostWifi }

class NetworkIssue {
  final NetworkIssueKind kind;

  /// Provider label, e.g. "LM Studio". Empty for [NetworkIssueKind.offline].
  final String provider;

  /// LAN host, e.g. "192.168.1.5". Empty when unknown.
  final String host;

  const NetworkIssue(this.kind, {this.provider = '', this.host = ''});
}

/// Thrown by ChatProvider's preflight so the normal error path runs
/// (user message stays, placeholder removed, Stop hidden, banner shown).
class NetworkPreflightException implements Exception {
  final String message;
  final String? detail;

  const NetworkPreflightException(this.message, {this.detail});

  @override
  String toString() => message;
}

abstract final class NetworkPreflightError {
  /// Tag on technical details so the support button stays hidden.
  static const detailPrefix = 'Network check:';

  static const offlineMessage =
      "You're offline. Connect to Wi-Fi or mobile data and try again.";

  static String needsWifiMessage(String provider, String host) =>
      "You're on mobile data. $provider on your computer ($host) is only "
      'reachable on the same Wi-Fi network as your computer. Connect to that '
      'Wi-Fi, or turn on Remote Access to use it from anywhere.';

  static String lostWifiMessage(String provider) =>
      'Lost connection to $provider — your phone left the Wi-Fi.';

  /// Current copy and the older "home Wi-Fi" wording (messages already
  /// stored in chats / support logs must still parse).
  static final RegExp _needsWifi = RegExp(
    r"You're on mobile data\. (.+?) on your computer \((.*?)\) is only "
    r'reachable on (?:your home Wi[-\u2011]Fi|the same Wi[-\u2011]Fi network '
    r'as your computer)\.',
  );
  static final RegExp _lostWifi = RegExp(
    r'Lost connection to (.+?) — your phone left the Wi[-\u2011]Fi\.',
  );

  /// Parse one of our own messages back into a [NetworkIssue].
  static NetworkIssue? parse(Object? error) {
    final s = error?.toString() ?? '';
    if (s.isEmpty) return null;
    if (s.contains(offlineMessage)) {
      return const NetworkIssue(NetworkIssueKind.offline);
    }
    final needs = _needsWifi.firstMatch(s);
    if (needs != null) {
      return NetworkIssue(
        NetworkIssueKind.needsWifi,
        provider: needs.group(1) ?? '',
        host: needs.group(2) ?? '',
      );
    }
    final lost = _lostWifi.firstMatch(s);
    if (lost != null) {
      return NetworkIssue(
        NetworkIssueKind.lostWifi,
        provider: lost.group(1) ?? '',
      );
    }
    return null;
  }

  /// Our offline / mobile-data / lost-Wi‑Fi copy, or a preflight detail.
  static bool matches(Object? error) {
    if (parse(error) != null) return true;
    final s = error?.toString() ?? '';
    return s.contains(detailPrefix);
  }
}

/// Which proactive chat banner to show for the current connection, if any.
///
/// * Fully offline → [NetworkIssueKind.offline] for any server-backed chat.
/// * LAN server, no Remote Access, no Wi‑Fi/Ethernet, no VPN →
///   [NetworkIssueKind.needsWifi].
/// * On-device / Apple Intelligence / USB / localhost → never.
NetworkIssueKind? proactiveNetworkIssue({
  required String providerKind,
  required String serverUrl,
  required bool isRemoteActive,
  required bool usbModeEnabled,
  required bool isOffline,
  required bool hasLocalNetwork,
  required bool hasVpn,
  bool lanCheck = true,
}) {
  if (providerKind == 'onDeviceGguf' ||
      providerKind == 'onDeviceMlx' ||
      providerKind == 'appleIntelligence') {
    return null;
  }
  if (usbModeEnabled) return null;
  final scope = isRemoteActive ? HostScope.public : classifyHost(serverUrl);
  if (scope == HostScope.loopback) return null;
  if (isOffline) return NetworkIssueKind.offline;
  if (lanCheck &&
      scope == HostScope.localNetwork &&
      !hasLocalNetwork &&
      !hasVpn) {
    return NetworkIssueKind.needsWifi;
  }
  return null;
}
