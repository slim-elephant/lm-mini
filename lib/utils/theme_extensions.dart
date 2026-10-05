import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../providers/theme_provider.dart';

/// Extension to easily access the current app theme colors from a BuildContext.
extension AppThemeContext on BuildContext {
  /// Get the current [AppThemeColors] for the active brightness.
  AppThemeColors get appThemeColors {
    final themeProvider = read<ThemeProvider>();
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.light
        ? themeProvider.currentTheme.lightColors
        : themeProvider.currentTheme.darkColors;
  }

  /// Get the current [AppTheme].
  AppTheme get appTheme => read<ThemeProvider>().currentTheme;

  /// Whether the current theme has a background gradient.
  bool get hasBackgroundGradient =>
      appThemeColors.backgroundGradient != null &&
      appThemeColors.backgroundGradient!.isNotEmpty;

  /// Build a decoration for gradient backgrounds (returns null if no gradient).
  BoxDecoration? get themeGradientDecoration {
    final colors = appThemeColors;
    if (colors.backgroundGradient == null ||
        colors.backgroundGradient!.isEmpty) {
      return null;
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.backgroundGradient!,
      ),
    );
  }

  /// Get a custom icon widget for a slot, or fall back to default Icon.
  /// [slot] should be one of: 'home_settings', 'home_search', 'home_folder',
  /// 'home_filter', 'chat_voice', 'chat_settings', 'chat_menu',
  /// 'input_attach', 'input_mic', 'input_send'
  Widget themeIcon(String slot, IconData defaultIcon, {double? size, Color? color}) {
    final icons = appTheme.customIcons;
    if (icons != null && icons.containsKey(slot)) {
      final path = icons[slot]!;
      final file = File(path);
      if (file.existsSync()) {
        final s = size ?? 24;
        return Image.file(
          file,
          width: s,
          height: s,
          color: color,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (_, __, ___) => Icon(defaultIcon, size: size, color: color),
        );
      }
    }
    return Icon(defaultIcon, size: size, color: color);
  }
}
