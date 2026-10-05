import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/call_service.dart';
import '../utils/response_parser.dart';
import '../utils/voice_stt_send_logic.dart';
import '../utils/tts_voice_display.dart';
import '../widgets/voice_conversation_surface.dart';
import '../l10n/app_localizations.dart';

/// Full-screen voice conversation mode.
/// Auto-listens → sends → streams response → reads aloud → loops.
class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen>
    with TickerProviderStateMixin {
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();
  final CallService _callService = CallService.instance;

  // State
  _VoiceState _state = _VoiceState.idle;
  String _transcribedText = '';
  String _assistantText = '';
  String _statusText = '';
  double _soundLevel = 0;
  bool _isInitialized = false;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  // Stream subscriptions
  StreamSubscription? _resultSub;
  StreamSubscription? _soundLevelSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  Timer? _listenRestartTimer;
  final ScrollController _transcriptScrollController = ScrollController();

  // Track last assistant message content to detect changes
  String? _lastAssistantContent;
  bool _isSending = false;
  bool _listenInProgress = false;
  bool _sttMicActive = false;
  int _sttConsecutiveFailures = 0;
  static const _maxSttRestartAttempts = 5;

  late final VoiceSttSendLogic _sttSendLogic;

  @override
  void initState() {
    super.initState();
    _sttSendLogic = VoiceSttSendLogic(
      onSend: (text) {
        if (!mounted) return;
        setState(() => _transcribedText = text);
        _sendTranscribedMessage(text);
      },
      onDisplayTextChanged: (text) {
        if (!mounted) return;
        setState(() => _transcribedText = text);
        _scrollTranscriptToEnd();
      },
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _initialize();
  }

  Future<void> _initialize() async {
    // Inform ChatProvider that voice mode is active
    final chatProvider = context.read<ChatProvider>();
    chatProvider.setVoiceModeActive(true);
    chatProvider
        .setVoiceCallConversationId(chatProvider.currentConversation?.id);
    // Ensure call mode is disabled when entering voice mode
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.settings.voiceCallMode) {
      settingsProvider.updateVoiceCallMode(false);
    }

    await _tts.initialize();
    final settings = settingsProvider.settings;
    if (Platform.isIOS && settings.voiceSttProvider == 'system') {
      await _callService.configureAudioSessionForVoiceChat();
    }
    final available = await _stt.initialize(
      sttProvider: settings.voiceSttProvider,
      localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
    );

    // Apply saved voice settings
    await _tts.setSpeechRate(settings.voiceSpeechRate);
    await _tts.setPitch(settings.voicePitch);
    await _tts.setLanguage(settings.voiceLanguage);
    if (settings.voiceName != null) {
      await _tts.setVoice(settings.voiceName);
    }

    // Set up TTS completion callback for continuous conversation
    _tts.onComplete = () {
      if (mounted && settings.voiceContinuousConversation) {
        // Auto-listen after speaking
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _state == _VoiceState.speaking) {
            _startListening();
          }
        });
      } else if (mounted) {
        setState(() => _state = _VoiceState.idle);
      }
    };

    _tts.onStart = () {
      if (mounted) setState(() => _state = _VoiceState.speaking);
    };

    // Set up STT streams
    _soundLevelSub = _stt.soundLevelStream.listen((level) {
      if (!mounted) return;
      setState(() => _soundLevel = level);
      if (level > 0.15 && _state == _VoiceState.listening) {
        final settings = context.read<SettingsProvider>().settings;
        _sttSendLogic.notifySpeechActivity(settings.voiceSttPauseForSeconds);
      }
    });

    _statusSub = _stt.statusStream.listen((status) {
      if (!mounted) return;
      if (status == 'listening') {
        _sttConsecutiveFailures = 0;
        if (!_sttMicActive) {
          setState(() => _sttMicActive = true);
        }
        return;
      }
      if (status == 'done' || status == 'notListening') {
        if (_sttMicActive) {
          setState(() => _sttMicActive = false);
        }
        if (_state == _VoiceState.review) {
          return;
        }
        if (_state == _VoiceState.listening) {
          if (_sttSendLogic.hasBufferedSpeech) {
            _sttSendLogic.commitSession();
            setState(() => _transcribedText = _sttSendLogic.displayText);
          }
          _scheduleListenRestart(delay: const Duration(milliseconds: 300));
        }
      }
    });

    _errorSub = _stt.errorStream.listen((error) {
      if (!mounted) return;
      if (SttService.isBenignSystemSttError(error)) {
        if (_state == _VoiceState.listening) {
          _scheduleListenRestart(delay: const Duration(milliseconds: 400));
        }
        return;
      }
      debugPrint('Voice mode: STT error: $error');
      _sttConsecutiveFailures++;
      if (_sttConsecutiveFailures >= _maxSttRestartAttempts) {
        _cancelPendingListenRestart();
        setState(() {
          _state = _VoiceState.idle;
          _sttMicActive = false;
          _errorMessage =
              'Microphone unavailable. Try again or use the keyboard.';
        });
        return;
      }
      if (_state == _VoiceState.review) {
        return;
      }
      if (_state == _VoiceState.listening) {
        _sttSendLogic.commitSession();
        setState(() => _transcribedText = _sttSendLogic.displayText);
        _scheduleListenRestart(
          delay: Duration(milliseconds: 400 * _sttConsecutiveFailures),
        );
      }
    });

    if (mounted) {
      setState(() {
        _isInitialized = true;
        if (!available) {
          _errorMessage = 'Speech recognition not available on this device';
        }
      });
    }

    // Start CallKit session if call mode is enabled
    if (settings.voiceCallMode && CallService.isOffered) {
      final chatProvider = context.read<ChatProvider>();
      final chatTitle =
          chatProvider.currentConversation?.title ?? 'LM Mini Call Mode';
      await _callService.startCall(callerName: chatTitle);
      chatProvider
          .setVoiceCallConversationId(chatProvider.currentConversation?.id);
      _callService.onCallEnded = () {
        // System or user ended the call from lock-screen / notification
        if (mounted) {
          _stopEverything();
          context.read<ChatProvider>().setVoiceCallConversationId(null);
          Navigator.of(context).pop();
        }
      };
    }
  }

  @override
  void dispose() {
    _callService.onCallEnded = null;
    _callService.endCall();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.setVoiceModeActive(false);
    chatProvider.setVoiceCallConversationId(null);
    // Disable call mode setting when leaving voice mode
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.settings.voiceCallMode) {
      settingsProvider.updateVoiceCallMode(false);
    }
    _pulseController.dispose();
    _waveController.dispose();
    _resultSub?.cancel();
    _soundLevelSub?.cancel();
    _statusSub?.cancel();
    _errorSub?.cancel();
    _cancelPendingListenRestart();
    _sttSendLogic.dispose();
    _transcriptScrollController.dispose();
    _tts.stop();
    _stt.stopListening();
    super.dispose();
  }

  void _scrollTranscriptToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_transcriptScrollController.hasClients) return;
      final max = _transcriptScrollController.position.maxScrollExtent;
      if (max <= 0) return;
      _transcriptScrollController.jumpTo(max);
    });
  }

  void _cancelPendingListenRestart() {
    _listenRestartTimer?.cancel();
    _listenRestartTimer = null;
  }

  void _scheduleListenRestart(
      {Duration delay = const Duration(milliseconds: 400)}) {
    if (!mounted) return;
    if (_sttConsecutiveFailures >= _maxSttRestartAttempts) return;
    _cancelPendingListenRestart();
    _listenRestartTimer = Timer(delay, () async {
      _listenRestartTimer = null;
      if (!mounted || _state != _VoiceState.listening) return;
      await _safeStartListening();
    });
  }

  Future<void> _safeStartListening() async {
    try {
      _sttSendLogic.commitSession();
      await _stt.stopListening();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        await _startListening(preserveBuffer: true);
      }
    } catch (e) {
      debugPrint('Voice mode: safe restart failed: $e');
      if (mounted) {
        setState(() {
          _state = _VoiceState.idle;
          _sttMicActive = false;
        });
      }
    }
  }

  Future<void> _startListening({bool preserveBuffer = false}) async {
    if (!mounted || _listenInProgress) return;
    _listenInProgress = true;
    try {
      if (!preserveBuffer) {
        _sttSendLogic.reset();
      }
      setState(() {
        _state = _VoiceState.listening;
        if (preserveBuffer) {
          _transcribedText = _sttSendLogic.displayText;
        } else {
          _transcribedText = '';
        }
        _errorMessage = null;
        _statusText = '';
      });

      // Convert voiceLanguage (e.g., 'en-US') to STT locale format (e.g., 'en_US')
      final settings = context.read<SettingsProvider>().settings;
      final sttLocale = settings.voiceSttLanguage.replaceAll('-', '_');

      await _stt.initialize(
        sttProvider: settings.voiceSttProvider,
        localeId: sttLocale,
      );
      if (_tts.isSpeaking) await _tts.stop();
      if (settings.voiceSttProvider == 'system') {
        await Future.delayed(const Duration(milliseconds: 350));
      }
      if (!mounted) return;

      final listenCap = Duration(seconds: settings.voiceSttListenForSeconds);
      var started = await _stt.startListening(
        onResult: (result) {
          // Only accept results while actively listening — late decodes
          // arriving during thinking/speaking would transcribe the
          // assistant's own TTS audio and re-send it in a loop.
          if (mounted && _state == _VoiceState.listening) {
            _sttSendLogic.handleResult(
              result,
              settings.voiceSttPauseForSeconds,
            );
          }
        },
        listenFor: listenCap,
        pauseFor: listenCap,
        pauseForSeconds: settings.voiceSttPauseForSeconds,
        sttProvider: settings.voiceSttProvider,
        localeId: sttLocale,
      );

      if (!started &&
          settings.voiceSttProvider == 'system' &&
          _sttConsecutiveFailures < _maxSttRestartAttempts) {
        await _stt.initialize(sttProvider: 'system', localeId: sttLocale);
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted && _state == _VoiceState.listening) {
          started = await _stt.startListening(
            onResult: (result) {
              if (mounted && _state == _VoiceState.listening) {
                _sttSendLogic.handleResult(
                  result,
                  settings.voiceSttPauseForSeconds,
                );
              }
            },
            listenFor: listenCap,
            pauseFor: listenCap,
            pauseForSeconds: settings.voiceSttPauseForSeconds,
            sttProvider: settings.voiceSttProvider,
            localeId: sttLocale,
          );
        }
      }

      if (!started && mounted) {
        _sttConsecutiveFailures++;
        if (_sttConsecutiveFailures >= _maxSttRestartAttempts) {
          setState(() {
            _state = _VoiceState.idle;
            _sttMicActive = false;
            _errorMessage =
                'Could not start listening. Check microphone permissions.';
          });
        } else {
          setState(() {
            _state = _VoiceState.listening;
            _sttMicActive = false;
            _errorMessage = 'Retrying microphone…';
          });
          _scheduleListenRestart(
            delay: Duration(milliseconds: 500 * _sttConsecutiveFailures),
          );
        }
      } else if (started) {
        _sttConsecutiveFailures = 0;
      }
    } finally {
      _listenInProgress = false;
    }
  }

  Future<void> _pauseListeningForReview() async {
    _cancelPendingListenRestart();
    _sttSendLogic.cancelPendingSend();
    await _stt.stopListening();
    if (!mounted) return;
    _sttSendLogic.commitSession();
    final text = _sttSendLogic.displayText.trim();
    if (text.isEmpty) {
      setState(() {
        _state = _VoiceState.idle;
        _sttMicActive = false;
      });
      return;
    }
    setState(() {
      _transcribedText = text;
      _state = _VoiceState.review;
      _sttMicActive = false;
    });
  }

  void _discardReview() {
    _cancelPendingListenRestart();
    _sttSendLogic.reset();
    setState(() {
      _state = _VoiceState.idle;
      _transcribedText = '';
      _sttMicActive = false;
    });
  }

  Future<void> _sendTranscribedMessage([String? messageOverride]) async {
    if (_isSending) return;
    final message = (messageOverride ?? _transcribedText).trim();
    if (message.isEmpty) {
      setState(() => _state = _VoiceState.idle);
      return;
    }

    _isSending = true;
    // Release the mic immediately — otherwise Whisper keeps transcribing
    // (including the assistant's TTS voice) and auto-sends echo messages.
    _cancelPendingListenRestart();
    _sttSendLogic.cancelPendingSend();
    _transcribedText = '';
    _sttSendLogic.reset();
    setState(() {
      _state = _VoiceState.thinking;
      _sttMicActive = false;
      _assistantText = '';
      _statusText = '';
    });
    try {
      await _stt.cancelListening();
    } catch (e) {
      debugPrint('VoiceModeScreen: cancelListening failed: $e');
    }
    if (!mounted) {
      _isSending = false;
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    _lastAssistantContent = '';

    // Send the message through the normal chat flow
    await chatProvider.sendMessage(
      message,
      settingsProvider.settings,
      settingsProvider: settingsProvider,
      uiContext: context,
    );

    _isSending = false;

    // Monitor for the response
    _monitorResponse();
  }

  void _monitorResponse() {
    // Poll for response completion
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final chatProvider = context.read<ChatProvider>();
      final messages = chatProvider.currentMessages;
      final isLoading = chatProvider.isLoading;

      // Find the latest assistant message
      String currentContent = '';
      for (int i = messages.length - 1; i >= 0; i--) {
        if (messages[i].role == 'assistant' &&
            !messages[i].content.startsWith('Tool call:') &&
            !messages[i].content.startsWith('MCP call:') &&
            !messages[i].content.startsWith('🔧 MCP call:')) {
          currentContent = messages[i].content;
          break;
        }
      }

      // Keep UI conversational — orb + transcript only.
      if (currentContent != _lastAssistantContent) {
        _lastAssistantContent = currentContent;
        // Parse to get just the answer (skip thinking)
        final parsed = ResponseParser.parse(currentContent);
        setState(() {
          _assistantText = ResponseParser.cleanForTts(parsed.answer);
          if (_state != _VoiceState.speaking) {
            _state = _VoiceState.responding;
          }
        });
        _scrollTranscriptToEnd();
      }

      // When done loading, read aloud
      if (!isLoading && currentContent.isNotEmpty) {
        timer.cancel();
        final parsed = ResponseParser.parse(currentContent);
        final cleanAnswer = ResponseParser.cleanForTts(parsed.answer);
        setState(() {
          _assistantText = cleanAnswer;
        });
        _scrollTranscriptToEnd();
        _readResponse(cleanAnswer);
      }
    });
  }

  Future<void> _readResponse(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _state = _VoiceState.idle);
      return;
    }

    setState(() => _state = _VoiceState.speaking);
    await _tts.speak(text);
  }

  void _stopEverything() {
    _tts.stop();
    _stt.stopListening();
    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.isLoading) {
      chatProvider.stopGeneration();
    }
    setState(() {
      _state = _VoiceState.idle;
      _transcribedText = '';
      _statusText = '';
    });
    _sttSendLogic.reset();
  }

  Future<void> _toggleCallMode(SettingsProvider settingsProvider) async {
    if (!CallService.isOffered) return;
    final newValue = !settingsProvider.settings.voiceCallMode;
    settingsProvider.updateVoiceCallMode(newValue);
    final chatProvider = context.read<ChatProvider>();

    if (newValue) {
      // Start CallKit session immediately
      final chatTitle =
          chatProvider.currentConversation?.title ?? 'LM Mini Call Mode';
      await _callService.startCall(callerName: chatTitle);
      chatProvider
          .setVoiceCallConversationId(chatProvider.currentConversation?.id);
      _callService.onCallEnded = () {
        if (mounted) {
          _stopEverything();
          context.read<ChatProvider>().setVoiceCallConversationId(null);
          Navigator.of(context).pop();
        }
      };
    } else {
      // End CallKit session immediately
      _callService.onCallEnded = null;
      chatProvider.setVoiceCallConversationId(null);
      await _callService.endCall();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _stopEverything();
            _callService.endCall();
            Navigator.pop(context);
          },
        ),
        title: Text(l10n.voiceMode),
        centerTitle: true,
        actions: [
          if (CallService.isOffered)
            Consumer<SettingsProvider>(
              builder: (context, sp, _) {
                final isCallActive = sp.settings.voiceCallMode;
                return IconButton(
                  icon: Icon(
                    isCallActive ? Icons.phone_in_talk : Icons.phone_disabled,
                    color: isCallActive ? Colors.green : null,
                  ),
                  onPressed: () => _toggleCallMode(sp),
                  tooltip:
                      isCallActive ? 'Disable call mode' : 'Enable call mode',
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showVoiceSettings(context),
            tooltip: l10n.voiceSettings,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withValues(alpha: 0.98),
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                  ]
                : [
                    theme.colorScheme.surface,
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: VoiceTranscriptViewport(
                            scrollController: _transcriptScrollController,
                            userText: (_state == _VoiceState.listening ||
                                        _state == _VoiceState.review) &&
                                    _transcribedText.trim().isNotEmpty
                                ? _transcribedText
                                : null,
                            assistantText: _assistantText.trim().isNotEmpty
                                ? _assistantText
                                : null,
                            visibleLines: 4,
                            showUserLiveIndicator:
                                _state == _VoiceState.listening &&
                                    (_sttMicActive || _listenInProgress),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final isListening = _state == _VoiceState.listening;
                  final isReview = _state == _VoiceState.review;
                  final micLive =
                      isListening && (_sttMicActive || _listenInProgress);
                  final isSpeaking = _state == _VoiceState.speaking;
                  final isProcessing = _state == _VoiceState.thinking ||
                      _state == _VoiceState.responding;
                  final accent = voiceConversationAccent(
                    theme.colorScheme,
                    listening: isListening || isReview,
                    processing: isProcessing,
                    speaking: isSpeaking,
                  );
                  final hint = isReview
                      ? l10n.voiceConvoHintIdle
                      : voiceConversationHint(
                          l10n,
                          idle: _state == _VoiceState.idle,
                          listening: isListening,
                          processing: isProcessing,
                          speaking: isSpeaking,
                        );
                  return Column(
                    children: [
                      VoiceConversationOrb(
                        animation: _pulseAnimation,
                        waveAnimation: _waveController,
                        size: 148,
                        soundLevel: _soundLevel,
                        isListening: micLive,
                        isSpeaking: isSpeaking,
                        isProcessing: isProcessing || (isListening && !micLive),
                        baseColor: accent,
                        onTap: _isInitialized ? _onOrbTap : null,
                        onLongPress: () {
                          if (_state != _VoiceState.idle) _stopEverything();
                        },
                      ),
                      if (hint.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          hint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (isReview) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _discardReview,
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                              label: Text(l10n.voiceDiscardRecording),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.errorContainer,
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => _sendTranscribedMessage(),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(l10n.sendLabel),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.errorContainer,
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onOrbTap() {
    switch (_state) {
      case _VoiceState.idle:
        _startListening();
        break;
      case _VoiceState.listening:
        _pauseListeningForReview();
        break;
      case _VoiceState.review:
        _startListening(preserveBuffer: true);
        break;
      case _VoiceState.speaking:
        _tts.stop();
        setState(() => _state = _VoiceState.idle);
        break;
      case _VoiceState.thinking:
      case _VoiceState.responding:
        _stopEverything();
        break;
    }
  }

  void _showVoiceSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.voiceSettings,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Speech Rate
                      Text(l10n.voiceSpeechRate,
                          style: Theme.of(context).textTheme.titleSmall),
                      Slider(
                        value: settings.voiceSpeechRate,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        label: '${(settings.voiceSpeechRate * 100).round()}%',
                        onChanged: (value) {
                          settingsProvider.updateVoiceSpeechRate(value);
                          _tts.setSpeechRate(value);
                          setSheetState(() {});
                        },
                      ),

                      // Pitch
                      Text(l10n.voicePitch,
                          style: Theme.of(context).textTheme.titleSmall),
                      Slider(
                        value: settings.voicePitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 30,
                        label: settings.voicePitch.toStringAsFixed(1),
                        onChanged: (value) {
                          settingsProvider.updateVoicePitch(value);
                          _tts.setPitch(value);
                          setSheetState(() {});
                        },
                      ),

                      const Divider(),

                      // Voice selection
                      Text(l10n.voiceSelection,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _buildVoicePicker(
                          context, settingsProvider, setSheetState),

                      const Divider(height: 32),

                      // Auto-read new responses
                      SwitchListTile(
                        title: Text(l10n.voiceAutoRead),
                        subtitle: Text(l10n.voiceAutoReadSubtitle),
                        value: settings.voiceAutoRead,
                        onChanged: (value) {
                          settingsProvider.updateVoiceAutoRead(value);
                          setSheetState(() {});
                        },
                      ),

                      // Continuous conversation
                      SwitchListTile(
                        title: Text(l10n.voiceContinuousConversation),
                        subtitle:
                            Text(l10n.voiceContinuousConversationSubtitle),
                        value: settings.voiceContinuousConversation,
                        onChanged: (value) {
                          settingsProvider
                              .updateVoiceContinuousConversation(value);
                          setSheetState(() {});
                        },
                      ),

                      // Auto-send after recognition
                      SwitchListTile(
                        title: Text(l10n.voiceAutoSend),
                        subtitle: Text(l10n.voiceAutoSendSubtitle),
                        value: settings.voiceAutoSend,
                        onChanged: (value) {
                          settingsProvider.updateVoiceAutoSend(value);
                          setSheetState(() {});
                        },
                      ),

                      const SizedBox(height: 16),

                      // Test voice button
                      OutlinedButton.icon(
                        onPressed: () {
                          _tts.speak(l10n.voiceTestPhrase);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.voiceTestVoice),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVoicePicker(BuildContext context,
      SettingsProvider settingsProvider, StateSetter setSheetState) {
    final settings = settingsProvider.settings;
    final langCode = settings.voiceLanguage.split('-').first;
    final voices = _tts.getVoicesForLanguage(langCode);
    final voiceIndexMap = TtsVoiceDisplay.indexMapForVoices(voices);

    if (voices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No voices available for $langCode',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: voices.length,
        itemBuilder: (context, index) {
          final voice = voices[index];
          final name = voice['name'] ?? 'Unknown';
          final isSelected = name == settings.voiceName;
          final displayTitle = _tts.displayTitleForVoice(
            voice,
            indexWithinLocale: voiceIndexMap[name],
          );

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _tts.displaySubtitleForVoice(voice),
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                  ),
                ],
              ),
              onSelected: (selected) {
                settingsProvider.updateVoiceName(selected ? name : null);
                _tts.setVoice(selected ? name : null);
                setSheetState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}

enum _VoiceState {
  idle,
  listening,
  review,
  thinking,
  responding,
  speaking,
}

/// Animated builder that works with AnimationController
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
