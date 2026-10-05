import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Families shipped in `google_fonts/` so the UI never hits fonts.gstatic.com.
abstract final class BundledGoogleFonts {
  static const families = <String>[
    'Inter',
    'Poppins',
    'Sora',
    'Manrope',
    'IBM Plex Sans',
    'Space Grotesk',
    'Fira Sans',
    'Merriweather',
  ];

  static bool contains(String? family) =>
      family != null && family.isNotEmpty && families.contains(family);

  /// Call once at startup, before any [GoogleFonts] TextStyle is built.
  static void disableRuntimeFetching() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  static TextTheme? textThemeOrNull(String? family) {
    if (!contains(family)) return null;
    try {
      return GoogleFonts.getTextTheme(family!);
    } catch (_) {
      return null;
    }
  }

  static TextStyle styleOrFallback(String family, TextStyle style) {
    if (!contains(family)) return style;
    try {
      return GoogleFonts.getFont(family, textStyle: style);
    } catch (_) {
      return style;
    }
  }
}
