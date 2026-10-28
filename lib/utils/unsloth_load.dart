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

  /// Load body for a target already resolved to files on the server.
  static Map<String, dynamic> resolvedLoadBody({
    required String modelPath,
    required String? variant,
    required int maxSeqLength,
  }) {
    return {
      'model_path': modelPath,
      if (variant != null && variant.isNotEmpty) 'gguf_variant': variant,
      'max_seq_length': maxSeqLength,
    };
  }

  /// Places Unsloth may hold [modelId]'s files, from `GET /api/models/local`:
  /// the repo id (its Hugging Face cache) first, then the `ref:` handles of
  /// copies in LM Studio, Ollama or a models folder. Loading the repo id only
  /// looks in the Hugging Face cache and downloads whatever is missing there,
  /// even when the same file sits in the LM Studio folder.
  static List<String> localCandidates(
    Map<String, dynamic>? local,
    String modelId,
  ) {
    final repo = modelPath(modelId);
    final out = <String>[repo];
    final models = local?['models'];
    if (models is! List) return out;
    for (final m in models) {
      if (m is! Map) continue;
      final id = (m['id'] ?? '').toString().trim();
      final mid = (m['model_id'] ?? '').toString().trim();
      if (id.isEmpty || m['partial'] == true) continue;
      if (m['source'] == 'hf_cache') continue;
      if (mid.toLowerCase() != repo.toLowerCase()) continue;
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }

  /// The quant to load from a `GET /api/models/gguf-variants` answer, taken
  /// only from files already on disk: [wantedQuant] when given, else the
  /// repo's default when downloaded, else the first downloaded one. Null when
  /// none of them is on disk.
  static String? downloadedVariant(
    Map<String, dynamic>? variants,
    String wantedQuant,
  ) {
    final list = variants?['variants'];
    if (list is! List) return null;
    final onDisk = <String>[];
    for (final v in list) {
      if (v is! Map) continue;
      if (v['downloaded'] != true || v['partial'] == true) continue;
      final quant = (v['quant'] ?? '').toString().trim();
      if (quant.isNotEmpty) onDisk.add(quant);
    }
    if (onDisk.isEmpty) return null;
    final wanted = wantedQuant.trim().toLowerCase();
    if (wanted.isNotEmpty) {
      for (final q in onDisk) {
        if (q.toLowerCase() == wanted) return q;
      }
      return null;
    }
    final fallback = (variants?['default_variant'] ?? '').toString().trim();
    for (final q in onDisk) {
      if (q.toLowerCase() == fallback.toLowerCase()) return q;
    }
    return onDisk.first;
  }

  static String notOnDiskMessage(String modelId) {
    final quant = quantFromModelId(modelId);
    final name = modelPath(modelId);
    return quant.isEmpty
        ? 'No downloaded quant of $name was found on this Unsloth server. '
            'Download one in Unsloth first.'
        : '$name $quant was not found on this Unsloth server. '
            'Download it in Unsloth first, or pick a quant you have.';
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
    final path = modelPath(modelId);
    // A model loaded from LM Studio's folder has a `ref:` handle as its
    // identifier and only the bare repo name as `active_model`.
    final identMatches = [status['model_identifier'], status['active_model']]
        .map((v) => (v ?? '').toString().trim())
        .where((ident) => ident.isNotEmpty && !ident.startsWith('ref:'))
        .any((ident) =>
            ident == modelId ||
            ident == path ||
            ident.endsWith('/$path') ||
            (!ident.contains('/') && path.endsWith('/$ident')));
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
