import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/about_user_prompt.dart';
import '../utils/layout_utils.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';

/// Settings → About you: the user's name and a short description, sent with
/// every chat (see [aboutUserPromptBlock]). Free for everyone.
class AboutYouScreen extends StatefulWidget {
  final bool embedded;

  const AboutYouScreen({super.key, this.embedded = false});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  late final TextEditingController _name;
  late final TextEditingController _about;
  late final SettingsProvider _settings;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsProvider>();
    _name = TextEditingController(
        text: _settings.settings.preferredUserName ?? '');
    _about = TextEditingController(text: _settings.settings.aboutUser ?? '');
  }

  /// Saves shortly after typing stops, so each keystroke is not a write.
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  void _save() {
    _saveTimer?.cancel();
    final s = _settings.settings;
    if (_name.text.trim() != (s.preferredUserName ?? '')) {
      _settings.updatePreferredUserName(_name.text);
    }
    if (_about.text.trim() != (s.aboutUser ?? '')) {
      _settings.updateAboutUser(_about.text);
    }
  }

  @override
  void dispose() {
    _save();
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final desktop = prefersWideSettingsLayout(context);

    return GlassSettingsScaffold(
      embedded: widget.embedded,
      title: l10n.aboutYouTitle,
      body: DesktopSettingsForm(
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
              l10n.aboutYouIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            GlassSettingsCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 60,
                    onChanged: (_) => _scheduleSave(),
                    decoration: InputDecoration(
                      labelText: l10n.aboutYouNameLabel,
                      hintText: l10n.aboutYouNameHint,
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _about,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 5,
                    maxLines: 12,
                    maxLength: kAboutUserMaxLength,
                    onChanged: (_) => _scheduleSave(),
                    decoration: InputDecoration(
                      labelText: l10n.aboutYouAboutLabel,
                      hintText: l10n.aboutYouAboutHint,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
