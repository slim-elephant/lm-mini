import 'dart:math';
import '../services/lm_studio_service.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';

/// Service for managing embeddings and semantic search
class EmbeddingsService {
  final LMStudioService _lmStudioService = LMStudioService();
  final DatabaseService _databaseService = DatabaseService();

  /// Calculate cosine similarity between two vectors
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have same length');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Find similar messages in a conversation using embeddings
  Future<List<MapEntry<ChatMessage, double>>> findSimilarMessages({
    required String baseUrl,
    required String embeddingModel,
    required String query,
    required String conversationId,
    int topK = 5,
    double minSimilarity = 0.5,
  }) async {
    try {
      // Get query embedding
      final queryEmbedding = await _lmStudioService.getEmbedding(
        baseUrl: baseUrl,
        text: query,
        embeddingModel: embeddingModel,
      );

      // Get all messages in conversation
      final messages = await _databaseService.getMessagesForConversation(conversationId);

      // Get embeddings for all messages
      final messageTexts = messages.map((m) => m.content).toList();
      final messageEmbeddings = await _lmStudioService.getEmbeddings(
        baseUrl: baseUrl,
        texts: messageTexts,
        embeddingModel: embeddingModel,
      );

      // Calculate similarities
      final similarities = <MapEntry<ChatMessage, double>>[];
      for (int i = 0; i < messages.length; i++) {
        final similarity = cosineSimilarity(queryEmbedding, messageEmbeddings[i]);
        if (similarity >= minSimilarity) {
          similarities.add(MapEntry(messages[i], similarity));
        }
      }

      // Sort by similarity (descending) and take top K
      similarities.sort((a, b) => b.value.compareTo(a.value));
      return similarities.take(topK).toList();
    } catch (e) {
      throw Exception('Error finding similar messages: $e');
    }
  }

  /// Find similar conversations based on their latest messages
  Future<List<MapEntry<ChatConversation, double>>> findSimilarConversations({
    required String baseUrl,
    required String embeddingModel,
    required String query,
    int topK = 5,
    double minSimilarity = 0.5,
  }) async {
    try {
      // Get query embedding
      final queryEmbedding = await _lmStudioService.getEmbedding(
        baseUrl: baseUrl,
        text: query,
        embeddingModel: embeddingModel,
      );

      // Get all conversations
      final conversations = await _databaseService.getAllConversations();

      // Get the last message from each conversation for embedding
      final conversationTexts = <String>[];
      final validConversations = <ChatConversation>[];
      
      for (final conv in conversations) {
        if (conv.messageIds.isNotEmpty) {
          final messages = await _databaseService.getMessagesForConversation(conv.id);
          if (messages.isNotEmpty) {
            // Use last user message or conversation title as representative text
            final userMessages = messages.where((m) => m.role == 'user').toList();
            final text = userMessages.isNotEmpty 
                ? userMessages.last.content 
                : conv.title;
            conversationTexts.add(text);
            validConversations.add(conv);
          }
        }
      }

      if (conversationTexts.isEmpty) {
        return [];
      }

      // Get embeddings for all conversations
      final conversationEmbeddings = await _lmStudioService.getEmbeddings(
        baseUrl: baseUrl,
        texts: conversationTexts,
        embeddingModel: embeddingModel,
      );

      // Calculate similarities
      final similarities = <MapEntry<ChatConversation, double>>[];
      for (int i = 0; i < validConversations.length; i++) {
        final similarity = cosineSimilarity(queryEmbedding, conversationEmbeddings[i]);
        if (similarity >= minSimilarity) {
          similarities.add(MapEntry(validConversations[i], similarity));
        }
      }

      // Sort by similarity (descending) and take top K
      similarities.sort((a, b) => b.value.compareTo(a.value));
      return similarities.take(topK).toList();
    } catch (e) {
      throw Exception('Error finding similar conversations: $e');
    }
  }

  /// Get relevant context from conversation history using semantic search
  /// This can be used for RAG (Retrieval Augmented Generation)
  Future<List<ChatMessage>> getRelevantContext({
    required String baseUrl,
    required String embeddingModel,
    required String query,
    required String conversationId,
    int maxMessages = 3,
  }) async {
    final similar = await findSimilarMessages(
      baseUrl: baseUrl,
      embeddingModel: embeddingModel,
      query: query,
      conversationId: conversationId,
      topK: maxMessages,
    );

    return similar.map((e) => e.key).toList();
  }
}
