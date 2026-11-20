/// Whether a chat continues LM Studio's stored conversation
/// (`previous_response_id`) or sends its own history.
///
/// LM Studio stores each reply with its thinking and hands it to the model's
/// chat template on the next turn. Some templates (e.g. Qwen 3.8 fine-tunes,
/// where an unset `preserve_thinking` means keep) then feed every old thought
/// back in. The history the app builds itself is answer-only, so turning
/// "Keep thinking in context" off for LM Studio skips the stored session.
class LmStudioSession {
  LmStudioSession._();

  /// The session id to continue, or null to send answer-only history.
  ///
  /// Only LM Studio (`providerKind == 'lmStudio'`) is affected; LM Mini Home
  /// and every other backend keep their current behaviour.
  static String? continuableResponseId(
    String? lastResponseId, {
    required String providerKind,
    required bool keepThinkingInContext,
  }) {
    if (providerKind == 'lmStudio' && !keepThinkingInContext) return null;
    return lastResponseId;
  }
}
