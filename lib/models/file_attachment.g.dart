// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileAttachment _$FileAttachmentFromJson(Map<String, dynamic> json) =>
    FileAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      type: $enumDecode(_$FileAttachmentTypeEnumMap, json['type']),
      fileSize: (json['fileSize'] as num).toInt(),
      extractedText: json['extractedText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FileAttachmentToJson(FileAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'type': _$FileAttachmentTypeEnumMap[instance.type]!,
      'fileSize': instance.fileSize,
      'extractedText': instance.extractedText,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$FileAttachmentTypeEnumMap = {
  FileAttachmentType.text: 'text',
  FileAttachmentType.csv: 'csv',
  FileAttachmentType.pdf: 'pdf',
  FileAttachmentType.image: 'image',
};
