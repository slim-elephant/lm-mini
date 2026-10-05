import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Small amber "PRO" chip used next to locked premium controls.
class ProBadge extends StatelessWidget {
  final bool compact;

  const ProBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 5,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.proBadge,
        style: TextStyle(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w700,
          color: Colors.amber[700],
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }
}
