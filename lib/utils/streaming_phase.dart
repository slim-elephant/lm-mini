/// Canonical generation stages shown in the full-width ChatGPT-style status.
abstract final class StreamingPhase {
  static const loadingModel = 'Loading model';
  static const processingPrompt = 'Processing prompt';
  static const thinking = 'Thinking';
  static const writing = 'Writing response';
  static const searching = 'Searching';
  static const usingTools = 'Using tools';

  /// Collapse noisy status strings into a stable stacked-line label.
  static String? canonical(String status) {
    final s = status.toLowerCase();
    if (s.contains('starting chat') ||
        s.contains('session expired') ||
        s == 'complete' ||
        s == 'cancelled') {
      return null;
    }
    if (s.contains('model loaded')) {
      // Completion of a load. Keeping this as [loadingModel] reopened the
      // line after "Processing prompt" when the end event arrived late.
      return null;
    }
    if (s.contains('loading model') ||
        (s.contains('loading ') && s.contains('...'))) {
      return loadingModel;
    }
    if (s.contains('processing prompt') ||
        s.contains('sending request') ||
        s.contains('generating response') ||
        s == 'processing...') {
      return processingPrompt;
    }
    if (s.contains('thinking')) return thinking;
    if (s.contains('writing')) return writing;
    if (s.contains('searching')) return searching;
    if (s.contains('tool') ||
        s.contains('mcp') ||
        s.contains('plugin') ||
        s.contains('connecting to mcp')) {
      return usingTools;
    }
    return null;
  }

  /// A late load event must not add a second "Loading model" line once the
  /// turn has moved on to prompt processing or a later stage.
  static bool shouldRecord(List<String> log, String phase) {
    if (log.isNotEmpty && log.last == phase) return false;
    if (phase == loadingModel && log.any((p) => p != loadingModel)) {
      return false;
    }
    return true;
  }
}
