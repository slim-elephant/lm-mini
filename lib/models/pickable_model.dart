/// Thin UI model for the Settings model browser.
///
/// Adapters map LM Studio / Ollama / Cloud / on-device sources into this shape
/// so [ModelBrowserScreen] can render one balanced row + details sheet.
library;

enum ModelProviderKind {
  lmStudio,
  ollama,
  cloud,
  onDevice,
}

/// One technical key/value line in the ⓘ details sheet.
class ModelDetailRow {
  final String label;
  final String value;

  const ModelDetailRow(this.label, this.value);
}

class PickableModel {
  final String id;
  final String displayName;

  /// Plain-English status line (e.g. "Ready to chat", "Needs download").
  final String? subtitle;

  final bool supportsVision;
  final bool isReasoning;
  final bool isLoaded;
  final bool isSelected;
  final bool isPinned;

  /// True while LM Studio (or similar) is loading this model into memory.
  final bool isLoading;

  /// Highlighted as a good fit for this device.
  final bool isRecommended;

  /// Brand/family for grouped browsing (Qwen, Meta, Google, …).
  final String? familyGroup;

  /// Friendly size, e.g. "About 6 GB".
  final String? sizeLabel;

  /// Local format label: `GGUF`, `MLX`, etc. Null for cloud.
  final String? typeLabel;

  /// Quantization label for a chip, e.g. `Q4_K_M` or `4bpw`. Null when unknown.
  final String? quantLabel;

  final ModelProviderKind providerKind;

  /// Nerdy specs for the ⓘ sheet.
  final List<ModelDetailRow> details;

  /// 0–1 while downloading; null otherwise.
  final double? downloadProgress;

  /// Filter bucket: `ready`, `downloaded`, `loaded`, `catalog`, …
  final String? statusKey;

  /// Original source object for adapter actions (LMStudioModel, LocalModelSpec, …).
  final Object? source;

  const PickableModel({
    required this.id,
    required this.displayName,
    this.subtitle,
    this.supportsVision = false,
    this.isReasoning = false,
    this.isLoaded = false,
    this.isSelected = false,
    this.isPinned = false,
    this.isLoading = false,
    this.isRecommended = false,
    this.familyGroup,
    this.sizeLabel,
    this.typeLabel,
    this.quantLabel,
    required this.providerKind,
    this.details = const [],
    this.downloadProgress,
    this.statusKey,
    this.source,
  });
}

/// Friendly disk-size copy for row chips.
String friendlySizeLabel({int? bytes, int? sizeMb}) {
  double? gb;
  if (bytes != null && bytes > 0) {
    gb = bytes / (1024 * 1024 * 1024);
  } else if (sizeMb != null && sizeMb > 0) {
    gb = sizeMb / 1024;
  }
  if (gb == null) return '';
  if (gb < 0.1) {
    final mb = (sizeMb ?? (bytes! / (1024 * 1024))).round();
    return '$mb MB';
  }
  if (gb < 10) return '${gb.toStringAsFixed(1)} GB';
  return '${gb.toStringAsFixed(0)} GB';
}
