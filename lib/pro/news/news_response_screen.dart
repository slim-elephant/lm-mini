// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/widget_data_service.dart';

/// Public-build stub of the News widget briefing screen.
///
/// The News widget is part of LM Mini Pro. This screen only shows a briefing
/// that is already stored on the device (if any) and otherwise explains where
/// the feature lives. It offers no refresh.
class NewsResponseScreen extends StatefulWidget {
  const NewsResponseScreen({super.key});

  @override
  State<NewsResponseScreen> createState() => _NewsResponseScreenState();
}

class _NewsResponseScreenState extends State<NewsResponseScreen> {
  Map<String, dynamic>? _news;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final news = await WidgetDataService.getNewsContent();
    if (!mounted) return;
    setState(() {
      _news = news;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = (_news?['title'] as String?)?.trim() ?? '';
    final body = (_news?['body'] as String?)?.trim() ?? '';
    final hasContent = title.isNotEmpty || body.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newsBriefing)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (!hasContent)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.newspaper_outlined,
                            size: 64, color: colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text(
                          'The News widget is available in the official LM Mini app.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (title.isNotEmpty) const SizedBox(height: 16),
                  SelectableText(
                    body,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ],
              ],
            ),
    );
  }
}
