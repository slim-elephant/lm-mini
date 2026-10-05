import 'package:flutter/material.dart';

import '../../models/pickable_model.dart';

/// Website-style model catalog card for Mac/iPad model browsers.
class ModelCatalogCard extends StatelessWidget {
  final PickableModel model;
  final VoidCallback? onTap;
  final VoidCallback? onInfo;
  final Widget? trailing;

  const ModelCatalogCard({
    super.key,
    required this.model,
    this.onTap,
    this.onInfo,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = model.isSelected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.65)
                  : cs.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.55),
              width: selected ? 1.5 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                      cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    ]
                  : [
                      Colors.white.withValues(alpha: isDark ? 0.045 : 0.55),
                      Colors.white.withValues(alpha: isDark ? 0.015 : 0.25),
                    ],
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (model.isLoaded)
                            _Badge(
                              label: 'Loaded',
                              fg: const Color(0xFF6EE7B7),
                              bg: const Color(0xFF34D399).withValues(alpha: 0.14),
                              border: const Color(0xFF34D399).withValues(alpha: 0.28),
                            ),
                          if (model.isSelected && !model.isLoaded)
                            _Badge(
                              label: 'Selected',
                              fg: cs.primary,
                              bg: cs.primary.withValues(alpha: 0.14),
                              border: cs.primary.withValues(alpha: 0.35),
                            ),
                          if (model.typeLabel != null &&
                              model.typeLabel!.isNotEmpty)
                            _Badge(
                              label: model.typeLabel!,
                              fg: const Color(0xFFC4B5FD),
                              bg: const Color(0xFFA78BFA).withValues(alpha: 0.12),
                              border: const Color(0xFFA78BFA).withValues(alpha: 0.28),
                            ),
                          if (model.quantLabel != null &&
                              model.quantLabel!.isNotEmpty)
                            _Badge(
                              label: model.quantLabel!,
                              fg: const Color(0xFFFCD34D),
                              bg: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                              border: const Color(0xFFFBBF24).withValues(alpha: 0.28),
                            ),
                          if (model.supportsVision)
                            _Badge(
                              label: 'Vision',
                              fg: cs.onSurfaceVariant,
                              bg: Colors.white.withValues(alpha: 0.06),
                              border: cs.outlineVariant.withValues(alpha: 0.45),
                            ),
                          if (model.isReasoning)
                            _Badge(
                              label: 'Reasoning',
                              fg: const Color(0xFFC4B5FD),
                              bg: const Color(0xFFA78BFA).withValues(alpha: 0.12),
                              border: const Color(0xFFA78BFA).withValues(alpha: 0.28),
                            ),
                        ],
                      ),
                    ),
                    if (model.sizeLabel != null && model.sizeLabel!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 6, top: 2),
                        child: Text(
                          model.sizeLabel!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: cs.primary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (model.isPinned) ...[
                      Icon(Icons.push_pin,
                          size: 14, color: cs.primary.withValues(alpha: 0.75)),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        model.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    model.subtitle?.isNotEmpty == true
                        ? model.subtitle!
                        : (model.familyGroup ?? model.providerKind.name),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (model.isLoading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    else if (model.downloadProgress != null)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: model.downloadProgress,
                            minHeight: 4,
                          ),
                        ),
                      )
                    else
                      Text(
                        model.familyGroup ?? '',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                    const Spacer(),
                    if (onInfo != null)
                      IconButton(
                        tooltip: 'Details',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: onInfo,
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final Color border;

  const _Badge({
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
    );
  }
}
