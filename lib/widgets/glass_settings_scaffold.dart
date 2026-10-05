import 'package:flutter/material.dart';

import '../utils/layout_utils.dart';
import 'glass_page_header.dart';

/// Shared chrome for secondary settings screens: navy wash + glass header +
/// rounded sheet body (same language as Voice / Group setup).
///
/// On Mac / iPad when [embedded] in the Settings split pane, content uses the
/// full pane width (desktop layout). Standalone push routes keep the glass
/// header chrome; body is full-width with comfortable padding via
/// [GlassSettingsBody].
class GlassSettingsScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? titleTrailing;
  final Color? topBackground;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  /// When false, [body] is not wrapped in [GlassSettingsBody] (caller handles it).
  final bool constrainBody;

  /// When true, omit the glass header / navy wash — for hosting inside the
  /// Mac/iPad Settings right pane (sidebar provides navigation).
  final bool embedded;

  const GlassSettingsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.titleTrailing,
    this.topBackground,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.constrainBody = true,
    this.embedded = false,
  });

  static const Color defaultTopDark = Color(0xFF1A202E);
  static const Color defaultTopLight = Color(0xFF243044);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Full-width pane with desktop padding on Mac/iPad (never a phone column).
    final content = constrainBody || embedded
        ? GlassSettingsBody(child: body)
        : body;

    if (embedded) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (actions.isNotEmpty || titleTrailing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (titleTrailing != null) titleTrailing!,
                    ...actions,
                  ],
                ),
              ),
            Expanded(child: content),
          ],
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final topBg = topBackground ?? (isDark ? defaultTopDark : defaultTopLight);
    final headerH = GlassPageHeader.heightFor(context);

    return Scaffold(
      backgroundColor: topBg,
      extendBodyBehindAppBar: true,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(headerH),
        child: GlassPageHeader(
          title: title,
          onBack: () => Navigator.of(context).maybePop(),
          actions: actions,
          titleTrailing: titleTrailing,
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: headerH),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings content padding for Mac / iPad. Uses full available width
/// (no phone-width column). On phone/Android this is a pass-through.
class GlassSettingsBody extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;

  const GlassSettingsBody({
    super.key,
    required this.child,
    this.horizontalPadding = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (!prefersWideSettingsLayout(context)) {
      return child;
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }
}

/// Side-by-side columns on wide Mac/iPad; stacked on phone/Android.
///
/// Uses the **local** layout width (detail pane), not the full window, so the
/// Settings split pane can two-column correctly beside the sidebar.
class SettingsTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double breakpoint;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  /// Relative flex for left / right when side-by-side (default equal).
  final int leftFlex;
  final int rightFlex;

  const SettingsTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 640,
    this.spacing = 28,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (!prefersWideSettingsLayout(context)) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          left,
          SizedBox(height: spacing),
          right,
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;
        if (!wide) {
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: spacing),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

/// Soft card used inside glass settings sheets.
class GlassSettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassSettingsCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Soft leading icon tile matching Voice settings rows.
class GlassSettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const GlassSettingsIcon(this.icon, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: c, size: 22),
    );
  }
}
