import 'dart:math' as math;

/// Whether a photo would exceed llama.cpp's default physical batch.
///
/// The server keeps `n_ubatch` at 512 unless the user raises it. Gemma 4
/// snaps a photo to 70, 140, 280, 560, or 1120 vision tokens. 560 and 1120
/// are over 512, so the server aborts. 280 is the largest budget that fits.
abstract final class VisionPhysicalBatch {
  static const int defaultPhysicalBatch = 512;

  /// Last Gemma 4 vision budget that still fits in [defaultPhysicalBatch].
  static const int safeTokenBudget = 280;

  /// Patch 16 pooled 3×3 → one token covers 48×48 pixels.
  static const int pixelsPerToken = 48 * 48;

  static int get safeMaxPixels => safeTokenBudget * pixelsPerToken;

  static bool exceeds(int width, int height) {
    if (width <= 0 || height <= 0) return false;
    return width * height > safeMaxPixels;
  }

  /// Longest edge that brings [width]×[height] inside [safeMaxPixels].
  static int targetLongestEdge(int width, int height) {
    final longest = math.max(width, height);
    if (!exceeds(width, height)) return longest;
    final scale = math.sqrt(safeMaxPixels / (width * height));
    return math.max(1, (longest * scale).floor());
  }
}
