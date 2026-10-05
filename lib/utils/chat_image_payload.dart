import 'dart:io';

/// Decoded size of chat image attachments (data URLs or local files).
///
/// Vision prompts tokenize by tiles, but a large JPEG/PNG in the request is
/// the practical signal that the image ate the context window.
abstract final class ChatImagePayload {
  /// Treat an attachment as "large" once decoded bytes reach 512 KB.
  static const int largeDecodedBytes = 512 * 1024;

  static int decodedByteLength(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return 0;
    if (trimmed.startsWith('data:')) {
      final comma = trimmed.indexOf(',');
      if (comma < 0 || comma + 1 >= trimmed.length) return 0;
      final b64 = trimmed.substring(comma + 1).replaceAll(RegExp(r'\s'), '');
      if (b64.isEmpty) return 0;
      var pad = 0;
      if (b64.endsWith('==')) {
        pad = 2;
      } else if (b64.endsWith('=')) {
        pad = 1;
      }
      final n = (b64.length * 3) ~/ 4 - pad;
      return n < 0 ? 0 : n;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return 0;
    }
    try {
      final file = File(trimmed);
      if (file.existsSync()) return file.lengthSync();
    } catch (_) {}
    return 0;
  }

  static int totalDecodedBytes(Iterable<String>? urls) {
    if (urls == null) return 0;
    var total = 0;
    for (final url in urls) {
      total += decodedByteLength(url);
    }
    return total;
  }

  /// Bytes of the payload if it is large enough to mention; otherwise null.
  static int? largeBytesOrNull(Iterable<String>? urls) {
    final n = totalDecodedBytes(urls);
    return n >= largeDecodedBytes ? n : null;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).round()} KB';
    }
    final mb = bytes / (1024 * 1024);
    final shown = mb >= 10 ? mb.round().toString() : mb.toStringAsFixed(1);
    return '$shown MB';
  }
}
