import '../models/file_attachment.dart';

/// Helpers for packing file attachments into on-device prompts.
///
/// On-device engines are sensitive to:
/// - duplicate user turns (display-only + full attachment message)
/// - huge PDF dumps that blow past the ~4k context cap
/// - heavy markdown / emoji scaffolding that small models misread
class OnDeviceAttachments {
  OnDeviceAttachments._();

  /// Rough char budget for attached document text given a context window.
  /// Leaves room for system prompt, chat history, and the reply.
  static int attachmentCharBudget(int contextTokens) {
    final ctx = contextTokens > 0 ? contextTokens : 4096;
    // ~4 chars/token; keep ~55% of the window for non-attachment content.
    return (ctx * 4 * 0.45).round().clamp(2000, 24000);
  }

  /// Append extracted file text to [content] in a plain, model-friendly form.
  static String withFileText(
    String content, {
    List<FileAttachment>? files,
    int? maxChars,
  }) {
    if (files == null || files.isEmpty) return content;

    final budget = maxChars ?? 12000;
    final buf = StringBuffer(content.trim());
    if (buf.isNotEmpty) buf.writeln();

    var remaining = budget;
    for (final file in files) {
      if (remaining <= 0) {
        buf.writeln();
        buf.writeln(
            '[Additional attached files were omitted — context limit reached.]');
        break;
      }

      final raw = (file.extractedText ?? '').trim();
      buf.writeln();
      buf.writeln('Attached file: ${file.fileName}');
      buf.writeln('---');
      if (raw.isEmpty) {
        buf.writeln(
            '(No extractable text — this may be a scanned or image-only PDF.)');
      } else if (raw.length <= remaining) {
        buf.writeln(raw);
        remaining -= raw.length;
      } else {
        buf.writeln(raw.substring(0, remaining));
        buf.writeln();
        buf.writeln(
            '[…truncated ${raw.length - remaining} characters to fit the on-device context window…]');
        remaining = 0;
      }
      buf.writeln('---');
    }

    return buf.toString().trim();
  }

  /// Rebuild API content for a stored user message (display text + files).
  static String contentForHistoryMessage(
    String displayContent, {
    List<FileAttachment>? files,
    int? maxChars,
  }) {
    return withFileText(displayContent, files: files, maxChars: maxChars);
  }
}
