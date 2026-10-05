import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/lm_studio_model.dart';
import '../models/system_prompt.dart';
import '../pro/pro_features.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/image_generation_facade.dart';
import '../services/image_generation_service.dart';
import '../utils/app_navigator.dart';
import '../utils/image_gen_unreachable_error.dart';
import '../utils/chat_image_compress.dart';
import '../utils/chat_title.dart';
import '../utils/image_picker_helper.dart';
import '../utils/persona_appearance.dart';
import '../utils/remote_host_backends.dart';
import '../utils/response_parser.dart';

/// Phone side of the watch chat list.
///
/// The watch asks for a short list, one thread, or a send. Chats stay in
/// Mini's database. The watch only receives titles and recent text.
class WatchBridge {
  WatchBridge._();

  static const channelName = 'net.neuro9.lmmini/watch';
  static const MethodChannel _channel = MethodChannel(channelName);
  static const _noticeKey = 'watch_available_notice_v1';
  static bool _installed = false;

  /// A paired Apple Watch that has not already been told about the watch app.
  /// Null when the notice was dismissed, there is no paired watch, or this
  /// is not iOS. [installed] is whether LM Mini is already on that watch.
  static Future<({bool installed})?> watchAvailability() async {
    if (kIsWeb || !Platform.isIOS) return null;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_noticeKey) == true) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>('watchStatus');
      if (raw is! Map) return null;
      final paired = raw['paired'] == true;
      if (!paired) return null;
      return (installed: raw['installed'] == true);
    } catch (_) {
      return null;
    }
  }

  static Future<void> markWatchNoticeShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_noticeKey, true);
  }

  static void install() {
    if (_installed || kIsWeb || !Platform.isIOS) return;
    _installed = true;
    _channel.setMethodCallHandler(_handle);
  }

  static Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case 'listChats':
        return _listChats();
      case 'persona':
        final args = _args(call.arguments);
        return _openPersona(args['personaId']?.toString() ?? '');
      case 'openChat':
        final args = _args(call.arguments);
        return _openChat(args['conversationId']?.toString() ?? '');
      case 'send':
        final args = _args(call.arguments);
        final id = await _prepare(args);
        final requestId = args['requestId']?.toString() ?? '';
        final image = args['image']?.toString().trim() ?? '';
        Future<void>.delayed(Duration.zero, () {
          unawaited(_generate(
            id,
            args['text']?.toString() ?? '',
            requestId,
            image: image,
          ));
        });
        return {'conversationId': id};
      case 'regenerate':
        final args = _args(call.arguments);
        final id = await _prepare(args);
        final requestId = args['requestId']?.toString() ?? '';
        final messageId = args['messageId']?.toString() ?? '';
        Future<void>.delayed(Duration.zero, () {
          unawaited(_regenerate(id, requestId, messageId));
        });
        return {'conversationId': id};
      case 'edit':
        final args = _args(call.arguments);
        final id = await _prepare(args);
        final requestId = args['requestId']?.toString() ?? '';
        Future<void>.delayed(Duration.zero, () {
          unawaited(_edit(
            id,
            requestId,
            args['messageId']?.toString() ?? '',
            args['text']?.toString() ?? '',
          ));
        });
        return {'conversationId': id};
      case 'delete':
        final args = _args(call.arguments);
        await _prepare(args);
        final messageId = args['messageId']?.toString() ?? '';
        final chat = _chat();
        final before = chat.currentMessages.length;
        await chat.deleteSingleMessage(messageId);
        if (chat.currentMessages.length == before) {
          throw PlatformException(
            code: 'missing',
            message: 'That message is not on the iPhone.',
          );
        }
        await _push('removed', {
          'requestId': args['requestId']?.toString() ?? '',
          'messageId': messageId,
        });
        return {'ok': true};
      case 'branch':
        final args = _args(call.arguments);
        await _prepare(args);
        if (!SubscriptionService().isPremium) {
          throw PlatformException(
            code: 'pro',
            message: 'Branching needs Pro on the iPhone.',
          );
        }
        final newId = await _chat().branchFromMessage(
          args['messageId']?.toString() ?? '',
        );
        if (newId == null || newId.isEmpty) {
          throw PlatformException(
            code: 'missing',
            message: 'That message is not on the iPhone.',
          );
        }
        return {'conversationId': newId};
      case 'imagine':
        final args = _args(call.arguments);
        return _imagine(args);
      default:
        throw PlatformException(
          code: 'unknown',
          message: 'Unknown watch request.',
        );
    }
  }

  static Map<String, dynamic> _args(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static Future<Map<String, Object>> _listChats() async {
    final chat = _chat();
    final settings = _settings().settings;
    if (chat.conversations.isEmpty) {
      await chat.loadConversations(silent: true);
    }
    final sorted = List<ChatConversation>.from(chat.listedConversations)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final byId = {
      for (final conversation in sorted) conversation.id: conversation
    };
    final page = sorted.take(30).toList();
    await chat.refreshAssistantPreviews(ids: page.map((c) => c.id));
    final rows = <Map<String, Object>>[];
    for (final conversation in page) {
      final group = conversation.isGroupChat;
      final persona = group
          ? null
          : PersonaAppearance.boundPersona(
              settings: settings,
              conversationSettings: conversation.settings,
            );
      final names = WatchPayload.groupNames(conversation.settings);
      final stored = WatchPayload.rowAvatarPaths(
        group: group,
        personaPath: persona?.avatarPath,
        conversationSettings: conversation.settings,
        globalAssistantPath: settings.assistantAvatarPath,
      );
      final faces = <String>[];
      for (final path in stored) {
        final file = await ImagePickerHelper.resolveImagePath(path);
        if (file != null && file.isNotEmpty) faces.add(file);
      }
      final last = WatchPayload.homeSnippet(
        chat.assistantPreviewFor(conversation.id) ?? '',
      );
      rows.add(
        WatchPayload.chatRow(
          id: conversation.id,
          title: WatchPayload.generatedTitle(conversation, byId),
          persona: persona?.name ?? '',
          preview: group && names.isNotEmpty ? names : last,
          updatedMs: conversation.updatedAt.millisecondsSinceEpoch,
          folderId: conversation.folderId,
          group: group,
          branch: conversation.parentConversationId != null,
          avatar: faces.isNotEmpty ? faces.first : '',
          avatar2: faces.length > 1 ? faces[1] : '',
          color: group
              ? WatchPayload.groupColor(conversation.settings)
              : persona?.color,
        ),
      );
    }
    final folders = await DatabaseService().getAllFolders();
    final personas = <Map<String, Object>>[];
    for (final prompt
        in settings.savedSystemPrompts ?? const <SystemPrompt>[]) {
      if (!prompt.isPersona) continue;
      final file = await ImagePickerHelper.resolveImagePath(prompt.avatarPath);
      personas.add(
        WatchPayload.personaCard(
          persona: prompt,
          settings: settings,
          avatar: file ?? '',
        ),
      );
      if (personas.length == 40) break;
    }
    return {
      'chats': rows,
      'personas': personas,
      'folders': [
        for (final folder in folders)
          WatchPayload.folderRow(
            id: folder.id,
            name: folder.name,
            count: sorted.where((c) => c.folderId == folder.id).length,
          ),
      ],
      'look': await WatchPayload.lookFor(settings: settings),
    };
  }

  static Future<Map<String, Object>> _openChat(String id) async {
    if (id.isEmpty) {
      throw PlatformException(code: 'missing', message: 'Missing chat.');
    }
    final messages = await DatabaseService().getMessagesForConversation(id);
    ChatConversation? conversation;
    for (final item in _chat().conversations) {
      if (item.id == id) {
        conversation = item;
        break;
      }
    }
    final items = WatchPayload.messageRows(messages);
    await WatchPayload.prepareMessageImages(items, messages);
    return {
      'items': items,
      'title': conversation?.title ?? '',
      'look': await WatchPayload.lookFor(
        settings: _settings().settings,
        conversationSettings: conversation?.settings,
      ),
    };
  }

  static SystemPrompt? _persona(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    for (final prompt
        in _settings().settings.savedSystemPrompts ?? const <SystemPrompt>[]) {
      if (prompt.id == trimmed) return prompt;
    }
    return null;
  }

  static Future<Map<String, Object>> _openPersona(String id) async {
    final persona = _persona(id);
    if (persona == null) {
      throw PlatformException(
        code: 'missing',
        message: 'That persona is not on the iPhone.',
      );
    }
    final settings = _settings();
    await settings.applyPersonaPreferredSettings(persona);
    final chat = _chat();
    await chat.createNewConversation(
      title: persona.name,
      settings: settings.settings,
      systemPromptId: persona.id,
    );
    final conversation = chat.currentConversation;
    if (conversation == null) {
      throw PlatformException(
        code: 'missing',
        message: 'Could not start that chat.',
      );
    }
    return {
      'conversationId': conversation.id,
      'look': await WatchPayload.lookFor(
        settings: settings.settings,
        conversationSettings: conversation.settings,
      ),
    };
  }

  static Future<String> _prepare(Map<String, dynamic> args) async {
    final chat = _chat();
    final settings = _settings();
    if (chat.isSendingMessage) {
      throw PlatformException(
        code: 'busy',
        message: 'LM Mini is already answering.',
      );
    }
    final requested = (args['conversationId']?.toString() ?? '').trim();
    final personaId = (args['personaId']?.toString() ?? '').trim();
    if (requested.isEmpty) {
      final persona = personaId.isEmpty ? null : _persona(personaId);
      if (persona != null) {
        await settings.applyPersonaPreferredSettings(persona);
        await chat.createNewConversation(
          title: persona.name,
          settings: settings.settings,
          systemPromptId: persona.id,
        );
      } else {
        await chat.createNewConversation(settings: settings.settings);
      }
    } else if (chat.currentConversation?.id != requested) {
      await chat.selectConversation(requested);
    }
    final conversation = chat.currentConversation;
    if (conversation == null ||
        (requested.isNotEmpty && conversation.id != requested)) {
      throw PlatformException(
        code: 'missing',
        message: 'That chat is no longer on the iPhone.',
      );
    }
    return conversation.id;
  }

  static Future<void> _generate(
    String conversationId,
    String text,
    String requestId, {
    String image = '',
  }) async {
    final chat = _chat();
    final settings = _settings();
    await _watchTurn(conversationId, requestId, () {
      return chat.sendMessage(
        text,
        settings.settings,
        imageUrls:
            image.isEmpty ? null : <String>['data:image/jpeg;base64,$image'],
        settingsProvider: settings,
        uiContext: rootNavigatorKey.currentContext,
      );
    });
  }

  static Future<void> _regenerate(
    String conversationId,
    String requestId,
    String messageId,
  ) async {
    final chat = _chat();
    final settings = _settings();
    await _watchTurn(conversationId, requestId, () {
      if (chat.currentConversation?.isGroupChat == true) {
        return chat.regenerateFromGroupMessage(
          messageId,
          settings.settings,
          uiContext: rootNavigatorKey.currentContext,
        );
      }
      return chat.regenerateLastResponse(
        settings.settings,
        settingsProvider: settings,
        uiContext: rootNavigatorKey.currentContext,
      );
    });
  }

  static Future<void> _edit(
    String conversationId,
    String requestId,
    String messageId,
    String text,
  ) async {
    final chat = _chat();
    final settings = _settings();
    await _watchTurn(conversationId, requestId, () {
      return chat.editMessage(
        messageId,
        text,
        settings.settings,
        andRegenerate: true,
        settingsProvider: settings,
        uiContext: rootNavigatorKey.currentContext,
      );
    });
  }

  static Future<void> _watchTurn(
    String conversationId,
    String requestId,
    Future<void> Function() run,
  ) async {
    try {
      final chat = _chat();
      final before = chat.currentMessages.map((m) => m.id).toSet();
      var pushed = '';
      var chain = Future<void>.value();

      var pushedThinking = '';
      void publish({bool force = false}) {
        final full = _newAssistantText(chat, before) ?? '';
        final thinking =
            WatchPayload.clip(_assistantThinking(chat, before), 800);
        final answerChanged = full != pushed;
        final thoughtChanged = thinking != pushedThinking;
        if (!answerChanged && !thoughtChanged) return;
        if (full.isEmpty && thinking.isEmpty) return;
        final replace = pushed.isNotEmpty && !full.startsWith(pushed);
        final chunk = replace
            ? full
            : (full.startsWith(pushed) ? full.substring(pushed.length) : full);
        if (!force &&
            !thoughtChanged &&
            !replace &&
            chunk.length < 24 &&
            chat.isSendingMessage) {
          return;
        }
        pushed = full;
        pushedThinking = thinking;
        chain = chain.then((_) => _push('delta', {
              'requestId': requestId,
              'text': chunk,
              'replace': replace,
              if (thinking.isNotEmpty) 'thinking': thinking,
            }));
      }

      void listener() => publish();
      chat.addListener(listener);
      try {
        await run();
        publish(force: true);
        await chain;
        final full = _newAssistantText(chat, before) ?? '';
        final created = _newestAssistant(chat, before);
        final thinking = WatchPayload.clip(
          created == null ? '' : _thinkingOf(created),
          800,
        );
        if (full.isEmpty && thinking.isEmpty) {
          final err = chat.error?.trim();
          await _push('done', {
            'requestId': requestId,
            'conversationId': conversationId,
            'error': (err == null || err.isEmpty)
                ? 'The model returned an empty reply.'
                : err,
          });
          return;
        }
        final userId = _newestUserId(chat, before);
        await _push('done', {
          'requestId': requestId,
          'conversationId': conversationId,
          'fullText': WatchPayload.clip(full, 3500),
          if (created != null) 'messageId': created.id,
          if (userId != null) 'userMessageId': userId,
          if (thinking.isNotEmpty) 'thinking': thinking,
          if (created != null)
            'imagePrompt': WatchPayload.clip(created.imagePrompt ?? '', 400),
        });
      } finally {
        chat.removeListener(listener);
      }
    } catch (e) {
      await _push('done', {
        'requestId': requestId,
        'conversationId': conversationId,
        'error': e.toString(),
      });
    }
  }

  static String? _newestUserId(ChatProvider chat, Set<String> before) {
    String? id;
    for (final message in chat.currentMessages) {
      if (message.role != 'user') continue;
      if (before.contains(message.id)) continue;
      id = message.id;
    }
    return id;
  }

  static ChatMessage? _newestAssistant(ChatProvider chat, Set<String> before) {
    for (var i = chat.currentMessages.length - 1; i >= 0; i--) {
      final message = chat.currentMessages[i];
      if (message.role != 'assistant') continue;
      if (before.contains(message.id)) continue;
      return message;
    }
    return null;
  }

  static String _assistantThinking(ChatProvider chat, Set<String> before) {
    final message = _newestAssistant(chat, before);
    if (message == null) return '';
    return _thinkingOf(message);
  }

  static String _thinkingOf(ChatMessage message) {
    return (ResponseParser.parse(message.content).thinking ?? '').trim();
  }

  static String? _newAssistantText(ChatProvider chat, Set<String> before) {
    for (var i = chat.currentMessages.length - 1; i >= 0; i--) {
      final message = chat.currentMessages[i];
      if (message.role != 'assistant') continue;
      if (before.contains(message.id)) continue;
      final text = WatchPayload.transcript(
        ResponseParser.answerOnly(message.content),
      );
      if (text.isEmpty) continue;
      return text;
    }
    return null;
  }

  static Future<Map<String, Object>> _imagine(Map<String, dynamic> args) async {
    final requestId = args['requestId']?.toString() ?? '';
    final prompt = (args['prompt']?.toString() ?? '').trim();
    if (prompt.isEmpty) {
      throw PlatformException(code: 'missing', message: 'Type a prompt first.');
    }
    final settings = _settings().settings;
    if (!settings.imageGenEnabled) {
      throw PlatformException(
        code: 'off',
        message: 'Image generation is turned off on the iPhone.',
      );
    }
    if (!settings.isImageGenReady) {
      throw PlatformException(
        code: 'off',
        message: 'Set up image generation on the iPhone first.',
      );
    }

    await _push('imagineStatus', {
      'requestId': requestId,
      'state': 'starting',
    });
    final conversationId = await _prepare(args);
    final chat = _chat();
    final effective = chat.settingsForImageGeneration(settings);
    await _push('imagineStatus', {
      'requestId': requestId,
      'state': 'generating',
    });

    try {
      final result = await generateImageForSettings(
        settings: effective,
        params: Txt2ImgParams(
          prompt: prompt,
          negativePrompt: effective.effectiveImageGenNegativePrompt,
          steps: effective.imageGenSteps,
          cfgScale: effective.imageGenCfgScale,
          width: effective.imageGenWidth,
          height: effective.imageGenHeight,
          samplerName: effective.imageGenSamplerName,
          scheduler: effective.imageGenScheduler,
          seed: effective.imageGenSeed,
          batchSize: effective.imageGenBatchSize,
          enableHr: effective.imageGenEnableHr,
          hrScale: effective.imageGenHrScale,
          hrUpscaler: effective.imageGenHrUpscaler,
          denoisingStrength: effective.imageGenDenoisingStrength,
          restoreFaces: effective.imageGenRestoreFaces,
          tiling: effective.imageGenTiling,
          loraName: effective.comfyUiLoraName,
          loraWeight: effective.comfyUiLoraWeight,
        ),
      );
      final now = DateTime.now();
      final assistantId = '${now.microsecondsSinceEpoch + 1}';
      final paths = await ImageGenerationService().saveImages(
        result.allImages,
        assistantId,
      );
      if (paths.isEmpty) {
        throw PlatformException(
          code: 'failed',
          message: 'The image server returned no image.',
        );
      }
      await chat.appendMessagesToCurrent([
        ChatMessage(
          id: now.microsecondsSinceEpoch.toString(),
          content: prompt,
          role: 'user',
          timestamp: now,
        ),
        ChatMessage(
          id: assistantId,
          content: '',
          role: 'assistant',
          timestamp: now.add(const Duration(milliseconds: 1)),
          imagePrompt: prompt,
          generatedImagePath: paths.first,
          generatedImagePaths: paths,
          generatedImageInfo: result.info,
        ),
      ]);
      return {
        'conversationId': conversationId,
        'path': paths.first,
      };
    } catch (e) {
      throw PlatformException(code: 'failed', message: watchError(e));
    }
  }

  static String watchError(Object error) {
    if (error is ImageGenUnreachableError) return error.userMessage;
    if (error is PlatformException) {
      return error.message ?? 'Image generation failed.';
    }
    return WatchPayload.clip(error.toString(), 180);
  }

  /// Push the Apple Watch toggles so an open watch updates without a refresh.
  static Future<void> syncWatchPrefs() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final settings = _settings().settings;
      await _push('look', {
        'fullWidth': !settings.watchAssistantInBubble,
        'watchPersonas': settings.watchShowPersonas,
      });
    } catch (_) {}
  }

  static Future<void> _push(String method, Map<String, Object> args) async {
    try {
      await _channel.invokeMethod(method, args);
    } catch (e) {
      if (kDebugMode) debugPrint('WatchBridge.$method: $e');
    }
  }

  static ChatProvider _chat() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      throw PlatformException(
        code: 'unavailable',
        message: 'Open LM Mini on the iPhone, then try again.',
      );
    }
    return context.read<ChatProvider>();
  }

  static SettingsProvider _settings() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      throw PlatformException(
        code: 'unavailable',
        message: 'Open LM Mini on the iPhone, then try again.',
      );
    }
    return context.read<SettingsProvider>();
  }
}

class WatchPayload {
  static String clip(String text, int max) {
    final trimmed = text.trim();
    if (max <= 0 || trimmed.isEmpty) return '';
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max).trimRight()}…';
  }

  /// Thread text for the watch. Keeps Markdown and line breaks. List titles
  /// still go through [homeSnippet], which flattens to one line.
  static String transcript(String text) {
    return ResponseParser.stripHiddenModelTags(text)
        .replaceAll('\r\n', '\n')
        .trim();
  }

  static Map<String, Object> chatRow({
    required String id,
    required String title,
    required String persona,
    required String preview,
    required int updatedMs,
    String? folderId,
    bool group = false,
    bool branch = false,
    String avatar = '',
    String avatar2 = '',
    int? color,
  }) {
    final who = group ? '' : persona.trim();
    final name = homeSnippet(title);
    final primary = who.isNotEmpty ? who : (name.isEmpty ? 'New Chat' : name);
    var secondary = homeSnippet(preview);
    if (who.isNotEmpty &&
        name.isNotEmpty &&
        name != who &&
        name != 'New Chat') {
      secondary = name;
    }
    if (secondary.isEmpty) secondary = 'New chat';
    final row = <String, Object>{
      'id': id,
      'title': clip(primary, 80),
      'preview': clip(secondary, 120),
      'updated': updatedMs,
    };
    final folder = folderId?.trim() ?? '';
    if (folder.isNotEmpty) row['folderId'] = folder;
    if (group) row['group'] = true;
    if (branch) row['branch'] = true;
    if (avatar.isNotEmpty) row['avatar'] = avatar;
    if (avatar2.isNotEmpty) row['avatar2'] = avatar2;
    if (color != null) row['color'] = color;
    return row;
  }

  static String homeSnippet(String text) => ChatTitle.homeSnippet(text);

  static String generatedTitle(
    ChatConversation conversation,
    Map<String, ChatConversation> byId,
  ) =>
      ChatTitle.generatedTitle(conversation, byId);

  static String groupNames(Map<String, dynamic>? settings) {
    final raw = settings?['participants'];
    if (raw is! List) return '';
    final names = <String>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final name = (item['displayName'] ?? '').toString().trim();
      if (name.isNotEmpty) names.add(name);
    }
    return names.join(', ');
  }

  static int? groupColor(Map<String, dynamic>? settings) {
    final raw = settings?['participants'];
    if (raw is! List) return null;
    for (final item in raw) {
      if (item is! Map) continue;
      final color = PersonaAppearance.parseColor(item['color']);
      if (color != null) return color;
    }
    return null;
  }

  /// Up to two image paths for a home-row face.
  ///
  /// A group uses the first participants who have a picture. A one-to-one
  /// chat uses the persona, then that chat's picture, then the global one.
  static List<String> rowAvatarPaths({
    required bool group,
    String? personaPath,
    Map<String, dynamic>? conversationSettings,
    String? globalAssistantPath,
  }) {
    if (group) {
      final raw = conversationSettings?['participants'];
      if (raw is! List) return const [];
      final paths = <String>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final path = item['avatarPath'];
        if (path is String && path.trim().isNotEmpty) {
          paths.add(path.trim());
        }
        if (paths.length == 2) break;
      }
      return paths;
    }
    final one = avatarStored(
      personaPath: personaPath,
      conversationSettings: conversationSettings,
      globalAssistantPath: globalAssistantPath,
    );
    if (one == null || one.isEmpty) return const [];
    return [one];
  }

  static Map<String, Object> folderRow({
    required String id,
    required String name,
    required int count,
  }) {
    final label = name.trim().isEmpty ? 'Folder' : name.trim();
    return {
      'id': id,
      'name': clip(label, 40),
      'count': count,
    };
  }

  /// Wallpaper path to resolve.
  ///
  /// A missing per-chat key uses the global wallpaper. An empty per-chat
  /// value means that chat has no wallpaper.
  static String? wallpaperStored({
    Map<String, dynamic>? conversationSettings,
    String? globalPath,
  }) {
    final chat = conversationSettings;
    if (chat != null && chat.containsKey('chatBackground')) {
      final value = chat['chatBackground'];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return '';
    }
    final global = globalPath?.trim() ?? '';
    return global.isEmpty ? null : global;
  }

  static String? avatarStored({
    String? personaPath,
    Map<String, dynamic>? conversationSettings,
    String? globalAssistantPath,
  }) {
    final persona = personaPath?.trim() ?? '';
    if (persona.isNotEmpty) return persona;
    final chatAvatar = conversationSettings?['assistantAvatar'];
    if (chatAvatar is String && chatAvatar.trim().isNotEmpty) {
      return chatAvatar.trim();
    }
    final global = globalAssistantPath?.trim() ?? '';
    return global.isEmpty ? null : global;
  }

  static Future<Map<String, Object>> lookFor({
    required AppSettings settings,
    Map<String, dynamic>? conversationSettings,
  }) async {
    final group = conversationSettings?['isGroupChat'] == true;
    final persona = group
        ? null
        : PersonaAppearance.boundPersona(
            settings: settings,
            conversationSettings: conversationSettings,
          );
    final wallpaper = await ImagePickerHelper.resolveImagePath(
      wallpaperStored(
        conversationSettings: conversationSettings,
        globalPath: settings.chatBackgroundPath,
      ),
    );
    final faces = rowAvatarPaths(
      group: group,
      personaPath: persona?.avatarPath,
      conversationSettings: conversationSettings,
      globalAssistantPath: settings.assistantAvatarPath,
    );
    final avatar = await ImagePickerHelper.resolveImagePath(
      faces.isEmpty ? null : faces.first,
    );
    final dim = (conversationSettings?['backgroundOverlayOpacity'] as num?)
            ?.toDouble() ??
        settings.chatBackgroundOverlayOpacity;
    final pinnedModel = (persona?.defaultModelId ?? '').trim().isNotEmpty;
    final pinnedProvider =
        (persona?.defaultProviderKind ?? '').trim().isNotEmpty;
    final look = <String, Object>{
      'fullWidth': !settings.watchAssistantInBubble,
      'watchPersonas': settings.watchShowPersonas,
      'dim': dim.round().clamp(0, 100),
      'wallpaper': wallpaper ?? '',
      'avatar': avatar ?? '',
      'imageGen': settings.isImageGenReady,
      'group': group,
      // The public build cannot branch; the watch hides its Branch action.
      'canBranch': ProFeatures.included,
      'personaId': persona?.id ?? '',
      'personaName':
          group ? groupNames(conversationSettings) : (persona?.name ?? ''),
      'prompt': group ? '' : clip(persona?.content ?? '', 800),
      'model': group
          ? ''
          : modelLabel(
              pinnedModel ? persona?.defaultModelId : settings.selectedModel,
            ),
      'provider': group
          ? ''
          : providerLabel(
              pinnedProvider
                  ? persona?.defaultProviderKind
                  : settings.activeProviderKind,
            ),
      'modelPinned': pinnedModel,
      'providerPinned': pinnedProvider,
    };
    final color =
        persona?.color ?? (group ? groupColor(conversationSettings) : null);
    if (color != null) look['color'] = color;
    return look;
  }

  static Map<String, Object> personaCard({
    required SystemPrompt persona,
    required AppSettings settings,
    String avatar = '',
  }) {
    final pinnedModel = (persona.defaultModelId ?? '').trim().isNotEmpty;
    final pinnedProvider =
        (persona.defaultProviderKind ?? '').trim().isNotEmpty;
    final row = <String, Object>{
      'id': persona.id,
      'name': clip(persona.name, 40),
      'prompt': clip(persona.content, 800),
      'model': modelLabel(
        pinnedModel ? persona.defaultModelId : settings.selectedModel,
      ),
      'provider': providerLabel(
        pinnedProvider
            ? persona.defaultProviderKind
            : settings.activeProviderKind,
      ),
      'modelPinned': pinnedModel,
      'providerPinned': pinnedProvider,
    };
    if (avatar.isNotEmpty) row['avatar'] = avatar;
    if (persona.color != null) row['color'] = persona.color!;
    return row;
  }

  /// A short provider name for the watch profile.
  static String providerLabel(String? kind) {
    final value = kind?.trim() ?? '';
    if (value.isEmpty) return '';
    if (value == 'cloud') return 'Cloud';
    return RemoteHostBackends.displayName(value);
  }

  /// A short model name. File paths keep only the file name.
  static String modelLabel(String? modelId) {
    final value = modelId?.trim() ?? '';
    if (value.isEmpty) return '';
    return LMStudioModel.friendlyLabel(value);
  }

  static const messageBody = 3500;
  static const transcriptBudget = 40000;

  static List<Map<String, Object>> messageRows(List<ChatMessage> messages) {
    final visible =
        messages.where((m) => m.role == 'user' || m.role == 'assistant');
    final tail = visible.length <= 20
        ? visible.toList()
        : visible.skip(visible.length - 20).toList();
    final rows = <Map<String, Object>>[];
    var budget = transcriptBudget;
    for (final message in tail.reversed) {
      if (budget <= 0) break;
      final parsed = ResponseParser.parse(message.content);
      final room = budget < messageBody ? budget : messageBody;
      final text = clip(transcript(parsed.answer), room);
      final thinking = clip(transcript(parsed.thinking ?? ''), 800);
      final prompt = clip(message.imagePrompt ?? '', 400);
      final hasImage = (message.imageUrls?.isNotEmpty ?? false) ||
          message.hasGeneratedImages;
      budget -= text.length;
      rows.add({
        'id': message.id,
        'role': message.role,
        'text': text,
        'hasImage': hasImage,
        if (thinking.isNotEmpty) 'thinking': thinking,
        if (prompt.isNotEmpty) 'imagePrompt': prompt,
      });
    }
    return _withoutImagePromptEcho(rows.reversed.toList());
  }

  /// The watch stores the image prompt on the picture message. The matching
  /// user line is the same prompt and should not appear as a chat bubble.
  static List<Map<String, Object>> _withoutImagePromptEcho(
    List<Map<String, Object>> rows,
  ) {
    final hidden = <int>{};
    for (var i = 0; i < rows.length - 1; i++) {
      if (rows[i]['role'] != 'user') continue;
      final next = rows[i + 1];
      if (next['hasImage'] != true) continue;
      final prompt = (next['imagePrompt'] as String? ?? '').trim();
      final userText = (rows[i]['text'] as String? ?? '').trim();
      if (prompt.isNotEmpty && userText == prompt) hidden.add(i);
    }
    if (hidden.isEmpty) return rows;
    return [
      for (var i = 0; i < rows.length; i++)
        if (!hidden.contains(i)) rows[i],
    ];
  }

  /// Puts a filesystem path on the newest image messages so the phone can
  /// send a small preview. Data URLs are written to a temp JPEG first.
  static Future<void> prepareMessageImages(
    List<Map<String, Object>> rows,
    List<ChatMessage> messages,
  ) async {
    final byId = {for (final message in messages) message.id: message};
    var remaining = 6;
    for (var i = rows.length - 1; i >= 0 && remaining > 0; i--) {
      final id = rows[i]['id'] as String? ?? '';
      final message = byId[id];
      if (message == null) continue;
      final hasImage = (message.imageUrls?.isNotEmpty ?? false) ||
          message.hasGeneratedImages;
      if (!hasImage) continue;
      final path = await _messageImageFile(message);
      if (path.isEmpty) continue;
      rows[i]['image'] = path;
      remaining--;
    }
  }

  static Future<String> _messageImageFile(ChatMessage message) async {
    for (final stored in message.allGeneratedImagePaths) {
      final resolved = await _resolveStoredImage(stored);
      if (resolved != null) return resolved;
    }
    for (final url in message.imageUrls ?? const <String>[]) {
      final trimmed = url.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('data:')) {
        final written = await _writePreviewFile(message.id, trimmed);
        if (written != null) return written;
        continue;
      }
      final resolved = await _resolveStoredImage(trimmed);
      if (resolved != null) return resolved;
    }
    return '';
  }

  static Future<String?> _resolveStoredImage(String stored) async {
    final direct = await ImagePickerHelper.resolveImagePath(stored);
    if (direct != null) return direct;
    final name = stored.split('/').last;
    if (name.isEmpty) return null;
    final docs = await getApplicationDocumentsDirectory();
    final generated = File('${docs.path}/generated_images/$name');
    if (await generated.exists()) return generated.path;
    return null;
  }

  static Future<String?> _writePreviewFile(String id, String dataUrl) async {
    final bytes = await ChatImageCompress.bytesFromUrl(dataUrl);
    if (bytes == null || bytes.isEmpty) return null;
    final jpeg = await ChatImageCompress.compressBytes(
      bytes,
      edge: 240,
      quality: 55,
    );
    final payload = jpeg ?? bytes;
    if (payload.isEmpty) return null;
    final dir = await getTemporaryDirectory();
    final folder = Directory('${dir.path}/watch-message-previews');
    if (!await folder.exists()) await folder.create(recursive: true);
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${folder.path}/$safe.jpg');
    await file.writeAsBytes(payload, flush: true);
    return file.path;
  }
}
