import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/streaming_phase.dart';

void main() {
  test('canonical collapses status strings into stacked phases', () {
    expect(StreamingPhase.canonical('Loading model... 40%'),
        StreamingPhase.loadingModel);
    expect(StreamingPhase.canonical('Model loaded in 1.2s'), isNull);
    expect(StreamingPhase.canonical('Processing prompt...'),
        StreamingPhase.processingPrompt);
    expect(StreamingPhase.canonical('Thinking...'), StreamingPhase.thinking);
    expect(StreamingPhase.canonical('Alice is thinking...'),
        StreamingPhase.thinking);
    expect(StreamingPhase.canonical('Generating response...'),
        StreamingPhase.processingPrompt);
    expect(StreamingPhase.canonical('Sending request...'),
        StreamingPhase.processingPrompt);
    expect(StreamingPhase.canonical('Processing...'),
        StreamingPhase.processingPrompt);
    expect(StreamingPhase.canonical('Writing response...'),
        StreamingPhase.writing);
    expect(StreamingPhase.canonical('🔍 Searching the web...'),
        StreamingPhase.searching);
    expect(StreamingPhase.canonical('Connecting to MCP...'),
        StreamingPhase.usingTools);
    expect(StreamingPhase.canonical('Starting chat...'), isNull);
    expect(StreamingPhase.canonical('Complete'), isNull);
    expect(StreamingPhase.canonical('Cancelled'), isNull);
  });

  test('a late load does not reopen the loading line', () {
    expect(
      StreamingPhase.shouldRecord(
        const [StreamingPhase.loadingModel, StreamingPhase.processingPrompt],
        StreamingPhase.loadingModel,
      ),
      isFalse,
    );
    expect(
      StreamingPhase.shouldRecord(
        const [StreamingPhase.loadingModel],
        StreamingPhase.loadingModel,
      ),
      isFalse,
    );
    expect(
      StreamingPhase.shouldRecord(
        const [],
        StreamingPhase.loadingModel,
      ),
      isTrue,
    );
  });
}
