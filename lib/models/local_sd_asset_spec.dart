/// Specification for a locally-runnable Stable Diffusion asset (checkpoint,
/// LoRA, or VAE). Mirrors [LocalModelSpec] in the LLM on-device pipeline.
///
/// Used by:
///   - `LocalSdAssetCatalog` to enumerate curated and custom SD assets.
///   - `LocalSdAssetDownloadService` to resolve a Hugging Face URL and
///     track download progress.
///   - `OnDeviceSdEndpoint` (future) to load and run the asset through the
///     Core ML Stable Diffusion runtime on Apple Silicon devices.
///
/// Pure data class — no Flutter imports — so it is safe to reuse from
/// `lib/services/`, `lib/screens/`, and unit tests.
library;

/// Inference runtime that should execute the SD pipeline. Today only
/// `coreml` is wired (via Apple's `apple/coreml-stable-diffusion` pipeline)
/// because it has the broadest Apple-device support. `mlxSd` and
/// `stableDiffusionCpp` are reserved for future expansion.
enum SdEngine {
  /// Apple's `apple/ml-stable-diffusion` Core ML pipeline. iOS 16.2+ /
  /// macOS 13.1+, Apple Silicon required.
  coreml,

  /// `mlx-swift` Stable Diffusion bindings. Apple Silicon only.
  mlxSd,

  /// `stable-diffusion.cpp` via FFI. Cross-platform fallback.
  stableDiffusionCpp,
}

/// What kind of artifact this entry is. The free tier may have exactly one
/// `isFreeSlot` entry per kind (one checkpoint, one LoRA, one VAE).
enum SdAssetKind { checkpoint, lora, vae }

/// Subscription tier required to download the asset.
enum SdAssetTier { free, pro }

/// A single SD asset entry shown in the on-device SD browser.
class LocalSdAssetSpec {
  /// Stable id used for storage paths and as the persisted selection key.
  /// Convention: `"{publisher}/{repo}/{variant}"`.
  final String id;

  /// Human-readable name shown in the catalog row.
  final String displayName;

  /// Optional one-line description for the row subtitle.
  final String? description;

  /// Hugging Face repo, e.g. `"apple/coreml-stable-diffusion-2-1-base"`.
  final String hfRepo;

  /// For single-file assets (LoRA `.safetensors`, VAE `.safetensors`): the
  /// single filename inside the repo. For multi-file Core ML pipelines:
  /// `null` — the downloader pulls every file under [hfSubfolder] (or the
  /// repo root if [hfSubfolder] is null).
  final String? hfFile;

  /// Optional subfolder within the HF repo to mirror. Used for Core ML SD
  /// repos that ship multiple variants under
  /// `original/compiled/`, `split_einsum/compiled/`, etc.
  final String? hfSubfolder;

  /// Approximate file/directory size in megabytes.
  final int sizeMb;

  /// Which engine runtime can load this asset.
  final SdEngine engine;

  /// Subscription tier required.
  final SdAssetTier tier;

  /// What kind of artifact this is.
  final SdAssetKind kind;

  /// For checkpoints: the natively-supported resolution (e.g. 512 or 768).
  /// Drives the default width/height in the generation form.
  final int? nativeResolution;

  /// Whether this checkpoint supports negative prompts. Mostly true; SD-2
  /// turbo / lightning models often don't.
  final bool supportsNegativePrompt;

  /// Hard minimum free RAM (GB) required to run the pipeline. Cross-checked
  /// against the device by `DeviceCapabilityService`.
  final double minRamGb;

  /// Optional SHA-256 for verification after download. Single-file assets
  /// only — multi-file Core ML pipelines have per-file hashes published in
  /// the repo and we trust HF.
  final String? sha256;

  /// True for the single free-tier entry for [kind]. The catalog must mark
  /// exactly one entry per kind as `isFreeSlot`; the downloader and UI
  /// use this to bypass the paywall.
  final bool isFreeSlot;

  const LocalSdAssetSpec({
    required this.id,
    required this.displayName,
    required this.hfRepo,
    required this.hfFile,
    required this.sizeMb,
    required this.engine,
    required this.tier,
    required this.kind,
    required this.minRamGb,
    this.description,
    this.hfSubfolder,
    this.nativeResolution,
    this.supportsNegativePrompt = true,
    this.sha256,
    this.isFreeSlot = false,
  });

  /// Slugified on-disk subdirectory under `Documents/local_sd_models/<kind>/`.
  String get diskSlug {
    final repoSlug = hfRepo.replaceAll('/', '_');
    final variant = hfSubfolder?.replaceAll('/', '_') ?? hfFile ?? 'all';
    return '${repoSlug}__$variant';
  }

  /// Approximate runtime memory footprint in MB (Core ML compiled models
  /// load weights from disk on demand, so overhead is lower than LLMs).
  int get estimatedRuntimeMb {
    final overhead = engine == SdEngine.coreml ? 1.10 : 1.25;
    return (sizeMb * overhead).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'description': description,
        'hfRepo': hfRepo,
        'hfFile': hfFile,
        'hfSubfolder': hfSubfolder,
        'sizeMb': sizeMb,
        'engine': engine.name,
        'tier': tier.name,
        'kind': kind.name,
        'nativeResolution': nativeResolution,
        'supportsNegativePrompt': supportsNegativePrompt,
        'minRamGb': minRamGb,
        'sha256': sha256,
        'isFreeSlot': isFreeSlot,
      };

  factory LocalSdAssetSpec.fromJson(Map<String, dynamic> json) =>
      LocalSdAssetSpec(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        description: json['description'] as String?,
        hfRepo: json['hfRepo'] as String,
        hfFile: json['hfFile'] as String?,
        hfSubfolder: json['hfSubfolder'] as String?,
        sizeMb: (json['sizeMb'] as num).toInt(),
        engine: SdEngine.values.firstWhere(
          (e) => e.name == json['engine'],
          orElse: () => SdEngine.coreml,
        ),
        tier: SdAssetTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => SdAssetTier.pro,
        ),
        kind: SdAssetKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => SdAssetKind.checkpoint,
        ),
        nativeResolution: (json['nativeResolution'] as num?)?.toInt(),
        supportsNegativePrompt:
            json['supportsNegativePrompt'] as bool? ?? true,
        minRamGb: (json['minRamGb'] as num?)?.toDouble() ?? 4.0,
        sha256: json['sha256'] as String?,
        isFreeSlot: json['isFreeSlot'] as bool? ?? false,
      );
}
