import '../models/app_settings.dart';
import '../models/param_preset.dart';
import '../models/system_prompt.dart';
import '../pro/params/param_preset_overlay.dart';

/// Resolution order for generation / load knobs:
/// **chat override → persona custom (if on) → model preset → global**.
///
/// Model and persona overlays are Pro-only. Free users always get Global
/// (plus any per-chat sampler overrides). Stored presets are left intact so
/// they return when the user is Pro again.
class ParamPresetResolver {
  ParamPresetResolver._();

  static AppSettings overlay({
    required AppSettings global,
    required bool isPremium,
    String? modelKey,
    SystemPrompt? persona,
    Map<String, dynamic> chatSettings = const {},
  }) {
    var settings = global;
    if (isPremium) {
      settings = ProParamOverlay.apply(
        global: global,
        modelKey: modelKey,
        persona: persona,
      );
    }
    return applyChatSamplerOverrides(settings, chatSettings);
  }

  static ParamPreset? lookup(
    Map<String, ParamPreset> presets,
    String? key,
  ) {
    if (key == null || key.isEmpty) return null;
    return presets[key];
  }

  /// Per-chat sampler keys historically stored on [ChatConversation.settings].
  static AppSettings applyChatSamplerOverrides(
    AppSettings settings,
    Map<String, dynamic> chatSettings,
  ) {
    if (chatSettings.isEmpty) return settings;

    var next = settings;
    if (chatSettings.containsKey('temperature')) {
      next = next.copyWith(
        temperature: (chatSettings['temperature'] as num?)?.toDouble() ??
            settings.temperature,
      );
    }
    if (chatSettings.containsKey('maxTokens')) {
      next = next.copyWith(
        maxTokens:
            (chatSettings['maxTokens'] as num?)?.toInt() ?? settings.maxTokens,
      );
    }
    if (chatSettings.containsKey('topP')) {
      next = next.copyWith(
        topP: (chatSettings['topP'] as num?)?.toDouble() ?? settings.topP,
      );
    }
    if (chatSettings.containsKey('topK')) {
      next = next.copyWith(
        topK: (chatSettings['topK'] as num?)?.toInt() ?? settings.topK,
      );
    }
    if (chatSettings.containsKey('minP')) {
      next = next.copyWith(
        minP: (chatSettings['minP'] as num?)?.toDouble() ?? settings.minP,
      );
    }
    if (chatSettings.containsKey('repeatPenalty')) {
      next = next.copyWith(
        repeatPenalty: (chatSettings['repeatPenalty'] as num?)?.toDouble() ??
            settings.repeatPenalty,
      );
    }
    if (chatSettings.containsKey('reasoningEnabled')) {
      final enabled = chatSettings['reasoningEnabled'] as bool? ?? true;
      next = next.copyWith(reasoning: enabled ? 'on' : 'off');
    }
    return next;
  }
}
