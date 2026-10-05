import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/glass_settings_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  final bool embedded;
  const TermsOfServiceScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return GlassSettingsScaffold(
      embedded: embedded,
      title: l10n.termsOfService,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
        children: [
          GlassSettingsCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.termsOfService,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: June 24, 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _h('Acceptance of Terms'),
                _b(
                  'By downloading, installing, or using LM Mini, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.',
                ),
                _h('Description of Service'),
                _b(
                  'LM Mini is a mobile application that provides an interface to connect with and interact with LM Studio servers running locally or on your network. The app facilitates communication between your device and your LM Studio installation.',
                ),
                _h('User Responsibilities'),
                _b(
                  'You are responsible for:\n\n'
                  '• Setting up and maintaining your LM Studio server\n'
                  '• Ensuring network connectivity between your device and server\n'
                  '• The content of conversations and interactions\n'
                  '• Compliance with applicable laws and regulations\n'
                  '• Proper use of language models and AI systems',
                ),
                _h('Limitations of Service'),
                _b(
                  'LM Mini is provided as-is without warranties of any kind. The app requires:\n\n'
                  '• A compatible LM Studio installation\n'
                  '• Network connectivity\n'
                  '• Compatible language models\n\n'
                  'We do not guarantee availability, performance, or compatibility with all systems.',
                ),
                _h('Subscriptions and LM Mini Pro'),
                _b(
                  'LM Mini offers optional LM Mini Pro features through auto-renewing subscriptions (monthly or yearly) or a one-time lifetime purchase, billed through Apple\'s App Store or Google Play. Subscriptions renew automatically until cancelled in your device\'s store settings. Lifetime is a single, non-recurring charge.',
                ),
                _h('LM Mini Pro — Lifetime Access'),
                _b(
                  'A lifetime purchase grants you a personal, non-transferable license to use LM Mini Pro features on your Apple ID or Google account for as long as we commercially offer and maintain the LM Mini app on supported platforms.\n\n'
                  'Lifetime access means:\n\n'
                  '• Pro features included in the app at the time of purchase, plus reasonable app updates we release for supported devices\n'
                  '• The same LM Mini Pro entitlement as an active subscriber, except where a feature explicitly requires a separate paid service\n\n'
                  'Lifetime access does not mean:\n\n'
                  '• That LM Mini, Neuro9, or any third party will operate forever\n'
                  '• Unlimited hosted infrastructure (for example Pro Search relay, cloud backup servers, or other services we pay to run). We may change, limit, or discontinue hosted features with reasonable notice\n'
                  '• Coverage of third-party costs (cloud AI API keys, LM Studio, Hugging Face, or other providers you connect)\n'
                  '• A refund if you stop using the app, if you change devices outside store restore rules, or if you disagree with future app changes — except where applicable law requires a refund\n\n'
                  'If we discontinue LM Mini: we will use reasonable efforts to provide advance notice (typically at least 90 days when practicable), keep restore/re-download available for a reasonable period as allowed by Apple and Google, and not charge lifetime customers again. We are not obligated to continue operating hosted services, app store listings, or online features after discontinuation. Where law requires, your remedies are limited to those mandated by applicable consumer protection rules.\n\n'
                  'Lifetime purchases are generally non-refundable through us; refund requests must be directed to Apple or Google under their policies.',
                ),
                _h('Privacy and Data'),
                _b(
                  'All data remains on your device and your LM Studio server. We do not collect, store, or transmit any personal data. Please refer to our Privacy Policy for detailed information.',
                ),
                _h('Intellectual Property'),
                _b(
                  'The LM Mini app and its original content are protected by copyright and other intellectual property laws. LM Studio is a separate product with its own terms and licensing.',
                ),
                _h('Limitation of Liability'),
                _b(
                  'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues.',
                ),
                _h('Termination'),
                _b(
                  'You may stop using the app at any time by uninstalling it from your device. These terms remain in effect until terminated.',
                ),
                _h('Changes to Terms'),
                _b(
                  'We may update these terms from time to time. Changes will be communicated through app updates. Continued use constitutes acceptance of updated terms.',
                ),
                _h('Contact Information'),
                const Text(
                  'For questions about these terms, please contact us through the App Store.',
                  style: TextStyle(fontSize: 15.5, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          t,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      );

  static Widget _b(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(t, style: const TextStyle(fontSize: 15.5, height: 1.5)),
      );
}
