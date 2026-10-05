import 'dart:convert';

/// The selected model is gone on the server (unloaded, deleted, never
/// downloaded). LM Studio often returns HTTP 404 `File Not Found` /
/// `not_found_error` — not a Mini crash, and not a stale
/// `previous_response_id`.
abstract final class ModelNotFoundError {
  static const type = 'model_not_found';

  static const userMessage =
      "This model isn't available on the server. Pick another in Model Selection.";

  /// Shown when this turn already reached the model, then LM Studio rejected
  /// the same id on the automatic retry. The model is still there.
  static const interruptedReplyMessage =
      'LM Studio interrupted the reply. Send your message again.';

  static String userMessageFor(String? modelId) {
    final id = modelId?.trim() ?? '';
    if (id.isEmpty) return userMessage;
    return 'Model "$id" isn\'t available on the server. '
        'Pick another in Model Selection.';
  }

  static bool matches(Object? error) {
    if (error == null) return false;
    if (_looksLikeStaleSession(error)) return false;

    if (error is Map) {
      final errType = error['type']?.toString().toLowerCase() ?? '';
      final errorType = error['error_type']?.toString().toLowerCase() ?? '';
      final code = error['code']?.toString().toLowerCase() ?? '';
      if (errType == type ||
          errorType == type ||
          errType == 'not_found_error' ||
          errorType == 'not_found_error' ||
          errType == 'model_not_found_error' ||
          code == 'model_not_found') {
        return true;
      }
      if (matches(error['error'])) return true;
      if (matches(error['message'])) return true;
      return false;
    }

    final text = error.toString();
    final trimmed = text.trim();
    if (trimmed.startsWith('{')) {
      try {
        if (matches(jsonDecode(trimmed))) return true;
      } catch (_) {}
    }
    final nested = trimmed.indexOf('{');
    if (nested > 0) {
      try {
        if (matches(jsonDecode(trimmed.substring(nested)))) return true;
      } catch (_) {}
    }

    final lower = text.toLowerCase();
    if (_looksLikeStaleSession(lower)) return false;

    if (lower.contains('model_not_found') ||
        lower.contains('not_found_error')) {
      return true;
    }
    if (lower.contains('file not found')) return true;
    if (lower.contains('is not downloaded')) return true;
    if (lower.contains('pick an installed model')) return true;
    if (lower.contains('no model selected')) return true;
    if (lower.contains("isn't available on the server") ||
        lower.contains('is not available on the server')) {
      return true;
    }
    if (lower.contains('invalid model identifier')) return true;
    if (lower.contains('valid downloaded model')) return true;
    if (lower.contains('unknown model')) return true;
    if (lower.contains('does not exist') && lower.contains('model')) {
      return true;
    }
    if (lower.contains('model') &&
        (lower.contains('not found') ||
            lower.contains('not downloaded') ||
            lower.contains('no longer available'))) {
      return true;
    }
    return false;
  }

  static bool _looksLikeStaleSession(Object? value) {
    final lower = value.toString().toLowerCase();
    if (lower.contains('previous_response_id') &&
        (lower.contains('could not find stored response') ||
            lower.contains('stored response'))) {
      return true;
    }
    if (value is Map && value['stale_previous_response_id'] == true) {
      return true;
    }
    return false;
  }
}
