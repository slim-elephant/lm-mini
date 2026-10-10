import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/utils/failed_messages.dart';

ChatMessage _m(String id, String role, [String content = 'x']) => ChatMessage(
      id: id,
      content: content,
      role: role,
      timestamp: DateTime(2026),
    );

void main() {
  group('FailedMessages settings map', () {
    test('read tolerates missing / bad data', () {
      expect(FailedMessages.read(null), isEmpty);
      expect(FailedMessages.read({}), isEmpty);
      expect(FailedMessages.read({'failedMessageIds': 'nope'}), isEmpty);
      expect(
        FailedMessages.read({
          'failedMessageIds': ['a', 1, '', 'b'],
        }),
        {'a', 'b'},
      );
    });

    test('add keeps other settings and is idempotent', () {
      final base = <String, dynamic>{'model': 'qwen'};
      final once = FailedMessages.withAdded(base, 'u1');
      expect(once['model'], 'qwen');
      expect(FailedMessages.read(once), {'u1'});
      final twice = FailedMessages.withAdded(once, 'u1');
      expect(identical(twice, once), isTrue);
      expect(base.containsKey('failedMessageIds'), isFalse);
    });

    test('remove drops the key when empty, no-op when absent', () {
      final s = FailedMessages.withAdded(
          FailedMessages.withAdded({'a': 1}, 'u1'), 'u2');
      final one = FailedMessages.withRemoved(s, ['u1']);
      expect(FailedMessages.read(one), {'u2'});
      final none = FailedMessages.withRemoved(one, ['u2']);
      expect(none.containsKey('failedMessageIds'), isFalse);
      expect(none['a'], 1);
      expect(identical(FailedMessages.withRemoved(none, ['zz']), none), isTrue);
    });
  });

  group('replies', () {
    test('assistant text after the user turn is a reply', () {
      final msgs = [_m('u1', 'user'), _m('a1', 'assistant', 'hello')];
      expect(FailedMessages.hasReplyAfter(msgs, 'u1'), isTrue);
    });

    test('empty, temp and tool-call messages are not replies', () {
      final msgs = [
        _m('u1', 'user'),
        _m('a0', 'assistant', '   '),
        _m('temp_1', 'assistant', 'partial'),
        _m('t1', 'assistant', 'Tool call: web_search'),
        _m('t2', 'tool', 'result'),
      ];
      expect(FailedMessages.hasReplyAfter(msgs, 'u1'), isFalse);
    });

    test('a reply after a later user turn does not count', () {
      final msgs = [
        _m('u1', 'user'),
        _m('u2', 'user'),
        _m('a1', 'assistant', 'hi'),
      ];
      expect(FailedMessages.hasReplyAfter(msgs, 'u1'), isFalse);
      expect(FailedMessages.hasReplyAfter(msgs, 'u2'), isTrue);
    });
  });

  group('consecutive failures ("hi", "hello")', () {
    final msgs = [
      _m('u0', 'user'),
      _m('a0', 'assistant', 'earlier reply'),
      _m('hi', 'user', 'hi'),
      _m('hello', 'user', 'hello'),
    ];

    test('earlier undelivered turns are found back to the last reply', () {
      expect(FailedMessages.undeliveredBefore(msgs, 'hello'), ['hi']);
      expect(FailedMessages.undeliveredBefore(msgs, 'hi'), isEmpty);
    });

    test('a reply to "hello" clears "hello" and the failed "hi"', () {
      final withReply = [...msgs, _m('a1', 'assistant', 'hey')];
      final cleared = FailedMessages.deliveredWith(
        withReply,
        {'hi', 'hello', 'u0'},
        'hello',
      );
      expect(cleared, {'hello', 'hi'});
    });
  });

  group('retryPlan', () {
    test('latest failed user turn → replay in place', () {
      final msgs = [
        _m('a0', 'assistant', 'hello'),
        _m('u1', 'user'),
      ];
      expect(FailedMessages.retryPlan(msgs, 'u1'),
          FailedRetryPlan.replayInPlace);
    });

    test('only tool noise / temp after it → still in place', () {
      final msgs = [
        _m('u1', 'user'),
        _m('t1', 'assistant', 'Tool call: x'),
        _m('temp_9', 'assistant', ''),
      ];
      expect(FailedMessages.retryPlan(msgs, 'u1'),
          FailedRetryPlan.replayInPlace);
    });

    test('earlier failed turn (later messages exist) → resend at bottom', () {
      final msgs = [
        _m('u1', 'user'),
        _m('u2', 'user'),
      ];
      expect(FailedMessages.retryPlan(msgs, 'u1'),
          FailedRetryPlan.resendAtBottom);
      final withReply = [
        _m('u1', 'user'),
        _m('a1', 'assistant', 'reply'),
      ];
      expect(FailedMessages.retryPlan(withReply, 'u1'),
          FailedRetryPlan.resendAtBottom);
    });

    test('missing or non-user → none', () {
      final msgs = [_m('a1', 'assistant', 'x')];
      expect(FailedMessages.retryPlan(msgs, 'a1'), FailedRetryPlan.none);
      expect(FailedMessages.retryPlan(msgs, 'zz'), FailedRetryPlan.none);
    });
  });
}
