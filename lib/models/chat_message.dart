import 'package:json_annotation/json_annotation.dart';
import 'message_stats.dart';
import 'file_attachment.dart';

part 'chat_message.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatMessage {
  final String id;
  final String content;
  final String role; // 'user', 'assistant', 'system'
  final DateTime timestamp;
  final String? model;
  
  // Performance statistics
  final MessageStats? stats;
  final ModelInfo? modelInfo;
  final RuntimeInfo? runtimeInfo;
  final TokenUsage? usage;
  
  // Vision support
  final List<String>? imageUrls; // For image attachments (base64 or file paths)
  
  // File attachments support (txt, csv, pdf)
  final List<FileAttachment>? fileAttachments;
  
  // Stateful chat support
  final String? responseId; // LM Studio stateful chat response ID

  // Image generation
  final String? imagePrompt; // Hidden prompt extracted from AI response for image gen
  final String? generatedImagePath; // Path to locally saved generated image (legacy single)
  final List<String>? generatedImagePaths; // Paths to all generated images (batch support)
  /// JSON metadata from the last image generation (ComfyUI request details, etc.).
  final String? generatedImageInfo;

  // Group chat support
  final String? participantId; // Links to GroupChatParticipant.id in group chats

  /// Character expression for this reply (`joy`, `anger`, …), from the hidden
  /// `[EXPRESSION: …]` tag. Picks the persona's expression sprite.
  final String? expression;

  // Swipes / generation alternatives
  final List<ChatMessage>? alternatives;
  final int? alternativeIndex;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.model,
    this.stats,
    this.modelInfo,
    this.runtimeInfo,
    this.usage,
    this.imageUrls,
    this.fileAttachments,
    this.responseId,
    this.imagePrompt,
    this.generatedImagePath,
    this.generatedImagePaths,
    this.generatedImageInfo,
    this.participantId,
    this.expression,
    this.alternatives,
    this.alternativeIndex,
  });

  /// Returns all generated image paths (prefers new list field, falls back to legacy single).
  List<String> get allGeneratedImagePaths {
    if (generatedImagePaths != null && generatedImagePaths!.isNotEmpty) {
      return generatedImagePaths!;
    }
    if (generatedImagePath != null && generatedImagePath!.isNotEmpty) {
      return [generatedImagePath!];
    }
    return [];
  }

  /// Whether any generated images exist.
  bool get hasGeneratedImages => allGeneratedImagePaths.isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? id,
    String? content,
    String? role,
    DateTime? timestamp,
    String? model,
    MessageStats? stats,
    ModelInfo? modelInfo,
    RuntimeInfo? runtimeInfo,
    TokenUsage? usage,
    List<String>? imageUrls,
    List<FileAttachment>? fileAttachments,
    String? responseId,
    String? imagePrompt,
    String? generatedImagePath,
    List<String>? generatedImagePaths,
    String? generatedImageInfo,
    String? participantId,
    String? expression,
    List<ChatMessage>? alternatives,
    int? alternativeIndex,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      model: model ?? this.model,
      stats: stats ?? this.stats,
      modelInfo: modelInfo ?? this.modelInfo,
      runtimeInfo: runtimeInfo ?? this.runtimeInfo,
      usage: usage ?? this.usage,
      imageUrls: imageUrls ?? this.imageUrls,
      fileAttachments: fileAttachments ?? this.fileAttachments,
      responseId: responseId ?? this.responseId,
      imagePrompt: imagePrompt ?? this.imagePrompt,
      generatedImagePath: generatedImagePath ?? this.generatedImagePath,
      generatedImagePaths: generatedImagePaths ?? this.generatedImagePaths,
      generatedImageInfo: generatedImageInfo ?? this.generatedImageInfo,
      participantId: participantId ?? this.participantId,
      expression: expression ?? this.expression,
      alternatives: alternatives ?? this.alternatives,
      alternativeIndex: alternativeIndex ?? this.alternativeIndex,
    );
  }
}
