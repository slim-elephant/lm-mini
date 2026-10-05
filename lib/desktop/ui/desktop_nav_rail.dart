import 'package:flutter/material.dart';

/// Tabs available in the desktop 3-column shell.
enum DesktopTab { chats, personas, settings, arena, nerds }

/// Callback for rail footer actions (Account, Support).
typedef RailFooterAction = void Function(String action);

/// A thin (72px) icon-with-label navigation rail for the desktop shell.
///
/// Dark navy background matching the glass header aesthetic; active tab gets a
/// subtle pill highlight.
class DesktopNavRail extends StatelessWidget {
  final DesktopTab activeTab;
  final ValueChanged<DesktopTab> onTabChanged;
  final RailFooterAction? onFooterAction;

  const DesktopNavRail({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    this.onFooterAction,
  });

  static const double width = 72;
  static const Color _bg = Color(0xFF0E1117);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            // Title bar owns macOS traffic-light clearance.
            const SizedBox(height: 8),
            _RailItem(
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'Chats',
              isActive: activeTab == DesktopTab.chats,
              onTap: () => onTabChanged(DesktopTab.chats),
            ),
            _RailItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Personas',
              isActive: activeTab == DesktopTab.personas,
              onTap: () => onTabChanged(DesktopTab.personas),
            ),
            _RailItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'Settings',
              isActive: activeTab == DesktopTab.settings,
              onTap: () => onTabChanged(DesktopTab.settings),
            ),
            _RailItem(
              icon: Icons.emoji_events_outlined,
              activeIcon: Icons.emoji_events_rounded,
              label: 'Arena',
              isActive: activeTab == DesktopTab.arena,
              onTap: () => onTabChanged(DesktopTab.arena),
            ),
            const Spacer(),
            _RailItem(
              icon: Icons.terminal_outlined,
              activeIcon: Icons.terminal_rounded,
              label: 'Nerds',
              isActive: activeTab == DesktopTab.nerds,
              onTap: () => onTabChanged(DesktopTab.nerds),
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.white.withValues(alpha: 0.10),
            ),
            const SizedBox(height: 8),
            _RailItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Account',
              isActive: false,
              onTap: () => onFooterAction?.call('account'),
            ),
            _RailItem(
              icon: Icons.help_outline_rounded,
              activeIcon: Icons.help_rounded,
              label: 'Support',
              isActive: false,
              onTap: () => onFooterAction?.call('support'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : Colors.white54;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
