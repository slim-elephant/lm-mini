import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/tts_language_catalog.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tts_pack_');
    Directory(p.join(dir.path, 'espeak-ng-data')).createSync();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  void sized(String name, int bytes) {
    final f = File(p.join(dir.path, name))..createSync();
    f.openSync(mode: FileMode.write)
      ..truncateSync(bytes) // sparse: no real disk use
      ..closeSync();
  }

  final english = TtsLanguageCatalog.assetById(TtsLanguageCatalog.englishId)!;

  test('complete Kokoro pack is ready', () {
    sized('model.onnx', 330 * 1024 * 1024);
    sized('voices.bin', 6 * 1024 * 1024);
    sized('tokens.txt', 1000);
    expect(TtsLanguageCatalog.looksLikeModelDir(dir.path, english), isTrue);
  });

  test('truncated model.onnx (interrupted download) is not ready', () {
    sized('model.onnx', 3 * 1024 * 1024);
    sized('voices.bin', 6 * 1024 * 1024);
    sized('tokens.txt', 1000);
    expect(TtsLanguageCatalog.looksLikeModelDir(dir.path, english), isFalse);
  });

  test('empty tokens.txt is not ready', () {
    sized('model.onnx', 330 * 1024 * 1024);
    sized('voices.bin', 6 * 1024 * 1024);
    sized('tokens.txt', 0);
    expect(TtsLanguageCatalog.looksLikeModelDir(dir.path, english), isFalse);
  });
}
