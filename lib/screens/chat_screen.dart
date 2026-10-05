import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/file_attachment.dart';
import '../models/group_chat_participant.dart';
import '../models/lm_studio_model.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_customization_dialog.dart';
import '../widgets/chat_settings_dialog.dart';
import '../widgets/global_download_fab.dart';
import '../widgets/desktop_shortcuts.dart';
import '../widgets/streaming_thinking_indicator.dart';
import '../widgets/full_width_nudge_dialog.dart';
import '../widgets/compact_error_banner.dart';
import '../utils/connect_host_error.dart';
import '../utils/lan_server_error.dart';
import '../utils/model_not_found_error.dart';
import '../utils/comfyui_prompt_error.dart';
import '../utils/image_gen_unreachable_error.dart';
import '../utils/server_unreachable_error.dart';
import '../widgets/setup_help_banner.dart';
import '../l10n/app_localizations.dart';
import '../services/call_service.dart';
import '../services/export_service.dart';
import '../services/tts_service.dart';
import '../services/kokoro_tts_service.dart';
import '../services/remote_kokoro_tts_service.dart';
import '../services/elevenlabs_tts_service.dart';
import '../services/grok_tts_service.dart';
import '../utils/kokoro_speaker_resolver.dart';
import '../utils/elevenlabs_voice_resolver.dart';
import '../utils/grok_voice_resolver.dart';
import '../utils/tts_engine.dart';
import '../services/local_network_service.dart';
import '../services/on_device_llm_service.dart';
import '../utils/chat_reasoning_toggle.dart';
import '../utils/image_picker_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/review_service.dart';
import '../services/support_nudge_service.dart';
import '../utils/response_parser.dart';
import '../widgets/support_nudge_dialog.dart';
import '../widgets/voice_input_panel.dart';
import '../widgets/transcription_progress_banner.dart';
import '../utils/transcription_launcher.dart';
import '../utils/theme_extensions.dart';
import '../utils/pencil_friendly_scroll_behavior.dart';
import '../utils/chat_list_auto_scroll.dart';
import '../utils/audio_setup_gate.dart';
import '../utils/group_chat_pro_gate.dart';
import '../utils/persona_appearance.dart';
import '../utils/persona_model_label.dart';
import '../models/app_settings.dart';
import 'settings_screen.dart';
import 'model_management_screen.dart';
import 'model_parameters_screen.dart';
import 'image_generation_settings_screen.dart';
import 'generated_images_library_screen.dart';
import 'system_prompts_screen.dart';
import 'persona_profile_screen.dart';
import 'group_chat_setup_screen.dart' show showEditGroupParticipantSheet;
import '../widgets/select_model_sheet.dart';
import '../widgets/persona_avatar.dart';
import '../widgets/persona_generator_dialog.dart';
import '../widgets/scrolling_prompt_cards.dart';
import '../widgets/chat_glass_header.dart';
import '../widgets/group_participant_glass_chip.dart';
import '../widgets/semantic_search_dialog.dart';
import '../models/system_prompt.dart';
import '../widgets/feature_request_unread_listener.dart';
import '../services/feature_request_service.dart';
import '../screens/feature_requests_screen.dart';
import '../main.dart' show firebaseInitialized;
import 'package:lm_mini_premium/lm_mini_premium.dart';
import '../pro/pro_features.dart';

part '../pro/group_chat/chat_screen_group.dart';
part '../pro/export/chat_screen_export.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? folderId;
  final bool launchCamera;
  final bool openInVoiceMode;
  final bool openInCallMode;
  final String? initialVoicePrompt;

  /// When set on a new chat, sends this as the first user message after create.
  final String? initialSendMessage;
  final bool showExpandToggle;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  /// When false, hide the download pill — used when this chat is embedded in
  /// [HomeScreen]'s two-column layout, which already hosts [GlobalDownloadFAB].
  final bool showDownloadFab;

  /// When set, the thread scrolls to this message after load.
  final String? highlightMessageId;

  /// Flat header without status-bar inset (desktop shell detail pane).
  final bool embeddedInShell;

  /// Tablet and desktop keep this chat inside the list. A branch tells that
  /// shell to show the new conversation instead of pushing another route.
  final ValueChanged<String>? onConversationReplaced;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.folderId,
    this.launchCamera = false,
    this.openInVoiceMode = false,
    this.openInCallMode = false,
    this.initialVoicePrompt,
    this.initialSendMessage,
    this.showExpandToggle = false,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.showDownloadFab = true,
    this.embeddedInShell = false,
    this.highlightMessageId,
    this.onConversationReplaced,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final MessageInputController _messageInputController =
      MessageInputController();
  String? _highlightedMessageId; // For temporarily highlighting found messages
  bool _userScrolled = false; // Track if user manually scrolled
  /// Show jump-to-latest control when the user is scrolled away from the bottom.
  bool _showScrollToBottom = false;
  static const double _scrollToBottomThreshold = 120;
  bool _pinToLatestScheduled = false;
  File? _pendingCameraImage; // Image captured from camera widget launch
  bool _wasLoading = false; // Track loading state for auto-read TTS
  bool _voiceModeActive = false; // Whether inline voice panel is showing
  bool _autoReadStreamingActive = false; // Kokoro streaming TTS in progress
  int _autoReadPreviousTtsLength = 0; // Characters already fed to Kokoro
  int _autoReadBaseIndex =
      0; // Message count at send start — only read messages after this
  bool _searxngV0NoticeDismissed = false; // SearXNG V0 notice dismissed by user
  bool _lastSearxngActive =
      false; // Track SearXNG state for re-toggle detection
  bool _offeredModelSheet = false;

  FeatureRequestService? _featureRequestService;
  String? _featureRequestUserId;
  bool _featureRequestIsAdmin = false;

  @override
  void initState() {
    super.initState();
    // Restore voice mode if this conversation has an active call, or if explicitly requested
    final chatProvider = context.read<ChatProvider>();
    _voiceModeActive = widget.openInVoiceMode ||
        (widget.conversationId != null &&
            chatProvider.voiceCallConversationId == widget.conversationId);
    if (widget.openInCallMode && CallService.isOffered) {
      context.read<SettingsProvider>().updateVoiceCallMode(true);
    }
    WidgetsBinding.instance.addObserver(this);
    // Listen for user scroll gestures
    _scrollController.addListener(_onScroll);
    _initSupportBadge();
    unawaited(_recoverLostCameraImage());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.conversationId != null) {
        await context
            .read<ChatProvider>()
            .selectConversation(widget.conversationId!);
        // Reversed ListView opens already pinned to the latest message —
        // no load-then-scroll. Reset scroll flags for the new thread.
        if (!mounted) return;
        setState(() {
          _userScrolled = false;
          _showScrollToBottom = false;
        });
        final highlightId = widget.highlightMessageId;
        if (highlightId != null && highlightId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final msgs = context.read<ChatProvider>().currentMessages;
            final idx = msgs.indexWhere((m) => m.id == highlightId);
            if (idx >= 0) _scrollToMessage(idx, highlightId);
          });
        }
      } else {
        final selectedPersonaId =
            context.read<SettingsProvider>().settings.selectedSystemPromptId;
        await context.read<ChatProvider>().createNewConversation(
              folderId: widget.folderId,
              systemPromptId: selectedPersonaId,
            );
        if (!mounted) return;
      }
      // Refresh models to get latest loaded_context_length
      context.read<SettingsProvider>().refreshModels();

      final pendingSend = widget.initialSendMessage?.trim();
      if (pendingSend != null &&
          pendingSend.isNotEmpty &&
          widget.conversationId == null &&
          mounted) {
        final settingsProvider = context.read<SettingsProvider>();
        await context.read<ChatProvider>().sendMessage(
              pendingSend,
              settingsProvider.settings,
              settingsProvider: settingsProvider,
              uiContext: context,
            );
      }

      // Launch camera if requested (from widget action)
      if (widget.launchCamera && mounted) {
        _launchCameraForNewChat();
      }

      if (_voiceModeActive && mounted) {
        final cp = context.read<ChatProvider>();
        final returningToCall = widget.conversationId != null &&
            cp.voiceCallConversationId == widget.conversationId;
        if (!returningToCall) {
          final ok = await ensureAudioSetup(context);
          if (!ok && mounted) {
            setState(() => _voiceModeActive = false);
          }
        }
      }

      if (mounted && !_voiceModeActive && !widget.launchCamera) {
        await _maybeShowFullWidthNudge();
      }
    });
  }

  Future<void> _maybeShowFullWidthNudge() async {
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;
    if (settings.fullWidthAssistantNudgeShown) return;
    settingsProvider.markFullWidthAssistantNudgeShown();
    if (settings.fullWidthAssistant) return;
    if (!mounted) return;
    await showFullWidthNudgeDialog(context);
  }

  Future<void> _initSupportBadge() async {
    if (!firebaseInitialized) return;
    final service = FeatureRequestService();
    try {
      final userId = await service.getCurrentUserId();
      final isAdmin = await service.isAdmin;
      if (!mounted) return;
      setState(() {
        _featureRequestService = service;
        _featureRequestUserId = userId;
        _featureRequestIsAdmin = isAdmin;
      });
    } catch (_) {}
  }

  Future<void> _activateVoiceMode() async {
    if (!await ensureAudioSetup(context)) return;
    if (!mounted) return;
    setState(() => _voiceModeActive = true);
  }

  Future<void> _toggleVoiceMode() async {
    if (_voiceModeActive) {
      setState(() => _voiceModeActive = false);
      return;
    }
    await _activateVoiceMode();
  }

  Future<void> _launchCameraForNewChat() async {
    final file = await ImagePickerHelper.captureFromCamera(context);
    if (file != null && mounted) {
      setState(() {
        _pendingCameraImage = file;
      });
    }
  }

  void _stageCameraImage(File file) {
    if (!mounted) return;
    setState(() => _pendingCameraImage = file);
  }

  /// Android can destroy the activity while the camera is open. The photo
  /// is then only available from the picker, not from the original future.
  Future<void> _recoverLostCameraImage() async {
    final files = await ImagePickerHelper.recoverLostImages();
    if (!mounted || files.isEmpty) return;
    setState(() => _pendingCameraImage = files.last);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Reversed ListView: offset 0 is the latest messages (visual bottom).
    final distanceFromBottom = _scrollController.position.pixels;

    // Re-enable auto-scroll when near the latest messages.
    if (distanceFromBottom <= kChatResumeFollowPixels) {
      _userScrolled = false;
    }

    final shouldShow = distanceFromBottom > _scrollToBottomThreshold;
    if (shouldShow != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _jumpToLatestMessages() {
    setState(() {
      _userScrolled = false;
      _showScrollToBottom = false;
    });
    _scrollToBottom(animate: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Cancel streaming TTS if active
    if (_autoReadStreamingActive) {
      KokoroTtsService().stop();
      RemoteKokoroTtsService().stop();
      ElevenLabsTtsService().stop();
      GrokTtsService().stop();
      _autoReadStreamingActive = false;
    }
    super.dispose();
  }

  /// Helper to speak text with native TTS using the given voice settings.
  void _speakWithNativeTts(String content, dynamic voiceSettings) {
    final tts = TtsService();
    tts.initialize().then((_) {
      tts.setSpeechRate(voiceSettings.voiceSpeechRate);
      tts.setPitch(voiceSettings.voicePitch);
      tts.setLanguage(voiceSettings.voiceLanguage);
      if (voiceSettings.voiceName != null) {
        tts.setVoice(voiceSettings.voiceName);
      }
      tts.speak(content);
    });
  }

  /// Kokoro speaker/speed for auto-read: persona / group participant → global.
  KokoroVoiceSettings _resolveAutoReadVoice(
    AppSettings voiceSettings,
    ChatProvider chatProvider,
    List<ChatMessage> messages,
  ) {
    ChatMessage? assistant;
    for (int i = messages.length - 1; i >= _autoReadBaseIndex; i--) {
      if (messages[i].role == 'assistant') {
        assistant = messages[i];
        break;
      }
    }
    if (assistant == null && messages.isNotEmpty) {
      assistant = messages.last.role == 'assistant' ? messages.last : null;
    }
    if (assistant == null) {
      return KokoroSpeakerResolver.resolveVoice(settings: voiceSettings);
    }
    return KokoroSpeakerResolver.resolveVoiceForMessage(
      settings: voiceSettings,
      message: assistant,
      conversation: chatProvider.currentConversation,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Save partial response when the app is about to go to the background
      context.read<ChatProvider>().onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_recoverLostCameraImage());
    }
  }

  /// Pin to the latest messages. The chat ListView is `reverse: true`, so
  /// offset 0 is the bottom (WhatsApp-style) — no scroll-through-history.
  void _scrollToBottom({bool animate = true}) {
    void go() {
      if (!mounted || !_scrollController.hasClients) return;
      final pixels = _scrollController.position.pixels;
      if (isPinnedToLatest(pixels)) return;
      if (animate) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    }

    go();
    // First message / empty→list swap: ListView may not have clients until
    // the next frame — retry so we stay pinned to the latest bubble.
    WidgetsBinding.instance.addPostFrameCallback((_) => go());
  }

  /// Android reverse lists apply a scroll correction when the newest bubble
  /// grows, which keeps the *start* of the reply in view. Jump back to 0 on
  /// the next frame unless the user dragged the outer list away.
  void _schedulePinToLatest() {
    if (_pinToLatestScheduled) return;
    _pinToLatestScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinToLatestScheduled = false;
      if (!mounted || _userScrolled) return;
      final autoScrollEnabled =
          context.read<SettingsProvider>().settings.autoScrollEnabled;
      if (!autoScrollEnabled || !_scrollController.hasClients) return;
      if (shouldRepinToLatest(
        autoScrollEnabled: autoScrollEnabled,
        userScrolled: _userScrolled,
        pixels: _scrollController.position.pixels,
      )) {
        _scrollToBottom(animate: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatProvider = context.watch<ChatProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final effectiveSettings =
        chatProvider.getEffectiveSettings(settingsProvider.settings);
    final isEmptyNewChat =
        !chatProvider.currentMessages.any((message) => message.role == 'user');
    final showPromptPills =
        settingsProvider.settings.showChatStarters && isEmptyNewChat;
    // Image pills / tiles only when the *selected* model is vision-capable.
    final showImagesTile =
        _selectedModelSupportsVision(effectiveSettings, settingsProvider);
    final autoScrollEnabled = settingsProvider.settings.autoScrollEnabled;

    // Follow the latest bubble when enabled and the user hasn't dragged away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final toast = chatProvider.takePendingToast();
      if (toast != null && mounted) {
        final message = switch (toast) {
          ChatToast.reasoningUnsupported => l10n.reasoningUnsupportedToast,
          ChatToast.transcriptionContextLarge =>
            l10n.transcriptionContextLargeToast,
          ChatToast.compactFailed => l10n.compactChatFailed,
          ChatToast.compactNeedModel => l10n.compactChatNeedModel,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      if (_scrollController.hasClients &&
          shouldRepinToLatest(
            autoScrollEnabled: autoScrollEnabled,
            userScrolled: _userScrolled,
            pixels: _scrollController.position.pixels,
          )) {
        // Reverse-list growth correction can leave the start of a long reply
        // on screen. Pin for the whole follow window — including the frame
        // after isSendingMessage flips false, when typing dots / markdown swap.
        _scrollToBottom(animate: false);
      }

      // Auto-read: stream TTS as text arrives (Kokoro) or read when done (native)
      final voiceSettings = settingsProvider.settings;
      // Public builds have no cloud TTS: ElevenLabs / Grok fall back to native.
      final ttsProvider = TtsEngine.effective(voiceSettings.voiceTtsProvider);
      final isStreamActive =
          chatProvider.isLoading || chatProvider.isSendingMessage;
      if (voiceSettings.voiceAutoRead && !_voiceModeActive) {
        // During streaming: feed text to Kokoro sentence-by-sentence
        if (isStreamActive &&
            TtsEngine.usesSentenceStreaming(ttsProvider)) {
          final isRemote = ttsProvider == 'kokoro_remote';
          final isElevenLabs =
              ttsProvider == TtsEngine.elevenLabs;
          final isGrok = ttsProvider == TtsEngine.grok;
          final kokoroTts = (!isRemote && !isElevenLabs && !isGrok)
              ? KokoroTtsService()
              : null;
          final remoteKokoroTts = isRemote ? RemoteKokoroTtsService() : null;
          final elevenLabsTts = isElevenLabs ? ElevenLabsTtsService() : null;
          final grokTts = isGrok ? GrokTtsService() : null;

          // Capture base index on transition to active so we only read
          // NEW assistant messages and don't replay previous ones.
          if (!_wasLoading) {
            _autoReadBaseIndex = chatProvider.currentMessages.length;
          }

          // Try to initialize in background if not yet ready
          if (isElevenLabs) {
            if (!elevenLabsTts!.isInitialized && !_autoReadStreamingActive) {
              elevenLabsTts.initialize(
                apiKey: voiceSettings.voiceElevenLabsApiKey,
                voiceId: voiceSettings.voiceElevenLabsVoiceId,
                modelId: voiceSettings.voiceElevenLabsModelId,
                speed: voiceSettings.voiceKokoroSpeed,
              );
            }
          } else if (isGrok) {
            if (!grokTts!.isInitialized && !_autoReadStreamingActive) {
              grokTts.initialize(
                apiKey: voiceSettings.voiceGrokApiKey,
                voiceId: voiceSettings.voiceGrokVoiceId,
                language: voiceSettings.locale ?? voiceSettings.voiceLanguage,
                speed: voiceSettings.voiceKokoroSpeed,
              );
            }
          } else if (isRemote) {
            if (!remoteKokoroTts!.isInitialized && !_autoReadStreamingActive) {
              remoteKokoroTts.initialize(
                serverUrl: voiceSettings.effectiveVoiceRemoteKokoroUrl,
                authToken:
                    voiceSettings.voiceRemoteKokoroHeaders?['X-LM-Mini-Token'],
                language:
                    voiceSettings.locale ?? voiceSettings.voiceSttLanguage,
              );
            }
          } else {
            if (!kokoroTts!.isInitialized && !_autoReadStreamingActive) {
              kokoroTts.initialize(
                language:
                    voiceSettings.locale ?? voiceSettings.voiceSttLanguage,
              );
            }
          }

          final isReady = isGrok
              ? grokTts!.isInitialized
              : isElevenLabs
                  ? elevenLabsTts!.isInitialized
                  : isRemote
                      ? remoteKokoroTts!.isInitialized
                      : kokoroTts!.isInitialized;
          if (isReady) {
            final messages = chatProvider.currentMessages;
            String currentContent = '';
            ChatMessage? assistant;
            for (int i = messages.length - 1; i >= _autoReadBaseIndex; i--) {
              if (messages[i].role == 'assistant') {
                assistant = messages[i];
                currentContent = messages[i].content;
                break;
              }
            }
            final parsed = ResponseParser.parse(currentContent);
            final cleanContent = ResponseParser.cleanForTts(parsed.answer);

            if (!_autoReadStreamingActive && cleanContent.isNotEmpty) {
              final voice = _resolveAutoReadVoice(
                voiceSettings,
                chatProvider,
                messages,
              );
              if (isElevenLabs) {
                elevenLabsTts!.setVoiceId(
                  assistant != null
                      ? ElevenLabsVoiceResolver.resolveVoiceIdForMessage(
                          settings: voiceSettings,
                          message: assistant,
                          conversation: chatProvider.currentConversation,
                        )
                      : ElevenLabsVoiceResolver.resolveVoiceId(
                          settings: voiceSettings,
                        ),
                );
                elevenLabsTts.setModelId(voiceSettings.voiceElevenLabsModelId);
                elevenLabsTts.setSpeed(voice.speed);
                elevenLabsTts.startStreaming();
              } else if (isGrok) {
                grokTts!.setVoiceId(
                  assistant != null
                      ? GrokVoiceResolver.resolveVoiceIdForMessage(
                          settings: voiceSettings,
                          message: assistant,
                          conversation: chatProvider.currentConversation,
                        )
                      : GrokVoiceResolver.resolveVoiceId(
                          settings: voiceSettings,
                        ),
                );
                grokTts.setLanguage(
                    voiceSettings.locale ?? voiceSettings.voiceLanguage);
                grokTts.setSpeed(voice.speed);
                grokTts.startStreaming();
              } else if (isRemote) {
                remoteKokoroTts!.setSpeakerId(voice.speakerId);
                remoteKokoroTts.setSpeed(voice.speed);
                remoteKokoroTts.startStreaming();
              } else {
                kokoroTts!.setSpeakerId(voice.speakerId);
                kokoroTts.setSpeed(voice.speed);
                kokoroTts.startStreaming();
              }
              _autoReadStreamingActive = true;
              _autoReadPreviousTtsLength = 0;
            }

            if (_autoReadStreamingActive &&
                cleanContent.length > _autoReadPreviousTtsLength) {
              final newText =
                  cleanContent.substring(_autoReadPreviousTtsLength);
              if (isElevenLabs) {
                elevenLabsTts!.feedText(newText);
              } else if (isGrok) {
                grokTts!.feedText(newText);
              } else if (isRemote) {
                remoteKokoroTts!.feedText(newText);
              } else {
                kokoroTts!.feedText(newText);
              }
              _autoReadPreviousTtsLength = cleanContent.length;
            }
          }
        }

        // Transition: streaming → done
        if (_wasLoading && !isStreamActive) {
          if (_autoReadStreamingActive) {
            // Finish streaming TTS session
            if (ttsProvider == TtsEngine.elevenLabs) {
              ElevenLabsTtsService().finishStreaming();
            } else if (ttsProvider == TtsEngine.grok) {
              GrokTtsService().finishStreaming();
            } else if (ttsProvider == 'kokoro_remote') {
              RemoteKokoroTtsService().finishStreaming();
            } else {
              KokoroTtsService().finishStreaming();
            }
            _autoReadStreamingActive = false;
            _autoReadPreviousTtsLength = 0;
          } else {
            // Non-streaming fallback (native TTS or engine not initialized)
            final messages = chatProvider.currentMessages;
            if (messages.isNotEmpty && messages.last.role == 'assistant') {
              // Strip thinking/reasoning and hidden tags — only read the answer aloud
              final parsed = ResponseParser.parse(messages.last.content);
              final textToRead = ResponseParser.cleanForTts(parsed.answer);
              if (textToRead.trim().isNotEmpty) {
                final voice = _resolveAutoReadVoice(
                  voiceSettings,
                  chatProvider,
                  messages,
                );
                if (ttsProvider == 'kokoro_remote') {
                  final remoteTts = RemoteKokoroTtsService();
                  remoteTts
                      .initialize(
                    serverUrl: voiceSettings.effectiveVoiceRemoteKokoroUrl,
                    authToken: voiceSettings
                        .voiceRemoteKokoroHeaders?['X-LM-Mini-Token'],
                  )
                      .then((ok) {
                    if (ok) {
                      remoteTts.setSpeakerId(voice.speakerId);
                      remoteTts.setSpeed(voice.speed);
                      remoteTts.speak(textToRead);
                    } else {
                      _speakWithNativeTts(textToRead, voiceSettings);
                    }
                  });
                } else if (ttsProvider == 'kokoro') {
                  final kokoroTts = KokoroTtsService();
                  kokoroTts
                      .initialize(
                    language:
                        voiceSettings.locale ?? voiceSettings.voiceSttLanguage,
                  )
                      .then((ok) {
                    if (ok) {
                      kokoroTts.setSpeakerId(voice.speakerId);
                      kokoroTts.setSpeed(voice.speed);
                      kokoroTts.speak(textToRead).then((played) {
                        if (!played) {
                          _speakWithNativeTts(textToRead, voiceSettings);
                        }
                      });
                    } else {
                      _speakWithNativeTts(textToRead, voiceSettings);
                    }
                  });
                } else if (ttsProvider ==
                    TtsEngine.elevenLabs) {
                  final elTts = ElevenLabsTtsService();
                  elTts
                      .initialize(
                    apiKey: voiceSettings.voiceElevenLabsApiKey,
                    voiceId: ElevenLabsVoiceResolver.resolveVoiceIdForMessage(
                      settings: voiceSettings,
                      message: messages.last,
                      conversation: chatProvider.currentConversation,
                    ),
                    modelId: voiceSettings.voiceElevenLabsModelId,
                    speed: voice.speed,
                  )
                      .then((ok) {
                    if (ok) {
                      elTts.speak(textToRead);
                    } else {
                      _speakWithNativeTts(textToRead, voiceSettings);
                    }
                  });
                } else if (ttsProvider == TtsEngine.grok) {
                  final grokTts = GrokTtsService();
                  grokTts
                      .initialize(
                    apiKey: voiceSettings.voiceGrokApiKey,
                    voiceId: GrokVoiceResolver.resolveVoiceIdForMessage(
                      settings: voiceSettings,
                      message: messages.last,
                      conversation: chatProvider.currentConversation,
                    ),
                    language:
                        voiceSettings.locale ?? voiceSettings.voiceLanguage,
                    speed: voice.speed,
                  )
                      .then((ok) {
                    if (ok) {
                      grokTts.speak(textToRead);
                    } else {
                      _speakWithNativeTts(textToRead, voiceSettings);
                    }
                  });
                } else {
                  _speakWithNativeTts(textToRead, voiceSettings);
                }
              }
            }
          }
        }
      }

      // Errors on screen hold off the review prompt for a while.
      if (chatProvider.error != null) ReviewService.noteChatError();

      // Check for review prompt when message exchange completes successfully
      if (_wasLoading && !isStreamActive) {
        final replyCompleted = chatProvider.takeReviewEligibleReply();
        final voiceActive = _voiceModeActive ||
            chatProvider.voiceCallConversationId != null;
        if (chatProvider.error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final prompted = await ReviewService().maybeRequestReview(
              context,
              replyCompleted: replyCompleted,
              voiceActive: voiceActive,
            );
            // Never stack the Pro nudge on top of a rating prompt.
            if (prompted || !mounted) return;
            // Check for support milestone nudge
            final chatCount = await ReviewService().getSuccessfulChatCount();
            final nudge = await SupportNudgeService().checkMilestone(chatCount);
            if (nudge != null && context.mounted) {
              await SupportNudgeDialog.show(context, nudge);
              ReviewService.notePaywallShown();
            }
          });
        }
      }

      _wasLoading = isStreamActive;
    });

    final gradientDecoration = context.themeGradientDecoration;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarStyle = isDark
        ? SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(context
              .read<ChatProvider>()
              .discardEmptyCurrentConversationIfNeeded());
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarStyle,
        child: DesktopShortcuts(
          bindings: {
            desktopMeta(LogicalKeyboardKey.keyW): () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            desktopMetaShift(LogicalKeyboardKey.keyA): () {
              _messageInputController.showAttachmentMenu();
            },
          },
          child: Stack(
            children: [
              if (gradientDecoration != null)
                Positioned.fill(
                    child: DecoratedBox(decoration: gradientDecoration)),
              Scaffold(
                backgroundColor: widget.embeddedInShell
                    ? (isDark
                        ? const Color(0xFF0E1117)
                        : Theme.of(context).colorScheme.surface)
                    : (gradientDecoration != null ? Colors.transparent : null),
                extendBodyBehindAppBar: !widget.embeddedInShell,
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(ChatGlassHeader.heightFor(
                      context,
                      embeddedInShell: widget.embeddedInShell)),
                  child: Consumer2<ChatProvider, SettingsProvider>(
                    builder: (context, chatProvider, settingsProvider, _) {
                      final l10n = AppLocalizations.of(context);
                      final conv = chatProvider.currentConversation;
                      final showAvatar =
                          settingsProvider.settings.showChatHeaderAvatar;
                      final hasOverrides = chatProvider.hasSettingOverrides;
                      final hasMessages =
                          chatProvider.currentMessages.isNotEmpty;
                      final callConvId = chatProvider.voiceCallConversationId;
                      final thisConvId = conv?.id;
                      final callOnOther =
                          callConvId != null && callConvId != thisConvId;
                      final searchEnabled = settingsProvider
                              .settings.enableSemanticSearch &&
                          settingsProvider.settings.selectedEmbeddingModel !=
                              null;

                      Widget buildHeader({required bool supportUnread}) {
                        final unreadGreen = Colors.greenAccent.shade400;
                        final menuItems = <ChatGlassMenuItem>[
                          if (searchEnabled)
                            ChatGlassMenuItem(
                              id: 'search',
                              label: l10n.searchMessagesTooltip,
                              icon: Icons.search_rounded,
                            ),
                          if (chatProvider.isGroupChat)
                            ChatGlassMenuItem(
                              id: 'group_settings',
                              label: 'Group Chat Settings',
                              icon: Icons.group_rounded,
                              showBadge: hasOverrides,
                            )
                          else
                            ChatGlassMenuItem(
                              id: 'settings',
                              label: l10n.chatSettingsMenuItem,
                              icon: hasOverrides
                                  ? Icons.tune
                                  : Icons.tune_outlined,
                              showBadge: hasOverrides,
                            ),
                          ChatGlassMenuItem(
                            id: 'customize',
                            label: l10n.appearanceMenuItem,
                            icon: Icons.palette_outlined,
                          ),
                          if (chatProvider
                              .currentConversationHasGeneratedImages)
                            ChatGlassMenuItem(
                              id: 'gallery',
                              label: l10n.generatedImagesGallery,
                              icon: Icons.photo_library_outlined,
                            ),
                          // Settings + Quick Support live in the desktop nav rail.
                          if (!widget.embeddedInShell) ...[
                            ChatGlassMenuItem(
                              id: 'app_settings',
                              label: l10n.settingsTitle,
                              icon: Icons.settings_outlined,
                              showBadge: supportUnread,
                              badgeColor: unreadGreen,
                            ),
                            ChatGlassMenuItem(
                              id: 'quick_support',
                              label: 'Quick Support',
                              icon: Icons.support_agent_rounded,
                              showBadge: supportUnread,
                              badgeColor: unreadGreen,
                            ),
                          ],
                          ChatGlassMenuItem(
                            id: 'export',
                            label: l10n.exportAndShare,
                            icon: Icons.ios_share_rounded,
                            enabled: hasMessages,
                          ),
                        ];

                        final personaModel = _resolveHeaderPersonaAndModel(
                          chatProvider: chatProvider,
                          settingsProvider: settingsProvider,
                          anyModelLabel: l10n.preferredModelAny,
                        );

                        return ChatGlassHeader(
                          title: conv?.title ?? l10n.chatDefaultTitle,
                          showTitle: false,
                          personaLabel: personaModel.$1,
                          modelLabel: personaModel.$2,
                          modelSubtitle: personaModel.$3,
                          avatar: _buildHeaderAvatar(
                            context: context,
                            chatProvider: chatProvider,
                            settingsProvider: settingsProvider,
                            showAvatar: showAvatar,
                          ),
                          voiceModeActive: _voiceModeActive,
                          showAudioTab: true,
                          audioEnabled: !callOnOther,
                          audioDisabledTooltip: callOnOther
                              ? 'Voice call active in another chat'
                              : null,
                          onVoiceModeChanged: (audio) async {
                            if (audio) {
                              if (_voiceModeActive || callOnOther) return;
                              await _activateVoiceMode();
                            } else if (_voiceModeActive) {
                              setState(() => _voiceModeActive = false);
                            }
                          },
                          menuItems: menuItems,
                          onMenuSelected: (id) {
                            switch (id) {
                              case 'search':
                                _showSemanticSearch(context);
                                break;
                              case 'settings':
                              case 'group_settings':
                                _showChatSettings(context, chatProvider);
                                break;
                              case 'customize':
                                _showChatCustomization(
                                    context, chatProvider, settingsProvider);
                                break;
                              case 'gallery':
                                _openConversationGallery(context, chatProvider);
                                break;
                              case 'app_settings':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SettingsScreen()),
                                );
                                break;
                              case 'quick_support':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const FeatureRequestsScreen(),
                                  ),
                                );
                                break;
                              case 'export':
                                if (hasMessages) {
                                  _showExportSheet(context, chatProvider);
                                }
                                break;
                            }
                          },
                          isModelLoading: chatProvider.isModelLoading,
                          modelLoadingProgress:
                              chatProvider.modelLoadingProgress,
                          showExpandToggle: widget.showExpandToggle,
                          isExpanded: widget.isExpanded,
                          onToggleExpanded: widget.onToggleExpanded,
                          onEditPersona: () {
                            final editable = _resolveEditablePersona(
                              chatProvider: chatProvider,
                              settingsProvider: settingsProvider,
                            );
                            if (editable == null) return null;
                            return () {
                              SystemPromptEditorScreen.open(
                                context,
                                prompt: editable,
                              );
                            };
                          }(),
                          onViewPersona: () {
                            final editable = _resolveEditablePersona(
                              chatProvider: chatProvider,
                              settingsProvider: settingsProvider,
                            );
                            if (editable == null) return null;
                            return () {
                              PersonaProfileScreen.open(context, editable);
                            };
                          }(),
                          embeddedInShell: widget.embeddedInShell,
                        );
                      }

                      if (_featureRequestService != null &&
                          _featureRequestUserId != null &&
                          firebaseInitialized) {
                        return FeatureRequestUnreadListener(
                          service: _featureRequestService!,
                          userId: _featureRequestUserId,
                          isAdmin: _featureRequestIsAdmin,
                          builder: (context, hasUnread) =>
                              buildHeader(supportUnread: hasUnread),
                        );
                      }
                      return buildHeader(supportUnread: false);
                    },
                  ),
                ),
                body: Consumer2<ChatProvider, SettingsProvider>(
                  builder: (context, chatProvider, settingsProvider, child) {
                    final awaitingTarget = widget.conversationId != null &&
                        (chatProvider.isLoading ||
                            chatProvider.currentConversation?.id !=
                                widget.conversationId);
                    if (awaitingTarget) {
                      return Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    }

                    final settings = settingsProvider.settings;
                    context.watch<SubscriptionService>();
                    final groupChatLocked =
                        GroupChatProGate.isLocked(chatProvider);
                    final isOnDevice =
                        settings.activeProviderKind == 'onDeviceGguf' ||
                            settings.activeProviderKind == 'onDeviceMlx';
                    final hasOnDeviceModel =
                        OnDeviceLLMService.instance.specForSettings(settings) !=
                            null;

                    // For LM Studio / cloud we need selectedModel. For on-device we
                    // key off selectedLocalModelId/catalog lookup instead.
                    if ((!isOnDevice &&
                            (settings.selectedModel == null ||
                                settings.selectedModel!.isEmpty)) ||
                        (isOnDevice && !hasOnDeviceModel)) {
                      if (!isOnDevice && !_offeredModelSheet) {
                        _offeredModelSheet = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          unawaited(
                            _openSelectModel(context, settingsProvider),
                          );
                        });
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noModelSelectedTitle,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noModelSelectedSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => unawaited(
                                _openSelectModel(context, settingsProvider),
                              ),
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: Text(l10n.selectModel),
                            ),
                          ],
                        ),
                      );
                    }

                    // Get per-chat customization or fall back to global settings
                    final conversation = chatProvider.currentConversation;
                    // Background: missing key → global; empty string → none; path → custom.
                    final String? chatBackgroundRaw;
                    final chatSettings = conversation?.settings;
                    if (chatSettings != null &&
                        chatSettings.containsKey('chatBackground')) {
                      final v = chatSettings['chatBackground'];
                      chatBackgroundRaw =
                          (v is String && v.isNotEmpty) ? v : null;
                    } else {
                      chatBackgroundRaw =
                          settingsProvider.settings.chatBackgroundPath;
                    }
                    final userAvatar =
                        conversation?.settings['userAvatar'] as String? ??
                            settingsProvider.settings.userAvatarPath;
                    final bubblePersona = PersonaAppearance.resolve(
                      settings: settingsProvider.settings,
                      conversationSettings: conversation?.settings,
                    );
                    // Live saved persona wins so face-focus / avatar edits refresh
                    // in open chats (conversation assistantAvatar can go stale).
                    final livePersona = _resolveEditablePersona(
                      chatProvider: chatProvider,
                      settingsProvider: settingsProvider,
                    );
                    final assistantAvatar = livePersona?.avatarPath ??
                        conversation?.settings['assistantAvatar'] as String? ??
                        bubblePersona?.avatarPath ??
                        settingsProvider.settings.assistantAvatarPath;
                    final chatBackground =
                        ImagePickerHelper.resolveImagePathSync(
                            chatBackgroundRaw);
                    final backgroundOverlayOpacity = (conversation
                                ?.settings['backgroundOverlayOpacity'] as num?)
                            ?.toDouble() ??
                        settingsProvider.settings.chatBackgroundOverlayOpacity;

                    // Detect SearXNG V0 mode for the notice banner
                    final effectiveSettings = chatProvider
                        .getEffectiveSettings(settingsProvider.settings);
                    final isSearxngActive = !SubscriptionService().isPremium &&
                        effectiveSettings.enableWebSearch &&
                        effectiveSettings.searxngUrl?.isNotEmpty == true &&
                        !effectiveSettings.useMcpToolsOnly;
                    // Reset notice when SearXNG is re-toggled (off → on)
                    if (isSearxngActive && !_lastSearxngActive) {
                      _searxngV0NoticeDismissed = false;
                    }
                    _lastSearxngActive = isSearxngActive;
                    final showSearxngV0Notice =
                        isSearxngActive && !_searxngV0NoticeDismissed;

                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: (chatBackground != null)
                          ? BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(File(chatBackground)),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(
                                      backgroundOverlayOpacity / 100.0),
                                  BlendMode.srcOver,
                                ),
                              ),
                            )
                          : null,
                      child: Column(
                        children: [
                          if (!widget.embeddedInShell)
                            SizedBox(
                                height: MediaQuery.of(context).padding.top),
                          // Thin call banner when voice is active on another chat
                          Builder(
                            builder: (context) {
                              final cp = context.watch<ChatProvider>();
                              final voiceCallId = cp.voiceCallConversationId;
                              final currentId = cp.currentConversation?.id;
                              final isCallOnOther = voiceCallId != null &&
                                  voiceCallId != currentId;
                              if (!isCallOnOther) {
                                return const SizedBox.shrink();
                              }
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        conversationId: voiceCallId,
                                        openInVoiceMode: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  color: Colors.red,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.phone_in_talk,
                                          color: Colors.white, size: 13),
                                      SizedBox(width: 6),
                                      Text(
                                        'Tap to return to call',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, bodyConstraints) {
                                final keyboardOpen =
                                    MediaQuery.viewInsetsOf(context).bottom > 0;
                                // Keep room for the empty-chat scroll area when the
                                // keyboard is up and the composer grows (maxLines).
                                final maxComposerH = bodyConstraints.maxHeight *
                                    (keyboardOpen ? 0.40 : 0.52);
                                return Column(
                                  children: [
                                    if (chatProvider.thinkingBudgetNotice &&
                                        chatProvider.error == null)
                                      _ThinkingBudgetBanner(
                                        onDismiss: chatProvider
                                            .dismissThinkingBudgetNotice,
                                        onAdjustMaxTokens: () =>
                                            _openModelParameters(context),
                                      ),
                                    // Chat error banner (dismissible with expandable details)
                                    if (chatProvider.error != null)
                                      _ErrorBanner(
                                        error: chatProvider.error!,
                                        errorDetail: chatProvider.errorDetail,
                                        onDismiss: () =>
                                            chatProvider.clearError(),
                                        serverUrl:
                                            settingsProvider.settings.serverUrl,
                                        isRemoteActive: settingsProvider
                                            .settings.isRemoteActive,
                                        usbModeEnabled: settingsProvider
                                            .settings.usbModeEnabled,
                                        providerKind: settingsProvider
                                            .settings.activeProviderKind,
                                        selectedModel: settingsProvider
                                            .settings.selectedModel,
                                        onSelectModel: () => _openSelectModel(
                                          context,
                                          settingsProvider,
                                        ),
                                        onGoToModels: () =>
                                            _openModelManagement(context),
                                        onAdjustMaxTokens: () =>
                                            _openModelParameters(context),
                                        onOpenImageSettings: () =>
                                            _openImageGenerationSettings(
                                          context,
                                        ),
                                        onCompressAndResend: chatProvider
                                                .canCompressAndResendImages
                                            ? () => chatProvider
                                                    .compressLastImagesAndResend(
                                                  settingsProvider.settings,
                                                  settingsProvider:
                                                      settingsProvider,
                                                  uiContext: context,
                                                )
                                            : null,
                                        largeImageBytes: chatProvider
                                            .latestLargeUserImageBytes,
                                      ),

                                    // Connection status — only relevant for LM Studio.
                                    // On-Device / Cloud / Apple Intelligence don't depend
                                    // on the LM Studio HTTP endpoint, so suppress the
                                    // misleading red banner there.
                                    if (settingsProvider.connectionError !=
                                            null &&
                                        _showsServerConnectionBanner(
                                          settingsProvider,
                                        ))
                                      _ErrorBanner(
                                        error:
                                            settingsProvider.connectionError!,
                                        errorDetail:
                                            settingsProvider.connectionError,
                                        onDismiss: () => settingsProvider
                                            .clearConnectionError(),
                                        serverUrl:
                                            settingsProvider.settings.serverUrl,
                                        isRemoteActive: settingsProvider
                                            .settings.isRemoteActive,
                                        usbModeEnabled: settingsProvider
                                            .settings.usbModeEnabled,
                                        providerKind: settingsProvider
                                            .settings.activeProviderKind,
                                        selectedModel: settingsProvider
                                            .settings.selectedModel,
                                        onSelectModel: () => _openSelectModel(
                                          context,
                                          settingsProvider,
                                        ),
                                        onGoToModels: () =>
                                            _openModelManagement(context),
                                        onAdjustMaxTokens: () =>
                                            _openModelParameters(context),
                                        onOpenImageSettings: () =>
                                            _openImageGenerationSettings(
                                          context,
                                        ),
                                      ),

                                    // SearXNG V0 notice (one-time, resets on re-toggle)
                                    if (showSearxngV0Notice)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiaryContainer,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onTertiaryContainer,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'SearXNG active — using stateless (V0) API',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onTertiaryContainer,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => setState(() =>
                                                  _searxngV0NoticeDismissed =
                                                      true),
                                              child: Icon(
                                                Icons.close,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onTertiaryContainer,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Messages fill remaining space above the input.
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const TranscriptionProgressBanner(),
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: chatProvider
                                                          .currentMessages
                                                          .isEmpty
                                                      ? _EmptyChatScrollBody(
                                                          showPromptPills:
                                                              showPromptPills,
                                                          // Desktop: cards sit under the
                                                          // composer; empty body is greeting only.
                                                          suppressMobileStarters:
                                                              widget
                                                                  .embeddedInShell,
                                                          showImagesTile:
                                                              showImagesTile,
                                                          isLoading: chatProvider
                                                              .isSendingMessage,
                                                          onPickFile:
                                                              _messageInputController
                                                                  .showAttachmentMenu,
                                                          onPickImage:
                                                              showImagesTile
                                                                  ? () {
                                                                      _messageInputController
                                                                          .pickVisionImage();
                                                                    }
                                                                  : null,
                                                          onTakePhoto:
                                                              showImagesTile
                                                                  ? () {
                                                                      _messageInputController
                                                                          .capturePhoto();
                                                                    }
                                                                  : null,
                                                          onTranscribe: () =>
                                                              TranscriptionLauncher
                                                                  .openTranscribeFlow(
                                                                      context),
                                                          onGeneratePersona: () =>
                                                              _openPersonaGenerator(
                                                                  context),
                                                          onPromptSelected:
                                                              (prompt) {
                                                            if (chatProvider
                                                                .isSendingMessage) {
                                                              return;
                                                            }
                                                            _messageInputController
                                                                .setText(
                                                                    prompt);
                                                          },
                                                          onChatFiles:
                                                              _messageInputController
                                                                  .showAttachmentMenu,
                                                          onImages:
                                                              showImagesTile
                                                                  ? () {
                                                                      _messageInputController
                                                                          .pickVisionImage();
                                                                    }
                                                                  : null,
                                                          onTranslate: () {
                                                            _messageInputController
                                                                .insertTranslatePromptFromClipboard();
                                                          },
                                                          onAudioChat:
                                                              _activateVoiceMode,
                                                        )
                                                      : NotificationListener<
                                                          ScrollNotification>(
                                                          onNotification:
                                                              (notification) {
                                                            if (isUserDragOnChatList(
                                                                notification)) {
                                                              _userScrolled =
                                                                  true;
                                                              return false;
                                                            }
                                                            // Growing the newest bubble
                                                            // (Android ClampingScrollPhysics)
                                                            // corrects pixels away from 0.
                                                            if (notification
                                                                        .depth ==
                                                                    0 &&
                                                                notification
                                                                    is ScrollMetricsNotification &&
                                                                notification
                                                                        .metrics
                                                                        .axis ==
                                                                    Axis.vertical &&
                                                                shouldRepinToLatest(
                                                                  autoScrollEnabled:
                                                                      autoScrollEnabled,
                                                                  userScrolled:
                                                                      _userScrolled,
                                                                  pixels: notification
                                                                      .metrics
                                                                      .pixels,
                                                                )) {
                                                              _schedulePinToLatest();
                                                            }
                                                            return false;
                                                          },
                                                          child:
                                                              ScrollConfiguration(
                                                            behavior:
                                                                const AppScrollBehavior(),
                                                            child: ListView
                                                                .builder(
                                                              // Reverse so the list opens
                                                              // already at the latest
                                                              // message (WhatsApp-style)
                                                              // instead of painting from
                                                              // the top then scrolling down.
                                                              reverse: true,
                                                              controller:
                                                                  _scrollController,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(16),
                                                              itemCount:
                                                                  chatProvider
                                                                      .currentMessages
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                // index 0 = newest (visual bottom)
                                                                final messages =
                                                                    chatProvider
                                                                        .currentMessages;
                                                                final chronologicalIndex =
                                                                    messages.length -
                                                                        1 -
                                                                        index;
                                                                final message =
                                                                    messages[
                                                                        chronologicalIndex];
                                                                final isHighlighted =
                                                                    _highlightedMessageId ==
                                                                        message
                                                                            .id;

                                                                // Resolve group chat participant info for this message
                                                                final isGroup =
                                                                    chatProvider
                                                                        .isGroupChat;
                                                                GroupChatParticipant?
                                                                    participant;
                                                                if (isGroup &&
                                                                    message.participantId !=
                                                                        null) {
                                                                  final participants =
                                                                      chatProvider
                                                                          .groupParticipants;
                                                                  for (final p
                                                                      in participants) {
                                                                    if (p.id ==
                                                                        message
                                                                            .participantId) {
                                                                      participant =
                                                                          p;
                                                                      break;
                                                                    }
                                                                  }
                                                                }

                                                                // Determine if this is the last assistant message (for regenerate button)
                                                                bool
                                                                    isLastAssistantMessage =
                                                                    false;
                                                                // For group chat: allow regenerate on any assistant message in the latest round
                                                                bool
                                                                    canRegenerateGroupMsg =
                                                                    false;
                                                                if (message.role ==
                                                                        'assistant' &&
                                                                    !message
                                                                        .content
                                                                        .startsWith(
                                                                            'Tool call:') &&
                                                                    !message
                                                                        .content
                                                                        .startsWith(
                                                                            'MCP call:') &&
                                                                    !message
                                                                        .content
                                                                        .startsWith(
                                                                            '🔧 MCP call:')) {
                                                                  if (chatProvider
                                                                      .isGroupChat) {
                                                                    // In group chat: show regenerate for any assistant message after the last user message
                                                                    canRegenerateGroupMsg =
                                                                        true;
                                                                    for (int i =
                                                                            chronologicalIndex +
                                                                                1;
                                                                        i < messages.length;
                                                                        i++) {
                                                                      if (messages[i]
                                                                              .role ==
                                                                          'user') {
                                                                        canRegenerateGroupMsg =
                                                                            false;
                                                                        break;
                                                                      }
                                                                    }
                                                                  } else {
                                                                    isLastAssistantMessage =
                                                                        true;
                                                                    // Check there's no later assistant message (use chronological index — list is reverse:true)
                                                                    for (int i =
                                                                            chronologicalIndex +
                                                                                1;
                                                                        i < messages.length;
                                                                        i++) {
                                                                      final m =
                                                                          messages[
                                                                              i];
                                                                      if (m.role ==
                                                                              'assistant' &&
                                                                          !m.content.startsWith(
                                                                              'Tool call:') &&
                                                                          !m.content.startsWith(
                                                                              'MCP call:') &&
                                                                          !m.content
                                                                              .startsWith('🔧 MCP call:')) {
                                                                        isLastAssistantMessage =
                                                                            false;
                                                                        break;
                                                                      }
                                                                    }
                                                                  }
                                                                }

                                                                return AnimatedContainer(
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          300),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16),
                                                                    boxShadow:
                                                                        isHighlighted
                                                                            ? [
                                                                                BoxShadow(
                                                                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                                                                  blurRadius: 12,
                                                                                  spreadRadius: 2,
                                                                                ),
                                                                              ]
                                                                            : null,
                                                                  ),
                                                                  child:
                                                                      MessageBubble(
                                                                    key:
                                                                        ValueKey(
                                                                      '${message.id}|'
                                                                      '${_avatarBubbleCacheKey(
                                                                        chatProvider:
                                                                            chatProvider,
                                                                        settingsProvider:
                                                                            settingsProvider,
                                                                        participant:
                                                                            participant,
                                                                        assistantAvatar:
                                                                            assistantAvatar,
                                                                      )}',
                                                                    ),
                                                                    message:
                                                                        message,
                                                                    isStreaming: chatProvider
                                                                            .isSendingMessage &&
                                                                        message.role ==
                                                                            'assistant' &&
                                                                        message
                                                                            .id
                                                                            .startsWith('temp_'),
                                                                    userAvatarPath:
                                                                        userAvatar,
                                                                    assistantAvatarPath:
                                                                        assistantAvatar,
                                                                    conversationSettings:
                                                                        conversation
                                                                            ?.settings,
                                                                    allMessages:
                                                                        chatProvider
                                                                            .currentMessages,
                                                                    messageIndex:
                                                                        chronologicalIndex,
                                                                    isLastAssistantMessage:
                                                                        isLastAssistantMessage ||
                                                                            canRegenerateGroupMsg,
                                                                    participantName:
                                                                        participant
                                                                            ?.displayName,
                                                                    participantAvatarPath:
                                                                        participant
                                                                            ?.avatarPath,
                                                                    participantColor: participant
                                                                            ?.color ??
                                                                        (chatProvider.isGroupChat
                                                                            ? null
                                                                            : bubblePersona?.color),
                                                                    assistantAvatarAlignment:
                                                                        _resolveAssistantAvatarAlignment(
                                                                      chatProvider:
                                                                          chatProvider,
                                                                      settingsProvider:
                                                                          settingsProvider,
                                                                      participant:
                                                                          participant,
                                                                    ),
                                                                    assistantAvatarScale:
                                                                        _resolveAssistantAvatarScale(
                                                                      chatProvider:
                                                                          chatProvider,
                                                                      settingsProvider:
                                                                          settingsProvider,
                                                                      participant:
                                                                          participant,
                                                                    ),
                                                                    onAssistantAvatarTap:
                                                                        () {
                                                                      if (message
                                                                              .role !=
                                                                          'assistant') {
                                                                        return null;
                                                                      }
                                                                      final persona =
                                                                          _resolveProfilePersonaForMessage(
                                                                        chatProvider:
                                                                            chatProvider,
                                                                        settingsProvider:
                                                                            settingsProvider,
                                                                        participant:
                                                                            participant,
                                                                      );
                                                                      if (persona ==
                                                                          null) {
                                                                        return null;
                                                                      }
                                                                      return () =>
                                                                          PersonaProfileScreen
                                                                              .open(
                                                                            context,
                                                                            persona,
                                                                          );
                                                                    }(),
                                                                    onAlternativeSelected:
                                                                        (newIndex) {
                                                                      chatProvider.setActiveAlternative(
                                                                          message
                                                                              .id,
                                                                          newIndex);
                                                                    },
                                                                    onRegenerate: (!chatProvider.isSendingMessage &&
                                                                            (isLastAssistantMessage ||
                                                                                canRegenerateGroupMsg))
                                                                        ? () async {
                                                                            if (chatProvider.isGroupChat) {
                                                                              if (groupChatLocked) {
                                                                                await GroupChatProGate.showUpgradeDialog(context);
                                                                                return;
                                                                              }
                                                                              await chatProvider.regenerateFromGroupMessage(
                                                                                message.id,
                                                                                settingsProvider.settings,
                                                                                uiContext: context,
                                                                              );
                                                                            } else {
                                                                              chatProvider.regenerateLastResponse(
                                                                                settingsProvider.settings,
                                                                                settingsProvider: settingsProvider,
                                                                                uiContext: context,
                                                                              );
                                                                            }
                                                                          }
                                                                        : null,
                                                                    onEdit: !chatProvider
                                                                            .isSendingMessage
                                                                        ? (newContent,
                                                                            {bool andRegenerate =
                                                                                false}) {
                                                                            chatProvider.editMessage(
                                                                              message.id,
                                                                              newContent,
                                                                              settingsProvider.settings,
                                                                              andRegenerate: andRegenerate,
                                                                              settingsProvider: settingsProvider,
                                                                              uiContext: context,
                                                                            );
                                                                          }
                                                                        : null,
                                                                    onDelete: !chatProvider
                                                                            .isSendingMessage
                                                                        ? () =>
                                                                            chatProvider.deleteSingleMessage(message.id)
                                                                        : null,
                                                                    // Branch — only visible to premium users, hidden for group chat
                                                                    onBranch: (!chatProvider.isSendingMessage &&
                                                                            !chatProvider.isGroupChat &&
                                                                            ProFeatures.isPro)
                                                                        ? () => _openBranch(message.id)
                                                                        : null,
                                                                    onMessageUpdated:
                                                                        (updated) {
                                                                      chatProvider
                                                                          .updateMessageInPlace(
                                                                              updated);
                                                                    },
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                                if (_showScrollToBottom &&
                                                    chatProvider.currentMessages
                                                        .isNotEmpty)
                                                  Positioned(
                                                    right: 16,
                                                    bottom: 12,
                                                    child: Material(
                                                      elevation: 3,
                                                      shape:
                                                          const CircleBorder(),
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      clipBehavior:
                                                          Clip.antiAlias,
                                                      child: IconButton(
                                                        tooltip:
                                                            'Scroll to bottom',
                                                        onPressed:
                                                            _jumpToLatestMessages,
                                                        icon: Icon(
                                                          Icons
                                                              .keyboard_arrow_down_rounded,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onPrimaryContainer,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Group chat: ask chips (manual) + autonomous stop
                                    if (chatProvider.isGroupChat &&
                                        !groupChatLocked &&
                                        (chatProvider.groupTurnMode ==
                                                'manual' ||
                                            chatProvider.isAutonomousCycling))
                                      _proGroupAskBar(context, chatProvider,
                                          settingsProvider, groupChatLocked),

                                    // Streaming / loading — directly above the composer
                                    // (hidden in full-width view; status lives in the reply).
                                    if (!settingsProvider
                                            .settings.fullWidthAssistant &&
                                        chatProvider.streamingStatus != null)
                                      StreamingThinkingIndicator(
                                        status: chatProvider.streamingStatus!,
                                        progress:
                                            chatProvider.streamingProgress,
                                        isInReasoningMode:
                                            chatProvider.isInReasoningMode,
                                        reasoningContent:
                                            chatProvider.currentReasoning,
                                        isModelLoading:
                                            chatProvider.isModelLoading,
                                      )
                                    else if (chatProvider.isAutoGeneratingImage)
                                      StreamingThinkingIndicator(
                                        status: chatProvider
                                                    .autoGenImageProgress >=
                                                0.05
                                            ? 'Generating image · ${(chatProvider.autoGenImageProgress * 100).toInt()}%'
                                            : 'Generating image...',
                                        progress:
                                            chatProvider.autoGenImageProgress,
                                      ),

                                    // Message input — pinned to the bottom, height-capped
                                    // so a tall composer + keyboard cannot overflow the
                                    // column (empty-chat starters scroll above instead).
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: maxComposerH,
                                      ),
                                      child: groupChatLocked
                                          ? Material(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              child: SafeArea(
                                                top: false,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.lock_outline,
                                                        size: 20,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          l10n.groupChatLockedBanner,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            GroupChatProGate
                                                                .showUpgradeDialog(
                                                                    context),
                                                        child: Text(l10n
                                                            .groupChatProRequiredUpgrade),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : _voiceModeActive
                                              ? VoiceInputPanel(
                                                  autoStartCallMode:
                                                      widget.openInCallMode &&
                                                          CallService.isOffered,
                                                  initialPrompt:
                                                      widget.initialVoicePrompt,
                                                  onClose: () => setState(() =>
                                                      _voiceModeActive = false),
                                                  onScrollToBottom: () {
                                                    if (settingsProvider
                                                        .settings
                                                        .autoScrollEnabled) {
                                                      _userScrolled = false;
                                                    }
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      _scrollToBottom();
                                                    });
                                                  },
                                                )
                                              : SingleChildScrollView(
                                                  primary: false,
                                                  child: MessageInput(
                                                    controller:
                                                        _messageInputController,
                                                    onSendMessage: (content,
                                                        {List<String>?
                                                            imageUrls,
                                                        List<FileAttachment>?
                                                            fileAttachments}) async {
                                                      if (groupChatLocked) {
                                                        await GroupChatProGate
                                                            .showUpgradeDialog(
                                                                context);
                                                        return;
                                                      }
                                                      // Reset user scroll flag when sending a new message (only if auto-scroll is enabled)
                                                      if (settingsProvider
                                                          .settings
                                                          .autoScrollEnabled) {
                                                        _userScrolled = false;
                                                        _showScrollToBottom =
                                                            false;
                                                      }
                                                      await chatProvider
                                                          .sendMessage(
                                                        content,
                                                        settingsProvider
                                                            .settings,
                                                        imageUrls: imageUrls,
                                                        fileAttachments:
                                                            fileAttachments,
                                                        settingsProvider:
                                                            settingsProvider,
                                                        uiContext: context,
                                                      );
                                                      // Auto scroll to bottom after sending (only if enabled and user hasn't scrolled up)
                                                      if (settingsProvider
                                                              .settings
                                                              .autoScrollEnabled &&
                                                          !_userScrolled) {
                                                        WidgetsBinding.instance
                                                            .addPostFrameCallback(
                                                                (_) {
                                                          _scrollToBottom();
                                                          // Extra frame after empty→list
                                                          // layout so the new ListView
                                                          // has a real maxScrollExtent.
                                                          WidgetsBinding
                                                              .instance
                                                              .addPostFrameCallback(
                                                                  (_) {
                                                            _scrollToBottom(
                                                                animate: false);
                                                          });
                                                        });
                                                      }
                                                    },
                                                    onStopGeneration: () =>
                                                        chatProvider
                                                            .stopGeneration(),
                                                    isLoading: chatProvider
                                                            .isSendingMessage ||
                                                        chatProvider
                                                            .isCompacting,
                                                    isCompacting: chatProvider
                                                        .isCompacting,
                                                    compactSummary: chatProvider
                                                        .compactSummary,
                                                    compactThroughMessageId:
                                                        chatProvider
                                                            .compactThroughMessageId,
                                                    onCompactChat: () =>
                                                        chatProvider
                                                            .compactCurrentConversation(
                                                      settingsProvider.settings,
                                                      settingsProvider:
                                                          settingsProvider,
                                                      uiContext: context,
                                                    ),
                                                    messages: chatProvider
                                                        .currentMessages,
                                                    settings: effectiveSettings,
                                                    availableModels:
                                                        settingsProvider
                                                            .availableModels,
                                                    actualModelContextLength:
                                                        chatProvider
                                                            .actualModelContextLength,
                                                    selectedModelLoadedContextLength:
                                                        settingsProvider
                                                            .selectedModelLoadedContextLength,
                                                    initialImages:
                                                        _pendingCameraImage !=
                                                                null
                                                            ? [
                                                                _pendingCameraImage!
                                                              ]
                                                            : null,
                                                    onInitialImagesConsumed:
                                                        () {
                                                      setState(() {
                                                        _pendingCameraImage =
                                                            null;
                                                      });
                                                    },
                                                    onCameraImageCaptured:
                                                        _stageCameraImage,
                                                    onStartVoiceMode:
                                                        _activateVoiceMode,
                                                    onToggleMcpServer:
                                                        (label) async {
                                                      // 1. Toggle globally so new chats inherit it
                                                      settingsProvider
                                                          .toggleMcpServer(
                                                              label);
                                                      // 2. Update local chat override so this chat remembers its state
                                                      final conversation =
                                                          chatProvider
                                                              .currentConversation;
                                                      if (conversation !=
                                                          null) {
                                                        final newSettings = Map<
                                                                String,
                                                                dynamic>.from(
                                                            conversation
                                                                .settings);
                                                        // toggleMcpServer computes the new list, so we wait for its effect
                                                        // or just compute it. The provider is synchronous.
                                                        // Give provider a tick to update
                                                        await Future.microtask(
                                                            () {});
                                                        newSettings[
                                                                'activeMcpServerLabels'] =
                                                            settingsProvider
                                                                .settings
                                                                .activeMcpServerLabels;
                                                        await chatProvider
                                                            .updateChatSettings(
                                                                newSettings);
                                                      }
                                                    },
                                                    onToggleIntegratedMcp:
                                                        (name) async {
                                                      // 1. Toggle globally so new chats inherit it
                                                      settingsProvider
                                                          .toggleIntegratedMcp(
                                                              name);
                                                      // 2. Update local chat override
                                                      final conversation =
                                                          chatProvider
                                                              .currentConversation;
                                                      if (conversation !=
                                                          null) {
                                                        final newSettings = Map<
                                                                String,
                                                                dynamic>.from(
                                                            conversation
                                                                .settings);
                                                        await Future.microtask(
                                                            () {});
                                                        newSettings[
                                                                'activeIntegratedNames'] =
                                                            settingsProvider
                                                                .settings
                                                                .activeIntegratedMcps
                                                                .map((m) =>
                                                                    m.name)
                                                                .toList();
                                                        await chatProvider
                                                            .updateChatSettings(
                                                                newSettings);
                                                      }
                                                    },
                                                    onToggleProSearch:
                                                        (enabled) async {
                                                      // 1. Update globally
                                                      settingsProvider
                                                          .updateEnableWebSearch(
                                                              enabled);
                                                      settingsProvider
                                                          .updatePreferSearxng(
                                                              false);
                                                      // 2. Update local chat override
                                                      final conversation =
                                                          chatProvider
                                                              .currentConversation;
                                                      if (conversation !=
                                                          null) {
                                                        final newSettings = Map<
                                                                String,
                                                                dynamic>.from(
                                                            conversation
                                                                .settings);
                                                        newSettings[
                                                                'enableWebSearch'] =
                                                            enabled;
                                                        newSettings[
                                                                'preferSearxng'] =
                                                            false;
                                                        await chatProvider
                                                            .updateChatSettings(
                                                                newSettings);
                                                      }
                                                    },
                                                    onToggleSearxng:
                                                        (enabled) async {
                                                      // 1. Update globally
                                                      settingsProvider
                                                          .updateEnableWebSearch(
                                                              enabled);
                                                      settingsProvider
                                                          .updatePreferSearxng(
                                                              enabled);
                                                      // 2. Update local chat override
                                                      final conversation =
                                                          chatProvider
                                                              .currentConversation;
                                                      if (conversation !=
                                                          null) {
                                                        final newSettings = Map<
                                                                String,
                                                                dynamic>.from(
                                                            conversation
                                                                .settings);
                                                        newSettings[
                                                                'enableWebSearch'] =
                                                            enabled;
                                                        newSettings[
                                                                'preferSearxng'] =
                                                            enabled;
                                                        await chatProvider
                                                            .updateChatSettings(
                                                                newSettings);
                                                      }
                                                    },
                                                    onToggleCodeSandbox:
                                                        (enabled) async {
                                                      settingsProvider
                                                          .updateEnableCodeSandbox(
                                                              enabled);
                                                      final conversation =
                                                          chatProvider
                                                              .currentConversation;
                                                      if (conversation !=
                                                          null) {
                                                        final newSettings = Map<
                                                                String,
                                                                dynamic>.from(
                                                            conversation
                                                                .settings);
                                                        newSettings[
                                                                'enableCodeSandbox'] =
                                                            enabled;
                                                        await chatProvider
                                                            .updateChatSettings(
                                                                newSettings);
                                                      }
                                                    },
                                                    onToggleThinking:
                                                        (enabled) async {
                                                      final conversation =
                                                          chatProvider
                                                              .currentConversation;
                                                      if (conversation ==
                                                          null) {
                                                        return;
                                                      }
                                                      final globalOn =
                                                          settingsProvider
                                                                  .settings
                                                                  .reasoning !=
                                                              'off';
                                                      await chatProvider
                                                          .updateChatSettings(
                                                        ChatReasoningToggle
                                                            .applyToChatSettings(
                                                          conversation.settings,
                                                          enabled: enabled,
                                                          globalReasoningOn:
                                                              globalOn,
                                                          canControl:
                                                              ChatReasoningToggle
                                                                  .canControl(
                                                            settings:
                                                                effectiveSettings,
                                                            chatCloudProviderId:
                                                                conversation.settings[
                                                                        'cloudProviderId']
                                                                    as String?,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    mentionableParticipants:
                                                        chatProvider.isGroupChat
                                                            ? chatProvider
                                                                .groupParticipants
                                                            : null,
                                                  ),
                                                ),
                                    ),
                                    // Desktop empty chat: 4 equal-width cards under composer.
                                    if (widget.embeddedInShell &&
                                        isEmptyNewChat &&
                                        !groupChatLocked &&
                                        !_voiceModeActive)
                                      DesktopChatStarterCards(
                                        isLoading:
                                            chatProvider.isSendingMessage,
                                        onChatFiles: _messageInputController
                                            .showAttachmentMenu,
                                        onTranslate: () {
                                          _messageInputController
                                              .insertTranslatePromptFromClipboard();
                                        },
                                        onTranscribe: () =>
                                            TranscriptionLauncher
                                                .openTranscribeFlow(context),
                                        onGeneratePersona: () =>
                                            _openPersonaGenerator(context),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (widget.showDownloadFab)
                GlobalDownloadFAB(
                  headerBottom: ChatGlassHeader.heightFor(
                    context,
                    embeddedInShell: widget.embeddedInShell,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSelectModel(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final ok = await showSelectModelSheet(context);
    if (!mounted || !ok) return;
    settingsProvider.clearConnectionError();
    context.read<ChatProvider>().clearError();
  }

  Future<void> _openModelManagement(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModelManagementScreen()),
    );
    if (!mounted) return;
    // Refresh catalog after user may have loaded/swapped models.
    final sp = context.read<SettingsProvider>();
    try {
      await sp.loadAvailableModels();
    } catch (_) {}
  }

  Future<void> _openModelParameters(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModelParametersScreen()),
    );
  }

  Future<void> _openImageGenerationSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ImageGenerationSettingsScreen(),
      ),
    );
  }

  Future<void> _openConversationGallery(
    BuildContext context,
    ChatProvider chatProvider,
  ) async {
    final conv = chatProvider.currentConversation;
    if (conv == null) return;
    final l10n = AppLocalizations.of(context);
    final messageId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => GeneratedImagesLibraryScreen(
          conversationId: conv.id,
          title: l10n.generatedImagesGallery,
          openInExistingChat: true,
        ),
      ),
    );
    if (!mounted || messageId == null || messageId.isEmpty) return;
    final msgs = context.read<ChatProvider>().currentMessages;
    final idx = msgs.indexWhere((m) => m.id == messageId);
    if (idx >= 0) _scrollToMessage(idx, messageId);
  }

  /// True when the active chat model accepts image inputs.
  bool _selectedModelSupportsVision(
    AppSettings effectiveSettings,
    SettingsProvider settingsProvider,
  ) {
    final kind = effectiveSettings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      final spec =
          OnDeviceLLMService.instance.specForSettings(effectiveSettings);
      return spec?.supportsVision == true;
    }
    final id = effectiveSettings.selectedModel;
    if (id == null || id.isEmpty) return false;
    final model = settingsProvider.resolveLmStudioModel(id);
    if (model != null) return model.isVLM || model.supportsVision;
    return false;
  }

  /// Active saved persona for Edit, or null if custom/none/group.
  SystemPrompt? _resolveEditablePersona({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
  }) {
    if (chatProvider.isGroupChat) return null;
    return _resolveSavedPersonaById(
      settingsProvider.settings,
      _activePersonaId(
        chatProvider: chatProvider,
        settingsProvider: settingsProvider,
      ),
    );
  }

  /// Persona profile for an assistant bubble avatar (1:1 or group participant).
  SystemPrompt? _resolveProfilePersonaForMessage({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
    GroupChatParticipant? participant,
  }) {
    if (chatProvider.isGroupChat) {
      return _resolveSavedPersonaById(
        settingsProvider.settings,
        participant?.personaId,
      );
    }
    return _resolveEditablePersona(
      chatProvider: chatProvider,
      settingsProvider: settingsProvider,
    );
  }

  Alignment _resolveAssistantAvatarAlignment({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
    GroupChatParticipant? participant,
  }) {
    final persona = _resolveProfilePersonaForMessage(
      chatProvider: chatProvider,
      settingsProvider: settingsProvider,
      participant: participant,
    );
    return PersonaAvatar.alignmentFromFocus(
      persona?.avatarFocusX,
      persona?.avatarFocusY,
    );
  }

  double _resolveAssistantAvatarScale({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
    GroupChatParticipant? participant,
  }) {
    final persona = _resolveProfilePersonaForMessage(
      chatProvider: chatProvider,
      settingsProvider: settingsProvider,
      participant: participant,
    );
    return PersonaAvatar.scaleFromFocus(persona?.avatarFocusScale);
  }

  String _avatarBubbleCacheKey({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
    GroupChatParticipant? participant,
    String? assistantAvatar,
  }) {
    final persona = _resolveProfilePersonaForMessage(
      chatProvider: chatProvider,
      settingsProvider: settingsProvider,
      participant: participant,
    );
    return '${persona?.avatarPath ?? participant?.avatarPath ?? assistantAvatar}|'
        '${persona?.avatarFocusX}|${persona?.avatarFocusY}|'
        '${persona?.avatarFocusScale}|'
        '${persona?.updatedAt.millisecondsSinceEpoch}|'
        '${participant?.id}';
  }

  String? _activePersonaId({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
  }) {
    final settings = settingsProvider.settings;
    final chat = chatProvider.currentConversation?.settings;
    if (chat != null && chat.containsKey('systemPromptId')) {
      final id = chat['systemPromptId']?.toString();
      if (id == null || id.isEmpty) return null;
      return id;
    }
    if (chat != null && chat.containsKey('systemPrompt')) {
      return null;
    }
    return settings.selectedSystemPromptId;
  }

  SystemPrompt? _resolveSavedPersonaById(AppSettings settings, String? id) {
    if (id == null || id.isEmpty) return null;
    final prompts = settings.savedSystemPrompts;
    if (prompts == null || prompts.isEmpty) return null;
    for (final p in prompts) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Returns (personaLabel, modelLabel, modelSubtitle) for the avatar info popover.
  (String, String, String?) _resolveHeaderPersonaAndModel({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
    required String anyModelLabel,
  }) {
    final settings = settingsProvider.settings;
    final conv = chatProvider.currentConversation;
    final chat = conv?.settings;

    if (chatProvider.isGroupChat) {
      final participants = chatProvider.groupParticipants;
      final names = participants.map((p) => p.displayName).join(', ');
      final models = participants
          .map((p) => p.modelId.isNotEmpty ? p.modelId : '—')
          .toSet()
          .join(', ');
      return (
        names.isEmpty ? 'Group Chat' : names,
        models.isEmpty ? 'Multiple models' : models,
        null,
      );
    }

    String personaLabel = 'Default';
    final prompts = settings.savedSystemPrompts;
    String? personaId;
    if (chat != null && chat.containsKey('systemPromptId')) {
      personaId = chat['systemPromptId']?.toString();
      if (personaId == null || personaId.isEmpty) {
        personaLabel = 'Custom / none';
        personaId = null;
      }
    } else if (chat != null && chat.containsKey('systemPrompt')) {
      personaLabel = 'Custom prompt';
      personaId = null;
    } else {
      personaId = settings.selectedSystemPromptId;
    }
    SystemPrompt? persona;
    if (personaId != null && prompts != null) {
      for (final p in prompts) {
        if (p.id == personaId) {
          personaLabel = p.name;
          persona = p;
          break;
        }
      }
    }

    final preferred = persona == null
        ? null
        : personaPreferredModelParts(persona, anyModelLabel: anyModelLabel);
    final chatModel = chat != null && chat.containsKey('model')
        ? chat['model']?.toString()
        : null;
    final chatOverrideDiffers = chatModel != null &&
        chatModel.isNotEmpty &&
        persona?.defaultModelId != null &&
        LMStudioModel.friendlyLabel(chatModel) !=
            LMStudioModel.friendlyLabel(persona!.defaultModelId!);

    if (preferred != null && !chatOverrideDiffers) {
      return (personaLabel, preferred.model, preferred.provider);
    }

    String modelLabel;
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      modelLabel = chatModel?.isNotEmpty == true
          ? chatModel!
          : (settings.selectedLocalModelId ?? 'On-device model');
    } else if (kind == 'cloud') {
      modelLabel = chatModel?.isNotEmpty == true
          ? chatModel!
          : (settings.selectedModel ?? 'Cloud model');
    } else {
      modelLabel = chatModel?.isNotEmpty == true
          ? chatModel!
          : (settings.selectedModel ?? 'No model selected');
    }
    modelLabel = LMStudioModel.friendlyLabel(modelLabel);
    final providerSubtitle = personaProviderDisplayName(
      kind,
      settingsProvider.resolveCloudProvider()?.id ??
          persona?.defaultCloudProviderId,
    );

    return (personaLabel, modelLabel, providerSubtitle);
  }

  Widget _buildHeaderAvatar({
    required BuildContext context,
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
    required bool showAvatar,
  }) {
    final cs = Theme.of(context).colorScheme;

    if (!showAvatar) {
      return ColoredBox(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Icon(Icons.forum_rounded, size: 22, color: cs.onSurfaceVariant),
      );
    }

    if (chatProvider.isGroupChat) {
      final participants = chatProvider.groupParticipants;
      if (participants.isEmpty) {
        return ColoredBox(
          color: cs.primaryContainer,
          child: Icon(Icons.groups_rounded, size: 22, color: cs.primary),
        );
      }
      final p = participants.first;
      final resolved = p.avatarPath != null
          ? ImagePickerHelper.resolveImagePathSync(p.avatarPath!)
          : null;
      final pColor = p.color != null ? Color(p.color!) : cs.primary;
      if (resolved != null) {
        return Image.file(File(resolved), fit: BoxFit.cover);
      }
      return ColoredBox(
        color: pColor.withValues(alpha: 0.22),
        child: Center(
          child: Text(
            p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: pColor,
            ),
          ),
        ),
      );
    }

    final conv = chatProvider.currentConversation;
    final settings = settingsProvider.settings;
    final personaId = _activePersonaId(
      chatProvider: chatProvider,
      settingsProvider: settingsProvider,
    );
    final persona = _resolveSavedPersonaById(settings, personaId);
    final appearance = PersonaAppearance.resolve(
      settings: settings,
      conversationSettings: conv?.settings,
    );
    // Prefer live persona path over stale chat assistantAvatar so header
    // matches bubbles (same crop via PersonaAvatar focus/scale).
    final avatarPath = persona?.avatarPath ??
        appearance?.avatarPath ??
        conv?.settings['assistantAvatar'] as String? ??
        settings.assistantAvatarPath;
    final personaColor = persona?.color != null
        ? Color(persona!.color!)
        : (appearance?.color != null ? Color(appearance!.color!) : null);

    return PersonaAvatar(
      imagePath: avatarPath,
      radius: ChatGlassHeader.avatarSize / 2,
      backgroundColor: personaColor ?? cs.primaryContainer,
      alignment: PersonaAvatar.alignmentFromFocus(
        persona?.avatarFocusX,
        persona?.avatarFocusY,
      ),
      scale: PersonaAvatar.scaleFromFocus(persona?.avatarFocusScale),
      fallbackIconColor:
          personaColor != null ? Colors.white : cs.onPrimaryContainer,
    );
  }

  /// The message row is removed as soon as the branch starts loading, so the
  /// open has to run from this screen, which stays mounted.
  Future<void> _openBranch(String messageId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final newId = await context.read<ChatProvider>().branchFromMessage(messageId);
    if (newId == null || !mounted) return;
    final replace = widget.onConversationReplaced;
    if (replace != null) {
      replace(newId);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(conversationId: newId),
        ),
      );
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.branchCreated)),
    );
  }

  Future<void> _openPersonaGenerator(BuildContext context) async {
    final prompt = await PersonaGeneratorDialog.show(context);
    if (!mounted || prompt == null) return;
    await PersonaProfileScreen.open(context, prompt);
  }

  Future<void> _showSemanticSearch(BuildContext context) async {
    final query = await SemanticSearchDialog.show(context);
    if (!mounted || query == null || query.isEmpty) return;
    _performSemanticSearch(context, query);
  }

  void _performSemanticSearch(BuildContext context, String query) {
    final l10n = AppLocalizations.of(context);
    final chatProvider = context.read<ChatProvider>();
    final messages = chatProvider.currentMessages;

    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noMessagesToSearch)),
      );
      return;
    }

    // For now, show a simple keyword search as placeholder
    final queryLower = query.toLowerCase();
    final results = <({ChatMessage message, int index, String snippet})>[];

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final contentLower = msg.content.toLowerCase();
      if (contentLower.contains(queryLower)) {
        // Create a snippet around the match
        final matchIndex = contentLower.indexOf(queryLower);
        final start = (matchIndex - 50).clamp(0, msg.content.length);
        final end =
            (matchIndex + query.length + 50).clamp(0, msg.content.length);
        var snippet = msg.content.substring(start, end);
        if (start > 0) snippet = '...$snippet';
        if (end < msg.content.length) snippet = '$snippet...';

        results.add((message: msg, index: i, snippet: snippet));
      }
    }

    _showSearchResults(context, query, results);
  }

  void _showSearchResults(BuildContext context, String query,
      List<({ChatMessage message, int index, String snippet})> results) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.searchResults,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            l10n.searchResultsFor(results.length, query),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Results
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noMessagesFound,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.tryDifferentSearch,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final result = results[index];
                          final msg = result.message;
                          final isUser = msg.role == 'user';

                          return _SearchResultTile(
                            message: msg,
                            snippet: result.snippet,
                            query: query,
                            isUser: isUser,
                            onTap: () {
                              Navigator.of(context).pop();
                              _scrollToMessage(result.index, result.message.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToMessage(int messageIndex, String messageId) {
    // Reversed list: offset 0 is the newest message. Older messages sit at
    // higher offsets (how many items from the end × approx height).
    const approximateMessageHeight = 120.0;
    final messageCount = context.read<ChatProvider>().currentMessages.length;
    final itemsFromBottom =
        (messageCount - 1 - messageIndex).clamp(0, messageCount);
    final targetOffset = itemsFromBottom * approximateMessageHeight;

    if (_scrollController.hasClients) {
      // Highlight the message
      setState(() {
        _highlightedMessageId = messageId;
      });

      // Scroll to the message
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );

      // Clear highlight after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }

  Future<void> _showChatCustomization(
    BuildContext context,
    ChatProvider chatProvider,
    SettingsProvider settingsProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final conversation = chatProvider.currentConversation;
    if (conversation == null) return;

    final updatedSettings = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ChatCustomizationDialog(
        conversation: conversation,
        globalChatBackground: settingsProvider.settings.chatBackgroundPath,
        globalUserAvatar: settingsProvider.settings.userAvatarPath,
        globalAssistantAvatar: settingsProvider.settings.assistantAvatarPath,
        globalBackgroundOverlayOpacity:
            settingsProvider.settings.chatBackgroundOverlayOpacity,
      ),
    );

    if (updatedSettings != null) {
      final updatedConversation = conversation.copyWith(
        settings: updatedSettings,
      );
      await chatProvider.updateConversation(updatedConversation);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatCustomizationSaved),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showExportSheet(
      BuildContext context, ChatProvider chatProvider) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isPremium = SubscriptionService().isPremium;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.85;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n.exportAndShare,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Free formats ──
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, top: 8, bottom: 4),
                      child: Text(
                        l10n.freeFormats,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(l10n.exportAsPdf),
                      onTap: () {
                        Navigator.pop(ctx);
                        _exportChat(context, chatProvider, 'pdf');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.text_snippet),
                      title: Text(l10n.exportAsTxt),
                      onTap: () {
                        Navigator.pop(ctx);
                        _exportChat(context, chatProvider, 'txt');
                      },
                    ),

                    // ── Premium formats ──
                    ..._proExportSheetTiles(
                        ctx, context, chatProvider, isPremium, l10n, cs),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportChat(
      BuildContext context, ChatProvider chatProvider, String format) async {
    final l10n = AppLocalizations.of(context);
    final conversation = chatProvider.currentConversation;
    final messages = chatProvider.currentMessages;

    if (conversation == null || messages.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noMessagesToExport)),
        );
      }
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.exportingChat),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final exportService = ExportService();
      await exportService.exportChat(conversation, messages, format);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        final msg = switch (format) {
          'pdf' => l10n.chatExportedAsPdf,
          'txt' => l10n.chatExportedAsTxt,
          _ => l10n.chatExported,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showChatSettings(
      BuildContext context, ChatProvider chatProvider) async {
    final l10n = AppLocalizations.of(context);
    final conversation = chatProvider.currentConversation;
    if (conversation == null) return;

    final newSettings = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ChatSettingsDialog(
        conversation: conversation,
      ),
    );

    if (newSettings != null && context.mounted) {
      await chatProvider.updateChatSettings(newSettings);

      if (context.mounted) {
        final hasOverrides = newSettings.keys.any((k) => [
              'model',
              'systemPrompt',
              'temperature',
              'maxTokens',
              'topP',
              'topK',
              'minP',
              'repeatPenalty'
            ].contains(k));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasOverrides
                ? l10n.chatSettingsUpdated
                : l10n.chatSettingsReset),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// A custom tile widget for displaying search results with highlighted query matches
class _SearchResultTile extends StatelessWidget {
  final ChatMessage message;
  final String snippet;
  final String query;
  final bool isUser;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.message,
    required this.snippet,
    required this.query,
    required this.isUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUser ? Icons.person : Icons.smart_toy,
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Text(
                        isUser ? l10n.you : l10n.assistant,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(message.timestamp, l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Highlighted snippet
                  _buildHighlightedText(context, snippet, query),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
      BuildContext context, String text, String query) {
    final theme = Theme.of(context);
    final spans = <TextSpan>[];
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();

    int start = 0;
    int index = textLower.indexOf(queryLower);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: theme.textTheme.bodyMedium?.copyWith(
          backgroundColor: theme.colorScheme.primaryContainer,
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ));

      start = index + query.length;
      index = textLower.indexOf(queryLower, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatTime(DateTime timestamp, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (diff.inDays == 1) {
      return l10n.yesterday;
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}

bool _isModelRelatedError(String error) => ModelNotFoundError.matches(error);

bool _showsServerConnectionBanner(SettingsProvider settings) {
  final kind = settings.settings.activeProviderKind;
  if (kind == 'onDeviceGguf' ||
      kind == 'onDeviceMlx' ||
      kind == 'appleIntelligence' ||
      kind == 'cloud') {
    return false;
  }
  return true;
}

/// Shown while a high-thinking turn is retried at low effort.
class _ThinkingBudgetBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onAdjustMaxTokens;

  const _ThinkingBudgetBanner({
    required this.onDismiss,
    required this.onAdjustMaxTokens,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF1E2A3A)
        : Theme.of(context).colorScheme.primaryContainer;
    final foreground = isDark
        ? const Color(0xFFD3E4FF)
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.psychology_alt_outlined,
                  color: foreground, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.thinkingBudgetRetryTitle,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.thinkingBudgetRetryBody,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.9),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: onAdjustMaxTokens,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: Icon(Icons.tune_rounded, size: 14, color: foreground),
                    label: Text(l10n.adjustMaxTokens),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: foreground, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
              tooltip: l10n.dismiss,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact error banner with optional model actions + local-network hint.
class _ErrorBanner extends StatelessWidget {
  final String error;
  final String? errorDetail;
  final VoidCallback onDismiss;
  final String? serverUrl;
  final bool isRemoteActive;
  final bool usbModeEnabled;
  final String? providerKind;
  final String? selectedModel;
  final VoidCallback? onSelectModel;
  final VoidCallback? onGoToModels;
  final VoidCallback? onAdjustMaxTokens;
  final VoidCallback? onOpenImageSettings;
  final VoidCallback? onCompressAndResend;
  final int? largeImageBytes;

  const _ErrorBanner({
    required this.error,
    this.errorDetail,
    required this.onDismiss,
    this.serverUrl,
    this.isRemoteActive = false,
    this.usbModeEnabled = false,
    this.providerKind,
    this.selectedModel,
    this.onSelectModel,
    this.onGoToModels,
    this.onAdjustMaxTokens,
    this.onOpenImageSettings,
    this.onCompressAndResend,
    this.largeImageBytes,
  });

  String get _blob => [
        error,
        if (errorDetail != null && errorDetail!.isNotEmpty) errorDetail!,
      ].join('\n');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = Platform.isIOS;
    final isLocalUrl =
        serverUrl != null && LocalNetworkService.isLocalNetworkUrl(serverUrl!);
    final detailBlob = _blob;
    final isLikelyNetworkIssue = isIOS &&
        isLocalUrl &&
        LocalNetworkService.isLikelyLocalNetworkPermissionIssue(detailBlob);

    final textColor = isDark
        ? const Color(0xFFFFB4AB)
        : Theme.of(context).colorScheme.onErrorContainer;

    final lanKind = LanServerError.classify(detailBlob);
    if (LanServerError.shouldShowLmStudioLanHelp(
      error: detailBlob,
      serverUrl: serverUrl,
      providerKind: providerKind,
    )) {
      final hostDown = lanKind == LanServerErrorKind.hostDown;
      return SetupHelpBanner(
        icon: hostDown
            ? Icons.power_settings_new_rounded
            : Icons.desktop_windows_outlined,
        title: hostDown
            ? l10n.lmStudioHostDownTitle
            : l10n.lmStudioPcNotAllowingTitle,
        steps: hostDown
            ? [
                l10n.lmStudioHostDownStep1,
                l10n.lmStudioHostDownStep2,
              ]
            : [l10n.lmStudioPcNotAllowingBody],
        imageAsset: LanServerError.assetPath,
        imageLabel: l10n.lmStudioServerSettingsImageLabel,
        onDismiss: onDismiss,
      );
    }

    final connectKind = ConnectHostError.classify(
      error: detailBlob,
      serverUrl: serverUrl,
      isRemoteActive: isRemoteActive,
      usbModeEnabled: usbModeEnabled,
    );
    if (connectKind == ConnectHostErrorKind.shareWithPhone) {
      return SetupHelpBanner(
        icon: Icons.phonelink_rounded,
        title: l10n.cantReachMacTitle,
        steps: [l10n.cantReachMacStep1, l10n.cantReachMacStep2],
        onDismiss: onDismiss,
      );
    }
    if (connectKind == ConnectHostErrorKind.usb) {
      return SetupHelpBanner(
        icon: Icons.usb_rounded,
        title: l10n.waitingForMac,
        steps: [l10n.waitingForMacBody],
        onDismiss: onDismiss,
      );
    }
    if (connectKind == ConnectHostErrorKind.lanHostDown) {
      final showLmsShot = providerKind == null || providerKind == 'lmStudio';
      return SetupHelpBanner(
        icon: Icons.power_settings_new_rounded,
        title: l10n.lmStudioHostDownTitle,
        steps: [
          l10n.lmStudioHostDownStep1,
          if (showLmsShot) l10n.lmStudioHostDownStep2,
        ],
        imageAsset: showLmsShot ? LanServerError.assetPath : null,
        imageLabel: showLmsShot ? l10n.lmStudioServerSettingsImageLabel : null,
        onDismiss: onDismiss,
      );
    }

    if (ModelNotFoundError.matches(detailBlob)) {
      final id = selectedModel?.trim() ?? '';
      final chips = <Widget>[
        if (onSelectModel != null)
          _ErrorActionChip(
            label: l10n.selectModel,
            icon: Icons.swap_horiz_rounded,
            color: Theme.of(context).colorScheme.primary,
            onTap: onSelectModel!,
          ),
        if (onGoToModels != null)
          _ErrorActionChip(
            label: l10n.goToModels,
            icon: Icons.storage_rounded,
            color: Theme.of(context).colorScheme.primary,
            onTap: onGoToModels!,
          ),
      ];
      return SetupHelpBanner(
        icon: Icons.smart_toy_outlined,
        title: l10n.modelMissingTitle,
        steps: [
          id.isEmpty ? l10n.modelMissingBody : l10n.modelMissingBodyNamed(id),
        ],
        actions: chips,
        onDismiss: onDismiss,
      );
    }

    final comfy = ComfyUiPromptError.parse(detailBlob);
    if (comfy != null && comfy.isCheckpointSetup) {
      final name = comfy.checkpointName?.trim() ?? '';
      final body = switch (comfy.kind) {
        ComfyUiPromptErrorKind.noCheckpoints => l10n.comfyUiNoCheckpointsBody,
        ComfyUiPromptErrorKind.noCheckpointSelected =>
          l10n.comfyUiNoCheckpointSelectedBody,
        ComfyUiPromptErrorKind.unknownCheckpoint => name.isEmpty
            ? l10n.comfyUiNoCheckpointSelectedBody
            : l10n.comfyUiUnknownCheckpointBody(name),
        ComfyUiPromptErrorKind.diffusionOnly => l10n.comfyUiDiffusionOnlyBody,
        ComfyUiPromptErrorKind.workflowRejected =>
          l10n.comfyUiWorkflowRejectedBody,
      };
      return SetupHelpBanner(
        icon: Icons.image_outlined,
        title: comfy.kind == ComfyUiPromptErrorKind.diffusionOnly
            ? l10n.comfyUiDiffusionOnlyTitle
            : l10n.comfyUiNoCheckpointsTitle,
        steps: [body],
        actions: [
          if (onOpenImageSettings != null)
            _ErrorActionChip(
              label: l10n.openImageSettings,
              icon: Icons.tune_rounded,
              color: Theme.of(context).colorScheme.primary,
              onTap: onOpenImageSettings!,
            ),
        ],
        onDismiss: onDismiss,
      );
    }

    final imageUnreachable = ImageGenUnreachableError.parse(detailBlob);
    if (imageUnreachable != null) {
      final name = imageUnreachable.providerLabel;
      final url = imageUnreachable.url.trim();
      return SetupHelpBanner(
        icon: Icons.image_not_supported_outlined,
        title: l10n.imageGenUnreachableTitle(name),
        steps: [
          url.isEmpty
              ? l10n.imageGenUnreachableNoUrlBody
              : l10n.imageGenUnreachableBody(name, url),
        ],
        actions: [
          if (onOpenImageSettings != null)
            _ErrorActionChip(
              label: l10n.openImageSettings,
              icon: Icons.tune_rounded,
              color: Theme.of(context).colorScheme.primary,
              onTap: onOpenImageSettings!,
            ),
        ],
        onDismiss: onDismiss,
      );
    }

    final chips = <Widget>[
      if (_isModelRelatedError(error) && onSelectModel != null)
        _ErrorActionChip(
          label: l10n.selectModel,
          icon: Icons.swap_horiz_rounded,
          color: textColor,
          onTap: onSelectModel!,
        ),
      if (_isModelRelatedError(error) && onGoToModels != null)
        _ErrorActionChip(
          label: l10n.goToModels,
          icon: Icons.storage_rounded,
          color: textColor,
          onTap: onGoToModels!,
        ),
    ];

    final bannerError = ServerUnreachableError.matches(detailBlob) &&
            error.contains('SocketException')
        ? l10n.connectionFailedMessage
        : error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompactErrorBanner(
          error: bannerError,
          errorDetail: errorDetail ?? (bannerError == error ? null : error),
          onDismiss: onDismiss,
          extraActions: chips,
          onAdjustMaxTokens: onAdjustMaxTokens,
          onOpenImageSettings: onOpenImageSettings,
          onCompressAndResend: onCompressAndResend,
          largeImageBytes: largeImageBytes,
        ),
        if (isLikelyNetworkIssue)
          Container(
            width: double.infinity,
            color: isDark
                ? const Color(0xFF3D1A1A)
                : Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi_lock,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.localNetworkBlocked,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.localNetworkFix,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.orange.shade200
                          : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(
                            color: Colors.orange.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.settings, size: 14),
                      label: Text(l10n.openAppSettings),
                      onPressed: () async {
                        final uri = Uri.parse('app-settings:');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ErrorActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty-chat hero greeting.
/// Empty new-chat body: greeting + prompt pills + starter tiles in one
/// scroll view so keyboard + tall composer cannot overflow the column.
class _EmptyChatScrollBody extends StatelessWidget {
  final bool showPromptPills;

  /// When true (desktop shell), skip mobile marquee/tiles — cards live under
  /// the composer instead.
  final bool suppressMobileStarters;
  final bool showImagesTile;
  final bool isLoading;
  final VoidCallback onPickFile;
  final VoidCallback? onPickImage;
  final VoidCallback? onTakePhoto;
  final VoidCallback onTranscribe;
  final VoidCallback onGeneratePersona;
  final ValueChanged<String> onPromptSelected;
  final VoidCallback onChatFiles;
  final VoidCallback? onImages;
  final VoidCallback onTranslate;
  final VoidCallback onAudioChat;

  const _EmptyChatScrollBody({
    required this.showPromptPills,
    this.suppressMobileStarters = false,
    required this.showImagesTile,
    required this.isLoading,
    required this.onPickFile,
    required this.onPickImage,
    required this.onTakePhoto,
    required this.onTranscribe,
    required this.onGeneratePersona,
    required this.onPromptSelected,
    required this.onChatFiles,
    required this.onImages,
    required this.onTranslate,
    required this.onAudioChat,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Phone landscape + short height: skip hero so tiles keep the room.
        // Desktop shell is usually "landscape" by MediaQuery — still show greeting.
        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final showMobileCards = !suppressMobileStarters;
        final showMobilePills =
            showPromptPills && !suppressMobileStarters && !isLandscape;
        final showGreeting = suppressMobileStarters
            ? constraints.maxHeight >= 80
            : !isLandscape && constraints.maxHeight >= 120;

        if (!showMobileCards && !showGreeting) {
          return const SizedBox.shrink();
        }

        final starters = showMobileCards
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showMobilePills) ...[
                    ScrollingPromptCards(
                      enabled: !isLoading,
                      showImageAction: showImagesTile,
                      onPickFile: onPickFile,
                      onPickImage: onPickImage,
                      onTakePhoto: onTakePhoto,
                      onTranscribe: onTranscribe,
                      onGeneratePersona: onGeneratePersona,
                      onPromptSelected: onPromptSelected,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ChatStarterTiles(
                    showImages: showImagesTile,
                    isLoading: isLoading,
                    onChatFiles: onChatFiles,
                    onImages: onImages,
                    onTranslate: onTranslate,
                    onAudioChat: onAudioChat,
                    onTranscribe: onTranscribe,
                    onGeneratePersona: onGeneratePersona,
                  ),
                  const SizedBox(height: 8),
                ],
              )
            : null;

        // Greeting centered in the empty pane; mobile starters stay bottom-pinned.
        // Fixed height (not scroll+Expanded) so Center gets a real flex slot.
        return SizedBox(
          height: constraints.maxHeight,
          child: Column(
            children: [
              Expanded(
                child: showGreeting
                    ? const Center(child: _EmptyChatGreeting())
                    : const SizedBox.shrink(),
              ),
              if (starters != null) starters,
            ],
          ),
        );
      },
    );
  }
}

class _EmptyChatGreeting extends StatelessWidget {
  const _EmptyChatGreeting();

  static const _accentDark = Color(0xFF5A3EAD);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Soft, wide glow behind the greeting — darker scrub in dark mode so
    // lavender text stays readable on the same bright cloud wallpaper.
    final shadow = [
      Shadow(
        color: (isDark ? Colors.black : Colors.white)
            .withValues(alpha: isDark ? 0.72 : 0.55),
        blurRadius: isDark ? 22 : 28,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: (isDark ? Colors.black : Colors.white)
            .withValues(alpha: isDark ? 0.5 : 0.35),
        blurRadius: isDark ? 40 : 48,
      ),
      Shadow(
        color: (isDark ? Colors.black : Colors.white)
            .withValues(alpha: isDark ? 0.32 : 0.18),
        blurRadius: isDark ? 56 : 72,
      ),
    ];
    // Modern geometric sans — reads more “AI product” than a book serif.
    final line1 = GoogleFonts.sora(
      fontWeight: FontWeight.w700,
      fontSize: 34,
      letterSpacing: -0.8,
      height: 1.15,
      color: isDark ? Colors.white : cs.onSurface,
      shadows: shadow,
    );
    final line2 = GoogleFonts.sora(
      fontWeight: FontWeight.w500,
      fontSize: 18,
      letterSpacing: -0.2,
      height: 1.3,
      // Light lavender washes out on bright wallpapers in dark mode —
      // prefer near-white with a strong dark scrub behind it.
      color: isDark ? const Color(0xFFF3ECFF) : _accentDark,
      shadows: shadow,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child:
                Text('Greetings!', style: line1, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text(
            'How may I assist you today?',
            style: line2,
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
