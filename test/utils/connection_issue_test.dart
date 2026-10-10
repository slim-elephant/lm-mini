import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/services/network_status_service.dart';
import 'package:lm_mini/utils/connection_issue.dart';
import 'package:lm_mini/utils/lan_server_error.dart';
import 'package:lm_mini/utils/network_preflight_error.dart';

const _lan = 'http://192.168.100.178:1234';
const _wifi = NetworkSnapshot([ConnectivityResult.wifi]);
const _mobile = NetworkSnapshot([ConnectivityResult.mobile]);
const _offline = NetworkSnapshot([ConnectivityResult.none]);
const _vpnMobile =
    NetworkSnapshot([ConnectivityResult.mobile, ConnectivityResult.vpn]);

// What the owner's screenshot had while on 5G.
const _socketTimeout = 'SocketException: Connection timed out (OS Error: '
    'Operation timed out, errno = 60), address = 192.168.100.178, port = 1234';

ConnectionIssue? _r({
  String url = _lan,
  String kind = 'lmStudio',
  bool remote = false,
  bool usb = false,
  NetworkSnapshot net = _wifi,
  String? chat,
  String? chatDetail,
  String? conn,
  bool ios = true,
  bool lanCheck = true,
  bool proven = false,
}) {
  final settings = AppSettings(
    serverUrl: url,
    activeProviderKind: kind,
    isRemoteActive: remote,
    usbModeEnabled: usb,
  );
  return resolveConnectionIssue(
    settings: settings,
    net: net,
    providerName: 'LM Studio',
    chatError: chat,
    chatErrorDetail: chatDetail,
    connectionError: conn,
    isIOS: ios,
    lanCheck: lanCheck,
    localAccessProven: proven,
  );
}

void main() {
  group('resolveConnectionIssue priority', () {
    test('nothing wrong → null', () {
      expect(_r(), isNull);
      expect(_r(net: NetworkSnapshot.unknown), isNull);
    });

    test('offline beats every stored error', () {
      final i = _r(
        net: _offline,
        chat: 'Model not found',
        conn: _socketTimeout,
      );
      expect(i?.kind, ConnectionIssueKind.offline);
      expect(i?.isNetworkState, isTrue);
      expect(i?.source, ConnectionIssueSource.network);
    });

    test('offline from a failed send is tagged chat (pill expands)', () {
      final i = _r(net: _offline, chat: NetworkPreflightError.offlineMessage);
      expect(i?.kind, ConnectionIssueKind.offline);
      expect(i?.source, ConnectionIssueSource.chat);
    });

    test('5G + LAN host: needsWifi suppresses stale SocketException + '
        'permission hint (owner screenshot)', () {
      final i = _r(net: _mobile, conn: _socketTimeout);
      expect(i?.kind, ConnectionIssueKind.needsWifi);
      expect(i?.host, '192.168.100.178');
      expect(i?.provider, 'LM Studio');
      expect(i?.source, ConnectionIssueSource.network);
    });

    test('5G send failure → one needsWifi, tagged chat', () {
      final msg = NetworkPreflightError.needsWifiMessage(
          'LM Studio', '192.168.100.178');
      final i = _r(net: _mobile, chat: msg, conn: _socketTimeout);
      expect(i?.kind, ConnectionIssueKind.needsWifi);
      expect(i?.source, ConnectionIssueSource.chat);
    });

    test('Wi‑Fi lost mid-reply while still on 5G → needsWifi', () {
      final i = _r(
        net: _mobile,
        chat: NetworkPreflightError.lostWifiMessage('LM Studio'),
      );
      expect(i?.kind, ConnectionIssueKind.needsWifi);
      expect(i?.source, ConnectionIssueSource.chat);
    });

    test('Wi‑Fi lost mid-reply, Wi‑Fi back → lostWifi banner', () {
      final i = _r(chat: NetworkPreflightError.lostWifiMessage('Ollama'));
      expect(i?.kind, ConnectionIssueKind.lostWifi);
      expect(i?.provider, 'Ollama');
      expect(i?.isNetworkState, isFalse);
    });

    test('Wi‑Fi back: stale needsWifi / offline errors are dropped', () {
      expect(
        _r(
          chat: NetworkPreflightError.needsWifiMessage('LM Studio', 'h'),
          conn: NetworkPreflightError.offlineMessage,
        ),
        isNull,
      );
    });

    test('VPN on 5G: no needsWifi, no permission hint', () {
      final i = _r(net: _vpnMobile, conn: _socketTimeout);
      expect(i?.kind, ConnectionIssueKind.serverUnreachable);
    });

    test('stored needsWifi (VPN not routing LAN) holds while off Wi‑Fi', () {
      final i = _r(
        net: _vpnMobile,
        chat: NetworkPreflightError.needsWifiMessage('LM Studio', 'h'),
      );
      expect(i?.kind, ConnectionIssueKind.needsWifi);
    });

    test('Remote Access active on 5G → no needsWifi', () {
      expect(_r(net: _mobile, remote: true), isNull);
    });

    test('on-device / USB / localhost never get network issues', () {
      expect(_r(kind: 'onDeviceGguf', net: _offline), isNull);
      expect(_r(usb: true, net: _offline), isNull);
      expect(_r(url: 'http://localhost:1234', net: _mobile), isNull);
    });

    test('group chat skips the live LAN check', () {
      expect(_r(net: _mobile, lanCheck: false), isNull);
    });

    test('server off on Wi‑Fi → serverUnreachable (refused)', () {
      final i = _r(
        chat: LanServerError.refusedUserMessage,
        chatDetail: 'SocketException: Connection refused',
      );
      expect(i?.kind, ConnectionIssueKind.serverUnreachable);
      expect(i?.source, ConnectionIssueSource.chat);
    });

    test('refused beats permission signature', () {
      final i = _r(conn: 'Connection refused; errno = 61; timed out');
      expect(i?.kind, ConnectionIssueKind.serverUnreachable);
    });

    test('iOS + Wi‑Fi + LAN + timeout → permission hint', () {
      final i = _r(conn: _socketTimeout);
      expect(i?.kind, ConnectionIssueKind.localNetworkPermission);
    });

    test('permission hint never on Android / mobile / proven / public', () {
      expect(_r(conn: _socketTimeout, ios: false)?.kind,
          ConnectionIssueKind.serverUnreachable);
      expect(_r(conn: _socketTimeout, net: _mobile)?.kind,
          ConnectionIssueKind.needsWifi);
      expect(_r(conn: _socketTimeout, proven: true)?.kind,
          ConnectionIssueKind.serverUnreachable);
      expect(
        _r(conn: _socketTimeout, url: 'https://relay.example.com')?.kind,
        ConnectionIssueKind.serverUnreachable,
      );
    });

    test('model not found → other (chat)', () {
      final i = _r(chat: "Model \"qwen\" isn't available on the server.");
      expect(i?.kind, ConnectionIssueKind.other);
      expect(i?.source, ConnectionIssueSource.chat);
    });

    test('chat error checked before connectionError at the same level', () {
      final i = _r(
        chat: 'SocketException: Connection reset by peer',
        conn: 'SocketException: Connection refused',
      );
      // Refused (row 4) is a higher row than generic transport (row 6).
      expect(i?.kind, ConnectionIssueKind.serverUnreachable);
      expect(i?.source, ConnectionIssueSource.connection);

      final j = _r(
        chat: 'SocketException: Connection refused',
        conn: 'SocketException: Connection refused',
      );
      expect(j?.source, ConnectionIssueSource.chat);
    });

    test('non-transport chat error hides a stale connectionError', () {
      final i = _r(
        chat: 'Context length exceeded',
        conn: 'SocketException: Connection refused',
      );
      expect(i?.kind, ConnectionIssueKind.other);
      expect(i?.source, ConnectionIssueSource.chat);
    });

    test('connectionError alone that is not transport → other', () {
      final i = _r(conn: 'No server URL configured');
      expect(i?.kind, ConnectionIssueKind.other);
      expect(i?.source, ConnectionIssueSource.connection);
    });
  });
}
