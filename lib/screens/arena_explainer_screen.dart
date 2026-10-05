import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../models/app_settings.dart';
import '../models/arena_models.dart';
import '../providers/settings_provider.dart';
import '../utils/remote_host_backends.dart';
import '../services/arena_scoring.dart';

/// "How we chose the winner" — a transparent breakdown of the objective
/// performance score, comparison charts, a spec comparison, the final ranking,
/// and the option to adopt the winner as the default model.
///
/// Works for both a live run and a saved run from history: it takes plain data
/// rather than a controller.
class ArenaExplainerScreen extends StatelessWidget {
  final List<ArenaContestantResult> results;
  final ArenaScoreboard scoreboard;
  final String? userPickId;

  /// When true, skip the AppBar for embedding in DesktopShell.
  final bool embedded;

  const ArenaExplainerScreen({
    super.key,
    required this.results,
    required this.scoreboard,
    this.userPickId,
    this.embedded = false,
  });

  ArenaContestantResult? _resultFor(String id) {
    for (final r in results) {
      if (r.contestant.id == id) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('Results & scoring')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _methodology(context),
          const SizedBox(height: 20),
          _MetricBars(
            title: 'Speed',
            subtitle: 'Tokens per second — higher is better',
            higherIsBetter: true,
            data: results
                .map((r) => _BarDatum(
                      label: r.contestant.displayName,
                      value: r.metrics.tokensPerSecond,
                      display: r.metrics.formattedTps,
                      color: Color(r.contestant.color),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          _MetricBars(
            title: 'Responsiveness',
            subtitle: 'Time to first token — lower is better',
            higherIsBetter: false,
            data: results
                .map((r) => _BarDatum(
                      label: r.contestant.displayName,
                      value: r.metrics.ttftMs,
                      display: r.metrics.formattedTtft,
                      color: Color(r.contestant.color),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _specComparison(context),
          const SizedBox(height: 20),
          Text('Ranking', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...scoreboard.ranked.asMap().entries.map((e) {
            final rank = e.key + 1;
            final score = e.value;
            final result = _resultFor(score.contestantId);
            if (result == null) return const SizedBox.shrink();
            return _scoreCard(
              context,
              rank: rank,
              score: score,
              result: result,
              isWinner: scoreboard.winnerId == score.contestantId,
              isUserPick: userPickId == score.contestantId,
            );
          }),
        ],
      ),
    );
  }

  Widget _methodology(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text('How the winner is chosen',
                  style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The winner is decided by an objective performance score (0–100). '
            'Each model is measured against the others on these factors:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...scoreboard.weights.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(e.key, style: theme.textTheme.bodyMedium),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: e.value,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        backgroundColor: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(e.value * 100).round()}%',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Answer quality is subjective, so it is never auto-judged. '
                    'Mark your own best answer back on the comparison cards.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specComparison(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Model specs', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < results.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(results[i].contestant.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(results[i].contestant.displayName,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text(results[i].contestant.specSummary,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _scoreCard(
    BuildContext context, {
    required int rank,
    required ArenaContestantScore score,
    required ArenaContestantResult result,
    required bool isWinner,
    required bool isUserPick,
  }) {
    final theme = Theme.of(context);
    final color = Color(result.contestant.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isWinner ? color : theme.colorScheme.outlineVariant,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Text('$rank',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(result.contestant.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isWinner) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.emoji_events, size: 16, color: color),
                          ],
                          if (isUserPick) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.thumb_up, size: 14, color: color),
                          ],
                        ],
                      ),
                      Text(result.contestant.specSummary,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (!score.disqualified)
                  Text(score.total.round().toString(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: color, fontWeight: FontWeight.w800)),
              ],
            ),
            if (score.disqualified) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.do_not_disturb_on_outlined,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(score.disqualifiedReason ?? 'Did not qualify',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...score.components.map((c) => _componentRow(context, c, color)),
            ],
            if (isWinner) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _setAsDefault(context, result.contestant),
                  icon: const Icon(Icons.push_pin_outlined, size: 18),
                  label: const Text('Set as default model'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _componentRow(
      BuildContext context, ArenaScoreComponent c, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(c.rawDisplay, style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              Text('+${c.contribution.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: c.normalized,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: theme.colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(width: 8),
              Text('weight ${(c.weight * 100).round()}%',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 2),
          Text(c.description,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Future<void> _setAsDefault(
      BuildContext context, ArenaContestant c) async {
    final sp = context.read<SettingsProvider>();
    final s = sp.settings;
    AppSettings updated;

    switch (c.providerKind) {
      case 'onDeviceGguf':
      case 'onDeviceMlx':
        updated = s.copyWith(
          activeProviderKind: c.providerKind,
          selectedLocalModelId: c.modelId,
          selectedModel: c.displayName,
        );
        break;
      case 'cloud':
        if (c.cloudProviderId != null) {
          await CloudApiService().setActiveProvider(c.cloudProviderId);
        }
        updated = s.copyWith(
          activeProviderKind: 'cloud',
          selectedModel: c.modelId,
        );
        break;
      default:
        updated = s.copyWith(
          activeProviderKind: RemoteHostBackends.isLlmKind(c.providerKind)
              ? c.providerKind
              : 'lmStudio',
          selectedModel: c.modelId,
        );
    }

    await sp.updateSettings(updated);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${c.displayName} is now your default model.')),
    );
  }
}

class _BarDatum {
  final String label;
  final double? value;
  final String display;
  final Color color;
  const _BarDatum({
    required this.label,
    required this.value,
    required this.display,
    required this.color,
  });
}

/// Simple labeled horizontal bar chart for one metric across contestants.
class _MetricBars extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool higherIsBetter;
  final List<_BarDatum> data;

  const _MetricBars({
    required this.title,
    required this.subtitle,
    required this.higherIsBetter,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = data
        .map((d) => d.value)
        .whereType<double>()
        .where((v) => v > 0)
        .toList();
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          Text(subtitle,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 10),
          ...data.map((d) {
            final fraction = (d.value != null && maxValue > 0)
                ? (d.value! / maxValue).clamp(0.02, 1.0)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(d.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall),
                      ),
                      Text(d.display,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 10,
                      backgroundColor: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(d.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
