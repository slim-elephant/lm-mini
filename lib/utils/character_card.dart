/// SillyTavern / Tavern character cards → LM Mini personas.
///
/// Supports:
/// - PNG cards with the card JSON base64-encoded in a `ccv3` (V3) or `chara`
///   (V1/V2) text chunk (tEXt, zTXt or iTXt).
/// - Raw JSON: V1 (flat fields, including the old TavernAI `char_*` names),
///   V2 (`chara_card_v2`) and V3 (`chara_card_v3`).
/// - CHARX (`.charx`): a zip with `card.json` plus assets (avatar icon and
///   `emotion` sprites).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'expression_tags.dart';

/// An image carried by a card file (avatar or expression sprite).
class CardImage {
  final Uint8List bytes;

  /// Lowercase extension without the dot (`png`, `webp`, `jpg`).
  final String ext;

  const CardImage(this.bytes, this.ext);
}

class CharacterCard {
  final String spec; // 'v1', 'chara_card_v2', 'chara_card_v3'
  final String name;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final List<String> alternateGreetings;
  final String exampleDialogue;
  final String systemPrompt;
  final String postHistoryInstructions;
  final String creatorNotes;
  final String creator;
  final List<String> tags;

  /// Lorebook entries marked always-on (`constant`). Keyword-triggered
  /// entries are not imported; see [skippedLoreEntries].
  final List<String> constantLore;
  final int skippedLoreEntries;

  final CardImage? avatar;

  /// Expression label (see [kExpressionLabels]) → image.
  final Map<String, CardImage> expressionSprites;

  const CharacterCard({
    required this.spec,
    required this.name,
    this.description = '',
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.alternateGreetings = const [],
    this.exampleDialogue = '',
    this.systemPrompt = '',
    this.postHistoryInstructions = '',
    this.creatorNotes = '',
    this.creator = '',
    this.tags = const [],
    this.constantLore = const [],
    this.skippedLoreEntries = 0,
    this.avatar,
    this.expressionSprites = const {},
  });

  CharacterCard withImages({
    CardImage? avatar,
    Map<String, CardImage>? expressionSprites,
  }) =>
      CharacterCard(
        spec: spec,
        name: name,
        description: description,
        personality: personality,
        scenario: scenario,
        firstMessage: firstMessage,
        alternateGreetings: alternateGreetings,
        exampleDialogue: exampleDialogue,
        systemPrompt: systemPrompt,
        postHistoryInstructions: postHistoryInstructions,
        creatorNotes: creatorNotes,
        creator: creator,
        tags: tags,
        constantLore: constantLore,
        skippedLoreEntries: skippedLoreEntries,
        avatar: avatar ?? this.avatar,
        expressionSprites: expressionSprites ?? this.expressionSprites,
      );
}

/// Thrown when a file is not a readable character card.
class CharacterCardException implements Exception {
  final String message;
  const CharacterCardException(this.message);
  @override
  String toString() => message;
}

const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

/// Parses a card from a file's name and bytes.
CharacterCard parseCharacterCardFile(String fileName, Uint8List bytes) {
  final lower = fileName.toLowerCase();
  if (_isPng(bytes)) {
    final json = readPngCardJson(bytes);
    if (json == null) {
      throw const CharacterCardException(
          'This PNG has no character card data. Export it from SillyTavern '
          'or download the card PNG, not a plain image.');
    }
    return parseCharacterCardJson(json)
        .withImages(avatar: CardImage(bytes, 'png'));
  }
  if (lower.endsWith('.charx') || _isZip(bytes)) {
    return _parseCharx(bytes);
  }
  final text = utf8.decode(bytes, allowMalformed: true).trim();
  if (text.startsWith('{')) {
    return parseCharacterCardJson(_decodeJsonObject(text));
  }
  throw const CharacterCardException(
      'Not a character card. Use a SillyTavern card PNG, a .json card or a '
      '.charx file.');
}

bool _isPng(Uint8List b) {
  if (b.length < 8) return false;
  for (var i = 0; i < 8; i++) {
    if (b[i] != _pngSignature[i]) return false;
  }
  return true;
}

bool _isZip(Uint8List b) =>
    b.length > 4 && b[0] == 0x50 && b[1] == 0x4B && b[2] == 0x03 && b[3] == 0x04;

/// Reads the card JSON from a PNG's text chunks. Prefers `ccv3` over
/// `chara`. Returns null when neither chunk is present.
Map<String, dynamic>? readPngCardJson(Uint8List bytes) {
  if (!_isPng(bytes)) return null;
  final chunks = <String, String>{};
  final data = ByteData.sublistView(bytes);
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length = data.getUint32(offset);
    final type = latin1.decode(bytes.sublist(offset + 4, offset + 8));
    final start = offset + 8;
    final end = start + length;
    if (end + 4 > bytes.length) break;
    if (type == 'tEXt' || type == 'zTXt' || type == 'iTXt') {
      final entry = _readTextChunk(type, bytes.sublist(start, end));
      if (entry != null) {
        final key = entry.key.toLowerCase();
        if (key == 'ccv3' || key == 'chara') chunks[key] = entry.value;
      }
    }
    if (type == 'IEND') break;
    offset = end + 4;
  }
  for (final key in const ['ccv3', 'chara']) {
    final raw = chunks[key];
    if (raw == null) continue;
    try {
      final decoded = utf8.decode(base64.decode(_cleanBase64(raw)));
      return _decodeJsonObject(decoded);
    } catch (_) {
      // Some exporters store plain JSON instead of base64.
      try {
        return _decodeJsonObject(raw);
      } catch (_) {}
    }
  }
  return null;
}

String _cleanBase64(String raw) {
  final s = raw.replaceAll(RegExp(r'\s'), '');
  final pad = s.length % 4;
  return pad == 0 ? s : s + '=' * (4 - pad);
}

MapEntry<String, String>? _readTextChunk(String type, Uint8List chunk) {
  final nul = chunk.indexOf(0);
  if (nul <= 0) return null;
  final keyword = latin1.decode(chunk.sublist(0, nul));
  try {
    switch (type) {
      case 'tEXt':
        return MapEntry(keyword, latin1.decode(chunk.sublist(nul + 1)));
      case 'zTXt':
        final inflated = const ZLibDecoder().decodeBytes(chunk.sublist(nul + 2));
        return MapEntry(keyword, latin1.decode(inflated));
      case 'iTXt':
        final compressed = chunk[nul + 1] == 1;
        var i = nul + 3;
        final langEnd = chunk.indexOf(0, i); // language tag
        if (langEnd < 0) return null;
        final transEnd = chunk.indexOf(0, langEnd + 1); // translated keyword
        if (transEnd < 0) return null;
        i = transEnd + 1;
        var text = chunk.sublist(i);
        if (compressed) {
          text = Uint8List.fromList(const ZLibDecoder().decodeBytes(text));
        }
        return MapEntry(keyword, utf8.decode(text, allowMalformed: true));
    }
  } catch (_) {
    return null;
  }
  return null;
}

Map<String, dynamic> _decodeJsonObject(String text) {
  final decoded = jsonDecode(text);
  if (decoded is! Map) {
    throw const CharacterCardException('The card JSON is not an object.');
  }
  return Map<String, dynamic>.from(decoded);
}

String _str(Object? v) => v == null ? '' : v.toString().trim();

List<String> _strList(Object? v) => v is List
    ? [
        for (final e in v)
          if (_str(e).isNotEmpty) _str(e),
      ]
    : const [];

/// Parses V1, V2 or V3 card JSON.
CharacterCard parseCharacterCardJson(Map<String, dynamic> json) {
  final spec = _str(json['spec']);
  final isWrapped = (spec == 'chara_card_v2' || spec == 'chara_card_v3') &&
      json['data'] is Map;
  final d = isWrapped ? Map<String, dynamic>.from(json['data'] as Map) : json;

  final name = _str(d['name']).isNotEmpty ? _str(d['name']) : _str(d['char_name']);
  if (name.isEmpty) {
    throw const CharacterCardException('The card has no character name.');
  }

  final lore = <String>[];
  var skipped = 0;
  final book = d['character_book'];
  if (book is Map && book['entries'] is List) {
    for (final entry in book['entries'] as List) {
      if (entry is! Map) continue;
      final content = _str(entry['content']);
      if (content.isEmpty || entry['enabled'] == false) continue;
      if (entry['constant'] == true) {
        lore.add(content);
      } else {
        skipped++;
      }
    }
  }

  return CharacterCard(
    spec: isWrapped ? spec : 'v1',
    name: name,
    description: _str(d['description']).isNotEmpty
        ? _str(d['description'])
        : _str(d['char_persona']),
    personality: _str(d['personality']),
    scenario: _str(d['scenario']).isNotEmpty
        ? _str(d['scenario'])
        : _str(d['world_scenario']),
    firstMessage: _str(d['first_mes']).isNotEmpty
        ? _str(d['first_mes'])
        : _str(d['char_greeting']),
    alternateGreetings: _strList(d['alternate_greetings']),
    exampleDialogue: _str(d['mes_example']).isNotEmpty
        ? _str(d['mes_example'])
        : _str(d['example_dialogue']),
    systemPrompt: _str(d['system_prompt']),
    postHistoryInstructions: _str(d['post_history_instructions']),
    creatorNotes: _str(d['creator_notes']),
    creator: _str(d['creator']),
    tags: _strList(d['tags']),
    constantLore: lore,
    skippedLoreEntries: skipped,
  );
}

CharacterCard _parseCharx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const CharacterCardException('The .charx file is not a valid zip.');
  }
  ArchiveFile? cardFile;
  for (final f in archive.files) {
    if (f.isFile && f.name.split('/').last.toLowerCase() == 'card.json') {
      cardFile = f;
      break;
    }
  }
  if (cardFile == null) {
    throw const CharacterCardException('The .charx file has no card.json.');
  }
  final json = _decodeJsonObject(
      utf8.decode(cardFile.content as List<int>, allowMalformed: true));
  final card = parseCharacterCardJson(json);

  Uint8List? fileBytes(String uri) {
    // CHARX uses "embeded://" (sic) and sometimes "embedded://".
    final path = uri.replaceFirst(RegExp(r'^embedd?ed://'), '');
    for (final f in archive.files) {
      if (f.isFile && f.name == path) {
        return Uint8List.fromList(f.content as List<int>);
      }
    }
    return null;
  }

  CardImage? avatar;
  final sprites = <String, CardImage>{};
  final data = json['data'];
  final assets = data is Map ? data['assets'] : null;
  if (assets is List) {
    for (final asset in assets) {
      if (asset is! Map) continue;
      final type = _str(asset['type']).toLowerCase();
      final uri = _str(asset['uri']);
      if (!uri.startsWith('embed')) continue;
      final b = fileBytes(uri);
      if (b == null) continue;
      final ext = _str(asset['ext']).toLowerCase().isNotEmpty
          ? _str(asset['ext']).toLowerCase()
          : uri.split('.').last.toLowerCase();
      if (type == 'icon' && (avatar == null || _str(asset['name']) == 'main')) {
        avatar = CardImage(b, ext);
      } else if (type == 'emotion') {
        final label = normalizeExpressionLabel(_str(asset['name']));
        if (label != null) sprites.putIfAbsent(label, () => CardImage(b, ext));
      }
    }
  }
  return card.withImages(avatar: avatar, expressionSprites: sprites);
}

/// Replaces card macros. `{{char}}`/`<BOT>` → the character, `{{user}}`/
/// `<USER>` → the user's name. Unknown macros are left as they are.
String substituteCardMacros(
  String text, {
  required String charName,
  required String userName,
}) {
  return text
      .replaceAll(RegExp(r'\{\{\s*char\s*\}\}', caseSensitive: false), charName)
      .replaceAll(RegExp(r'<BOT>', caseSensitive: false), charName)
      .replaceAll(RegExp(r'\{\{\s*user\s*\}\}', caseSensitive: false), userName)
      .replaceAll(RegExp(r'<USER>', caseSensitive: false), userName)
      .replaceAll(RegExp(r'\{\{\s*original\s*\}\}', caseSensitive: false), '');
}

/// Builds the persona system prompt from a card.
String buildPersonaPromptFromCard(CharacterCard card, {required String userName}) {
  String sub(String s) =>
      substituteCardMacros(s, charName: card.name, userName: userName).trim();

  final parts = <String>[];
  final system = sub(card.systemPrompt);
  parts.add(system.isNotEmpty
      ? system
      : 'You are ${card.name}. Stay in character as ${card.name} in this '
          'conversation with $userName. Write ${card.name}\'s replies only.');
  void section(String title, String body) {
    final text = sub(body);
    if (text.isNotEmpty) parts.add('## $title\n$text');
  }

  section(card.name, card.description);
  section('Personality', card.personality);
  section('Scenario', card.scenario);
  if (card.constantLore.isNotEmpty) {
    section('World info', card.constantLore.join('\n\n'));
  }
  final examples = card.exampleDialogue
      .replaceAll(RegExp(r'^\s*<START>\s*$', multiLine: true), '---')
      .replaceFirst(RegExp(r'^\s*---\s*'), '');
  section('Example dialogue', examples);
  final post = sub(card.postHistoryInstructions);
  if (post.isNotEmpty) parts.add(post);
  return parts.join('\n\n');
}
