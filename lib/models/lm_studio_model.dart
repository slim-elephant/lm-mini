import 'package:json_annotation/json_annotation.dart';

part 'lm_studio_model.g.dart';

@JsonSerializable()
class LMStudioModel {
  final String id;
  @JsonKey(defaultValue: 'model')
  final String object;
  @JsonKey(defaultValue: 'llm')
  final String type;
  @JsonKey(defaultValue: '')
  final String publisher;
  @JsonKey(defaultValue: '')
  final String arch;
  @JsonKey(name: 'compatibility_type', defaultValue: '')
  final String compatibilityType;
  @JsonKey(defaultValue: '')
  final String quantization;
  @JsonKey(defaultValue: 'not-loaded')
  final String state;
  @JsonKey(name: 'max_context_length', defaultValue: 0)
  final int maxContextLength;
  @JsonKey(name: 'loaded_context_length')
  final int? loadedContextLength;
  @JsonKey(name: 'size_bytes')
  final int? sizeBytes;
  @JsonKey(name: 'params_string')
  final String? paramsString;
  final List<String>? capabilities; // e.g., ["tool_use"]

  // V1 API fields
  final String? v1DisplayName;
  final String? format; // "gguf", "mlx", or null
  final String? description;
  final double? bitsPerWeight;
  final bool? visionCapability;
  final bool? toolUseCapability;
  final int? evalBatchSize;
  final bool? flashAttention;
  final int? loadedNumExperts;
  final bool? offloadKvCacheToGpu;
  final int? loadedParallel;
  final String? loadedInstanceId;

  /// From LM Studio V1 `capabilities.reasoning.allowed_options`.
  /// `null` = unknown; empty = no reasoning API; otherwise the exact values
  /// Mini may send (`off` / `on` / `low` / `medium` / `high`).
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<String>? reasoningAllowedOptions;

  LMStudioModel({
    required this.id,
    required this.object,
    required this.type,
    required this.publisher,
    required this.arch,
    required this.compatibilityType,
    required this.quantization,
    required this.state,
    required this.maxContextLength,
    this.loadedContextLength,
    this.sizeBytes,
    this.paramsString,
    this.capabilities,
    this.v1DisplayName,
    this.format,
    this.description,
    this.bitsPerWeight,
    this.visionCapability,
    this.toolUseCapability,
    this.evalBatchSize,
    this.flashAttention,
    this.loadedNumExperts,
    this.offloadKvCacheToGpu,
    this.loadedParallel,
    this.loadedInstanceId,
    this.reasoningAllowedOptions,
  });

  factory LMStudioModel.fromJson(Map<String, dynamic> json) =>
      _$LMStudioModelFromJson(json);

  /// Parse from LM Studio REST API v1 response format
  factory LMStudioModel.fromV1Json(Map<String, dynamic> json) {
    final quantObj = json['quantization'] as Map<String, dynamic>?;
    final rawCaps = json['capabilities'];
    Map<String, dynamic>? capObj;
    var capTags = const <String>[];
    if (rawCaps is Map) {
      capObj = Map<String, dynamic>.from(rawCaps);
    } else if (rawCaps is List) {
      capTags = rawCaps.map((e) => e.toString().toLowerCase()).toList();
    }
    final loadedInstances = json['loaded_instances'] as List<dynamic>? ?? [];
    final isLoaded = loadedInstances.isNotEmpty;

    int? loadedContextLength;
    int? evalBatch;
    bool? flashAttn;
    int? numExperts;
    bool? offloadKv;
    int? parallel;
    String? instanceId;
    if (isLoaded) {
      final firstInstance = loadedInstances[0] as Map<String, dynamic>;
      instanceId = firstInstance['id'] as String?;
      final config = firstInstance['config'] as Map<String, dynamic>?;
      if (config != null) {
        loadedContextLength = (config['context_length'] as num?)?.toInt();
        evalBatch = (config['eval_batch_size'] as num?)?.toInt();
        flashAttn = _asBool(config['flash_attention']);
        numExperts = (config['num_experts'] as num?)?.toInt();
        offloadKv = _asBool(config['offload_kv_cache_to_gpu']);
        parallel = (config['parallel'] as num?)?.toInt();
      }
    }

    final bool? vision =
        capTags.contains('vision') || capTags.contains('multimodal')
            ? true
            : _asBool(capObj?['vision']);
    final bool? toolUse =
        capTags.contains('tools') || capTags.contains('tool_use')
            ? true
            : _asBool(capObj?['trained_for_tool_use']);
    final embedFromCaps = capTags.contains('embedding') ||
        capTags.contains('embeddings') ||
        _asBool(capObj?['embedding']) == true;
    // LM Studio 0.4.8+: reasoning is an object
    // `{ allowed_options: ["off","on"], default: "on" }`, not a bool.
    // Older builds may still send bool `reasoning` / `thinking`.
    final List<String>? reasoningOptions = parseReasoningAllowedOptions(capObj);
    final bool? reasoning = reasoningOptions == null
        ? _parseReasoningCapability(capObj)
        : reasoningOptions.isNotEmpty;

    final id = (json['key'] ?? json['id'] ?? json['name'] ?? json['model'])
        ?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Model JSON is missing key/id');
    }

    final displayName = json['display_name'] as String?;
    final declaredType = (json['type'] as String?) ?? 'llm';
    final isEmbeddingModel = declaredType == 'embedding' ||
        declaredType == 'embeddings' ||
        embedFromCaps ||
        looksLikeEmbeddingModel(id, displayName);

    return LMStudioModel(
      id: id,
      object: 'model',
      type: isEmbeddingModel
          ? (declaredType == 'embeddings' ? 'embeddings' : 'embedding')
          : declaredType,
      publisher: json['publisher'] as String? ?? '',
      arch: json['architecture'] as String? ?? '',
      compatibilityType: json['format'] as String? ?? '',
      quantization: quantObj?['name'] as String? ?? '',
      state: isLoaded ? 'loaded' : 'not-loaded',
      maxContextLength: (json['max_context_length'] as num?)?.toInt() ?? 0,
      loadedContextLength: loadedContextLength,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      paramsString: json['params_string'] as String?,
      // Map v1 capabilities to v0 list for backward compat
      capabilities: [
        if (toolUse == true) 'tool_use',
        if (reasoning == true) 'thinking',
        if (vision == true) 'vision',
        if (isEmbeddingModel) 'embedding',
      ],
      v1DisplayName: displayName,
      format: json['format'] as String?,
      description: json['description'] as String?,
      bitsPerWeight: (quantObj?['bits_per_weight'] as num?)?.toDouble(),
      visionCapability: vision,
      toolUseCapability: toolUse,
      evalBatchSize: evalBatch,
      flashAttention: flashAttn,
      loadedNumExperts: numExperts,
      offloadKvCacheToGpu: offloadKv,
      loadedParallel: parallel,
      loadedInstanceId: instanceId,
      reasoningAllowedOptions: reasoningOptions,
    );
  }

  /// Coerce JSON values that should be booleans without throwing on maps/strings.
  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'on') return true;
      if (lower == 'false' || lower == '0' || lower == 'off') return false;
    }
    return null;
  }

  /// LM Studio V1 `capabilities.reasoning.allowed_options`.
  ///
  /// - `null` — unknown (older servers, or a bool `true` with no option list)
  /// - `[]` — model has no reasoning API (omit the request field)
  /// - non-empty — send only these values
  static const reasoningOptionValues = ['off', 'on', 'low', 'medium', 'high'];

  static List<String>? parseReasoningAllowedOptions(
    Map<String, dynamic>? capObj,
  ) {
    if (capObj == null) return null;
    final thinking = capObj['thinking'];
    final reasoning = capObj['reasoning'];
    if (reasoning is Map) {
      final options = reasoning['allowed_options'];
      if (options is List) {
        return [
          for (final o in options)
            if (o != null && reasoningOptionValues.contains('$o')) '$o',
        ];
      }
      return null;
    }
    if (reasoning == false || thinking == false) return const [];
    if (reasoning == true || thinking == true) return null;
    final modern = capObj.containsKey('trained_for_tool_use') ||
        capObj.containsKey('reasoning') ||
        capObj.containsKey('thinking');
    if (modern && reasoning == null && thinking == null) return const [];
    return null;
  }

  /// LM Studio may expose reasoning as:
  /// - bool (`true` / `false`)
  /// - object `{ allowed_options: [...], default: "on"|"off" }`
  /// - legacy `thinking` bool
  static bool? _parseReasoningCapability(Map<String, dynamic>? capObj) {
    if (capObj == null) return null;

    final thinking = _asBool(capObj['thinking']);
    if (thinking != null) return thinking;

    final reasoning = capObj['reasoning'];
    final asBool = _asBool(reasoning);
    if (asBool != null) return asBool;

    if (reasoning is Map) {
      final options = reasoning['allowed_options'];
      if (options is List &&
          options.any((o) => o == 'on' || o == true || o == 'true')) {
        return true;
      }
      final def = _asBool(reasoning['default']);
      if (def != null) return def;
      // Presence of a reasoning config object means the model supports it.
      return true;
    }
    return null;
  }

  /// LM Studio `{models:[{key}]}` or llama.cpp / OpenAI `{data:[{id}]}`.
  ///
  /// llama-server sends both an Ollama-style `models` list (no `key`) and an
  /// OpenAI `data` list — prefer `data` unless the `models` entries look like
  /// LM Studio V1.
  static List<LMStudioModel> parseListResponse(Map<String, dynamic> json) {
    final v1 = json['models'];
    final data = json['data'];
    final v1Maps = v1 is List
        ? v1.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final looksLmStudio = v1Maps.any((m) => m['key'] != null);

    if (looksLmStudio) {
      return [
        for (final m in v1Maps)
          if ((m['key'] ?? m['id']) != null) LMStudioModel.fromV1Json(m),
      ];
    }

    final capById = <String, List<String>>{};
    for (final m in v1Maps) {
      final id = (m['name'] ?? m['model'] ?? m['id'] ?? '').toString();
      final caps = m['capabilities'];
      if (id.isEmpty || caps is! List) continue;
      capById[id] = [
        for (final c in caps) c.toString().toLowerCase(),
      ];
    }

    if (data is List) {
      return [
        for (final item in data.whereType<Map>())
          if (_fromOpenAiCompat(Map<String, dynamic>.from(item), capById)
              case final model?)
            model,
      ];
    }

    return [
      for (final m in v1Maps)
        if (_fromOpenAiCompat(m, capById) case final model?) model,
    ];
  }

  static LMStudioModel? _fromOpenAiCompat(
    Map<String, dynamic> map,
    Map<String, List<String>> capById,
  ) {
    final id = (map['id'] ?? map['key'] ?? map['name'] ?? map['model'] ?? '')
        .toString();
    if (id.isEmpty) return null;
    final caps = capById[id] ??
        (map['capabilities'] is List
            ? [
                for (final c in map['capabilities'] as List)
                  c.toString().toLowerCase(),
              ]
            : const <String>[]);
    final vision = caps.contains('vision') || caps.contains('multimodal');
    final embedding = caps.contains('embedding') ||
        caps.contains('embeddings') ||
        looksLikeEmbeddingModel(id);
    final meta = map['meta'];
    int? nCtx;
    int? size;
    if (meta is Map) {
      nCtx = (meta['n_ctx'] as num?)?.toInt();
      size = (meta['size'] as num?)?.toInt();
    }
    return LMStudioModel.fromV1Json({
      'key': id,
      'type': embedding
          ? 'embedding'
          : (vision ? 'vlm' : 'llm'),
      'publisher': map['owned_by'] ?? '',
      'architecture': '',
      'format': 'gguf',
      'quantization': <String, dynamic>{},
      'capabilities': {'vision': vision},
      'display_name': friendlyLabel(id),
      'max_context_length': nCtx ?? map['max_context_length'] ?? 0,
      'size_bytes': size ?? map['size_bytes'],
      'loaded_instances': [
        {'id': '0', 'config': <String, dynamic>{}},
      ],
    });
  }

  /// llama.cpp `GET /props` → `modalities.vision`.
  static bool visionFromProps(Map<String, dynamic> props) {
    final modalities = props['modalities'];
    if (modalities is Map && modalities['vision'] == true) return true;
    return false;
  }

  /// Native LM Studio `/api/v1/models` (do **not** GET llama.cpp `/props`).
  ///
  /// Home's proxy rewrites llama-server into V1 `{key}` rows but leaves
  /// `architecture` empty and `publisher` as `llamacpp`. Those still need
  /// `/props` for vision.
  static bool isNativeLmStudioModelsPayload(Map<String, dynamic> json) {
    final v1 = json['models'];
    if (v1 is! List) return false;
    var sawKey = false;
    var looksLikeLlamaCppShim = true;
    for (final raw in v1.whereType<Map>()) {
      if (raw['key'] == null) continue;
      sawKey = true;
      final arch = raw['architecture']?.toString() ?? '';
      final publisher =
          (raw['publisher'] ?? raw['owned_by'] ?? '').toString().toLowerCase();
      final isShim =
          arch.isEmpty && (publisher.isEmpty || publisher == 'llamacpp');
      if (!isShim) looksLikeLlamaCppShim = false;
    }
    return sawKey && !looksLikeLlamaCppShim;
  }

  LMStudioModel withVision([bool enabled = true]) {
    if (supportsVision == enabled) return this;
    return LMStudioModel(
      id: id,
      object: object,
      type: enabled ? 'vlm' : (type == 'vlm' ? 'llm' : type),
      publisher: publisher,
      arch: arch,
      compatibilityType: compatibilityType,
      quantization: quantization,
      state: state,
      maxContextLength: maxContextLength,
      loadedContextLength: loadedContextLength,
      sizeBytes: sizeBytes,
      paramsString: paramsString,
      capabilities: [
        ...?capabilities?.where((c) => c != 'vision'),
        if (enabled) 'vision',
      ],
      v1DisplayName: v1DisplayName,
      format: format,
      description: description,
      bitsPerWeight: bitsPerWeight,
      visionCapability: enabled,
      toolUseCapability: toolUseCapability,
      evalBatchSize: evalBatchSize,
      flashAttention: flashAttention,
      loadedNumExperts: loadedNumExperts,
      offloadKvCacheToGpu: offloadKvCacheToGpu,
      loadedParallel: loadedParallel,
      loadedInstanceId: loadedInstanceId,
      reasoningAllowedOptions: reasoningAllowedOptions,
    );
  }

  Map<String, dynamic> toJson() => _$LMStudioModelToJson(this);

  // Helper methods
  bool get isLoaded => state == 'loaded';
  bool get isLLM => type == 'llm' && !isEmbedding;
  bool get isEmbedding {
    final t = type.toLowerCase();
    if (t == 'embedding' || t == 'embeddings') return true;
    if (capabilities?.any((c) {
          final n = c.toLowerCase();
          return n == 'embedding' || n == 'embeddings';
        }) ==
        true) {
      return true;
    }
    return looksLikeEmbeddingModel(id, v1DisplayName);
  }
  bool get isVLM => visionCapability == true || type == 'vlm';
  bool get supportsVision => visionCapability == true || type == 'vlm';
  bool get supportsTools =>
      toolUseCapability == true ||
      (capabilities?.contains('tool_use') ?? false);

  /// Reasoning / thinking models (Ollama `thinking`, or mapped capability tags).
  /// LM Studio often omits this from `/models` — see [ReasoningSupportService].
  bool get isReasoningModel =>
      (reasoningAllowedOptions?.isNotEmpty ?? false) ||
      capabilities?.contains('thinking') == true ||
      capabilities?.contains('reasoning') == true;

  /// Embedding / retrieval models (not for chat).
  ///
  /// LM Studio V1 reports `type: embedding`. Ollama, OpenAI-compat, and
  /// llama.cpp often omit that, so we also match well-known embedding names.
  static bool looksLikeEmbeddingModel(String modelId, [String? displayName]) {
    final s = '$modelId ${displayName ?? ''}'.toLowerCase();
    if (s.contains('embed')) return true;
    const families = [
      'all-minilm',
      'all-mpnet',
      'bge-m3',
      'bge-large',
      'bge-small',
      'bge-base',
      'bge-micro',
      'gte-large',
      'gte-small',
      'gte-base',
      'gte-qwen',
      'gte-modernbert',
      'multilingual-e5',
      'e5-large',
      'e5-small',
      'e5-base',
      'e5-mistral',
    ];
    if (families.any(s.contains)) return true;
    return RegExp(r'(^|[^a-z0-9])(bge|gte)[-_.]').hasMatch(s);
  }

  /// Drop embedding / retrieval ids from a chat-model picker list.
  static List<String> chatModelIds(Iterable<String> ids) =>
      ids.where((id) => !looksLikeEmbeddingModel(id)).toList();

  /// Prefer API display name; path-style llama-server ids show as basename.
  String get displayName => friendlyLabel(v1DisplayName ?? id);

  /// Short label for UI. Keeps provider/model ids like `openai/gpt-4o`;
  /// only basenames absolute filesystem paths from llama-server `--model`.
  static String friendlyLabel(String name) {
    var label = name.trim();
    if (label.startsWith('models/')) label = label.substring(7);
    final isFsPath = label.startsWith('/') ||
        label.contains('\\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(label);
    if (isFsPath) {
      final parts = label.split(RegExp(r'[/\\]')).where((p) => p.isNotEmpty);
      if (parts.isNotEmpty) return parts.last;
    }
    return label;
  }

  String get statusDisplay => isLoaded ? 'Loaded' : 'Available';

  String get quantizationDisplay {
    if (quantization.isEmpty || quantization == 'unknown') return '';
    if (bitsPerWeight != null) {
      return '$quantization (${bitsPerWeight!.toStringAsFixed(0)}bpw)';
    }
    return quantization;
  }

  String get formattedSize {
    if (sizeBytes == null) return 'Unknown';
    final bytes = sizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

@JsonSerializable()
class LMStudioModelsResponse {
  final String object;
  final List<LMStudioModel> data;

  LMStudioModelsResponse({
    required this.object,
    required this.data,
  });

  factory LMStudioModelsResponse.fromJson(Map<String, dynamic> json) =>
      _$LMStudioModelsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LMStudioModelsResponseToJson(this);
}
