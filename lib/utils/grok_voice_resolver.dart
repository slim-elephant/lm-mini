import '../models/app_settings.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/group_chat_participant.dart';
import '../models/grok_voice.dart';
import '../models/system_prompt.dart';

/// Resolves which Grok TTS voice ID to use for a playback context.
///
/// Same chain as Kokoro / ElevenLabs: override → group participant → persona →
/// selected prompt → global settings (default [GrokVoices.defaultId]).
class GrokVoiceResolver {
  GrokVoiceResolver._();

  static String resolveVoiceId({
    required AppSettings settings,
    String? overrideVoiceId,
    GroupChatParticipant? participant,
    String? personaId,
    List<SystemPrompt>? savedPrompts,
  }) {
    final override = overrideVoiceId?.trim();
    if (override != null && override.isNotEmpty) return override;

    final fromParticipant = participant?.grokVoiceId?.trim();
    if (fromParticipant != null && fromParticipant.isNotEmpty) {
      return fromParticipant;
    }

    final prompts = savedPrompts ?? settings.savedSystemPrompts ?? const [];
    final resolvedPersonaId = personaId ?? participant?.personaId;
    if (resolvedPersonaId != null) {
      final persona = _findPrompt(prompts, resolvedPersonaId);
      final id = persona?.grokVoiceId?.trim();
      if (id != null && id.isNotEmpty) return id;
    }

    final selectedId = settings.selectedSystemPromptId;
    if (selectedId != null) {
      final selected = _findPrompt(prompts, selectedId);
      final id = selected?.grokVoiceId?.trim();
      if (id != null && id.isNotEmpty) return id;
    }

    final global = settings.voiceGrokVoiceId?.trim();
    if (global != null && global.isNotEmpty) return global;
    return GrokVoices.defaultId;
  }

  static String resolveVoiceIdForMessage({
    required AppSettings settings,
    required ChatMessage message,
    ChatConversation? conversation,
    List<SystemPrompt>? savedPrompts,
  }) {
    return resolveVoiceId(
      settings: settings,
      participant: _participantForMessage(conversation, message),
      personaId: _chatPersonaId(conversation),
      savedPrompts: savedPrompts,
    );
  }

  static String? _chatPersonaId(ChatConversation? conversation) {
    final chatSettings = conversation?.settings;
    if (chatSettings != null && chatSettings['systemPromptId'] is String) {
      return chatSettings['systemPromptId'] as String;
    }
    return null;
  }

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
