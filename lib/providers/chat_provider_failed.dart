part of 'chat_provider.dart';

/// "Not delivered · Tap to retry" for user turns (iMessage / WhatsApp style).
///
/// Ids live in `conversation.settings['failedMessageIds']` — never a DB
/// column (agent.md §25g). See [FailedMessages] for the pure rules.
///
/// Consecutive failures ("hi", then "hello"): each bubble is marked on its
/// own. Retrying / sending the last one sends the earlier undelivered user
/// turns as history (the stateful session is rewound so LM Studio sees them
/// once — see [_includeUndeliveredTurnsInContext]). When that reply arrives
/// the earlier turns are marked delivered too, since they were included.
extension _FailedMessageTracking on ChatProvider {
  /// Replay [replay] in place: drop anything after it (tool-call noise from
  /// the failed attempt) and rewind the V1 session to the last reply before
  /// it, so the server never sees this user text twice.
  Future<void> _prepareReplayTurn(ChatMessage replay) async {
    final idx = _currentMessages.indexWhere((m) => m.id == replay.id);
    if (idx < 0) return;
    final trailing = _currentMessages.sublist(idx + 1);
    for (final m in trailing) {
      if (!m.id.startsWith('temp_')) {
        await _databaseService.deleteMessage(m.id);
      }
    }
    if (trailing.isNotEmpty) {
      _currentMessages.removeRange(idx + 1, _currentMessages.length);
    }

    // A failed turn never got a response_id, so the chain to resume from is
    // the last real reply before it.
    String? previousResponseId;
    for (var i = idx - 1; i >= 0; i--) {
      final m = _currentMessages[i];
      if (m.role == 'assistant' &&
          m.responseId != null &&
          !m.content.startsWith('Tool call:') &&
          !m.content.startsWith('MCP call:') &&
          !m.content.startsWith('🔧 MCP call:')) {
        previousResponseId = m.responseId;
        break;
      }
    }
    _currentConversation = _currentConversation!.copyWith(
      lastResponseId: previousResponseId,
      clearLastResponseId: previousResponseId == null,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(_currentConversation!);
    _syncConversationInList(_currentConversation!);
    _pendingAlternatives = null;
    notifyListeners();
  }

  /// User turns after the last reply (e.g. an earlier "Not delivered"
  /// message) are not in LM Studio's stored response chain. Rewind to a
  /// stateless send so they go out once as history with [userMessageId].
  Future<void> _includeUndeliveredTurnsInContext(String userMessageId) async {
    final conv = _currentConversation;
    if (conv == null || conv.lastResponseId == null) return;
    if (conv.settings['isGroupChat'] == true) return;
    final earlier =
        FailedMessages.undeliveredBefore(_currentMessages, userMessageId);
    if (earlier.isEmpty) return;
    debugPrint('📨 ${earlier.length} undelivered turn(s) before this send — '
        'resending history instead of previous_response_id');
    _sessionWarm = false;
    _currentConversation = conv.copyWith(clearLastResponseId: true);
    await _databaseService.updateConversation(_currentConversation!);
    _syncConversationInList(_currentConversation!);
  }

  /// After a send / retry / regenerate for [userMessageId] finished:
  /// * a reply exists → clear it (and earlier undelivered turns it carried);
  /// * an error and no reply → mark it "Not delivered";
  /// * otherwise (Stop with nothing yet) → leave as is.
  Future<void> _recordSendOutcome({
    required String? conversationId,
    required String? userMessageId,
  }) async {
    if (conversationId == null || userMessageId == null) return;
    try {
      final onScreen = _currentConversation?.id == conversationId;
      ChatConversation? conv;
      List<ChatMessage> messages;
      if (onScreen) {
        conv = _currentConversation;
        messages = _currentMessages;
      } else {
        // Switched chats mid-reply: read the origin chat fresh so a stale
        // copy never overwrites its lastResponseId.
        final all = await _databaseService.getAllConversations();
        conv = all.where((c) => c.id == conversationId).firstOrNull;
        messages =
            await _databaseService.getMessagesForConversation(conversationId);
      }
      if (conv == null) return;
      final failed = FailedMessages.read(conv.settings);
      Map<String, dynamic> next;
      if (!messages.any((m) => m.id == userMessageId)) {
        next = FailedMessages.withRemoved(conv.settings, [userMessageId]);
      } else if (FailedMessages.hasReplyAfter(messages, userMessageId)) {
        next = FailedMessages.withRemoved(
          conv.settings,
          FailedMessages.deliveredWith(messages, failed, userMessageId),
        );
      } else if (_error != null) {
        next = FailedMessages.withAdded(conv.settings, userMessageId);
      } else {
        return;
      }
      if (identical(next, conv.settings)) return;
      await _saveConversationSettings(conv, next, onScreen: onScreen);
    } catch (e) {
      debugPrint('ChatProvider: failed-message bookkeeping skipped: $e');
    }
  }

  /// Persist only the settings map (keeps updatedAt / lastResponseId).
  Future<void> _saveConversationSettings(
    ChatConversation conv,
    Map<String, dynamic> settings, {
    required bool onScreen,
  }) async {
    final updated = conv.copyWith(settings: settings);
    await _databaseService.updateConversation(updated);
    if (onScreen && _currentConversation?.id == updated.id) {
      // Re-read the live copy: the reply may have advanced lastResponseId.
      _currentConversation = _currentConversation!.copyWith(settings: settings);
      _syncConversationInList(_currentConversation!);
    } else {
      final i = _conversations.indexWhere((c) => c.id == updated.id);
      if (i != -1) {
        _conversations[i] = _conversations[i].copyWith(settings: settings);
      }
    }
  }
}
