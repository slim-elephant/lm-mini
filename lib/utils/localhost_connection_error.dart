/// Detects "talking to localhost from another device" setup mistakes.
///
/// On a phone, `localhost` is the phone itself — not the computer running
/// LM Studio / Ollama. That shows up as connection refused and is not a
/// crash worth a support ticket.
abstract final class LocalhostConnectionError {
  static const userMessage =
      "Can't connect to localhost. On a phone or tablet, localhost means this device — not your computer. In Settings, use your computer's IP address instead (for example http://192.168.1.10:1234) and keep both on the same Wi‑Fi.";

  static bool isLoopbackHost(String? host) {
    if (host == null || host.isEmpty) return false;
    var h = host.trim().toLowerCase();
    if (h.startsWith('[') && h.endsWith(']')) {
      h = h.substring(1, h.length - 1);
    }
    return h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '::1' ||
        h == '0.0.0.0' ||
        h == '::';
  }

  static bool matches(Object? error, {String? serverUrl}) {
    final text = error?.toString() ?? '';
    final lower = text.toLowerCase();

    if (lower.contains("can't connect to localhost") ||
        lower.contains('cannot connect to localhost') ||
        lower.contains("use your computer's ip") ||
        lower.contains('use your computer’s ip')) {
      return true;
    }

    final urlHost = Uri.tryParse(serverUrl ?? '')?.host;
    final loopbackUrl = isLoopbackHost(urlHost);
    final loopbackInText = lower.contains('localhost') ||
        lower.contains('127.0.0.1') ||
        lower.contains('::1') ||
        lower.contains('uri=http://localhost') ||
        lower.contains('uri=https://localhost');

    if (!loopbackInText && !loopbackUrl) return false;

    return lower.contains('connection refused') ||
        lower.contains('socketexception') ||
        lower.contains('os error: connection refused') ||
        lower.contains('errno = 61') ||
        lower.contains('errno = 111') ||
        lower.contains('connection failed') ||
        lower.contains('failed to connect') ||
        lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('network is unreachable');
  }
}
