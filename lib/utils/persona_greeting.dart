import '../models/system_prompt.dart';

/// The opening message a new chat with [persona] starts with: its greeting
/// or one of its alternate greetings. The pick is stable per conversation,
/// so the preview and the saved message match. Null when the persona has
/// no greeting.
String? greetingForConversation(SystemPrompt? persona, String conversationId) {
  if (persona == null) return null;
  final options = [
    if (persona.greeting != null && persona.greeting!.trim().isNotEmpty)
      persona.greeting!.trim(),
    for (final g in persona.alternateGreetings ?? const <String>[])
      if (g.trim().isNotEmpty) g.trim(),
  ];
  if (options.isEmpty) return null;
  var hash = 0;
  for (final unit in conversationId.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return options[hash % options.length];
}
