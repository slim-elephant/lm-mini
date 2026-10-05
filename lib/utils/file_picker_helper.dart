import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/file_attachment.dart';
import 'file_picker_path_error.dart';

/// Max PDF size we'll try to parse in-app (~40 MB). Larger files are still
/// attached, but we skip Syncfusion extraction to avoid OOM / crashes.
const int _kMaxPdfExtractBytes = 40 * 1024 * 1024;

/// Soft cap for spreadsheet rows sent to the model (per sheet).
const int _kMaxSpreadsheetRows = 2500;

/// Soft cap for plain-text attachment characters sent to the model.
const int _kMaxTextExtractChars = 400000;

class FilePickerHelper {
  /// Extensions the unified document picker accepts.
  ///
  /// Models never receive binary files from Ollama/LM Studio APIs — we extract
  /// text locally and inject it into the prompt (same pattern as PDF/CSV).
  static const List<String> supportedDocumentExtensions = [
    // Documents
    'txt', 'md', 'markdown', 'pdf', 'rtf', 'log',
    // Data
    'csv', 'tsv', 'json', 'jsonl', 'xml', 'yaml', 'yml',
    // Spreadsheets (decoded to text tables)
    'xlsx', 'ods',
    // Markup / web
    'html', 'htm',
    // Common source / config
    'dart', 'py', 'js', 'ts', 'tsx', 'jsx', 'swift', 'java', 'kt', 'go', 'rs',
    'c', 'cpp', 'h', 'hpp', 'cs', 'rb', 'php', 'css', 'scss', 'sql', 'sh',
  ];

  /// Pick a document file and extract its text content
  static Future<FileAttachment?> pickDocument(
    BuildContext context, {
    List<String>? allowedExtensions,
  }) async {
    final attachments = await pickDocuments(
      context,
      allowedExtensions: allowedExtensions,
    );
    return attachments.isEmpty ? null : attachments.first;
  }

  /// Pick one or more document files and extract their text content.
  static Future<List<FileAttachment>> pickDocuments(
    BuildContext context, {
    List<String>? allowedExtensions,
  }) async {
    final extensions = allowedExtensions ?? supportedDocumentExtensions;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return const [];

      final attachments = <FileAttachment>[];
      for (var i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        final attachment = await _attachmentFromPlatformFile(file, index: i);
        if (attachment != null) attachments.add(attachment);
      }
      return attachments;
    } catch (e, st) {
      if (kDebugMode) {
        print('FilePickerHelper: File pick error: $e\n$st');
      }
      if (context.mounted) {
        final message = FilePickerPathError.matches(e)
            ? FilePickerPathError.userMessage
            : 'Could not open file picker: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return const [];
    }
  }

  /// Filesystem path, or a temp copy when Android only gave bytes.
  static Future<String?> resolveLocalPath(PlatformFile file) async {
    final existing = file.path;
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    final dir = await Directory.systemTemp.createTemp('lmmini_pick_');
    final name = file.name.trim().isEmpty ? 'file.bin' : file.name;
    final dest = File(path.join(dir.path, path.basename(name)));
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  static Future<FileAttachment?> _attachmentFromPlatformFile(
    PlatformFile file, {
    int index = 0,
  }) async {
    try {
      final sourcePath = await resolveLocalPath(file);
      if (sourcePath == null) return null;
      final sourceFile = File(sourcePath);
      final fileSize = await sourceFile.length();
      final extension = path.extension(sourcePath).toLowerCase();
      if (!_isSupportedDocumentExtension(extension)) return null;

      final type = typeForExtension(extension);

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final permanentPath = path.join(appDir.path, 'attachments', fileName);
      final permanentDir = Directory(path.dirname(permanentPath));
      if (!await permanentDir.exists()) {
        await permanentDir.create(recursive: true);
      }
      final permanentFile = await sourceFile.copy(permanentPath);

      String? extractedText;
      try {
        extractedText =
            await _extractTextFromFile(permanentFile, type, extension);
        if (kDebugMode) {
          print(
              'FilePickerHelper: Extracted ${extractedText?.length ?? 0} characters from ${type.name} file');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'FilePickerHelper: Error extracting text from ${type.name}: $e');
        }
        extractedText = 'File attached (extraction failed: $e)';
      }

      return FileAttachment(
        id: '${DateTime.now().microsecondsSinceEpoch}_$index',
        fileName: file.name,
        filePath: permanentPath,
        type: type,
        fileSize: fileSize,
        extractedText: extractedText,
        createdAt: DateTime.now(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('FilePickerHelper: attachmentFromPlatformFile error: $e\n$st');
      }
      return null;
    }
  }

  /// Build a persisted attachment from an on-disk path (desktop drag-and-drop).
  static Future<FileAttachment?> attachFromPath(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final fileName = path.basename(sourcePath);
      final extension = path.extension(sourcePath).toLowerCase();
      if (!_isSupportedDocumentExtension(extension)) return null;

      final type = typeForExtension(extension);
      final fileSize = await sourceFile.length();
      final appDir = await getApplicationDocumentsDirectory();
      final permanentName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final permanentPath =
          path.join(appDir.path, 'attachments', permanentName);
      final permanentDir = Directory(path.dirname(permanentPath));
      if (!await permanentDir.exists()) {
        await permanentDir.create(recursive: true);
      }
      final permanentFile = await sourceFile.copy(permanentPath);

      String? extractedText;
      try {
        extractedText =
            await _extractTextFromFile(permanentFile, type, extension);
      } catch (e) {
        extractedText = 'File attached (extraction failed: $e)';
      }

      return FileAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        filePath: permanentPath,
        type: type,
        fileSize: fileSize,
        extractedText: extractedText,
        createdAt: DateTime.now(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('FilePickerHelper: attachFromPath error: $e\n$st');
      }
      return null;
    }
  }

  static bool _isSupportedDocumentExtension(String extension) {
    final bare = extension.startsWith('.') ? extension.substring(1) : extension;
    return supportedDocumentExtensions.contains(bare.toLowerCase());
  }

  static FileAttachmentType typeForExtension(String extension) {
    final ext = extension.startsWith('.') ? extension : '.$extension';
    switch (ext.toLowerCase()) {
      case '.pdf':
        return FileAttachmentType.pdf;
      case '.csv':
      case '.tsv':
      case '.xlsx':
      case '.ods':
        return FileAttachmentType.csv;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.webp':
      case '.heic':
      case '.bmp':
        return FileAttachmentType.image;
      default:
        return FileAttachmentType.text;
    }
  }

  /// Extract text content from a file based on its type / extension.
  static Future<String?> _extractTextFromFile(
    File file,
    FileAttachmentType type,
    String extension,
  ) async {
    final ext = extension.toLowerCase();
    switch (ext) {
      case '.pdf':
        return _extractFromPdfFile(file);
      case '.csv':
        return _extractFromCsvFile(file, delimiter: ',');
      case '.tsv':
        return _extractFromCsvFile(file, delimiter: '\t');
      case '.xlsx':
      case '.ods':
        return _extractFromSpreadsheetFile(file);
      default:
        return _extractFromTextFile(file, label: _labelForExtension(ext));
    }
  }

  static String _labelForExtension(String ext) {
    switch (ext) {
      case '.md':
      case '.markdown':
        return 'Markdown';
      case '.json':
      case '.jsonl':
        return 'JSON';
      case '.yaml':
      case '.yml':
        return 'YAML';
      case '.xml':
        return 'XML';
      case '.html':
      case '.htm':
        return 'HTML';
      default:
        return 'Text File';
    }
  }

  /// Extract text from a plain text / markdown / code file.
  static Future<String?> _extractFromTextFile(
    File file, {
    String label = 'Text File',
  }) async {
    try {
      var content = await file.readAsString(encoding: utf8);
      if (kDebugMode) {
        print('$label extracted: ${content.length} characters');
      }
      if (content.trim().isEmpty) {
        return '$label attached (file is empty).';
      }
      content = _truncateText(content);
      return '$label Content:\n${'-' * 40}\n$content';
    } catch (e) {
      try {
        var content = await file.readAsString(encoding: latin1);
        if (content.trim().isEmpty) {
          return '$label attached (file is empty).';
        }
        content = _truncateText(content);
        return '$label Content:\n${'-' * 40}\n$content';
      } catch (e2) {
        if (kDebugMode) {
          print('Error reading text file: $e2');
        }
        return '$label attached (unable to read content: encoding issue).';
      }
    }
  }

  static String _truncateText(String content) {
    if (content.length <= _kMaxTextExtractChars) return content;
    return '${content.substring(0, _kMaxTextExtractChars)}\n\n'
        '[…truncated — file continues beyond $_kMaxTextExtractChars characters]';
  }

  /// Extract text from a CSV/TSV file (formatted for readability).
  static Future<String?> _extractFromCsvFile(
    File file, {
    required String delimiter,
  }) async {
    try {
      final content = await file.readAsString();
      final lines = const LineSplitter().convert(content);

      if (lines.isEmpty) return content;

      final buffer = StringBuffer();
      buffer.writeln(delimiter == '\t' ? 'TSV Data:' : 'CSV Data:');
      buffer.writeln('-' * 40);

      final limit = lines.length > _kMaxSpreadsheetRows
          ? _kMaxSpreadsheetRows
          : lines.length;
      for (int i = 0; i < limit; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cells =
            delimiter == '\t' ? line.split('\t') : _parseCsvLine(line);

        if (i == 0) {
          buffer.writeln('Headers: ${cells.join(' | ')}');
          buffer.writeln('-' * 40);
        } else {
          buffer.writeln('Row $i: ${cells.join(' | ')}');
        }
      }
      if (lines.length > limit) {
        buffer.writeln(
            '\n[…truncated — showing first $limit of ${lines.length} rows]');
      }

      return buffer.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Error reading CSV/TSV file: $e');
      }
      return null;
    }
  }

  /// Decode .xlsx / .ods into readable sheet tables for the model.
  static Future<String?> _extractFromSpreadsheetFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
      if (decoder.tables.isEmpty) {
        return 'Spreadsheet attached (no sheets found).';
      }

      final buffer = StringBuffer();
      buffer.writeln('Spreadsheet Content:');
      buffer.writeln('-' * 40);

      var sheetIndex = 0;
      for (final entry in decoder.tables.entries) {
        sheetIndex++;
        if (sheetIndex > 8) {
          buffer.writeln(
              '\n[…truncated — ${decoder.tables.length - 8} more sheet(s) omitted]');
          break;
        }
        final table = entry.value;
        buffer.writeln('\n### Sheet: ${entry.key}');
        buffer.writeln('Rows: ${table.maxRows}, Columns: ${table.maxCols}');
        buffer.writeln('-' * 40);

        final rowLimit = table.maxRows > _kMaxSpreadsheetRows
            ? _kMaxSpreadsheetRows
            : table.maxRows;
        for (var r = 0; r < rowLimit; r++) {
          final row = table.rows[r];
          final cells = row
              .map((cell) => cell == null ? '' : cell.toString().trim())
              .toList();
          if (cells.every((c) => c.isEmpty)) continue;
          if (r == 0) {
            buffer.writeln('Headers: ${cells.join(' | ')}');
            buffer.writeln('-' * 40);
          } else {
            buffer.writeln('Row $r: ${cells.join(' | ')}');
          }
        }
        if (table.maxRows > rowLimit) {
          buffer.writeln(
              '[…truncated — showing first $rowLimit of ${table.maxRows} rows]');
        }
      }

      final text = buffer.toString();
      return _truncateText(text);
    } catch (e, st) {
      if (kDebugMode) {
        print('Error reading spreadsheet: $e\n$st');
      }
      return 'Spreadsheet attached (could not decode — try exporting as CSV). '
          'Legacy .xls is not supported; use .xlsx or .ods.';
    }
  }

  /// Simple CSV line parser that handles quoted fields
  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  /// True when [bytes] look like a real PDF (`%PDF` magic, allowing a small
  /// leading offset for BOMs / junk prefixes).
  static bool _looksLikePdf(List<int> bytes) {
    if (bytes.length < 5) return false;
    final limit = bytes.length < 1024 ? bytes.length : 1024;
    for (var i = 0; i <= limit - 4; i++) {
      if (bytes[i] == 0x25 && // %
          bytes[i + 1] == 0x50 && // P
          bytes[i + 2] == 0x44 && // D
          bytes[i + 3] == 0x46) {
        // F
        return true;
      }
    }
    return false;
  }

  /// Extract text from a PDF file using Syncfusion PDF library.
  static Future<String?> _extractFromPdfFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (!_looksLikePdf(bytes)) {
        if (kDebugMode) {
          print(
              'FilePickerHelper: Skipping Syncfusion — file is not a valid PDF '
              '(missing %PDF header). name=${path.basename(file.path)} '
              'size=${bytes.length}');
        }
        return 'PDF file attached (this file does not appear to be a valid PDF '
            '— it may be renamed or corrupted).';
      }
      if (bytes.length > _kMaxPdfExtractBytes) {
        return 'PDF file attached (file is too large to extract text in-app; '
            'open it externally to view).';
      }

      final extracted =
          await Isolate.run(() => _extractPdfTextInIsolate(bytes));
      return extracted;
    } catch (e, st) {
      if (kDebugMode) {
        print('Error reading PDF file: $e\n$st');
      }
      return 'PDF file attached (text could not be extracted — open the file to view it).';
    }
  }

  /// Runs entirely inside [Isolate.run] — must not touch Flutter bindings.
  static String _extractPdfTextInIsolate(List<int> bytes) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final pageCount = document.pages.count;
      if (pageCount <= 0) {
        return 'PDF file attached (no pages found).';
      }

      try {
        final allText = extractor
            .extractText(startPageIndex: 0, endPageIndex: pageCount - 1)
            .trim();
        if (allText.isNotEmpty) {
          return 'PDF Content:\n${'-' * 40}\n$allText';
        }
      } catch (_) {
        // Fall through to page-by-page.
      }

      final buffer = StringBuffer();
      buffer.writeln('PDF Content:');
      buffer.writeln('-' * 40);
      var anyPage = false;
      for (var i = 0; i < pageCount; i++) {
        try {
          final pageText =
              extractor.extractText(startPageIndex: i, endPageIndex: i).trim();
          if (pageText.isEmpty) continue;
          anyPage = true;
          if (pageCount > 1) {
            buffer.writeln('\n--- Page ${i + 1} ---');
          }
          buffer.writeln(pageText);
        } catch (_) {
          // Skip bad pages.
        }
      }

      if (anyPage) return buffer.toString().trim();
      return 'PDF file attached (no extractable text found - may contain images only).';
    } finally {
      try {
        document?.dispose();
      } catch (_) {
        // Corrupt docs can throw on dispose; ignore.
      }
    }
  }

  static bool isExtractedTextPreviewable(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final trimmed = text.trim();
    if (trimmed.startsWith('PDF file attached (')) return false;
    if (trimmed.startsWith('Text file attached (')) return false;
    if (trimmed.startsWith('Spreadsheet attached (')) return false;
    if (trimmed.startsWith('Markdown attached (')) return false;
    if (trimmed.startsWith('File attached (')) return false;
    return true;
  }

  /// Get the file type from a file path
  static FileAttachmentType getFileType(String filePath) {
    return typeForExtension(path.extension(filePath));
  }
}
