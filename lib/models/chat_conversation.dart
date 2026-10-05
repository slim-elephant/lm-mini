import 'package:json_annotation/json_annotation.dart';

part 'chat_conversation.g.dart';

@JsonSerializable()
class ChatConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> messageIds;
  final Map<String, dynamic> settings; // Store conversation-specific settings
  final String? folderId; // Optional folder ID for organization
  final String? lastResponseId; // For stateful chat API continuation
  final String? parentConversationId; // ID of parent conversation if this is a branch

  ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageIds,
    required this.settings,
    this.folderId,
    this.lastResponseId,
    this.parentConversationId,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ChatConversationToJson(this);
  
  bool get isGroupChat => settings['isGroupChat'] == true;

  ChatConversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? messageIds,
    Map<String, dynamic>? settings,
    String? folderId,
    String? lastResponseId,
    bool clearLastResponseId = false,
    String? parentConversationId,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageIds: messageIds ?? this.messageIds,
      settings: settings ?? this.settings,
      folderId: folderId ?? this.folderId,
      lastResponseId: clearLastResponseId ? null : (lastResponseId ?? this.lastResponseId),
      parentConversationId: parentConversationId ?? this.parentConversationId,
    );
  }
}
