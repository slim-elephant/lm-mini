import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../pro/pro_features.dart';
import '../providers/chat_provider.dart';
import '../screens/subscription_screen.dart';

/// Group Chat is configurable for everyone; sending requires Pro.
///
/// In the open-source build (`!ProFeatures.included`) the dialog is purely
/// informational and never opens the subscription screen.
class GroupChatProGate {
  GroupChatProGate._();

  static bool isLocked(ChatProvider chatProvider) =>
      chatProvider.isGroupChat && !ProFeatures.isPro;

  static Future<void> showUpgradeDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (!ProFeatures.included) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.group_rounded),
          title: Text(l10n.groupChatProRequiredTitle),
          content: const Text(
              'Group chat replies are available in the official LM Mini app.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
      );
      return;
    }
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.group_rounded),
        title: Text(l10n.groupChatProRequiredTitle),
        content: Text(l10n.groupChatProRequiredBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.groupChatProRequiredUpgrade),
          ),
        ],
      ),
    );

    if (upgrade == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    }
  }
}
