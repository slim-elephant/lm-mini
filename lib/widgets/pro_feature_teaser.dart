import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/biometric_label.dart';
import '../screens/subscription_screen.dart';
import 'pro_price_button.dart';

/// Short looping animation that shows what a Pro feature does, for the
/// locked chips in the composer and the top of the paywall. Null when a
/// feature has no animation yet.
Widget? proFeatureAnimation(PaywallFeature feature, {double height = 200}) {
  final Widget? scene = switch (feature) {
    PaywallFeature.webSearch => const _SearchAnimation(),
    PaywallFeature.codeSandbox => const _SandboxAnimation(),
    PaywallFeature.export => const _ExportAnimation(),
    PaywallFeature.groupChat => const _GroupChatAnimation(),
    PaywallFeature.remoteAccess => const _RemoteAccessAnimation(),
    PaywallFeature.liveActivity => const _LiveActivityAnimation(),
    PaywallFeature.compactChat => const _CompactAnimation(),
    PaywallFeature.appLock => const _AppLockAnimation(),
    PaywallFeature.branching => const _BranchingAnimation(),
    PaywallFeature.analytics => const _AnalyticsAnimation(),
    PaywallFeature.cloudBackup => const _CloudBackupAnimation(),
    PaywallFeature.huggingFace => const _HuggingFaceAnimation(),
    PaywallFeature.memory => const _MemoryAnimation(),
    _ => null,
  };
  if (scene == null) return null;
  // Fixed stage height; large text sizes clip instead of overflowing.
  return SizedBox(
    height: height,
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: scene,
    ),
  );
}

/// Free users tapping a locked Pro tool: what it does, then Get Pro.
Future<void> showProFeatureTeaser(
  BuildContext context,
  PaywallFeature feature,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _TeaserSheet(feature: feature),
  );
}

class _TeaserCopy {
  final String title;
  final List<String> points;
  const _TeaserCopy(this.title, this.points);
}

_TeaserCopy _copyFor(AppLocalizations l10n, PaywallFeature f) {
  switch (f) {
    case PaywallFeature.codeSandbox:
      return _TeaserCopy(l10n.teaserSandboxTitle, [
        l10n.teaserSandboxPoint1,
        l10n.teaserSandboxPoint2,
        l10n.teaserSandboxPoint3,
      ]);
    case PaywallFeature.export:
      return _TeaserCopy(l10n.teaserExportTitle, [
        l10n.teaserExportPoint1,
        l10n.teaserExportPoint2,
        l10n.teaserExportPoint3,
      ]);
    case PaywallFeature.groupChat:
      return _TeaserCopy(l10n.teaserGroupTitle, [
        l10n.teaserGroupPoint1,
        l10n.teaserGroupPoint2,
        l10n.teaserGroupPoint3,
      ]);
    case PaywallFeature.remoteAccess:
      return _TeaserCopy(l10n.teaserRemoteTitle, [
        l10n.teaserRemotePoint1,
        l10n.teaserRemotePoint2,
        l10n.teaserRemotePoint3,
      ]);
    case PaywallFeature.liveActivity:
      return _TeaserCopy(l10n.teaserLiveTitle, [
        l10n.teaserLivePoint1,
        l10n.teaserLivePoint2,
        l10n.teaserLivePoint3,
      ]);
    case PaywallFeature.compactChat:
      return _TeaserCopy(l10n.teaserCompactTitle, [
        l10n.teaserCompactPoint1,
        l10n.teaserCompactPoint2,
        l10n.teaserCompactPoint3,
      ]);
    case PaywallFeature.appLock:
      return _TeaserCopy(l10n.teaserLockTitle, [
        l10n.teaserLockPoint1(BiometricLabel.text(l10n)),
        l10n.teaserLockPoint2,
        l10n.teaserLockPoint3,
      ]);
    case PaywallFeature.branching:
      return _TeaserCopy(l10n.teaserBranchTitle, [
        l10n.teaserBranchPoint1,
        l10n.teaserBranchPoint2,
        l10n.teaserBranchPoint3,
      ]);
    case PaywallFeature.analytics:
      return _TeaserCopy(l10n.teaserStatsTitle, [
        l10n.teaserStatsPoint1,
        l10n.teaserStatsPoint2,
        l10n.teaserStatsPoint3,
      ]);
    case PaywallFeature.cloudBackup:
      return _TeaserCopy(l10n.teaserBackupTitle, [
        l10n.teaserBackupPoint1,
        l10n.teaserBackupPoint2,
        l10n.teaserBackupPoint3,
      ]);
    case PaywallFeature.huggingFace:
      return _TeaserCopy(l10n.teaserHfTitle, [
        l10n.teaserHfPoint1,
        l10n.teaserHfPoint2,
        l10n.teaserHfPoint3,
      ]);
    case PaywallFeature.memory:
      return _TeaserCopy(l10n.teaserMemoryTitle, [
        l10n.teaserMemoryPoint1,
        l10n.teaserMemoryPoint2,
        l10n.teaserMemoryPoint3,
      ]);
    case PaywallFeature.storage:
      return _TeaserCopy(l10n.teaserStorageTitle, [
        l10n.teaserStoragePoint1,
        l10n.teaserStoragePoint2,
        l10n.teaserStoragePoint3,
      ]);
    case PaywallFeature.webSearch:
    default:
      return _TeaserCopy(l10n.teaserSearchTitle, [
        l10n.teaserSearchPoint1,
        l10n.teaserSearchPoint2,
        l10n.teaserSearchPoint3,
      ]);
  }
}

class _TeaserSheet extends StatelessWidget {
  final PaywallFeature feature;
  const _TeaserSheet({required this.feature});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final copy = _copyFor(l10n, feature);
    final animation = proFeatureAnimation(feature);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (animation != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                child: animation,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            copy.title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final p in copy.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          ProPriceButton(
            height: 50,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubscriptionScreen(highlight: feature),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.firstChatNameSkip),
          ),
        ],
      ),
    );
  }
}

/// Loops [period]; children read [t] in 0..1 and pick their own beats.
class _Looping extends StatefulWidget {
  final Duration period;
  final Widget Function(BuildContext context, double t) builder;
  const _Looping({required this.period, required this.builder});

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => widget.builder(context, _c.value),
      );
}

/// 0..1 progress of [t] between [a] and [b].
double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

/// Question → the model reaches out over a locked link → live results come
/// back with sources.
class _SearchAnimation extends StatelessWidget {
  const _SearchAnimation();

  static const _accent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final query = l10n.teaserSearchDemoQuery;
    final results = [
      l10n.teaserSearchDemoResult1,
      l10n.teaserSearchDemoResult2,
      l10n.teaserSearchDemoResult3,
    ];
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final typed =
            query.substring(0, (query.length * _seg(t, 0.02, 0.28)).round());
        final travel = _seg(t, 0.30, 0.52);
        final globePulse = _seg(t, 0.48, 0.60);
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          typed.isEmpty ? ' ' : typed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Locked link: dots travel to the globe.
                    SizedBox(
                      width: 56,
                      height: 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (i) {
                              final on = travel > i / 4 && travel < 1;
                              return Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: on ? _accent : cs.outlineVariant,
                                ),
                              );
                            }),
                          ),
                          Icon(Icons.lock_rounded,
                              size: 12,
                              color:
                                  travel > 0 ? _accent : cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Transform.scale(
                      scale: 1 + 0.18 * (1 - (2 * globePulse - 1).abs()),
                      child: const Icon(Icons.public_rounded,
                          size: 30, color: _accent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < results.length; i++)
                  Builder(builder: (context) {
                    final p = _seg(t, 0.58 + i * 0.09, 0.70 + i * 0.09);
                    return Opacity(
                      opacity: p,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - p)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: _sceneCard(cs),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded,
                                  size: 14, color: _accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  results[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The model writes code → it runs in a sealed box → the exact answer.
class _SandboxAnimation extends StatelessWidget {
  const _SandboxAnimation();

  static const _accent = Color(0xFF14B8A6);
  static const _lines = [
    'nums = range(1, 101)',
    'total = sum(nums)',
    'print(total)',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final run = _seg(t, 0.50, 0.66);
        final out = _seg(t, 0.66, 0.76);
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _lines.length; i++)
                          Builder(builder: (context) {
                            final line = _lines[i];
                            final p = _seg(t, 0.02 + i * 0.14, 0.15 + i * 0.14);
                            return Text(
                              line.substring(0, (line.length * p).round()),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: Color(0xFF93C5FD),
                                height: 1.5,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: run == 0 ? 0 : (run < 1 ? run : 1),
                            strokeWidth: 3,
                            color: _accent,
                            backgroundColor: cs.outlineVariant,
                          ),
                        ),
                        const Icon(Icons.shield_rounded,
                            size: 20, color: _accent),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.teaserSandboxDemoSafe,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Opacity(
                    opacity: out,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * out,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _accent.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '5050',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _accent,
                              ),
                            ),
                            Text(
                              l10n.teaserSandboxDemoExact,
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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
  }
}

/// Shared card look for every scene (same radius, border and fill).
BoxDecoration _sceneCard(ColorScheme cs, {Color? tint}) => BoxDecoration(
      color: tint?.withValues(alpha: 0.12) ?? cs.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: tint?.withValues(alpha: 0.4) ??
            cs.outlineVariant.withValues(alpha: 0.5),
      ),
    );

/// Chat → a Markdown note flies into Obsidian / Files / PDF.
class _ExportAnimation extends StatelessWidget {
  const _ExportAnimation();

  static const _accent = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final targets = [
      (Icons.hub_rounded, 'Obsidian'),
      (Icons.folder_rounded, l10n.teaserExportDemoFiles),
      (Icons.picture_as_pdf_rounded, 'PDF'),
    ];
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final fly = Curves.easeInOut.transform(_seg(t, 0.30, 0.55));
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 172,
              child: LayoutBuilder(builder: (context, c) {
                final noteLeft = 8 + (c.maxWidth * 0.36) * fly;
                final noteTop = 52 + 34 * fly;
                return Stack(
                  children: [
                    // The chat.
                    Positioned(
                      left: 0,
                      top: 0,
                      width: c.maxWidth * 0.46,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < 2; i++)
                            Opacity(
                              opacity:
                                  _seg(t, 0.02 + i * 0.10, 0.12 + i * 0.10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                height: 16,
                                width: c.maxWidth * (i == 0 ? 0.40 : 0.30),
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? cs.primary
                                      : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // The note.
                    Positioned(
                      left: noteLeft,
                      top: noteTop,
                      child: Opacity(
                        opacity: _seg(t, 0.20, 0.30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: _sceneCard(cs, tint: _accent),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.description_rounded,
                                  size: 16, color: _accent),
                              SizedBox(width: 6),
                              Text(
                                'Chat.md',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Destinations light up one by one.
                    Positioned(
                      right: 0,
                      top: 8,
                      child: Column(
                        children: [
                          for (var i = 0; i < targets.length; i++)
                            Builder(builder: (context) {
                              final lit =
                                  _seg(t, 0.55 + i * 0.08, 0.63 + i * 0.08);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                width: 112,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: _sceneCard(cs,
                                    tint: lit > 0.5 ? _accent : null),
                                child: Row(
                                  children: [
                                    Icon(targets[i].$1,
                                        size: 16,
                                        color: Color.lerp(
                                            cs.onSurfaceVariant, _accent, lit)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        targets[i].$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    if (lit >= 1)
                                      const Icon(Icons.check_rounded,
                                          size: 14, color: _accent),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// One question, several AI personas answer in turn.
class _GroupChatAnimation extends StatelessWidget {
  const _GroupChatAnimation();

  static const _accent = Color(0xFF8B5CF6);
  static const _voices = [
    (Color(0xFF3B82F6), 'Q'),
    (Color(0xFFF59E0B), 'G'),
    (Color(0xFF10B981), 'M'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final replies = [
      l10n.teaserGroupDemoReply1,
      l10n.teaserGroupDemoReply2,
      l10n.teaserGroupDemoReply3,
    ];
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: _seg(t, 0.02, 0.12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.teaserGroupDemoQuestion,
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _voices.length; i++)
                  Builder(builder: (context) {
                    final p = _seg(t, 0.22 + i * 0.16, 0.34 + i * 0.16);
                    final (color, letter) = _voices[i];
                    return Opacity(
                      opacity: p,
                      child: Transform.translate(
                        offset: Offset(-10 * (1 - p), 0),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: color,
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: _sceneCard(cs, tint: color),
                                  child: Text(
                                    replies[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                Opacity(
                  opacity: _seg(t, 0.78, 0.86),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_rounded,
                          size: 16, color: _accent),
                      const SizedBox(width: 4),
                      Text(
                        l10n.teaserGroupDemoTag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Phone away from home → locked tunnel through the relay → your home
/// server answers. A snooper bounces off the shield; nothing is stored.
class _RemoteAccessAnimation extends StatelessWidget {
  const _RemoteAccessAnimation();

  static const _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 6000),
      builder: (context, t) {
        final go = Curves.easeInOut.transform(_seg(t, 0.06, 0.36));
        final back = Curves.easeInOut.transform(_seg(t, 0.46, 0.76));
        final snoop = _seg(t, 0.20, 0.42);
        final blocked = t > 0.34 && t < 0.62;
        final fadeOut = 1 - _seg(t, 0.93, 1.0);
        final shieldPulse = (t > 0.30 && t < 0.42)
            ? 1 + 0.12 * (1 - ((t - 0.36).abs() / 0.06)).clamp(0.0, 1.0)
            : 1.0;

        Widget node(IconData icon, String label, {bool lit = false}) =>
            SizedBox(
              width: 74,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: _sceneCard(cs, tint: lit ? _accent : null),
                    child: Icon(icon,
                        size: 24, color: lit ? _accent : cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            );

        Widget chip(String text, IconData icon) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: _sceneCard(cs, tint: _accent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: _accent),
                  const SizedBox(width: 4),
                  Text(text,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _accent)),
                ],
              ),
            );

        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SizedBox(
              height: 176,
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth;
                // Message travelling along the tunnel (y = 58).
                final outX = 30 + (w - 160) * go;
                final backX = 30 + (w - 160) * (1 - back);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tunnel.
                    Positioned(
                      left: 50,
                      right: 50,
                      top: 22,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          node(Icons.phone_iphone_rounded,
                              l10n.teaserRemoteDemoPhone,
                              lit: back >= 1),
                          Transform.scale(
                            scale: shieldPulse,
                            child: node(Icons.shield_rounded,
                                l10n.teaserRemoteDemoRelay,
                                lit: blocked || (go > 0.4 && go < 0.6)),
                          ),
                          node(Icons.dns_rounded, l10n.teaserRemoteDemoServer,
                              lit: go >= 1 && back < 0.1),
                        ],
                      ),
                    ),
                    // Snooper drops toward the tunnel and bounces off.
                    Positioned(
                      left: w / 2 + 34,
                      top: -6 +
                          30 *
                              (snoop < 0.7
                                  ? snoop / 0.7
                                  : 1 - (snoop - 0.7) / 0.3 * 0.6),
                      child: Opacity(
                        opacity: (t > 0.18 && t < 0.66) ? 1 : 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              blocked
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 16,
                              color: blocked ? cs.error : cs.onSurfaceVariant,
                            ),
                            if (blocked) ...[
                              const SizedBox(width: 3),
                              Text(l10n.teaserRemoteDemoBlocked,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: cs.error)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Question out…
                    if (go > 0 && go < 1)
                      Positioned(
                        left: outX,
                        top: 72,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 11, color: cs.onPrimary),
                              const SizedBox(width: 4),
                              Text(l10n.teaserRemoteDemoQuestion,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onPrimary)),
                            ],
                          ),
                        ),
                      ),
                    // …answer back from home.
                    if (back > 0)
                      Positioned(
                        left: backX,
                        top: 72,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: _sceneCard(cs, tint: _accent),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.home_rounded,
                                  size: 12, color: _accent),
                              const SizedBox(width: 4),
                              Text(l10n.teaserRemoteDemoAnswer,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    // What protects it.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: _seg(t, 0.76, 0.84),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            chip(l10n.teaserRemoteDemoEncrypted,
                                Icons.lock_rounded),
                            chip(l10n.teaserRemoteDemoPaired,
                                Icons.verified_user_rounded),
                            chip(l10n.teaserRemoteDemoNotStored,
                                Icons.do_not_disturb_on_rounded),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// You leave the app; the reply keeps going on the Lock Screen.
class _LiveActivityAnimation extends StatelessWidget {
  const _LiveActivityAnimation();

  static const _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final progress = _seg(t, 0.15, 0.75);
        final done = progress >= 1;
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        final now = TimeOfDay.now().format(context);
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DynamicIsland(
                    progress: progress,
                    done: done,
                    expanded: _seg(t, 0.08, 0.16),
                    accent: _accent,
                    workingLabel: l10n.teaserLiveDemoIsland,
                    doneLabel: l10n.teaserLiveDemoDone,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    now,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: _seg(t, 0.05, 0.15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle_rounded
                                : Icons.auto_awesome_rounded,
                            color: done ? const Color(0xFF34D399) : _accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  done
                                      ? l10n.teaserLiveDemoDone
                                      : l10n.teaserLiveDemoWorking,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    color: done
                                        ? const Color(0xFF34D399)
                                        : _accent,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }
}

/// The context meter fills up; older messages fold into a summary and the
/// chat keeps going.
class _CompactAnimation extends StatelessWidget {
  const _CompactAnimation();

  static const _accent = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final fill = _seg(t, 0.05, 0.40);
        final fold = Curves.easeInOut.transform(_seg(t, 0.45, 0.65));
        final meter = fill * 0.95 - fold * 0.65;
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        final full = meter > 0.85;
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: meter.clamp(0.0, 1.0),
                          minHeight: 6,
                          color: full ? cs.error : _accent,
                          backgroundColor: cs.outlineVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(meter.clamp(0.0, 1.0) * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: full ? cs.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: Stack(
                    children: [
                      // Old messages squeeze together and fade.
                      for (var i = 0; i < 4; i++)
                        Positioned(
                          left: i.isEven ? 0 : null,
                          right: i.isOdd ? 0 : null,
                          top: (i * 24.0) * (1 - fold),
                          child: Opacity(
                            opacity: _seg(t, 0.05 + i * 0.07, 0.12 + i * 0.07) *
                                (1 - fold),
                            child: Container(
                              width: i.isEven ? 170 : 130,
                              height: 18,
                              decoration: BoxDecoration(
                                color: i.isOdd
                                    ? cs.primary
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                      // …into one summary card.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Opacity(
                          opacity: fold,
                          child: Transform.scale(
                            scale: 0.9 + 0.1 * fold,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: _sceneCard(cs, tint: _accent),
                              child: Row(
                                children: [
                                  const Icon(Icons.compress_rounded,
                                      size: 16, color: _accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.teaserCompactDemoSummary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The pill at the top of the screen: grows while the reply is written,
/// then shows a green tick.
class _DynamicIsland extends StatelessWidget {
  final double progress;
  final bool done;
  final double expanded;
  final Color accent;
  final String workingLabel;
  final String doneLabel;

  const _DynamicIsland({
    required this.progress,
    required this.done,
    required this.expanded,
    required this.accent,
    required this.workingLabel,
    required this.doneLabel,
  });

  @override
  Widget build(BuildContext context) {
    const ready = Color(0xFF34D399);
    final width = 86 + 120 * expanded;
    return Container(
      width: width,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
      ),
      child: expanded < 0.6
          ? const SizedBox.shrink()
          : Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: done
                      ? const Icon(Icons.check_circle_rounded,
                          size: 14, color: ready)
                      : CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          color: accent,
                          backgroundColor: Colors.white24,
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    done ? doneLabel : workingLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: done ? ready : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Chats hidden behind a lock → Face ID / fingerprint scan → unlocked.
class _AppLockAnimation extends StatelessWidget {
  const _AppLockAnimation();

  static const _accent = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final method = BiometricLabel.current;
    final face = method == BiometricMethod.faceId ||
        method == BiometricMethod.faceUnlock;
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final scan = _seg(t, 0.25, 0.55);
        final unlocked = t > 0.58;
        final reveal = _seg(t, 0.58, 0.70);
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        final bracket = 0.85 + 0.15 * (1 - (2 * scan - 1).abs());
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // The app's chats, hidden until unlocked.
                Expanded(
                  child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: _sceneCard(cs),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: 0.15 + 0.85 * reveal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < 4; i++)
                                Align(
                                  alignment: i.isOdd
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    width: i.isOdd ? 70 : 100,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: i.isOdd
                                          ? cs.primary
                                          : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!unlocked)
                          Center(
                            child: Icon(Icons.lock_rounded,
                                size: 34, color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Biometric scan.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: unlocked ? 1 : bracket,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: unlocked
                                ? const Color(0xFF10B981)
                                : _accent.withValues(alpha: 0.3 + 0.7 * scan),
                            width: 2.5,
                          ),
                        ),
                        child: Icon(
                          unlocked
                              ? Icons.check_rounded
                              : (face ? Icons.face_rounded : Icons.fingerprint),
                          size: 34,
                          color: unlocked ? const Color(0xFF10B981) : _accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unlocked
                          ? l10n.teaserLockDemoUnlocked
                          : (method == BiometricMethod.fingerprint
                              ? l10n.teaserLockDemoFingerprint
                              : BiometricLabel.text(l10n, method)),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One conversation splits at a message into two paths you can switch
/// between.
class _BranchingAnimation extends StatelessWidget {
  const _BranchingAnimation();

  static const _accent = Color(0xFFA855F7);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final split = Curves.easeOut.transform(_seg(t, 0.25, 0.45));
        final a = _seg(t, 0.45, 0.58);
        final b = _seg(t, 0.55, 0.68);
        final active = t > 0.72 ? 1 : 0;
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        Widget bubble(String text, {bool user = false, bool lit = false}) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: user
                  ? BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : _sceneCard(cs, tint: lit ? _accent : null),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: user ? cs.onPrimary : cs.onSurface,
                ),
              ),
            );
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 168,
              child: LayoutBuilder(builder: (context, c) {
                final half = (c.maxWidth - 12) / 2;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Center(
                        child: Opacity(
                          opacity: _seg(t, 0.02, 0.12),
                          child:
                              bubble(l10n.teaserBranchDemoQuestion, user: true),
                        ),
                      ),
                    ),
                    // The fork.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 36,
                      child: CustomPaint(
                        size: Size(c.maxWidth, 40),
                        painter: _ForkPainter(
                          progress: split,
                          color: _accent.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    for (final (i, p, label, reply) in [
                      (
                        0,
                        a,
                        l10n.teaserBranchDemoA,
                        l10n.teaserBranchDemoReplyA
                      ),
                      (
                        1,
                        b,
                        l10n.teaserBranchDemoB,
                        l10n.teaserBranchDemoReplyB
                      ),
                    ])
                      Positioned(
                        left: i == 0 ? 0 : half + 12,
                        width: half,
                        top: 82,
                        child: Opacity(
                          opacity: p,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_tree_rounded,
                                      size: 12, color: _accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              bubble(reply, lit: active == 1 && i == 1),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _ForkPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ForkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mid = Offset(size.width / 2, 0);
    for (final x in [size.width * 0.25, size.width * 0.75]) {
      final end = Offset(x, size.height);
      final path = Path()
        ..moveTo(mid.dx, mid.dy)
        ..cubicTo(
            mid.dx, size.height * 0.6, x, size.height * 0.4, end.dx, end.dy);
      final metric = path.computeMetrics().first;
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_ForkPainter old) =>
      old.progress != progress || old.color != color;
}

/// Bars grow per model with speed numbers: your own usage dashboard.
class _AnalyticsAnimation extends StatelessWidget {
  const _AnalyticsAnimation();

  static const _accent = Color(0xFF6366F1);
  static const _bars = [
    ('Qwen 3.5', 0.85, '42 t/s'),
    ('Gemma 4', 0.62, '31 t/s'),
    ('Ministral', 0.40, '19 t/s'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 5200),
      builder: (context, t) {
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        final grow = Curves.easeOutCubic.transform(_seg(t, 0.10, 0.55));
        final count = (1284 * _seg(t, 0.10, 0.60)).round();
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: _sceneCard(cs, tint: _accent),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$count',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _accent)),
                            Text(l10n.teaserStatsDemoMessages,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: _sceneCard(cs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${(1.8 * grow).toStringAsFixed(1)} s',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(l10n.teaserStatsDemoFirstToken,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final (name, value, speed) in _bars)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11)),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) => Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 12,
                                width: c.maxWidth * value * grow,
                                decoration: BoxDecoration(
                                  color: _accent.withValues(
                                      alpha: 0.35 + 0.6 * value),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Opacity(
                          opacity: _seg(t, 0.50, 0.60),
                          child: Text(speed,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Chats get sealed (encrypted) and go up to your iCloud / Google account,
/// then come back on a new phone.
class _CloudBackupAnimation extends StatelessWidget {
  const _CloudBackupAnimation();

  static const _accent = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 5600),
      builder: (context, t) {
        final seal = _seg(t, 0.15, 0.30);
        final up = Curves.easeInOut.transform(_seg(t, 0.30, 0.50));
        final down = Curves.easeInOut.transform(_seg(t, 0.58, 0.78));
        final restored = t > 0.78;
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        Widget phone(String label, {bool lit = false}) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: _sceneCard(cs, tint: lit ? _accent : null),
                  child: Icon(Icons.phone_iphone_rounded,
                      size: 24, color: lit ? _accent : cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            );
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 168,
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth;
                // Package path: left phone → cloud (top centre) → right phone.
                final x = up < 1
                    ? 24 + (w / 2 - 48) * up
                    : w / 2 - 24 + (w / 2 - 48) * down;
                final y = up < 1 ? 100 - 70 * up : 30 + 70 * down;
                return Stack(
                  children: [
                    Positioned(
                      left: w / 2 - 34,
                      top: 0,
                      child: Icon(Icons.cloud_rounded,
                          size: 68,
                          color: (up >= 1 && down < 0.2)
                              ? _accent
                              : cs.outlineVariant),
                    ),
                    Positioned(
                        left: 0,
                        bottom: 0,
                        child: phone(l10n.teaserBackupDemoThis)),
                    Positioned(
                        right: 0,
                        bottom: 0,
                        child: phone(l10n.teaserBackupDemoNew, lit: restored)),
                    if (t > 0.10 && !restored)
                      Positioned(
                        left: x,
                        top: y,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration:
                              _sceneCard(cs, tint: seal > 0.5 ? _accent : null),
                          child: Icon(
                            seal > 0.5
                                ? Icons.enhanced_encryption_rounded
                                : Icons.chat_rounded,
                            size: 20,
                            color: seal > 0.5 ? _accent : cs.primary,
                          ),
                        ),
                      ),
                    if (restored)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 80,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: _sceneCard(cs, tint: _accent),
                            child: Text(
                              l10n.teaserBackupDemoRestored,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// Search Hugging Face → pick the quant that fits → it downloads onto the
/// phone and is ready offline.
class _HuggingFaceAnimation extends StatelessWidget {
  const _HuggingFaceAnimation();

  static const _accent = Color(0xFFFF9D00);
  static const _query = 'qwen 3.5 gguf';
  static const _repos = [
    'unsloth/Qwen3.5-9B-GGUF',
    'bartowski/Qwen3.5-4B-GGUF',
  ];
  static const _quants = ['Q3_K_M', 'Q4_K_M', 'Q8_0'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 6000),
      builder: (context, t) {
        final typed =
            _query.substring(0, (_query.length * _seg(t, 0.02, 0.20)).round());
        final pick = _seg(t, 0.36, 0.42);
        final quants = _seg(t, 0.42, 0.50);
        final choose = t > 0.56;
        final download = Curves.easeInOut.transform(_seg(t, 0.62, 0.82));
        final ready = t > 0.82;
        final fadeOut = 1 - _seg(t, 0.92, 1.0);
        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: _sceneCard(cs),
                        child: Row(
                          children: [
                            const Text('🤗', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                typed.isEmpty ? ' ' : typed,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _repos.length; i++)
                        Builder(builder: (context) {
                          final p = _seg(t, 0.20 + i * 0.06, 0.30 + i * 0.06);
                          final picked = i == 0 && pick > 0.5;
                          return Opacity(
                            opacity: p,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - p)),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: _sceneCard(cs,
                                    tint: picked ? _accent : null),
                                child: Text(
                                  _repos[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: picked
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      Opacity(
                        opacity: quants,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final q in _quants)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: _sceneCard(cs,
                                    tint: choose && q == 'Q4_K_M'
                                        ? _accent
                                        : null),
                                child: Text(
                                  q == 'Q4_K_M' && choose
                                      ? '$q · ${l10n.teaserHfDemoFits}'
                                      : q,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: choose && q == 'Q4_K_M'
                                        ? _accent
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        width: 56,
                        height: 92,
                        decoration: _sceneCard(cs, tint: ready ? _accent : null)
                            .copyWith(borderRadius: BorderRadius.circular(14)),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (download > 0 && !ready)
                              SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  value: download,
                                  strokeWidth: 3,
                                  color: _accent,
                                  backgroundColor: cs.outlineVariant,
                                ),
                              ),
                            Icon(
                              ready
                                  ? Icons.check_rounded
                                  : Icons.download_rounded,
                              size: 20,
                              color: download > 0 ? _accent : cs.outlineVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: ready ? 1 : 0,
                        child: Text(
                          l10n.teaserHfDemoReady,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// You mention a fact → it's saved as a memory → a brand-new chat already
/// uses it.
class _MemoryAnimation extends StatelessWidget {
  const _MemoryAnimation();

  static const _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return _Looping(
      period: const Duration(milliseconds: 6400),
      builder: (context, t) {
        final tell = _seg(t, 0.02, 0.10);
        final fact1 = _seg(t, 0.16, 0.26);
        final fact2 = _seg(t, 0.24, 0.34);
        // First chat slides away, the new chat comes in.
        final swap = Curves.easeInOut.transform(_seg(t, 0.42, 0.52));
        final ask = _seg(t, 0.54, 0.62);
        final glow = _seg(t, 0.62, 0.70);
        final reply = _seg(t, 0.70, 0.80);
        final fadeOut = 1 - _seg(t, 0.92, 1.0);

        Widget bubble(String text, {required bool user, double p = 1}) =>
            Opacity(
              opacity: p,
              child: Align(
                alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 210),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: user
                      ? BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(14),
                        )
                      : _sceneCard(cs),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                ),
              ),
            );

        Widget fact(String text, double p) => Opacity(
              opacity: p,
              child: Transform.scale(
                scale: 0.8 + 0.2 * p,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: _sceneCard(cs, tint: _accent),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ),
            );

        return Opacity(
          opacity: fadeOut,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 168,
                    child: ClipRect(
                      child: Stack(
                        children: [
                          // First chat.
                          Transform.translate(
                            offset: Offset(0, -40 * swap),
                            child: Opacity(
                              opacity: 1 - swap,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: bubble(l10n.teaserMemoryDemoTell,
                                    user: true, p: tell),
                              ),
                            ),
                          ),
                          // New chat.
                          Opacity(
                            opacity: swap,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - swap)),
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Text(
                                        l10n.teaserMemoryDemoNewChat,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    bubble(l10n.teaserMemoryDemoAsk,
                                        user: true, p: ask),
                                    const SizedBox(height: 6),
                                    Opacity(
                                      opacity: reply,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 6),
                                            child: Icon(
                                                Icons.psychology_rounded,
                                                size: 16,
                                                color: _accent),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: bubble(
                                                l10n.teaserMemoryDemoReply,
                                                user: false),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // The memory card fills up, then lights while it's used.
                Container(
                  width: 88,
                  padding: const EdgeInsets.all(8),
                  decoration: _sceneCard(cs,
                      tint: glow > 0 && reply < 1 ? _accent : null),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology_outlined,
                          size: 20,
                          color: fact1 > 0 ? _accent : cs.onSurfaceVariant),
                      const SizedBox(height: 6),
                      fact(l10n.teaserMemoryDemoFact1, fact1),
                      const SizedBox(height: 5),
                      fact(l10n.teaserMemoryDemoFact2, fact2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
