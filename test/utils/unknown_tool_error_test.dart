import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/error_report_service.dart';
import 'package:lm_mini/utils/unknown_tool_error.dart';

void main() {
  test('reads the tool name from the raw tool error', () {
    expect(
      UnknownToolError.toolName('Error: Unknown tool "google_search"'),
      'google_search',
    );
    expect(UnknownToolError.toolName('Web search failed'), isNull);
    expect(UnknownToolError.toolName(null), isNull);
  });

  test('message names the tool and what to do, without the raw error', () {
    final msg = UnknownToolError.userMessageFor('google_search');
    expect(msg, contains('"google_search"'));
    expect(msg, contains('Tool Calling'));
    expect(msg, contains('another model'));
    expect(msg, isNot(contains('Error:')));
    expect(UnknownToolError.userMessageFor(null), isNot(contains('""')));
    expect(UnknownToolError.userMessageFor(' '), isNot(contains('(')));
  });

  test('recognised as model behaviour, so no support ticket', () {
    const raw = 'Error: Unknown tool "google_search"';
    expect(UnknownToolError.matches(raw), isTrue);
    expect(
      UnknownToolError.matches(UnknownToolError.userMessageFor('x')),
      isTrue,
    );
    expect(ErrorReportService.isIgnorable(raw), isTrue);
    expect(
      ErrorReportService.isIgnorable(
          UnknownToolError.userMessageFor('google_search')),
      isTrue,
    );
    expect(UnknownToolError.matches('SearXNG search failed'), isFalse);
    expect(UnknownToolError.matches(null), isFalse);
  });
}
