import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../models/app_settings.dart';
import '../models/arena_models.dart';
import '../models/lm_studio_model.dart';
import '../services/reasoning_support_service.dart';

/// Per-chat thinking on/off — same `reasoningEnabled` key as Chat Settings.
class ChatReasoningToggle {
  ChatReasoningToggle._();

  static String modelIdFor(AppSettings settings) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      return settings.selectedLocalModelId ?? settings.selectedModel ?? '';
    }
    return settings.selectedModel ?? '';
  }

  /// llama.cpp OpenAI-compat, Ollama `think`, and oMLX — not GPT-5 effort.
  static bool requestTypeSupportsNativeThink(CloudApiType type) {
    return type == CloudApiType.openaiCompatible ||
        type.isLocalOpenAiCompatible;
  }

  /// Any backend that can expose a thinking control in chat / Model Parameters.
  static bool requestTypeSupportsThinkingUi(CloudApiType type) {
    return requestTypeSupportsNativeThink(type) ||
        type.supportsReasoningEffort ||
        type.supportsZAiThinking;
  }

  /// Whether the composer / Chat Settings thinking control should appear.
  static bool shouldShow({
    required AppSettings settings,
    String? chatCloudProviderId,
    List<LMStudioModel> availableModels = const [],
    LMStudioModel? Function(String modelId)? resolveLmStudioModel,
  }) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return false;
    }

    final modelId = modelIdFor(settings);
    if (modelId.isEmpty) return false;

    bool looksLike() => modelLooksLikeReasoning(
          modelId,
          availableModels: availableModels,
          resolveLmStudioModel: resolveLmStudioModel,
        );

    // Home sidecar, native Ollama, and oMLX send think / enable_thinking.
    // Do not wait for CloudApiType.supportsReasoningEffort (GPT-5 / o-series).
    // Unsloth exposes a first-class enable_thinking flag (on by default).
    if (kind == 'unsloth') return true;
    if (kind == 'lmMiniDesktop' || CloudApiType.isFreeLocalKind(kind)) {
      return looksLike();
    }

    final provider = _cloudProvider(
      settings: settings,
      chatCloudProviderId: chatCloudProviderId,
    );
    if (provider != null) {
      if (requestTypeSupportsThinkingUi(provider.requestApiType)) {
        return looksLike();
      }
      return false;
    }

    if (kind == 'lmStudio' || kind.isEmpty) {
      final opts = ReasoningSupportService.instance.allowedOptionsSync(modelId);
      if (opts != null) return true;
      return looksLike();
    }

    return looksLike();
  }

  /// LM Studio models that omit a reasoning API cannot turn thinking off.
  static bool canControl({
    required AppSettings settings,
    String? chatCloudProviderId,
  }) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence' ||
        kind == 'lmMiniDesktop' ||
        kind == 'cloud' ||
        CloudApiType.isFreeLocalKind(kind)) {
      return true;
    }
    if (chatCloudProviderId != null && chatCloudProviderId.isNotEmpty) {
      return true;
    }
    final modelId = modelIdFor(settings);
    if (modelId.isEmpty) return true;
    return ReasoningSupportService.instance.exposesReasoningApiSync(modelId);
  }

  /// Persist like Chat Settings: store only when it differs from global.
  static Map<String, dynamic> applyToChatSettings(
    Map<String, dynamic> chatSettings, {
    required bool enabled,
    required bool globalReasoningOn,
    required bool canControl,
  }) {
    final next = Map<String, dynamic>.from(chatSettings);
    if (!canControl) {
      next.remove('reasoningEnabled');
      return next;
    }
    if (enabled == globalReasoningOn) {
      next.remove('reasoningEnabled');
    } else {
      next['reasoningEnabled'] = enabled;
    }
    return next;
  }

  static bool modelLooksLikeReasoning(
    String modelId, {
    List<LMStudioModel> availableModels = const [],
    LMStudioModel? Function(String modelId)? resolveLmStudioModel,
  }) {
    LMStudioModel? resolved;
    try {
      resolved = resolveLmStudioModel?.call(modelId);
    } catch (_) {}
    resolved ??= availableModels.where((m) => m.id == modelId).firstOrNull;
    if (resolved == null) {
      final needle = modelId.toLowerCase();
      final needleBase = needle.split('/').last;
      for (final m in availableModels) {
        final id = m.id.toLowerCase();
        final idBase = id.split('/').last;
        final display = m.displayName.toLowerCase();
        if (idBase == needleBase ||
            display == needle ||
            id.endsWith(needle) ||
            needle.endsWith(idBase)) {
          resolved = m;
          break;
        }
      }
    }
    if (resolved != null) {
      if (resolved.isReasoningModel) return true;
      if (ArenaContestant.looksLikeReasoningModel(
          resolved.id, resolved.displayName)) {
        return true;
      }
    }
    return ArenaContestant.looksLikeReasoningModel(modelId, null);
  }

  static CloudApiProvider? _cloudProvider({
    required AppSettings settings,
    String? chatCloudProviderId,
  }) {
    final cloud = CloudApiService();
    if (chatCloudProviderId != null && chatCloudProviderId.isNotEmpty) {
      final byId =
          cloud.providers.where((p) => p.id == chatCloudProviderId).firstOrNull;
      if (byId != null) return byId;
    }

    final kind = settings.activeProviderKind;
    if (kind != 'cloud' && !CloudApiType.isFreeLocalKind(kind)) {
      return null;
    }

    final active = cloud.activeProvider;
    if (active != null && active.type.providerKind == kind) {
      return active;
    }
    switch (kind) {
      case 'ollama':
        return cloud.providers
            .where((p) => p.type == CloudApiType.ollama)
            .firstOrNull;
      case 'omlx':
        return cloud.providers
            .where((p) => p.type == CloudApiType.omlx)
            .firstOrNull;
      case 'jan':
        return cloud.providers
            .where((p) => p.type == CloudApiType.jan)
            .firstOrNull;
      case 'unsloth':
        return cloud.providers
            .where((p) => p.type == CloudApiType.unsloth)
            .firstOrNull;
      case 'cloud':
        return cloud.providers.where((p) => p.type.isPremium).firstOrNull;
      default:
        return null;
    }
  }
}
