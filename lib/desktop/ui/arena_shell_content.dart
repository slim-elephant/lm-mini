import 'package:flutter/material.dart';

import '../../models/arena_models.dart';
import '../../models/arena_run.dart';
import '../../pro/pro_features.dart';
import '../../services/arena_scoring.dart';
import '../../services/benchmark_service.dart';
import '../../screens/arena_explainer_screen.dart';
import '../../screens/arena_setup_screen.dart';

/// Two-column Arena content for the desktop shell.
///
/// Column 2: past arena runs + "New Run" button (Pro build only).
/// Column 3: Arena setup screen or result details. In the public build the
/// setup pane spans the full width.
class ArenaShellContent extends StatefulWidget {
  const ArenaShellContent({super.key});

  @override
  State<ArenaShellContent> createState() => _ArenaShellContentState();
}

enum _ArenaPane { setup, results }

class _ArenaShellContentState extends State<ArenaShellContent> {
  _ArenaPane _pane = _ArenaPane.setup;
  ArenaRun? _selectedRun;
  late Future<List<ArenaRun>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ProFeatures.included
        ? BenchmarkService.instance.fetchHistory()
        : Future.value(const <ArenaRun>[]);
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = BenchmarkService.instance.fetchHistory();
    });
    await _historyFuture;
  }

  @override
  Widget build(BuildContext context) {
    if (!ProFeatures.included) return _buildContentPane(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: _buildHistoryPanel(context),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        Expanded(
          child: _buildContentPane(context),
        ),
      ],
    );
  }

  Widget _buildHistoryPanel(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Arena',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _pane = _ArenaPane.setup;
                      _selectedRun = null;
                    });
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ArenaRun>>(
              future: _historyFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }
                final runs = snap.data ?? [];
                if (runs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_outlined,
                              size: 48,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No past runs yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: runs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final run = runs[i];
                      final isSelected = _selectedRun?.id == run.id;
                      return Card(
                        margin: EdgeInsets.zero,
                        color: isSelected
                            ? cs.primaryContainer.withValues(alpha: 0.5)
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                cs.primary.withValues(alpha: 0.14),
                            child: Icon(
                              run.mode == ArenaMode.benchmark
                                  ? Icons.speed
                                  : Icons.compare_arrows,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(run.promptLabel,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${run.contestantCount} models · ${_formatDate(run.createdAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedRun = run;
                              _pane = _ArenaPane.results;
                            });
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPane(BuildContext context) {
    if (_pane == _ArenaPane.results && _selectedRun != null) {
      final run = _selectedRun!;
      final board = ArenaScoring.score(run.results);
      return ArenaExplainerScreen(
        key: ValueKey('arena-result-${run.id}'),
        results: run.results,
        scoreboard: board,
        userPickId: run.userPickId,
        embedded: true,
      );
    }
    return const ArenaSetupScreen(embedded: true);
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$m/$day $hh:$mm';
  }
}
