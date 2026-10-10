import 'dart:async';
import 'dart:io';

/// Where a chat server lives, judged only from its URL.
enum HostScope {
  /// Home / office LAN: RFC1918, link-local, `.local`, single-label names,
  /// IPv6 ULA / link-local. Only reachable on that Wi‑Fi / Ethernet
  /// (or through a VPN that routes the subnet).
  localNetwork,

  /// This device: localhost, 127.0.0.0/8, ::1. On a phone that is the USB
  /// bridge or an on-device server — never block it.
  loopback,

  /// Carrier-grade NAT range (100.64.0.0/10) and Tailscale names. Usually a
  /// VPN such as Tailscale, which works over mobile data — probe, never block.
  vpnRange,

  /// Anything else (cloud APIs, relay, a DDNS name).
  public,
}

/// What to do before sending a chat request to a server.
enum PreflightDecision {
  /// Send right away (cloud / loopback / remote relay).
  proceed,

  /// No network at all — fail now with the offline message.
  blockOffline,

  /// LAN host while the phone is on mobile data only (no Wi‑Fi, no VPN).
  blockNeedsWifi,

  /// Quick TCP connect first so a dead host fails in seconds, not a minute.
  probe,
}

/// Outcome of a TCP connect probe.
enum ProbeResult { ok, refused, timeout, unreachable }

/// Classify [url]'s host. Accepts bare hosts (`192.168.1.5:1234`) too.
HostScope classifyHost(String url) {
  final host = hostOf(url);
  if (host == null || host.isEmpty) return HostScope.public;
  return classifyHostName(host);
}

/// Lowercased host of [url] without IPv6 brackets. Null if unparseable.
String? hostOf(String url) {
  var raw = url.trim();
  if (raw.isEmpty) return null;
  if (!raw.contains('://')) raw = 'http://$raw';
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  var host = uri.host.trim().toLowerCase();
  if (host.startsWith('[') && host.endsWith(']')) {
    host = host.substring(1, host.length - 1);
  }
  return host.isEmpty ? null : host;
}

/// Classify a bare host name / IP literal.
HostScope classifyHostName(String rawHost) {
  var host = rawHost.trim().toLowerCase();
  if (host.startsWith('[') && host.endsWith(']')) {
    host = host.substring(1, host.length - 1);
  }
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);
  if (host.isEmpty) return HostScope.public;

  if (host == 'localhost' || host.endsWith('.localhost')) {
    return HostScope.loopback;
  }

  final v4 = _parseIpv4(host);
  if (v4 != null) return _classifyIpv4(v4);

  if (host.contains(':')) return _classifyIpv6(host);

  // Tailscale MagicDNS names work over mobile data when the VPN is up.
  if (host.endsWith('.ts.net')) return HostScope.vpnRange;

  if (host.endsWith('.local') ||
      host.endsWith('.lan') ||
      host.endsWith('.home') ||
      host.endsWith('.home.arpa') ||
      host.endsWith('.internal')) {
    return HostScope.localNetwork;
  }

  // Single-label names (`mypc`, `studio-mac`) only resolve on the LAN.
  if (!host.contains('.')) return HostScope.localNetwork;

  return HostScope.public;
}

List<int>? _parseIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return null;
  final out = <int>[];
  for (final p in parts) {
    if (p.isEmpty || p.length > 3) return null;
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return null;
    out.add(n);
  }
  return out;
}

HostScope _classifyIpv4(List<int> o) {
  final a = o[0];
  final b = o[1];
  if (a == 127) return HostScope.loopback;
  if (a == 0 && b == 0 && o[2] == 0 && o[3] == 0) return HostScope.loopback;
  if (a == 10) return HostScope.localNetwork;
  if (a == 172 && b >= 16 && b <= 31) return HostScope.localNetwork;
  if (a == 192 && b == 168) return HostScope.localNetwork;
  if (a == 169 && b == 254) return HostScope.localNetwork;
  if (a == 100 && b >= 64 && b <= 127) return HostScope.vpnRange;
  return HostScope.public;
}

HostScope _classifyIpv6(String host) {
  // Drop a zone id (`fe80::1%en0`).
  final pct = host.indexOf('%');
  final h = pct >= 0 ? host.substring(0, pct) : host;
  if (h == '::1' || h == '::') return HostScope.loopback;

  // IPv4-mapped (`::ffff:192.168.1.5`).
  if (h.startsWith('::ffff:')) {
    final v4 = _parseIpv4(h.substring(7));
    if (v4 != null) return _classifyIpv4(v4);
  }

  // Tailscale's IPv6 range lives inside ULA — treat it like the VPN it is.
  if (h.startsWith('fd7a:115c:a1e0:')) return HostScope.vpnRange;

  final first = h.split(':').first;
  final hextet = int.tryParse(first.isEmpty ? '0' : first, radix: 16);
  if (hextet == null) return HostScope.public;
  if ((hextet & 0xfe00) == 0xfc00) return HostScope.localNetwork; // fc00::/7
  if ((hextet & 0xffc0) == 0xfe80) return HostScope.localNetwork; // fe80::/10
  return HostScope.public;
}

/// Pure decision table. See agent.md / report for the matrix.
///
/// | scope        | offline      | Wi‑Fi/Ethernet | VPN only | mobile only    |
/// |--------------|--------------|----------------|----------|----------------|
/// | loopback     | proceed      | proceed        | proceed  | proceed        |
/// | public       | blockOffline | proceed        | proceed  | proceed        |
/// | vpnRange     | blockOffline | probe          | probe    | probe          |
/// | localNetwork | blockOffline | probe          | probe    | blockNeedsWifi |
PreflightDecision decide({
  required HostScope hostScope,
  required bool isOffline,
  required bool hasLocalNetwork,
  required bool hasVpn,
}) {
  if (hostScope == HostScope.loopback) return PreflightDecision.proceed;
  if (isOffline) return PreflightDecision.blockOffline;
  switch (hostScope) {
    case HostScope.public:
      return PreflightDecision.proceed;
    case HostScope.vpnRange:
      return PreflightDecision.probe;
    case HostScope.localNetwork:
      return (hasLocalNetwork || hasVpn)
          ? PreflightDecision.probe
          : PreflightDecision.blockNeedsWifi;
    case HostScope.loopback:
      return PreflightDecision.proceed;
  }
}

/// Map a socket failure to a [ProbeResult].
ProbeResult probeResultForError(Object error) {
  if (error is TimeoutException) return ProbeResult.timeout;
  final s = error.toString().toLowerCase();
  int? code;
  if (error is SocketException) code = error.osError?.errorCode;
  if (code == 61 || code == 111 || code == 10061 || s.contains('refused')) {
    return ProbeResult.refused;
  }
  if (code == 60 ||
      code == 110 ||
      code == 10060 ||
      s.contains('timed out') ||
      s.contains('timeout')) {
    return ProbeResult.timeout;
  }
  return ProbeResult.unreachable;
}

/// Default port for [uri] when none is given.
int portFor(Uri uri) {
  if (uri.hasPort) return uri.port;
  return uri.scheme == 'https' ? 443 : 80;
}

/// TCP reachability probe with a short success cache.
abstract final class ServerReachability {
  static const Duration defaultTimeout = Duration(seconds: 4);
  static const Duration successTtl = Duration(seconds: 20);
  static const Duration failureTtl = Duration(seconds: 3);

  static final Map<String, DateTime> _okUntil = {};
  static final Map<String, ({ProbeResult result, DateTime until})> _failed =
      {};

  /// True once any LAN probe succeeded in this process. Used to avoid
  /// failing the very first send on iOS while the Local Network permission
  /// prompt is still on screen.
  static bool hasEverReachedLocalHost = false;

  static String _key(Uri uri) => '${uri.host.toLowerCase()}:${portFor(uri)}';

  /// Cached success for [uri] that has not expired yet.
  static bool isCachedOk(Uri uri) {
    final until = _okUntil[_key(uri)];
    return until != null && DateTime.now().isBefore(until);
  }

  /// Forget cached results (tests, network changes).
  static void clearCache() {
    _okUntil.clear();
    _failed.clear();
  }

  /// TCP connect to [uri]'s host:port. Never throws.
  static Future<ProbeResult> probe(
    Uri uri, {
    Duration timeout = defaultTimeout,
  }) async {
    final key = _key(uri);
    final now = DateTime.now();
    final okUntil = _okUntil[key];
    if (okUntil != null && now.isBefore(okUntil)) return ProbeResult.ok;
    final failed = _failed[key];
    if (failed != null && now.isBefore(failed.until)) return failed.result;

    var host = uri.host;
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    }
    if (host.isEmpty) return ProbeResult.unreachable;

    ProbeResult result;
    Socket? socket;
    try {
      // Outer timeout also bounds a slow DNS / mDNS lookup.
      socket = await Socket.connect(host, portFor(uri), timeout: timeout)
          .timeout(timeout + const Duration(milliseconds: 500));
      result = ProbeResult.ok;
    } catch (e) {
      result = probeResultForError(e);
    } finally {
      socket?.destroy();
    }

    if (result == ProbeResult.ok) {
      _okUntil[key] = DateTime.now().add(successTtl);
      _failed.remove(key);
      if (classifyHostName(host) != HostScope.public) {
        hasEverReachedLocalHost = true;
      }
    } else {
      _okUntil.remove(key);
      _failed[key] = (result: result, until: DateTime.now().add(failureTtl));
    }
    return result;
  }
}
