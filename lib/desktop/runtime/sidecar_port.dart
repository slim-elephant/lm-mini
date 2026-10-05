/// Parse OS tool output for PIDs listening on the desktop llama-server port.
abstract final class SidecarPort {
  /// `lsof -nP -iTCP:PORT -sTCP:LISTEN -t` stdout.
  static Set<int> parseLsofPids(String stdout) {
    final pids = <int>{};
    for (final line in stdout.split(RegExp(r'\s+'))) {
      final pid = int.tryParse(line.trim());
      if (pid != null && pid > 1) pids.add(pid);
    }
    return pids;
  }

  /// `netstat -ano -p TCP` (Windows) stdout — only LISTENING rows for [port].
  static Set<int> parseNetstatListeningPids(String stdout, int port) {
    final pids = <int>{};
    final needle = ':$port';
    for (final raw in stdout.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final upper = line.toUpperCase();
      if (!upper.contains('LISTENING')) continue;
      if (!line.contains(needle)) continue;
      // Avoid matching :87410 when looking for :8741.
      if (!_localAddressHasPort(line, port)) continue;
      final parts = line.split(RegExp(r'\s+'));
      final pid = int.tryParse(parts.last);
      if (pid != null && pid > 1) pids.add(pid);
    }
    return pids;
  }

  static bool _localAddressHasPort(String line, int port) {
    // "TCP 127.0.0.1:8741 0.0.0.0:0 LISTENING 1234"
    final match = RegExp(
      r'(?:\[::\]|\[::1\]|\d+\.\d+\.\d+\.\d+|\*):' '$port' r'(?:\s|$)',
    ).firstMatch(line);
    return match != null;
  }
}
