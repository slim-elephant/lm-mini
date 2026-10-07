import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Small purple "BETA" chip for features still being tested.
class BetaBadge extends StatelessWidget {
  final bool compact;

  const BetaBadge({super.key, this.compact = false});

  static const _purple = Color(0xFF7C4DFF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 5, vertical: 1),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.betaBadge,
        style: TextStyle(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFB39DFF)
              : _purple,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }
}
