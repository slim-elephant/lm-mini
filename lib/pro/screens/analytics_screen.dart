// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Public-build stub: The analytics dashboard is a Pro feature that ships only in the official
/// LM Mini app. Renders an informational placeholder.
class AnalyticsScreen extends StatelessWidget {
  final bool embedded;
  const AnalyticsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    const body = Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Available in the official LM Mini app.',
          textAlign: TextAlign.center,
        ),
      ),
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).analytics)),
      body: body,
    );
  }
}
