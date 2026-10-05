import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Client OS platform for support tickets and analytics user properties.
enum ClientPlatformKind { ios, android, macos, other }

/// Detects the running platform and captures app version for Firestore support
/// metadata (`platform`, `appVersion`).
class ClientPlatform {
  ClientPlatform._();

  static ClientPlatformKind get kind {
    if (kIsWeb) return ClientPlatformKind.other;
    if (Platform.isIOS) return ClientPlatformKind.ios;
    if (Platform.isAndroid) return ClientPlatformKind.android;
    if (Platform.isMacOS) return ClientPlatformKind.macos;
    return ClientPlatformKind.other;
  }

  /// Stored in Firestore as `ios`, `android`, `macos`, or `other`.
  static String get storageKey => kind.name;

  static bool get isIos => kind == ClientPlatformKind.ios;
  static bool get isAndroid => kind == ClientPlatformKind.android;
  static bool get isMacOS => kind == ClientPlatformKind.macos;

  /// True when running on the iOS Simulator (system Speech often fails here).
  static bool get isIosSimulator {
    if (kIsWeb || !Platform.isIOS) return false;
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
  }

  /// Short label for admin UI chips.
  static String get displayLabel {
    switch (kind) {
      case ClientPlatformKind.ios:
        return 'iOS';
      case ClientPlatformKind.android:
        return 'Android';
      case ClientPlatformKind.macos:
        return 'macOS';
      case ClientPlatformKind.other:
        return 'Other';
    }
  }

  static ClientPlatformKind? parseStorageKey(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in ClientPlatformKind.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  /// Metadata written alongside feature requests and comments.
  static Future<Map<String, String>> supportMetadata() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return {
        'platform': storageKey,
        'appVersion': '${info.version}+${info.buildNumber}',
      };
    } catch (_) {
      return {'platform': storageKey};
    }
  }
}
