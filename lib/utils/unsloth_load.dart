/// Unsloth model ids are `owner/repo:QUANT` (for example
/// `unsloth/gemma-4-e2b-it-GGUF:UD-Q4_K_XL`). Context length is applied only
/// by `POST /api/inference/load`, not by the chat request.
class UnslothLoad {
  UnslothLoad._();

  /// Quant label after the last `:`, or empty when the id has none.
  static String quantFromModelId(String modelId) {
    final i = modelId.lastIndexOf(':');
    if (i <= 0 || i >= modelId.length - 1) return '';
    final suffix = modelId.substring(i + 1).trim();
    if (suffix.isEmpty || suffix.contains('/') || suffix.contains(' ')) {
      return '';
    }
    return suffix;
  }

  /// Repo id Unsloth expects as `model_path` (the part before `:QUANT`).
  static String modelPath(String modelId) {
    final quant = quantFromModelId(modelId);
    if (quant.isEmpty) return modelId.trim();
    return modelId.substring(0, modelId.lastIndexOf(':')).trim();
  }

  static String contextKey(String modelId, int maxSeqLength) =>
      '$modelId@$maxSeqLength';

  /// Chat base URLs sometimes end in `/v1`. Inference routes live on the origin.
  static String apiRoot(String baseUrl) {
    var b = baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    if (b.toLowerCase().endsWith('/v1')) {
      b = b.substring(0, b.length - 3);
    }
    return b;
  }

  static Map<String, dynamic> loadBody({
    required String modelId,
    required int maxSeqLength,
  }) {
    final quant = quantFromModelId(modelId);
    return {
      'model_path': modelPath(modelId),
      if (quant.isNotEmpty) 'gguf_variant': quant,
      'max_seq_length': maxSeqLength,
    };
  }

  static int? loadedContextLength(Map<String, dynamic>? status) {
    if (status == null) return null;
    if (status['loaded'] == false) return null;
    final ctx = status['context_length'];
    if (ctx is num && ctx > 0) return ctx.toInt();
    return null;
  }

  /// True when this catalog id is one of the models Unsloth currently has
  /// in memory. `loaded` is a list of ids in current Studio builds, and a
  /// boolean in older ones. The rest of the catalog stays not-loaded.
  static bool catalogModelIsLoaded(
    Map<String, dynamic>? status,
    String modelId,
  ) {
    if (status == null || status['loaded'] == false) return false;
    final loaded = status['loaded'];
    if (loaded is List) {
      for (final item in loaded) {
        final ident = item.toString().trim();
        if (ident.isEmpty) continue;
        if (ident == modelId) return true;
        if (statusIsModel({
          'loaded': true,
          'model_identifier': ident,
          'gguf_variant': status['gguf_variant'],
        }, modelId)) {
          return true;
        }
      }
    }
    final asActive = loaded is List
        ? (Map<String, dynamic>.from(status)..['loaded'] = true)
        : status;
    return statusIsModel(asActive, modelId);
  }

  /// True when [status] is the same repo and quant Mini has selected.
  static bool statusIsModel(Map<String, dynamic>? status, String modelId) {
    if (status == null || status['loaded'] == false) return false;
    final ident = (status['model_identifier'] ?? status['active_model'] ?? '')
        .toString()
        .trim();
    if (ident.isEmpty) return false;
    final path = modelPath(modelId);
    final identMatches =
        ident == modelId || ident == path || ident.endsWith('/$path');
    if (!identMatches) return false;
    final quant = quantFromModelId(modelId);
    final variant = (status['gguf_variant'] ?? '').toString().trim();
    if (quant.isEmpty || variant.isEmpty) return true;
    return variant == quant;
  }

  static const apiKeyRequiredMessage =
      'This Unsloth server needs an API key. Paste it above and try again.';

  static const apiKeyRejectedMessage =
      'Unsloth rejected that API key. Check it and try again.';

  /// True when a connection test failed because the server wanted a key.
  static bool connectionNeedsApiKey(String? error) {
    if (error == null || error.isEmpty) return false;
    final lower = error.toLowerCase();
    return lower.contains('authentication') ||
        lower.contains('not authenticated') ||
        lower.contains('401') ||
        lower.contains('403');
  }

  static String authFailureMessage({required bool hadKey}) =>
      hadKey ? apiKeyRejectedMessage : apiKeyRequiredMessage;

  static bool alreadyLoaded(
    Map<String, dynamic>? status,
    String modelId,
    int desiredContext,
  ) {
    if (!statusIsModel(status, modelId)) return false;
    return loadedContextLength(status) == desiredContext;
  }
}
