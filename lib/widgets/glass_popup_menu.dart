import 'package:flutter/material.dart';
import 'glass_blur.dart';

class GlassPopupMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final bool destructive;
  final bool enabled;

  const GlassPopupMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.destructive = false,
    this.enabled = true,
  });
}

/// Frosted glass overflow menu — same language as the chat header menu.
class GlassPopupMenuButton extends StatefulWidget {
  final Widget child;
  final List<GlassPopupMenuItem> items;
  final ValueChanged<String> onSelected;
  final String? tooltip;
  final Offset offset;
  final double menuWidth;
  final Alignment targetAnchor;
  final Alignment followerAnchor;

  /// Tighter rows for in-chat overflow (full-width ⋯).
  final bool compact;

  /// Prefer opening above the button (latest chat message, above composer).
  final bool preferAbove;

  const GlassPopupMenuButton({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    this.tooltip,
    this.offset = const Offset(0, 8),
    this.menuWidth = 240,
    this.targetAnchor = Alignment.bottomRight,
    this.followerAnchor = Alignment.topRight,
    this.compact = false,
    this.preferAbove = false,
  });

  @override
  State<GlassPopupMenuButton> createState() => _GlassPopupMenuButtonState();
}

class _GlassPopupMenuButtonState extends State<GlassPopupMenuButton> {
  OverlayEntry? _entry;
  bool _open = false;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _removeMenu() {
    _entry?.remove();
    _entry = null;
    _open = false;
  }

  void _toggle() {
    if (_open) {
      setState(_removeMenu);
      return;
    }
    _showMenu();
  }

  void _showMenu() {
    final hostContext = context;
    final overlay = Overlay.of(hostContext, rootOverlay: true);
    final theme = Theme.of(hostContext);
    final media = MediaQuery.of(hostContext);

    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final buttonBox = hostContext.findRenderObject() as RenderBox?;
    if (overlayBox == null ||
        buttonBox == null ||
        !overlayBox.hasSize ||
        !buttonBox.hasSize) {
      return;
    }

    final origin = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final buttonSize = buttonBox.size;
    final overlaySize = overlayBox.size;

    final pad = media.padding;
    final keyboard = media.viewInsets.bottom;
    // Keep the menu out of the home indicator / keyboard / composer band.
    final bottomReserve = keyboard + pad.bottom + (widget.preferAbove ? 108 : 12);
    final topReserve = pad.top + 8;
    final menuW = widget.menuWidth;
    final estimatedH =
        widget.items.length * (widget.compact ? 36.0 : 54.0) + 10;
    final availableH =
        (overlaySize.height - topReserve - bottomReserve).clamp(120.0, 420.0);
    final menuH = estimatedH.clamp(80.0, availableH);

    final alignLeft = widget.followerAnchor.x <= 0;
    var left = alignLeft
        ? origin.dx + widget.offset.dx
        : origin.dx + buttonSize.width - menuW + widget.offset.dx;
    final maxLeft = overlaySize.width - menuW - 8.0;
    if (maxLeft > 8.0) {
      left = left.clamp(8.0, maxLeft);
    } else {
      left = 8.0;
    }

    final gap = widget.offset.dy.abs().clamp(4.0, 12.0);
    final spaceBelow = overlaySize.height -
        bottomReserve -
        (origin.dy + buttonSize.height) -
        gap;
    final spaceAbove = origin.dy - topReserve - gap;
    final openUp = widget.preferAbove
        ? spaceAbove >= 80
        : (spaceBelow < menuH && spaceAbove > spaceBelow);

    double top;
    if (openUp) {
      top = origin.dy - gap - menuH;
    } else {
      top = origin.dy + buttonSize.height + gap;
    }
    final maxTop = overlaySize.height - bottomReserve - menuH;
    if (top > maxTop) top = maxTop;
    if (top < topReserve) top = topReserve;

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return MediaQuery(
          data: media,
          child: Theme(
            data: theme,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (mounted) setState(_removeMenu);
                    },
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: menuW,
                  child: Material(
                    color: Colors.transparent,
                    child: _GlassMenuPanel(
                      isDark: theme.brightness == Brightness.dark,
                      width: menuW,
                      maxHeight: menuH,
                      compact: widget.compact,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < widget.items.length; i++) ...[
                            if (i > 0)
                              widget.compact
                                  ? const _FadedMenuDivider()
                                  : Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      indent: 14,
                                      endIndent: 14,
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.18),
                                    ),
                            _GlassMenuRow(
                              item: widget.items[i],
                              compact: widget.compact,
                              onTap: () {
                                final id = widget.items[i].id;
                                if (mounted) setState(_removeMenu);
                                widget.onSelected(id);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: widget.child,
    );
    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

class _GlassMenuPanel extends StatelessWidget {
  final bool isDark;
  final double width;
  final double? maxHeight;
  final bool compact;
  final Widget child;

  const _GlassMenuPanel({
    required this.isDark,
    required this.width,
    required this.child,
    this.maxHeight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final glassOn = GlassBlur.enabledOf(context);
    final colors = glassOn
        ? (isDark
            ? [
                Color.alphaBlend(
                  cs.surface.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.10),
                ),
                Color.alphaBlend(
                  cs.surface.withValues(alpha: 0.88),
                  Colors.white.withValues(alpha: 0.04),
                ),
              ]
            : [
                Color.alphaBlend(
                  cs.surface.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.55),
                ),
                Color.alphaBlend(
                  cs.primaryContainer.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.32),
                ),
              ])
        : [GlassBlur.solidFillOf(context), GlassBlur.solidFillOf(context)];
    final borderColor = compact
        ? null
        : glassOn
            ? Color.alphaBlend(
                cs.outline.withValues(alpha: isDark ? 0.35 : 0.28),
                Colors.white.withValues(alpha: isDark ? 0.16 : 0.55),
              )
            : GlassBlur.solidBorderOf(context);

    Widget body = child;
    if (maxHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: child,
        ),
      );
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: compact
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(16),
              border:
                  borderColor == null ? null : Border.all(color: borderColor),
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _GlassMenuRow extends StatelessWidget {
  final GlassPopupMenuItem item;
  final VoidCallback onTap;
  final bool compact;

  const _GlassMenuRow({
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = !item.enabled
        ? cs.onSurfaceVariant.withValues(alpha: 0.45)
        : item.destructive
            ? cs.error
            : cs.onSurface;
    final iconColor = compact
        ? (!item.enabled
            ? color
            : item.destructive
                ? cs.error.withValues(alpha: 0.72)
                : cs.onSurface.withValues(alpha: isDark ? 0.48 : 0.42))
        : color;
    const tile = 32.0;

    return InkWell(
      onTap: item.enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 8 : 12,
        ),
        child: Row(
          children: [
            if (compact)
              Icon(item.icon, size: 18, color: iconColor)
            else
              Container(
                width: tile,
                height: tile,
                decoration: BoxDecoration(
                  color: item.destructive
                      ? cs.error.withValues(alpha: 0.12)
                      : cs.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: color),
              ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: compact ? 14 : null,
                      fontWeight: compact ? FontWeight.w400 : FontWeight.w600,
                      color: color,
                      letterSpacing: compact ? 0 : -0.1,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FadedMenuDivider extends StatelessWidget {
  const _FadedMenuDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mid = cs.outline.withValues(alpha: isDark ? 0.10 : 0.08);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 0.5,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                mid.withValues(alpha: 0),
                mid,
                mid,
                mid.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.16, 0.84, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
