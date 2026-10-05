import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Pre-prompt shown on Android before opening Play In-App Review or the store.
/// Google Play's in-app review API often returns unavailable or shows nothing;
/// this dialog guarantees the user sees a rating prompt.
class ReviewPromptDialog extends StatelessWidget {
  const ReviewPromptDialog({super.key});

  /// Returns `true` if the user tapped Rate, `false` if dismissed.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ReviewPromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.star_rate_rounded, color: Colors.amber.shade600, size: 36),
      title: Text(l10n.reviewPromptTitle, textAlign: TextAlign.center),
      content: Text(
        l10n.reviewPromptMessage,
        textAlign: TextAlign.center,
        style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.reviewPromptLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.reviewPromptRate),
        ),
      ],
    );
  }
}
