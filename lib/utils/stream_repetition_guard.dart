/// Detects runaway model loops (same letter / word / short tag repeated).
///
/// Used to cut off generation in chat and Arena when the model gets stuck
/// emitting the same unit many times in a row.
class StreamRepetitionGuard {
  StreamRepetitionGuard._();

  /// How many identical units in a row trigger a stop.
  static const int defaultThreshold = 10;

  /// Max length of a repeating multi-character unit (tags, short phrases).
  static const int maxUnitLength = 48;

  /// Returns true when [text] ends with the same unit repeated [threshold]
  /// times (character, whitespace-separated token, or short substring).
  static bool shouldStop(
    String text, {
    int threshold = defaultThreshold,
  }) {
    if (threshold < 3) threshold = 3;
    if (text.length < threshold) return false;

    if (_sameCharAtEnd(text, threshold)) return true;
    if (_sameTokenAtEnd(text, threshold)) return true;
    if (_sameSubstringAtEnd(text, threshold)) return true;
    return false;
  }

  static bool _sameCharAtEnd(String text, int threshold) {
    final last = text[text.length - 1];
    // Ignore ordinary spaces — models often emit spacing. Newlines / tabs /
    // visible characters looping are the failure mode.
    if (last == ' ') return false;
    var count = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      if (text[i] != last) break;
      count++;
      if (count >= threshold) return true;
    }
    return false;
  }

  static bool _sameTokenAtEnd(String text, int threshold) {
    // Split on whitespace; keep punctuation glued to words so tags match.
    final parts = text
        .trimRight()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < threshold) return false;
    final last = parts.last;
    // Single-char tokens are already covered by [_sameCharAtEnd].
    if (last.length < 2) return false;
    var count = 0;
    for (var i = parts.length - 1; i >= 0; i--) {
      if (parts[i] != last) break;
      count++;
      if (count >= threshold) return true;
    }
    return false;
  }

  static bool _sameSubstringAtEnd(String text, int threshold) {
    const maxLen = maxUnitLength;
    final limit = text.length ~/ threshold;
    if (limit < 2) return false;
    final upper = limit < maxLen ? limit : maxLen;
    for (var unitLen = 2; unitLen <= upper; unitLen++) {
      final unit = text.substring(text.length - unitLen);
      if (unit.trim().isEmpty) continue;
      // Prefer units that look like tags / symbols looping.
      var allMatch = true;
      for (var n = 1; n < threshold; n++) {
        final start = text.length - unitLen * (n + 1);
        if (text.substring(start, start + unitLen) != unit) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) return true;
    }
    return false;
  }
}
