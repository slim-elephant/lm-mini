import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/tts_voice_display.dart';

/// Text-to-Speech service wrapping native engines
/// (Apple AVSpeechSynthesizer on iOS, Google TTS on Android)
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _tts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  // Current settings
  double _speechRate = 0.45; // 0.0 - 1.0 (slightly slower for natural feel)
  double _pitch = 1.0; // 0.5 - 2.0
  double _volume = 1.0; // 0.0 - 1.0
  String? _selectedVoice; // Voice identifier
  String _language = 'en-US';

  // Callbacks
  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onPause;
  VoidCallback? onContinue;
  VoidCallback? onCancel;
  VoidCallback? onError;
  Function(String, int, int)? onProgress; // text, startOffset, endOffset

  // Available voices cache
  List<Map<String, String>> _availableVoices = [];

  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  bool get isInitialized => _isInitialized;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String? get selectedVoice => _selectedVoice;
  String get language => _language;
  List<Map<String, String>> get availableVoices => _availableVoices;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _tts = FlutterTts();

    // Set up handlers
    _tts!.setStartHandler(() {
      _isSpeaking = true;
      _isPaused = false;
      _enableWakeLock();
      onStart?.call();
    });

    _tts!.setCompletionHandler(() {
      _isSpeaking = false;
      _isPaused = false;
      _disableWakeLock();
      onComplete?.call();
    });

    _tts!.setPauseHandler(() {
      _isPaused = true;
      onPause?.call();
    });

    _tts!.setContinueHandler(() {
      _isPaused = false;
      onContinue?.call();
    });

    _tts!.setCancelHandler(() {
      _isSpeaking = false;
      _isPaused = false;
      _disableWakeLock();
      onCancel?.call();
    });

    _tts!.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      onProgress?.call(text, startOffset, endOffset);
    });

    _tts!.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _isSpeaking = false;
      _isPaused = false;
      _disableWakeLock();
      onError?.call();
    });

    // iOS-specific: use AVAudioSession category for mixing
    if (Platform.isIOS) {
      await _tts!.setSharedInstance(true);
      await _tts!.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }

    // Ensure completion handler fires reliably on all platforms
    await _tts!.awaitSpeakCompletion(true);

    // Apply default settings
    await _tts!.setSpeechRate(_speechRate);
    await _tts!.setPitch(_pitch);
    await _tts!.setVolume(_volume);
    await _tts!.setLanguage(_language);

    // Cache available voices
    await _loadAvailableVoices();

    // Auto-select the best quality voice for the current language
    await autoSelectBestVoice();

    _isInitialized = true;
  }

  Future<void> _loadAvailableVoices() async {
    try {
      final voices = await _tts!.getVoices;
      if (voices != null) {
        _availableVoices = (voices as List)
            .map((v) => Map<String, String>.from(
                  (v as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
                ))
            .toList();

        // Sort by quality (premium > enhanced > compact) then by name
        _availableVoices.sort((a, b) {
          final qualA = _voiceQuality(a['name'] ?? '');
          final qualB = _voiceQuality(b['name'] ?? '');
          if (qualA != qualB) return qualB - qualA; // Higher quality first
          final langCompare = (a['locale'] ?? '').compareTo(b['locale'] ?? '');
          if (langCompare != 0) return langCompare;
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        });
      }
    } catch (e) {
      debugPrint('Failed to load TTS voices: $e');
    }
  }

  /// Returns a quality score for a voice name.
  /// Higher = better quality. Used for sorting & auto-selection.
  int _voiceQuality(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('premium')) return 3;
    if (lower.contains('enhanced')) return 2;
    if (lower.contains('compact')) return 0;
    // Android voices: "local" variants are higher quality than network
    if (lower.contains('-local')) return 2;
    return 1; // Unknown / default quality
  }

  /// Get the best available voice for a language code.
  /// Prefers premium > enhanced > default > compact voices.
  Map<String, String>? getBestVoiceForLanguage(String langCode) {
    final voices = getVoicesForLanguage(langCode);
    if (voices.isEmpty) return null;
    // Already sorted by quality (descending), so first is best
    return voices.first;
  }

  /// Auto-select the best voice for the current language if no voice is selected.
  Future<void> autoSelectBestVoice() async {
    if (_selectedVoice != null) return; // User already picked one
    final langCode = _language.split('-').first;
    final best = getBestVoiceForLanguage(langCode);
    if (best != null) {
      _selectedVoice = best['name'];
      await _tts!.setVoice(best);
      debugPrint('TTS auto-selected voice: ${best['name']} (quality: ${_voiceQuality(best['name'] ?? '')})');
    }
  }

  /// Get voices filtered by language code (e.g., 'en', 'de', 'fr')
  List<Map<String, String>> getVoicesForLanguage(String langCode) {
    return _availableVoices.where((v) {
      final locale = v['locale'] ?? '';
      return locale.toLowerCase().startsWith(langCode.toLowerCase());
    }).toList();
  }

  /// Get a human-readable quality label for a voice
  String getVoiceQualityLabel(String voiceName) {
    final q = _voiceQuality(voiceName);
    switch (q) {
      case 3: return 'Premium';
      case 2: return 'Enhanced';
      case 0: return 'Compact';
      default: return 'Standard';
    }
  }

  String displayTitleForVoice(Map<String, String> voice, {int? indexWithinLocale}) {
    return TtsVoiceDisplay.title(
      name: voice['name'] ?? '',
      locale: voice['locale'],
      indexWithinLocale: indexWithinLocale,
    );
  }

  String displaySubtitleForVoice(Map<String, String> voice) {
    return TtsVoiceDisplay.subtitle(
      name: voice['name'] ?? '',
      locale: voice['locale'],
      qualityLabel: getVoiceQualityLabel(voice['name'] ?? ''),
    );
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    // Strip markdown formatting for cleaner speech
    final cleanText = _stripMarkdown(text);
    if (cleanText.trim().isEmpty) return;

    await _tts!.speak(cleanText);
  }

  /// Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _tts!.stop();
    _isSpeaking = false;
    _isPaused = false;
    _disableWakeLock();
  }

  /// Pause speaking (iOS only)
  Future<void> pause() async {
    if (!_isInitialized || !_isSpeaking) return;
    if (Platform.isIOS) {
      await _tts!.pause();
    } else {
      // Android doesn't support pause, so stop instead
      await stop();
    }
  }

  /// Update speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _tts!.setSpeechRate(_speechRate);
    }
  }

  /// Update pitch (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (_isInitialized) {
      await _tts!.setPitch(_pitch);
    }
  }

  /// Update volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _tts!.setVolume(_volume);
    }
  }

  /// Set the voice by name/identifier
  Future<void> setVoice(String? voiceName) async {
    _selectedVoice = voiceName;
    if (_isInitialized && voiceName != null) {
      final voice = _availableVoices.firstWhere(
        (v) => v['name'] == voiceName,
        orElse: () => {},
      );
      if (voice.isNotEmpty) {
        await _tts!.setVoice(voice);
      }
    } else if (_isInitialized && voiceName == null) {
      // Reset to best available voice for current language
      await autoSelectBestVoice();
    }
  }

  /// Set the language (also re-selects the best voice if no explicit voice is set)
  Future<void> setLanguage(String language) async {
    _language = language;
    if (_isInitialized) {
      await _tts!.setLanguage(language);
    }
  }

  /// Strip markdown formatting for cleaner speech output
  String _stripMarkdown(String text) {
    var clean = text;

    // Remove code blocks
    clean = clean.replaceAll(RegExp(r'```[\s\S]*?```'), ' code block omitted ');
    clean = clean.replaceAll(RegExp(r'`[^`]+`'), '');

    // Remove headers
    clean = clean.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Remove bold/italic markers
    clean = clean.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    clean = clean.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    clean = clean.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    clean = clean.replaceAll(RegExp(r'_([^_]+)_'), r'$1');

    // Remove links but keep text
    clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');

    // Remove images
    clean = clean.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), '');

    // Remove horizontal rules
    clean = clean.replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '');

    // Remove bullet points
    clean = clean.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');

    // Remove numbered lists markers
    clean = clean.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // Remove hidden image generation prompts [IMG_PROMPT: ...]
    clean = clean.replaceAll(RegExp(r'\[IMG_PROMPT:\s*.+?\]', dotAll: true), '');

    // Remove any hidden tags the model may emit (e.g. [MEMORY_SAVE: ...], [TOOL: ...])
    clean = clean.replaceAll(RegExp(r'\[(?:MEMORY_SAVE|MEMORY|TOOL|ACTION|FUNCTION_CALL):[^\]]*\]', dotAll: true), '');

    // Remove HTML tags
    clean = clean.replaceAll(RegExp(r'<[^>]+>'), '');

    // Clean up extra whitespace
    clean = clean.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    clean = clean.replaceAll(RegExp(r' {2,}'), ' ');

    return clean.trim();
  }

  // ---------------------------------------------------------------------------
  // Wake lock helpers — keep screen on while speaking
  // ---------------------------------------------------------------------------

  Future<void> _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
      debugPrint('🔒 TTS wake lock enabled');
    } catch (e) {
      debugPrint('⚠️ TTS could not enable wake lock: $e');
    }
  }

  Future<void> _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
      debugPrint('🔓 TTS wake lock disabled');
    } catch (e) {
      debugPrint('⚠️ TTS could not disable wake lock: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    _tts?.stop();
    _isInitialized = false;
  }
}
