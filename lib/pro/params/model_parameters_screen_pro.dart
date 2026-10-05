// LM-MINI-PRO-STUB
part of '../../screens/model_parameters_screen.dart';

/// Public-build stub: per-model parameter presets are part of LM Mini Pro,
/// so the screen shows only the Global form (no Model tab, badge or footer).
extension _ProModelPresetTab on _ModelParametersScreenState {
  Widget? _proModelSegmentBadge(BuildContext context, bool isPremium) => null;

  Widget _proModelLockedBody(BuildContext context, Widget tabBar) =>
      const SizedBox.shrink();

  Widget? _proModelFooter(
    BuildContext context, {
    required bool showModelTab,
    required bool hasModel,
    required String? presetKey,
    required ParamPreset? modelPreset,
    required SettingsProvider settingsProvider,
  }) =>
      null;

  void _proOpenPaywall() {}
}
