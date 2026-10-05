import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_conversation.dart';
import '../models/chat_folder.dart';
import '../models/system_prompt.dart';
import '../pro/pro_features.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

class WidgetDataService {
  static const String appGroupId = 'group.net.neuro9.lmmini';

  /// Android [HomeWidgetProvider] class names — must match Kotlin receivers.
  static const List<String> androidWidgetNames = [
    'LMMiniWidgetProvider',
    'NewsWidgetProvider',
    'PersonasWidgetProvider',
    'FoldersWidgetProvider',
    'RecentsWidgetProvider',
  ];

  /// Widgets this build registers. The public build ships no News widget
  /// (the export drops its iOS bundle entry and Android receiver).
  static List<String> get _androidWidgets => [
        for (final name in androidWidgetNames)
          if (ProFeatures.included || name != 'NewsWidgetProvider') name,
      ];

  static bool _loggedMissingAndroidWidgetProvider = false;

  /// HomeWidget is only implemented on iOS and Android.
  static bool get _supportsHomeWidget => Platform.isIOS || Platform.isAndroid;

  // SharedPreferences keys
  static const String _kNewsPrompt = 'widget_news_prompt';
  static const String _kNewsContent = 'widget_news_content';
  static const String _kNewsTitle = 'widget_news_title';
  static const String _kNewsGeneratedAt = 'widget_news_generated_at';

  static Future<void> initialize() async {
    if (!_supportsHomeWidget) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  // --- STATS SYNC ---
  static Future<void> updateStats({
    int messageCountIncrement = 0,
    int tokensInIncrement = 0,
    int tokensOutIncrement = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    int totalMsg =
        (prefs.getInt('stat_total_messages') ?? 0) + messageCountIncrement;
    int totalIn =
        (prefs.getInt('stat_total_tokens_in') ?? 0) + tokensInIncrement;
    int totalOut =
        (prefs.getInt('stat_total_tokens_out') ?? 0) + tokensOutIncrement;

    await prefs.setInt('stat_total_messages', totalMsg);
    await prefs.setInt('stat_total_tokens_in', totalIn);
    await prefs.setInt('stat_total_tokens_out', totalOut);

    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<int>('total_messages', totalMsg);
    await HomeWidget.saveWidgetData<int>('total_tokens_in', totalIn);
    await HomeWidget.saveWidgetData<int>('total_tokens_out', totalOut);

    await _updateWidget();
  }

  // --- PERSONAS SYNC ---
  static Future<void> updatePersonas(List<SystemPrompt> allPrompts) async {
    final personas = allPrompts.where((p) => p.isPersona).take(6).toList();
    final List<Map<String, dynamic>> personaData = personas
        .map((p) => {
              'id': p.id,
              'name': p.name,
              'avatarPath': p.avatarPath,
              'color': p.color?.toRadixString(16),
            })
        .toList();

    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>(
        'personas_json', jsonEncode(personaData));
    await _updateWidget();
  }

  // --- RECENT CONVERSATIONS SYNC ---
  /// Sync the 3 most recently-updated conversations to the widget.
  /// Skips group chats so the widget always reflects a tappable single-chat.
  static Future<void> updateRecentConversations(
      List<ChatConversation> conversations) async {
    final recents = conversations
        .where((c) => !c.isGroupChat)
        .take(3)
        .map((c) => {
              'id': c.id,
              'title': c.title,
              'updatedAt': c.updatedAt.millisecondsSinceEpoch,
            })
        .toList();
    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>(
        'recent_conversations_json', jsonEncode(recents));
    await _updateWidget();
  }

  // --- TOP FOLDERS SYNC ---
  /// Sync the top folders (by conversation count) to the widget. Folders
  /// with zero conversations are filtered out.
  static Future<void> updateTopFolders(List<ChatFolder> folders) async {
    final sorted = [...folders]..sort(
        (a, b) => b.conversationIds.length.compareTo(a.conversationIds.length));
    final top = sorted
        .where((f) => f.conversationIds.isNotEmpty)
        .take(4)
        .map((f) => {
              'id': f.id,
              'name': f.name,
              'count': f.conversationIds.length,
              'color': f.color,
            })
        .toList();
    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>('folders_json', jsonEncode(top));
    await _updateWidget();
  }

  // --- NEWS WIDGET (PRO) ---
  static Future<String?> getNewsPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNewsPrompt);
  }

  static Future<void> saveNewsPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNewsPrompt, prompt.trim());
    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>('news_prompt', prompt.trim());
    await _updateWidget();
  }

  static Future<void> saveNewsContent({
    required String title,
    required String body,
    DateTime? generatedAt,
  }) async {
    final at = generatedAt ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNewsTitle, title);
    await prefs.setString(_kNewsContent, body);
    await prefs.setInt(_kNewsGeneratedAt, at.millisecondsSinceEpoch);
    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>('news_title', title);
    await HomeWidget.saveWidgetData<String>('news_content', body);
    await HomeWidget.saveWidgetData<int>(
        'news_generated_at', at.millisecondsSinceEpoch);
    await _updateWidget();
  }

  static Future<Map<String, dynamic>?> getNewsContent() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString(_kNewsTitle);
    final body = prefs.getString(_kNewsContent);
    final at = prefs.getInt(_kNewsGeneratedAt);
    if (title == null && body == null) return null;
    return {
      'title': title ?? '',
      'body': body ?? '',
      'generatedAt':
          at != null ? DateTime.fromMillisecondsSinceEpoch(at) : null,
    };
  }

  // --- AUTOMATED PROMPT SYNC ---
  static Future<void> saveAutomatedPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_automated_prompt', prompt);
    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>('automated_prompt', prompt);
    await _updateWidget();
  }

  static Future<String?> getAutomatedPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('widget_automated_prompt');
  }

  static Future<void> saveAutomatedResponse(String response) async {
    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>('automated_response', response);
    await _updateWidget();
  }

  // --- PREMIUM SYNC ---
  static Future<void> syncPremiumStatus() async {
    if (!_supportsHomeWidget) return;
    final isPremium = SubscriptionService().isPremium;
    await HomeWidget.saveWidgetData<bool>('is_premium', isPremium);
    await _updateWidget();
  }

  static Future<void> _updateWidget() async {
    if (!_supportsHomeWidget) return;
    if (Platform.isAndroid) {
      for (final name in _androidWidgets) {
        try {
          await HomeWidget.updateWidget(name: name);
        } catch (e) {
          final message = e.toString();
          final missingAndroidProvider =
              message.contains('No Widget found with Name') ||
                  message.contains('AppWidgetProvider') ||
                  message.contains('WidgetProvider');

          if (missingAndroidProvider) {
            if (!_loggedMissingAndroidWidgetProvider) {
              debugPrint(
                'WidgetDataService: Android widget "$name" not found. '
                'Skipping remaining refresh calls.',
              );
              _loggedMissingAndroidWidgetProvider = true;
            }
            return;
          }
          rethrow;
        }
      }
      return;
    }

    // Reload every WidgetKit kind we ship so secondary widgets (News,
    // Personas, etc.) pick up data changes too.
    final iosKinds = [
      'LMWidget',
      if (ProFeatures.included) 'NewsWidget',
      'PersonasWidget',
      'TopFoldersWidget',
      'RecentConversationsWidget',
    ];
    for (final kind in iosKinds) {
      await HomeWidget.updateWidget(
        name: androidWidgetNames.first,
        iOSName: kind,
      );
    }
  }
}
