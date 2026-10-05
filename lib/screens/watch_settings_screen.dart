import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/watch_bridge.dart';
import '../utils/layout_utils.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';

/// Apple Watch appearance. Changes are pushed to a reachable watch immediately.
class WatchSettingsScreen extends StatelessWidget {
  final bool embedded;

  const WatchSettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final current = settings.settings;
    final theme = Theme.of(context);
    final desktop = prefersWideSettingsLayout(context);

    return GlassSettingsScaffold(
      embedded: embedded,
      title: 'Apple Watch',
      body: DesktopSettingsForm(
        maxWidth: desktop ? 720 : double.infinity,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            desktop ? 0 : 8,
            desktop ? 12 : 8,
            desktop ? 0 : 8,
            36,
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(desktop ? 4 : 16, 8, 16, 12),
              child: Text(
                'These apply on the watch as soon as the iPhone can reach it.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            _switch(
              context,
              desktop: desktop,
              icon: Icons.face_retouching_natural,
              title: 'Show personas',
              subtitle:
                  'The persona row on the watch home screen. Off removes that row completely.',
              value: current.watchShowPersonas,
              onChanged: (value) {
                settings.updateWatchShowPersonas(value);
                WatchBridge.syncWatchPrefs();
              },
            ),
            _switch(
              context,
              desktop: desktop,
              icon: Icons.chat_bubble_outline,
              title: 'Assistant bubbles',
              subtitle:
                  'Assistant replies sit in a bubble. Off lets them run the full width of the watch.',
              value: current.watchAssistantInBubble,
              onChanged: (value) {
                settings.updateWatchAssistantInBubble(value);
                WatchBridge.syncWatchPrefs();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _switch(
    BuildContext context, {
    required bool desktop,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    if (desktop) {
      return DesktopPreferenceRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: Switch(value: value, onChanged: onChanged),
      );
    }
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
