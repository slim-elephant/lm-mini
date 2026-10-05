/// One timed slice of a file transcription (phrase-level timestamps).
class TranscriptionSegment {
  final int startMs;
  final int endMs;
  final String text;

  const TranscriptionSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'startMs': startMs,
        'endMs': endMs,
        'text': text,
      };

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      startMs: (json['startMs'] as num?)?.toInt() ?? 0,
      endMs: (json['endMs'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
    );
  }
}
