// LM-MINI-PRO-STUB
part of '../../services/home_sync_service.dart';

/// Public build: the phone-side Home sync client is part of the official app
/// (it needs Remote Access pairing). The Mac host still serves GET snapshots;
/// a POST merge is answered but not persisted.
extension _ProHomeSyncClient on HomeSyncService {
  Future<HomeSyncPreview> _proPreview() async =>
      const HomeSyncPreview(localChats: 0, localFolders: 0);

  Future<HomeSyncSnapshot?> _proFetchRemoteSnapshot() async => null;

  Future<bool> _proSyncNow() async => false;

  Future<bool> _proApplySnapshot(
    HomeSyncSnapshot before,
    HomeSyncSnapshot merged,
  ) async =>
      false;
}
