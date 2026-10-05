import 'dart:convert';

const _redacted = '[redacted]';

/// Prompt-like JSON keys. Keep ~1% (floor 64, cap 200 chars).
const _promptKeys = {
  'system_prompt',
  'input',
  'content',
  'prompt',
  'text',
  'data_url',
  'image_url',
};

const _minPromptChars = 64;
const _maxPromptChars = 200;
const _longLineChars = 600;

const _secretKeys = {
  'authorization',
  'api-token',
  'api_token',
  'apitoken',
  'api_key',
  'apikey',
  'cf-access-client-secret',
  'x-api-key',
  'x-lm-mini-token',
  'x-goog-api-key',
  'x-auth-token',
  'cookie',
  'set-cookie',
  'access_token',
  'id_token',
  'refresh_token',
  'password',
  'secret',
};

const _headerAllowlist = {
  'accept',
  'accept-encoding',
  'cache-control',
  'connection',
  'content-length',
  'content-type',
  'host',
  'mcp-protocol-version',
  'user-agent',
};

final _jsonSecretKey = RegExp(
  r'("(?:Authorization|authorization|api[_-]?key|apiToken|api_token|'
  r'CF-Access-Client-Secret|X-Api-Key|X-LM-Mini-Token|X-Goog-Api-Key|'
  r'access_token|id_token|refresh_token|password|secret|cookie)"\s*:\s*")'
  r'([^"\\]*(?:\\.[^"\\]*)*)(")',
  caseSensitive: false,
);

final _httpAuthHeader = RegExp(
  r'((?:Authorization|CF-Access-Client-Secret|X-Api-Key|X-LM-Mini-Token|'
  r'X-Goog-Api-Key)\s*:\s*)(?!\[redacted\]).+$',
  caseSensitive: false,
  multiLine: true,
);

final _bearerToken = RegExp(
  r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
  caseSensitive: false,
);

final _jwt = RegExp(
  r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
);

/// Strip tokens from a debug / support log line.
String redactLogSecrets(String input) {
  if (input.isEmpty) return input;
  var s = input;
  s = s.replaceAllMapped(_jsonSecretKey, (m) => '${m[1]}$_redacted${m[3]}');
  s = s.replaceAllMapped(_httpAuthHeader, (m) => '${m[1]}$_redacted');
  s = s.replaceAllMapped(_bearerToken, (_) => 'Bearer $_redacted');
  s = s.replaceAllMapped(_jwt, (_) => '[redacted-jwt]');
  final asJson = _trimJsonBlobIfPossible(s);
  if (asJson != null) return asJson;
  return _trimLongLine(s);
}

String? _trimJsonBlobIfPossible(String input) {
  final trimmed = input.trimLeft();
  if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) return null;
  try {
    final decoded = jsonDecode(trimmed);
    return const JsonEncoder.withIndent('  ')
        .convert(redactSecretsInJson(decoded));
  } catch (_) {
    return null;
  }
}

String _trimLongLine(String input) {
  if (input.contains('\n')) {
    return input.split('\n').map(_trimOneLine).join('\n');
  }
  return _trimOneLine(input);
}

String _trimOneLine(String input) {
  if (input.length <= _longLineChars) return input;
  if (input.contains(' chars trimmed]')) return input;
  final keep =
      (input.length * 0.01).round().clamp(_minPromptChars, _maxPromptChars);
  final head = (keep * 2) ~/ 3;
  final tail = keep - head;
  final omitted = input.length - keep;
  return '${input.substring(0, head)}…[$omitted chars trimmed]…'
      '${input.substring(input.length - tail)}';
}

String _trimLogString(String value, {String? key}) {
  if (value.contains(' chars trimmed]') || value.contains('[omitted ')) {
    return value;
  }
  final dataIdx = value.indexOf('base64,');
  if (value.startsWith('data:') && dataIdx >= 0) {
    final omitted = value.length - dataIdx - 7;
    return '${value.substring(0, dataIdx + 7)}[omitted $omitted chars]';
  }
  final lower = key?.toLowerCase() ?? '';
  final isPrompt = _promptKeys.contains(lower) || value.length > _longLineChars;
  if (!isPrompt || value.length <= _minPromptChars) return value;
  final keep =
      (value.length * 0.01).round().clamp(_minPromptChars, _maxPromptChars);
  if (value.length <= keep) return value;
  final head = (keep * 2) ~/ 3;
  final tail = keep - head;
  final omitted = value.length - keep;
  return '${value.substring(0, head)}…[$omitted chars trimmed]…'
      '${value.substring(value.length - tail)}';
}

/// Pretty-print JSON for [debugPrint] with secrets removed.
String jsonEncodeForLog(Object? value) {
  return const JsonEncoder.withIndent('  ').convert(redactSecretsInJson(value));
}

/// Walk a request/response tree and replace auth material.
Object? redactSecretsInJson(Object? value, {String? parentKey}) {
  if (value is Map) {
    final parentIsHeaders =
        parentKey != null && parentKey.toLowerCase() == 'headers';
    return <String, dynamic>{
      for (final e in value.entries)
        e.key.toString(): _redactJsonEntry(
          key: e.key.toString(),
          value: e.value,
          parentIsHeaders: parentIsHeaders,
        ),
    };
  }
  if (value is List) {
    return [
      for (final item in value) redactSecretsInJson(item, parentKey: parentKey),
    ];
  }
  if (value is String) return _redactStringLeaf(value);
  return value;
}

Object? _redactJsonEntry({
  required String key,
  required Object? value,
  required bool parentIsHeaders,
}) {
  final lower = key.toLowerCase();
  if (_secretKeys.contains(lower) ||
      (parentIsHeaders && !_headerAllowlist.contains(lower))) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return value;
    return _redacted;
  }
  final redacted = redactSecretsInJson(value, parentKey: key);
  if (redacted is String) return _trimLogString(redacted, key: key);
  return redacted;
}

String _redactStringLeaf(String value) {
  final trimmed = value.trim();
  if (trimmed.toLowerCase().startsWith('bearer ')) return 'Bearer $_redacted';
  if (_jwt.hasMatch(trimmed)) return '[redacted-jwt]';
  return value;
}
