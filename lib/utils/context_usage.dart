import 'context_fit.dart';
import 'response_parser.dart';

/// One chat row for the composer context meter.
class ContextUsageMessage {
  final String content;

  /// Server prompt tokens for this reply, when LM Studio reported them.
  final int? inputTokens;

  /// Server generated tokens, including thinking.
  final int? outputTokens;

  const ContextUsageMessage({
    required this.content,
    this.inputTokens,
    this.outputTokens,
  });

  bool get hasServerTokens =>
      inputTokens != null &&
      outputTokens != null &&
      inputTokens! >= 0 &&
      outputTokens! >= 0;
}

/// Context occupied in the composer bar.
///
/// LM Studio counts real tokens, including thinking. A character guess of the
/// visible answer stays far below that. When a reply has server stats, those
/// numbers are the meter. Text is only estimated for the draft and for turns
/// that have not finished yet.
class ContextUsage {
  ContextUsage._();

  /// Answer plus thinking. The visible-answer helper hides thinking, which
  /// made the bar lag LM Studio for the whole generation.
  static String countableText(String content) {
    final parsed = ResponseParser.parse(content);
    final answer = parsed.answer.trim();
    final thinking = (parsed.thinking ?? '').trim();
    if (thinking.isEmpty && answer.isEmpty) return content.trim();
    if (thinking.isEmpty) return answer;
    if (answer.isEmpty) return thinking;
    return '$thinking\n$answer';
  }

  static int used({
    required List<ContextUsageMessage> messages,
    String systemPrompt = '',
    String draft = '',
    String? compactSummary,
  }) {
    var used = 0;
    int? previousInput;
    var coveredUntil = -1;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (!message.hasServerTokens) continue;
      final input = message.inputTokens!;
      final output = message.outputTokens!;
      if (previousInput == null || input < previousInput || input > used) {
        // First reply, a new session, or a full history resend.
        used = input + output;
      } else {
        // Continuation. `input` grows by the new prompt only. Earlier
        // output tokens stay in the cache and are not inside `input`.
        used += (input - previousInput) + output;
      }
      previousInput = input;
      coveredUntil = i;
    }

    if (coveredUntil < 0) {
      used += ContextFit.estimateTokens(systemPrompt);
      final summary = compactSummary?.trim();
      if (summary != null && summary.isNotEmpty) {
        used += ContextFit.estimateTokens(summary);
      }
      for (final message in messages) {
        used += ContextFit.estimateTokens(countableText(message.content));
      }
    } else {
      for (var i = coveredUntil + 1; i < messages.length; i++) {
        used += ContextFit.estimateTokens(countableText(messages[i].content));
      }
    }

    used += ContextFit.estimateTokens(draft);
    return used;
  }
}
