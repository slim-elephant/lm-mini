import 'dart:io';

import 'package:flutter/material.dart';

import '../models/system_prompt.dart';
import '../utils/image_picker_helper.dart';
import '../utils/persona_palette.dart';

/// Tall portrait tile for Mac/iPad personas grids — image + name, no prompt text.
class PersonaPortraitCard extends StatelessWidget {
  final SystemPrompt prompt;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const PersonaPortraitCard({
    super.key,
    required this.prompt,
    required this.isSelected,
    required this.onSelect,
    required this.onView,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  static bool isPackAvatar(String? path) {
    if (path == null) return false;
    return path.contains('persona_pack_') ||
        path.contains('assets/images/persona_pack');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = prompt.color != null
        ? Color(prompt.color!)
        : (PersonaPalette.cachedOf(prompt)?.primary ?? cs.primary);
    final avatarPath =
        ImagePickerHelper.resolveImagePathSync(prompt.avatarPath);
    final pack = isPackAvatar(prompt.avatarPath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        onLongPress: onView,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
              width: isSelected ? 2.5 : 1,
            ),
            color: isDark
                ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
                : cs.surfaceContainerLowest,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PortraitArt(
                        path: avatarPath,
                        accent: accent,
                        isPackArt: pack,
                      ),
                      Positioned(
                        top: 8,
                        right: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MiniIconButton(
                              icon: Icons.visibility_outlined,
                              tooltip: 'Profile',
                              onTap: onView,
                            ),
                            _MiniIconButton(
                              icon: Icons.edit_outlined,
                              tooltip: 'Edit',
                              onTap: onEdit,
                            ),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              onSelected: (v) {
                                if (v == 'dup') onDuplicate();
                                if (v == 'del') onDelete();
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'dup',
                                  child: Text('Duplicate'),
                                ),
                                PopupMenuItem(
                                  value: 'del',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? cs.primary : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (prompt.isPersona)
                          _Badge(label: 'Persona', color: cs.primary),
                        if (prompt.boundModelIds == null ||
                            prompt.boundModelIds!.isEmpty)
                          _Badge(
                            label: 'All models',
                            color: cs.onSurfaceVariant,
                            icon: Icons.public,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortraitArt extends StatelessWidget {
  final String? path;
  final Color accent;
  final bool isPackArt;

  const _PortraitArt({
    required this.path,
    required this.accent,
    required this.isPackArt,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.85),
              accent.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.face_rounded, size: 56, color: Colors.white70),
        ),
      );
    }

    final file = File(path!);
    if (isPackArt) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: accent.withValues(alpha: 0.25)),
          Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image_outlined,
              color: accent,
            ),
          ),
        ],
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Container(
        color: accent.withValues(alpha: 0.3),
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Icon(icon, size: 15, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
