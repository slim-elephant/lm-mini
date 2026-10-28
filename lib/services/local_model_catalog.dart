import 'dart:math' as math;

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
  /// Catalog refreshed Oct 2026 to the latest families only: Qwen 3.5,
  /// Gemma 4, Bonsai (1-bit), LFM 2.5, MiniCPM 5, Ministral 3, SmolLM 3 and
  /// Granite 4. GGUF runs on the bundled llama.cpp (fllama 5f286c9). MLX
  /// builds are listed only for families the bundled mlx-swift-examples
  /// 2.25.9 can load (no Qwen 3.5 / Gemma 4 / Ministral 3 there yet).
  /// Models removed here keep working for people who downloaded them (the
  /// download stores its spec); see LocalModelDownloadService.
  static const List<LocalModelSpec> entries = [
    // ─── FREE MODELS (GGUF, any device) ───
    LocalModelSpec(
      id: 'qwen/qwen3.5-2b/Q4_K_M',
      displayName: 'Qwen 3.5 2B',
      description: 'Newest small Qwen. Tool calling. Best free pick. ~1.2 GB.',
      hfRepo: 'lmstudio-community/Qwen3.5-2B-GGUF',
      hfFile: 'Qwen3.5-2B-Q4_K_M.gguf',
      sizeMb: 1212,
      paramsB: 2.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 3.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'qwen/qwen3.5-0.8b/Q4_K_M',
      displayName: 'Qwen 3.5 0.8B',
      description: 'Tiny Qwen 3.5 for phones with little memory. ~0.5 GB.',
      hfRepo: 'lmstudio-community/Qwen3.5-0.8B-GGUF',
      hfFile: 'Qwen3.5-0.8B-Q4_K_M.gguf',
      sizeMb: 503,
      paramsB: 0.8,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'google/gemma-4-e2b-it/Q4_K_M',
      displayName: 'Gemma 4 E2B',
      description: 'Google Gemma 4, phone size. Strong all-rounder. ~3 GB.',
      hfRepo: 'unsloth/gemma-4-E2B-it-GGUF',
      hfFile: 'gemma-4-E2B-it-Q4_K_M.gguf',
      sizeMb: 2963,
      paramsB: 2.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 5.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'prism-ml/bonsai-1.7b/Q1_0',
      displayName: 'Bonsai 1.7B (1-bit)',
      description: '1-bit model from PrismML. Tiny download, fast on any phone. ~240 MB.',
      hfRepo: 'prism-ml/Bonsai-1.7B-gguf',
      hfFile: 'Bonsai-1.7B-Q1_0.gguf',
      sizeMb: 237,
      paramsB: 1.7,
      quantization: 'Q1_0',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'liquidai/lfm2.5-1.2b-instruct/Q4_K_M',
      displayName: 'LFM 2.5 1.2B',
      description: 'Liquid AI. Very fast for its size. Tool calling. ~0.7 GB.',
      hfRepo: 'LiquidAI/LFM2.5-1.2B-Instruct-GGUF',
      hfFile: 'LFM2.5-1.2B-Instruct-Q4_K_M.gguf',
      sizeMb: 697,
      paramsB: 1.2,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'openbmb/minicpm5-1b/Q4_K_M',
      displayName: 'MiniCPM 5 1B',
      description: 'OpenBMB small model. Fast on phones. ~0.7 GB.',
      hfRepo: 'openbmb/MiniCPM5-1B-GGUF',
      hfFile: 'MiniCPM5-1B-Q4_K_M.gguf',
      sizeMb: 656,
      paramsB: 1.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
      isFreeSlot: true,
    ),

    // ─── QWEN 3.5 (GGUF) ───
    LocalModelSpec(
      id: 'qwen/qwen3.5-4b/Q4_K_M',
      displayName: 'Qwen 3.5 4B',
      description: 'Qwen 3.5 mid size. Tool calling and images. ~3.2 GB.',
      hfRepo: 'lmstudio-community/Qwen3.5-4B-GGUF',
      hfFile: 'Qwen3.5-4B-Q4_K_M.gguf',
      mmprojHfFile: 'mmproj-Qwen3.5-4B-BF16.gguf',
      sizeMb: 3226,
      paramsB: 4.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      supportsVision: true,
      minRamGb: 6.0,
    ),
    LocalModelSpec(
      id: 'qwen/qwen3.5-9b/Q4_K_M',
      displayName: 'Qwen 3.5 9B',
      description: 'Qwen 3.5 large. Tool calling and images. ~6.1 GB.',
      hfRepo: 'lmstudio-community/Qwen3.5-9B-GGUF',
      hfFile: 'Qwen3.5-9B-Q4_K_M.gguf',
      mmprojHfFile: 'mmproj-Qwen3.5-9B-BF16.gguf',
      sizeMb: 6245,
      paramsB: 9.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      supportsVision: true,
      minRamGb: 9.0,
    ),

    // ─── GEMMA 4 (GGUF) ───
    LocalModelSpec(
      id: 'google/gemma-4-e4b-it/Q4_K_M',
      displayName: 'Gemma 4 E4B',
      description: 'Google Gemma 4, larger phone size. Tool calling and images. ~5.6 GB.',
      hfRepo: 'unsloth/gemma-4-E4B-it-GGUF',
      hfFile: 'gemma-4-E4B-it-Q4_K_M.gguf',
      mmprojHfFile: 'mmproj-F16.gguf',
      sizeMb: 5691,
      paramsB: 4.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      supportsVision: true,
      minRamGb: 9.0,
    ),
    LocalModelSpec(
      id: 'google/gemma-4-12b-it/Q4_K_M',
      displayName: 'Gemma 4 12B',
      description: 'Google Gemma 4 12B. Text only here. ~6.6 GB.',
      hfRepo: 'unsloth/gemma-4-12B-it-GGUF',
      hfFile: 'gemma-4-12b-it-Q4_K_M.gguf',
      sizeMb: 6792,
      paramsB: 12.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 10.0,
    ),

    // ─── BONSAI 1-BIT (GGUF) ───
    LocalModelSpec(
      id: 'prism-ml/bonsai-4b/Q1_0',
      displayName: 'Bonsai 4B (1-bit)',
      description: '4B model in 1-bit. ~550 MB.',
      hfRepo: 'prism-ml/Bonsai-4B-gguf',
      hfFile: 'Bonsai-4B-Q1_0.gguf',
      sizeMb: 546,
      paramsB: 4.0,
      quantization: 'Q1_0',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
    ),
    LocalModelSpec(
      id: 'prism-ml/bonsai-8b/Q1_0',
      displayName: 'Bonsai 8B (1-bit)',
      description: '8B model in 1-bit. Big model, small download. ~1.1 GB.',
      hfRepo: 'prism-ml/Bonsai-8B-gguf',
      hfFile: 'Bonsai-8B-Q1_0.gguf',
      sizeMb: 1105,
      paramsB: 8.0,
      quantization: 'Q1_0',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 3.0,
    ),

    // ─── LFM 2.5 (GGUF) ───
    LocalModelSpec(
      id: 'liquidai/lfm2.5-1.2b-thinking/Q4_K_M',
      displayName: 'LFM 2.5 1.2B Thinking',
      description: 'Liquid AI reasoning model. Thinks before answering. ~0.7 GB.',
      hfRepo: 'LiquidAI/LFM2.5-1.2B-Thinking-GGUF',
      hfFile: 'LFM2.5-1.2B-Thinking-Q4_K_M.gguf',
      sizeMb: 697,
      paramsB: 1.2,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
    ),
    LocalModelSpec(
      id: 'liquidai/lfm2.5-2.6b/Q4_K_M',
      displayName: 'LFM 2.5 2.6B',
      description: 'Liquid AI mid size. Tool calling. ~1.6 GB.',
      hfRepo: 'LiquidAI/LFM2.5-2.6B-GGUF',
      hfFile: 'LFM2.5-2.6B-Q4_K_M.gguf',
      sizeMb: 1597,
      paramsB: 2.6,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 4.0,
    ),
    LocalModelSpec(
      id: 'liquidai/lfm2.5-8b-a1b/Q4_K_M',
      displayName: 'LFM 2.5 8B-A1B',
      description: 'Liquid AI mixture of experts: 8B knowledge at 1B speed. ~4.8 GB.',
      hfRepo: 'LiquidAI/LFM2.5-8B-A1B-GGUF',
      hfFile: 'LFM2.5-8B-A1B-Q4_K_M.gguf',
      sizeMb: 4917,
      paramsB: 8.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 8.0,
    ),
    LocalModelSpec(
      id: 'liquidai/lfm2.5-vl-1.6b/Q4_K_M',
      displayName: 'LFM 2.5 VL 1.6B',
      description: 'Liquid AI vision model. Understands photos. ~1.2 GB.',
      hfRepo: 'LiquidAI/LFM2.5-VL-1.6B-GGUF',
      hfFile: 'LFM2.5-VL-1.6B-Q4_K_M.gguf',
      mmprojHfFile: 'mmproj-LFM2.5-VL-1.6b-Q8_0.gguf',
      sizeMb: 1253,
      paramsB: 1.6,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: false,
      supportsVision: true,
      minRamGb: 3.0,
    ),

    // ─── MINISTRAL 3 (GGUF) ───
    LocalModelSpec(
      id: 'mistralai/ministral-3-3b-instruct-2512/Q4_K_M',
      displayName: 'Ministral 3 3B',
      description: 'Mistral small model. Tool calling and images. ~2.8 GB.',
      hfRepo: 'mistralai/Ministral-3-3B-Instruct-2512-GGUF',
      hfFile: 'Ministral-3-3B-Instruct-2512-Q4_K_M.gguf',
      mmprojHfFile: 'Ministral-3-3B-Instruct-2512-BF16-mmproj.gguf',
      sizeMb: 2851,
      paramsB: 3.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      supportsVision: true,
      minRamGb: 5.0,
    ),
    LocalModelSpec(
      id: 'mistralai/ministral-3-8b-instruct-2512/Q4_K_M',
      displayName: 'Ministral 3 8B',
      description: 'Mistral 8B. Tool calling and images. ~5.6 GB.',
      hfRepo: 'mistralai/Ministral-3-8B-Instruct-2512-GGUF',
      hfFile: 'Ministral-3-8B-Instruct-2512-Q4_K_M.gguf',
      mmprojHfFile: 'Ministral-3-8B-Instruct-2512-BF16-mmproj.gguf',
      sizeMb: 5777,
      paramsB: 8.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      supportsVision: true,
      minRamGb: 9.0,
    ),
    LocalModelSpec(
      id: 'mistralai/ministral-3-14b-instruct-2512/Q4_K_M',
      displayName: 'Ministral 3 14B',
      description: 'Mistral 14B for Macs and big phones. Tool calling and images. ~8.5 GB.',
      hfRepo: 'mistralai/Ministral-3-14B-Instruct-2512-GGUF',
      hfFile: 'Ministral-3-14B-Instruct-2512-Q4_K_M.gguf',
      mmprojHfFile: 'Ministral-3-14B-Instruct-2512-BF16-mmproj.gguf',
      sizeMb: 8697,
      paramsB: 14.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      supportsVision: true,
      minRamGb: 12.0,
    ),

    // ─── SMOLLM 3 / GRANITE 4 (GGUF) ───
    LocalModelSpec(
      id: 'huggingfacetb/smollm3-3b/Q4_K_M',
      displayName: 'SmolLM 3 3B',
      description: 'Hugging Face open model. Tool calling. ~1.8 GB.',
      hfRepo: 'ggml-org/SmolLM3-3B-GGUF',
      hfFile: 'SmolLM3-Q4_K_M.gguf',
      sizeMb: 1827,
      paramsB: 3.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 4.0,
    ),
    LocalModelSpec(
      id: 'ibm-granite/granite-4.0-h-1b/Q4_K_M',
      displayName: 'Granite 4.0 H 1B',
      description: 'IBM hybrid model. Long chats use little memory. ~0.9 GB.',
      hfRepo: 'ibm-granite/granite-4.0-h-1b-GGUF',
      hfFile: 'granite-4.0-h-1b-Q4_K_M.gguf',
      sizeMb: 859,
      paramsB: 1.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 3.0,
    ),
    LocalModelSpec(
      id: 'ibm-granite/granite-4.2-3b/Q4_K_M',
      displayName: 'Granite 4.2 3B',
      description: 'IBM Granite, latest. Tool calling. ~2.1 GB.',
      hfRepo: 'ibm-granite/granite-4.2-3b-GGUF',
      hfFile: 'granite-4.2-3b-Q4_K_M.gguf',
      sizeMb: 2140,
      paramsB: 3.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 4.0,
    ),
    LocalModelSpec(
      id: 'ibm-granite/granite-4.2-8b/Q4_K_M',
      displayName: 'Granite 4.2 8B',
      description: 'IBM Granite 8B. Tool calling. ~5 GB.',
      hfRepo: 'ibm-granite/granite-4.2-8b-GGUF',
      hfFile: 'granite-4.2-8b-Q4_K_M.gguf',
      sizeMb: 5100,
      paramsB: 8.0,
      quantization: 'Q4_K_M',
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 8.0,
    ),

    // ─── MLX (Apple Silicon; only families the bundled MLX supports) ───
    // The ~3B builds are free, like the free GGUF models above.
    LocalModelSpec(
      id: 'mlx-community/lfm2.5-1.2b-instruct-4bit/mlx',
      displayName: 'LFM 2.5 1.2B (MLX)',
      description: 'Liquid AI, MLX build for Apple chips.',
      hfRepo: 'mlx-community/LFM2.5-1.2B-Instruct-4bit',
      hfFile: null,
      sizeMb: 633,
      paramsB: 1.2,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/lfm2.5-2.6b-4bit/mlx',
      displayName: 'LFM 2.5 2.6B (MLX)',
      description: 'Liquid AI mid size, MLX.',
      hfRepo: 'mlx-community/LFM2.5-2.6B-4bit',
      hfFile: null,
      sizeMb: 1464,
      paramsB: 2.6,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 3.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'mlx-community/lfm2.5-8b-a1b-4bit/mlx',
      displayName: 'LFM 2.5 8B-A1B (MLX)',
      description: 'Liquid AI mixture of experts, MLX.',
      hfRepo: 'mlx-community/LFM2.5-8B-A1B-MLX-4bit',
      hfFile: null,
      sizeMb: 4561,
      paramsB: 8.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 7.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/smollm3-3b-4bit/mlx',
      displayName: 'SmolLM 3 3B (MLX)',
      description: 'Hugging Face SmolLM 3, MLX.',
      hfRepo: 'mlx-community/SmolLM3-3B-4bit',
      hfFile: null,
      sizeMb: 1666,
      paramsB: 3.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 3.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'mlx-community/granite-4.0-h-1b-4bit/mlx',
      displayName: 'Granite 4.0 H 1B (MLX)',
      description: 'IBM hybrid model, MLX.',
      hfRepo: 'mlx-community/granite-4.0-h-1b-4bit',
      hfFile: null,
      sizeMb: 795,
      paramsB: 1.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
    ),
    LocalModelSpec(
      id: 'ibm-granite/granite-4.2-3b-q4-mlx/mlx',
      displayName: 'Granite 4.2 3B (MLX)',
      description: 'IBM Granite, official MLX build.',
      hfRepo: 'ibm-granite/granite-4.2-3b-q4-mlx',
      hfFile: null,
      sizeMb: 1970,
      paramsB: 3.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 4.0,
      isFreeSlot: true,
    ),
    LocalModelSpec(
      id: 'ibm-granite/granite-4.2-8b-q4-mlx/mlx',
      displayName: 'Granite 4.2 8B (MLX)',
      description: 'IBM Granite 8B, official MLX build.',
      hfRepo: 'ibm-granite/granite-4.2-8b-q4-mlx',
      hfFile: null,
      sizeMb: 4724,
      paramsB: 8.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 7.0,
    ),
    LocalModelSpec(
      id: 'mlx-community/minicpm5-1b-4bit/mlx',
      displayName: 'MiniCPM 5 1B (MLX)',
      description: 'OpenBMB small model, MLX.',
      hfRepo: 'mlx-community/MiniCPM5-1B-4bit',
      hfFile: null,
      sizeMb: 589,
      paramsB: 1.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
    ),
    LocalModelSpec(
      id: 'openbmb/minicpm5-2b-mlx/mlx',
      displayName: 'MiniCPM 5 2B (MLX)',
      description: 'OpenBMB 2B, official MLX build.',
      hfRepo: 'openbmb/MiniCPM5-2B-MLX',
      hfFile: null,
      sizeMb: 1360,
      paramsB: 2.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 3.0,
    ),
    LocalModelSpec(
      id: 'prism-ml/ternary-bonsai-4b-mlx-2bit/mlx',
      displayName: 'Ternary Bonsai 4B (MLX)',
      description: 'PrismML ternary model, MLX 2-bit. ~1.1 GB.',
      hfRepo: 'prism-ml/Ternary-Bonsai-4B-mlx-2bit',
      hfFile: null,
      sizeMb: 1090,
      paramsB: 4.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 2.0,
    ),
    LocalModelSpec(
      id: 'prism-ml/ternary-bonsai-8b-mlx-2bit/mlx',
      displayName: 'Ternary Bonsai 8B (MLX)',
      description: 'PrismML ternary 8B, MLX 2-bit. ~2.2 GB.',
      hfRepo: 'prism-ml/Ternary-Bonsai-8B-mlx-2bit',
      hfFile: null,
      sizeMb: 2208,
      paramsB: 8.0,
      quantization: '',
      engine: LocalEngine.mlx,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: true,
      minRamGb: 4.0,
    ),

    // ─── Hidden: MoE expert streaming (own engine, not listed) ───
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

  /// Catalog models retired in the Oct 2026 refresh. Downloads people
  /// already finished keep working and are listed under "Older models".
  static const Set<String> retiredIds = {
    'qwen/qwen3-1.7b/Q4_K_M',
    'meta-llama/llama-3.2-1b-instruct/Q4_K_M',
    'google/gemma-3-1b-it/Q4_K_M',
    'deepseek/deepseek-r1-distill-qwen-1.5b/Q4_K_M',
    'mlx-community/qwen3-1.7b-4bit/mlx',
    'mlx-community/qwen3-4b-instruct-2507-4bit/mlx',
    'mlx-community/qwen3-8b-4bit/mlx',
    'mlx-community/llama-3.2-1b-instruct-4bit/mlx',
    'mlx-community/llama-3.2-3b-instruct-4bit/mlx',
    'mlx-community/gemma-3-1b-it-4bit/mlx',
    'mlx-community/gemma-3-4b-it-4bit/mlx',
    'mlx-community/gemma-3-12b-it-4bit/mlx',
    'mlx-community/qwen3-14b-4bit/mlx',
    'mlx-community/gemma-3-27b-it-4bit/mlx',
    'mlx-community/qwen3-32b-4bit/mlx',
    'mlx-community/phi-4-mini-instruct-4bit/mlx',
    'mlx-community/deepseek-r1-distill-qwen-1.5b-4bit/mlx',
    'mlx-community/qwen3-0.6b-4bit/mlx',
    'qwen/qwen3-4b-instruct-2507/Q4_K_M',
    'qwen/qwen3-8b/Q4_K_M',
    'qwen/qwen3-8b/Q5_K_M',
    'google/gemma-3-12b-it/Q4_K_M',
    'meta-llama/llama-3.2-3b-instruct/Q4_K_M',
    'google/gemma-3-4b-it/Q4_K_M',
    'microsoft/phi-4-mini-instruct/Q4_K_M',
    'qwen/qwen3-0.6b/Q4_K_M',
  };

  /// Family card for models downloaded before they left the catalog.
  static const olderModelsFamily = 'Older models';

  /// Display order for brand grouping in the on-device browser.
  static const List<String> familyOrder = [
    'Qwen',
    'Google',
    'Liquid AI',
    'Mistral',
    'IBM',
    'Hugging Face',
    'OpenBMB',
    'PrismML',
    'Meta',
    'DeepSeek',
    'Microsoft',
    olderModelsFamily,
    'Imported',
    'Other',
  ];

  /// Brand bucket for the family cards.
  static String familyGroup(LocalModelSpec spec) {
    if (spec.isImported) return 'Imported';
    if (retiredIds.contains(spec.id)) return olderModelsFamily;
    final s = '${spec.id} ${spec.displayName} ${spec.hfRepo}'.toLowerCase();
    if (s.contains('bonsai') || s.contains('prism')) return 'PrismML';
    if (s.contains('minicpm') || s.contains('openbmb')) return 'OpenBMB';
    if (s.contains('lfm') || s.contains('liquid')) return 'Liquid AI';
    if (s.contains('granite') || s.contains('ibm-')) return 'IBM';
    if (s.contains('mistral')) return 'Mistral';
    if (s.contains('qwen')) return 'Qwen';
    if (s.contains('gemma') || s.contains('google/')) return 'Google';
    if (s.contains('smol')) return 'Hugging Face';
    if (s.contains('llama') || s.contains('meta-llama')) return 'Meta';
    if (s.contains('deepseek')) return 'DeepSeek';
    if (s.contains('phi')) return 'Microsoft';
    return 'Other';
  }

  /// Logo file in assets/icons/brands for a family card (null: letter badge).
  static String? familyLogo(String family) => const {
        'Qwen': 'qwen-color.svg',
        'Google': 'google-color.svg',
        'OpenBMB': 'openbmb.png',
        'PrismML': 'prismml.png',
        'Liquid AI': 'liquid.svg',
        'Mistral': 'mistral-color.svg',
        'IBM': 'ibm.svg',
        'Hugging Face': 'huggingface-color.svg',
        'Meta': 'meta-color.svg',
        'DeepSeek': 'deepseek-color.svg',
        'Microsoft': 'microsoft-color.svg',
        'Apple': 'apple.svg',
      }[family];

  /// Company behind a family, shown under the model name on its card.
  static String familyCompany(String family) => const {
        'Qwen': 'Alibaba',
        'Google': 'Google',
        'Liquid AI': 'Liquid AI',
        'Mistral': 'Mistral AI',
        'IBM': 'IBM',
        'Hugging Face': 'Hugging Face',
        'OpenBMB': 'OpenBMB',
        'PrismML': 'PrismML',
      }[family] ??
      '';

  /// Model line(s) shown as a family card's title, e.g. "Gemma 4".
  static String familyLines(String family) => const {
        'Qwen': 'Qwen 3.5',
        'Google': 'Gemma 4',
        'Liquid AI': 'LFM 2.5',
        'Mistral': 'Ministral 3',
        'IBM': 'Granite 4',
        'Hugging Face': 'SmolLM 3',
        'OpenBMB': 'MiniCPM',
        'PrismML': 'Bonsai',
      }[family] ??
      '';

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

  /// Largest catalog model free users can download; bigger ones need Pro.
  static const double freeTierMaxParamsB = 3.0;

  /// Free to download without Pro: the starter slots, anything up to
  /// [freeTierMaxParamsB], and the user's own imports.
  static bool isFreeTier(LocalModelSpec spec) =>
      spec.isFreeSlot ||
      spec.isImported ||
      spec.paramsB <= freeTierMaxParamsB;

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
    // MLX is only a tiebreaker on Apple chips: the strongest current
    // families (Qwen 3.5, Gemma 4, Ministral 3) are GGUF-only in this build.
    if (cap.supportsMlx && e.engine == LocalEngine.mlx) {
      score += 15;
    } else if (!cap.supportsMlx && e.engine == LocalEngine.fllama) {
      score += 80;
    }
    // Vulkan helps GGUF on Android.
    if (cap.supportsVulkan && e.engine == LocalEngine.fllama) score += 25;
    if (e.supportsToolCalls) score += 18;
    if (e.supportsVision) score += 12;

    // Prefer the strongest current families.
    final id = e.id.toLowerCase();
    if (id.contains('qwen3.5')) score += 60;
    if (id.contains('gemma-4')) score += 52;
    if (id.contains('ministral-3')) score += 34;
    if (id.contains('lfm2.5')) score += 30;
    if (id.contains('granite-4')) score += 28;
    if (id.contains('smollm3')) score += 26;
    if (id.contains('minicpm5')) score += 24;
    if (id.contains('bonsai')) score += 10;

    // Bigger helps, but with diminishing returns, so a stronger family
    // beats a merely larger one (Qwen 3.5 4B over Granite 4.2 8B).
    score += (math.sqrt(qualityParams(e)) * 30).round();

    // Mild preference for free-slot / easy first download on low RAM.
    if (e.isFreeSlot && cap.ramGb < 5) score += 15;

    return score;
  }

  /// Parameter count adjusted for answer quality: 1-bit and ternary models
  /// and small-active mixtures of experts answer like smaller dense models.
  static double qualityParams(LocalModelSpec e) {
    final id = e.id.toLowerCase();
    if (id.contains('ternary-bonsai')) return e.paramsB * 0.4;
    if (id.contains('bonsai')) return e.paramsB * 0.35;
    if (id.contains('-a1b')) return 3.0;
    return e.paramsB;
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
  /// Best quality that runs comfortably, by [fitScore]. (The Mac browser
  /// uses [recommendedForVram] instead: the largest model that fits.)
  static LocalModelSpec? bestFor(DeviceCapability cap) => _bestByScore(cap);

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
      if (DeviceCapabilityService.instance.verdict(e, cap) != ModelFit.runs) {
        continue;
      }
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
    bool eligible(LocalModelSpec e) {
      if (isDraft(e)) return false;
      if (!isListed(e)) return false;
      if (freeTierOnly && !isFreeTier(e)) return false;
      return fitScore(e, cap) > 0;
    }

    // One build per model (MLX on Apple chips when both exist), then the
    // strongest few by score, ordered small → large for Faster → Best.
    final byLine = <String, LocalModelSpec>{};
    for (final e in entries.where(eligible)) {
      final line = modelLine(e);
      final prev = byLine[line];
      if (prev == null || fitScore(e, cap) > fitScore(prev, cap)) {
        byLine[line] = e;
      }
    }
    final ranked = byLine.values.toList()
      ..sort((a, b) => fitScore(b, cap).compareTo(fitScore(a, cap)));
    if (ranked.isEmpty) return null;

    // Best = top score; Faster = the lightest of the strong options;
    // Balanced = the next best that's neither.
    final best = ranked.first;
    final top = ranked.take(5).toList();
    final faster = top.reduce(
        (a, b) => qualityParams(b) < qualityParams(a) ? b : a);
    final balanced = top.firstWhere(
      (e) => e.id != best.id && e.id != faster.id,
      orElse: () => faster,
    );

    return OnboardingModelPicks(
      faster: faster,
      balanced: balanced,
      best: best,
    );
  }
}
