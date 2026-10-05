import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/feature_attachment_service.dart';

/// Compact attachment picker for feature requests and comments. Lets the
/// user pick up to [FeatureAttachmentService.maxAttachments] photos or
/// short videos from the gallery / camera, validates them client-side,
/// and renders thumbnails with a remove control.
///
/// The widget is fully controlled — the parent owns the [files] list and
/// must rebuild after [onChanged]. Keep this state lifted so the parent
/// can pass the same list into the upload service when submitting.
class AttachmentPicker extends StatelessWidget {
  final List<File> files;
  final ValueChanged<List<File>> onChanged;

  /// Optional override of the max count (defaults to service constant).
  final int maxFiles;

  const AttachmentPicker({
    super.key,
    required this.files,
    required this.onChanged,
    this.maxFiles = FeatureAttachmentService.maxAttachments,
  });

  bool _isVideo(File f) => FeatureAttachmentService.isVideoPath(f.path);

  bool _isLog(File f) => FeatureAttachmentService.isLogPath(f.path);

  Future<void> _pickFromGallery(BuildContext context) async {
    final remaining = maxFiles - files.length;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    try {
      final picked = await picker.pickMultipleMedia(limit: remaining);
      if (picked.isEmpty) return;
      final newList = [...files, ...picked.map((x) => File(x.path))];
      final trimmed =
          newList.length > maxFiles ? newList.sublist(0, maxFiles) : newList;
      final validation = FeatureAttachmentService.instance.validate(trimmed);
      if (validation != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validation)),
          );
        }
        return;
      }
      onChanged(trimmed);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    }
  }

  Future<void> _pickFromCamera(BuildContext context, bool video) async {
    final remaining = maxFiles - files.length;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    try {
      final XFile? x = video
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.camera);
      if (x == null) return;
      final newList = [...files, File(x.path)];
      final validation = FeatureAttachmentService.instance.validate(newList);
      if (validation != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validation)),
          );
        }
        return;
      }
      onChanged(newList);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture: $e')),
        );
      }
    }
  }

  void _remove(int index) {
    final next = [...files]..removeAt(index);
    onChanged(next);
  }

  Future<void> _showPickSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              subtitle: Text(l10n.galleryLimitsSubtitle),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera(context, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l10n.recordVideo),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canAdd = files.length < maxFiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              l10n.attachmentsCount(files.length, maxFiles),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.add),
              onPressed: canAdd ? () => _showPickSheet(context) : null,
            ),
          ],
        ),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final f = files[i];
                final isVideo = _isVideo(f);
                final isLog = _isLog(f);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: isLog
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 32,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.errorLogLabel,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : isVideo
                                ? Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 38,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Image.file(f, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _remove(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                      if (isVideo)
                        Positioned(
                          bottom: 2,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIDEO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
