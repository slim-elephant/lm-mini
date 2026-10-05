import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/generated_image_library_item.dart';
import '../providers/chat_provider.dart';
import '../screens/chat_screen.dart';
import '../services/generated_image_library_service.dart';
import '../utils/media_gallery.dart';
import '../utils/media_type_utils.dart';
import '../utils/share_helper.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/image_gen_button.dart';

class GeneratedImagesLibraryScreen extends StatefulWidget {
  final String? conversationId;
  final String? title;
  final bool openInExistingChat;

  const GeneratedImagesLibraryScreen({
    super.key,
    this.conversationId,
    this.title,
    this.openInExistingChat = false,
  });

  @override
  State<GeneratedImagesLibraryScreen> createState() =>
      _GeneratedImagesLibraryScreenState();
}

class _GeneratedImagesLibraryScreenState
    extends State<GeneratedImagesLibraryScreen> {
  final _library = GeneratedImageLibraryService();
  List<GeneratedImageLibraryItem> _items = [];
  bool _loading = true;
  bool _selecting = false;
  final Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    List<GeneratedImageLibraryItem> items;
    final scopedId = widget.conversationId;
    if (scopedId != null) {
      final chat = context.read<ChatProvider>();
      if (chat.currentConversation?.id == scopedId) {
        final raw = chat.generatedImagesForCurrentConversation();
        items = [];
        for (final item in raw) {
          items.add(GeneratedImageLibraryItem(
            filePath:
                await GeneratedImageLibraryService.resolvePath(item.filePath),
            messageId: item.messageId,
            conversationId: item.conversationId,
            conversationTitle: item.conversationTitle,
            timestamp: item.timestamp,
            imagePrompt: item.imagePrompt,
            infoJson: item.infoJson,
            orphan: item.orphan,
          ));
        }
      } else {
        items = (await _library.listAll())
            .where((i) => i.conversationId == scopedId)
            .toList();
      }
    } else {
      items = await _library.listAll();
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      _selectedKeys.removeWhere(
        (k) => items.every((item) => item.fileKey != k),
      );
    });
  }

  List<GeneratedImageLibraryItem> get _selectedItems =>
      _items.where((i) => _selectedKeys.contains(i.fileKey)).toList();

  void _toggleSelectMode() {
    setState(() {
      _selecting = !_selecting;
      if (!_selecting) _selectedKeys.clear();
    });
  }

  void _toggleKey(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  Future<void> _confirmDelete(List<GeneratedImageLibraryItem> items) async {
    if (items.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.generatedImagesDeleteConfirmTitle),
        content: Text(l10n.generatedImagesDeleteConfirmBody(items.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<ChatProvider>().deleteGeneratedLibraryItems(items);
    if (!mounted) return;
    setState(() {
      _selecting = false;
      _selectedKeys.clear();
    });
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return GlassSettingsScaffold(
      title: widget.title ?? l10n.generatedImagesLibrary,
      actions: [
        if (_items.isNotEmpty)
          TextButton(
            onPressed: _toggleSelectMode,
            child: Text(
              _selecting
                  ? l10n.generatedImagesCancelSelect
                  : l10n.generatedImagesSelect,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      bottomNavigationBar: _selecting && _selectedKeys.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _confirmDelete(_selectedItems),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    l10n.generatedImagesDeleteN(_selectedKeys.length),
                  ),
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _EmptyLibrary(l10n: l10n)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cross = w >= 900
                        ? 4
                        : w >= 600
                            ? 3
                            : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final selected = _selectedKeys.contains(item.fileKey);
                        return _LibraryTile(
                          item: item,
                          selecting: _selecting,
                          selected: selected,
                          onTap: () async {
                            if (_selecting) {
                              _toggleKey(item.fileKey);
                              return;
                            }
                            final messageId =
                                await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (_) => GeneratedImageDetailScreen(
                                  item: item,
                                  openInExistingChat: widget.openInExistingChat,
                                  onDeleted: () async {
                                    await _reload();
                                  },
                                ),
                              ),
                            );
                            if (!context.mounted) return;
                            if (widget.openInExistingChat &&
                                messageId != null &&
                                messageId.isNotEmpty) {
                              Navigator.of(context).pop(messageId);
                            }
                          },
                          onLongPress: () {
                            if (!_selecting) {
                              setState(() {
                                _selecting = true;
                                _selectedKeys.add(item.fileKey);
                              });
                            }
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyLibrary({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48, color: cs.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(
              l10n.generatedImagesLibraryEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.generatedImagesLibraryEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  final GeneratedImageLibraryItem item;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LibraryTile({
    required this.item,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isVideo = isVideoFilePath(item.filePath);
    final file = File(item.filePath);
    final exists = file.existsSync();
    final provider =
        item.parsed.providerKey == 'unknown' ? null : item.parsed.providerLabel;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (exists && !isVideo)
                    Image.file(file, fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        exists
                            ? Icons.videocam_outlined
                            : Icons.broken_image_outlined,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  if (isVideo && exists)
                    const Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.play_circle_fill,
                          color: Colors.white70, size: 36),
                    ),
                  if (provider != null)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Text(
                        provider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54)
                          ],
                        ),
                      ),
                    ),
                  if (selecting)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _SelectMark(selected: selected),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                item.displayPrompt ??
                    AppLocalizations.of(context).generatedImagesNoPrompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectMark extends StatelessWidget {
  final bool selected;
  const _SelectMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? cs.primary : Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: selected ? Icon(Icons.check, size: 14, color: cs.onPrimary) : null,
    );
  }
}

class GeneratedImageDetailScreen extends StatelessWidget {
  final GeneratedImageLibraryItem item;
  final Future<void> Function()? onDeleted;
  final bool openInExistingChat;

  const GeneratedImageDetailScreen({
    super.key,
    required this.item,
    this.onDeleted,
    this.openInExistingChat = false,
  });

  String _formatWhen(DateTime ts) {
    final m = ts.month.toString().padLeft(2, '0');
    final d = ts.day.toString().padLeft(2, '0');
    final h = ts.hour.toString().padLeft(2, '0');
    final min = ts.minute.toString().padLeft(2, '0');
    return '${ts.year}-$m-$d  $h:$min';
  }

  Future<void> _openChat(BuildContext context) async {
    if (openInExistingChat) {
      final messageId = item.messageId;
      if (messageId == null || messageId.isEmpty) return;
      Navigator.of(context).pop(messageId);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final id = item.conversationId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.generatedImagesChatUnavailable)),
      );
      return;
    }
    final chat = context.read<ChatProvider>();
    var conv = chat.conversationById(id);
    if (conv == null) {
      await chat.loadConversations(silent: true);
      conv = chat.conversationById(id);
    }
    if (!context.mounted) return;
    if (conv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.generatedImagesChatUnavailable)),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: id,
          highlightMessageId: item.messageId,
        ),
      ),
    );
  }

  Future<void> _deleteThis(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.generatedImagesDeleteConfirmTitle),
        content: Text(l10n.generatedImagesDeleteConfirmBody(1)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<ChatProvider>().deleteGeneratedLibraryItems([item]);
    await onDeleted?.call();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final parsed = item.parsed;
    final file = File(item.filePath);
    final exists = file.existsSync();
    final isVideo = isVideoFilePath(item.filePath);
    final prompt = item.displayPrompt;
    final chatTitle = item.conversationTitle?.trim();

    return GlassSettingsScaffold(
      title: parsed.providerLabel,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          GestureDetector(
            onTap: exists
                ? () => showGeneratedMediaViewer(context, item.filePath)
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1,
                child: exists && !isVideo
                    ? Image.file(file, fit: BoxFit.cover)
                    : ColoredBox(
                        color: cs.surfaceContainerHighest,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                exists
                                    ? Icons.videocam_outlined
                                    : Icons.broken_image_outlined,
                                size: 40,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exists
                                    ? l10n.generatedImagesVideo
                                    : l10n.generatedImagesMissingFile,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: parsed.providerLabel),
              _MetaChip(label: _formatWhen(item.timestamp)),
              if (item.orphan) _MetaChip(label: l10n.generatedImagesOrphan),
              ...parsed.summaryChips.map(
                (c) => _MetaChip(label: '${c.label}  ${c.value}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassSettingsCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.generatedImagesPrompt,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  prompt ?? l10n.generatedImagesNoPrompt,
                  style: const TextStyle(height: 1.4),
                ),
                if (parsed.negativePrompt != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.generatedImagesNegativePrompt,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    parsed.negativePrompt!,
                    style: TextStyle(
                      height: 1.4,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (chatTitle != null && chatTitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              chatTitle,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          if (exists) ...[
            FilledButton.tonalIcon(
              onPressed: () => saveMediaToGallery(context, item.filePath),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                MediaGallery.savesToPhotos ? l10n.saveToPhotos : l10n.save,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => shareFileFromContext(context, item.filePath),
              icon: const Icon(Icons.share_outlined),
              label: Text(l10n.share),
            ),
            const SizedBox(height: 10),
          ],
          if (item.conversationId != null)
            FilledButton.tonalIcon(
              onPressed: () => _openChat(context),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(
                openInExistingChat
                    ? l10n.generatedImagesShowInChat
                    : l10n.generatedImagesOpenChat,
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _deleteThis(context),
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            label: Text(
              l10n.delete,
              style: TextStyle(color: cs.error),
            ),
          ),
          if (parsed.raw.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.generatedImagesDetails,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            GlassSettingsCard(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                parsed.raw.entries
                    .where((e) => e.key != 'workflow')
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
