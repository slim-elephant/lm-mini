/// A voice from the user's ElevenLabs library (`GET /v1/voices`).
class ElevenLabsVoice {
  final String voiceId;
  final String name;
  final String? category;
  final String? description;

  const ElevenLabsVoice({
    required this.voiceId,
    required this.name,
    this.category,
    this.description,
  });

  factory ElevenLabsVoice.fromJson(Map<String, dynamic> json) {
    return ElevenLabsVoice(
      voiceId: json['voice_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Voice',
      category: json['category'] as String?,
      description: json['description'] as String?,
    );
  }

  String get subtitle {
    final parts = <String>[
      if (category != null && category!.isNotEmpty) category!,
      if (description != null && description!.trim().isNotEmpty)
        description!.trim(),
    ];
    return parts.isEmpty ? voiceId : parts.join(' · ');
  }
}

class ElevenLabsTtsModel {
  final String id;
  final String label;
  final String hint;

  const ElevenLabsTtsModel({
    required this.id,
    required this.label,
    required this.hint,
  });
}

/// TTS models offered in Voice Settings. Product names stay in English.
abstract final class ElevenLabsTtsModels {
  static const conversational = 'eleven_v3_conversational';
  static const flash = 'eleven_flash_v2_5';
  static const multilingualV2 = 'eleven_multilingual_v2';
  static const v3 = 'eleven_v3';
  static const defaultId = conversational;

  static const all = <ElevenLabsTtsModel>[
    ElevenLabsTtsModel(
      id: conversational,
      label: 'v3 Conversational',
      hint: 'Default — expressive, ~280ms',
    ),
    ElevenLabsTtsModel(
      id: flash,
      label: 'Flash v2.5',
      hint: 'Lowest latency',
    ),
    ElevenLabsTtsModel(
      id: multilingualV2,
      label: 'Multilingual v2',
      hint: 'Highest quality, slower',
    ),
    ElevenLabsTtsModel(
      id: v3,
      label: 'v3',
      hint: 'Most expressive, slower',
    ),
  ];

  static ElevenLabsTtsModel byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return all.first;
  }
}

/// Result of checking an ElevenLabs API key.
class ElevenLabsKeyCheck {
  final bool ok;
  final String? error;
  final List<ElevenLabsVoice> voices;

  const ElevenLabsKeyCheck({
    required this.ok,
    this.error,
    this.voices = const [],
  });
}
