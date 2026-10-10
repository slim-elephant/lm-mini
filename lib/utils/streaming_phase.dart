/// Canonical generation stages shown in the full-width ChatGPT-style status.
abstract final class StreamingPhase {
  static const loadingModel = 'Loading model';
  static const processingPrompt = 'Processing prompt';
  static const thinking = 'Thinking';
  static const writing = 'Writing response';
  static const searching = 'Searching';
  static const usingTools = 'Using tools';

  /// "Connecting to LM Studio…" (network preflight). Not MCP.
  static bool isConnecting(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s.startsWith('connecting to ') && !s.contains('mcp');
  }

  /// Provider name inside a [isConnecting] status ("LM Studio").
  static String connectingTarget(String status) {
    var t = status.trim();
    if (t.length >= 14) t = t.substring(14);
    while (t.endsWith('…') || t.endsWith('.')) {
      t = t.substring(0, t.length - 1);
    }
    return t.trim();
  }

  /// Collapse noisy status strings into a stable stacked-line label.
  /// A connecting status is kept verbatim (it carries the provider name).
  static String? canonical(String status) {
    if (isConnecting(status)) return status;
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
  /// Add [phase] to [log]. "Connecting to …" is the first line only until
  /// the next stage arrives — that stage replaces it instead of stacking.
  static void record(List<String> log, String phase) {
    if (log.isNotEmpty && isConnecting(log.last) && log.last != phase) {
      log.removeLast();
    }
    if (shouldRecord(log, phase)) log.add(phase);
  }

  static bool shouldRecord(List<String> log, String phase) {
    if (log.isNotEmpty && log.last == phase) return false;
    if (phase == loadingModel && log.any((p) => p != loadingModel)) {
      return false;
    }
    return true;
  }
}
