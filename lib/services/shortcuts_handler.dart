import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../pro/pro_features.dart';
import '../screens/chat_screen.dart';
import '../services/call_service.dart';
import '../services/local_model_download_service.dart';
import '../services/on_device_mlx_endpoint.dart';
import '../services/tool_support_resolver.dart';
import '../services/tts_service.dart';
import '../utils/response_parser.dart';
import '../utils/transcription_launcher.dart';
import 'apple_intelligence_endpoint.dart';
import 'lm_studio_service.dart';
import 'news_widget_service.dart';
import 'on_device_llm_service.dart';
import 'siri_inference_snapshot.dart';
import 'siri_intent_bridge.dart';
import 'widget_data_service.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

/// Routes `lmmini://shortcut/<path>?…` URLs (sent from Shortcuts via the
/// "Open URL" action OR from native iOS App Intents) to the right
/// underlying model pipeline, then surfaces the result.
///
/// Supported paths (Phase A — URL deep links):
///
///   /ask?prompt=...&onDevice=1
///        One-shot prompt against the user's active provider. Result is
///        copied to the clipboard and shown in a dialog with Copy/Share
///        actions.
///
///   /summarize?text=...&style=bullets|paragraph|tweet
///        Summarize the supplied text with a fixed "be concise" system
///        prompt. `style` defaults to `bullets`.
///
///   /translate?text=...&to=Spanish
///        Translate text into the requested target language.
///
///   /news?topics=ai,science
///        Refresh the News widget content (Pro). Topics override the
///        configured news prompt for this run only.
///
///   /voice?callMode=1&onDevice=1&persona=ID&conversationId=ID&prompt=...
///        Open voice conversation mode. Optional params select CallKit,
///        on-device provider, persona, existing chat, or first message.
///
///   /ask?prompt=...&onDevice=1&speak=1
///        One-shot ask; `speak=1` reads the answer aloud when done.
///
///   /search?query=...&speak=1
///        Web search via the full chat tool loop (Pro Search / SearXNG),
///        then optionally read the answer aloud. Uses the active provider.
///
///   /transcribe?path=/path/to/audio.m4a
///        Open the transcribe flow or start from a file path (iOS/Android).
///
/// The handler is intentionally provider-agnostic: it consults the
/// currently-active provider (LM Studio / on-device / cloud) via
/// [SettingsProvider] so a Shortcut behaves identically to typing in the
/// app. Pro-gated paths short-circuit with an informative dialog when
/// the user isn't subscribed.
class ShortcutsHandler {
  ShortcutsHandler._();
  static final ShortcutsHandler instance = ShortcutsHandler._();

  /// When true, skip in-app progress/result chrome — Siri is waiting on
  /// the App Group for the string.
  bool _silentSiri = false;

  /// Entry point invoked from `HomeScreen._handleDeepLinkAction` when a
  /// `DeepLinkAction.runShortcut` event arrives. [arg] is the full
  /// `lmmini://shortcut/...` URL string (preserving query encoding).
  Future<void> handle(BuildContext context, String? arg) async {
    if (arg == null || arg.isEmpty) return;
    final uri = Uri.tryParse(arg);
    if (uri == null) return;

    // Accept both `lmmini://shortcut/ask` and `lmmini://shortcut/ask` where
    // the path segments are `/ask` — Uri parses both consistently as
    // pathSegments == ['ask'].
    final segments = uri.pathSegments;
    if (segments.isEmpty) return;
    final kind = segments.first.toLowerCase();
    _silentSiri = SiriIntentBridge.isWaiting(uri);

    try {
      switch (kind) {
        case 'ask':
          await _runAsk(context, uri);
          break;
        case 'summarize':
          await _runSummarize(context, uri);
          break;
        case 'translate':
          await _runTranslate(context, uri);
          break;
        case 'news':
          await _runNewsRefresh(context, uri);
          break;
        case 'voice':
          await _runVoice(context, uri);
          break;
        case 'search':
          await _runSearch(context, uri);
          break;
        case 'transcribe':
          await _runTranscribe(context, uri);
          break;
        default:
          await _reject(context, uri, 'Unknown shortcut: /$kind');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('ShortcutsHandler error: $e\n$st');
      await SiriIntentBridge.failUri(uri, e);
      if (context.mounted && !SiriIntentBridge.isWaiting(uri)) {
        _showError(context, e.toString());
      }
    }
  }

  // ─── Individual shortcut implementations ─────────────────────────

  Future<void> _runAsk(BuildContext context, Uri uri) async {
    final prompt = (uri.queryParameters['prompt'] ?? '').trim();
    if (prompt.isEmpty) {
      await _reject(context, uri, 'Missing `prompt` parameter.');
      return;
    }
    final forceOnDevice = _isTruthy(uri.queryParameters['onDevice']);
    final speakAloud = _isTruthy(uri.queryParameters['speak']);
    final silent = SiriIntentBridge.isWaiting(uri);
    final result = await _runPrompt(
      context,
      systemPrompt: 'You are a helpful assistant. Reply concisely.',
      userPrompt: prompt,
      forceOnDevice: forceOnDevice,
      progressLabel: 'Thinking…',
      silent: silent,
    );
    await _deliver(
      context,
      uri,
      title: 'Ask LM Mini',
      body: result,
      speakAloud: speakAloud,
    );
  }

  Future<void> _runSummarize(BuildContext context, Uri uri) async {
    final text = (uri.queryParameters['text'] ?? '').trim();
    if (text.isEmpty) {
      await _reject(context, uri, 'Missing `text` parameter.');
      return;
    }
    final style = (uri.queryParameters['style'] ?? 'bullets').toLowerCase();
    final styleInstruction = switch (style) {
      'paragraph' => 'as a single tight paragraph (~3 sentences)',
      'tweet' => 'as one tweet under 240 characters',
      _ => 'as 3–5 short bullet points',
    };
    final system = 'You are an expert summarizer. Summarize the user\'s text '
        '$styleInstruction. Use plain language. Do not add commentary.';
    final result = await _runPrompt(
      context,
      systemPrompt: system,
      userPrompt: text,
      progressLabel: 'Summarizing…',
      silent: SiriIntentBridge.isWaiting(uri),
    );
    await _deliver(context, uri, title: 'Summary', body: result);
  }

  Future<void> _runTranslate(BuildContext context, Uri uri) async {
    final text = (uri.queryParameters['text'] ?? '').trim();
    final target = (uri.queryParameters['to'] ?? '').trim();
    if (text.isEmpty || target.isEmpty) {
      await _reject(context, uri, 'Missing `text` or `to` parameter.');
      return;
    }
    final system = 'You are a professional translator. Translate the user\'s '
        'text into $target. Output ONLY the translation — no notes, no '
        'quotation marks, no explanations.';
    final result = await _runPrompt(
      context,
      systemPrompt: system,
      userPrompt: text,
      progressLabel: 'Translating to $target…',
      silent: SiriIntentBridge.isWaiting(uri),
    );
    await _deliver(context, uri, title: 'Translation', body: result);
  }

  Future<void> _runNewsRefresh(BuildContext context, Uri uri) async {
    if (!ProFeatures.included) {
      await _reject(context, uri,
          'The News widget is available in the official LM Mini app.');
      return;
    }
    final topics = (uri.queryParameters['topics'] ?? '').trim();
    final overridePrompt = topics.isEmpty
        ? null
        : 'Brief me on the latest news for these topics: $topics. '
            'Return 5–10 bullet points with sources.';
    _showProgress(context, 'Refreshing news widget…');
    try {
      if (overridePrompt != null) {
        await NewsWidgetService.instance.refreshNow(overridePrompt);
      } else {
        await NewsWidgetService.instance.refreshIfPossible(force: true);
      }
      final cached = await WidgetDataService.getNewsContent();
      if (context.mounted && !_silentSiri) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final title = cached?['title'] as String? ?? 'News updated';
      final body = cached?['body'] as String? ?? '(no content)';
      await _deliver(context, uri, title: title, body: body);
    } catch (e) {
      if (context.mounted && !_silentSiri) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      rethrow;
    }
  }

  Future<void> _runSearch(BuildContext context, Uri uri) async {
    final query =
        (uri.queryParameters['query'] ?? uri.queryParameters['prompt'] ?? '')
            .trim();
    if (query.isEmpty) {
      await _reject(context, uri, 'Missing `query` parameter.');
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (_isTruthy(uri.queryParameters['onDevice'])) {
      final ok = await _activateOnDeviceProvider(settingsProvider);
      if (!ok) {
        await _reject(
          context,
          uri,
          'No on-device model is ready. Download one from Settings → '
          'On-Device Models first.',
        );
        return;
      }
    } else if (!await _ensureProviderReady(context, settingsProvider)) {
      await SiriIntentBridge.failUri(
        uri,
        'Provider is not ready. Open LM Mini and check Settings.',
      );
      return;
    }

    final settings = settingsProvider.settings;
    if (!_canRunWebSearch(settings)) {
      await _reject(
        context,
        uri,
        ProFeatures.included
            ? 'Web search is not available. LM Mini Pro users can use Pro Search '
                '(Settings → Tools → Web Search). Others need a SearXNG URL '
                'configured and a tool-capable model.'
            : 'Web search is not available. Configure a SearXNG URL '
                '(Settings → Tools → Web Search) and use a tool-capable model.',
      );
      return;
    }
    if (!ToolSupportResolver.instance.currentModelSupportsTools(settings)) {
      await _reject(
        context,
        uri,
        'The active model does not support web search. Switch to a '
        'tool-capable model or a cloud provider.',
      );
      return;
    }

    // Search defaults to spoken output; pass speak=0 to disable.
    // Siri wait path already speaks via IntentDialog.
    final speakAloud = uri.queryParameters.containsKey('speak')
        ? _isTruthy(uri.queryParameters['speak'])
        : !_silentSiri;

    _showProgress(context, 'Searching the web…');
    try {
      final title = query.length > 48
          ? 'Search: ${query.substring(0, 48)}…'
          : 'Search: $query';
      await chatProvider.createNewConversation(title: title);
      final chatSettings = Map<String, dynamic>.from(
        chatProvider.currentConversation?.settings ?? {},
      );
      chatSettings['enableWebSearch'] = true;
      chatSettings['enableToolUse'] = true;
      await chatProvider.updateChatSettings(chatSettings);

      final searchPrompt = 'Search the web for: $query\n\n'
          'Use web_search to find current information, then give a concise '
          'answer suitable for being read aloud (2–4 sentences or short '
          'bullet points). Cite key facts; do not mention tools or search '
          'steps.';

      final runSettings = settings.copyWith(
        enableWebSearch: true,
        enableToolUse: true,
      );
      await chatProvider.sendMessage(
        searchPrompt,
        runSettings,
        settingsProvider: settingsProvider,
        uiContext: context,
      );

      if (context.mounted && !_silentSiri) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (chatProvider.error != null) {
        await _reject(context, uri, chatProvider.error!);
        return;
      }

      final answer = _extractLastAssistantReply(chatProvider);
      if (answer == null || answer.trim().isEmpty) {
        await _reject(context, uri, 'No response from the model.');
        return;
      }

      await _deliver(
        context,
        uri,
        title: 'Search',
        body: answer,
        speakAloud: speakAloud,
      );
    } catch (e) {
      if (context.mounted && !_silentSiri) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      rethrow;
    }
  }

  Future<void> _runTranscribe(BuildContext context, Uri uri) async {
    final path = (uri.queryParameters['path'] ?? '').trim();
    if (path.isEmpty) {
      await TranscriptionLauncher.openTranscribeFlow(context);
      return;
    }
    await TranscriptionLauncher.startTranscriptionFromFile(context, path);
  }

  Future<void> _runVoice(BuildContext context, Uri uri) async {
    final settingsProvider = context.read<SettingsProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (_isTruthy(uri.queryParameters['onDevice'])) {
      final ok = await _activateOnDeviceProvider(settingsProvider);
      if (!ok) {
        _showError(
          context,
          'No on-device model is ready. Download one from Settings → '
          'On-Device Models first.',
        );
        return;
      }
    } else if (!await _ensureProviderReady(context, settingsProvider)) {
      return;
    }

    final callMode =
        CallService.isOffered && _isTruthy(uri.queryParameters['callMode']);
    if (callMode) {
      settingsProvider.updateVoiceCallMode(true);
    }

    final personaId = (uri.queryParameters['persona'] ?? '').trim();
    final conversationId = (uri.queryParameters['conversationId'] ?? '').trim();
    final initialPrompt = (uri.queryParameters['prompt'] ?? '').trim();

    String? targetConversationId;

    if (conversationId.isNotEmpty) {
      await chatProvider.loadConversations();
      final exists =
          chatProvider.conversations.any((c) => c.id == conversationId);
      if (!exists) {
        _showError(context, 'Conversation not found.');
        return;
      }
      targetConversationId = conversationId;
    } else if (personaId.isNotEmpty) {
      final applied = await _applyPersona(settingsProvider, personaId);
      if (!applied) {
        _showError(context, 'Persona not found: $personaId');
        return;
      }
      await chatProvider.createNewConversation();
      targetConversationId = chatProvider.currentConversation?.id;
    } else {
      await chatProvider.createNewConversation();
      targetConversationId = chatProvider.currentConversation?.id;
    }

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: targetConversationId,
          openInVoiceMode: true,
          openInCallMode: callMode,
          initialVoicePrompt: initialPrompt.isEmpty ? null : initialPrompt,
        ),
      ),
    );
  }

  Future<bool> _applyPersona(
      SettingsProvider settingsProvider, String personaId) async {
    final personas = settingsProvider.settings.savedSystemPrompts ?? [];
    final matches =
        personas.where((p) => p.id == personaId).toList(growable: false);
    if (matches.isEmpty) return false;
    await settingsProvider.applyPersonaPreferredSettings(matches.first);
    return true;
  }

  Future<bool> _activateOnDeviceProvider(SettingsProvider sp) async {
    await LocalModelDownloadService.instance.init();
    final hasReady = LocalModelDownloadService.instance.readyEntries.isNotEmpty;
    if (!hasReady) return false;

    final kind = sp.settings.activeProviderKind;
    if (kind != 'onDeviceGguf' && kind != 'onDeviceMlx') {
      final mlxOk = await OnDeviceMlxEndpoint.isPlatformSupported();
      final newKind = mlxOk ? 'onDeviceMlx' : 'onDeviceGguf';
      await sp.updateSettings(
        sp.settings.copyWith(activeProviderKind: newKind),
      );
      CloudApiService().setActiveProvider(null);
    } else {
      final reconciled = await sp.reconcileOnDeviceSelection(sp.settings);
      if (reconciled != sp.settings) {
        await sp.updateSettings(reconciled);
      }
    }

    return OnDeviceLLMService.instance.specForSettings(sp.settings) != null;
  }

  Future<bool> _ensureProviderReady(
      BuildContext context, SettingsProvider sp) async {
    final s = sp.settings;
    final kind = s.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      return _activateOnDeviceProvider(sp);
    }
    if (kind == 'appleIntelligence') return true;
    if (SettingsProvider.isCloudProviderKind(kind)) {
      if (sp.isCloudProviderReady()) return true;
      _showError(context, 'Configure a cloud provider in Settings first.');
      return false;
    }
    if (s.serverUrl.trim().isEmpty) {
      _showError(context, 'No model server configured.');
      return false;
    }
    return true;
  }

  bool _canRunWebSearch(AppSettings settings) {
    if (settings.useMcpToolsOnly) return false;

    final hasSearxng = settings.searxngUrl?.trim().isNotEmpty == true;
    final isPremium = SubscriptionService().isPremium;
    final kind = settings.activeProviderKind;

    if (kind == 'appleIntelligence') return false;

    if (isPremium && !(settings.preferSearxng && hasSearxng)) {
      if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
        return hasSearxng;
      }
      return true;
    }

    return hasSearxng;
  }

  String? _extractLastAssistantReply(ChatProvider chatProvider) {
    for (var i = chatProvider.currentMessages.length - 1; i >= 0; i--) {
      final message = chatProvider.currentMessages[i];
      if (message.role != 'assistant') continue;
      final content = message.content.trim();
      if (content.isEmpty) continue;
      if (content.startsWith('Tool call:')) continue;
      return content;
    }
    return null;
  }

  Future<void> _speakText(BuildContext context, String text) async {
    final settings = context.read<SettingsProvider>().settings;
    final clean = ResponseParser.cleanForTts(
      ResponseParser.parse(text).answer,
    );
    if (clean.trim().isEmpty) return;

    final tts = TtsService();
    await tts.initialize();
    await tts.setSpeechRate(settings.voiceSpeechRate);
    await tts.setPitch(settings.voicePitch);
    await tts.setLanguage(settings.voiceLanguage);
    if (settings.voiceName != null) {
      await tts.setVoice(settings.voiceName);
    }
    await tts.speak(clean);
  }

  // ─── Provider routing ────────────────────────────────────────────

  Future<String> _runPrompt(
    BuildContext context, {
    required String systemPrompt,
    required String userPrompt,
    String progressLabel = 'Working…',
    bool forceOnDevice = false,
    bool silent = false,
  }) async {
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;
    if (!silent) _showProgress(context, progressLabel);
    try {
      String out;
      final useOnDevice = forceOnDevice ||
          settings.activeProviderKind == 'onDeviceGguf' ||
          settings.activeProviderKind == 'onDeviceMlx';
      final kind = settings.activeProviderKind;

      if (useOnDevice) {
        final ready = await OnDeviceLLMService.instance.isReady(settings);
        if (!ready) {
          throw StateError(
            'No on-device model is ready. Download one from Settings → '
            'On-Device Models first.',
          );
        }
        final buf = StringBuffer();
        await for (final delta in OnDeviceLLMService.instance.streamChat(
          settings: settings,
          history: const [],
          userMessage: userPrompt,
          systemPrompt: systemPrompt,
        )) {
          buf.write(delta);
        }
        out = buf.toString();
      } else if (kind == 'appleIntelligence') {
        final buf = StringBuffer();
        final prompt = '$systemPrompt\n\n$userPrompt';
        await for (final delta in AppleIntelligenceEndpoint().streamCompletion(
          prompt: prompt,
        )) {
          buf.write(delta);
        }
        out = buf.toString();
      } else {
        final snap = SiriInferenceSnapshot.from(
          settings: settings,
          cloud: settingsProvider.resolveCloudProvider(),
          forceOnDevice: forceOnDevice,
        );
        if (snap.chatUrl != null &&
            snap.chatUrl!.isNotEmpty &&
            (snap.model?.isNotEmpty ?? false)) {
          out = await _postOpenAiOneShot(
            snap,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
          );
        } else {
          out = await _runLmStudioOneShot(settings, systemPrompt, userPrompt);
        }
      }
      return out.trim();
    } finally {
      if (!silent && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<String> _postOpenAiOneShot(
    SiriInferenceSnapshot snap, {
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final response = await http
        .post(
          Uri.parse(snap.chatUrl!),
          headers: snap.headers,
          body: jsonEncode({
            'model': snap.model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': snap.temperature,
            'max_tokens': snap.maxTokens,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (response.statusCode != 200) {
      throw StateError(
        'The model server returned HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final content = decoded['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final msg = first['message'];
          if (msg is Map && msg['content'] is String) {
            return (msg['content'] as String).trim();
          }
        }
      }
    }
    throw StateError('Unexpected response shape from server.');
  }

  Future<String> _runLmStudioOneShot(
    AppSettings settings,
    String systemPrompt,
    String userPrompt,
  ) async {
    if (settings.serverUrl.trim().isEmpty) {
      throw StateError('No model server configured.');
    }
    final lm = LMStudioService();
    final now = DateTime.now();
    final messages = <ChatMessage>[
      ChatMessage(
        id: '${now.microsecondsSinceEpoch}-sys',
        content: systemPrompt,
        role: 'system',
        timestamp: now,
      ),
      ChatMessage(
        id: '${now.microsecondsSinceEpoch}-usr',
        content: userPrompt,
        role: 'user',
        timestamp: now,
      ),
    ];
    final res = await lm.getChatCompletion(
      baseUrl: settings.serverUrl,
      messages: messages,
      settings: settings,
    );
    final content = res['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    final choices = res['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final msg = first['message'];
        if (msg is Map && msg['content'] is String) {
          return msg['content'] as String;
        }
      }
    }
    throw StateError('Unexpected response shape from server.');
  }

  Future<void> _deliver(
    BuildContext context,
    Uri uri, {
    required String title,
    required String body,
    bool speakAloud = false,
  }) async {
    await SiriIntentBridge.completeUri(uri, body);
    if (!context.mounted) return;
    if (_silentSiri) {
      await Clipboard.setData(ClipboardData(text: body));
      return;
    }
    if (speakAloud && body.trim().isNotEmpty) {
      await _speakText(context, body);
    }
    if (context.mounted) _presentResult(context, title, body);
  }

  Future<void> _reject(BuildContext context, Uri uri, String message) async {
    await SiriIntentBridge.failUri(uri, message);
    if (context.mounted && !_silentSiri) {
      _showError(context, message);
    }
  }

  // ─── UI helpers ──────────────────────────────────────────────────

  void _showProgress(BuildContext context, String label) {
    if (_silentSiri) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Flexible(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }

  void _presentResult(BuildContext context, String title, String body) {
    // Always copy to clipboard so Shortcuts' "Get clipboard" next step
    // can chain the result without needing a true return value.
    Clipboard.setData(ClipboardData(text: body));
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(body),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: body));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (_silentSiri) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shortcut error: $message')),
    );
  }

  static bool _isTruthy(String? v) {
    if (v == null) return false;
    final lower = v.toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes' || lower == 'y';
  }
}
