import 'package:flutter/material.dart';
import '../utils/bundled_google_fonts.dart';

class ChatFontHelper {
  static const List<String> supportedFonts = [
    'Inter',
    'Manrope',
    'IBM Plex Sans',
    'Space Grotesk',
    'Fira Sans',
    'Merriweather',
  ];

  static const String systemDefaultLabel = 'System Default';

  static TextStyle apply(String? fontFamily, TextStyle style) {
    // Prefer the user's chat font; default body text to Inter so names
    // (Poppins) and message text stay visually distinct.
    final family =
        (fontFamily == null || fontFamily.isEmpty) ? 'Inter' : fontFamily;

    return BundledGoogleFonts.styleOrFallback(family, style);
  }
}
