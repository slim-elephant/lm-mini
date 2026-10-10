import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_model_capabilities.dart';

const _providersKey = 'cloud_api_providers';
const _activeProviderKey = 'cloud_api_active_id';

/// Normalizes a user-entered server URL for OpenAI-compatible providers.
String normalizeCloudBaseUrl(String url) {
  var trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    trimmed = 'http://$trimmed';
  }
  while (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

/// Hosted OpenAI Chat Completions (`api.openai.com`), not Azure or docs sites.
bool isHostedOpenAiBaseUrl(String? url) {
  final normalized = normalizeCloudBaseUrl(url ?? '');
  if (normalized.isEmpty) return false;
  final host = Uri.tryParse(normalized)?.host.toLowerCase() ?? '';
  return host == 'api.openai.com' ||
      host == 'openai.com' ||
      host == 'www.openai.com';
}

/// Compatible (or a bare URL) pointed at OpenAI's API uses first-party
/// Chat Completions shaping (GPT-5 extras, no llama.cpp fields).
CloudApiType? effectiveChatApiType(CloudApiType? type, String? baseUrl) {
  if (type == CloudApiType.openai) return type;
  if (!isHostedOpenAiBaseUrl(baseUrl)) return type;
  if (type == null || type == CloudApiType.openaiCompatible) {
    return CloudApiType.openai;
  }
  return type;
}

/// Manages API keys and configurations for cloud LLM providers.
class CloudApiService extends ChangeNotifier {
  static final CloudApiService _instance = CloudApiService._internal();
  factory CloudApiService() => _instance;
  CloudApiService._internal();

  List<CloudApiProvider> _providers = [];
  String? _activeProviderId;
  String? lastConnectionError;

  /// Relay token when remote LM Mini Connect is active.
  String? remoteAuthToken;

  /// Paired relay base URL. [remoteAuthToken] only goes to providers whose
  /// base URL is under it (free local servers routed through the relay).
  String? remoteRelayBaseUrl;

  List<CloudApiProvider> get providers => List.unmodifiable(_providers);
  String? get activeProviderId => _activeProviderId;
  CloudApiProvider? get activeProvider {
    if (_activeProviderId == null) return null;
    for (final p in _providers) {
      if (p.id == _activeProviderId) return p;
    }
    return null;
  }

  bool get isCloudActive => _activeProviderId != null && activeProvider != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_providersKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        _providers = list
            .map((e) => CloudApiProvider.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('CloudApiService.load: failed to parse providers: $e');
        _providers = [];
      }
    }
    _activeProviderId = prefs.getString(_activeProviderKey);
    notifyListeners();
  }

  Future<void> saveProvider(CloudApiProvider provider) async {
    final normalized = provider.copyWith(
      baseUrl: provider.baseUrl == null || provider.baseUrl!.trim().isEmpty
          ? provider.baseUrl
          : normalizeCloudBaseUrl(provider.baseUrl!),
    );
    final index = _providers.indexWhere((p) => p.id == normalized.id);
    if (index >= 0) {
      _providers[index] = normalized;
    } else {
      _providers.add(normalized);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> removeProvider(String id) async {
    _providers.removeWhere((p) => p.id == id);
    if (_activeProviderId == id) {
      _activeProviderId = null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setActiveProvider(String? id) async {
    _activeProviderId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeProviderKey);
    } else {
      await prefs.setString(_activeProviderKey, id);
    }
    notifyListeners();
  }

  Future<List<String>> fetchModels(CloudApiProvider provider) async {
    final detailed = await fetchModelsDetailed(provider);
    return detailed.map((m) => m.id).toList();
  }

  Future<List<CloudModelInfo>> fetchModelsDetailed(
      CloudApiProvider provider) async {
    // Ollama: prefer native /api/tags (+ /api/show enrichment when available).
    // OpenAI /v1/models is a weaker fallback for capability detection.
    if (provider.type == CloudApiType.ollama) {
      final tagsUrl = '${provider.effectiveBaseUrl}/api/tags';
      try {
        final ollamaModels = await _fetchOllamaTagsModels(provider, tagsUrl);
        if (ollamaModels.isNotEmpty) return ollamaModels;
      } catch (e) {
        debugPrint('CloudApiService: Ollama /api/tags failed, trying /v1: $e');
      }
    }

    var openAiModels = await _fetchOpenAiModelsList(
      provider,
      provider.modelsUrl,
    );
    if (provider.type == CloudApiType.omlx) {
      openAiModels = await _mergeOmlxModelStatus(provider, openAiModels);
    }
    return openAiModels;
  }

  Future<List<CloudModelInfo>> _fetchOpenAiModelsList(
    CloudApiProvider provider,
    String url,
  ) async {
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: _authHeaders(provider))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch models (HTTP ${response.statusCode})');
    }

    final body = json.decode(response.body);
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((entry) => _cloudModelFromOpenAiEntry(entry))
        .whereType<CloudModelInfo>()
        .toList();
  }

  Future<List<CloudModelInfo>> _fetchOllamaTagsModels(
    CloudApiProvider provider,
    String url,
  ) async {
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: _authHeaders(provider))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch Ollama models (HTTP ${response.statusCode})');
    }

    final body = json.decode(response.body);
    final models = body is Map<String, dynamic> ? body['models'] : null;
    if (models is! List) return const [];

    final parsed = models
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final id =
              (entry['name'] as String? ?? entry['model'] as String? ?? '')
                  .trim();
          if (id.isEmpty) return null;
          final lower = id.toLowerCase();
          return CloudModelInfo(
            id: id,
            supportsVision: _ollamaHeuristicSupportsVision(lower),
            // Heuristic default; refined below via /api/show when possible.
            supportsTools: _ollamaHeuristicSupportsTools(lower),
          );
        })
        .whereType<CloudModelInfo>()
        .toList();

    // Enrich a bounded subset with /api/show capabilities (tools/vision/thinking).
    final base = provider.effectiveBaseUrl;
    final enrichLimit = parsed.length < 24 ? parsed.length : 24;
    await Future.wait(List.generate(enrichLimit, (i) async {
      final model = parsed[i];
      try {
        final show = await http
            .post(
              Uri.parse('$base/api/show'),
              headers: _authHeaders(provider),
              body: json.encode({'model': model.id, 'name': model.id}),
            )
            .timeout(const Duration(seconds: 6));
        if (show.statusCode != 200) return;
        final showBody = json.decode(show.body);
        if (showBody is! Map) return;
        final caps = showBody['capabilities'];
        final capSet = <String>{};
        if (caps is List) {
          for (final c in caps) {
            if (c is String) capSet.add(c.toLowerCase());
          }
        }
        final supportsTools = capSet.isNotEmpty
            ? (capSet.contains('tools') || capSet.contains('tool'))
            : model.supportsTools;
        final supportsVision = capSet.contains('vision') ||
            (capSet.isEmpty && model.supportsVision);
        final supportsThinking =
            capSet.contains('thinking') || capSet.contains('reasoning');
        parsed[i] = CloudModelInfo(
          id: model.id,
          supportsTools: supportsTools,
          supportsVision: supportsVision,
          supportsThinking: supportsThinking,
        );
      } catch (_) {}
    }));

    return parsed;
  }

  bool _ollamaHeuristicSupportsVision(String lowerId) {
    const markers = [
      'vision',
      'llava',
      'pixtral',
      'moondream',
      'minicpm-v',
      'internvl',
      'qwen2-vl',
      'qwen2.5-vl',
      'qwen3-vl',
      'qwen3.5',
      'qwen3_5',
      'qwen35',
      '-vl',
      'vl-',
      'vlm',
      ':vl',
      '_vl',
      'vl_',
    ];
    return markers.any(lowerId.contains);
  }

  bool _ollamaHeuristicSupportsTools(String lowerId) {
    const families = [
      'qwen2.5',
      'qwen3',
      'qwen2',
      'llama3.1',
      'llama3.2',
      'llama3.3',
      'llama4',
      'mistral',
      'mixtral',
      'command-r',
      'firefunction',
      'hermes',
      'tool',
      'ii-search',
      'deepseek-r1',
      'gpt-oss',
    ];
    if (lowerId.contains('gemma') && !lowerId.contains('tool')) return false;
    if (lowerId.contains('llava')) return false;
    if (lowerId.contains('moondream')) return false;
    if (lowerId.contains('codegemma')) return false;
    if (lowerId.contains('deepseek-coder')) return false;
    if (lowerId.contains('starcoder')) return false;
    if (lowerId.contains('codellama')) return false;
    if (lowerId.contains('wizardcoder')) return false;
    return families.any(lowerId.contains);
  }

  CloudModelInfo? _cloudModelFromOpenAiEntry(Map<String, dynamic> entry) {
    final id = entry['id'] as String? ?? '';
    if (id.isEmpty) return null;
    final caps = capabilitiesFromOpenAiEntry(entry);
    return CloudModelInfo(
      id: id,
      supportsVision: caps.vision,
      supportsTools: caps.tools,
      supportsThinking: caps.thinking,
    );
  }

  /// oMLX `/v1/models` is OpenAI-shaped and has no capability fields.
  /// `/v1/models/status` includes `model_type` (`vlm` vs `llm`).
  Future<List<CloudModelInfo>> _mergeOmlxModelStatus(
    CloudApiProvider provider,
    List<CloudModelInfo> listed,
  ) async {
    try {
      final uri = Uri.parse('${provider.effectiveBaseUrl}/v1/models/status');
      final response = await http
          .get(uri, headers: _authHeaders(provider))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return listed;
      final body = json.decode(response.body);
      if (body is! Map) return listed;
      final models = body['models'];
      if (models is! List) return listed;

      final byId = <String, Map<String, dynamic>>{};
      for (final raw in models) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final id = (map['id'] as String? ?? '').trim();
        final alias = (map['model_alias'] as String? ?? '').trim();
        if (id.isNotEmpty) byId[id] = map;
        if (alias.isNotEmpty) byId[alias] = map;
      }
      if (byId.isEmpty) return listed;

      final merged = listed.map((model) {
        final status = byId[model.id];
        if (status == null) return model;
        final caps = capabilitiesFromOmlxStatus(status);
        final hasType =
            status['model_type'] != null || status['engine_type'] != null;
        return CloudModelInfo(
          id: model.id,
          supportsVision:
              hasType ? caps.vision : (caps.vision || model.supportsVision),
          supportsTools: caps.tools || model.supportsTools,
          supportsThinking: caps.thinking || model.supportsThinking,
        );
      }).toList();

      final knownIds = merged.map((m) => m.id).toSet();
      for (final entry in byId.entries) {
        if (knownIds.contains(entry.key)) continue;
        final id = (entry.value['id'] as String? ?? entry.key).trim();
        if (id.isEmpty || knownIds.contains(id)) continue;
        final caps = capabilitiesFromOmlxStatus(entry.value);
        merged.add(CloudModelInfo(
          id: id,
          supportsVision: caps.vision,
          supportsTools: caps.tools,
          supportsThinking: caps.thinking,
        ));
        knownIds.add(id);
      }
      return merged;
    } catch (e) {
      debugPrint('CloudApiService: oMLX /v1/models/status merge failed: $e');
      return listed;
    }
  }

  Future<bool> testConnection(CloudApiProvider provider) async {
    lastConnectionError = null;
    try {
      final uri = Uri.parse(provider.modelsUrl);
      final response = await http
          .get(uri, headers: _authHeaders(provider))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) return true;

      if (response.statusCode == 401 || response.statusCode == 403) {
        lastConnectionError =
            'Authentication failed (HTTP ${response.statusCode}). Check your API key.';
        return false;
      }

      lastConnectionError = 'Server returned HTTP ${response.statusCode}';
      debugPrint(
          '⚠️ testConnection HTTP ${response.statusCode}: ${response.body}');
      return false;
    } on TimeoutException {
      lastConnectionError =
          'Connection timed out. Check that the server is running and reachable.';
      debugPrint('⚠️ testConnection error: $lastConnectionError');
      return false;
    } catch (e) {
      lastConnectionError = e.toString();
      debugPrint('⚠️ testConnection error: $e');
      return false;
    }
  }

  Map<String, String> _requestHeaders(CloudApiProvider provider) {
    final headers = <String, String>{
      'Accept': 'application/json',
      ...provider.type.extraHeaders,
    };
    if (provider.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${provider.apiKey}';
    }
    if (provider.customHeadersEnabled && provider.customHeaders != null) {
      provider.customHeaders!.forEach((k, v) {
        final key = k.trim();
        if (key.isEmpty) return;
        headers[key] = v;
      });
    }
    final relay = remoteAuthToken?.trim();
    if (relay != null &&
        relay.isNotEmpty &&
        _isUnderRelay(provider.effectiveBaseUrl) &&
        (provider.type == CloudApiType.ollama ||
            provider.type == CloudApiType.omlx ||
            provider.type == CloudApiType.jan ||
            provider.type == CloudApiType.unsloth)) {
      headers['X-LM-Mini-Token'] = relay;
      headers['X-LM-Mini-Backend'] = provider.type.providerKind;
    }
    return headers;
  }

  /// Same scheme/host/port as [remoteRelayBaseUrl], path at or under it.
  bool _isUnderRelay(String url) {
    final relay = Uri.tryParse(remoteRelayBaseUrl?.trim() ?? '');
    final target = Uri.tryParse(url.trim());
    if (relay == null ||
        target == null ||
        relay.host.isEmpty ||
        relay.scheme.toLowerCase() != target.scheme.toLowerCase() ||
        relay.host.toLowerCase() != target.host.toLowerCase() ||
        relay.port != target.port) {
      return false;
    }
    final base = relay.path.replaceAll(RegExp(r'/+$'), '');
    return base.isEmpty ||
        target.path == base ||
        target.path.startsWith('$base/');
  }

  Map<String, String> _authHeaders(CloudApiProvider provider) =>
      _requestHeaders(provider);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        json.encode(_providers.map((p) => p.toMap()).toList(growable: false));
    await prefs.setString(_providersKey, encoded);
    if (_activeProviderId == null) {
      await prefs.remove(_activeProviderKey);
    } else {
      await prefs.setString(_activeProviderKey, _activeProviderId!);
    }
  }
}

/// Configuration for a single cloud API provider.
class CloudApiProvider {
  final String id;
  final String name;
  final CloudApiType type;
  final String apiKey;
  final String? baseUrl;
  final String? selectedModel;
  final bool isEnabled;
  final Map<String, String>? customHeaders;
  final bool customHeadersEnabled;

  CloudApiProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.apiKey,
    this.baseUrl,
    this.selectedModel,
    this.isEnabled = true,
    this.customHeaders,
    this.customHeadersEnabled = false,
  });

  CloudApiProvider copyWith({
    String? name,
    CloudApiType? type,
    String? apiKey,
    String? baseUrl,
    String? selectedModel,
    bool? isEnabled,
    Object? customHeaders = _cloudUnset,
    bool? customHeadersEnabled,
  }) {
    return CloudApiProvider(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      selectedModel: selectedModel ?? this.selectedModel,
      isEnabled: isEnabled ?? this.isEnabled,
      customHeaders: identical(customHeaders, _cloudUnset)
          ? this.customHeaders
          : customHeaders as Map<String, String>?,
      customHeadersEnabled: customHeadersEnabled ?? this.customHeadersEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'selectedModel': selectedModel,
        'isEnabled': isEnabled,
        'customHeaders': customHeaders,
        'customHeadersEnabled': customHeadersEnabled,
      };

  factory CloudApiProvider.fromMap(Map<String, dynamic> map) {
    Map<String, String>? headers;
    final rawHeaders = map['customHeaders'];
    if (rawHeaders is Map) {
      headers = rawHeaders.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    return CloudApiProvider(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CloudApiType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => CloudApiType.openaiCompatible,
      ),
      apiKey: map['apiKey'] as String? ?? '',
      baseUrl: map['baseUrl'] as String?,
      selectedModel: map['selectedModel'] as String?,
      isEnabled: map['isEnabled'] as bool? ?? true,
      customHeaders: headers,
      customHeadersEnabled: map['customHeadersEnabled'] as bool? ?? false,
    );
  }

  /// Suggested models for each provider type.
  List<String> get suggestedModels => type.suggestedModels;

  /// The effective API base URL (default per type, or user-overridden).
  String get effectiveBaseUrl {
    final raw = (baseUrl != null && baseUrl!.isNotEmpty)
        ? baseUrl!
        : type.defaultBaseUrl;
    final normalized = normalizeCloudBaseUrl(raw);
    if (isHostedOpenAiBaseUrl(normalized)) {
      return 'https://api.openai.com';
    }
    return normalized;
  }

  /// Request shaping: Compatible + openai.com → first-party OpenAI APIs.
  CloudApiType get requestApiType =>
      effectiveChatApiType(type, effectiveBaseUrl) ?? type;

  /// Full chat completions URL for this provider.
  String get chatCompletionsUrl => '$effectiveBaseUrl${type.chatPath}';

  /// Full models list URL for this provider.
  String get modelsUrl => '$effectiveBaseUrl${type.modelsPath}';
}

/// All supported cloud API provider types.
///
/// Every type listed here uses an OpenAI-compatible chat completions
/// format, so the same streaming code path works for all of them.
/// The only differences are the URL paths, request parameters, and
/// which features are supported.
enum CloudApiType {
  openai,
  openRouter,
  mistral,
  deepSeek,

  /// Google AI Studio (Gemini) via the OpenAI-compatible endpoint.
  gemini,
  openaiCompatible,

  /// Z.AI (GLM) OpenAI-compatible API — https://docs.z.ai
  zAi,

  /// Vercel AI Gateway — https://ai-gateway.vercel.sh/v1
  vercelAiGateway,

  /// oMLX — local OpenAI-compatible MLX server. **Non-premium.**
  omlx,

  /// Ollama — local inference server. **Non-premium.**
  /// Chat uses native `/api/chat` (not OpenAI `/v1`); MCP/Pro Search are client-side.
  ollama,

  /// Jan — local OpenAI-compatible llama.cpp server. **Non-premium.**
  /// Default: `http://127.0.0.1:1337/v1` (`POST /v1/chat/completions`).
  jan,

  /// Unsloth Desktop — local OpenAI-compatible server. **Non-premium.**
  /// Default: `http://localhost:8888` (`POST /v1/chat/completions`).
  /// Requires `Authorization: Bearer sk-unsloth-…`.
  unsloth;

  /// First-party OpenAI is hidden on Apple platforms (App Store positioning).
  static bool get hideFirstPartyOpenAi =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Saved OpenAI servers stay visible; new adds omit this type on Apple.
  static bool showInTypePicker(
    CloudApiType type, {
    CloudApiType? keepIfCurrent,
  }) {
    if (type != CloudApiType.openai) return true;
    if (!hideFirstPartyOpenAi) return true;
    return keepIfCurrent == CloudApiType.openai;
  }

  static bool warnBeforeRemoving(CloudApiType? type) =>
      type == CloudApiType.openai && hideFirstPartyOpenAi;

  /// Whether using this provider requires an active Pro subscription.
  bool get isPremium {
    switch (this) {
      case CloudApiType.omlx:
      case CloudApiType.ollama:
      case CloudApiType.jan:
      case CloudApiType.unsloth:
        return false;
      default:
        return true;
    }
  }

  /// Free local servers (Ollama, oMLX, Jan, Unsloth) — not the Pro `'cloud'` umbrella.
  bool get isFreeLocalServer => !isPremium;

  /// Maps `AppSettings.activeProviderKind` to a free local [CloudApiType].
  static CloudApiType? forProviderKind(String kind) {
    switch (kind) {
      case 'ollama':
        return CloudApiType.ollama;
      case 'omlx':
        return CloudApiType.omlx;
      case 'jan':
        return CloudApiType.jan;
      case 'unsloth':
        return CloudApiType.unsloth;
      default:
        return null;
    }
  }

  static bool isFreeLocalKind(String kind) => forProviderKind(kind) != null;

  String get providerKind {
    switch (this) {
      case CloudApiType.omlx:
        return 'omlx';
      case CloudApiType.ollama:
        return 'ollama';
      case CloudApiType.jan:
        return 'jan';
      case CloudApiType.unsloth:
        return 'unsloth';
      default:
        return 'cloud';
    }
  }

  bool get isLocalOpenAiCompatible {
    switch (this) {
      case CloudApiType.omlx:
      case CloudApiType.ollama:
      case CloudApiType.jan:
      case CloudApiType.unsloth:
        return true;
      default:
        return false;
    }
  }

  bool get allowsEmptyApiKey =>
      this == CloudApiType.ollama || this == CloudApiType.jan;

  String get displayName {
    switch (this) {
      case CloudApiType.openai:
        return 'OpenAI';
      case CloudApiType.openRouter:
        return 'OpenRouter';
      case CloudApiType.mistral:
        return 'Mistral';
      case CloudApiType.deepSeek:
        return 'DeepSeek';
      case CloudApiType.gemini:
        return 'Google AI Studio';
      case CloudApiType.openaiCompatible:
        return 'A.I Compatible API';
      case CloudApiType.zAi:
        return 'Z.AI';
      case CloudApiType.vercelAiGateway:
        return 'Vercel AI Gateway';
      case CloudApiType.omlx:
        return 'oMLX';
      case CloudApiType.ollama:
        return 'Ollama';
      case CloudApiType.jan:
        return 'JAN AI';
      case CloudApiType.unsloth:
        return 'Unsloth';
    }
  }

  String get iconEmoji {
    switch (this) {
      case CloudApiType.openai:
        return '🤖';
      case CloudApiType.openRouter:
        return '🔀';
      case CloudApiType.mistral:
        return '🌬️';
      case CloudApiType.deepSeek:
        return '🔍';
      case CloudApiType.gemini:
        return '✨';
      case CloudApiType.openaiCompatible:
        return '🔌';
      case CloudApiType.zAi:
        return '🧠';
      case CloudApiType.vercelAiGateway:
        return '▲';
      case CloudApiType.omlx:
        return '🍏';
      case CloudApiType.ollama:
        return '🦙';
      case CloudApiType.jan:
        return '⚡';
      case CloudApiType.unsloth:
        return '🦥';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case CloudApiType.openai:
        return 'https://api.openai.com';
      case CloudApiType.openRouter:
        return 'https://openrouter.ai/api';
      case CloudApiType.mistral:
        return 'https://api.mistral.ai';
      case CloudApiType.deepSeek:
        return 'https://api.deepseek.com';
      case CloudApiType.gemini:
        return 'https://generativelanguage.googleapis.com';
      case CloudApiType.openaiCompatible:
        return '';
      case CloudApiType.zAi:
        return 'https://api.z.ai/api/paas/v4';
      case CloudApiType.vercelAiGateway:
        return 'https://ai-gateway.vercel.sh';
      case CloudApiType.omlx:
        return 'http://localhost:8000';
      case CloudApiType.ollama:
        return 'http://localhost:11434';
      case CloudApiType.jan:
        return 'http://localhost:1337';
      case CloudApiType.unsloth:
        return 'http://localhost:8888';
    }
  }

  String get chatPath {
    switch (this) {
      case CloudApiType.gemini:
        return '/v1beta/openai/chat/completions';
      case CloudApiType.zAi:
        // Base URL already ends at /v4 — OpenAI SDK appends chat/completions.
        return '/chat/completions';
      default:
        return '/v1/chat/completions';
    }
  }

  String get modelsPath {
    switch (this) {
      case CloudApiType.gemini:
        return '/v1beta/openai/models';
      case CloudApiType.zAi:
        return '/models';
      default:
        return '/v1/models';
    }
  }

  String get apiKeyUrl {
    switch (this) {
      case CloudApiType.openai:
        return 'https://platform.openai.com/api-keys';
      case CloudApiType.openRouter:
        return 'https://openrouter.ai/keys';
      case CloudApiType.mistral:
        return 'https://console.mistral.ai/api-keys';
      case CloudApiType.deepSeek:
        return 'https://platform.deepseek.com/api_keys';
      case CloudApiType.gemini:
        return 'https://aistudio.google.com/apikey';
      case CloudApiType.openaiCompatible:
        return '';
      case CloudApiType.zAi:
        return 'https://z.ai/manage-apikey/apikey-list';
      case CloudApiType.vercelAiGateway:
        return 'https://vercel.com/docs/ai-gateway';
      case CloudApiType.omlx:
        return '';
      case CloudApiType.ollama:
        return 'https://ollama.com/settings/keys';
      case CloudApiType.jan:
        return 'https://jan.ai/docs/desktop/api-server';
      case CloudApiType.unsloth:
        return 'https://unsloth.ai/docs/integrations/connect-curl-and-http-to-unsloth';
    }
  }

  List<String> get suggestedModels {
    switch (this) {
      case CloudApiType.openai:
        return [
          'gpt-5.6',
          'gpt-5.4',
          'gpt-5-mini',
          'gpt-5-nano',
          'gpt-4.1',
          'gpt-4.1-mini',
          'gpt-4o',
          'gpt-4o-mini',
          'o4-mini',
          'o3-mini',
        ];
      case CloudApiType.openRouter:
        return [
          'openai/gpt-5.6',
          'openai/gpt-4o',
          'anthropic/claude-sonnet-4',
          'google/gemini-2.5-flash',
          'meta-llama/llama-3.3-70b-instruct',
        ];
      case CloudApiType.mistral:
        return [
          'mistral-large-latest',
          'mistral-medium-latest',
          'mistral-small-latest',
          'codestral-latest',
          'pixtral-large-latest',
        ];
      case CloudApiType.deepSeek:
        return ['deepseek-chat', 'deepseek-reasoner'];
      case CloudApiType.gemini:
        return [
          'gemini-2.5-flash',
          'gemini-2.5-pro',
          'gemini-2.0-flash',
        ];
      case CloudApiType.openaiCompatible:
        return [];
      case CloudApiType.zAi:
        return ['glm-5.2', 'glm-4.6', 'glm-4.5', 'glm-4.5-air'];
      case CloudApiType.vercelAiGateway:
        return [
          'openai/gpt-5.6',
          'anthropic/claude-sonnet-4',
          'google/gemini-2.5-flash',
        ];
      case CloudApiType.omlx:
        return [];
      case CloudApiType.ollama:
        return [
          'llama3.2',
          'qwen2.5',
          'gemma3',
          'deepseek-r1',
          'mistral',
          'llava',
        ];
      case CloudApiType.jan:
        return [];
      case CloudApiType.unsloth:
        return [];
    }
  }

  bool get supportsModelListing => true;

  /// Ollama accepts top_k via native /api/chat options.
  bool get supportsTopK {
    switch (this) {
      case CloudApiType.openRouter:
      case CloudApiType.openaiCompatible:
      case CloudApiType.vercelAiGateway:
      case CloudApiType.omlx:
      case CloudApiType.ollama:
      case CloudApiType.jan:
      case CloudApiType.unsloth:
        return true;
      default:
        return false;
    }
  }

  bool get supportsMinP {
    switch (this) {
      case CloudApiType.openRouter:
      case CloudApiType.openaiCompatible:
      case CloudApiType.vercelAiGateway:
      case CloudApiType.omlx:
      case CloudApiType.ollama:
      case CloudApiType.jan:
      case CloudApiType.unsloth:
        return true;
      default:
        return false;
    }
  }

  bool get supportsRepeatPenalty {
    switch (this) {
      case CloudApiType.openRouter:
      case CloudApiType.openaiCompatible:
      case CloudApiType.vercelAiGateway:
      case CloudApiType.omlx:
      case CloudApiType.ollama:
      case CloudApiType.jan:
      case CloudApiType.unsloth:
        return true;
      default:
        return false;
    }
  }

  bool get supportsFrequencyPenalty {
    switch (this) {
      case CloudApiType.gemini:
        return false;
      default:
        return true;
    }
  }

  bool get supportsPresencePenalty {
    switch (this) {
      case CloudApiType.gemini:
        return false;
      default:
        return true;
    }
  }

  bool get supportsImageInput {
    switch (this) {
      case CloudApiType.deepSeek:
        return false;
      default:
        return true;
    }
  }

  /// OpenAI-style `reasoning_effort` (GPT-5 / o-series, gateways that pass it through).
  bool get supportsReasoningEffort {
    switch (this) {
      case CloudApiType.openai:
      case CloudApiType.openRouter:
      case CloudApiType.vercelAiGateway:
      case CloudApiType.deepSeek:
        return true;
      default:
        return false;
    }
  }

  /// OpenAI-style `verbosity` (`low` / `medium` / `high`) for GPT-5 family.
  bool get supportsVerbosity {
    switch (this) {
      case CloudApiType.openai:
      case CloudApiType.openRouter:
      case CloudApiType.vercelAiGateway:
        return true;
      default:
        return false;
    }
  }

  /// Z.AI thinking mode via `thinking: { type: enabled|disabled }`.
  bool get supportsZAiThinking => this == CloudApiType.zAi;

  /// Unsloth top-level `enable_thinking` (on by default on the server).
  bool get supportsUnslothThinking => this == CloudApiType.unsloth;

  /// Ollama num_ctx via native /api/chat options.
  bool get supportsContextWindow => this == CloudApiType.ollama;

  /// Ollama chat uses native POST /api/chat (not OpenAI /v1).
  bool get usesNativeChatApi => this == CloudApiType.ollama;
  bool get supportsV1Api => false;
  bool get supportsMcp => false;

  /// Tool calling is supported; per-model gating lives in ToolSupportResolver.
  bool get supportsTools => true;
  bool get supportsAutoUnload => false;
  bool get supportsModelLoadConfig => false;

  Map<String, String> get extraHeaders {
    switch (this) {
      case CloudApiType.openRouter:
        return {
          'HTTP-Referer': 'https://lmmini.app',
          'X-Title': 'LM Mini',
        };
      default:
        return {};
    }
  }
}

const Object _cloudUnset = Object();

/// Detailed model metadata returned by [CloudApiService.fetchModelsDetailed].
///
/// Stubbed to always be empty. The real premium package populates this from
/// the provider's `/v1/models` response so the app can correctly enable
/// image attachments for vision-capable cloud models.
class CloudModelInfo {
  final String id;
  final bool supportsVision;
  final bool supportsTools;
  final bool supportsThinking;

  const CloudModelInfo({
    required this.id,
    this.supportsVision = false,
    this.supportsTools = false,
    this.supportsThinking = false,
  });
}
