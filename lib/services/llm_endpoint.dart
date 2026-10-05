/// Unified abstraction over every chat backend the app can talk to.
///
/// Today the app routes through these code paths inside
/// `ChatProvider._sendMessageWithTools`:
///   1. `CloudApiProvider` (premium cloud APIs — OpenAI/OpenRouter/etc.)
///   2. `LMStudioService` V0/V1 (LM Studio)
///   3. `OllamaService` native `/api/chat` (Ollama — tools/MCP/Pro Search client-side)
///   4. Local tool loop (web search / MCP) layered on top of the above.
///
/// Phase 2/2b/3 add three more backends — fllama (on-device GGUF),
/// MLX-Swift (on-device MLX), and Apple FoundationModels. To avoid copying
/// the streaming/SSE/tool plumbing for each, every backend implements
/// [LLMEndpoint] and `ChatProvider` resolves a single endpoint per request.
///
/// **Phase 1 ships only the interface and adapter shells.** The existing
/// call sites are NOT migrated in this phase so we can verify the
/// abstraction lands cleanly without behavior change.
library;

/// Tier label so the UI can show a "Free" / "Pro" hint next to a backend
/// without coupling to the subscription package.
enum EndpointTier { free, pro }

/// What kind of backend this endpoint is — used for routing decisions and
/// for the connection-type picker in Settings.
enum EndpointKind {
  /// LM Studio / Ollama / any OpenAI-compatible HTTP server reachable on
  /// the network (the default LM Studio code path).
  lmStudio,

  /// User-configured cloud API (OpenAI, OpenRouter, Mistral, DeepSeek,
  /// Gemini, generic OpenAI-compatible).
  cloud,

  /// Local OpenAI-compatible inference server (oMLX). Wire-compatible with
  /// the cloud path but free, with localhost defaults.
  omlx,

  /// Local OpenAI-compatible inference server (Ollama). Free; defaults to
  /// http://localhost:11434 with optional Bearer auth for remote/cloud.
  /// Runtime chat uses native `OllamaService` (`/api/chat`), not `/v1`.
  ollama,

  /// On-device GGUF inference via fllama.
  onDeviceGguf,

  /// On-device MLX inference via the MlxEngine bridge.
  onDeviceMlx,

  /// Apple FoundationModels (iOS 26+).
  appleIntelligence,
}

/// Capability bits used by the chat UI and by `ChatProvider` to decide
/// whether to inject tools, show vision attachments, etc.
class EndpointCapabilities {
  /// Whether the active model supports OpenAI-style function/tool calling.
  /// When `false`, the tool-call UI is auto-hidden and `ChatProvider`
  /// skips the entire tools/MCP/Pro-Search branch.
  final bool supportsToolCalls;

  /// Whether the active model accepts image inputs.
  final bool supportsVision;

  /// Whether the endpoint supports server-side streaming (every endpoint
  /// we ship does today; field reserved for future non-streaming backends).
  final bool supportsStreaming;

  /// Whether requests are billed per-token (only true for cloud APIs).
  /// UI can show a small dollar-sign hint for these.
  final bool isMetered;

  const EndpointCapabilities({
    required this.supportsToolCalls,
    required this.supportsVision,
    this.supportsStreaming = true,
    this.isMetered = false,
  });

  static const EndpointCapabilities none = EndpointCapabilities(
    supportsToolCalls: false,
    supportsVision: false,
  );
}

/// Lightweight model descriptor returned by [LLMEndpoint.listModels].
/// Intentionally narrower than `LMStudioModel`/`CloudModelInfo` so it's
/// safe to surface in the cross-provider model picker.
class EndpointModelInfo {
  final String id;
  final String displayName;
  final bool supportsTools;
  final bool supportsVision;
  final int? contextLength;

  const EndpointModelInfo({
    required this.id,
    required this.displayName,
    this.supportsTools = false,
    this.supportsVision = false,
    this.contextLength,
  });
}

/// Abstract chat backend. Implementations live in the same `services/`
/// folder. See `LMStudioEndpoint`, `CloudEndpoint`, `OnDeviceFllamaEndpoint`,
/// `OnDeviceMlxEndpoint`, `AppleIntelligenceEndpoint`.
///
/// Note: this interface deliberately does NOT model the streaming chat call
/// yet. Migrating `ChatProvider._sendMessageWithTools` to call through this
/// happens in Phase 6 after every concrete endpoint is in place. For Phase
/// 1 we only need the interface to exist plus the discovery methods so the
/// connection picker can enumerate available endpoints.
abstract class LLMEndpoint {
  /// Stable identifier used for persistence (e.g. as a per-chat override).
  String get id;

  /// Backend kind for routing/UI.
  EndpointKind get kind;

  /// User-visible name for the connection picker.
  String get displayName;

  /// Tier hint for the UI.
  EndpointTier get tier;

  /// Capabilities for the currently-selected model (if any). May change
  /// when the user picks a different model from the same endpoint.
  EndpointCapabilities get capabilities;

  /// Whether the endpoint is reachable and configured. UI shows a status
  /// chip next to the endpoint name based on this.
  Future<bool> isAvailable();

  /// List models offered by this endpoint. May hit the network for cloud
  /// endpoints; cache results upstream.
  Future<List<EndpointModelInfo>> listModels();
}
