import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../pro/pro_features.dart';
import '../screens/subscription_screen.dart';
import '../utils/layout_utils.dart';
import 'adaptive_modal.dart';
import 'home_glass_header.dart';

/// Result of [showAddServerSheet].
sealed class AddServerSelection {
  const AddServerSelection();
}

/// User picked LM Studio (local desktop server).
final class AddServerLmStudio extends AddServerSelection {
  const AddServerLmStudio();
}

/// User picked LM Studio via USB (iOS → Mac cable bridge).
final class AddServerUsb extends AddServerSelection {
  const AddServerUsb();
}

/// User picked a [CloudApiType] (includes Ollama / oMLX).
final class AddServerCloud extends AddServerSelection {
  final CloudApiType type;
  const AddServerCloud(this.type);
}

/// Shows a polished picker for adding a new server / provider (~60% height).
/// Mac / iPad: centered dialog; phone / Android: bottom sheet.
Future<AddServerSelection?> showAddServerSheet(
  BuildContext context, {
  bool hideLocalNetwork = false,
}) {
  return showAdaptiveModal<AddServerSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    dialogMaxWidth: 520,
    builder: (ctx) => _AddServerSheet(hideLocalNetwork: hideLocalNetwork),
  );
}

class _AddServerSheet extends StatelessWidget {
  const _AddServerSheet({this.hideLocalNetwork = false});

  final bool hideLocalNetwork;

  /// Cloud types offered in this build: public builds omit paid (Pro) types.
  static List<CloudApiType> get _offeredCloudTypes => _cloudTypes
      .where((t) => ProFeatures.included || !t.isPremium)
      .toList();

  static const _localCloudTypes = <CloudApiType>[
    CloudApiType.ollama,
    CloudApiType.omlx,
    CloudApiType.jan,
    CloudApiType.unsloth,
  ];

  static List<CloudApiType> get _cloudTypes {
    const all = <CloudApiType>[
      CloudApiType.openai,
      CloudApiType.openRouter,
      CloudApiType.vercelAiGateway,
      CloudApiType.gemini,
      CloudApiType.zAi,
      CloudApiType.mistral,
      CloudApiType.deepSeek,
      CloudApiType.openaiCompatible,
    ];
    if (CloudApiType.hideFirstPartyOpenAi) {
      return all.where((t) => t != CloudApiType.openai).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wide = prefersWideSettingsLayout(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final canvas = isDark ? const Color(0xFF12151C) : const Color(0xFFF4F6FA);
    final fg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.88);
    final muted = fg.withValues(alpha: 0.62);
    final cloudTypes = _offeredCloudTypes;
    final maxH = MediaQuery.sizeOf(context).height * (wide ? 0.85 : 0.60);

    final sheet = Container(
      decoration: BoxDecoration(
        color: canvas.withValues(alpha: 0.96),
        borderRadius: wide
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!wide)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add a server',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hideLocalNetwork
                                    ? 'Cloud APIs. Ollama, JAN AI, Unsloth, ComfyUI, and AUTOMATIC1111 stay on Connect.'
                                    : 'Local Wi‑Fi, USB, or a cloud provider.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GlassCircleIconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onTap: () => Navigator.of(context).maybePop(),
                        onLightCanvas: !isDark,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  if (!hideLocalNetwork) ...[
                  Text(
                    'On your network',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ServerTypeTile(
                    icon: Icons.desktop_windows_rounded,
                    title: 'LM Studio',
                    subtitle: 'Desktop app on this Wi‑Fi',
                    fg: fg,
                    onTap: () =>
                        Navigator.pop(context, const AddServerLmStudio()),
                  ),
                  if (Platform.isIOS)
                    _ServerTypeTile(
                      icon: Icons.usb_rounded,
                      title: 'LM Studio via USB',
                      subtitle: 'Cable to Mac — no Wi‑Fi needed',
                      fg: fg,
                      onTap: () => Navigator.pop(context, const AddServerUsb()),
                    ),
                  for (final type in _localCloudTypes)
                    _ServerTypeTile(
                      icon: _iconFor(type),
                      title: type.displayName,
                      subtitle: type == CloudApiType.ollama
                          ? 'Local models, free to use'
                          : type == CloudApiType.jan
                              ? 'Local models from the JAN AI app'
                              : type == CloudApiType.unsloth
                                  ? 'Unsloth Desktop on your computer'
                                  : 'Apple Silicon MLX server',
                      fg: fg,
                      locked:
                          type.isPremium && !SubscriptionService().isPremium,
                      onTap: () => _onCloudTap(context, type),
                    ),
                  const SizedBox(height: 14),
                  ],
                  if (cloudTypes.isNotEmpty) ...[
                  Text(
                    'Cloud',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ],
                  for (final type in cloudTypes)
                    _ServerTypeTile(
                      icon: _iconFor(type),
                      title: type.displayName,
                      subtitle: type == CloudApiType.openaiCompatible
                          ? 'Any A.I-compatible API'
                          : type == CloudApiType.gemini
                              ? 'Gemini via Google AI Studio'
                              : type == CloudApiType.vercelAiGateway
                                  ? 'Many models via Vercel'
                                  : type == CloudApiType.zAi
                                      ? 'GLM models (A.I-compatible)'
                                      : type == CloudApiType.openRouter
                                          ? 'Route many models'
                                          : 'Requires an API key',
                      fg: fg,
                      locked:
                          type.isPremium && !SubscriptionService().isPremium,
                      onTap: () => _onCloudTap(context, type),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final padded = Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: wide
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: sheet,
            )
          : Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: sheet,
              ),
            ),
    );

    return GlassCanvas(
      onLightCanvas: !isDark,
      child: padded,
    );
  }

  void _onCloudTap(BuildContext context, CloudApiType type) {
    if (type.isPremium && !SubscriptionService().isPremium) {
      if (!ProFeatures.showUpsell) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }
    Navigator.pop(context, AddServerCloud(type));
  }

  static IconData _iconFor(CloudApiType type) {
    switch (type) {
      case CloudApiType.ollama:
        return Icons.pets_rounded;
      case CloudApiType.omlx:
        return Icons.memory_rounded;
      case CloudApiType.jan:
        return Icons.bolt_rounded;
      case CloudApiType.unsloth:
        return Icons.science_rounded;
      case CloudApiType.openai:
        return Icons.auto_awesome_rounded;
      case CloudApiType.openRouter:
        return Icons.alt_route_rounded;
      case CloudApiType.vercelAiGateway:
        return Icons.hub_rounded;
      case CloudApiType.gemini:
        return Icons.diamond_outlined;
      case CloudApiType.zAi:
        return Icons.psychology_alt_rounded;
      case CloudApiType.mistral:
        return Icons.air_rounded;
      case CloudApiType.deepSeek:
        return Icons.search_rounded;
      case CloudApiType.openaiCompatible:
        return Icons.hub_outlined;
    }
  }
}

class _ServerTypeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color fg;
  final bool locked;
  final String? badge;
  final VoidCallback onTap;

  const _ServerTypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fg,
    required this.onTap,
    this.locked = false,
  }) : badge = null;

  @override
  Widget build(BuildContext context) {
    final muted = fg.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: fg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                          if (locked) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked ? 'Upgrade to unlock' : subtitle,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  locked
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
