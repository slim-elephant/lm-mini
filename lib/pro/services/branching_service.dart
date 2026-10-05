// LM-MINI-PRO-STUB
/// Public-build stub: conversation branching is a Pro feature that ships only
/// in the official LM Mini app. [createBranch] always returns null.
class BranchingService {
  static final BranchingService _instance = BranchingService._internal();
  factory BranchingService() => _instance;
  BranchingService._internal();

  /// Always returns null in the public build (no branch is created).
  Future<String?> createBranch({
    required String sourceConversationId,
    required String branchFromMessageId,
    String? title,
    Map<String, dynamic>? sourceSettings,
  }) async =>
      null;
}
