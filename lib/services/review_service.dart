import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/review_prompt_dialog.dart';

/// Why [ReviewPromptPolicy.evaluate] declined to prompt.
enum ReviewSkipReason {
  notEnoughChats,
  notDueYet,
  alreadyPromptedThisVersion,
  tooSoonSinceLastPrompt,
  paywallOpen,
  paywallRecent,
  voiceActive,
  replyNotClean,
  recentError,
}

/// Pure review-prompt decision. No I/O, so it is unit-testable.
class ReviewPromptPolicy {
  /// Successful AI replies before the first prompt.
  static const int firstPromptThreshold = 3;

  /// Successful replies since the last prompt before asking again.
  static const int repeatPromptInterval = 20;

  /// Minimum days between prompts. Apple also caps SKStoreReviewController
  /// at 3 displays per 365 days; this keeps us well under that.
  static const int minDaysBetweenPrompts = 30;

  /// Never prompt this soon after the paywall was shown or dismissed.
  static const Duration paywallCooldown = Duration(minutes: 10);

  /// Never prompt this soon after a chat error was on screen.
  static const Duration errorCooldown = Duration(minutes: 10);

  /// Returns `null` when a prompt should be shown, otherwise the reason not to.
  static ReviewSkipReason? evaluate({
    required DateTime now,
    required int successfulChats,
    required int promptCount,
    required int? chatsAtLastPrompt,
    required String? lastPromptVersion,
    required DateTime? lastPromptDate,
    required String appVersion,
    required bool replyCompleted,
    required bool voiceActive,
    required bool paywallOpen,
    required DateTime? lastPaywallAt,
    required DateTime? lastErrorAt,
  }) {
    // Context guards first: never ask next to a paywall, mid-voice, or
    // after anything went wrong.
    if (!replyCompleted) return ReviewSkipReason.replyNotClean;
    if (voiceActive) return ReviewSkipReason.voiceActive;
    if (paywallOpen) return ReviewSkipReason.paywallOpen;
    if (lastPaywallAt != null &&
        now.difference(lastPaywallAt) < paywallCooldown) {
      return ReviewSkipReason.paywallRecent;
    }
    if (lastErrorAt != null && now.difference(lastErrorAt) < errorCooldown) {
      return ReviewSkipReason.recentError;
    }

    if (successfulChats < firstPromptThreshold) {
      return ReviewSkipReason.notEnoughChats;
    }

    if (promptCount > 0) {
      if (lastPromptVersion == appVersion) {
        return ReviewSkipReason.alreadyPromptedThisVersion;
      }
      // Older installs have no stored count; treat as 0 so the 30-day and
      // per-version gates decide.
      final sinceLast = successfulChats - (chatsAtLastPrompt ?? 0);
      if (sinceLast < repeatPromptInterval) {
        return ReviewSkipReason.notDueYet;
      }
    }

    if (lastPromptDate != null &&
        now.difference(lastPromptDate).inDays < minDaysBetweenPrompts) {
      return ReviewSkipReason.tooSoonSinceLastPrompt;
    }

    return null;
  }
}

/// Service that tracks successful chat completions and prompts
/// for an App Store / Play Store / Mac App Store review at appropriate moments.
class ReviewService {
  static const String _successfulChatsKey = 'successful_chat_count';
  static const String _lastReviewPromptVersionKey = 'last_review_prompt_version';
  static const String _lastReviewPromptDateKey = 'last_review_prompt_date';
  static const String _reviewPromptCountKey = 'review_prompt_count';
  static const String _reviewPromptChatCountKey = 'review_prompt_chat_count';

  // In-memory session signals (a cold start resets them, which is fine:
  // the cooldowns are minutes, not days).
  static int _paywallOpenCount = 0;
  static DateTime? _lastPaywallAt;
  static DateTime? _lastChatErrorAt;

  /// Call from the paywall's initState (and any purchase flow start).
  static void notePaywallOpened() {
    _paywallOpenCount++;
    _lastPaywallAt = DateTime.now();
  }

  /// Call from the paywall's dispose. Starts the post-paywall cooldown.
  static void notePaywallClosed() {
    if (_paywallOpenCount > 0) _paywallOpenCount--;
    _lastPaywallAt = DateTime.now();
  }

  /// Marks a paywall-adjacent moment (purchase, upsell nudge) without
  /// open/close pairing.
  static void notePaywallShown() {
    _lastPaywallAt = DateTime.now();
  }

  /// Call whenever a chat error is on screen.
  static void noteChatError() {
    _lastChatErrorAt = DateTime.now();
  }

  @visibleForTesting
  static void resetSessionSignals() {
    _paywallOpenCount = 0;
    _lastPaywallAt = null;
    _lastChatErrorAt = null;
  }

  final InAppReview _inAppReview = InAppReview.instance;

  /// Record a successful chat completion
  Future<void> recordSuccessfulChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_successfulChatsKey) ?? 0;
      await prefs.setInt(_successfulChatsKey, count + 1);
      debugPrint('ReviewService: Successful chats: ${count + 1}');
    } catch (e) {
      debugPrint('ReviewService: Error recording chat: $e');
    }
  }

  /// Get the current successful chat count
  Future<int> getSuccessfulChatCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_successfulChatsKey) ?? 0;
  }

  /// Check if we should prompt for a review and show it if appropriate.
  /// [context] is required on Android to show the pre-prompt dialog.
  /// [replyCompleted] must be false for cancelled / errored replies.
  /// Returns `true` when any rating UI was shown (including a declined
  /// Android pre-prompt), so callers can avoid stacking other dialogs.
  Future<bool> maybeRequestReview(
    BuildContext context, {
    bool replyCompleted = true,
    bool voiceActive = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final successfulChats = prefs.getInt(_successfulChatsKey) ?? 0;
      final promptCount = prefs.getInt(_reviewPromptCountKey) ?? 0;
      final lastPromptDateStr = prefs.getString(_lastReviewPromptDateKey);
      final appVersion = await _currentAppVersion();

      final skip = ReviewPromptPolicy.evaluate(
        now: DateTime.now(),
        successfulChats: successfulChats,
        promptCount: promptCount,
        chatsAtLastPrompt: prefs.getInt(_reviewPromptChatCountKey),
        lastPromptVersion: prefs.getString(_lastReviewPromptVersionKey),
        lastPromptDate: lastPromptDateStr == null
            ? null
            : DateTime.tryParse(lastPromptDateStr),
        appVersion: appVersion,
        replyCompleted: replyCompleted,
        voiceActive: voiceActive,
        paywallOpen: _paywallOpenCount > 0,
        lastPaywallAt: _lastPaywallAt,
        lastErrorAt: _lastChatErrorAt,
      );
      if (skip != null) {
        debugPrint(
            'ReviewService: Skip (${skip.name}, chats=$successfulChats)');
        return false;
      }

      debugPrint(
          'ReviewService: Requesting review (platform=${Platform.operatingSystem})');

      if (!kIsWeb && Platform.isAndroid) {
        if (!context.mounted) return false;
        final wantsToRate = await ReviewPromptDialog.show(context);
        await _recordPrompt(prefs, promptCount, appVersion, successfulChats);
        if (wantsToRate == true) await _launchReviewFlow();
        return true;
      }

      // iOS + macOS: SKStoreReviewController via in_app_review.
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        debugPrint('ReviewService: In-app review not available');
        return false;
      }

      await _inAppReview.requestReview();
      await _recordPrompt(prefs, promptCount, appVersion, successfulChats);
      return true;
    } catch (e) {
      debugPrint('ReviewService: Error requesting review: $e');
      return false;
    }
  }

  Future<void> _launchReviewFlow() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await openStoreListing();
      }
    } catch (e) {
      debugPrint('ReviewService: Review flow failed, opening store: $e');
      await openStoreListing();
    }
  }

  Future<void> _recordPrompt(
    SharedPreferences prefs,
    int promptCount,
    String appVersion,
    int successfulChats,
  ) async {
    await prefs.setString(_lastReviewPromptVersionKey, appVersion);
    await prefs.setString(
        _lastReviewPromptDateKey, DateTime.now().toIso8601String());
    await prefs.setInt(_reviewPromptCountKey, promptCount + 1);
    await prefs.setInt(_reviewPromptChatCountKey, successfulChats);
  }

  Future<String> _currentAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Open the App Store / Play Store page directly (for a "Rate Us" button in settings)
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: '6751125309',
      );
    } catch (e) {
      debugPrint('ReviewService: Error opening store listing: $e');
    }
  }
}
