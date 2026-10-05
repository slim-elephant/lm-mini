/// Helpers for making OpenAI-style chat message arrays safe for strict
/// chat templates. Qwen requires a single leading system message. Gemma 3
/// also requires user/assistant turns to alternate, and calls
/// `raise_exception` when they do not.
class ChatMessageNormalizer {
  ChatMessageNormalizer._();

  /// Merge every `role: system` entry into a single leading system message.
  /// Mid-history system messages (e.g. search-result rewrites) are converted
  /// to `user` so templates that forbid non-leading system roles still work.
  static List<Map<String, dynamic>> coalesceSystemMessages(
    List<Map<String, dynamic>> messages,
  ) {
    if (messages.isEmpty) return messages;

    final systemParts = <String>[];
    final rest = <Map<String, dynamic>>[];

    for (final raw in messages) {
      final msg = Map<String, dynamic>.from(raw);
      if (msg['role'] == 'system') {
        final content = msg['content'];
        final text = content is String
            ? content.trim()
            : (content?.toString().trim() ?? '');
        if (text.isNotEmpty) systemParts.add(text);
        continue;
      }
      rest.add(msg);
    }

    if (systemParts.isEmpty) return rest;

    return [
      {'role': 'system', 'content': systemParts.join('\n\n')},
      ...rest,
    ];
  }

  /// Append [memoryContext] into the leading system message when present,
  /// otherwise insert a new leading system message. Never inserts a second
  /// system role mid-array (which breaks Qwen templates).
  static List<Map<String, dynamic>> injectMemoryContext(
    List<Map<String, dynamic>> messages,
    String? memoryContext,
  ) {
    final memory = memoryContext?.trim() ?? '';
    if (memory.isEmpty) {
      return coalesceSystemMessages(messages);
    }

    final coalesced = coalesceSystemMessages(messages);
    if (coalesced.isNotEmpty && coalesced.first['role'] == 'system') {
      final existing = coalesced.first['content']?.toString() ?? '';
      coalesced[0] = {
        'role': 'system',
        'content': existing.isEmpty ? memory : '$existing\n\n$memory',
      };
      return coalesced;
    }

    return [
      {'role': 'system', 'content': memory},
      ...coalesced,
    ];
  }

  /// Fold system text into one leading message, then force the remaining
  /// turns into user, assistant, user, assistant order.
  ///
  /// Gemma 3's tokenizer template raises `Jinja.TemplateException` unless
  /// that pattern holds. Consecutive turns of the same role (a dropped tool
  /// bubble, two user sends, a context cut that starts on an assistant
  /// reply) are merged. Tool and other roles are attached to the previous
  /// assistant turn, or to the user turn when there is no assistant yet.
  /// A history that starts with the assistant gets an empty user turn so
  /// the template still accepts it.
  static List<({String role, String content})> strictTurnOrder(
    List<({String role, String content})> messages,
  ) {
    final systemParts = <String>[];
    final turns = <({String role, String content})>[];

    void pushTurn(String role, String text) {
      if (text.isEmpty) return;
      if (turns.isNotEmpty && turns.last.role == role) {
        final prev = turns.removeLast();
        turns.add((role: role, content: '${prev.content}\n\n$text'));
        return;
      }
      turns.add((role: role, content: text));
    }

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final text = message.content.trim();
      final keepEmptyUser =
          text.isEmpty && i == messages.length - 1 && message.role == 'user';
      if (text.isEmpty && !keepEmptyUser) continue;

      if (message.role == 'system') {
        systemParts.add(text);
        continue;
      }

      var role = message.role == 'model' ? 'assistant' : message.role;
      if (role != 'user' && role != 'assistant') {
        role = turns.isNotEmpty && turns.last.role == 'assistant'
            ? 'assistant'
            : 'user';
      }
      pushTurn(role, keepEmptyUser ? ' ' : text);
    }

    if (turns.isNotEmpty && turns.first.role == 'assistant') {
      turns.insert(0, (role: 'user', content: ' '));
    }

    return [
      if (systemParts.isNotEmpty)
        (role: 'system', content: systemParts.join('\n\n')),
      ...turns,
    ];
  }

  /// Whether an error string looks like the Qwen / Jinja
  /// "System message must be at the beginning" failure.
  static bool isSystemMessageOrderError(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('system message must be at the beginning') ||
        (s.contains('unable to generate parser') &&
            s.contains('system message'));
  }
}
