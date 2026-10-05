/// Transport failures talking to LM Studio / Ollama / a LAN host.
///
/// These belong on the connection banner, not Send to support. A phone
/// backgrounding the app, a Wi‑Fi blip, or a closed socket (EBADF) is not
/// a Mini crash.
abstract final class ServerUnreachableError {
  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    const needles = [
      'socketexception',
      'clientexception',
      'handshakeexception',
      'bad file descriptor',
      'connection refused',
      'connection reset',
      'connection abort',
      'connection closed',
      'software caused connection abort',
      'network is unreachable',
      'failed host lookup',
      'os error: broken pipe',
      'errno = 9',
      'errno = 54',
      'errno = 61',
      'errno = 64',
      'errno = 103',
      'errno = 111',
      'host is down',
      'ehostdown',
    ];
    return needles.any(s.contains);
  }
}
