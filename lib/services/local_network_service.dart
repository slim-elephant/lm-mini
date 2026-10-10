import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service to detect local network access permission status on iOS.
///
/// iOS 14+ requires apps to have explicit permission to access the local network.
/// There's no direct API to check the permission status — instead we detect it
/// by attempting a lightweight local network operation and interpreting errors.
class LocalNetworkService {
  /// Check if the given URL points to a local/private network address
  static bool isLocalNetworkUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;

      // Check for common local addresses
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return false; // localhost doesn't need local network permission
      }

      // Check for private IP ranges
      final parts = host.split('.');
      if (parts.length == 4) {
        final first = int.tryParse(parts[0]) ?? 0;
        final second = int.tryParse(parts[1]) ?? 0;

        // 10.x.x.x
        if (first == 10) return true;
        // 172.16.x.x - 172.31.x.x
        if (first == 172 && second >= 16 && second <= 31) return true;
        // 192.168.x.x
        if (first == 192 && second == 168) return true;
      }

      // Check for .local domains (Bonjour)
      if (host.endsWith('.local')) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Attempt to detect if local network access permission is likely denied.
  ///
  /// This works by trying to connect to the given local IP address.
  /// On iOS, if the local network permission hasn't been granted yet,
  /// the system will show the permission dialog on the first attempt.
  /// If the user previously denied, the connection will silently fail.
  ///
  /// Returns:
  /// - `true` if local network access appears to be available
  /// - `false` if it appears denied or cannot be determined
  static Future<bool> checkLocalNetworkAccess(String host, int port) async {
    if (!Platform.isIOS) return true; // Only relevant on iOS

    try {
      // Try a TCP connection with a short timeout
      // This will trigger the local network permission dialog if not yet shown
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } on SocketException catch (e) {
      // "Connection refused" means we reached the network but nothing's listening
      // This still means local network permission IS granted
      if (e.osError?.errorCode == 61 || // Connection refused (macOS/iOS)
          e.osError?.errorCode == 111 || // Connection refused (Linux)
          e.message.contains('Connection refused')) {
        return true;
      }

      // "Network is unreachable" or "No route to host" could mean permission denied
      // But could also mean the device isn't on the right network
      debugPrint(
          'LocalNetworkService: SocketException: ${e.message} (code: ${e.osError?.errorCode})');
      return false;
    } on TimeoutException {
      // Timeout could mean:
      // 1. Local network permission denied (iOS silently blocks)
      // 2. Host is unreachable (different network, firewall)
      // We can't distinguish these cases, but we return false to trigger the help dialog
      debugPrint(
          'LocalNetworkService: Connection timed out — possible local network permission issue');
      return false;
    } catch (e) {
      debugPrint('LocalNetworkService: Unexpected error: $e');
      return false;
    }
  }

  /// Analyze a connection error to determine if it's likely a local network
  /// permission issue on iOS.
  ///
  /// Returns true if the error pattern suggests the user needs to enable
  /// local network access in iOS Settings.
  static bool isLikelyLocalNetworkPermissionIssue(String errorMessage) {
    if (!Platform.isIOS) return false;
    return matchesPermissionSignature(errorMessage);
  }

  /// Error text that looks like iOS silently blocking LAN sockets. Platform
  /// independent (for tests); callers must also check iOS, Wi‑Fi and a LAN
  /// host — see `resolveConnectionIssue`.
  static bool matchesPermissionSignature(String errorMessage) {
    // Permission denied usually times out or has no route. Connection refused
    // means we reached the PC (LMS isn't serving). Host is down means the
    // machine is off/asleep — those get LMS setup help, not this iOS sheet.
    final permissionPatterns = [
      'Connection timed out',
      'No route to host',
      'Network is unreachable',
      'Operation timed out',
      'errno = 65', // No route to host
      'errno = 51', // Network is unreachable
    ];

    final lowerError = errorMessage.toLowerCase();
    return permissionPatterns.any(
      (pattern) => lowerError.contains(pattern.toLowerCase()),
    );
  }
}
