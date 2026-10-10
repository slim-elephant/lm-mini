import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';
import '../utils/streaming_phase.dart';

/// Watches [ChatProvider] so stacked phases update without waiting for tokens.
class FullWidthStreamingStatusHost extends StatelessWidget {
  final double fontSize;

  const FullWidthStreamingStatusHost({
    super.key,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = context.select<ChatProvider, ({int n, String last})>(
      (p) {
        final log = p.streamingPhaseLog;
        return (
          n: log.length,
          last: log.isEmpty ? '' : log.last,
        );
      },
    );
    if (snapshot.n == 0) {
      return FullWidthStreamingStatus(
        phases: const [StreamingPhase.processingPrompt],
        fontSize: fontSize,
      );
    }
    final phases = context.read<ChatProvider>().streamingPhaseLog;
    return FullWidthStreamingStatus(
      phases: phases,
      fontSize: fontSize,
    );
  }
}

/// ChatGPT-style stacked status: completed lines stay, the current line shimmers.
class FullWidthStreamingStatus extends StatelessWidget {
  final List<String> phases;
  final double fontSize;

  const FullWidthStreamingStatus({
    super.key,
    required this.phases,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < phases.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _PhaseLine(
              label: _labelFor(l10n, phases[i]),
              fontSize: fontSize,
              active: i == phases.length - 1,
              base: base,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  static String _labelFor(AppLocalizations l10n, String phase) {
    switch (phase) {
      case StreamingPhase.loadingModel:
        return l10n.streamingPhaseLoadingModel;
      case StreamingPhase.processingPrompt:
        return l10n.streamingPhaseProcessingPrompt;
      case StreamingPhase.thinking:
        return l10n.streamingPhaseThinking;
      case StreamingPhase.writing:
        return l10n.streamingPhaseWriting;
      case StreamingPhase.searching:
        return l10n.streamingPhaseSearching;
      case StreamingPhase.usingTools:
        return l10n.streamingPhaseUsingTools;
      default:
        if (StreamingPhase.isConnecting(phase)) {
          return l10n.streamingPhaseConnecting(
            StreamingPhase.connectingTarget(phase),
          );
        }
        return phase;
    }
  }
}

class _PhaseLine extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool active;
  final Color base;
  final bool isDark;

  const _PhaseLine({
    required this.label,
    required this.fontSize,
    required this.active,
    required this.base,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: -0.2,
    );
    if (!active) {
      return Text(
        label,
        style: style.copyWith(color: base.withValues(alpha: 0.38)),
      );
    }
    return _ShimmerText(
      text: label,
      style: style,
      base: base,
      isDark: isDark,
    );
  }
}

class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color base;
  final bool isDark;

  const _ShimmerText({
    required this.text,
    required this.style,
    required this.base,
    required this.isDark,
  });

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.6 + 3.2 * t, 0),
              end: Alignment(-0.4 + 3.2 * t, 0),
              colors: [
                widget.base.withValues(alpha: 0.28),
                widget.base.withValues(alpha: 0.72),
                (widget.isDark ? Colors.white : widget.base)
                    .withValues(alpha: widget.isDark ? 0.98 : 0.92),
                widget.base.withValues(alpha: 0.72),
                widget.base.withValues(alpha: 0.28),
              ],
              stops: const [0.0, 0.32, 0.5, 0.68, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: widget.style.copyWith(color: Colors.white),
      ),
    );
  }
}
