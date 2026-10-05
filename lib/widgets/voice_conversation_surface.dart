import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Scrollable live transcript — shows ~[visibleLines] of text and auto-scrolls
/// as the user or assistant speaks.
class VoiceTranscriptViewport extends StatefulWidget {
  const VoiceTranscriptViewport({
    super.key,
    required this.scrollController,
    this.userText,
    this.assistantText,
    this.visibleLines = 4,
    this.showUserLiveIndicator = false,
  });

  final ScrollController scrollController;
  final String? userText;
  final String? assistantText;
  final int visibleLines;
  final bool showUserLiveIndicator;

  @override
  State<VoiceTranscriptViewport> createState() =>
      _VoiceTranscriptViewportState();
}

class _VoiceTranscriptViewportState extends State<VoiceTranscriptViewport> {
  @override
  void didUpdateWidget(covariant VoiceTranscriptViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userText != widget.userText ||
        oldWidget.assistantText != widget.assistantText) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollController.hasClients) return;
      final max = widget.scrollController.position.maxScrollExtent;
      if (max <= 0) return;
      widget.scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  double _lineHeight(ThemeData theme) {
    final style = theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    return (style.fontSize ?? 16) * (style.height ?? 1.45);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineHeight = _lineHeight(theme);
    final viewportHeight = lineHeight * widget.visibleLines + 20;

    final user = widget.userText?.trim() ?? '';
    final assistant = widget.assistantText?.trim() ?? '';
    final hasUser = user.isNotEmpty;
    final hasAssistant = assistant.isNotEmpty;

    if (!hasUser && !hasAssistant) {
      return SizedBox(height: viewportHeight * 0.55);
    }

    final textStyle = theme.textTheme.bodyLarge!.copyWith(
      height: 1.45,
      fontSize: 16,
    );

    return SizedBox(
      height: viewportHeight,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.06, 0.94, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasAssistant)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.88,
                    ),
                    child: Text(
                      assistant,
                      style: textStyle.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.88),
                      ),
                    ),
                  ),
                ),
              if (hasAssistant && hasUser) const SizedBox(height: 14),
              if (hasUser)
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.88,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.14),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              user,
                              style: textStyle.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (widget.showUserLiveIndicator) ...[
                            const SizedBox(width: 8),
                            _LiveMicDot(color: theme.colorScheme.primary),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveMicDot extends StatefulWidget {
  final Color color;
  const _LiveMicDot({required this.color});

  @override
  State<_LiveMicDot> createState() => _LiveMicDotState();
}

class _LiveMicDotState extends State<_LiveMicDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// ChatGPT-style central voice orb with soft ripples and waveform ring.
class VoiceConversationOrb extends StatelessWidget {
  const VoiceConversationOrb({
    super.key,
    required this.animation,
    required this.waveAnimation,
    required this.size,
    required this.soundLevel,
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
    required this.baseColor,
    this.onTap,
    this.onLongPress,
  });

  final Animation<double> animation;
  final Animation<double> waveAnimation;
  final double size;
  final double soundLevel;
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final Color baseColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: Listenable.merge([animation, waveAnimation]),
          builder: (context, child) {
            final active = isListening || isSpeaking || isProcessing;
            final level = soundLevel.clamp(0.0, 10.0) / 10.0;
            double pulse = 1.0;
            if (isListening) {
              pulse = 1.0 + level * 0.18;
            } else if (isSpeaking) {
              pulse = 0.92 + animation.value * 0.12;
            } else if (isProcessing) {
              pulse = 1.0 + math.sin(animation.value * math.pi * 2) * 0.04;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                if (active) ...[
                  _RippleRing(
                    diameter: size * (0.92 + level * 0.08),
                    opacity: 0.12 + level * 0.1,
                    color: baseColor,
                  ),
                  _RippleRing(
                    diameter: size * (1.08 + level * 0.12),
                    opacity: 0.07 + level * 0.06,
                    color: baseColor,
                  ),
                ],
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: size * 0.62,
                    height: size * 0.62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          baseColor.withOpacity(0.95),
                          baseColor,
                          baseColor.withOpacity(0.82),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(active ? 0.45 : 0.18),
                          blurRadius: active ? 36 : 18,
                          spreadRadius: active ? 6 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isListening
                          ? _WaveformRing(
                              level: level,
                              color: Colors.white.withOpacity(0.9),
                              phase: waveAnimation.value,
                            )
                          : isProcessing
                              ? SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                )
                              : Icon(
                                  isSpeaking
                                      ? Icons.graphic_eq_rounded
                                      : Icons.mic_none_rounded,
                                  color: Colors.white.withOpacity(0.92),
                                  size: size * 0.22,
                                ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  final double diameter;
  final double opacity;
  final Color color;

  const _RippleRing({
    required this.diameter,
    required this.opacity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(opacity), width: 1.5),
      ),
    );
  }
}

class _WaveformRing extends StatelessWidget {
  final double level;
  final Color color;
  final double phase;

  const _WaveformRing({
    required this.level,
    required this.color,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final h = 6.0 +
            math.sin(phase * math.pi * 2 + i * 0.9) * 5 * level +
            level * 12;
        return Container(
          width: 3,
          height: h.clamp(4.0, 22.0),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

/// Soft frosted backdrop for voice conversation surfaces.
///
/// Flat translucent fill (no top→bottom dark wash) so chat wallpaper shows
/// through evenly — same glass language as empty-chat starter cards.
BoxDecoration voiceConversationDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark
        ? const Color(0xFF1A1428).withValues(alpha: 0.38)
        : Colors.white.withValues(alpha: 0.48),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    border: Border(
      top: BorderSide(
        color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.72),
      ),
    ),
  );
}

String voiceConversationHint(
  AppLocalizations l10n, {
  required bool idle,
  required bool listening,
  required bool processing,
  required bool speaking,
  /// When [listening] is true but the mic has not started capturing yet,
  /// show a "warming up" hint so the user doesn't speak into a dead mic.
  bool micWarmingUp = false,
}) {
  if (listening) {
    return micWarmingUp
        ? l10n.voiceConvoHintStarting
        : l10n.voiceConvoHintListening;
  }
  if (processing) return l10n.voiceConvoHintProcessing;
  if (speaking) return l10n.voiceConvoHintSpeaking;
  return l10n.voiceConvoHintIdle;
}

Color voiceConversationAccent(
  ColorScheme scheme, {
  required bool listening,
  required bool processing,
  required bool speaking,
}) {
  if (listening) return scheme.primary;
  if (processing) return scheme.tertiary;
  if (speaking) return scheme.secondary;
  return scheme.primary.withOpacity(0.75);
}
