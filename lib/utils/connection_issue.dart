import 'dart:io' show Platform;

import '../models/app_settings.dart';
import '../services/local_network_service.dart';
import '../services/network_status_service.dart';
import 'connect_host_error.dart';
import 'lan_server_error.dart';
import 'network_preflight_error.dart';
import 'server_reachability.dart';
import 'server_unreachable_error.dart';

/// The one connection problem the UI should explain right now.
///
/// | # | kind                     | when                                                        |
/// |---|--------------------------|-------------------------------------------------------------|
/// | 1 | offline                  | live snapshot offline, server-backed chat (not loopback)    |
/// | 2 | needsWifi                | LAN host, no Wi‑Fi/Ethernet, no VPN, Remote Access off      |
/// |   |                          | (live), or a stored needsWifi error while still off Wi‑Fi   |
/// | 3 | lostWifi                 | Wi‑Fi dropped mid-reply (stored chat error)                 |
/// | 4 | serverUnreachable        | refused / host down (LanServerError), Connect 502/503       |
/// | 5 | localNetworkPermission   | iOS + on Wi‑Fi + LAN host + timeout / no-route signature    |
/// |   |                          | and no LAN host answered yet in this process                |
/// | 6 | serverUnreachable        | other transport failures (SocketException, preflight tag)   |
/// | 7 | other                    | anything else (model missing, token limit, image errors…)   |
///
/// At each row the chat error is checked before the model-list
/// connectionError. A non-transport chat error (row 7) means the last send
/// got past the network, so a connectionError beside it is ignored.
///
/// Rows 1–2 come from the live [NetworkSnapshot] and win over any stored
/// chat / model-list error: those are just symptoms of being offline or on
/// mobile data. A stored offline / needsWifi error whose condition no
/// longer holds (Wi‑Fi is back) is stale and dropped.
enum ConnectionIssueKind {
  offline,
  needsWifi,
  lostWifi,
  serverUnreachable,
  localNetworkPermission,
  other,
}

/// Where the text of the issue came from.
enum ConnectionIssueSource {
  /// Live phone connection state (no stored error needed).
  network,

  /// ChatProvider.error / errorDetail.
  chat,

  /// SettingsProvider.connectionError (model list / health check).
  connection,
}

class ConnectionIssue {
  final ConnectionIssueKind kind;
  final ConnectionIssueSource source;

  /// Provider label, e.g. "LM Studio".
  final String provider;

  /// Server host, e.g. "192.168.1.5". Empty when unknown.
  final String host;

  /// Raw error / detail for [ConnectionIssueSource.chat] and
  /// [ConnectionIssueSource.connection]. Null for live network issues.
  final String? error;
  final String? detail;

  const ConnectionIssue(
    this.kind, {
    required this.source,
    this.provider = '',
    this.host = '',
    this.error,
    this.detail,
  });

  /// Phone-side state (offline / mobile data). Shown as the pill above the
  /// composer — never as a second banner on top.
  bool get isNetworkState =>
      kind == ConnectionIssueKind.offline ||
      kind == ConnectionIssueKind.needsWifi;

  /// Offline / mobile data / lost Wi‑Fi — the [NetworkIssue] copy applies.
  NetworkIssue? get networkIssue => switch (kind) {
        ConnectionIssueKind.offline =>
          const NetworkIssue(NetworkIssueKind.offline),
        ConnectionIssueKind.needsWifi =>
          NetworkIssue(NetworkIssueKind.needsWifi,
              provider: provider, host: host),
        ConnectionIssueKind.lostWifi =>
          NetworkIssue(NetworkIssueKind.lostWifi,
              provider: provider, host: host),
        _ => null,
      };

  @override
  String toString() => 'ConnectionIssue(${kind.name}, ${source.name}, '
      '$provider, $host, ${error ?? ''})';
}

bool _isServerBacked(AppSettings s) {
  final kind = s.activeProviderKind;
  if (kind == 'onDeviceGguf' ||
      kind == 'onDeviceMlx' ||
      kind == 'appleIntelligence') {
    return false;
  }
  return !s.usbModeEnabled;
}

String _blob(String? error, String? detail) => [
      if (error != null && error.isNotEmpty) error,
      if (detail != null && detail.isNotEmpty && detail != error) detail,
    ].join('\n');

/// Pick at most ONE connection issue to explain. Pure — pass [isIOS] and
/// [localAccessProven] in tests.
///
/// * [settings] — the chat's effective settings (per-chat overrides + cloud
///   routing applied).
/// * [providerName] — label for copy ("LM Studio"). Defaults to the name in
///   a stored error, then "LM Studio".
/// * [lanCheck] — false for group chats (participants may use other hosts);
///   the live mobile-data check is skipped, stored errors still apply.
/// * [localAccessProven] — a LAN host answered in this process, so iOS
///   Local Network permission is granted (no permission hint).
ConnectionIssue? resolveConnectionIssue({
  required AppSettings settings,
  required NetworkSnapshot net,
  String? providerName,
  String? chatError,
  String? chatErrorDetail,
  String? connectionError,
  bool lanCheck = true,
  bool? isIOS,
  bool localAccessProven = false,
}) {
  final ios = isIOS ?? Platform.isIOS;
  final serverBacked = _isServerBacked(settings);
  final url = settings.serverUrl;
  final scope = settings.isRemoteActive ? HostScope.public : classifyHost(url);
  final host = settings.isRemoteActive ? '' : (hostOf(url) ?? '');
  final chatBlob = _blob(chatError, chatErrorDetail);
  final hasChat = chatBlob.isNotEmpty;
  final connBlob = connectionError ?? '';
  final hasConn = connBlob.isNotEmpty;

  final chatNet = hasChat ? NetworkPreflightError.parse(chatBlob) : null;
  final connNet = hasConn ? NetworkPreflightError.parse(connBlob) : null;
  String name() {
    final p = providerName?.trim() ?? '';
    if (p.isNotEmpty) return p;
    for (final i in [chatNet, connNet]) {
      if (i != null && i.provider.isNotEmpty) return i.provider;
    }
    return 'LM Studio';
  }

  final hostIsLan = scope == HostScope.localNetwork;
  final offWifi = !net.isOffline && !net.hasLocalNetwork;

  // ── 1. Offline ────────────────────────────────────────────────────────
  if (serverBacked && scope != HostScope.loopback && net.isOffline) {
    return ConnectionIssue(
      ConnectionIssueKind.offline,
      // "chat" when the last send failed for this reason (the pill then
      // explains it); otherwise just the live state.
      source: chatNet != null
          ? ConnectionIssueSource.chat
          : ConnectionIssueSource.network,
      provider: name(),
      host: host,
    );
  }

  // ── 2. Mobile data with a LAN server ─────────────────────────────────
  final liveNeedsWifi = lanCheck &&
      serverBacked &&
      hostIsLan &&
      offWifi &&
      !net.hasVpn;
  // A stored needsWifi (e.g. VPN reported but not routing the LAN) still
  // holds while the phone has no Wi‑Fi.
  final storedNeedsWifi = offWifi &&
      (hostIsLan || !lanCheck) &&
      (chatNet?.kind == NetworkIssueKind.needsWifi ||
          connNet?.kind == NetworkIssueKind.needsWifi);
  if (liveNeedsWifi || storedNeedsWifi) {
    final storedHost = [chatNet, connNet]
        .whereType<NetworkIssue>()
        .map((i) => i.host)
        .firstWhere((h) => h.isNotEmpty, orElse: () => '');
    return ConnectionIssue(
      ConnectionIssueKind.needsWifi,
      // Wi‑Fi lost mid-reply and still off it: one needsWifi pill, expanded
      // because the last send failed for this reason.
      source: (chatNet?.kind == NetworkIssueKind.needsWifi ||
              chatNet?.kind == NetworkIssueKind.lostWifi)
          ? ConnectionIssueSource.chat
          : (liveNeedsWifi
              ? ConnectionIssueSource.network
              : ConnectionIssueSource.connection),
      provider: name(),
      host: host.isNotEmpty ? host : storedHost,
    );
  }

  // Symptoms of a phone-side outage we just ruled out (Wi‑Fi is back):
  // stale offline / needsWifi copy is dropped.
  final chatStale = chatNet != null &&
      (chatNet.kind == NetworkIssueKind.offline ||
          chatNet.kind == NetworkIssueKind.needsWifi);
  final connStale = connNet != null &&
      (connNet.kind == NetworkIssueKind.offline ||
          connNet.kind == NetworkIssueKind.needsWifi);
  final chatLive = hasChat && !chatStale;
  final connLive = hasConn && !connStale;

  ConnectionIssue fromChat(ConnectionIssueKind k) => ConnectionIssue(
        k,
        source: ConnectionIssueSource.chat,
        provider: name(),
        host: host,
        error: chatError ?? chatErrorDetail,
        detail: chatErrorDetail,
      );
  ConnectionIssue fromConn(ConnectionIssueKind k) => ConnectionIssue(
        k,
        source: ConnectionIssueSource.connection,
        provider: name(),
        host: host,
        error: connectionError,
        detail: connectionError,
      );

  // ── 3. Lost Wi‑Fi mid-reply ──────────────────────────────────────────
  if (chatLive && chatNet?.kind == NetworkIssueKind.lostWifi) {
    return ConnectionIssue(
      ConnectionIssueKind.lostWifi,
      source: ConnectionIssueSource.chat,
      provider: chatNet!.provider.isNotEmpty ? chatNet.provider : name(),
      host: host,
      error: chatError,
      detail: chatErrorDetail,
    );
  }

  bool definiteServer(String s) =>
      LanServerError.classify(s) != null || ConnectHostError.matches(s);
  bool permission(String s) =>
      ios &&
      serverBacked &&
      hostIsLan &&
      net.hasLocalNetwork &&
      !net.isOffline &&
      !localAccessProven &&
      LocalNetworkService.matchesPermissionSignature(s);
  bool transport(String s) =>
      ServerUnreachableError.matches(s) || NetworkPreflightError.matches(s);

  // A chat error that is not a transport failure (model missing, token
  // limit…) came from the latest send, which got past the network. A
  // model-list connectionError next to it is stale — ignore it.
  final chatIsOther = chatLive &&
      !definiteServer(chatBlob) &&
      !permission(chatBlob) &&
      !transport(chatBlob);
  final useConn = connLive && !chatIsOther;

  // ── 4. Server refused / host down / Connect relay gateway ────────────
  if (chatLive && definiteServer(chatBlob)) {
    return fromChat(ConnectionIssueKind.serverUnreachable);
  }
  if (useConn && definiteServer(connBlob)) {
    return fromConn(ConnectionIssueKind.serverUnreachable);
  }

  // ── 5. iOS Local Network permission ─────────────────────────────────
  // Only on Wi‑Fi / Ethernet: on mobile data a LAN timeout is expected and
  // the permission hint would be wrong.
  if (chatLive && permission(chatBlob)) {
    return fromChat(ConnectionIssueKind.localNetworkPermission);
  }
  if (useConn && permission(connBlob)) {
    return fromConn(ConnectionIssueKind.localNetworkPermission);
  }

  // ── 6. Other transport failures ──────────────────────────────────────
  if (chatLive && transport(chatBlob)) {
    return fromChat(ConnectionIssueKind.serverUnreachable);
  }
  if (useConn && transport(connBlob)) {
    return fromConn(ConnectionIssueKind.serverUnreachable);
  }

  // ── 7. Anything else ─────────────────────────────────────────────────
  if (chatLive) return fromChat(ConnectionIssueKind.other);
  if (useConn) return fromConn(ConnectionIssueKind.other);
  return null;
}
