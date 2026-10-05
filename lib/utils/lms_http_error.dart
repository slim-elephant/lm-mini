import 'dart:convert';

/// LM Studio / OpenAI-style "this JSON field was missing" errors.
///
/// Mini still sends `model` / `messages` / `instance_id`. When the server
/// reports them missing, the body usually never arrived (proxy, tunnel,
/// or a non-LMS URL) — it is not an empty picker.
String? missingRequiredFieldFromHttpBody(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      final decoded = jsonDecode(trimmed);
      final fromJson = _fieldFromJson(decoded);
      if (fromJson != null) return fromJson;
    } catch (_) {}
  }

  return _fieldFromMessage(trimmed);
}

bool requestJsonHasField(Map<dynamic, dynamic> request, String field) {
  if (!request.containsKey(field)) return false;
  final value = request[field];
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is List) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

/// Chat JSON Mini sent never arrived as a parsed body.
abstract final class DroppedRequestBodyError {
  static const userMessage =
      'Mini sent this chat, but it never reached LM Studio. '
      'If you run a proxy, tunnel, or extra URL in front of LM Studio, try '
      'without it — or point Mini straight at LM Studio (your computer\'s IP, '
      'USB, or Connect).';

  static bool matches(Object? error) {
    if (error == null) return false;
    if (error is Map) {
      return matches(error['error']) ||
          matches(error['message']) ||
          matches(error['error_type']);
    }

    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.isEmpty) return false;
    if (lower.contains('never reached lm studio')) return true;
    if (lower.contains('was missing, but mini sent it')) return true;

    final field = missingRequiredFieldFromHttpBody(text);
    if (field == 'model' || field == 'messages' || field == 'instance_id') {
      return true;
    }
    if (lower.contains("'messages' field is required") ||
        lower.contains('"messages" field is required')) {
      return true;
    }
    return false;
  }
}

String? _fieldFromJson(Object? value) {
  if (value is Map) {
    final err = value['error'];
    if (err is Map) {
      final param = err['param']?.toString().trim();
      if (param != null && param.isNotEmpty) return param;
      final fromMsg = _fieldFromMessage(err['message']?.toString() ?? '');
      if (fromMsg != null) return fromMsg;
    }
    if (err is String) {
      final fromMsg = _fieldFromMessage(err);
      if (fromMsg != null) return fromMsg;
    }
    final fromMsg = _fieldFromMessage(value['message']?.toString() ?? '');
    if (fromMsg != null) return fromMsg;
  }
  return null;
}

String? _fieldFromMessage(String message) {
  if (message.isEmpty) return null;
  final missing = RegExp(
    r"Missing required field '([^']+)'",
    caseSensitive: false,
  ).firstMatch(message);
  if (missing != null) return missing[1];
  final required = RegExp(
    r"'([^']+)' field is required",
    caseSensitive: false,
  ).firstMatch(message);
  if (required != null) return required[1];
  return null;
}
