import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import 'composer_shine_border.dart';
import 'think_brain_icon.dart';

/// A widget that displays the model's thinking/reasoning process during streaming.
/// Shows full content with auto-scrolling and can be expanded/collapsed.
class StreamingThinkingIndicator extends StatefulWidget {
  final String status;
  final double? progress;
  final bool isInReasoningMode;
  final String? reasoningContent;
  final bool isModelLoading;

  const StreamingThinkingIndicator({
    super.key,
    required this.status,
    this.progress,
    this.isInReasoningMode = false,
    this.reasoningContent,
    this.isModelLoading = false,
  });

  @override
  State<StreamingThinkingIndicator> createState() =>
      _StreamingThinkingIndicatorState();
}

class _StreamingThinkingIndicatorState extends State<StreamingThinkingIndicator>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // Static so the collapse/expand state persists across widget rebuilds and new messages
  static bool _persistedIsExpanded = true;
  bool _userScrolled = false;
  late AnimationController _dotsAnimationController;

  bool get _isExpanded => _persistedIsExpanded;
  set _isExpanded(bool value) => _persistedIsExpanded = value;

  @override
  void initState() {
    super.initState();
    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(StreamingThinkingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new content arrives (if user hasn't manually scrolled up)
    if (widget.reasoningContent != oldWidget.reasoningContent &&
        !_userScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _dotsAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedDots(Color color) {
    return AnimatedBuilder(
      animation: _dotsAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = (_dotsAnimationController.value + delay) % 1.0;
            final opacity =
                (animValue < 0.5) ? (animValue * 2) : (2 - animValue * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: 0.3 + (opacity * 0.7),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildHeaderRow({
    required ColorScheme colorScheme,
    required Color statusColor,
    required bool hasReasoning,
  }) {
    return InkWell(
      onTap: hasReasoning
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (widget.progress != null && !widget.isInReasoningMode) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isModelLoading
                        ? Colors.orange
                        : colorScheme.primary,
                  ),
                ),
              ),
            ] else if (widget.isInReasoningMode) ...[
              ThinkBrainIcon(
                size: 16,
                color: colorScheme.primary,
              ),
            ] else ...[
              _buildAnimatedDots(colorScheme.primary),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.status,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            if (hasReasoning) ...[
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: statusColor.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningBody(ColorScheme colorScheme) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.dragDetails != null) {
            _userScrolled = true;
          }
        }
        if (notification is ScrollEndNotification) {
          if (_scrollController.hasClients &&
              _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 10) {
            _userScrolled = false;
          }
        }
        return false;
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 150),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                widget.reasoningContent!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasReasoning =
        widget.reasoningContent != null && widget.reasoningContent!.isNotEmpty;
    final useModernChrome =
        !context.watch<SettingsProvider>().settings.useLegacyComposer;

    if (!useModernChrome) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          border: Border(
            top: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderRow(
              colorScheme: colorScheme,
              statusColor: colorScheme.onPrimaryContainer,
              hasReasoning: hasReasoning,
            ),
            if (hasReasoning && _isExpanded) _buildReasoningBody(colorScheme),
          ],
        ),
      );
    }

    // Shine chrome: inset card that matches the composer language.
    final panelBg =
        isDark ? const Color(0xFF141820) : colorScheme.surfaceContainerHighest;
    final shineColor =
        isDark ? const Color(0xFF9B87F5) : colorScheme.primary;
    final statusColor =
        colorScheme.onSurface.withValues(alpha: isDark ? 0.88 : 0.82);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: CustomPaint(
        foregroundPainter: ComposerShineBorder(
          color: shineColor,
          radius: 16,
          wrapBottomCorners: true,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderRow(
                colorScheme: colorScheme,
                statusColor: statusColor,
                hasReasoning: hasReasoning,
              ),
              if (hasReasoning && _isExpanded) _buildReasoningBody(colorScheme),
            ],
          ),
        ),
      ),
    );
  }
}
