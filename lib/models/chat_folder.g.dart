// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatFolder _$ChatFolderFromJson(Map<String, dynamic> json) => ChatFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      conversationIds: (json['conversationIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChatFolderToJson(ChatFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'conversationIds': instance.conversationIds,
      'sortOrder': instance.sortOrder,
    };
