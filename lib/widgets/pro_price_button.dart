import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../l10n/app_localizations.dart';

/// "Get Pro for $2.50/mo" with "Billed yearly at $29.99" under it: the yearly
/// plan as a monthly price, the lowest number Pro has, in the store's
/// currency. Every upsell dialog uses this so they all quote the same price.
class ProPriceButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double height;
  final double radius;

  const ProPriceButton({
    super.key,
    required this.onPressed,
    this.height = 48,
    this.radius = 14,
  });

  /// Button text for places that only fit a label (dialog actions).
  static String label(AppLocalizations l10n) {
    final perMonth = SubscriptionService().displayAnnualPerMonthPrice;
    return perMonth == null
        ? l10n.paywallGetPro
        : l10n.nudgeGetProPerMonth(perMonth);
  }

  /// "Billed yearly at …", or null when there is no per-month price to explain.
  static String? billedYearly(AppLocalizations l10n) {
    final sub = SubscriptionService();
    return sub.displayAnnualPerMonthPrice == null
        ? null
        : l10n.nudgeBilledYearly(sub.displayAnnualPrice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final sub = SubscriptionService();
    if (!sub.isInitialized) sub.initialize();
    return ListenableBuilder(
      listenable: sub,
      builder: (context, _) {
        final caption = billedYearly(l10n);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              child: FilledButton.icon(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: Text(
                  label(l10n),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
          ],
        );
      },
    );
  }
}
