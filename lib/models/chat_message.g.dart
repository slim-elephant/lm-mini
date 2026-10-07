// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      model: json['model'] as String?,
      stats: json['stats'] == null
          ? null
          : MessageStats.fromJson(json['stats'] as Map<String, dynamic>),
      modelInfo: json['modelInfo'] == null
          ? null
          : ModelInfo.fromJson(json['modelInfo'] as Map<String, dynamic>),
      runtimeInfo: json['runtimeInfo'] == null
          ? null
          : RuntimeInfo.fromJson(json['runtimeInfo'] as Map<String, dynamic>),
      usage: json['usage'] == null
          ? null
          : TokenUsage.fromJson(json['usage'] as Map<String, dynamic>),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      fileAttachments: (json['fileAttachments'] as List<dynamic>?)
          ?.map((e) => FileAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      responseId: json['responseId'] as String?,
      imagePrompt: json['imagePrompt'] as String?,
      generatedImagePath: json['generatedImagePath'] as String?,
      generatedImagePaths: (json['generatedImagePaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      generatedImageInfo: json['generatedImageInfo'] as String?,
      participantId: json['participantId'] as String?,
      expression: json['expression'] as String?,
      alternatives: (json['alternatives'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      alternativeIndex: (json['alternativeIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'role': instance.role,
      'timestamp': instance.timestamp.toIso8601String(),
      'model': instance.model,
      'stats': instance.stats?.toJson(),
      'modelInfo': instance.modelInfo?.toJson(),
      'runtimeInfo': instance.runtimeInfo?.toJson(),
      'usage': instance.usage?.toJson(),
      'imageUrls': instance.imageUrls,
      'fileAttachments':
          instance.fileAttachments?.map((e) => e.toJson()).toList(),
      'responseId': instance.responseId,
      'imagePrompt': instance.imagePrompt,
      'generatedImagePath': instance.generatedImagePath,
      'generatedImagePaths': instance.generatedImagePaths,
      'generatedImageInfo': instance.generatedImageInfo,
      'participantId': instance.participantId,
      'expression': instance.expression,
      'alternatives': instance.alternatives?.map((e) => e.toJson()).toList(),
      'alternativeIndex': instance.alternativeIndex,
    };
