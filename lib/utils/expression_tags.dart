/// Character expression sprites (SillyTavern "Character Expressions").
///
/// The model starts each reply with a hidden `[EXPRESSION: joy]` tag. Mini
/// strips it from the text, stores the label on the message, and shows the
/// persona's matching sprite.
library;

/// SillyTavern's expression labels (the GoEmotions set it classifies into).
/// Sprite files are named after these, for example `joy.png` or `joy_2.png`.
const List<String> kExpressionLabels = [
  'admiration',
  'amusement',
  'anger',
  'annoyance',
  'approval',
  'caring',
  'confusion',
  'curiosity',
  'desire',
  'disappointment',
  'disapproval',
  'disgust',
  'embarrassment',
  'excitement',
  'fear',
  'gratitude',
  'grief',
  'joy',
  'love',
  'nervousness',
  'neutral',
  'optimism',
  'pride',
  'realization',
  'relief',
  'remorse',
  'sadness',
  'surprise',
];

/// A smaller set that covers most scenes. Used as the default for sprite
/// generation, so a first run doesn't queue 28 images.
const List<String> kCoreExpressionLabels = [
  'neutral',
  'joy',
  'sadness',
  'anger',
  'surprise',
  'fear',
  'love',
  'embarrassment',
];

const String _kExpressionInstructionMarker = '[EXPRESSION_INSTRUCTION]';

/// Common names that aren't SillyTavern labels but mean the same thing.
const Map<String, String> _kExpressionAliases = {
  'happy': 'joy',
  'happiness': 'joy',
  'smile': 'joy',
  'smiling': 'joy',
  'laugh': 'amusement',
  'laughing': 'amusement',
  'sad': 'sadness',
  'crying': 'sadness',
  'cry': 'sadness',
  'angry': 'anger',
  'mad': 'anger',
  'annoyed': 'annoyance',
  'surprised': 'surprise',
  'shocked': 'surprise',
  'scared': 'fear',
  'afraid': 'fear',
  'embarrassed': 'embarrassment',
  'blush': 'embarrassment',
  'blushing': 'embarrassment',
  'confused': 'confusion',
  'curious': 'curiosity',
  'excited': 'excitement',
  'nervous': 'nervousness',
  'proud': 'pride',
  'relieved': 'relief',
  'disgusted': 'disgust',
  'disappointed': 'disappointment',
  'grateful': 'gratitude',
  'thinking': 'realization',
  'idle': 'neutral',
  'default': 'neutral',
  'calm': 'neutral',
};

/// Maps a label, alias or sprite filename stem (`Joy`, `joy_2`, `happy-1`)
/// to a label in [kExpressionLabels]. Returns null when nothing matches.
String? normalizeExpressionLabel(String raw) {
  var value = raw.trim().toLowerCase();
  if (value.isEmpty) return null;
  // Strip a trailing variant number: joy_2, joy-2, joy 2, joy2.
  value = value.replaceFirst(RegExp(r'[\s_\-.]*\d+$'), '');
  value = value.replaceAll(RegExp(r'[^a-z]'), '');
  if (value.isEmpty) return null;
  if (kExpressionLabels.contains(value)) return value;
  return _kExpressionAliases[value];
}

/// Result of pulling the hidden expression tag out of a reply.
class ExpressionTagResult {
  final String cleanContent;
  final String? expression;

  const ExpressionTagResult(this.cleanContent, this.expression);
}

final RegExp _kExpressionTag =
    RegExp(r'\[EXPRESSION:\s*([^\]\n]{1,40})\]', caseSensitive: false);
final RegExp _kTruncatedExpressionTag =
    RegExp(r'\[EXPRESSION:?[^\]\n]{0,40}$', caseSensitive: false);

/// Removes every `[EXPRESSION: …]` tag and returns the first valid label.
/// A tag cut off at the end of the output is removed too.
ExpressionTagResult extractExpressionTag(String content) {
  if (!content.toUpperCase().contains('[EXPRESSION')) {
    return ExpressionTagResult(content, null);
  }
  String? label;
  for (final match in _kExpressionTag.allMatches(content)) {
    label ??= normalizeExpressionLabel(match.group(1) ?? '');
  }
  var clean = content.replaceAll(_kExpressionTag, '');
  clean = clean.replaceFirst(_kTruncatedExpressionTag, '');
  return ExpressionTagResult(clean.trim(), label);
}

/// Display-only cleanup while a reply streams in: hides complete tags and a
/// tag that is still being written.
String stripExpressionTagsForDisplay(String text) {
  if (!text.contains('[')) return text;
  var out = text.replaceAll(_kExpressionTag, '');
  out = out.replaceFirst(_kTruncatedExpressionTag, '');
  // A lone '[' or '[EXP…' prefix at the very start while streaming.
  final trimmed = out.trimLeft();
  if (trimmed.isNotEmpty &&
      '[EXPRESSION:'.startsWith(trimmed.toUpperCase()) &&
      trimmed.length < 12) {
    return '';
  }
  return out.trimLeft();
}

/// System instruction asking for the tag. [labels] are the expressions the
/// persona has sprites for.
String expressionSystemInstruction(List<String> labels) =>
    '\n\n$_kExpressionInstructionMarker Start each reply with a hidden tag '
    '[EXPRESSION: label] naming your current facial expression, using exactly '
    'one of: ${labels.join(', ')}. Then write the reply. Never mention or '
    'explain the tag.';

/// Short per-turn reminder (LM Studio stateful sessions only send the
/// system prompt once).
String expressionTurnReminder(List<String> labels) =>
    '\n\n$_kExpressionInstructionMarker Begin your reply with '
    '[EXPRESSION: ${labels.take(6).join('|')}|…]. Do not mention the tag.';

String applyExpressionInstructionToSystem(
  String systemPrompt,
  List<String>? labels,
) {
  if (labels == null || labels.isEmpty) return systemPrompt;
  if (systemPrompt.contains(_kExpressionInstructionMarker)) {
    return systemPrompt;
  }
  return '$systemPrompt${expressionSystemInstruction(labels)}';
}

String appendExpressionTurnReminder(String content, List<String>? labels) {
  if (labels == null || labels.isEmpty) return content;
  if (content.contains(_kExpressionInstructionMarker)) return content;
  return '$content${expressionTurnReminder(labels)}';
}

/// Labels the model may use for a persona: its sprite labels, plus
/// `neutral` so the model always has a calm option.
List<String> expressionLabelsForSprites(Map<String, String>? sprites) {
  if (sprites == null || sprites.isEmpty) return const [];
  final labels = <String>{
    for (final key in sprites.keys)
      if (kExpressionLabels.contains(key)) key,
  };
  labels.add('neutral');
  return [
    for (final label in kExpressionLabels)
      if (labels.contains(label)) label,
  ];
}

/// Sprite path for [expression], falling back to `neutral`, then to any
/// sprite. Returns null when the persona has none.
String? spriteForExpression(Map<String, String>? sprites, String? expression) {
  if (sprites == null || sprites.isEmpty) return null;
  if (expression != null && sprites[expression] != null) {
    return sprites[expression];
  }
  return sprites['neutral'] ?? sprites.values.first;
}
