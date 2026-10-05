import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/chat_image_payload.dart';

void main() {
  group('ChatImagePayload', () {
    test('estimates decoded bytes from a data URL', () {
      final bytes = List<int>.filled(600 * 1024, 7);
      final url = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      expect(ChatImagePayload.decodedByteLength(url), bytes.length);
      expect(ChatImagePayload.largeBytesOrNull([url]), bytes.length);
      expect(ChatImagePayload.formatBytes(bytes.length), '600 KB');
    });

    test('ignores a small thumbnail', () {
      final bytes = List<int>.filled(40 * 1024, 1);
      final url = 'data:image/png;base64,${base64Encode(bytes)}';
      expect(ChatImagePayload.largeBytesOrNull([url]), isNull);
    });
  });
}
