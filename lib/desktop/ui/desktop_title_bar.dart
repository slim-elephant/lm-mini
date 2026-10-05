import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../../l10n/app_localizations.dart';
import '../../pro/pro_features.dart';
import '../../screens/subscription_screen.dart';
import '../../widgets/adaptive_modal.dart';

/// Custom macOS / desktop title bar painted in Flutter.
///
/// Sits under the native traffic lights (transparent title bar +
/// fullSizeContentView). Left inset clears the traffic lights; title is
/// centered; Upgrade sits on the right.
class DesktopTitleBar extends StatelessWidget {
  static const double height = 52;
  static const Color background = Color(0xFF0E1117);

  /// Space reserved so traffic lights don't overlap controls.
  static const double trafficLightInset = 78;

  const DesktopTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? background : theme.colorScheme.surface;
    final titleColor = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final leftInset = Platform.isMacOS ? trafficLightInset : 16.0;

    return Material(
      color: bg,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered app name (IgnorePointer so empty bar still drags the window).
            IgnorePointer(
              child: Text(
                'LM Mini Home',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            // Right: Upgrade (hidden when already Pro, and in public builds).
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: ListenableBuilder(
                listenable: SubscriptionService(),
                builder: (context, _) {
                  if (!ProFeatures.showUpsell) {
                    return const SizedBox.shrink();
                  }
                  return TextButton(
                    onPressed: () {
                      showAdaptiveModal(
                        context: context,
                        builder: (_) => const SubscriptionScreen(),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFB8A9E8)
                          : theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).upgradeToPro,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Traffic lights live in this inset (native overlay).
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: leftInset,
              child: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}
