import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/glass_settings_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool embedded;
  const PrivacyPolicyScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return GlassSettingsScaffold(
      embedded: embedded,
      title: l10n.privacyPolicy,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
        children: [
          GlassSettingsCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.privacyPolicy,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: August 30, 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ..._sections(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(ColorScheme cs) {
    const bodyStyle = TextStyle(fontSize: 15.5, height: 1.5);
    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(
            t,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        );
    Widget body(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(t, style: bodyStyle),
        );

    return [
      heading('Overview'),
      body(
        'This screen describes the open-source / community build of LM Mini '
        '(the GitHub tree with the Pro stub). Chats stay on your devices by '
        'default. We do not read your conversations.',
      ),
      heading('What stays on your device'),
      body(
        'Chat history, settings, personas, and server connection details are '
        'stored locally on your phone, tablet, or computer. Uninstalling the '
        'app removes that local data.',
      ),
      heading('How chat works'),
      body(
        'Messages go to the backend you choose: on-device models, or your own '
        'LM Studio / Ollama / similar server on your network. We are not in '
        'the middle of ordinary local chat.',
      ),
      heading('Chat sync with LM Mini Home'),
      body(
        'If you pair with LM Mini Home (Share with phone) and turn on chat '
        'sync, your phone and Mac exchange chats over an encrypted relay so '
        'they can stay in sync. The relay only forwards data in real time. '
        'Chat sync never stays on our servers — we do not store your '
        'conversations on the relay.',
      ),
      heading('Optional iCloud'),
      body(
        'If you enable iCloud sync on Apple devices, Apple stores that data '
        'under your iCloud account according to Apple’s privacy policy. That '
        'is not our relay, and it is off unless you turn it on.',
      ),
      heading('Other network use'),
      body(
        'The app may check lmmini.com for a current version number. If you '
        'configure a search tool (for example SearXNG) or a local image '
        'server, traffic goes to those endpoints you set — not to us.',
      ),
      heading('What we do not do in this build'),
      body(
        'This community build does not connect to LM Mini’s production '
        'Firebase project, does not run our product analytics, and does not '
        'include Pro cloud services. App Store and Google Play builds are '
        'described at lmmini.com/privacy.html.',
      ),
      heading('Contact'),
      const Text(
        'Questions: support@lmmini.com',
        style: bodyStyle,
      ),
    ];
  }
}
