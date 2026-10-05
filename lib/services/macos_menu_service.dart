import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/settings_screen.dart';
import '../utils/app_navigator.dart';

/// Handles native macOS menu bar actions (Settings… ⌘,).
class MacosMenuService {
  MacosMenuService._();
  static final MacosMenuService instance = MacosMenuService._();

  static const _channel = MethodChannel('lm_mini/macos_menu');

  void initialize() {
    if (!Platform.isMacOS) return;
    _channel.setMethodCallHandler(_handleCall);
  }

  Future<void> _handleCall(MethodCall call) async {
    if (call.method == 'openSettings') {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }
}
