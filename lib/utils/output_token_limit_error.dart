/// Tools finished but the model hit its max-output cap before a reply.
///
/// Not a Mini crash. Point the user at Model Parameters instead of
/// Send to support.
abstract final class OutputTokenLimitError {
  static const userMessage =
      'MCP tools ran successfully but the model ran out of output tokens '
      'before writing a response. Try increasing max tokens in settings.';

  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    return s.contains('ran out of output tokens') ||
        s.contains('need more output tokens') ||
        s.contains('increasing max tokens');
  }
}
