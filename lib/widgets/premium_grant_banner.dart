import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/premium_grant.dart';
import '../services/promotional_premium_service.dart';

/// Dismissible banner shown on the home screen when the user received free Pro.
class PremiumGrantBanner extends StatelessWidget {
  final PremiumGrant grant;
  final VoidCallback onDismiss;

  const PremiumGrantBanner({
    super.key,
    required this.grant,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reason = grant.reason?.trim();

    return Material(
      color: colorScheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.workspace_premium, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.premiumGrantBannerTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.premiumGrantBannerBody(grant.durationLabel),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.premiumGrantBannerReason(reason),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.dismiss,
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: colorScheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Welcome dialog when the app opens after receiving complimentary Pro.
class PremiumGrantWelcomeDialog {
  static Future<void> show(BuildContext context, PremiumGrant grant) {
    final l10n = AppLocalizations.of(context);
    final reason = grant.reason?.trim();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, size: 40),
        title: Text(l10n.premiumGrantDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.premiumGrantDialogBody(grant.durationLabel)),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.premiumGrantDialogReason(reason),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              await PromotionalPremiumService.instance.markWelcomeDialogShown();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.premiumGrantDialogButton),
          ),
        ],
      ),
    );
  }
}
