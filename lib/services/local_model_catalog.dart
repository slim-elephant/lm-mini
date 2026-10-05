import '../models/local_model_spec.dart';
import 'device_capability_service.dart';

/// Labeled Faster / Balanced / Best picks for the onboarding wizard.
class OnboardingModelPicks {
  final LocalModelSpec faster;
  final LocalModelSpec balanced;
  final LocalModelSpec best;

  const OnboardingModelPicks({
    required this.faster,
    required this.balanced,
    required this.best,
  });

  List<({String label, LocalModelSpec spec})> get labeled {
    final out = <({String label, LocalModelSpec spec})>[
      (label: 'Faster', spec: faster),
    ];
    if (balanced.id != faster.id) {
      out.add((label: 'Balanced', spec: balanced));
    }
    if (best.id != faster.id && best.id != balanced.id) {
      out.add((label: 'Best', spec: best));
    } else if (best.id != faster.id && balanced.id == faster.id) {
      out.add((label: 'Best', spec: best));
    }
    return out;
  }
}

/// Curated catalog of locally-runnable models offered in the Local Models
/// browser. The single "free slot" entry per device class can be downloaded
/// on the free tier; everything else is Pro-only.
///
/// This file is intentionally a pure constant list so we can:
///   - update the catalog by shipping an app update (no server roundtrip),
///   - test against it deterministically.
///
/// Users may also add custom Hugging Face URLs at runtime (Pro-only past the
/// free slot); those are tracked separately in user settings.
class LocalModelCatalog {
  LocalModelCatalog._();

  /// All curated entries in display order.
  ///
  /// Ordering note: the on-device browser re-sorts at render time to push
  /// MLX entries to the top on Apple Silicon. The list below is logical
  /// (small → large within a family); don't depend on its order in tests.
  ///
  /// Catalog refreshed mid-2026: Qwen3 (+ Instruct-2507), Gemma 3, Llama 3.2,
  /// Phi-4 Mini, DeepSeek R1 distill. One Q4 (GGUF) / 4-bit (MLX) per size;
  /// legacy Qwen 1.5 / 2.5 / SmolLM removed.
  static const List<LocalModelSpec> entries = [
    // ─── FREE SLOT (GGUF under ~1.9B) ────────────────────────────────
    // Primary free pick: Qwen3 1.7B — strongest small general model.
    LocalModelSpec(
      id: 'qwen/qwen3-1.7b/Q4_K_M',
      displayName: 'Qwen 3 1.7B',
      description: 'Latest Qwen 3 small model. Tool calling. ~1.2 GB.',
      hfRepo: 'lmstudio-community/Qwen3-1.7B-GGUF',
      hfFile: 'Qwen3-1.7B-Q4_K_M.gguf',
      sizeMb: 1223,
      paramsB: 1.7,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 3.0,
      isFreeSlot: true,
      draftModelId: 'qwen/qwen3-0.6b/Q4_K_M',
    ),
    LocalModelSpec(
      id: 'meta-llama/llama-3.2-1b-instruct/Q4_K_M',
      displayName: 'Llama 3.2 1B Instruct',
      description: 'Meta\'s small Llama — fast on every phone. Tool calling.',
      hfRepo: 'bartowski/Llama-3.2-1B-Instruct-GGUF',
      hfFile: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      sizeMb: 808,
      paramsB: 1.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'llama3',
      supportsToolCalls: true,
      minRamGb: 3.0,
      isFreeSlot: true,
      draftModelId: 'meta-llama/llama-3.2-1b-instruct/Q4_K_M',
    ),
    LocalModelSpec(
      id: 'google/gemma-3-1b-it/Q4_K_M',
      displayName: 'Gemma 3 1B Instruct',
      description: 'Tiny Google Gemma 3 — great on phones under 6 GB RAM.',
      hfRepo: 'lmstudio-community/gemma-3-1b-it-GGUF',
      hfFile: 'gemma-3-1b-it-Q4_K_M.gguf',
      sizeMb: 750,
      paramsB: 1.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'gemma',
      supportsToolCalls: false,
      minRamGb: 3.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'deepseek/deepseek-r1-distill-qwen-1.5b/Q4_K_M',
      displayName: 'DeepSeek R1 Distill 1.5B',
      description: 'Reasoning-tuned distill. Strong math and code.',
      hfRepo: 'bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF',
      hfFile: 'DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
      sizeMb: 1065,
      paramsB: 1.5,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'qwen2',
      supportsToolCalls: false,
      minRamGb: 3.0,
      isFreeSlot: true,
    ),

    // ─── MLX (Apple Silicon — preferred on iOS) ──────────────────────

    // -- Qwen 3 --
    LocalModelSpec(
      id: 'mlx-community/qwen3-1.7b-4bit/mlx',
      displayName: 'Qwen 3 1.7B (MLX)',
      description: 'Latest Qwen 3, MLX 4-bit. Tool calling. ~1 GB.',
      hfRepo: 'mlx-community/Qwen3-1.7B-4bit',
      hfFile: null,
      sizeMb: 1100,
      paramsB: 1.7,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 3.0,
      draftModelId: 'mlx-community/qwen3-0.6b-4bit/mlx',
    ),
    LocalModelSpec(
      id: 'mlx-community/qwen3-4b-instruct-2507-4bit/mlx',
      displayName: 'Qwen 3 4B Instruct 2507 (MLX)',
      description: 'July 2025 Instruct refresh — best 4B balance on 8 GB.',
      hfRepo: 'mlx-community/Qwen3-4B-Instruct-2507-4bit',
      hfFile: null,
      sizeMb: 2400,
      paramsB: 4.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 6.0,
      draftModelId: 'mlx-community/qwen3-0.6b-4bit/mlx',
    ),
    LocalModelSpec(
      id: 'mlx-community/qwen3-8b-4bit/mlx',
      displayName: 'Qwen 3 8B (MLX)',
      description: 'Frontier quality. Requires 12 GB RAM (Pro iPhone / M-series).',
      hfRepo: 'mlx-community/Qwen3-8B-4bit',
      hfFile: null,
      sizeMb: 4700,
      paramsB: 8.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 10.0,
    ),

    // -- Llama 3.2 --
    LocalModelSpec(
      id: 'mlx-community/llama-3.2-1b-instruct-4bit/mlx',
      displayName: 'Llama 3.2 1B Instruct (MLX)',
      description: 'Tiny Meta Llama on MLX — also used as a draft model.',
      hfRepo: 'mlx-community/Llama-3.2-1B-Instruct-4bit',
      hfFile: null,
      sizeMb: 700,
      paramsB: 1.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'llama3',
      supportsToolCalls: true,
      minRamGb: 3.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/llama-3.2-3b-instruct-4bit/mlx',
      displayName: 'Llama 3.2 3B Instruct (MLX)',
      description: 'Meta Llama 3.2, MLX 4-bit. Tool calling.',
      hfRepo: 'mlx-community/Llama-3.2-3B-Instruct-4bit',
      hfFile: null,
      sizeMb: 1900,
      paramsB: 3.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'llama3',
      supportsToolCalls: true,
      minRamGb: 6.0,
      draftModelId: 'mlx-community/llama-3.2-1b-instruct-4bit/mlx',
    ),

    // -- Gemma 3 --
    LocalModelSpec(
      id: 'mlx-community/gemma-3-1b-it-4bit/mlx',
      displayName: 'Gemma 3 1B Instruct (MLX)',
      description: 'Google Gemma 3 — tiny, strong reasoning. MLX 4-bit.',
      hfRepo: 'mlx-community/gemma-3-1b-it-4bit',
      hfFile: null,
      sizeMb: 700,
      paramsB: 1.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'gemma',
      supportsToolCalls: false,
      minRamGb: 3.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/gemma-3-4b-it-4bit/mlx',
      displayName: 'Gemma 3 4B Instruct (MLX)',
      description: 'Google Gemma 3 4B with vision. MLX 4-bit.',
      hfRepo: 'mlx-community/gemma-3-4b-it-4bit',
      hfFile: null,
      sizeMb: 2700,
      paramsB: 4.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'gemma',
      supportsToolCalls: false,
      supportsVision: true,
      minRamGb: 6.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/gemma-3-12b-it-4bit/mlx',
      displayName: 'Gemma 3 12B Instruct (MLX)',
      description: 'Premier Gemma 3 size. 12 GB RAM recommended.',
      hfRepo: 'mlx-community/gemma-3-12b-it-4bit',
      hfFile: null,
      sizeMb: 7100,
      paramsB: 12.0,
      quantization: '4-bit',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'gemma',
      supportsToolCalls: false,
      supportsVision: true,
      minRamGb: 12.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/qwen3-14b-4bit/mlx',
      displayName: 'Qwen 3 14B (MLX)',
      description: 'Strong desktop quality. Fits ~16 GB unified memory.',
      hfRepo: 'mlx-community/Qwen3-14B-4bit',
      hfFile: null,
      sizeMb: 8200,
      paramsB: 14.0,
      quantization: '4-bit',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 16.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/gemma-3-27b-it-4bit/mlx',
      displayName: 'Gemma 3 27B Instruct (MLX)',
      description: 'Large Gemma 3. Aims at ~70% of 36 GB unified memory.',
      hfRepo: 'mlx-community/gemma-3-27b-it-4bit',
      hfFile: null,
      sizeMb: 15500,
      paramsB: 27.0,
      quantization: '4-bit',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'gemma',
      supportsToolCalls: false,
      supportsVision: true,
      minRamGb: 24.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/qwen3-32b-4bit/mlx',
      displayName: 'Qwen 3 32B (MLX)',
      description: 'Top desktop pick on 32 GB+ Macs. 4-bit MLX.',
      hfRepo: 'mlx-community/Qwen3-32B-4bit',
      hfFile: null,
      sizeMb: 18000,
      paramsB: 32.0,
      quantization: '4-bit',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 32.0,
    ),

    // -- Phi-4 --
    LocalModelSpec(
      id: 'mlx-community/phi-4-mini-instruct-4bit/mlx',
      displayName: 'Phi-4 Mini Instruct (MLX)',
      description: 'Microsoft Phi-4 Mini — strong reasoning at ~3.8B.',
      hfRepo: 'mlx-community/Phi-4-mini-instruct-4bit',
      hfFile: null,
      sizeMb: 2300,
      paramsB: 3.8,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'phi3',
      supportsToolCalls: true,
      minRamGb: 6.0,
    ),

    // -- DeepSeek R1 Distill --
    LocalModelSpec(
      id: 'mlx-community/deepseek-r1-distill-qwen-1.5b-4bit/mlx',
      displayName: 'DeepSeek R1 Distill 1.5B (MLX)',
      description: 'Reasoning-tuned distill of R1 onto Qwen 2.5 1.5B.',
      hfRepo: 'mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit',
      hfFile: null,
      sizeMb: 1000,
      paramsB: 1.5,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: false,
      minRamGb: 3.0,
    ),

    // -- MLX draft --
    LocalModelSpec(
      id: 'mlx-community/qwen3-0.6b-4bit/mlx',
      displayName: 'Qwen 3 0.6B (MLX draft)',
      description: 'Tiny draft for Qwen 3 speculative decoding.',
      hfRepo: 'mlx-community/Qwen3-0.6B-4bit',
      hfFile: null,
      sizeMb: 420,
      paramsB: 0.6,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: false,
      minRamGb: 2.0,
    ),

    // ─── GGUF (Android + devices without MLX) ────────────────────────

    LocalModelSpec(
      id: 'qwen/qwen3-4b-instruct-2507/Q4_K_M',
      displayName: 'Qwen 3 4B Instruct 2507',
      description: 'July 2025 Instruct refresh — best general 4B pick.',
      hfRepo: 'lmstudio-community/Qwen3-4B-Instruct-2507-GGUF',
      hfFile: 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
      sizeMb: 2500,
      paramsB: 4.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 6.0,
      draftModelId: 'qwen/qwen3-0.6b/Q4_K_M',
    ),
    LocalModelSpec(
      id: 'qwen/qwen3-8b/Q4_K_M',
      displayName: 'Qwen 3 8B',
      description: 'Frontier quality. 12 GB RAM recommended.',
      hfRepo: 'lmstudio-community/Qwen3-8B-GGUF',
      hfFile: 'Qwen3-8B-Q4_K_M.gguf',
      sizeMb: 4900,
      paramsB: 8.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 10.0,
    ),
    LocalModelSpec(
      id: 'qwen/qwen3-8b/Q5_K_M',
      displayName: 'Qwen 3 8B',
      description: 'Higher quality GGUF quant. ~6.5 GB.',
      hfRepo: 'lmstudio-community/Qwen3-8B-GGUF',
      hfFile: 'Qwen3-8B-Q5_K_M.gguf',
      sizeMb: 5600,
      paramsB: 8.0,
      quantization: 'Q5_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 12.0,
    ),
    LocalModelSpec(
      id: 'qwen/qwen3-8b/Q8_0',
      displayName: 'Qwen 3 8B',
      description: 'Near-full precision GGUF. ~8.5 GB.',
      hfRepo: 'lmstudio-community/Qwen3-8B-GGUF',
      hfFile: 'Qwen3-8B-Q8_0.gguf',
      sizeMb: 8500,
      paramsB: 8.0,
      quantization: 'Q8_0',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 16.0,
    ),

    // ─── GGUF MoE stream (iOS device). File is ~18 GB; RAM is ~3 GB. ──
    LocalModelSpec(
      id: 'qwen/qwen3-30b-a3b/Q4_K_M/stream',
      displayName: 'Qwen 3 30B-A3B (stream)',
      description:
          'Mixture-of-Experts GGUF streamed from flash. ~18 GB on disk, '
          '~3 GB RAM. iPhone only — experimental.',
      hfRepo: 'lmstudio-community/Qwen3-30B-A3B-GGUF',
      hfFile: 'Qwen3-30B-A3B-Q4_K_M.gguf',
      sizeMb: 18500,
      paramsB: 30.5,
      quantization: 'Q4_K_M',
      engine: LocalEngine.moeStream,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: true,
      minRamGb: 4.0,
    ),
    LocalModelSpec(
      id: 'google/gemma-3-12b-it/Q4_K_M',
      displayName: 'Gemma 3 12B Instruct',
      description: 'Gemma 3 12B GGUF with vision projector.',
      hfRepo: 'lmstudio-community/gemma-3-12b-it-GGUF',
      hfFile: 'gemma-3-12b-it-Q4_K_M.gguf',
      mmprojHfFile: 'mmproj-model-f16.gguf',
      sizeMb: 8500,
      paramsB: 12.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'gemma',
      supportsToolCalls: false,
      supportsVision: true,
      minRamGb: 16.0,
    ),
    LocalModelSpec(
      id: 'meta-llama/llama-3.2-3b-instruct/Q4_K_M',
      displayName: 'Llama 3.2 3B Instruct',
      description: 'Meta Llama 3.2 3B with tool calling.',
      hfRepo: 'bartowski/Llama-3.2-3B-Instruct-GGUF',
      hfFile: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
      sizeMb: 2020,
      paramsB: 3.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'llama3',
      supportsToolCalls: true,
      minRamGb: 6.0,
      draftModelId: 'meta-llama/llama-3.2-1b-instruct/Q4_K_M',
    ),
    LocalModelSpec(
      id: 'google/gemma-3-4b-it/Q4_K_M',
      displayName: 'Gemma 3 4B Instruct',
      description: 'Google Gemma 3 with vision — strong phone/tablet pick.',
      hfRepo: 'lmstudio-community/gemma-3-4b-it-GGUF',
      hfFile: 'gemma-3-4b-it-Q4_K_M.gguf',
      mmprojHfFile: 'mmproj-model-f16.gguf',
      sizeMb: 3650, // GGUF + mmproj (~850 MB)
      paramsB: 4.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'gemma',
      supportsToolCalls: false,
      supportsVision: true,
      minRamGb: 6.0,
    ),
    LocalModelSpec(
      id: 'microsoft/phi-4-mini-instruct/Q4_K_M',
      displayName: 'Phi-4 Mini Instruct',
      description: 'Microsoft Phi-4 Mini — strong reasoning at 3.8B.',
      hfRepo: 'lmstudio-community/Phi-4-mini-instruct-GGUF',
      hfFile: 'Phi-4-mini-instruct-Q4_K_M.gguf',
      sizeMb: 2400,
      paramsB: 3.8,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'phi3',
      supportsToolCalls: true,
      minRamGb: 6.0,
    ),
    LocalModelSpec(
      id: 'qwen/qwen3-0.6b/Q4_K_M',
      displayName: 'Qwen 3 0.6B (draft)',
      description: 'Tiny draft for Qwen 3 speculative decoding.',
      hfRepo: 'lmstudio-community/Qwen3-0.6B-GGUF',
      hfFile: 'Qwen3-0.6B-Q4_K_M.gguf',
      sizeMb: 470,
      paramsB: 0.6,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'qwen2',
      supportsToolCalls: false,
      minRamGb: 2.0,
    ),
  ];

  /// The single curated model that any user can download on the free tier.
  static LocalModelSpec get freeSlot =>
      entries.firstWhere((e) => e.isFreeSlot);

  /// Look up a curated spec by id. Returns null when [id] isn't curated
  /// (i.e. it's a user-added custom download).
  static LocalModelSpec? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Display order for brand grouping in the on-device browser.
  static const List<String> familyOrder = [
    'Qwen',
    'Google',
    'Meta',
    'DeepSeek',
    'Microsoft',
    'Hugging Face',
    'Other',
  ];

  /// Brand bucket for expand/collapse grouping.
  static String familyGroup(LocalModelSpec spec) {
    final s = '${spec.id} ${spec.displayName} ${spec.hfRepo}'.toLowerCase();
    if (s.contains('qwen')) return 'Qwen';
    if (s.contains('gemma') || s.contains('google/')) return 'Google';
    if (s.contains('llama') || s.contains('meta-llama')) return 'Meta';
    if (s.contains('deepseek')) return 'DeepSeek';
    if (s.contains('phi')) return 'Microsoft';
    if (s.contains('smol')) return 'Hugging Face';
    return 'Other';
  }

  /// One row in the desktop browser: family + size, with quants nested under it.
  static String modelLine(LocalModelSpec spec) {
    return spec.displayName
        .replaceAll(RegExp(r'\s*\(MLX\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\(draft\)', caseSensitive: false), '')
        .trim();
  }

  /// Quant chip for a catalog entry (GGUF filename or MLX 4-bit).
  static String quantLabel(LocalModelSpec spec) {
    if (spec.quantization.isNotEmpty) return spec.quantization;
    if (spec.engine == LocalEngine.mlx) return '4-bit';
    return '';
  }

  /// True for phone-class models we hide on desktop unless already downloaded.
  static bool isPhoneClass(LocalModelSpec spec) => spec.paramsB < 3.0;

  static bool isDraft(LocalModelSpec e) =>
      e.displayName.toLowerCase().contains('draft') ||
      e.description?.toLowerCase().contains('draft') == true;

  /// Experimental entries kept in the catalog for lookups, not shown in
  /// pickers. The 30B MoE stream model stays on its own engine.
  static const Set<String> hiddenIds = {
    'qwen/qwen3-30b-a3b/Q4_K_M/stream',
  };

  static bool isListed(LocalModelSpec spec) => !hiddenIds.contains(spec.id);

  static bool get listsMoeStream =>
      entries.any((e) => e.engine == LocalEngine.moeStream && isListed(e));

  /// Score higher = better pick for this device (MLX on Apple, GGUF elsewhere).
  static int fitScore(LocalModelSpec e, DeviceCapability cap) {
    if (isDraft(e)) return -1000;
    if (e.engine == LocalEngine.mlx && !cap.supportsMlx) return -1000;
    // Expert-stream is an iOS experiment — never auto-pick it as Faster/Best.
    if (e.engine == LocalEngine.moeStream) return -100;
    final fit = DeviceCapabilityService.instance.verdict(e, cap);
    if (fit == ModelFit.blocked) return -1000;
    if (fit == ModelFit.tight) return -50;

    var score = 0;
    // Prefer the engine that matches the platform.
    if (cap.supportsMlx && e.engine == LocalEngine.mlx) {
      score += 120;
    } else if (!cap.supportsMlx && e.engine == LocalEngine.fllama) {
      score += 80;
    }
    // Vulkan helps GGUF on Android.
    if (cap.supportsVulkan && e.engine == LocalEngine.fllama) score += 25;
    if (e.supportsToolCalls) score += 18;
    if (e.supportsVision) score += 12;

    // Prefer modern families / Instruct-2507 refresh.
    final id = e.id.toLowerCase();
    if (id.contains('instruct-2507') || id.contains('2507')) score += 50;
    if (id.contains('qwen3')) score += 40;
    if (id.contains('gemma-3')) score += 32;
    if (id.contains('phi-4')) score += 28;
    if (id.contains('llama-3.2') || id.contains('llama-3.3')) score += 22;
    if (id.contains('deepseek-r1')) score += 20;

    // Prefer the largest model that still fits comfortably (sweet spot).
    score += (e.paramsB * 12).round();

    // Mild preference for free-slot / easy first download on low RAM.
    if (e.isFreeSlot && cap.ramGb < 5) score += 15;

    return score;
  }

  /// Top models that should run well on this device (best first).
  static List<LocalModelSpec> recommendationsFor(
    DeviceCapability cap, {
    int limit = 3,
  }) {
    final scored = entries
        .map((e) => (e, fitScore(e, cap)))
        .where((p) => p.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(limit).map((p) => p.$1).toList();
  }

  /// Single best pick for the device banner.
  static LocalModelSpec? bestFor(DeviceCapability cap) {
    if (cap.ramGb >= 12) {
      return recommendedForVram(cap) ?? _bestByScore(cap);
    }
    return _bestByScore(cap);
  }

  static LocalModelSpec? _bestByScore(DeviceCapability cap) {
    final list = recommendationsFor(cap, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  /// Largest model whose estimated runtime stays within [fraction] of RAM
  /// (unified memory on Apple Silicon ≈ VRAM).
  static LocalModelSpec? recommendedForVram(
    DeviceCapability cap, {
    double fraction = 0.70,
  }) {
    final budgetMb = cap.ramGb * 1024 * fraction;
    LocalModelSpec? pick;
    var bestRuntime = -1;
    for (final e in entries) {
      if (isDraft(e)) continue;
      if (e.engine == LocalEngine.mlx && !cap.supportsMlx) continue;
      if (e.engine == LocalEngine.moeStream) continue;
      if (isPhoneClass(e) && cap.ramGb >= 8) continue;
      final runtime = e.estimatedRuntimeMb;
      if (runtime > budgetMb) continue;
      final mlxBoost = cap.supportsMlx && e.engine == LocalEngine.mlx;
      final pickIsMlx = pick != null &&
          cap.supportsMlx &&
          pick.engine == LocalEngine.mlx;
      if (runtime > bestRuntime ||
          (runtime == bestRuntime && mlxBoost && !pickIsMlx)) {
        bestRuntime = runtime;
        pick = e;
      }
    }
    return pick;
  }

  /// Three onboarding picks sized for this device (Faster / Balanced / Best).
  ///
  /// Prefers MLX on Apple Silicon and GGUF elsewhere. Returns null when the
  /// catalog has no runnable candidates for [cap].
  ///
  /// When [freeTierOnly] is true, only [LocalModelSpec.isFreeSlot] entries
  /// are considered (free-plan onboarding).
  static OnboardingModelPicks? onboardingPicks(
    DeviceCapability cap, {
    bool freeTierOnly = false,
  }) {
    final preferredEngine =
        cap.supportsMlx ? LocalEngine.mlx : LocalEngine.fllama;
    bool eligible(LocalModelSpec e) {
      if (isDraft(e)) return false;
      if (freeTierOnly && !e.isFreeSlot) return false;
      return fitScore(e, cap) > 0;
    }

    var candidates = entries.where((e) {
      if (!eligible(e)) return false;
      if (e.engine != preferredEngine) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.paramsB.compareTo(b.paramsB));

    // Fall back to any fitting engine if the preferred one is empty.
    if (candidates.isEmpty) {
      candidates = entries.where(eligible).toList()
        ..sort((a, b) => a.paramsB.compareTo(b.paramsB));
    }
    if (candidates.isEmpty) return null;

    final faster = candidates.first;
    LocalModelSpec best = candidates.last;
    for (var i = candidates.length - 1; i >= 0; i--) {
      final e = candidates[i];
      if (DeviceCapabilityService.instance.verdict(e, cap) == ModelFit.runs) {
        best = e;
        break;
      }
    }

    // Prefer a mid-size (~3–4B) when available; else geometric mid of the range.
    final targetParams = (faster.paramsB + best.paramsB) / 2;
    const sweetSpot = 3.5;
    LocalModelSpec balanced = faster;
    var bestDist = double.infinity;
    for (final e in candidates) {
      final distToMid = (e.paramsB - targetParams).abs();
      final distToSweet = (e.paramsB - sweetSpot).abs();
      final dist = distToSweet < 1.5 ? distToSweet : distToMid;
      if (dist < bestDist) {
        bestDist = dist;
        balanced = e;
      }
    }
    // Keep labels distinct when possible.
    if (candidates.length >= 3 &&
        (balanced.id == faster.id || balanced.id == best.id)) {
      final midIndex = candidates.length ~/ 2;
      balanced = candidates[midIndex];
    }

    return OnboardingModelPicks(
      faster: faster,
      balanced: balanced,
      best: best,
    );
  }
}
