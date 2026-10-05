/// A participant in a group chat — links a persona/system prompt to a model.
class GroupChatParticipant {
  final String id;
  final String
      modelId; // Model identifier (LM Studio id, on-device catalog id, or cloud model id)
  final String displayName; // User-assigned name (e.g. "Professor", "Coder")
  final String? systemPrompt; // Persona-specific system prompt text
  final String? personaId; // Reference to a saved SystemPrompt/persona ID
  final String? avatarPath; // Custom avatar image path
  final int? color; // Accent color for visual distinction (ARGB int)
  final int order; // Turn order for round-robin mode
  final bool enableToolUse; // Per-participant tool toggle
  final String?
      lastResponseId; // Stateful session ID for this participant's model
  /// Which backend should handle this participant's reply. One of:
  ///   - `null`           → legacy; infer at send time, then persist
  ///   - `'lmStudio'`     → LM Studio / Ollama / OpenAI-compatible local server
  ///   - `'lmMiniDesktop'`→ LM Mini Home desktop sidecar
  ///   - `'onDeviceGguf'` → on-device fllama GGUF inference
  ///   - `'onDeviceMlx'`  → on-device MLX inference
  ///   - `'cloud'`        → a configured `CloudApiProvider` (premium)
  ///   - `'omlx'` / `'ollama'` / `'appleIntelligence'`
  final String? providerKind;

  /// When [providerKind] is `'cloud'`, the id of the configured
  /// `CloudApiProvider` to use for this participant. Ignored otherwise.
  final String? cloudProviderId;

  /// Kokoro TTS speaker ID (0–10). Null = fall back to persona / global.
  final int? kokoroSpeakerId;

  /// Kokoro speech speed (0.5–2.0). Null = fall back to persona / global.
  final double? kokoroSpeed;

  /// ElevenLabs `voice_id`. Null = fall back to persona / global.
  final String? elevenLabsVoiceId;

  /// Grok TTS `voice_id`. Null = fall back to persona / global.
  final String? grokVoiceId;

  GroupChatParticipant({
    required this.id,
    required this.modelId,
    required this.displayName,
    this.systemPrompt,
    this.personaId,
    this.avatarPath,
    this.color,
    this.order = 0,
    this.enableToolUse = false,
    this.lastResponseId,
    this.providerKind,
    this.cloudProviderId,
    this.kokoroSpeakerId,
    this.kokoroSpeed,
    this.elevenLabsVoiceId,
    this.grokVoiceId,
  });

  GroupChatParticipant copyWith({
    String? id,
    String? modelId,
    String? displayName,
    String? systemPrompt,
    bool clearSystemPrompt = false,
    String? personaId,
    bool clearPersonaId = false,
    String? avatarPath,
    bool clearAvatar = false,
    int? color,
    bool clearColor = false,
    int? order,
    bool? enableToolUse,
    String? lastResponseId,
    bool clearLastResponseId = false,
    String? providerKind,
    bool clearProviderKind = false,
    String? cloudProviderId,
    bool clearCloudProviderId = false,
    int? kokoroSpeakerId,
    bool clearKokoroSpeaker = false,
    double? kokoroSpeed,
    bool clearKokoroSpeed = false,
    String? elevenLabsVoiceId,
    bool clearElevenLabsVoice = false,
    String? grokVoiceId,
    bool clearGrokVoice = false,
  }) {
    return GroupChatParticipant(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      displayName: displayName ?? this.displayName,
      systemPrompt:
          clearSystemPrompt ? null : (systemPrompt ?? this.systemPrompt),
      personaId: clearPersonaId ? null : (personaId ?? this.personaId),
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      color: clearColor ? null : (color ?? this.color),
      order: order ?? this.order,
      enableToolUse: enableToolUse ?? this.enableToolUse,
      lastResponseId:
          clearLastResponseId ? null : (lastResponseId ?? this.lastResponseId),
      providerKind:
          clearProviderKind ? null : (providerKind ?? this.providerKind),
      cloudProviderId: clearCloudProviderId
          ? null
          : (cloudProviderId ?? this.cloudProviderId),
      kokoroSpeakerId:
          clearKokoroSpeaker ? null : (kokoroSpeakerId ?? this.kokoroSpeakerId),
      kokoroSpeed: clearKokoroSpeed ? null : (kokoroSpeed ?? this.kokoroSpeed),
      elevenLabsVoiceId: clearElevenLabsVoice
          ? null
          : (elevenLabsVoiceId ?? this.elevenLabsVoiceId),
      grokVoiceId: clearGrokVoice ? null : (grokVoiceId ?? this.grokVoiceId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelId': modelId,
        'displayName': displayName,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        if (personaId != null) 'personaId': personaId,
        if (avatarPath != null) 'avatarPath': avatarPath,
        if (color != null) 'color': color,
        'order': order,
        'enableToolUse': enableToolUse,
        if (lastResponseId != null) 'lastResponseId': lastResponseId,
        if (providerKind != null) 'providerKind': providerKind,
        if (cloudProviderId != null) 'cloudProviderId': cloudProviderId,
        if (kokoroSpeakerId != null) 'kokoroSpeakerId': kokoroSpeakerId,
        if (kokoroSpeed != null) 'kokoroSpeed': kokoroSpeed,
        if (elevenLabsVoiceId != null) 'elevenLabsVoiceId': elevenLabsVoiceId,
        if (grokVoiceId != null) 'grokVoiceId': grokVoiceId,
      };

  factory GroupChatParticipant.fromJson(Map<String, dynamic> json) {
    return GroupChatParticipant(
      id: json['id'] as String,
      modelId: json['modelId'] as String,
      displayName: json['displayName'] as String,
      systemPrompt: json['systemPrompt'] as String?,
      personaId: json['personaId'] as String?,
      avatarPath: json['avatarPath'] as String?,
      color: _parseArgb(json['color']),
      order: (json['order'] as num?)?.toInt() ?? 0,
      enableToolUse: json['enableToolUse'] as bool? ?? false,
      lastResponseId: json['lastResponseId'] as String?,
      providerKind: json['providerKind'] as String?,
      cloudProviderId: json['cloudProviderId'] as String?,
      kokoroSpeakerId: (json['kokoroSpeakerId'] as num?)?.toInt(),
      kokoroSpeed: (json['kokoroSpeed'] as num?)?.toDouble(),
      elevenLabsVoiceId: json['elevenLabsVoiceId'] as String?,
      grokVoiceId: json['grokVoiceId'] as String?,
    );
  }

  static int? _parseArgb(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  /// Short model name for display (removes path prefix)
  String get shortModelName => modelId.split('/').last;
}
