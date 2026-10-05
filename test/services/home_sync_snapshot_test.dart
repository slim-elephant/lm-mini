import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/chat_conversation.dart';
import 'package:lm_mini/models/chat_folder.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/models/system_prompt.dart';
import 'package:lm_mini/services/home_sync_snapshot.dart';

ChatConversation _convo(String id, DateTime updated) => ChatConversation(
      id: id,
      title: id,
      createdAt: updated,
      updatedAt: updated,
      messageIds: const ['m1'],
      settings: const {},
    );

HomeSyncConversation _packed(String id, DateTime updated) =>
    HomeSyncConversation(
      conversation: _convo(id, updated),
      messages: [
        ChatMessage(
          id: 'm-$id',
          content: 'hi',
          role: 'user',
          timestamp: updated,
        ),
      ],
    );

void main() {
  final older = DateTime.utc(2026, 1, 1);
  final newer = DateTime.utc(2026, 8, 1);

  test('keeps the newer conversation when both sides edited', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(conversations: [_packed('a', older)]),
      HomeSyncSnapshot(conversations: [_packed('a', newer)]),
    );
    expect(merged.conversations.single.conversation.updatedAt, newer);
  });

  test('adds a conversation that only exists on Home', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(conversations: [_packed('phone', newer)]),
      HomeSyncSnapshot(conversations: [_packed('home', newer)]),
    );
    expect(merged.conversations.map((c) => c.conversation.id).toSet(),
        {'phone', 'home'});
  });

  test('tombstone deletes an older local chat', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(conversations: [_packed('gone', older)]),
      HomeSyncSnapshot(
        deletedConversations: [
          HomeSyncTombstone(id: 'gone', deletedAt: newer),
        ],
      ),
    );
    expect(merged.conversations, isEmpty);
  });

  test('a newer local edit beats a tombstone', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(conversations: [_packed('kept', newer)]),
      HomeSyncSnapshot(
        deletedConversations: [
          HomeSyncTombstone(id: 'kept', deletedAt: older),
        ],
      ),
    );
    expect(merged.conversations.single.conversation.id, 'kept');
  });

  test('newer Home record keeps the phone AI title', () {
    final phone = HomeSyncConversation(
      conversation: ChatConversation(
        id: 'a',
        title: 'Safe trip home Bushra',
        createdAt: older,
        updatedAt: older,
        messageIds: const ['m1'],
        settings: const {'titleSource': 'ai'},
      ),
      messages: const [],
    );
    final home = HomeSyncConversation(
      conversation: ChatConversation(
        id: 'a',
        title: '[IMG_PROMPT: Pakistani woma...',
        createdAt: older,
        updatedAt: newer,
        messageIds: const ['m1', 'm2'],
        settings: const {'titleSource': 'auto'},
      ),
      messages: const [],
    );
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(conversations: [phone]),
      HomeSyncSnapshot(conversations: [home]),
    );
    expect(merged.conversations.single.conversation.title,
        'Safe trip home Bushra');
    expect(merged.conversations.single.conversation.settings['titleSource'],
        'ai');
  });

  test('merges folders by updatedAt', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(
        folders: [
          ChatFolder(
            id: 'f',
            name: 'Old',
            createdAt: older,
            updatedAt: older,
            conversationIds: const [],
          ),
        ],
      ),
      HomeSyncSnapshot(
        folders: [
          ChatFolder(
            id: 'f',
            name: 'New',
            createdAt: older,
            updatedAt: newer,
            conversationIds: const ['a'],
          ),
        ],
      ),
    );
    expect(merged.folders.single.name, 'New');
    expect(merged.folders.single.conversationIds, ['a']);
  });

  test('collapses two folders with the same name', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(
        folders: [
          ChatFolder(
            id: 'games-phone',
            name: 'Games',
            createdAt: older,
            updatedAt: older,
            conversationIds: const ['c1'],
          ),
        ],
        conversations: [_packed('c1', older)],
      ),
      HomeSyncSnapshot(
        folders: [
          ChatFolder(
            id: 'games-mac',
            name: 'games',
            createdAt: newer,
            updatedAt: newer,
            conversationIds: const ['c2'],
          ),
        ],
        conversations: [
          HomeSyncConversation(
            conversation: _convo('c2', newer).copyWith(folderId: 'games-mac'),
            messages: const [],
          ),
        ],
      ),
    );
    expect(merged.folders, hasLength(1));
    expect(merged.folders.single.name.toLowerCase(), 'games');
    expect(merged.folders.single.conversationIds.toSet(), {'c1', 'c2'});
    expect(
      merged.conversations
          .where((c) => c.conversation.id == 'c2')
          .single
          .conversation
          .folderId,
      merged.folders.single.id,
    );
    expect(merged.deletedFolders.map((t) => t.id).toSet().length, 1);
  });

  test('merge is idempotent when both sides already match', () {
    final snap = HomeSyncSnapshot(
      folders: [
        ChatFolder(
          id: 'f',
          name: 'Games',
          createdAt: older,
          updatedAt: older,
          conversationIds: const ['a'],
        ),
      ],
      conversations: [
        HomeSyncConversation(
          conversation: _convo('a', older).copyWith(folderId: 'f'),
          messages: const [],
        ),
      ],
    );
    final merged = HomeSyncMerge.merge(snap, snap);
    expect(merged.folders.single.updatedAt, older);
    expect(merged.conversations.single.conversation.updatedAt, older);
    expect(merged.conversations.single.conversation.folderId, 'f');
    expect(merged.deletedFolders, isEmpty);
  });

  test('preview copy picks both / phone / mac / generic', () {
    expect(
      const HomeSyncPreview(
        localChats: 3,
        localFolders: 0,
        remoteChats: 5,
        remoteFolders: 1,
        remoteReachable: true,
      ).kind,
      HomeSyncPromptKind.both,
    );
    expect(
      const HomeSyncPreview(
        localChats: 2,
        localFolders: 0,
        remoteChats: 0,
        remoteFolders: 0,
        remoteReachable: true,
      ).kind,
      HomeSyncPromptKind.phoneOnly,
    );
    expect(
      const HomeSyncPreview(
        localChats: 0,
        localFolders: 0,
        remoteChats: 4,
        remoteFolders: 0,
        remoteReachable: true,
      ).kind,
      HomeSyncPromptKind.macOnly,
    );
    expect(
      const HomeSyncPreview(localChats: 2, localFolders: 1).kind,
      HomeSyncPromptKind.generic,
    );
  });

  SystemPrompt persona({
    required String id,
    required String name,
    required DateTime updatedAt,
    String? avatarPath,
    String content = 'hello',
  }) {
    return SystemPrompt(
      id: id,
      name: name,
      content: content,
      createdAt: updatedAt,
      updatedAt: updatedAt,
      avatarPath: avatarPath,
    );
  }

  test('persona catalog unions both devices and keeps the higher memory count',
      () {
    final merged = HomeSyncMerge.mergePersonaCatalog(
      [
        HomeSyncPersonaInfo(
          id: 'a',
          name: 'Old',
          updatedAt: older,
          memoryCount: 1,
          hasAvatar: false,
        ),
      ],
      [
        HomeSyncPersonaInfo(
          id: 'a',
          name: 'New',
          updatedAt: newer,
          memoryCount: 4,
          hasAvatar: true,
        ),
        HomeSyncPersonaInfo(
          id: 'b',
          name: 'Mac only',
          updatedAt: newer,
          memoryCount: 2,
        ),
      ],
    );
    expect(merged.map((p) => p.id).toSet(), {'a', 'b'});
    final a = merged.singleWhere((p) => p.id == 'a');
    expect(a.name, 'New');
    expect(a.memoryCount, 4);
    expect(a.hasAvatar, isTrue);
  });

  test('persona payloads merge only checked ids and union memories', () {
    final phone = HomeSyncPersona(
      prompt: persona(id: 'p', name: 'Phone', updatedAt: newer),
      avatarBase64: 'cGhvbmU=',
      avatarExt: '.jpg',
      memories: [
        {
          'id': 'm1',
          'content': 'likes tea',
          'scope': 'private',
          'personaId': 'p',
          'updatedAt': older.toIso8601String(),
        },
      ],
    );
    final home = HomeSyncPersona(
      prompt: persona(id: 'p', name: 'Home', updatedAt: older),
      memories: [
        {
          'id': 'm2',
          'content': 'lives in KL',
          'scope': 'private',
          'personaId': 'p',
          'updatedAt': newer.toIso8601String(),
        },
        {
          'id': 'm1',
          'content': 'likes oolong',
          'scope': 'private',
          'personaId': 'p',
          'updatedAt': newer.toIso8601String(),
        },
      ],
    );
    final other = HomeSyncPersona(
      prompt: persona(id: 'skip', name: 'Skip', updatedAt: newer),
    );
    final merged = HomeSyncMerge.mergePersonas(
      [phone, other],
      [home],
      syncIds: {'p'},
    );
    expect(merged, hasLength(1));
    expect(merged.single.prompt.name, 'Phone');
    expect(merged.single.avatarBase64, 'cGhvbmU=');
    expect(merged.single.memories, hasLength(2));
    expect(
      merged.single.memories.map((m) => m['content']).toSet(),
      {'likes oolong', 'lives in KL'},
    );
  });

  test('persona memories without ids collapse on content + scope + persona',
      () {
    final merged = HomeSyncMerge.mergePersonaMemories(
      [
        {
          'content': 'same fact',
          'scope': 'private',
          'personaId': 'p',
          'updatedAt': older.toIso8601String(),
        },
      ],
      [
        {
          'content': 'same fact',
          'scope': 'private',
          'personaId': 'p',
          'updatedAt': newer.toIso8601String(),
          'category': 'personal',
        },
      ],
    );
    expect(merged, hasLength(1));
    expect(merged.single['category'], 'personal');
  });

  test('newer persona-sync selection wins over an older chat-sync POST', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(
        personasEnabled: true,
        syncPersonaIds: const ['kept'],
        personasUpdatedAt: newer,
        personaCatalog: [
          HomeSyncPersonaInfo(id: 'kept', name: 'Kept', updatedAt: newer),
        ],
      ),
      HomeSyncSnapshot(
        personasEnabled: false,
        syncPersonaIds: const [],
        personasUpdatedAt: older,
      ),
    );
    expect(merged.personasEnabled, isTrue);
    expect(merged.syncPersonaIds, ['kept']);
  });

  test('newer phone persona-sync selection overwrites Home', () {
    final merged = HomeSyncMerge.merge(
      HomeSyncSnapshot(
        personasEnabled: true,
        syncPersonaIds: const ['old'],
        personasUpdatedAt: older,
      ),
      HomeSyncSnapshot(
        personasEnabled: true,
        syncPersonaIds: const ['new'],
        personasUpdatedAt: newer,
      ),
    );
    expect(merged.syncPersonaIds, ['new']);
  });
}
