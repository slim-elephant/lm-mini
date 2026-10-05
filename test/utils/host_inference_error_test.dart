import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/host_inference_error.dart';

void main() {
  group('HostInferenceError', () {
    test('matches llama.cpp GGML scheduler overflow', () {
      const raw =
          'llama-server process has terminated: GGML_ASSERT(n_inputs < GGML_SCHED_MAX_SPLIT_INPUTS) failed';
      expect(HostInferenceError.isGgmlScheduler(raw), isTrue);
      expect(HostInferenceError.isTerminated(raw), isFalse);
      expect(HostInferenceError.matches(raw), isTrue);
      expect(
        HostInferenceError.userMessage(raw),
        HostInferenceError.ggmlUserMessage,
      );
    });

    test('matches LM Studio {"error":"terminated"}', () {
      expect(
        HostInferenceError.isTerminated('{"error":"terminated"}'),
        isTrue,
      );
      expect(HostInferenceError.isTerminated('terminated'), isTrue);
      expect(
        HostInferenceError.isTerminated(
          '❌ LM Studio error: terminated (type: null)',
        ),
        isTrue,
      );
    });

    test('does not match legal copy or unrelated errors', () {
      expect(
        HostInferenceError.matches(
          'These terms remain in effect until terminated.',
        ),
        isFalse,
      );
      expect(
        HostInferenceError.matches('Cannot connect to LM Studio'),
        isFalse,
      );
      expect(HostInferenceError.matches(null), isFalse);
    });

    test('mentions a huge attached image on terminated', () {
      final msg = HostInferenceError.terminatedUserMessageFor(
        largeImageBytes: 6 * 1024 * 1024,
      );
      expect(msg, contains('6.0 MB'));
      expect(HostInferenceError.isTerminated(msg), isTrue);
    });
  });
}
