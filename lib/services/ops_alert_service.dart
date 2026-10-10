import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_admin_config.dart';
import 'app_notification_service.dart';

/// Admin-only push notifications for server ops alerts (Pro Search down,
/// relay stuck, recoveries).
///
/// A Cloud Function sends FCM messages with `data.type == 'ops_alert'` to
/// every token in `ops_admin_devices`. This service registers the current
/// device there while an app admin is signed in and unregisters it when the
/// user is no longer an admin. Regular users never see a permission prompt
/// and never get an FCM token (auto-init is off in the native configs).
///
/// Platforms: iOS and Android only. macOS is a deliberate platform guard:
/// FCM on macOS needs its own APNs entitlement + key setup and admins get the
/// alerts on their phones; the Mac app shows nothing for this admin-only tool.
class OpsAlertService {
  OpsAlertService._();
  static final OpsAlertService instance = OpsAlertService._();

  static const _prefsTokenKey = 'ops_alert.token';
  static const _collection = 'ops_admin_devices';
  static const _channelId = 'ops_alerts';
  static const _channelName = 'Ops alerts';
  static const _channelDescription = 'Server status alerts for app admins';

  Future<void> _queue = Future.value();
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  bool _channelReady = false;

  static bool get _supportedPlatform =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Registers or unregisters this device for ops alerts based on the
  /// current Firebase user. Safe to call repeatedly; calls are serialized.
  /// Never throws.
  Future<void> syncForCurrentUser() {
    final next = _queue.then((_) => _sync()).catchError((Object e) {
      debugPrint('🚨 OpsAlert: sync failed: $e');
    });
    _queue = next;
    return next;
  }

  Future<void> _sync() async {
    if (!_supportedPlatform || !PremiumConfig.firebaseReady) return;

    final user = FirebaseAuth.instance.currentUser;
    if (AppAdminConfig.isAdmin(user?.uid)) {
      await _register(user!.uid);
    } else {
      await _unregister();
    }
  }

  Future<void> _register(String uid) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('🚨 OpsAlert: notification permission denied');
    }

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!await _waitForApnsToken(messaging)) {
        debugPrint('🚨 OpsAlert: no APNs token yet; will retry next sync');
        return;
      }
    } else {
      await _ensureAndroidChannel();
      _foregroundSub ??= FirebaseMessaging.onMessage.listen(_showForeground);
    }

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('🚨 OpsAlert: FCM returned no token');
      return;
    }
    await _writeToken(token, uid);

    _tokenRefreshSub ??= messaging.onTokenRefresh.listen((newToken) {
      unawaited(_onTokenRefresh(newToken));
    });
  }

  Future<bool> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  Future<void> _writeToken(String token, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_prefsTokenKey);
    final firestore = FirebaseFirestore.instance;

    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}

    await firestore.collection(_collection).doc(token).set({
      'uid': uid,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updatedAt': FieldValue.serverTimestamp(),
      if (appVersion != null) 'appVersion': appVersion,
    });
    await prefs.setString(_prefsTokenKey, token);
    debugPrint('🚨 OpsAlert: registered device for ops alerts');

    if (previous != null && previous != token) {
      try {
        await firestore.collection(_collection).doc(previous).delete();
      } catch (e) {
        debugPrint('🚨 OpsAlert: could not delete old token doc: $e');
      }
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (!AppAdminConfig.isAdmin(uid)) return;
      await _writeToken(token, uid!);
    } catch (e) {
      debugPrint('🚨 OpsAlert: token refresh write failed: $e');
    }
  }

  Future<void> _unregister() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundSub?.cancel();
    _foregroundSub = null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsTokenKey);
    if (token == null) return;

    // Firestore rules only let admins delete, so this fails after a switch to
    // a non-admin account. Deleting the FCM token below invalidates it either
    // way; the sender prunes unregistered tokens.
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(token)
          .delete();
    } catch (e) {
      debugPrint('🚨 OpsAlert: could not delete token doc: $e');
    }
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.deleteToken();
      await messaging.setAutoInitEnabled(false);
    } catch (e) {
      debugPrint('🚨 OpsAlert: could not delete FCM token: $e');
    }
    await prefs.remove(_prefsTokenKey);
    debugPrint('🚨 OpsAlert: unregistered device from ops alerts');
  }

  Future<void> _ensureAndroidChannel() async {
    if (_channelReady) return;
    await AppNotificationService.instance.initialize();
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    _channelReady = true;
  }

  /// Android does not display FCM notifications while the app is in the
  /// foreground, so mirror them as a local notification. iOS uses the
  /// foreground presentation options instead.
  Future<void> _showForeground(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;
      await _ensureAndroidChannel();
      // One slot per component, so "recovered" replaces "down".
      final component = message.data['component'] ?? 'other';
      await FlutterLocalNotificationsPlugin().show(
        'ops_alert.$component'.hashCode & 0x7fffffff,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('🚨 OpsAlert: foreground notification failed: $e');
    }
  }
}
