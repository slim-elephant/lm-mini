import 'localhost_connection_error.dart';
import '../services/local_network_service.dart';

/// Why a LAN socket to LM Studio (or another local server) failed.
///
/// Connection refused means we reached the machine but nothing is accepting
/// the port — usually LM Studio's "Serve on Local Network" is off.
/// Host is down means the machine itself did not answer — often asleep or off.
enum LanServerErrorKind { connectionRefused, hostDown }

/// Classifies errno 61 / 64 style LAN failures for in-app setup help.
///
/// These are not Mini crashes. Do not Send to support.
abstract final class LanServerError {
  static const refusedUserMessage =
      'Your PC is not allowing connections. In LM Studio, open Developer → '
      'Server Settings and turn on Serve on Local Network.';

  static const hostDownUserMessage =
      "Can't reach your PC. Make sure it is on, then in LM Studio open "
      'Developer → Server Settings and turn on Serve on Local Network.';

  static const assetPath = 'assets/images/lm_studio_network_settings.png';

  static LanServerErrorKind? classify(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return null;

    if (s.contains('host is down') ||
        s.contains('errno = 64') ||
        s.contains('errno=64') ||
        s.contains('ehostdown')) {
      return LanServerErrorKind.hostDown;
    }

    if (s.contains("can't reach your pc") ||
        s.contains('cannot reach your pc') ||
        s.contains('make sure it is on')) {
      return LanServerErrorKind.hostDown;
    }

    if (s.contains('not allowing connections')) {
      return LanServerErrorKind.connectionRefused;
    }

    if (s.contains('connection refused') ||
        s.contains('errno = 61') ||
        s.contains('errno=61') ||
        s.contains('errno = 111') ||
        s.contains('errno=111') ||
        s.contains('econnrefused')) {
      return LanServerErrorKind.connectionRefused;
    }

    return null;
  }

  static bool matches(Object? error) => classify(error) != null;

  /// LMS-specific screenshot + Serve on Local Network copy.
  ///
  /// Requires a LAN URL (not localhost, not Connect/relay) and the LM Studio
  /// provider. Localhost is [LocalhostConnectionError] instead.
  static bool shouldShowLmStudioLanHelp({
    required Object? error,
    String? serverUrl,
    String? providerKind,
  }) {
    if (providerKind != null && providerKind != 'lmStudio') return false;
    if (classify(error) == null) return false;
    if (LocalhostConnectionError.matches(error, serverUrl: serverUrl)) {
      return false;
    }
    if (serverUrl == null || serverUrl.isEmpty) return false;
    return LocalNetworkService.isLocalNetworkUrl(serverUrl);
  }
}
