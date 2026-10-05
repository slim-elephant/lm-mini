import 'package:flutter/material.dart';
import '../desktop/ui/desktop_shell.dart';
import '../utils/layout_utils.dart';
import 'home_screen.dart';

/// Switches between [DesktopShell] (macOS/iPad wide) and [HomeScreen] (phone).
///
/// Responsive to window resizing — shrink below the threshold and it falls
/// back to phone-style navigation automatically.
class AdaptiveRoot extends StatelessWidget {
  const AdaptiveRoot({super.key});

  @override
  Widget build(BuildContext context) {
    if (prefersDesktopShell(context)) {
      return const DesktopShell();
    }
    return const HomeScreen();
  }
}
