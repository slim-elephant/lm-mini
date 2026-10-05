import '../../models/arena_models.dart';
import '../../models/lm_studio_model.dart';
import '../../models/pickable_model.dart';

PickableModel mapLmStudioModel({
  required LMStudioModel model,
  required String? selectedModelId,
  required bool isPinned,
  String? loadingModelId,
  ModelProviderKind kind = ModelProviderKind.lmStudio,
}) {
  final type = _typeLabel(model);
  final size = friendlySizeLabel(bytes: model.sizeBytes);
  final reasoning = model.isReasoningModel ||
      ArenaContestant.looksLikeReasoningModel(model.id, model.displayName);

  final selected = model.id == selectedModelId;
  final loading = loadingModelId != null && loadingModelId == model.id;
  String subtitle;
  if (kind == ModelProviderKind.cloud) {
    subtitle = selected ? 'Selected' : 'Available';
  } else if (kind == ModelProviderKind.ollama) {
    subtitle = selected ? 'Ready to chat' : 'On Ollama';
  } else if (loading) {
    subtitle = 'Loading…';
  } else if (model.isLoaded && selected) {
    subtitle = 'Loaded · selected for chat';
  } else if (model.isLoaded) {
    subtitle = 'Loaded in ${_runtimeLabel(model)}';
  } else if (selected) {
    subtitle = 'Selected · needs load';
  } else {
    subtitle = 'On ${_runtimeLabel(model)}';
  }

  final details = <ModelDetailRow>[
    ModelDetailRow('ID', model.id),
    if (model.publisher.isNotEmpty)
      ModelDetailRow('Publisher', model.publisher),
    if (model.arch.isNotEmpty) ModelDetailRow('Architecture', model.arch),
    if (model.quantizationDisplay.isNotEmpty)
      ModelDetailRow('Quantization', model.quantizationDisplay),
    if (model.format != null && model.format!.isNotEmpty)
      ModelDetailRow('Format', model.format!),
    if (model.maxContextLength > 0)
      ModelDetailRow('Max context', '${model.maxContextLength}'),
    if (model.loadedContextLength != null)
      ModelDetailRow('Loaded context', '${model.loadedContextLength}'),
    if (model.flashAttention != null)
      ModelDetailRow('Flash attention', model.flashAttention! ? 'Yes' : 'No'),
    ModelDetailRow('State', model.state),
    if (model.type.isNotEmpty) ModelDetailRow('Type', model.type),
    if (model.sizeBytes != null) ModelDetailRow('Size', model.formattedSize),
  ];

  return PickableModel(
    id: model.id,
    displayName: kind == ModelProviderKind.cloud
        ? _cleanCloudId(model.displayName)
        : model.displayName,
    subtitle: subtitle,
    supportsVision: model.supportsVision ||
        ArenaContestant.looksLikeVisionModel(model.id, model.displayName),
    isReasoning: reasoning,
    isLoaded: model.isLoaded,
    isSelected: selected,
    isPinned: isPinned,
    isLoading: loading,
    sizeLabel: size.isEmpty ? null : size,
    typeLabel: kind == ModelProviderKind.cloud ? null : type,
    quantLabel: model.quantization.isEmpty || model.quantization == 'unknown'
        ? null
        : model.quantization,
    providerKind: kind,
    details: details,
    statusKey: model.isLoaded
        ? 'ready'
        : (kind == ModelProviderKind.lmStudio ? 'downloaded' : 'ready'),
    source: model,
  );
}

String _runtimeLabel(LMStudioModel model) {
  switch (model.publisher.trim()) {
    case 'Unsloth':
    case 'JAN AI':
    case 'oMLX':
      return model.publisher.trim();
    default:
      return 'LM Studio';
  }
}

String? _typeLabel(LMStudioModel model) {
  final f = (model.format ?? model.compatibilityType).toLowerCase();
  if (f.contains('mlx')) return 'MLX';
  if (f.contains('gguf')) return 'GGUF';
  if (f.isNotEmpty) return f.toUpperCase();
  return null;
}

String _cleanCloudId(String id) => LMStudioModel.friendlyLabel(id);
