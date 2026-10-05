// LM-MINI-PRO-STUB
part of '../../screens/voice_settings_screen.dart';

/// Public-build stub: ElevenLabs / Grok cloud TTS settings are part of
/// LM Mini Pro, so the picker offers only the free engines (System,
/// Downloaded voice, PC voice) and no cloud rows or voice test exist.
extension _ProCloudTts on _VoiceSettingsScreenState {
  Future<void> _proCheckCloudTts(String provider) async {}

  void _proCloudTtsSetSpeed(double value) {}

  List<Widget> _proCloudTtsProviderOptions(
    BuildContext context,
    SettingsProvider settingsProvider,
    AppLocalizations l10n,
    String current,
  ) =>
      const <Widget>[];

  List<Widget> _proCloudTtsSettingsRows(
    BuildContext context,
    AppSettings settings,
    SettingsProvider settingsProvider,
    AppLocalizations l10n,
  ) =>
      const <Widget>[];

  Future<bool?> _proCloudTtsTestVoice(
    AppSettings settings,
    String phrase,
  ) async =>
      null;
}
