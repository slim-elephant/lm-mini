import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/error_report_service.dart';
import 'package:lm_mini/utils/server_busy_error.dart';

void main() {
  test('recognises a server that is still on the previous turn', () {
    for (final e in [
      'A turn for this story is already running; no extra turn was queued',
      '{"error":{"message":"A turn for this story is already running; '
          'no extra turn was queued","type":"story_memory_error"}}',
      'Exception: A request for this session is already in progress',
      'Another generation is already running for this chat',
      ServerBusyError.userMessage,
    ]) {
      expect(ServerBusyError.matches(e), isTrue, reason: e);
      expect(ErrorReportService.isIgnorable(e), isTrue, reason: e);
    }
  });

  test('leaves other errors alone', () {
    for (final e in [
      'Compute error.',
      'model "x" not found',
      'The download is already running',
      // LM Mini Home's own busy answers are already plain language.
      'Mac is answering another request. Try again when it finishes.',
      '',
    ]) {
      expect(ServerBusyError.matches(e), isFalse, reason: e);
    }
    expect(ServerBusyError.matches(null), isFalse);
  });
}
