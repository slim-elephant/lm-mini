import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/chat_conversation.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/models/elevenlabs_voice.dart';
import 'package:lm_mini/models/group_chat_participant.dart';
import 'package:lm_mini/models/system_prompt.dart';
import 'package:lm_mini/utils/elevenlabs_voice_resolver.dart';
import 'package:lm_mini/utils/tts_engine.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);

  SystemPrompt persona({
    required String id,
    String? elevenLabsVoiceId,
  }) {
    return SystemPrompt(
      id: id,
      name: id,
      content: 'You are $id.',
      createdAt: now,
      updatedAt: now,
      elevenLabsVoiceId: elevenLabsVoiceId,
    );
  }

  test('uses global voice when nothing else is set', () {
    final settings = AppSettings(voiceElevenLabsVoiceId: 'global_voice');
    expect(
      ElevenLabsVoiceResolver.resolveVoiceId(settings: settings),
      'global_voice',
    );
  });

  test('persona overrides global', () {
    final settings = AppSettings(
      voiceElevenLabsVoiceId: 'global_voice',
      selectedSystemPromptId: 'p1',
      savedSystemPrompts: [
        persona(id: 'p1', elevenLabsVoiceId: 'persona_voice')
      ],
    );
    expect(
      ElevenLabsVoiceResolver.resolveVoiceId(settings: settings),
      'persona_voice',
    );
  });

  test('group participant overrides persona', () {
    final settings = AppSettings(
      voiceElevenLabsVoiceId: 'global_voice',
      savedSystemPrompts: [
        persona(id: 'p1', elevenLabsVoiceId: 'persona_voice')
      ],
    );
    final participant = GroupChatParticipant(
      id: 'g1',
      modelId: 'm',
      displayName: 'A',
      personaId: 'p1',
      elevenLabsVoiceId: 'participant_voice',
    );
    expect(
      ElevenLabsVoiceResolver.resolveVoiceId(
        settings: settings,
        participant: participant,
      ),
      'participant_voice',
    );
  });

  test('explicit override wins', () {
    final settings = AppSettings(voiceElevenLabsVoiceId: 'global_voice');
    expect(
      ElevenLabsVoiceResolver.resolveVoiceId(
        settings: settings,
        overrideVoiceId: 'override',
      ),
      'override',
    );
  });

  test('resolveVoiceIdForMessage uses participant id from conversation', () {
    final settings = AppSettings(voiceElevenLabsVoiceId: 'global_voice');
    final participant = GroupChatParticipant(
      id: 'p_a',
      modelId: 'm',
      displayName: 'A',
      elevenLabsVoiceId: 'group_voice',
    );
    final conversation = ChatConversation(
      id: 'c1',
      title: 'g',
      createdAt: now,
      updatedAt: now,
      messageIds: const ['m1'],
      settings: {
        'participants': [participant.toJson()],
      },
    );
    final message = ChatMessage(
      id: 'm1',
      content: 'hello',
      role: 'assistant',
      timestamp: now,
      participantId: 'p_a',
    );
    expect(
      ElevenLabsVoiceResolver.resolveVoiceIdForMessage(
        settings: settings,
        message: message,
        conversation: conversation,
      ),
      'group_voice',
    );
  });

  test('persona and group json round-trip elevenLabsVoiceId', () {
    final p = persona(id: 'p1', elevenLabsVoiceId: 'abc');
    expect(SystemPrompt.fromJson(p.toJson()).elevenLabsVoiceId, 'abc');

    final g = GroupChatParticipant(
      id: 'g',
      modelId: 'm',
      displayName: 'A',
      elevenLabsVoiceId: 'xyz',
    );
    expect(
      GroupChatParticipant.fromJson(g.toJson()).elevenLabsVoiceId,
      'xyz',
    );
  });

  test('AppSettings defaults to v3 conversational and round-trips the key', () {
    final fresh = AppSettings.fromJson({});
    expect(fresh.voiceElevenLabsModelId, 'eleven_v3_conversational');
    expect(fresh.hasElevenLabsApiKey, isFalse);

    final saved = AppSettings(
      voiceTtsProvider: TtsEngine.elevenLabs,
      voiceElevenLabsApiKey: 'sk_test_key_1234',
      voiceElevenLabsVoiceId: 'voice_1',
      voiceElevenLabsModelId: ElevenLabsTtsModels.flash,
    );
    final restored = AppSettings.fromJson(saved.toJson());
    expect(restored.voiceTtsProvider, TtsEngine.elevenLabs);
    expect(restored.voiceElevenLabsApiKey, 'sk_test_key_1234');
    expect(restored.voiceElevenLabsVoiceId, 'voice_1');
    expect(restored.voiceElevenLabsModelId, ElevenLabsTtsModels.flash);
    expect(restored.voiceElevenLabsApiKeyMasked, '••••1234');
  });

  test('sentence streaming includes ElevenLabs', () {
    expect(TtsEngine.usesSentenceStreaming(TtsEngine.elevenLabs), isTrue);
    expect(TtsEngine.usesSentenceStreaming(TtsEngine.native), isFalse);
  });
}
