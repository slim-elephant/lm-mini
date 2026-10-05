// LM-MINI-PRO-STUB
part of '../../screens/system_prompts_screen.dart';

/// Public-build stub: persona memory sharing / write scope, the image seed,
/// per-persona model parameters and ElevenLabs / Grok persona voices are
/// part of LM Mini Pro, so the editor shows none of them. Stored values are
/// still kept when a persona is edited and saved.
extension _ProPersonaEditor on _SystemPromptEditorScreenState {
  List<Widget> _proPersonaMemorySection(BuildContext context) =>
      const <Widget>[];

  List<Widget> _proImageSeedSection(BuildContext context) => const <Widget>[];

  Widget _proCustomParamsTile(BuildContext context) => const SizedBox.shrink();

  List<Widget> _proCloudVoiceProviderChoices(
    BuildContext sheetContext,
    Widget Function({
      required String? id,
      required IconData icon,
      required String title,
      required bool enabled,
      String? disabledSubtitle,
    }) option,
    AppLocalizations l10n,
    bool elevenLabsReady,
    bool grokReady,
  ) =>
      const <Widget>[];

  List<Widget> _proCloudVoiceRows(BuildContext context) => const <Widget>[];
}
