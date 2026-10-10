import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lm_studio_model.dart';
import '../models/chat_message.dart';
import '../models/app_settings.dart';
import '../models/message_stats.dart';
import 'reasoning_support_service.dart';
import '../utils/chat_image_payload.dart';
import '../utils/chat_message_normalizer.dart';
import '../utils/log_redaction.dart';
import '../utils/lms_http_error.dart';
import '../utils/lm_studio_download_cancel.dart';
import '../utils/model_not_found_error.dart';
import '../utils/openai_compatible_params.dart';
import '../utils/relay_url.dart';
import '../utils/server_http_client.dart';
import '../utils/unsloth_load.dart';
import '../utils/image_gen_prompt.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

/// Extracts a reasoning/thinking delta from OpenAI-compatible stream chunks.
/// oMLX and other providers may use `reasoning_content`, `reasoning`, or
/// `thinking` depending on model template.
String? _reasoningFromDelta(Map<String, dynamic>? delta) {
  if (delta == null) return null;
  for (final key in ['reasoning_content', 'reasoning', 'thinking']) {
    final value = delta[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}

class LMStudioService {
  static const String _modelsEndpoint = '/api/v1/models';
  static const String _modelsV0Endpoint =
      '/api/v0/models'; // for single model info (no v1 equiv)
  static const String _openAIChatEndpoint =
      '/v1/chat/completions'; // OpenAI-compatible (supports tools)
  static const String _responsesEndpoint =
      '/v1/responses'; // New responses endpoint (supports MCP)
  static const String _statefulChatEndpoint =
      '/api/v1/chat'; // New v1 stateful endpoint with MCP support
  static const String _completionsEndpoint = '/api/v0/completions';
  static const String _embeddingsEndpoint =
      '/v1/embeddings'; // OpenAI-compatible endpoint
  static const String _loadModelEndpoint = '/api/v1/models/load';
  static const String _unloadModelEndpoint = '/api/v1/models/unload';
  static const String _downloadModelEndpoint = '/api/v1/models/download';
  static const String _downloadStatusEndpoint =
      '/api/v1/models/download/status';

  // HuggingFace API
  static const String _huggingFaceApiBase = 'https://huggingface.co/api';

  /// Max time to wait for the next byte on an in-flight SSE stream before
  /// treating the connection as dead. Guards against "half-open" sockets
  /// (e.g. a backgrounded mobile connection whose NAT mapping expired without
  /// a FIN/RST) so a stalled generation surfaces an error and clears its
  /// foreground notification instead of hanging forever. Generous enough to
  /// tolerate slow time-to-first-token on reasoning / cloud models.
  static const Duration _streamIdleTimeout = Duration(seconds: 120);

  /// HTTP clients dedicated to in-flight streaming requests. Tracked so
  /// `stopGeneration()` can close them, which closes the underlying SSE
  /// socket. LM Studio detects the client disconnect and aborts the
  /// in-progress generation (there is no explicit `/cancel` REST
  /// endpoint — closing the connection is the documented behavior).
  static final Set<http.Client> _activeStreamClients = <http.Client>{};

  /// Hugging Face download-status GETs in flight. Chat streams wait for
  /// these to finish so they do not overlap (LM Studio often returns an
  /// empty completion for a second concurrent request).
  static int _downloadStatusInFlight = 0;

  /// True while any Chat Completions / V1 SSE client is still open.
  static bool get hasActiveStreams => _activeStreamClients.isNotEmpty;

  static Future<void> waitForDownloadStatusIdle({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (_downloadStatusInFlight > 0) {
      if (DateTime.now().isAfter(deadline)) {
        debugPrint(
            '⚠️ LMStudioService.waitForDownloadStatusIdle: timed out with '
            '$_downloadStatusInFlight status request(s) still open');
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  /// One-shot GET to the chat server with a short TCP connect timeout.
  static Future<http.Response> _serverGet(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final client = createServerHttpClient();
    try {
      return await client.get(url, headers: headers);
    } finally {
      client.close();
    }
  }

  /// One-shot POST to the chat server with a short TCP connect timeout.
  static Future<http.Response> _serverPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = createServerHttpClient();
    try {
      return await client.post(url, headers: headers, body: body);
    } finally {
      client.close();
    }
  }

  /// Track the SSE client immediately so download polling yields, then wait
  /// for any in-flight status GET before opening the stream.
  ///
  /// Uses [createServerHttpClient] so a dead LAN host fails within
  /// [kServerConnectTimeout] instead of the OS default (~60–75 s).
  Future<http.Client> _beginStreamClient() async {
    final client = createServerHttpClient();
    _activeStreamClients.add(client);
    await waitForDownloadStatusIdle();
    return client;
  }

  /// Wait until in-flight SSE clients are closed (or [timeout]).
  /// One-shot requests (e.g. auto titles) must not overlap the main chat
  /// stream — LM Studio often returns an empty completion for a second
  /// concurrent request.
  static Future<void> waitForStreamsIdle({
    Duration timeout = const Duration(seconds: 30),
    Duration grace = const Duration(milliseconds: 150),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (_activeStreamClients.isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        debugPrint(
          '⚠️ LMStudioService.waitForStreamsIdle: timed out with '
          '${_activeStreamClients.length} client(s) still open',
        );
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (grace > Duration.zero) {
      await Future<void>.delayed(grace);
    }
  }

  /// Close every in-flight streaming HTTP client. Safe to call when no
  /// streams are active. Used by `ChatProvider.stopGeneration()`.
  static void cancelAllActiveStreams() {
    if (_activeStreamClients.isEmpty) return;
    debugPrint(
        '🛑 LMStudioService: closing ${_activeStreamClients.length} active stream client(s)');
    final snapshot = List<http.Client>.from(_activeStreamClients);
    _activeStreamClients.clear();
    for (final c in snapshot) {
      try {
        c.close();
      } catch (_) {
        // best-effort; client may already be closed
      }
    }
  }

  /// Remote access auth token for relay server.
  /// Set by SettingsProvider when remote mode is active.
  String? remoteAuthToken;

  /// Relay backend to hit when [remoteAuthToken] is set (`lmStudio`,
  /// `lmMiniDesktop`, …). Defaults to LM Studio for Electron Connect.
  String? remoteBackend;

  /// Paired relay base URL (`remoteServerUrl`). [remoteAuthToken] and the
  /// `X-LM-Mini-Backend` routing header are only sent to requests under it.
  String? remoteRelayBaseUrl;

  static bool _isLoopbackUrl(String? url) {
    final host = url == null ? null : Uri.tryParse(url.trim())?.host;
    return host == '127.0.0.1' || host == 'localhost' || host == '::1';
  }

  /// Arbitrary extra HTTP headers added to every LM Studio request.
  /// Includes Cloudflare Access service-token headers and any user-defined
  /// custom headers. Set by SettingsProvider whenever settings change.
  Map<String, String>? customHeaders;

  /// Build HTTP headers with optional API token authentication
  /// LM Studio 0.4.0+ supports Bearer token authentication
  /// When remote access is active, also includes the relay auth token
  Map<String, String> _buildHeaders({
    required String requestUrl,
    String? apiToken,
    bool isStream = false,
    String? backend,
    CloudApiType? cloudProviderType,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (isStream) {
      headers['Accept'] = 'text/event-stream';
    }
    if (apiToken != null && apiToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiToken';
    }
    // Relay token + backend routing only ever go to the paired relay —
    // never to cloud APIs or other hosts sharing this client.
    final toRelay = isRelayRequestUrl(requestUrl, remoteRelayBaseUrl);
    if (toRelay && remoteAuthToken != null && remoteAuthToken!.isNotEmpty) {
      headers['X-LM-Mini-Token'] = remoteAuthToken!;
    }
    // Route through LM Mini Connect to the correct desktop backend. The
    // routing hint (not the token) may also go to a loopback URL — the USB
    // bridge on this phone — since it never leaves the device.
    final resolvedBackend = !(toRelay || _isLoopbackUrl(requestUrl))
        ? null
        : backend ??
        (cloudProviderType == CloudApiType.omlx
            ? 'omlx'
            : cloudProviderType == CloudApiType.ollama
                ? 'ollama'
                : cloudProviderType == CloudApiType.jan
                    ? 'jan'
                    : cloudProviderType == CloudApiType.unsloth
                        ? 'unsloth'
                        : (remoteAuthToken != null &&
                                remoteAuthToken!.isNotEmpty
                            ? (remoteBackend ?? 'lmStudio')
                            : null));
    if (resolvedBackend != null && resolvedBackend.isNotEmpty) {
      headers['X-LM-Mini-Backend'] = resolvedBackend;
    }
    if (customHeaders != null && customHeaders!.isNotEmpty) {
      // User-supplied headers take precedence for proxy auth (Cloudflare
      // Access, etc.). Never let them override hop-by-hop / body framing
      // or LMS sees an empty JSON object ("model" / "messages" required).
      customHeaders!.forEach((key, value) {
        final lower = key.toLowerCase();
        if (lower == 'content-length' ||
            lower == 'transfer-encoding' ||
            lower == 'host' ||
            lower == 'connection' ||
            lower == 'expect') {
          return;
        }
        headers[key] = value;
      });
    }
    return headers;
  }

  static bool _hasApiToken(String? apiToken) =>
      apiToken != null && apiToken.isNotEmpty;

  /// Parse error response from LM Studio API
  /// Returns a user-friendly error message
  static String _parseErrorResponse(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map) {
        // Check for error object (OpenAI format)
        if (body['error'] != null) {
          final error = body['error'];
          if (error is Map) {
            return error['message'] ?? error.toString();
          }
          return error.toString();
        }
        // Check for message field
        if (body['message'] != null) {
          return body['message'].toString();
        }
      }
    } catch (_) {}

    // Provide helpful messages for common status codes
    switch (response.statusCode) {
      case 401:
        return 'Authentication failed. Check your API token in Settings.';
      case 403:
        return 'Access forbidden. Your API token may not have permission for this operation.';
      case 404:
        return 'Endpoint not found. Check the server URL and that the selected provider is running.';
      case 500:
        return 'The server returned an error. Try again or restart the server.';
      case 502:
      case 503:
        return 'The server is unavailable. Make sure it is running and reachable.';
      default:
        return 'Server error (${response.statusCode}): ${response.reasonPhrase}';
    }
  }

  /// LM Studio `/api/v1/chat` error when `previous_response_id` is gone
  /// (30-day auto-delete, server data wipe, or a bogus id). There is no GET
  /// lookup — this is only visible on the next send.
  static const String stalePreviousResponseIdType =
      'stale_previous_response_id';

  /// True when [value] is LM Studio's "stored response not found" error.
  /// Accepts HTTP bodies, error maps, stream chunks, or message strings.
  static bool isStalePreviousResponseId(Object? value) {
    if (value == null) return false;
    if (value is String) {
      final text = value.trim();
      if (text.startsWith('{')) {
        try {
          return isStalePreviousResponseId(jsonDecode(text));
        } catch (_) {}
      }
      final lower = text.toLowerCase();
      return lower.contains('could not find stored response') &&
          lower.contains('previous_response_id');
    }
    if (value is Map) {
      if (value['stale_previous_response_id'] == true) return true;
      if (value['error_type']?.toString() == stalePreviousResponseIdType) {
        return true;
      }
      if (value['param']?.toString() == 'previous_response_id') {
        final code = value['code']?.toString();
        if (code == null || code == 'invalid_value') return true;
      }
      if (isStalePreviousResponseId(value['error'])) return true;
      if (isStalePreviousResponseId(value['message'])) return true;
      return false;
    }
    return isStalePreviousResponseId(value.toString());
  }

  static const String contextOverflowType = 'exceed_context_size_error';

  /// SSE started (`chat.start`) then the socket closed with no error body.
  /// Distinct from [contextOverflowType] so MCP / auth / empty-response
  /// messages are not overwritten.
  static const String streamClosedAfterStartType =
      'stream_closed_after_chat_start';

  static final _contextOverflowTokensRe = RegExp(
    r'request\s*\((\d+)\s*tokens?\)\s*exceeds the available context size\s*\((\d+)\s*tokens?\)',
    caseSensitive: false,
  );

  /// True when the engine rejected the prompt as larger than `n_ctx`.
  /// Matches llama.cpp `exceed_context_size_error` and LM Studio wrappers.
  static bool isContextOverflowError(Object? value) {
    if (value == null) return false;
    if (value is Map) {
      if (isStreamClosedAfterStart(value)) return false;
      if (value['error_type']?.toString() == contextOverflowType) return true;
      final type = value['type']?.toString();
      if (type == contextOverflowType) return true;
      if (isContextOverflowError(value['error'])) return true;
      if (isContextOverflowError(value['message'])) return true;
      return false;
    }
    final text = value.toString();
    if (text.trim().startsWith('{')) {
      try {
        if (isContextOverflowError(jsonDecode(text))) return true;
      } catch (_) {}
    }
    final lower = text.toLowerCase();
    if (lower.contains('exceed_context_size_error')) return true;
    if (lower.contains('exceeds the available context size')) return true;
    if (lower.contains('n_prompt_tokens') && lower.contains('n_ctx')) {
      return true;
    }
    if (lower.contains('context length') &&
        (lower.contains('exceed') || lower.contains('n_ctx'))) {
      return true;
    }
    if (lower.contains('n_keep') && lower.contains('context')) return true;
    return _contextOverflowTokensRe.hasMatch(text);
  }

  /// Prompt tokens vs loaded `n_ctx` when the engine reported them.
  static ({int? promptTokens, int? contextTokens}) contextOverflowTokens(
      Object? value) {
    int? prompt;
    int? ctx;
    void take(Object? source) {
      if (source is Map) {
        final p = source['n_prompt_tokens'] ?? source['prompt_tokens'];
        final c = source['n_ctx'] ?? source['context_length'];
        if (p is num) prompt ??= p.toInt();
        if (c is num) ctx ??= c.toInt();
        take(source['error']);
        take(source['message']);
        return;
      }
      final text = source?.toString() ?? '';
      final match = _contextOverflowTokensRe.firstMatch(text);
      if (match != null) {
        prompt ??= int.tryParse(match.group(1)!);
        ctx ??= int.tryParse(match.group(2)!);
      }
      final nested = text.indexOf('{');
      if (nested >= 0) {
        try {
          take(jsonDecode(text.substring(nested)));
        } catch (_) {}
      }
    }

    take(value);
    return (promptTokens: prompt, contextTokens: ctx);
  }

  static String contextOverflowUserMessage(
    Object? value, {
    int? largeImageBytes,
  }) {
    final tokens = contextOverflowTokens(value);
    final prompt = tokens.promptTokens;
    final ctx = tokens.contextTokens;
    final image = _largeImageCause(largeImageBytes);
    if (prompt != null && ctx != null && prompt > 0 && ctx > 0) {
      return 'Context ran out. This prompt is $prompt tokens but the loaded '
          'window is only $ctx.$image '
          'Increase context length, compact the chat, or use Roll / Cut middle.';
    }
    if (ctx != null && ctx > 0) {
      return 'Context ran out. This prompt is larger than the loaded window '
          '($ctx tokens).$image '
          'Increase context length, compact the chat, or use Roll / Cut middle.';
    }
    return 'Context ran out. This prompt is larger than the loaded window.$image '
        'Increase context length, compact the chat, or use Roll / Cut middle.';
  }

  static String _largeImageCause(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    return ' A large attached image (${ChatImagePayload.formatBytes(bytes)}) '
        'is the likely cause — try a smaller photo.';
  }

  /// LM Studio often sends `chat.start` then tears down the SSE socket when
  /// llama.cpp rejects the prompt, without forwarding `exceed_context_size_error`.
  static Map<String, dynamic> streamClosedAfterChatStartChunk({
    int? contextTokens,
  }) {
    return {
      'error':
          'LM Studio closed the stream after chat.start with no error body.',
      'error_type': streamClosedAfterStartType,
      'type': streamClosedAfterStartType,
      if (contextTokens != null && contextTokens > 0) 'n_ctx': contextTokens,
      'stream_closed_after_start': true,
    };
  }

  static bool isStreamClosedAfterStart(Object? value) {
    if (value is Map) {
      return value['error_type']?.toString() == streamClosedAfterStartType ||
          value['type']?.toString() == streamClosedAfterStartType ||
          value['stream_closed_after_start'] == true;
    }
    return false;
  }

  static String streamClosedAfterStartUserMessage({
    int? contextTokens,
    int? largeImageBytes,
  }) {
    return contextOverflowUserMessage(
      {
        'error_type': contextOverflowType,
        if (contextTokens != null && contextTokens > 0) 'n_ctx': contextTokens,
      },
      largeImageBytes: largeImageBytes,
    );
  }

  /// SSE never produced a token — only ingest events. LM Studio often dies
  /// this way when the prompt (or a large image) exceeds `n_ctx`.
  static bool isIngestOnlyStream(Iterable<String> chunkLog) {
    if (chunkLog.isEmpty) return false;
    const ingest = {
      'chat.start',
      'prompt_processing.start',
      'prompt_processing.progress',
      'prompt_processing.end',
      'model_load.start',
      'model_load.progress',
      'model_load.end',
    };
    var sawIngest = false;
    for (final e in chunkLog) {
      if (!ingest.contains(e)) return false;
      if (e == 'chat.start' || e.startsWith('prompt_processing')) {
        sawIngest = true;
      }
    }
    return sawIngest;
  }

  static String _exactLmStudioErrorText(Object? payload) {
    if (payload == null) return '<null>';
    if (payload is String) return payload;
    try {
      return jsonEncode(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  static void _debugPrintExactLmStudioError(String where, Object? payload) {
    debugPrint(
        '📥 LM Studio error [$where]: ${_exactLmStudioErrorText(payload)}');
  }

  /// SSE error / overflow payload, including engine errors that arrive as a
  /// bare JSON object (no wrapping `error` key) after `chat.start`.
  static Map<String, dynamic>? errorChunkFromV1Json(
    dynamic jsonData, {
    String? eventType,
  }) {
    if (jsonData is! Map) return null;
    final map = Map<String, dynamic>.from(jsonData);
    final errorObj = map['error'];
    final declaredType = eventType ?? map['type']?.toString();
    final overflow = isContextOverflowError(map) ||
        isContextOverflowError(errorObj) ||
        isContextOverflowError(map['message']);
    final stale =
        isStalePreviousResponseId(map) || isStalePreviousResponseId(errorObj);
    final missingModel = !stale &&
        (ModelNotFoundError.matches(map) ||
            ModelNotFoundError.matches(errorObj));
    final isErrorEvent = overflow ||
        stale ||
        missingModel ||
        errorObj != null ||
        declaredType == 'error' ||
        (declaredType?.contains('error') ?? false);
    if (!isErrorEvent) return null;

    _debugPrintExactLmStudioError('V1 SSE ${declaredType ?? 'data'}', map);

    String message;
    String? errType;
    if (errorObj is Map) {
      errType = errorObj['type']?.toString();
      message = errorObj['message']?.toString() ?? errorObj.toString();
    } else if (errorObj != null) {
      message = errorObj.toString();
    } else {
      message = map['message']?.toString() ?? map.toString();
      errType = map['type']?.toString();
    }

    return {
      'error': message,
      'error_type': stale
          ? stalePreviousResponseIdType
          : overflow
              ? contextOverflowType
              : missingModel
                  ? ModelNotFoundError.type
                  : (errType ?? declaredType ?? 'unknown'),
      if (stale) 'stale_previous_response_id': true,
      if (ReasoningSupportService.isReasoningConfigError(errorObj) ||
          ReasoningSupportService.isReasoningConfigError(map))
        'reasoning_config_error': true,
    };
  }

  static bool _v1ErrorAbortsStream(Map<String, dynamic> chunk) {
    final type = chunk['error_type'] as String?;
    return type == contextOverflowType ||
        type == streamClosedAfterStartType ||
        type == stalePreviousResponseIdType ||
        type == ModelNotFoundError.type ||
        chunk['reasoning_config_error'] == true;
  }

  /// Structured stream chunk for a dropped `previous_response_id`.
  static Map<String, dynamic>? stalePreviousResponseErrorFromHttpBody(
      String body) {
    if (!isStalePreviousResponseId(body)) return null;
    final msg = ReasoningSupportService.messageFromHttpBody(body) ??
        'Previous response was not found on the server.';
    return {
      'error': msg,
      'error_type': stalePreviousResponseIdType,
      'stale_previous_response_id': true,
    };
  }

  /// Structured stream chunk when the selected model is missing on the server.
  static Map<String, dynamic>? modelNotFoundErrorFromHttpBody(String body) {
    if (isStalePreviousResponseId(body)) return null;
    if (!ModelNotFoundError.matches(body)) return null;
    final msg = ReasoningSupportService.messageFromHttpBody(body) ??
        ModelNotFoundError.userMessage;
    return {
      'error': msg,
      'error_type': ModelNotFoundError.type,
    };
  }

  /// Maps [AppSettings.reasoning] to the LM Studio `/api/v1/chat` `reasoning`
  /// field (`off` | `low` | `medium` | `high` | `on`). Returns null when this
  /// model has been learned to reject the param.
  ///
  /// Omitting the field is **not** off — LM Studio uses the model's default,
  /// which is thinking-on for Qwen3. Send `"off"` when the user wants off.
  ///
  /// [forceOffForTools]: if the user has thinking on and the model is a known
  /// tools+thinking conflict family that still accepts the param, send `"off"`
  /// instead. Never sends anything for blocklisted models.
  static String? reasoningApiValue(
    AppSettings settings,
    String modelId, {
    bool forceOffForTools = false,
  }) {
    final normalized = switch (settings.reasoning) {
      'true' => 'low',
      'false' => 'off',
      _ => settings.reasoning,
    };

    final allowed =
        ReasoningSupportService.instance.allowedOptionsSync(modelId);
    final coerced = ReasoningSupportService.coerceApiValue(normalized, allowed);
    if (coerced == null) return null;

    // User has thinking on; for Qwen+tools, try disabling via API when possible.
    if (forceOffForTools &&
        coerced != 'off' &&
        modelNeedsReasoningOffForTools(modelId)) {
      final off = ReasoningSupportService.coerceApiValue('off', allowed);
      if (off == 'off') return 'off';
    }

    return coerced;
  }

  /// Qwen 3.5/3.6 (+ LM Studio) often emit malformed tool XML when thinking
  /// is on (`Failed to parse tool call: Expected "<parameter="..."`).
  /// Only useful when the model exposes a reasoning API control.
  static bool modelNeedsReasoningOffForTools(String modelId) {
    final id = modelId.toLowerCase();
    if (id.contains('qwen3.5') ||
        id.contains('qwen3.6') ||
        id.contains('qwen3_5') ||
        id.contains('qwen3_6')) {
      return true;
    }
    // e.g. qwen-3.5-4b, qwen3-5b naming variants
    return RegExp(r'qwen[-_]?3\.?[56]\b').hasMatch(id);
  }

  /// Whether the UI should offer reasoning controls for this model.
  /// Learned from LM Studio errors — not from model name heuristics.
  static bool modelLikelyExposesReasoningConfig(String modelId) {
    if (modelId.isEmpty) return true;
    return ReasoningSupportService.instance.isSupportedSync(modelId);
  }

  Future<List<LMStudioModel>> getAvailableModels({
    required String baseUrl,
    String? apiToken,
  }) async {
    try {
      final headers = _buildHeaders(requestUrl: baseUrl, apiToken: apiToken);
      final response = await _serverGet(
        Uri.parse('$baseUrl$_modelsEndpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map) {
          final map = Map<String, dynamic>.from(jsonData);
          if (map['models'] is List || map['data'] is List) {
            return _modelsFromPayload(
              map,
              baseUrl: baseUrl,
              headers: headers,
            );
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      }

      // llama-server / OpenAI-compat has `/v1/models`, not `/api/v1/models`.
      if (response.statusCode == 404 ||
          response.statusCode == 405 ||
          response.statusCode == 200) {
        final openAi = await _serverGet(
          Uri.parse('$baseUrl/v1/models'),
          headers: headers,
        );
        if (openAi.statusCode == 200) {
          final jsonData = json.decode(openAi.body);
          if (jsonData is Map) {
            return _modelsFromPayload(
              Map<String, dynamic>.from(jsonData),
              baseUrl: baseUrl,
              headers: headers,
            );
          }
        } else if (openAi.statusCode == 401 || openAi.statusCode == 403) {
          throw Exception(_parseErrorResponse(openAi));
        }
      }

      debugPrint(
          'LMStudioService: Error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to load models: ${response.statusCode}');
    } catch (e) {
      debugPrint('LMStudioService: Exception in getAvailableModels: $e');
      rethrow;
    }
  }

  Future<List<LMStudioModel>> _modelsFromPayload(
    Map<String, dynamic> map, {
    required String baseUrl,
    required Map<String, String> headers,
  }) async {
    final parsed = LMStudioModel.parseListResponse(map);
    // Real LM Studio already includes capabilities.vision. Probing `/props`
    // there logs a server error (unknown route, HTTP 200). llama-server and
    // Home's V1 shim still need `/props` for `modalities.vision`.
    if (LMStudioModel.isNativeLmStudioModelsPayload(map)) {
      return parsed;
    }
    return _enrichLlamaCppModalities(
      baseUrl: baseUrl,
      headers: headers,
      models: parsed,
    );
  }

  /// llama.cpp `GET /props` reports whether a multimodal projector is loaded.
  /// Skip anything that isn't llama.cpp (LM Studio answers unknown routes
  /// with 200 and an error body).
  Future<List<LMStudioModel>> _enrichLlamaCppModalities({
    required String baseUrl,
    required Map<String, String> headers,
    required List<LMStudioModel> models,
  }) async {
    if (models.isEmpty) return models;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/props'), headers: headers)
          .timeout(const Duration(seconds: 2));
      if (response.statusCode != 200) return models;
      final decoded = json.decode(response.body);
      if (decoded is! Map) return models;
      final props = Map<String, dynamic>.from(decoded);
      if (props['modalities'] is! Map) return models;
      final vision = LMStudioModel.visionFromProps(props);
      return [for (final m in models) m.withVision(vision)];
    } catch (_) {
      return models;
    }
  }

  /// Stream chat completion with optional tool use support.
  /// When enableToolUse is true in settings, uses OpenAI-compatible endpoint
  /// which supports function calling and tools.
  ///
  /// Can accept either:
  /// - `messages`: List of ChatMessage objects (will be formatted automatically)
  /// - `formattedMessages`: Pre-formatted message list (takes priority if provided)
  Stream<Map<String, dynamic>> streamChatCompletion({
    required String baseUrl,
    List<ChatMessage>? messages,
    List<Map<String, dynamic>>? formattedMessages,
    required AppSettings settings,
    List<Map<String, dynamic>>? tools,
    String? apiToken,
    CloudApiType? cloudProviderType,
    Map<String, String>? extraHeaders,
    String? memoryContext,
  }) async* {
    final apiType = effectiveChatApiType(cloudProviderType, baseUrl);
    final requestBaseUrl =
        isHostedOpenAiBaseUrl(baseUrl) ? 'https://api.openai.com' : baseUrl;
    // Determine endpoint path
    final String endpoint;
    if (apiType != null) {
      // Cloud provider — use its specific chat path
      endpoint = apiType.chatPath;
    } else {
      // Fallback to OpenAI-compatible endpoint as requested
      endpoint = _openAIChatEndpoint;
    }

    // Use formattedMessages if provided, otherwise format from ChatMessage list
    var apiMessages = formattedMessages ??
        (messages?.map((msg) {
              // For messages with images, use LM Studio vision format
              if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
                return {
                  'role': msg.role,
                  'content': [
                    {'type': 'input_text', 'text': msg.content},
                    ...msg.imageUrls!.map((url) => {
                          'type': 'input_image',
                          'image_url': url,
                        }),
                  ],
                };
              }
              // Regular text message
              return <String, dynamic>{
                'role': msg.role,
                'content': msg.content,
              };
            }).toList() ??
            <Map<String, dynamic>>[]);

    // Merge memory into the single leading system message. Inserting a
    // second `role: system` mid-array breaks Qwen chat templates
    // ("System message must be at the beginning").
    apiMessages = ChatMessageNormalizer.injectMemoryContext(
      apiMessages,
      memoryContext,
    );

    try {
      final isCloud = apiType != null;
      if (isCloud && !apiType.supportsTools) {
        tools = null;
      }
      final modelId = settings.selectedModel?.trim() ?? '';
      if (modelId.isEmpty) {
        yield {'error': 'No model selected.'};
        return;
      }
      if (apiMessages.isEmpty) {
        yield {'error': 'No messages to send.'};
        return;
      }
      // GPT-5 / o-series reject deprecated max_tokens and often reject
      // non-default sampling params (temperature, top_p, penalties).
      final omitSampling = openAiOmitsSamplingParams(modelId);
      final reasoningEffort = openAiReasoningEffortApiValue(
        reasoning: settings.reasoning,
        modelId: modelId,
        providerType: apiType,
      );
      final verbosity = openAiVerbosityApiValue(
        verbosity: settings.verbosity,
        modelId: modelId,
        providerType: apiType,
      );
      final zAiThinking = zAiThinkingFields(
        reasoningEnabled: settings.isReasoningEnabled,
        providerType: apiType,
      );
      final llamaThinking = llamaCppThinkingFields(
        reasoning: settings.reasoning,
        modelId: modelId,
        providerType: apiType,
      );
      final requestBody = <String, dynamic>{
        'model': modelId,
        'messages': apiMessages,
        if (!omitSampling) 'temperature': settings.temperature,
        ...openAiMaxTokensFields(
          maxTokens: settings.maxTokens,
          modelId: modelId,
          providerType: apiType,
        ),
        if (!omitSampling) 'top_p': settings.topP,
        'stream': true,
        // LM Studio only: repeat_penalty and TTL
        if (!isCloud) 'repeat_penalty': settings.repeatPenalty,
        if (!isCloud && settings.autoUnloadTtlMinutes != null)
          'ttl': settings.autoUnloadTtlMinutes! * 60,
        // Cloud provider: send frequency/presence penalty when supported
        if (!omitSampling && isCloud && apiType.supportsFrequencyPenalty)
          'frequency_penalty': settings.frequencyPenalty,
        if (!omitSampling && isCloud && apiType.supportsPresencePenalty)
          'presence_penalty': settings.presencePenalty,
        // OpenRouter supports repeat_penalty as repetition_penalty
        if (isCloud && apiType.supportsRepeatPenalty)
          'repetition_penalty': settings.repeatPenalty,
        if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
        if (verbosity != null) 'verbosity': verbosity,
        if (zAiThinking != null) ...zAiThinking,
        ...llamaThinking,
        // Add tools array if provided
        if (tools != null && tools.isNotEmpty) 'tools': tools,
        // Enable tool use (auto lets the model decide when to call tools)
        if (tools != null && tools.isNotEmpty) 'tool_choice': 'auto',
        if (openAiResponseFormat(
          useStructuredOutput: settings.useStructuredOutput,
          providerType: apiType,
        )
            case final format?)
          'response_format': format,
      };

      debugPrint('LMStudioService: Chat request body:');
      debugPrint(jsonEncodeForLog(requestBody));

      final request = http.Request(
        'POST',
        Uri.parse('$requestBaseUrl$endpoint'),
      );

      request.headers.addAll(_buildHeaders(
        requestUrl: requestBaseUrl,
        apiToken: apiToken,
        isStream: true,
        cloudProviderType: apiType,
      ));
      // Add provider-specific extra headers (e.g., OpenRouter's HTTP-Referer)
      if (extraHeaders != null) {
        request.headers.addAll(extraHeaders);
      }

      request.body = jsonEncode(requestBody);

      // Use a dedicated client so stopGeneration() can abort this stream
      // by closing the socket. Removed in the finally below.
      final client = await _beginStreamClient();
      try {
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          debugPrint(
              '⚠️ Chat completions HTTP ${streamedResponse.statusCode}: $body');
          final droppedField = missingRequiredFieldFromHttpBody(body);
          if (droppedField != null &&
              requestJsonHasField(requestBody, droppedField)) {
            yield {
              'error': DroppedRequestBodyError.userMessage,
            };
            return;
          }
          final missing = modelNotFoundErrorFromHttpBody(body);
          yield {
            'error': missing?['error'] ??
                _parseErrorResponse(
                    http.Response(body, streamedResponse.statusCode)),
            if (missing != null)
              'error_type': ModelNotFoundError.type
            else if (isContextOverflowError(body))
              'error_type': contextOverflowType,
          };
          return;
        }

        // Accumulate tool calls across chunks
        final Map<int, Map<String, dynamic>> toolCallBuffers = {};

        // SSE line buffer — TCP packets can split lines mid-JSON
        String lineBuffer = '';

        await for (final chunk in streamedResponse.stream
            .timeout(_streamIdleTimeout)
            .transform(utf8.decoder)) {
          // Debug: Print raw response chunks
          // debugPrint('📥 Raw chunk: $chunk');

          // Accumulate with previous partial line and split
          final combined = lineBuffer + chunk;
          final lines = combined.split('\n');
          // Last element may be incomplete — keep it in buffer
          lineBuffer = lines.removeLast();

          for (final line in lines) {
            if (line.trim().isEmpty) continue;

            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();

              if (data == '[DONE]') {
                return;
              }

              try {
                final jsonData = jsonDecode(data);

                // Check for error in response
                if (jsonData['error'] != null) {
                  final error = jsonData['error'];
                  final errorMessage = error is Map
                      ? (error['message'] ?? error.toString())
                      : error.toString();
                  debugPrint('📥 LM Studio error: $errorMessage');
                  yield {'error': errorMessage};
                  return;
                }

                final choices = jsonData['choices'] as List?;

                if (choices != null && choices.isNotEmpty) {
                  final choice = choices[0] as Map<String, dynamic>;
                  final delta = choice['delta'] as Map<String, dynamic>?;
                  final finishReason = choice['finish_reason'] as String?;

                  // Handle reasoning/thinking deltas (reasoning models, oMLX, etc.)
                  final reasoningContent = _reasoningFromDelta(delta);
                  if (reasoningContent != null) {
                    yield {'reasoning': reasoningContent};
                  }

                  // Handle regular content
                  final content = delta?['content'] as String?;
                  if (content != null) {
                    yield {'content': content};
                  }

                  // Handle tool calls (streaming format - accumulate across chunks)
                  final toolCalls = delta?['tool_calls'] as List?;
                  if (toolCalls != null && toolCalls.isNotEmpty) {
                    for (final toolCall in toolCalls) {
                      final index = toolCall['index'] as int? ?? 0;
                      final id = toolCall['id'] as String?;
                      final type = toolCall['type'] as String?;
                      final function =
                          toolCall['function'] as Map<String, dynamic>?;

                      // Initialize buffer for this tool call if needed
                      toolCallBuffers[index] ??= {
                        'id': id,
                        'type': type ?? 'function',
                        'name': '',
                        'arguments': '',
                      };

                      // Accumulate function name and arguments
                      if (function != null) {
                        final name = function['name'] as String?;
                        final arguments = function['arguments'] as String?;

                        if (name != null && name.isNotEmpty) {
                          toolCallBuffers[index]!['name'] = name;
                        }
                        if (arguments != null) {
                          toolCallBuffers[index]!['arguments'] =
                              (toolCallBuffers[index]!['arguments'] as String) +
                                  arguments;
                        }
                      }
                    }
                  }

                  // Check if model finished with tool_calls
                  if (finishReason == 'tool_calls') {
                    debugPrint('📥 Finish reason: tool_calls');

                    // Yield all accumulated tool calls
                    for (final buffer in toolCallBuffers.values) {
                      final name = buffer['name'] as String;
                      final arguments = buffer['arguments'] as String;
                      debugPrint(
                          '📥 Complete tool call: $name with args: $arguments');
                      yield {
                        'tool_call': name,
                        'arguments': arguments.isNotEmpty ? arguments : '{}',
                      };
                    }

                    yield {'finish_reason': 'tool_calls'};
                  }
                }

                // LM Studio only provides usage in streaming mode's final chunks (if at all)
                // Stats, model_info, and runtime are not available in streaming
                if (jsonData['usage'] != null) {
                  debugPrint('📥 Usage: ${jsonData['usage']}');
                  try {
                    yield {
                      'usage': TokenUsage.fromJson(jsonData['usage']),
                    };
                  } catch (e) {
                    debugPrint('📥 Failed to parse usage: $e');
                  }
                }
              } catch (e) {
                // Skip malformed JSON chunks
                debugPrint('📥 Parse error: $e');
                continue;
              }
            }
          }
        }
      } finally {
        _activeStreamClients.remove(client);
        try {
          client.close();
        } catch (_) {}
      }
    } catch (e) {
      throw Exception('Error during chat completion: $e');
    }
  }

  /// Stream chat completion using v1 API with MCP integrations support.
  /// Falls back to v0 API (streamChatCompletion) if v1 API fails.
  ///
  /// The v1 API (/api/v1/chat) supports:
  /// - MCP integrations via `integrations` array
  /// - Named SSE streaming events
  /// - More detailed progress events
  /// - `previous_response_id` for conversation continuity
  Stream<Map<String, dynamic>> streamChatCompletionV1({
    required String baseUrl,
    List<ChatMessage>? messages,
    List<Map<String, dynamic>>? formattedMessages,
    required AppSettings settings,
    List<Map<String, dynamic>>? tools,
    String? apiToken,
    String? previousResponseId,
    bool skipContextInjection = false,
    String? memoryContext,
    List<Map<String, dynamic>>? extraIntegrations,

    /// When true, omit `context_length` so LM Studio won't JIT-load a second
    /// instance of an already-loaded model.
    bool omitLoadParams = false,
  }) async* {
    // Build the input content from messages
    final List<Map<String, dynamic>> apiMessages = formattedMessages ??
        (messages?.map((msg) {
              if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
                return {
                  'role': msg.role,
                  'content': [
                    {'type': 'text', 'text': msg.content},
                    ...msg.imageUrls!.map((url) => {
                          'type': 'image',
                          'data_url': url,
                        }),
                  ],
                };
              }
              return <String, dynamic>{
                'role': msg.role,
                'content': msg.content,
              };
            }).toList() ??
            []);

    // Extract the latest user message as input (v1 API format)
    // The v1 API uses `input` instead of `messages` array
    // input can be a string or an array of objects (for images)
    dynamic userInput = '';
    final systemPrompts = <String>[];
    final conversationHistory =
        <Map<String, dynamic>>[]; // Collect non-system, non-latest messages

    for (final msg in apiMessages) {
      if (msg['role'] == 'system') {
        systemPrompts.add(msg['content'].toString());
      } else {
        conversationHistory.add(msg);
      }
    }

    // The last message should be the current user message
    if (conversationHistory.isNotEmpty) {
      final lastMsg = conversationHistory.last;
      if (lastMsg['role'] == 'user') {
        final content = lastMsg['content'];
        if (content is List) {
          // Convert from messages format to v1 input format (vision)
          userInput = content.map((item) {
            if (item is Map) {
              final type = item['type'] as String?;
              if (type == 'text' || type == 'input_text' || type == 'message') {
                return {
                  'type': 'text',
                  'content': item['text'] ?? item['content']
                };
              }
              if (type == 'image') {
                if (item.containsKey('data_url')) return item;
                if (item.containsKey('image_url')) {
                  final urlObj = item['image_url'];
                  return {
                    'type': 'image',
                    'data_url': urlObj is Map ? urlObj['url'] : urlObj
                  };
                }
              }
              if (type == 'image_url') {
                final urlObj = item['image_url'];
                return {
                  'type': 'image',
                  'data_url': urlObj is Map ? urlObj['url'] : urlObj
                };
              }
              if (type == 'input_image') {
                return {'type': 'image', 'data_url': item['image_url']};
              }
            }
            return item;
          }).toList();
        } else {
          userInput = content.toString();
        }
      }
    }

    // Inject conversation history when there's no server-side session and the
    // caller hasn't already handled context injection (skipContextInjection).
    // This is used by the tool-calling path which builds a messages array but
    // relies on the service to form the v1 `input` string.
    if (!skipContextInjection &&
        previousResponseId == null &&
        conversationHistory.length > 1) {
      final priorMessages =
          conversationHistory.sublist(0, conversationHistory.length - 1);
      if (priorMessages.isNotEmpty && userInput is String) {
        final historyBuffer = StringBuffer();
        historyBuffer
            .writeln('[Previous conversation context — continue from here]');
        historyBuffer.writeln();
        for (final msg in priorMessages) {
          final role = msg['role'] == 'user' ? 'User' : 'Assistant';
          final content = msg['content'];
          final text = content is List
              ? (content.firstWhere(
                      (c) =>
                          c is Map &&
                          (c['type'] == 'text' || c['type'] == 'input_text'),
                      orElse: () => {'text': ''})['text'] ??
                  '')
              : content.toString();
          historyBuffer.writeln('$role: $text');
          historyBuffer.writeln();
        }
        historyBuffer.writeln('[End of previous context]');
        historyBuffer.writeln();
        historyBuffer.writeln('User: $userInput');
        userInput = historyBuffer.toString();
        debugPrint(
            '📜 V1 API: No previous_response_id — injected ${priorMessages.length} messages as context');
      }
    }

    if ((userInput is String && userInput.trim().isNotEmpty) ||
        userInput is List) {
      userInput = withImageGenTurnReminder(
        userInput,
        enabled: settings.imageGenEnabled,
      );
    }

    // If no explicit system prompt in messages, use settings (cold sessions only)
    if (previousResponseId == null) {
      if (systemPrompts.isEmpty && settings.systemPrompt.isNotEmpty) {
        systemPrompts.add(settings.systemPrompt);
      }
      if (settings.imageGenEnabled &&
          !systemPrompts.any((s) => s.contains('[IMAGE_GEN_INSTRUCTION]'))) {
        if (systemPrompts.isEmpty) {
          systemPrompts.add(kImageGenSystemInstruction.trim());
        } else {
          systemPrompts[0] = applyImageGenInstructionToSystem(
            systemPrompts[0],
            enabled: true,
          );
        }
      }

      // Append memory context if provided
      if (memoryContext != null && memoryContext.isNotEmpty) {
        systemPrompts.add(memoryContext);
      }
    } else {
      // Warm session: drop any system prompts extracted from the client
      // messages array so we don't re-inject them mid-history.
      systemPrompts.clear();
    }

    // Build integrations array for MCP servers
    // Supports both:
    // - Integrated MCPs: "mcp/name" strings (configured in LM Studio's mcp.json)
    //   NOTE: Integrated MCPs require auth enabled in LM Studio. When no API
    //   token is set, activeIntegratedMcps returns empty automatically.
    // - Ephemeral MCPs: objects with type: 'ephemeral_mcp' (HTTP URLs)
    //   These work without auth (only need "Allow per-request MCPs" in LM Studio).
    //
    // Deduplication: When an integrated MCP and an ephemeral MCP share the same
    // name/label, the integrated MCP takes priority (it runs locally in LM Studio
    // and is more reliable). The ephemeral duplicate is skipped.
    List<dynamic>? integrations;
    final activeMcpServers = settings.enableToolUse
        ? settings.activeMcpServers
        : <McpServerConfig>[];
    final activeIntegratedMcps = settings.enableToolUse
        ? settings.activeIntegratedMcps
        : <IntegratedMcpConfig>[];

    if (settings.enableToolUse &&
        !settings.hasApiToken &&
        (settings.integratedMcps?.any((m) => m.enabled) ?? false)) {
      debugPrint(
          '⚠️ V1 API: Skipping integrated MCPs — no API token set (auth required in LM Studio)');
    }

    // Collect integrated MCP names for dedup against ephemeral MCPs
    final integratedNames = activeIntegratedMcps.map((m) => m.name).toSet();

    if (activeMcpServers.isNotEmpty || activeIntegratedMcps.isNotEmpty) {
      integrations = [];

      // Add integrated MCPs first (they take priority)
      // Skip web_search/read_url when Pro Search is active (extraIntegrations)
      final hasProSearch =
          extraIntegrations != null && extraIntegrations.isNotEmpty;
      const proSearchOverlap = {'web_search', 'read_url'};
      for (final mcp in activeIntegratedMcps) {
        if (hasProSearch && proSearchOverlap.contains(mcp.name)) {
          debugPrint(
              '🔌 V1 API: Skipping integrated MCP "${mcp.name}" — Pro Search active');
          continue;
        }
        integrations.add(mcp.toApiFormat());
        debugPrint('🔌 V1 API: Adding integrated MCP: ${mcp.toApiFormat()}');
      }

      // Add ephemeral MCPs, skipping duplicates that match an integrated MCP name
      for (final server in activeMcpServers) {
        if (integratedNames.contains(server.label)) {
          debugPrint(
              '🔌 V1 API: Skipping ephemeral MCP "${server.label}" — integrated MCP takes priority');
          continue;
        }
        integrations.add(server.toApiFormat());
        debugPrint('🔌 V1 API: Adding ephemeral MCP: ${server.label}');
      }

      debugPrint(
          '🔌 V1 API: Total ${integrations.length} MCP integrations (${activeIntegratedMcps.length} integrated, ${integrations.length - activeIntegratedMcps.length} ephemeral)');
    }

    // Merge extra integrations (e.g., Pro Search MCP server)
    if (settings.enableToolUse &&
        extraIntegrations != null &&
        extraIntegrations.isNotEmpty) {
      integrations ??= [];
      for (final extra in extraIntegrations) {
        integrations.add(extra);
        debugPrint(
            '🔌 V1 API: Adding extra integration: ${extra['server_label'] ?? extra['id'] ?? 'unknown'}');
      }
    }

    final modelId = settings.selectedModel?.trim() ?? '';
    if (modelId.isEmpty) {
      yield {'error': 'No model selected.'};
      return;
    }

    try {
      final requestBody = {
        'model': modelId,
        'input': userInput,
        'stream': true,
        if (previousResponseId != null)
          'previous_response_id': previousResponseId,
        // Generation parameters
        'temperature': settings.temperature,
        'max_output_tokens': settings.maxTokens,
        'top_p': settings.topP,
        'top_k': settings.topK,
        'min_p': settings.minP,
        'repeat_penalty': settings.repeatPenalty,
        // JIT load config — needed when the model isn't already in memory.
        // Omit when reusing a loaded instance (avoids parallel :2 / :3 loads).
        if (!omitLoadParams)
          'context_length':
              settings.loadContextLength ?? settings.contextWindow,
        // System prompt — only on cold sessions. Re-sending system_prompt
        // with previous_response_id can make LM Studio append a system
        // message mid-history, which Qwen templates reject.
        if (systemPrompts.isNotEmpty && previousResponseId == null)
          'system_prompt': systemPrompts.join('\n\n'),
        // Reasoning support (LM Studio /api/v1/chat only).
        // Force off for Qwen 3.5/3.6 when tools/MCP/Pro Search are attached.
        if (reasoningApiValue(
          settings,
          settings.selectedModel ?? '',
          forceOffForTools: integrations != null && integrations.isNotEmpty,
        )
            case final reasoning?)
          'reasoning': reasoning,
        // MCP integrations
        if (integrations != null && integrations.isNotEmpty)
          'integrations': integrations,
        // Do not send `ttl` here — current LM Studio `/api/v1/chat` 400s it
        // and the v0 fallback then failed on `json_object`. Idle unload TTL
        // stays on OpenAI Completions (`/v1/chat/completions`) only.
        // Note: v1 API handles tools via 'integrations' (MCP servers),
        // NOT via OpenAI-compatible 'tools'/'tool_choice' keys.
        // Those are only used in the v0 fallback (/v1/chat/completions).
      };

      debugPrint(
          'LMStudioService: V1 Chat reasoning=${reasoningApiValue(settings, settings.selectedModel ?? '', forceOffForTools: integrations != null && integrations.isNotEmpty)}');
      debugPrint(
          '📡 V1: previous_response_id=${previousResponseId ?? "NULL (new session)"}');
      debugPrint(jsonEncodeForLog(requestBody));

      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl$_statefulChatEndpoint'),
      );

      request.headers.addAll(_buildHeaders(
        requestUrl: baseUrl,
        apiToken: apiToken,
        isStream: true,
      ));
      request.body = jsonEncode(requestBody);

      // Dedicated client tracked for cancellation via stopGeneration().
      final client = await _beginStreamClient();
      try {
        final streamedResponse = await client.send(request);

        // If 404, v1 API might not be available - fallback to v0
        if (streamedResponse.statusCode == 404) {
          final body = await streamedResponse.stream.bytesToString();
          final missing = modelNotFoundErrorFromHttpBody(body);
          if (missing != null) {
            debugPrint('⚠️ V1: selected model is not on the server');
            yield missing;
            return;
          }
          debugPrint('⚠️ V1 API not available (404), falling back to v0 API');
          yield* streamChatCompletion(
            baseUrl: baseUrl,
            formattedMessages: formattedMessages,
            messages: messages,
            settings: settings,
            tools: tools,
            apiToken: apiToken,
            memoryContext: memoryContext,
          );
          return;
        }

        if (streamedResponse.statusCode == 401 ||
            streamedResponse.statusCode == 403) {
          final body = await streamedResponse.stream.bytesToString();
          debugPrint(
              '⚠️ V1 API auth error ${streamedResponse.statusCode}: $body');
          yield {
            'error': _parseErrorResponse(
                http.Response(body, streamedResponse.statusCode))
          };
          return;
        }

        if (streamedResponse.statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          _debugPrintExactLmStudioError(
              'V1 HTTP ${streamedResponse.statusCode}', body);
          final stale = stalePreviousResponseErrorFromHttpBody(body);
          if (stale != null) {
            debugPrint(
                '⚠️ V1: previous_response_id is gone — caller should reinject history');
            yield stale;
            return;
          }
          if (ReasoningSupportService.isReasoningConfigHttpBody(body)) {
            yield {
              'error': ReasoningSupportService.messageFromHttpBody(body) ??
                  'Model does not expose reasoning configuration.',
              'reasoning_config_error': true,
            };
            return;
          }
          if (isContextOverflowError(body)) {
            yield {
              'error': _parseErrorResponse(
                  http.Response(body, streamedResponse.statusCode)),
              'error_type': contextOverflowType,
            };
            return;
          }
          final missing = modelNotFoundErrorFromHttpBody(body);
          if (missing != null) {
            debugPrint('⚠️ V1: selected model is not on the server');
            yield missing;
            return;
          }
          final droppedField = missingRequiredFieldFromHttpBody(body);
          if (droppedField != null &&
              requestJsonHasField(requestBody, droppedField)) {
            debugPrint(
                '⚠️ V1: server says missing "$droppedField" but Mini sent it '
                '(auth=${_hasApiToken(apiToken) ? 'set' : 'none'}). '
                'Not falling back to v0.');
            yield {
              'error': DroppedRequestBodyError.userMessage,
            };
            return;
          }
          debugPrint(
              '⚠️ V1 API error (${streamedResponse.statusCode}), falling back to v0 API');
          yield* streamChatCompletion(
            baseUrl: baseUrl,
            formattedMessages: formattedMessages,
            messages: messages,
            settings: settings,
            tools: tools,
            apiToken: apiToken,
            memoryContext: memoryContext,
          );
          return;
        }

        // Parse v1 API streaming response (named SSE events)
        debugPrint('📡 V1 HTTP ${streamedResponse.statusCode} (SSE)');
        String? currentEventType;
        String? lastSseEvent;
        String? responseId;
        var sawChatStart = false;
        var sawOutput = false;
        var sawServerError = false;

        // SSE line buffer — TCP packets can split lines mid-JSON
        String lineBuffer = '';

        await for (final chunk in streamedResponse.stream
            .timeout(_streamIdleTimeout)
            .transform(utf8.decoder)) {
          // Accumulate with previous partial line and split
          final combined = lineBuffer + chunk;
          final lines = combined.split('\n');
          // Last element may be incomplete — keep it in buffer
          lineBuffer = lines.removeLast();

          for (final line in lines) {
            if (line.trim().isEmpty) {
              // SSE dispatches on a blank line; don't leak the previous type
              // onto a later data-only error payload.
              currentEventType = null;
              continue;
            }

            // Named SSE format: "event: <type>" and "data: <json>"
            if (line.startsWith('event:')) {
              currentEventType =
                  line.substring(line.startsWith('event: ') ? 7 : 6).trim();
              lastSseEvent = currentEventType;
              continue;
            }

            final data = line.startsWith('data: ')
                ? line.substring(6).trim()
                : line.startsWith('data:')
                    ? line.substring(5).trim()
                    : null;
            if (data != null) {
              // Raw debug: log SSE events (skip noisy delta events)
              final evt = currentEventType ?? '?';
              lastSseEvent = evt;
              final looksLikeError = evt.contains('error') ||
                  data.toLowerCase().contains('error') ||
                  isContextOverflowError(data);
              if (looksLikeError) {
                _debugPrintExactLmStudioError('V1 SSE [$evt]', data);
              } else if (evt != 'reasoning.delta' &&
                  evt != 'message.delta' &&
                  evt != 'content.delta') {
                final truncData = data.length > 2000
                    ? '${data.substring(0, 2000)}...[${data.length} chars]'
                    : data;
                debugPrint('📥 V1 SSE [$evt]: $truncData');
              }

              if (data == '[DONE]') {
                if (responseId != null) {
                  yield {'response_id': responseId};
                }
                return;
              }

              try {
                final jsonData = jsonDecode(data);
                final payloadType =
                    jsonData is Map ? jsonData['type'] as String? : null;
                final eventType = (payloadType != null &&
                        (payloadType == 'error' ||
                            payloadType.contains('error') ||
                            isContextOverflowError(jsonData)))
                    ? payloadType
                    : (currentEventType ?? payloadType);

                final errorChunk = errorChunkFromV1Json(
                  jsonData,
                  eventType: eventType,
                );
                if (errorChunk != null) {
                  sawServerError = true;
                  yield errorChunk;
                  if (_v1ErrorAbortsStream(errorChunk)) return;
                  continue;
                }

                // Process based on event type

                switch (eventType) {
                  case 'chat.start':
                    sawChatStart = true;
                    responseId = jsonData['response_id'] as String?;
                    yield {'type': 'chat.start', 'response_id': responseId};
                    break;

                  case 'model_load.start':
                    yield {
                      'type': 'model_load.start',
                      'status': 'Loading model...'
                    };
                    break;

                  case 'model_load.progress':
                    yield {
                      'type': 'model_load.progress',
                      'progress': jsonData['progress'],
                      'status': 'Loading model...',
                    };
                    break;

                  case 'model_load.end':
                    yield {'type': 'model_load.end', 'status': 'Model loaded'};
                    break;

                  case 'prompt_processing.start':
                    yield {
                      'type': 'prompt_processing.start',
                      'status': 'Processing...'
                    };
                    break;

                  case 'prompt_processing.progress':
                    yield {
                      'type': 'prompt_processing.progress',
                      'progress': jsonData['progress'],
                      'status': 'Processing prompt...',
                    };
                    break;

                  case 'prompt_processing.end':
                    yield {'type': 'prompt_processing.end'};
                    break;

                  case 'reasoning.start':
                    yield {'type': 'reasoning.start'};
                    break;

                  case 'reasoning.delta':
                    // Reasoning content (thinking)
                    final content = jsonData['delta'] ?? jsonData['content'];
                    if (content != null) {
                      sawOutput = true;
                      yield {'reasoning': content};
                    }
                    break;

                  case 'reasoning.end':
                    yield {'type': 'reasoning.end'};
                    break;

                  case 'message.start':
                    yield {'type': 'message.start'};
                    break;

                  case 'message.delta':
                  case 'content.delta':
                    // Main message content
                    final content = jsonData['delta'] ?? jsonData['content'];
                    if (content != null) {
                      sawOutput = true;
                      yield {'content': content};
                    }
                    break;

                  // MCP tool call events per LM Studio streaming-events spec:
                  // https://lmstudio.ai/docs/developer/rest/streaming-events
                  case 'tool_call.start':
                    // LM Studio may send tool_call.start as a bare event (no tool field),
                    // then follow with tool_call.name for the actual tool name.
                    sawOutput = true;
                    yield {
                      'type': 'tool_call.start',
                      'tool': jsonData['tool'] ?? jsonData['tool_name'],
                      'provider_info': jsonData['provider_info'],
                    };
                    break;

                  case 'tool_call.name':
                    // Separate event with the tool name + provider info
                    sawOutput = true;
                    yield {
                      'type': 'tool_call.name',
                      'tool': jsonData['tool_name'] ?? jsonData['tool'],
                      'provider_info': jsonData['provider_info'],
                    };
                    break;

                  case 'tool_call.arguments':
                    sawOutput = true;
                    yield {
                      'type': 'tool_call.arguments',
                      'tool': jsonData['tool'] ?? jsonData['tool_name'],
                      'arguments': jsonData['arguments'],
                      'provider_info': jsonData['provider_info'],
                    };
                    break;

                  case 'tool_call.success':
                    sawOutput = true;
                    yield {
                      'type': 'tool_call.success',
                      'tool': jsonData['tool'],
                      'arguments': jsonData['arguments'],
                      'output': jsonData['output'],
                      'provider_info': jsonData['provider_info'],
                    };
                    break;

                  case 'tool_call.failure':
                    sawOutput = true;
                    yield {
                      'type': 'tool_call.failure',
                      'reason': jsonData['reason'],
                      'metadata': jsonData['metadata'],
                    };
                    break;

                  case 'tool_calls':
                    // Tool calls in OpenAI v0 format (fallback)
                    sawOutput = true;
                    yield {'tool_calls': jsonData['tool_calls']};
                    break;

                  case 'chat.end':
                    // chat.end wraps the full result: {"type":"chat.end","result":{...response..., "output":[...], "response_id":"resp_...", "stats":{...}}}
                    // debugPrint('📡 V1 raw chat.end keys: ${jsonData.keys.toList()}');
                    final result = jsonData['result'] as Map<String, dynamic>?;
                    debugPrint(
                        '📡 V1 chat.end result keys: ${result?.keys.toList() ?? "NO RESULT"}');
                    debugPrint(
                        '📡 V1 chat.end result.response_id: ${result?['response_id']}');
                    debugPrint(
                        '📡 V1 chat.end jsonData.response_id: ${jsonData['response_id']}');
                    responseId = result?['response_id'] as String? ??
                        jsonData['response_id'] as String? ??
                        responseId;
                    final stats = result?['stats'] as Map<String, dynamic>? ??
                        jsonData['stats'] as Map<String, dynamic>? ??
                        jsonData['usage'] as Map<String, dynamic>?;
                    debugPrint(
                        '📡 V1 chat.end stats: ${stats != null ? stats.keys.toList() : "NULL"}');
                    // Extract full output items from result (fallback when streaming deltas were incomplete)
                    final outputItems = result?['output'] as List<dynamic>?;
                    sawOutput = true;
                    yield {
                      'type': 'chat.end',
                      'response_id': responseId,
                      'usage': stats,
                      if (outputItems != null) 'output': outputItems,
                    };
                    break;

                  case 'message.end':
                    yield {'type': 'message.end'};
                    break;

                  case 'error':
                    // Pre-switch `errorChunkFromV1Json` should already have
                    // consumed this. Keep a fallback that prints the exact body.
                    _debugPrintExactLmStudioError(
                        'V1 SSE error event fallback', jsonData);
                    final fallback = errorChunkFromV1Json(
                      jsonData,
                      eventType: 'error',
                    );
                    if (fallback != null) {
                      yield fallback;
                      if (_v1ErrorAbortsStream(fallback)) return;
                    }
                    break;

                  default:
                    // For unknown events, try to extract content
                    if (jsonData['delta'] != null) {
                      sawOutput = true;
                      yield {'content': jsonData['delta']};
                    } else if (jsonData['content'] != null) {
                      sawOutput = true;
                      yield {'content': jsonData['content']};
                    }
                    // Also handle OpenAI-style choices array (v0 fallback format)
                    final choices = jsonData['choices'] as List?;
                    if (choices != null && choices.isNotEmpty) {
                      final delta =
                          choices[0]['delta'] as Map<String, dynamic>?;
                      if (delta != null) {
                        final rc = _reasoningFromDelta(delta);
                        if (rc != null) {
                          yield {'reasoning': rc};
                        }
                        if (delta['content'] != null) {
                          yield {'content': delta['content']};
                        }
                      }
                    }
                }
                currentEventType = null;
              } catch (e) {
                debugPrint('📥 V1 Parse error: $e');
                debugPrint('📥 V1 SSE raw data: $data');
                if (isContextOverflowError(data)) {
                  _debugPrintExactLmStudioError('V1 SSE non-JSON', data);
                  yield {
                    'error': data,
                    'error_type': contextOverflowType,
                  };
                  return;
                }
                continue;
              }
            }
          }
        }

        if (lineBuffer.trim().isNotEmpty) {
          debugPrint('📥 V1 SSE leftover (no trailing newline): $lineBuffer');
          for (final raw in lineBuffer.split('\n')) {
            final line = raw.trim();
            if (line.isEmpty) continue;
            if (line.startsWith('event:')) {
              currentEventType =
                  line.substring(line.startsWith('event: ') ? 7 : 6).trim();
              lastSseEvent = currentEventType;
              continue;
            }
            var leftover = line;
            if (leftover.startsWith('data:')) {
              leftover = leftover.startsWith('data: ')
                  ? leftover.substring(6).trim()
                  : leftover.substring(5).trim();
            }
            try {
              final jsonData = jsonDecode(leftover);
              final leftoverChunk = errorChunkFromV1Json(
                jsonData,
                eventType: currentEventType ??
                    (jsonData is Map ? jsonData['type'] as String? : null),
              );
              if (leftoverChunk != null) {
                sawServerError = true;
                yield leftoverChunk;
                if (_v1ErrorAbortsStream(leftoverChunk)) return;
              } else {
                _debugPrintExactLmStudioError('V1 SSE leftover JSON', jsonData);
              }
            } catch (e) {
              debugPrint('📥 V1 leftover parse error: $e');
              if (isContextOverflowError(leftover)) {
                _debugPrintExactLmStudioError('V1 leftover text', leftover);
                yield {
                  'error': leftover,
                  'error_type': contextOverflowType,
                };
                return;
              }
            }
          }
        }
        debugPrint(
            '📡 V1 SSE stream closed (lastEvent=${lastSseEvent ?? 'none'}, leftoverChars=${lineBuffer.length}, sawChatStart=$sawChatStart, sawOutput=$sawOutput, sawServerError=$sawServerError)');
        if (sawChatStart && !sawOutput && !sawServerError) {
          final closed = streamClosedAfterChatStartChunk(
            contextTokens: settings.loadContextLength ?? settings.contextWindow,
          );
          _debugPrintExactLmStudioError(
              'V1 SSE closed after chat.start', closed);
          yield closed;
        }
      } finally {
        _activeStreamClients.remove(client);
        try {
          client.close();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ V1 API exception: $e, falling back to v0 API');
      // Fallback to v0 API on any error
      yield* streamChatCompletion(
        baseUrl: baseUrl,
        formattedMessages: formattedMessages,
        messages: messages,
        settings: settings,
        tools: tools,
        apiToken: apiToken,
        memoryContext: memoryContext,
      );
    }
  }

  Future<Map<String, dynamic>> getChatCompletion({
    required String baseUrl,
    required List<ChatMessage> messages,
    required AppSettings settings,
    String? apiToken,
  }) async {
    try {
      final modelId = settings.selectedModel ?? '';
      final omitSampling = openAiOmitsSamplingParams(modelId);
      final reasoningEffort = openAiReasoningEffortApiValue(
        reasoning: settings.reasoning,
        modelId: modelId,
      );
      final llamaThinking = llamaCppThinkingFields(
        reasoning: settings.reasoning,
        modelId: modelId,
      );
      final requestBody = {
        'model': modelId,
        'messages': messages.map((msg) {
          // For messages with images, use LM Studio vision format
          if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
            return {
              'role': msg.role,
              'content': [
                {'type': 'input_text', 'text': msg.content},
                ...msg.imageUrls!.map((url) => {
                      'type': 'input_image',
                      'image_url': url,
                    }),
              ],
            };
          }
          // Regular text message
          return {
            'role': msg.role,
            'content': msg.content,
          };
        }).toList(),
        if (!omitSampling) 'temperature': settings.temperature,
        ...openAiMaxTokensFields(
            maxTokens: settings.maxTokens, modelId: modelId),
        if (!omitSampling) 'top_p': settings.topP,
        if (!omitSampling) 'repeat_penalty': settings.repeatPenalty,
        'stream': false,
        if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
        ...llamaThinking,
        if (openAiResponseFormat(
          useStructuredOutput: settings.useStructuredOutput,
        )
            case final format?)
          'response_format': format,
      };

      debugPrint(
          'LMStudioService: Non-streaming request (likely memory extraction):');
      debugPrint(jsonEncodeForLog(requestBody));

      final response = await _serverPost(
        Uri.parse('$baseUrl$_openAIChatEndpoint'),
        headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final choices = jsonResponse['choices'] as List?;

        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;

          // LM Studio only provides usage (token counts)
          // Stats object exists but is always empty {}
          // model_info and runtime are not provided
          TokenUsage? usage;
          if (jsonResponse['usage'] != null) {
            try {
              usage = TokenUsage.fromJson(jsonResponse['usage']);
            } catch (e) {
              debugPrint('📥 Failed to parse usage: $e');
            }
          }

          String? reasoning;
          for (final key in ['reasoning_content', 'reasoning', 'thinking']) {
            final v = message?[key];
            if (v is String && v.trim().isNotEmpty) {
              reasoning = v;
              break;
            }
          }

          return {
            'content': message?['content']?.toString() ?? '',
            if (reasoning != null) 'reasoning': reasoning,
            'usage': usage,
            'finish_reason': choices[0]['finish_reason'],
          };
        } else {
          throw Exception('No response from model');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      } else {
        throw Exception(
            'Failed to get chat completion: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during chat completion: $e');
    }
  }

  /// Stateful chat - send a new message in a conversation thread
  /// Uses /api/v1/chat endpoint which manages conversation context server-side
  ///
  /// [input] - The user's message (text or array for vision)
  /// [previousResponseId] - Optional response_id from previous message to continue conversation
  /// [store] - Whether to store conversation (default true). Set false for one-off requests
  Future<Map<String, dynamic>> sendStatefulChat({
    required String baseUrl,
    required String modelId,
    required dynamic input, // String for text, List for vision messages
    String? previousResponseId,
    AppSettings? settings,
    List<String>? imageUrls,
    bool store = true,
    String? apiToken,
    bool omitLoadParams = false,
  }) async {
    try {
      // Build input - handle both text and vision
      dynamic chatInput = input;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        chatInput = [
          {'type': 'text', 'content': input.toString()},
          ...imageUrls.map((url) => {
                'type': 'image',
                'data_url': url,
              }),
        ];
      }

      final requestBody = {
        'model': modelId,
        'input': chatInput,
        if (previousResponseId != null)
          'previous_response_id': previousResponseId,
        'store': store,
        // Generation parameters (v1 API naming)
        if (settings != null) ...{
          'temperature': settings.temperature,
          'top_p': settings.topP,
          'top_k': settings.topK,
          'min_p': settings.minP,
          'repeat_penalty': settings.repeatPenalty,
          'max_output_tokens': settings.maxTokens,
          if (!omitLoadParams)
            'context_length':
                settings.loadContextLength ?? settings.contextWindow,
          if (reasoningApiValue(settings, modelId) case final reasoning?)
            'reasoning': reasoning,
          if (settings.systemPrompt.isNotEmpty)
            'system_prompt': settings.systemPrompt,
        },
      };

      debugPrint('LMStudioService: Stateful chat request:');
      debugPrint(jsonEncodeForLog(requestBody));

      final response = await _serverPost(
        Uri.parse('$baseUrl$_statefulChatEndpoint'),
        headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        debugPrint('LMStudioService: Stateful chat response:');
        debugPrint(jsonEncodeForLog(jsonResponse));

        // Extract output - it's an array of message objects
        final output = jsonResponse['output'] as List?;
        String content = '';

        if (output != null && output.isNotEmpty) {
          for (var item in output) {
            if (item is Map &&
                item['type'] == 'message' &&
                item['content'] != null) {
              content += item['content'].toString();
            }
          }
        }

        return {
          'content': content,
          'response_id': jsonResponse['response_id'] as String?,
          'model_instance_id': jsonResponse['model_instance_id'] as String?,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      } else {
        debugPrint(
            'LMStudioService: Stateful chat error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to send stateful chat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LMStudioService: Exception in sendStatefulChat: $e');
      rethrow;
    }
  }

  /// Stream stateful chat with detailed progress events
  /// Yields events: model_load.progress, prompt_processing.progress, reasoning.delta, message.delta, etc.
  Stream<Map<String, dynamic>> streamStatefulChat({
    required String baseUrl,
    required String modelId,
    required dynamic input,
    String? previousResponseId,
    AppSettings? settings,
    List<String>? imageUrls,
    bool store = true,
    String? apiToken,
    String? memoryContext,
    bool omitLoadParams = false,
  }) async* {
    try {
      // Build input - handle both text and vision
      dynamic chatInput = input;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        chatInput = [
          {'type': 'text', 'content': input.toString()},
          ...imageUrls.map((url) => {
                'type': 'image',
                'data_url': url,
              }),
        ];
      }
      chatInput = withImageGenTurnReminder(
        chatInput,
        enabled: settings?.imageGenEnabled == true,
      );

      // Build integrations array for MCP servers
      // Per LM Studio docs (https://lmstudio.ai/docs/developer/rest/chat):
      // - Plugin (mcp.json): string shorthand "mcp/<label>" or {"type":"plugin","id":"mcp/<label>"}
      // - Ephemeral MCP: {"type":"ephemeral_mcp","server_label":"...","server_url":"..."}
      // Respect enableToolUse — Arena and other isolated callers disable tools.
      List<dynamic>? integrations;
      if (settings != null && settings.enableToolUse) {
        final activeMcpServers = settings.activeMcpServers;
        final activeIntegratedMcps = settings.activeIntegratedMcps;

        if (!settings.hasApiToken &&
            (settings.integratedMcps?.any((m) => m.enabled) ?? false)) {
          debugPrint(
              '⚠️ Stateful chat: Skipping integrated MCPs — no API token set');
        }

        if (activeMcpServers.isNotEmpty || activeIntegratedMcps.isNotEmpty) {
          integrations = [];
          for (final mcp in activeIntegratedMcps) {
            integrations.add(mcp.toApiFormat());
            debugPrint(
                '🔌 Stateful chat: Adding integrated MCP: ${mcp.toApiFormat()}');
          }
          for (final server in activeMcpServers) {
            integrations.add(server.toApiFormat());
            debugPrint(
                '🔌 Stateful chat: Adding ephemeral MCP: ${server.label}');
          }
          debugPrint(
              '🔌 Stateful chat: Total ${integrations.length} MCP integrations');
        }
      }

      final hasMcpIntegrations =
          integrations != null && integrations.isNotEmpty;

      // Build combined system prompt (base + memory context).
      // Only on cold sessions — re-sending system_prompt with
      // previous_response_id appends a system message mid-history,
      // which Qwen templates reject and which bloats context until
      // [IMG_PROMPT] is truncated off the output.
      String? combinedSystemPrompt;
      if (previousResponseId == null) {
        if (settings != null && settings.systemPrompt.isNotEmpty) {
          combinedSystemPrompt = settings.systemPrompt;
        }
        if (settings != null && settings.imageGenEnabled) {
          combinedSystemPrompt = applyImageGenInstructionToSystem(
            combinedSystemPrompt ?? '',
            enabled: true,
          );
        }
        if (memoryContext != null && memoryContext.isNotEmpty) {
          combinedSystemPrompt = (combinedSystemPrompt ?? '') + memoryContext;
        }
      }

      final requestBody = {
        'model': modelId,
        'input': chatInput,
        if (previousResponseId != null)
          'previous_response_id': previousResponseId,
        'store': store,
        'stream': true, // Enable streaming
        // Generation parameters (v1 API naming)
        if (settings != null) ...{
          'temperature': settings.temperature,
          'top_p': settings.topP,
          'top_k': settings.topK,
          'min_p': settings.minP,
          'repeat_penalty': settings.repeatPenalty,
          // Omit max_output_tokens for MCP — let model use full context
          if (!hasMcpIntegrations) 'max_output_tokens': settings.maxTokens,
          if (!omitLoadParams)
            'context_length':
                settings.loadContextLength ?? settings.contextWindow,
          if (reasoningApiValue(
            settings,
            modelId,
            forceOffForTools: hasMcpIntegrations,
          )
              case final reasoning?)
            'reasoning': reasoning,
        },
        if (combinedSystemPrompt != null && combinedSystemPrompt.isNotEmpty)
          'system_prompt': combinedSystemPrompt,
        // MCP integrations
        if (integrations != null && integrations.isNotEmpty)
          'integrations': integrations,
      };

      debugPrint('LMStudioService: Streaming stateful chat request:');
      debugPrint(jsonEncodeForLog(requestBody));

      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl$_statefulChatEndpoint'),
      );

      request.headers.addAll(_buildHeaders(
        requestUrl: baseUrl,
        apiToken: apiToken,
        isStream: true,
      ));

      request.body = jsonEncode(requestBody);

      final client = await _beginStreamClient();
      try {
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          debugPrint(
              '⚠️ Stateful chat error ${streamedResponse.statusCode}: $body');
          final stale = stalePreviousResponseErrorFromHttpBody(body);
          if (stale != null) {
            yield {
              'type': 'error',
              'error': {
                'message': stale['error'],
                'stale_previous_response_id': true,
              },
              'error_type': stalePreviousResponseIdType,
              'stale_previous_response_id': true,
            };
            return;
          }
          final reasoningError =
              ReasoningSupportService.isReasoningConfigHttpBody(body);
          final parsed = _parseErrorResponse(
              http.Response(body, streamedResponse.statusCode));
          final overflow =
              isContextOverflowError(body) || isContextOverflowError(parsed);
          final missing = modelNotFoundErrorFromHttpBody(body);
          yield {
            'type': 'error',
            'error': {
              'message': missing?['error'] ?? parsed,
              if (reasoningError) 'reasoning_config_error': true,
              if (missing != null)
                'type': ModelNotFoundError.type
              else if (overflow)
                'type': contextOverflowType,
            },
            if (missing != null)
              'error_type': ModelNotFoundError.type
            else if (overflow)
              'error_type': contextOverflowType,
          };
          return;
        }

        // SSE line buffer — TCP packets can split lines mid-JSON
        String lineBuffer = '';
        String? currentEventType;

        await for (final chunk in streamedResponse.stream
            .timeout(_streamIdleTimeout)
            .transform(utf8.decoder)) {
          // debugPrint('📥 [Stateful] Raw chunk: $chunk');
          // Accumulate with previous partial line and split
          final combined = lineBuffer + chunk;
          final lines = combined.split('\n');
          // Last element may be incomplete — keep it in buffer
          lineBuffer = lines.removeLast();

          for (final line in lines) {
            if (line.trim().isEmpty) continue;

            // SSE format: "event: <type>" and "data: <json>"
            if (line.startsWith('event: ')) {
              currentEventType = line.substring(7).trim();
              // debugPrint('📥 [Stateful] Event type: $currentEventType');
            } else if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              // debugPrint('📥 [Stateful] Data: $data');

              try {
                final jsonData = jsonDecode(data);
                final eventType =
                    currentEventType ?? jsonData['type'] as String?;

                if (eventType == null) continue;

                // Yield events with their data
                switch (eventType) {
                  case 'chat.start':
                    yield {
                      'type': 'chat.start',
                      'model_instance_id': jsonData['model_instance_id'],
                    };
                    break;

                  case 'model_load.start':
                    yield {
                      'type': 'model_load.start',
                      'model_instance_id': jsonData['model_instance_id'],
                    };
                    break;

                  case 'model_load.progress':
                    yield {
                      'type': 'model_load.progress',
                      'progress': jsonData['progress'],
                    };
                    break;

                  case 'model_load.end':
                    yield {
                      'type': 'model_load.end',
                      'load_time_seconds': jsonData['load_time_seconds'],
                    };
                    break;

                  case 'prompt_processing.start':
                    yield {'type': 'prompt_processing.start'};
                    break;

                  case 'prompt_processing.progress':
                    yield {
                      'type': 'prompt_processing.progress',
                      'progress': jsonData['progress'],
                    };
                    break;

                  case 'prompt_processing.end':
                    yield {'type': 'prompt_processing.end'};
                    break;

                  case 'reasoning.start':
                    yield {'type': 'reasoning.start'};
                    break;

                  case 'reasoning.delta':
                    // debugPrint('📥 [Stateful] Reasoning content: ${jsonData['content']}');
                    yield {
                      'type': 'reasoning.delta',
                      'content': jsonData['content'],
                    };
                    break;

                  case 'reasoning.end':
                    yield {'type': 'reasoning.end'};
                    break;

                  case 'tool_call.start':
                    yield {
                      'type': 'tool_call.start',
                      'tool': jsonData['tool'],
                      'provider_info': jsonData['provider_info'],
                    };
                    break;

                  case 'tool_call.arguments':
                    yield {
                      'type': 'tool_call.arguments',
                      'tool': jsonData['tool'],
                      'arguments': jsonData['arguments'],
                    };
                    break;

                  case 'tool_call.success':
                    yield {
                      'type': 'tool_call.success',
                      'tool': jsonData['tool'],
                      'arguments': jsonData['arguments'],
                      'output': jsonData['output'],
                      'provider_info': jsonData['provider_info'],
                    };
                    break;

                  case 'tool_call.failure':
                    yield {
                      'type': 'tool_call.failure',
                      'reason': jsonData['reason'],
                      'metadata': jsonData['metadata'],
                    };
                    break;

                  case 'message.start':
                    yield {'type': 'message.start'};
                    break;

                  case 'message.delta':
                    // debugPrint('📥 [Stateful] Message content: ${jsonData['content']}');
                    yield {
                      'type': 'message.delta',
                      'content': jsonData['content'],
                    };
                    break;

                  case 'message.end':
                    yield {'type': 'message.end'};
                    break;

                  case 'error':
                    final staleError = isStalePreviousResponseId(jsonData) ||
                        isStalePreviousResponseId(jsonData['error']);
                    final missingError = !staleError &&
                        (ModelNotFoundError.matches(jsonData) ||
                            ModelNotFoundError.matches(jsonData['error']));
                    yield {
                      'type': 'error',
                      'error': jsonData['error'],
                      if (staleError) ...{
                        'error_type': stalePreviousResponseIdType,
                        'stale_previous_response_id': true,
                      } else if (missingError)
                        'error_type': ModelNotFoundError.type,
                    };
                    break;

                  case 'chat.end':
                    // Final result with response_id, stats, etc.
                    final result = jsonData['result'] as Map<String, dynamic>?;
                    debugPrint(
                        '📡 Stateful chat.end result keys: ${result?.keys.toList() ?? "NO RESULT"}');
                    debugPrint(
                        '📡 Stateful chat.end response_id: ${result?['response_id']}');
                    debugPrint(
                        '📡 Stateful chat.end output: ${result?['output']}');
                    final chatEndStats =
                        result?['stats'] as Map<String, dynamic>? ??
                            jsonData['stats'] as Map<String, dynamic>? ??
                            jsonData['usage'] as Map<String, dynamic>?;
                    yield {
                      'type': 'chat.end',
                      'response_id':
                          result?['response_id'] ?? jsonData['response_id'],
                      'model_instance_id': result?['model_instance_id'] ??
                          jsonData['model_instance_id'],
                      'stats': chatEndStats,
                      'usage': chatEndStats,
                      'output': result?['output'] ?? jsonData['output'],
                    };
                    return;
                }

                currentEventType = null; // Reset for next event
              } catch (e) {
                debugPrint('Failed to parse SSE data: $e');
                continue;
              }
            }
          }
        }
      } finally {
        _activeStreamClients.remove(client);
        try {
          client.close();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('LMStudioService: Exception in streamStatefulChat: $e');
      yield {
        'type': 'error',
        'error': {'type': 'unknown', 'message': e.toString()},
      };
    }
  }

  /// DEPRECATED: Stream chat with MCP tools using /v1/responses endpoint
  /// This endpoint uses tools array with type:'mcp' format
  ///
  /// Now MCP is handled through the v1 API (/api/v1/chat) with integrations array
  /// and type:'ephemeral_mcp' format. Kept for reference.
  ///
  /// [mcpTools] - List of MCP server configurations from settings
  // ignore: unused_element
  Stream<Map<String, dynamic>> streamResponsesWithMcp({
    required String baseUrl,
    required String modelId,
    required List<ChatMessage> messages,
    required List<Map<String, dynamic>> mcpTools,
    AppSettings? settings,
  }) async* {
    try {
      // Convert chat messages to input format
      // For /v1/responses, we need to pass previous messages as context
      final List<Map<String, dynamic>> formattedMessages = messages.map((msg) {
        if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
          return {
            'role': msg.role,
            'content': [
              {'type': 'input_text', 'text': msg.content},
              ...msg.imageUrls!.map((url) => {
                    'type': 'input_image',
                    'image_url': url,
                  }),
            ],
          };
        }
        return {
          'role': msg.role,
          'content': msg.content,
        };
      }).toList();

      final requestBody = {
        'model': modelId,
        'input': formattedMessages, // Send full conversation for context
        'tools': mcpTools, // MCP tools in {"type": "mcp", ...} format
        'stream': true,
        if (settings != null) ...{
          'temperature': settings.temperature,
          'top_p': settings.topP,
          'max_output_tokens': settings.maxTokens,
        },
      };

      debugPrint('🔧 LMStudioService: Streaming with MCP via /v1/responses');
      debugPrint('🔧 MCP Tools: ${jsonEncodeForLog(mcpTools)}');
      debugPrint('🔧 Request body: ${jsonEncodeForLog(requestBody)}');

      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl$_responsesEndpoint'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });

      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        debugPrint('🔧 MCP Stream error ${streamedResponse.statusCode}: $body');
        throw Exception(
            'Failed to stream with MCP: ${streamedResponse.statusCode} - $body');
      }

      // SSE line buffer — TCP packets can split lines mid-JSON
      String lineBuffer = '';
      String? currentEventType;

      await for (final chunk in streamedResponse.stream
          .timeout(_streamIdleTimeout)
          .transform(utf8.decoder)) {
        // Accumulate with previous partial line and split
        final combined = lineBuffer + chunk;
        final lines = combined.split('\n');
        // Last element may be incomplete — keep it in buffer
        lineBuffer = lines.removeLast();

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          // SSE format: "event: <type>" and "data: <json>"
          if (line.startsWith('event: ')) {
            currentEventType = line.substring(7).trim();
            debugPrint('📥 [MCP] Event type: $currentEventType');
          } else if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();

            // Handle [DONE] signal
            if (data == '[DONE]') {
              yield {'type': 'done'};
              return;
            }

            try {
              final jsonData = jsonDecode(data);
              final eventType = currentEventType ?? jsonData['type'] as String?;

              debugPrint(
                  '📥 [MCP] Event: $eventType, Data: ${data.length > 200 ? '${data.substring(0, 200)}...' : data}');

              if (eventType == null) continue;

              switch (eventType) {
                case 'response.created':
                  yield {
                    'type': 'response.created',
                    'id': jsonData['id'],
                    'model': jsonData['model'],
                  };
                  break;

                case 'response.in_progress':
                  yield {'type': 'response.in_progress'};
                  break;

                case 'response.output_text.delta':
                  // Text content delta
                  final delta = jsonData['delta'] as String?;
                  if (delta != null && delta.isNotEmpty) {
                    yield {
                      'type': 'content',
                      'content': delta,
                    };
                  }
                  break;

                case 'response.content_part.added':
                case 'response.output_item.added':
                  // New content part or output item
                  final part = jsonData['part'] ?? jsonData['item'];
                  if (part != null) {
                    yield {
                      'type': 'output_item',
                      'item': part,
                    };
                  }
                  break;

                case 'response.function_call_arguments.delta':
                  // Tool call arguments being streamed
                  yield {
                    'type': 'tool_call.arguments.delta',
                    'delta': jsonData['delta'],
                    'item_id': jsonData['item_id'],
                  };
                  break;

                case 'response.function_call_arguments.done':
                  yield {
                    'type': 'tool_call.arguments.done',
                    'arguments': jsonData['arguments'],
                    'item_id': jsonData['item_id'],
                  };
                  break;

                case 'response.mcp_call.in_progress':
                  // MCP tool call started
                  yield {
                    'type': 'mcp_call.start',
                    'tool': jsonData['name'] ?? jsonData['tool'],
                    'server': jsonData['server_label'],
                    'arguments': jsonData['arguments'],
                  };
                  break;

                case 'response.mcp_call.completed':
                  // MCP tool call completed
                  yield {
                    'type': 'mcp_call.result',
                    'tool': jsonData['name'] ?? jsonData['tool'],
                    'output': jsonData['output'] ?? jsonData['result'],
                  };
                  break;

                case 'response.mcp_call.failed':
                  yield {
                    'type': 'mcp_call.error',
                    'tool': jsonData['name'] ?? jsonData['tool'],
                    'error': jsonData['error'],
                  };
                  break;

                case 'response.output_text.done':
                  yield {
                    'type': 'content.done',
                    'text': jsonData['text'],
                  };
                  break;

                case 'response.completed':
                case 'response.done':
                  // Response complete
                  yield {
                    'type': 'done',
                    'usage': jsonData['usage'],
                    'output': jsonData['output'],
                  };
                  return;

                case 'error':
                  yield {
                    'type': 'error',
                    'error': jsonData['error'] ??
                        jsonData['message'] ??
                        'Unknown error',
                  };
                  break;

                default:
                  // Pass through unknown events
                  debugPrint('📥 [MCP] Unknown event: $eventType');
                  yield {
                    'type': eventType,
                    'data': jsonData,
                  };
              }

              currentEventType = null;
            } catch (e) {
              debugPrint('📥 [MCP] Failed to parse: $e');
              continue;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🔧 LMStudioService: Exception in streamResponsesWithMcp: $e');
      yield {
        'type': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Test connection to LM Studio server
  /// Returns a map with 'success' boolean and optional 'error' message
  Future<Map<String, dynamic>> testConnection(String baseUrl,
      {String? apiToken}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$_modelsEndpoint'),
            headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      if (response.statusCode == 404 || response.statusCode == 405) {
        final openAi = await http
            .get(
              Uri.parse('$baseUrl/v1/models'),
              headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
            )
            .timeout(const Duration(seconds: 5));
        if (openAi.statusCode == 200) {
          return {'success': true};
        }
        if (openAi.statusCode == 401) {
          return {
            'success': false,
            'error':
                'Authentication required. Please add your API token in Settings.',
            'authError': true,
          };
        }
      }
      if (response.statusCode == 401) {
        return {
          'success': false,
          'error':
              'Authentication required. Please add your API token in Settings.',
          'authError': true,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'Access forbidden. Check your API token permissions.',
          'authError': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status ${response.statusCode}',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Connection timed out. Make sure LM Studio server is running.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed: ${e.toString()}',
      };
    }
  }

  /// Get information about a specific model
  Future<LMStudioModel> getModelInfo({
    required String baseUrl,
    required String modelId,
    String? apiToken,
  }) async {
    try {
      final response = await _serverGet(
        Uri.parse('$baseUrl$_modelsV0Endpoint/$modelId'),
        headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LMStudioModel.fromJson(jsonData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      } else {
        throw Exception('Failed to load model info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting model info: $e');
    }
  }

  /// Text Completions API - provide a prompt and get a completion
  Future<Map<String, dynamic>> getTextCompletion({
    required String baseUrl,
    required String prompt,
    required AppSettings settings,
    int? maxTokens,
    String? stopSequence,
  }) async {
    try {
      final requestBody = {
        'model': settings.selectedModel ?? '',
        'prompt': prompt,
        'temperature': settings.temperature,
        'max_tokens': maxTokens ?? settings.maxTokens,
        'top_p': settings.topP,
        'repeat_penalty': settings.repeatPenalty,
        'stream': false,
        if (stopSequence != null) 'stop': stopSequence,
      };

      final response = await _serverPost(
        Uri.parse('$baseUrl$_completionsEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final choices = jsonResponse['choices'] as List;

        if (choices.isNotEmpty) {
          return {
            'text': choices[0]['text'] as String,
            'usage': jsonResponse['usage'],
            'stats': jsonResponse['stats'],
            'model_info': jsonResponse['model_info'],
            'runtime': jsonResponse['runtime'],
          };
        } else {
          throw Exception('No response from model');
        }
      } else {
        throw Exception('Failed to get completion: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during text completion: $e');
    }
  }

  /// Text Embeddings API - convert text to embedding vector
  Future<List<double>> getEmbedding({
    required String baseUrl,
    required String text,
    required String embeddingModel,
  }) async {
    try {
      final requestBody = {
        'model': embeddingModel,
        'input': text,
      };

      final response = await _serverPost(
        Uri.parse('$baseUrl$_embeddingsEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'] as List;

        if (data.isNotEmpty) {
          final embedding = data[0]['embedding'] as List;
          return embedding.map((e) => (e as num).toDouble()).toList();
        } else {
          throw Exception('No embedding returned');
        }
      } else {
        throw Exception('Failed to get embedding: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting embedding: $e');
    }
  }

  /// Get embeddings for multiple texts at once
  Future<List<List<double>>> getEmbeddings({
    required String baseUrl,
    required List<String> texts,
    required String embeddingModel,
  }) async {
    try {
      final requestBody = {
        'model': embeddingModel,
        'input': texts,
      };

      final response = await _serverPost(
        Uri.parse('$baseUrl$_embeddingsEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'] as List;

        return data.map<List<double>>((item) {
          final embedding = item['embedding'] as List;
          return embedding.map((e) => (e as num).toDouble()).toList();
        }).toList();
      } else {
        throw Exception('Failed to get embeddings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting embeddings: $e');
    }
  }

  /// Load a model with optional configuration
  ///
  /// Supported config parameters:
  /// - context_length: Maximum number of tokens (int)
  /// - eval_batch_size: Batch size for evaluation (int)
  /// - flash_attention: Enable flash attention optimization (bool)
  /// - num_experts: Number of experts for MoE models (int)
  /// - offload_kv_cache_to_gpu: Offload KV cache to GPU (bool)
  Future<bool> loadModel({
    required String baseUrl,
    required String modelPath,
    Map<String, dynamic>? config,
    String? apiToken,
  }) async {
    try {
      final path = modelPath.trim();
      if (path.isEmpty) {
        throw Exception('No model selected.');
      }
      final requestBody = {
        'model': path,
        if (config != null) ...config,
      };

      final response = await _serverPost(
        Uri.parse('$baseUrl$_loadModelEndpoint'),
        headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      } else {
        debugPrint(
            'LMStudioService: Load model error ${response.statusCode}: ${response.body}');
        final droppedField = missingRequiredFieldFromHttpBody(response.body);
        if (droppedField != null &&
            requestJsonHasField(requestBody, droppedField)) {
          throw Exception(DroppedRequestBodyError.userMessage);
        }
        final parsed = _parseErrorResponse(response);
        // Prefer LM Studio's message (e.g. model_not_found) over bare status.
        if (parsed.isNotEmpty && parsed != 'Unknown error') {
          throw Exception(parsed);
        }
        throw Exception('Failed to load model: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LMStudioService: Exception in loadModel: $e');
      rethrow;
    }
  }

  /// Unsloth `GET /api/inference/status`. Null when the route is missing.
  Future<Map<String, dynamic>?> fetchUnslothInferenceStatus({
    required String baseUrl,
    String? apiToken,
  }) async {
    final root = UnslothLoad.apiRoot(baseUrl);
    final response = await http
        .get(
          Uri.parse('$root/api/inference/status'),
          headers: _buildHeaders(
            requestUrl: root,
            apiToken: apiToken,
            cloudProviderType: CloudApiType.unsloth,
          ),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  /// Load (or reload) an Unsloth model at [maxSeqLength] tokens.
  ///
  /// Chat completions ignore context length. Unsloth only applies it here.
  Future<void> loadUnslothModel({
    required String baseUrl,
    required String modelId,
    required int maxSeqLength,
    String? apiToken,
  }) async {
    final root = UnslothLoad.apiRoot(baseUrl);
    final response = await http
        .post(
          Uri.parse('$root/api/inference/load'),
          headers: _buildHeaders(
            requestUrl: root,
            apiToken: apiToken,
            cloudProviderType: CloudApiType.unsloth,
          ),
          body: jsonEncode(
            UnslothLoad.loadBody(modelId: modelId, maxSeqLength: maxSeqLength),
          ),
        )
        .timeout(const Duration(minutes: 10));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(_parseErrorResponse(response));
    }
    final parsed = _parseErrorResponse(response);
    if (parsed.isNotEmpty && parsed != 'Unknown error') {
      throw Exception(parsed);
    }
    throw Exception('Failed to load model: ${response.statusCode}');
  }

  /// Take an Unsloth model out of memory.
  Future<void> unloadUnslothModel({
    required String baseUrl,
    required String modelId,
    String? apiToken,
  }) async {
    final root = UnslothLoad.apiRoot(baseUrl);
    final response = await http
        .post(
          Uri.parse('$root/api/inference/unload'),
          headers: _buildHeaders(
            requestUrl: root,
            apiToken: apiToken,
            cloudProviderType: CloudApiType.unsloth,
          ),
          body: jsonEncode({
            'model_path': UnslothLoad.modelPath(modelId),
          }),
        )
        .timeout(const Duration(minutes: 5));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final parsed = _parseErrorResponse(response);
    if (parsed.isNotEmpty && parsed != 'Unknown error') {
      throw Exception(parsed);
    }
    throw Exception('Failed to unload model: ${response.statusCode}');
  }

  /// Unload a model from memory
  ///
  /// [instanceId] - The model instance ID to unload (usually the model path/id)
  Future<bool> unloadModel({
    required String baseUrl,
    required String instanceId,
    String? apiToken,
  }) async {
    try {
      final id = instanceId.trim();
      if (id.isEmpty) {
        throw Exception('No model instance to unload.');
      }
      final requestBody = {
        'instance_id': id,
      };

      final response = await _serverPost(
        Uri.parse('$baseUrl$_unloadModelEndpoint'),
        headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint('LMStudioService: Model unloaded successfully: $id');
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      } else {
        debugPrint(
            'LMStudioService: Unload model error ${response.statusCode}: ${response.body}');
        final droppedField = missingRequiredFieldFromHttpBody(response.body);
        if (droppedField != null &&
            requestJsonHasField(requestBody, droppedField)) {
          throw Exception(DroppedRequestBodyError.userMessage);
        }
        throw Exception('Failed to unload model: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LMStudioService: Exception in unloadModel: $e');
      rethrow;
    }
  }

  /// Download a model from LM Studio catalog or Hugging Face
  ///
  /// [model] - Model identifier (e.g., "ibm/granite-4-micro") or Hugging Face URL
  /// [quantization] - Optional quantization level (e.g., "Q4_K_M"), only for HF URLs
  ///
  /// Returns download job status with job_id for tracking
  Future<Map<String, dynamic>> downloadModel({
    required String baseUrl,
    required String model,
    String? quantization,
    String? apiToken,
  }) async {
    try {
      final requestBody = {
        'model': model,
        if (quantization != null) 'quantization': quantization,
      };

      final response = await http.post(
        Uri.parse('$baseUrl$_downloadModelEndpoint'),
        headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      } else {
        final parsed = _tryParseErrorJson(response.body);
        final message = parsed?['message'] as String?;
        debugPrint(
            'LMStudioService: Download model error ${response.statusCode}: ${response.body}');
        throw Exception(
            message ?? 'Failed to download model: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LMStudioService: Exception in downloadModel: $e');
      rethrow;
    }
  }

  /// Ask LM Studio which GGUF quantizations it supports for a Hugging Face URL.
  /// Uses a probe request — LM Studio responds with the exact quant names it expects.
  Future<List<String>> listHfDownloadQuantizations({
    required String baseUrl,
    required String modelUrl,
    String? apiToken,
  }) async {
    final hfUrl = modelUrl.startsWith('http')
        ? modelUrl
        : 'https://huggingface.co/$modelUrl';

    final response = await http.post(
      Uri.parse('$baseUrl$_downloadModelEndpoint'),
      headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
      body: jsonEncode({
        'model': hfUrl,
        'quantization': '__lmmini_quant_list_probe__',
      }),
    );

    if (response.statusCode == 200) {
      // Single-quant repo — LM Studio accepted without needing a picker.
      return const [];
    }

    final parsed = _tryParseErrorJson(response.body);
    final message = parsed?['message'] as String? ?? '';
    final quants = _parseAvailableQuantizations(message);
    if (quants.isNotEmpty) return quants;

    throw Exception(
      message.isNotEmpty
          ? message
          : 'Could not list quantizations from LM Studio',
    );
  }

  static Map<String, dynamic>? _tryParseErrorJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        return Map<String, dynamic>.from(decoded['error'] as Map);
      }
    } catch (_) {}
    return null;
  }

  static List<String> _parseAvailableQuantizations(String message) {
    final match = RegExp(r'Available quantizations are:\s*(.+?)(?:\.|$)')
        .firstMatch(message);
    if (match == null) return const [];
    return match
        .group(1)!
        .trim()
        .split(RegExp(r'\s+'))
        .where((q) => q.isNotEmpty)
        .toList();
  }

  /// Get download status for a specific job
  ///
  /// Returns status object with progress information
  /// Status can be: "downloading", "paused", "completed", "failed"
  Future<Map<String, dynamic>> getDownloadStatus({
    required String baseUrl,
    required String jobId,
    String? apiToken,
  }) async {
    _downloadStatusInFlight++;
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$_downloadStatusEndpoint/$jobId'),
            headers: _buildHeaders(requestUrl: baseUrl, apiToken: apiToken),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_parseErrorResponse(response));
      } else {
        debugPrint(
            'LMStudioService: Download status error ${response.statusCode}: ${response.body}');
        throw Exception(
            'Failed to get download status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LMStudioService: Exception in getDownloadStatus: $e');
      rethrow;
    } finally {
      _downloadStatusInFlight--;
    }
  }

  /// Ask LM Studio to stop an in-flight Hugging Face / catalog download.
  ///
  /// Returns true if LMS accepted a cancel. Public REST docs omit this; we
  /// try a few endpoint shapes that match load/unload.
  Future<bool> cancelDownload({
    required String baseUrl,
    required String jobId,
    String? apiToken,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) return false;
    final headers = _buildHeaders(requestUrl: baseUrl, apiToken: apiToken);

    for (final attempt in lmStudioDownloadCancelAttempts(id)) {
      try {
        final uri = Uri.parse('$baseUrl${attempt.path}');
        final http.Response response;
        if (attempt.method == 'DELETE') {
          response = await http.delete(uri, headers: headers);
        } else {
          response = await http.post(
            uri,
            headers: headers,
            body: attempt.body == null ? null : jsonEncode(attempt.body),
          );
        }
        if (lmStudioCancelHttpAccepted(response.statusCode)) {
          final parsed = _tryParseErrorJson(response.body);
          if (parsed != null &&
              (parsed['type'] == 'not_implemented' ||
                  parsed['type'] == 'not_found')) {
            debugPrint('LMStudioService: cancel download ${attempt.path} '
                'not implemented: ${response.body}');
            continue;
          }
          debugPrint('LMStudioService: cancel download via ${attempt.method} '
              '${attempt.path} → ${response.statusCode}');
          return true;
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception(_parseErrorResponse(response));
        }
        if (lmStudioCancelHttpTryNext(response.statusCode)) {
          debugPrint('LMStudioService: cancel download ${attempt.path} '
              '${response.statusCode}, trying next');
          continue;
        }
        debugPrint('LMStudioService: cancel download ${attempt.path} '
            '${response.statusCode}: ${response.body}');
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('403')) {
          rethrow;
        }
        debugPrint(
            'LMStudioService: cancel download ${attempt.path} failed: $e');
      }
    }
    return false;
  }

  /// Get available quantizations from HuggingFace repository
  ///
  /// Fetches the file list from HF API and extracts GGUF quantizations
  /// Returns list of {path, size, quantization, filename}
  Future<List<Map<String, dynamic>>> getHuggingFaceQuantizations(
      String repoUrl) async {
    try {
      // Extract user/repo from URL
      final uri = Uri.parse(repoUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 2) {
        throw Exception(
            'Invalid HuggingFace URL format. Expected: https://huggingface.co/user/repo');
      }

      final user = pathSegments[0];
      final repo = pathSegments[1];
      final apiUrl = '$_huggingFaceApiBase/models/$user/$repo/tree/main';

      debugPrint('LMStudioService: Fetching HF quantizations from $apiUrl');
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> files = jsonDecode(response.body);

        // Filter for GGUF files and extract quantization info
        final ggufFiles = files
            .where((file) =>
                file['type'] == 'file' &&
                file['path'].toString().toLowerCase().endsWith('.gguf'))
            .map((file) {
          final path = file['path'].toString();
          final size = (file['size'] as num?)?.toInt() ?? 0;

          // Extract quantization from filename
          final filename = path.split('/').last;
          String quantization = 'Unknown';

          // Convert to uppercase for easier matching
          final filenameUpper = filename.toUpperCase();

          // Try to match quantization patterns directly in the filename
          // This avoids splitting and losing the underscore connections
          final patterns = [
            // IQ quantizations: IQ4_NL, IQ3_M, etc.
            RegExp(r'IQ\d+_[A-Z]+'),
            // Q quantizations with K/M variants: Q4_K_M, Q5_K_S, Q6_K, etc.
            RegExp(r'Q\d+_K(?:_[SMLV])?'),
            // Q quantizations with numbers: Q8_0, Q4_0, Q5_0, Q5_1, etc.
            RegExp(r'Q\d+_\d+'),
            // Simple Q quantizations: Q4, Q5, Q8, etc.
            RegExp(r'Q\d+(?![_A-Z0-9])'),
            // Floating point: BF16, F16, F32, etc.
            RegExp(r'(?:BF|F)\d+'),
          ];

          for (var pattern in patterns) {
            final match = pattern.firstMatch(filenameUpper);
            if (match != null) {
              quantization = match.group(0)!;
              break;
            }
          }

          return {
            'path': path,
            'size': size,
            'quantization': quantization,
            'filename': filename,
          };
        }).toList();

        debugPrint('LMStudioService: Found ${ggufFiles.length} GGUF files');
        return ggufFiles;
      } else {
        throw Exception(
            'Failed to fetch HuggingFace files: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
          'LMStudioService: Exception in getHuggingFaceQuantizations: $e');
      rethrow;
    }
  }
}
