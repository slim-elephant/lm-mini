import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/server_profile.dart';
import '../providers/settings_provider.dart';
import '../services/image_generation_facade.dart';
import '../services/server_profile_service.dart';
import '../utils/url_host.dart';

export '../utils/url_host.dart' show SharedHostPeer;

/// If chat and image-gen used the same LAN host, offer to move the other URL
/// and then test it.
Future<void> maybeOfferSharedHostUpdate(
  BuildContext context, {
  required String previousChangedUrl,
  required String newChangedUrl,
  required String peerUrl,
  required SharedHostPeer peer,
  required String changedName,
  required String peerName,
}) async {
  final change = sharedHostUpdate(
    previousChangedUrl: previousChangedUrl,
    newChangedUrl: newChangedUrl,
    peerUrl: peerUrl,
    peer: peer,
  );
  if (change == null) return;
  if (!context.mounted) return;

  final settings = context.read<SettingsProvider>().settings;
  if (peer == SharedHostPeer.imageGen &&
      settings.imageGenProvider == 'onDevice') {
    return;
  }

  final l10n = AppLocalizations.of(context);
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          peer == SharedHostPeer.imageGen
              ? l10n.sharedHostUpdateImageTitle
              : l10n.sharedHostUpdateChatTitle(peerName),
        ),
        content: Text(
          l10n.sharedHostUpdateBody(
            changedName,
            peerName,
            change.oldHost,
            change.suggestedPeerUrl,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.sharedHostUpdateSkip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.sharedHostUpdateConfirm),
          ),
        ],
      );
    },
  );
  if (go != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) {
      return AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.sharedHostTesting(peerName))),
          ],
        ),
      );
    },
  );

  String? err;
  try {
    final sp = context.read<SettingsProvider>();
    if (peer == SharedHostPeer.imageGen) {
      await sp.updateSettings(
        sp.settings.copyWith(imageGenServerUrl: change.suggestedPeerUrl),
      );
      err = await testBackendConnection(sp.settings).timeout(
        const Duration(seconds: 10),
        onTimeout: () => 'Timed out after 10 seconds',
      );
    } else {
      err = await applyAndTestChatUrl(sp, change.suggestedPeerUrl);
    }
  } catch (e) {
    err = e.toString();
  }

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        icon: Icon(
          err == null
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          size: 48,
          color: err == null
              ? Theme.of(ctx).colorScheme.secondary
              : Theme.of(ctx).colorScheme.error,
        ),
        title: Text(
          err == null
              ? l10n.sharedHostTestSuccessTitle
              : l10n.sharedHostTestFailTitle,
        ),
        content: Text(
          err == null
              ? l10n.sharedHostTestSuccessBody(
                  peerName,
                  change.suggestedPeerUrl,
                )
              : l10n.sharedHostTestFailBody(
                  peerName,
                  change.suggestedPeerUrl,
                  err,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      );
    },
  );
}

String chatBackendDisplayName(SettingsProvider sp) {
  final kind = sp.settings.activeProviderKind;
  if (kind == 'lmStudio') return 'LM Studio';
  final cloud = sp.resolveCloudProvider();
  if (cloud != null) return cloud.type.displayName;
  return 'chat server';
}

Future<String?> applyAndTestChatUrl(SettingsProvider sp, String url) async {
  final profile = ServerProfileService.instance.activeProfile;
  if (profile != null &&
      (profile.kind == ServerProfileKind.lmStudio ||
          profile.kind == ServerProfileKind.cloud)) {
    final ok = await sp.saveAndActivateServerProfile(
      profile.copyWith(baseUrl: url),
    );
    if (!ok) return "Couldn't switch to this server.";
    return sp.connectionError;
  }
  sp.updateServerUrl(url);
  final ok = await sp.testConnection();
  return ok ? null : (sp.connectionError ?? "Couldn't connect.");
}
