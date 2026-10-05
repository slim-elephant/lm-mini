import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Two accent colors sampled from an avatar image for glass UI washes.
///
/// Prefers vivid background hues (greens, blues, etc.) over skin / shirt
/// neutrals that usually dominate selfie center mass.
class AvatarPalette {
  final Color primary;
  final Color secondary;

  const AvatarPalette({
    required this.primary,
    required this.secondary,
  });

  static const AvatarPalette fallback = AvatarPalette(
    primary: Color(0xFF5CE1FF),
    secondary: Color(0xFF2B6CFF),
  );

  /// Extract two UI-friendly colors from [path].
  static Future<AvatarPalette> fromFile(
    String path, {
    Color? fallbackPrimary,
    Color? fallbackSecondary,
  }) async {
    final defaults = AvatarPalette(
      primary: fallbackPrimary ?? AvatarPalette.fallback.primary,
      secondary: fallbackSecondary ?? AvatarPalette.fallback.secondary,
    );
    try {
      final file = File(path);
      if (!await file.exists()) return defaults;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return defaults;

      // Keep enough resolution to separate face vs edge foliage.
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 96,
        targetHeight: 96,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final w = image.width;
      final h = image.height;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (data == null || w <= 0 || h <= 0) return defaults;

      final scores = <int, double>{};

      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final i = (y * w + x) * 4;
          final a = data.getUint8(i + 3);
          if (a < 200) continue;
          final r = data.getUint8(i);
          final g = data.getUint8(i + 1);
          final b = data.getUint8(i + 2);

          final maxC = math.max(r, math.max(g, b));
          final minC = math.min(r, math.min(g, b));
          if (maxC < 24 || minC > 235) continue;
          final chroma = maxC - minC;
          if (chroma < 22) continue; // gray / asphalt / black shirt

          final hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
          if (_isLikelySkin(hsl)) continue;

          // Bias toward frame edges (background plants / walls / sky).
          final nx = (x + 0.5) / w;
          final ny = (y + 0.5) / h;
          final edge =
              math.max((nx - 0.5).abs(), (ny - 0.5).abs()) * 2; // 0 center → 1 edge
          final edgeWeight = 0.35 + edge * 1.65;

          // Prefer cooler / greener / bluer accents for glass UI.
          final coolBoost = _coolAccentBoost(hsl);

          // Saturation & mid lightness read better as frosted tints.
          final sat = hsl.saturation;
          final lit = hsl.lightness;
          final satBoost = 0.4 + sat * 1.8;
          final litBoost = 1.0 - ((lit - 0.45).abs() * 1.2).clamp(0.0, 0.85);

          final weight = edgeWeight * coolBoost * satBoost * litBoost;

          final key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
          scores[key] = (scores[key] ?? 0) + weight;
        }
      }

      if (scores.isEmpty) {
        // Last resort: allow muted non-skin samples with weaker filter.
        return _fallbackFromLooseSample(data, w, h, defaults);
      }

      final sorted = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      Color expand(int key) {
        final r = ((key >> 10) & 0x1F) << 3;
        final g = ((key >> 5) & 0x1F) << 3;
        final b = (key & 0x1F) << 3;
        return _liftForGlass(Color.fromARGB(255, r, g, b));
      }

      final c1 = expand(sorted.first.key);
      Color c2 = defaults.secondary;
      for (var i = 1; i < sorted.length; i++) {
        final candidate = expand(sorted[i].key);
        if (_colorDistance(c1, candidate) > 48) {
          c2 = candidate;
          break;
        }
      }
      if (_colorDistance(c1, c2) <= 48) {
        // Pair with a complementary cool accent so glass isn't monochrome.
        c2 = _complementCool(c1);
      }

      return AvatarPalette(primary: c1, secondary: c2);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AvatarPalette.fromFile failed: $e\n$st');
      }
      return defaults;
    }
  }

  static AvatarPalette _fallbackFromLooseSample(
    ByteData data,
    int w,
    int h,
    AvatarPalette defaults,
  ) {
    final scores = <int, double>{};
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        if (data.getUint8(i + 3) < 200) continue;
        final r = data.getUint8(i);
        final g = data.getUint8(i + 1);
        final b = data.getUint8(i + 2);
        final hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
        if (_isLikelySkin(hsl)) continue;
        final nx = (x + 0.5) / w;
        final ny = (y + 0.5) / h;
        final edge = math.max((nx - 0.5).abs(), (ny - 0.5).abs()) * 2;
        final key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
        scores[key] = (scores[key] ?? 0) + (0.5 + edge);
      }
    }
    if (scores.isEmpty) return defaults;
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    Color expand(int key) {
      final r = ((key >> 10) & 0x1F) << 3;
      final g = ((key >> 5) & 0x1F) << 3;
      final b = (key & 0x1F) << 3;
      return _liftForGlass(Color.fromARGB(255, r, g, b));
    }

    final c1 = expand(sorted.first.key);
    final c2 = sorted.length > 1
        ? expand(sorted[1].key)
        : _complementCool(c1);
    return AvatarPalette(primary: c1, secondary: c2);
  }

  /// Skin / beige / warm flesh tones that muddy glass overlays.
  static bool _isLikelySkin(HSLColor hsl) {
    final h = hsl.hue;
    final s = hsl.saturation;
    final l = hsl.lightness;
    // Classic skin cluster (peach → tan → brown).
    final warmHue = h >= 8 && h <= 55;
    if (warmHue && s >= 0.12 && s <= 0.72 && l >= 0.22 && l <= 0.88) {
      return true;
    }
    // Desaturated warm browns / lips / shadows on face.
    if (h >= 5 && h <= 45 && s >= 0.08 && s <= 0.35 && l >= 0.15 && l <= 0.55) {
      return true;
    }
    return false;
  }

  /// Boost greens, cyans, blues; mild for magenta/purple; low for warm leftovers.
  static double _coolAccentBoost(HSLColor hsl) {
    final h = hsl.hue;
    if (h >= 75 && h <= 200) return 2.4; // green → cyan
    if (h > 200 && h <= 265) return 2.1; // blue → indigo
    if (h > 265 && h <= 320) return 1.35; // purple
    if (h >= 55 && h < 75) return 1.15; // yellow-green foliage edge
    return 0.45; // remaining warms (should be rare after skin filter)
  }

  /// Slightly saturate / brighten so glass tints don't go muddy.
  static Color _liftForGlass(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation * 1.15).clamp(0.35, 0.92))
        .withLightness((hsl.lightness * 0.92 + 0.08).clamp(0.28, 0.72))
        .toColor();
  }

  static Color _complementCool(Color c) {
    final hsl = HSLColor.fromColor(c);
    final targetHue = (hsl.hue + 140) % 360;
    // Nudge complement into blue-green family if it lands warm.
    final hue = (targetHue >= 20 && targetHue <= 60) ? 195.0 : targetHue;
    return HSLColor.fromAHSL(1, hue, 0.55, 0.48).toColor();
  }

  static double _colorDistance(Color a, Color b) {
    final dr = (a.r - b.r) * 255.0;
    final dg = (a.g - b.g) * 255.0;
    final db = (a.b - b.b) * 255.0;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }
}
