import '../models/chat_message.dart';

/// How to retry a user message that was not delivered.
enum FailedRetryPlan {
  /// Latest user turn with no reply after it: replay it in place (no new
  /// bubble).
  replayInPlace,

  /// Older turn (later messages exist): remove it and send its text and
  /// attachments again as a new message at the bottom.
  resendAtBottom,

  /// Message is gone or not a user message.
  none,
}

/// "Not delivered" bookkeeping for user messages, stored in
/// `conversation.settings['failedMessageIds']` (no DB column — §25g).
///
/// A user turn is failed when its send ended with an error and no assistant
/// content was produced for it. A later successful reply clears it, and
/// also clears earlier failed user turns that were sent as history with it.
abstract final class FailedMessages {
  static const settingsKey = 'failedMessageIds';

  /// Failed ids stored on a conversation (tolerates bad / missing data).
  static Set<String> read(Map<String, dynamic>? settings) {
    final raw = settings?[settingsKey];
    if (raw is! List) return <String>{};
    return raw.whereType<String>().where((s) => s.isNotEmpty).toSet();
  }

  /// [settings] with [id] added. Returns the same map when unchanged.
  static Map<String, dynamic> withAdded(
    Map<String, dynamic> settings,
    String id,
  ) {
    final ids = read(settings);
    if (!ids.add(id)) return settings;
    return {...settings, settingsKey: ids.toList()};
  }

  /// [settings] with [ids] removed (key dropped when empty). Returns the
  /// same map when unchanged.
  static Map<String, dynamic> withRemoved(
    Map<String, dynamic> settings,
    Iterable<String> ids,
  ) {
    final current = read(settings);
    final next = current.difference(ids.toSet());
    if (next.length == current.length) return settings;
    final out = {...settings};
    if (next.isEmpty) {
      out.remove(settingsKey);
    } else {
      out[settingsKey] = next.toList();
    }
    return out;
  }

  /// Tool / MCP call records are not a reply the user can read.
  static bool _isToolNoise(ChatMessage m) =>
      m.content.startsWith('Tool call:') ||
      m.content.startsWith('MCP call:') ||
      m.content.startsWith('🔧 MCP call:');

  /// Whether [m] counts as assistant content for a user turn.
  static bool isReply(ChatMessage m) {
    if (m.role != 'assistant') return false;
    if (m.id.startsWith('temp_')) return false;
    if (_isToolNoise(m)) return false;
    return m.content.trim().isNotEmpty || m.hasGeneratedImages;
  }

  /// True when an assistant reply follows the user message [userId]
  /// (before the next user message).
  static bool hasReplyAfter(List<ChatMessage> messages, String userId) {
    final idx = messages.indexWhere((m) => m.id == userId);
    if (idx < 0) return false;
    for (var i = idx + 1; i < messages.length; i++) {
      final m = messages[i];
      if (m.role == 'user') return false;
      if (isReply(m)) return true;
    }
    return false;
  }

  /// User messages between the last reply and [userId] (exclusive) — the
  /// "hi" before "hello" when both failed. They are sent as history with
  /// [userId], so a successful reply delivers them too.
  static List<String> undeliveredBefore(
    List<ChatMessage> messages,
    String userId,
  ) {
    final idx = messages.indexWhere((m) => m.id == userId);
    if (idx <= 0) return const [];
    final out = <String>[];
    for (var i = idx - 1; i >= 0; i--) {
      final m = messages[i];
      if (isReply(m)) break;
      if (m.role == 'user') out.add(m.id);
    }
    return out;
  }

  /// Ids to clear after [userId] got a reply: itself plus the earlier
  /// failed turns that went along as history.
  static Set<String> deliveredWith(
    List<ChatMessage> messages,
    Set<String> failed,
    String userId,
  ) {
    return {
      userId,
      ...undeliveredBefore(messages, userId).where(failed.contains),
    };
  }

  /// Decide how to retry [messageId].
  static FailedRetryPlan retryPlan(
    List<ChatMessage> messages,
    String messageId,
  ) {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0 || messages[idx].role != 'user') return FailedRetryPlan.none;
    for (var i = idx + 1; i < messages.length; i++) {
      final m = messages[i];
      if (m.id.startsWith('temp_')) continue;
      // A later user turn or a real reply: this one is history now.
      if (m.role == 'user' || isReply(m)) {
        return FailedRetryPlan.resendAtBottom;
      }
    }
    return FailedRetryPlan.replayInPlace;
  }
}
