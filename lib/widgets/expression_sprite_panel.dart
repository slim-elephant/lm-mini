import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/system_prompt.dart';
import '../utils/expression_tags.dart';
import '../utils/image_picker_helper.dart';

/// Visual-novel style sprite of the character's current expression, shown
/// over the bottom-right of the chat. Tap to collapse to a small chip.
class ExpressionSpritePanel extends StatelessWidget {
  final SystemPrompt persona;
  final String? expression;
  final bool collapsed;
  final ValueChanged<bool> onCollapsedChanged;

  /// Height available to the chat list; the sprite takes up to ~40% of it.
  final double availableHeight;

  const ExpressionSpritePanel({
    super.key,
    required this.persona,
    required this.expression,
    required this.collapsed,
    required this.onCollapsedChanged,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final rel = spriteForExpression(persona.expressionSprites, expression);
    final path = ImagePickerHelper.resolveImagePathSync(rel);
    if (path == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final label = expression != null && persona.expressionSprites?[expression] != null
        ? expression!
        : 'neutral';

    if (collapsed) {
      return Semantics(
        button: true,
        label: l10n.spritePanelShow(persona.name),
        child: GestureDetector(
          onTap: () => onCollapsedChanged(false),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: FileImage(File(path)),
                ),
                const SizedBox(width: 8),
                Text(
                  _labelText(label),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final height = (availableHeight * 0.4).clamp(120.0, 320.0);
    return Semantics(
      image: true,
      label: '${persona.name}: ${_labelText(label)}',
      child: GestureDetector(
        onTap: () => onCollapsedChanged(true),
        child: SizedBox(
          height: height,
          width: height * 0.75,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Image.file(
              File(path),
              key: ValueKey(path),
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  static String _labelText(String label) =>
      label.isEmpty ? label : label[0].toUpperCase() + label.substring(1);
}
