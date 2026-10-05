/// Whether an Ollama model should receive an OpenAI-style `tools` array.
///
/// `/api/show` `capabilities` is authoritative when present. Name heuristics
/// are a conservative fallback for older servers that omit the field.
abstract final class OllamaToolSupport {
  /// Families known to honor tool calling on current Ollama builds.
  static const allowlist = [
    'qwen2.5',
    'qwen3',
    'qwen2',
    'llama3.1',
    'llama3.2',
    'llama3.3',
    'llama4',
    'mistral',
    'mixtral',
    'command-r',
    'firefunction',
    'hermes',
    'tool',
    'ii-search',
    'deepseek-r1',
    'gpt-oss',
  ];

  /// Resolve from `/api/show` capabilities. A non-empty set is trusted even
  /// when it omits `tools` — do not OR a name heuristic on top.
  static bool fromShowCapabilities({
    required Iterable<String> capabilities,
    required String modelId,
  }) {
    final capSet = <String>{
      for (final c in capabilities)
        if (c.trim().isNotEmpty) c.trim().toLowerCase(),
    };
    if (capSet.isNotEmpty) {
      return capSet.contains('tools') || capSet.contains('tool');
    }
    return heuristic(modelId);
  }

  /// Conservative name heuristic when capabilities are missing.
  /// Unknown / coder-style models default to **false**.
  static bool heuristic(String? modelId) {
    if (modelId == null || modelId.trim().isEmpty) return false;
    final lower = modelId.toLowerCase();

    if (lower.contains('gemma') && !lower.contains('tool')) return false;
    if (lower.contains('llava')) return false;
    if (lower.contains('moondream')) return false;
    if (lower.contains('codegemma')) return false;
    if (lower.contains('deepseek-coder')) return false;
    if (lower.contains('starcoder')) return false;
    if (lower.contains('codellama')) return false;
    if (lower.contains('wizardcoder')) return false;

    return allowlist.any(lower.contains);
  }
}
