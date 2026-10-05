import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/context_fit.dart';

void main() {
  List<ContextTurn> turns(int count, {int chars = 40}) {
    return [
      for (var i = 0; i < count; i++)
        ContextTurn(
            role: i.isEven ? 'user' : 'assistant', text: 'm$i${'x' * chars}'),
    ];
  }

  test('parse storage values', () {
    expect(ContextFitMode.parse(null), ContextFitMode.off);
    expect(ContextFitMode.parse('roll'), ContextFitMode.roll);
    expect(ContextFitMode.parse('cutMiddle'), ContextFitMode.cutMiddle);
    expect(ContextFitMode.roll.storageValue, 'roll');
  });

  test('budget is 90% of loaded context', () {
    expect(ContextFit.budgetFor(1000), 900);
    expect(ContextFit.budgetFor(256), 230);
  });

  test('under budget returns all turns plus summary', () {
    final fitted = ContextFit.fit(
      turns: turns(4, chars: 8),
      maxTokens: 10000,
      mode: ContextFitMode.roll,
      compactSummary: 'hello',
    );
    expect(fitted.first.role, 'summary');
    expect(fitted.length, 5);
  });

  test('roll drops oldest live turns', () {
    final all = turns(6, chars: 40); // ~10 tokens each
    final fitted = ContextFit.fit(
      turns: all,
      maxTokens: 25,
      mode: ContextFitMode.roll,
    );
    expect(fitted, isNotEmpty);
    expect(fitted.first.text.startsWith('m0'), isFalse);
    expect(fitted.last.text.startsWith('m5'), isTrue);
    expect(ContextFit.estimateTokens(fitted.map((t) => t.text).join()) <= 40,
        isTrue);
  });

  test('cut middle keeps opening and tail', () {
    final all = turns(8, chars: 40);
    final fitted = ContextFit.fit(
      turns: all,
      maxTokens: 40,
      mode: ContextFitMode.cutMiddle,
    );
    expect(fitted.first.text.startsWith('m0'), isTrue);
    expect(fitted.last.text.startsWith('m7'), isTrue);
    final ids = fitted.map((t) => t.text.substring(0, 2)).toList();
    expect(ids.contains('m3') && ids.contains('m4'), isFalse);
  });

  test('off still keeps a compact summary and rolls if needed', () {
    final fitted = ContextFit.fit(
      turns: turns(8, chars: 80),
      maxTokens: 30,
      mode: ContextFitMode.off,
      compactSummary: 'SUM',
    );
    expect(fitted.first.role, 'summary');
  });

  test('stateful format wraps summary and history', () {
    final text = ContextFit.formatForStatefulInput(
      const [
        ContextTurn(role: 'summary', text: 'We talked about cats.'),
        ContextTurn(role: 'user', text: 'And dogs?'),
        ContextTurn(role: 'assistant', text: 'Yes.'),
      ],
      newUserContent: 'What next?',
    );
    expect(text, contains('Conversation summary'));
    expect(text, contains('User: And dogs?'));
    expect(text, contains('User: What next?'));
  });

  test('zero budget keeps summary only', () {
    final fitted = ContextFit.fit(
      turns: turns(4, chars: 40),
      maxTokens: 0,
      mode: ContextFitMode.roll,
      compactSummary: 'keep me',
    );
    expect(fitted, hasLength(1));
    expect(fitted.single.role, 'summary');
    expect(fitted.single.text, 'keep me');
  });
}
