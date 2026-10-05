// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/glass_settings_scaffold.dart';

/// Informational placeholder; App Lock ships in the official LM Mini app.
class AppLockSettingsScreen extends StatelessWidget {
  final bool embedded;

  const AppLockSettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassSettingsScaffold(
      embedded: embedded,
      title: l10n.appLock,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'App Lock is available in the official LM Mini app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
