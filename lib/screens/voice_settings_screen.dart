import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../desktop/desktop_platform.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../services/feature_request_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/mac_system_stt_service.dart';
import '../services/kokoro_tts_service.dart';
import '../services/remote_kokoro_tts_service.dart';
import '../services/elevenlabs_tts_service.dart';
import '../services/grok_tts_service.dart';
// Used by the Pro part only; unused with the open-source stub part.
// ignore: unused_import
import '../models/elevenlabs_voice.dart';
// ignore: unused_import
import '../models/grok_voice.dart';
import '../utils/tts_engine.dart';
import '../pro/pro_features.dart';
import '../services/kokoro_model_manager.dart';
import '../services/whisper_model_manager.dart';
import '../services/whisper_stt_service.dart';
import '../services/macos_media_permissions.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import '../pro/admin/admin_voice_import_screen.dart';
import 'subscription_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/locale_display_names.dart';
import '../utils/tts_language_catalog.dart';
import '../utils/tts_voice_display.dart';
import '../utils/layout_utils.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_page_header.dart';
import '../widgets/glass_settings_scaffold.dart';

// Cloud TTS (ElevenLabs / Grok) settings: LM Mini Pro, stubbed in the public export.
part '../pro/tts/voice_settings_cloud_tts.dart';

/// Settings screen for voice mode (TTS & STT configuration)
class VoiceSettingsScreen extends StatefulWidget {
  final bool embedded;
  const VoiceSettingsScreen({super.key, this.embedded = false});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();
  final KokoroTtsService _kokoroTts = KokoroTtsService();
  final RemoteKokoroTtsService _remoteKokoroTts = RemoteKokoroTtsService();
  // ignore: unused_field
  final ElevenLabsTtsService _elevenLabsTts = ElevenLabsTtsService();
  // ignore: unused_field
  final GrokTtsService _grokTts = GrokTtsService();
  final KokoroModelManager _modelManager = KokoroModelManager();
  final WhisperModelManager _whisperModelManager = WhisperModelManager.instance;

  bool _ttsReady = false;
  bool _sttAvailable = false;
  bool _whisperModelReady = false;
  bool _whisperDownloading = false;
  double _whisperDownloadProgress = 0;
  String? _whisperError;
  bool _kokoroModelReady = false;
  final Map<String, bool> _kokoroReadyByLang = {};
  bool _kokoroDownloading = false;
  String? _kokoroDownloadingLang;
  double _kokoroDownloadProgress = 0;
  String? _kokoroError;
  bool _voiceTestRunning = false;
  String _voiceTestPhase = '';
  double? _voiceTestProgress;
  bool _voiceTestIndeterminate = false;
  bool _remoteKokoroConnected = false;
  bool _remoteKokoroChecking = false;
  // ignore: unused_field
  bool _elevenLabsReady = false;
  // ignore: unused_field
  bool _elevenLabsChecking = false;
  // ignore: unused_field
  bool _grokReady = false;
  // ignore: unused_field
  bool _grokChecking = false;
  bool _canImportVoicePacks = false;

  /// True when the native macOS SFSpeechRecognizer bridge is usable (installed
  /// build). When it is, "System (macOS Speech)" is offered even on sandboxed
  /// Mac builds because the native path is crash-safe.
  bool _macNativeSpeech = false;
  StreamSubscription<double>? _progressSub;
  StreamSubscription<double>? _whisperProgressSub;

  /// Whether listening must use Whisper on this platform. Native macOS speech
  /// (when available) lifts the sandboxed-Mac Whisper-only restriction.
  bool get _whisperOnly =>
      DesktopPlatform.macListeningRequiresWhisper && !_macNativeSpeech;

  /// setState for the Pro part's extension (setState is protected).
  // ignore: unused_element
  void _setStateFromPart(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadVoiceImportAccess();
  }

  Future<void> _loadVoiceImportAccess() async {
    // The voice-pack import tool ships only in the official app.
    if (!ProFeatures.included) return;
    try {
      final can = await FeatureRequestService().isModerator;
      if (mounted) setState(() => _canImportVoicePacks = can);
    } catch (e) {
      debugPrint('⚠️ Voice import access: $e');
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _whisperProgressSub?.cancel();
    super.dispose();
  }

  Future<void> _initServices() async {
    try {
      await _tts.initialize();
      if (!mounted) return;
      final settingsProvider = context.read<SettingsProvider>();
      // Resolve native macOS speech availability first: an installed .app can
      // use Apple's on-device recognizer safely even when sandboxed, which
      // lifts the Whisper-only restriction. Dev/IDE launches report false.
      _macNativeSpeech = await MacSystemSttService.instance.isAvailable();
      if (!mounted) return;
      // Sandboxed Mac without native speech: system STT can hard-crash — force
      // Whisper. Unsandboxed / native-capable builds keep built-in recognition.
      final whisperOnly = _whisperOnly;
      if (whisperOnly &&
          settingsProvider.settings.voiceSttProvider == 'system') {
        settingsProvider.updateVoiceSttProvider('whisper');
      }
      final settings = settingsProvider.settings;
      var sttOk = false;
      try {
        sttOk = await _stt.initialize(
          sttProvider: settings.voiceSttProvider,
          localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
        );
      } catch (e, st) {
        debugPrint('🎙️ Voice settings STT init failed: $e\n$st');
      }
      if (!mounted) return;
      setState(() {
        _ttsReady = _tts.isInitialized;
        _sttAvailable = sttOk;
      });
      await _tts.setSpeechRate(settings.voiceSpeechRate);
      await _tts.setPitch(settings.voicePitch);
      await _tts.setLanguage(settings.voiceLanguage);
      if (settings.voiceName != null) {
        await _tts.setVoice(settings.voiceName);
      }
      await _checkKokoroModel();
      await _checkWhisperModel();
      await _proCheckCloudTts(settings.voiceTtsProvider);
      if (!mounted) return;
      if (whisperOnly &&
          settingsProvider.settings.voiceSttProvider == 'whisper' &&
          !_whisperModelReady &&
          !_whisperDownloading) {
        _promptWhisperDownloadIfNeeded();
      }
    } catch (e, st) {
      debugPrint('🎙️ Voice settings init failed: $e\n$st');
      if (mounted) {
        setState(() {
          _ttsReady = _tts.isInitialized;
          _sttAvailable = false;
        });
      }
    }
  }

  /// Nudge sandboxed-Mac users to download Whisper instead of a dead-end status.
  void _promptWhisperDownloadIfNeeded() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.voiceSttMacosDownloadWhisper),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.download,
          onPressed: () => _downloadWhisperModel(),
        ),
      ),
    );
  }

  Future<void> _checkKokoroModel() async {
    // Clear any previous error before we try again.
    if (mounted) setState(() => _kokoroError = null);

    Map<String, bool> readyMap;
    try {
      readyMap = await _modelManager.languageReadyMap();
    } catch (e, st) {
      debugPrint('🔊 KokoroModel readyMap failed: $e\n$st');
      if (mounted) {
        setState(() => _kokoroError = e.toString());
        _showKokoroErrorDialog(e, st, phase: 'model-scan');
      }
      return;
    }

    final ready = readyMap.values.any((v) => v);
    if (mounted) {
      setState(() {
        _kokoroReadyByLang
          ..clear()
          ..addAll(readyMap);
        _kokoroModelReady = ready;
        _kokoroDownloading = _modelManager.isDownloading;
      });
    }
    if (!ready) return; // No model downloaded yet.
    if (!mounted) return;

    // Do not load sherpa-onnx here. Opening this screen used to spawn the
    // native TTS worker and SIGABRT the iOS Simulator.
    final settings = context.read<SettingsProvider>().settings;
    final lang = _readyOnDeviceSpeakLanguage(settings);
    if (lang != null) _kokoroTts.setPreferredLanguage(lang);
    _kokoroTts.setSpeakerId(settings.voiceKokoroSpeakerId);
    _kokoroTts.setSpeed(settings.voiceKokoroSpeed);
  }

  /// Downloaded TTS pack to use for Test Voice / init (not UI locale, not STT).
  String? _readyOnDeviceSpeakLanguage(AppSettings settings) {
    final readyIds = {
      for (final e in _kokoroReadyByLang.entries)
        if (e.value) e.key,
    };
    return TtsLanguageCatalog.pickReadyLanguage(
      preferred: settings.voiceLanguage,
      detected: settings.locale,
      readyIds: readyIds,
    );
  }

  /// Shows a diagnostic dialog when Kokoro TTS crashes or fails to initialise.
  /// Gives the user the error details so they can report them, and a quick
  /// escape-hatch to switch back to native TTS so the app stays usable.
  void _showKokoroErrorDialog(
    Object error,
    StackTrace stackTrace, {
    required String phase,
    String? lang,
    Map<String, bool>? readyMap,
  }) {
    if (!mounted) return;

    // Build a diagnostic block that is useful for bug reports.
    final sb = StringBuffer();
    sb.writeln('── Diagnostic info ──');
    sb.writeln('Phase : $phase');
    if (lang != null) sb.writeln('Lang  : $lang');
    if (readyMap != null) {
      final packs =
          readyMap.entries.where((e) => e.value).map((e) => e.key).join(', ');
      sb.writeln('Packs : ${packs.isEmpty ? '(none)' : packs}');
    }
    sb.writeln('Error : $error');
    sb.writeln();
    sb.writeln('── Stack trace ──');
    // Trim to first 20 frames so the dialog isn't overwhelming.
    final frames = stackTrace.toString().split('\n');
    sb.writeAll(frames.take(20), '\n');
    if (frames.length > 20) sb.writeln('\n… (${frames.length - 20} more)');
    final diagnostics = sb.toString();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Kokoro TTS Error')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kokoro (on-device neural TTS) failed to start. '
                  'You can switch to a different voice engine below.\n\n'
                  'If you want to report this issue, please copy the '
                  'diagnostic info and send it to support.',
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: SelectableText(
                      diagnostics,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Switch to Native TTS'),
              onPressed: () {
                Navigator.pop(ctx);
                final sp = context.read<SettingsProvider>();
                sp.updateVoiceTtsProvider('native');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Switched to native TTS'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkRemoteKokoro() async {
    final settings = context.read<SettingsProvider>().settings;
    final serverUrl = settings.effectiveVoiceRemoteKokoroUrl;
    final authToken = settings.voiceRemoteKokoroHeaders?['X-LM-Mini-Token'];

    setState(() => _remoteKokoroChecking = true);

    final ok = await _remoteKokoroTts.testConnection(
      serverUrl,
      authToken: authToken,
    );

    if (mounted) {
      setState(() {
        _remoteKokoroConnected = ok;
        _remoteKokoroChecking = false;
      });
    }

    if (ok) {
      await _remoteKokoroTts.initialize(
        serverUrl: serverUrl,
        authToken: authToken,
        language: settings.voiceLanguage,
      );
      _remoteKokoroTts.setSpeakerId(settings.voiceKokoroSpeakerId);
      _remoteKokoroTts.setSpeed(settings.voiceKokoroSpeed);
    }
  }

  Future<void> _downloadKokoroLanguage(String langId) async {
    setState(() {
      _kokoroDownloading = true;
      _kokoroDownloadingLang = langId;
      _kokoroDownloadProgress = 0;
      _kokoroError = null;
    });

    _progressSub?.cancel();
    _progressSub = _modelManager.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _kokoroDownloadProgress = progress);
      }
    });

    final success = await _modelManager.downloadLanguage(langId);

    _progressSub?.cancel();

    final readyMap = await _modelManager.languageReadyMap();
    if (mounted) {
      setState(() {
        _kokoroDownloading = false;
        _kokoroDownloadingLang = null;
        _kokoroReadyByLang
          ..clear()
          ..addAll(readyMap);
        _kokoroModelReady = readyMap.values.any((v) => v);
        _kokoroError = success ? null : _modelManager.error;
      });
    }

    if (success) {
      _kokoroTts.setPreferredLanguage(langId);
    }
  }

  Future<void> _deleteKokoroLanguage(String langId) async {
    final lang = TtsLanguageCatalog.byId(langId);
    final l10n = AppLocalizations.of(context);
    final shared = lang?.sharesKokoroPack == true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.voiceKokoroDeleteTitle),
        content: Text(
          shared
              ? l10n.voiceTtsSharedPackDeleteMessage
              : l10n.voiceKokoroDeleteMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.voiceKokoroDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _modelManager.deleteLanguage(langId);
    final readyMap = await _modelManager.languageReadyMap();
    final anyReady = readyMap.values.any((v) => v);
    if (!anyReady) {
      await _kokoroTts.dispose();
    }
    if (!mounted) return;
    setState(() {
      _kokoroReadyByLang
        ..clear()
        ..addAll(readyMap);
      _kokoroModelReady = anyReady;
    });
  }

  Future<void> _deleteKokoroModel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).voiceKokoroDeleteTitle),
        content: Text(AppLocalizations.of(context).voiceKokoroDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).voiceKokoroDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _kokoroTts.dispose();
      await _modelManager.deleteModel();
      if (mounted) {
        setState(() {
          _kokoroModelReady = false;
          _kokoroReadyByLang.clear();
        });
        // Switch back to native if Kokoro was selected
        final settingsProvider = context.read<SettingsProvider>();
        if (settingsProvider.settings.voiceTtsProvider == 'kokoro') {
          settingsProvider.updateVoiceTtsProvider('native');
        }
      }
    }
  }

  Map<String, bool> _whisperReadyById = {};

  Future<void> _checkWhisperModel() async {
    final settingsProvider = context.read<SettingsProvider>();
    final selected = settingsProvider.settings.whisperModelId;
    _whisperModelManager.setSelectedModelId(selected);
    final readyMap = <String, bool>{};
    for (final spec in WhisperModelManager.catalog) {
      readyMap[spec.id] = await _whisperModelManager.isModelReady(spec.id);
    }
    if (mounted) {
      setState(() {
        _whisperReadyById = readyMap;
        _whisperModelReady = readyMap[selected] ?? false;
        _whisperDownloading = _whisperModelManager.isDownloading;
      });
    }
  }

  /// Re-init TTS when the Speaking status chip is tapped.
  Future<void> _retrySpeakingStatus() async {
    final l10n = AppLocalizations.of(context);
    try {
      await _tts.initialize();
      if (!mounted) return;
      final settings = context.read<SettingsProvider>().settings;
      await _tts.setSpeechRate(settings.voiceSpeechRate);
      await _tts.setPitch(settings.voicePitch);
      await _tts.setLanguage(settings.voiceLanguage);
      if (settings.voiceName != null) {
        await _tts.setVoice(settings.voiceName);
      }
      if (settings.voiceTtsProvider == TtsEngine.kokoro) {
        await _checkKokoroModel();
      } else {
        await _proCheckCloudTts(settings.voiceTtsProvider);
      }
      if (!mounted) return;
      setState(() => _ttsReady = _tts.isInitialized);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ttsReady ? l10n.voiceAvailable : l10n.voiceUnavailable,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _ttsReady = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.voiceUnavailable}: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Ask for mic (again) and re-check Whisper / system STT readiness.
  Future<void> _retryListeningStatus() async {
    final l10n = AppLocalizations.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;

    // permission_handler is reliable on iOS/Android. On macOS we use the
    // native TCC channel so Microphone + Speech Recognition purpose strings
    // actually appear (App Store Review 2.1).
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS)) {
      try {
        final micOk = await VoiceCapturePermissions.ensureForVoiceInput();
        if (!micOk) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Platform.isMacOS
                    ? 'Microphone access was not granted. Allow it when prompted, or enable it in System Settings → Privacy & Security → Microphone.'
                    : 'Microphone permission is required for listening.',
              ),
              behavior: SnackBarBehavior.floating,
              action: Platform.isIOS || Platform.isAndroid
                  ? SnackBarAction(
                      label: l10n.openAppSettings,
                      onPressed: openAppSettings,
                    )
                  : null,
            ),
          );
        }
      } on MissingPluginException {
        debugPrint(
            '🎙️ permission_handler unavailable — skipping mic preflight');
      } catch (e) {
        debugPrint('🎙️ Mic permission check failed: $e');
      }
    }

    // On sandboxed Mac without native speech, built-in STT is unavailable —
    // treat as Whisper path.
    final effectiveProvider =
        _whisperOnly && settings.voiceSttProvider == 'system'
            ? 'whisper'
            : settings.voiceSttProvider;
    if (_whisperOnly && settings.voiceSttProvider == 'system') {
      settingsProvider.updateVoiceSttProvider('whisper');
    }

    if (effectiveProvider == 'whisper') {
      await _checkWhisperModel();
      if (!_whisperModelReady) {
        if (!mounted) return;
        if (_whisperDownloading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.voiceDownloadingListeningModel),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _whisperOnly
                  ? l10n.voiceSttMacosDownloadWhisper
                  : l10n.voiceNeedsDownload,
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.download,
              onPressed: () => _downloadWhisperModel(),
            ),
          ),
        );
        await _downloadWhisperModel();
      }
    }

    if (!mounted) return;
    var sttOk = false;
    try {
      sttOk = await _stt.initialize(
        sttProvider: effectiveProvider,
        localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
      );
    } catch (e, st) {
      debugPrint('🎙️ Listening retry failed: $e\n$st');
    }
    if (effectiveProvider == 'whisper') {
      await _checkWhisperModel();
    }
    if (!mounted) return;
    setState(() => _sttAvailable = sttOk);

    final ready = effectiveProvider == 'whisper' ? _whisperModelReady : sttOk;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ready
              ? '${l10n.voiceStatusListening}: ${l10n.voiceAvailable}'
              : '${l10n.voiceStatusListening}: ${l10n.voiceUnavailable}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadWhisperModel([String? modelId]) async {
    if (!mounted) return;
    final id =
        modelId ?? context.read<SettingsProvider>().settings.whisperModelId;
    await context.read<SettingsProvider>().updateWhisperModelId(id);

    if (!mounted) return;
    setState(() {
      _whisperDownloading = true;
      _whisperDownloadProgress = 0;
      _whisperError = null;
    });

    _whisperProgressSub?.cancel();
    _whisperProgressSub =
        _whisperModelManager.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _whisperDownloadProgress = progress);
      }
    });

    final success = await _whisperModelManager.downloadModel(id);
    await _whisperModelManager.ensureVadModel();
    _whisperProgressSub?.cancel();

    if (!mounted) return;
    setState(() {
      _whisperDownloading = false;
      _whisperError = success ? null : _whisperModelManager.error;
    });
    await _checkWhisperModel();

    if (!mounted || !success) return;
    final settings = context.read<SettingsProvider>().settings;
    await _stt.initialize(
      sttProvider: 'whisper',
      localeId: settings.voiceSttLanguage.replaceAll('-', '_'),
    );
  }

  Future<void> _selectWhisperModel(String modelId) async {
    if (!mounted) return;
    await context.read<SettingsProvider>().updateWhisperModelId(modelId);
    if (!mounted) return;
    await _checkWhisperModel();
  }

  void _showWhisperSizeInfo() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          l10n.voiceWhisperSizeInfoTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.voiceWhisperSizeInfoBody,
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWhisperModel() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          l10n.voiceRemoveListeningModelTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.voiceRemoveListeningModelBody,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.voiceWhisperDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await WhisperSttService.instance.resetEngine();
      final selected = context.read<SettingsProvider>().settings.whisperModelId;
      await _whisperModelManager.deleteModel(selected);
      if (mounted) {
        await _checkWhisperModel();
        final settingsProvider = context.read<SettingsProvider>();
        final anyReady = _whisperReadyById.values.any((v) => v);
        if (!anyReady &&
            settingsProvider.settings.voiceSttProvider == 'whisper') {
          settingsProvider.updateVoiceSttProvider('system');
        }
      }
    }
  }

  String _ttsProviderLabel(AppLocalizations l10n, String provider) {
    switch (provider) {
      case TtsEngine.kokoro:
        return l10n.voiceTtsOnDeviceNeural;
      case TtsEngine.kokoroRemote:
        return l10n.voiceTtsPcVoice;
      case TtsEngine.elevenLabs:
        return l10n.voiceTtsElevenLabs;
      case TtsEngine.grok:
        return l10n.voiceTtsGrok;
      default:
        return l10n.voiceTtsSystemVoice;
    }
  }

  String _ttsProviderHint(AppLocalizations l10n, String provider) {
    switch (provider) {
      case TtsEngine.kokoro:
        return l10n.voiceTtsOnDeviceHint;
      case TtsEngine.kokoroRemote:
        return l10n.voiceTtsPcHint;
      case TtsEngine.elevenLabs:
        return l10n.voiceTtsElevenLabsHint;
      case TtsEngine.grok:
        return l10n.voiceTtsGrokHint;
      default:
        return l10n.voiceTtsSystemHint;
    }
  }

  String _sttProviderLabel(AppLocalizations l10n, String provider) {
    return provider == 'whisper' ? 'Whisper' : l10n.voiceSttOnDevice;
  }

  String _sttProviderHint(AppLocalizations l10n, String provider) {
    if (provider == 'whisper') return l10n.voiceSttWhisperHint;
    if (_whisperOnly) {
      return l10n.voiceSttMacosDownloadWhisper;
    }
    return l10n.voiceSttSystemHint;
  }

  String _listeningStatusValue(AppLocalizations l10n, AppSettings settings) {
    final whisperOnly = _whisperOnly;
    final provider = whisperOnly && settings.voiceSttProvider == 'system'
        ? 'whisper'
        : settings.voiceSttProvider;
    final listeningReady =
        provider == 'whisper' ? _whisperModelReady : _sttAvailable;
    if (listeningReady) {
      return _sttProviderLabel(l10n, provider);
    }
    if (provider == 'whisper' && !_whisperModelReady) {
      return l10n.voiceNeedsDownload;
    }
    return l10n.voiceUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topBg = isDark ? const Color(0xFF1A202E) : const Color(0xFF243044);
    final headerH = GlassPageHeader.heightFor(context);

    final content = Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final settings = settingsProvider.settings;
        final whisperOnly = _whisperOnly;
        final listeningProvider =
            whisperOnly && settings.voiceSttProvider == 'system'
                ? 'whisper'
                : settings.voiceSttProvider;
        final listeningReady =
            listeningProvider == 'whisper' ? _whisperModelReady : _sttAvailable;
        final desktop = prefersWideSettingsLayout(context);
        return DesktopSettingsForm(
          maxWidth: desktop ? 720 : double.infinity,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              desktop ? 0 : 16,
              desktop ? 12 : 20,
              desktop ? 0 : 16,
              36,
            ),
            children: [
              Text(
                l10n.voiceSettingsIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Ready status
              _sectionLabel(context, l10n.voiceSectionReady),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusChip(
                      theme: theme,
                      icon: Icons.graphic_eq_rounded,
                      label: l10n.voiceStatusSpeaking,
                      value: _ttsReady
                          ? l10n.voiceAvailable
                          : l10n.voiceUnavailable,
                      ok: _ttsReady,
                      onTap: _retrySpeakingStatus,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusChip(
                      theme: theme,
                      icon: Icons.mic_none_rounded,
                      label: l10n.voiceStatusListening,
                      value: _listeningStatusValue(l10n, settings),
                      ok: listeningReady,
                      onTap: _retryListeningStatus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Speaking (TTS)
              _sectionLabel(context, l10n.voiceSectionSpeaking),
              const SizedBox(height: 10),
              _card(
                context,
                child: Column(
                  children: [
                    _toggleRow(
                      context,
                      icon: Icons.auto_stories_rounded,
                      title: l10n.voiceAutoRead,
                      subtitle: l10n.voiceAutoReadSubtitle,
                      value: settings.voiceAutoRead,
                      onChanged: settingsProvider.updateVoiceAutoRead,
                    ),
                    _divider(context),
                    _navRow(
                      context,
                      icon: Icons.speaker_group_rounded,
                      title: l10n.voiceHowISpeak,
                      subtitle:
                          '${_ttsProviderLabel(l10n, settings.voiceTtsProvider)}\n${_ttsProviderHint(l10n, settings.voiceTtsProvider)}',
                      onTap: () =>
                          _showTtsProviderPicker(context, settingsProvider),
                    ),
                    if (_canImportVoicePacks) ...[
                      _divider(context),
                      _navRow(
                        context,
                        icon: Icons.admin_panel_settings_rounded,
                        title: l10n.voiceImportPack,
                        subtitle: l10n.voiceImportPackSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminVoiceImportScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    if (settings.voiceTtsProvider == TtsEngine.kokoro) ...[
                      _divider(context),
                      _navRow(
                        context,
                        icon: Icons.language_rounded,
                        title: l10n.voiceTtsLanguagePacks,
                        subtitle: _kokoroPacksSubtitle(l10n),
                        onTap: () => _showKokoroPacksSheet(l10n, theme),
                      ),
                      if (_kokoroDownloading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LinearProgressIndicator(
                                value: _kokoroDownloadProgress > 0
                                    ? _kokoroDownloadProgress
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      if (_kokoroHasVoices) ...[
                        _divider(context),
                        _navRow(
                          context,
                          icon: Icons.record_voice_over_rounded,
                          title: l10n.voiceKokoroVoice,
                          subtitle: _kokoroSpeakerDisplayName(
                              settings.voiceKokoroSpeakerId),
                          onTap: () => _showKokoroSpeakerPicker(
                              context, settingsProvider),
                        ),
                      ],
                    ],
                    if (settings.voiceTtsProvider == 'kokoro_remote') ...[
                      _divider(context),
                      _remoteKokoroStatusRow(context, l10n),
                      _hintRow(context, l10n.voiceKokoroFallback),
                      _divider(context),
                      _navRow(
                        context,
                        icon: Icons.record_voice_over_rounded,
                        title: l10n.voiceKokoroVoice,
                        subtitle: _kokoroSpeakerDisplayName(
                            settings.voiceKokoroSpeakerId),
                        onTap: () =>
                            _showKokoroSpeakerPicker(context, settingsProvider),
                      ),
                    ],
                    ..._proCloudTtsSettingsRows(
                        context, settings, settingsProvider, l10n),
                    if (settings.voiceTtsProvider == 'native') ...[
                      _divider(context),
                      _navRow(
                        context,
                        icon: Icons.language_rounded,
                        title: l10n.voiceLanguage,
                        subtitle:
                            '${LocaleDisplayNames.displayName(settings.voiceLanguage)}\n${l10n.voiceLanguageSubtitle}',
                        onTap: () =>
                            _showLanguagePicker(context, settingsProvider),
                      ),
                      _divider(context),
                      _navRow(
                        context,
                        icon: Icons.record_voice_over_rounded,
                        title: l10n.voiceSelection,
                        subtitle: settings.voiceName != null
                            ? _formatVoiceName(settings.voiceName!)
                            : l10n.voiceDefault,
                        onTap: () =>
                            _showVoicePicker(context, settingsProvider),
                      ),
                    ],
                    _divider(context),
                    _buildTestVoiceTile(l10n, theme, settings),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Listening (STT)
              _sectionLabel(context, l10n.voiceSectionListening),
              const SizedBox(height: 10),
              _card(
                context,
                child: Column(
                  children: [
                    _navRow(
                      context,
                      icon: Icons.translate_rounded,
                      title: l10n.voiceSttLanguage,
                      subtitle:
                          '${LocaleDisplayNames.displayName(settings.voiceSttLanguage)}\n${l10n.voiceSttLanguageSubtitle}',
                      onTap: () =>
                          _showSttLanguagePicker(context, settingsProvider),
                    ),
                    _divider(context),
                    _navRow(
                      context,
                      icon: Icons.hearing_rounded,
                      title: l10n.voiceHowIHearYou,
                      subtitle:
                          '${_sttProviderLabel(l10n, listeningProvider)}\n${_sttProviderHint(l10n, listeningProvider)}',
                      onTap: () =>
                          _showSttProviderPicker(context, settingsProvider),
                    ),
                    if (listeningProvider == 'whisper') ...[
                      _divider(context),
                      _navRow(
                        context,
                        icon: Icons.model_training_outlined,
                        title: l10n.voiceListeningModel,
                        subtitle: _whisperModelSubtitle(l10n, settings),
                        onTap: () =>
                            _showWhisperModelSheet(l10n, theme, settings),
                        trailing: IconButton(
                          tooltip: l10n.voiceAboutModelSizes,
                          icon: const Icon(Icons.info_outline_rounded),
                          onPressed: _showWhisperSizeInfo,
                        ),
                      ),
                      if (_whisperDownloading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l10n.voiceWhisperDownloading),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: _whisperDownloadProgress > 0
                                    ? _whisperDownloadProgress
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      _hintRow(context, l10n.voiceWhisperFallback),
                    ],
                    _divider(context),
                    _toggleRow(
                      context,
                      icon: Icons.send_rounded,
                      title: l10n.voiceAutoSend,
                      subtitle: l10n.voiceAutoSendSubtitle,
                      value: settings.voiceAutoSend,
                      onChanged: settingsProvider.updateVoiceAutoSend,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Conversation
              _sectionLabel(context, l10n.voiceSectionConversation),
              const SizedBox(height: 10),
              _card(
                context,
                child: _toggleRow(
                  context,
                  icon: Icons.loop_rounded,
                  title: l10n.voiceContinuousConversation,
                  subtitle: l10n.voiceContinuousConversationSubtitle,
                  value: settings.voiceContinuousConversation,
                  onChanged: settingsProvider.updateVoiceContinuousConversation,
                ),
              ),
              if (settingsProvider.isAdvancedSettings) ...[
                const SizedBox(height: 22),
                _sectionLabel(context, 'Advanced options'),
                const SizedBox(height: 10),
                _card(
                  context,
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: _softIcon(context, Icons.tune_rounded),
                      title: const Text(
                        'Speed, timing & models',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Optional fine-tuning — defaults work for most people',
                      ),
                      children: [
                        if (settings.voiceTtsProvider == 'kokoro' &&
                            _kokoroModelReady) ...[
                          _sliderRow(
                            context,
                            icon: Icons.speed_rounded,
                            title: l10n.voiceKokoroSpeed,
                            valueLabel:
                                '${settings.voiceKokoroSpeed.toStringAsFixed(1)}x',
                            value: settings.voiceKokoroSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            onChanged: (value) {
                              settingsProvider.updateVoiceKokoroSpeed(value);
                              _kokoroTts.setSpeed(value);
                            },
                          ),
                          _divider(context),
                          _dangerRow(
                            context,
                            title: l10n.voiceKokoroDeleteModel,
                            onTap: _deleteKokoroModel,
                          ),
                          _divider(context),
                        ],
                        if (settings.voiceTtsProvider == 'kokoro_remote') ...[
                          _sliderRow(
                            context,
                            icon: Icons.speed_rounded,
                            title: l10n.voiceKokoroSpeed,
                            valueLabel:
                                '${settings.voiceKokoroSpeed.toStringAsFixed(1)}x',
                            value: settings.voiceKokoroSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            onChanged: (value) {
                              settingsProvider.updateVoiceKokoroSpeed(value);
                              _remoteKokoroTts.setSpeed(value);
                            },
                          ),
                          _divider(context),
                        ],
                        if (settings.voiceTtsProvider == TtsEngine.elevenLabs ||
                            settings.voiceTtsProvider == TtsEngine.grok) ...[
                          _sliderRow(
                            context,
                            icon: Icons.speed_rounded,
                            title: l10n.voiceKokoroSpeed,
                            valueLabel:
                                '${settings.voiceKokoroSpeed.toStringAsFixed(1)}x',
                            value: settings.voiceKokoroSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            onChanged: (value) {
                              settingsProvider.updateVoiceKokoroSpeed(value);
                              _proCloudTtsSetSpeed(value);
                            },
                          ),
                          _divider(context),
                        ],
                        if (settings.voiceTtsProvider == 'native') ...[
                          _sliderRow(
                            context,
                            icon: Icons.speed_rounded,
                            title: l10n.voiceSpeechRate,
                            valueLabel:
                                '${(settings.voiceSpeechRate * 100).round()}%',
                            value: settings.voiceSpeechRate,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            onChanged: (value) {
                              settingsProvider.updateVoiceSpeechRate(value);
                              _tts.setSpeechRate(value);
                            },
                          ),
                          _divider(context),
                          _sliderRow(
                            context,
                            icon: Icons.tune_rounded,
                            title: l10n.voicePitch,
                            valueLabel: settings.voicePitch.toStringAsFixed(1),
                            value: settings.voicePitch,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            onChanged: (value) {
                              settingsProvider.updateVoicePitch(value);
                              _tts.setPitch(value);
                            },
                          ),
                          _divider(context),
                        ],
                        _sliderRow(
                          context,
                          icon: Icons.hourglass_bottom_rounded,
                          title: l10n.voicePauseBeforeSend,
                          subtitle: l10n.voicePauseBeforeSendSubtitle,
                          valueLabel: l10n.voiceSttSeconds(
                              settings.voiceSttPauseForSeconds),
                          value: settings.voiceSttPauseForSeconds.toDouble(),
                          min: 1,
                          max: 120,
                          divisions: 119,
                          onChanged: (value) => settingsProvider
                              .updateVoiceSttPauseForSeconds(value.round()),
                        ),
                        _divider(context),
                        _sliderRow(
                          context,
                          icon: Icons.timer_outlined,
                          title: l10n.voiceListeningLimit,
                          subtitle: l10n.voiceListeningLimitSubtitle,
                          valueLabel: l10n.voiceSttSeconds(
                              settings.voiceSttListenForSeconds),
                          value: settings.voiceSttListenForSeconds.toDouble(),
                          min: 15,
                          max: 300,
                          divisions: 57,
                          onChanged: (value) => settingsProvider
                              .updateVoiceSttListenForSeconds(value.round()),
                        ),
                        if (settings.voiceSttProvider == 'whisper' &&
                            _whisperModelReady) ...[
                          _divider(context),
                          _dangerRow(
                            context,
                            title: l10n.voiceWhisperDeleteModel,
                            onTap: _deleteWhisperModel,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),

              _tipCard(context, l10n),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: GlassSettingsBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                child: Text(
                  l10n.voiceSettings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: topBg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(headerH),
        child: GlassPageHeader(
          title: l10n.voiceSettings,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: headerH),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _softIcon(BuildContext context, IconData icon, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: c, size: 22),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 66,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
    );
  }

  Widget _navRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _sliderRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _softIcon(context, icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintRow(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerRow(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading:
          _softIcon(context, Icons.delete_outline_rounded, color: cs.error),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: cs.error),
      ),
      onTap: onTap,
    );
  }

  Widget _remoteKokoroStatusRow(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final ok = _remoteKokoroConnected;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: _remoteKokoroChecking
          ? const SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          : _softIcon(
              context,
              ok ? Icons.check_circle_rounded : Icons.cloud_off_rounded,
              color: ok ? Colors.green : cs.error,
            ),
      title: Text(
        ok ? l10n.voiceRemoteKokoroConnected : l10n.voiceRemoteKokoroNotFound,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(l10n.voiceRemoteKokoroRequiresConnect),
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded),
        onPressed: _checkRemoteKokoro,
      ),
    );
  }

  Widget _tipCard(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                l10n.voiceQuickTip,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.voiceQuickTipBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVoiceSheet({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget Function(BuildContext context, ScrollController? scroll)
        builder,
    bool scrollable = false,
    double initialChildSize = 0.56,
    double minChildSize = 0.36,
    double maxChildSize = 0.92,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final wide = prefersWideSettingsLayout(context);
    await showAdaptiveModal<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      showDragHandle: !wide,
      dialogMaxWidth: 560,
      shape: wide
          ? null
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
      builder: (sheetContext) {
        final keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final header = Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        );

        final Widget sheet;
        if (wide) {
          sheet = SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: scrollable
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        Expanded(
                          child: builder(
                            sheetContext,
                            PrimaryScrollController.maybeOf(sheetContext),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          builder(sheetContext, null),
                        ],
                      ),
                    ),
            ),
          );
        } else if (!scrollable) {
          final maxH =
              (MediaQuery.sizeOf(sheetContext).height - keyboard) * 0.78;
          sheet = SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      builder(sheetContext, null),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          sheet = DraggableScrollableSheet(
            initialChildSize: initialChildSize,
            minChildSize: minChildSize,
            maxChildSize: maxChildSize,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(child: builder(context, scrollController)),
                ],
              );
            },
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: sheet,
        );
      },
    );
  }

  Widget _optionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
    Color? accent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = accent ?? cs.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              color: selected
                  ? tint.withValues(alpha: isDark ? 0.18 : 0.10)
                  : (isDark
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
                      : cs.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? tint.withValues(alpha: 0.55)
                    : cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                _softIcon(context, icon, color: tint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? tint : cs.outlineVariant,
                      size: 22,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetSearchField({
    required BuildContext context,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.55)),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTestVoiceTile(
    AppLocalizations l10n,
    ThemeData theme,
    AppSettings settings,
  ) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: _voiceTestRunning
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.primary,
                      ),
                    ),
                  ),
                )
              : _softIcon(context, Icons.play_circle_outline_rounded),
          title: Text(
            l10n.voiceTestVoice,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            _voiceTestRunning
                ? _voiceTestPhaseLabel(l10n, _voiceTestPhase)
                : l10n.voiceTestSampleHint,
          ),
          enabled: !_voiceTestRunning,
          onTap: () => _runVoiceTest(l10n, settings),
        ),
        if (_voiceTestRunning)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_voiceTestIndeterminate || _voiceTestProgress == null)
                  const LinearProgressIndicator()
                else
                  LinearProgressIndicator(value: _voiceTestProgress),
                if (_voiceTestProgress != null && !_voiceTestIndeterminate) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(_voiceTestProgress! * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String _voiceTestPhaseLabel(AppLocalizations l10n, String phase) {
    switch (phase) {
      case 'initializing':
        return l10n.voiceTestProgressInitializing;
      case 'generating':
        return l10n.voiceTestProgressGenerating;
      case 'preparing':
        return l10n.voiceTestProgressPreparing;
      case 'playing':
        return l10n.voiceTestProgressPlaying;
      case 'connecting':
        return l10n.voiceTestProgressConnecting;
      case 'complete':
        return l10n.voiceTestProgressComplete;
      default:
        return l10n.voiceTestVoiceSubtitle;
    }
  }

  void _setVoiceTestProgress(String phase, double? progress) {
    if (!mounted) return;
    setState(() {
      _voiceTestPhase = phase;
      _voiceTestProgress = progress;
      _voiceTestIndeterminate =
          progress == null && phase != 'complete' && phase != 'error';
    });
  }

  Future<void> _runVoiceTest(AppLocalizations l10n, dynamic settings) async {
    if (_voiceTestRunning) return;
    setState(() {
      _voiceTestRunning = true;
      _voiceTestPhase = 'initializing';
      _voiceTestProgress = null;
      _voiceTestIndeterminate = true;
    });

    final phrase = l10n.voiceTestPhrase;
    VoidCallback? previousComplete;
    Function(String, int, int)? previousTtsProgress;

    try {
      if (settings.voiceTtsProvider == 'kokoro_remote' &&
          _remoteKokoroConnected) {
        _setVoiceTestProgress('connecting', null);
        _setVoiceTestProgress('generating', null);
        final ok = await _remoteKokoroTts.speak(phrase);
        _setVoiceTestProgress(ok ? 'complete' : 'error', ok ? 1.0 : null);
      } else if (await _proCloudTtsTestVoice(settings, phrase) != null) {
        // ElevenLabs / Grok voice test ran in the Pro part.
      } else if (settings.voiceTtsProvider == 'kokoro' && _kokoroModelReady) {
        final langId = _readyOnDeviceSpeakLanguage(settings);
        if (langId == null) {
          throw Exception(l10n.voiceTestNoPackReady);
        }
        final ok = await _kokoroTts.speak(
          TtsLanguageCatalog.testPhraseFor(langId),
          language: langId,
          awaitCompletion: true,
          onProgress: (phase, progress) {
            _setVoiceTestProgress(phase, progress);
          },
        );
        if (!ok) {
          throw Exception(
            _kokoroTts.lastError ?? l10n.voiceTestNoPackReady,
          );
        }
      } else {
        final expectedLength = phrase.length;
        previousTtsProgress = _tts.onProgress;
        _tts.onProgress = (text, start, end) {
          if (expectedLength <= 0) return;
          _setVoiceTestProgress(
            'playing',
            (end / expectedLength).clamp(0.0, 1.0),
          );
        };
        previousComplete = _tts.onComplete;
        final completer = Completer<void>();
        _tts.onComplete = () {
          previousComplete?.call();
          if (!completer.isCompleted) completer.complete();
        };
        _setVoiceTestProgress('playing', 0.0);
        await _tts.speak(phrase);
        await completer.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () {},
        );
        _setVoiceTestProgress('complete', 1.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      _tts.onProgress = previousTtsProgress;
      if (previousComplete != null) {
        _tts.onComplete = previousComplete;
      }
      if (mounted) {
        setState(() {
          _voiceTestRunning = false;
          _voiceTestPhase = '';
          _voiceTestProgress = null;
          _voiceTestIndeterminate = false;
        });
      }
    }
  }

  Widget _buildStatusChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required bool ok,
    VoidCallback? onTap,
  }) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = ok ? const Color(0xFF2E9E6B) : cs.error;
    final chip = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            ok ? Icons.check_circle_rounded : Icons.touch_app_rounded,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: chip,
      ),
    );
  }

  String _whisperModelSubtitle(AppLocalizations l10n, AppSettings settings) {
    final spec = WhisperModelManager.byId(settings.whisperModelId);
    if (spec == null) return l10n.voiceChooseListeningModel;
    final ready = _whisperReadyById[spec.id] == true;
    final status = ready ? l10n.voiceModelReady : l10n.voiceNeedsDownload;
    return '${spec.displayName} · ${spec.sizeLabel} · $status';
  }

  void _showWhisperModelSheet(
    AppLocalizations l10n,
    ThemeData theme,
    AppSettings settings,
  ) {
    showAdaptiveModal(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: !prefersWideSettingsLayout(context),
      dialogMaxWidth: 560,
      shape: prefersWideSettingsLayout(context)
          ? null
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
      builder: (ctx) {
        return _WhisperModelSheet(
          parent: this,
          l10n: l10n,
          theme: theme,
        );
      },
    );
  }

  Widget _buildWhisperModelPicker(
    AppLocalizations l10n,
    ThemeData theme,
    AppSettings settings, {
    VoidCallback? onUiChanged,
  }) {
    final selectedId = settings.whisperModelId;
    final downloadingSelected = _whisperDownloading &&
        _whisperModelManager.selectedModelId == selectedId;
    final cs = theme.colorScheme;

    Future<void> select(String id) async {
      await _selectWhisperModel(id);
      if (!mounted) return;
      onUiChanged?.call();
    }

    Future<void> download(String id) async {
      await _downloadWhisperModel(id);
      if (!mounted) return;
      onUiChanged?.call();
    }

    return Column(
      children: [
        for (final spec in WhisperModelManager.catalog)
          _optionCard(
            context: context,
            icon: Icons.graphic_eq_rounded,
            title: spec.displayName,
            subtitle: [
              spec.sizeLabel,
              spec.description,
              if (_whisperReadyById[spec.id] == true) l10n.voiceDownloaded,
              if (_whisperError != null &&
                  selectedId == spec.id &&
                  !(_whisperReadyById[spec.id] ?? false))
                l10n.voiceDownloadFailed,
            ].where((s) => s.isNotEmpty).join(' · '),
            selected: selectedId == spec.id,
            onTap: _whisperDownloading ? () {} : () => select(spec.id),
            trailing: downloadingSelected && selectedId == spec.id
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      value: _whisperDownloadProgress > 0
                          ? _whisperDownloadProgress
                          : null,
                    ),
                  )
                : (_whisperReadyById[spec.id] == true
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2E9E6B), size: 22)
                    : IconButton(
                        tooltip: l10n.download,
                        icon: Icon(Icons.download_rounded, color: cs.primary),
                        onPressed: _whisperDownloading
                            ? null
                            : () => download(spec.id),
                      )),
          ),
        if (downloadingSelected) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _whisperDownloadProgress >= 0.85
                      ? l10n.voiceFinishingSetup
                      : l10n.voiceDownloadingListeningModel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: _whisperDownloadProgress > 0
                        ? _whisperDownloadProgress
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _whisperDownloadProgress > 0
                      ? '${(_whisperDownloadProgress * 100).toStringAsFixed(0)}%'
                      : l10n.voiceStartingDownload,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ] else if (!(_whisperReadyById[selectedId] ?? false)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed:
                  _whisperDownloading ? null : () => download(selectedId),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(
                '${l10n.download} ${WhisperModelManager.byId(selectedId)?.displayName ?? 'model'}',
              ),
            ),
          ),
        ],
        if (_whisperError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              _whisperError!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }

  bool get _kokoroHasVoices =>
      ['en', 'es', 'fr', 'zh'].any((id) => _kokoroReadyByLang[id] == true);

  String _kokoroPacksSubtitle(AppLocalizations l10n) {
    if (_kokoroDownloading) {
      final lang = TtsLanguageCatalog.byId(_kokoroDownloadingLang ?? '');
      final name = lang?.nativeName ?? '';
      return name.isEmpty
          ? l10n.voiceKokoroDownloading
          : l10n.voiceTtsLanguagePacksSubtitleDownloading(name);
    }
    const langs = TtsLanguageCatalog.languages;
    final ready =
        langs.where((lang) => _kokoroReadyByLang[lang.id] == true).length;
    if (ready == 0) return l10n.voiceTtsLanguagePacksSubtitleNone;
    return l10n.voiceTtsLanguagePacksSubtitleReady(ready, langs.length);
  }

  void _showKokoroPacksSheet(AppLocalizations l10n, ThemeData theme) {
    showAdaptiveModal(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: !prefersWideSettingsLayout(context),
      dialogMaxWidth: 560,
      shape: prefersWideSettingsLayout(context)
          ? null
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
      builder: (ctx) {
        return _KokoroPacksSheet(
          parent: this,
          l10n: l10n,
          theme: theme,
        );
      },
    );
  }

  Widget _buildKokoroModelTile(
    AppLocalizations l10n,
    ThemeData theme, {
    VoidCallback? onUiChanged,
  }) {
    const langs = TtsLanguageCatalog.languages;
    return Column(
      children: [
        for (var i = 0; i < langs.length; i++) ...[
          if (i > 0) _divider(context),
          _kokoroLanguageRow(
            l10n,
            theme,
            langs[i],
            onUiChanged: onUiChanged,
          ),
        ],
        if (_kokoroError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Text(
              _kokoroError!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _kokoroLanguageRow(
    AppLocalizations l10n,
    ThemeData theme,
    TtsLanguageSpec lang, {
    VoidCallback? onUiChanged,
  }) {
    final cs = theme.colorScheme;
    final ready = _kokoroReadyByLang[lang.id] == true;
    final downloading = _kokoroDownloadingLang == lang.id;
    final spec = TtsLanguageCatalog.assetById(lang.assetId);
    final sizeMB = spec?.sizeMB ?? 0;
    final subtitle = downloading
        ? (_kokoroDownloadProgress > 0
            ? '${(_kokoroDownloadProgress * 100).toStringAsFixed(0)}%'
            : l10n.voiceStartingDownload)
        : ready
            ? '${lang.voiceLabel} · ${l10n.voiceReady}'
            : (lang.sharesKokoroPack
                ? l10n.voiceTtsSharedPackSize(sizeMB)
                : l10n.voiceTtsPiperPackSize(sizeMB));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: downloading
          ? SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    value: _kokoroDownloadProgress > 0
                        ? _kokoroDownloadProgress
                        : null,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            )
          : _softIcon(
              context,
              ready ? Icons.check_circle_rounded : Icons.language_rounded,
              color: ready ? const Color(0xFF2E9E6B) : cs.primary,
            ),
      title: Text(
        '${lang.flag}  ${lang.nativeName}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (downloading) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value:
                  _kokoroDownloadProgress > 0 ? _kokoroDownloadProgress : null,
            ),
          ],
        ],
      ),
      trailing: downloading
          ? null
          : ready
              ? IconButton(
                  tooltip: l10n.voiceKokoroDeleteModel,
                  onPressed: _kokoroDownloading
                      ? null
                      : () async {
                          await _deleteKokoroLanguage(lang.id);
                          onUiChanged?.call();
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                )
              : FilledButton(
                  onPressed: _kokoroDownloading
                      ? null
                      : () async {
                          await _downloadKokoroLanguage(lang.id);
                          onUiChanged?.call();
                        },
                  child: Text(l10n.voiceKokoroDownloadButton),
                ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, SettingsProvider settingsProvider) {
    final voices = _tts.availableVoices;
    final langSet = <String>{};
    for (final v in voices) {
      final locale = v['locale'] ?? '';
      if (locale.isNotEmpty && !locale.startsWith('he')) langSet.add(locale);
    }
    final languages = langSet.toList()
      ..sort((a, b) => LocaleDisplayNames.displayName(a)
          .compareTo(LocaleDisplayNames.displayName(b)));

    final l10n = AppLocalizations.of(context);
    _showVoiceSheet(
      context: context,
      title: l10n.voiceSpokenReplyLanguage,
      subtitle: l10n.voiceSpokenReplyLanguageSubtitle,
      scrollable: true,
      initialChildSize: 0.62,
      builder: (context, scroll) {
        return ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final lang = languages[index];
            final selected = lang == settingsProvider.settings.voiceLanguage;
            return _optionCard(
              context: context,
              icon: Icons.language_rounded,
              title: LocaleDisplayNames.displayName(lang),
              subtitle: lang,
              selected: selected,
              onTap: () {
                settingsProvider.updateVoiceLanguage(lang);
                _tts.setLanguage(lang);
                settingsProvider.updateVoiceName(null);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showSttLanguagePicker(
      BuildContext context, SettingsProvider settingsProvider) {
    final langSet = <String>{};
    for (final locale in _stt.availableLocales) {
      final id = locale.localeId.replaceAll('_', '-');
      if (id.isNotEmpty && !id.startsWith('he')) langSet.add(id);
    }
    const fallbacks = [
      'en-US',
      'en-GB',
      'de-DE',
      'es-ES',
      'fr-FR',
      'it-IT',
      'pt-BR',
      'ru-RU',
      'ja-JP',
      'ko-KR',
      'zh-CN',
      'ar-SA',
      'hi-IN',
      'tr-TR',
      'nl-NL',
      'pl-PL',
      'sv-SE',
      'uk-UA',
    ];
    langSet.addAll(fallbacks);
    langSet.add(settingsProvider.settings.voiceSttLanguage);
    final languages = langSet.toList()
      ..sort((a, b) => LocaleDisplayNames.displayName(a)
          .compareTo(LocaleDisplayNames.displayName(b)));

    final l10n = AppLocalizations.of(context);
    _showVoiceSheet(
      context: context,
      title: l10n.voiceRecognitionLanguage,
      subtitle: l10n.voiceRecognitionLanguageSubtitle,
      scrollable: true,
      initialChildSize: 0.66,
      builder: (context, scroll) {
        return ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final lang = languages[index];
            final selected = lang == settingsProvider.settings.voiceSttLanguage;
            return _optionCard(
              context: context,
              icon: Icons.translate_rounded,
              title: LocaleDisplayNames.displayName(lang),
              subtitle: lang,
              selected: selected,
              onTap: () async {
                settingsProvider.updateVoiceSttLanguage(lang);
                await _stt.initialize(
                  sttProvider: settingsProvider.settings.voiceSttProvider,
                  localeId: lang.replaceAll('-', '_'),
                );
                if (context.mounted) Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showSttProviderPicker(
      BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final current = settingsProvider.settings.voiceSttProvider;
    final whisperOnly = _whisperOnly;

    _showVoiceSheet(
      context: context,
      title: l10n.voiceHowIHearYou,
      subtitle: whisperOnly
          ? l10n.voiceSttMacosRequiresWhisper
          : l10n.voiceHowIHearYouSubtitle,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!whisperOnly)
              _optionCard(
                context: context,
                icon: Icons.phone_iphone_rounded,
                title: l10n.voiceSttOnDevice,
                subtitle: l10n.voiceSttSystemHint,
                selected: current == 'system',
                onTap: () {
                  settingsProvider.updateVoiceSttProvider('system');
                  Navigator.pop(context);
                },
              ),
            _optionCard(
              context: context,
              icon: Icons.psychology_alt_rounded,
              title: l10n.voiceSttProviderWhisper,
              subtitle: whisperOnly
                  ? l10n.voiceSttMacosDownloadWhisper
                  : l10n.voiceSttWhisperHint,
              selected: current == 'whisper' || whisperOnly,
              onTap: () {
                settingsProvider.updateVoiceSttProvider('whisper');
                Navigator.pop(context);
                _checkWhisperModel().then((_) {
                  if (!mounted) return;
                  if (!_whisperModelReady && !_whisperDownloading) {
                    _downloadWhisperModel();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _showTtsProviderPicker(
      BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final current = settingsProvider.settings.voiceTtsProvider;

    _showVoiceSheet(
      context: context,
      title: l10n.voiceEngineTitle,
      subtitle: l10n.voiceEngineSubtitle,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _optionCard(
              context: context,
              icon: Icons.phone_iphone_rounded,
              title: l10n.voiceTtsSystemVoice,
              subtitle: l10n.voiceTtsSystemHint,
              selected: current == 'native',
              onTap: () {
                settingsProvider.updateVoiceTtsProvider('native');
                Navigator.pop(context);
              },
            ),
            _optionCard(
              context: context,
              icon: Icons.auto_awesome_rounded,
              title: l10n.voiceTtsOnDeviceNeural,
              subtitle: l10n.voiceTtsOnDeviceHint,
              selected: current == 'kokoro',
              onTap: () {
                settingsProvider.updateVoiceTtsProvider('kokoro');
                Navigator.pop(context);
                // _checkKokoroModel already catches and shows a dialog on
                // failure, so no additional try/catch needed here.
                _checkKokoroModel();
              },
            ),
            // Remote PC voice is a Pro feature; the open-source build hides
            // it instead of showing an upsell.
            if (ProFeatures.included ||
                !settingsProvider.settings.isRemoteActive)
            _optionCard(
              context: context,
              icon: Icons.computer_rounded,
              title: l10n.voiceTtsPcVoice,
              subtitle: l10n.voiceTtsPcHint,
              selected: current == 'kokoro_remote',
              onTap: () {
                final settings = settingsProvider.settings;
                if (settings.isRemoteActive &&
                    !SubscriptionService().isPremium) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                  return;
                }
                settingsProvider.updateVoiceTtsProvider('kokoro_remote');
                Navigator.pop(context);
                _checkRemoteKokoro();
              },
            ),
            ..._proCloudTtsProviderOptions(context, settingsProvider, l10n, current),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _showKokoroSpeakerPicker(
      BuildContext context, SettingsProvider settingsProvider) {
    const speakers = KokoroTtsService.speakers;
    final currentSpeakerId = settingsProvider.settings.voiceKokoroSpeakerId;
    final l10n = AppLocalizations.of(context);

    _showVoiceSheet(
      context: context,
      title: l10n.voiceChooseAVoice,
      subtitle: l10n.voiceChooseAVoiceSubtitle,
      scrollable: true,
      initialChildSize: 0.58,
      builder: (context, scroll) {
        return ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: speakers.length,
          itemBuilder: (context, index) {
            final speaker = speakers[index];
            final id = speaker['id'] as int;
            final name = speaker['name'] as String;
            final gender = speaker['gender'] as String;
            final code = speaker['code'] as String;
            final isFemale = gender == 'female';
            return _optionCard(
              context: context,
              icon: isFemale ? Icons.face_3_rounded : Icons.face_rounded,
              title: name,
              subtitle: code,
              selected: id == currentSpeakerId,
              accent:
                  isFemale ? const Color(0xFFE091B0) : const Color(0xFF6DA8FF),
              onTap: () {
                settingsProvider.updateVoiceKokoroSpeakerId(id);
                _kokoroTts.setSpeakerId(id);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  String _kokoroSpeakerDisplayName(int speakerId) {
    return TtsLanguageCatalog.speakerDisplayName(speakerId);
  }

  void _showVoicePicker(
      BuildContext context, SettingsProvider settingsProvider) {
    final langCode = settingsProvider.settings.voiceLanguage.split('-').first;
    final voices = _tts.getVoicesForLanguage(langCode);
    final voiceIndexMap = TtsVoiceDisplay.indexMapForVoices(voices);

    if (voices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).voiceNoVoicesAvailable),
        ),
      );
      return;
    }

    var query = '';
    final wide = prefersWideSettingsLayout(context);
    showAdaptiveModal<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: !wide,
      dialogMaxWidth: 560,
      shape: wide
          ? null
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filteredVoices = normalizedQuery.isEmpty
                ? voices
                : voices.where((voice) {
                    final rawName = (voice['name'] ?? '').toString();
                    final name = rawName.toLowerCase();
                    final displayTitle = _tts
                        .displayTitleForVoice(
                          voice,
                          indexWithinLocale: voiceIndexMap[rawName],
                        )
                        .toLowerCase();
                    final displaySubtitle =
                        _tts.displaySubtitleForVoice(voice).toLowerCase();
                    return name.contains(normalizedQuery) ||
                        displayTitle.contains(normalizedQuery) ||
                        displaySubtitle.contains(normalizedQuery);
                  }).toList();

            Widget body(ScrollController? scrollController) {
              final cs = Theme.of(context).colorScheme;
              final sheetL10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sheetL10n.voiceTtsSystemVoice,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sheetL10n.voicePickSystemVoiceSubtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _sheetSearchField(
                    context: context,
                    hint: sheetL10n.search,
                    onChanged: (value) => setSheetState(() => query = value),
                  ),
                  _optionCard(
                    context: context,
                    icon: Icons.smartphone_rounded,
                    title: sheetL10n.voiceDefault,
                    subtitle:
                        AppLocalizations.of(context).voiceUseSystemDefault,
                    selected: settingsProvider.settings.voiceName == null,
                    onTap: () {
                      settingsProvider.updateVoiceName(null);
                      _tts.setVoice(null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  Expanded(
                    child: filteredVoices.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                AppLocalizations.of(context).tryDifferentSearch,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: filteredVoices.length,
                            itemBuilder: (context, index) {
                              final voice = filteredVoices[index];
                              final name = voice['name'] ?? 'Unknown';
                              final isSelected =
                                  name == settingsProvider.settings.voiceName;
                              final displayTitle = _tts.displayTitleForVoice(
                                voice,
                                indexWithinLocale: voiceIndexMap[name],
                              );
                              final displaySubtitle =
                                  _tts.displaySubtitleForVoice(voice);
                              return _optionCard(
                                context: context,
                                icon: Icons.record_voice_over_rounded,
                                title: displayTitle,
                                subtitle: displaySubtitle,
                                selected: isSelected,
                                onTap: () {
                                  settingsProvider.updateVoiceName(name);
                                  _tts.setVoice(name);
                                  Navigator.pop(sheetContext);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            }

            if (wide) {
              return SafeArea(child: body(null));
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) => body(scrollController),
            );
          },
        );
      },
    );
  }

  String _formatVoiceName(String name) {
    for (final voice in _tts.availableVoices) {
      if (voice['name'] == name) {
        final indices = TtsVoiceDisplay.indexMapForVoices(_tts.availableVoices);
        return _tts.displayTitleForVoice(
          voice,
          indexWithinLocale: indices[name],
        );
      }
    }
    return TtsVoiceDisplay.title(name: name);
  }
}

class _WhisperModelSheet extends StatefulWidget {
  final _VoiceSettingsScreenState parent;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _WhisperModelSheet({
    required this.parent,
    required this.l10n,
    required this.theme,
  });

  @override
  State<_WhisperModelSheet> createState() => _WhisperModelSheetState();
}

class _WhisperModelSheetState extends State<_WhisperModelSheet> {
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _progressSub = WhisperModelManager.instance.progressStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = widget.theme;
    final parent = widget.parent;

    final cs = theme.colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            final liveSettings = settingsProvider.settings;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.voiceListeningModel,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.voiceWhisperSizeInfoBody,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.voiceAboutModelSizes,
                        icon:
                            Icon(Icons.info_outline_rounded, color: cs.primary),
                        onPressed: parent._showWhisperSizeInfo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      parent._buildWhisperModelPicker(
                        l10n,
                        theme,
                        liveSettings,
                        onUiChanged: () {
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _KokoroPacksSheet extends StatefulWidget {
  final _VoiceSettingsScreenState parent;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _KokoroPacksSheet({
    required this.parent,
    required this.l10n,
    required this.theme,
  });

  @override
  State<_KokoroPacksSheet> createState() => _KokoroPacksSheetState();
}

class _KokoroPacksSheetState extends State<_KokoroPacksSheet> {
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _progressSub = widget.parent._modelManager.progressStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = widget.theme;
    final parent = widget.parent;
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.voiceTtsLanguagePacks,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.voiceTtsLanguagePacksHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  parent._buildKokoroModelTile(
                    l10n,
                    theme,
                    onUiChanged: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
