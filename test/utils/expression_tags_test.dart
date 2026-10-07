import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/expression_tags.dart';

void main() {
  group('normalizeExpressionLabel', () {
    test('labels, case, variants and aliases', () {
      expect(normalizeExpressionLabel('Joy'), 'joy');
      expect(normalizeExpressionLabel('joy_2'), 'joy');
      expect(normalizeExpressionLabel('anger-1'), 'anger');
      expect(normalizeExpressionLabel('happy'), 'joy');
      expect(normalizeExpressionLabel('Blushing'), 'embarrassment');
      expect(normalizeExpressionLabel('background'), isNull);
      expect(normalizeExpressionLabel(''), isNull);
    });
  });

  group('extractExpressionTag', () {
    test('strips the tag and returns the label', () {
      final r = extractExpressionTag('[EXPRESSION: joy]\nHello there!');
      expect(r.expression, 'joy');
      expect(r.cleanContent, 'Hello there!');
    });

    test('first valid tag wins and every copy is removed', () {
      final r = extractExpressionTag(
          '[expression: Happy] Hi [EXPRESSION: anger] again');
      expect(r.expression, 'joy');
      expect(r.cleanContent, 'Hi  again');
    });

    test('unknown label is removed but ignored', () {
      final r = extractExpressionTag('[EXPRESSION: smug-ish] Fine.');
      expect(r.expression, isNull);
      expect(r.cleanContent, 'Fine.');
    });

    test('truncated tag at the end is removed', () {
      final r = extractExpressionTag('Answer text [EXPRESSION: jo');
      expect(r.expression, isNull);
      expect(r.cleanContent, 'Answer text');
    });

    test('no tag leaves content untouched', () {
      final r = extractExpressionTag('Plain [link](x)');
      expect(r.expression, isNull);
      expect(r.cleanContent, 'Plain [link](x)');
    });
  });

  group('stripExpressionTagsForDisplay', () {
    test('hides a tag that is still streaming', () {
      expect(stripExpressionTagsForDisplay('['), '');
      expect(stripExpressionTagsForDisplay('[EXPRE'), '');
      expect(stripExpressionTagsForDisplay('[EXPRESSION: jo'), '');
      expect(stripExpressionTagsForDisplay('[EXPRESSION: joy] Hel'), 'Hel');
    });

    test('keeps normal brackets', () {
      expect(stripExpressionTagsForDisplay('[1] footnote'), '[1] footnote');
    });
  });

  group('instructions', () {
    test('system instruction is added once', () {
      final once = applyExpressionInstructionToSystem('Base', ['joy', 'neutral']);
      expect(once, contains('[EXPRESSION: label]'));
      expect(once, contains('joy, neutral'));
      expect(applyExpressionInstructionToSystem(once, ['joy']), once);
      expect(applyExpressionInstructionToSystem('Base', null), 'Base');
      expect(applyExpressionInstructionToSystem('Base', const []), 'Base');
    });

    test('turn reminder is added once', () {
      final once = appendExpressionTurnReminder('Hi', ['joy']);
      expect(appendExpressionTurnReminder(once, ['joy']), once);
      expect(appendExpressionTurnReminder('Hi', null), 'Hi');
    });
  });

  test('labels and sprite lookup', () {
    final sprites = {'joy': 'a.png', 'anger': 'b.png', 'weird': 'c.png'};
    expect(expressionLabelsForSprites(sprites), ['anger', 'joy', 'neutral']);
    expect(spriteForExpression(sprites, 'joy'), 'a.png');
    expect(spriteForExpression({'neutral': 'n.png', 'joy': 'a.png'}, 'fear'),
        'n.png');
    expect(spriteForExpression(sprites, null), 'a.png');
    expect(spriteForExpression(null, 'joy'), isNull);
  });
}
