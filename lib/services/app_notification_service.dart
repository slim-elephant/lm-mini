import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Lightweight local notifications for admin-granted premium and similar events.
class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  static const _premiumChannelId = 'lmmini_premium_grants';
  static const _premiumNotificationId = 9101;
  static const _downloadChannelId = 'lmmini_hf_download';
  static const _downloadNotificationId = 9003;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        ),
      );

      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            _premiumChannelId,
            'Premium gifts',
            description:
                'Notifications when you receive complimentary Pro access',
            importance: Importance.high,
          ),
        );
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            _downloadChannelId,
            'Hugging Face downloads',
            description: 'Shows progress while a model downloads',
            importance: Importance.low,
            playSound: false,
            showBadge: false,
          ),
        );
      }

      _initialized = true;
    } catch (e, st) {
      debugPrint('⚠️ AppNotificationService.initialize failed: $e\n$st');
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    if (!_initialized) await initialize();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    if (Platform.isMacOS) {
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final granted = await mac?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  Future<void> showPremiumGrantNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _premiumChannelId,
      'Premium gifts',
      channelDescription:
          'Notifications when you receive complimentary Pro access',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      _premiumNotificationId,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
    );
  }

  /// Ongoing Android progress notification for Hugging Face / on-device
  /// downloads. Free for every user — not the Pro generation Live Activity.
  Future<void> showDownloadProgress({
    required String title,
    required String body,
    required int progressPct,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_initialized) await initialize();
    if (!_initialized) return;

    final indeterminate = progressPct <= 0;
    final androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      'Hugging Face downloads',
      channelDescription: 'Shows progress while a model downloads',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progressPct.clamp(0, 100),
      indeterminate: indeterminate,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.progress,
    );

    await _plugin.show(
      _downloadNotificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> endDownloadProgress({
    String? title,
    String? body,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_initialized) return;

    if (title != null && body != null) {
      const androidDetails = AndroidNotificationDetails(
        _downloadChannelId,
        'Hugging Face downloads',
        channelDescription: 'Shows progress while a model downloads',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: false,
        autoCancel: true,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
      );
      await _plugin.show(
        _downloadNotificationId,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
      return;
    }

    await _plugin.cancel(_downloadNotificationId);
  }
}
