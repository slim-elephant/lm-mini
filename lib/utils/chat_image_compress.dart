import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import 'chat_image_payload.dart';
import 'vision_physical_batch.dart';

/// Shrinks chat vision attachments so LM Studio / llama.cpp is less likely
/// to kill the generation (OOM / `terminated`).
abstract final class ChatImageCompress {
  static const int maxEdge = 1280;
  static const int jpegQuality = 70;
  static const int aggressiveMaxEdge = 768;

  /// Longest edge for photos sent to LM Studio / llama.cpp.
  ///
  /// Gemma 4 encodes the image with non-causal attention, so the whole image
  /// must fit in one ubatch. LM Studio's default ubatch is 512. A square
  /// 768px image is about 300 tokens; a full-resolution photo goes past 512
  /// and llama-server aborts, which unloads the model.
  static const int llamaCppVisionMaxEdge = 768;
  static const int aggressiveJpegQuality = 50;
  static const failedUserMessage =
      "Couldn't shrink the attached image. Try a smaller photo.";

  /// Shrinks only photos whose pixel count would exceed llama.cpp's default
  /// physical batch. Returns null when every image is already safe.
  static Future<List<String>?> shrinkUrlsToPhysicalBatch(
    List<String> urls,
  ) async {
    if (urls.isEmpty) return null;
    final out = <String>[];
    var changed = false;
    for (final url in urls) {
      final shrunk = await shrinkUrlToPhysicalBatch(url);
      if (shrunk != null && shrunk != url) {
        out.add(shrunk);
        changed = true;
      } else {
        out.add(url);
      }
    }
    return changed ? out : null;
  }

  static Future<String?> shrinkUrlToPhysicalBatch(String url) async {
    final bytes = await bytesFromUrl(url);
    if (bytes == null || bytes.isEmpty) return null;
    img.Image? decoded = img.decodeImage(bytes);
    decoded ??= await _decodeWithDartUi(bytes);
    if (decoded == null) return null;
    if (!VisionPhysicalBatch.exceeds(decoded.width, decoded.height)) {
      return null;
    }
    final edge = VisionPhysicalBatch.targetLongestEdge(
      decoded.width,
      decoded.height,
    );
    final jpeg = await compressBytes(bytes, edge: edge);
    if (jpeg == null || jpeg.isEmpty) return null;
    return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
  }

  /// Returns a new list when at least one URL got smaller; otherwise null.
  static Future<List<String>?> compressUrls(
    List<String> urls, {
    int edge = maxEdge,
    int quality = jpegQuality,
  }) async {
    if (urls.isEmpty) return null;
    final out = <String>[];
    var changed = false;
    for (final url in urls) {
      final compressed = await compressUrl(
        url,
        edge: edge,
        quality: quality,
      );
      if (compressed != null && compressed != url) {
        out.add(compressed);
        changed = true;
      } else {
        out.add(url);
      }
    }
    return changed ? out : null;
  }

  static Future<String?> compressUrl(
    String url, {
    int edge = maxEdge,
    int quality = jpegQuality,
  }) async {
    final bytes = await bytesFromUrl(url);
    if (bytes == null || bytes.isEmpty) return null;

    final jpeg = await compressBytes(
      bytes,
      edge: edge,
      quality: quality,
    );
    if (jpeg == null || jpeg.isEmpty) return null;
    if (jpeg.length >= bytes.length &&
        ChatImagePayload.decodedByteLength(url) <
            ChatImagePayload.largeDecodedBytes) {
      return null;
    }
    if (jpeg.length >= bytes.length) {
      // Still worth switching to JPEG of a resized frame when the original
      // was a huge PNG / HEIC even if encodeJpg couldn't beat the file size.
      final decoded = img.decodeImage(bytes);
      if (decoded != null && math.max(decoded.width, decoded.height) <= edge) {
        return null;
      }
    }
    return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
  }

  static Future<Uint8List?> compressBytes(
    Uint8List bytes, {
    int edge = maxEdge,
    int quality = jpegQuality,
  }) async {
    img.Image? decoded = img.decodeImage(bytes);
    decoded ??= await _decodeWithDartUi(bytes);
    if (decoded == null) return null;

    final longest = math.max(decoded.width, decoded.height);
    var frame = decoded;
    if (longest > edge) {
      final scale = edge / longest;
      frame = img.copyResize(
        decoded,
        width: math.max(1, (decoded.width * scale).round()),
        height: math.max(1, (decoded.height * scale).round()),
        interpolation: img.Interpolation.linear,
      );
    }

    return Uint8List.fromList(img.encodeJpg(frame, quality: quality));
  }

  static Future<Uint8List?> bytesFromUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('data:')) {
      final comma = trimmed.indexOf(',');
      if (comma < 0 || comma + 1 >= trimmed.length) return null;
      try {
        return Uint8List.fromList(
          base64Decode(
              trimmed.substring(comma + 1).replaceAll(RegExp(r'\s'), '')),
        );
      } catch (_) {
        return null;
      }
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return null;
    }
    try {
      final file = File(trimmed);
      if (await file.exists()) return await file.readAsBytes();
    } catch (_) {}
    return null;
  }

  static Future<img.Image?> _decodeWithDartUi(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final w = image.width;
      final h = image.height;
      final bd = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (bd == null) return null;
      return img.Image.fromBytes(
        width: w,
        height: h,
        bytes: bd.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
    } catch (_) {
      return null;
    }
  }
}
