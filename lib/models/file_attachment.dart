import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

part 'file_attachment.g.dart';

enum FileAttachmentType {
  text,
  csv,
  pdf,
  image,
}

@JsonSerializable()
class FileAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final FileAttachmentType type;
  final int fileSize; // in bytes
  final String? extractedText; // Text content extracted from the file
  final DateTime createdAt;

  FileAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.fileSize,
    this.extractedText,
    required this.createdAt,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) => _$FileAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$FileAttachmentToJson(this);

  /// Short uppercase extension badge (e.g. MD, XLSX, PDF).
  String get extensionLabel {
    final ext = p.extension(fileName).replaceFirst('.', '').toUpperCase();
    if (ext.isNotEmpty && ext.length <= 5) return ext;
    switch (type) {
      case FileAttachmentType.pdf:
        return 'PDF';
      case FileAttachmentType.csv:
        return 'CSV';
      case FileAttachmentType.image:
        return 'IMG';
      case FileAttachmentType.text:
        return 'TXT';
    }
  }

  String get typeDisplayName {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.md':
      case '.markdown':
        return 'Markdown';
      case '.xlsx':
      case '.ods':
        return 'Spreadsheet';
      case '.csv':
        return 'CSV';
      case '.tsv':
        return 'TSV';
      case '.pdf':
        return 'PDF';
      case '.json':
      case '.jsonl':
        return 'JSON';
      case '.yaml':
      case '.yml':
        return 'YAML';
    }
    switch (type) {
      case FileAttachmentType.text:
        return 'Text File';
      case FileAttachmentType.csv:
        return 'Spreadsheet';
      case FileAttachmentType.pdf:
        return 'PDF File';
      case FileAttachmentType.image:
        return 'Image';
    }
  }

  String get typeIcon {
    switch (type) {
      case FileAttachmentType.text:
        return '📄';
      case FileAttachmentType.csv:
        return '📊';
      case FileAttachmentType.pdf:
        return '📕';
      case FileAttachmentType.image:
        return '🖼️';
    }
  }

  String get fileSizeDisplay {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  FileAttachment copyWith({
    String? id,
    String? fileName,
    String? filePath,
    FileAttachmentType? type,
    int? fileSize,
    String? extractedText,
    DateTime? createdAt,
  }) {
    return FileAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      fileSize: fileSize ?? this.fileSize,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
