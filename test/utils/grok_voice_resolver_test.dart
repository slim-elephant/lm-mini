import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/chat_conversation.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/models/group_chat_participant.dart';
import 'package:lm_mini/models/grok_voice.dart';
import 'package:lm_mini/models/system_prompt.dart';
import 'package:lm_mini/utils/grok_voice_resolver.dart';
import 'package:lm_mini/utils/tts_engine.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);

  SystemPrompt persona({
    required String id,
    String? grokVoiceId,
  }) {
    return SystemPrompt(
      id: id,
      name: id,
      content: 'You are $id.',
      createdAt: now,
      updatedAt: now,
      grokVoiceId: grokVoiceId,
    );
  }

  test('uses global voice when nothing else is set', () {
    final settings = AppSettings(voiceGrokVoiceId: 'luna');
    expect(
      GrokVoiceResolver.resolveVoiceId(settings: settings),
      'luna',
    );
  });

  test('falls back to eve when no voice is stored', () {
    final settings = AppSettings();
    expect(
      GrokVoiceResolver.resolveVoiceId(settings: settings),
      GrokVoices.defaultId,
    );
  });

  test('persona overrides global', () {
    final settings = AppSettings(
      voiceGrokVoiceId: 'eve',
      selectedSystemPromptId: 'p1',
      savedSystemPrompts: [persona(id: 'p1', grokVoiceId: 'luna')],
    );
    expect(
      GrokVoiceResolver.resolveVoiceId(settings: settings),
      'luna',
    );
  });

  test('group participant overrides persona', () {
    final settings = AppSettings(
      voiceGrokVoiceId: 'eve',
      savedSystemPrompts: [persona(id: 'p1', grokVoiceId: 'luna')],
    );
    final participant = GroupChatParticipant(
      id: 'g1',
      modelId: 'm',
      displayName: 'A',
      personaId: 'p1',
      grokVoiceId: 'atlas',
    );
    expect(
      GrokVoiceResolver.resolveVoiceId(
        settings: settings,
        participant: participant,
      ),
      'atlas',
    );
  });

  test('explicit override wins', () {
    final settings = AppSettings(voiceGrokVoiceId: 'eve');
    expect(
      GrokVoiceResolver.resolveVoiceId(
        settings: settings,
        overrideVoiceId: 'orion',
      ),
      'orion',
    );
  });

  test('resolveVoiceIdForMessage uses participant id from conversation', () {
    final settings = AppSettings(voiceGrokVoiceId: 'eve');
    final participant = GroupChatParticipant(
      id: 'p_a',
      modelId: 'm',
      displayName: 'A',
      grokVoiceId: 'rex',
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
      GrokVoiceResolver.resolveVoiceIdForMessage(
        settings: settings,
        message: message,
        conversation: conversation,
      ),
      'rex',
    );
  });

  test('persona and group json round-trip grokVoiceId', () {
    final p = persona(id: 'p1', grokVoiceId: 'eve');
    expect(SystemPrompt.fromJson(p.toJson()).grokVoiceId, 'eve');

    final g = GroupChatParticipant(
      id: 'g',
      modelId: 'm',
      displayName: 'A',
      grokVoiceId: 'leo',
    );
    expect(GroupChatParticipant.fromJson(g.toJson()).grokVoiceId, 'leo');
  });

  test('AppSettings round-trips Grok key and voice', () {
    final fresh = AppSettings.fromJson({});
    expect(fresh.hasGrokApiKey, isFalse);
    expect(fresh.voiceGrokVoiceId, isNull);

    final saved = AppSettings(
      voiceTtsProvider: TtsEngine.grok,
      voiceGrokApiKey: 'xai-test-key-1234',
      voiceGrokVoiceId: 'eve',
    );
    final restored = AppSettings.fromJson(saved.toJson());
    expect(restored.voiceTtsProvider, TtsEngine.grok);
    expect(restored.voiceGrokApiKey, 'xai-test-key-1234');
    expect(restored.voiceGrokVoiceId, 'eve');
    expect(restored.voiceGrokApiKeyMasked, '••••1234');
  });

  test('sentence streaming includes Grok', () {
    expect(TtsEngine.usesSentenceStreaming(TtsEngine.grok), isTrue);
    expect(TtsEngine.usesSentenceStreaming(TtsEngine.native), isFalse);
  });
}
