/// Data models for **Arena mode** — side-by-side model comparison.
///
/// Arena runs isolated turns (one prompt → N models, no cross-talk) and
/// collects real performance metrics for each contestant so the user can learn
/// which model is the best fit for their prompt **and** their device. Two
/// flavours exist:
///   - **Compare**: a single free-form prompt (Pro).
///   - **Benchmark**: a fixed, versioned prompt set so results are comparable
///     across runs/devices and can power a leaderboard later.
///
/// This is intentionally a pure data library (no Flutter imports) so it can be
/// reused from services, the controller, screens, and unit tests.
library;

import 'local_model_spec.dart';
import 'lm_studio_model.dart';

/// Which kind of arena the user is running.
enum ArenaMode { compare, benchmark }

/// How to schedule multiple models that share one desktop/server provider
/// (e.g. two LM Studio models). On-device is always one-at-a-time.
enum ArenaSameProviderSchedule {
  /// Fire all networked contestants concurrently (fastest wall-clock).
  parallel,

  /// Run one after another; for LM Studio, unload the previous model before
  /// loading the next so VRAM/RAM isn't shared unfairly.
  /// On-device (GGUF / MLX) always uses this behavior — only one model fits
  /// in phone memory at a time.
  unloadBetween,
}

/// Parses a parameter count in billions from a free-form string such as
/// `"7B"`, `"1.5 B"`, or `"Qwen2.5-3B-Instruct"`. Returns null when unknown.
double? parseParamsB(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final m = RegExp(r'([\d]+(?:\.[\d]+)?)\s*[bB]\b').firstMatch(raw);
  if (m != null) return double.tryParse(m.group(1)!);
  final m2 = RegExp(r'([\d]+(?:\.[\d]+)?)').firstMatch(raw);
  return m2 != null ? double.tryParse(m2.group(1)!) : null;
}

/// One model entered into the arena. Carries enough spec metadata
/// (params, quant, size) to make same-model/different-quant and
/// same-quant/different-size comparisons meaningful.
class ArenaContestant {
  /// Stable id, unique within a single arena run.
  final String id;

  /// User-facing label (defaults to the model's short name).
  final String displayName;

  /// Backend model identifier (LM Studio id, on-device catalog id, or cloud
  /// model id).
  final String modelId;

  /// Which backend serves this contestant. One of:
  ///   - `'lmStudio'`     → LM Studio / OpenAI-compatible local server
  ///   - `'onDeviceGguf'` → on-device fllama GGUF inference
  ///   - `'onDeviceMlx'`  → on-device MLX inference
  ///   - `'ollama'`       → local Ollama via CloudApiProvider
  ///   - `'omlx'`         → local oMLX via CloudApiProvider
  ///   - `'cloud'`        → a configured cloud `CloudApiProvider` (Pro)
  final String providerKind;

  /// When [providerKind] is cloud/ollama/omlx, the id of the configured
  /// provider to use. Ignored otherwise.
  final String? cloudProviderId;

  /// Accent color (ARGB int) used to visually distinguish the contestant.
  final int color;

  /// The on-device model spec, when this contestant runs on-device. Drives the
  /// device-fit verdict shown in results. Null for LM Studio / cloud.
  final LocalModelSpec? spec;

  // ── Spec metadata (best-effort; populated for on-device + LM Studio) ──
  /// Parameter count in billions (e.g. 3.0 for a 3B model).
  final double? paramsB;

  /// Quantization label (e.g. `"Q4_K_M"`, or `"MLX"`).
  final String? quant;

  /// Approximate on-disk size in megabytes.
  final int? sizeMb;

  /// Architecture family (e.g. `"qwen2"`, `"llama"`).
  final String? arch;

  /// True when the backend reported a reasoning/thinking capability (e.g. LM
  /// Studio). Also set via [looksLikeReasoningModel] heuristics when unknown.
  final bool isReasoningModel;

  const ArenaContestant({
    required this.id,
    required this.displayName,
    required this.modelId,
    required this.providerKind,
    required this.color,
    this.cloudProviderId,
    this.spec,
    this.paramsB,
    this.quant,
    this.sizeMb,
    this.arch,
    this.isReasoningModel = false,
  });

  /// Best-effort detection from model id / display name when capabilities are
  /// missing (common for cloud, Ollama, llama.cpp `/v1/models`, and on-device).
  static bool looksLikeReasoningModel(String modelId, [String? displayName]) {
    final s = '$modelId ${displayName ?? ''}'.toLowerCase();
    if (s.contains('reasoning') ||
        s.contains('thinking') ||
        s.contains('deepseek-r1') ||
        s.contains('deepseek_r1') ||
        s.contains('qwq') ||
        s.contains('magistral') ||
        s.contains('r1-distill') ||
        s.contains('r1_distill') ||
        s.contains('gemma-4') ||
        s.contains('gemma4') ||
        s.contains('gpt-oss') ||
        RegExp(r'gemma\s*4').hasMatch(s)) {
      return true;
    }
    // Qwen 3 / 3.5 / 3.6 hybrid thinking (not Qwen2.5). Matches path-style
    // llama-server ids such as `.../Qwen3.6-27B-Fable-Fusion-....gguf`.
    if (RegExp(r'qwen[-_.\s]*3(\.\d+)?(?!\d)').hasMatch(s)) {
      return true;
    }
    // OpenAI o-series and similar short tokens (word boundaries).
    return RegExp(r'(^|[^a-z0-9])(o1|o3|o4)([^a-z0-9]|$)').hasMatch(s);
  }

  /// Best-effort vision / VLM detection when the backend omits capabilities
  /// (llama.cpp `/v1/models` without a loaded mmproj).
  static bool looksLikeVisionModel(String modelId, [String? displayName]) {
    final s = '$modelId ${displayName ?? ''}'.toLowerCase();
    const markers = [
      'vision',
      'llava',
      'pixtral',
      'moondream',
      'minicpm-v',
      'internvl',
      'qwen-vl',
      'qwen2-vl',
      'qwen2.5-vl',
      'qwen3-vl',
    ];
    if (markers.any(s.contains)) return true;
    return RegExp(r'(^|[^a-z0-9])(vl|vlm)([^a-z0-9]|$)').hasMatch(s) ||
        s.contains('-vl-') ||
        s.contains('_vl_') ||
        s.contains('-vl.') ||
        s.contains(':vl');
  }

  /// Build a contestant from an on-device [LocalModelSpec].
  factory ArenaContestant.fromLocalSpec({
    required String id,
    required LocalModelSpec spec,
    required int color,
  }) {
    return ArenaContestant(
      id: id,
      displayName: spec.displayName,
      modelId: spec.id,
      providerKind:
          spec.engine == LocalEngine.mlx ? 'onDeviceMlx' : 'onDeviceGguf',
      color: color,
      spec: spec,
      paramsB: spec.paramsB,
      quant: spec.quantization.isEmpty ? 'MLX' : spec.quantization,
      sizeMb: spec.sizeMb,
      arch: spec.chatTemplate,
      isReasoningModel: looksLikeReasoningModel(spec.id, spec.displayName),
    );
  }

  /// Build a contestant from an LM Studio model descriptor.
  factory ArenaContestant.fromLmStudio({
    required String id,
    required LMStudioModel model,
    required int color,
    String providerKind = 'lmStudio',
  }) {
    return ArenaContestant(
      id: id,
      displayName: model.displayName,
      modelId: model.id,
      providerKind: providerKind,
      color: color,
      paramsB: parseParamsB(model.paramsString ?? model.id),
      quant: model.quantization.isEmpty ? null : model.quantization,
      sizeMb: model.sizeBytes != null
          ? (model.sizeBytes! / (1024 * 1024)).round()
          : null,
      arch: model.arch.isEmpty ? null : model.arch,
      isReasoningModel: model.isReasoningModel ||
          looksLikeReasoningModel(model.id, model.displayName),
    );
  }

  /// Build a cloud contestant (spec metadata mostly unknown).
  factory ArenaContestant.cloud({
    required String id,
    required String modelId,
    required String cloudProviderId,
    required int color,
    String? displayName,
  }) {
    final label = displayName ?? modelId.split('/').last;
    return ArenaContestant(
      id: id,
      displayName: label,
      modelId: modelId,
      providerKind: 'cloud',
      cloudProviderId: cloudProviderId,
      color: color,
      paramsB: parseParamsB(modelId),
      isReasoningModel: looksLikeReasoningModel(modelId, label),
    );
  }

  /// Ollama / oMLX contestant (same stream path as cloud, freer local backends).
  factory ArenaContestant.fromLocalServerProvider({
    required String id,
    required String modelId,
    required String cloudProviderId,
    required String providerKind,
    required int color,
    String? displayName,
  }) {
    assert(providerKind == 'ollama' ||
        providerKind == 'omlx' ||
        providerKind == 'jan' ||
        providerKind == 'unsloth');
    final label = displayName ?? modelId.split('/').last;
    return ArenaContestant(
      id: id,
      displayName: label,
      modelId: modelId,
      providerKind: providerKind,
      cloudProviderId: cloudProviderId,
      color: color,
      paramsB: parseParamsB(modelId),
      isReasoningModel: looksLikeReasoningModel(modelId, label),
    );
  }

  bool get isOnDevice =>
      providerKind == 'onDeviceGguf' || providerKind == 'onDeviceMlx';

  /// Short, path-free model name for compact display.
  String get shortModelName => modelId.split('/').last;

  /// Human-readable engine/runtime label.
  String get providerLabel {
    switch (providerKind) {
      case 'onDeviceGguf':
        return 'On-device · GGUF';
      case 'onDeviceMlx':
        return 'On-device · MLX';
      case 'ollama':
        return 'Ollama';
      case 'omlx':
        return 'oMLX';
      case 'jan':
        return 'JAN AI';
      case 'unsloth':
        return 'Unsloth';
      case 'cloud':
        return 'Cloud';
      case 'lmStudio':
        return 'LM Studio';
      case 'lmMiniDesktop':
        return 'LM Mini Home';
      default:
        return providerKind;
    }
  }

  /// True when this contestant routes through a [CloudApiProvider] id.
  bool get usesCloudProvider =>
      providerKind == 'cloud' ||
      providerKind == 'ollama' ||
      providerKind == 'omlx' ||
      providerKind == 'jan' ||
      providerKind == 'unsloth';

  /// Normalized name for matching the "same" model across providers.
  String get familyKey {
    final raw = displayName.isNotEmpty ? displayName : modelId;
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .replaceAll(RegExp(r'(instruct|chat|it)$'), '');
  }

  /// Formatted params badge, e.g. `"3B"` / `"1.5B"`.
  String? get paramsLabel {
    if (paramsB == null) return null;
    final v = paramsB!;
    final s =
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${s}B';
  }

  /// Formatted size badge, e.g. `"2.3 GB"`.
  String? get sizeLabel {
    if (sizeMb == null) return null;
    if (sizeMb! >= 1024) return '${(sizeMb! / 1024).toStringAsFixed(1)} GB';
    return '$sizeMb MB';
  }

  /// One-line spec summary: `"3B · Q4_K_M · 2.3 GB"`.
  String get specSummary {
    final parts = <String>[
      if (paramsLabel != null) paramsLabel!,
      if (quant != null && quant!.isNotEmpty) quant!,
      if (sizeLabel != null) sizeLabel!,
    ];
    return parts.isEmpty ? providerLabel : parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'modelId': modelId,
        'providerKind': providerKind,
        if (cloudProviderId != null) 'cloudProviderId': cloudProviderId,
        'color': color,
        if (spec != null) 'spec': spec!.toJson(),
        'paramsB': paramsB,
        'quant': quant,
        'sizeMb': sizeMb,
        'arch': arch,
        'isReasoningModel': isReasoningModel,
      };

  factory ArenaContestant.fromJson(Map<String, dynamic> json) {
    final modelId = json['modelId'] as String;
    final displayName = json['displayName'] as String;
    return ArenaContestant(
      id: json['id'] as String,
      displayName: displayName,
      modelId: modelId,
      providerKind: json['providerKind'] as String,
      cloudProviderId: json['cloudProviderId'] as String?,
      color: json['color'] as int,
      spec: json['spec'] == null
          ? null
          : LocalModelSpec.fromJson(
              (json['spec'] as Map).cast<String, dynamic>()),
      paramsB: (json['paramsB'] as num?)?.toDouble(),
      quant: json['quant'] as String?,
      sizeMb: (json['sizeMb'] as num?)?.toInt(),
      arch: json['arch'] as String?,
      isReasoningModel: json['isReasoningModel'] as bool? ??
          looksLikeReasoningModel(modelId, displayName),
    );
  }
}

/// Real, comparable performance metrics for one contestant's answer (or the
/// aggregate across a benchmark prompt set).
///
/// Backends report stats unevenly (LM Studio V1 gives real numbers, on-device
/// gives none, cloud is partial), so the [tokensEstimated] flag records when a
/// value was derived client-side rather than reported by the server.
class ArenaMetrics {
  /// Generation throughput (output tokens per second). Higher is better.
  final double? tokensPerSecond;

  /// Time to first token in milliseconds (responsiveness). Lower is better.
  /// Measured from after model load finishes (when known), not including load.
  final double? ttftMs;

  /// Time spent loading weights into memory (ms), when reported / observed.
  final double? loadMs;

  /// Total output tokens produced.
  final int? outputTokens;

  /// Wall-clock time from request to completion, in milliseconds.
  final double? totalMs;

  /// True when [outputTokens] / [tokensPerSecond] were estimated client-side
  /// (e.g. on-device, where the engine doesn't report usage).
  final bool tokensEstimated;

  /// Why generation stopped (e.g. `stop`, `length`), when known.
  final String? stopReason;

  const ArenaMetrics({
    this.tokensPerSecond,
    this.ttftMs,
    this.loadMs,
    this.outputTokens,
    this.totalMs,
    this.tokensEstimated = false,
    this.stopReason,
  });

  String get formattedTps => tokensPerSecond != null
      ? '${tokensPerSecond!.toStringAsFixed(1)} t/s'
      : '—';

  String get formattedTtft {
    if (ttftMs == null) return '—';
    if (ttftMs! >= 1000) return '${(ttftMs! / 1000).toStringAsFixed(2)} s';
    return '${ttftMs!.round()} ms';
  }

  String get formattedLoad {
    if (loadMs == null) return '—';
    if (loadMs! >= 1000) return '${(loadMs! / 1000).toStringAsFixed(2)} s';
    return '${loadMs!.round()} ms';
  }

  String get formattedTotal {
    if (totalMs == null) return '—';
    return '${(totalMs! / 1000).toStringAsFixed(1)} s';
  }

  String get formattedTokens =>
      outputTokens != null ? '$outputTokens${tokensEstimated ? '≈' : ''}' : '—';

  /// Aggregates per-prompt metrics into a single summary for benchmark runs.
  static ArenaMetrics aggregate(List<ArenaMetrics> samples) {
    if (samples.isEmpty) return const ArenaMetrics();
    if (samples.length == 1) return samples.first;

    int totalTokens = 0;
    double genTimeSum = 0; // seconds spent generating (excludes TTFT)
    double ttftSum = 0;
    int ttftCount = 0;
    double loadSum = 0;
    int loadCount = 0;
    double totalMsSum = 0;
    bool estimated = false;

    for (final s in samples) {
      final tokens = s.outputTokens ?? 0;
      totalTokens += tokens;
      if (s.tokensPerSecond != null && s.tokensPerSecond! > 0 && tokens > 0) {
        genTimeSum += tokens / s.tokensPerSecond!;
      }
      if (s.ttftMs != null) {
        ttftSum += s.ttftMs!;
        ttftCount++;
      }
      if (s.loadMs != null) {
        loadSum += s.loadMs!;
        loadCount++;
      }
      if (s.totalMs != null) totalMsSum += s.totalMs!;
      if (s.tokensEstimated) estimated = true;
    }

    final aggTps = genTimeSum > 0 ? totalTokens / genTimeSum : null;
    final aggTtft = ttftCount > 0 ? ttftSum / ttftCount : null;
    final aggLoad = loadCount > 0 ? loadSum / loadCount : null;

    return ArenaMetrics(
      tokensPerSecond: aggTps,
      ttftMs: aggTtft,
      loadMs: aggLoad,
      outputTokens: totalTokens,
      totalMs: totalMsSum,
      tokensEstimated: estimated,
      stopReason: samples.last.stopReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'tokensPerSecond': tokensPerSecond,
        'ttftMs': ttftMs,
        'loadMs': loadMs,
        'outputTokens': outputTokens,
        'totalMs': totalMs,
        'tokensEstimated': tokensEstimated,
        'stopReason': stopReason,
      };

  factory ArenaMetrics.fromJson(Map<String, dynamic> json) => ArenaMetrics(
        tokensPerSecond: (json['tokensPerSecond'] as num?)?.toDouble(),
        ttftMs: (json['ttftMs'] as num?)?.toDouble(),
        loadMs: (json['loadMs'] as num?)?.toDouble(),
        outputTokens: (json['outputTokens'] as num?)?.toInt(),
        totalMs: (json['totalMs'] as num?)?.toDouble(),
        tokensEstimated: json['tokensEstimated'] as bool? ?? false,
        stopReason: json['stopReason'] as String?,
      );
}

/// Lifecycle of a single contestant during an arena run.
enum ArenaContestantStatus { pending, streaming, done, error, cancelled }

/// Mutable runtime + final state for one contestant. The controller updates
/// this live during streaming; screens render from it.
class ArenaContestantResult {
  final ArenaContestant contestant;

  /// Accumulated visible answer text for the *current* prompt (excludes
  /// reasoning). For benchmark runs this resets each prompt; [sampleAnswer]
  /// holds the first prompt's answer for display.
  String content;

  /// Accumulated reasoning / thinking text for the current prompt.
  String reasoning;

  /// The first prompt's answer, kept as a representative sample.
  String sampleAnswer;

  /// Error message when [status] is [ArenaContestantStatus.error].
  String? error;

  ArenaContestantStatus status;

  /// Aggregate metrics (settles when the run finishes).
  ArenaMetrics metrics;

  /// Per-prompt metrics captured during a benchmark run.
  final List<ArenaMetrics> samples;

  /// Device-fit verdict for on-device contestants; null otherwise.
  ModelFit? fit;

  /// 0-based index of the prompt currently being processed (benchmark mode).
  int promptIndex;

  /// Total prompts this contestant will run.
  int promptCount;

  ArenaContestantResult({
    required this.contestant,
    this.content = '',
    this.reasoning = '',
    this.sampleAnswer = '',
    this.error,
    this.status = ArenaContestantStatus.pending,
    this.metrics = const ArenaMetrics(),
    List<ArenaMetrics>? samples,
    this.fit,
    this.promptIndex = 0,
    this.promptCount = 1,
  }) : samples = samples ?? [];

  /// Text to display in the card (sample answer once available, else live).
  String get displayContent => sampleAnswer.isNotEmpty ? sampleAnswer : content;

  bool get hasContent =>
      content.trim().isNotEmpty || sampleAnswer.trim().isNotEmpty;
  bool get isTerminal =>
      status == ArenaContestantStatus.done ||
      status == ArenaContestantStatus.error ||
      status == ArenaContestantStatus.cancelled;

  Map<String, dynamic> toJson() => {
        'contestant': contestant.toJson(),
        'sampleAnswer': sampleAnswer,
        'error': error,
        'status': status.name,
        'metrics': metrics.toJson(),
        'samples': samples.map((s) => s.toJson()).toList(),
        'fit': fit?.name,
      };

  factory ArenaContestantResult.fromJson(Map<String, dynamic> json) {
    return ArenaContestantResult(
      contestant: ArenaContestant.fromJson(
          (json['contestant'] as Map).cast<String, dynamic>()),
      sampleAnswer: json['sampleAnswer'] as String? ?? '',
      content: json['sampleAnswer'] as String? ?? '',
      error: json['error'] as String?,
      status: ArenaContestantStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ArenaContestantStatus.done,
      ),
      metrics: ArenaMetrics.fromJson(
          (json['metrics'] as Map).cast<String, dynamic>()),
      samples: (json['samples'] as List?)
          ?.map(
              (s) => ArenaMetrics.fromJson((s as Map).cast<String, dynamic>()))
          .toList(),
      fit: json['fit'] == null
          ? null
          : ModelFit.values.firstWhere(
              (f) => f.name == json['fit'],
              orElse: () => ModelFit.runs,
            ),
    );
  }
}
