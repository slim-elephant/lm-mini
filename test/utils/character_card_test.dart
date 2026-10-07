import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/character_card.dart';

Uint8List _chunk(String type, List<int> data) {
  final out = BytesBuilder();
  final len = ByteData(4)..setUint32(0, data.length);
  out.add(len.buffer.asUint8List());
  out.add(latin1.encode(type));
  out.add(data);
  out.add([0, 0, 0, 0]); // CRC is not checked by the reader.
  return out.toBytes();
}

Uint8List _png(Map<String, List<int>> textChunks) {
  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);
  out.add(_chunk('IHDR', List.filled(13, 0)));
  textChunks.forEach((type, data) => out.add(_chunk(type, data)));
  out.add(_chunk('IEND', const []));
  return out.toBytes();
}

List<int> _tEXt(String key, String value) =>
    [...latin1.encode(key), 0, ...latin1.encode(value)];

String _b64(Map<String, dynamic> json) => base64.encode(utf8.encode(jsonEncode(json)));

Map<String, dynamic> _v2({String name = 'Aria'}) => {
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': {
        'name': name,
        'description': '{{char}} is a starship engineer.',
        'personality': 'curious, blunt',
        'scenario': '{{user}} visits the engine room.',
        'first_mes': '*{{char}} looks up.* Oh, hi {{user}}.',
        'alternate_greetings': ['Back again?', ''],
        'mes_example': '<START>\n{{user}}: Hi\n{{char}}: Hey.',
        'system_prompt': '',
        'post_history_instructions': '',
        'tags': ['sci-fi'],
        'creator': 'someone',
        'character_book': {
          'entries': [
            {'content': 'The ship is called Halcyon.', 'constant': true},
            {'content': 'Secret lore.', 'constant': false, 'keys': ['x']},
          ],
        },
      },
    };

void main() {
  group('PNG cards', () {
    test('reads a V2 card from a chara tEXt chunk and keeps the PNG as avatar',
        () {
      final png = _png({'tEXt': _tEXt('chara', _b64(_v2()))});
      final card = parseCharacterCardFile('aria.png', png);
      expect(card.spec, 'chara_card_v2');
      expect(card.name, 'Aria');
      expect(card.alternateGreetings, ['Back again?']);
      expect(card.constantLore, ['The ship is called Halcyon.']);
      expect(card.skippedLoreEntries, 1);
      expect(card.avatar?.bytes, png);
      expect(card.avatar?.ext, 'png');
    });

    test('prefers ccv3 over chara', () {
      final v3 = _v2(name: 'Aria V3')..['spec'] = 'chara_card_v3';
      final out = BytesBuilder()
        ..add([137, 80, 78, 71, 13, 10, 26, 10])
        ..add(_chunk('tEXt', _tEXt('chara', _b64(_v2(name: 'Old')))))
        ..add(_chunk('tEXt', _tEXt('ccv3', _b64(v3))))
        ..add(_chunk('IEND', const []));
      final card = parseCharacterCardFile('a.png', out.toBytes());
      expect(card.name, 'Aria V3');
      expect(card.spec, 'chara_card_v3');
    });

    test('reads a compressed iTXt chunk', () {
      final text = utf8.encode(_b64(_v2(name: 'Zed')));
      final compressed = const ZLibEncoder().encode(text);
      final data = [
        ...latin1.encode('chara'), 0, 1, 0, // keyword, compressed, method
        0, // empty language tag
        0, // empty translated keyword
        ...compressed,
      ];
      final card = parseCharacterCardFile('z.png', _png({'iTXt': data}));
      expect(card.name, 'Zed');
    });

    test('a plain PNG explains that it is not a card', () {
      expect(
        () => parseCharacterCardFile('photo.png', _png({})),
        throwsA(isA<CharacterCardException>()),
      );
    });
  });

  group('JSON cards', () {
    test('reads flat V1 and old TavernAI field names', () {
      final card = parseCharacterCardFile(
        'old.json',
        Uint8List.fromList(utf8.encode(jsonEncode({
          'char_name': 'Old Bob',
          'char_persona': 'A grumpy innkeeper.',
          'world_scenario': 'A tavern.',
          'char_greeting': 'What do you want?',
          'example_dialogue': '',
        }))),
      );
      expect(card.spec, 'v1');
      expect(card.name, 'Old Bob');
      expect(card.description, 'A grumpy innkeeper.');
      expect(card.firstMessage, 'What do you want?');
    });

    test('rejects a card without a name', () {
      expect(
        () => parseCharacterCardJson({'description': 'x'}),
        throwsA(isA<CharacterCardException>()),
      );
    });
  });

  test('CHARX: avatar icon and emotion sprites', () {
    final card = _v2()..['spec'] = 'chara_card_v3';
    (card['data'] as Map)['assets'] = [
      {'type': 'icon', 'uri': 'embeded://assets/icon/main.png', 'name': 'main', 'ext': 'png'},
      {'type': 'emotion', 'uri': 'embeded://assets/emotion/Happy.webp', 'name': 'happy', 'ext': 'webp'},
      {'type': 'emotion', 'uri': 'embeded://assets/emotion/sad_2.png', 'name': 'sadness_2', 'ext': 'png'},
      {'type': 'emotion', 'uri': 'embeded://assets/emotion/x.png', 'name': 'not-an-emotion', 'ext': 'png'},
    ];
    final archive = Archive()
      ..addFile(ArchiveFile.string('card.json', jsonEncode(card)))
      ..addFile(ArchiveFile('assets/icon/main.png', 3, [1, 2, 3]))
      ..addFile(ArchiveFile('assets/emotion/Happy.webp', 1, [4]))
      ..addFile(ArchiveFile('assets/emotion/sad_2.png', 1, [5]))
      ..addFile(ArchiveFile('assets/emotion/x.png', 1, [6]));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
    final parsed = parseCharacterCardFile('aria.charx', bytes);
    expect(parsed.avatar?.bytes, [1, 2, 3]);
    expect(parsed.expressionSprites.keys, unorderedEquals(['joy', 'sadness']));
    expect(parsed.expressionSprites['joy']?.ext, 'webp');
  });

  group('persona prompt', () {
    test('substitutes macros and includes the card sections', () {
      final card = parseCharacterCardJson(_v2());
      final prompt = buildPersonaPromptFromCard(card, userName: 'Sam');
      expect(prompt, contains('Aria is a starship engineer.'));
      expect(prompt, contains('Sam visits the engine room.'));
      expect(prompt, contains('## Personality\ncurious, blunt'));
      expect(prompt, contains('## World info\nThe ship is called Halcyon.'));
      expect(prompt, isNot(contains('Secret lore.')));
      expect(prompt, isNot(contains('<START>')));
      expect(prompt, isNot(contains('{{')));
    });

    test('a card system prompt replaces the default opener', () {
      final json = _v2();
      (json['data'] as Map)['system_prompt'] =
          'Write as {{char}}. {{original}}';
      final prompt = buildPersonaPromptFromCard(parseCharacterCardJson(json),
          userName: 'Sam');
      expect(prompt.startsWith('Write as Aria.'), isTrue);
      expect(prompt, isNot(contains('Stay in character')));
    });

    test('substituteCardMacros handles <BOT>/<USER> and spacing', () {
      expect(
        substituteCardMacros('<BOT> greets <USER>. {{ char }}/{{User}}',
            charName: 'A', userName: 'B'),
        'A greets B. A/B',
      );
    });
  });
}
