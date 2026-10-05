import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_glass_header.dart';
import 'glass_blur.dart';

/// Glass page chrome: back + title tab (+ optional trailing in-tab widget) + actions.
///
/// Matches the home Folders single-tab language. Pass [onLightCanvas] when the
/// scaffold behind the header is a light surface (not navy).
class GlassPageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? titleTrailing;
  final bool onLightCanvas;

  /// When true (desktop shell / split detail pane), skip status-bar inset.
  final bool embedded;

  const GlassPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.titleTrailing,
    this.onLightCanvas = false,
    this.embedded = false,
  });

  static const double contentHeight = 70;

  static double heightFor(BuildContext context, {bool embedded = false}) {
    if (embedded) return contentHeight + 8;
    return MediaQuery.paddingOf(context).top + contentHeight + 2;
  }

  @override
  Widget build(BuildContext context) {
    final top = embedded ? 0.0 : MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightCanvas = onLightCanvas && !isDark;
    final fg = lightCanvas
        ? Colors.black.withValues(alpha: 0.88)
        : (embedded
            ? (isDark
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.black.withValues(alpha: 0.75))
            : Colors.white);
    final statusStyle = lightCanvas || embedded
        ? SystemUiOverlayStyle.dark
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          );
    final shellBg = embedded
        ? (isDark
            ? const Color(0xFF0E1117)
            : Theme.of(context).colorScheme.surface)
        : Colors.transparent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusStyle,
      child: GlassCanvas(
        onLightCanvas: lightCanvas || (embedded && !isDark),
        child: Material(
          color: shellBg,
          child: SizedBox(
            height: top + contentHeight + (embedded ? 8 : 2),
            child: Padding(
              padding: EdgeInsets.only(top: top),
              child: SizedBox(
                height: contentHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if (onBack != null) ...[
                        GlassCircleIconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onTap: onBack,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: fg,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _GlassTitleTab(
                            label: title,
                            trailing: titleTrailing,
                            onLightCanvas: lightCanvas || (embedded && !isDark),
                          ),
                        ),
                      ),
                      ...actions.map(
                        (action) => Padding(
                          // Match back → title gap between trailing actions.
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTitleTab extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final bool onLightCanvas;

  const _GlassTitleTab({
    required this.label,
    this.trailing,
    required this.onLightCanvas,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedPill =
        isDark ? const Color(0xFF0B0E14) : Colors.white.withValues(alpha: 0.95);
    final selectedPillText =
        isDark ? Colors.white : Colors.black.withValues(alpha: 0.9);

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
                    : onLightCanvas
                        ? [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.28),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.32),
                            Colors.white.withValues(alpha: 0.14),
                          ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: isDark ? 0.26 : (onLightCanvas ? 0.7 : 0.6),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selectedPill,
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
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selectedPillText,
                            fontSize: 14,
                            letterSpacing: -0.1,
                          ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
