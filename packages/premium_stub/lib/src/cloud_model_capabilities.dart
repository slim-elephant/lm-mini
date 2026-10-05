/// Parses vision / tools / thinking flags from OpenAI-compatible model
/// listings. oMLX's `/v1/models` omits these; `/v1/models/status` includes
/// `model_type: "vlm" | "llm"`.
library;


bool modelTypeLooksVision(String? raw) {
  if (raw == null) return false;
  final t = raw.trim().toLowerCase();
  return t == 'vlm' ||
      t == 'vision' ||
      t == 'multimodal' ||
      t == 'vision-language';
}

bool engineTypeLooksVision(String? raw) {
  if (raw == null) return false;
  final t = raw.trim().toLowerCase();
  return t == 'vlm' || t == 'vision';
}

bool heuristicSupportsVision(String lowerId) {
  const markers = [
    'vision',
    'llava',
    'pixtral',
    'moondream',
    'minicpm-v',
    'internvl',
    'qwen2-vl',
    'qwen2.5-vl',
    'qwen3-vl',
    'qwen3.5',
    'qwen3_5',
    'qwen35',
    '-vl',
    'vl-',
    'vlm',
    ':vl',
    '_vl',
    'vl_',
  ];
  if (markers.any(lowerId.contains)) return true;
  // Llama 3.2 11B/90B Instruct variants are VLMs; 1B/3B are text.
  if (lowerId.contains('llama-3.2') || lowerId.contains('llama3.2')) {
    return lowerId.contains('11b') || lowerId.contains('90b');
  }
  // Gemma 3 4B+ is multimodal; 1B is text-only.
  if (RegExp(r'gemma[-_]?3').hasMatch(lowerId)) {
    return !RegExp(r'(^|[-_])1b').hasMatch(lowerId);
  }
  return false;
}

bool heuristicSupportsTools(String lowerId) {
  const families = [
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
  ];
  if (lowerId.contains('gemma') && !lowerId.contains('tool')) return false;
  if (lowerId.contains('llava')) return false;
  return families.any(lowerId.contains);
}

({bool vision, bool tools, bool thinking}) capabilitiesFromOpenAiEntry(
  Map<String, dynamic> entry,
) {
  final id = (entry['id'] as String? ?? '').toLowerCase();
  final caps = entry['capabilities'];

  var vision = modelTypeLooksVision(entry['model_type']?.toString()) ||
      modelTypeLooksVision(entry['type']?.toString()) ||
      engineTypeLooksVision(entry['engine_type']?.toString());

  var tools = false;
  var thinking = false;

  if (caps is Map) {
    vision = vision ||
        caps['vision'] == true ||
        caps['vlm'] == true ||
        caps['multimodal'] == true;
    tools = caps['tools'] == true || caps['tool_use'] == true;
    thinking = caps['thinking'] == true || caps['reasoning'] == true;
  } else if (caps is List) {
    final set = {
      for (final c in caps)
        if (c != null) c.toString().toLowerCase(),
    };
    vision = vision ||
        set.contains('vision') ||
        set.contains('vlm') ||
        set.contains('multimodal');
    tools = set.contains('tools') ||
        set.contains('tool') ||
        set.contains('tool_use');
    thinking = set.contains('thinking') || set.contains('reasoning');
  } else if (!vision) {
    vision = heuristicSupportsVision(id);
  }

  return (vision: vision, tools: tools, thinking: thinking);
}

({bool vision, bool tools, bool thinking}) capabilitiesFromOmlxStatus(
  Map<String, dynamic> status,
) {
  final type = status['model_type']?.toString();
  final engine = status['engine_type']?.toString();
  final vision = modelTypeLooksVision(type) || engineTypeLooksVision(engine);
  final thinkingDefault = status['thinking_default'];
  final thinking = thinkingDefault == true ||
      (thinkingDefault is String &&
          thinkingDefault.toLowerCase() != 'false' &&
          thinkingDefault.toLowerCase() != 'off' &&
          thinkingDefault.toLowerCase() != 'disabled' &&
          thinkingDefault.isNotEmpty);
  return (vision: vision, tools: false, thinking: thinking);
}
