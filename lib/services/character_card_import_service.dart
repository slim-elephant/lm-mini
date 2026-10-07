import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/system_prompt.dart';
import '../utils/character_card.dart';
import '../utils/expression_tags.dart';

/// Result of importing one or more character card files.
class CharacterCardImportResult {
  final List<SystemPrompt> personas;

  /// File name → reason, for files that could not be imported.
  final Map<String, String> failures;
  final int spriteCount;

  /// Keyword-triggered lorebook entries that were not imported.
  final int skippedLoreEntries;

  const CharacterCardImportResult({
    required this.personas,
    required this.failures,
    required this.spriteCount,
    required this.skippedLoreEntries,
  });
}

/// Result of adding expression sprites to a persona.
class SpriteImportResult {
  /// Label → relative path, merged over the persona's existing sprites.
  final Map<String, String> sprites;
  final int added;

  /// Files whose names didn't match an expression label.
  final List<String> unmatched;

  const SpriteImportResult({
    required this.sprites,
    required this.added,
    required this.unmatched,
  });
}

/// Imports SillyTavern character cards as personas, and expression sprites
/// into personas. Images are stored under `images/` in app documents with
/// relative paths, like other persona avatars.
class CharacterCardImportService {
  CharacterCardImportService._();

  static const cardExtensions = ['png', 'json', 'charx'];
  static const spriteExtensions = ['png', 'webp', 'jpg', 'jpeg', 'gif', 'zip'];
  static const _imageExtensions = {'png', 'webp', 'jpg', 'jpeg', 'gif'};

  /// Opens the file picker and turns every chosen card into a persona.
  /// Returns null when the user cancels.
  static Future<CharacterCardImportResult?> pickAndImportCards({
    required String userName,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: cardExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;

    final personas = <SystemPrompt>[];
    final failures = <String, String>{};
    var sprites = 0;
    var skippedLore = 0;
    for (var i = 0; i < picked.files.length; i++) {
      final file = picked.files[i];
      try {
        final bytes = await _bytesOf(file);
        final card = parseCharacterCardFile(file.name, bytes);
        final persona =
            await personaFromCard(card, userName: userName, index: i);
        personas.add(persona);
        sprites += persona.expressionSprites?.length ?? 0;
        skippedLore += card.skippedLoreEntries;
      } on CharacterCardException catch (e) {
        failures[file.name] = e.message;
      } catch (e) {
        debugPrint('Character card import failed for ${file.name}: $e');
        failures[file.name] = e.toString();
      }
    }
    return CharacterCardImportResult(
      personas: personas,
      failures: failures,
      spriteCount: sprites,
      skippedLoreEntries: skippedLore,
    );
  }

  /// Builds a persona from a parsed card and saves its images.
  static Future<SystemPrompt> personaFromCard(
    CharacterCard card, {
    required String userName,
    int index = 0,
  }) async {
    final now = DateTime.now();
    final id = 'sp_${now.millisecondsSinceEpoch}_$index';
    String sub(String s) =>
        substituteCardMacros(s, charName: card.name, userName: userName)
            .trim();

    String? avatarPath;
    if (card.avatar != null) {
      avatarPath = await _saveImage(
        card.avatar!.bytes,
        folder: 'images',
        name: 'card_$id',
        ext: card.avatar!.ext,
      );
    }
    final sprites = <String, String>{};
    for (final entry in card.expressionSprites.entries) {
      sprites[entry.key] = await _saveSprite(id, entry.key, entry.value);
    }

    final greeting = sub(card.firstMessage);
    final alternates = [
      for (final g in card.alternateGreetings)
        if (sub(g).isNotEmpty) sub(g),
    ];
    return SystemPrompt(
      id: id,
      name: card.name,
      content: buildPersonaPromptFromCard(card, userName: userName),
      createdAt: now,
      updatedAt: now,
      avatarPath: avatarPath,
      greeting: greeting.isEmpty ? null : greeting,
      alternateGreetings: alternates.isEmpty ? null : alternates,
      expressionSprites: sprites.isEmpty ? null : sprites,
      // Character chats shouldn't leak the user's real-life memories by
      // default; the user can switch this back on in the persona editor.
      shareMemories: false,
    );
  }

  /// Opens the file picker for sprite images (named by expression, for
  /// example `joy.png`) or a zip of them, and merges them into [persona].
  /// Returns null when the user cancels.
  static Future<SpriteImportResult?> pickAndImportSprites(
    SystemPrompt persona,
  ) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: spriteExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;

    final images = <String, CardImage>{};
    final unmatched = <String>[];
    void consider(String fileName, Uint8List bytes) {
      final ext = p.extension(fileName).replaceFirst('.', '').toLowerCase();
      if (!_imageExtensions.contains(ext)) return;
      final label = normalizeExpressionLabel(p.basenameWithoutExtension(fileName));
      if (label == null) {
        unmatched.add(p.basename(fileName));
        return;
      }
      // First file wins for a label (joy.png before joy_2.png).
      images.putIfAbsent(label, () => CardImage(bytes, ext));
    }

    final files = [...picked.files]..sort((a, b) => a.name.compareTo(b.name));
    for (final file in files) {
      final bytes = await _bytesOf(file);
      if (file.name.toLowerCase().endsWith('.zip')) {
        final archive = ZipDecoder().decodeBytes(bytes);
        final entries = archive.files.where((f) => f.isFile).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        for (final entry in entries) {
          if (entry.name.split('/').any((part) => part.startsWith('.'))) {
            continue; // __MACOSX/._joy.png and friends
          }
          consider(entry.name, Uint8List.fromList(entry.content as List<int>));
        }
      } else {
        consider(file.name, bytes);
      }
    }

    final merged = Map<String, String>.from(persona.expressionSprites ?? {});
    for (final entry in images.entries) {
      merged[entry.key] = await _saveSprite(persona.id, entry.key, entry.value);
    }
    return SpriteImportResult(
      sprites: merged,
      added: images.length,
      unmatched: unmatched,
    );
  }

  /// Saves one generated or imported sprite and returns its relative path.
  static Future<String> saveSpriteBytes(
    String personaId,
    String label,
    Uint8List bytes, {
    String ext = 'png',
  }) =>
      _saveSprite(personaId, label, CardImage(bytes, ext));

  /// Deletes sprite files that are no longer referenced.
  static Future<void> deleteSpriteFiles(Iterable<String> relativePaths) async {
    final docs = await getApplicationDocumentsDirectory();
    for (final rel in relativePaths) {
      if (!rel.startsWith('images/sprites/')) continue;
      final f = File(p.join(docs.path, rel));
      try {
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  static Future<String> _saveSprite(
    String personaId,
    String label,
    CardImage image,
  ) {
    final safeId = personaId.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return _saveImage(
      image.bytes,
      folder: 'images/sprites/$safeId',
      name: label,
      ext: image.ext,
    );
  }

  static Future<String> _saveImage(
    Uint8List bytes, {
    required String folder,
    required String name,
    required String ext,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final cleanExt = _imageExtensions.contains(ext) ? ext : 'png';
    // Timestamped names so a replaced sprite never shows a cached image.
    final rel =
        '$folder/${name}_${DateTime.now().microsecondsSinceEpoch}.$cleanExt';
    final file = File(p.join(docs.path, rel));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return rel;
  }

  static Future<Uint8List> _bytesOf(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    final path = file.path;
    if (path == null) throw const CharacterCardException('Could not read the file.');
    return File(path).readAsBytes();
  }
}
