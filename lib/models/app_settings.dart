import 'package:flutter/material.dart';
import 'param_preset.dart';
import 'system_prompt.dart';
import '../utils/relay_url.dart';

/// Reads a non-nullable list field safely. After hot reload, newly added list
/// fields on existing [AppSettings] instances can be null at runtime.
List<String> _readStringList(List<String> Function() read) {
  try {
    return read();
  } on TypeError {
    return const [];
  }
}

String _readString(String Function() read, String fallback) {
  try {
    return read();
  } on TypeError {
    return fallback;
  }
}

List<Map<String, dynamic>> _parseComfyWorkflowFields(Object? raw) {
  if (raw is! List) return const [];
  final fields = <Map<String, dynamic>>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final name = entry['name']?.toString() ?? '';
    final nodeId = entry['nodeId']?.toString() ?? '';
    if (name.isEmpty || nodeId.isEmpty) continue;
    final value = entry['value'];
    if (value == null || value is List || value is Map) continue;
    fields.add({
      'nodeId': nodeId,
      'classType': entry['classType']?.toString() ?? '',
      'name': name,
      'value': value,
    });
  }
  return fields;
}

Map<String, String> _readStringMap(Map<String, String> Function() read) {
  try {
    return read();
  } on TypeError {
    return const {};
  }
}

Map<String, String> _parseStringMap(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.value != null) entry.key.toString(): entry.value.toString(),
  };
}

Map<String, ParamPreset> _readParamPresetMap(
    Map<String, ParamPreset> Function() read) {
  try {
    return read();
  } on TypeError {
    return const {};
  }
}

Map<String, ParamPreset> _parseParamPresetMap(dynamic value) {
  if (value is! Map) return const {};
  final out = <String, ParamPreset>{};
  for (final entry in value.entries) {
    final raw = entry.value;
    if (raw is Map) {
      out[entry.key.toString()] =
          ParamPreset.fromJson(Map<String, dynamic>.from(raw));
    }
  }
  return out;
}

/// Configuration for an Ephemeral MCP server (defined per-request via HTTP URL)
class McpServerConfig {
  final String label;
  final String url;
  final String?
      authorization; // Authorization header value (e.g., "Bearer token")
  final Map<String, String>? headers; // Additional custom headers

  McpServerConfig({
    required this.label,
    required this.url,
    this.authorization,
    this.headers,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
        if (authorization != null) 'authorization': authorization,
        if (headers != null) 'headers': headers,
      };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) =>
      McpServerConfig(
        label: json['label'] as String,
        url: json['url'] as String,
        authorization: json['authorization'] as String?,
        headers:
            (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
      );

  /// Convert to LM Studio v1 API format for /api/v1/chat integrations array
  /// Uses ephemeral_mcp type for per-request MCP servers
  Map<String, dynamic> toApiFormat() {
    // Build headers map with Authorization if specified
    Map<String, String>? apiHeaders;
    if (authorization != null || (headers != null && headers!.isNotEmpty)) {
      apiHeaders = {};
      if (authorization != null && authorization!.isNotEmpty) {
        apiHeaders['Authorization'] = authorization!;
      }
      if (headers != null) {
        apiHeaders.addAll(headers!);
      }
    }

    return {
      'type': 'ephemeral_mcp',
      'server_label': label,
      'server_url': url,
      if (apiHeaders != null && apiHeaders.isNotEmpty) 'headers': apiHeaders,
    };
  }

  /// Check if this MCP server has authentication configured
  bool get hasAuthentication =>
      authorization != null && authorization!.isNotEmpty;

  /// Get a display string for authentication status
  String get authDisplayText {
    if (authorization == null || authorization!.isEmpty) return 'No auth';
    if (authorization!.startsWith('Bearer ')) return 'Bearer token';
    return 'Auth configured';
  }
}

/// Configuration for an Integrated MCP (configured in LM Studio's mcp.json)
/// These are referenced by name like "mcp/playwright" in the integrations array
class IntegratedMcpConfig {
  final String name; // Name from LM Studio's mcp.json (e.g., "playwright")
  final bool enabled;

  IntegratedMcpConfig({
    required this.name,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'enabled': enabled,
      };

  factory IntegratedMcpConfig.fromJson(Map<String, dynamic> json) =>
      IntegratedMcpConfig(
        name: json['name'] as String,
        enabled: json['enabled'] as bool? ?? true,
      );

  IntegratedMcpConfig copyWith({
    String? name,
    bool? enabled,
  }) {
    return IntegratedMcpConfig(
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Convert to LM Studio v1 API format for integrations array
  /// Per docs: {"type": "plugin", "id": "mcp/<name>"}
  /// String shorthand "mcp/<name>" is also valid but object form is explicit
  Map<String, dynamic> toApiFormat() => {
        'type': 'plugin',
        'id': 'mcp/$name',
      };
}

class AppSettings {
  static const Object _unset = Object();
  final String serverUrl;
  final String? apiToken; // LM Studio API token for authentication (optional)

  /// Optional Cloudflare Access service-token Client ID. When set, sent as the
  /// `CF-Access-Client-Id` header on every LM Studio request so the request
  /// passes through a Cloudflare Access policy without interactive SSO.
  final String? cfAccessClientId;

  /// Optional Cloudflare Access service-token Client Secret. Sent as the
  /// `CF-Access-Client-Secret` header alongside [cfAccessClientId].
  final String? cfAccessClientSecret;

  /// Arbitrary custom HTTP headers added to every LM Studio request.
  /// Keys are header names, values are header values. Null/empty means none.
  /// Useful for reverse proxies or auth gateways that require additional
  /// headers (e.g. an internal service token, a Bearer-like header under a
  /// custom name, etc.).
  final Map<String, String>? customRequestHeaders;

  /// Master switch for [customRequestHeaders]. When false, no extra headers
  /// are attached even if the map is populated — lets users keep their
  /// configured headers around without sending them.
  final bool customHeadersEnabled;
  final String? selectedModel;

  /// Last chosen chat model per server slot (`remote:lmMiniDesktop`,
  /// `local:http://localhost:1234`, …). [selectedModel] is the active slot.
  final Map<String, String> selectedModelByServer;
  final double temperature;
  final int maxTokens;
  final int contextWindow;
  final String systemPrompt;
  final double topP;
  final int topK;
  final double minP; // New v1 API parameter
  final double repeatPenalty; // v1 API repeat penalty
  final double frequencyPenalty; // OpenAI-style frequency penalty (-2 to 2)
  final double presencePenalty; // OpenAI-style presence penalty (-2 to 2)
  final String reasoning; // "off", "low", "medium", "high", "on"
  /// Whether reasoning/thinking is enabled (API + UI). Per-chat override sets
  /// [reasoning] to `"off"` via [ChatProvider.getEffectiveSettings].
  bool get isReasoningEnabled => reasoning != 'off';

  /// OpenAI GPT-5 `verbosity`: "low", "medium", "high".
  final String verbosity;

  /// When there is no `previous_response_id`, how to fit history into
  /// ~90% of loaded context: `off` | `roll` | `cutMiddle`.
  final String contextFitMode;

  /// Chat + LM Studio load context (kept equal via [SettingsProvider.updateContextWindow]).
  int get effectiveContextWindow => contextWindow;

  final ThemeMode themeMode;

  // Load model config parameters
  final int? loadContextLength; // Override context length when loading model
  final int? loadEvalBatchSize; // Batch size for evaluation
  final bool loadFlashAttention; // Enable flash attention
  final int? loadNumExperts; // Number of experts for MoE models
  final bool loadOffloadKvCache; // Offload KV cache to GPU

  /// Shrink photos that would exceed a local server's physical batch.
  final bool resizeImageForPhysicalBatch;

  /// Model IDs for which the user chose to keep LM Studio's loaded instance
  /// params instead of LM Mini's Model Loading Config.
  final List<String> modelsPreferLoadedParams;

  /// Pro-only per-model generation/load snapshots. Keyed by [ParamPresetKey].
  /// Models without an entry use the Global knobs on this [AppSettings].
  final Map<String, ParamPreset> modelParamPresets;
  final String? userAvatarPath;
  final String? assistantAvatarPath;
  final String? chatBackgroundPath;

  /// Global wallpaper dim (0–100). Per-chat override may replace this.
  final double chatBackgroundOverlayOpacity;

  /// Frosted [BackdropFilter] blur on glass chrome. Off keeps translucent fills.
  final bool glassEffectsEnabled;

  /// Cooler / cheaper UI: no glass blur, plain text while streaming,
  /// Home/iCloud sync only after the reply finishes. Screen stay-awake during
  /// generation is unchanged — without it iOS (no Live Activity) and Android
  /// HTTP streams truncate when the display sleeps.
  final bool lowBatteryMode;

  /// Glass blur actually drawn. Low battery mode always skips GPU blur.
  bool get glassEffectsActive => glassEffectsEnabled && !lowBatteryMode;

  // Advanced features
  final bool showRuntimeInfo;
  final String? selectedEmbeddingModel;
  final bool enableSemanticSearch;
  final bool useStructuredOutput;
  final String? responseFormat; // 'json_object' or null for regular text
  final bool enableToolUse; // Enable tool calling (uses OpenAI-compatible API)
  final bool
      enableWebSearch; // Enable web search tool (can be toggled independently)
  final bool
      useMcpToolsOnly; // Use LM Studio MCP tools only (don't send local tool definitions)
  final List<McpServerConfig>? mcpServers; // Ephemeral MCP servers (HTTP URLs)
  final List<String>?
      activeMcpServerLabels; // Which ephemeral MCP servers are currently enabled (by label)
  final List<IntegratedMcpConfig>?
      integratedMcps; // Integrated MCPs (from LM Studio's mcp.json)
  final String?
      searxngUrl; // SearXNG instance URL for better web search (e.g., http://localhost:8888)
  final bool
      preferSearxng; // When true, SearXNG wins over Pro Search even for premium users
  /// Premium Code Sandbox (run_code MCP) — Python / JavaScript on the hosted Pro service.
  final bool enableCodeSandbox;
  final List<String>
      pinnedModels; // Model IDs the user has pinned/favorited; sorted to top of model list
  final int searchResultsCount; // Number of search results to return (2-10)
  final bool
      unlimitedToolCalls; // Remove tool call iteration limit for Integrated/Ephemeral MCPs (not Pro Search)
  final int?
      autoUnloadTtlMinutes; // Auto-unload model after idle time (null = LM Studio default)
  final bool
      useV1Api; // Use LM Studio v1 API (/api/v1/chat) with MCP integrations support

  // UI preferences
  final bool
      showFoldersView; // Remember if user prefers folders view or conversations view
  final bool hideAvatars; // Hide avatars in chat for more width
  final bool autoScrollEnabled; // Auto-scroll chat during streaming
  /// Empty-chat scrolling prompt pills (Chat Files / Images cards stay visible).
  final bool showChatStarters;

  /// When true, use the classic compact message input instead of the shine composer.
  final bool useLegacyComposer;
  final double chatFontSize; // Chat message font size (10-24)
  final double chatIconSize; // Chat action icon size (10-24)
  final String selectedThemeId; // Selected app theme ID
  /// Visual variant of the launcher icon the user has chosen. Drives both
  /// the iOS alternate-icon hint and the in-app splash background:
  ///   - `'default'` — lavender / indigo (matches `Icon-App-Light-1024.png`)
  ///   - `'dark'`    — near-black gradient (matches `Icon-App-Dark-1024.png`)
  ///   - `'glass'`   — tinted / translucent (matches `Icon-App-Tinted-1024.png`)
  /// The actual home-screen icon is selected by iOS via the AppIcon set's
  /// `appearances` entries; we just mirror that choice inside the app so the
  /// splash screen, About card, etc. feel coherent.
  final String iconTheme;
  final bool showChatHeaderAvatar; // Show avatar in chat app bar
  final double chatBubbleAvatarRadius; // Chat bubble avatar radius (14-32)
  final bool
      avatarAboveMessage; // Show avatar above message bubble instead of beside it
  /// User stays in a bubble; assistant text is full-width, with no card behind it.
  final bool fullWidthAssistant;

  /// One-time "try full-width" prompt for people who still have bubbles.
  final bool fullWidthAssistantNudgeShown;

  /// Persona row on the Apple Watch home screen.
  final bool watchShowPersonas;

  /// Assistant replies on the watch sit in a bubble. Off lets them run full width.
  final bool watchAssistantInBubble;

  // System prompt management
  final List<SystemPrompt>?
      savedSystemPrompts; // User's saved system prompts library
  final String?
      selectedSystemPromptId; // Currently active system prompt ID (null = use inline systemPrompt)

  // Localization
  final String? locale; // User's preferred locale code (null = system default)

  // Voice settings
  final bool voiceAutoRead; // Auto-read assistant responses aloud
  final double voiceSpeechRate; // TTS speech rate (0.0 - 1.0)
  final double voicePitch; // TTS pitch (0.5 - 2.0)
  final String? voiceName; // Selected TTS voice name
  final String voiceLanguage; // TTS language (e.g., 'en-US')
  /// Speech recognition language for text mic + Voice Call (e.g. 'en-US').
  /// Independent of [voiceLanguage] so TTS can stay in another language.
  final String voiceSttLanguage;
  final bool voiceAutoSend; // Auto-send after speech recognition completes
  final int voiceSttPauseForSeconds; // Silence before STT finalizes (seconds)
  final int voiceSttListenForSeconds; // Max listening duration (seconds)
  final String voiceSttProvider; // 'system' or 'whisper'
  /// Selected sherpa-onnx Whisper size: tiny | base | small | medium | turbo | large-v3
  final String whisperModelId;
  final bool
      voiceContinuousConversation; // Auto-listen after TTS finishes in voice mode
  final String
      voiceTtsProvider; // 'native' | 'kokoro' | 'kokoro_remote' | 'elevenlabs' | 'grok'
  final int voiceKokoroSpeakerId; // Speaker ID for Kokoro TTS (0-10)
  final double voiceKokoroSpeed; // Kokoro TTS speed (0.5-2.0)
  /// User's ElevenLabs xi-api-key (BYOK, stored locally).
  final String? voiceElevenLabsApiKey;

  /// Selected ElevenLabs voice_id from the user's library.
  final String? voiceElevenLabsVoiceId;

  /// ElevenLabs TTS model. Default: eleven_v3_conversational.
  final String voiceElevenLabsModelId;

  /// User's xAI API key for Grok TTS (BYOK, stored locally).
  final String? voiceGrokApiKey;

  /// Selected Grok TTS voice_id. Default: eve.
  final String? voiceGrokVoiceId;
  final String? voiceRemoteKokoroUrl; // Remote Kokoro TTS server URL
  final String? voiceRemoteKokoroModel; // Selected model on remote PC
  final bool
      voiceCallMode; // Enable CallKit call mode for background voice chat

  // Image generation (AUTOMATIC1111 / Stable Diffusion WebUI)
  final bool imageGenEnabled; // Master toggle
  final String imageGenServerUrl; // e.g. http://192.168.1.50:7860
  final String? imageGenSelectedModel; // SD checkpoint title
  final String imageGenNegativePrompt;
  final int imageGenSteps;
  final double imageGenCfgScale;
  final int imageGenWidth;
  final int imageGenHeight;
  final String imageGenSamplerName;
  final String? imageGenScheduler;
  final int imageGenSeed; // -1 = random
  final int imageGenBatchSize;
  final bool imageGenEnableHr;
  final double imageGenHrScale;
  final String? imageGenHrUpscaler;
  final double imageGenDenoisingStrength;
  final bool imageGenRestoreFaces;
  final bool imageGenTiling;
  final bool imageGenReviewPrompt; // Show prompt to user before sending
  final bool imageGenAutoGenerate; // Auto-generate image on each response

  // Image generation — provider selection & ComfyUI support
  /// Which image-gen backend to use. Supported values: `'a1111'` (default, AUTOMATIC1111
  /// Stable Diffusion WebUI), `'comfyui'` (ComfyUI `/prompt` workflow API), or
  /// `'onDevice'` (iOS Core ML Stable Diffusion).
  final String imageGenProvider;

  /// Selected on-device Core ML checkpoint id ([LocalSdAssetSpec.id]).
  /// Used when [imageGenProvider] is `'onDevice'`.
  final String? selectedLocalSdCheckpointId;

  /// Raw ComfyUI workflow JSON (the prompt graph). When set, overrides the
  /// default built-in text-to-image workflow. Placeholder tokens inside string
  /// node inputs are substituted at request time:
  /// `%PROMPT%`, `%NEGATIVE%`, `%SEED%`, `%STEPS%`, `%CFG%`, `%WIDTH%`,
  /// `%HEIGHT%`, `%SAMPLER%`, `%SCHEDULER%`, `%CHECKPOINT%`,
  /// `%LORA%`, `%LORA_WEIGHT%`.
  final String? comfyUiWorkflowJson;

  /// Optional ComfyUI saved workflow path under the server's `workflows/`
  /// user-data folder. When set, this server-side workflow takes precedence
  /// over [comfyUiWorkflowJson] and is fetched fresh at generation time.
  ///
  /// The file may be an API-format export or a Comfy canvas save (`nodes` +
  /// `links`); Mini converts canvas saves at generation time.
  final String? comfyUiWorkflowPath;

  /// When set, a ComfyUI image run is written to this name in the workflow
  /// list. A new name is added. The same name updates that saved workflow.
  final String? comfyUiWorkflowSaveName;

  /// Optional client id used when polling ComfyUI `/history/{prompt_id}`.
  /// Generated automatically on first use if null.
  final String? comfyUiClientId;

  /// Whether to send a negative prompt when generating with ComfyUI.
  /// Defaults to `false` because many modern ComfyUI workflows (Flux, SDXL
  /// Turbo, distilled models) either ignore or actively misbehave with a
  /// non-empty negative prompt. When `false`, the negative prompt field is
  /// hidden in settings and an empty string is forwarded to the workflow.
  final bool comfyUiUseNegativePrompt;

  /// Optional LoRA filename as listed by ComfyUI (`LoraLoader.lora_name`).
  /// Substituted into API workflows as `%LORA%`. Null/empty = no LoRA selected.
  final String? comfyUiLoraName;

  /// LoRA strength substituted as `%LORA_WEIGHT%` (model + clip). Default 1.0.
  final double comfyUiLoraWeight;

  /// Workflow path whose sampler, CFG, and scheduler were copied into Image
  /// Generation. Until this matches the selected workflow, Mini still sends
  /// your steps, but leaves the graph's own sampler, scheduler, and CFG alone.
  final String? comfyUiControlsLoadedFrom;

  /// Extra scalar widgets from the loaded workflow (CLIP, VAE, shift, …).
  /// Steps, CFG, sampler, scheduler, size, seed, and the image model live in
  /// the normal Image Generation fields.
  final List<Map<String, dynamic>> comfyUiWorkflowFields;

  // Remote access (relay server via LM Mini Connect companion app)
  final String?
      remoteServerUrl; // The relay URL (e.g., https://connect.lmmini.com/s/{sessionId})
  final String? remoteAuthToken; // Shared secret from QR code pairing
  final bool isRemoteActive; // Whether remote mode is currently enabled
  final String?
      remoteLastConnected; // ISO8601 timestamp of last successful remote connection
  final String?
      savedLocalServerUrl; // Saved local server URL when switching to remote
  /// Saved Ollama/oMLX base URL when remote mode rewrites the cloud provider.
  final String? savedLocalCloudBaseUrl;
  final String?
      remoteEncryptionKey; // End-to-end encryption key for remote access
  /// Connect app semver from the last paired QR (v5+).
  final String? remoteConnectVersion;

  /// Backends advertised by the last paired Connect QR (`lmStudio`, `ollama`, `omlx`, `jan`, `unsloth`).
  final List<String> remoteBackends;

  /// When true, the app should re-enable remote mode after a transient
  /// disconnect (e.g. background health-check failures). Cleared when the
  /// user manually turns remote off or unpairs.
  final bool remoteAutoReconnect;

  /// User opted in to merge chats/folders with LM Mini Home over the relay.
  final bool homeSyncEnabled;

  /// User already answered the first-connect Home sync prompt (enable or not now).
  final bool homeSyncPrompted;

  /// Also copy selected personas (prompt, photo, memories) over Home sync.
  final bool homeSyncPersonasEnabled;

  /// Persona ids the user checked in the Home sync picker.
  final List<String> homeSyncPersonaIds;

  /// When the user last changed persona sync on/off or the checked ids.
  final DateTime? homeSyncPersonasUpdatedAt;

  // Live Activity (iOS 16.2+)
  final bool
      liveActivityEnabled; // iOS Live Activity; Android foreground notification during generation

  // Onboarding
  final bool hasCompletedOnboarding;

  /// Set during onboarding: `'beginner'` or `'power'`. Null if skipped/legacy.
  final String? aiExperienceLevel;

  /// Whether Settings shows power-user / technical options.
  ///
  /// `null` (legacy installs) and `'power'` are Advanced; only `'beginner'` is Basic.
  bool get isAdvancedSettings => aiExperienceLevel != 'beginner';

  /// Preferred name for the AI to call the user. Null if not set.
  final String? preferredUserName;

  /// How persona expression sprites appear in chat:
  /// `'off'`, `'panel'` (large sprite above the composer), `'avatar'`
  /// (message avatar shows the reply's expression) or `'both'`.
  final String expressionSpriteMode;

  /// Whether the chat sprite panel is collapsed.
  final bool spritePanelCollapsed;

  /// Expressions the model may tag replies with in this chat. Set by
  /// ChatProvider.getEffectiveSettings when the chat's persona has sprites;
  /// never saved.
  final List<String>? expressionLabels;

  bool get showsSpritePanel =>
      expressionSpriteMode == 'panel' || expressionSpriteMode == 'both';
  bool get showsSpriteAvatars =>
      expressionSpriteMode == 'avatar' || expressionSpriteMode == 'both';

  /// Whether the one-time voice/audio setup dialog has been completed.
  final bool hasCompletedAudioSetup;

  /// User has seen the Arena anonymous-benchmark consent card.
  final bool hasAcceptedArenaDataShare;

  /// When true, finished Arena runs may upload anonymized speed rows
  /// (device + model + metrics; never prompts/answers) to the public pool.
  final bool arenaShareAnonymousResults;

  // Input behavior
  /// How the physical/external keyboard's Enter/Return key behaves.
  /// - `'auto'` — send when an external/hardware keyboard is attached; newline otherwise (default)
  /// - `'send'` — Enter always sends the message, Shift+Enter inserts newline
  /// - `'newline'` — Enter always inserts a newline (send button required to send)
  ///
  /// Note: On-screen soft keyboards on mobile always insert a newline regardless
  /// of this setting; only hardware Enter keys are intercepted for the send action.
  final String enterKeyBehavior;

  /// USB Mode — when true, the app routes LM Studio traffic through the
  /// in-process USB bridge (`http://127.0.0.1:2347`) which forwards over a
  /// USB cable to LM Mini Connect on a Mac. Mutually exclusive with the
  /// remote-relay flow. Only meaningful on iOS.
  final bool usbModeEnabled;

  // ─── On-device / provider routing (Phase 1) ───────────────────────

  /// Which chat backend is currently active. Mirrors `EndpointKind` from
  /// `lib/services/llm_endpoint.dart` but stored as a string so this model
  /// doesn't pull in a service-layer dependency. Valid values:
  ///   `'lmStudio' | 'cloud' | 'omlx' | 'ollama' | 'onDeviceGguf' | 'onDeviceMlx' | 'appleIntelligence'`.
  /// Defaults to `'lmStudio'` so existing users see no behavior change.
  final String activeProviderKind;

  /// Currently selected on-device model id (matches `LocalModelSpec.id`)
  /// when [activeProviderKind] is `onDeviceGguf` or `onDeviceMlx`. Null when
  /// no local model is selected.
  final String? selectedLocalModelId;

  /// User-toggled speculative decoding for on-device inference. Pro-only.
  /// Auto-falls back to off when the device can't fit the target+draft pair.
  final bool speculativeDecodingEnabled;

  AppSettings({
    this.serverUrl = 'http://localhost:1234',
    this.apiToken,
    this.cfAccessClientId,
    this.cfAccessClientSecret,
    this.customRequestHeaders,
    this.customHeadersEnabled = false,
    this.selectedModel,
    Map<String, String>? selectedModelByServer,
    this.temperature = 0.8,
    this.maxTokens = 2048,
    // Match LM Studio's common default context length (see Model Loading).
    this.contextWindow = 4096,
    this.systemPrompt = '',
    this.topP = 0.9,
    this.topK = 40,
    this.minP = 0.05,
    this.repeatPenalty = 1.1,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.reasoning = 'off',
    this.verbosity = 'medium',
    this.contextFitMode = 'off',
    this.themeMode = ThemeMode.system,
    this.loadContextLength,
    // LM Studio Advanced defaults (0.3.x / 0.4.x): eval batch 2048,
    // flash attention on, offload KV cache to GPU on.
    this.loadEvalBatchSize = 2048,
    this.loadFlashAttention = true,
    this.loadNumExperts,
    this.loadOffloadKvCache = true,
    this.resizeImageForPhysicalBatch = true,
    this.modelsPreferLoadedParams = const [],
    Map<String, ParamPreset>? modelParamPresets,
    this.userAvatarPath,
    this.assistantAvatarPath,
    this.chatBackgroundPath,
    this.chatBackgroundOverlayOpacity = 15.0,
    this.glassEffectsEnabled = true,
    this.lowBatteryMode = false,
    this.showRuntimeInfo = false,
    this.selectedEmbeddingModel,
    this.enableSemanticSearch = false,
    this.useStructuredOutput = false,
    this.responseFormat,
    this.enableToolUse = false,
    this.enableWebSearch =
        true, // Web search on by default when tool calling is enabled
    this.useMcpToolsOnly = false,
    this.mcpServers,
    this.activeMcpServerLabels,
    this.integratedMcps,
    this.searxngUrl,
    this.preferSearxng = false,
    this.enableCodeSandbox = false,
    this.pinnedModels = const [],
    this.searchResultsCount = 5,
    this.unlimitedToolCalls = false,
    this.autoUnloadTtlMinutes,
    this.useV1Api = true, // Default to v1 API for new features
    this.showFoldersView = false,
    this.hideAvatars = true,
    this.autoScrollEnabled = true,
    this.showChatStarters = false,
    this.useLegacyComposer = true,
    this.chatFontSize = 14.0,
    this.chatIconSize = 14.0,
    this.selectedThemeId = 'default',
    this.iconTheme = 'default',
    this.showChatHeaderAvatar = true,
    this.chatBubbleAvatarRadius = 26,
    this.avatarAboveMessage = false,
    this.fullWidthAssistant = true,
    this.fullWidthAssistantNudgeShown = false,
    this.watchShowPersonas = true,
    this.watchAssistantInBubble = true,
    this.savedSystemPrompts,
    this.selectedSystemPromptId,
    this.locale,
    this.voiceAutoRead = false,
    this.voiceSpeechRate = 0.45,
    this.voicePitch = 1.0,
    this.voiceName,
    this.voiceLanguage = 'en-US',
    this.voiceSttLanguage = 'en-US',
    this.voiceAutoSend = false,
    this.voiceSttPauseForSeconds = 3,
    this.voiceSttListenForSeconds = 60,
    this.voiceSttProvider = 'whisper',
    this.whisperModelId = 'tiny',
    this.voiceContinuousConversation = true,
    this.voiceTtsProvider = 'native',
    this.voiceKokoroSpeakerId = 0,
    this.voiceKokoroSpeed = 1.0,
    this.voiceElevenLabsApiKey,
    this.voiceElevenLabsVoiceId,
    this.voiceElevenLabsModelId = 'eleven_v3_conversational',
    this.voiceGrokApiKey,
    this.voiceGrokVoiceId,
    this.voiceRemoteKokoroUrl,
    this.voiceRemoteKokoroModel,
    this.voiceCallMode = false,
    // Image generation defaults
    this.imageGenEnabled = false,
    this.imageGenServerUrl = '',
    this.imageGenSelectedModel,
    this.imageGenNegativePrompt =
        'blurry, bad quality, worst quality, low quality',
    this.imageGenSteps = 20,
    this.imageGenCfgScale = 7.0,
    this.imageGenWidth = 512,
    this.imageGenHeight = 512,
    this.imageGenSamplerName = 'Euler a',
    this.imageGenScheduler,
    this.imageGenSeed = -1,
    this.imageGenBatchSize = 1,
    this.imageGenEnableHr = false,
    this.imageGenHrScale = 2.0,
    this.imageGenHrUpscaler,
    this.imageGenDenoisingStrength = 0.7,
    this.imageGenRestoreFaces = false,
    this.imageGenTiling = false,
    this.imageGenReviewPrompt = false,
    this.imageGenAutoGenerate = false,
    // Image gen provider & ComfyUI
    this.imageGenProvider = 'a1111',
    this.selectedLocalSdCheckpointId,
    this.comfyUiWorkflowJson,
    this.comfyUiWorkflowPath,
    this.comfyUiWorkflowSaveName,
    this.comfyUiClientId,
    this.comfyUiUseNegativePrompt = false,
    this.comfyUiLoraName,
    this.comfyUiLoraWeight = 1.0,
    this.comfyUiControlsLoadedFrom,
    this.comfyUiWorkflowFields = const [],
    // Remote access
    this.remoteServerUrl,
    this.remoteAuthToken,
    this.isRemoteActive = false,
    this.remoteLastConnected,
    this.savedLocalServerUrl,
    this.savedLocalCloudBaseUrl,
    this.remoteEncryptionKey,
    this.remoteConnectVersion,
    List<String>? remoteBackends,
    this.remoteAutoReconnect = false,
    this.homeSyncEnabled = false,
    this.homeSyncPrompted = false,
    this.homeSyncPersonasEnabled = false,
    List<String>? homeSyncPersonaIds,
    this.homeSyncPersonasUpdatedAt,
    // Live Activity
    this.liveActivityEnabled = false,
    // Onboarding
    this.hasCompletedOnboarding = false,
    this.aiExperienceLevel,
    this.preferredUserName,
    this.expressionSpriteMode = 'both',
    this.spritePanelCollapsed = false,
    this.expressionLabels,
    this.hasCompletedAudioSetup = false,
    this.hasAcceptedArenaDataShare = false,
    this.arenaShareAnonymousResults = true,
    // Input behavior
    this.enterKeyBehavior = 'auto',
    // USB mode
    this.usbModeEnabled = false,
    // On-device routing (Phase 1)
    this.activeProviderKind = 'lmStudio',
    this.selectedLocalModelId,
    this.speculativeDecodingEnabled = false,
  })  : remoteBackends = remoteBackends ?? const [],
        homeSyncPersonaIds = homeSyncPersonaIds ?? const [],
        selectedModelByServer = selectedModelByServer ?? const {},
        modelParamPresets = modelParamPresets ?? const {};

  /// Whether an API token is configured for LM Studio authentication.
  /// Integrated MCPs (from mcp.json) require authentication to be enabled
  /// in LM Studio, so they should be skipped when no token is set.
  bool get hasApiToken => apiToken != null && apiToken!.isNotEmpty;

  bool get hasElevenLabsApiKey =>
      voiceElevenLabsApiKey != null && voiceElevenLabsApiKey!.trim().isNotEmpty;

  String get voiceElevenLabsApiKeyMasked {
    final key = voiceElevenLabsApiKey?.trim() ?? '';
    if (key.length < 8) return '••••';
    return '••••${key.substring(key.length - 4)}';
  }

  bool get hasGrokApiKey =>
      voiceGrokApiKey != null && voiceGrokApiKey!.trim().isNotEmpty;

  String get voiceGrokApiKeyMasked {
    final key = voiceGrokApiKey?.trim() ?? '';
    if (key.length < 8) return '••••';
    return '••••${key.substring(key.length - 4)}';
  }

  /// Extra headers (Cloudflare Access service token + arbitrary custom headers)
  /// that should be added to every LM Studio HTTP request. Returns null when
  /// nothing is configured — or when the master [customHeadersEnabled] toggle
  /// is off — so callers can skip header munging.
  ///
  /// Order: arbitrary [customRequestHeaders] first, then the discrete
  /// Cloudflare Access fields override any matching key so the dedicated
  /// settings always win over a duplicate KV entry.
  Map<String, String>? get effectiveExtraHeaders {
    if (!customHeadersEnabled) return null;
    final headers = <String, String>{};
    if (customRequestHeaders != null) {
      customRequestHeaders!.forEach((k, v) {
        final key = k.trim();
        if (key.isEmpty) return;
        headers[key] = v;
      });
    }
    final cfId = cfAccessClientId?.trim();
    final cfSecret = cfAccessClientSecret?.trim();
    if (cfId != null && cfId.isNotEmpty) {
      headers['CF-Access-Client-Id'] = cfId;
    }
    if (cfSecret != null && cfSecret.isNotEmpty) {
      headers['CF-Access-Client-Secret'] = cfSecret;
    }
    return headers.isEmpty ? null : headers;
  }

  /// Whether image generation can run with the current settings.
  /// On-device needs a selected ready checkpoint; remote needs a server URL.
  bool get isImageGenReady {
    if (!imageGenEnabled) return false;
    if (imageGenProvider == 'onDevice') {
      final id = selectedLocalSdCheckpointId;
      return id != null && id.isNotEmpty;
    }
    return imageGenServerUrl.trim().isNotEmpty ||
        (isRemoteActive &&
            remoteServerUrl != null &&
            remoteServerUrl!.isNotEmpty);
  }

  /// The effective image generation server URL.
  /// When remote access is active, routes through the relay server.
  /// Always strips trailing slashes so endpoint concatenation produces clean paths
  /// (RunPod proxies and many other servers reject double-slash paths).
  String get effectiveImageGenUrl {
    String url;
    if (isRemoteActive &&
        remoteServerUrl != null &&
        remoteServerUrl!.isNotEmpty) {
      // Relay URL — relay-client routes /sdapi/* to A1111. Use the paired
      // URL, not [serverUrl]: chat settings patched for a cloud provider
      // carry that provider's URL there.
      url = remoteServerUrl!;
    } else {
      url = imageGenServerUrl;
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// The negative prompt that should actually be sent to the active image
  /// generation backend.
  ///
  /// For ComfyUI, modern workflows often expect an empty negative prompt;
  /// callers should use this getter (rather than reading
  /// [imageGenNegativePrompt] directly) so the user's negative-prompt opt-in
  /// toggle is honored.
  String get effectiveImageGenNegativePrompt {
    if (imageGenProvider == 'comfyui' && !comfyUiUseNegativePrompt) {
      return '';
    }
    return imageGenNegativePrompt;
  }

  /// True when [url] is under the active paired relay URL. Relay-only
  /// headers (token, backend routing, LM Studio custom headers) must never
  /// go anywhere else.
  bool isActiveRelayUrl(String url) =>
      isRemoteActive && isRelayRequestUrl(url, remoteServerUrl);

  /// Extra headers needed for image gen requests when going through relay.
  /// Null for a direct A1111 / ComfyUI / RunPod host: neither the relay
  /// token nor the LM Studio custom headers go there.
  Map<String, String>? get imageGenRelayHeaders {
    if (!isActiveRelayUrl(effectiveImageGenUrl)) return null;
    final headers = <String, String>{};
    if (remoteAuthToken != null && remoteAuthToken!.isNotEmpty) {
      headers['X-LM-Mini-Token'] = remoteAuthToken!;
    }
    final extra = effectiveExtraHeaders;
    if (extra != null) headers.addAll(extra);
    return headers.isEmpty ? null : headers;
  }

  /// The effective Remote Kokoro TTS server URL.
  ///
  /// In relay mode, requests go through Share with phone's relay URL, which
  /// routes `/tts/*` to the desktop Kokoro service.
  /// In direct LAN mode, derive the TTS URL from the configured LM
  /// Studio host but switch to Kokoro's dedicated port 9998.
  String get effectiveVoiceRemoteKokoroUrl {
    if (voiceRemoteKokoroUrl != null && voiceRemoteKokoroUrl!.isNotEmpty) {
      return voiceRemoteKokoroUrl!;
    }

    if (isRemoteActive &&
        remoteServerUrl != null &&
        remoteServerUrl!.isNotEmpty) {
      return remoteServerUrl!;
    }

    final uri = Uri.tryParse(serverUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return serverUrl;
    }

    return uri
        .replace(
          port: 9998,
          path: '',
          query: null,
          fragment: null,
        )
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  /// Extra headers needed for Remote Kokoro requests when going through relay.
  /// Null when the user pointed Kokoro at their own URL.
  Map<String, String>? get voiceRemoteKokoroHeaders {
    if (isActiveRelayUrl(effectiveVoiceRemoteKokoroUrl) &&
        remoteAuthToken != null &&
        remoteAuthToken!.isNotEmpty) {
      return {'X-LM-Mini-Token': remoteAuthToken!};
    }
    return null;
  }

  /// Get list of ephemeral MCP servers that are currently active/enabled
  /// If activeMcpServerLabels is null, all configured servers are active (default)
  List<McpServerConfig> get activeMcpServers {
    if (mcpServers == null || mcpServers!.isEmpty) return [];
    if (activeMcpServerLabels == null) {
      return mcpServers!; // All active by default
    }
    return mcpServers!
        .where((s) => activeMcpServerLabels!.contains(s.label))
        .toList();
  }

  /// Get list of integrated MCPs that are currently enabled.
  /// Returns empty when no API token is set because integrated MCPs
  /// require authentication to be enabled in LM Studio.
  List<IntegratedMcpConfig> get activeIntegratedMcps {
    if (integratedMcps == null || integratedMcps!.isEmpty) return [];
    if (!hasApiToken) return []; // Integrated MCPs require auth in LM Studio
    return integratedMcps!.where((m) => m.enabled).toList();
  }

  /// Get the effective system prompt text
  /// If a saved prompt is selected, use its content; otherwise use the inline systemPrompt
  String get effectiveSystemPrompt {
    if (selectedSystemPromptId != null && savedSystemPrompts != null) {
      final selected =
          savedSystemPrompts!.where((p) => p.id == selectedSystemPromptId);
      if (selected.isNotEmpty) return selected.first.content;
    }
    return systemPrompt;
  }

  /// Get the currently selected saved system prompt (if any)
  SystemPrompt? get selectedSystemPrompt {
    if (selectedSystemPromptId == null || savedSystemPrompts == null) {
      return null;
    }
    final matches =
        savedSystemPrompts!.where((p) => p.id == selectedSystemPromptId);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Get saved prompts that are available for a specific model
  List<SystemPrompt> getPromptsForModel(String? modelId) {
    if (savedSystemPrompts == null || savedSystemPrompts!.isEmpty) return [];
    if (modelId == null) return savedSystemPrompts!;
    return savedSystemPrompts!.where((p) => p.isBoundToModel(modelId)).toList();
  }

  /// Rebuilds list fields that may be null on legacy/hot-reload instances.
  AppSettings repairListFields() => copyWith(
        modelsPreferLoadedParams:
            _readStringList(() => modelsPreferLoadedParams),
        pinnedModels: _readStringList(() => pinnedModels),
        remoteBackends: _readStringList(() => remoteBackends),
        homeSyncPersonaIds: _readStringList(() => homeSyncPersonaIds),
        selectedModelByServer: _readStringMap(() => selectedModelByServer),
        contextFitMode: _readString(() => contextFitMode, 'off'),
        modelParamPresets: _readParamPresetMap(() => modelParamPresets),
      );

  AppSettings copyWith({
    String? serverUrl,
    Object? apiToken = _unset,
    Object? cfAccessClientId = _unset,
    Object? cfAccessClientSecret = _unset,
    Object? customRequestHeaders = _unset,
    bool? customHeadersEnabled,
    Object? selectedModel = _unset,
    Map<String, String>? selectedModelByServer,
    double? temperature,
    int? maxTokens,
    int? contextWindow,
    String? systemPrompt,
    double? topP,
    int? topK,
    double? minP,
    double? repeatPenalty,
    double? frequencyPenalty,
    double? presencePenalty,
    String? reasoning,
    String? verbosity,
    String? contextFitMode,
    ThemeMode? themeMode,
    Object? loadContextLength = _unset,
    Object? loadEvalBatchSize = _unset,
    bool? loadFlashAttention,
    Object? loadNumExperts = _unset,
    bool? loadOffloadKvCache,
    bool? resizeImageForPhysicalBatch,
    List<String>? modelsPreferLoadedParams,
    Map<String, ParamPreset>? modelParamPresets,
    Object? userAvatarPath = _unset,
    Object? assistantAvatarPath = _unset,
    Object? chatBackgroundPath = _unset,
    double? chatBackgroundOverlayOpacity,
    bool? glassEffectsEnabled,
    bool? lowBatteryMode,
    bool? showRuntimeInfo,
    Object? selectedEmbeddingModel = _unset,
    bool? enableSemanticSearch,
    bool? useStructuredOutput,
    Object? responseFormat = _unset,
    bool? enableToolUse,
    bool? enableWebSearch,
    bool? useMcpToolsOnly,
    Object? mcpServers = _unset,
    Object? activeMcpServerLabels = _unset,
    Object? integratedMcps = _unset,
    Object? searxngUrl = _unset,
    bool? preferSearxng,
    bool? enableCodeSandbox,
    List<String>? pinnedModels,
    int? searchResultsCount,
    bool? unlimitedToolCalls,
    Object? autoUnloadTtlMinutes = _unset,
    bool? useV1Api,
    bool? showFoldersView,
    bool? hideAvatars,
    bool? autoScrollEnabled,
    bool? showChatStarters,
    bool? useLegacyComposer,
    double? chatFontSize,
    double? chatIconSize,
    String? selectedThemeId,
    String? iconTheme,
    bool? showChatHeaderAvatar,
    double? chatBubbleAvatarRadius,
    bool? avatarAboveMessage,
    bool? fullWidthAssistant,
    bool? fullWidthAssistantNudgeShown,
    bool? watchShowPersonas,
    bool? watchAssistantInBubble,
    Object? savedSystemPrompts = _unset,
    Object? selectedSystemPromptId = _unset,
    Object? locale = _unset,
    bool? voiceAutoRead,
    double? voiceSpeechRate,
    double? voicePitch,
    Object? voiceName = _unset,
    String? voiceLanguage,
    String? voiceSttLanguage,
    bool? voiceAutoSend,
    int? voiceSttPauseForSeconds,
    int? voiceSttListenForSeconds,
    String? voiceSttProvider,
    String? whisperModelId,
    bool? voiceContinuousConversation,
    String? voiceTtsProvider,
    int? voiceKokoroSpeakerId,
    double? voiceKokoroSpeed,
    Object? voiceElevenLabsApiKey = _unset,
    Object? voiceElevenLabsVoiceId = _unset,
    String? voiceElevenLabsModelId,
    Object? voiceGrokApiKey = _unset,
    Object? voiceGrokVoiceId = _unset,
    String? voiceRemoteKokoroUrl,
    String? voiceRemoteKokoroModel,
    bool? voiceCallMode,
    // Image generation
    bool? imageGenEnabled,
    String? imageGenServerUrl,
    Object? imageGenSelectedModel = _unset,
    String? imageGenNegativePrompt,
    int? imageGenSteps,
    double? imageGenCfgScale,
    int? imageGenWidth,
    int? imageGenHeight,
    String? imageGenSamplerName,
    Object? imageGenScheduler = _unset,
    int? imageGenSeed,
    int? imageGenBatchSize,
    bool? imageGenEnableHr,
    double? imageGenHrScale,
    Object? imageGenHrUpscaler = _unset,
    double? imageGenDenoisingStrength,
    bool? imageGenRestoreFaces,
    bool? imageGenTiling,
    bool? imageGenReviewPrompt,
    bool? imageGenAutoGenerate,
    String? imageGenProvider,
    Object? selectedLocalSdCheckpointId = _unset,
    Object? comfyUiWorkflowJson = _unset,
    Object? comfyUiWorkflowPath = _unset,
    Object? comfyUiWorkflowSaveName = _unset,
    Object? comfyUiClientId = _unset,
    bool? comfyUiUseNegativePrompt,
    Object? comfyUiLoraName = _unset,
    double? comfyUiLoraWeight,
    Object? comfyUiControlsLoadedFrom = _unset,
    List<Map<String, dynamic>>? comfyUiWorkflowFields,
    // Remote access
    Object? remoteServerUrl = _unset,
    Object? remoteAuthToken = _unset,
    bool? isRemoteActive,
    Object? remoteLastConnected = _unset,
    Object? savedLocalServerUrl = _unset,
    Object? savedLocalCloudBaseUrl = _unset,
    Object? remoteEncryptionKey = _unset,
    Object? remoteConnectVersion = _unset,
    List<String>? remoteBackends,
    bool? remoteAutoReconnect,
    bool? homeSyncEnabled,
    bool? homeSyncPrompted,
    bool? homeSyncPersonasEnabled,
    List<String>? homeSyncPersonaIds,
    Object? homeSyncPersonasUpdatedAt = _unset,
    bool? liveActivityEnabled,
    bool? hasCompletedOnboarding,
    Object? aiExperienceLevel = _unset,
    Object? preferredUserName = _unset,
    String? expressionSpriteMode,
    bool? spritePanelCollapsed,
    Object? expressionLabels = _unset,
    bool? hasCompletedAudioSetup,
    bool? hasAcceptedArenaDataShare,
    bool? arenaShareAnonymousResults,
    String? enterKeyBehavior,
    bool? usbModeEnabled,
    String? activeProviderKind,
    Object? selectedLocalModelId = _unset,
    bool? speculativeDecodingEnabled,
  }) {
    return AppSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      apiToken:
          identical(apiToken, _unset) ? this.apiToken : apiToken as String?,
      cfAccessClientId: identical(cfAccessClientId, _unset)
          ? this.cfAccessClientId
          : cfAccessClientId as String?,
      cfAccessClientSecret: identical(cfAccessClientSecret, _unset)
          ? this.cfAccessClientSecret
          : cfAccessClientSecret as String?,
      customRequestHeaders: identical(customRequestHeaders, _unset)
          ? this.customRequestHeaders
          : customRequestHeaders as Map<String, String>?,
      customHeadersEnabled: customHeadersEnabled ?? this.customHeadersEnabled,
      selectedModel: identical(selectedModel, _unset)
          ? this.selectedModel
          : selectedModel as String?,
      selectedModelByServer:
          selectedModelByServer ?? this.selectedModelByServer,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      contextWindow: contextWindow ?? this.contextWindow,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      minP: minP ?? this.minP,
      repeatPenalty: repeatPenalty ?? this.repeatPenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      reasoning: reasoning ?? this.reasoning,
      verbosity: verbosity ?? this.verbosity,
      contextFitMode:
          contextFitMode ?? _readString(() => this.contextFitMode, 'off'),
      themeMode: themeMode ?? this.themeMode,
      loadContextLength: identical(loadContextLength, _unset)
          ? this.loadContextLength
          : loadContextLength as int?,
      loadEvalBatchSize: identical(loadEvalBatchSize, _unset)
          ? this.loadEvalBatchSize
          : loadEvalBatchSize as int?,
      loadFlashAttention: loadFlashAttention ?? this.loadFlashAttention,
      loadNumExperts: identical(loadNumExperts, _unset)
          ? this.loadNumExperts
          : loadNumExperts as int?,
      loadOffloadKvCache: loadOffloadKvCache ?? this.loadOffloadKvCache,
      resizeImageForPhysicalBatch:
          resizeImageForPhysicalBatch ?? this.resizeImageForPhysicalBatch,
      modelsPreferLoadedParams: modelsPreferLoadedParams ??
          _readStringList(() => this.modelsPreferLoadedParams),
      modelParamPresets: modelParamPresets ??
          _readParamPresetMap(() => this.modelParamPresets),
      userAvatarPath: identical(userAvatarPath, _unset)
          ? this.userAvatarPath
          : userAvatarPath as String?,
      assistantAvatarPath: identical(assistantAvatarPath, _unset)
          ? this.assistantAvatarPath
          : assistantAvatarPath as String?,
      chatBackgroundPath: identical(chatBackgroundPath, _unset)
          ? this.chatBackgroundPath
          : chatBackgroundPath as String?,
      chatBackgroundOverlayOpacity:
          chatBackgroundOverlayOpacity ?? this.chatBackgroundOverlayOpacity,
      glassEffectsEnabled: glassEffectsEnabled ?? this.glassEffectsEnabled,
      lowBatteryMode: lowBatteryMode ?? this.lowBatteryMode,
      showRuntimeInfo: showRuntimeInfo ?? this.showRuntimeInfo,
      selectedEmbeddingModel: identical(selectedEmbeddingModel, _unset)
          ? this.selectedEmbeddingModel
          : selectedEmbeddingModel as String?,
      enableSemanticSearch: enableSemanticSearch ?? this.enableSemanticSearch,
      useStructuredOutput: useStructuredOutput ?? this.useStructuredOutput,
      responseFormat: identical(responseFormat, _unset)
          ? this.responseFormat
          : responseFormat as String?,
      enableToolUse: enableToolUse ?? this.enableToolUse,
      enableWebSearch: enableWebSearch ?? this.enableWebSearch,
      useMcpToolsOnly: useMcpToolsOnly ?? this.useMcpToolsOnly,
      mcpServers: identical(mcpServers, _unset)
          ? this.mcpServers
          : mcpServers as List<McpServerConfig>?,
      activeMcpServerLabels: identical(activeMcpServerLabels, _unset)
          ? this.activeMcpServerLabels
          : activeMcpServerLabels as List<String>?,
      integratedMcps: identical(integratedMcps, _unset)
          ? this.integratedMcps
          : integratedMcps as List<IntegratedMcpConfig>?,
      searxngUrl: identical(searxngUrl, _unset)
          ? this.searxngUrl
          : searxngUrl as String?,
      preferSearxng: preferSearxng ?? this.preferSearxng,
      enableCodeSandbox: enableCodeSandbox ?? this.enableCodeSandbox,
      pinnedModels: pinnedModels ?? _readStringList(() => this.pinnedModels),
      searchResultsCount: searchResultsCount ?? this.searchResultsCount,
      unlimitedToolCalls: unlimitedToolCalls ?? this.unlimitedToolCalls,
      autoUnloadTtlMinutes: identical(autoUnloadTtlMinutes, _unset)
          ? this.autoUnloadTtlMinutes
          : autoUnloadTtlMinutes as int?,
      useV1Api: useV1Api ?? this.useV1Api,
      showFoldersView: showFoldersView ?? this.showFoldersView,
      hideAvatars: hideAvatars ?? this.hideAvatars,
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      showChatStarters: showChatStarters ?? this.showChatStarters,
      useLegacyComposer: useLegacyComposer ?? this.useLegacyComposer,
      chatFontSize: chatFontSize ?? this.chatFontSize,
      chatIconSize: chatIconSize ?? this.chatIconSize,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      iconTheme: iconTheme ?? this.iconTheme,
      showChatHeaderAvatar: showChatHeaderAvatar ?? this.showChatHeaderAvatar,
      chatBubbleAvatarRadius:
          chatBubbleAvatarRadius ?? this.chatBubbleAvatarRadius,
      avatarAboveMessage: avatarAboveMessage ?? this.avatarAboveMessage,
      fullWidthAssistant: fullWidthAssistant ?? this.fullWidthAssistant,
      fullWidthAssistantNudgeShown:
          fullWidthAssistantNudgeShown ?? this.fullWidthAssistantNudgeShown,
      watchShowPersonas: watchShowPersonas ?? this.watchShowPersonas,
      watchAssistantInBubble:
          watchAssistantInBubble ?? this.watchAssistantInBubble,
      savedSystemPrompts: identical(savedSystemPrompts, _unset)
          ? this.savedSystemPrompts
          : savedSystemPrompts as List<SystemPrompt>?,
      selectedSystemPromptId: identical(selectedSystemPromptId, _unset)
          ? this.selectedSystemPromptId
          : selectedSystemPromptId as String?,
      locale: identical(locale, _unset) ? this.locale : locale as String?,
      voiceAutoRead: voiceAutoRead ?? this.voiceAutoRead,
      voiceSpeechRate: voiceSpeechRate ?? this.voiceSpeechRate,
      voicePitch: voicePitch ?? this.voicePitch,
      voiceName:
          identical(voiceName, _unset) ? this.voiceName : voiceName as String?,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      voiceSttLanguage: voiceSttLanguage ?? this.voiceSttLanguage,
      voiceAutoSend: voiceAutoSend ?? this.voiceAutoSend,
      voiceSttPauseForSeconds:
          voiceSttPauseForSeconds ?? this.voiceSttPauseForSeconds,
      voiceSttListenForSeconds:
          voiceSttListenForSeconds ?? this.voiceSttListenForSeconds,
      voiceSttProvider: voiceSttProvider ?? this.voiceSttProvider,
      whisperModelId: whisperModelId ?? this.whisperModelId,
      voiceContinuousConversation:
          voiceContinuousConversation ?? this.voiceContinuousConversation,
      voiceTtsProvider: voiceTtsProvider ?? this.voiceTtsProvider,
      voiceKokoroSpeakerId: voiceKokoroSpeakerId ?? this.voiceKokoroSpeakerId,
      voiceKokoroSpeed: voiceKokoroSpeed ?? this.voiceKokoroSpeed,
      voiceElevenLabsApiKey: identical(voiceElevenLabsApiKey, _unset)
          ? this.voiceElevenLabsApiKey
          : voiceElevenLabsApiKey as String?,
      voiceElevenLabsVoiceId: identical(voiceElevenLabsVoiceId, _unset)
          ? this.voiceElevenLabsVoiceId
          : voiceElevenLabsVoiceId as String?,
      voiceElevenLabsModelId:
          voiceElevenLabsModelId ?? this.voiceElevenLabsModelId,
      voiceGrokApiKey: identical(voiceGrokApiKey, _unset)
          ? this.voiceGrokApiKey
          : voiceGrokApiKey as String?,
      voiceGrokVoiceId: identical(voiceGrokVoiceId, _unset)
          ? this.voiceGrokVoiceId
          : voiceGrokVoiceId as String?,
      voiceRemoteKokoroUrl: voiceRemoteKokoroUrl ?? this.voiceRemoteKokoroUrl,
      voiceRemoteKokoroModel:
          voiceRemoteKokoroModel ?? this.voiceRemoteKokoroModel,
      voiceCallMode: voiceCallMode ?? this.voiceCallMode,
      imageGenEnabled: imageGenEnabled ?? this.imageGenEnabled,
      imageGenServerUrl: imageGenServerUrl ?? this.imageGenServerUrl,
      imageGenSelectedModel: identical(imageGenSelectedModel, _unset)
          ? this.imageGenSelectedModel
          : imageGenSelectedModel as String?,
      imageGenNegativePrompt:
          imageGenNegativePrompt ?? this.imageGenNegativePrompt,
      imageGenSteps: imageGenSteps ?? this.imageGenSteps,
      imageGenCfgScale: imageGenCfgScale ?? this.imageGenCfgScale,
      imageGenWidth: imageGenWidth ?? this.imageGenWidth,
      imageGenHeight: imageGenHeight ?? this.imageGenHeight,
      imageGenSamplerName: imageGenSamplerName ?? this.imageGenSamplerName,
      imageGenScheduler: identical(imageGenScheduler, _unset)
          ? this.imageGenScheduler
          : imageGenScheduler as String?,
      imageGenSeed: imageGenSeed ?? this.imageGenSeed,
      imageGenBatchSize: imageGenBatchSize ?? this.imageGenBatchSize,
      imageGenEnableHr: imageGenEnableHr ?? this.imageGenEnableHr,
      imageGenHrScale: imageGenHrScale ?? this.imageGenHrScale,
      imageGenHrUpscaler: identical(imageGenHrUpscaler, _unset)
          ? this.imageGenHrUpscaler
          : imageGenHrUpscaler as String?,
      imageGenDenoisingStrength:
          imageGenDenoisingStrength ?? this.imageGenDenoisingStrength,
      imageGenRestoreFaces: imageGenRestoreFaces ?? this.imageGenRestoreFaces,
      imageGenTiling: imageGenTiling ?? this.imageGenTiling,
      imageGenReviewPrompt: imageGenReviewPrompt ?? this.imageGenReviewPrompt,
      imageGenAutoGenerate: imageGenAutoGenerate ?? this.imageGenAutoGenerate,
      imageGenProvider: imageGenProvider ?? this.imageGenProvider,
      selectedLocalSdCheckpointId:
          identical(selectedLocalSdCheckpointId, _unset)
              ? this.selectedLocalSdCheckpointId
              : selectedLocalSdCheckpointId as String?,
      comfyUiWorkflowJson: identical(comfyUiWorkflowJson, _unset)
          ? this.comfyUiWorkflowJson
          : comfyUiWorkflowJson as String?,
      comfyUiWorkflowPath: identical(comfyUiWorkflowPath, _unset)
          ? this.comfyUiWorkflowPath
          : comfyUiWorkflowPath as String?,
      comfyUiWorkflowSaveName: identical(comfyUiWorkflowSaveName, _unset)
          ? this.comfyUiWorkflowSaveName
          : comfyUiWorkflowSaveName as String?,
      comfyUiClientId: identical(comfyUiClientId, _unset)
          ? this.comfyUiClientId
          : comfyUiClientId as String?,
      comfyUiUseNegativePrompt:
          comfyUiUseNegativePrompt ?? this.comfyUiUseNegativePrompt,
      comfyUiLoraName: identical(comfyUiLoraName, _unset)
          ? this.comfyUiLoraName
          : comfyUiLoraName as String?,
      comfyUiLoraWeight: comfyUiLoraWeight ?? this.comfyUiLoraWeight,
      comfyUiControlsLoadedFrom: identical(comfyUiControlsLoadedFrom, _unset)
          ? this.comfyUiControlsLoadedFrom
          : comfyUiControlsLoadedFrom as String?,
      comfyUiWorkflowFields:
          comfyUiWorkflowFields ?? this.comfyUiWorkflowFields,
      remoteServerUrl: identical(remoteServerUrl, _unset)
          ? this.remoteServerUrl
          : remoteServerUrl as String?,
      remoteAuthToken: identical(remoteAuthToken, _unset)
          ? this.remoteAuthToken
          : remoteAuthToken as String?,
      isRemoteActive: isRemoteActive ?? this.isRemoteActive,
      remoteLastConnected: identical(remoteLastConnected, _unset)
          ? this.remoteLastConnected
          : remoteLastConnected as String?,
      savedLocalServerUrl: identical(savedLocalServerUrl, _unset)
          ? this.savedLocalServerUrl
          : savedLocalServerUrl as String?,
      savedLocalCloudBaseUrl: identical(savedLocalCloudBaseUrl, _unset)
          ? this.savedLocalCloudBaseUrl
          : savedLocalCloudBaseUrl as String?,
      remoteEncryptionKey: identical(remoteEncryptionKey, _unset)
          ? this.remoteEncryptionKey
          : remoteEncryptionKey as String?,
      remoteConnectVersion: identical(remoteConnectVersion, _unset)
          ? this.remoteConnectVersion
          : remoteConnectVersion as String?,
      remoteBackends: remoteBackends ?? this.remoteBackends,
      remoteAutoReconnect: remoteAutoReconnect ?? this.remoteAutoReconnect,
      homeSyncEnabled: homeSyncEnabled ?? this.homeSyncEnabled,
      homeSyncPrompted: homeSyncPrompted ?? this.homeSyncPrompted,
      homeSyncPersonasEnabled:
          homeSyncPersonasEnabled ?? this.homeSyncPersonasEnabled,
      homeSyncPersonaIds: homeSyncPersonaIds ?? this.homeSyncPersonaIds,
      homeSyncPersonasUpdatedAt: identical(homeSyncPersonasUpdatedAt, _unset)
          ? this.homeSyncPersonasUpdatedAt
          : homeSyncPersonasUpdatedAt as DateTime?,
      liveActivityEnabled: liveActivityEnabled ?? this.liveActivityEnabled,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      aiExperienceLevel: identical(aiExperienceLevel, _unset)
          ? this.aiExperienceLevel
          : aiExperienceLevel as String?,
      preferredUserName: identical(preferredUserName, _unset)
          ? this.preferredUserName
          : preferredUserName as String?,
      expressionSpriteMode: expressionSpriteMode ?? this.expressionSpriteMode,
      spritePanelCollapsed: spritePanelCollapsed ?? this.spritePanelCollapsed,
      expressionLabels: identical(expressionLabels, _unset)
          ? this.expressionLabels
          : expressionLabels as List<String>?,
      hasCompletedAudioSetup:
          hasCompletedAudioSetup ?? this.hasCompletedAudioSetup,
      hasAcceptedArenaDataShare:
          hasAcceptedArenaDataShare ?? this.hasAcceptedArenaDataShare,
      arenaShareAnonymousResults:
          arenaShareAnonymousResults ?? this.arenaShareAnonymousResults,
      enterKeyBehavior: enterKeyBehavior ?? this.enterKeyBehavior,
      usbModeEnabled: usbModeEnabled ?? this.usbModeEnabled,
      activeProviderKind: activeProviderKind ?? this.activeProviderKind,
      selectedLocalModelId: identical(selectedLocalModelId, _unset)
          ? this.selectedLocalModelId
          : selectedLocalModelId as String?,
      speculativeDecodingEnabled:
          speculativeDecodingEnabled ?? this.speculativeDecodingEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'apiToken': apiToken,
      'cfAccessClientId': cfAccessClientId,
      'cfAccessClientSecret': cfAccessClientSecret,
      'customRequestHeaders': customRequestHeaders,
      'customHeadersEnabled': customHeadersEnabled,
      'selectedModel': selectedModel,
      'selectedModelByServer': selectedModelByServer,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'contextWindow': contextWindow,
      'systemPrompt': systemPrompt,
      'topP': topP,
      'topK': topK,
      'minP': minP,
      'repeatPenalty': repeatPenalty,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
      'reasoning': reasoning,
      'verbosity': verbosity,
      'contextFitMode': _readString(() => contextFitMode, 'off'),
      'themeMode': themeMode.name,
      'loadContextLength': loadContextLength,
      'loadEvalBatchSize': loadEvalBatchSize,
      'loadFlashAttention': loadFlashAttention,
      'loadNumExperts': loadNumExperts,
      'loadOffloadKvCache': loadOffloadKvCache,
      'resizeImageForPhysicalBatch': resizeImageForPhysicalBatch,
      'modelsPreferLoadedParams':
          _readStringList(() => modelsPreferLoadedParams),
      'modelParamPresets': {
        for (final e in _readParamPresetMap(() => modelParamPresets).entries)
          e.key: e.value.toJson(),
      },
      'userAvatarPath': userAvatarPath,
      'assistantAvatarPath': assistantAvatarPath,
      'chatBackgroundPath': chatBackgroundPath,
      'chatBackgroundOverlayOpacity': chatBackgroundOverlayOpacity,
      'glassEffectsEnabled': glassEffectsEnabled,
      'lowBatteryMode': lowBatteryMode,
      'showRuntimeInfo': showRuntimeInfo,
      'selectedEmbeddingModel': selectedEmbeddingModel,
      'enableSemanticSearch': enableSemanticSearch,
      'useStructuredOutput': useStructuredOutput,
      'responseFormat': responseFormat,
      'enableToolUse': enableToolUse,
      'enableWebSearch': enableWebSearch,
      'useMcpToolsOnly': useMcpToolsOnly,
      'mcpServers': mcpServers?.map((s) => s.toJson()).toList(),
      'activeMcpServerLabels': activeMcpServerLabels,
      'integratedMcps': integratedMcps?.map((m) => m.toJson()).toList(),
      'searxngUrl': searxngUrl,
      'preferSearxng': preferSearxng,
      'enableCodeSandbox': enableCodeSandbox,
      'pinnedModels': _readStringList(() => pinnedModels),
      'searchResultsCount': searchResultsCount,
      'unlimitedToolCalls': unlimitedToolCalls,
      'autoUnloadTtlMinutes': autoUnloadTtlMinutes,
      'useV1Api': useV1Api,
      'showFoldersView': showFoldersView,
      'hideAvatars': hideAvatars,
      'autoScrollEnabled': autoScrollEnabled,
      'showChatStarters': showChatStarters,
      'useLegacyComposer': useLegacyComposer,
      'chatFontSize': chatFontSize,
      'chatIconSize': chatIconSize,
      'selectedThemeId': selectedThemeId,
      'iconTheme': iconTheme,
      'showChatHeaderAvatar': showChatHeaderAvatar,
      'chatBubbleAvatarRadius': chatBubbleAvatarRadius,
      'avatarAboveMessage': avatarAboveMessage,
      'fullWidthAssistant': fullWidthAssistant,
      'fullWidthAssistantNudgeShown': fullWidthAssistantNudgeShown,
      'watchShowPersonas': watchShowPersonas,
      'watchAssistantInBubble': watchAssistantInBubble,
      'savedSystemPrompts': savedSystemPrompts?.map((p) => p.toJson()).toList(),
      'selectedSystemPromptId': selectedSystemPromptId,
      'locale': locale,
      'voiceAutoRead': voiceAutoRead,
      'voiceSpeechRate': voiceSpeechRate,
      'voicePitch': voicePitch,
      'voiceName': voiceName,
      'voiceLanguage': voiceLanguage,
      'voiceSttLanguage': voiceSttLanguage,
      'voiceAutoSend': voiceAutoSend,
      'voiceSttPauseForSeconds': voiceSttPauseForSeconds,
      'voiceSttListenForSeconds': voiceSttListenForSeconds,
      'voiceSttProvider': voiceSttProvider,
      'whisperModelId': whisperModelId,
      'voiceContinuousConversation': voiceContinuousConversation,
      'voiceTtsProvider': voiceTtsProvider,
      'voiceKokoroSpeakerId': voiceKokoroSpeakerId,
      'voiceKokoroSpeed': voiceKokoroSpeed,
      'voiceElevenLabsApiKey': voiceElevenLabsApiKey,
      'voiceElevenLabsVoiceId': voiceElevenLabsVoiceId,
      'voiceElevenLabsModelId': voiceElevenLabsModelId,
      'voiceGrokApiKey': voiceGrokApiKey,
      'voiceGrokVoiceId': voiceGrokVoiceId,
      'voiceRemoteKokoroUrl': voiceRemoteKokoroUrl,
      'voiceRemoteKokoroModel': voiceRemoteKokoroModel,
      'voiceCallMode': voiceCallMode,
      'imageGenEnabled': imageGenEnabled,
      'imageGenServerUrl': imageGenServerUrl,
      'imageGenSelectedModel': imageGenSelectedModel,
      'imageGenNegativePrompt': imageGenNegativePrompt,
      'imageGenSteps': imageGenSteps,
      'imageGenCfgScale': imageGenCfgScale,
      'imageGenWidth': imageGenWidth,
      'imageGenHeight': imageGenHeight,
      'imageGenSamplerName': imageGenSamplerName,
      'imageGenScheduler': imageGenScheduler,
      'imageGenSeed': imageGenSeed,
      'imageGenBatchSize': imageGenBatchSize,
      'imageGenEnableHr': imageGenEnableHr,
      'imageGenHrScale': imageGenHrScale,
      'imageGenHrUpscaler': imageGenHrUpscaler,
      'imageGenDenoisingStrength': imageGenDenoisingStrength,
      'imageGenRestoreFaces': imageGenRestoreFaces,
      'imageGenTiling': imageGenTiling,
      'imageGenReviewPrompt': imageGenReviewPrompt,
      'imageGenAutoGenerate': imageGenAutoGenerate,
      'imageGenProvider': imageGenProvider,
      'selectedLocalSdCheckpointId': selectedLocalSdCheckpointId,
      'comfyUiWorkflowJson': comfyUiWorkflowJson,
      'comfyUiWorkflowPath': comfyUiWorkflowPath,
      'comfyUiWorkflowSaveName': comfyUiWorkflowSaveName,
      'comfyUiClientId': comfyUiClientId,
      'comfyUiUseNegativePrompt': comfyUiUseNegativePrompt,
      'comfyUiLoraName': comfyUiLoraName,
      'comfyUiLoraWeight': comfyUiLoraWeight,
      'comfyUiControlsLoadedFrom': comfyUiControlsLoadedFrom,
      'comfyUiWorkflowFields': comfyUiWorkflowFields,
      'remoteServerUrl': remoteServerUrl,
      'remoteAuthToken': remoteAuthToken,
      'isRemoteActive': isRemoteActive,
      'remoteLastConnected': remoteLastConnected,
      'savedLocalServerUrl': savedLocalServerUrl,
      'savedLocalCloudBaseUrl': savedLocalCloudBaseUrl,
      'remoteEncryptionKey': remoteEncryptionKey,
      'remoteConnectVersion': remoteConnectVersion,
      'remoteBackends': remoteBackends,
      'remoteAutoReconnect': remoteAutoReconnect,
      'homeSyncEnabled': homeSyncEnabled,
      'homeSyncPrompted': homeSyncPrompted,
      'homeSyncPersonasEnabled': homeSyncPersonasEnabled,
      'homeSyncPersonaIds': homeSyncPersonaIds,
      'homeSyncPersonasUpdatedAt': homeSyncPersonasUpdatedAt?.toIso8601String(),
      'liveActivityEnabled': liveActivityEnabled,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'aiExperienceLevel': aiExperienceLevel,
      'preferredUserName': preferredUserName,
      'expressionSpriteMode': expressionSpriteMode,
      'spritePanelCollapsed': spritePanelCollapsed,
      'hasCompletedAudioSetup': hasCompletedAudioSetup,
      'hasAcceptedArenaDataShare': hasAcceptedArenaDataShare,
      'arenaShareAnonymousResults': arenaShareAnonymousResults,
      'enterKeyBehavior': enterKeyBehavior,
      'usbModeEnabled': usbModeEnabled,
      'activeProviderKind': activeProviderKind,
      'selectedLocalModelId': selectedLocalModelId,
      'speculativeDecodingEnabled': speculativeDecodingEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      serverUrl: json['serverUrl'] ?? 'http://localhost:1234',
      apiToken: json['apiToken'],
      cfAccessClientId: json['cfAccessClientId'] as String?,
      cfAccessClientSecret: json['cfAccessClientSecret'] as String?,
      customRequestHeaders: _migrateCustomRequestHeaders(json),
      // Default to enabled if user previously configured anything (back-compat
      // with builds that didn't have a master toggle), otherwise respect the
      // persisted value.
      customHeadersEnabled: json['customHeadersEnabled'] as bool? ??
          _legacyCustomHeadersConfigured(json),
      selectedModel: json['selectedModel'],
      selectedModelByServer: _parseStringMap(json['selectedModelByServer']),
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      maxTokens: json['maxTokens'] ?? 1024,
      contextWindow: json['contextWindow'] ?? 4096,
      systemPrompt: json['systemPrompt'] ?? '',
      topP: (json['topP'] ?? 0.9).toDouble(),
      topK: json['topK'] ?? 40,
      minP: (json['minP'] ?? 0.05).toDouble(),
      repeatPenalty: (json['repeatPenalty'] ?? 1.1).toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] ?? 0.0).toDouble(),
      presencePenalty: (json['presencePenalty'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? 'off',
      verbosity: json['verbosity'] ?? 'medium',
      contextFitMode: json['contextFitMode'] is String
          ? json['contextFitMode'] as String
          : 'off',
      themeMode: _parseThemeMode(json['themeMode']),
      loadContextLength: json['loadContextLength'],
      loadEvalBatchSize: json.containsKey('loadEvalBatchSize')
          ? (json['loadEvalBatchSize'] as num?)?.toInt()
          : 2048,
      loadFlashAttention: json['loadFlashAttention'] ?? true,
      loadNumExperts: json['loadNumExperts'],
      loadOffloadKvCache: json['loadOffloadKvCache'] ?? true,
      resizeImageForPhysicalBatch: json['resizeImageForPhysicalBatch'] ?? true,
      modelsPreferLoadedParams: (json['modelsPreferLoadedParams'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      modelParamPresets: _parseParamPresetMap(json['modelParamPresets']),
      userAvatarPath: json['userAvatarPath'],
      assistantAvatarPath: json['assistantAvatarPath'],
      chatBackgroundPath: json['chatBackgroundPath'],
      chatBackgroundOverlayOpacity:
          (json['chatBackgroundOverlayOpacity'] as num?)?.toDouble() ?? 15.0,
      glassEffectsEnabled: json['glassEffectsEnabled'] ?? true,
      lowBatteryMode: json['lowBatteryMode'] ?? false,
      showRuntimeInfo: json['showRuntimeInfo'] ?? false,
      selectedEmbeddingModel: json['selectedEmbeddingModel'],
      enableSemanticSearch: json['enableSemanticSearch'] ?? false,
      useStructuredOutput: json['useStructuredOutput'] ?? false,
      responseFormat: json['responseFormat'],
      enableToolUse: json['enableToolUse'] ?? json['enableWebSearch'] ?? false,
      enableWebSearch: json.containsKey('enableToolUse')
          ? (json['enableWebSearch'] as bool? ??
              true) // New format: separate web search toggle
          : true, // Old format: enableWebSearch was legacy key for enableToolUse, default new field to true
      useMcpToolsOnly: json['useMcpToolsOnly'] ?? false,
      mcpServers: (json['mcpServers'] as List?)
          ?.map((s) => McpServerConfig.fromJson(s as Map<String, dynamic>))
          .toList(),
      activeMcpServerLabels:
          (json['activeMcpServerLabels'] as List?)?.cast<String>(),
      integratedMcps: (json['integratedMcps'] as List?)
          ?.map((m) => IntegratedMcpConfig.fromJson(m as Map<String, dynamic>))
          .toList(),
      searxngUrl: json['searxngUrl'],
      preferSearxng: json['preferSearxng'] ?? false,
      enableCodeSandbox: json['enableCodeSandbox'] ?? false,
      pinnedModels:
          (json['pinnedModels'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      searchResultsCount: json['searchResultsCount'] ?? 5,
      unlimitedToolCalls: json['unlimitedToolCalls'] ?? false,
      autoUnloadTtlMinutes: json['autoUnloadTtlMinutes'],
      useV1Api: json['useV1Api'] ?? true,
      showFoldersView: json['showFoldersView'] ?? false,
      hideAvatars: json['hideAvatars'] ?? false,
      autoScrollEnabled: json['autoScrollEnabled'] ?? true,
      showChatStarters: json['showChatStarters'] ?? false,
      useLegacyComposer: json['useLegacyComposer'] ?? true,
      chatFontSize: (json['chatFontSize'] ?? 14.0).toDouble(),
      chatIconSize: (json['chatIconSize'] ?? 14.0).toDouble(),
      selectedThemeId: json['selectedThemeId'] as String? ?? 'default',
      iconTheme: json['iconTheme'] as String? ?? 'default',
      showChatHeaderAvatar: json['showChatHeaderAvatar'] ?? true,
      chatBubbleAvatarRadius:
          (json['chatBubbleAvatarRadius'] ?? 26.0).toDouble(),
      avatarAboveMessage: json['avatarAboveMessage'] ?? false,
      fullWidthAssistant: json['fullWidthAssistant'] ?? false,
      fullWidthAssistantNudgeShown:
          json['fullWidthAssistantNudgeShown'] ?? false,
      watchShowPersonas: json['watchShowPersonas'] ?? true,
      watchAssistantInBubble: json['watchAssistantInBubble'] ?? true,
      savedSystemPrompts: (json['savedSystemPrompts'] as List?)
          ?.map((p) => SystemPrompt.fromJson(p as Map<String, dynamic>))
          .toList(),
      selectedSystemPromptId: json['selectedSystemPromptId'],
      locale: json['locale'],
      voiceAutoRead: json['voiceAutoRead'] ?? false,
      voiceSpeechRate: (json['voiceSpeechRate'] ?? 0.45).toDouble(),
      voicePitch: (json['voicePitch'] ?? 1.0).toDouble(),
      voiceName: json['voiceName'],
      voiceLanguage: json['voiceLanguage'] ?? 'en-US',
      // Older installs only had voiceLanguage — keep STT aligned until the
      // user picks a dedicated recognition language.
      voiceSttLanguage:
          json['voiceSttLanguage'] ?? json['voiceLanguage'] ?? 'en-US',
      voiceAutoSend: json['voiceAutoSend'] ?? false,
      voiceSttPauseForSeconds: json['voiceSttPauseForSeconds'] ?? 3,
      voiceSttListenForSeconds: json['voiceSttListenForSeconds'] ?? 60,
      voiceSttProvider: json['voiceSttProvider'] ?? 'whisper',
      whisperModelId: json['whisperModelId'] ?? 'tiny',
      voiceContinuousConversation: json['voiceContinuousConversation'] ?? true,
      voiceTtsProvider: (json['voiceTtsProvider'] == 'lm_studio')
          ? 'native'
          : (json['voiceTtsProvider'] ?? 'native'),
      voiceKokoroSpeakerId: json['voiceKokoroSpeakerId'] ?? 0,
      voiceKokoroSpeed: (json['voiceKokoroSpeed'] ?? 1.0).toDouble(),
      voiceElevenLabsApiKey: json['voiceElevenLabsApiKey'] as String?,
      voiceElevenLabsVoiceId: json['voiceElevenLabsVoiceId'] as String?,
      voiceElevenLabsModelId:
          (json['voiceElevenLabsModelId'] as String?)?.trim().isNotEmpty == true
              ? json['voiceElevenLabsModelId'] as String
              : 'eleven_v3_conversational',
      voiceGrokApiKey: json['voiceGrokApiKey'] as String?,
      voiceGrokVoiceId: json['voiceGrokVoiceId'] as String?,
      voiceRemoteKokoroUrl: json['voiceRemoteKokoroUrl'],
      voiceRemoteKokoroModel: json['voiceRemoteKokoroModel'],
      voiceCallMode: json['voiceCallMode'] ?? false,
      imageGenEnabled: json['imageGenEnabled'] ?? false,
      imageGenServerUrl: json['imageGenServerUrl'] ?? '',
      imageGenSelectedModel: json['imageGenSelectedModel'],
      imageGenNegativePrompt: json['imageGenNegativePrompt'] ??
          'blurry, bad quality, worst quality, low quality',
      imageGenSteps: json['imageGenSteps'] ?? 20,
      imageGenCfgScale: (json['imageGenCfgScale'] ?? 7.0).toDouble(),
      imageGenWidth: json['imageGenWidth'] ?? 512,
      imageGenHeight: json['imageGenHeight'] ?? 512,
      imageGenSamplerName: json['imageGenSamplerName'] ?? 'Euler a',
      imageGenScheduler: json['imageGenScheduler'],
      imageGenSeed: json['imageGenSeed'] ?? -1,
      imageGenBatchSize: json['imageGenBatchSize'] ?? 1,
      imageGenEnableHr: json['imageGenEnableHr'] ?? false,
      imageGenHrScale: (json['imageGenHrScale'] ?? 2.0).toDouble(),
      imageGenHrUpscaler: json['imageGenHrUpscaler'],
      imageGenDenoisingStrength:
          (json['imageGenDenoisingStrength'] ?? 0.7).toDouble(),
      imageGenRestoreFaces: json['imageGenRestoreFaces'] ?? false,
      imageGenTiling: json['imageGenTiling'] ?? false,
      imageGenReviewPrompt: json['imageGenReviewPrompt'] ?? false,
      imageGenAutoGenerate: json['imageGenAutoGenerate'] ?? false,
      imageGenProvider: (json['imageGenProvider'] as String?) ?? 'a1111',
      selectedLocalSdCheckpointId:
          json['selectedLocalSdCheckpointId'] as String?,
      comfyUiWorkflowJson: json['comfyUiWorkflowJson'] as String?,
      comfyUiWorkflowPath: json['comfyUiWorkflowPath'] as String?,
      comfyUiWorkflowSaveName: json['comfyUiWorkflowSaveName'] as String?,
      comfyUiClientId: json['comfyUiClientId'] as String?,
      comfyUiUseNegativePrompt:
          (json['comfyUiUseNegativePrompt'] as bool?) ?? false,
      comfyUiLoraName: json['comfyUiLoraName'] as String?,
      comfyUiLoraWeight: (json['comfyUiLoraWeight'] as num?)?.toDouble() ?? 1.0,
      comfyUiControlsLoadedFrom: json['comfyUiControlsLoadedFrom'] as String?,
      comfyUiWorkflowFields: _parseComfyWorkflowFields(
        json['comfyUiWorkflowFields'],
      ),
      remoteServerUrl: json['remoteServerUrl'],
      remoteAuthToken: json['remoteAuthToken'],
      isRemoteActive: json['isRemoteActive'] ?? false,
      remoteLastConnected: json['remoteLastConnected'],
      savedLocalServerUrl: json['savedLocalServerUrl'],
      savedLocalCloudBaseUrl: json['savedLocalCloudBaseUrl'] as String?,
      remoteEncryptionKey: json['remoteEncryptionKey'],
      remoteConnectVersion: json['remoteConnectVersion'] as String?,
      remoteBackends: (json['remoteBackends'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      remoteAutoReconnect: json['remoteAutoReconnect'] ?? false,
      homeSyncEnabled: json['homeSyncEnabled'] ?? false,
      homeSyncPrompted: json['homeSyncPrompted'] ?? false,
      homeSyncPersonasEnabled: json['homeSyncPersonasEnabled'] ?? false,
      homeSyncPersonaIds: (json['homeSyncPersonaIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      homeSyncPersonasUpdatedAt: DateTime.tryParse(
        json['homeSyncPersonasUpdatedAt'] as String? ?? '',
      ),
      liveActivityEnabled: json['liveActivityEnabled'] ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      aiExperienceLevel: json['aiExperienceLevel'] as String?,
      preferredUserName: json['preferredUserName'] as String?,
      expressionSpriteMode: const ['off', 'panel', 'avatar', 'both']
              .contains(json['expressionSpriteMode'])
          ? json['expressionSpriteMode'] as String
          : 'both',
      spritePanelCollapsed: json['spritePanelCollapsed'] as bool? ?? false,
      hasCompletedAudioSetup: json['hasCompletedAudioSetup'] ?? false,
      hasAcceptedArenaDataShare: json['hasAcceptedArenaDataShare'] ?? false,
      arenaShareAnonymousResults: json['arenaShareAnonymousResults'] ?? true,
      enterKeyBehavior: (json['enterKeyBehavior'] as String?) ?? 'auto',
      usbModeEnabled: (json['usbModeEnabled'] as bool?) ?? false,
      activeProviderKind: (json['activeProviderKind'] as String?) ?? 'lmStudio',
      selectedLocalModelId: json['selectedLocalModelId'] as String?,
      speculativeDecodingEnabled:
          (json['speculativeDecodingEnabled'] as bool?) ?? false,
    );
  }

  static ThemeMode _parseThemeMode(String? themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Merges the legacy dedicated Cloudflare Access fields into the generic
  /// custom-headers map so older settings persist as plain KV entries.
  static Map<String, String>? _migrateCustomRequestHeaders(
      Map<String, dynamic> json) {
    final base = (json['customRequestHeaders'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
        <String, String>{};
    final merged = Map<String, String>.from(base);
    final cfId = (json['cfAccessClientId'] as String?)?.trim();
    final cfSecret = (json['cfAccessClientSecret'] as String?)?.trim();
    if (cfId != null && cfId.isNotEmpty) {
      merged.putIfAbsent('CF-Access-Client-Id', () => cfId);
    }
    if (cfSecret != null && cfSecret.isNotEmpty) {
      merged.putIfAbsent('CF-Access-Client-Secret', () => cfSecret);
    }
    return merged.isEmpty ? null : merged;
  }

  /// Returns true if a legacy build had any header configuration so we keep
  /// it active after the master toggle was introduced.
  static bool _legacyCustomHeadersConfigured(Map<String, dynamic> json) {
    final hasMap = (json['customRequestHeaders'] as Map?)?.isNotEmpty ?? false;
    final hasCfId =
        ((json['cfAccessClientId'] as String?)?.trim().isNotEmpty) ?? false;
    final hasCfSecret =
        ((json['cfAccessClientSecret'] as String?)?.trim().isNotEmpty) ?? false;
    return hasMap || hasCfId || hasCfSecret;
  }
}
