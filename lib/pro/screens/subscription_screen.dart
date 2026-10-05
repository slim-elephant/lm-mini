// LM-MINI-PRO-STUB
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open-source build: informational page in place of the LM Mini Pro paywall.
///
/// Pro features ship only in the official LM Mini app. This page explains that
/// and links to the stores and the public source repository. It sells nothing.
class SubscriptionScreen extends StatelessWidget {
  final bool embedded;
  const SubscriptionScreen({super.key, this.embedded = false});

  static const String _appStoreUrl =
      'https://apps.apple.com/app/lm-mini/id6751125309';
  static const String _macAppStoreUrl =
      'https://apps.apple.com/app/lm-mini/id6751125309?platform=mac';
  static const String _googlePlayUrl =
      'https://play.google.com/store/apps/details?id=net.neuro9.lmmini';
  static const String _sourceUrl = 'https://github.com/slim-elephant/lm-mini';

  static Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // No handler for the link on this platform; nothing else to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('LM Mini Pro')),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final appStoreUrl = Platform.isMacOS ? _macAppStoreUrl : _appStoreUrl;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'LM Mini Pro',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pro features are available in the official LM Mini app. '
                  'This open-source build includes every free feature.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => _open(appStoreUrl),
                  child: const Text('App Store'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _open(_googlePlayUrl),
                  child: const Text('Google Play'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _open(_sourceUrl),
                  child: const Text('Source code on GitHub'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
