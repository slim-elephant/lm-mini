import '../models/transcription_segment.dart';

/// Builds plain text and SRT subtitle files from timed segments.
class SrtFormatter {
  SrtFormatter._();

  static String plainText(List<TranscriptionSegment> segments) {
    return segments
        .map((s) => s.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n')
        .trim();
  }

  static String srt(List<TranscriptionSegment> segments) {
    final buffer = StringBuffer();
    var index = 1;
    for (final seg in segments) {
      final text = seg.text.trim();
      if (text.isEmpty) continue;
      buffer.writeln(index++);
      buffer.writeln(
          '${_formatSrtTime(seg.startMs)} --> ${_formatSrtTime(seg.endMs)}');
      buffer.writeln(text);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  static String _formatSrtTime(int ms) {
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    final f = ms % 1000;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')},'
        '${f.toString().padLeft(3, '0')}';
  }
}
