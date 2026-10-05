/// JSON that should be an array, including wrapped `{ "data": [...] }` bodies.
List<dynamic>? jsonAsList(Object? decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map) {
    for (final key in const [
      'data',
      'models',
      'samplers',
      'schedulers',
      'upscalers',
      'images',
      'items',
      'result',
    ]) {
      final value = decoded[key];
      if (value is List) return value;
    }
  }
  return null;
}

/// AUTOMATIC1111 `/sdapi/v1/options` — not LM Studio / ComfyUI error objects.
bool looksLikeA1111Options(Object? decoded) {
  if (decoded is! Map) return false;
  const keys = {
    'sd_model_checkpoint',
    'sd_checkpoint',
    'sd_vae',
    'CLIP_stop_at_last_layers',
    'samples_save',
    'samples_format',
  };
  return keys.any(decoded.containsKey);
}
