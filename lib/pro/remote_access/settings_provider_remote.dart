// LM-MINI-PRO-STUB
part of '../../providers/settings_provider.dart';

/// Public build: no Remote Access engine (LM Mini Connect / Home relay).
/// Deactivate / unpair / pause in [SettingsProvider] still restore the saved
/// local server URL, so LAN profiles and USB Mode keep working.
extension _ProRemoteAccess on SettingsProvider {
  Future<void> _proActivateRemoteAccess(RemoteConnectionInfo info) async {}

  Future<void> _proReactivateRemoteAccess() async {}

  void _proApplyRemoteReachable(Map<String, bool> reachable) {}

  void _proApplyHostStatus({
    required Map<String, bool> reachable,
    String? platform,
    bool? kokoroReady,
    bool? hostStatusOk,
    String? hostStatusError,
  }) {}

  Future<void> _proRefreshRemoteHostStatus() async {}

  Future<void> _proSwitchRemoteBackend(String kind) async {}

  Future<void> _proOnAppResumed() async {}
}
