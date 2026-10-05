import 'dart:convert';

import 'chat_image_payload.dart';

/// The model host (LM Studio / Ollama llama-server) died mid-generation.
///
/// Not a Mini crash — hide Send to support and point at context size,
/// max tokens, or a huge attached photo.
enum HostInferenceErrorKind {
  ggmlScheduler,
  terminated,
}

abstract final class HostInferenceError {
  static const ggmlUserMessage =
      "The model server crashed (llama.cpp scheduler). This isn't Mini. "
      'Lower context length and max tokens — very large values (for example '
      '128k context) often cause this.';

  static const terminatedUserMessage =
      'LM Studio stopped the generation on your computer '
      '(the process was terminated).';

  static String terminatedUserMessageFor({int? largeImageBytes}) {
    if (largeImageBytes == null || largeImageBytes <= 0) {
      return terminatedUserMessage;
    }
    return 'LM Studio stopped the generation on your computer. '
        'A large attached image (${ChatImagePayload.formatBytes(largeImageBytes)}) '
        'is the likely cause.';
  }

  static String userMessage(Object? error, {int? largeImageBytes}) {
    return switch (classify(error)) {
      HostInferenceErrorKind.ggmlScheduler => ggmlUserMessage,
      HostInferenceErrorKind.terminated =>
        terminatedUserMessageFor(largeImageBytes: largeImageBytes),
      null => error?.toString() ?? terminatedUserMessage,
    };
  }

  static bool matches(Object? error) => classify(error) != null;

  static bool isGgmlScheduler(Object? error) =>
      classify(error) == HostInferenceErrorKind.ggmlScheduler;

  static bool isTerminated(Object? error) =>
      classify(error) == HostInferenceErrorKind.terminated;

  static HostInferenceErrorKind? classify(Object? error) {
    if (error == null) return null;
    if (error is Map) {
      return classify(error['error_type']) ??
          classify(error['type']) ??
          classify(error['error']) ??
          classify(error['message']);
    }

    final text = error.toString();
    final trimmed = text.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        final nested = classify(decoded);
        if (nested != null) return nested;
      } catch (_) {}
    }
    final nestedJson = trimmed.indexOf('{');
    if (nestedJson > 0) {
      try {
        final nested = classify(jsonDecode(trimmed.substring(nestedJson)));
        if (nested != null) return nested;
      } catch (_) {}
    }

    final lower = text.toLowerCase();
    if (lower.isEmpty) return null;
    if (_isGgml(lower)) return HostInferenceErrorKind.ggmlScheduler;
    if (_isTerminated(lower)) return HostInferenceErrorKind.terminated;
    return null;
  }

  static bool _isGgml(String lower) {
    if (lower.contains('ggml_assert')) return true;
    if (lower.contains('ggml_sched_max_split_inputs')) return true;
    if (lower.contains('n_inputs < ggml_sched')) return true;
    if (lower.contains('llama.cpp scheduler')) return true;
    return false;
  }

  static bool _isTerminated(String lower) {
    if (lower.contains('until terminated')) return false;
    if (lower.contains('ggml_assert')) return false;

    if (lower.contains('stopped the generation')) return true;
    if (lower.contains('the process was terminated')) return true;
    if (lower.contains('"error":"terminated"') ||
        lower.contains('"error": "terminated"')) {
      return true;
    }

    final compact = lower.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact == 'terminated' ||
        compact == 'error: terminated' ||
        compact == 'exception: terminated') {
      return true;
    }
    if (compact.contains('llama-server process has terminated') ||
        compact.contains('llama server process has terminated')) {
      return true;
    }
    if (compact.contains('lm studio error: terminated') ||
        compact.contains('lm studio error exact') &&
            compact.contains('terminated')) {
      return true;
    }
    return false;
  }
}
