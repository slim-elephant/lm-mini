import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/chat_message.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/media_gallery.dart';
import '../utils/media_type_utils.dart';
import '../utils/share_helper.dart';
import '../l10n/app_localizations.dart';
import 'glass_blur.dart';

/// Review / edit the image prompt before sending it to ComfyUI, A1111, or
/// on-device SD. Used by the compact image button and full-width ⋯ menu.
Future<String?> showImagePromptReviewDialog(
  BuildContext context, {
  required String initialPrompt,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _ImagePromptReviewDialog(initialPrompt: initialPrompt),
  );
}

class _ImagePromptReviewDialog extends StatefulWidget {
  final String initialPrompt;

  const _ImagePromptReviewDialog({required this.initialPrompt});

  @override
  State<_ImagePromptReviewDialog> createState() =>
      _ImagePromptReviewDialogState();
}

class _ImagePromptReviewDialogState extends State<_ImagePromptReviewDialog> {
  late final TextEditingController _controller;
  double? _fieldHeight;

  static const _vPad = 28.0;
  static const _minLines = 3;
  static const _defaultLines = 6;
  static const _dialogVerticalInset = 24.0;
  static const _dialogVerticalInsetKeyboard = 12.0;
  // Header row (~62) + paddings + gaps + action row (~40).
  static const _chromeAboveField = 18.0 + 64.0 + 16.0;
  static const _chromeBelowField = 14.0 + 40.0 + 16.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _lineHeight(ThemeData theme) {
    final style = theme.textTheme.bodyMedium?.copyWith(height: 1.35);
    final fontSize = style?.fontSize ?? 14;
    final height = style?.height ?? 1.35;
    return fontSize * height;
  }

  double _heightForLines(int lines, ThemeData theme) =>
      _lineHeight(theme) * lines + _vPad;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final keyboardOpen = keyboard > 80;
    final verticalInset =
        keyboardOpen ? _dialogVerticalInsetKeyboard : _dialogVerticalInset;
    // Dialog already adds viewInsets to insetPadding — do not pad again.
    final availableH = (media.size.height - keyboard - verticalInset * 2)
        .clamp(0.0, media.size.height);
    final minFieldH = _heightForLines(_minLines, theme);
    final defaultFieldH = _heightForLines(_defaultLines, theme);
    final maxFieldH = (availableH - _chromeAboveField - _chromeBelowField)
        .clamp(48.0, availableH);
    final minH = maxFieldH < minFieldH ? maxFieldH : minFieldH;
    final fieldH = (_fieldHeight ?? defaultFieldH).clamp(minH, maxFieldH);
    final glassOn = GlassBlur.enabledOf(context);
    final fill = glassOn
        ? cs.surface.withValues(alpha: isDark ? 0.92 : 0.96)
        : GlassBlur.solidFillOf(context);
    final border = glassOn
        ? cs.outline.withValues(alpha: 0.14)
        : GlassBlur.solidBorderOf(context);
    final gripColor =
        cs.onSurfaceVariant.withValues(alpha: isDark ? 0.42 : 0.38);

    return Dialog(
      insetPadding:
          EdgeInsets.symmetric(horizontal: 20, vertical: verticalInset),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassBlur(
          sigmaX: 28,
          sigmaY: 28,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: availableH,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            Icon(Icons.auto_awesome_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.reviewImagePrompt,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.reviewPromptSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    fit: FlexFit.loose,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minH,
                        maxHeight: fieldH,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TextField(
                            controller: _controller,
                            autofocus: true,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.35),
                            decoration: InputDecoration(
                              hintText: l10n.editImagePromptHint,
                              filled: true,
                              fillColor: cs.surfaceContainerHighest.withValues(
                                alpha: isDark ? 0.45 : 0.55,
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                22,
                                20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: cs.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: cs.outline.withValues(alpha: 0.18),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) {
                                  setState(() {
                                    _fieldHeight = (fieldH + details.delta.dy)
                                        .clamp(minH, maxFieldH);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: CustomPaint(
                                    size: const Size(14, 14),
                                    painter: _ResizeGripPainter(
                                      color: gripColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: Text(l10n.cancel),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(l10n.generate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeGripPainter extends CustomPainter {
  final Color color;

  const _ResizeGripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final o = 3.0 + i * 3.4;
      canvas.drawLine(
        Offset(size.width - o, size.height - 1),
        Offset(size.width - 1, size.height - o),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResizeGripPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Widget that shows an image generation icon button in the action row.
/// Always returns an icon-sized widget (never the full image).
/// Use [GeneratedImageDisplay] separately to show the generated image below the row.
class ImageGenButton extends StatefulWidget {
  final ChatMessage message;
  final void Function(ChatMessage updated) onMessageUpdated;
  final Color textColor;

  const ImageGenButton({
    super.key,
    required this.message,
    required this.onMessageUpdated,
    required this.textColor,
  });

  @override
  State<ImageGenButton> createState() => _ImageGenButtonState();
}

class _ImageGenButtonState extends State<ImageGenButton> {
  String? _error;

  String _getPrompt() {
    // For user messages, use the message text as prompt
    if (widget.message.role == 'user') {
      return widget.message.content;
    }
    // For assistant messages, prefer the extracted imagePrompt
    if (widget.message.imagePrompt != null &&
        widget.message.imagePrompt!.isNotEmpty) {
      return widget.message.imagePrompt!;
    }
    // Fallback: use first 200 chars of the message
    final text = widget.message.content;
    return text.length > 200 ? text.substring(0, 200) : text;
  }

  Future<void> _generate() async {
    final globalSettings = context.read<SettingsProvider>().settings;
    final chatProvider = context.read<ChatProvider>();
    final settings = chatProvider.settingsForImageGeneration(
      globalSettings,
      message: widget.message,
    );
    if (!settings.isImageGenReady) {
      _showUnreachableBanner(
        settings.imageGenProvider == 'onDevice'
            ? 'No on-device SD checkpoint selected. Go to Settings → Image Generation and download/activate a model.'
            : 'No image generation server configured. Go to Settings → Image Generation to set the server URL.',
      );
      return;
    }

    // If review prompt is enabled, show dialog for editing before sending
    String prompt = _getPrompt();
    if (settings.imageGenReviewPrompt) {
      final editedPrompt =
          await showImagePromptReviewDialog(context, initialPrompt: prompt);
      if (editedPrompt == null) return;
      if (!mounted) return;
      prompt = editedPrompt;
    }

    if (mounted) setState(() => _error = null);

    await chatProvider.generateImageForMessage(
      message: widget.message,
      baseSettings: globalSettings,
      prompt: prompt,
      settingsProvider: context.read<SettingsProvider>(),
    );
  }

  Future<void> _cancel() async {
    await context
        .read<ChatProvider>()
        .cancelImageGeneration(messageId: widget.message.id);
  }

  void _showUnreachableBanner(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading:
              Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error),
          content: Text(
            message,
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          actions: [
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).clearMaterialBanners(),
              child: const Text('DISMISS'),
            ),
          ],
        ),
      );
    // Auto-dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        ScaffoldMessenger.of(context).clearMaterialBanners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.message.hasGeneratedImages;
    final chatProvider = context.watch<ChatProvider>();
    final isGenerating = chatProvider.isImageGeneratingFor(widget.message.id);
    final isQueued = chatProvider.isImageGenQueued(widget.message.id);

    if (isGenerating) {
      return _buildProgressIndicator(
        context,
        progress: chatProvider.imageGenProgressFor(widget.message.id),
        queued: isQueued,
      );
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    if (hasImage) {
      return _buildRegenerateIcon(context);
    }

    return _buildButton(context);
  }

  Widget _buildRegenerateIcon(BuildContext context) {
    final iconColor = widget.textColor.withValues(alpha: 0.7);
    return Tooltip(
      message: 'Regenerate Image',
      child: GestureDetector(
        onTap: _generate,
        child: Icon(
          Icons.image_outlined,
          size: 14,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final iconColor = widget.textColor.withValues(alpha: 0.7);
    return Tooltip(
      message: 'Generate Image',
      child: GestureDetector(
        onTap: _generate,
        child: Icon(
          Icons.auto_awesome,
          size: 14,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context, {
    double? progress,
    bool queued = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = widget.textColor.withValues(alpha: 0.7);
    final effectiveProgress = progress ?? 0;
    final label = queued
        ? 'Queued...'
        : effectiveProgress >= 0.05
            ? '${(effectiveProgress * 100).toInt()}%'
            : 'Generating...';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: queued
                  ? null
                  : effectiveProgress >= 0.05
                      ? effectiveProgress
                      : null,
              strokeWidth: 2,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: iconColor),
          ),
          const SizedBox(width: 2),
          IconButton(
            onPressed: _cancel,
            tooltip: 'Cancel',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            iconSize: 16,
            icon: Icon(Icons.close, color: cs.error),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = widget.textColor.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Image generation failed',
          child: Icon(Icons.error_outline, size: 14, color: cs.error),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Retry',
          child: GestureDetector(
            onTap: _generate,
            child: Icon(Icons.refresh, size: 14, color: iconColor),
          ),
        ),
      ],
    );
  }
}

/// Displays generated images inline with a tap-for-fullscreen + regenerate option.
/// Supports multiple images from batch generation.
/// Used by message_bubble.dart to show images below the action row.
class GeneratedImageDisplay extends StatefulWidget {
  final String? imagePath; // Legacy single image path
  final List<String>? imagePaths; // Multiple image paths (batch)
  final VoidCallback? onRegenerate;

  const GeneratedImageDisplay({
    super.key,
    this.imagePath,
    this.imagePaths,
    this.onRegenerate,
  });

  @override
  State<GeneratedImageDisplay> createState() => _GeneratedImageDisplayState();
}

class _GeneratedImageDisplayState extends State<GeneratedImageDisplay> {
  List<String>? _resolvedPaths;

  @override
  void initState() {
    super.initState();
    _resolvePaths();
  }

  @override
  void didUpdateWidget(covariant GeneratedImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePaths != widget.imagePaths ||
        oldWidget.imagePath != widget.imagePath) {
      _resolvePaths();
    }
  }

  Future<void> _resolvePaths() async {
    List<String> rawPaths = [];
    if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
      rawPaths = widget.imagePaths!;
    } else if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      rawPaths = [widget.imagePath!];
    }

    if (rawPaths.isEmpty) {
      if (mounted) setState(() => _resolvedPaths = []);
      return;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final resolved = rawPaths.map((p) {
      final name = p.split('/').last;
      final newPath = '${docDir.path}/generated_images/$name';
      if (File(newPath).existsSync()) return newPath;
      return p;
    }).toList();

    if (mounted) setState(() => _resolvedPaths = resolved);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paths = _resolvedPaths;
    if (paths == null) return const SizedBox.shrink(); // Loading
    if (paths.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show images: single or horizontal scroll for batch
          if (paths.length == 1)
            _buildSingleImage(context, paths.first, cs)
          else
            _buildImageGrid(context, paths, cs),
          const SizedBox(height: 4),
          // Regenerate button (only if callback provided)
          if (widget.onRegenerate != null)
            Tooltip(
              message: 'Regenerate image',
              child: GestureDetector(
                onTap: widget.onRegenerate,
                child: Icon(Icons.image_outlined, size: 12, color: cs.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, String path, ColorScheme cs) {
    final file = File(path);
    if (!file.existsSync()) {
      return Text(
        'Media file not found',
        style: TextStyle(fontSize: 11, color: cs.error),
      );
    }

    return GestureDetector(
      onTap: () => _showFullscreen(context, path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 300,
            maxHeight: 300,
          ),
          child: isVideoFilePath(path)
              ? _InlineVideoTile(
                  key: ValueKey(path),
                  path: path,
                  errorPlaceholder: _buildErrorPlaceholder(cs),
                )
              : Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildErrorPlaceholder(cs),
                ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(
      BuildContext context, List<String> paths, ColorScheme cs) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final path = paths[index];
          final file = File(path);
          if (!file.existsSync()) {
            return SizedBox(
              width: 150,
              child: Center(
                child: Text('Media not found',
                    style: TextStyle(fontSize: 11, color: cs.error)),
              ),
            );
          }
          return GestureDetector(
            onTap: () => _showFullscreen(context, path),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                height: 200,
                child: isVideoFilePath(path)
                    ? _InlineVideoTile(
                        key: ValueKey(path),
                        path: path,
                        errorPlaceholder: _buildErrorPlaceholder(cs),
                      )
                    : Image.file(
                        file,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildErrorPlaceholder(cs),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorPlaceholder(ColorScheme cs) {
    return Container(
      width: 200,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Failed to load',
        style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
      ),
    );
  }

  void _showFullscreen(BuildContext context, String path) {
    showGeneratedMediaViewer(context, path);
  }
}

class _MediaViewerActions extends StatelessWidget {
  final String path;

  const _MediaViewerActions({required this.path});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: MediaGallery.savesToPhotos ? l10n.saveToPhotos : l10n.save,
          icon: const Icon(Icons.download_rounded),
          onPressed: () => saveMediaToGallery(context, path),
        ),
        IconButton(
          tooltip: l10n.share,
          icon: const Icon(Icons.share),
          onPressed: () => shareFileFromContext(context, path),
        ),
      ],
    );
  }
}

/// Fullscreen image or video viewer for generated media.
void showGeneratedMediaViewer(BuildContext context, String path) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => isVideoFilePath(path)
          ? _FullscreenVideo(videoPath: path)
          : _FullscreenImage(imagePath: path),
    ),
  );
}

/// Fullscreen image viewer with pinch-to-zoom.
class _FullscreenImage extends StatelessWidget {
  final String imagePath;
  const _FullscreenImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _MediaViewerActions(path: imagePath),
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}

/// Inline autoplaying (looped, muted) video preview — mimics an animated GIF.
/// Tap is handled by the parent to open the fullscreen player with sound.
class _InlineVideoTile extends StatefulWidget {
  final String path;
  final Widget errorPlaceholder;
  const _InlineVideoTile({
    super.key,
    required this.path,
    required this.errorPlaceholder,
  });

  @override
  State<_InlineVideoTile> createState() => _InlineVideoTileState();
}

class _InlineVideoTileState extends State<_InlineVideoTile> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(File(widget.path));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.errorPlaceholder;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        // Subtle badge so users know it's a tappable video with sound.
        Positioned(
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

/// Fullscreen video player with sound, play/pause, and looping.
class _FullscreenVideo extends StatefulWidget {
  final String videoPath;
  const _FullscreenVideo({required this.videoPath});

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(File(widget.videoPath));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _MediaViewerActions(path: widget.videoPath),
        ],
      ),
      body: Center(
        child: _failed
            ? const Text('Failed to play video',
                style: TextStyle(color: Colors.white))
            : (controller == null || !controller.value.isInitialized)
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: _togglePlay,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                        if (!controller.value.isPlaying)
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.white70, size: 72),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

/// Compact "ComfyUI details" control for Show Runtime Info.
class ComfyUiDetailsButton extends StatelessWidget {
  final String infoJson;
  final Color textColor;

  const ComfyUiDetailsButton({
    super.key,
    required this.infoJson,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetailsSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 14,
                color: textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.comfyUiDetails,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: textColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(infoJson);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final pretty = data.isEmpty
        ? infoJson
        : const JsonEncoder.withIndent('  ').convert(data);

    String? field(String key) {
      final v = data[key];
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    l10n.comfyUiDetailsTitle,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (field('prompt_id') != null)
                        _ComfyDetailChip(
                            label: 'prompt_id', value: field('prompt_id')!),
                      if (field('seed') != null)
                        _ComfyDetailChip(label: 'seed', value: field('seed')!),
                      if (field('workflow_path') != null)
                        _ComfyDetailChip(
                            label: 'workflow', value: field('workflow_path')!),
                      if (field('checkpoint') != null)
                        _ComfyDetailChip(
                            label: 'checkpoint', value: field('checkpoint')!),
                      if (field('lora_name') != null)
                        _ComfyDetailChip(
                          label: 'lora',
                          value:
                              '${field('lora_name')} @ ${field('lora_weight') ?? '1.0'}',
                        ),
                      if (field('steps') != null)
                        _ComfyDetailChip(
                            label: 'steps', value: field('steps')!),
                      if (field('width') != null && field('height') != null)
                        _ComfyDetailChip(
                          label: 'size',
                          value: '${field('width')}×${field('height')}',
                        ),
                    ],
                  ),
                  if (field('prompt') != null) ...[
                    const SizedBox(height: 12),
                    Text('Prompt',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.7))),
                    const SizedBox(height: 4),
                    SelectableText(field('prompt')!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Raw JSON',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: pretty));
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text(l10n.comfyUiDetailsCopied)),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(l10n.comfyUiDetailsCopy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      pretty,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ComfyDetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _ComfyDetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
