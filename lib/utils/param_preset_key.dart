import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../models/app_settings.dart';

/// Stable map key for a per-model [ParamPreset].
///
/// Format:
/// - Local / on-device: `providerKind::modelId`
/// - Cloud / Ollama / oMLX: `providerKind::cloudProviderId::modelId`
///
/// Lookup must use the **effective** model for the send (chat override, group
/// participant, or Settings selection), not only the globally selected model.
class ParamPresetKey {
  ParamPresetKey._();

  static bool usesCloudProviderId(String providerKind) {
    return providerKind == 'cloud' ||
        CloudApiType.isFreeLocalKind(providerKind);
  }

  /// Chat / on-device model id currently selected on [settings].
  static String? selectedModelId(AppSettings settings) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      final id = settings.selectedLocalModelId?.trim();
      return (id == null || id.isEmpty) ? null : id;
    }
    final id = settings.selectedModel?.trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  static String? build({
    required String providerKind,
    String? modelId,
    String? cloudProviderId,
  }) {
    final id = modelId?.trim() ?? '';
    if (id.isEmpty) return null;
    final kind = providerKind.trim().isEmpty ? 'lmStudio' : providerKind.trim();
    if (usesCloudProviderId(kind)) {
      final cp = cloudProviderId?.trim() ?? '';
      if (cp.isNotEmpty) return '$kind::$cp::$id';
    }
    return '$kind::$id';
  }

  static String? fromSettings(
    AppSettings settings, {
    String? cloudProviderId,
  }) {
    return build(
      providerKind: settings.activeProviderKind,
      modelId: selectedModelId(settings),
      cloudProviderId: cloudProviderId,
    );
  }
}
