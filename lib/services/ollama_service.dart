import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_settings.dart';
import '../models/message_stats.dart';
import '../utils/chat_message_normalizer.dart';
import '../utils/log_redaction.dart';
import '../utils/ollama_tool_support.dart';

/// Native Ollama HTTP client (`/api/chat`, `/api/tags`, `/api/show`).
///
/// Yields the same stream event contract as [LMStudioService.streamChatCompletion]
/// so [ChatProvider] can reuse its V0 tool loop:
/// - `{'content': String}`
/// - `{'reasoning': String}`
/// - `{'tool_call': name, 'arguments': jsonString}`
/// - `{'error': String}`
/// - `{'usage': TokenUsage}` (optional)
class OllamaService {
  OllamaService._();
  static final OllamaService instance = OllamaService._();

  static const Duration _streamIdleTimeout = Duration(seconds: 120);
  static const Duration _showTimeout = Duration(seconds: 8);

  static final Set<http.Client> _activeStreamClients = <http.Client>{};

  /// Relay auth token when remote LM Connect is active.
  String? remoteAuthToken;

  /// Abort in-flight `/api/chat` streams (same pattern as LM Studio).
  static void cancelAllActiveStreams() {
    if (_activeStreamClients.isEmpty) return;
    debugPrint(
        '🛑 OllamaService: closing ${_activeStreamClients.length} active stream client(s)');
    final snapshot = List<http.Client>.from(_activeStreamClients);
    _activeStreamClients.clear();
    for (final client in snapshot) {
      try {
        client.close();
      } catch (_) {}
    }
  }

  Map<String, String> _headers({String? apiToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/x-ndjson, application/json',
      // Tell LM Mini Connect to route to the local Ollama process.
      'X-LM-Mini-Backend': 'ollama',
    };
    final token = apiToken?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final relay = remoteAuthToken?.trim();
    if (relay != null && relay.isNotEmpty) {
      headers['X-LM-Mini-Token'] = relay;
    }
    return headers;
  }

  String _normalizeBase(String baseUrl) {
    var trimmed = baseUrl.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// List models via native `GET /api/tags`, optionally enriching with
  /// `POST /api/show` capabilities (tools / vision / context).
  Future<List<OllamaModelInfo>> listModels({
    required String baseUrl,
    String? apiToken,
    bool enrichCapabilities = true,
    int enrichLimit = 24,
  }) async {
    final base = _normalizeBase(baseUrl);
    final response = await http
        .get(Uri.parse('$base/api/tags'), headers: _headers(apiToken: apiToken))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to list Ollama models (HTTP ${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    final models = body is Map<String, dynamic> ? body['models'] : null;
    if (models is! List) return const [];

    final parsed = <OllamaModelInfo>[];
    for (final entry in models.whereType<Map<String, dynamic>>()) {
      final id =
          (entry['name'] as String? ?? entry['model'] as String? ?? '').trim();
      if (id.isEmpty) continue;
      final lower = id.toLowerCase();
      parsed.add(OllamaModelInfo(
        id: id,
        supportsVision: _heuristicSupportsVision(lower),
        supportsTools: OllamaToolSupport.heuristic(id),
      ));
    }

    if (!enrichCapabilities || parsed.isEmpty) return parsed;

    final toEnrich = parsed.take(enrichLimit).toList();
    await Future.wait(toEnrich.map((model) async {
      final shown = await showModel(
        baseUrl: base,
        model: model.id,
        apiToken: apiToken,
      );
      if (shown == null) return;
      final index = parsed.indexWhere((m) => m.id == model.id);
      if (index < 0) return;
      parsed[index] = parsed[index].copyWith(
        supportsTools: shown.supportsTools,
        supportsVision: shown.supportsVision,
        supportsThinking: shown.supportsThinking,
        contextLength: shown.contextLength,
      );
    }));

    return parsed;
  }

  /// Pull (download) a model from the Ollama library via `POST /api/pull`.
  ///
  /// Streams progress events. [onProgress] receives a 0–1 fraction when
  /// byte totals are known, plus a human-readable status string.
  Future<void> pullModel({
    required String baseUrl,
    required String model,
    String? apiToken,
    void Function(double? progress, String status)? onProgress,
    http.Client? client,
  }) async {
    final name = model.trim();
    if (name.isEmpty) {
      throw ArgumentError('Model name is required');
    }
    final base = _normalizeBase(baseUrl);
    final ownedClient = client == null;
    final httpClient = client ?? http.Client();
    if (ownedClient) _activeStreamClients.add(httpClient);

    try {
      final request = http.Request('POST', Uri.parse('$base/api/pull'));
      request.headers.addAll(_headers(apiToken: apiToken));
      request.body = jsonEncode({
        'model': name,
        'stream': true,
      });

      final streamed =
          await httpClient.send(request).timeout(const Duration(seconds: 30));
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final body = await streamed.stream.bytesToString();
        throw Exception(_parseError(body, streamed.statusCode));
      }

      final lines = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        Map<String, dynamic> event;
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is! Map<String, dynamic>) continue;
          event = decoded;
        } catch (_) {
          continue;
        }

        final error = event['error']?.toString();
        if (error != null && error.isNotEmpty) {
          throw Exception(error);
        }

        final status = event['status']?.toString() ?? 'Downloading…';
        final total = (event['total'] as num?)?.toDouble();
        final completed = (event['completed'] as num?)?.toDouble();
        double? progress;
        if (total != null && total > 0 && completed != null) {
          progress = (completed / total).clamp(0.0, 1.0);
        } else if (status.toLowerCase().contains('success')) {
          progress = 1.0;
        }
        onProgress?.call(progress, status);

        if (status.toLowerCase() == 'success') {
          return;
        }
      }
    } finally {
      if (ownedClient) {
        _activeStreamClients.remove(httpClient);
        httpClient.close();
      }
    }
  }

  /// `POST /api/show` — capabilities + context length when available.
  Future<OllamaModelInfo?> showModel({
    required String baseUrl,
    required String model,
    String? apiToken,
  }) async {
    try {
      final base = _normalizeBase(baseUrl);
      final response = await http
          .post(
            Uri.parse('$base/api/show'),
            headers: _headers(apiToken: apiToken),
            body: jsonEncode({'model': model, 'name': model}),
          )
          .timeout(_showTimeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final caps = body['capabilities'];
      final capSet = <String>{};
      if (caps is List) {
        for (final c in caps) {
          if (c is String) capSet.add(c.toLowerCase());
        }
      }

      final supportsTools = OllamaToolSupport.fromShowCapabilities(
        capabilities: capSet,
        modelId: model,
      );
      // Prefer /api/show capabilities; fall back to name heuristics only when
      // the server omitted the capabilities list.
      final supportsVision = capSet.contains('vision') ||
          (capSet.isEmpty && _heuristicSupportsVision(model.toLowerCase()));
      final supportsThinking =
          capSet.contains('thinking') || capSet.contains('reasoning');

      int? contextLength;
      final modelInfo = body['model_info'];
      if (modelInfo is Map) {
        for (final entry in modelInfo.entries) {
          final key = entry.key.toString().toLowerCase();
          if (key.endsWith('.context_length') || key == 'context_length') {
            final value = entry.value;
            if (value is int) {
              contextLength = value;
            } else if (value is num) {
              contextLength = value.toInt();
            }
          }
        }
      }

      return OllamaModelInfo(
        id: model,
        supportsTools: supportsTools,
        supportsVision: supportsVision,
        supportsThinking: supportsThinking,
        contextLength: contextLength,
      );
    } catch (e) {
      debugPrint('OllamaService.showModel($model): $e');
      return null;
    }
  }

  /// Strict name heuristic — avoid bare `contains('vl')` false positives.
  bool _heuristicSupportsVision(String lowerId) {
    const markers = [
      'vision',
      'llava',
      'pixtral',
      'moondream',
      'minicpm-v',
      'internvl',
      '-vl',
      'vl-',
      'vlm',
      ':vl',
      '_vl',
      'vl_',
    ];
    return markers.any(lowerId.contains);
  }

  /// Native chat stream. Normalizes OpenAI-style messages from ChatProvider
  /// into Ollama `/api/chat` format (images, tool_calls, options).
  Stream<Map<String, dynamic>> streamChat({
    required String baseUrl,
    required List<Map<String, dynamic>> messages,
    required AppSettings settings,
    List<Map<String, dynamic>>? tools,
    String? apiToken,
    String? memoryContext,
  }) async* {
    final base = _normalizeBase(baseUrl);
    final apiMessages =
        _toOllamaMessages(messages, memoryContext: memoryContext);
    final options = <String, dynamic>{
      'temperature': settings.temperature,
      'top_p': settings.topP,
      'top_k': settings.topK,
      'min_p': settings.minP,
      'repeat_penalty': settings.repeatPenalty,
      'num_predict': settings.maxTokens,
      'num_ctx': settings.contextWindow,
      if (settings.frequencyPenalty != 0)
        'frequency_penalty': settings.frequencyPenalty,
      if (settings.presencePenalty != 0)
        'presence_penalty': settings.presencePenalty,
    };

    final think = _thinkValue(settings.reasoning);

    final requestBody = <String, dynamic>{
      'model': settings.selectedModel ?? '',
      'messages': apiMessages,
      'stream': true,
      'options': options,
      if (think != null) 'think': think,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
      if (settings.useStructuredOutput) 'format': 'json',
      if (settings.autoUnloadTtlMinutes != null)
        'keep_alive': '${settings.autoUnloadTtlMinutes}m',
    };

    debugPrint('OllamaService: POST $base/api/chat');
    debugPrint(jsonEncodeForLog({
      ...requestBody,
      // Don't dump huge image payloads in logs.
      'messages': apiMessages.map((m) {
        final copy = Map<String, dynamic>.from(m);
        if (copy['images'] is List) {
          copy['images'] = ['<${(copy['images'] as List).length} image(s)>'];
        }
        return copy;
      }).toList(),
    }));

    final client = http.Client();
    _activeStreamClients.add(client);
    try {
      final request = http.Request('POST', Uri.parse('$base/api/chat'));
      request.headers.addAll(_headers(apiToken: apiToken));
      request.body = jsonEncode(requestBody);

      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        yield {'error': _parseError(body, streamedResponse.statusCode)};
        return;
      }

      // Accumulate partial tool calls across NDJSON chunks.
      final toolCallBuffers = <int, Map<String, dynamic>>{};
      String lineBuffer = '';

      await for (final chunk in streamedResponse.stream
          .timeout(_streamIdleTimeout)
          .transform(utf8.decoder)) {
        final combined = lineBuffer + chunk;
        final lines = combined.split('\n');
        lineBuffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final jsonData = jsonDecode(trimmed);
            if (jsonData is! Map<String, dynamic>) continue;

            if (jsonData['error'] != null) {
              final err = jsonData['error'];
              yield {
                'error': err is String
                    ? err
                    : (err is Map
                        ? (err['message'] ?? err.toString())
                        : err.toString()),
              };
              return;
            }

            final message = jsonData['message'];
            if (message is Map<String, dynamic>) {
              final thinking = message['thinking'];
              if (thinking is String && thinking.isNotEmpty) {
                yield {'reasoning': thinking};
              }
              final content = message['content'];
              if (content is String && content.isNotEmpty) {
                yield {'content': content};
              }

              final toolCalls = message['tool_calls'];
              if (toolCalls is List && toolCalls.isNotEmpty) {
                for (var i = 0; i < toolCalls.length; i++) {
                  final tc = toolCalls[i];
                  if (tc is! Map) continue;
                  final function = tc['function'];
                  if (function is! Map) continue;
                  final name = function['name'] as String? ?? '';
                  final args = function['arguments'];
                  toolCallBuffers[i] ??= {
                    'name': '',
                    'arguments': '',
                  };
                  if (name.isNotEmpty) {
                    toolCallBuffers[i]!['name'] = name;
                  }
                  if (args != null) {
                    if (args is String) {
                      toolCallBuffers[i]!['arguments'] =
                          (toolCallBuffers[i]!['arguments'] as String) + args;
                    } else {
                      toolCallBuffers[i]!['arguments'] = jsonEncode(args);
                    }
                  }
                }
              }
            }

            final done = jsonData['done'] == true;
            if (done && toolCallBuffers.isNotEmpty) {
              for (final buffer in toolCallBuffers.values) {
                final name = (buffer['name'] as String?)?.trim() ?? '';
                if (name.isEmpty) continue;
                final arguments = buffer['arguments'] as String? ?? '{}';
                yield {
                  'tool_call': name,
                  'arguments': arguments.isNotEmpty ? arguments : '{}',
                };
              }
              yield {'finish_reason': 'tool_calls'};
              toolCallBuffers.clear();
            }

            if (done) {
              final promptEval = jsonData['prompt_eval_count'];
              final evalCount = jsonData['eval_count'];
              if (promptEval is int || evalCount is int) {
                final promptTokens = promptEval is int ? promptEval : 0;
                final completionTokens = evalCount is int ? evalCount : 0;
                yield {
                  'usage': TokenUsage(
                    promptTokens: promptTokens,
                    completionTokens: completionTokens,
                    totalTokens: promptTokens + completionTokens,
                  ),
                };
              }
            }
          } catch (e) {
            debugPrint('OllamaService: parse error: $e');
            continue;
          }
        }
      }
    } on TimeoutException {
      yield {
        'error':
            'Ollama stream timed out waiting for tokens. Is the model still loading?',
      };
    } catch (e) {
      yield {'error': e.toString()};
    } finally {
      _activeStreamClients.remove(client);
      try {
        client.close();
      } catch (_) {}
    }
  }

  Object? _thinkValue(String reasoning) {
    switch (reasoning) {
      case 'off':
      case 'false':
        return false;
      case 'on':
      case 'true':
      case 'low':
      case 'medium':
      case 'high':
      case 'max':
        // llama.cpp (and Ollama's boolean think) only honor on/off. LM Studio
        // levels are coerced to on so leftover Global params still think.
        return true;
      default:
        return null;
    }
  }

  String _parseError(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is String && err.isNotEmpty) return err;
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
      }
    } catch (_) {}
    final trimmed = body.trim();
    if (trimmed.isNotEmpty && trimmed.length < 400) {
      return 'Ollama error HTTP $statusCode: $trimmed';
    }
    return 'Ollama error HTTP $statusCode';
  }

  /// Convert ChatProvider OpenAI-style messages into Ollama `/api/chat` messages.
  List<Map<String, dynamic>> _toOllamaMessages(
    List<Map<String, dynamic>> messages, {
    String? memoryContext,
  }) {
    // Coalesce + merge memory first so Qwen never sees a second system role.
    final normalized = ChatMessageNormalizer.injectMemoryContext(
      messages,
      memoryContext,
    );
    final out = <Map<String, dynamic>>[];

    for (final raw in normalized) {
      final role = raw['role'] as String? ?? 'user';
      final content = raw['content'];

      if (role == 'tool') {
        out.add({
          'role': 'tool',
          'content': content is String ? content : jsonEncode(content),
          if (raw['name'] is String) 'name': raw['name'],
        });
        continue;
      }

      if (role == 'assistant' && raw['tool_calls'] is List) {
        final toolCalls = <Map<String, dynamic>>[];
        for (final tc in (raw['tool_calls'] as List)) {
          if (tc is! Map) continue;
          final function = tc['function'];
          if (function is! Map) continue;
          final name = function['name'] as String? ?? '';
          if (name.isEmpty) continue;
          dynamic args = function['arguments'];
          if (args is String) {
            try {
              args = jsonDecode(args);
            } catch (_) {
              args = <String, dynamic>{};
            }
          }
          toolCalls.add({
            'function': {
              'name': name,
              'arguments': args is Map ? args : <String, dynamic>{},
            },
          });
        }
        out.add({
          'role': 'assistant',
          'content': content is String ? content : '',
          if (toolCalls.isNotEmpty) 'tool_calls': toolCalls,
        });
        continue;
      }

      if (content is List) {
        // OpenAI multimodal → Ollama images[] + text content.
        final textParts = <String>[];
        final images = <String>[];
        for (final part in content) {
          if (part is! Map) continue;
          final type = part['type'] as String?;
          if (type == 'text') {
            final text = part['text'] as String? ?? '';
            if (text.isNotEmpty) textParts.add(text);
          } else if (type == 'image_url') {
            final imageUrl = part['image_url'];
            String? url;
            if (imageUrl is Map) {
              url = imageUrl['url'] as String?;
            } else if (imageUrl is String) {
              url = imageUrl;
            }
            final encoded = _imageToBase64(url);
            if (encoded != null) images.add(encoded);
          }
        }
        out.add({
          'role': role,
          'content': textParts.join('\n'),
          if (images.isNotEmpty) 'images': images,
        });
        continue;
      }

      out.add({
        'role': role,
        'content': content is String ? content : (content?.toString() ?? ''),
      });
    }

    return out;
  }

  /// Accepts data-URLs or raw base64; strips the data-URL prefix for Ollama.
  String? _imageToBase64(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma > 0 && comma < url.length - 1) {
        return url.substring(comma + 1);
      }
    }
    // Remote http(s) URLs aren't accepted by Ollama images[]; skip.
    if (url.startsWith('http://') || url.startsWith('https://')) {
      debugPrint(
          'OllamaService: skipping remote image URL (need base64 data URL)');
      return null;
    }
    return url;
  }
}

class OllamaModelInfo {
  final String id;
  final bool supportsVision;
  final bool supportsTools;

  /// From `/api/show` `capabilities` (`thinking` / `reasoning`).
  final bool supportsThinking;
  final int? contextLength;

  const OllamaModelInfo({
    required this.id,
    this.supportsVision = false,
    this.supportsTools = false,
    this.supportsThinking = false,
    this.contextLength,
  });

  OllamaModelInfo copyWith({
    String? id,
    bool? supportsVision,
    bool? supportsTools,
    bool? supportsThinking,
    int? contextLength,
  }) {
    return OllamaModelInfo(
      id: id ?? this.id,
      supportsVision: supportsVision ?? this.supportsVision,
      supportsTools: supportsTools ?? this.supportsTools,
      supportsThinking: supportsThinking ?? this.supportsThinking,
      contextLength: contextLength ?? this.contextLength,
    );
  }
}
