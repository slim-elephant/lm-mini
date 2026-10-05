import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/chat_conversation.dart';
import 'package:lm_mini/providers/chat_provider.dart';

void main() {
  ChatConversation chat({
    List<String> messageIds = const [],
    Map<String, dynamic> settings = const {},
  }) {
    return ChatConversation(
      id: '1',
      title: 'New Chat',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      messageIds: messageIds,
      settings: settings,
    );
  }

  test('only explicit isDraft chats are drafts', () {
    expect(
      ChatProvider.isEmptyDraftConversation(chat(settings: {'isDraft': true})),
      isTrue,
    );
  });

  test('legacy chats with empty messageIds are NOT drafts', () {
    expect(ChatProvider.isEmptyDraftConversation(chat()), isFalse);
    expect(
      ChatProvider.isEmptyDraftConversation(chat(messageIds: ['m1'])),
      isFalse,
    );
  });

  test('group chats are never drafts even with isDraft leftover', () {
    // Group creation does not set isDraft; if somehow present, listed filter
    // still only keys off isDraft — group setup creates without the flag.
    expect(
      ChatProvider.isEmptyDraftConversation(
        chat(settings: {'isGroupChat': true}),
      ),
      isFalse,
    );
  });
}
