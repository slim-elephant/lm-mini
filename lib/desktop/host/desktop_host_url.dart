/// Parse `http://host:port` style URLs for desktop host proxy targets.
({String host, int port})? parseHostPort(
  String raw, {
  int defaultPort = 80,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  try {
    final withScheme =
        trimmed.contains('://') ? trimmed : 'http://$trimmed';
    final uri = Uri.parse(withScheme);
    final host = uri.host;
    if (host.isEmpty) return null;
    final port = uri.hasPort ? uri.port : defaultPort;
    return (host: host, port: port);
  } catch (_) {
    return null;
  }
}

String formatHostPort(String host, int port) {
  if (host.isEmpty) return '';
  return 'http://$host:$port';
}
