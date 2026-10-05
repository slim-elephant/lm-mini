import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Reminds lifetime Pro users to cancel their still-active subscription.
class DuplicateSubscriptionDialog extends StatelessWidget {
  const DuplicateSubscriptionDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final sub = SubscriptionService();
    if (!sub.hasBothSubscriptionAndLifetime) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DuplicateSubscriptionDialog(),
    );
  }

  String _storeName(AppLocalizations l10n) {
    if (Platform.isIOS || Platform.isMacOS) return l10n.appStore;
    return l10n.googlePlayStore;
  }

  Future<void> _openManagementUrl(BuildContext context) async {
    final url = SubscriptionService().subscriptionManagementUrl;
    if (url == null || url.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).duplicateSubscriptionNoManageUrl,
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = _storeName(l10n);
    final hasManageUrl = SubscriptionService().subscriptionManagementUrl != null;

    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
      title: Text(l10n.duplicateSubscriptionDialogTitle),
      content: Text(l10n.duplicateSubscriptionDialogBody(store)),
      actions: [
        if (hasManageUrl)
          FilledButton(
            onPressed: () async {
              await _openManagementUrl(context);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.duplicateSubscriptionDialogManage(store)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.duplicateSubscriptionDialogDismiss),
        ),
      ],
    );
  }
}
