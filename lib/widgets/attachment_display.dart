import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/feature_request.dart';
import '../services/feature_attachment_service.dart';
import 'fullscreen_image_viewer.dart';

/// Renders a horizontally-scrolling strip of attachment thumbnails for a
/// feature request or comment. Photos open in-app with pinch-to-zoom; videos
/// open in the system media app.
///
/// Error log files are admin-only: they are hidden and never fetched unless
/// [showLogs] is true.
class AttachmentDisplay extends StatelessWidget {
  final List<FeatureAttachment> attachments;
  final double size;

  /// When false (default), `.log` / text attachments are omitted and not opened.
  final bool showLogs;

  const AttachmentDisplay({
    super.key,
    required this.attachments,
    this.size = 84,
    this.showLogs = false,
  });

  List<FeatureAttachment> get _visible => FeatureAttachment.visibleForViewer(
        attachments,
        isAdmin: showLogs,
      );

  Future<void> _open(BuildContext context, FeatureAttachment a) async {
    if (a.isLog) {
      if (!showLogs) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _AdminLogPreviewDialog(attachment: a),
      );
      return;
    }
    if (a.isImage) {
      final imageUrls =
          attachments.where((x) => x.isImage).map((x) => x.url).toList();
      final imageIndex = imageUrls.indexOf(a.url);
      await FullscreenImageViewer.openNetwork(
        context,
        urls: imageUrls,
        initialIndex: imageIndex >= 0 ? imageIndex : 0,
      );
      return;
    }

    final uri = Uri.tryParse(a.url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    if (visible.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final a = visible[i];
          return GestureDetector(
            onTap: () => _open(context, a),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: size,
                height: size,
                color: theme.colorScheme.surfaceContainerHighest,
                child: a.isImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            a.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: theme.colorScheme.outline),
                            ),
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                          if (attachments.where((x) => x.isImage).length > 1)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Icon(
                                Icons.zoom_in,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                        ],
                      )
                    : a.isLog
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              Center(
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
                                      'LOG',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(color: Colors.black87),
                              const Center(
                                child: Icon(Icons.play_circle_outline,
                                    size: 38, color: Colors.white),
                              ),
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
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminLogPreviewDialog extends StatefulWidget {
  final FeatureAttachment attachment;

  const _AdminLogPreviewDialog({required this.attachment});

  @override
  State<_AdminLogPreviewDialog> createState() => _AdminLogPreviewDialogState();
}

class _AdminLogPreviewDialogState extends State<_AdminLogPreviewDialog> {
  late final Future<String> _load;

  @override
  void initState() {
    super.initState();
    _load =
        FeatureAttachmentService.instance.downloadLogText(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Error log'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: FutureBuilder<String>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Text(
                'Could not load log: ${snap.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              );
            }
            final text = snap.data ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Log copied')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
