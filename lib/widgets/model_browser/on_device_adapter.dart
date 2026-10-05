import '../../desktop/desktop_platform.dart';
import '../../models/arena_models.dart';
import '../../models/local_model_spec.dart';
import '../../models/pickable_model.dart';
import '../../services/device_capability_service.dart';
import '../../services/local_model_catalog.dart';
import '../../services/local_model_download_service.dart';

PickableModel mapOnDeviceModel({
  required LocalModelSpec spec,
  required LocalModelEntry? entry,
  required String? activeLocalId,
  DeviceCapability? cap,
  DeviceCapabilityService? capability,
  bool isRecommended = false,
  bool isFocused = false,
  bool isLoading = false,
  bool compactQuantName = false,
}) {
  final status = entry?.status ?? LocalModelStatus.notDownloaded;
  final fit = capability == null || cap == null
      ? ModelFit.runs
      : capability.verdict(spec, cap);
  final isDesktop = DesktopPlatform.isDesktop;

  String subtitle;
  switch (status) {
    case LocalModelStatus.ready:
      if (activeLocalId == spec.id) {
        subtitle = isLoading ? 'Loading…' : 'Loaded';
      } else if (isDesktop) {
        subtitle = 'On this Mac · tap to load';
      } else {
        subtitle = 'On this phone';
      }
    case LocalModelStatus.downloading:
      final pct = ((entry?.progress ?? 0) * 100).round();
      subtitle = 'Downloading… $pct%';
    case LocalModelStatus.failed:
      subtitle = 'Download failed';
    case LocalModelStatus.notDownloaded:
      subtitle = isFocused ? 'Selected · tap Download below' : 'Needs download';
  }

  if (status == LocalModelStatus.ready ||
      status == LocalModelStatus.notDownloaded) {
    if (fit == ModelFit.tight) {
      subtitle = '$subtitle · May be tight on RAM';
    } else if (fit == ModelFit.blocked) {
      subtitle = '$subtitle · Likely too large';
    }
  }

  final size = friendlySizeLabel(sizeMb: spec.sizeMb);
  final type = spec.engine == LocalEngine.mlx
      ? 'MLX'
      : spec.engine == LocalEngine.moeStream
          ? 'GGUF stream'
          : 'GGUF';
  final quantLabel = LocalModelCatalog.quantLabel(spec);
  final reasoning =
      ArenaContestant.looksLikeReasoningModel(spec.id, spec.displayName);
  final displayName = compactQuantName
      ? (quantLabel.isEmpty ? type : '$type · $quantLabel')
      : spec.displayName;

  final details = <ModelDetailRow>[
    ModelDetailRow('ID', spec.id),
    if (spec.description != null && spec.description!.isNotEmpty)
      ModelDetailRow('Description', spec.description!),
    ModelDetailRow('Engine', type),
    if (spec.quantization.isNotEmpty)
      ModelDetailRow('Quantization', spec.quantization),
    ModelDetailRow('Parameters', '${spec.paramsB}B'),
    ModelDetailRow('Size', '${spec.sizeMb} MB'),
    ModelDetailRow('Min RAM', '${spec.minRamGb} GB'),
    ModelDetailRow(
      'Fit',
      fit == ModelFit.runs
          ? 'Runs comfortably'
          : fit == ModelFit.tight
              ? 'Tight'
              : 'Blocked',
    ),
    if (spec.hfRepo.isNotEmpty) ModelDetailRow('Hugging Face', spec.hfRepo),
    if (spec.hfFile != null) ModelDetailRow('File', spec.hfFile!),
    if (entry?.localPath != null) ModelDetailRow('Path', entry!.localPath!),
    ModelDetailRow('Vision', spec.supportsVision ? 'Yes' : 'No'),
    ModelDetailRow('Tool calls', spec.supportsToolCalls ? 'Yes' : 'No'),
    if (spec.isImported) const ModelDetailRow('Source', 'Imported'),
    if (spec.isFreeSlot) const ModelDetailRow('Plan', 'Free slot'),
  ];

  // All / Downloaded filters: anything on-device shares "downloaded".
  final String statusKey;
  switch (status) {
    case LocalModelStatus.ready:
    case LocalModelStatus.downloading:
    case LocalModelStatus.failed:
      statusKey = 'downloaded';
    case LocalModelStatus.notDownloaded:
      statusKey = 'catalog';
  }

  return PickableModel(
    id: spec.id,
    displayName: displayName,
    subtitle: subtitle,
    supportsVision: spec.supportsVision,
    isReasoning: reasoning,
    isLoaded: status == LocalModelStatus.ready &&
        activeLocalId == spec.id &&
        !isLoading,
    isSelected: activeLocalId == spec.id || isFocused,
    isLoading: isLoading,
    isRecommended: isRecommended,
    familyGroup: compactQuantName
        ? LocalModelCatalog.modelLine(spec)
        : LocalModelCatalog.familyGroup(spec),
    sizeLabel: size.isEmpty ? null : size,
    typeLabel: type,
    quantLabel: quantLabel.isEmpty ? null : quantLabel,
    providerKind: ModelProviderKind.onDevice,
    details: details,
    downloadProgress:
        status == LocalModelStatus.downloading ? entry?.progress : null,
    statusKey: statusKey,
    source: spec,
  );
}
