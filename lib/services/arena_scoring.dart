/// Transparent winner scoring for **Arena mode**.
///
/// We deliberately score only what we can measure *objectively* on-device:
/// speed, responsiveness, device fit, and successful completion. Answer
/// *quality* is subjective, so it is never auto-judged here — the user marks
/// their own "best answer" in the UI. This split keeps the auto-winner honest
/// and explainable, which is exactly what the "How we chose the winner" screen
/// surfaces.
///
/// Pure Dart (no Flutter imports) so it is unit-testable.
library;

import '../models/arena_models.dart';
import '../models/local_model_spec.dart';

/// One weighted factor in a contestant's score.
class ArenaScoreComponent {
  /// Human-readable factor name, e.g. "Speed".
  final String label;

  /// Short explanation of what the factor measures and which direction wins.
  final String description;

  /// The raw measured value, formatted for display (e.g. "22.4 t/s").
  final String rawDisplay;

  /// Normalized 0–1 sub-score (1.0 = best among contestants for this factor).
  final double normalized;

  /// Relative weight of this factor in the final score (weights sum to 1.0).
  final double weight;

  const ArenaScoreComponent({
    required this.label,
    required this.description,
    required this.rawDisplay,
    required this.normalized,
    required this.weight,
  });

  /// Points this factor contributes to the 0–100 total.
  double get contribution => normalized * weight * 100.0;
}

/// A contestant's full score breakdown.
class ArenaContestantScore {
  final String contestantId;
  final List<ArenaScoreComponent> components;

  /// Final 0–100 performance score.
  final double total;

  /// True when the contestant errored or produced no answer (total forced 0).
  final bool disqualified;

  /// Reason for disqualification, when [disqualified].
  final String? disqualifiedReason;

  const ArenaContestantScore({
    required this.contestantId,
    required this.components,
    required this.total,
    this.disqualified = false,
    this.disqualifiedReason,
  });
}

/// The result of scoring an arena run.
class ArenaScoreboard {
  /// Scores ordered best → worst.
  final List<ArenaContestantScore> ranked;

  /// Id of the auto-selected performance winner, or null when nobody qualified.
  final String? winnerId;

  /// The weighting profile used, exposed so the explainer screen can describe
  /// the methodology.
  final Map<String, double> weights;

  const ArenaScoreboard({
    required this.ranked,
    required this.winnerId,
    required this.weights,
  });

  ArenaContestantScore? scoreFor(String contestantId) {
    for (final s in ranked) {
      if (s.contestantId == contestantId) return s;
    }
    return null;
  }
}

class ArenaScoring {
  ArenaScoring._();

  // Weighting profile. Speed dominates because Arena's primary job is helping
  // users find the fastest model their device/prompt can run well; the other
  // factors keep a fast-but-broken model from winning.
  static const double wSpeed = 0.45;
  static const double wLatency = 0.25;
  static const double wFit = 0.15;
  static const double wCompletion = 0.15;

  static const Map<String, double> weights = {
    'Speed': wSpeed,
    'Responsiveness': wLatency,
    'Device fit': wFit,
    'Completion': wCompletion,
  };

  /// Maps a [ModelFit] verdict to a 0–1 fit sub-score. Non-on-device
  /// contestants (no spec / unknown) are treated as a perfect fit since the
  /// model isn't competing for this device's RAM.
  static double _fitScore(ModelFit? fit) {
    switch (fit) {
      case ModelFit.runs:
        return 1.0;
      case ModelFit.tight:
        return 0.5;
      case ModelFit.blocked:
        return 0.0;
      case null:
        return 1.0;
    }
  }

  static String _fitLabel(ModelFit? fit) {
    switch (fit) {
      case ModelFit.runs:
        return 'Runs comfortably';
      case ModelFit.tight:
        return 'Tight fit';
      case ModelFit.blocked:
        return 'Over budget';
      case null:
        return 'Not device-bound';
    }
  }

  /// Scores all [results] relative to each other and picks a winner.
  static ArenaScoreboard score(List<ArenaContestantResult> results) {
    // Qualifying contestants must have finished with some content.
    final qualifying = results
        .where((r) =>
            r.status == ArenaContestantStatus.done && r.hasContent)
        .toList();

    // Best (max) throughput and best (min) latency across qualifiers, used to
    // normalize each contestant onto a 0–1 scale.
    double maxTps = 0;
    double minTtft = double.infinity;
    for (final r in qualifying) {
      final tps = r.metrics.tokensPerSecond;
      final ttft = r.metrics.ttftMs;
      if (tps != null && tps > maxTps) maxTps = tps;
      if (ttft != null && ttft > 0 && ttft < minTtft) minTtft = ttft;
    }

    final scores = <ArenaContestantScore>[];
    for (final r in results) {
      final isQualified =
          r.status == ArenaContestantStatus.done && r.hasContent;

      if (!isQualified) {
        final reason = r.status == ArenaContestantStatus.error
            ? (r.error ?? 'Failed to respond')
            : r.status == ArenaContestantStatus.cancelled
                ? 'Cancelled'
                : 'No answer produced';
        scores.add(ArenaContestantScore(
          contestantId: r.contestant.id,
          components: const [],
          total: 0,
          disqualified: true,
          disqualifiedReason: reason,
        ));
        continue;
      }

      final tps = r.metrics.tokensPerSecond ?? 0;
      final ttft = r.metrics.ttftMs;

      final speedNorm = maxTps > 0 ? (tps / maxTps).clamp(0.0, 1.0) : 0.0;
      final latencyNorm = (ttft != null && ttft > 0 && minTtft.isFinite)
          ? (minTtft / ttft).clamp(0.0, 1.0)
          : 0.5; // unknown latency → neutral
      final fitNorm = _fitScore(r.fit);
      // Completion: 1.0 for a natural stop, 0.6 when truncated by length.
      final stop = r.metrics.stopReason?.toLowerCase();
      final completionNorm =
          (stop == 'length' || stop == 'max_tokens') ? 0.6 : 1.0;

      final components = <ArenaScoreComponent>[
        ArenaScoreComponent(
          label: 'Speed',
          description:
              'Generation throughput. Faster token output scores higher.',
          rawDisplay: r.metrics.formattedTps +
              (r.metrics.tokensEstimated ? ' (est.)' : ''),
          normalized: speedNorm,
          weight: wSpeed,
        ),
        ArenaScoreComponent(
          label: 'Responsiveness',
          description:
              'Time to the first token. A snappier first response scores higher.',
          rawDisplay: r.metrics.formattedTtft,
          normalized: latencyNorm,
          weight: wLatency,
        ),
        ArenaScoreComponent(
          label: 'Device fit',
          description:
              'How comfortably the model fits this device\'s memory budget.',
          rawDisplay: _fitLabel(r.fit),
          normalized: fitNorm,
          weight: wFit,
        ),
        ArenaScoreComponent(
          label: 'Completion',
          description:
              'Whether the model finished naturally rather than being cut off.',
          rawDisplay: (stop == 'length' || stop == 'max_tokens')
              ? 'Truncated (length)'
              : 'Finished cleanly',
          normalized: completionNorm,
          weight: wCompletion,
        ),
      ];

      final total =
          components.fold<double>(0, (sum, c) => sum + c.contribution);

      scores.add(ArenaContestantScore(
        contestantId: r.contestant.id,
        components: components,
        total: total,
      ));
    }

    // Rank: qualified by total desc, then t/s as tiebreak; disqualified last.
    final tpsById = {
      for (final r in results)
        r.contestant.id: r.metrics.tokensPerSecond ?? 0,
    };
    scores.sort((a, b) {
      if (a.disqualified != b.disqualified) {
        return a.disqualified ? 1 : -1;
      }
      final byTotal = b.total.compareTo(a.total);
      if (byTotal != 0) return byTotal;
      return (tpsById[b.contestantId] ?? 0)
          .compareTo(tpsById[a.contestantId] ?? 0);
    });

    final winnerId = scores.isNotEmpty && !scores.first.disqualified
        ? scores.first.contestantId
        : null;

    return ArenaScoreboard(
      ranked: scores,
      winnerId: winnerId,
      weights: weights,
    );
  }
}
