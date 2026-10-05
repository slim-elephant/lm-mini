/// How Mini fits history when there is no `previous_response_id`.
enum ContextFitMode {
  /// Current behavior: send everything; the server may error.
  off,

  /// Drop oldest turns; keep the most recent.
  roll,

  /// Keep the opening and the latest turns; drop the middle.
  cutMiddle;

  static ContextFitMode parse(String? raw) {
    return switch (raw) {
      'roll' => ContextFitMode.roll,
      'cutMiddle' => ContextFitMode.cutMiddle,
      _ => ContextFitMode.off,
    };
  }

  String get storageValue => switch (this) {
        ContextFitMode.off => 'off',
        ContextFitMode.roll => 'roll',
        ContextFitMode.cutMiddle => 'cutMiddle',
      };
}

class ContextTurn {
  final String role;
  final String text;

  const ContextTurn({required this.role, required this.text});
}

/// Client-side packing so a cold V1 send stays under ~90% of loaded context.
class ContextFit {
  ContextFit._();

  /// Leave 10% of the window for the new user turn + a short reply.
  static const double fitFraction = 0.90;

  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / 4).ceil();
  }

  static int budgetFor(int loadedContextTokens) {
    if (loadedContextTokens <= 0) return 0;
    return (loadedContextTokens * fitFraction).floor();
  }

  /// [compactSummary] is always kept first when it fits.
  static List<ContextTurn> fit({
    required List<ContextTurn> turns,
    required int maxTokens,
    required ContextFitMode mode,
    String? compactSummary,
  }) {
    final summary = compactSummary?.trim();
    final hasSummary = summary != null && summary.isNotEmpty;
    final withSummary = <ContextTurn>[
      if (hasSummary) ContextTurn(role: 'summary', text: summary),
      ...turns,
    ];
    if (maxTokens <= 0) {
      if (!hasSummary) return const [];
      return [ContextTurn(role: 'summary', text: summary)];
    }
    if (_totalTokens(withSummary) <= maxTokens) return withSummary;

    if (mode == ContextFitMode.off) {
      // Compact prefix only — do not drop live turns unless they cannot fit
      // even with the summary.
      if (!hasSummary) return withSummary;
      return _roll(withSummary, maxTokens);
    }

    if (mode == ContextFitMode.cutMiddle) {
      return _cutMiddle(withSummary, maxTokens);
    }
    return _roll(withSummary, maxTokens);
  }

  static String formatForStatefulInput(
    List<ContextTurn> turns, {
    required String newUserContent,
  }) {
    if (turns.isEmpty) return newUserContent;
    final buffer = StringBuffer();
    var wroteHistory = false;
    for (final turn in turns) {
      if (turn.role == 'summary') {
        buffer.writeln('[Conversation summary — continue from here]');
        buffer.writeln();
        buffer.writeln(turn.text);
        buffer.writeln();
        buffer.writeln('[End of summary]');
        buffer.writeln();
        wroteHistory = true;
        continue;
      }
      if (!wroteHistory) {
        buffer.writeln('[Previous conversation context — continue from here]');
        buffer.writeln();
        wroteHistory = true;
      }
      final label = turn.role == 'user' ? 'User' : 'Assistant';
      buffer.writeln('$label: ${turn.text}');
      buffer.writeln();
    }
    if (wroteHistory) {
      buffer.writeln('[End of previous context]');
      buffer.writeln();
      buffer.writeln('User: $newUserContent');
      return buffer.toString();
    }
    return newUserContent;
  }

  static int _totalTokens(List<ContextTurn> turns) {
    var n = 0;
    for (final t in turns) {
      n += estimateTokens(t.text);
    }
    return n;
  }

  static List<ContextTurn> _roll(List<ContextTurn> turns, int maxTokens) {
    final pinned = <ContextTurn>[];
    final rest = <ContextTurn>[];
    for (final turn in turns) {
      if (turn.role == 'summary' && pinned.isEmpty) {
        pinned.add(turn);
      } else {
        rest.add(turn);
      }
    }
    var used = _totalTokens(pinned);
    if (used > maxTokens && pinned.isNotEmpty) {
      return [_truncate(pinned.first, maxTokens)];
    }
    final kept = <ContextTurn>[];
    for (var i = rest.length - 1; i >= 0; i--) {
      final turn = rest[i];
      final cost = estimateTokens(turn.text);
      if (kept.isNotEmpty && used + cost > maxTokens) break;
      if (kept.isEmpty && used + cost > maxTokens) {
        kept.insert(0, _truncate(turn, maxTokens - used));
        used = maxTokens;
        break;
      }
      kept.insert(0, turn);
      used += cost;
    }
    if (pinned.isEmpty && kept.isEmpty && turns.isNotEmpty) {
      return [_truncate(turns.last, maxTokens)];
    }
    return [...pinned, ...kept];
  }

  /// Keep ~20% of the budget on the opening (including summary), rest on the tail.
  static List<ContextTurn> _cutMiddle(List<ContextTurn> turns, int maxTokens) {
    if (turns.isEmpty) return turns;
    final headBudget = (maxTokens * 0.2).floor().clamp(1, maxTokens);
    final head = <ContextTurn>[];
    var headUsed = 0;
    for (final turn in turns) {
      final cost = estimateTokens(turn.text);
      if (head.isNotEmpty && headUsed + cost > headBudget) break;
      if (head.isEmpty && cost > headBudget) {
        head.add(_truncate(turn, headBudget));
        headUsed = headBudget;
        break;
      }
      head.add(turn);
      headUsed += cost;
    }

    final tailBudget = (maxTokens - headUsed).clamp(0, maxTokens);
    final tail = <ContextTurn>[];
    var tailUsed = 0;
    for (var i = turns.length - 1; i >= head.length; i--) {
      final turn = turns[i];
      final cost = estimateTokens(turn.text);
      if (tail.isNotEmpty && tailUsed + cost > tailBudget) break;
      if (tail.isEmpty && cost > tailBudget && tailBudget > 0) {
        tail.insert(0, _truncate(turn, tailBudget));
        break;
      }
      tail.insert(0, turn);
      tailUsed += cost;
    }
    return [...head, ...tail];
  }

  static ContextTurn _truncate(ContextTurn turn, int maxTokens) {
    final maxChars = (maxTokens * 4).clamp(0, turn.text.length);
    if (maxChars >= turn.text.length) return turn;
    return ContextTurn(
      role: turn.role,
      text: '${turn.text.substring(0, maxChars)}…',
    );
  }
}
