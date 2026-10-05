import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../models/lm_studio_model.dart';
import '../models/system_prompt.dart';
import 'remote_host_backends.dart';

/// Provider • model line for a persona's preferred backend, or null when unset.
String? personaPreferredModelLabel(
  SystemPrompt persona, {
  required String anyModelLabel,
}) {
  return personaPreferredBackendLabel(
    providerKind: persona.defaultProviderKind,
    cloudProviderId: persona.defaultCloudProviderId,
    modelId: persona.defaultModelId,
    anyModelLabel: anyModelLabel,
  );
}

({String model, String provider})? personaPreferredModelParts(
  SystemPrompt persona, {
  required String anyModelLabel,
}) {
  return personaPreferredBackendParts(
    providerKind: persona.defaultProviderKind,
    cloudProviderId: persona.defaultCloudProviderId,
    modelId: persona.defaultModelId,
    anyModelLabel: anyModelLabel,
  );
}

String? personaPreferredBackendLabel({
  String? providerKind,
  String? cloudProviderId,
  String? modelId,
  required String anyModelLabel,
}) {
  final parts = personaPreferredBackendParts(
    providerKind: providerKind,
    cloudProviderId: cloudProviderId,
    modelId: modelId,
    anyModelLabel: anyModelLabel,
  );
  if (parts == null) return null;
  return '${parts.provider} • ${parts.model}';
}

({String model, String provider})? personaPreferredBackendParts({
  String? providerKind,
  String? cloudProviderId,
  String? modelId,
  required String anyModelLabel,
}) {
  if (providerKind == null && modelId == null) return null;
  final model = modelId == null || modelId.isEmpty
      ? anyModelLabel
      : LMStudioModel.friendlyLabel(modelId);
  return (
    model: model,
    provider: personaProviderDisplayName(providerKind, cloudProviderId),
  );
}

String personaProviderDisplayName(String? kind, [String? cloudProviderId]) {
  if (kind == null || kind.isEmpty) return 'Default';
  switch (kind) {
    case 'onDeviceGguf':
      return 'On-Device (GGUF)';
    case 'onDeviceMlx':
      return 'On-Device (MLX)';
    case 'cloud':
    case 'omlx':
    case 'ollama':
    case 'jan':
    case 'unsloth':
      if (cloudProviderId != null && cloudProviderId.isNotEmpty) {
        final cp = CloudApiService()
            .providers
            .where((p) => p.id == cloudProviderId)
            .firstOrNull;
        if (cp != null) return cp.name;
      }
      if (kind == 'cloud') return 'Cloud';
      return RemoteHostBackends.displayName(kind);
    default:
      return RemoteHostBackends.displayName(kind);
  }
}
