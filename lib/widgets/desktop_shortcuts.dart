import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] with [CallbackShortcuts] on desktop platforms.
///
/// Does not steal keyboard focus from text fields — unlike a [Focus] with
/// [autofocus], [CallbackShortcuts] only handles its bindings when no editable
/// has primary focus.
class DesktopShortcuts extends StatelessWidget {
  final Widget child;
  final Map<ShortcutActivator, VoidCallback> bindings;

  const DesktopShortcuts({
    super.key,
    required this.child,
    required this.bindings,
  });

  static bool get isEnabled =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled || bindings.isEmpty) return child;
    return CallbackShortcuts(
      bindings: bindings,
      child: child,
    );
  }
}

/// Meta key on macOS, Control on Windows/Linux.
LogicalKeySet desktopMeta(LogicalKeyboardKey key) {
  if (Platform.isMacOS) {
    return LogicalKeySet(LogicalKeyboardKey.meta, key);
  }
  return LogicalKeySet(LogicalKeyboardKey.control, key);
}

LogicalKeySet desktopMetaShift(LogicalKeyboardKey key) {
  if (Platform.isMacOS) {
    return LogicalKeySet(
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.shift,
      key,
    );
  }
  return LogicalKeySet(
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.shift,
    key,
  );
}
