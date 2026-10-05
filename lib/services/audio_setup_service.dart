import '../models/app_settings.dart';
import '../desktop/desktop_platform.dart';
import 'kokoro_model_manager.dart';
import 'mac_system_stt_service.dart';
import 'whisper_model_manager.dart';

/// Checks whether voice/audio features are configured for the user's choices.
class AudioSetupService {
  AudioSetupService._();

  /// Show the setup dialog when the user has not finished setup, or when
  /// required on-device assets are missing.
  static Future<bool> needsSetup(AppSettings settings) async {
    if (!settings.hasCompletedAudioSetup) return true;
    return !(await isConfigured(settings));
  }

  static Future<bool> isConfigured(AppSettings settings) async {
    // Sandboxed Mac builds normally need Whisper — unless the native macOS
    // speech recognizer is available (real installed .app), in which case
    // "System (macOS Speech)" needs no downloaded model.
    final macNative = await MacSystemSttService.instance.isAvailable();
    final needsWhisper = settings.voiceSttProvider == 'whisper' ||
        (DesktopPlatform.macListeningRequiresWhisper && !macNative);
    if (needsWhisper) {
      if (!await WhisperModelManager.instance.hasAnyModelReady()) return false;
    }

    switch (settings.voiceTtsProvider) {
      case 'kokoro':
        if (!await KokoroModelManager().isModelReady()) return false;
        break;
      case 'kokoro_remote':
        if (settings.effectiveVoiceRemoteKokoroUrl.trim().isEmpty) {
          return false;
        }
        break;
      case 'elevenlabs':
        if (!settings.hasElevenLabsApiKey) return false;
        break;
      case 'grok':
        if (!settings.hasGrokApiKey) return false;
        break;
    }

    return true;
  }
}
