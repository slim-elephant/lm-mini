import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pro/pro_features.dart';
import '../utils/layout_utils.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';

/// Phase C of the Shortcuts integration — a one-stop Settings page that:
///
///   1. Explains App Intents the user can drag into Shortcuts.
///   2. Lists ready-to-tap sample shortcuts hosted on lmmini.com.
///   3. Documents the `lmmini://shortcut/...` URL scheme so power users
///      can build their own Shortcuts using the "Open URLs" action.
///
/// iOS only — App Intents and Shortcuts.app are not available on Android.
class SiriShortcutsScreen extends StatelessWidget {
  final bool embedded;
  const SiriShortcutsScreen({super.key, this.embedded = false});

  static const _samples = <_Sample>[
    _Sample(
      title: 'Search with LM Mini',
      subtitle:
          'Siri dictation → web search → spoken answer via your provider.',
      icon: Icons.travel_explore,
      url: 'https://lmmini.com/shortcuts/search-web.html',
    ),
    _Sample(
      title: 'Voice chat with LM Mini',
      subtitle: 'Opens hands-free voice mode — mic ready, AI speaks back.',
      icon: Icons.mic,
      url: 'https://lmmini.com/shortcuts/voice-chat.html',
    ),
    _Sample(
      title: 'Ask LM Mini (on-device)',
      subtitle: 'Voice → local model → spoken answer. Action Button friendly.',
      icon: Icons.mic_none,
      url: 'https://lmmini.com/shortcuts/ask-on-device.html',
    ),
    _Sample(
      title: 'Summarize Safari article',
      subtitle: 'Share Sheet from Safari → 3 bullet summary.',
      icon: Icons.text_snippet,
      url: 'https://lmmini.com/shortcuts/summarize-safari.html',
    ),
    _Sample(
      title: 'Translate clipboard',
      subtitle: 'Lock-screen widget tap → translate + replace clipboard.',
      icon: Icons.translate,
      url: 'https://lmmini.com/shortcuts/translate-clipboard.html',
    ),
  ];

  /// News brief sample: the News widget ships only in the official app.
  static const _newsSample = _Sample(
    title: 'Morning news brief',
    subtitle: 'Daily 7AM automation → spoken news brief in your TTS voice.',
    icon: Icons.newspaper,
    url: 'https://lmmini.com/shortcuts/morning-news.html',
  );

  static List<_Sample> get _visibleSamples => [
        ..._samples,
        if (ProFeatures.included) _newsSample,
      ];

  static const _urlSchemes = <_UrlScheme>[
    _UrlScheme(
      method: '/voice',
      template: 'lmmini://shortcut/voice?onDevice=0&prompt=YOUR_PROMPT',
      blurb: 'Open voice chat. `persona=` and `conversationId=` optional.',
    ),
    _UrlScheme(
      method: '/ask',
      template: 'lmmini://shortcut/ask?prompt=YOUR_PROMPT&onDevice=1&speak=1',
      blurb:
          'One-shot prompt. `onDevice=1` forces local. `speak=1` reads aloud.',
    ),
    _UrlScheme(
      method: '/summarize',
      template: 'lmmini://shortcut/summarize?text=TEXT&style=bullets',
      blurb: 'style: bullets | paragraph | tweet',
    ),
    _UrlScheme(
      method: '/translate',
      template: 'lmmini://shortcut/translate?text=TEXT&to=Spanish',
      blurb: 'Free-form target language.',
    ),
  ];

  static List<_UrlScheme> get _visibleUrlSchemes => [
        const _UrlScheme(
          method: '/search',
          template: 'lmmini://shortcut/search?query=YOUR_QUERY&speak=1',
          blurb: ProFeatures.included
              ? 'Web search via Pro Search or SearXNG. `speak=1` reads aloud (default).'
              : 'Web search via SearXNG and a tool-capable model. `speak=1` reads aloud (default).',
        ),
        ..._urlSchemes,
        if (ProFeatures.included)
          const _UrlScheme(
            method: '/news',
            template: 'lmmini://shortcut/news?topics=ai,science',
            blurb: 'Refreshes the News widget (Pro).',
          ),
      ];

  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final samples = _visibleSamples;

    return GlassSettingsScaffold(
      embedded: embedded,
      title: 'Siri & Shortcuts',
      body: Builder(
        builder: (context) {
          final desktop = prefersWideSettingsLayout(context);
          return DesktopSettingsForm(
            maxWidth: desktop ? 720 : double.infinity,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                desktop ? 0 : 16,
                desktop ? 12 : 20,
                desktop ? 0 : 16,
                36,
              ),
              children: [
                Text(
                  'Use Siri and Shortcuts.app with LM Mini — voice search, chat, and automations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _sectionLabel(context, 'Voice commands'),
                const SizedBox(height: 10),
                GlassSettingsCard(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Say “Hey Siri, ask LM Mini”. Siri asks what to send, then speaks '
                    'the model’s answer. LM Studio on the LAN or a cloud API can reply '
                    'without opening the app. On-device models open Mini briefly; Siri '
                    'still reads the reply.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ),
                const SizedBox(height: 12),
                _SearchShortcutGuide(
                  onOpenGuide: () => _openExternal(
                    context,
                    'https://lmmini.com/shortcuts/search-web.html',
                  ),
                  onOpenDocs: () => _openExternal(
                    context,
                    'https://lmmini.com/docs.html#siri-search',
                  ),
                  onCopyUrl: () => _copy(
                    context,
                    'lmmini://shortcut/search?query=YOUR_QUERY&speak=1',
                  ),
                ),
                const SizedBox(height: 22),
                _sectionLabel(context, 'Sample Shortcuts'),
                const SizedBox(height: 10),
                GlassSettingsCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < samples.length; i++) ...[
                        if (i > 0)
                          useDesktopSettingsControls(context)
                              ? const SizedBox(height: 2)
                              : Divider(
                                  height: 1,
                                  indent: 66,
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.45),
                                ),
                        DesktopPreferenceRow(
                          icon: samples[i].icon,
                          title: samples[i].title,
                          subtitle: samples[i].subtitle,
                          trailing: Icon(Icons.open_in_new_rounded,
                              size: 18, color: cs.onSurfaceVariant),
                          onTap: () => _openExternal(context, samples[i].url),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _sectionLabel(context, 'Build your own'),
                const SizedBox(height: 10),
                GlassSettingsCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Shortcuts.app → "+" → search "LM Mini" — drag any of '
                        'these actions into your Shortcut:',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      const _IntentChip('Ask LM Mini', Icons.bubble_chart),
                      const _IntentChip('Start Voice Chat', Icons.mic),
                      const _IntentChip(
                          'Search with LM Mini', Icons.travel_explore),
                      const _IntentChip(
                          'Summarize with LM Mini', Icons.text_fields),
                      const _IntentChip(
                          'Translate with LM Mini', Icons.translate),
                      if (ProFeatures.included)
                        const _IntentChip('Generate News Brief', Icons.feed),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _sectionLabel(context, 'URL scheme'),
                const SizedBox(height: 10),
                GlassSettingsCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'In any Shortcut, add an "Open URLs" action with one of these '
                        'templates. The result is copied to the clipboard so the next '
                        'step can use "Get Clipboard".',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      for (final u in _visibleUrlSchemes) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    u.method,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Copy template',
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 18),
                                    onPressed: () => _copy(context, u.template),
                                  ),
                                ],
                              ),
                              SelectableText(
                                u.template,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                u.blurb,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () => _openExternal(
                    context,
                    'https://lmmini.com/docs.html#apple-shortcuts',
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Full Shortcuts documentation'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openExternal(context, 'shortcuts://'),
                  icon: const Icon(Icons.launch_rounded),
                  label: const Text('Open Shortcuts app'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
    );
  }
}

class _Sample {
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  const _Sample({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
  });
}

class _UrlScheme {
  final String method;
  final String template;
  final String blurb;
  const _UrlScheme({
    required this.method,
    required this.template,
    required this.blurb,
  });
}

class _IntentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _IntentChip(this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Featured walkthrough for the Search with LM Mini Siri shortcut.
class _SearchShortcutGuide extends StatelessWidget {
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenDocs;
  final VoidCallback onCopyUrl;

  const _SearchShortcutGuide({
    required this.onOpenGuide,
    required this.onOpenDocs,
    required this.onCopyUrl,
  });

  static const _steps = [
    'Open Shortcuts.app → tap +.',
    'Add Dictate Text, then Search with LM Mini.',
    'Set Query to the dictated text. Leave Speak answer aloud on.',
    'Name it “Search with LM Mini” and run once.',
    'Say: “Hey Siri, search with LM Mini”.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GlassSettingsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlassSettingsIcon(Icons.travel_explore),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search the web by voice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ask Siri to search something — LM Mini uses your active '
            'provider (LM Studio, cloud, etc.), runs a real web search '
            '(${ProFeatures.included ? 'Pro Search or SearXNG' : 'SearXNG'}), '
            'then reads the answer with your TTS voice.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Text(
            'Before you start',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ProFeatures.included
                ? '• Pro: enable Web Search under Settings → Tools\n'
                    '• Local: configure SearXNG + a tool-capable model\n'
                    '• Cloud (Pro): pick your provider in Settings → Server'
                : '• Configure SearXNG under Settings → Tools → Web Search\n'
                    '• Use a tool-capable model\n'
                    '• Pick your provider in Settings → Server',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Build in Shortcuts.app',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ..._steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: Text(step, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'lmmini://shortcut/search?query=YOUR_QUERY&speak=1',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: onOpenGuide,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Step-by-step guide'),
              ),
              TextButton.icon(
                onPressed: onOpenDocs,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Web docs'),
              ),
              TextButton.icon(
                onPressed: onCopyUrl,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy URL'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
