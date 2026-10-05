/// Curated Ollama library entries for in-app browse/pull.
///
/// Models are pulled onto the **computer running Ollama** (not onto the phone).
/// Tags reflect the official [Ollama library](https://ollama.com/library) as of
/// mid-2026 (Gemma 4, Qwen 3.5/3.6, Llama 4 / 3.3, etc.).
class OllamaCatalogEntry {
  final String id; // ollama pull name, e.g. gemma4:e4b
  final String displayName;
  final String description;
  final String category; // chat | code | vision | reasoning
  final String sizeLabel; // human size from the library page

  const OllamaCatalogEntry({
    required this.id,
    required this.displayName,
    required this.description,
    required this.category,
    required this.sizeLabel,
  });
}

/// Popular current Ollama library models. Prefer official tags users can
/// `ollama pull` directly. Custom names remain available in the pull sheet.
class OllamaModelCatalog {
  OllamaModelCatalog._();

  static const List<OllamaCatalogEntry> entries = [
    // ── Gemma 4 (Google) ────────────────────────────────────────────────
    OllamaCatalogEntry(
      id: 'gemma4:e2b',
      displayName: 'Gemma 4 E2B',
      description: 'Edge multimodal Gemma 4 — text, image, audio.',
      category: 'chat',
      sizeLabel: '7.2 GB',
    ),
    OllamaCatalogEntry(
      id: 'gemma4:e4b',
      displayName: 'Gemma 4 E4B',
      description: 'Default Gemma 4 edge model. Strong local assistant.',
      category: 'chat',
      sizeLabel: '9.6 GB',
    ),
    OllamaCatalogEntry(
      id: 'gemma4:12b',
      displayName: 'Gemma 4 12B',
      description: 'Workstation Gemma 4 with 256K context.',
      category: 'chat',
      sizeLabel: '7.6 GB',
    ),
    OllamaCatalogEntry(
      id: 'gemma4:26b',
      displayName: 'Gemma 4 26B',
      description: 'MoE Gemma 4 (~4B active). Higher quality, larger download.',
      category: 'chat',
      sizeLabel: '18 GB',
    ),
    OllamaCatalogEntry(
      id: 'gemma4:31b',
      displayName: 'Gemma 4 31B',
      description: 'Dense Gemma 4 workstation model.',
      category: 'chat',
      sizeLabel: '20 GB',
    ),

    // ── Qwen 3.5 / 3.6 ──────────────────────────────────────────────────
    OllamaCatalogEntry(
      id: 'qwen3.5:0.8b',
      displayName: 'Qwen 3.5 0.8B',
      description: 'Tiny multimodal Qwen 3.5 for quick tests.',
      category: 'chat',
      sizeLabel: '1.0 GB',
    ),
    OllamaCatalogEntry(
      id: 'qwen3.5:2b',
      displayName: 'Qwen 3.5 2B',
      description: 'Small multimodal Qwen 3.5.',
      category: 'chat',
      sizeLabel: '2.7 GB',
    ),
    OllamaCatalogEntry(
      id: 'qwen3.5:4b',
      displayName: 'Qwen 3.5 4B',
      description: 'Compact multimodal Qwen 3.5 for everyday chat.',
      category: 'chat',
      sizeLabel: '3.4 GB',
    ),
    OllamaCatalogEntry(
      id: 'qwen3.5:9b',
      displayName: 'Qwen 3.5 9B',
      description: 'Default Qwen 3.5 — strong general + vision.',
      category: 'chat',
      sizeLabel: '6.6 GB',
    ),
    OllamaCatalogEntry(
      id: 'qwen3.6:27b',
      displayName: 'Qwen 3.6 27B',
      description: 'Agentic coding + thinking upgrades over Qwen 3.5.',
      category: 'code',
      sizeLabel: '17 GB',
    ),
    OllamaCatalogEntry(
      id: 'qwen3.6:35b',
      displayName: 'Qwen 3.6 35B',
      description: 'Latest Qwen 3.6 flagship open weight (default tag).',
      category: 'code',
      sizeLabel: '24 GB',
    ),
    OllamaCatalogEntry(
      id: 'qwen3-coder',
      displayName: 'Qwen 3 Coder',
      description: 'Coding-focused Qwen 3 family model.',
      category: 'code',
      sizeLabel: 'varies',
    ),

    // ── Llama ───────────────────────────────────────────────────────────
    OllamaCatalogEntry(
      id: 'llama3.3',
      displayName: 'Llama 3.3',
      description: 'Meta Llama 3.3 — strong general chat.',
      category: 'chat',
      sizeLabel: 'varies',
    ),
    OllamaCatalogEntry(
      id: 'llama4:scout',
      displayName: 'Llama 4 Scout',
      description: 'Meta Llama 4 multimodal MoE (17B active).',
      category: 'vision',
      sizeLabel: '67 GB',
    ),
    OllamaCatalogEntry(
      id: 'llama4:maverick',
      displayName: 'Llama 4 Maverick',
      description: 'Larger Llama 4 multimodal MoE.',
      category: 'vision',
      sizeLabel: '245 GB',
    ),

    // ── Other popular current picks ─────────────────────────────────────
    OllamaCatalogEntry(
      id: 'deepseek-r1',
      displayName: 'DeepSeek R1',
      description: 'Reasoning-focused DeepSeek model.',
      category: 'reasoning',
      sizeLabel: 'varies',
    ),
    OllamaCatalogEntry(
      id: 'mistral',
      displayName: 'Mistral',
      description: 'Classic Mistral Instruct.',
      category: 'chat',
      sizeLabel: 'varies',
    ),
    OllamaCatalogEntry(
      id: 'phi4',
      displayName: 'Phi-4',
      description: 'Microsoft Phi-4 — dense STEM/reasoning.',
      category: 'reasoning',
      sizeLabel: 'varies',
    ),
    OllamaCatalogEntry(
      id: 'gpt-oss',
      displayName: 'GPT-OSS',
      description: 'Open-weight GPT-OSS family on Ollama.',
      category: 'chat',
      sizeLabel: 'varies',
    ),
  ];
}
