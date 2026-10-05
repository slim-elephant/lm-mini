import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/image_picker_helper.dart';

/// Circular persona avatar with optional face focus + zoom for bubbles.
class PersonaAvatar extends StatelessWidget {
  final String? imagePath;
  final double radius;
  final Color? backgroundColor;
  final Alignment alignment;
  /// 1.0 = default cover crop; higher zooms into the face.
  final double scale;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;

  const PersonaAvatar({
    super.key,
    this.imagePath,
    required this.radius,
    this.backgroundColor,
    this.alignment = const Alignment(0, -0.28),
    this.scale = 1.0,
    this.fallbackIcon = Icons.smart_toy,
    this.fallbackIconColor,
  });

  static Alignment alignmentFromFocus(double? x, double? y) {
    if (x == null && y == null) return const Alignment(0, -0.28);
    return Alignment(
      (x ?? 0).clamp(-1.0, 1.0),
      (y ?? -0.28).clamp(-1.0, 1.0),
    );
  }

  static double scaleFromFocus(double? scale, {double fallback = 1.0}) {
    if (scale == null || scale <= 0) return fallback;
    return scale.clamp(1.0, 3.5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved =
        imagePath != null ? ImagePickerHelper.resolveImagePathSync(imagePath!) : null;
    final fileOk = resolved != null && File(resolved).existsSync();
    final bg = backgroundColor ?? theme.colorScheme.secondary;
    final iconColor = fallbackIconColor ?? theme.colorScheme.onSecondary;
    final size = radius * 2;
    final safeScale = scale.clamp(1.0, 3.5);

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: fileOk
            ? Transform.scale(
                key: ValueKey(
                  '$resolved|${alignment.x}|${alignment.y}|$safeScale',
                ),
                scale: safeScale,
                alignment: alignment,
                child: Image.file(
                  File(resolved),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  alignment: alignment,
                  gaplessPlayback: false,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: bg,
                    child: Icon(
                      fallbackIcon,
                      size: radius * 0.6,
                      color: iconColor,
                    ),
                  ),
                ),
              )
            : ColoredBox(
                color: bg,
                child: Icon(fallbackIcon, size: radius * 0.6, color: iconColor),
              ),
      ),
    );
  }
}
