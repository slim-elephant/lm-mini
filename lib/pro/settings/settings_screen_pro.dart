// LM-MINI-PRO-STUB
part of '../../screens/settings_screen.dart';

/// Open-source build: no LM Mini Pro section, badges or account decoration.
extension _ProSettings on _SettingsScreenState {
  List<Widget> _proFeaturesSection(BuildContext context) => const <Widget>[];

  Widget _proTitle(String title) => Text(title);

  Widget _proAccountDecoration(
    BuildContext context, {
    required Widget Function(Color? outline) button,
  }) {
    return SizedBox(
      width: HomeGlassHeader.iconSize,
      height: HomeGlassHeader.iconSize,
      child: button(null),
    );
  }
}
