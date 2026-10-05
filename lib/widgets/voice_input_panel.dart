import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/stt_recognition_result.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/mac_system_stt_service.dart';
import '../services/kokoro_tts_service.dart';
import '../services/remote_kokoro_tts_service.dart';
import '../services/elevenlabs_tts_service.dart';
import '../services/grok_tts_service.dart';
import '../services/call_service.dart';
import '../services/macos_media_permissions.dart';
import '../services/whisper_model_manager.dart';
import '../desktop/desktop_platform.dart';
import '../utils/response_parser.dart';
import '../utils/client_platform.dart';
import '../utils/voice_stt_send_logic.dart';
import '../utils/kokoro_speaker_resolver.dart';
import '../utils/elevenlabs_voice_resolver.dart';
import '../utils/grok_voice_resolver.dart';
import '../utils/tts_engine.dart';
import '../widgets/voice_conversation_surface.dart';
import '../widgets/composer_shine_border.dart';
import '../l10n/app_localizations.dart';
import 'glass_blur.dart';

/// Inline voice conversation panel that replaces MessageInput at the bottom
/// of the chat screen. Shows animated orb, state label, and transcription.
/// Handles the TTS→STT loop for continuous voice conversation.
class VoiceInputPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onScrollToBottom;
  final bool autoStartCallMode;
  final String? initialPrompt;

  const VoiceInputPanel({
    super.key,
    required this.onClose,
    this.onScrollToBottom,
    this.autoStartCallMode = false,
    this.initialPrompt,
  });

  @override
  State<VoiceInputPanel> createState() => _VoiceInputPanelState();
}

enum VoicePanelState {
  idle,
  listening,
  review,
  thinking,
  responding,
  speaking,
}

class _VoiceInputPanelState extends State<VoiceInputPanel>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();
  final KokoroTtsService _kokoroTts = KokoroTtsService();
  final RemoteKokoroTtsService _remoteKokoroTts = RemoteKokoroTtsService();
  final ElevenLabsTtsService _elevenLabsTts = ElevenLabsTtsService();
  final GrokTtsService _grokTts = GrokTtsService();
  final CallService _callService = CallService.instance;

  VoicePanelState _state = VoicePanelState.idle;
  String _transcribedText = '';
  String _assistantPreviewText = '';
  String _statusText = '';
  double _soundLevel = 0;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _lastAssistantContent;
  int _responseBaseIndex =
      0; // Message count before sending — only monitor messages after this
  bool _isSending = false;

  /// True while waiting for model reply TTS (own send or group chip tap).
  bool _awaitingResponse = false;

  /// Group chat: message currently being spoken (persona voice).
  String? _groupActiveMessageId;
  final Set<String> _groupCompletedIds = {};
  bool _isPlayingAudioCue = false;
  AudioPlayer? _beepPlayer;
  VoidCallback? _chatProviderListener;
  ChatProvider? _chatProviderRef;
  SettingsProvider? _settingsProviderRef;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _soundLevelSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  Timer? _responseMonitor;
  Timer? _listenRestartTimer;
  final ScrollController _transcriptScrollController = ScrollController();

  /// Prevents overlapping [_startListening] calls (CallKit + STT races).
  bool _listenInProgress = false;

  /// Backs off STT restarts after repeated failures in call mode.
  int _sttConsecutiveFailures = 0;
  static const _maxSttRestartAttempts = 5;

  /// Tracks whether the OS mic is actively capturing (vs restarting).
  bool _sttMicActive = false;

  late final VoiceSttSendLogic _sttSendLogic;

  /// STT stream listeners are attached once, after lazy init on desktop.
  bool _sttStreamsAttached = false;

  /// Set at the start of [dispose] so queued STT events cannot call setState
  /// after this State is torn down (`mounted` alone can race cancel()).
  bool _disposed = false;

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  void _safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _sttSendLogic = VoiceSttSendLogic(
      onSend: (text) {
        if (_disposed || !mounted) return;
        _safeSetState(() => _transcribedText = text);
        _sendTranscribedMessage(text);
      },
      onDisplayTextChanged: (text) {
        if (_disposed || !mounted) return;
        _safeSetState(() => _transcribedText = text);
        _scrollTranscriptToEnd();
      },
    );
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _initialize();

    // Inform ChatProvider that voice mode is active so auto image
    // generation defers its notifyListeners() calls to avoid cutting off TTS.
    // NOTE: voiceCallConversationId is only set when the user explicitly
    // enables call mode (phone button). Plain voice mode should NOT set it,
    // otherwise the "In call" badge and "Tap to return to call" banner
    // appear incorrectly for regular voice interactions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatProvider = context.read<ChatProvider>();
        final settingsProvider = context.read<SettingsProvider>();
        _chatProviderRef = chatProvider;
        _settingsProviderRef = settingsProvider;
        chatProvider.setVoiceModeActive(true);
        // Plain voice mode disables call mode; shortcut call mode keeps it on.
        if (!widget.autoStartCallMode &&
            settingsProvider.settings.voiceCallMode) {
          settingsProvider.updateVoiceCallMode(false);
        }
        // Chip-tap replies in group chats start generation outside this panel.
        _chatProviderListener = _onChatProviderChanged;
        chatProvider.addListener(_chatProviderListener!);
      }
    });
  }

  void _onChatProviderChanged() {
    if (_disposed || !mounted) return;
    final chatProvider = context.read<ChatProvider>();
    if (!chatProvider.isGroupChat) return;
    if (_awaitingResponse ||
        _responseMonitor != null ||
        _groupActiveMessageId != null ||
        _isSending) {
      return;
    }
    if (!(chatProvider.isSendingMessage || chatProvider.isLoading)) return;
    if (_state == VoicePanelState.thinking ||
        _state == VoicePanelState.responding ||
        _state == VoicePanelState.speaking) {
      return;
    }

    _awaitingResponse = true;
    _groupCompletedIds.clear();
    _groupActiveMessageId = null;
    _responseBaseIndex = chatProvider.currentMessages.length;
    _cancelPendingListenRestart();
    unawaited(_stt.cancelListening());
    _safeSetState(() {
      _state = VoicePanelState.thinking;
      _sttMicActive = false;
      _transcribedText = '';
      _assistantPreviewText = '';
    });
    _monitorResponse();
  }

  String _systemSttUnavailableMessage() {
    if (ClientPlatform.isIosSimulator) {
      return 'System speech recognition does not work in the iOS Simulator. '
          'Switch to Whisper in Voice Settings, or test on a real iPhone.';
    }
    return 'Could not start listening. Check Microphone and Speech Recognition '
        'in Settings → Privacy.';
  }

  Future<void> _initialize() async {
    var sttAvailable = false;
    try {
      if (!_tts.isInitialized) {
        await _tts.initialize();
      }
      if (!mounted) return;
      final settings = context.read<SettingsProvider>().settings;
      final ttsProvider = TtsEngine.effective(settings.voiceTtsProvider);

      final voice = KokoroSpeakerResolver.resolveVoice(settings: settings);
      if (ttsProvider == 'kokoro') {
        await _kokoroTts.initialize(
          language: settings.locale ?? settings.voiceSttLanguage,
        );
        _kokoroTts.setSpeakerId(voice.speakerId);
        _kokoroTts.setSpeed(voice.speed);
      } else if (ttsProvider == 'kokoro_remote') {
        await _remoteKokoroTts.initialize(
          serverUrl: settings.effectiveVoiceRemoteKokoroUrl,
          authToken: settings.voiceRemoteKokoroHeaders?['X-LM-Mini-Token'],
          language: settings.locale ?? settings.voiceSttLanguage,
        );
        _remoteKokoroTts.setSpeakerId(voice.speakerId);
        _remoteKokoroTts.setSpeed(voice.speed);
      } else if (ttsProvider == TtsEngine.elevenLabs) {
        await _elevenLabsTts.initialize(
          apiKey: settings.voiceElevenLabsApiKey,
          voiceId: ElevenLabsVoiceResolver.resolveVoiceId(settings: settings),
          modelId: settings.voiceElevenLabsModelId,
          speed: voice.speed,
        );
      } else if (ttsProvider == TtsEngine.grok) {
        await _grokTts.initialize(
          apiKey: settings.voiceGrokApiKey,
          voiceId: GrokVoiceResolver.resolveVoiceId(settings: settings),
          language: settings.locale ?? settings.voiceLanguage,
          speed: voice.speed,
        );
      }

      await _applyTtsSettings(settings);

      // iOS system Speech needs playAndRecord — Kokoro/TTS init may leave
      // the session in playback-only mode before the first listen attempt.
      // Use dictation mode (not .voiceChat) for best recognition accuracy;
      // call mode reconfigures to .voiceChat via _toggleCallMode.
      if (Platform.isIOS && settings.voiceSttProvider == 'system') {
        if (settings.voiceCallMode) {
          await _callService.configureAudioSessionForVoiceChat();
        } else {
          await _callService.configureAudioSessionForDictation();
        }
      }

      // STT touches the mic stack — defer on desktop until the user taps the orb.
      if (!_isDesktop) {
        sttAvailable = await _stt.initialize(
          sttProvider: settings.voiceSttProvider,
          localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
        );
        if (sttAvailable) {
          _attachSttStreams();
        }
      }
    } catch (e, st) {
      debugPrint('VoiceInputPanel: initialization failed: $e\n$st');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage =
              'Voice mode failed to start on this device. Try again.';
        });
      }
      return;
    }

    _wireTtsCallbacks();

    if (!_isDesktop) {
      _beepPlayer = AudioPlayer();
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
        if (!_isDesktop && !sttAvailable) {
          _errorMessage = 'Speech recognition not available on this device';
        }
      });

      if (sttAvailable && !_isDesktop) {
        Future.delayed(const Duration(milliseconds: 400), () async {
          if (!mounted) return;
          await _bootstrapShortcutVoiceSession(sttAvailable);
        });
      } else if (widget.autoStartCallMode && !_isDesktop) {
        Future.delayed(const Duration(milliseconds: 400), () async {
          if (!mounted) return;
          await _bootstrapShortcutVoiceSession(false);
        });
      }
    }
  }

  Future<void> _applyTtsSettings(AppSettings settings) async {
    try {
      await _tts.setSpeechRate(settings.voiceSpeechRate);
      await _tts.setPitch(settings.voicePitch);
      await _tts.setLanguage(settings.voiceLanguage);
      if (settings.voiceName != null) {
        await _tts.setVoice(settings.voiceName);
      }
    } catch (e) {
      debugPrint('VoiceInputPanel: TTS settings failed: $e');
    }
  }

  void _attachSttStreams() {
    if (_sttStreamsAttached || _disposed) return;
    _sttStreamsAttached = true;

    _soundLevelSub = _stt.soundLevelStream.listen((level) {
      if (_disposed || !mounted) return;
      _safeSetState(() => _soundLevel = level);
      // When the mic picks up speech-level amplitude, reset the send
      // timer so a slow Whisper decode can't race the countdown while
      // the user is still mid-sentence (ChatGPT-like smooth listening).
      if (level > 0.15 && _state == VoicePanelState.listening) {
        final settings = context.read<SettingsProvider>().settings;
        _sttSendLogic.notifySpeechActivity(settings.voiceSttPauseForSeconds);
      }
    });

    _statusSub = _stt.statusStream.listen((status) {
      if (_disposed || !mounted) return;
      if (status == 'listening') {
        _sttConsecutiveFailures = 0;
        if (!_sttMicActive) {
          _safeSetState(() => _sttMicActive = true);
        }
        return;
      }
      if (status == 'done' || status == 'notListening') {
        if (_sttMicActive) {
          _safeSetState(() => _sttMicActive = false);
        }
        if (_state == VoicePanelState.review) {
          return;
        }
        // iOS ends mic sessions frequently (~10–20 s). Keep the voice
        // panel in listening mode and restart capture instead of going idle.
        if (_state == VoicePanelState.listening) {
          if (_sttSendLogic.hasBufferedSpeech) {
            _sttSendLogic.commitSession();
            _safeSetState(() => _transcribedText = _sttSendLogic.displayText);
          }
          _scheduleListenRestart(delay: const Duration(milliseconds: 300));
        }
      }
    });

    _errorSub = _stt.errorStream.listen((error) {
      if (_disposed || !mounted) return;
      if (SttService.isBenignSystemSttError(error)) {
        if (_state == VoicePanelState.listening) {
          _scheduleListenRestart(delay: const Duration(milliseconds: 400));
        }
        return;
      }
      debugPrint('Voice: STT error while in panel: $error');
      if (error.contains('no audio is arriving') ||
          error.contains('Microphone is open but')) {
        _cancelPendingListenRestart();
        _safeSetState(() {
          _state = VoicePanelState.idle;
          _sttMicActive = false;
          _errorMessage = error;
        });
        return;
      }
      final settings = context.read<SettingsProvider>().settings;
      if (ClientPlatform.isIosSimulator &&
          settings.voiceSttProvider == 'system' &&
          error.contains('error_listen_failed')) {
        _cancelPendingListenRestart();
        _safeSetState(() {
          _state = VoicePanelState.idle;
          _sttMicActive = false;
          _errorMessage = _systemSttUnavailableMessage();
        });
        return;
      }
      _sttConsecutiveFailures++;
      if (_sttConsecutiveFailures >= _maxSttRestartAttempts) {
        _cancelPendingListenRestart();
        _safeSetState(() {
          _state = VoicePanelState.idle;
          _sttMicActive = false;
          _errorMessage =
              'Microphone unavailable. End call mode and try again.';
        });
        return;
      }
      if (_state == VoicePanelState.review) {
        return;
      }
      if (_state == VoicePanelState.listening) {
        _sttSendLogic.commitSession();
        _safeSetState(() => _transcribedText = _sttSendLogic.displayText);
        _scheduleListenRestart(
          delay: Duration(milliseconds: 400 * _sttConsecutiveFailures),
        );
      }
    });
  }

  /// Lazily initialize STT (deferred on desktop until the user taps the orb).
  /// Returns null on success, or a user-facing error string on failure.
  Future<String?> _ensureSttReady() async {
    final settings = context.read<SettingsProvider>().settings;
    var provider = settings.voiceSttProvider;

    // Always surface Mic TCC dialogs before touching the recorder.
    final micOk = await VoiceCapturePermissions.ensureForVoiceInput();
    if (!micOk) {
      return _isDesktop
          ? 'Microphone access is required. Allow it when prompted, or enable LM Mini in System Settings → Privacy & Security → Microphone.'
          : 'Could not start listening. Check microphone permissions.';
    }

    // Sandboxed Mac forces Whisper ONLY when the native macOS speech bridge
    // is unavailable (dev/IDE launches). Installed builds keep "system".
    final macNative = await MacSystemSttService.instance.isAvailable();
    final macWhisperOnly =
        DesktopPlatform.macListeningRequiresWhisper && !macNative;
    if (macWhisperOnly && provider == 'system') {
      provider = 'whisper';
      if (mounted) {
        context.read<SettingsProvider>().updateVoiceSttProvider('whisper');
      }
    }

    if (provider == 'whisper' || macWhisperOnly) {
      provider = 'whisper';
      final usableId = await WhisperModelManager.instance.resolveUsableModelId(
        context.read<SettingsProvider>().settings.whisperModelId,
      );
      if (usableId == null) {
        return macWhisperOnly
            ? 'On-device listening requires a Whisper speech model. Open Voice Settings and download Tiny (or another) Whisper model, then try again.'
            : 'Download a Whisper speech model in Voice Settings to use on-device listening.';
      }
      if (mounted) {
        final sp = context.read<SettingsProvider>();
        if (sp.settings.whisperModelId != usableId) {
          sp.updateWhisperModelId(usableId);
        }
        if (sp.settings.voiceSttProvider != 'whisper') {
          sp.updateVoiceSttProvider('whisper');
        }
      }
    }

    if (_stt.isInitialized &&
        _stt.isAvailable &&
        _stt.activeProvider == provider) {
      _attachSttStreams();
      return null;
    }
    try {
      final available = await _stt.initialize(
        sttProvider: provider,
        localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
      );
      if (available) {
        _attachSttStreams();
        return null;
      }
      if (macWhisperOnly) {
        return 'Could not start Whisper listening. Open Voice Settings, confirm a Whisper model is downloaded, then try again.';
      }
      return _isDesktop
          ? 'Could not start listening. Check Voice Settings and try again.'
          : 'Could not start listening. Check microphone permissions.';
    } catch (e, st) {
      debugPrint('VoiceInputPanel: STT init failed: $e\n$st');
      return 'Could not start listening: $e';
    }
  }

  void _wireTtsCallbacks() {
    _tts.onComplete = () {
      if (_isPlayingAudioCue) {
        _isPlayingAudioCue = false;
        return;
      }
      _onTtsComplete();
    };

    _tts.onCancel = () {
      _isPlayingAudioCue = false;
      if (mounted && _state == VoicePanelState.speaking) {
        setState(() => _state = VoicePanelState.idle);
      }
    };

    _tts.onError = () {
      _isPlayingAudioCue = false;
      if (mounted && _state == VoicePanelState.speaking) {
        _onTtsComplete();
      }
    };

    _tts.onStart = () {
      if (mounted && !_isPlayingAudioCue) {
        setState(() => _state = VoicePanelState.speaking);
      }
    };

    _kokoroTts.onComplete = _onTtsComplete;
    _kokoroTts.onError = () {};

    _remoteKokoroTts.onComplete = _onTtsComplete;
    _remoteKokoroTts.onError = () {};

    _elevenLabsTts.onComplete = _onTtsComplete;
    _elevenLabsTts.onError = () {};

    _grokTts.onComplete = _onTtsComplete;
    _grokTts.onError = () {};
  }

  Future<void> _bootstrapShortcutVoiceSession(bool sttAvailable) async {
    if (widget.autoStartCallMode && CallService.isOffered) {
      final sp = context.read<SettingsProvider>();
      if (!sp.settings.voiceCallMode || !_callService.isCallActive) {
        await _toggleCallMode(sp);
      }
    }

    final seedPrompt = widget.initialPrompt?.trim();
    if (seedPrompt != null && seedPrompt.isNotEmpty) {
      _transcribedText = seedPrompt;
      _sendTranscribedMessage();
      return;
    }

    if (sttAvailable && _state == VoicePanelState.idle) {
      await _startListening();
    }
  }

  void _cancelPendingListenRestart() {
    _listenRestartTimer?.cancel();
    _listenRestartTimer = null;
  }

  void _scheduleListenRestart(
      {Duration delay = const Duration(milliseconds: 400)}) {
    if (_disposed || !mounted) return;
    if (_sttConsecutiveFailures >= _maxSttRestartAttempts) return;
    _cancelPendingListenRestart();
    _listenRestartTimer = Timer(delay, () async {
      _listenRestartTimer = null;
      if (_disposed || !mounted) return;
      if (_state != VoicePanelState.listening &&
          _state != VoicePanelState.idle) {
        return;
      }
      await _safeStartListening();
    });
  }

  void _onTtsComplete() {
    if (!mounted) return;

    // Group chat: play the next persona reply before returning to listen.
    if (_finishGroupUtteranceAndContinue()) return;

    _awaitingResponse = false;
    // Read settings DYNAMICALLY — not from a captured closure
    final settings = context.read<SettingsProvider>().settings;
    if (settings.voiceContinuousConversation || settings.voiceCallMode) {
      setState(() => _state = VoicePanelState.idle);
      if (settings.voiceCallMode) {
        // Re-activate audio session for recording before starting STT.
        // TTS playback may have changed the audio session category,
        // and in background iOS won't automatically restore it.
        _callService.activateAudioSessionForRecording().then((_) {
          // Play beep then restart listening in call mode
          _playBeep().then((_) {
            if (mounted &&
                (_state == VoicePanelState.idle ||
                    _state == VoicePanelState.speaking)) {
              _startListening();
            }
          });
        });
      } else {
        // Small delay before auto-listening again
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted &&
              (_state == VoicePanelState.idle ||
                  _state == VoicePanelState.speaking)) {
            _startListening();
          }
        });
      }
    } else {
      setState(() => _state = VoicePanelState.idle);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsProvider>().settings;
    final inCallMode = settings.voiceCallMode && _callService.isCallActive;

    // Keep the iOS audio session in record mode while backgrounded during CallKit.
    // Android mic access still requires the app process to stay foreground-eligible
    // (call notification / foreground service); "While using the app" blocks mic
    // when the activity is not visible.
    if (inCallMode &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      _callService.activateAudioSessionForRecording();
    }

    if (state == AppLifecycleState.resumed) {
      // When app resumes, if we're stuck in speaking/responding but TTS/streaming
      // already finished, transition to listening (call mode) or idle.
      final settings = context.read<SettingsProvider>().settings;
      final chatProvider = context.read<ChatProvider>();
      final isActive = chatProvider.isSendingMessage || chatProvider.isLoading;

      // Re-activate audio session if in call mode — iOS may have
      // deactivated it while the app was in the background
      if (inCallMode) {
        _callService.activateAudioSessionForRecording();
      }

      if (!isActive &&
          (_state == VoicePanelState.speaking ||
              _state == VoicePanelState.responding ||
              _state == VoicePanelState.thinking)) {
        // TTS/streaming finished while app was backgrounded
        if (!_tts.isSpeaking &&
            !_kokoroTts.isSpeaking &&
            !_remoteKokoroTts.isSpeaking &&
            !_elevenLabsTts.isSpeaking &&
            !_grokTts.isSpeaking) {
          if (settings.voiceCallMode || settings.voiceContinuousConversation) {
            // Delay to allow audio session to fully restore after backgrounding
            Future.delayed(const Duration(milliseconds: 600), () {
              if (!mounted) return;
              _playBeep().then((_) {
                if (mounted) {
                  _safeStartListening();
                }
              });
            });
          } else {
            setState(() => _state = VoicePanelState.idle);
          }
        }
      } else if (_state == VoicePanelState.listening) {
        // Was listening when backgrounded — audio engine may be dead, restart
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && _state == VoicePanelState.listening) {
            _safeStartListening();
          }
        });
      }
    }
  }

  /// Safely restart listening with try-catch to avoid audio engine crashes
  /// (AVAudioIONode inputFormat crash when audio session isn't ready).
  Future<void> _safeStartListening() async {
    try {
      _sttSendLogic.commitSession();
      await _stt.stopListening();
      // Re-activate audio session if in call mode — the session may
      // have been interrupted or reconfigured while backgrounded
      final settings = context.read<SettingsProvider>().settings;
      if (settings.voiceCallMode && _callService.isCallActive) {
        await _callService.activateAudioSessionForRecording();
      }
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        await _startListening(preserveBuffer: true);
      }
    } catch (e) {
      debugPrint('Voice: safe restart failed: $e');
      if (mounted) {
        setState(() {
          _state = VoicePanelState.idle;
          _sttMicActive = false;
        });
      }
    }
  }

  void _scrollTranscriptToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_transcriptScrollController.hasClients) return;
      final max = _transcriptScrollController.position.maxScrollExtent;
      if (max <= 0) return;
      _transcriptScrollController.jumpTo(max);
    });
  }

  @override
  void dispose() {
    // Mark disposed first so any already-queued STT/mic events no-op
    // instead of calling setState on a defunct Element.
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cancelPendingListenRestart();
    // Prevent CallKit callbacks from closing the panel during teardown.
    _callService.onCallEnded = null;

    _soundLevelSub?.cancel();
    _statusSub?.cancel();
    _errorSub?.cancel();
    _soundLevelSub = null;
    _statusSub = null;
    _errorSub = null;
    _sttStreamsAttached = false;
    _responseMonitor?.cancel();
    _responseMonitor = null;
    _sttSendLogic.dispose();
    _transcriptScrollController.dispose();

    _tts.onComplete = null;
    _tts.onStart = null;
    _tts.onCancel = null;
    _tts.onError = null;
    _kokoroTts.onComplete = null;
    _kokoroTts.onError = null;
    _kokoroTts.onPlaybackStart = null;
    _remoteKokoroTts.onComplete = null;
    _remoteKokoroTts.onError = null;
    _remoteKokoroTts.onPlaybackStart = null;
    _elevenLabsTts.onComplete = null;
    _elevenLabsTts.onError = null;
    _elevenLabsTts.onPlaybackStart = null;
    _grokTts.onComplete = null;
    _grokTts.onError = null;
    _grokTts.onPlaybackStart = null;
    _tts.stop();
    _kokoroTts.stop();
    _remoteKokoroTts.stop();
    _elevenLabsTts.stop();
    _grokTts.stop();
    // Stop mic after unsubscribing so status events don't hit this State.
    _stt.stopListening();
    _beepPlayer?.dispose();

    // Clear voice mode flag so auto image generation resumes normally.
    // Do not use context.read here — the element is deactivated during dispose.
    final chatProvider = _chatProviderRef;
    if (_chatProviderListener != null && chatProvider != null) {
      chatProvider.removeListener(_chatProviderListener!);
      _chatProviderListener = null;
    }
    chatProvider?.setVoiceModeActive(false);
    chatProvider?.setVoiceCallConversationId(null);
    // Disable call mode setting when leaving voice mode
    final settingsProvider = _settingsProviderRef;
    if (settingsProvider != null && settingsProvider.settings.voiceCallMode) {
      settingsProvider.updateVoiceCallMode(false);
    }

    _pulseController.dispose();
    _waveController.dispose();
    _callService.endCall();
    super.dispose();
  }

  Future<void> _toggleCallMode(SettingsProvider settingsProvider) async {
    if (!CallService.isOffered) return;
    final newValue = !settingsProvider.settings.voiceCallMode;
    final chatProvider = context.read<ChatProvider>();
    _cancelPendingListenRestart();

    if (newValue) {
      // Release the mic before CallKit reconfigures the audio session.
      await _stt.stopListening();
      if (!mounted) return;

      settingsProvider.updateVoiceCallMode(true);

      await _callService.configureAudioSessionForVoiceChat();
      if (!mounted) return;

      final chatTitle =
          chatProvider.currentConversation?.title ?? 'LM Mini Call Mode';
      await _callService.startCall(callerName: chatTitle);
      if (!mounted) return;

      chatProvider
          .setVoiceCallConversationId(chatProvider.currentConversation?.id);
      _callService.onCallEnded = () {
        if (!mounted) return;
        _cancelPendingListenRestart();
        _stopEverything();
        chatProvider.setVoiceCallConversationId(null);
        widget.onClose();
      };

      _sttConsecutiveFailures = 0;
      // Let CallKit settle the audio route before starting STT.
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _startListening();
    } else {
      _callService.onCallEnded = null;
      chatProvider.setVoiceCallConversationId(null);
      await _callService.endCall();
      await _callService.deactivateAudioSession();
      if (!mounted) return;
      settingsProvider.updateVoiceCallMode(false);
      _sttConsecutiveFailures = 0;
    }
  }

  /// Routes STT results by provider.
  ///
  /// Whisper is VAD-gated: the recognizer emits one complete utterance per
  /// turn as a final result (endpointed by trailing silence), so we send
  /// immediately on final and just mirror interims to the transcript. The
  /// old silence-timer / merge logic (`VoiceSttSendLogic`) is only needed for
  /// the system recognizer, which streams partial phrases across restarts.
  void _handleSttResult(SttRecognitionResult result, AppSettings settings) {
    // Ignore late results once we've left listening (e.g. a flush-on-stop
    // decode arriving after we've already dispatched a send).
    if (!mounted || _state != VoicePanelState.listening) return;

    if (settings.voiceSttProvider == 'whisper') {
      if (result.finalResult) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        setState(() => _transcribedText = text);
        _sendTranscribedMessage(text);
      } else {
        setState(() => _transcribedText = result.recognizedWords);
        _scrollTranscriptToEnd();
      }
      return;
    }

    _sttSendLogic.handleResult(result, settings.voiceSttPauseForSeconds);
  }

  Future<void> _startListening({bool preserveBuffer = false}) async {
    if (!mounted || _listenInProgress) return;
    _listenInProgress = true;
    try {
      final sttError = await _ensureSttReady();
      if (!mounted) return;
      if (sttError != null) {
        setState(() {
          _state = VoicePanelState.idle;
          _errorMessage = sttError;
        });
        return;
      }

      if (!preserveBuffer) {
        _sttSendLogic.reset();
        _assistantPreviewText = '';
      }
      // Stop TTS if still speaking
      if (_tts.isSpeaking) await _tts.stop();
      if (_kokoroTts.isSpeaking) await _kokoroTts.stop();
      if (_remoteKokoroTts.isSpeaking) await _remoteKokoroTts.stop();
      if (_elevenLabsTts.isSpeaking) await _elevenLabsTts.stop();
      if (_grokTts.isSpeaking) await _grokTts.stop();
      if (!mounted) return;

      // Ensure the audio session is configured for recording before STT.
      // TTS playback or backgrounding may have changed the session state.
      // Plain voice mode uses dictation mode for accuracy; call mode keeps
      // the .voiceChat session so recording continues in the background.
      final settings = context.read<SettingsProvider>().settings;
      if (Platform.isIOS && settings.voiceSttProvider == 'system') {
        if (settings.voiceCallMode && _callService.isCallActive) {
          await _callService.activateAudioSessionForRecording();
        } else {
          await _callService.configureAudioSessionForDictation();
        }
        await Future.delayed(const Duration(milliseconds: 200));
      } else if (settings.voiceCallMode && _callService.isCallActive) {
        await _callService.activateAudioSessionForRecording();
        // Brief delay to let the audio session settle after reconfiguration
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (!mounted) return;

      if (settings.voiceSttProvider == 'system' && !Platform.isIOS) {
        // Let TTS / Kokoro / Whisper release the audio session before STT.
        await Future.delayed(const Duration(milliseconds: 350));
      }
      if (!mounted) return;

      setState(() {
        _state = VoicePanelState.listening;
        if (preserveBuffer) {
          _transcribedText = _sttSendLogic.displayText;
        } else {
          _transcribedText = '';
        }
        _errorMessage = null;
        _statusText = '';
      });

      final listenCap = Duration(seconds: settings.voiceSttListenForSeconds);
      bool started = false;
      try {
        started = await _stt.startListening(
          onResult: (result) => _handleSttResult(result, settings),
          listenFor: listenCap,
          pauseFor: listenCap,
          pauseForSeconds: settings.voiceSttPauseForSeconds,
          sttProvider: settings.voiceSttProvider,
          localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
        );
      } catch (e, st) {
        debugPrint('VoiceInputPanel: startListening crashed: $e\n$st');
        started = false;
      }

      if (!started) {
        _sttConsecutiveFailures++;
        if (settings.voiceSttProvider == 'system' &&
            _sttConsecutiveFailures < _maxSttRestartAttempts) {
          await _stt.initialize(
            sttProvider: 'system',
            localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
          );
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted && _state == VoicePanelState.listening) {
            started = await _stt.startListening(
              onResult: (result) => _handleSttResult(result, settings),
              listenFor: listenCap,
              pauseFor: listenCap,
              pauseForSeconds: settings.voiceSttPauseForSeconds,
              sttProvider: settings.voiceSttProvider,
              localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
            );
          }
        }
      }

      if (!mounted) return;

      if (!started && mounted) {
        final settings = context.read<SettingsProvider>().settings;
        if (ClientPlatform.isIosSimulator &&
            settings.voiceSttProvider == 'system') {
          setState(() {
            _state = VoicePanelState.idle;
            _sttMicActive = false;
            _errorMessage = _systemSttUnavailableMessage();
          });
          return;
        }
        _sttConsecutiveFailures++;
        if (_sttConsecutiveFailures >= _maxSttRestartAttempts) {
          setState(() {
            _state = VoicePanelState.idle;
            _sttMicActive = false;
            _errorMessage = _systemSttUnavailableMessage();
          });
        } else {
          setState(() {
            _state = VoicePanelState.listening;
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
    if (!mounted) return;
    _cancelPendingListenRestart();
    _sttSendLogic.cancelPendingSend();

    final settings = context.read<SettingsProvider>().settings;
    String text;
    if (settings.voiceSttProvider == 'whisper') {
      // VAD path: use the latest interim transcript as the review text and
      // cancel cleanly so the flush doesn't auto-send this turn.
      text = _transcribedText.trim();
      await _stt.cancelListening();
    } else {
      await _stt.stopListening();
      if (!mounted) return;
      _sttSendLogic.commitSession();
      text = _sttSendLogic.displayText.trim();
    }
    if (!mounted) return;

    if (text.isEmpty) {
      setState(() {
        _state = VoicePanelState.idle;
        _sttMicActive = false;
      });
      return;
    }
    setState(() {
      _transcribedText = text;
      _state = VoicePanelState.review;
      _sttMicActive = false;
    });
  }

  void _discardReview() {
    if (!mounted) return;
    _cancelPendingListenRestart();
    _sttSendLogic.reset();
    setState(() {
      _state = VoicePanelState.idle;
      _transcribedText = '';
      _sttMicActive = false;
    });
  }

  Future<void> _sendTranscribedMessage([String? messageOverride]) async {
    if (_isSending) return;
    final message = (messageOverride ?? _transcribedText).trim();
    if (message.isEmpty) {
      setState(() => _state = VoicePanelState.idle);
      return;
    }

    _isSending = true;
    _awaitingResponse = true;
    _groupCompletedIds.clear();
    _groupActiveMessageId = null;
    // Release the mic immediately — otherwise Whisper keeps transcribing
    // (including the assistant's TTS voice) and auto-sends echo messages.
    _cancelPendingListenRestart();
    _sttSendLogic.cancelPendingSend();
    // Drop the mic now — do not flush leftover VAD (that keeps `record`
    // active and blocks Kokoro/`just_audio` with CannotInterruptOthers).
    _transcribedText = '';
    _assistantPreviewText = '';
    _sttSendLogic.reset();
    setState(() {
      _state = VoicePanelState.thinking;
      _sttMicActive = false;
      _statusText = '';
    });
    try {
      await _stt.cancelListening();
    } catch (e) {
      debugPrint('VoiceInputPanel: cancelListening failed: $e');
    }
    if (!mounted) {
      _isSending = false;
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    _lastAssistantContent = '';

    // Audio cue in call mode: play beep so user knows bot is processing
    if (settingsProvider.settings.voiceCallMode) {
      _playBeep();
    }

    // Capture current message count BEFORE sending so the monitor only
    // looks at NEW assistant messages and doesn't replay old ones.
    _responseBaseIndex = chatProvider.currentMessages.length;

    // Fire-and-forget: don't await sendMessage so the monitor can
    // feed text to Kokoro TTS while the stream is still running.
    // sendMessage sets isLoading=true synchronously before any await,
    // and errors are handled internally with try/catch.
    chatProvider.sendMessage(
      message,
      settingsProvider.settings,
      settingsProvider: settingsProvider,
      uiContext: context,
    );

    _isSending = false; // Unlock after dispatching

    // Scroll to bottom so user sees the new messages
    widget.onScrollToBottom?.call();

    // Start monitoring IMMEDIATELY — while text is still streaming in
    _monitorResponse();
  }

  void _monitorResponse() {
    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.isGroupChat) {
      _monitorGroupResponse();
      return;
    }
    _monitorSingleResponse();
  }

  List<ChatMessage> _groupAssistantMessages(ChatProvider chatProvider) {
    final messages = chatProvider.currentMessages;
    final out = <ChatMessage>[];
    for (var i = _responseBaseIndex; i < messages.length; i++) {
      final m = messages[i];
      if (m.role != 'assistant') continue;
      if (m.content.startsWith('Tool call:') ||
          m.content.startsWith('MCP call:') ||
          m.content.startsWith('🔧 MCP call:')) {
        continue;
      }
      out.add(m);
    }
    return out;
  }

  String _cleanAssistantText(String content) {
    final parsed = ResponseParser.parse(content);
    return ResponseParser.cleanForTts(parsed.answer);
  }

  /// After one persona finishes speaking, play the next ready reply (round robin).
  /// Returns true if more group TTS work remains (caller should not auto-listen yet).
  bool _finishGroupUtteranceAndContinue() {
    final chatProvider = context.read<ChatProvider>();
    if (!chatProvider.isGroupChat) return false;

    if (_groupActiveMessageId != null) {
      _groupCompletedIds.add(_groupActiveMessageId!);
      _groupActiveMessageId = null;
    }

    final next = _nextStableGroupMessage(chatProvider);
    if (next != null) {
      final text = _cleanAssistantText(next.content);
      if (text.isNotEmpty) {
        _groupActiveMessageId = next.id;
        unawaited(_readResponse(text, message: next));
        return true;
      }
      _groupCompletedIds.add(next.id);
    }

    final stillGenerating =
        chatProvider.isSendingMessage || chatProvider.isLoading;
    final pending = _groupAssistantMessages(chatProvider)
        .any((m) => !_groupCompletedIds.contains(m.id));

    if (stillGenerating || pending) {
      if (_responseMonitor == null) {
        _monitorGroupResponse();
      }
      if (mounted && _state != VoicePanelState.speaking) {
        setState(() => _state = VoicePanelState.responding);
      }
      return true;
    }

    return false;
  }

  ChatMessage? _nextStableGroupMessage(ChatProvider chatProvider) {
    final assistants = _groupAssistantMessages(chatProvider);
    final isActive = chatProvider.isSendingMessage || chatProvider.isLoading;
    for (var i = 0; i < assistants.length; i++) {
      final msg = assistants[i];
      if (_groupCompletedIds.contains(msg.id)) continue;
      if (_groupActiveMessageId == msg.id) continue;
      final isLast = i == assistants.length - 1;
      // A reply is ready once the next persona has started, or generation ended.
      final ready = !isLast || !isActive;
      if (!ready) return null;
      final text = _cleanAssistantText(msg.content);
      if (text.isEmpty) {
        _groupCompletedIds.add(msg.id);
        continue;
      }
      return msg;
    }
    return null;
  }

  void _monitorGroupResponse() {
    _responseMonitor?.cancel();
    final lastSeen = <String, String>{};
    final stableTicks = <String, int>{};

    _responseMonitor =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final chatProvider = context.read<ChatProvider>();
      final isActive = chatProvider.isSendingMessage || chatProvider.isLoading;
      final assistants = _groupAssistantMessages(chatProvider);

      if (assistants.isNotEmpty) {
        final latest = assistants.last;
        final preview = _cleanAssistantText(latest.content);
        if (preview != _assistantPreviewText) {
          setState(() => _assistantPreviewText = preview);
          _scrollTranscriptToEnd();
        }
        if (_state != VoicePanelState.speaking) {
          setState(() => _state = VoicePanelState.responding);
        }
      }

      // Already speaking — wait for TTS completion callback.
      if (_groupActiveMessageId != null) return;

      for (var i = 0; i < assistants.length; i++) {
        final msg = assistants[i];
        if (_groupCompletedIds.contains(msg.id)) continue;

        final text = _cleanAssistantText(msg.content);
        if (lastSeen[msg.id] == text) {
          stableTicks[msg.id] = (stableTicks[msg.id] ?? 0) + 1;
        } else {
          lastSeen[msg.id] = text;
          stableTicks[msg.id] = 0;
        }

        final isLast = i == assistants.length - 1;
        final turnFinished = !isLast || !isActive;
        final stable = (stableTicks[msg.id] ?? 0) >= 2;

        if (turnFinished && stable && text.isNotEmpty) {
          _groupActiveMessageId = msg.id;
          unawaited(_readResponse(text, message: msg));
          return;
        }
        // Wait for this persona to finish before considering later ones.
        break;
      }

      if (!isActive &&
          _groupActiveMessageId == null &&
          assistants.every((m) => _groupCompletedIds.contains(m.id))) {
        timer.cancel();
        _responseMonitor = null;
        if (assistants.isEmpty) {
          _awaitingResponse = false;
          setState(() => _state = VoicePanelState.idle);
        } else {
          // All spoken already (edge case) — return to listen loop.
          _onTtsComplete();
        }
      }
    });
  }

  void _monitorSingleResponse() {
    _responseMonitor?.cancel();
    bool streamingTtsStarted = false;
    int previousTtsLength = 0;

    _responseMonitor =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final chatProvider = context.read<ChatProvider>();
      final messages = chatProvider.currentMessages;
      // Use isSendingMessage (set synchronously) OR isLoading to detect active stream
      final isActive = chatProvider.isSendingMessage || chatProvider.isLoading;

      // Find latest assistant message — only consider messages AFTER the
      // send point to avoid replaying previous responses.
      String currentContent = '';
      ChatMessage? latestAssistant;
      for (int i = messages.length - 1; i >= _responseBaseIndex; i--) {
        if (messages[i].role == 'assistant' &&
            !messages[i].content.startsWith('Tool call:') &&
            !messages[i].content.startsWith('MCP call:') &&
            !messages[i].content.startsWith('🔧 MCP call:')) {
          latestAssistant = messages[i];
          currentContent = messages[i].content;
          break;
        }
      }

      // Keep UI conversational — don't surface raw streaming / TTS status text.
      if (currentContent != _lastAssistantContent) {
        _lastAssistantContent = currentContent;
        final parsed = ResponseParser.parse(currentContent);
        final preview = ResponseParser.cleanForTts(parsed.answer);
        if (preview != _assistantPreviewText) {
          setState(() => _assistantPreviewText = preview);
          _scrollTranscriptToEnd();
        }
        if (_state != VoicePanelState.speaking) {
          setState(() => _state = VoicePanelState.responding);
        }
      }

      // Streaming TTS: feed text sentence-by-sentence as it arrives
      final settings = context.read<SettingsProvider>().settings;
      final ttsProvider = TtsEngine.effective(settings.voiceTtsProvider);
      final useStreamingTts =
          (ttsProvider == 'kokoro' && _kokoroTts.isInitialized) ||
              (ttsProvider == 'kokoro_remote' &&
                  _remoteKokoroTts.isInitialized) ||
              (ttsProvider == TtsEngine.elevenLabs &&
                  _elevenLabsTts.isInitialized) ||
              (ttsProvider == TtsEngine.grok &&
                  _grokTts.isInitialized);
      if (useStreamingTts) {
        final isRemote = ttsProvider == 'kokoro_remote';
        final isElevenLabs = ttsProvider == TtsEngine.elevenLabs;
        final isGrok = ttsProvider == TtsEngine.grok;
        final parsed = ResponseParser.parse(currentContent);
        final cleanContent = ResponseParser.cleanForTts(parsed.answer);

        if (cleanContent.length > previousTtsLength) {
          if (!streamingTtsStarted) {
            // Stop "Thinking" audio cue if still playing
            _isPlayingAudioCue = false;
            if (_tts.isSpeaking) _tts.stop();
            final voice = latestAssistant != null
                ? KokoroSpeakerResolver.resolveVoiceForMessage(
                    settings: settings,
                    message: latestAssistant,
                    conversation: chatProvider.currentConversation,
                  )
                : KokoroSpeakerResolver.resolveVoice(settings: settings);
            if (isElevenLabs) {
              final elVoice = latestAssistant != null
                  ? ElevenLabsVoiceResolver.resolveVoiceIdForMessage(
                      settings: settings,
                      message: latestAssistant,
                      conversation: chatProvider.currentConversation,
                    )
                  : ElevenLabsVoiceResolver.resolveVoiceId(settings: settings);
              _elevenLabsTts.setVoiceId(elVoice);
              _elevenLabsTts.setModelId(settings.voiceElevenLabsModelId);
              _elevenLabsTts.setSpeed(voice.speed);
              _elevenLabsTts.onComplete = _onTtsComplete;
              _elevenLabsTts.onError = () {
                if (mounted && _state == VoicePanelState.speaking) {
                  _onTtsComplete();
                }
              };
              _elevenLabsTts.startStreaming();
              _elevenLabsTts.onPlaybackStart = () {
                if (mounted) {
                  setState(() => _statusText = '');
                }
              };
            } else if (isGrok) {
              final grokVoice = latestAssistant != null
                  ? GrokVoiceResolver.resolveVoiceIdForMessage(
                      settings: settings,
                      message: latestAssistant,
                      conversation: chatProvider.currentConversation,
                    )
                  : GrokVoiceResolver.resolveVoiceId(settings: settings);
              _grokTts.setVoiceId(grokVoice);
              _grokTts.setLanguage(settings.locale ?? settings.voiceLanguage);
              _grokTts.setSpeed(voice.speed);
              _grokTts.onComplete = _onTtsComplete;
              _grokTts.onError = () {
                if (mounted && _state == VoicePanelState.speaking) {
                  _onTtsComplete();
                }
              };
              _grokTts.startStreaming();
              _grokTts.onPlaybackStart = () {
                if (mounted) {
                  setState(() => _statusText = '');
                }
              };
            } else if (isRemote) {
              _remoteKokoroTts.setSpeakerId(voice.speakerId);
              _remoteKokoroTts.setSpeed(voice.speed);
              _remoteKokoroTts.onComplete = _onTtsComplete;
              _remoteKokoroTts.onError = () {
                if (mounted && _state == VoicePanelState.speaking) {
                  _onTtsComplete();
                }
              };
              _remoteKokoroTts.startStreaming();
              _remoteKokoroTts.onPlaybackStart = () {
                if (mounted) {
                  setState(() => _statusText = '');
                }
              };
            } else {
              _kokoroTts.setSpeakerId(voice.speakerId);
              _kokoroTts.setSpeed(voice.speed);
              _kokoroTts.onComplete = _onTtsComplete;
              _kokoroTts.onError = () {
                if (mounted && _state == VoicePanelState.speaking) {
                  _onTtsComplete();
                }
              };
              _kokoroTts.startStreaming();
              _kokoroTts.onPlaybackStart = () {
                if (mounted) {
                  setState(() => _statusText = '');
                }
              };
            }
            streamingTtsStarted = true;
            if (mounted) {
              setState(() {
                _state = VoicePanelState.speaking;
                _statusText = '🔊 Preparing audio...';
              });
            }
          }
          final newText = cleanContent.substring(previousTtsLength);
          if (isElevenLabs) {
            _elevenLabsTts.feedText(newText);
          } else if (isGrok) {
            _grokTts.feedText(newText);
          } else if (isRemote) {
            _remoteKokoroTts.feedText(newText);
          } else {
            _kokoroTts.feedText(newText);
          }
          previousTtsLength = cleanContent.length;
        }

        if (!isActive) {
          timer.cancel();
          _responseMonitor = null;
          if (streamingTtsStarted) {
            if (isElevenLabs) {
              _elevenLabsTts.finishStreaming();
            } else if (isGrok) {
              _grokTts.finishStreaming();
            } else if (isRemote) {
              _remoteKokoroTts.finishStreaming();
            } else {
              _kokoroTts.finishStreaming();
            }
            // onComplete callback will handle state transition
          } else if (currentContent.isNotEmpty) {
            // Very short response — not enough to trigger streaming
            final parsed = ResponseParser.parse(currentContent);
            _readResponse(ResponseParser.cleanForTts(parsed.answer),
                message: latestAssistant);
          } else {
            _awaitingResponse = false;
            setState(() => _state = VoicePanelState.idle);
          }
          return;
        }
      } else {
        // Non-Kokoro or Kokoro not initialized: wait for full response
        if (!isActive && currentContent.isNotEmpty) {
          timer.cancel();
          _responseMonitor = null;
          final parsed = ResponseParser.parse(currentContent);
          _readResponse(ResponseParser.cleanForTts(parsed.answer),
              message: latestAssistant);
        }
      }
    });
  }

  /// Play a short beep tone to signal user's turn to speak
  Future<void> _playBeep() async {
    if (_isDesktop) return;
    try {
      _beepPlayer ??= AudioPlayer();
      final wavBytes = _generateBeepWav();
      await _beepPlayer!.setAudioSource(_BeepAudioSource(wavBytes));
      await _beepPlayer!.play();
      await Future.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      debugPrint('Beep playback error: $e');
    }
  }

  /// Generate a short 880Hz sine wave beep as WAV bytes
  static Uint8List _generateBeepWav() {
    const sampleRate = 44100;
    const frequency = 880.0;
    const numSamples = (sampleRate * 0.15) ~/ 1; // 150ms
    const dataSize = numSamples * 2; // 16-bit mono

    final bytes = ByteData(44 + dataSize);

    // RIFF header
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(i, 'RIFF'.codeUnitAt(i));
    }
    bytes.setUint32(4, 36 + dataSize, Endian.little);
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(8 + i, 'WAVE'.codeUnitAt(i));
    }

    // fmt chunk
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(12 + i, 'fmt '.codeUnitAt(i));
    }
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(36 + i, 'data'.codeUnitAt(i));
    }
    bytes.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final fadeIn = (i < numSamples * 0.1) ? i / (numSamples * 0.1) : 1.0;
      final fadeOut =
          (i > numSamples * 0.7) ? (numSamples - i) / (numSamples * 0.3) : 1.0;
      final sample =
          (sin(2 * pi * frequency * t) * 32767 * 0.4 * fadeIn * fadeOut)
              .toInt()
              .clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, sample, Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  Future<void> _readResponse(String text, {ChatMessage? message}) async {
    if (text.trim().isEmpty) {
      _awaitingResponse = false;
      setState(() => _state = VoicePanelState.idle);
      return;
    }
    setState(() => _state = VoicePanelState.speaking);

    // Stop audio cue if still playing
    _isPlayingAudioCue = false;
    if (_tts.isSpeaking) await _tts.stop();

    // Try Kokoro TTS if configured
    if (!mounted) return;
    final settings = context.read<SettingsProvider>().settings;
    final ttsProvider = TtsEngine.effective(settings.voiceTtsProvider);
    final chatProvider = context.read<ChatProvider>();
    ChatMessage? assistant = message;
    if (assistant == null) {
      final messages = chatProvider.currentMessages;
      for (int i = messages.length - 1; i >= _responseBaseIndex; i--) {
        if (messages[i].role == 'assistant') {
          assistant = messages[i];
          break;
        }
      }
    }
    final voice = assistant != null
        ? KokoroSpeakerResolver.resolveVoiceForMessage(
            settings: settings,
            message: assistant,
            conversation: chatProvider.currentConversation,
          )
        : KokoroSpeakerResolver.resolveVoice(settings: settings);
    if (ttsProvider == 'kokoro_remote') {
      _remoteKokoroTts.setSpeakerId(voice.speakerId);
      _remoteKokoroTts.setSpeed(voice.speed);
      _remoteKokoroTts.onComplete = _onTtsComplete;
      _remoteKokoroTts.onError = () {
        if (mounted && _state == VoicePanelState.speaking) {
          _onTtsComplete();
        }
      };
      final success = await _remoteKokoroTts.speak(text);
      if (success) return;
      // Fall through to native TTS if remote Kokoro failed
    } else if (ttsProvider == 'kokoro') {
      _kokoroTts.setSpeakerId(voice.speakerId);
      _kokoroTts.setSpeed(voice.speed);
      _kokoroTts.onComplete = _onTtsComplete;
      _kokoroTts.onError = () {
        if (mounted && _state == VoicePanelState.speaking) {
          _onTtsComplete();
        }
      };
      final success = await _kokoroTts.speak(text);
      if (success) {
        // Kokoro handled it — completion callback will transition state
        return;
      }
      // Fall through to native TTS if Kokoro failed
    } else if (ttsProvider == TtsEngine.elevenLabs) {
      final elVoice = assistant != null
          ? ElevenLabsVoiceResolver.resolveVoiceIdForMessage(
              settings: settings,
              message: assistant,
              conversation: chatProvider.currentConversation,
            )
          : ElevenLabsVoiceResolver.resolveVoiceId(settings: settings);
      _elevenLabsTts.setVoiceId(elVoice);
      _elevenLabsTts.setModelId(settings.voiceElevenLabsModelId);
      _elevenLabsTts.setSpeed(voice.speed);
      _elevenLabsTts.onComplete = _onTtsComplete;
      _elevenLabsTts.onError = () {
        if (mounted && _state == VoicePanelState.speaking) {
          _onTtsComplete();
        }
      };
      final success = await _elevenLabsTts.speak(text);
      if (success) return;
    } else if (ttsProvider == TtsEngine.grok) {
      final grokVoice = assistant != null
          ? GrokVoiceResolver.resolveVoiceIdForMessage(
              settings: settings,
              message: assistant,
              conversation: chatProvider.currentConversation,
            )
          : GrokVoiceResolver.resolveVoiceId(settings: settings);
      _grokTts.setVoiceId(grokVoice);
      _grokTts.setLanguage(settings.locale ?? settings.voiceLanguage);
      _grokTts.setSpeed(voice.speed);
      _grokTts.onComplete = _onTtsComplete;
      _grokTts.onError = () {
        if (mounted && _state == VoicePanelState.speaking) {
          _onTtsComplete();
        }
      };
      final success = await _grokTts.speak(text);
      if (success) return;
    }

    await _tts.speak(text);
    // speak() now awaits completion (awaitSpeakCompletion is true).
    // The onComplete callback should have already fired, but if not,
    // trigger the transition as a safety fallback.
    if (mounted && _state == VoicePanelState.speaking) {
      _onTtsComplete();
    }
  }

  void _stopEverything() {
    if (!mounted) return;
    _cancelPendingListenRestart();
    _responseMonitor?.cancel();
    _responseMonitor = null;
    _awaitingResponse = false;
    _groupActiveMessageId = null;
    _groupCompletedIds.clear();
    _isPlayingAudioCue = false;
    _tts.stop();
    _kokoroTts.stop();
    _remoteKokoroTts.stop();
    _elevenLabsTts.stop();
    _grokTts.stop();
    _stt.stopListening();
    _sttSendLogic.reset();
    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.isLoading) {
      chatProvider.stopGeneration();
    }
    setState(() {
      _state = VoicePanelState.idle;
      _transcribedText = '';
      _assistantPreviewText = '';
      _statusText = '';
    });
  }

  void _onOrbTap() {
    if (!_isInitialized) return;
    switch (_state) {
      case VoicePanelState.idle:
        _startListening();
        break;
      case VoicePanelState.listening:
        _pauseListeningForReview();
        break;
      case VoicePanelState.review:
        _startListening(preserveBuffer: true);
        break;
      case VoicePanelState.speaking:
        _tts.stop();
        _kokoroTts.stop();
        _remoteKokoroTts.stop();
        _elevenLabsTts.stop();
        _grokTts.stop();
        setState(() => _state = VoicePanelState.idle);
        break;
      case VoicePanelState.thinking:
      case VoicePanelState.responding:
        _stopEverything();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isListening = _state == VoicePanelState.listening;
    final isReview = _state == VoicePanelState.review;
    final micLive = isListening && (_sttMicActive || _listenInProgress);
    final isSpeaking = _state == VoicePanelState.speaking;
    final isProcessing = _state == VoicePanelState.thinking ||
        _state == VoicePanelState.responding;
    final accent = voiceConversationAccent(
      colorScheme,
      listening: isListening || isReview,
      processing: isProcessing,
      speaking: isSpeaking,
    );
    final hint = isReview
        ? l10n.voiceConvoHintIdle
        : voiceConversationHint(
            l10n,
            idle: _state == VoicePanelState.idle,
            listening: isListening,
            processing: isProcessing,
            speaking: isSpeaking,
            micWarmingUp: isListening && !_sttMicActive,
          );

    final showUserText =
        (isListening || isReview) && _transcribedText.trim().isNotEmpty;
    final showAssistantText =
        isProcessing || isSpeaking || _assistantPreviewText.isNotEmpty;

    final isDark = theme.brightness == Brightness.dark;
    final useLegacyComposer =
        context.watch<SettingsProvider>().settings.useLegacyComposer;
    final shineColor = isDark ? const Color(0xFF9B87F5) : colorScheme.primary;

    Widget panel = Container(
      decoration: voiceConversationDecoration(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              VoiceTranscriptViewport(
                scrollController: _transcriptScrollController,
                userText: showUserText ? _transcribedText : null,
                assistantText: showAssistantText ? _assistantPreviewText : null,
                visibleLines: 4,
                showUserLiveIndicator: micLive,
              ),
              const SizedBox(height: 8),
              VoiceConversationOrb(
                animation: _pulseAnimation,
                waveAnimation: _waveController,
                size: 112,
                soundLevel: _soundLevel,
                isListening: micLive,
                isSpeaking: isSpeaking,
                isProcessing: isProcessing || (isListening && !micLive),
                baseColor: accent,
                onTap: _onOrbTap,
                onLongPress: () {
                  if (_state != VoicePanelState.idle) _stopEverything();
                },
              ),
              if (hint.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      _stopEverything();
                      widget.onClose();
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.voiceExitMode,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withOpacity(0.8),
                    ),
                  ),
                  if (_state == VoicePanelState.listening)
                    FilledButton.tonalIcon(
                      onPressed: _pauseListeningForReview,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: Text(l10n.voiceStopRecording),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.error,
                      ),
                    )
                  else if (_state == VoicePanelState.review)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _discardReview,
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: Text(l10n.voiceDiscardRecording),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => _sendTranscribedMessage(),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(l10n.sendLabel),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.error,
                          ),
                        ),
                      ],
                    )
                  else if (_state != VoicePanelState.idle)
                    FilledButton.tonalIcon(
                      onPressed: _stopEverything,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: Text(l10n.voiceStopRecording),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.error,
                      ),
                    )
                  else
                    const SizedBox(width: 96),
                  if (!_isDesktop && CallService.isOffered)
                    Consumer<SettingsProvider>(
                      builder: (context, sp, _) {
                        final isCallActive = sp.settings.voiceCallMode;
                        return IconButton(
                          onPressed: () => _toggleCallMode(sp),
                          icon: Icon(
                            isCallActive
                                ? Icons.phone_in_talk_rounded
                                : Icons.phone_outlined,
                            color: isCallActive ? Colors.white : null,
                          ),
                          tooltip: isCallActive ? 'End call' : 'Start call',
                          style: IconButton.styleFrom(
                            backgroundColor: isCallActive
                                ? Colors.red.shade600
                                : colorScheme.surfaceContainerHighest
                                    .withOpacity(0.8),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!useLegacyComposer) {
      panel = CustomPaint(
        foregroundPainter: ComposerShineBorder(
          color: shineColor,
          radius: 24,
          fadeEnd: 0.45,
        ),
        child: panel,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: GlassBlur(
        sigmaX: isDark ? 28 : 32,
        sigmaY: isDark ? 28 : 32,
        child: panel,
      ),
    );
  }
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
    return _AnimatedBuilderInner(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class _AnimatedBuilderInner extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimatedBuilderInner({
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

/// Audio source for playing generated beep WAV bytes via just_audio
class _BeepAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  _BeepAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
