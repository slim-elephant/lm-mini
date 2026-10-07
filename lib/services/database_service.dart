import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/chat_folder.dart';
import '../models/generated_image_library_item.dart';
import '../utils/response_parser.dart';
import '../utils/chat_title.dart';
import 'dart:convert';
import 'dart:io';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'chat_app.db';
  static const int _dbVersion =
      13; // Persist the character expression shown with assistant replies

  static const String _messagesTable = 'messages';
  static const String _conversationsTable = 'conversations';
  static const String _foldersTable = 'folders';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_conversationsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        message_ids TEXT NOT NULL,
        settings TEXT NOT NULL,
        folder_id TEXT,
        last_response_id TEXT,
        parent_conversation_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $_messagesTable (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        role TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        model TEXT,
        stats TEXT,
        model_info TEXT,
        runtime_info TEXT,
        usage TEXT,
        image_urls TEXT,
        file_attachments TEXT,
        response_id TEXT,
        image_prompt TEXT,
        generated_image_paths TEXT,
        generated_image_info TEXT,
        participant_id TEXT,
        expression TEXT,
        alternatives TEXT,
        alternative_index INTEGER,
        conversation_id TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES $_conversationsTable (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $_foldersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        conversation_ids TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for message stats
      await db.execute('ALTER TABLE $_messagesTable ADD COLUMN stats TEXT');
      await db
          .execute('ALTER TABLE $_messagesTable ADD COLUMN model_info TEXT');
      await db
          .execute('ALTER TABLE $_messagesTable ADD COLUMN runtime_info TEXT');
      await db.execute('ALTER TABLE $_messagesTable ADD COLUMN usage TEXT');
    }

    if (oldVersion < 3) {
      // Add folders table and folder_id column
      await db.execute('''
        CREATE TABLE $_foldersTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          conversation_ids TEXT NOT NULL
        )
      ''');

      await db.execute(
          'ALTER TABLE $_conversationsTable ADD COLUMN folder_id TEXT');
      await db
          .execute('ALTER TABLE $_messagesTable ADD COLUMN image_urls TEXT');
    }

    if (oldVersion < 4) {
      await db
          .execute('ALTER TABLE $_messagesTable ADD COLUMN response_id TEXT');
    }

    if (oldVersion < 5) {
      await db.execute(
          'ALTER TABLE $_conversationsTable ADD COLUMN parent_conversation_id TEXT');
    }

    if (oldVersion < 6) {
      await db
          .execute('ALTER TABLE $_messagesTable ADD COLUMN image_prompt TEXT');
      await db.execute(
          'ALTER TABLE $_messagesTable ADD COLUMN generated_image_paths TEXT');
    }

    if (oldVersion < 7) {
      await db.execute(
          'ALTER TABLE $_conversationsTable ADD COLUMN last_response_id TEXT');
    }

    if (oldVersion < 8) {
      final hasSortOrder = await _columnExists(db, _foldersTable, 'sort_order');
      if (!hasSortOrder) {
        await db.execute(
          'ALTER TABLE $_foldersTable ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
        );
      }
    }

    if (oldVersion < 9) {
      final hasParticipantId =
          await _columnExists(db, _messagesTable, 'participant_id');
      if (!hasParticipantId) {
        await db.execute(
          'ALTER TABLE $_messagesTable ADD COLUMN participant_id TEXT',
        );
      }
    }

    if (oldVersion < 10) {
      final hasAlternatives =
          await _columnExists(db, _messagesTable, 'alternatives');
      if (!hasAlternatives) {
        await db.execute(
          'ALTER TABLE $_messagesTable ADD COLUMN alternatives TEXT',
        );
      }
      final hasAlternativeIndex =
          await _columnExists(db, _messagesTable, 'alternative_index');
      if (!hasAlternativeIndex) {
        await db.execute(
          'ALTER TABLE $_messagesTable ADD COLUMN alternative_index INTEGER',
        );
      }
    }

    if (oldVersion < 11) {
      final hasFileAttachments =
          await _columnExists(db, _messagesTable, 'file_attachments');
      if (!hasFileAttachments) {
        await db.execute(
          'ALTER TABLE $_messagesTable ADD COLUMN file_attachments TEXT',
        );
      }
    }

    if (oldVersion < 12) {
      final hasGeneratedImageInfo =
          await _columnExists(db, _messagesTable, 'generated_image_info');
      if (!hasGeneratedImageInfo) {
        await db.execute(
          'ALTER TABLE $_messagesTable ADD COLUMN generated_image_info TEXT',
        );
      }
    }

    if (oldVersion < 13) {
      if (!await _columnExists(db, _messagesTable, 'expression')) {
        await db.execute(
          'ALTER TABLE $_messagesTable ADD COLUMN expression TEXT',
        );
      }
    }
  }

  Future<bool> _columnExists(
      Database db, String tableName, String columnName) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }

  // Conversation methods
  Future<String> insertConversation(ChatConversation conversation) async {
    final db = await database;
    await db.insert(
      _conversationsTable,
      {
        'id': conversation.id,
        'title': conversation.title,
        'created_at': conversation.createdAt.millisecondsSinceEpoch,
        'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
        'message_ids': jsonEncode(conversation.messageIds),
        'settings': jsonEncode(conversation.settings),
        'folder_id': conversation.folderId,
        'last_response_id': conversation.lastResponseId,
        'parent_conversation_id': conversation.parentConversationId,
      },
    );
    return conversation.id;
  }

  Future<List<ChatConversation>> getAllConversations() async {
    final db = await database;
    final maps = await db.query(
      _conversationsTable,
      orderBy: 'updated_at DESC',
    );

    return maps
        .map((map) => ChatConversation(
              id: map['id'] as String,
              title: map['title'] as String,
              createdAt:
                  DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
              updatedAt:
                  DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
              messageIds:
                  List<String>.from(jsonDecode(map['message_ids'] as String)),
              settings: Map<String, dynamic>.from(
                  jsonDecode(map['settings'] as String)),
              folderId:
                  map['folder_id']?.toString(),
              lastResponseId: map['last_response_id'] as String?,
              parentConversationId: map['parent_conversation_id']?.toString(),
            ))
        .toList();
  }

  Future<void> updateConversation(ChatConversation conversation) async {
    final db = await database;
    await db.update(
      _conversationsTable,
      {
        'title': conversation.title,
        'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
        'message_ids': jsonEncode(conversation.messageIds),
        'settings': jsonEncode(conversation.settings),
        'folder_id': conversation.folderId,
        'last_response_id': conversation.lastResponseId,
      },
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    final db = await database;
    // Clean up generated image files before cascade-deleting messages
    final maps = await db.query(
      _messagesTable,
      columns: ['generated_image_paths'],
      where: 'conversation_id = ? AND generated_image_paths IS NOT NULL',
      whereArgs: [conversationId],
    );
    for (final map in maps) {
      try {
        final paths = List<String>.from(
          jsonDecode(map['generated_image_paths'] as String),
        );
        for (final path in paths) {
          try {
            final file = File(path);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
      } catch (_) {}
    }
    await db.delete(
      _conversationsTable,
      where: 'id = ?',
      whereArgs: [conversationId],
    );
    // Messages will be deleted automatically due to CASCADE
  }

  // Message methods
  Future<String> insertMessage(
      ChatMessage message, String conversationId) async {
    final db = await database;
    await db.insert(
      _messagesTable,
      {
        'id': message.id,
        'content': message.content,
        'role': message.role,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'model': message.model,
        'stats':
            message.stats != null ? jsonEncode(message.stats!.toJson()) : null,
        'model_info': message.modelInfo != null
            ? jsonEncode(message.modelInfo!.toJson())
            : null,
        'runtime_info': message.runtimeInfo != null
            ? jsonEncode(message.runtimeInfo!.toJson())
            : null,
        'usage':
            message.usage != null ? jsonEncode(message.usage!.toJson()) : null,
        'image_urls':
            message.imageUrls != null ? jsonEncode(message.imageUrls) : null,
        'file_attachments': message.fileAttachments != null &&
                message.fileAttachments!.isNotEmpty
            ? jsonEncode(
                message.fileAttachments!.map((f) => f.toJson()).toList())
            : null,
        'response_id': message.responseId,
        'conversation_id': conversationId,
        'image_prompt': message.imagePrompt,
        'generated_image_paths': message.allGeneratedImagePaths.isNotEmpty
            ? jsonEncode(message.allGeneratedImagePaths)
            : null,
        'generated_image_info': message.generatedImageInfo,
        'expression': message.expression,
        'participant_id': message.participantId,
        'alternatives': message.alternatives != null
            ? jsonEncode(message.alternatives!.map((m) => m.toJson()).toList())
            : null,
        'alternative_index': message.alternativeIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return message.id;
  }

  Future<void> upsertConversation(ChatConversation conversation) async {
    final db = await database;
    await db.insert(
      _conversationsTable,
      {
        'id': conversation.id,
        'title': conversation.title,
        'created_at': conversation.createdAt.millisecondsSinceEpoch,
        'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
        'message_ids': jsonEncode(conversation.messageIds),
        'settings': jsonEncode(conversation.settings),
        'folder_id': conversation.folderId,
        'last_response_id': conversation.lastResponseId,
        'parent_conversation_id': conversation.parentConversationId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertFolder(ChatFolder folder) async {
    final db = await database;
    await db.insert(
      _foldersTable,
      {
        'id': folder.id,
        'name': folder.name,
        'color': folder.color,
        'created_at': folder.createdAt.millisecondsSinceEpoch,
        'updated_at': folder.updatedAt.millisecondsSinceEpoch,
        'conversation_ids': jsonEncode(folder.conversationIds),
        'sort_order': folder.sortOrder,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Latest assistant message preview for conversation list rows.
  Future<String?> getLastAssistantPreview(
    String conversationId, {
    int maxChars = 100,
  }) async {
    final db = await database;
    final maps = await db.query(
      _messagesTable,
      columns: ['content'],
      where: "conversation_id = ? AND role = 'assistant'",
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    var text = (maps.first['content'] as String?)?.trim() ?? '';
    if (text.isEmpty) return null;
    // Strip thinking / hidden tags for list preview.
    text = ChatTitle.displayLabel(ResponseParser.answerOnly(text));
    if (text.isEmpty) return null;
    if (text.length > maxChars) {
      return '${text.substring(0, maxChars).trimRight()}…';
    }
    return text;
  }

  Future<List<ChatMessage>> getMessagesForConversation(
      String conversationId) async {
    final db = await database;
    final maps = await db.query(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return maps.map(_messageFromDbMap).toList();
  }

  ChatMessage _messageFromDbMap(Map<String, Object?> map) {
    List<String>? imagePaths;
    try {
      if (map['generated_image_paths'] != null) {
        imagePaths = List<String>.from(
            jsonDecode(map['generated_image_paths'] as String));
      }
    } catch (_) {}
    return ChatMessage.fromJson({
      'id': map['id'],
      'content': map['content'],
      'role': map['role'],
      'timestamp': DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          .toIso8601String(),
      'model': map['model'],
      'stats': map['stats'] != null ? jsonDecode(map['stats'] as String) : null,
      'modelInfo': map['model_info'] != null
          ? jsonDecode(map['model_info'] as String)
          : null,
      'runtimeInfo': map['runtime_info'] != null
          ? jsonDecode(map['runtime_info'] as String)
          : null,
      'usage': map['usage'] != null ? jsonDecode(map['usage'] as String) : null,
      'imageUrls': map['image_urls'] != null
          ? List<String>.from(jsonDecode(map['image_urls'] as String))
          : null,
      'fileAttachments': map['file_attachments'] != null
          ? jsonDecode(map['file_attachments'] as String)
          : null,
      'responseId': map['response_id'],
      'imagePrompt': map['image_prompt'],
      'generatedImagePaths': imagePaths,
      'generatedImagePath':
          imagePaths != null && imagePaths.isNotEmpty ? imagePaths.first : null,
      'generatedImageInfo': map['generated_image_info'],
      'participantId': map['participant_id'],
      'expression': map['expression'],
      'alternatives': map['alternatives'] != null
          ? jsonDecode(map['alternatives'] as String)
          : null,
      'alternativeIndex': map['alternative_index'],
    });
  }

  Future<ChatMessage?> getMessage(String messageId) async {
    final db = await database;
    final maps = await db.query(
      _messagesTable,
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _messageFromDbMap(maps.first);
  }

  /// Every generated still/video attached to a chat message, newest first.
  Future<List<GeneratedImageLibraryItem>>
      listGeneratedImageLibraryItems() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT m.id, m.content, m.role, m.timestamp, m.model, m.stats,
             m.model_info, m.runtime_info, m.usage, m.image_urls,
             m.file_attachments, m.response_id, m.image_prompt,
             m.generated_image_paths, m.generated_image_info,
             m.participant_id, m.expression, m.alternatives,
             m.alternative_index,
             m.conversation_id, c.title AS conversation_title
      FROM $_messagesTable m
      LEFT JOIN $_conversationsTable c ON c.id = m.conversation_id
      WHERE (m.generated_image_paths IS NOT NULL
             AND TRIM(m.generated_image_paths) != ''
             AND m.generated_image_paths != '[]')
         OR (m.alternatives IS NOT NULL
             AND m.alternatives LIKE '%generatedImagePath%')
      ORDER BY m.timestamp DESC
    ''');
    final items = <GeneratedImageLibraryItem>[];
    for (final map in maps) {
      try {
        final msg = _messageFromDbMap(map);
        items.addAll(libraryItemsFromMessage(
          message: msg,
          conversationId: map['conversation_id'] as String? ?? '',
          conversationTitle: map['conversation_title'] as String?,
        ));
      } catch (_) {}
    }
    return items;
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    // Fetch image paths before deleting so we can clean up files
    final maps = await db.query(
      _messagesTable,
      columns: ['generated_image_paths'],
      where: 'id = ?',
      whereArgs: [messageId],
    );
    if (maps.isNotEmpty && maps.first['generated_image_paths'] != null) {
      final paths = List<String>.from(
        jsonDecode(maps.first['generated_image_paths'] as String),
      );
      for (final path in paths) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    await db.delete(
      _messagesTable,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Writes generated-image paths even if that message is not in the open
  /// chat. Leaving the conversation must not drop a finished image.
  Future<void> updateMessageGeneratedImages({
    required String messageId,
    required List<String> paths,
    String? info,
  }) async {
    final db = await database;
    await db.update(
      _messagesTable,
      {
        'generated_image_paths': paths.isNotEmpty ? jsonEncode(paths) : null,
        'generated_image_info': info,
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Paths already stored for [messageId], or empty if the row is missing.
  Future<List<String>> getGeneratedImagePaths(String messageId) async {
    final db = await database;
    final maps = await db.query(
      _messagesTable,
      columns: ['generated_image_paths'],
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (maps.isEmpty) return const [];
    final raw = maps.first['generated_image_paths'];
    if (raw is! String || raw.isEmpty) return const [];
    try {
      return List<String>.from(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  Future<void> updateMessage(ChatMessage message) async {
    final db = await database;
    await db.update(
      _messagesTable,
      {
        'content': message.content,
        'model': message.model,
        'stats':
            message.stats != null ? jsonEncode(message.stats!.toJson()) : null,
        'model_info': message.modelInfo != null
            ? jsonEncode(message.modelInfo!.toJson())
            : null,
        'runtime_info': message.runtimeInfo != null
            ? jsonEncode(message.runtimeInfo!.toJson())
            : null,
        'usage':
            message.usage != null ? jsonEncode(message.usage!.toJson()) : null,
        'image_urls':
            message.imageUrls != null ? jsonEncode(message.imageUrls) : null,
        'file_attachments': message.fileAttachments != null &&
                message.fileAttachments!.isNotEmpty
            ? jsonEncode(
                message.fileAttachments!.map((f) => f.toJson()).toList())
            : null,
        'image_prompt': message.imagePrompt,
        'generated_image_paths': message.allGeneratedImagePaths.isNotEmpty
            ? jsonEncode(message.allGeneratedImagePaths)
            : null,
        'generated_image_info': message.generatedImageInfo,
        'expression': message.expression,
        'alternatives': message.alternatives != null
            ? jsonEncode(message.alternatives!.map((m) => m.toJson()).toList())
            : null,
        'alternative_index': message.alternativeIndex,
      },
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessagesAfterTimestamp(
      String conversationId, int timestamp) async {
    final db = await database;
    await db.delete(
      _messagesTable,
      where: 'conversation_id = ? AND timestamp >= ?',
      whereArgs: [conversationId, timestamp],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_messagesTable);
    await db.delete(_conversationsTable);
    await db.delete(_foldersTable);
  }

  // Folder methods
  Future<String> insertFolder(ChatFolder folder) async {
    final db = await database;
    await db.insert(
      _foldersTable,
      {
        'id': folder.id,
        'name': folder.name,
        'color': folder.color,
        'created_at': folder.createdAt.millisecondsSinceEpoch,
        'updated_at': folder.updatedAt.millisecondsSinceEpoch,
        'conversation_ids': jsonEncode(folder.conversationIds),
        'sort_order': folder.sortOrder,
      },
    );
    return folder.id;
  }

  Future<List<ChatFolder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query(
      _foldersTable,
      orderBy: 'sort_order ASC, name ASC',
    );

    return maps
        .map((map) => ChatFolder(
              id: map['id'] as String,
              name: map['name'] as String,
              color: map['color'] as String?,
              createdAt:
                  DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
              updatedAt:
                  DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
              conversationIds: List<String>.from(
                  jsonDecode(map['conversation_ids'] as String)),
              sortOrder: (map['sort_order'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<ChatFolder?> getFolderById(String id) async {
    final db = await database;
    final maps = await db.query(
      _foldersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return ChatFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      conversationIds:
          List<String>.from(jsonDecode(map['conversation_ids'] as String)),
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Future<void> updateFolder(ChatFolder folder) async {
    final db = await database;
    await db.update(
      _foldersTable,
      {
        'name': folder.name,
        'color': folder.color,
        'updated_at': folder.updatedAt.millisecondsSinceEpoch,
        'conversation_ids': jsonEncode(folder.conversationIds),
        'sort_order': folder.sortOrder,
      },
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> updateFolderSortOrders(List<ChatFolder> folders) async {
    final db = await database;
    final batch = db.batch();
    for (final folder in folders) {
      batch.update(
        _foldersTable,
        {'sort_order': folder.sortOrder},
        where: 'id = ?',
        whereArgs: [folder.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> reassignConversationsToFolder(
    String fromFolderId,
    String toFolderId,
  ) async {
    final db = await database;
    await db.update(
      _conversationsTable,
      {'folder_id': toFolderId},
      where: 'folder_id = ?',
      whereArgs: [fromFolderId],
    );
  }

  Future<void> deleteFolderRow(String folderId) async {
    final db = await database;
    await db.delete(
      _foldersTable,
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  Future<void> deleteFolder(String folderId) async {
    final db = await database;

    // Remove folder_id from conversations
    await db.update(
      _conversationsTable,
      {'folder_id': null},
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );

    // Delete folder
    await db.delete(
      _foldersTable,
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  // ─── Backup / Restore Helpers ────────────────────────────────────

  /// Export all data as raw database maps (for cloud backup).
  /// Returns a map with 'conversations', 'messages', and 'folders' lists.
  Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await database;
    return {
      'conversations': await db.query(_conversationsTable),
      'messages': await db.query(_messagesTable),
      'folders': await db.query(_foldersTable),
    };
  }

  /// Import data from a backup payload, replacing ALL local data.
  ///
  /// [backupData] must contain 'conversations', 'messages', and 'folders' lists.
  /// Each item in those lists must be a Map matching the database column schema.
  Future<void> importAllData(Map<String, dynamic> backupData) async {
    final db = await database;

    // Clear everything first
    await clearAllData();

    // Use batch writes for performance
    final batch = db.batch();

    final conversations = backupData['conversations'] as List? ?? [];
    for (final row in conversations) {
      batch.insert(_conversationsTable, Map<String, dynamic>.from(row as Map));
    }

    final messages = backupData['messages'] as List? ?? [];
    for (final row in messages) {
      batch.insert(_messagesTable, Map<String, dynamic>.from(row as Map));
    }

    final folders = backupData['folders'] as List? ?? [];
    for (final row in folders) {
      batch.insert(_foldersTable, Map<String, dynamic>.from(row as Map));
    }

    await batch.commit(noResult: true);
  }
}
