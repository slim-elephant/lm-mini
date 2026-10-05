import 'dart:async';

import 'package:flutter/material.dart';

import '../desktop/ui/desktop_title_bar.dart';
import 'glass_blur.dart';

/// Short-lived glass toast pinned near the top of the screen.
///
/// Prefer this over bottom [SnackBar]s that cover the composer.
/// On wide / Mac layouts the toast is centered with a max width so it does
/// not span the full shell (rail + panes).
class GlassToast {
  GlassToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static const double _maxWidth = 380;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color? accent,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    dismiss();

    final mq = MediaQuery.of(context);
    final isWide = mq.size.width >= 700;
    // Sit high under the status bar (phone) or desktop title bar (Mac shell).
    final top = isWide ? DesktopTitleBar.height + 8 : mq.padding.top + 8;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = accent ?? cs.primary;

    _entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) {
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * -10),
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: GlassBlur(
                            sigmaX: 28,
                            sigmaY: 28,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1A1428)
                                              .withValues(alpha: 0.88),
                                          const Color(0xFF120E1C)
                                              .withValues(alpha: 0.82),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.92),
                                          Colors.white.withValues(alpha: 0.82),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: isDark ? 0.22 : 0.7),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          accentColor.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon,
                                        size: 18, color: accentColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.95)
                                                : cs.onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}
