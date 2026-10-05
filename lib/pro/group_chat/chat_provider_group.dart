// LM-MINI-PRO-STUB
part of '../../providers/chat_provider.dart';

/// Open-source build: group chat replies are not included. Group
/// conversations stay viewable; every Pro entry point is a no-op.
extension _ProGroupChat on ChatProvider {
  Future<void> _proSendGroupMessage(
      String content, AppSettings settings, List<String>? imageUrls,
      {String? userDisplayContent, String? memoryContext}) async {
    _isSendingMessage = false;
    _notifyFromPart();
  }

  Future<void> _proTriggerParticipantResponse(
      String participantId, AppSettings settings) async {}

  Future<void> _proRunAutonomousCycle(AppSettings settings) async {
    _isAutonomousCycling = false;
    _notifyFromPart();
  }

  Future<void> _proRegenerateFromGroupMessage(
      String messageId, AppSettings settings) async {}
}
