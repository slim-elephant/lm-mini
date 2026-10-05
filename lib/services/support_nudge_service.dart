import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pro/pro_features.dart';

/// Data class for a milestone nudge to show the user.
class MilestoneNudge {
  final String headline;
  final String subtitle;
  final int totalChats;
  final int daysUsing;
  final bool isDayMilestone; // true = day milestone, false = chat milestone

  const MilestoneNudge({
    required this.headline,
    required this.subtitle,
    required this.totalChats,
    required this.daysUsing,
    this.isDayMilestone = false,
  });
}

/// Tracks usage milestones and decides when to show "Support LM Mini" nudges.
///
/// Two types of milestones:
/// - **Chat milestones**: every 50 conversations (50, 100, 150, ...)
/// - **Day milestones**: 7, 30, 90, 180, 365 days since first use
///
/// Each milestone is shown only once. Premium users never see nudges.
class SupportNudgeService {
  static const String _firstUseDateKey = 'support_nudge_first_use';
  static const String _lastChatMilestoneKey = 'support_nudge_last_chat_milestone';
  static const String _shownDayMilestonesKey = 'support_nudge_shown_day_milestones';
  static const String _lastNudgeDateKey = 'support_nudge_last_date';

  /// Chat milestone interval
  static const int _chatInterval = 50;

  /// Day milestones to celebrate
  static const List<int> _dayMilestones = [7, 30, 90, 180, 365];

  /// Minimum days between any nudge (avoid spamming)
  static const int _minDaysBetweenNudges = 7;

  /// Record first use date if not already set.
  Future<void> ensureFirstUseTracked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_firstUseDateKey)) {
        await prefs.setString(_firstUseDateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint('SupportNudge: Error tracking first use: $e');
    }
  }

  /// Check if a milestone nudge should be shown after a successful chat.
  /// Returns a [MilestoneNudge] or null if no nudge is due.
  Future<MilestoneNudge?> checkMilestone(int currentChatCount) async {
    // Premium users (and public builds, which have no Pro) never see nudges.
    if (!ProFeatures.showUpsell) return null;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Ensure first use is tracked
      if (!prefs.containsKey(_firstUseDateKey)) {
        await prefs.setString(_firstUseDateKey, DateTime.now().toIso8601String());
      }

      // Don't nudge too often
      final lastNudgeStr = prefs.getString(_lastNudgeDateKey);
      if (lastNudgeStr != null) {
        final daysSince = DateTime.now().difference(DateTime.parse(lastNudgeStr)).inDays;
        if (daysSince < _minDaysBetweenNudges) return null;
      }

      final daysUsing = _getDaysUsing(prefs);

      // Check chat milestone first (every 50 chats)
      final lastChatMilestone = prefs.getInt(_lastChatMilestoneKey) ?? 0;
      final nextChatMilestone = lastChatMilestone + _chatInterval;
      if (currentChatCount >= nextChatMilestone && nextChatMilestone > 0) {
        await prefs.setInt(_lastChatMilestoneKey, nextChatMilestone);
        await prefs.setString(_lastNudgeDateKey, DateTime.now().toIso8601String());
        return MilestoneNudge(
          headline: _chatHeadline(nextChatMilestone),
          subtitle: _chatSubtitle(nextChatMilestone),
          totalChats: currentChatCount,
          daysUsing: daysUsing,
        );
      }

      // Check day milestones
      final shownDayMilestones = prefs.getStringList(_shownDayMilestonesKey) ?? [];
      for (final dayTarget in _dayMilestones) {
        if (daysUsing >= dayTarget && !shownDayMilestones.contains(dayTarget.toString())) {
          shownDayMilestones.add(dayTarget.toString());
          await prefs.setStringList(_shownDayMilestonesKey, shownDayMilestones);
          await prefs.setString(_lastNudgeDateKey, DateTime.now().toIso8601String());
          return MilestoneNudge(
            headline: _dayHeadline(dayTarget),
            subtitle: _daySubtitle(dayTarget),
            totalChats: currentChatCount,
            daysUsing: daysUsing,
            isDayMilestone: true,
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('SupportNudge: Error checking milestone: $e');
      return null;
    }
  }

  int _getDaysUsing(SharedPreferences prefs) {
    final firstUseStr = prefs.getString(_firstUseDateKey);
    if (firstUseStr == null) return 0;
    return DateTime.now().difference(DateTime.parse(firstUseStr)).inDays;
  }

  // ─── Headlines & subtitles ────────────────────────────────────────

  String _chatHeadline(int count) {
    if (count >= 500) return '🎉 $count conversations!';
    if (count >= 200) return '🚀 $count conversations!';
    if (count >= 100) return '💯 $count conversations!';
    return '🎉 $count conversations!';
  }

  String _chatSubtitle(int count) {
    if (count >= 500) return "You're a power user — LM Mini runs because of people like you.";
    if (count >= 200) return 'LM Mini is clearly part of your workflow now.';
    if (count >= 100) return "That's a lot of AI chats — glad LM Mini is useful!";
    return "You've been putting LM Mini to work!";
  }

  String _dayHeadline(int days) {
    if (days >= 365) return '🎂 1 year with LM Mini!';
    if (days >= 180) return '✨ 6 months with LM Mini!';
    if (days >= 90) return '🌟 3 months with LM Mini!';
    if (days >= 30) return '🎉 1 month with LM Mini!';
    return '👋 1 week with LM Mini!';
  }

  String _daySubtitle(int days) {
    if (days >= 365) return "A whole year of local AI. You're incredible.";
    if (days >= 180) return 'Half a year of privacy-first AI chat.';
    if (days >= 90) return "Three months in — you're a dedicated user.";
    if (days >= 30) return 'A month of local AI conversations!';
    return 'Welcome to the LM Mini community!';
  }
}
