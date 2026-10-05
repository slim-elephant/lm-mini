/// Specification for a locally-runnable LLM (GGUF via fllama or MLX via the
/// MlxEngine bridge). Used by:
///   - `LocalModelCatalog` to enumerate curated and custom local models.
///   - `DeviceCapabilityService.verdict()` to decide whether the model will
///     run on the current device.
///   - `LocalModelDownloader` to resolve a Hugging Face download URL.
///
/// This is intentionally a pure data class (no Flutter imports) so it can be
/// reused from `lib/services/`, `lib/screens/`, and unit tests.
library;

/// Inference engine that should execute the model.
enum LocalEngine {
  /// llama.cpp via the fllama Flutter plugin. Cross-platform.
  fllama,

  /// mlx-swift via our custom MethodChannel/EventChannel bridge.
  /// Apple Silicon only (iOS + macOS).
  mlx,

  /// GGUF MoE expert streaming (BigMoeOnEdge). iOS device only for now —
  /// weights stay on flash; only routed experts enter RAM.
  moeStream,
}

/// Subscription tier required to download the model.
enum LocalModelTier { free, pro }

/// Outcome of `DeviceCapabilityService.verdict(spec)`.
enum ModelFit {
  /// Plenty of headroom; model should run comfortably.
  runs,

  /// Will load but may stutter or hit OOM under load.
  tight,

  /// Won't fit on this device; download should be blocked or warned.
  blocked,
}

/// A single local-model entry shown in the Local Models browser.
class LocalModelSpec {
  /// Stable id used for storage paths and as the persisted selection key.
  /// Convention: `"{publisher}/{repo}/{quant}"` (slashes will be slugified for
  /// the on-disk path).
  final String id;

  /// Human-readable name shown in the UI (e.g. "Qwen2.5 1.5B Instruct").
  final String displayName;

  /// Optional one-line description shown in the catalog row.
  final String? description;

  /// Hugging Face repo, e.g. `"Qwen/Qwen2.5-1.5B-Instruct-GGUF"`. For MLX
  /// entries, typically `"mlx-community/<name>"`.
  final String hfRepo;

  /// For GGUF: the single `.gguf` filename inside the repo.
  /// For MLX: null — the downloader pulls every file in the repo's root.
  final String? hfFile;

  /// Optional multimodal projector filename in the same HF repo (GGUF vision).
  /// Example: `"mmproj-model-f16.gguf"`. Downloaded next to [hfFile] and
  /// passed to fllama as `mmprojPath`.
  final String? mmprojHfFile;

  /// File size in megabytes (approximate, used for fit and storage warnings).
  final int sizeMb;

  /// Parameter count in billions (e.g. 1.5 for a 1.5B model). Used for the
  /// catalog badge and for sanity-checking fit verdicts.
  final double paramsB;

  /// Quantization label as it appears in the GGUF filename (e.g. `"Q4_K_M"`).
  /// Empty string for MLX entries (where quantization is baked into the repo).
  final String quantization;

  /// `LocalEngine.fllama` for GGUF, `LocalEngine.mlx` for MLX.
  final LocalEngine engine;

  /// Subscription tier required.
  final LocalModelTier tier;

  /// Chat template family for prompt building. Currently informational; the
  /// engine bridges read the model's own chat template when present.
  /// Values: `"chatml" | "llama3" | "qwen2" | "gemma" | "phi3" | "auto"`.
  final String chatTemplate;

  /// Whether the model's chat template supports the `tools` parameter.
  /// Drives the cross-provider tool-call UI auto-disable in Phase 6.
  final bool supportsToolCalls;

  /// Whether the model can take image inputs (vision-language model).
  final bool supportsVision;

  /// Hard minimum RAM (GB) required to load the model with a small context.
  /// `DeviceCapabilityService` cross-references this with the device's RAM.
  final double minRamGb;

  /// Optional spec id of the curated draft model to use for speculative
  /// decoding. Must share the target's tokenizer family. Null if no draft
  /// pair is registered.
  final String? draftModelId;

  /// Optional SHA-256 of the GGUF file (for verification after download).
  /// Null when the upstream repo doesn't publish one.
  final String? sha256;

  /// True for the single free-tier model that any user (even on a free plan)
  /// can download. The catalog should mark exactly one entry as `isFreeSlot`
  /// per device class; the downloader uses this to bypass the paywall.
  final bool isFreeSlot;

  /// True when the user imported a local model from the device file picker
  /// (GGUF file or MLX folder) instead of downloading from Hugging Face.
  final bool isImported;

  const LocalModelSpec({
    required this.id,
    required this.displayName,
    required this.hfRepo,
    required this.hfFile,
    required this.sizeMb,
    required this.paramsB,
    required this.quantization,
    required this.engine,
    required this.tier,
    required this.chatTemplate,
    required this.minRamGb,
    this.description,
    this.mmprojHfFile,
    this.supportsToolCalls = false,
    this.supportsVision = false,
    this.draftModelId,
    this.sha256,
    this.isFreeSlot = false,
    this.isImported = false,
  });

  /// Slugified on-disk subdirectory under `Documents/local_models/`.
  /// Example: `Qwen_Qwen2.5-1.5B-Instruct-GGUF__Q4_K_M`.
  String get diskSlug {
    if (isImported) {
      final fname = hfFile ?? id.split('/').last;
      final base = fname.replaceAll(RegExp(r'\.gguf$', caseSensitive: false), '');
      final safe = base.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
      return 'imported__$safe';
    }
    final repoSlug = hfRepo.replaceAll('/', '_');
    final quantSlug = quantization.isEmpty ? 'mlx' : quantization;
    return '${repoSlug}__$quantSlug';
  }

  /// Single-file GGUF on disk (fllama resident load, or MoE stream).
  bool get isGguf =>
      engine == LocalEngine.fllama || engine == LocalEngine.moeStream;

  /// Approximate runtime memory footprint in MB (file size + overhead).
  /// fllama (GGUF) needs more overhead for context + scratch buffers than
  /// MLX which loads weights directly into unified memory.
  /// MoE streaming keeps experts on flash — budget a ~3 GB working set
  /// (dense weights + expert cache + KV), not the full GGUF.
  int get estimatedRuntimeMb {
    if (engine == LocalEngine.moeStream) return 3200;
    final overhead = engine == LocalEngine.mlx ? 1.15 : 1.30;
    return (sizeMb * overhead).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'description': description,
        'hfRepo': hfRepo,
        'hfFile': hfFile,
        'mmprojHfFile': mmprojHfFile,
        'sizeMb': sizeMb,
        'paramsB': paramsB,
        'quantization': quantization,
        'engine': engine.name,
        'tier': tier.name,
        'chatTemplate': chatTemplate,
        'supportsToolCalls': supportsToolCalls,
        'supportsVision': supportsVision,
        'minRamGb': minRamGb,
        'draftModelId': draftModelId,
        'sha256': sha256,
        'isFreeSlot': isFreeSlot,
        'isImported': isImported,
      };

  factory LocalModelSpec.fromJson(Map<String, dynamic> json) => LocalModelSpec(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        description: json['description'] as String?,
        hfRepo: json['hfRepo'] as String,
        hfFile: json['hfFile'] as String?,
        mmprojHfFile: json['mmprojHfFile'] as String?,
        sizeMb: (json['sizeMb'] as num).toInt(),
        paramsB: (json['paramsB'] as num).toDouble(),
        quantization: json['quantization'] as String? ?? '',
        engine: LocalEngine.values.firstWhere(
          (e) => e.name == json['engine'],
          orElse: () => LocalEngine.fllama,
        ),
        tier: LocalModelTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => LocalModelTier.pro,
        ),
        chatTemplate: json['chatTemplate'] as String? ?? 'auto',
        supportsToolCalls: json['supportsToolCalls'] as bool? ?? false,
        supportsVision: json['supportsVision'] as bool? ?? false,
        minRamGb: (json['minRamGb'] as num?)?.toDouble() ?? 4.0,
        draftModelId: json['draftModelId'] as String?,
        sha256: json['sha256'] as String?,
        isFreeSlot: json['isFreeSlot'] as bool? ?? false,
        isImported: json['isImported'] as bool? ?? false,
      );
}
