/// A Grok / xAI TTS voice (`GET /v1/tts/voices` or `/v1/custom-voices`).
class GrokVoice {
  final String voiceId;
  final String name;
  final String? description;
  final bool custom;

  const GrokVoice({
    required this.voiceId,
    required this.name,
    this.description,
    this.custom = false,
  });

  factory GrokVoice.fromJson(Map<String, dynamic> json, {bool custom = false}) {
    final id = (json['voice_id'] as String?)?.trim() ??
        (json['id'] as String?)?.trim() ??
        '';
    final name = (json['name'] as String?)?.trim();
    return GrokVoice(
      voiceId: id,
      name: (name == null || name.isEmpty) ? id : name,
      description: json['description'] as String? ?? json['hint'] as String?,
      custom: custom,
    );
  }

  String get subtitle {
    if (custom) {
      final hint = description?.trim();
      if (hint != null && hint.isNotEmpty) return hint;
      return voiceId;
    }
    return description?.trim().isNotEmpty == true
        ? description!.trim()
        : voiceId;
  }
}

/// Built-in Grok TTS roster used when the voices API is unreachable.
/// IDs are lowercase; the API treats them as case-insensitive.
abstract final class GrokVoices {
  static const defaultId = 'eve';

  static const all = <GrokVoice>[
    GrokVoice(voiceId: 'eve', name: 'Eve', description: 'Energetic and upbeat'),
    GrokVoice(voiceId: 'ara', name: 'Ara', description: 'Warm and friendly'),
    GrokVoice(
        voiceId: 'leo', name: 'Leo', description: 'Authoritative and strong'),
    GrokVoice(voiceId: 'rex', name: 'Rex', description: 'Confident and clear'),
    GrokVoice(voiceId: 'sal', name: 'Sal', description: 'Smooth and balanced'),
    GrokVoice(
        voiceId: 'luna',
        name: 'Luna',
        description: 'Gentle, patient, and deeply nurturing'),
    GrokVoice(
        voiceId: 'atlas',
        name: 'Atlas',
        description: 'Confident, commanding, and reassuring'),
    GrokVoice(
        voiceId: 'aurora',
        name: 'Aurora',
        description: 'Serene, steady, and radiant'),
    GrokVoice(
        voiceId: 'liora',
        name: 'Liora',
        description: 'Calm, grounded, and luminous'),
    GrokVoice(
        voiceId: 'carina',
        name: 'Carina',
        description: 'Soft, empathetic, and soothing'),
    GrokVoice(
        voiceId: 'zagan',
        name: 'Zagan',
        description: 'Powerful, dramatic, and unmistakable'),
    GrokVoice(
        voiceId: 'helix',
        name: 'Helix',
        description: 'Bold, dynamic, and adrenaline-fueled'),
    GrokVoice(
        voiceId: 'orion',
        name: 'Orion',
        description: 'Rich, cinematic, and resonant'),
    GrokVoice(
        voiceId: 'naksh',
        name: 'Naksh',
        description: 'Warm, thoughtful, and wise'),
    GrokVoice(
        voiceId: 'iris',
        name: 'Iris',
        description: 'Friendly, upbeat, and naturally charming'),
    GrokVoice(
        voiceId: 'altair',
        name: 'Altair',
        description: 'Elegant, refined, and effortlessly premium'),
    GrokVoice(
        voiceId: 'zenith',
        name: 'Zenith',
        description: 'Sharp, focused, and driven'),
    GrokVoice(
        voiceId: 'perseus',
        name: 'Perseus',
        description: 'Strong, confident, and trustworthy'),
    GrokVoice(
        voiceId: 'helios',
        name: 'Helios',
        description: 'Upbeat, energetic, and endlessly versatile'),
    GrokVoice(
        voiceId: 'lux',
        name: 'Lux',
        description: 'Grounded, calm, and quietly wise'),
    GrokVoice(
        voiceId: 'kepler',
        name: 'Kepler',
        description: 'Inventive, forward-thinking, and charismatic'),
    GrokVoice(
        voiceId: 'rigel',
        name: 'Rigel',
        description: 'Precise, professional, and calmly confident'),
    GrokVoice(
        voiceId: 'cosmo',
        name: 'Cosmo',
        description: 'Bright, curious, and easy to follow'),
    GrokVoice(
        voiceId: 'celeste',
        name: 'Celeste',
        description: 'Compassionate, confident, and reassuring'),
    GrokVoice(
        voiceId: 'ursa',
        name: 'Ursa',
        description: 'Friendly, warm, and steadfast'),
    GrokVoice(
        voiceId: 'sirius',
        name: 'Sirius',
        description: 'Quick-witted, clever, and playful'),
    GrokVoice(
        voiceId: 'lumen',
        name: 'Lumen',
        description: 'Warm, articulate, and engaging'),
    GrokVoice(
        voiceId: 'castor',
        name: 'Castor',
        description: 'Charismatic, down-to-earth, and easygoing'),
    GrokVoice(
        voiceId: 'wellness',
        name: 'Wellness',
        description: 'Soft, empathetic, and soothing'),
    GrokVoice(
        voiceId: 'support', name: 'Support', description: 'Clear and helpful'),
  ];

  static GrokVoice? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    final needle = id.toLowerCase();
    for (final v in all) {
      if (v.voiceId == needle) return v;
    }
    return null;
  }

  static String pickDefaultId(List<GrokVoice> voices) {
    for (final v in voices) {
      if (v.voiceId.toLowerCase() == defaultId) return v.voiceId;
    }
    if (voices.isNotEmpty) return voices.first.voiceId;
    return defaultId;
  }
}

/// Result of checking an xAI API key for Grok TTS.
class GrokKeyCheck {
  final bool ok;
  final String? error;
  final List<GrokVoice> voices;

  const GrokKeyCheck({
    required this.ok,
    this.error,
    this.voices = const [],
  });
}
