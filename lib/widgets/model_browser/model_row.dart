import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pickable_model.dart';
import '../glass_blur.dart';

/// Balanced model row: title, plain subtitle, glass capability pills,
/// size/type as trailing meta (not chip dump).
class ModelRow extends StatelessWidget {
  final PickableModel model;
  final VoidCallback? onTap;
  final VoidCallback? onInfo;
  final Widget? trailing;

  const ModelRow({
    super.key,
    required this.model,
    this.onTap,
    this.onInfo,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final selected = model.isSelected;
    final sizeType = [
      if (model.sizeLabel != null && model.sizeLabel!.isNotEmpty)
        model.sizeLabel!,
      if (model.typeLabel != null && model.typeLabel!.isNotEmpty)
        model.typeLabel!,
    ].join(' · ');
    final showNotLoaded = selected &&
        !model.isLoaded &&
        !model.isLoading &&
        model.providerKind == ModelProviderKind.lmStudio;

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.35)
          : cs.surfaceContainerLow.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (model.isLoaded)
                    Container(width: 4, color: const Color(0xFF3DDC84))
                  else if (model.isLoading)
                    Container(width: 4, color: cs.primary)
                  else if (showNotLoaded)
                    Container(width: 4, color: cs.error),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (model.isPinned) ...[
                                      Icon(Icons.push_pin,
                                          size: 14,
                                          color: cs.primary
                                              .withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        model.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                if (model.subtitle != null &&
                                    model.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    model.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: model.isLoading
                                          ? cs.primary
                                          : showNotLoaded
                                              ? cs.error
                                              : cs.onSurfaceVariant,
                                      height: 1.25,
                                      fontWeight:
                                          (showNotLoaded || model.isLoading)
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                    ),
                                  ),
                                ],
                                if (model.downloadProgress != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: model.downloadProgress!
                                          .clamp(0.0, 1.0),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                                if (model.isRecommended ||
                                    model.isLoaded ||
                                    model.isLoading ||
                                    showNotLoaded ||
                                    model.isReasoning ||
                                    model.supportsVision ||
                                    (model.quantLabel != null &&
                                        model.quantLabel!.isNotEmpty)) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (model.isRecommended)
                                        _StatusPill(
                                          label: l10n.bestForYou,
                                          icon: Icons.auto_awesome_rounded,
                                          color: cs.primary,
                                        ),
                                      if (model.isLoading)
                                        _StatusPill(
                                          label: l10n.loadingLabel,
                                          icon: Icons.hourglass_top_rounded,
                                          color: cs.primary,
                                        ),
                                      if (model.isLoaded)
                                        _StatusPill(
                                          label: l10n.loadedLabel,
                                          icon: Icons.memory_rounded,
                                          color: const Color(0xFF3DDC84),
                                        ),
                                      if (showNotLoaded)
                                        _StatusPill(
                                          label: l10n.notLoadedLabel,
                                          icon: Icons.hourglass_empty_rounded,
                                          color: cs.error,
                                        ),
                                      if (model.quantLabel != null &&
                                          model.quantLabel!.isNotEmpty)
                                        _GlassCapabilityPill(
                                          label: model.quantLabel!,
                                          icon: Icons.tune_rounded,
                                          color: const Color(0xFFFFB74D),
                                        ),
                                      if (model.isReasoning)
                                        _GlassCapabilityPill(
                                          label: l10n.reasoningLabel,
                                          icon: Icons.psychology_outlined,
                                          color: const Color(0xFFB39DDB),
                                        ),
                                      if (model.supportsVision)
                                        _GlassCapabilityPill(
                                          label: l10n.imagesLabel,
                                          icon: Icons.image_outlined,
                                          color: const Color(0xFF64B5F6),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (onInfo != null)
                                    IconButton(
                                      icon: Icon(Icons.info_outline,
                                          size: 20, color: cs.onSurfaceVariant),
                                      tooltip: l10n.detailsTooltip,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: onInfo,
                                    ),
                                  if (trailing != null) trailing!,
                                  if (selected)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.check_circle,
                                          color: cs.primary, size: 22),
                                    ),
                                ],
                              ),
                              if (sizeType.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 8, top: 2),
                                  child: Text(
                                    sizeType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (model.isLoading)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft tinted capability pill (Reasoning / Images).
class _GlassCapabilityPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _GlassCapabilityPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = color.withValues(alpha: isDark ? 0.18 : 0.14);
    final border = color.withValues(alpha: isDark ? 0.42 : 0.38);
    final fg = isDark
        ? Color.lerp(color, Colors.white, 0.35)!
        : Color.lerp(color, Colors.black, 0.25)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: GlassBlur(
        sigmaX: 14,
        sigmaY: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
