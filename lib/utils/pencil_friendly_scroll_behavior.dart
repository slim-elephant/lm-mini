import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Default scroll behavior for LM Mini.
///
/// Treats the Apple Pencil (stylus) exactly like a finger: a drag scrolls the
/// list, while a stationary long-press still hands the gesture to text
/// selection (`SelectionArea` / `TextField`), so tap-and-hold to select text
/// and the context menu keep working. This mirrors native iPadOS behavior —
/// the Flutter gesture arena resolves long-press vs. drag the same way it does
/// for touch input.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}
