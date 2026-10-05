/// Detects when reasoning spent the output cap, so chat can retry once
/// at low effort instead of stopping on an empty answer.
abstract final class ThinkingBudget {
  /// Effort to send on the automatic retry.
  ///
  /// Prefers `low`. Models that only expose off/on get `off`, because
  /// sending `low` would be coerced back to `on`.
  static String? retryEffort(String? reasoning, [List<String>? allowed]) {
    if (!isHighEffort(reasoning)) return null;
    if (allowed != null && allowed.isEmpty) return null;
    if (allowed == null || allowed.contains('low')) return 'low';
    if (allowed.contains('off')) return 'off';
    return null;
  }

  /// `high` and `on` both ask for a long thinking trace.
  static bool isHighEffort(String? reasoning) {
    switch (reasoning) {
      case 'high':
      case 'on':
      case 'true':
        return true;
      default:
        return false;
    }
  }

  /// Empty answer whose stats show thinking filled the output cap.
  ///
  /// A normal end (`eos` / `stop`) with a short trace does not match.
  /// Missing stats do not match — we only downgrade effort when the
  /// server says the cap was hit.
  static bool consumedByThinking({
    required Map<String, dynamic>? stats,
    required int maxTokens,
    required bool hadReasoning,
  }) {
    if (stats == null) return false;
    final reasoningTokens = _asInt(stats['reasoning_output_tokens']);
    final totalTokens = _asInt(stats['total_output_tokens']) ??
        _asInt(stats['completion_tokens']);
    final thought =
        hadReasoning || (reasoningTokens != null && reasoningTokens > 0);
    if (!thought) return false;

    final lengthStop = _isLengthStop(
      stats['stop_reason'] ?? stats['finish_reason'],
    );
    if (lengthStop) return true;

    if (reasoningTokens == null ||
        reasoningTokens <= 0 ||
        totalTokens == null ||
        totalTokens <= 0 ||
        maxTokens <= 0) {
      return false;
    }
    final dominates = reasoningTokens >= (totalTokens * 0.85).ceil();
    final nearCap = totalTokens >= (maxTokens * 0.9).floor();
    return dominates && nearCap;
  }

  static bool shouldRetryWithLowEffort({
    required String? reasoning,
    required Map<String, dynamic>? stats,
    required int maxTokens,
    required bool answerEmpty,
    required bool hadReasoning,
  }) {
    if (!answerEmpty || !isHighEffort(reasoning)) return false;
    return consumedByThinking(
      stats: stats,
      maxTokens: maxTokens,
      hadReasoning: hadReasoning,
    );
  }

  static bool _isLengthStop(Object? raw) {
    final stop = raw?.toString().toLowerCase() ?? '';
    if (stop.isEmpty) return false;
    return stop.contains('length') ||
        stop.contains('max_output') ||
        stop.contains('max_tokens');
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
