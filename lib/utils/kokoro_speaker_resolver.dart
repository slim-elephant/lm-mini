import '../models/app_settings.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/group_chat_participant.dart';
import '../models/system_prompt.dart';
import 'tts_language_catalog.dart';

/// Resolved Kokoro voice settings for a playback context.
class KokoroVoiceSettings {
  final int speakerId;
  final double speed;

  const KokoroVoiceSettings({
    required this.speakerId,
    required this.speed,
  });
}

/// Resolves which Kokoro speaker / speed to use for TTS playback.
///
/// Priority (speaker and speed independently):
/// 1. Explicit override
/// 2. Group participant fields
/// 3. Persona ([SystemPrompt]) linked via personaId / participant
/// 4. Active/selected system prompt on [settings]
/// 5. Global `settings.voiceKokoroSpeakerId` / `voiceKokoroSpeed`
class KokoroSpeakerResolver {
  KokoroSpeakerResolver._();

  static const int minSpeakerId = 0;
  static const int maxSpeakerId = 10;
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  static int clampSpeakerId(int id) => id.clamp(minSpeakerId, maxSpeakerId);

  static double clampSpeed(double speed) => speed.clamp(minSpeed, maxSpeed);

  static KokoroVoiceSettings resolveVoice({
    required AppSettings settings,
    int? overrideSpeakerId,
    double? overrideSpeed,
    GroupChatParticipant? participant,
    String? personaId,
    List<SystemPrompt>? savedPrompts,
  }) {
    return KokoroVoiceSettings(
      speakerId: resolve(
        settings: settings,
        overrideSpeakerId: overrideSpeakerId,
        participant: participant,
        personaId: personaId,
        savedPrompts: savedPrompts,
      ),
      speed: resolveSpeed(
        settings: settings,
        overrideSpeed: overrideSpeed,
        participant: participant,
        personaId: personaId,
        savedPrompts: savedPrompts,
      ),
    );
  }

  /// Resolve speaker ID from optional pieces of context.
  static int resolve({
    required AppSettings settings,
    int? overrideSpeakerId,
    GroupChatParticipant? participant,
    String? personaId,
    List<SystemPrompt>? savedPrompts,
  }) {
    if (overrideSpeakerId != null) {
      return clampSpeakerId(overrideSpeakerId);
    }

    final fromParticipant = participant?.kokoroSpeakerId;
    if (fromParticipant != null) {
      return clampSpeakerId(fromParticipant);
    }

    final prompts = savedPrompts ?? settings.savedSystemPrompts ?? const [];
    final resolvedPersonaId = personaId ?? participant?.personaId;
    if (resolvedPersonaId != null) {
      final persona = _findPrompt(prompts, resolvedPersonaId);
      if (persona?.kokoroSpeakerId != null) {
        return clampSpeakerId(persona!.kokoroSpeakerId!);
      }
    }

    final selectedId = settings.selectedSystemPromptId;
    if (selectedId != null) {
      final selected = _findPrompt(prompts, selectedId);
      if (selected?.kokoroSpeakerId != null) {
        return clampSpeakerId(selected!.kokoroSpeakerId!);
      }
    }

    return clampSpeakerId(settings.voiceKokoroSpeakerId);
  }

  /// Resolve speech speed from optional pieces of context.
  static double resolveSpeed({
    required AppSettings settings,
    double? overrideSpeed,
    GroupChatParticipant? participant,
    String? personaId,
    List<SystemPrompt>? savedPrompts,
  }) {
    if (overrideSpeed != null) {
      return clampSpeed(overrideSpeed);
    }

    final fromParticipant = participant?.kokoroSpeed;
    if (fromParticipant != null) {
      return clampSpeed(fromParticipant);
    }

    final prompts = savedPrompts ?? settings.savedSystemPrompts ?? const [];
    final resolvedPersonaId = personaId ?? participant?.personaId;
    if (resolvedPersonaId != null) {
      final persona = _findPrompt(prompts, resolvedPersonaId);
      if (persona?.kokoroSpeed != null) {
        return clampSpeed(persona!.kokoroSpeed!);
      }
    }

    final selectedId = settings.selectedSystemPromptId;
    if (selectedId != null) {
      final selected = _findPrompt(prompts, selectedId);
      if (selected?.kokoroSpeed != null) {
        return clampSpeed(selected!.kokoroSpeed!);
      }
    }

    return clampSpeed(settings.voiceKokoroSpeed);
  }

  /// Resolve for an assistant [message] in the given [conversation].
  static KokoroVoiceSettings resolveVoiceForMessage({
    required AppSettings settings,
    required ChatMessage message,
    ChatConversation? conversation,
    List<SystemPrompt>? savedPrompts,
  }) {
    final participant = _participantForMessage(conversation, message);

    String? chatPersonaId;
    final chatSettings = conversation?.settings;
    if (chatSettings != null && chatSettings['systemPromptId'] is String) {
      chatPersonaId = chatSettings['systemPromptId'] as String;
    }

    return resolveVoice(
      settings: settings,
      participant: participant,
      personaId: chatPersonaId,
      savedPrompts: savedPrompts,
    );
  }

  /// Convenience: speaker only (keeps existing call sites compiling).
  static int resolveForMessage({
    required AppSettings settings,
    required ChatMessage message,
    ChatConversation? conversation,
    List<SystemPrompt>? savedPrompts,
  }) {
    return resolveVoiceForMessage(
      settings: settings,
      message: message,
      conversation: conversation,
      savedPrompts: savedPrompts,
    ).speakerId;
  }

  static String displayName(int speakerId, {String? language}) {
    return TtsLanguageCatalog.speakerDisplayName(speakerId, language: language);
  }

  static String speedLabel(double speed) =>
      '${clampSpeed(speed).toStringAsFixed(1)}x';

  static GroupChatParticipant? _participantForMessage(
    ChatConversation? conversation,
    ChatMessage message,
  ) {
    if (message.participantId == null || conversation == null) return null;
    final raw = conversation.settings['participants'] as List?;
    if (raw == null) return null;
    for (final p in raw) {
      if (p is! Map) continue;
      final map = Map<String, dynamic>.from(p);
      if (map['id'] == message.participantId) {
        return GroupChatParticipant.fromJson(map);
      }
    }
    return null;
  }

  static SystemPrompt? _findPrompt(List<SystemPrompt> prompts, String id) {
    for (final p in prompts) {
      if (p.id == id) return p;
    }
    return null;
  }
}
