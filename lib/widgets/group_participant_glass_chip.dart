import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/group_chat_participant.dart';
import '../utils/image_picker_helper.dart';
import 'glass_blur.dart';

/// Frosted participant chip matching empty-chat scrolling prompt pills.
class GroupParticipantGlassChip extends StatefulWidget {
  final GroupChatParticipant participant;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Soft pulse + glow to draw attention (manual-mode Ask nudge).
  final bool nudge;

  /// Visually muted + non-tappable (busy / same-provider lock).
  final bool disabled;

  const GroupParticipantGlassChip({
    super.key,
    required this.participant,
    this.onPressed,
    this.onLongPress,
    this.nudge = false,
    this.disabled = false,
  });

  @override
  State<GroupParticipantGlassChip> createState() =>
      _GroupParticipantGlassChipState();
}

class _GroupParticipantGlassChipState extends State<GroupParticipantGlassChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.nudge && !widget.disabled) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GroupParticipantGlassChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse = widget.nudge && !widget.disabled;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.participant.color != null
        ? Color(widget.participant.color!)
        : cs.primary;
    final resolvedAvatar = widget.participant.avatarPath != null
        ? ImagePickerHelper.resolveImagePathSync(widget.participant.avatarPath!)
        : null;

    final fill = isDark
        ? const Color(0xFF1A1428).withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.58);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.85);
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.94)
        : cs.onSurface.withValues(alpha: 0.92);

    Widget chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.disabled ? null : widget.onPressed,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(999),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: GlassBlur(
            sigmaX: 22,
            sigmaY: 22,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t =
                    (widget.nudge && !widget.disabled) ? _pulse.value : 0.0;
                final glow = accent.withValues(alpha: 0.18 + 0.28 * t);
                return Opacity(
                  opacity: widget.disabled ? 0.45 : 1,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.nudge && !widget.disabled
                            ? Color.lerp(border, accent, 0.45 + 0.4 * t)!
                            : border,
                        width: widget.nudge && !widget.disabled ? 1.4 : 0.8,
                      ),
                      boxShadow: [
                        if (widget.nudge && !widget.disabled)
                          BoxShadow(
                            color: glow,
                            blurRadius: 10 + 8 * t,
                            spreadRadius: 0.5 + t,
                          ),
                        if (isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: accent.withValues(alpha: 0.85),
                    backgroundImage: resolvedAvatar != null
                        ? FileImage(File(resolvedAvatar))
                        : null,
                    child: resolvedAvatar == null
                        ? Text(
                            widget.participant.displayName.isNotEmpty
                                ? widget.participant.displayName[0]
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.participant.displayName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      fontSize: 13.5,
                      height: 1.15,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.nudge || widget.disabled) return chip;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1.0 + 0.045 * math.sin(_pulse.value * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
      child: chip,
    );
  }
}
