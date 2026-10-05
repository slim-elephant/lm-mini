/// Neutral speech-to-text result used by both system and Whisper backends.
class SttRecognitionResult {
  final String recognizedWords;
  final bool finalResult;

  const SttRecognitionResult({
    required this.recognizedWords,
    required this.finalResult,
  });
}
