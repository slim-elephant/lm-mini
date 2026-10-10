/// Relay-only request headers (`X-LM-Mini-Token`, `X-LM-Mini-Backend`).
///
/// The relay token unlocks the paired computer. It must only travel to the
/// paired relay / LM Mini Home URL — never to cloud APIs, LAN servers, or
/// image / TTS hosts the user typed in.
library;

/// True when [requestUrl] points at the paired relay [relayBaseUrl]
/// (same scheme, host and port, and a path at or under the relay path).
///
/// Returns false when either URL is missing or not absolute.
bool isRelayRequestUrl(String? requestUrl, String? relayBaseUrl) {
  final relay = _parseAbsolute(relayBaseUrl);
  final request = _parseAbsolute(requestUrl);
  if (relay == null || request == null) return false;
  if (relay.scheme.toLowerCase() != request.scheme.toLowerCase()) return false;
  if (relay.host.toLowerCase() != request.host.toLowerCase()) return false;
  if (relay.port != request.port) return false;
  final base = relay.path.replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty) return true;
  final path = request.path;
  return path == base || path.startsWith('$base/');
}

Uri? _parseAbsolute(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  return uri;
}
