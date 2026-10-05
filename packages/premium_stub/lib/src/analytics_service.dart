import 'package:flutter/foundation.dart';

/// Stub analytics service — all operations are no-ops.
///
/// In the real premium package, this tracks token usage, model usage,
/// conversation counts, and response times in Firestore.
class AnalyticsService extends ChangeNotifier {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  int get totalTokens => 0;
  int get totalConversations => 0;
  int get totalMessages => 0;
  Map<String, int> get modelUsage => const {};
  Map<String, int> get toolUsage => const {};
  double get avgResponseTime => 0;

  /// No-op in stub.
  Future<void> load() async {}

  /// No-op in stub.
  void recordMessage({
    required String modelId,
    int promptTokens = 0,
    int completionTokens = 0,
    double? responseTimeMs,
  }) {}

  /// No-op in stub.
  void recordConversation() {}

  /// No-op in stub.
  void recordToolUse(String toolName) {}
}
