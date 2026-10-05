import '../models/app_settings.dart';
import '../models/lm_studio_model.dart';
import '../utils/ollama_tool_support.dart';
import 'local_model_catalog.dart';
import 'local_model_download_service.dart';

/// Single source of truth for "does the currently-selected model support
/// OpenAI-style tool calling?"
///
/// Used by:
///   - The chat settings dialog → to hide/disable the "Tool use" toggle
///     when the active model can't honor it.
///   - `ChatProvider._sendMessageWithTools` → to skip the tool-injection /
///     MCP / Pro Search branch when the active model lacks tools (avoids
///     cryptic "tool calls aren't supported" errors).
///   - The message input → to hide the Tools chip on incompatible models.
///
/// Resolution rules:
///   - On-device GGUF/MLX: use `LocalModelSpec.supportsToolCalls`.
///     Unknown / custom user-added models default to `false` (conservative
///     — small on-device models often lack a tools-capable chat template).
///   - Apple Intelligence: always `true` (FoundationModels has first-class
///     tool support).
///   - Ollama: `availableModels.toolUseCapability` from `/api/show` when
///     present; otherwise a conservative name heuristic (unknown / coder
///     models default off).
///   - Cloud / oMLX / LM Studio: `true` by default (preserves today's
///     behavior; richer per-model detection is a follow-up).
///
/// Synchronous so widget `build` methods can call this directly.
class ToolSupportResolver {
  ToolSupportResolver._();
  static final ToolSupportResolver instance = ToolSupportResolver._();

  /// Whether the active backend can participate in tool / Pro Search flows at all.
  bool providerSupportsToolCalling(String? activeProviderKind) {
    switch (activeProviderKind) {
      case 'onDeviceGguf':
      case 'onDeviceMlx':
      case 'appleIntelligence':
      case 'lmStudio':
      case 'cloud':
      case 'omlx':
      case 'ollama':
      case 'jan':
      case 'unsloth':
        return true;
      default:
        return true;
    }
  }

  /// Whether Pro Search should appear in the chat composer for premium users.
  bool canShowProSearch(
    AppSettings settings, {
    required bool isPremium,
    List<LMStudioModel>? availableModels,
  }) {
    if (!isPremium) return false;
    if (!settings.enableToolUse) return false;
    if (settings.preferSearxng && settings.searxngUrl?.isNotEmpty == true) {
      return false;
    }
    return currentModelSupportsTools(
      settings,
      availableModels: availableModels,
    );
  }

  bool currentModelSupportsTools(
    AppSettings settings, {
    List<LMStudioModel>? availableModels,
  }) {
    if (!providerSupportsToolCalling(settings.activeProviderKind)) {
      return false;
    }

    final selectedId = settings.selectedModel;
    if (availableModels != null &&
        selectedId != null &&
        selectedId.trim().isNotEmpty) {
      final selectedLower = selectedId.toLowerCase();
      for (final model in availableModels) {
        if (model.id.toLowerCase() != selectedLower) continue;
        if (model.toolUseCapability == true) return true;
        if (model.toolUseCapability == false) return false;
        if (model.capabilities?.contains('tool_use') == true) return true;
        break;
      }
    }

    switch (settings.activeProviderKind) {
      case 'onDeviceGguf':
      case 'onDeviceMlx':
        final id = settings.selectedLocalModelId;
        if (id == null) return false;
        final spec = LocalModelCatalog.byId(id) ??
            LocalModelDownloadService.instance.entryById(id)?.spec;
        return spec?.supportsToolCalls ?? false;

      case 'appleIntelligence':
        return true;

      case 'ollama':
        return _ollamaModelSupportsTools(settings.selectedModel);

      case 'cloud':
      case 'omlx':
      case 'jan':
      case 'unsloth':
        return true;

      case 'lmStudio':
      default:
        return true;
    }
  }

  bool _ollamaModelSupportsTools(String? modelId) {
    return OllamaToolSupport.heuristic(modelId);
  }
}
