import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../desktop/desktop_platform.dart';
import '../providers/settings_provider.dart';
import '../services/audio_setup_service.dart';
import '../services/mac_system_stt_service.dart';
import '../services/macos_media_permissions.dart';
import '../widgets/audio_setup_dialog.dart';

/// Returns `true` when voice/audio features may proceed.
///
/// Always requests microphone (+ speech recognition on Apple platforms) first
/// so App Store Review sees the Info.plist purpose-string dialogs on mic tap.
Future<bool> ensureAudioSetup(BuildContext context) async {
  final settingsProvider = context.read<SettingsProvider>();
  var settings = settingsProvider.settings;

  // TCC prompts must run on mic/voice entry — before setup dialogs or STT init.
  final micOk = await VoiceCapturePermissions.ensureForVoiceInput();
  if (!micOk) {
    if (context.mounted) {
      final isMac = !kIsWeb && Platform.isMacOS;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMac
                ? 'Microphone access is required for voice input. '
                    'Allow LM Mini when prompted. If nothing appears, quit the '
                    'IDE-launched build and open LM Mini.app directly, or enable '
                    'it in System Settings → Privacy & Security → Microphone.'
                : 'Microphone access is required for voice input. '
                    'Please allow access when prompted.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  // Sandboxed Mac without the native speech bridge cannot use Apple system
  // STT (the plugin crashes) — keep Whisper selected. When the native bridge
  // is available (installed .app), leave the user's "system" choice intact.
  final macNativeSpeech = await MacSystemSttService.instance.isAvailable();
  if (DesktopPlatform.macListeningRequiresWhisper &&
      !macNativeSpeech &&
      settings.voiceSttProvider == 'system') {
    settingsProvider.updateVoiceSttProvider('whisper');
    settings = settingsProvider.settings;
  }

  if (!await AudioSetupService.needsSetup(settings)) {
    return true;
  }

  if (!context.mounted) return false;
  final result = await AudioSetupDialog.show(context);
  if (!context.mounted) return false;
  if (result == null || result == AudioSetupDialogResult.cancelled) {
    return false;
  }

  settingsProvider.completeAudioSetup();
  settings = settingsProvider.settings;

  // Dialog success must still leave listening actually configured (esp. Whisper
  // on sandboxed Mac). Do not open voice mode with a dead STT path.
  if (!await AudioSetupService.isConfigured(settings)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            DesktopPlatform.macListeningRequiresWhisper
                ? 'Download a Whisper speech model in Voice Settings before using Voice Mode on Mac.'
                : 'Finish Voice Settings setup before using voice input.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  return true;
}
