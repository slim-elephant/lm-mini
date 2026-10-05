import 'dart:convert';

/// Parsed generation metadata stored on [ChatMessage.generatedImageInfo].
class ParsedGeneratedImageInfo {
  final String providerKey;
  final String? prompt;
  final String? negativePrompt;
  final String? checkpoint;
  final String? loraName;
  final String? loraWeight;
  final String? sampler;
  final String? scheduler;
  final String? seed;
  final String? steps;
  final String? cfgScale;
  final String? width;
  final String? height;
  final String? workflowPath;
  final Map<String, dynamic> raw;

  const ParsedGeneratedImageInfo({
    required this.providerKey,
    this.prompt,
    this.negativePrompt,
    this.checkpoint,
    this.loraName,
    this.loraWeight,
    this.sampler,
    this.scheduler,
    this.seed,
    this.steps,
    this.cfgScale,
    this.width,
    this.height,
    this.workflowPath,
    this.raw = const {},
  });

  bool get isComfyUi => providerKey == 'comfyui';
  bool get isOnDevice => providerKey == 'onDevice';
  bool get isAutomatic1111 => providerKey == 'automatic1111';

  String get providerLabel {
    switch (providerKey) {
      case 'comfyui':
        return 'ComfyUI';
      case 'onDevice':
        return 'On-device';
      case 'automatic1111':
        return 'AUTOMATIC1111';
      default:
        return 'Image generation';
    }
  }

  String? get sizeLabel {
    if (width == null || height == null) return null;
    return '$width×$height';
  }

  String? get loraLabel {
    if (loraName == null || loraName!.isEmpty) return null;
    final w = loraWeight;
    return (w == null || w.isEmpty) ? loraName : '$loraName @ $w';
  }

  List<({String label, String value})> get summaryChips {
    final chips = <({String label, String value})>[];
    void add(String label, String? value) {
      if (value == null || value.isEmpty) return;
      chips.add((label: label, value: value));
    }

    add('model', checkpoint);
    add('lora', loraLabel);
    add('seed', seed);
    add('steps', steps);
    add('cfg', cfgScale);
    add('size', sizeLabel);
    add('sampler', sampler);
    add('scheduler', scheduler);
    add('workflow', workflowPath);
    return chips;
  }
}

Map<String, dynamic> decodeGeneratedImageInfoMap(String? raw) {
  if (raw == null) return const {};
  final text = raw.trim();
  if (text.isEmpty) return const {};
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    if (decoded is String) {
      final inner = jsonDecode(decoded);
      if (inner is Map) return Map<String, dynamic>.from(inner);
    }
  } catch (_) {}
  return const {};
}

bool isComfyGeneratedImageInfo(String? raw) {
  return parseGeneratedImageInfo(raw).isComfyUi;
}

ParsedGeneratedImageInfo parseGeneratedImageInfo(
  String? raw, {
  String? fallbackPrompt,
}) {
  final data = decodeGeneratedImageInfoMap(raw);
  String? str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  final providerRaw = str(data['provider'])?.toLowerCase();
  final onDevice = data['on_device'] == true || providerRaw == 'ondevice';
  final looksA1111 = data.containsKey('sd_model_name') ||
      data.containsKey('infotexts') ||
      data.containsKey('sd_model_hash');

  final providerKey = switch (providerRaw) {
    'comfyui' => 'comfyui',
    'ondevice' || 'on_device' => 'onDevice',
    'automatic1111' || 'a1111' => 'automatic1111',
    _ when onDevice => 'onDevice',
    _ when looksA1111 => 'automatic1111',
    _ => 'unknown',
  };

  String? prompt = str(data['prompt']);
  if (prompt == null) {
    final texts = data['infotexts'];
    if (texts is List && texts.isNotEmpty) {
      prompt = str(texts.first);
    }
  }
  prompt ??= fallbackPrompt?.trim().isEmpty == true ? null : fallbackPrompt;

  return ParsedGeneratedImageInfo(
    providerKey: providerKey,
    prompt: prompt,
    negativePrompt: str(data['negative_prompt']),
    checkpoint: str(data['checkpoint']) ?? str(data['sd_model_name']),
    loraName: str(data['lora_name']),
    loraWeight: str(data['lora_weight']),
    sampler: str(data['sampler_name']) ?? str(data['sampler']),
    scheduler: str(data['scheduler']),
    seed: str(data['seed']),
    steps: str(data['steps']),
    cfgScale: str(data['cfg_scale'] ?? data['cfg']),
    width: str(data['width']),
    height: str(data['height']),
    workflowPath: str(data['workflow_path']),
    raw: data,
  );
}
