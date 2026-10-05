import 'response_parser.dart';

/// Cold-session system instruction. Ask for the tag at the **start** of the
/// reply so a shrinking LM Studio output budget (context filling up) cannot
/// eat `[IMG_PROMPT]` the way an end-of-message tag is lost after a few turns.
const kImageGenSystemInstruction =
    '\n\n[IMAGE_GEN_INSTRUCTION] After any thinking, start each reply with a single hidden tag [IMG_PROMPT: concise English comma-separated visual tags], then write your answer. Do not mention this tag to the user.';

/// Per-turn reminder on the current user payload. LM Studio `/api/v1/chat`
/// must not re-send `system_prompt` once `previous_response_id` is set
/// (it appends a system message mid-history). Without this, the model
/// forgets the tag after the first replies.
const kImageGenTurnReminder =
    '\n\n[IMAGE_GEN_INSTRUCTION] Start your reply with [IMG_PROMPT: english comma-separated visual tags], then the answer. Do not mention the tag.';

String applyImageGenInstructionToSystem(
  String systemPrompt, {
  required bool enabled,
}) {
  if (!enabled) return systemPrompt;
  if (systemPrompt.contains('[IMAGE_GEN_INSTRUCTION]')) return systemPrompt;
  return '$systemPrompt$kImageGenSystemInstruction';
}

String appendImageGenTurnReminder(String content, {required bool enabled}) {
  if (!enabled) return content;
  if (content.contains('[IMAGE_GEN_INSTRUCTION]')) return content;
  return '$content$kImageGenTurnReminder';
}

/// Append the turn reminder to a v1 `input` string or vision text part.
dynamic withImageGenTurnReminder(dynamic input, {required bool enabled}) {
  if (!enabled) return input;
  if (input is String) {
    return appendImageGenTurnReminder(input, enabled: true);
  }
  if (input is List) {
    final copy = List<dynamic>.from(input);
    for (var i = 0; i < copy.length; i++) {
      final item = copy[i];
      if (item is! Map) continue;
      final type = item['type']?.toString();
      if (type != 'text' && type != 'input_text' && type != 'message') {
        continue;
      }
      final raw = item['content'] ?? item['text'];
      final text = raw?.toString() ?? '';
      final updated = Map<String, dynamic>.from(item);
      if (item.containsKey('content')) {
        updated['content'] = appendImageGenTurnReminder(text, enabled: true);
      }
      if (item.containsKey('text')) {
        updated['text'] = appendImageGenTurnReminder(text, enabled: true);
      }
      copy[i] = updated;
      return copy;
    }
  }
  return input;
}

/// Re-attach a stored image prompt so packed history still demonstrates the
/// tag. Mini strips `[IMG_PROMPT]` from saved assistant text; without this
/// the model copies its own untagged replies and stops emitting the tag.
String assistantTurnForHistory(String answer, String? imagePrompt) {
  final prompt = imagePrompt?.trim();
  if (prompt == null || prompt.isEmpty) return answer;
  if (answer.contains('[IMG_PROMPT:')) return answer;
  return '[IMG_PROMPT: $prompt]\n$answer';
}

/// Prefer a tag in the visible message; fall back to thinking/reasoning
/// (models often hide it there after "do not mention this tag").
ImagePromptResult extractImagePromptFromAssistant({
  required String message,
  String? reasoning,
}) {
  final fromMessage = extractImagePrompt(message);
  if (fromMessage.imagePrompt != null && fromMessage.imagePrompt!.isNotEmpty) {
    return fromMessage;
  }
  final thought = reasoning?.trim();
  if (thought == null || thought.isEmpty) return fromMessage;
  final fromThought = extractImagePrompt(thought);
  if (fromThought.imagePrompt == null || fromThought.imagePrompt!.isEmpty) {
    return fromMessage;
  }
  return ImagePromptResult(
    cleanContent: fromMessage.cleanContent,
    imagePrompt: fromThought.imagePrompt,
  );
}
