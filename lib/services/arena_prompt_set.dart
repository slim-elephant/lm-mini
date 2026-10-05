/// Standardized prompt sets for **Arena benchmark mode**.
///
/// Keeping the benchmark prompts fixed + versioned is what makes results
/// comparable across runs, models, and devices — and what will let us
/// aggregate a device-class leaderboard later. Never edit an existing set's
/// prompts in place; bump [ArenaPromptSet.version] (or add a new set) so older
/// records stay comparable among themselves.
library;

class ArenaPromptSet {
  /// Stable identifier stored with every benchmark record.
  final String id;

  /// Increment whenever the prompts change so old + new data don't mix.
  final int version;

  /// Human-readable name.
  final String name;

  /// Short description for the UI.
  final String description;

  /// The ordered prompts run against each model.
  final List<String> prompts;

  const ArenaPromptSet({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    required this.prompts,
  });

  /// Short onboarding / "find my model" race — one prompt, ~30–60s per model.
  static const ArenaPromptSet quick = ArenaPromptSet(
    id: 'quick',
    version: 1,
    name: 'Quick race',
    description:
        'One short prompt to compare speed and first-word snappiness. '
        'Best for picking a model in under a minute.',
    prompts: [
      'In three short sentences, explain what a large language model is, '
          'then give one practical tip for running one on a phone.',
    ],
  );

  /// The default standard suite: a short factual answer, a reasoning task, and
  /// a longer generative task — exercising prompt-processing, throughput, and
  /// sustained generation.
  static const ArenaPromptSet standard = ArenaPromptSet(
    id: 'standard',
    version: 1,
    name: 'Standard suite',
    description:
        'Three prompts (concise answer, reasoning, and long-form writing) for '
        'a balanced speed benchmark.',
    prompts: [
      'In two sentences, explain what an API is to a non-technical person.',
      'A farmer has 17 sheep. All but 9 run away. How many are left? '
          'Think step by step, then give the final answer.',
      'Write a 150-word product description for a pair of noise-cancelling '
          'headphones aimed at remote workers. Be vivid and persuasive.',
    ],
  );

  /// All selectable sets (room to grow into "coding", "roleplay", etc.).
  static const List<ArenaPromptSet> all = [quick, standard];
}
