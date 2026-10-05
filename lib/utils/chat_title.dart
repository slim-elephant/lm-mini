import '../models/chat_conversation.dart';
import 'response_parser.dart';

/// Chat list titles: placeholder vs AI vs user, and when auto-title may run.
class ChatTitle {
  static const sourceKey = 'titleSource';
  static const sourceUser = 'user';
  static const sourceAi = 'ai';
  static const sourceAuto = 'auto';

  static const greetings = {
    'hi',
    'hello',
    'hey',
    'yo',
    'sup',
    'hola',
    'bonjour',
    'hallo',
    'ciao',
    'hey there',
    'hi there',
    'hello there',
    'good morning',
    'good afternoon',
    'good evening',
    'howdy',
    'thanks',
    'thank you',
    'ok',
    'okay',
    'yes',
    'no',
    'test',
  };

  static String? sourceOf(Map<String, dynamic>? settings) {
    final v = settings?[sourceKey];
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  static bool isLocked(Map<String, dynamic>? settings) {
    final s = sourceOf(settings);
    return s == sourceUser || s == sourceAi;
  }

  static Map<String, dynamic> withSource(
    Map<String, dynamic> settings,
    String source,
  ) {
    final next = Map<String, dynamic>.from(settings);
    next[sourceKey] = source;
    return next;
  }

  static bool isPlaceholder(String title) {
    final t = title.trim();
    return t.isEmpty || t.toLowerCase() == 'new chat';
  }

  static bool isJunk(String title) {
    final t = title.toUpperCase();
    return t.contains('[IMG_PROMPT') ||
        t.contains('[IMAGE_GEN_INSTRUCTION]') ||
        t.contains('[MEMORY_SAVE') ||
        t.contains('[MEMORY:');
  }

  /// Truncated first-message fallback (`foo…` at 50 chars).
  static bool looksLikeMessageFallback(String title) {
    if (isJunk(title)) return true;
    final t = title.trim();
    return t.endsWith('...') && t.length >= 47;
  }

  /// Short greetings / tiny openers — wait for a later user message.
  static bool isTrivialSeed(String content) {
    final t = content.trim().toLowerCase().replaceAll(RegExp(r'[!?.…]+$'), '');
    if (t.isEmpty) return true;
    if (greetings.contains(t)) return true;
    final words = t.split(RegExp(r'\s+'));
    return words.length <= 2 && t.length <= 16;
  }

  static bool isGreetingTitle(String title) {
    final t = title.trim().toLowerCase().replaceAll(RegExp(r'[!?.…]+$'), '');
    return greetings.contains(t);
  }

  static String displayLabel(String title) {
    var t = ResponseParser.stripHiddenModelTags(title);
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// List text with thinking blocks and image-prompt tags removed.
  static String homeSnippet(String text) {
    return displayLabel(ResponseParser.answerOnly(text));
  }

  /// A stored `Branch: first words` label is the branch-point message, not a
  /// title. A branch then uses its parent's generated title when it has one.
  static String generatedTitle(
    ChatConversation conversation,
    Map<String, ChatConversation> byId,
  ) {
    if (isGeneratedTitle(conversation.title)) {
      return homeSnippet(conversation.title);
    }
    final parentId = conversation.parentConversationId;
    if (parentId == null) return '';
    final parent = byId[parentId];
    if (parent == null || !isGeneratedTitle(parent.title)) return '';
    return homeSnippet(parent.title);
  }

  static bool isGeneratedTitle(String title) {
    final raw = title.trim();
    if (raw.isEmpty) return false;
    if (RegExp(r'^branch:\s*', caseSensitive: false).hasMatch(raw)) {
      return false;
    }
    if (isPlaceholder(raw) ||
        isJunk(raw) ||
        isGreetingTitle(raw) ||
        looksLikeMessageFallback(raw)) {
      return false;
    }
    return homeSnippet(raw).isNotEmpty;
  }

  static String fallbackFromUserMessage(String content) {
    var t = displayLabel(content);
    if (t.isEmpty) return 'New Chat';
    return t.length > 50 ? '${t.substring(0, 47)}...' : t;
  }

  static String firstSubstantialSeed(
    Iterable<String> userMessages,
    String fallback,
  ) {
    final users = userMessages
        .map((m) => m.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (users.isEmpty) return fallback;
    for (final u in users) {
      if (!isTrivialSeed(u)) return u;
    }
    return users.last;
  }

  /// True when auto-title may still replace [currentTitle].
  ///
  /// AI and manual names stay put. Do not treat later user messages as a
  /// reason to retitle — only the first substantial seed's fallback.
  static bool isProvisional({
    required String currentTitle,
    Map<String, dynamic>? settings,
    required String seed,
  }) {
    if (isJunk(currentTitle)) return true;
    if (isLocked(settings)) return false;
    if (isPlaceholder(currentTitle) || isGreetingTitle(currentTitle)) {
      return true;
    }
    return currentTitle.trim() == fallbackFromUserMessage(seed);
  }

  static String? sanitizeGenerated(String raw) {
    var t = ResponseParser.answerOnly(raw);
    t = displayLabel(t);
    if (t.isEmpty) return null;
    t = t
        .replaceAll(RegExp(r'^```\w*\n?'), '')
        .replaceAll(RegExp(r'\n?```$'), '')
        .trim();
    t = t.split(RegExp(r'[\r\n]+')).first.trim();
    t = t.replaceFirst(
        RegExp(r'^(title|chat title)\s*:\s*', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'^["“«]|["”»]$'), '').trim();
    t = t.replaceAll(RegExp(r'[.!?]+$'), '').trim();
    t = displayLabel(t);
    if (t.isEmpty || t.toLowerCase() == 'new chat' || isJunk(t)) return null;
    if (t.length > 80) t = '${t.substring(0, 57)}...';
    final words = t.split(RegExp(r'\s+'));
    if (words.length > 12) {
      t = words.take(8).join(' ');
    }
    return t;
  }

  static int _rank(ChatConversation c) {
    if (isJunk(c.title)) return -1;
    final source = sourceOf(c.settings);
    if (source == sourceUser) return 4;
    if (source == sourceAi) return 3;
    if (isPlaceholder(c.title) || isGreetingTitle(c.title)) return 0;
    if (looksLikeMessageFallback(c.title)) return 1;
    return 2;
  }

  /// Keep a locked/AI title when last-write-wins would clobber it.
  static ChatConversation preferStableTitle({
    required ChatConversation winner,
    required ChatConversation loser,
  }) {
    final keepLoser = _rank(loser) > _rank(winner);
    final chosen = keepLoser ? loser : winner;
    if (chosen.title == winner.title &&
        sourceOf(chosen.settings) == sourceOf(winner.settings)) {
      return winner;
    }
    return winner.copyWith(
      title: chosen.title,
      settings: withSource(
        Map<String, dynamic>.from(winner.settings),
        sourceOf(chosen.settings) ??
            (keepLoser ? sourceAi : (sourceOf(winner.settings) ?? sourceAuto)),
      ),
    );
  }
}
