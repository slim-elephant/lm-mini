import 'package:flutter/material.dart';

import '../models/system_prompt.dart';
import 'avatar_palette.dart';
import 'image_picker_helper.dart';

/// Read / extract / persist glass-frame colors on a [SystemPrompt].
class PersonaPalette {
  static AvatarPalette? cachedOf(SystemPrompt persona) {
    if (persona.palettePrimary == null || persona.paletteSecondary == null) {
      return null;
    }
    return AvatarPalette(
      primary: Color(persona.palettePrimary!),
      secondary: Color(persona.paletteSecondary!),
    );
  }

  static AvatarPalette fallbackFor(SystemPrompt persona, Color accent) {
    return cachedOf(persona) ??
        AvatarPalette(
          primary: accent,
          secondary: Color.lerp(accent, const Color(0xFF2B6CFF), 0.45)!,
        );
  }

  /// Extract from avatar file and return persona with palette fields set.
  /// Clears palette when there is no avatar.
  static Future<SystemPrompt> ensureCached(SystemPrompt persona) async {
    final path = ImagePickerHelper.resolveImagePathSync(persona.avatarPath);
    if (path == null) {
      if (persona.palettePrimary == null && persona.paletteSecondary == null) {
        return persona;
      }
      return persona.copyWith(clearPalette: true);
    }

    final accent = persona.color != null ? Color(persona.color!) : null;
    final extracted = await AvatarPalette.fromFile(
      path,
      fallbackPrimary: accent,
      fallbackSecondary: accent == null
          ? null
          : Color.lerp(accent, const Color(0xFF2B6CFF), 0.45),
    );

    return persona.copyWith(
      palettePrimary: extracted.primary.toARGB32(),
      paletteSecondary: extracted.secondary.toARGB32(),
    );
  }
}
