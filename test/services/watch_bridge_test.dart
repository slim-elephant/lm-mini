import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/chat_conversation.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/models/system_prompt.dart';
import 'package:lm_mini/services/watch_bridge.dart';

void main() {
  test('clip keeps short text and ends long text with an ellipsis', () {
    expect(WatchPayload.clip('  hello ', 10), 'hello');
    expect(WatchPayload.clip('abcdefghij', 4), 'abcd…');
  });

  test(
      'chat row uses the persona as the title and the chat name as the preview',
      () {
    final row = WatchPayload.chatRow(
      id: 'c1',
      title: 'Solana price check now',
      persona: 'Researcher',
      preview: 'last answer',
      updatedMs: 10,
    );
    expect(row['title'], 'Researcher');
    expect(row['preview'], 'Solana price check now');
    expect(row['updated'], 10);
    expect(row.containsKey('folderId'), isFalse);
  });

  test('chat row keeps a folder id and folder rows carry a count', () {
    final row = WatchPayload.chatRow(
      id: 'c1',
      title: 'Notes',
      persona: '',
      preview: '',
      updatedMs: 1,
      folderId: 'f1',
    );
    expect(row['folderId'], 'f1');
    expect(row['preview'], 'New chat');
    expect(
      WatchPayload.folderRow(id: 'f1', name: 'Work', count: 2)['count'],
      2,
    );
  });

  test('wallpaper follows the chat override and otherwise the global image',
      () {
    expect(
      WatchPayload.wallpaperStored(
        conversationSettings: const {'chatBackground': 'chats/a.jpg'},
        globalPath: 'global.jpg',
      ),
      'chats/a.jpg',
    );
    expect(
      WatchPayload.wallpaperStored(
        conversationSettings: const {'chatBackground': ''},
        globalPath: 'global.jpg',
      ),
      '',
    );
    expect(
      WatchPayload.wallpaperStored(
        conversationSettings: const {},
        globalPath: 'global.jpg',
      ),
      'global.jpg',
    );
  });

  test('avatar prefers the persona, then the chat, then the global assistant',
      () {
    expect(
      WatchPayload.avatarStored(
        personaPath: 'persona.png',
        conversationSettings: const {'assistantAvatar': 'chat.png'},
        globalAssistantPath: 'global.png',
      ),
      'persona.png',
    );
    expect(
      WatchPayload.avatarStored(
        personaPath: '',
        conversationSettings: const {'assistantAvatar': 'chat.png'},
        globalAssistantPath: 'global.png',
      ),
      'chat.png',
    );
    expect(
      WatchPayload.avatarStored(
        personaPath: null,
        conversationSettings: const {},
        globalAssistantPath: 'global.png',
      ),
      'global.png',
    );
  });

  test('group row keeps the chat title, people, and both pictures', () {
    final row = WatchPayload.chatRow(
      id: 'g1',
      title: 'Study group',
      persona: 'Researcher',
      preview: 'Ada, Lin',
      updatedMs: 3,
      group: true,
      avatar: 'a.jpg',
      avatar2: 'b.jpg',
    );
    expect(row['title'], 'Study group');
    expect(row['preview'], 'Ada, Lin');
    expect(row['group'], isTrue);
    expect(row['avatar'], 'a.jpg');
    expect(row['avatar2'], 'b.jpg');
  });

  test('group faces and names come from the participants', () {
    const settings = {
      'participants': [
        {'displayName': 'Ada', 'avatarPath': 'a.png', 'color': 0xFF112233},
        {'displayName': 'Lin', 'avatarPath': ' b.png '},
        {'displayName': 'No Face'},
      ],
    };
    expect(
      WatchPayload.rowAvatarPaths(
        group: true,
        conversationSettings: settings,
      ),
      ['a.png', 'b.png'],
    );
    expect(WatchPayload.groupNames(settings), 'Ada, Lin, No Face');
    expect(WatchPayload.groupColor(settings), 0xFF112233);
    expect(
      WatchPayload.rowAvatarPaths(
        group: false,
        personaPath: 'persona.png',
        globalAssistantPath: 'global.png',
      ),
      ['persona.png'],
    );
  });

  test('a branch uses the parent title and a missing title uses the message',
      () {
    final parent = ChatConversation(
      id: 'p',
      title: 'Solar sail design',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      messageIds: const [],
      settings: const {},
    );
    final branch = ChatConversation(
      id: 'b',
      title: 'Branch: <think>Thinking Process: 1.',
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 1, 2),
      messageIds: const [],
      settings: const {},
      parentConversationId: 'p',
    );
    final byId = {'p': parent, 'b': branch};
    expect(WatchPayload.generatedTitle(branch, byId), 'Solar sail design');
    final row = WatchPayload.chatRow(
      id: 'b',
      title: WatchPayload.generatedTitle(branch, byId),
      persona: 'Researcher',
      preview: 'Branch: <think>Thinking Process: 1. [IMG_PROMPT: a cat]',
      updatedMs: 4,
      branch: true,
    );
    expect(row['title'], 'Researcher');
    expect(row['preview'], 'Solar sail design');
    expect(row['branch'], isTrue);

    final untitled = WatchPayload.chatRow(
      id: 'n',
      title: '',
      persona: 'Researcher',
      preview: '<think>hidden</think>Hello from the model [IMG_PROMPT: a cat]',
      updatedMs: 5,
    );
    expect(untitled['preview'], 'Hello from the model');
    expect(untitled.containsKey('branch'), isFalse);
  });

  test(
      'message rows collapse thinking and keep the image prompt off the bubble',
      () {
    final rows = WatchPayload.messageRows([
      ChatMessage(
        id: 'u',
        content: 'a red bicycle',
        role: 'user',
        timestamp: DateTime.utc(2026, 1, 1),
      ),
      ChatMessage(
        id: 'a',
        content:
            '<think>plan the picture</think>Here it is [IMG_PROMPT: a red bicycle]',
        role: 'assistant',
        timestamp: DateTime.utc(2026, 1, 1, 0, 0, 1),
        imagePrompt: 'a red bicycle',
        generatedImagePaths: const ['bike.jpg'],
      ),
    ]);
    expect(rows, hasLength(1));
    expect(rows.single['text'], 'Here it is');
    expect(rows.single['thinking'], 'plan the picture');
    expect(rows.single['imagePrompt'], 'a red bicycle');
    expect(rows.single['text'].toString().contains('IMG_PROMPT'), isFalse);
  });

  test('message rows strip every image prompt tag, including thinking', () {
    final rows = WatchPayload.messageRows([
      ChatMessage(
        id: 'a',
        content:
            '<think>see [IMG_PROMPT: secret]</think>Hello [IMG_PROMPT: one] and [IMG_PROMPT: two]',
        role: 'assistant',
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    ]);
    expect(rows.single['text'].toString().contains('IMG_PROMPT'), isFalse);
    expect(rows.single['thinking'].toString().contains('IMG_PROMPT'), isFalse);
    expect(rows.single['text'], contains('Hello'));
  });

  test('message rows keep the last 20 and flag images', () {
    final messages = List.generate(25, (i) {
      return ChatMessage(
        id: '$i',
        content: 'line $i',
        role: i.isEven ? 'user' : 'assistant',
        timestamp: DateTime.utc(2026, 1, 1),
        imageUrls: i == 24 ? const ['path'] : null,
      );
    });
    final rows = WatchPayload.messageRows(messages);
    expect(rows, hasLength(20));
    expect(rows.first['text'], 'line 5');
    expect(rows.last['hasImage'], isTrue);
    expect(rows.last['text'], 'line 24');
  });

  test('message rows keep markdown line breaks and the rest of the answer', () {
    final body =
        'Hello\n\n1. **D&D Character Skills:** Focusing on the skills.\n\n'
        '${'word ' * 120}end';
    expect(body.length, greaterThan(500));
    final rows = WatchPayload.messageRows([
      ChatMessage(
        id: 'a',
        content: body,
        role: 'assistant',
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    ]);
    expect(rows.single['text'], body);
    expect(rows.single['text'].toString().contains('**D&D'), isTrue);
    expect(rows.single['text'].toString().contains('\n'), isTrue);
  });

  test('persona card keeps the prompt and only pins a chosen model', () {
    final persona = SystemPrompt(
      id: 'p1',
      name: 'Researcher',
      content: 'Answer with sources.',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      color: 0xFF4F46E5,
      defaultModelId: '/models/qwen.gguf',
    );
    final card = WatchPayload.personaCard(
      persona: persona,
      settings: AppSettings(
        selectedModel: 'fallback',
        activeProviderKind: 'lmStudio',
      ),
    );
    expect(card['name'], 'Researcher');
    expect(card['prompt'], 'Answer with sources.');
    expect(card['model'], 'qwen.gguf');
    expect(card['provider'], 'LM Studio');
    expect(card['modelPinned'], isTrue);
    expect(card['providerPinned'], isFalse);
    expect(card['color'], 0xFF4F46E5);
    expect(WatchPayload.providerLabel('cloud'), 'Cloud');
    expect(WatchPayload.providerLabel('onDeviceMlx'), 'On-device');
    expect(WatchPayload.modelLabel(''), '');
  });
}
