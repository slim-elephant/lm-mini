import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lm_mini/utils/chat_image_compress.dart';
import 'package:lm_mini/utils/chat_image_payload.dart';

void main() {
  group('ChatImageCompress', () {
    test('shrinks a large JPEG under the vision payload cap', () async {
      final src = img.Image(width: 2400, height: 1800);
      final rnd = math.Random(1);
      for (var y = 0; y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          src.setPixelRgb(
            x,
            y,
            rnd.nextInt(256),
            rnd.nextInt(256),
            rnd.nextInt(256),
          );
        }
      }
      final original = Uint8List.fromList(
        img.encodeJpg(src, quality: 95),
      );
      expect(original.length, greaterThan(ChatImagePayload.largeDecodedBytes));

      final compressed = await ChatImageCompress.compressBytes(original);
      expect(compressed, isNotNull);
      expect(compressed!.length, lessThan(original.length));

      final decoded = img.decodeImage(compressed)!;
      expect(decoded.width, lessThanOrEqualTo(ChatImageCompress.maxEdge));
      expect(decoded.height, lessThanOrEqualTo(ChatImageCompress.maxEdge));
    });

    test(
        'llama.cpp vision edge stays at 768 so Gemma 4 fits the default ubatch',
        () async {
      final src = img.Image(width: 1600, height: 1200);
      img.fill(src, color: img.ColorRgb8(40, 80, 120));
      final original = Uint8List.fromList(img.encodeJpg(src, quality: 90));
      final compressed = await ChatImageCompress.compressBytes(
        original,
        edge: ChatImageCompress.llamaCppVisionMaxEdge,
      );
      expect(compressed, isNotNull);
      final decoded = img.decodeImage(compressed!)!;
      expect(
        math.max(decoded.width, decoded.height),
        lessThanOrEqualTo(ChatImageCompress.llamaCppVisionMaxEdge),
      );
      expect(ChatImageCompress.llamaCppVisionMaxEdge, 768);
    });

    test('leaves a tiny thumbnail as-is', () async {
      final src = img.Image(width: 64, height: 48);
      img.fill(src, color: img.ColorRgb8(9, 9, 9));
      final original = Uint8List.fromList(img.encodeJpg(src, quality: 70));
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(original)}';
      expect(ChatImagePayload.largeBytesOrNull([dataUrl]), isNull);
      expect(await ChatImageCompress.compressUrl(dataUrl), isNull);
    });
  });
}
