/// Prompt larger than the loaded context window — not a Mini crash.
///
/// Covers llama.cpp `exceed_context_size_error` and LM Studio hanging up
/// after `chat.start` / prompt processing with no error body.
abstract final class ContextWindowError {
  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    if (s.contains('exceed_context_size_error')) return true;
    if (s.contains('exceeds the available context size')) return true;
    if (s.contains('context ran out')) return true;
    if (s.contains("didn't fit the loaded context") ||
        s.contains('did not fit the loaded context')) {
      return true;
    }
    if (s.contains('larger than the loaded window') ||
        s.contains('larger than the loaded context')) {
      return true;
    }
    if (s.contains('stream_closed_after_chat_start')) return true;
    if (s.contains('closed the stream after chat.start')) return true;
    return false;
  }
}
