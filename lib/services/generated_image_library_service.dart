import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/chat_message.dart';
import '../models/generated_image_library_item.dart';
import 'database_service.dart';

/// Lists generated stills/videos from chat messages plus leftover files on disk.
class GeneratedImageLibraryService {
  GeneratedImageLibraryService({DatabaseService? database})
      : _db = database ?? DatabaseService();

  final DatabaseService _db;

  static Future<Directory> imagesDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/generated_images');
  }

  static Future<String> resolvePath(String stored) async {
    final file = File(stored);
    if (await file.exists()) return stored;
    final name = generatedFileKey(stored);
    if (name.isEmpty) return stored;
    final dir = await imagesDirectory();
    final relocated = '${dir.path}/$name';
    if (await File(relocated).exists()) return relocated;
    return stored;
  }

  Future<List<GeneratedImageLibraryItem>> listAll() async {
    final fromDb = await _db.listGeneratedImageLibraryItems();
    final resolved = <GeneratedImageLibraryItem>[];
    final seenKeys = <String>{};
    for (final item in fromDb) {
      final path = await resolvePath(item.filePath);
      seenKeys.add(generatedFileKey(path));
      seenKeys.add(generatedFileKey(item.filePath));
      resolved.add(GeneratedImageLibraryItem(
        filePath: path,
        messageId: item.messageId,
        conversationId:
            (item.conversationId == null || item.conversationId!.isEmpty)
                ? null
                : item.conversationId,
        conversationTitle: item.conversationTitle,
        timestamp: item.timestamp,
        imagePrompt: item.imagePrompt,
        infoJson: item.infoJson,
      ));
    }

    try {
      final dir = await imagesDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is! File) continue;
          final key = generatedFileKey(entity.path);
          if (key.startsWith('.')) continue;
          if (seenKeys.contains(key)) continue;
          seenKeys.add(key);
          resolved.add(GeneratedImageLibraryItem(
            filePath: entity.path,
            timestamp: entity.statSync().modified,
            orphan: true,
          ));
        }
      }
    } catch (_) {}

    resolved.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return resolved;
  }

  /// Deletes files and unlinks them from messages. Chat text is kept.
  Future<int> deleteItems(List<GeneratedImageLibraryItem> items) async {
    if (items.isEmpty) return 0;
    final keys = items.map((i) => i.fileKey).where((k) => k.isNotEmpty).toSet();
    final byMessage = <String, List<GeneratedImageLibraryItem>>{};
    for (final item in items) {
      final id = item.messageId;
      if (id == null || id.isEmpty) continue;
      byMessage.putIfAbsent(id, () => []).add(item);
    }

    for (final entry in byMessage.entries) {
      final msg = await _db.getMessage(entry.key);
      if (msg == null) continue;
      final stripped = stripGeneratedImageFiles(msg, keys);
      if (stripped != null) {
        await _db.updateMessage(stripped);
      }
    }

    var deleted = 0;
    for (final item in items) {
      for (final path in {item.filePath, await resolvePath(item.filePath)}) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            deleted++;
            break;
          }
        } catch (_) {}
      }
    }
    return deleted;
  }
}

/// Apply library deletes to an in-memory transcript.
List<ChatMessage> applyGeneratedImageDeletes(
  List<ChatMessage> messages,
  Iterable<GeneratedImageLibraryItem> items,
) {
  final keys = items.map((i) => i.fileKey).where((k) => k.isNotEmpty).toSet();
  if (keys.isEmpty) return messages;
  return [
    for (final msg in messages) stripGeneratedImageFiles(msg, keys) ?? msg,
  ];
}
