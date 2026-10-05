import 'app_settings.dart';
import 'lm_studio_model.dart';

/// User choice when LM Studio already has a model loaded with different params
/// than LM Mini's Model Loading Config.
enum ModelLoadConflictAction {
  /// Keep the in-memory instance; omit load params from chat requests.
  useExistingLoaded,

  /// Unload the current instance, then load with LM Mini params.
  reloadWithMiniParams,

  /// Load another instance with LM Mini params (parallel).
  loadParallelWithMiniParams,
}

class ModelLoadParamMismatch {
  final String key;
  final String label;
  final String loadedDisplay;
  final String desiredDisplay;

  const ModelLoadParamMismatch({
    required this.key,
    required this.label,
    required this.loadedDisplay,
    required this.desiredDisplay,
  });
}

class ModelLoadConfigDiff {
  final List<ModelLoadParamMismatch> mismatches;

  const ModelLoadConfigDiff(this.mismatches);

  bool get hasMismatch => mismatches.isNotEmpty;
}

/// Builds and compares LM Studio `/api/v1/models/load` parameters.
class ModelLoadConfigHelper {
  ModelLoadConfigHelper._();

  static Map<String, dynamic> buildConfig(AppSettings settings) {
    final config = <String, dynamic>{
      'context_length': settings.loadContextLength ?? settings.contextWindow,
    };
    if (settings.loadEvalBatchSize != null) {
      config['eval_batch_size'] = settings.loadEvalBatchSize;
    }
    if (settings.loadFlashAttention) {
      config['flash_attention'] = true;
    }
    if (settings.loadNumExperts != null) {
      config['num_experts'] = settings.loadNumExperts;
    }
    if (settings.loadOffloadKvCache) {
      config['offload_kv_cache_to_gpu'] = true;
    }
    return config;
  }

  static ModelLoadConfigDiff diffLoadedVsDesired(
    LMStudioModel model,
    AppSettings settings,
  ) {
    if (!model.isLoaded) return const ModelLoadConfigDiff([]);

    final desired = buildConfig(settings);
    final mismatches = <ModelLoadParamMismatch>[];

    void compare({
      required String key,
      required String label,
      required dynamic loaded,
      required dynamic desired,
    }) {
      // Unknown loaded value → don't force a reload / parallel instance.
      if (loaded == null) return;
      if (desired == null) return;
      if (_valuesEqual(loaded, desired)) return;
      mismatches.add(ModelLoadParamMismatch(
        key: key,
        label: label,
        loadedDisplay: _formatValue(loaded),
        desiredDisplay: _formatValue(desired),
      ));
    }

    compare(
      key: 'context_length',
      label: 'Context length',
      loaded: model.loadedContextLength,
      desired: desired['context_length'],
    );

    // If LM Studio didn't echo load config fields, don't treat unknowns as
    // mismatches — that used to force parallel reloads every chat turn.
    if (settings.loadEvalBatchSize != null && model.evalBatchSize != null) {
      compare(
        key: 'eval_batch_size',
        label: 'Eval batch size',
        loaded: model.evalBatchSize,
        desired: settings.loadEvalBatchSize,
      );
    }

    if (settings.loadFlashAttention && model.flashAttention != null) {
      compare(
        key: 'flash_attention',
        label: 'Flash attention',
        loaded: model.flashAttention,
        desired: true,
      );
    }

    if (settings.loadNumExperts != null && model.loadedNumExperts != null) {
      compare(
        key: 'num_experts',
        label: 'Num experts',
        loaded: model.loadedNumExperts,
        desired: settings.loadNumExperts,
      );
    }

    if (settings.loadOffloadKvCache && model.offloadKvCacheToGpu != null) {
      compare(
        key: 'offload_kv_cache_to_gpu',
        label: 'Offload KV cache to GPU',
        loaded: model.offloadKvCacheToGpu,
        desired: true,
      );
    }

    return ModelLoadConfigDiff(mismatches);
  }

  /// Align LM Mini's Model Loading Config with what's already loaded in LM Studio.
  static AppSettings syncSettingsFromLoadedModel(
    AppSettings settings,
    LMStudioModel model,
  ) {
    var next = settings.copyWith(
      loadContextLength:
          model.loadedContextLength ?? settings.loadContextLength,
      loadFlashAttention: model.flashAttention ?? false,
      loadOffloadKvCache: model.offloadKvCacheToGpu ?? false,
    );
    if (model.evalBatchSize != null) {
      next = next.copyWith(loadEvalBatchSize: model.evalBatchSize);
    }
    if (model.loadedNumExperts != null) {
      next = next.copyWith(loadNumExperts: model.loadedNumExperts);
    }
    return next;
  }

  static bool _valuesEqual(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a is bool || b is bool) return a == b;
    if (a is num && b is num) return a == b;
    return a.toString() == b.toString();
  }

  static String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'On' : 'Off';
    if (value is num && value is! double) return value.toString();
    return value.toString();
  }

  /// Slider / dialog label for a token count (`7680` → `7.5K`).
  static String formatTokenCount(int n) {
    if (n < 1024) return '$n';
    if (n < 1024 * 10) {
      final k = n / 1024;
      return '${k.toStringAsFixed(1)}K';
    }
    return '${(n / 1024).round()}K';
  }

  /// Context length is LM Studio load-time `n_ctx`. Offer unload+reload when
  /// Mini's desired size differs from the instance already in memory.
  static bool shouldOfferContextReload({
    required String providerKind,
    required LMStudioModel? model,
    required int desiredContextLength,
  }) {
    if (providerKind != 'lmStudio') return false;
    if (model == null || !model.isLoaded) return false;
    final loaded = model.loadedContextLength;
    if (loaded == null) return false;
    return loaded != desiredContextLength;
  }
}
