import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/arena_models.dart';
import '../models/arena_run.dart';
import '../models/local_model_spec.dart';
import '../pro/pro_features.dart';
import '../providers/arena_controller.dart';
import '../providers/settings_provider.dart';
import '../services/arena_prompt_set.dart';
import '../services/benchmark_service.dart';
import '../utils/response_parser.dart';
import '../widgets/glass_page_header.dart';
import '../widgets/home_glass_header.dart';
import 'arena_explainer_screen.dart';

/// The live Arena run: every contestant streams the same prompt(s) into its own
/// swipeable card with a sticky metrics strip. When the run finishes a winner
/// banner appears with a path to the full scoring breakdown.
class ArenaScreen extends StatefulWidget {
  final ArenaMode mode;
  final List<String> prompts;
  final String? promptSetId;
  final int? promptSetVersion;
  final List<ArenaContestant> contestants;
  final AppSettings settings;
  final ArenaSameProviderSchedule sameProviderSchedule;

  const ArenaScreen({
    super.key,
    required this.mode,
    required this.prompts,
    required this.contestants,
    required this.settings,
    this.promptSetId,
    this.promptSetVersion,
    this.sameProviderSchedule = ArenaSameProviderSchedule.parallel,
  });

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final ArenaController _controller;
  final PageController _pageController = PageController();
  int _page = 0;
  bool _saveHandled = false;
  String? _runId;

  @override
  void initState() {
    super.initState();
    _controller = ArenaController(
      mode: widget.mode,
      prompts: widget.prompts,
      promptSetId: widget.promptSetId,
      promptSetVersion: widget.promptSetVersion,
      settings: widget.settings,
      contestants: widget.contestants,
      sameProviderSchedule: widget.sameProviderSchedule,
    );
    _controller.addListener(_onControllerChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (_controller.isFinished && !_saveHandled && !_controller.isCancelled) {
      _saveHandled = true;
      _saveRun(sharePublic: true);
    }
  }

  Future<void> _saveRun({required bool sharePublic}) async {
    if (!mounted) return;
    final isPremium = SubscriptionService().isPremium;
    final settings = context.read<SettingsProvider>().settings;
    final device = _controller.device;
    _runId ??= 'arena_${DateTime.now().millisecondsSinceEpoch}';
    final setName = widget.promptSetId == ArenaPromptSet.quick.id
        ? ArenaPromptSet.quick.name
        : ArenaPromptSet.standard.name;
    final run = ArenaRun(
      id: _runId!,
      createdAt: _controller.startedAt ?? DateTime.now(),
      mode: widget.mode,
      promptLabel: widget.mode == ArenaMode.compare
          ? _controller.displayPrompt
          : setName,
      promptSetId: widget.promptSetId,
      promptSetVersion: widget.promptSetVersion,
      results: _controller.results,
      winnerId: _controller.winnerId,
      userPickId: _controller.userPickId,
      platform: BenchmarkService.platformName(),
      deviceName: device?.deviceName ?? 'Unknown device',
      deviceClass: device?.hwMachine ?? '',
      chip: device?.chipLabel.isNotEmpty == true
          ? device!.chipLabel
          : (device?.chip.name ?? ''),
      ramGb: device?.ramGb ?? 0,
      appVersion: '',
    );
    // Free races always contribute anonymized speed rows; Pro can opt out.
    final shareAnonymous =
        sharePublic && (isPremium ? settings.arenaShareAnonymousResults : true);
    await BenchmarkService.instance.saveRun(
      run,
      savePrivate: ProFeatures.isPro,
      shareAnonymous: shareAnonymous,
    );
  }

  void _onUserPick(String contestantId) {
    _controller.setUserPick(contestantId);
    // Re-save private history with the quality pick (public already uploaded).
    if (_saveHandled) {
      _saveRun(sharePublic: false);
    }
  }

  void _openResults() {
    final board = _controller.scoreboard;
    if (board == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArenaExplainerScreen(
          results: _controller.results,
          scoreboard: board,
          userPickId: _controller.userPickId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerH = GlassPageHeader.heightFor(context);
    final canvasBg =
        isDark ? const Color(0xFF080A0F) : theme.colorScheme.surface;
    final iconFg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.88);
    final title =
        widget.mode == ArenaMode.compare ? 'Your prompt' : 'Speed race';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: canvasBg,
        body: Stack(
          children: [
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final results = _controller.results;
                  return Padding(
                    padding: EdgeInsets.only(top: headerH),
                    child: Column(
                      children: [
                        _promptBar(context),
                        if (_controller.isFinished) _winnerBanner(context),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) => setState(() => _page = i),
                            itemCount: results.length,
                            itemBuilder: (context, i) => _ContestantCard(
                              result: results[i],
                              isWinner: _controller.winnerId ==
                                  results[i].contestant.id,
                              isUserPick: _controller.userPickId ==
                                  results[i].contestant.id,
                              showPickButton: _controller.isFinished,
                              onPick: () =>
                                  _onUserPick(results[i].contestant.id),
                            ),
                          ),
                        ),
                        if (results.length > 1) _dots(context, results.length),
                        if (_controller.isFinished) _resultsButton(context),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: GlassPageHeader(
                title: title,
                onBack: () => Navigator.pop(context),
                onLightCanvas: !isDark,
                actions: [
                  GlassCircleIconButton(
                    tooltip: 'What do these results mean?',
                    onTap: _showResultsHelp,
                    child: Icon(Icons.info_outline, size: 20, color: iconFg),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => _controller.isRunning
                        ? GlassCircleIconButton(
                            tooltip: 'Stop',
                            onTap: _controller.cancel,
                            child: Icon(Icons.stop_circle_outlined,
                                size: 20, color: iconFg),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResultsHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reading Arena results'),
        content: const SingleChildScrollView(
          child: Text(
            'Speed — how fast the model generates tokens after it starts answering.\n\n'
            'First token — time from “model ready” to the first word. '
            'Loading the model into memory is not included here.\n\n'
            'Load — how long it took to load weights into memory (when the server reports it). '
            'Already-loaded models often show —.\n\n'
            'Tokens — how much text was generated for this prompt.\n\n'
            'Fit — only for on-device models: whether this phone’s RAM can run that size comfortably '
            '(Good / Tight / Over). Desktop models show “Server” because fit is about your computer, not the phone.\n\n'
            'Faster on this run — automatic performance pick from speed + responsiveness. '
            '“Mark as best answer” is your quality pick.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _promptBar(BuildContext context) {
    final theme = Theme.of(context);
    final setLabel = widget.promptSetId == ArenaPromptSet.quick.id
        ? ArenaPromptSet.quick.name
        : ArenaPromptSet.standard.name;
    final label = widget.mode == ArenaMode.benchmark
        ? '$setLabel · ${widget.prompts.length} prompt${widget.prompts.length == 1 ? '' : 's'}'
        : _controller.displayPrompt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            widget.mode == ArenaMode.benchmark
                ? Icons.checklist_rtl
                : Icons.chat_bubble_outline,
            size: 16,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _winnerBanner(BuildContext context) {
    final theme = Theme.of(context);
    final winnerId = _controller.winnerId;
    if (winnerId == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        child: Text(
          'No winner — every model failed or was cancelled.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    final winner = _controller.resultFor(winnerId)!;
    final color = Color(winner.contestant.color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.08)
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Faster on this run',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
                Text(
                  '${winner.contestant.displayName} · ${winner.contestant.providerLabel}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            winner.metrics.formattedTps,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _dots(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == _page;
          final color = Color(_controller.results[i].contestant.color);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? color : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _resultsButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton.icon(
          onPressed: _openResults,
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('View results & scoring'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ),
    );
  }
}

/// A single contestant's swipeable card: header + spec chips, sticky metrics
/// strip, reasoning, and the streaming answer.
class _ContestantCard extends StatelessWidget {
  final ArenaContestantResult result;
  final bool isWinner;
  final bool isUserPick;
  final bool showPickButton;
  final VoidCallback onPick;

  const _ContestantCard({
    required this.result,
    required this.isWinner,
    required this.isUserPick,
    required this.showPickButton,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(result.contestant.color);
    final parsed = ResponseParser.parse(result.displayContent);
    final reasoning = result.reasoning.isNotEmpty
        ? result.reasoning
        : (parsed.thinking ?? '');
    // Arena races disable IMG_PROMPT instructions; still strip if present.
    final answer = parsed.answer
        .replaceAll(RegExp(r'\[IMG_PROMPT:\s*.+?\]', dotAll: true), '')
        .replaceAll(RegExp(r'\[IMG_PROMPT:[^\]]*$', dotAll: true), '')
        .trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? color : theme.colorScheme.outlineVariant,
          width: isWinner ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, color),
          _metricsStrip(context, color),
          const Divider(height: 1),
          Expanded(child: _body(context, theme, reasoning, answer)),
          if (showPickButton) _pickBar(context, color),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Color color) {
    final theme = Theme.of(context);
    final c = result.contestant;
    return Container(
      color: color.withValues(alpha: 0.10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.20),
                child:
                    Icon(_iconForKind(c.providerKind), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.displayName,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isWinner) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.emoji_events, size: 16, color: color),
                        ],
                      ],
                    ),
                    Text(c.providerLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              _statusChip(context),
            ],
          ),
          const SizedBox(height: 8),
          _specChips(context, color),
        ],
      ),
    );
  }

  Widget _specChips(BuildContext context, Color color) {
    final c = result.contestant;
    final theme = Theme.of(context);
    final chips = <String>[
      if (c.paramsLabel != null) c.paramsLabel!,
      if (c.quant != null && c.quant!.isNotEmpty) c.quant!,
      if (c.sizeLabel != null) c.sizeLabel!,
      if (c.arch != null && c.arch!.isNotEmpty) c.arch!,
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips
          .map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }

  Widget _statusChip(BuildContext context) {
    final theme = Theme.of(context);
    switch (result.status) {
      case ArenaContestantStatus.pending:
        return Text('Queued', style: theme.textTheme.bodySmall);
      case ArenaContestantStatus.streaming:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            if (result.promptCount > 1) ...[
              const SizedBox(height: 4),
              Text('${result.promptIndex + 1}/${result.promptCount}',
                  style: theme.textTheme.labelSmall),
            ],
          ],
        );
      case ArenaContestantStatus.done:
        return Icon(Icons.check_circle,
            size: 18, color: theme.colorScheme.primary);
      case ArenaContestantStatus.error:
        return Icon(Icons.error_outline,
            size: 18, color: theme.colorScheme.error);
      case ArenaContestantStatus.cancelled:
        return Icon(Icons.block, size: 18, color: theme.colorScheme.outline);
    }
  }

  Widget _metricsStrip(BuildContext context, Color color) {
    final m = result.metrics;
    return Container(
      color: color.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          _metric(context, 'Speed', m.formattedTps, Icons.speed, color),
          _metric(context, 'First token', m.formattedTtft, Icons.timer_outlined,
              color),
          _metric(
              context, 'Load', m.formattedLoad, Icons.hourglass_empty, color),
          _metric(context, 'Tokens', m.formattedTokens, Icons.numbers_outlined,
              color),
          _fitMetric(context, color),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _fitMetric(BuildContext context, Color color) {
    final theme = Theme.of(context);
    final fit = result.fit;
    // Fit is an on-device RAM check. Desktop backends are not "unfit" on phone.
    if (!result.contestant.isOnDevice || fit == null) {
      return _metric(
        context,
        'Fit',
        result.contestant.isOnDevice ? '—' : 'Server',
        Icons.memory_outlined,
        color,
      );
    }
    final (label, icon, c) = switch (fit) {
      ModelFit.runs => ('Good', Icons.check_circle_outline, Colors.green),
      ModelFit.tight => ('Tight', Icons.warning_amber_outlined, Colors.orange),
      ModelFit.blocked => ('Over', Icons.block, theme.colorScheme.error),
    };
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: c),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('Fit',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _body(
      BuildContext context, ThemeData theme, String reasoning, String answer) {
    if (result.status == ArenaContestantStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 32),
              const SizedBox(height: 10),
              Text(result.error ?? 'Failed to respond',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (!result.hasContent &&
        result.status == ArenaContestantStatus.streaming &&
        reasoning.isEmpty) {
      return const Center(child: Text('Thinking…'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      children: [
        if (reasoning.isNotEmpty) ...[
          _reasoningBlock(context, reasoning),
          const SizedBox(height: 12),
        ],
        if (answer.isNotEmpty)
          MarkdownBody(data: answer, selectable: true)
        else if (result.status == ArenaContestantStatus.streaming)
          const Text('…'),
      ],
    );
  }

  Widget _reasoningBlock(BuildContext context, String reasoning) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Icon(Icons.psychology_outlined,
            size: 18, color: theme.colorScheme.outline),
        title: Text('Reasoning', style: theme.textTheme.bodySmall),
        children: [
          Text(reasoning,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _pickBar(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: isUserPick
                ? FilledButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.thumb_up, size: 18),
                    label: const Text('Your best answer'),
                    style: FilledButton.styleFrom(backgroundColor: color),
                  )
                : OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.thumb_up_outlined, size: 18),
                    label: const Text('Mark as best answer'),
                  ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForKind(String kind) {
    switch (kind) {
      case 'onDeviceGguf':
      case 'onDeviceMlx':
        return Icons.smartphone;
      case 'ollama':
        return Icons.terminal;
      case 'omlx':
        return Icons.memory;
      case 'jan':
        return Icons.bolt_rounded;
      case 'unsloth':
        return Icons.science_rounded;
      case 'cloud':
        return Icons.cloud_outlined;
      default:
        return Icons.dns_outlined;
    }
  }
}
