import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/whisper_transcript_stabilizer.dart';

void main() {
  group('WhisperTranscriptStabilizer', () {
    test('accepts first interim', () {
      expect(
        WhisperTranscriptStabilizer.shouldAcceptInterimUpdate('', 'hello'),
        isTrue,
      );
    });

    test('accepts strict extension', () {
      expect(
        WhisperTranscriptStabilizer.shouldAcceptInterimUpdate(
          'hello there',
          'hello there friend',
        ),
        isTrue,
      );
    });

    test('rejects rewrite of earlier words', () {
      expect(
        WhisperTranscriptStabilizer.shouldAcceptInterimUpdate(
          'hello there',
          'yellow there',
        ),
        isFalse,
      );
    });

    test('accepts correction on trailing word when prefix matches', () {
      expect(
        WhisperTranscriptStabilizer.shouldAcceptInterimUpdate(
          'hello ther',
          'hello there',
        ),
        isTrue,
      );
    });
  });

  group('WhisperTranscriptStabilizer.collapseRepeats', () {
    test('collapses repeated sentence loop', () {
      expect(
        WhisperTranscriptStabilizer.collapseRepeats(
          'Hello. Hello. Hello. Hello. Hello. Hello.',
        ),
        'Hello.',
      );
    });

    test('collapses repeated phrase loop without terminal punctuation', () {
      expect(
        WhisperTranscriptStabilizer.collapseRepeats(
          'Your message appears repeated multiple. '
          'Your message appears repeated multiple. '
          'Your message appears repeated multiple. Your',
        ),
        'Your message appears repeated multiple. Your',
      );
    });

    test('keeps normal speech untouched', () {
      expect(
        WhisperTranscriptStabilizer.collapseRepeats(
          'Hello, how are you doing?',
        ),
        'Hello, how are you doing?',
      );
    });

    test('keeps a legitimate double word', () {
      expect(
        WhisperTranscriptStabilizer.collapseRepeats('it was very very good'),
        'it was very very good',
      );
    });

    test('collapses word repeated many times', () {
      expect(
        WhisperTranscriptStabilizer.collapseRepeats('no no no no no way'),
        'no way',
      );
    });

    test('handles empty input', () {
      expect(WhisperTranscriptStabilizer.collapseRepeats('  '), '');
    });
  });
}
