// LM-MINI-PRO-STUB
import 'package:flutter/widgets.dart';

/// Public-build stand-in for the Pro App Lock service. App Lock is never
/// enabled, so the app never locks and recovery binding is a no-op.
class AppLockService extends ChangeNotifier {
  AppLockService();

  static AppLockService? _instance;
  static AppLockService get instance => _instance ??= AppLockService();

  Future<void> load() async {}

  bool get isEnabled => false;

  int get timeoutSeconds => 0;

  Future<void> bindRecoveryIfUnlocked({
    required String uid,
    String? email,
  }) async {}
}
