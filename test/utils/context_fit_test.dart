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

  test('budget is 80% of loaded context', () {
    expect(ContextFit.budgetFor(1000), 800);
    expect(ContextFit.budgetFor(256), 204);
  });

  group('estimateTokens', () {
    // Real counts measured on LM Studio (Qwen 3 / Gemma 4), the larger of
    // the two models, for the exact text built here.
    final samples = <String, (String, int)>{
      'plain English': (
        "We aren't building something new; we are restoring what was "
                "always there. Okay so I just took a quick overview of that "
                "book and as deep as it actually looks it's pretty much "
                "surface stuff, I'm considerably much deeper than that so it "
                "may be a waste of time or perhaps it's not the correct book. " *
            12,
        816
      ),
      'markdown answer': (
        '### Key points\n\n- **First:** the model reads the *whole* '
                'prompt.\n- **Second:** tokens != words (e.g. `n_ctx=4096`).'
                '\n\n1. Step one\n2. Step two — done ✅\n\n> Note: see §3.2.'
                '\n\n' *
            14,
        895
      ),
      'numbers and symbols': (
        '2026-11-17T23:16:55.280622Z | 192.168.1.183:1337 | 64,459 in / '
                '430 out = 64,889 (62.1%) | \$4.99 → \$29.99\n' *
            16,
        1440
      ),
      'Russian': (
        'Остатки удалённых чатов, неиспользуемые и временные файлы можно '
                'смело удалить, а чаты, модели и персоны при этом не '
                'затрагиваются. ' *
            14,
        631
      ),
      'Chinese': ('已删除聊天的残留、未使用的文件和临时文件可以放心删除，你的聊天、模型和角色不受影响。' * 20, 500),
      'emoji chat': (
        "haha yes 😂😂 that's so true!! 🙌🔥 ok brb 🏃‍♂️💨 … lol 🤣 " * 30,
        902
      ),
      'JSON': (
        '{"model": "qwen3.5:4b", "options": {"temperature": 0.8, "top_p": '
                '0.9, "num_ctx": 4096}, "stream": true}\n' *
            18,
        917
      ),
    };

    for (final e in samples.entries) {
      test('${e.key}: within the packing margin of the real count', () {
        final (text, real) = e.value;
        final est = ContextFit.estimateTokens(text);
        // History is packed to fitFraction of the window, so the estimate
        // may be low by at most 1 / fitFraction before a send overflows.
        expect(real / est, lessThan(1 / ContextFit.fitFraction),
            reason: 'estimate $est vs real $real');
        // And not wildly high, or chats would be trimmed for no reason.
        expect(est / real, lessThan(1.6),
            reason: 'estimate $est vs real $real');
      });
    }

    test('the old characters ÷ 4 rule would have overflowed', () {
      final (text, real) = samples['numbers and symbols']!;
      expect(real / (text.length / 4), greaterThan(3));
      final (md, mdReal) = samples['markdown answer']!;
      expect(mdReal / (md.length / 4), greaterThan(1 / 0.9));
    });

    test('empty and tiny strings', () {
      expect(ContextFit.estimateTokens(''), 0);
      expect(ContextFit.estimateTokens('a'), 1);
      expect(ContextFit.estimateTokens('zzzz'), 2);
    });
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
