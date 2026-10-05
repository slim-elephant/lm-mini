import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/app_localizations.dart';
import 'glass_blur.dart';

enum ScrollingPromptAction {
  sendPrompt,
  pickFile,
  pickImage,
  takePhoto,
  transcribe,
  generatePersona,
}

class _PromptItem {
  final String label;
  final String? prompt;
  final IconData icon;
  final Color accent;
  final ScrollingPromptAction action;

  const _PromptItem({
    required this.label,
    required this.icon,
    required this.accent,
    this.prompt,
    this.action = ScrollingPromptAction.sendPrompt,
  });
}

/// Auto-scrolling, staggered suggestion cards for an empty new chat.
///
/// Order is shuffled every time this widget is created (new empty chat / reopen).
/// Marquee uses a measured cycle + [Transform] so it loops seamlessly.
class ScrollingPromptCards extends StatefulWidget {
  final ValueChanged<String> onPromptSelected;
  final VoidCallback? onPickFile;
  final VoidCallback? onPickImage;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onTranscribe;
  final VoidCallback? onGeneratePersona;
  final bool enabled;
  final bool showImageAction;

  const ScrollingPromptCards({
    super.key,
    required this.onPromptSelected,
    this.onPickFile,
    this.onPickImage,
    this.onTakePhoto,
    this.onTranscribe,
    this.onGeneratePersona,
    this.enabled = true,
    this.showImageAction = true,
  });

  /// Open-ended prompts — cursor lands at the end so the user can finish typing.
  static List<_PromptItem> _promptsFor(AppLocalizations l10n) => [
        _PromptItem(
          label: l10n.promptWriteEmail,
          prompt: l10n.promptWriteEmailBody,
          icon: Icons.mail_outline_rounded,
          accent: const Color(0xFFE89BB5),
        ),
        _PromptItem(
          label: l10n.promptGiveIdeas,
          prompt: l10n.promptGiveIdeasBody,
          icon: Icons.lightbulb_outline_rounded,
          accent: const Color(0xFFB39DDB),
        ),
        _PromptItem(
          label: l10n.promptExplainSimply,
          prompt: l10n.promptExplainSimplyBody,
          icon: Icons.menu_book_outlined,
          accent: const Color(0xFF90CAF9),
        ),
        _PromptItem(
          label: l10n.promptFixWriting,
          prompt: l10n.promptFixWritingBody,
          icon: Icons.edit_outlined,
          accent: const Color(0xFF80CBC4),
        ),
        _PromptItem(
          label: l10n.promptHelpStudy,
          prompt: l10n.promptHelpStudyBody,
          icon: Icons.school_outlined,
          accent: const Color(0xFFFFAB91),
        ),
        _PromptItem(
          label: l10n.promptPlanTrip,
          prompt: l10n.promptPlanTripBody,
          icon: Icons.luggage_outlined,
          accent: const Color(0xFFF48FB1),
        ),
        _PromptItem(
          label: l10n.promptSummarize,
          prompt: l10n.promptSummarizeBody,
          icon: Icons.notes_rounded,
          accent: const Color(0xFFA5D6A7),
        ),
        _PromptItem(
          label: l10n.promptChecklist,
          prompt: l10n.promptChecklistBody,
          icon: Icons.checklist_rounded,
          accent: const Color(0xFFFFCC80),
        ),
        _PromptItem(
          label: l10n.promptFunFact,
          prompt: l10n.promptFunFactBody,
          icon: Icons.auto_awesome_outlined,
          accent: const Color(0xFF81D4FA),
        ),
        _PromptItem(
          label: l10n.promptQuizMe,
          prompt: l10n.promptQuizMeBody,
          icon: Icons.quiz_outlined,
          accent: const Color(0xFFCE93D8),
        ),
        _PromptItem(
          label: l10n.promptRoleplay,
          prompt: l10n.promptRoleplayBody,
          icon: Icons.theater_comedy_outlined,
          accent: const Color(0xFFEF9A9A),
        ),
        _PromptItem(
          label: l10n.promptCodeHelp,
          prompt: l10n.promptCodeHelpBody,
          icon: Icons.code_rounded,
          accent: const Color(0xFF9FA8DA),
        ),
        _PromptItem(
          label: l10n.promptDraftReply,
          prompt: l10n.promptDraftReplyBody,
          icon: Icons.reply_rounded,
          accent: const Color(0xFF80DEEA),
        ),
        _PromptItem(
          label: l10n.promptPracticeInterview,
          prompt: l10n.promptPracticeInterviewBody,
          icon: Icons.work_outline_rounded,
          accent: const Color(0xFFFFD54F),
        ),
        _PromptItem(
          label: l10n.promptMealIdeas,
          prompt: l10n.promptMealIdeasBody,
          icon: Icons.restaurant_outlined,
          accent: const Color(0xFFFF8A65),
        ),
        _PromptItem(
          label: l10n.promptWorkoutPlan,
          prompt: l10n.promptWorkoutPlanBody,
          icon: Icons.fitness_center_rounded,
          accent: const Color(0xFFAED581),
        ),
        _PromptItem(
          label: l10n.promptTranslateCasually,
          prompt: l10n.promptTranslateCasuallyBody,
          icon: Icons.translate_rounded,
          accent: const Color(0xFF64B5F6),
        ),
        _PromptItem(
          label: l10n.promptNameIdeas,
          prompt: l10n.promptNameIdeasBody,
          icon: Icons.badge_outlined,
          accent: const Color(0xFFF06292),
        ),
        _PromptItem(
          label: l10n.promptProsCons,
          prompt: l10n.promptProsConsBody,
          icon: Icons.balance_rounded,
          accent: const Color(0xFFBA68C8),
        ),
        _PromptItem(
          label: l10n.promptRewriteShorter,
          prompt: l10n.promptRewriteShorterBody,
          icon: Icons.compress_rounded,
          accent: const Color(0xFF4DB6AC),
        ),
        _PromptItem(
          label: l10n.promptTeachVocab,
          prompt: l10n.promptTeachVocabBody,
          icon: Icons.language_rounded,
          accent: const Color(0xFF7986CB),
        ),
        _PromptItem(
          label: l10n.promptStoryTime,
          prompt: l10n.promptStoryTimeBody,
          icon: Icons.auto_stories_outlined,
          accent: const Color(0xFFFFB74D),
        ),
        _PromptItem(
          label: l10n.promptDebugWithMe,
          prompt: l10n.promptDebugWithMeBody,
          icon: Icons.bug_report_outlined,
          accent: const Color(0xFFE57373),
        ),
        _PromptItem(
          label: l10n.promptDailyMotivation,
          prompt: l10n.promptDailyMotivationBody,
          icon: Icons.favorite_border_rounded,
          accent: const Color(0xFFFF8A80),
        ),
        // Lightweight games small models handle well — short turns, clear rules.
        _PromptItem(
          label: l10n.promptPlayDnd,
          prompt: l10n.promptPlayDndBody,
          icon: Icons.casino_outlined,
          accent: const Color(0xFFE040FB),
        ),
        // No arb key for 20 Questions yet — keep English until keys exist.
        const _PromptItem(
          label: '20 Questions',
          prompt:
              'Let\'s play 20 Questions. You think of something and I ask yes/no questions. Start by confirming you\'re ready, then I\'ll ask. Category: ',
          icon: Icons.psychology_alt_outlined,
          accent: Color(0xFF7C4DFF),
        ),
        _PromptItem(
          label: l10n.promptWordChain,
          prompt: l10n.promptWordChainBody,
          icon: Icons.link_rounded,
          accent: const Color(0xFF00BFA5),
        ),
        _PromptItem(
          label: l10n.promptRiddleDuel,
          prompt: l10n.promptRiddleDuelBody,
          icon: Icons.extension_outlined,
          accent: const Color(0xFFFFAB40),
        ),
        _PromptItem(
          label: l10n.promptWouldYouRather,
          prompt: l10n.promptWouldYouRatherBody,
          icon: Icons.swipe_rounded,
          accent: const Color(0xFF40C4FF),
        ),
        _PromptItem(
          label: l10n.promptEscapeRoom,
          prompt: l10n.promptEscapeRoomBody,
          icon: Icons.lock_open_rounded,
          accent: const Color(0xFFFF7043),
        ),
        _PromptItem(
          label: l10n.promptTriviaBattle,
          prompt: l10n.promptTriviaBattleBody,
          icon: Icons.emoji_events_outlined,
          accent: const Color(0xFFFFD54F),
        ),
        _PromptItem(
          label: l10n.promptStoryRpg,
          prompt: l10n.promptStoryRpgBody,
          icon: Icons.map_outlined,
          accent: const Color(0xFFAB47BC),
        ),
        _PromptItem(
          label: l10n.promptGuessNumber,
          prompt: l10n.promptGuessNumberBody,
          icon: Icons.pin_outlined,
          accent: const Color(0xFF66BB6A),
        ),
        _PromptItem(
          label: l10n.promptTwoTruths,
          prompt: l10n.promptTwoTruthsBody,
          icon: Icons.visibility_outlined,
          accent: const Color(0xFF5C6BC0),
        ),
      ];

  static _PromptItem _readFileFor(AppLocalizations l10n) => _PromptItem(
        label: l10n.promptReadMyFile,
        icon: Icons.insert_drive_file_outlined,
        accent: const Color(0xFF7E57C2),
        action: ScrollingPromptAction.pickFile,
      );

  static _PromptItem _whatIsImageFor(AppLocalizations l10n) => _PromptItem(
        label: l10n.promptWhatIsImage,
        prompt: 'What is this image? ',
        icon: Icons.image_outlined,
        accent: const Color(0xFF42A5F5),
        action: ScrollingPromptAction.pickImage,
      );

  static _PromptItem _takePhotoFor(AppLocalizations l10n) => _PromptItem(
        label: l10n.promptTakePhoto,
        icon: Icons.photo_camera_outlined,
        accent: const Color(0xFF26A69A),
        action: ScrollingPromptAction.takePhoto,
      );

  static _PromptItem _transcribeAudioFor(AppLocalizations l10n) => _PromptItem(
        label: l10n.promptTranscribeAudio,
        icon: Icons.graphic_eq_rounded,
        accent: const Color(0xFFAB47BC),
        action: ScrollingPromptAction.transcribe,
      );

  static _PromptItem _generatePersonaFor(AppLocalizations l10n) => _PromptItem(
        label: l10n.promptPersonaGenerator,
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFF7C4DFF),
        action: ScrollingPromptAction.generatePersona,
      );

  @override
  State<ScrollingPromptCards> createState() => _ScrollingPromptCardsState();
}

class _ScrollingPromptCardsState extends State<ScrollingPromptCards> {
  late List<_PromptItem> _row1;
  late List<_PromptItem> _row2;
  late List<_PromptItem> _row3;
  late double _phase1;
  late double _phase2;
  late double _phase3;
  bool _rowsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_rowsReady) {
      _rowsReady = true;
      _reshuffle(AppLocalizations.of(context));
    }
  }

  void _reshuffle(AppLocalizations l10n) {
    final rng = math.Random();
    final shuffled =
        List<_PromptItem>.from(ScrollingPromptCards._promptsFor(l10n))
          ..shuffle(rng);

    final rows = List.generate(3, (_) => <_PromptItem>[]);
    for (var i = 0; i < shuffled.length; i++) {
      rows[i % 3].add(shuffled[i]);
    }

    void insertAction(List<_PromptItem> row, _PromptItem action) {
      final idx = rng.nextInt(row.length + 1);
      row.insert(idx, action);
    }

    insertAction(rows[0], ScrollingPromptCards._generatePersonaFor(l10n));
    insertAction(rows[0], ScrollingPromptCards._readFileFor(l10n));
    if (widget.showImageAction) {
      insertAction(rows[1], ScrollingPromptCards._whatIsImageFor(l10n));
      insertAction(rows[1], ScrollingPromptCards._takePhotoFor(l10n));
    }
    insertAction(rows[1], ScrollingPromptCards._transcribeAudioFor(l10n));

    _row1 = rows[0];
    _row2 = rows[1];
    _row3 = rows[2];
    _phase1 = rng.nextDouble() * 200;
    _phase2 = rng.nextDouble() * 200;
    _phase3 = rng.nextDouble() * 200;
  }

  void _handleTap(_PromptItem item) {
    if (!widget.enabled) return;
    switch (item.action) {
      case ScrollingPromptAction.sendPrompt:
        final prompt = item.prompt;
        if (prompt != null) widget.onPromptSelected(prompt);
      case ScrollingPromptAction.pickFile:
        widget.onPickFile?.call();
      case ScrollingPromptAction.pickImage:
        final prompt = item.prompt;
        if (prompt != null) widget.onPromptSelected(prompt);
        widget.onPickImage?.call();
      case ScrollingPromptAction.takePhoto:
        widget.onTakePhoto?.call();
      case ScrollingPromptAction.transcribe:
        widget.onTranscribe?.call();
      case ScrollingPromptAction.generatePersona:
        widget.onGeneratePersona?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_rowsReady) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            stops: [0.0, 0.08, 0.92, 1.0],
          ).createShader(bounds);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MarqueePromptRow(
              items: _row1,
              speed: 24,
              reverse: false,
              initialPhase: _phase1,
              enabled: widget.enabled,
              onSelected: _handleTap,
            ),
            const SizedBox(height: 10),
            _MarqueePromptRow(
              items: _row2,
              speed: 20,
              reverse: true,
              initialPhase: _phase2,
              enabled: widget.enabled,
              onSelected: _handleTap,
            ),
            const SizedBox(height: 10),
            _MarqueePromptRow(
              items: _row3,
              speed: 28,
              reverse: false,
              initialPhase: _phase3,
              enabled: widget.enabled,
              onSelected: _handleTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarqueePromptRow extends StatefulWidget {
  final List<_PromptItem> items;
  final double speed;
  final bool reverse;
  final double initialPhase;
  final bool enabled;
  final ValueChanged<_PromptItem> onSelected;

  const _MarqueePromptRow({
    required this.items,
    required this.speed,
    required this.reverse,
    required this.initialPhase,
    required this.enabled,
    required this.onSelected,
  });

  @override
  State<_MarqueePromptRow> createState() => _MarqueePromptRowState();
}

class _MarqueePromptRowState extends State<_MarqueePromptRow>
    with SingleTickerProviderStateMixin {
  static const _gap = 10.0;

  final GlobalKey _measureKey = GlobalKey();

  /// Raw [Ticker] keeps moving even when system animator scale is 0
  /// (Android "Remove animations" / battery saver) — AnimationController often stalls there.
  late final Ticker _ticker;

  double _cycleWidth = 0;
  double _offset = 0;
  Duration _lastTick = Duration.zero;
  bool _paused = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialPhase;
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCycle());
  }

  @override
  void didUpdateWidget(covariant _MarqueePromptRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) &&
        oldWidget.items.length != widget.items.length) {
      _cycleWidth = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureCycle());
    }
    _syncTicker();
  }

  void _measureCycle() {
    if (!mounted) return;
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width < 8) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureCycle());
      return;
    }
    final next = box.size.width + _gap;
    if ((next - _cycleWidth).abs() > 0.5) {
      setState(() => _cycleWidth = next);
    }
    _lastTick = Duration.zero;
    _syncTicker();
  }

  void _syncTicker() {
    final shouldRun =
        mounted && widget.enabled && !_paused && !_dragging && _cycleWidth > 1;
    if (shouldRun) {
      if (!_ticker.isActive) {
        _lastTick = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (_paused || _dragging || !widget.enabled || _cycleWidth <= 1) return;

    final dtMs = (elapsed - _lastTick).inMicroseconds / 1000.0;
    _lastTick = elapsed;
    if (dtMs <= 0 || dtMs > 64) return;

    final delta = widget.speed * (dtMs / 1000.0);
    setState(() {
      _offset += widget.reverse ? -delta : delta;
      // Keep offset bounded so we never accumulate huge doubles.
      if (_offset > _cycleWidth * 1000 || _offset < -_cycleWidth * 1000) {
        _offset %= _cycleWidth;
      }
    });
  }

  double get _visualOffset {
    if (_cycleWidth <= 1) return 0;
    var o = _offset % _cycleWidth;
    if (o < 0) o += _cycleWidth;
    return o;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_cycleWidth <= 1) return;
    setState(() {
      // Dragging right reveals earlier chips (decrease offset).
      _offset -= details.delta.dx;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<Widget> _chipRow(List<_PromptItem> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(const SizedBox(width: _gap));
      final item = items[i];
      out.add(
        _PromptChip(
          item: item,
          enabled: widget.enabled,
          onTap: () => widget.onSelected(item),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return const SizedBox(height: 44);
        }

        // SizedBox = finite viewport. OverflowBox lets the chip strip be wider
        // without layout errors. ClipRect paints only the visible window.
        return SizedBox(
          height: 44,
          width: width,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              setState(() {
                _dragging = true;
                _paused = true;
              });
              _syncTicker();
            },
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: (_) {
              setState(() {
                _dragging = false;
                _paused = false;
              });
              _syncTicker();
            },
            onHorizontalDragCancel: () {
              setState(() {
                _dragging = false;
                _paused = false;
              });
              _syncTicker();
            },
            onTapDown: (_) {
              setState(() => _paused = true);
              _syncTicker();
            },
            onTapUp: (_) {
              setState(() => _paused = false);
              _syncTicker();
            },
            onTapCancel: () {
              setState(() => _paused = false);
              _syncTicker();
            },
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: width,
                maxWidth: double.infinity,
                minHeight: 44,
                maxHeight: 44,
                child: Transform.translate(
                  offset: Offset(-_visualOffset, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        key: _measureKey,
                        mainAxisSize: MainAxisSize.min,
                        children: _chipRow(widget.items),
                      ),
                      const SizedBox(width: _gap),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _chipRow(widget.items),
                      ),
                      const SizedBox(width: _gap),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _chipRow(widget.items),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PromptChip extends StatelessWidget {
  final _PromptItem item;
  final bool enabled;
  final VoidCallback onTap;

  const _PromptChip({
    required this.item,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = 999.0;
    final fill = isDark
        ? const Color(0xFF1A1428).withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.58);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.85);
    final iconColor = Color.lerp(
      item.accent,
      isDark ? Colors.white : cs.onSurface,
      isDark ? 0.2 : 0.25,
    )!;
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.94)
        : cs.onSurface.withValues(alpha: 0.92);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: GlassBlur(
            sigmaX: 22,
            sigmaY: 22,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border, width: 0.8),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
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
  }
}
