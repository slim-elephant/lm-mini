import 'localhost_connection_error.dart';

/// Host of [url], lowercased, without brackets. Null if unparseable.
String? urlHost(String? url) {
  if (url == null) return null;
  var raw = url.trim();
  if (raw.isEmpty) return null;
  if (!raw.contains('://')) raw = 'http://$raw';
  final host = Uri.tryParse(raw)?.host.trim();
  if (host == null || host.isEmpty) return null;
  return host.toLowerCase();
}

/// True when two URLs point at the same host (ports may differ).
bool sameLanHost(String? a, String? b) {
  final ha = urlHost(a);
  final hb = urlHost(b);
  if (ha == null || hb == null) return false;
  return ha == hb;
}

/// Whether this host is a LAN machine we should offer to keep in sync.
///
/// Private IPv4, Tailscale CGNAT, and .local names — not localhost, not
/// public APIs like api.openai.com, not LM Mini Connect / relay hosts.
bool isOfferableLanHost(String? host) {
  if (host == null || host.isEmpty) return false;
  if (LocalhostConnectionError.isLoopbackHost(host)) return false;
  final h = host.toLowerCase();
  if (h.contains('lm-mini-relay') ||
      h.contains('connect.lmmini.com') ||
      h.contains('relay.lmmini.com') ||
      h.endsWith('.run.app')) {
    return false;
  }
  if (h.endsWith('.local') || h.endsWith('.lan') || h.endsWith('.home')) {
    return true;
  }
  if (!h.contains('.')) return true;
  final parts = h.split('.');
  if (parts.length == 4) {
    final nums = parts.map(int.tryParse).toList();
    if (nums.every((n) => n != null)) {
      final a = nums[0]!;
      final b = nums[1]!;
      if (a == 10) return true;
      if (a == 192 && b == 168) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
      if (a == 100 && b >= 64 && b <= 127) return true;
    }
  }
  return false;
}

/// Copy of [url] with the host replaced. Preserves scheme, port, and path.
String? replaceUrlHost(String url, String newHost) {
  final host = newHost.trim();
  if (host.isEmpty) return null;
  var raw = url.trim();
  if (raw.isEmpty) return null;
  final hadScheme = raw.contains('://');
  if (!hadScheme) raw = 'http://$raw';
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.host.isEmpty) return null;
  var out = uri.replace(host: host).toString();
  if (out.endsWith('/') &&
      !url.trim().endsWith('/') &&
      (uri.path.isEmpty || uri.path == '/')) {
    out = out.substring(0, out.length - 1);
  }
  return out;
}

enum SharedHostPeer { chat, imageGen }

class SharedHostChange {
  final SharedHostPeer peer;
  final String previousPeerUrl;
  final String suggestedPeerUrl;
  final String oldHost;
  final String newHost;

  const SharedHostChange({
    required this.peer,
    required this.previousPeerUrl,
    required this.suggestedPeerUrl,
    required this.oldHost,
    required this.newHost,
  });
}

/// If [peerUrl] used the same host as [previousChangedUrl], suggest moving it
/// to the host of [newChangedUrl] (ports stay on the peer URL).
SharedHostChange? sharedHostUpdate({
  required String previousChangedUrl,
  required String newChangedUrl,
  required String peerUrl,
  required SharedHostPeer peer,
}) {
  final oldHost = urlHost(previousChangedUrl);
  final newHost = urlHost(newChangedUrl);
  final peerHost = urlHost(peerUrl);
  if (oldHost == null || newHost == null || peerHost == null) return null;
  if (oldHost == newHost) return null;
  if (peerHost != oldHost) return null;
  if (!isOfferableLanHost(oldHost) || !isOfferableLanHost(newHost)) {
    return null;
  }
  final suggested = replaceUrlHost(peerUrl, newHost);
  if (suggested == null || suggested == peerUrl) return null;
  return SharedHostChange(
    peer: peer,
    previousPeerUrl: peerUrl,
    suggestedPeerUrl: suggested,
    oldHost: oldHost,
    newHost: newHost,
  );
}
