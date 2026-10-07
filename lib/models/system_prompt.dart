import 'package:lm_mini_premium/lm_mini_premium.dart';

import 'param_preset.dart';

/// A saved system prompt that can be reused across chats.
/// When persona fields (avatarPath, color, defaultModelId) are set,
/// it acts as a full "Persona" for group chat use.
class SystemPrompt {
  static const Object _unset = Object();
  final String id;
  final String name;
  final String content;
  final List<String>?
      boundModelIds; // Models this prompt is associated with (null = all models)
  final DateTime createdAt;
  final DateTime updatedAt;

  // Persona fields (optional — upgrades a system prompt into a persona)
  final String? avatarPath; // Custom avatar image path
  /// Face focus for circular bubble avatars (−1…1). Null → slight upper bias.
  final double? avatarFocusX;
  final double? avatarFocusY;

  /// Zoom into face for bubble crop (≥1). Null → 1.0.
  final double? avatarFocusScale;

  /// Cached glass-frame colors from the avatar (ARGB). Avoids re-scanning on open.
  final int? palettePrimary;
  final int? paletteSecondary;
  final int? color; // Accent color for chat bubble border/name (as ARGB int)
  final String?
      defaultModelId; // Preferred model id for this persona (within defaultProviderKind)
  /// Provider this persona prefers. One of:
  ///   - `null`  → not bound; uses the chat's active provider
  ///   - `'lmStudio'`
  ///   - `'onDeviceGguf'`
  ///   - `'onDeviceMlx'`
  ///   - `'cloud'`  (requires [defaultCloudProviderId])
  /// Apple Intelligence is currently unsupported as a persona binding.
  final String? defaultProviderKind;

  /// When [defaultProviderKind] is `'cloud'`, the id of the configured
  /// `CloudApiProvider` to use. Ignored otherwise.
  final String? defaultCloudProviderId;
  final int?
      imageGenSeed; // Per-persona seed for A1111 image gen (-1 = random, null = use global)
  /// ComfyUI saved-workflow path for this persona. Null = use global
  /// [AppSettings.comfyUiWorkflowPath] / JSON / default. Ignored when the
  /// active image provider is not ComfyUI.
  final String? comfyUiWorkflowPath;

  /// Optional ComfyUI API-format workflow JSON for this persona.
  /// Used when [comfyUiWorkflowPath] is null/empty. Null = use global
  /// [AppSettings.comfyUiWorkflowJson] / default.
  final String? comfyUiWorkflowJson;

  /// Kokoro TTS speaker ID (0–10). Null = use the global voice setting.
  final int? kokoroSpeakerId;

  /// Kokoro speech speed (0.5–2.0). Null = use the global speed setting.
  final double? kokoroSpeed;

  /// ElevenLabs `voice_id` from the user's library. Null = global ElevenLabs voice.
  final String? elevenLabsVoiceId;

  /// Grok TTS `voice_id`. Null = global Grok voice.
  final String? grokVoiceId;

  /// When false, memory is neither injected nor extracted while this persona
  /// is active (1:1 and group chat). Defaults to true for existing personas.
  final bool shareMemories;

  /// Memory categories this persona may receive when [shareMemories] is true.
  /// Keys match Memory screen categories: personal, preference, technical,
  /// work, general.
  ///
  /// `null` ⇒ all categories (backward compatible default).
  /// Non-empty ⇒ only those categories are injected.
  /// Empty ⇒ share is on but no categories selected (injects nothing).
  final List<String>? sharedMemoryCategories;

  /// Where memories learned during this persona's chats are filed.
  ///
  /// - [MemoryScope.global] — normal assistant behaviour, facts go to the
  ///   shared pool every chat can see.
  /// - [MemoryScope.private] — facts about the user that only this persona
  ///   should know (a therapist or journal persona).
  /// - [MemoryScope.lore] — roleplay continuity notes about the story, kept
  ///   out of every other chat and never presented as facts about the user.
  final MemoryScope memoryWriteScope;

  /// When true (Pro), [customParams] overlay model/global params whenever
  /// this persona is active. Off keeps the snapshot so toggling back restores it.
  final bool useCustomParams;

  /// Optional full Model Parameters snapshot for this persona.
  final ParamPreset? customParams;

  /// Assistant message posted when a new chat starts with this persona
  /// (SillyTavern `first_mes`). Null = the chat starts empty.
  final String? greeting;

  /// Other opening messages from an imported character card. One is picked
  /// at random alongside [greeting] when a chat starts.
  final List<String>? alternateGreetings;

  /// Expression sprites: emotion label (see `kExpressionLabels`) → image
  /// path relative to the app documents directory.
  final Map<String, String>? expressionSprites;

  SystemPrompt({
    required this.id,
    required this.name,
    required this.content,
    this.boundModelIds,
    required this.createdAt,
    required this.updatedAt,
    this.avatarPath,
    this.avatarFocusX,
    this.avatarFocusY,
    this.avatarFocusScale,
    this.palettePrimary,
    this.paletteSecondary,
    this.color,
    this.defaultModelId,
    this.defaultProviderKind,
    this.defaultCloudProviderId,
    this.imageGenSeed,
    this.comfyUiWorkflowPath,
    this.comfyUiWorkflowJson,
    this.kokoroSpeakerId,
    this.kokoroSpeed,
    this.elevenLabsVoiceId,
    this.grokVoiceId,
    this.shareMemories = true,
    this.sharedMemoryCategories,
    this.memoryWriteScope = MemoryScope.global,
    this.useCustomParams = false,
    this.customParams,
    this.greeting,
    this.alternateGreetings,
    this.expressionSprites,
  });

  /// Whether this persona has at least one expression sprite.
  bool get hasExpressionSprites =>
      expressionSprites != null && expressionSprites!.isNotEmpty;

  /// Whether this system prompt has persona fields configured
  bool get isPersona =>
      avatarPath != null ||
      color != null ||
      defaultModelId != null ||
      defaultProviderKind != null ||
      kokoroSpeakerId != null ||
      kokoroSpeed != null ||
      elevenLabsVoiceId != null ||
      grokVoiceId != null ||
      greeting != null ||
      hasExpressionSprites;

  SystemPrompt copyWith({
    String? id,
    String? name,
    String? content,
    List<String>? boundModelIds,
    bool clearBoundModels = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarPath,
    bool clearAvatar = false,
    double? avatarFocusX,
    double? avatarFocusY,
    double? avatarFocusScale,
    bool clearAvatarFocus = false,
    int? palettePrimary,
    int? paletteSecondary,
    bool clearPalette = false,
    int? color,
    bool clearColor = false,
    String? defaultModelId,
    bool clearDefaultModel = false,
    String? defaultProviderKind,
    bool clearDefaultProvider = false,
    String? defaultCloudProviderId,
    bool clearDefaultCloudProvider = false,
    int? imageGenSeed,
    bool clearImageGenSeed = false,
    String? comfyUiWorkflowPath,
    bool clearComfyUiWorkflowPath = false,
    String? comfyUiWorkflowJson,
    bool clearComfyUiWorkflowJson = false,
    int? kokoroSpeakerId,
    bool clearKokoroSpeaker = false,
    double? kokoroSpeed,
    bool clearKokoroSpeed = false,
    String? elevenLabsVoiceId,
    bool clearElevenLabsVoice = false,
    String? grokVoiceId,
    bool clearGrokVoice = false,
    bool? shareMemories,
    List<String>? sharedMemoryCategories,
    bool clearSharedMemoryCategories = false,
    MemoryScope? memoryWriteScope,
    bool? useCustomParams,
    Object? customParams = _unset,
    bool clearCustomParams = false,
    String? greeting,
    bool clearGreeting = false,
    List<String>? alternateGreetings,
    bool clearAlternateGreetings = false,
    Map<String, String>? expressionSprites,
    bool clearExpressionSprites = false,
  }) {
    return SystemPrompt(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      boundModelIds:
          clearBoundModels ? null : (boundModelIds ?? this.boundModelIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      avatarFocusX: clearAvatar || clearAvatarFocus
          ? null
          : (avatarFocusX ?? this.avatarFocusX),
      avatarFocusY: clearAvatar || clearAvatarFocus
          ? null
          : (avatarFocusY ?? this.avatarFocusY),
      avatarFocusScale: clearAvatar || clearAvatarFocus
          ? null
          : (avatarFocusScale ?? this.avatarFocusScale),
      palettePrimary: clearAvatar || clearPalette
          ? null
          : (palettePrimary ?? this.palettePrimary),
      paletteSecondary: clearAvatar || clearPalette
          ? null
          : (paletteSecondary ?? this.paletteSecondary),
      color: clearColor ? null : (color ?? this.color),
      defaultModelId:
          clearDefaultModel ? null : (defaultModelId ?? this.defaultModelId),
      defaultProviderKind: clearDefaultProvider
          ? null
          : (defaultProviderKind ?? this.defaultProviderKind),
      defaultCloudProviderId: clearDefaultCloudProvider
          ? null
          : (defaultCloudProviderId ?? this.defaultCloudProviderId),
      imageGenSeed:
          clearImageGenSeed ? null : (imageGenSeed ?? this.imageGenSeed),
      comfyUiWorkflowPath: clearComfyUiWorkflowPath
          ? null
          : (comfyUiWorkflowPath ?? this.comfyUiWorkflowPath),
      comfyUiWorkflowJson: clearComfyUiWorkflowJson
          ? null
          : (comfyUiWorkflowJson ?? this.comfyUiWorkflowJson),
      kokoroSpeakerId:
          clearKokoroSpeaker ? null : (kokoroSpeakerId ?? this.kokoroSpeakerId),
      kokoroSpeed: clearKokoroSpeed ? null : (kokoroSpeed ?? this.kokoroSpeed),
      elevenLabsVoiceId: clearElevenLabsVoice
          ? null
          : (elevenLabsVoiceId ?? this.elevenLabsVoiceId),
      grokVoiceId: clearGrokVoice ? null : (grokVoiceId ?? this.grokVoiceId),
      shareMemories: shareMemories ?? this.shareMemories,
      sharedMemoryCategories: clearSharedMemoryCategories
          ? null
          : (sharedMemoryCategories ?? this.sharedMemoryCategories),
      memoryWriteScope: memoryWriteScope ?? this.memoryWriteScope,
      useCustomParams: useCustomParams ?? this.useCustomParams,
      customParams: clearCustomParams
          ? null
          : (identical(customParams, _unset)
              ? this.customParams
              : customParams as ParamPreset?),
      greeting: clearGreeting ? null : (greeting ?? this.greeting),
      alternateGreetings: clearAlternateGreetings
          ? null
          : (alternateGreetings ?? this.alternateGreetings),
      expressionSprites: clearExpressionSprites
          ? null
          : (expressionSprites ?? this.expressionSprites),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'boundModelIds': boundModelIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (avatarPath != null) 'avatarPath': avatarPath,
        if (avatarFocusX != null) 'avatarFocusX': avatarFocusX,
        if (avatarFocusY != null) 'avatarFocusY': avatarFocusY,
        if (avatarFocusScale != null) 'avatarFocusScale': avatarFocusScale,
        if (palettePrimary != null) 'palettePrimary': palettePrimary,
        if (paletteSecondary != null) 'paletteSecondary': paletteSecondary,
        if (color != null) 'color': color,
        if (defaultModelId != null) 'defaultModelId': defaultModelId,
        if (defaultProviderKind != null)
          'defaultProviderKind': defaultProviderKind,
        if (defaultCloudProviderId != null)
          'defaultCloudProviderId': defaultCloudProviderId,
        if (imageGenSeed != null) 'imageGenSeed': imageGenSeed,
        if (comfyUiWorkflowPath != null && comfyUiWorkflowPath!.isNotEmpty)
          'comfyUiWorkflowPath': comfyUiWorkflowPath,
        if (comfyUiWorkflowJson != null && comfyUiWorkflowJson!.isNotEmpty)
          'comfyUiWorkflowJson': comfyUiWorkflowJson,
        if (kokoroSpeakerId != null) 'kokoroSpeakerId': kokoroSpeakerId,
        if (kokoroSpeed != null) 'kokoroSpeed': kokoroSpeed,
        if (elevenLabsVoiceId != null) 'elevenLabsVoiceId': elevenLabsVoiceId,
        if (grokVoiceId != null) 'grokVoiceId': grokVoiceId,
        'shareMemories': shareMemories,
        if (sharedMemoryCategories != null)
          'sharedMemoryCategories': sharedMemoryCategories,
        'memoryWriteScope': memoryWriteScope.name,
        'useCustomParams': useCustomParams,
        if (customParams != null) 'customParams': customParams!.toJson(),
        if (greeting != null && greeting!.isNotEmpty) 'greeting': greeting,
        if (alternateGreetings != null && alternateGreetings!.isNotEmpty)
          'alternateGreetings': alternateGreetings,
        if (hasExpressionSprites) 'expressionSprites': expressionSprites,
      };

  factory SystemPrompt.fromJson(Map<String, dynamic> json) => SystemPrompt(
        id: json['id'] as String,
        name: json['name'] as String,
        content: json['content'] as String,
        boundModelIds: (json['boundModelIds'] as List?)?.cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        avatarPath: json['avatarPath'] as String?,
        avatarFocusX: (json['avatarFocusX'] as num?)?.toDouble(),
        avatarFocusY: (json['avatarFocusY'] as num?)?.toDouble(),
        avatarFocusScale: (json['avatarFocusScale'] as num?)?.toDouble(),
        palettePrimary: _parseArgb(json['palettePrimary']),
        paletteSecondary: _parseArgb(json['paletteSecondary']),
        color: _parseArgb(json['color']),
        defaultModelId: json['defaultModelId'] as String?,
        defaultProviderKind: json['defaultProviderKind'] as String?,
        defaultCloudProviderId: json['defaultCloudProviderId'] as String?,
        imageGenSeed: (json['imageGenSeed'] as num?)?.toInt(),
        comfyUiWorkflowPath: _nonEmptyString(json['comfyUiWorkflowPath']),
        comfyUiWorkflowJson: _nonEmptyString(json['comfyUiWorkflowJson']),
        kokoroSpeakerId: (json['kokoroSpeakerId'] as num?)?.toInt(),
        kokoroSpeed: (json['kokoroSpeed'] as num?)?.toDouble(),
        elevenLabsVoiceId: _nonEmptyString(json['elevenLabsVoiceId']),
        grokVoiceId: _nonEmptyString(json['grokVoiceId']),
        shareMemories: json['shareMemories'] as bool? ?? true,
        sharedMemoryCategories:
            (json['sharedMemoryCategories'] as List?)?.cast<String>(),
        memoryWriteScope: memoryScopeFromWire(json['memoryWriteScope']),
        useCustomParams: json['useCustomParams'] as bool? ?? false,
        customParams: _parseCustomParams(json['customParams']),
        greeting: _nonEmptyString(json['greeting']),
        alternateGreetings: (json['alternateGreetings'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
        expressionSprites: _parseSprites(json['expressionSprites']),
      );

  static Map<String, String>? _parseSprites(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, String>{};
    raw.forEach((k, v) {
      final key = k.toString().trim();
      final path = v?.toString().trim() ?? '';
      if (key.isNotEmpty && path.isNotEmpty) out[key] = path;
    });
    return out.isEmpty ? null : out;
  }

  static ParamPreset? _parseCustomParams(dynamic raw) {
    if (raw is! Map) return null;
    return ParamPreset.fromJson(Map<String, dynamic>.from(raw));
  }

  static int? _parseArgb(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  static String? _nonEmptyString(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Check if this prompt is bound to a specific model
  bool isBoundToModel(String modelId) {
    if (boundModelIds == null || boundModelIds!.isEmpty) {
      return true; // Unbound = available for all
    }
    return boundModelIds!.contains(modelId);
  }

  /// Get display text for bound models
  String get boundModelsDisplay {
    if (boundModelIds == null || boundModelIds!.isEmpty) return 'All models';
    if (boundModelIds!.length == 1) return boundModelIds!.first.split('/').last;
    return '${boundModelIds!.length} models';
  }
}
