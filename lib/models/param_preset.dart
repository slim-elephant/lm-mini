import 'app_settings.dart';

/// Snapshot of generation + model-load knobs from Model Parameters.
///
/// Globals live on [AppSettings]. A model preset is this snapshot keyed by
/// provider + model. A persona may store one optional snapshot used whenever
/// that persona is active.
class ParamPreset {
  static const Object _unset = Object();

  final double temperature;
  final int maxTokens;
  final int contextWindow;
  final double topP;
  final int topK;
  final double minP;
  final double repeatPenalty;
  final double frequencyPenalty;
  final double presencePenalty;
  final String reasoning;
  final String verbosity;
  final String contextFitMode;
  final int? loadContextLength;
  final int? loadEvalBatchSize;
  final bool loadFlashAttention;
  final int? loadNumExperts;
  final bool loadOffloadKvCache;
  final bool resizeImageForPhysicalBatch;

  const ParamPreset({
    required this.temperature,
    required this.maxTokens,
    required this.contextWindow,
    required this.topP,
    required this.topK,
    required this.minP,
    required this.repeatPenalty,
    required this.frequencyPenalty,
    required this.presencePenalty,
    required this.reasoning,
    required this.verbosity,
    required this.contextFitMode,
    this.loadContextLength,
    this.loadEvalBatchSize,
    required this.loadFlashAttention,
    this.loadNumExperts,
    required this.loadOffloadKvCache,
    this.resizeImageForPhysicalBatch = true,
  });

  factory ParamPreset.fromSettings(AppSettings s) {
    return ParamPreset(
      temperature: s.temperature,
      maxTokens: s.maxTokens,
      contextWindow: s.contextWindow,
      topP: s.topP,
      topK: s.topK,
      minP: s.minP,
      repeatPenalty: s.repeatPenalty,
      frequencyPenalty: s.frequencyPenalty,
      presencePenalty: s.presencePenalty,
      reasoning: s.reasoning,
      verbosity: s.verbosity,
      contextFitMode: s.contextFitMode,
      loadContextLength: s.loadContextLength,
      loadEvalBatchSize: s.loadEvalBatchSize,
      loadFlashAttention: s.loadFlashAttention,
      loadNumExperts: s.loadNumExperts,
      loadOffloadKvCache: s.loadOffloadKvCache,
      resizeImageForPhysicalBatch: s.resizeImageForPhysicalBatch,
    );
  }

  /// Overlay this snapshot onto [settings]. Load context stays in sync with
  /// [contextWindow] when [loadContextLength] is omitted.
  AppSettings applyTo(AppSettings settings) {
    final loadCtx = loadContextLength ?? contextWindow;
    return settings.copyWith(
      temperature: temperature,
      maxTokens: maxTokens,
      contextWindow: contextWindow,
      topP: topP,
      topK: topK,
      minP: minP,
      repeatPenalty: repeatPenalty,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      reasoning: reasoning,
      verbosity: verbosity,
      contextFitMode: contextFitMode,
      loadContextLength: loadCtx,
      loadEvalBatchSize: loadEvalBatchSize,
      loadFlashAttention: loadFlashAttention,
      loadNumExperts: loadNumExperts,
      loadOffloadKvCache: loadOffloadKvCache,
      resizeImageForPhysicalBatch: resizeImageForPhysicalBatch,
    );
  }

  ParamPreset copyWith({
    double? temperature,
    int? maxTokens,
    int? contextWindow,
    double? topP,
    int? topK,
    double? minP,
    double? repeatPenalty,
    double? frequencyPenalty,
    double? presencePenalty,
    String? reasoning,
    String? verbosity,
    String? contextFitMode,
    Object? loadContextLength = _unset,
    Object? loadEvalBatchSize = _unset,
    bool? loadFlashAttention,
    Object? loadNumExperts = _unset,
    bool? loadOffloadKvCache,
    bool? resizeImageForPhysicalBatch,
  }) {
    final nextContext = contextWindow ?? this.contextWindow;
    int? nextLoadCtx;
    if (identical(loadContextLength, _unset)) {
      nextLoadCtx = this.loadContextLength;
      if (contextWindow != null) nextLoadCtx = contextWindow;
    } else {
      nextLoadCtx = loadContextLength as int?;
    }
    return ParamPreset(
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      contextWindow: nextContext,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      minP: minP ?? this.minP,
      repeatPenalty: repeatPenalty ?? this.repeatPenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      reasoning: reasoning ?? this.reasoning,
      verbosity: verbosity ?? this.verbosity,
      contextFitMode: contextFitMode ?? this.contextFitMode,
      loadContextLength: nextLoadCtx,
      loadEvalBatchSize: identical(loadEvalBatchSize, _unset)
          ? this.loadEvalBatchSize
          : loadEvalBatchSize as int?,
      loadFlashAttention: loadFlashAttention ?? this.loadFlashAttention,
      loadNumExperts: identical(loadNumExperts, _unset)
          ? this.loadNumExperts
          : loadNumExperts as int?,
      loadOffloadKvCache: loadOffloadKvCache ?? this.loadOffloadKvCache,
      resizeImageForPhysicalBatch:
          resizeImageForPhysicalBatch ?? this.resizeImageForPhysicalBatch,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'maxTokens': maxTokens,
        'contextWindow': contextWindow,
        'topP': topP,
        'topK': topK,
        'minP': minP,
        'repeatPenalty': repeatPenalty,
        'frequencyPenalty': frequencyPenalty,
        'presencePenalty': presencePenalty,
        'reasoning': reasoning,
        'verbosity': verbosity,
        'contextFitMode': contextFitMode,
        'loadContextLength': loadContextLength,
        'loadEvalBatchSize': loadEvalBatchSize,
        'loadFlashAttention': loadFlashAttention,
        'loadNumExperts': loadNumExperts,
        'loadOffloadKvCache': loadOffloadKvCache,
        'resizeImageForPhysicalBatch': resizeImageForPhysicalBatch,
      };

  factory ParamPreset.fromJson(Map<String, dynamic> json) {
    final contextWindow = (json['contextWindow'] as num?)?.toInt() ?? 4096;
    return ParamPreset(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.8,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2048,
      contextWindow: contextWindow,
      topP: (json['topP'] as num?)?.toDouble() ?? 0.9,
      topK: (json['topK'] as num?)?.toInt() ?? 40,
      minP: (json['minP'] as num?)?.toDouble() ?? 0.05,
      repeatPenalty: (json['repeatPenalty'] as num?)?.toDouble() ?? 1.1,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? 'off',
      verbosity: json['verbosity'] as String? ?? 'medium',
      contextFitMode: json['contextFitMode'] as String? ?? 'off',
      loadContextLength: (json['loadContextLength'] as num?)?.toInt(),
      loadEvalBatchSize: (json['loadEvalBatchSize'] as num?)?.toInt(),
      loadFlashAttention: json['loadFlashAttention'] as bool? ?? true,
      loadNumExperts: (json['loadNumExperts'] as num?)?.toInt(),
      loadOffloadKvCache: json['loadOffloadKvCache'] as bool? ?? true,
      resizeImageForPhysicalBatch:
          json['resizeImageForPhysicalBatch'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ParamPreset &&
        other.temperature == temperature &&
        other.maxTokens == maxTokens &&
        other.contextWindow == contextWindow &&
        other.topP == topP &&
        other.topK == topK &&
        other.minP == minP &&
        other.repeatPenalty == repeatPenalty &&
        other.frequencyPenalty == frequencyPenalty &&
        other.presencePenalty == presencePenalty &&
        other.reasoning == reasoning &&
        other.verbosity == verbosity &&
        other.contextFitMode == contextFitMode &&
        other.loadContextLength == loadContextLength &&
        other.loadEvalBatchSize == loadEvalBatchSize &&
        other.loadFlashAttention == loadFlashAttention &&
        other.loadNumExperts == loadNumExperts &&
        other.loadOffloadKvCache == loadOffloadKvCache &&
        other.resizeImageForPhysicalBatch == resizeImageForPhysicalBatch;
  }

  @override
  int get hashCode => Object.hashAll([
        temperature,
        maxTokens,
        contextWindow,
        topP,
        topK,
        minP,
        repeatPenalty,
        frequencyPenalty,
        presencePenalty,
        reasoning,
        verbosity,
        contextFitMode,
        loadContextLength,
        loadEvalBatchSize,
        loadFlashAttention,
        loadNumExperts,
        loadOffloadKvCache,
        resizeImageForPhysicalBatch,
      ]);
}
