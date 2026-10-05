import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

/// Frosted [BackdropFilter] that no-ops when glass is off or Low battery mode
/// is on (`glassEffectsActive`).
///
/// Overlay menus must swap to [solidFillOf] when glass is off — translucent
/// white fills are unreadable without the blur frosting what's behind them.
/// Circular header buttons keep their translucent fills (icons stay visible).
class GlassBlur extends StatelessWidget {
  const GlassBlur({
    super.key,
    required this.child,
    required this.sigmaX,
    required this.sigmaY,
  });

  final Widget child;
  final double sigmaX;
  final double sigmaY;

  /// Current glass flag. [ReadContext.read] (not [SelectContext.select]) so
  /// overlay menus can call this while their host widget is not in `build`.
  static bool enabledOf(BuildContext context) {
    try {
      return context.read<SettingsProvider>().settings.glassEffectsActive;
    } on ProviderNotFoundException {
      return true;
    }
  }

  /// Elevated opaque fill for menus / dialogs when glass is off.
  static Color solidFillOf(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHigh;

  static Color solidBorderOf(BuildContext context) =>
      Theme.of(context).colorScheme.outline.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    if (!enabledOf(context)) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: child,
    );
  }
}
