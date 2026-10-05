import '../models/local_sd_asset_spec.dart';

/// Curated catalog of on-device Stable Diffusion assets. Mirrors
/// [LocalModelCatalog] for LLMs.
///
/// Free-tier rules (matching the LLM catalog convention):
///   - Exactly **one** entry per [SdAssetKind] is marked `isFreeSlot: true`.
///   - Free users may download any `isFreeSlot` entry without a paywall.
///   - Pro users may download anything plus add custom HF repos.
///
/// Sizes/RAM estimates are approximate. They're used by
/// `DeviceCapabilityService` to gate downloads on low-memory devices.
class LocalSdAssetCatalog {
  LocalSdAssetCatalog._();

  /// All curated assets, in display order (free slot first within each kind).
  static const List<LocalSdAssetSpec> entries = [
    // ── Checkpoints ──────────────────────────────────────────────────────
    // FREE SLOT — Apple's split-einsum SD 2.1 base. Chunked Unet only (~2.6 GB);
    // monolithic Unet is omitted as redundant.
    LocalSdAssetSpec(
      id: 'apple/coreml-sd-2-1-base/split-einsum',
      displayName: 'Stable Diffusion 2.1 Base (Apple)',
      description: '512×512, Apple Core ML split-einsum. Smallest pipeline.',
      hfRepo: 'apple/coreml-stable-diffusion-2-1-base',
      hfFile: null,
      hfSubfolder: 'split_einsum/compiled',
      sizeMb: 2600,
      engine: SdEngine.coreml,
      tier: SdAssetTier.free,
      kind: SdAssetKind.checkpoint,
      nativeResolution: 512,
      minRamGb: 4.0,
      isFreeSlot: true,
    ),

    // PRO — SDXL Base 1.0 (Apple), 1024×1024. Larger but much higher quality.
    LocalSdAssetSpec(
      id: 'apple/coreml-sdxl-base-1.0/split-einsum',
      displayName: 'SDXL Base 1.0 (Apple)',
      description: '1024×1024, Apple Core ML split-einsum. High quality.',
      hfRepo: 'apple/coreml-stable-diffusion-xl-base',
      hfFile: null,
      hfSubfolder: 'split_einsum/compiled',
      sizeMb: 5800,
      engine: SdEngine.coreml,
      tier: SdAssetTier.pro,
      kind: SdAssetKind.checkpoint,
      nativeResolution: 1024,
      minRamGb: 8.0,
    ),

    // PRO — Apple's distilled SDXL Turbo, ~4-step inference.
    LocalSdAssetSpec(
      id: 'apple/coreml-sdxl-turbo/split-einsum',
      displayName: 'SDXL Turbo (Apple)',
      description: '512×512, single-step Core ML pipeline. Very fast.',
      hfRepo: 'apple/coreml-stable-diffusion-xl-base',
      hfFile: null,
      hfSubfolder: 'split_einsum_v2/compiled',
      sizeMb: 5600,
      engine: SdEngine.coreml,
      tier: SdAssetTier.pro,
      kind: SdAssetKind.checkpoint,
      nativeResolution: 512,
      supportsNegativePrompt: false,
      minRamGb: 8.0,
    ),

    // PRO — Stable Diffusion 1.5 (Apple Core ML). Similar download size to
    // SD 2.1 once the redundant mono-Unet is omitted (~2.7 GB).
    LocalSdAssetSpec(
      id: 'apple/coreml-sd-1-5/split-einsum',
      displayName: 'Stable Diffusion 1.5',
      description: '512×512, classic SD v1.5 aesthetic. Similar size to 2.1.',
      hfRepo: 'apple/coreml-stable-diffusion-v1-5',
      hfFile: null,
      hfSubfolder: 'split_einsum/compiled',
      sizeMb: 2700,
      engine: SdEngine.coreml,
      tier: SdAssetTier.pro,
      kind: SdAssetKind.checkpoint,
      nativeResolution: 512,
      minRamGb: 4.0,
    ),

    // ── LoRAs ────────────────────────────────────────────────────────────
    // FREE SLOT — LCM-LoRA for SD 1.5 (latent consistency, 4-step inference).
    LocalSdAssetSpec(
      id: 'latent-consistency/lcm-lora-sdv1-5',
      displayName: 'LCM-LoRA (SD 1.5)',
      description: '4-step inference adapter. Faster generation.',
      hfRepo: 'latent-consistency/lcm-lora-sdv1-5',
      hfFile: 'pytorch_lora_weights.safetensors',
      sizeMb: 134,
      engine: SdEngine.coreml,
      tier: SdAssetTier.free,
      kind: SdAssetKind.lora,
      minRamGb: 0.5,
      isFreeSlot: true,
    ),

    // PRO LoRAs
    LocalSdAssetSpec(
      id: 'latent-consistency/lcm-lora-sdxl',
      displayName: 'LCM-LoRA (SDXL)',
      description: '4-step inference adapter for SDXL pipelines.',
      hfRepo: 'latent-consistency/lcm-lora-sdxl',
      hfFile: 'pytorch_lora_weights.safetensors',
      sizeMb: 394,
      engine: SdEngine.coreml,
      tier: SdAssetTier.pro,
      kind: SdAssetKind.lora,
      minRamGb: 0.5,
    ),
    LocalSdAssetSpec(
      id: 'ostris/super-cereal-sdxl-lora',
      displayName: 'Super Cereal (SDXL)',
      description: 'Vibrant illustrated cereal-box aesthetic.',
      hfRepo: 'ostris/super-cereal-sdxl-lora',
      hfFile: 'cereal_box_sdxl_v1.safetensors',
      sizeMb: 230,
      engine: SdEngine.coreml,
      tier: SdAssetTier.pro,
      kind: SdAssetKind.lora,
      minRamGb: 0.5,
    ),

    // ── VAEs ─────────────────────────────────────────────────────────────
    // FREE SLOT — Stability's improved VAE for SD 1.5 / 2.x. ~335 MB.
    LocalSdAssetSpec(
      id: 'stabilityai/sd-vae-ft-mse-original',
      displayName: 'SD VAE FT-MSE',
      description: 'Improved Stability VAE for SD 1.5 / 2.x.',
      hfRepo: 'stabilityai/sd-vae-ft-mse-original',
      hfFile: 'vae-ft-mse-840000-ema-pruned.safetensors',
      sizeMb: 335,
      engine: SdEngine.coreml,
      tier: SdAssetTier.free,
      kind: SdAssetKind.vae,
      minRamGb: 0.5,
      isFreeSlot: true,
    ),

    // PRO VAEs
    LocalSdAssetSpec(
      id: 'madebyollin/sdxl-vae-fp16-fix',
      displayName: 'SDXL VAE (fp16 fix)',
      description: 'Fixed fp16 SDXL VAE, avoids NaN at fp16 inference.',
      hfRepo: 'madebyollin/sdxl-vae-fp16-fix',
      hfFile: 'sdxl_vae.safetensors',
      sizeMb: 335,
      engine: SdEngine.coreml,
      tier: SdAssetTier.pro,
      kind: SdAssetKind.vae,
      minRamGb: 0.5,
    ),
  ];

  /// The single free-tier checkpoint. Throws if the catalog is misconfigured.
  static LocalSdAssetSpec get freeCheckpoint =>
      entries.firstWhere((e) => e.kind == SdAssetKind.checkpoint && e.isFreeSlot);

  /// The single free-tier LoRA.
  static LocalSdAssetSpec get freeLora =>
      entries.firstWhere((e) => e.kind == SdAssetKind.lora && e.isFreeSlot);

  /// The single free-tier VAE.
  static LocalSdAssetSpec get freeVae =>
      entries.firstWhere((e) => e.kind == SdAssetKind.vae && e.isFreeSlot);

  /// Entries filtered by kind.
  static List<LocalSdAssetSpec> byKind(SdAssetKind kind) =>
      entries.where((e) => e.kind == kind).toList();

  /// Lookup a spec by id, or null when it isn't curated.
  static LocalSdAssetSpec? findById(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }
}
