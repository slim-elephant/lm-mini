import 'dart:convert';

/// `model_type` values the bundled MLX engine can load (mlx-swift-examples
/// 2.25.9, LLMModelFactory). Update together with the Swift package.
const kSupportedMlxModelTypes = <String>{
  'mistral', 'llama', 'phi', 'phi3', 'phimoe', 'gemma', 'gemma2', 'gemma3',
  'gemma3_text', 'gemma3n', 'qwen2', 'qwen3', 'qwen3_moe', 'starcoder2',
  'cohere', 'openelm', 'internlm2', 'deepseek_v3', 'granite',
  'granitemoehybrid', 'mimo', 'glm4', 'acereason', 'falcon_h1', 'bitnet',
  'smollm3', 'ernie4_5', 'lfm2', 'baichuan_m1', 'exaone4', 'gpt_oss',
  'olmoe', 'olmo2', 'bailing_moe', 'lfm2_moe',
};

/// Why an MLX folder with this `config.json` text can't be used, or null when
/// it can. Checked before copying, so an unsupported model fails in seconds
/// instead of after gigabytes are copied and again at the first chat.
String? mlxConfigProblem(String? configJson) {
  if (configJson == null || configJson.trim().isEmpty) {
    return 'This folder has no config.json. Pick the folder that holds '
        'config.json and the .safetensors files.';
  }
  Object? decoded;
  try {
    decoded = jsonDecode(configJson);
  } catch (_) {
    return 'config.json in this folder could not be read.';
  }
  final type =
      decoded is Map ? (decoded['model_type'] ?? '').toString().trim() : '';
  if (type.isEmpty) {
    return 'config.json does not say which model this is (no model_type).';
  }
  if (!kSupportedMlxModelTypes.contains(type.toLowerCase())) {
    return 'LM Mini\'s MLX engine can\'t run "$type" models yet. Try a GGUF '
        'build of this model, or an MLX model such as Qwen 3, Gemma 3, '
        'Llama, LFM 2 or SmolLM 3.';
  }
  return null;
}
