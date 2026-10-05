// LM-MINI-PRO-STUB
import '../../services/remote_connection_info.dart';

export '../../services/remote_connection_info.dart';

/// Public build: Remote Access (relay pairing with LM Mini Home / Connect) is
/// part of the official app. LAN servers keep working without it.
class RemoteAccessService {
  bool get isConnected => false;
  String? get lastError => null;
  Stream<RemoteConnectionStatus> get statusStream =>
      const Stream<RemoteConnectionStatus>.empty();

  RemoteConnectionInfo? parseQrCode(String rawData) => null;

  static RemoteConnectionInfo? parseRelayUrl(String raw) =>
      RemoteRelayHttp.parseRelayUrl(raw);

  static String probePathForBackend(String backend) =>
      RemoteRelayHttp.probePathForBackend(backend);

  static String friendlyConnectionError(Object e) =>
      RemoteRelayHttp.friendlyConnectionError(e);

  static String httpErrorMessage(int status, String body) =>
      RemoteRelayHttp.httpErrorMessage(status, body);

  Future<RemoteConnectionInfo> enrichFromHostStatus(
    RemoteConnectionInfo info,
  ) async =>
      info;

  Future<bool> testConnection(
    String url,
    String token, {
    String backend = 'lmStudio',
  }) async =>
      false;

  void startHealthCheck(
    String url,
    String token, {
    Duration interval = const Duration(seconds: 30),
    String backend = 'lmStudio',
  }) {}

  void stopHealthCheck() {}

  Future<int?> measureLatency(String url, String token,
          {String backend = 'lmStudio'}) async =>
      null;

  void dispose() {}
}
