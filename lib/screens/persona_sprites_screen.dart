import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/system_prompt.dart';
import '../pro/personas/sprite_generation.dart';
import '../providers/settings_provider.dart';
import '../services/character_card_import_service.dart';
import '../utils/expression_tags.dart';
import '../utils/image_picker_helper.dart';
import '../widgets/beta_badge.dart';

/// Expression sprites for one persona: import (images or a SillyTavern zip),
/// replace, remove, and (Pro) generate with image generation.
class PersonaSpritesScreen extends StatefulWidget {
  final String personaId;

  const PersonaSpritesScreen({super.key, required this.personaId});

  static Future<void> open(BuildContext context, SystemPrompt persona) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonaSpritesScreen(personaId: persona.id),
      ),
    );
  }

  @override
  State<PersonaSpritesScreen> createState() => _PersonaSpritesScreenState();
}

class _PersonaSpritesScreenState extends State<PersonaSpritesScreen> {
  bool _busy = false;

  SystemPrompt? _persona(BuildContext context, {bool listen = true}) {
    final settings = listen
        ? context.watch<SettingsProvider>().settings
        : context.read<SettingsProvider>().settings;
    for (final p in settings.savedSystemPrompts ?? const <SystemPrompt>[]) {
      if (p.id == widget.personaId) return p;
    }
    return null;
  }

  void _save(SystemPrompt persona, Map<String, String> sprites) {
    context.read<SettingsProvider>().updateSavedSystemPrompt(
          sprites.isEmpty
              ? persona.copyWith(clearExpressionSprites: true)
              : persona.copyWith(expressionSprites: sprites),
        );
  }

  Future<void> _import() async {
    final persona = _persona(context, listen: false);
    if (persona == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final result =
          await CharacterCardImportService.pickAndImportSprites(persona);
      if (result == null || !mounted) return;
      final live = _persona(context, listen: false) ?? persona;
      final replaced = [
        for (final e in (live.expressionSprites ?? {}).entries)
          if (result.sprites[e.key] != e.value) e.value,
      ];
      _save(live, result.sprites);
      await CharacterCardImportService.deleteSpriteFiles(replaced);
      final parts = [l10n.personaExpressionsImported(result.added)];
      if (result.unmatched.isNotEmpty) {
        parts.add(l10n.personaExpressionsUnmatched(
            result.unmatched.take(5).join(', ')));
      }
      messenger.showSnackBar(SnackBar(content: Text(parts.join('\n'))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _replace(String label) async {
    final persona = _persona(context, listen: false);
    if (persona == null) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    if (file == null) return;
    final bytes = file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null || !mounted) return;
    final ext = (file.extension ?? 'png').toLowerCase();
    final rel = await CharacterCardImportService.saveSpriteBytes(
      persona.id,
      label,
      bytes,
      ext: ext,
    );
    if (!mounted) return;
    final live = _persona(context, listen: false) ?? persona;
    final old = live.expressionSprites?[label];
    _save(live, {...?live.expressionSprites, label: rel});
    if (old != null) await CharacterCardImportService.deleteSpriteFiles([old]);
  }

  Future<void> _remove(String label) async {
    final persona = _persona(context, listen: false);
    final old = persona?.expressionSprites?[label];
    if (persona == null || old == null) return;
    final next = Map<String, String>.from(persona.expressionSprites!)
      ..remove(label);
    _save(persona, next);
    await CharacterCardImportService.deleteSpriteFiles([old]);
  }

  Future<void> _removeAll() async {
    final persona = _persona(context, listen: false);
    if (persona == null || !persona.hasExpressionSprites) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.personaExpressionsRemoveAllConfirm(persona.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.personaExpressionsRemoveAll),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final old = persona.expressionSprites!.values.toList();
    _save(persona, const {});
    await CharacterCardImportService.deleteSpriteFiles(old);
  }

  void _showCellActions(String label, bool hasSprite) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.personaExpressionsReplace),
              onTap: () {
                Navigator.pop(ctx);
                _replace(label);
              },
            ),
            if (hasSprite)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.personaExpressionsRemove),
                onTap: () {
                  Navigator.pop(ctx);
                  _remove(label);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final persona = _persona(context);
    if (persona == null) {
      return Scaffold(appBar: AppBar());
    }
    final sprites = persona.expressionSprites ?? const <String, String>{};
    final cs = Theme.of(context).colorScheme;
    // Sprites the persona has first, then the rest of the labels.
    final labels = [
      for (final l in kExpressionLabels)
        if (sprites.containsKey(l)) l,
      for (final l in kExpressionLabels)
        if (!sprites.containsKey(l)) l,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.personaExpressionsTitle),
            const SizedBox(width: 8),
            const BetaBadge(),
          ],
        ),
        actions: [
          if (sprites.isNotEmpty)
            IconButton(
              tooltip: l10n.personaExpressionsRemoveAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _busy ? null : _removeAll,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.personaExpressionsSubtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _import,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_upload_outlined),
                label: Text(l10n.personaExpressionsImport),
              ),
              ProSpriteGeneration.generateButton(
                context: context,
                persona: persona,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: labels.length,
            itemBuilder: (context, i) {
              final label = labels[i];
              final path = ImagePickerHelper.resolveImagePathSync(sprites[label]);
              return _SpriteCell(
                label: label,
                path: path,
                missingText: l10n.personaExpressionsMissing,
                onTap: () => _showCellActions(label, sprites[label] != null),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SpriteCell extends StatelessWidget {
  final String label;
  final String? path;
  final String missingText;
  final VoidCallback onTap;

  const _SpriteCell({
    required this.label,
    required this.path,
    required this.missingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: path != null ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: path != null
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.file(
                        File(path!),
                        key: ValueKey(path),
                        fit: BoxFit.contain,
                        cacheWidth: 300,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    )
                  : Center(
                      child: Text(
                        missingText,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
