import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/appearance_settings_screen.dart';
import 'glass_blur.dart';

Future<void> showFullWidthNudgeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _FullWidthNudgeDialog(),
  );
}

class _FullWidthNudgeDialog extends StatelessWidget {
  const _FullWidthNudgeDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final glassOn = GlassBlur.enabledOf(context);
    final fill = glassOn
        ? cs.surface.withValues(alpha: isDark ? 0.92 : 0.96)
        : GlassBlur.solidFillOf(context);
    final border = glassOn
        ? cs.outline.withValues(alpha: 0.14)
        : GlassBlur.solidBorderOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassBlur(
          sigmaX: 28,
          sigmaY: 28,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.tryFullWidthTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tryFullWidthBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.tryFullWidthNotNow),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppearanceSettingsScreen(
                              highlightFullWidth: true,
                            ),
                          ),
                        );
                      },
                      child: Text(l10n.tryFullWidthOpenAppearance),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
