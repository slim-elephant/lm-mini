import '../models/chat_conversation.dart';
import '../models/chat_folder.dart';
import '../models/chat_message.dart';
import '../models/system_prompt.dart';
import '../utils/chat_title.dart';

class HomeSyncTombstone {
  const HomeSyncTombstone({required this.id, required this.deletedAt});

  final String id;
  final DateTime deletedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'deletedAt': deletedAt.toIso8601String(),
      };

  factory HomeSyncTombstone.fromJson(Map<String, dynamic> json) {
    return HomeSyncTombstone(
      id: json['id'] as String,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class HomeSyncConversation {
  const HomeSyncConversation({
    required this.conversation,
    required this.messages,
  });

  final ChatConversation conversation;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() => {
        'conversation': conversation.toJson(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory HomeSyncConversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return HomeSyncConversation(
      conversation: ChatConversation.fromJson(
        Map<String, dynamic>.from(json['conversation'] as Map),
      ),
      messages: rawMessages is List
          ? rawMessages
              .whereType<Map>()
              .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
    );
  }
}

class HomeSyncPersonaInfo {
  const HomeSyncPersonaInfo({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.memoryCount = 0,
    this.hasAvatar = false,
    this.color,
  });

  final String id;
  final String name;
  final DateTime updatedAt;
  final int memoryCount;
  final bool hasAvatar;
  final int? color;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'updatedAt': updatedAt.toIso8601String(),
        'memoryCount': memoryCount,
        'hasAvatar': hasAvatar,
        if (color != null) 'color': color,
      };

  factory HomeSyncPersonaInfo.fromJson(Map<String, dynamic> json) {
    return HomeSyncPersonaInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      memoryCount: (json['memoryCount'] as num?)?.toInt() ?? 0,
      hasAvatar: json['hasAvatar'] as bool? ?? false,
      color: json['color'] is int
          ? json['color'] as int
          : (json['color'] as num?)?.toInt(),
    );
  }
}

class HomeSyncPersona {
  const HomeSyncPersona({
    required this.prompt,
    this.avatarBase64,
    this.avatarExt,
    this.memories = const [],
  });

  final SystemPrompt prompt;
  final String? avatarBase64;
  final String? avatarExt;
  final List<Map<String, dynamic>> memories;

  Map<String, dynamic> toJson() => {
        'prompt': prompt.toJson(),
        if (avatarBase64 != null) 'avatarBase64': avatarBase64,
        if (avatarExt != null) 'avatarExt': avatarExt,
        'memories': memories,
      };

  factory HomeSyncPersona.fromJson(Map<String, dynamic> json) {
    final rawMem = json['memories'];
    return HomeSyncPersona(
      prompt: SystemPrompt.fromJson(
        Map<String, dynamic>.from(json['prompt'] as Map),
      ),
      avatarBase64: json['avatarBase64'] as String?,
      avatarExt: json['avatarExt'] as String?,
      memories: rawMem is List
          ? [
              for (final item in rawMem)
                if (item is Map) Map<String, dynamic>.from(item),
            ]
          : const [],
    );
  }
}

class HomeSyncSnapshot {
  const HomeSyncSnapshot({
    this.folders = const [],
    this.conversations = const [],
    this.deletedConversations = const [],
    this.deletedFolders = const [],
    this.personaCatalog = const [],
    this.personas = const [],
    this.syncPersonaIds = const [],
    this.personasEnabled = false,
    this.personasUpdatedAt,
  });

  final List<ChatFolder> folders;
  final List<HomeSyncConversation> conversations;
  final List<HomeSyncTombstone> deletedConversations;
  final List<HomeSyncTombstone> deletedFolders;
  final List<HomeSyncPersonaInfo> personaCatalog;
  final List<HomeSyncPersona> personas;
  final List<String> syncPersonaIds;
  final bool personasEnabled;
  final DateTime? personasUpdatedAt;

  Map<String, dynamic> toJson() => {
        'folders': folders.map((f) => f.toJson()).toList(),
        'conversations': conversations.map((c) => c.toJson()).toList(),
        'deletedConversations':
            deletedConversations.map((t) => t.toJson()).toList(),
        'deletedFolders': deletedFolders.map((t) => t.toJson()).toList(),
        'personaCatalog': personaCatalog.map((p) => p.toJson()).toList(),
        'personas': personas.map((p) => p.toJson()).toList(),
        'syncPersonaIds': syncPersonaIds,
        'personasEnabled': personasEnabled,
        if (personasUpdatedAt != null)
          'personasUpdatedAt': personasUpdatedAt!.toIso8601String(),
      };

  factory HomeSyncSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key];
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map) parse(Map<String, dynamic>.from(item)),
      ];
    }

    return HomeSyncSnapshot(
      folders: parseList('folders', ChatFolder.fromJson),
      conversations: parseList('conversations', HomeSyncConversation.fromJson),
      deletedConversations:
          parseList('deletedConversations', HomeSyncTombstone.fromJson),
      deletedFolders: parseList('deletedFolders', HomeSyncTombstone.fromJson),
      personaCatalog: parseList('personaCatalog', HomeSyncPersonaInfo.fromJson),
      personas: parseList('personas', HomeSyncPersona.fromJson),
      syncPersonaIds: (json['syncPersonaIds'] as List?)
              ?.map((e) => e.toString())
              .where((id) => id.isNotEmpty)
              .toList() ??
          const [],
      personasEnabled: json['personasEnabled'] as bool? ?? false,
      personasUpdatedAt: DateTime.tryParse(
        json['personasUpdatedAt'] as String? ?? '',
      ),
    );
  }
}

class HomeSyncMerge {
  HomeSyncMerge._();

  /// Last-write-wins merge. Tombstones win when they are newer than the
  /// surviving record's [updatedAt].
  static HomeSyncSnapshot merge(
    HomeSyncSnapshot local,
    HomeSyncSnapshot remote,
  ) {
    final deletedConvos = _mergeTombstones(
      local.deletedConversations,
      remote.deletedConversations,
    );
    final deletedFolders = _mergeTombstones(
      local.deletedFolders,
      remote.deletedFolders,
    );
    final deletedConvoAt = {
      for (final t in deletedConvos) t.id: t.deletedAt,
    };
    final deletedFolderAt = {
      for (final t in deletedFolders) t.id: t.deletedAt,
    };

    final convos = <String, HomeSyncConversation>{};
    for (final item in [...local.conversations, ...remote.conversations]) {
      final id = item.conversation.id;
      final deletedAt = deletedConvoAt[id];
      if (deletedAt != null &&
          !item.conversation.updatedAt.isAfter(deletedAt)) {
        continue;
      }
      final existing = convos[id];
      if (existing == null) {
        convos[id] = item;
      } else if (item.conversation.updatedAt
          .isAfter(existing.conversation.updatedAt)) {
        convos[id] = HomeSyncConversation(
          conversation: ChatTitle.preferStableTitle(
            winner: item.conversation,
            loser: existing.conversation,
          ),
          messages: item.messages,
        );
      } else {
        convos[id] = HomeSyncConversation(
          conversation: ChatTitle.preferStableTitle(
            winner: existing.conversation,
            loser: item.conversation,
          ),
          messages: existing.messages,
        );
      }
    }

    final folders = <String, ChatFolder>{};
    for (final item in [...local.folders, ...remote.folders]) {
      final deletedAt = deletedFolderAt[item.id];
      if (deletedAt != null && !item.updatedAt.isAfter(deletedAt)) {
        continue;
      }
      final existing = folders[item.id];
      if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
        folders[item.id] = item;
      }
    }

    final collapsed = collapseNamedFolders(
      folders.values.toList(),
      convos.values.toList(),
    );

    final incoming = remote;
    DateTime personaStamp(DateTime? value) =>
        value ?? DateTime.fromMillisecondsSinceEpoch(0);
    final incomingPersonaWins = !personaStamp(local.personasUpdatedAt)
        .isAfter(personaStamp(incoming.personasUpdatedAt));
    final personasEnabled = incomingPersonaWins
        ? incoming.personasEnabled
        : local.personasEnabled;
    final syncIds = {
      if (personasEnabled)
        ...(incomingPersonaWins
            ? incoming.syncPersonaIds
            : local.syncPersonaIds),
    };
    final personasUpdatedAt = incomingPersonaWins
        ? incoming.personasUpdatedAt
        : local.personasUpdatedAt;

    return HomeSyncSnapshot(
      folders: collapsed.folders,
      conversations: collapsed.conversations,
      deletedConversations: deletedConvos,
      deletedFolders: _mergeTombstones(
        deletedFolders,
        collapsed.folderTombstones,
      ),
      personaCatalog: mergePersonaCatalog(
        local.personaCatalog,
        incoming.personaCatalog,
      ),
      personas: mergePersonas(
        local.personas,
        incoming.personas,
        syncIds: syncIds,
      ),
      syncPersonaIds: syncIds.toList(),
      personasEnabled: personasEnabled,
      personasUpdatedAt: personasUpdatedAt,
    );
  }

  static List<HomeSyncPersonaInfo> mergePersonaCatalog(
    List<HomeSyncPersonaInfo> local,
    List<HomeSyncPersonaInfo> remote,
  ) {
    final byId = <String, HomeSyncPersonaInfo>{};
    for (final item in [...local, ...remote]) {
      if (item.id.isEmpty) continue;
      final existing = byId[item.id];
      if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
        byId[item.id] = HomeSyncPersonaInfo(
          id: item.id,
          name: item.name,
          updatedAt: item.updatedAt,
          memoryCount: item.memoryCount >= (existing?.memoryCount ?? 0)
              ? item.memoryCount
              : existing!.memoryCount,
          hasAvatar: item.hasAvatar || (existing?.hasAvatar ?? false),
          color: item.color ?? existing?.color,
        );
      } else {
        byId[item.id] = HomeSyncPersonaInfo(
          id: existing.id,
          name: existing.name,
          updatedAt: existing.updatedAt,
          memoryCount: existing.memoryCount >= item.memoryCount
              ? existing.memoryCount
              : item.memoryCount,
          hasAvatar: existing.hasAvatar || item.hasAvatar,
          color: existing.color ?? item.color,
        );
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static List<HomeSyncPersona> mergePersonas(
    List<HomeSyncPersona> local,
    List<HomeSyncPersona> remote, {
    required Set<String> syncIds,
  }) {
    if (syncIds.isEmpty) return const [];
    final byId = <String, HomeSyncPersona>{};
    for (final item in [...local, ...remote]) {
      final id = item.prompt.id;
      if (!syncIds.contains(id)) continue;
      final existing = byId[id];
      byId[id] = existing == null ? item : pickPersona(existing, item);
    }
    return byId.values.toList();
  }

  static HomeSyncPersona pickPersona(HomeSyncPersona a, HomeSyncPersona b) {
    final aWins = !b.prompt.updatedAt.isAfter(a.prompt.updatedAt);
    final winner = aWins ? a : b;
    final loser = aWins ? b : a;
    final winnerHasBytes = winner.avatarBase64?.isNotEmpty ?? false;
    final winnerHasPath = winner.prompt.avatarPath?.isNotEmpty ?? false;
    return HomeSyncPersona(
      prompt: winner.prompt,
      avatarBase64: winnerHasBytes
          ? winner.avatarBase64
          : winnerHasPath
              ? null
              : loser.avatarBase64,
      avatarExt: winnerHasBytes
          ? winner.avatarExt
          : winnerHasPath
              ? winner.avatarExt
              : (loser.avatarExt ?? winner.avatarExt),
      memories: mergePersonaMemories(a.memories, b.memories),
    );
  }

  static List<Map<String, dynamic>> mergePersonaMemories(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    DateTime stamp(Map<String, dynamic> m) =>
        DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
        DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    String key(Map<String, dynamic> m) {
      final id = m['id']?.toString().trim() ?? '';
      if (id.isNotEmpty) return 'id:$id';
      return 'c:${m['content']}|${m['scope']}|${m['personaId']}';
    }

    final byKey = <String, Map<String, dynamic>>{};
    for (final item in [...a, ...b]) {
      final k = key(item);
      final existing = byKey[k];
      if (existing == null || stamp(item).isAfter(stamp(existing))) {
        byKey[k] = item;
      }
    }
    return byKey.values.toList();
  }

  /// Folders with the same name (trimmed, case-insensitive) become one folder.
  /// Conversations pointing at dropped ids are remapped onto the survivor.
  static ({
    List<ChatFolder> folders,
    List<HomeSyncConversation> conversations,
    List<HomeSyncTombstone> folderTombstones,
    Map<String, String> remap,
  }) collapseNamedFolders(
    List<ChatFolder> folders,
    List<HomeSyncConversation> conversations, {
    DateTime? tombstoneAt,
  }) {
    DateTime? stamp;
    DateTime at() => stamp ??= tombstoneAt ?? DateTime.now();
    final groups = <String, List<ChatFolder>>{};
    final ungrouped = <ChatFolder>[];
    for (final folder in folders) {
      final key = folder.name.trim().toLowerCase();
      if (key.isEmpty) {
        ungrouped.add(folder);
        continue;
      }
      groups.putIfAbsent(key, () => []).add(folder);
    }

    final kept = <String, ChatFolder>{
      for (final folder in ungrouped) folder.id: folder,
    };
    final remap = <String, String>{};
    final tombstones = <HomeSyncTombstone>[];

    int memberCount(ChatFolder folder) {
      final ids = {...folder.conversationIds};
      for (final item in conversations) {
        if (item.conversation.folderId == folder.id) {
          ids.add(item.conversation.id);
        }
      }
      return ids.length;
    }

    for (final group in groups.values) {
      if (group.length == 1) {
        kept[group.first.id] = group.first;
        continue;
      }
      group.sort((a, b) {
        final byMembers = memberCount(b).compareTo(memberCount(a));
        if (byMembers != 0) return byMembers;
        final byUpdated = b.updatedAt.compareTo(a.updatedAt);
        if (byUpdated != 0) return byUpdated;
        return a.sortOrder.compareTo(b.sortOrder);
      });
      final winner = group.first;
      final ids = <String>{...winner.conversationIds};
      var latest = winner.updatedAt;
      for (final loser in group.skip(1)) {
        ids.addAll(loser.conversationIds);
        if (loser.updatedAt.isAfter(latest)) latest = loser.updatedAt;
        remap[loser.id] = winner.id;
        tombstones.add(HomeSyncTombstone(id: loser.id, deletedAt: at()));
      }
      kept[winner.id] = winner.copyWith(
        conversationIds: ids.toList(),
        updatedAt: latest,
      );
    }

    final remapped = <HomeSyncConversation>[];
    for (final item in conversations) {
      final oldId = item.conversation.folderId;
      final newId = oldId == null ? null : (remap[oldId] ?? oldId);
      if (newId == oldId) {
        remapped.add(item);
        continue;
      }
      remapped.add(
        HomeSyncConversation(
          conversation: item.conversation.copyWith(
            folderId: newId,
            updatedAt: at(),
          ),
          messages: item.messages,
        ),
      );
      if (newId != null) {
        final folder = kept[newId];
        if (folder != null &&
            !folder.conversationIds.contains(item.conversation.id)) {
          kept[newId] = folder.copyWith(
            conversationIds: [...folder.conversationIds, item.conversation.id],
            updatedAt: at(),
          );
        }
      }
    }

    final byConvoId = {
      for (final item in remapped) item.conversation.id: item,
    };
    for (final folder in kept.values) {
      for (final convoId in folder.conversationIds) {
        final item = byConvoId[convoId];
        if (item == null || item.conversation.folderId == folder.id) continue;
        byConvoId[convoId] = HomeSyncConversation(
          conversation: item.conversation.copyWith(
            folderId: folder.id,
            updatedAt: at(),
          ),
          messages: item.messages,
        );
      }
    }

    return (
      folders: kept.values.toList(),
      conversations: byConvoId.values.toList(),
      folderTombstones: tombstones,
      remap: remap,
    );
  }

  static List<HomeSyncTombstone> _mergeTombstones(
    List<HomeSyncTombstone> a,
    List<HomeSyncTombstone> b,
  ) {
    final map = <String, HomeSyncTombstone>{};
    for (final t in [...a, ...b]) {
      final existing = map[t.id];
      if (existing == null || t.deletedAt.isAfter(existing.deletedAt)) {
        map[t.id] = t;
      }
    }
    return map.values.toList();
  }
}

/// Counts used by the first-connect opt-in dialog.
class HomeSyncPreview {
  const HomeSyncPreview({
    required this.localChats,
    required this.localFolders,
    this.remoteChats,
    this.remoteFolders,
    this.remoteReachable = false,
  });

  final int localChats;
  final int localFolders;
  final int? remoteChats;
  final int? remoteFolders;
  final bool remoteReachable;

  bool get phoneHasData => localChats > 0 || localFolders > 0;
  bool get macHasData =>
      (remoteChats ?? 0) > 0 || (remoteFolders ?? 0) > 0;

  HomeSyncPromptKind get kind {
    if (!remoteReachable) return HomeSyncPromptKind.generic;
    if (phoneHasData && macHasData) return HomeSyncPromptKind.both;
    if (phoneHasData) return HomeSyncPromptKind.phoneOnly;
    if (macHasData) return HomeSyncPromptKind.macOnly;
    return HomeSyncPromptKind.generic;
  }
}

enum HomeSyncPromptKind { both, phoneOnly, macOnly, generic }

