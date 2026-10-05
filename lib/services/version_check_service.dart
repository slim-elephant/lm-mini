import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'changelog_service.dart';
import '../utils/semver.dart';

const _defaultAppStoreUrl =
    'https://apps.apple.com/us/app/lm-mini/id6751125309';
const _defaultPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=net.neuro9.lmmini';
const _defaultMinSupportedVersion = '1.3.0';

/// Latest published store build, taken from the Firestore `changelog`
/// collection (same source as the launch dialog). Website
/// `app-version.json` is not used for this banner.
class AppVersionInfo {
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String? deprecationDate;
  final String downloadUrl;
  final String? notes;

  AppVersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.downloadUrl,
    this.deprecationDate,
    this.notes,
  });

  factory AppVersionInfo.fromChangelog(
    ChangelogEntry entry,
    String currentVersion, {
    TargetPlatform? platform,
  }) {
    return AppVersionInfo(
      currentVersion: currentVersion,
      latestVersion: entry.version,
      minSupportedVersion: _defaultMinSupportedVersion,
      downloadUrl: storeUrlForChangelog(entry, platform: platform),
      notes: notesFromChangelog(entry),
    );
  }

  bool get hasUpdate => semverLess(currentVersion, latestVersion);
  bool get isUnsupported => semverLess(currentVersion, minSupportedVersion);
}

String storeUrlForChangelog(
  ChangelogEntry entry, {
  TargetPlatform? platform,
}) {
  final p = platform ?? defaultTargetPlatform;
  switch (p) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      final url = entry.appStoreUrl?.trim();
      return (url != null && url.isNotEmpty) ? url : _defaultAppStoreUrl;
    case TargetPlatform.android:
      final url = entry.playStoreUrl?.trim();
      return (url != null && url.isNotEmpty) ? url : _defaultPlayStoreUrl;
    default:
      return 'https://lmmini.com/download.html';
  }
}

String? notesFromChangelog(ChangelogEntry entry) {
  if (entry.title.isNotEmpty && entry.changes.isNotEmpty) {
    return '${entry.title}. ${entry.changes.first}';
  }
  if (entry.title.isNotEmpty) return entry.title;
  if (entry.changes.isNotEmpty) {
    return entry.changes.take(2).join(' ');
  }
  return null;
}

/// Manifest for LM Mini Connect (https://lmmini.com/connect-version.json).
class ConnectVersionInfo {
  final String? pairedVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String downloadUrl;
  final String? notes;

  ConnectVersionInfo({
    required this.pairedVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.downloadUrl,
    this.notes,
  });

  bool get hasUpdate {
    if (pairedVersion == null || pairedVersion!.isEmpty) return true;
    return semverLess(pairedVersion!, latestVersion);
  }

  bool get isUnsupported {
    if (pairedVersion == null || pairedVersion!.isEmpty) return true;
    return semverLess(pairedVersion!, minSupportedVersion);
  }
}

class VersionCheckService {
  VersionCheckService._();
  static final VersionCheckService instance = VersionCheckService._();

  static const _connectManifestUrl = 'https://lmmini.com/connect-version.json';
  static const _prefsLastCheckKey = 'app_version_last_check_ms';
  static const _prefsDismissedVersionKey = 'app_version_dismissed';
  static const _prefsConnectDismissedKey = 'connect_version_dismissed';
  static const _prefsConnectSnoozeUntilKey = 'connect_version_snooze_until_ms';
  static const connectSnoozeDuration = Duration(days: 7);

  AppVersionInfo? _info;
  AppVersionInfo? get info => _info;

  ConnectVersionInfo? _connectInfo;
  ConnectVersionInfo? get connectInfo => _connectInfo;

  @visibleForTesting
  void debugReset() {
    _info = null;
    _connectInfo = null;
  }

  /// Latest Firestore changelog vs the installed app version.
  /// Safe to call from the home banner — failures are swallowed.
  Future<AppVersionInfo?> check({
    Duration minInterval = const Duration(hours: 12),
    Future<ChangelogEntry?> Function()? fetchLatest,
    String? currentVersion,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_prefsLastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastMs < minInterval.inMilliseconds && _info != null) {
        return _info;
      }

      final installed =
          currentVersion ?? (await PackageInfo.fromPlatform()).version;
      final entry =
          await (fetchLatest ?? ChangelogService().fetchLatest)();
      if (entry == null || entry.version.isEmpty) {
        return _info;
      }

      _info = AppVersionInfo.fromChangelog(entry, installed);
      await prefs.setInt(_prefsLastCheckKey, now);
      return _info;
    } catch (e) {
      if (kDebugMode) debugPrint('VersionCheck failed: $e');
      return _info;
    }
  }

  /// Compare the paired Connect version against the website manifest.
  Future<ConnectVersionInfo?> checkConnect({
    String? pairedVersion,
    Duration minInterval = const Duration(hours: 12),
  }) async {
    try {
      if (_connectInfo != null &&
          _connectInfo!.pairedVersion == pairedVersion) {
        return _connectInfo;
      }

      final response = await http
          .get(Uri.parse(_connectManifestUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return _connectInfo;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _connectInfo = ConnectVersionInfo(
        pairedVersion: pairedVersion,
        latestVersion: (json['latestVersion'] as String?) ?? '1.5.1',
        minSupportedVersion:
            (json['minSupportedVersion'] as String?) ?? '1.3.0',
        downloadUrl: (json['url'] as String?) ??
            (json['downloadUrl'] as String?) ??
            'https://lmmini.com/download.html#mac',
        notes: json['notes'] as String?,
      );
      return _connectInfo;
    } catch (e) {
      if (kDebugMode) debugPrint('Connect version check failed: $e');
      return _connectInfo;
    }
  }

  /// Whether the user explicitly dismissed the banner for this latest version.
  Future<bool> isDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsDismissedVersionKey) == version;
  }

  Future<void> dismiss(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsDismissedVersionKey, version);
  }

  Future<bool> isConnectDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_prefsConnectSnoozeUntilKey) ?? 0;
    if (until > DateTime.now().millisecondsSinceEpoch) return true;
    // Legacy permanent dismiss (pre-snooze) still honored for that version.
    return prefs.getString(_prefsConnectDismissedKey) == version;
  }

  /// Hide the Connect update banner for [connectSnoozeDuration] (7 days).
  Future<void> dismissConnect(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(connectSnoozeDuration).millisecondsSinceEpoch;
    await prefs.setInt(_prefsConnectSnoozeUntilKey, until);
    await prefs.setString(_prefsConnectDismissedKey, version);
  }
}
