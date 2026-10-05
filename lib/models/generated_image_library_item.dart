import '../models/chat_message.dart';
import '../utils/generated_image_info.dart';

/// One generated file in Settings → Image Generation → Generated images.
class GeneratedImageLibraryItem {
  final String filePath;
  final String? messageId;
  final String? conversationId;
  final String? conversationTitle;
  final DateTime timestamp;
  final String? imagePrompt;
  final String? infoJson;
  final bool orphan;

  const GeneratedImageLibraryItem({
    required this.filePath,
    required this.timestamp,
    this.messageId,
    this.conversationId,
    this.conversationTitle,
    this.imagePrompt,
    this.infoJson,
    this.orphan = false,
  });

  String get fileKey => generatedFileKey(filePath);

  String get fileName {
    final name = generatedFileKey(filePath);
    return name.isEmpty ? filePath : name;
  }

  ParsedGeneratedImageInfo get parsed =>
      parseGeneratedImageInfo(infoJson, fallbackPrompt: imagePrompt);

  String? get displayPrompt {
    final fromInfo = parsed.prompt?.trim();
    if (fromInfo != null && fromInfo.isNotEmpty) return fromInfo;
    final fromMessage = imagePrompt?.trim();
    if (fromMessage != null && fromMessage.isNotEmpty) return fromMessage;
    return null;
  }
}

/// Basename used to match stored DB paths with files on disk.
String generatedFileKey(String path) {
  final normalized = path.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  return slash >= 0 ? normalized.substring(slash + 1) : normalized;
}

bool sameGeneratedFile(String a, String b) =>
    a == b || generatedFileKey(a) == generatedFileKey(b);

/// Expand a stored message (and its swipe alternatives) into library rows.
List<GeneratedImageLibraryItem> libraryItemsFromMessage({
  required ChatMessage message,
  required String conversationId,
  String? conversationTitle,
}) {
  final items = <GeneratedImageLibraryItem>[];
  void addFrom(ChatMessage msg) {
    for (final path in msg.allGeneratedImagePaths) {
      if (path.trim().isEmpty) continue;
      items.add(GeneratedImageLibraryItem(
        filePath: path,
        messageId: message.id,
        conversationId: conversationId,
        conversationTitle: conversationTitle,
        timestamp: msg.timestamp,
        imagePrompt: msg.imagePrompt ?? message.imagePrompt,
        infoJson: msg.generatedImageInfo ?? message.generatedImageInfo,
      ));
    }
  }

  addFrom(message);
  final alts = message.alternatives;
  if (alts != null) {
    for (final alt in alts) {
      addFrom(alt);
    }
  }
  return items;
}

bool messageTreeHasGeneratedImages(ChatMessage message) {
  if (message.hasGeneratedImages) return true;
  final alts = message.alternatives;
  if (alts == null) return false;
  return alts.any((a) => a.hasGeneratedImages);
}

bool messagesHaveGeneratedImages(Iterable<ChatMessage> messages) =>
    messages.any(messageTreeHasGeneratedImages);

List<GeneratedImageLibraryItem> libraryItemsFromMessages(
  Iterable<ChatMessage> messages, {
  required String conversationId,
  String? conversationTitle,
}) {
  final items = <GeneratedImageLibraryItem>[
    for (final message in messages)
      ...libraryItemsFromMessage(
        message: message,
        conversationId: conversationId,
        conversationTitle: conversationTitle,
      ),
  ];
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
}

/// Drop matching files from a message and its alternatives.
/// Returns null when nothing changed (cannot clear fields via [ChatMessage.copyWith]).
ChatMessage? stripGeneratedImageFiles(
  ChatMessage message,
  Set<String> fileKeys,
) {
  if (fileKeys.isEmpty) return null;

  List<String>? strippedPaths(ChatMessage msg) {
    final current = msg.allGeneratedImagePaths;
    if (current.isEmpty) return null;
    final remaining =
        current.where((p) => !fileKeys.contains(generatedFileKey(p))).toList();
    if (remaining.length == current.length) return null;
    return remaining;
  }

  final topRemaining = strippedPaths(message);
  var changed = topRemaining != null;

  List<ChatMessage>? nextAlts = message.alternatives;
  if (nextAlts != null && nextAlts.isNotEmpty) {
    final rewritten = <ChatMessage>[];
    var altChanged = false;
    for (final alt in nextAlts) {
      final stripped = stripGeneratedImageFiles(alt, fileKeys);
      if (stripped != null) {
        rewritten.add(stripped);
        altChanged = true;
      } else {
        rewritten.add(alt);
      }
    }
    if (altChanged) {
      nextAlts = rewritten;
      changed = true;
    }
  }

  if (!changed) return null;

  final remaining = topRemaining ?? message.allGeneratedImagePaths;
  return ChatMessage(
    id: message.id,
    content: message.content,
    role: message.role,
    timestamp: message.timestamp,
    model: message.model,
    stats: message.stats,
    modelInfo: message.modelInfo,
    runtimeInfo: message.runtimeInfo,
    usage: message.usage,
    imageUrls: message.imageUrls,
    fileAttachments: message.fileAttachments,
    responseId: message.responseId,
    imagePrompt: message.imagePrompt,
    generatedImagePath: remaining.isEmpty ? null : remaining.first,
    generatedImagePaths: remaining.isEmpty ? null : remaining,
    generatedImageInfo:
        remaining.isEmpty ? null : message.generatedImageInfo,
    participantId: message.participantId,
    alternatives: nextAlts,
    alternativeIndex: message.alternativeIndex,
  );
}
