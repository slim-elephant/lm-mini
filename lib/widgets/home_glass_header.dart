import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'glass_blur.dart';
import 'glass_popup_menu.dart';

enum HomeListTab { chats, groups }

/// Provides canvas tone so [GlassCircleIconButton] can adapt frosted fills.
class GlassCanvas extends InheritedWidget {
  final bool onLightCanvas;

  const GlassCanvas({
    super.key,
    required this.onLightCanvas,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<GlassCanvas>()
            ?.onLightCanvas ??
        false;
  }

  @override
  bool updateShouldNotify(GlassCanvas oldWidget) =>
      onLightCanvas != oldWidget.onLightCanvas;
}

/// Glass home header: Chats/Groups tabs on the left, action icons on the right.
class HomeGlassHeader extends StatelessWidget {
  final HomeListTab listTab;

  /// False hides the Groups segment (public build without group chats).
  final bool showGroupsTab;
  final ValueChanged<HomeListTab> onListTabChanged;
  final bool showFolders;
  final bool showSearch;
  final bool selectionMode;
  final int selectedCount;
  final String? folderTitle;
  final VoidCallback? onFolderBack;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onEnterSelection;
  final VoidCallback? onExitSelection;
  final VoidCallback? onSelectAll;
  final VoidCallback? onBulkMove;
  final VoidCallback? onBulkDelete;
  final VoidCallback onToggleFolders;
  final VoidCallback onToggleSearch;
  final VoidCallback? onOpenArena;
  final VoidCallback? onNewGroupChat;
  final Widget settingsButton;
  final String selectTooltip;
  final String foldersTooltip;
  final String chatsTooltip;
  final String searchHint;

  /// Icon-only Chats/Groups toggle for narrow master panes (phone landscape).
  final bool compactTabs;

  /// When true, renders a flat shell column header (no status-bar inset).
  final bool embeddedInShell;

  const HomeGlassHeader({
    super.key,
    required this.listTab,
    this.showGroupsTab = true,
    required this.onListTabChanged,
    required this.showFolders,
    required this.showSearch,
    required this.selectionMode,
    required this.selectedCount,
    this.folderTitle,
    this.onFolderBack,
    this.onSearchChanged,
    this.onEnterSelection,
    this.onExitSelection,
    this.onSelectAll,
    this.onBulkMove,
    this.onBulkDelete,
    required this.onToggleFolders,
    required this.onToggleSearch,
    this.onOpenArena,
    this.onNewGroupChat,
    required this.settingsButton,
    required this.selectTooltip,
    required this.foldersTooltip,
    required this.chatsTooltip,
    required this.searchHint,
    this.compactTabs = false,
    this.embeddedInShell = false,
  });

  // ~10% larger than the first glass-home pass for easier tap targets.
  static const double contentHeight = 70;
  static const double iconSize = 46;

  static double heightFor(BuildContext context,
      {bool embeddedInShell = false}) {
    if (embeddedInShell) return contentHeight + 8;
    return MediaQuery.paddingOf(context).top + contentHeight + 2;
  }

  @override
  Widget build(BuildContext context) {
    final top = embeddedInShell ? 0.0 : MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onLightCanvas = embeddedInShell || (showFolders && !isDark);
    final cs = Theme.of(context).colorScheme;
    final shellBg = embeddedInShell
        ? (isDark ? const Color(0xFF0E1117) : cs.surface)
        : Colors.transparent;

    return GlassCanvas(
      onLightCanvas: onLightCanvas,
      child: Material(
        color: shellBg,
        child: SizedBox(
          height: top + contentHeight + (embeddedInShell ? 8 : 2),
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: SizedBox(
              height: contentHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: selectionMode
                    ? _SelectionRow(
                        selectedCount: selectedCount,
                        onClose: onExitSelection,
                        onSelectAll: onSelectAll,
                        onBulkMove: onBulkMove,
                        onBulkDelete: onBulkDelete,
                      )
                    : showSearch
                        ? _SearchRow(
                            searchHint: searchHint,
                            onChanged: onSearchChanged,
                            onClose: onToggleSearch,
                          )
                        : _NormalRow(
                            listTab: listTab,
                            showGroupsTab: showGroupsTab,
                            onListTabChanged: onListTabChanged,
                            showFolders: showFolders,
                            folderTitle: folderTitle,
                            onFolderBack: onFolderBack,
                            onEnterSelection: onEnterSelection,
                            onToggleFolders: onToggleFolders,
                            onToggleSearch: onToggleSearch,
                            onOpenArena: onOpenArena,
                            onNewGroupChat: onNewGroupChat,
                            settingsButton: settingsButton,
                            selectTooltip: selectTooltip,
                            foldersTooltip: foldersTooltip,
                            chatsTooltip: chatsTooltip,
                            compactTabs: compactTabs,
                            embeddedInShell: embeddedInShell,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NormalRow extends StatelessWidget {
  final HomeListTab listTab;
  final bool showGroupsTab;
  final ValueChanged<HomeListTab> onListTabChanged;
  final bool showFolders;
  final String? folderTitle;
  final VoidCallback? onFolderBack;
  final VoidCallback? onEnterSelection;
  final VoidCallback onToggleFolders;
  final VoidCallback onToggleSearch;
  final VoidCallback? onOpenArena;
  final VoidCallback? onNewGroupChat;
  final Widget settingsButton;
  final String selectTooltip;
  final String foldersTooltip;
  final String chatsTooltip;
  final bool compactTabs;
  final bool embeddedInShell;

  const _NormalRow({
    required this.listTab,
    this.showGroupsTab = true,
    required this.onListTabChanged,
    required this.showFolders,
    this.folderTitle,
    this.onFolderBack,
    this.onEnterSelection,
    required this.onToggleFolders,
    required this.onToggleSearch,
    this.onOpenArena,
    this.onNewGroupChat,
    required this.settingsButton,
    required this.selectTooltip,
    required this.foldersTooltip,
    required this.chatsTooltip,
    this.compactTabs = false,
    this.embeddedInShell = false,
  });

  @override
  Widget build(BuildContext context) {
    final inFolder = folderTitle != null && onFolderBack != null;
    final fg = _iconColor(context);
    final actionGap = compactTabs ? 4.0 : 6.0;

    return Row(
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: inFolder
                ? _FolderBackChip(
                    title: folderTitle!,
                    onBack: onFolderBack!,
                    foreground: fg,
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: showFolders
                        ? _TitleChip(label: foldersTooltip)
                        : _ChatsGroupsToggle(
                            listTab: listTab,
                            showGroupsTab: showGroupsTab,
                            onChanged: onListTabChanged,
                            compact: compactTabs,
                            embeddedInShell: embeddedInShell,
                          ),
                  ),
          ),
        ),
        SizedBox(width: compactTabs ? 4 : 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassCircleIconButton(
              tooltip: showFolders ? chatsTooltip : foldersTooltip,
              onTap: onToggleFolders,
              isActive: showFolders,
              child: Icon(
                showFolders
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.folder_outlined,
                size: compactTabs ? 20 : 22,
                color: fg,
              ),
            ),
            SizedBox(width: actionGap),
            _GlassActionsMenu(
              selectTooltip: selectTooltip,
              onSearch: onToggleSearch,
              onSelect: showFolders ? null : onEnterSelection,
              onArena: onOpenArena,
              onNewGroup: onNewGroupChat,
              iconColor: fg,
            ),
            SizedBox(width: actionGap),
            IconTheme(
              data: IconThemeData(color: fg, size: compactTabs ? 20 : 22),
              child: settingsButton,
            ),
          ],
        ),
      ],
    );
  }

  Color _iconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (embeddedInShell) {
      return isDark
          ? Colors.white.withValues(alpha: 0.88)
          : Colors.black.withValues(alpha: 0.75);
    }
    // Folders light mode uses a light surface — dark icons. Otherwise navy top → white.
    if (showFolders && !isDark) {
      return Colors.black.withValues(alpha: 0.88);
    }
    return Colors.white;
  }
}

class _GlassActionsMenu extends StatelessWidget {
  final String selectTooltip;
  final VoidCallback onSearch;
  final VoidCallback? onSelect;
  final VoidCallback? onArena;
  final VoidCallback? onNewGroup;
  final Color iconColor;

  const _GlassActionsMenu({
    required this.selectTooltip,
    required this.onSearch,
    this.onSelect,
    this.onArena,
    this.onNewGroup,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = iconColor;
    final l10n = AppLocalizations.of(context);
    final items = <GlassPopupMenuItem>[
      GlassPopupMenuItem(
        id: 'search',
        label: l10n.search,
        icon: Icons.search_rounded,
      ),
      if (onSelect != null)
        GlassPopupMenuItem(
          id: 'select',
          label: selectTooltip,
          icon: Icons.checklist_rounded,
        ),
      if (onArena != null)
        GlassPopupMenuItem(
          id: 'arena',
          label: l10n.arenaMode,
          icon: Icons.emoji_events_outlined,
        ),
      if (onNewGroup != null)
        GlassPopupMenuItem(
          id: 'group',
          label: l10n.newGroupChat,
          icon: Icons.group_add_rounded,
        ),
    ];

    return GlassPopupMenuButton(
      tooltip: l10n.moreTooltip,
      menuWidth: 220,
      items: items,
      onSelected: (value) {
        switch (value) {
          case 'search':
            onSearch();
          case 'select':
            onSelect?.call();
          case 'arena':
            onArena?.call();
          case 'group':
            onNewGroup?.call();
        }
      },
      child: IgnorePointer(
        child: GlassCircleIconButton(
          tooltip: l10n.moreTooltip,
          onTap: () {},
          child: Icon(Icons.more_horiz_rounded, size: 22, color: fg),
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final String searchHint;
  final ValueChanged<String>? onChanged;
  final VoidCallback onClose;

  const _SearchRow({
    required this.searchHint,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: GlassBlur(
              sigmaX: 28,
              sigmaY: 28,
              child: Container(
                height: HomeGlassHeader.iconSize,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.04),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.36),
                            Colors.white.withValues(alpha: 0.16),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.6),
                  ),
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: onChanged,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: searchHint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GlassCircleIconButton(
          tooltip: l10n.closeSearch,
          onTap: onClose,
          child: const Icon(
            Icons.close_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SelectionRow extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onClose;
  final VoidCallback? onSelectAll;
  final VoidCallback? onBulkMove;
  final VoidCallback? onBulkDelete;

  const _SelectionRow({
    required this.selectedCount,
    this.onClose,
    this.onSelectAll,
    this.onBulkMove,
    this.onBulkDelete,
  });

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        GlassCircleIconButton(
          tooltip: l10n.cancel,
          onTap: onClose,
          child: const Icon(Icons.close_rounded, size: 22, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.nSelected(selectedCount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
          ),
        ),
        GlassCircleIconButton(
          tooltip: l10n.selectAll,
          onTap: onSelectAll,
          child: const Icon(Icons.select_all_rounded, size: 22, color: fg),
        ),
        const SizedBox(width: 6),
        GlassCircleIconButton(
          tooltip: l10n.moveTooltip,
          onTap: onBulkMove,
          child: const Icon(Icons.folder_outlined, size: 22, color: fg),
        ),
        const SizedBox(width: 6),
        GlassCircleIconButton(
          tooltip: l10n.delete,
          onTap: onBulkDelete,
          child: const Icon(Icons.delete_outline_rounded, size: 22, color: fg),
        ),
      ],
    );
  }
}

class _ChatsGroupsToggle extends StatelessWidget {
  final HomeListTab listTab;
  final bool showGroupsTab;
  final ValueChanged<HomeListTab> onChanged;
  final bool compact;
  final bool embeddedInShell;

  const _ChatsGroupsToggle({
    required this.listTab,
    this.showGroupsTab = true,
    required this.onChanged,
    this.compact = false,
    this.embeddedInShell = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    if (embeddedInShell) {
      return Container(
        height: HomeGlassHeader.iconSize,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabSegment(
              label: l10n.chatsTab,
              icon: Icons.chat_bubble_outline_rounded,
              selected: listTab == HomeListTab.chats,
              compact: false,
              embeddedInShell: true,
              onTap: () => onChanged(HomeListTab.chats),
            ),
            if (showGroupsTab)
              _TabSegment(
                label: l10n.groupsTab,
                icon: Icons.groups_outlined,
                selected: listTab == HomeListTab.groups,
                compact: false,
                embeddedInShell: true,
                onTap: () => onChanged(HomeListTab.groups),
              ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: GlassBlur(
          sigmaX: 32,
          sigmaY: 32,
          child: Container(
            height: HomeGlassHeader.iconSize + (compact ? 0 : 4),
            padding: EdgeInsets.all(compact ? 2 : 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.32),
                        Colors.white.withValues(alpha: 0.14),
                      ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TabSegment(
                  label: l10n.chatsTab,
                  icon: Icons.chat_bubble_outline_rounded,
                  selected: listTab == HomeListTab.chats,
                  compact: compact,
                  onTap: () => onChanged(HomeListTab.chats),
                ),
                if (showGroupsTab)
                  _TabSegment(
                    label: l10n.groupsTab,
                    icon: Icons.groups_outlined,
                    selected: listTab == HomeListTab.groups,
                    compact: compact,
                    onTap: () => onChanged(HomeListTab.groups),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final bool embeddedInShell;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.embeddedInShell = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = embeddedInShell
        ? (selected
            ? (isDark ? Colors.white : Colors.black.withValues(alpha: 0.9))
            : (isDark
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.45)))
        : (selected
            ? (isDark ? Colors.white : Colors.black.withValues(alpha: 0.9))
            : Colors.white.withValues(alpha: isDark ? 0.72 : 0.88));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minHeight: embeddedInShell ? 42 : 40,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: embeddedInShell ? 12 : (compact ? 8 : 11),
          vertical: embeddedInShell ? 0 : (compact ? 6 : 8),
        ),
        decoration: BoxDecoration(
          color: selected
              ? (embeddedInShell
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white)
                  : (isDark
                      ? const Color(0xFF0B0E14)
                      : Colors.white.withValues(alpha: 0.95)))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: selected && isDark && !embeddedInShell
              ? Border.all(color: Colors.white.withValues(alpha: 0.14))
              : null,
          boxShadow: selected && !embeddedInShell
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.10),
                    blurRadius: isDark ? 10 : 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: compact ? 18 : 17, color: fg),
            if (!compact || selected || embeddedInShell) ...[
              SizedBox(width: compact ? 5 : 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fg,
                      fontSize: compact ? 12.5 : 14,
                      height: 1.0,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FolderBackChip extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Color foreground;

  const _FolderBackChip({
    required this.title,
    required this.onBack,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassCircleIconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: onBack,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: foreground),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
          ),
        ),
      ],
    );
  }
}

class _TitleChip extends StatelessWidget {
  final String label;
  const _TitleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Single selected tab matching Chats/Groups glass control.
    final fg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.9);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: GlassBlur(
          sigmaX: 32,
          sigmaY: 32,
          child: Container(
            height: HomeGlassHeader.iconSize + 4,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.28),
                      ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.7),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0B0E14)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(999),
                border: isDark
                    ? Border.all(color: Colors.white.withValues(alpha: 0.14))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.10),
                    blurRadius: isDark ? 10 : 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_outlined, size: 17, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: fg,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted circular icon control shared by the home glass header.
class GlassCircleIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isActive;
  final double size;

  /// When set, overrides [GlassCanvas] for light-canvas frosted fills.
  final bool? onLightCanvas;

  /// Stronger fill/border/shadow for floating actions on busy surfaces.
  final bool prominent;

  /// Mixes this color into the frost fill (e.g. green when connected).
  final Color? tint;

  /// Extra ring color (e.g. gold when Pro). Overrides the default border.
  final Color? outline;

  const GlassCircleIconButton({
    super.key,
    required this.child,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
    this.size = HomeGlassHeader.iconSize,
    this.onLightCanvas,
    this.prominent = false,
    this.tint,
    this.outline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightCanvas = (onLightCanvas ?? GlassCanvas.of(context)) && !isDark;

    final List<Color> fill;
    if (isDark) {
      fill = [
        Colors.white
            .withValues(alpha: prominent ? 0.28 : (isActive ? 0.14 : 0.08)),
        Colors.white
            .withValues(alpha: prominent ? 0.14 : (isActive ? 0.06 : 0.03)),
      ];
    } else if (lightCanvas) {
      // Prominent FAB: frosted white that still reads on a pale list, without
      // looking like a solid grey disc.
      fill = [
        Colors.white.withValues(alpha: prominent ? 0.72 : 0.78),
        Colors.white.withValues(alpha: prominent ? 0.52 : 0.58),
      ];
    } else {
      fill = [
        Colors.white
            .withValues(alpha: prominent ? 0.58 : (isActive ? 0.42 : 0.28)),
        Colors.white
            .withValues(alpha: prominent ? 0.36 : (isActive ? 0.22 : 0.12)),
      ];
    }
    if (tint != null) {
      final wash = isDark ? 0.16 : (lightCanvas ? 0.12 : 0.14);
      fill[0] = Color.alphaBlend(tint!.withValues(alpha: wash + 0.04), fill[0]);
      fill[1] = Color.alphaBlend(tint!.withValues(alpha: wash), fill[1]);
    }

    final Color borderColor;
    if (outline != null) {
      borderColor = outline!.withValues(alpha: isDark ? 0.92 : 0.88);
    } else if (tint != null) {
      borderColor = Color.lerp(
        Colors.white.withValues(alpha: isDark ? 0.28 : 0.55),
        tint!.withValues(alpha: isDark ? 0.70 : 0.55),
        0.4,
      )!;
    } else if (lightCanvas) {
      borderColor = Colors.black.withValues(alpha: prominent ? 0.14 : 0.12);
    } else {
      borderColor = Colors.white.withValues(
        alpha: isDark ? (prominent ? 0.42 : 0.28) : (prominent ? 0.75 : 0.65),
      );
    }
    final borderWidth = outline != null ? 1.7 : (prominent ? 1.25 : 1);

    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  prominent ? (isDark ? 0.40 : 0.14) : (isDark ? 0.22 : 0.08),
            ),
            blurRadius: prominent ? 18 : 14,
            offset: Offset(0, prominent ? 5 : 4),
          ),
          if (prominent && !isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          if (outline != null)
            BoxShadow(
              color: outline!.withValues(alpha: isDark ? 0.20 : 0.14),
              blurRadius: 3,
              spreadRadius: 0,
            ),
        ],
      ),
      child: ClipOval(
        child: GlassBlur(
          sigmaX: 28,
          sigmaY: 28,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tint == null && lightCanvas && !prominent
                        ? [
                            Colors.black
                                .withValues(alpha: isActive ? 0.10 : 0.06),
                            Colors.black
                                .withValues(alpha: isActive ? 0.05 : 0.03),
                          ]
                        : fill,
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth.toDouble(),
                  ),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
