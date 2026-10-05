import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'arena_shell_content.dart';
import 'desktop_nav_rail.dart';
import 'desktop_title_bar.dart';
import 'nerds_shell_content.dart';
import 'personas_shell_content.dart';
import '../../screens/home_screen.dart';
import '../../screens/settings_nav.dart';
import '../../screens/settings_screen.dart';
import '../../widgets/desktop_shortcuts.dart';

/// The top-level 3-column desktop shell for macOS and iPad.
///
/// Layout: [custom title bar] / [72px Rail] | [~280px Context] | [Detail]
///
/// On macOS, a Flutter title bar paints under transparent native chrome so
/// traffic lights sit on the left; title is centered; Upgrade is on the right.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  static const Color _shellBg = Color(0xFF0E1117);

  DesktopTab _activeTab = DesktopTab.chats;
  String? _settingsInitialNavId;
  int _settingsNavEpoch = 0;

  @override
  Widget build(BuildContext context) {
    Widget body = DesktopShortcuts(
      bindings: {
        desktopMeta(LogicalKeyboardKey.digit1): () =>
            _switchTab(DesktopTab.chats),
        desktopMeta(LogicalKeyboardKey.digit2): () =>
            _switchTab(DesktopTab.personas),
        desktopMeta(LogicalKeyboardKey.digit3): () =>
            _switchTab(DesktopTab.settings),
        desktopMeta(LogicalKeyboardKey.digit4): () =>
            _switchTab(DesktopTab.arena),
        desktopMeta(LogicalKeyboardKey.digit5): () =>
            _switchTab(DesktopTab.nerds),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DesktopTitleBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DesktopNavRail(
                  activeTab: _activeTab,
                  onTabChanged: _switchTab,
                  onFooterAction: _handleFooterAction,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(_activeTab),
                      child: _buildTabContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Traffic lights overlay the rail; strip top safe-area so panes flush
    // to the window edge (no black gap under the title bar).
    if (Platform.isMacOS) {
      body = MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: body,
      );
    }

    return ColoredBox(color: _shellBg, child: body);
  }

  void _switchTab(DesktopTab tab) {
    if (tab != _activeTab) setState(() => _activeTab = tab);
  }

  void _openSettingsSection(String navId) {
    setState(() {
      _settingsInitialNavId = navId;
      _settingsNavEpoch++;
      _activeTab = DesktopTab.settings;
    });
  }

  void _handleFooterAction(String action) {
    switch (action) {
      case 'account':
        _openSettingsSection(SettingsNavId.account);
        break;
      case 'support':
        _openSettingsSection(SettingsNavId.supportFeatureRequests);
        break;
    }
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case DesktopTab.chats:
        return const HomeScreen(embeddedInShell: true);
      case DesktopTab.personas:
        return const PersonasShellContent();
      case DesktopTab.settings:
        return SettingsScreen(
          key: ValueKey('settings-$_settingsNavEpoch-$_settingsInitialNavId'),
          embedded: true,
          initialNavId: _settingsInitialNavId,
        );
      case DesktopTab.arena:
        return const ArenaShellContent();
      case DesktopTab.nerds:
        return const NerdsShellContent();
    }
  }
}
