import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import 'glass_blur.dart';

class ChatGlassMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool showBadge;

  /// Defaults to theme primary. Use green for support unread, etc.
  final Color? badgeColor;

  const ChatGlassMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.showBadge = false,
    this.badgeColor,
  });
}

/// Floating glass chat header: avatar + Chat/Voice tabs + expandable menu.
class ChatGlassHeader extends StatefulWidget {
  final Widget avatar;
  final String title;
  final bool showTitle;
  final String personaLabel;
  final String modelLabel;
  final String? modelSubtitle;
  final bool voiceModeActive;
  final bool showAudioTab;
  final bool audioEnabled;
  final String? audioDisabledTooltip;
  final ValueChanged<bool> onVoiceModeChanged;
  final List<ChatGlassMenuItem> menuItems;
  final ValueChanged<String> onMenuSelected;
  final bool isModelLoading;
  final double? modelLoadingProgress;
  final bool showExpandToggle;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  /// When set, avatar info card shows an Edit icon for the active persona.
  final VoidCallback? onEditPersona;

  /// When set, avatar info card shows a View (profile) icon.
  final VoidCallback? onViewPersona;
  final bool embeddedInShell;

  const ChatGlassHeader({
    super.key,
    required this.avatar,
    required this.title,
    this.showTitle = false,
    required this.personaLabel,
    required this.modelLabel,
    this.modelSubtitle,
    required this.voiceModeActive,
    this.showAudioTab = true,
    this.audioEnabled = true,
    this.audioDisabledTooltip,
    required this.onVoiceModeChanged,
    required this.menuItems,
    required this.onMenuSelected,
    this.isModelLoading = false,
    this.modelLoadingProgress,
    this.showExpandToggle = false,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.onEditPersona,
    this.onViewPersona,
    this.embeddedInShell = false,
  });

  static const double contentHeight = 64;

  /// Outer diameter of the header avatar ring (matches [_ChatGlassHeaderState._circle]).
  static const double avatarSize = 50;

  static double heightFor(BuildContext context,
      {bool embeddedInShell = false}) {
    if (embeddedInShell) return contentHeight + 8;
    return MediaQuery.paddingOf(context).top + contentHeight + 2;
  }

  @override
  State<ChatGlassHeader> createState() => _ChatGlassHeaderState();
}

class _ChatGlassHeaderState extends State<ChatGlassHeader> {
  final LayerLink _menuLink = LayerLink();
  final LayerLink _avatarLink = LayerLink();
  OverlayEntry? _menuEntry;
  OverlayEntry? _infoEntry;
  bool _menuOpen = false;
  bool _infoOpen = false;

  static const double _circle = ChatGlassHeader.avatarSize;
  static const double _backCircle = _circle * 0.92; // ~8% smaller than peers

  @override
  void dispose() {
    _removeMenu();
    _removeInfo();
    super.dispose();
  }

  void _removeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
    _menuOpen = false;
  }

  void _removeInfo() {
    _infoEntry?.remove();
    _infoEntry = null;
    _infoOpen = false;
  }

  void _toggleMenu() {
    _removeInfo();
    if (_menuOpen) {
      setState(_removeMenu);
      return;
    }
    _showMenu();
  }

  void _toggleAvatarInfo() {
    _removeMenu();
    if (_infoOpen) {
      setState(_removeInfo);
      return;
    }
    _showAvatarInfo();
  }

  void _showMenu() {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    _menuEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(_removeMenu),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _menuLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10),
              child: Material(
                color: Colors.transparent,
                child: _ChatGlassOverlayPanel(
                  isDark: isDark,
                  width: 256,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.menuItems.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: cs.outline.withValues(alpha: 0.18),
                          ),
                        _GlassMenuTile(
                          item: widget.menuItems[i],
                          onTap: () {
                            final id = widget.menuItems[i].id;
                            setState(_removeMenu);
                            widget.onMenuSelected(id);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_menuEntry!);
    setState(() => _menuOpen = true);
  }

  void _showAvatarInfo() {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    _infoEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(_removeInfo),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _avatarLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 10),
              child: Material(
                color: Colors.transparent,
                child: _ChatGlassOverlayPanel(
                  isDark: isDark,
                  width: 260,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: _GlassAvatarRing(
                                size: 40,
                                ring: 2.5,
                                onTap: null,
                                child: widget.avatar,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.15,
                                  height: 1.2,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (widget.onViewPersona != null)
                              IconButton(
                                // No Tooltip: this panel is a CompositedTransformFollower.
                                // Flutter tooltips use OverlayPortal, which can't read the
                                // follower paint transform during layout (debug assert spam).
                                tooltip: null,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: () {
                                  setState(_removeInfo);
                                  widget.onViewPersona!();
                                },
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  size: 20,
                                  color: cs.primary,
                                ),
                              ),
                            if (widget.onEditPersona != null)
                              IconButton(
                                tooltip: null,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: () {
                                  setState(_removeInfo);
                                  widget.onEditPersona!();
                                },
                                icon: Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: cs.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: AppLocalizations.of(context)
                              .memoryPersonaFallback,
                          value: widget.personaLabel,
                          color: cs.onSurface,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.memory_rounded,
                          label: AppLocalizations.of(context).model,
                          value: widget.modelLabel,
                          subtitle: widget.modelSubtitle,
                          color: cs.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_infoEntry!);
    setState(() => _infoOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final top =
        widget.embeddedInShell ? 0.0 : MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellBg = widget.embeddedInShell
        ? (isDark
            ? const Color(0xFF0E1117)
            : Theme.of(context).colorScheme.surface)
        : Colors.transparent;

    return Material(
      color: shellBg,
      child: SizedBox(
        height: top +
            ChatGlassHeader.contentHeight +
            (widget.embeddedInShell ? 8 : 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!widget.embeddedInShell)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.04,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: top),
              child: SizedBox(
                height: ChatGlassHeader.contentHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Builder(
                    builder: (context) {
                      final showExpand = widget.showExpandToggle &&
                          widget.onToggleExpanded != null;
                      final leftWidth =
                          (canPop ? _backCircle + 6 : 0) + _circle;
                      final rightWidth =
                          _circle + (showExpand ? _circle + 6 : 0);
                      final side = math.max(leftWidth, rightWidth);
                      return Row(
                        children: [
                          SizedBox(
                            width: side,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canPop) ...[
                                  _GlassCircleButton(
                                    size: _backCircle,
                                    tooltip: MaterialLocalizations.of(context)
                                        .backButtonTooltip,
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                    child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                CompositedTransformTarget(
                                  link: _avatarLink,
                                  child: _GlassAvatarRing(
                                    size: _circle,
                                    ring: 3.5,
                                    tooltip: AppLocalizations.of(context)
                                        .personaAndModel,
                                    onTap: _toggleAvatarInfo,
                                    isActive: _infoOpen,
                                    child: widget.avatar,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _ChatAudioToggle(
                                  voiceModeActive: widget.voiceModeActive,
                                  showAudioTab: widget.showAudioTab,
                                  audioEnabled: widget.audioEnabled,
                                  audioDisabledTooltip:
                                      widget.audioDisabledTooltip,
                                  embeddedInShell: widget.embeddedInShell,
                                  onSelectChat: () =>
                                      widget.onVoiceModeChanged(false),
                                  onSelectAudio: () =>
                                      widget.onVoiceModeChanged(true),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: side,
                            child: Align(
                              alignment: Alignment.centerRight,
                              // Scale down if expand + menu would overflow the rail.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showExpand) ...[
                                      _GlassCircleButton(
                                        size: _circle,
                                        tooltip: widget.isExpanded
                                            ? 'Collapse'
                                            : 'Expand',
                                        onTap: widget.onToggleExpanded!,
                                        child: Icon(
                                          widget.isExpanded
                                              ? Icons.fullscreen_exit_rounded
                                              : Icons.fullscreen_rounded,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    CompositedTransformTarget(
                                      link: _menuLink,
                                      child: _GlassCircleButton(
                                        size: _circle,
                                        tooltip: AppLocalizations.of(context)
                                            .chatOptions,
                                        isActive: _menuOpen,
                                        onTap: _toggleMenu,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              _menuOpen
                                                  ? Icons.close_rounded
                                                  : Icons.more_horiz_rounded,
                                              size: 24,
                                            ),
                                            if (widget.menuItems
                                                .any((e) => e.showBadge))
                                              Positioned(
                                                right: -1,
                                                top: -1,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: widget.menuItems
                                                            .where((e) =>
                                                                e.showBadge)
                                                            .map((e) =>
                                                                e.badgeColor)
                                                            .whereType<Color>()
                                                            .firstOrNull ??
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (widget.isModelLoading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: widget.modelLoadingProgress,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatGlassOverlayPanel extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final double? width;

  const _ChatGlassOverlayPanel({
    required this.isDark,
    required this.child,
    this.width,
  });

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final glassOn = GlassBlur.enabledOf(context);
    final colors = glassOn
        ? (isDark
            ? [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ]
            : [
                Colors.white.withValues(alpha: 0.34),
                Colors.white.withValues(alpha: 0.16),
              ])
        : [GlassBlur.solidFillOf(context), GlassBlur.solidFillOf(context)];
    final borderColor = glassOn
        ? Colors.white.withValues(alpha: isDark ? 0.22 : 0.55)
        : GlassBlur.solidBorderOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: GlassBlur(
        sigmaX: 36,
        sigmaY: 36,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                      height: 1.2,
                    ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular control with frosted glass fill + light rim.
class _GlassCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isActive;
  final double size;

  const _GlassCircleButton({
    required this.child,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
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
                    colors: isDark
                        ? [
                            Colors.white
                                .withValues(alpha: isActive ? 0.14 : 0.08),
                            Colors.white
                                .withValues(alpha: isActive ? 0.06 : 0.03),
                          ]
                        : [
                            Colors.white
                                .withValues(alpha: isActive ? 0.42 : 0.28),
                            Colors.white
                                .withValues(alpha: isActive ? 0.22 : 0.12),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.28 : 0.65),
                    width: 1,
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

/// Avatar with a visible frosted glass halo around the photo edge.
class _GlassAvatarRing extends StatelessWidget {
  final Widget child;
  final double size;
  final double ring;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isActive;

  const _GlassAvatarRing({
    required this.child,
    required this.size,
    required this.ring,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inner = size - ring * 2;

    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: GlassBlur(
          sigmaX: 30,
          sigmaY: 30,
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
                    colors: isDark
                        ? [
                            Colors.white
                                .withValues(alpha: isActive ? 0.18 : 0.12),
                            Colors.white
                                .withValues(alpha: isActive ? 0.08 : 0.05),
                          ]
                        : [
                            Colors.white
                                .withValues(alpha: isActive ? 0.48 : 0.32),
                            Colors.white
                                .withValues(alpha: isActive ? 0.24 : 0.14),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.32 : 0.7),
                    width: 1.1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(ring),
                  child: ClipOval(
                    child: SizedBox(
                      width: inner,
                      height: inner,
                      child: child,
                    ),
                  ),
                ),
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

class _ChatAudioToggle extends StatelessWidget {
  final bool voiceModeActive;
  final bool showAudioTab;
  final bool audioEnabled;
  final String? audioDisabledTooltip;
  final bool embeddedInShell;
  final VoidCallback onSelectChat;
  final VoidCallback onSelectAudio;

  const _ChatAudioToggle({
    required this.voiceModeActive,
    required this.showAudioTab,
    required this.audioEnabled,
    required this.audioDisabledTooltip,
    required this.onSelectChat,
    required this.onSelectAudio,
    this.embeddedInShell = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (embeddedInShell) {
      return Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: l10n.chatTab,
              icon: Icons.chat_bubble_outline_rounded,
              selected: !voiceModeActive,
              embeddedInShell: true,
              onTap: onSelectChat,
            ),
            if (showAudioTab)
              _Segment(
                label: l10n.voiceTab,
                icon: Icons.graphic_eq_rounded,
                selected: voiceModeActive,
                enabled: audioEnabled,
                disabledTooltip: audioDisabledTooltip,
                embeddedInShell: true,
                onTap: onSelectAudio,
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
            height: 50,
            padding: const EdgeInsets.all(4),
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
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Segment(
                  label: l10n.chatTab,
                  icon: Icons.chat_bubble_outline_rounded,
                  selected: !voiceModeActive,
                  onTap: onSelectChat,
                ),
                if (showAudioTab)
                  _Segment(
                    label: l10n.voiceTab,
                    icon: Icons.graphic_eq_rounded,
                    selected: voiceModeActive,
                    enabled: audioEnabled,
                    disabledTooltip: audioDisabledTooltip,
                    onTap: onSelectAudio,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final bool embeddedInShell;
  final String? disabledTooltip;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.embeddedInShell = false,
    this.disabledTooltip,
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
            : (isDark
                ? Colors.white.withValues(alpha: enabled ? 0.78 : 0.35)
                : Colors.black.withValues(alpha: enabled ? 0.55 : 0.28)));

    final child = GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minHeight: embeddedInShell ? 42 : 40,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: embeddedInShell ? 0 : 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? (embeddedInShell
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white)
                  : (isDark
                      ? const Color(0xFF2A2A2E).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.95)))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected && !embeddedInShell
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: -0.1,
                    fontSize: 14,
                  ),
            ),
          ],
        ),
      ),
    );

    if (!enabled && disabledTooltip != null) {
      return Tooltip(message: disabledTooltip!, child: child);
    }
    return child;
  }
}

class _GlassMenuTile extends StatelessWidget {
  final ChatGlassMenuItem item;
  final VoidCallback onTap;

  const _GlassMenuTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = item.enabled
        ? cs.onSurface
        : cs.onSurfaceVariant.withValues(alpha: 0.55);

    return InkWell(
      onTap: item.enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ),
            if (item.showBadge)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.badgeColor ?? cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
