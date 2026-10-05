import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_notification_service.dart';
import 'model_download_platform.dart';

/// Lock-screen / notification progress for Hugging Face model downloads.
///
/// Free for every user. Chat-generation Live Activity stays Pro and is gated
/// separately by [AppSettings.liveActivityEnabled].
///
/// - **iOS 16.2+**: ActivityKit Live Activity (Lock Screen + Dynamic Island).
/// - **Android**: ongoing progress notification.
class DownloadProgressActivity {
  DownloadProgressActivity._();
  static final DownloadProgressActivity instance = DownloadProgressActivity._();

  bool _active = false;
  DateTime? _lastUpdate;
  String _displayName = 'Download';
  double _progress = 0;
  String _statusText = 'Downloading…';

  bool get isActive => _active;

  bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Ask Android 13+ for notifications before a native foreground download.
  Future<void> prepareAndroidPermission() async {
    if (!Platform.isAndroid) return;
    await AppNotificationService.instance.requestPermissionIfNeeded();
  }

  Future<void> start({required String displayName}) async {
    if (!_supported) return;
    _displayName = displayName.trim().isEmpty ? 'Download' : displayName.trim();
    _active = true;
    _lastUpdate = null;
    _progress = 0;
    _statusText = 'Starting…';

    if (Platform.isIOS) {
      await ModelDownloadPlatform.instance.startDownloadLiveActivity(
        displayName: _displayName,
      );
      return;
    }

    await AppNotificationService.instance.requestPermissionIfNeeded();
    await AppNotificationService.instance.showDownloadProgress(
      title: _displayName,
      body: 'Starting…',
      progressPct: 0,
    );
  }

  Future<void> update({
    required double progress,
    String? statusText,
  }) async {
    if (!_active || !_supported) return;

    final clamped = progress.clamp(0.0, 1.0);
    final pct = (clamped * 100).round();
    // Percent is rendered once from `progress` on the Live Activity.
    // Don't send "12%" here or the banner shows two different numbers.
    final raw = statusText?.trim() ?? '';
    final isPercentOnly = RegExp(r'^\d{1,3}%$').hasMatch(raw);
    final text = (raw.isNotEmpty && !isPercentOnly) ? raw : 'Downloading…';
    _progress = clamped;
    _statusText = text;

    final now = DateTime.now();
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!).inMilliseconds < 400) {
      return;
    }
    _lastUpdate = now;

    if (Platform.isIOS) {
      await ModelDownloadPlatform.instance.updateDownloadLiveActivity(
        displayName: _displayName,
        progress: clamped,
        statusText: text,
      );
      return;
    }

    await AppNotificationService.instance.showDownloadProgress(
      title: _displayName,
      body: text,
      progressPct: pct,
    );
  }

  Future<void> end({bool success = true, bool cancelled = false}) async {
    if (!_active) return;
    _active = false;
    _lastUpdate = null;
    final name = _displayName;
    _displayName = 'Download';
    _progress = 0;
    _statusText = 'Downloading…';

    if (Platform.isIOS) {
      await ModelDownloadPlatform.instance.endDownloadLiveActivity(
        success: success,
      );
      return;
    }

    await AppNotificationService.instance.endDownloadProgress(
      title: name,
      body: cancelled
          ? 'Download cancelled'
          : success
              ? 'Download complete'
              : 'Download failed',
    );
  }

  /// Recreate the iOS Live Activity after the app was opened (which ends it).
  Future<void> reassertIfNeeded() async {
    if (!_active || !_supported || !Platform.isIOS) return;
    await ModelDownloadPlatform.instance.startDownloadLiveActivity(
      displayName: _displayName,
      progress: _progress,
      statusText: _statusText,
    );
  }
}
