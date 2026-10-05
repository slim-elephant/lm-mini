import 'dart:io';

import 'package:flutter/material.dart';
// Used by the Pro part only; unused with the open-source stub part.
// ignore: unused_import
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../pro/pro_features.dart';
// ignore: unused_import
import '../services/news_widget_service.dart';
import '../services/widget_data_service.dart';
import '../utils/layout_utils.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';

// News widget (AI briefing) settings: LM Mini Pro, stubbed in the public export.
part '../pro/news/widget_settings_news.dart';

class WidgetSettingsScreen extends StatefulWidget {
  final bool embedded;
  const WidgetSettingsScreen({super.key, this.embedded = false});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _newsPromptController = TextEditingController();
  bool _isLoading = true;
  // News widget state, used by the Pro part only (unused with the stub part).
  // ignore: unused_field, prefer_final_fields
  bool _refreshingNews = false;
  // ignore: unused_field
  Map<String, dynamic>? _lastNews;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ignore: unused_element
  void _setStateFromPart(VoidCallback fn) => setState(fn);

  Future<void> _loadAll() async {
    final prompt = await WidgetDataService.getAutomatedPrompt();
    await _proLoadNews();
    if (prompt != null) _promptController.text = prompt;
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrompt() async {
    await WidgetDataService.saveAutomatedPrompt(_promptController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Widget config saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GlassSettingsScaffold(
      embedded: widget.embedded,
      title: 'Widgets',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
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
                        'Configure home-screen widgets. They update when you use the app.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (Platform.isAndroid) ...[
                        const SizedBox(height: 18),
                        _sectionLabel(context, 'Available widgets'),
                        const SizedBox(height: 10),
                        _buildAndroidWidgetCatalog(colorScheme),
                      ],
                      const SizedBox(height: 22),
                      _sectionLabel(context, 'Background prompt'),
                      const SizedBox(height: 10),
                      GlassSettingsCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Runs every few hours in the background. The result shows on the main LM Mini widget.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _promptController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Background Prompt',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                hintText:
                                    'e.g. "What is a cool history fact for today?"',
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _savePrompt,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Save'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._proNewsSection(context),
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

  Widget _buildAndroidWidgetCatalog(ColorScheme colorScheme) {
    const widgets = [
      (Icons.bar_chart_rounded, 'LM Mini', 'Usage stats and quick new chat'),
      if (ProFeatures.included)
        (
          Icons.newspaper_rounded,
          'LM News (Pro)',
          'AI briefing from your prompt'
        ),
      (Icons.person_rounded, 'Personas', 'Start a chat with a saved persona'),
      (Icons.folder_rounded, 'Top Folders', 'Jump into your busiest folders'),
      (Icons.history_rounded, 'Recent Chats', 'Resume latest conversations'),
    ];
    final desktop = useDesktopSettingsControls(context);
    return GlassSettingsCard(
      child: Column(
        children: [
          for (var i = 0; i < widgets.length; i++) ...[
            if (i > 0)
              desktop
                  ? const SizedBox(height: 2)
                  : Divider(
                      height: 1,
                      indent: 66,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
            DesktopPreferenceRow(
              icon: widgets[i].$1,
              title: widgets[i].$2,
              subtitle: widgets[i].$3,
              trailing: const SizedBox.shrink(),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              'Long-press your home screen → Widgets → LM Mini.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _newsPromptController.dispose();
    super.dispose();
  }
}
