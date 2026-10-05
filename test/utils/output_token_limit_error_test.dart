import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/output_token_limit_error.dart';

void main() {
  group('OutputTokenLimitError', () {
    test('matches the in-app MCP copy', () {
      expect(
        OutputTokenLimitError.matches(OutputTokenLimitError.userMessage),
        isTrue,
      );
    });

    test('matches the debug fallback phrasing', () {
      expect(
        OutputTokenLimitError.matches(
          'MCP tools completed but no final answer. Model may need more output tokens.',
        ),
        isTrue,
      );
    });

    test('does not match unrelated errors', () {
      expect(OutputTokenLimitError.matches('Cannot connect to LM Studio'),
          isFalse);
      expect(OutputTokenLimitError.matches(null), isFalse);
    });
  });
}
