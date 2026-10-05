import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/chat_conversation.dart';
import 'package:lm_mini/utils/chat_title.dart';

ChatConversation _convo({
  required String title,
  Map<String, dynamic> settings = const {},
}) {
  final now = DateTime.utc(2026, 9, 16);
  return ChatConversation(
    id: 'c1',
    title: title,
    createdAt: now,
    updatedAt: now,
    messageIds: const [],
    settings: settings,
  );
}

void main() {
  group('ChatTitle.isProvisional', () {
    test('keeps an AI title from the phone', () {
      expect(
        ChatTitle.isProvisional(
          currentTitle: 'Safe trip home Bushra',
          settings: {ChatTitle.sourceKey: ChatTitle.sourceAi},
          seed: 'write a goodbye note',
        ),
        isFalse,
      );
    });

    test('keeps a manual rename', () {
      expect(
        ChatTitle.isProvisional(
          currentTitle: 'Notes',
          settings: {ChatTitle.sourceKey: ChatTitle.sourceUser},
          seed: 'latest user message that is long enough',
        ),
        isFalse,
      );
    });

    test('does not retitle just because a later user line matches', () {
      expect(
        ChatTitle.isProvisional(
          currentTitle: 'Safe trip home Bushra',
          settings: const {},
          seed: '[IMG_PROMPT: Pakistani woman in a car]\nDrive safe',
        ),
        isFalse,
      );
    });

    test('still titles New Chat and first-message fallbacks', () {
      expect(
        ChatTitle.isProvisional(
          currentTitle: 'New Chat',
          settings: const {},
          seed: 'Plan a trip home for Bushra',
        ),
        isTrue,
      );
      expect(
        ChatTitle.isProvisional(
          currentTitle: 'Plan a trip home for Bushra',
          settings: {ChatTitle.sourceKey: ChatTitle.sourceAuto},
          seed: 'Plan a trip home for Bushra',
        ),
        isTrue,
      );
    });

    test('treats leaked IMG_PROMPT titles as replaceable', () {
      expect(
        ChatTitle.isProvisional(
          currentTitle: '[IMG_PROMPT: Pakistani woma...',
          settings: {ChatTitle.sourceKey: ChatTitle.sourceAuto},
          seed: 'Plan a trip home for Bushra',
        ),
        isTrue,
      );
    });
  });

  group('ChatTitle seeds and display', () {
    test('uses the first substantial user message, not the latest', () {
      expect(
        ChatTitle.firstSubstantialSeed(
          [
            'hi',
            'Plan a trip home for Bushra',
            'also generate a portrait [IMG_PROMPT: Pakistani woman]',
          ],
          'fallback',
        ),
        'Plan a trip home for Bushra',
      );
    });

    test('strips IMG_PROMPT from fallback and list labels', () {
      expect(
        ChatTitle.fallbackFromUserMessage(
          '[IMG_PROMPT: Pakistani woman in a car]\nDrive safe tonight',
        ),
        'Drive safe tonight',
      );
      expect(
        ChatTitle.displayLabel('[IMG_PROMPT: Pakistani woma...'),
        isNot(contains('IMG_PROMPT')),
      );
    });

    test('rejects generated titles that are hidden tags', () {
      expect(
        ChatTitle.sanitizeGenerated('[IMG_PROMPT: Pakistani woman]'),
        isNull,
      );
      expect(
        ChatTitle.sanitizeGenerated('Safe trip home Bushra'),
        'Safe trip home Bushra',
      );
    });
  });

  group('ChatTitle.preferStableTitle', () {
    test('newer Home fallback does not clobber phone AI title', () {
      final home = _convo(
        title: '[IMG_PROMPT: Pakistani woma...',
        settings: {ChatTitle.sourceKey: ChatTitle.sourceAuto},
      );
      final phone = _convo(
        title: 'Safe trip home Bushra',
        settings: {ChatTitle.sourceKey: ChatTitle.sourceAi},
      );
      final merged = ChatTitle.preferStableTitle(winner: home, loser: phone);
      expect(merged.title, 'Safe trip home Bushra');
      expect(ChatTitle.sourceOf(merged.settings), ChatTitle.sourceAi);
    });

    test('keeps a real unsourced title over a truncated message fallback', () {
      final homeFallback = _convo(title: '${'x' * 47}...');
      final phone = _convo(title: 'Safe trip home Bushra');
      final merged = ChatTitle.preferStableTitle(
        winner: homeFallback,
        loser: phone,
      );
      expect(merged.title, 'Safe trip home Bushra');
    });
  });
}
