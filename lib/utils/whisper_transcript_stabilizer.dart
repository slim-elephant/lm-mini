/// Helpers for pseudo-streaming Whisper output.
///
/// Offline Whisper re-decodes the entire mic buffer on each pass, so interim
/// text can rewrite words the user already saw. We only accept updates that
/// grow or extend the previous hypothesis.
class WhisperTranscriptStabilizer {
  WhisperTranscriptStabilizer._();

  /// Returns true when [next] is safe to show instead of [previous].
  static bool shouldAcceptInterimUpdate(String previous, String next) {
    final prev = previous.trim();
    final nextText = next.trim();
    if (nextText.isEmpty) return false;
    if (prev.isEmpty) return true;
    if (nextText == prev) return false;
    if (nextText.startsWith(prev)) return true;

    final prevWords = _words(prev);
    final nextWords = _words(nextText);
    if (nextWords.length > prevWords.length && _sharePrefix(prevWords, nextWords, prevWords.length - 1)) {
      return true;
    }

    if (nextWords.length >= prevWords.length &&
        _sharePrefix(prevWords, nextWords, prevWords.length - 1)) {
      return true;
    }

    return false;
  }

  /// Collapses Whisper repetition loops ("Hello. Hello. Hello." → "Hello.").
  ///
  /// Offline Whisper commonly gets stuck emitting the same sentence or word
  /// n-gram over and over, especially on short/echoey audio. Consecutive
  /// duplicate sentences are collapsed, and word n-grams repeated 3+ times
  /// in a row (2+ for longer phrases) are reduced to one occurrence.
  static String collapseRepeats(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    var result = _collapseDuplicateSentences(trimmed);
    result = _collapseRepeatedNgrams(result);
    return result;
  }

  static String _collapseDuplicateSentences(String text) {
    final sentences = RegExp(r'[^.!?]+[.!?]*')
        .allMatches(text)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sentences.length < 2) return text;

    final kept = <String>[];
    String? lastKey;
    for (final sentence in sentences) {
      final key = _normalize(sentence);
      if (key.isNotEmpty && key == lastKey) continue;
      kept.add(sentence);
      lastKey = key;
    }
    return kept.join(' ');
  }

  static String _collapseRepeatedNgrams(String text) {
    var words = _words(text);
    final maxN = words.length ~/ 2;
    for (var n = maxN > 8 ? 8 : maxN; n >= 1; n--) {
      // Longer phrases almost never legitimately repeat back-to-back;
      // single words can ("very very"), so require a longer run there.
      final minRepeats = n >= 3 ? 2 : 3;
      final kept = <String>[];
      var i = 0;
      while (i < words.length) {
        var repeats = 1;
        while (i + (repeats + 1) * n <= words.length &&
            _ngramEquals(words, i, i + repeats * n, n)) {
          repeats++;
        }
        if (repeats >= minRepeats) {
          kept.addAll(words.sublist(i, i + n));
          i += repeats * n;
        } else {
          kept.add(words[i]);
          i++;
        }
      }
      words = kept;
    }
    return words.join(' ');
  }

  static bool _ngramEquals(List<String> words, int a, int b, int n) {
    for (var k = 0; k < n; k++) {
      if (_normalize(words[a + k]) != _normalize(words[b + k])) return false;
    }
    return true;
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<String> _words(String text) =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  static bool _sharePrefix(List<String> a, List<String> b, int count) {
    if (count <= 0) return true;
    if (a.length < count || b.length < count) return false;
    for (var i = 0; i < count; i++) {
      if (a[i].toLowerCase() != b[i].toLowerCase()) return false;
    }
    return true;
  }
}
