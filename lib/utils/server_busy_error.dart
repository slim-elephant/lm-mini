/// The user's server refused a message because it is still working on the
/// previous one (HTTP 409 from a proxy or story/memory layer that handles
/// one turn at a time). Not an app failure: waiting fixes it.
abstract final class ServerBusyError {
  static const userMessage =
      'Your server is still working on the previous message, so it did not '
      'take this one. Wait for it to finish, then send again.';

  static final _busy = RegExp(
    r'\b(turn|request|generation|response|run)\b[^.]{0,60}'
    r'\balready (running|in progress|being processed)\b',
    caseSensitive: false,
  );

  static bool matches(Object? error) {
    final text = error?.toString() ?? '';
    if (text.isEmpty) return false;
    if (text.contains(userMessage)) return true;
    final lower = text.toLowerCase();
    if (lower.contains('no extra turn was queued')) return true;
    return _busy.hasMatch(text);
  }
}
