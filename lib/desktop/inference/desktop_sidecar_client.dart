import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../runtime/desktop_runtime_manager.dart';

/// OpenAI-compatible HTTP client for the desktop llama-server sidecar.
class DesktopSidecarClient {
  DesktopSidecarClient({DesktopRuntimeManager? runtime})
      : _runtime = runtime ?? DesktopRuntimeManager.instance;

  final DesktopRuntimeManager _runtime;

  String get baseUrl => _runtime.baseUrl;

  /// Streams text deltas from `/v1/chat/completions`.
  Stream<String> streamChat({
    required List<({String role, String content})> messages,
    double temperature = 0.8,
    int maxTokens = 2048,
    double topP = 0.9,
  }) async* {
    if (!_runtime.isRunning) {
      throw StateError('Desktop sidecar is not running.');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    try {
      final uri = Uri.parse('$baseUrl/v1/chat/completions');
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      req.add(utf8.encode(jsonEncode({
        'model': 'local',
        'stream': true,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'top_p': topP,
        'messages': [
          for (final m in messages) {'role': m.role, 'content': m.content},
        ],
      })));

      final res = await req.close();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final body = await res.transform(utf8.decoder).join();
        throw StateError(
          'Sidecar chat failed (${res.statusCode}): $body',
        );
      }

      var buffer = '';
      await for (final chunk in res.transform(utf8.decoder)) {
        buffer += chunk;
        while (true) {
          final idx = buffer.indexOf('\n');
          if (idx < 0) break;
          final line = buffer.substring(0, idx).trimRight();
          buffer = buffer.substring(idx + 1);
          if (line.isEmpty || !line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;
            final delta = choices.first['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) yield content;
          } catch (_) {
            // Ignore malformed SSE lines.
          }
        }
      }
    } finally {
      client.close(force: true);
    }
  }
}
