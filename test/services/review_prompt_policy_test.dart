import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/review_service.dart';

void main() {
  final now = DateTime(2026, 10, 6, 12);

  ReviewSkipReason? evaluate({
    int successfulChats = 3,
    int promptCount = 0,
    int? chatsAtLastPrompt,
    String? lastPromptVersion,
    DateTime? lastPromptDate,
    String appVersion = '1.9.11',
    bool replyCompleted = true,
    bool voiceActive = false,
    bool paywallOpen = false,
    DateTime? lastPaywallAt,
    DateTime? lastErrorAt,
  }) =>
      ReviewPromptPolicy.evaluate(
        now: now,
        successfulChats: successfulChats,
        promptCount: promptCount,
        chatsAtLastPrompt: chatsAtLastPrompt,
        lastPromptVersion: lastPromptVersion,
        lastPromptDate: lastPromptDate,
        appVersion: appVersion,
        replyCompleted: replyCompleted,
        voiceActive: voiceActive,
        paywallOpen: paywallOpen,
        lastPaywallAt: lastPaywallAt,
        lastErrorAt: lastErrorAt,
      );

  group('first prompt', () {
    test('not before the 3rd successful reply', () {
      expect(evaluate(successfulChats: 2), ReviewSkipReason.notEnoughChats);
    });

    test('fires on the 3rd successful reply', () {
      expect(evaluate(successfulChats: 3), isNull);
    });

    test('still fires later if the 3rd reply was suppressed', () {
      expect(evaluate(successfulChats: 7), isNull);
    });
  });

  group('never next to a paywall / voice / error', () {
    test('paywall open', () {
      expect(evaluate(paywallOpen: true), ReviewSkipReason.paywallOpen);
    });

    test('paywall dismissed 5 minutes ago', () {
      expect(
        evaluate(lastPaywallAt: now.subtract(const Duration(minutes: 5))),
        ReviewSkipReason.paywallRecent,
      );
    });

    test('paywall dismissed 11 minutes ago is fine', () {
      expect(
        evaluate(lastPaywallAt: now.subtract(const Duration(minutes: 11))),
        isNull,
      );
    });

    test('voice mode active', () {
      expect(evaluate(voiceActive: true), ReviewSkipReason.voiceActive);
    });

    test('cancelled or errored reply', () {
      expect(evaluate(replyCompleted: false), ReviewSkipReason.replyNotClean);
    });

    test('recent chat error (e.g. cold start into a failed connection)', () {
      expect(
        evaluate(lastErrorAt: now.subtract(const Duration(minutes: 2))),
        ReviewSkipReason.recentError,
      );
      expect(
        evaluate(lastErrorAt: now.subtract(const Duration(minutes: 15))),
        isNull,
      );
    });

    test('context guards win even when a prompt is due', () {
      expect(
        evaluate(successfulChats: 50, paywallOpen: true),
        ReviewSkipReason.paywallOpen,
      );
    });
  });

  group('repeat prompts', () {
    final longAgo = now.subtract(const Duration(days: 60));

    test('same app version never prompts twice', () {
      expect(
        evaluate(
          successfulChats: 100,
          promptCount: 1,
          chatsAtLastPrompt: 3,
          lastPromptVersion: '1.9.11',
          lastPromptDate: longAgo,
        ),
        ReviewSkipReason.alreadyPromptedThisVersion,
      );
    });

    test('needs 20 more replies since the last prompt', () {
      expect(
        evaluate(
          successfulChats: 22,
          promptCount: 1,
          chatsAtLastPrompt: 3,
          lastPromptVersion: '1.9.10',
          lastPromptDate: longAgo,
        ),
        ReviewSkipReason.notDueYet,
      );
      expect(
        evaluate(
          successfulChats: 23,
          promptCount: 1,
          chatsAtLastPrompt: 3,
          lastPromptVersion: '1.9.10',
          lastPromptDate: longAgo,
        ),
        isNull,
      );
    });

    test('at least 30 days apart', () {
      expect(
        evaluate(
          successfulChats: 80,
          promptCount: 1,
          chatsAtLastPrompt: 3,
          lastPromptVersion: '1.9.10',
          lastPromptDate: now.subtract(const Duration(days: 29)),
        ),
        ReviewSkipReason.tooSoonSinceLastPrompt,
      );
    });

    test('legacy installs without a stored chat count still work', () {
      expect(
        evaluate(
          successfulChats: 25,
          promptCount: 1,
          lastPromptVersion: '1.9.0',
          lastPromptDate: longAgo,
        ),
        isNull,
      );
    });
  });
}
