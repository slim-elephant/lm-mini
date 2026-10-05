import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../runtime/desktop_runtime_manager.dart';
import '../../screens/settings_screen.dart';
import '../../utils/app_navigator.dart';
import '../desktop_platform.dart';
import '../ui/desktop_host_screen.dart';

/// Desktop tray for host status (Connect parity).
///
/// macOS: native `NSStatusItem`. Windows: Win32 notify icon.
/// Same method channel — no third-party tray package.
class DesktopTrayService {
  DesktopTrayService._();
  static final DesktopTrayService instance = DesktopTrayService._();

  static const _channel = MethodChannel('lm_mini/desktop_tray');

  bool _initialized = false;

  bool get _supported =>
      DesktopPlatform.supportsHostMode &&
      (Platform.isMacOS || Platform.isWindows);

  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleCall);
    try {
      await _channel.invokeMethod('ensureTray');
      await updateStatus(
        sharing: false,
        connected: false,
        usbConnected: false,
        tooltip: 'LM Mini Home',
      );
    } catch (e) {
      debugPrint('🖥️ DesktopTray: ensureTray failed: $e');
    }
  }

  Future<void> updateStatus({
    required bool sharing,
    required bool connected,
    bool usbConnected = false,
    required String tooltip,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('setStatus', {
        'sharing': sharing,
        'connected': connected,
        'usbConnected': usbConnected,
        'tooltip': tooltip,
      });
    } catch (e) {
      debugPrint('🖥️ DesktopTray: setStatus failed: $e');
    }
  }

  /// When true, closing the last window keeps the app alive (tray mode).
  Future<void> setKeepAlive(bool enabled) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('setKeepAlive', {'enabled': enabled});
    } catch (e) {
      debugPrint('🖥️ DesktopTray: setKeepAlive failed: $e');
    }
  }

  Future<void> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'showWindow':
        // Native already ordered the window front.
        break;
      case 'openHost':
        _openHostScreen();
      case 'openSettings':
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      case 'quit':
        await DesktopRuntimeManager.instance.stop();
        await _channel.invokeMethod('terminate');
      default:
        break;
    }
  }

  void _openHostScreen() {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const DesktopHostScreen()),
    );
  }
}
