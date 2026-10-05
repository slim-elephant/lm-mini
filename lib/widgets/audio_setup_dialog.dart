import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../desktop/desktop_platform.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../screens/voice_settings_screen.dart';
import '../services/kokoro_model_manager.dart';
import '../services/whisper_model_manager.dart';

enum AudioSetupDialogResult {
  cancelled,
  onDevice,
  systemNative,
  openSettings,
}

/// One-time dialog shown before first use of voice input or audio chat.
class AudioSetupDialog extends StatefulWidget {
  const AudioSetupDialog({super.key});

  static Future<AudioSetupDialogResult?> show(BuildContext context) {
    return showDialog<AudioSetupDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AudioSetupDialog(),
    );
  }

  @override
  State<AudioSetupDialog> createState() => _AudioSetupDialogState();
}

class _AudioSetupDialogState extends State<AudioSetupDialog> {
  final KokoroModelManager _kokoroManager = KokoroModelManager();

  bool _kokoroReady = false;
  bool _whisperReady = false;
  bool _downloading = false;
  double _downloadProgress = 0;
  String _downloadPhase = '';
  String? _error;

  StreamSubscription<double>? _kokoroProgressSub;
  StreamSubscription<double>? _whisperProgressSub;

  bool get _whisperRequired => DesktopPlatform.macListeningRequiresWhisper;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _kokoroProgressSub?.cancel();
    _whisperProgressSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final kokoroReady = await _kokoroManager.isModelReady();
    final whisperReady = await WhisperModelManager.instance.isModelReady();
    if (!mounted) return;
    setState(() {
      _kokoroReady = kokoroReady;
      _whisperReady = whisperReady;
    });
  }

  /// On sandboxed Mac: download Whisper (required) + optional Kokoro.
  /// Elsewhere: Kokoro TTS only; Whisper stays optional unless already selected.
  Future<void> _downloadOnDeviceModels() async {
    final settingsProvider = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context);

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      if (_whisperRequired ||
          settingsProvider.settings.voiceSttProvider == 'whisper') {
        settingsProvider.updateVoiceSttProvider('whisper');
        if (!await WhisperModelManager.instance.isModelReady()) {
          setState(() {
            _downloadPhase = l10n.voiceSttMacosDownloadWhisper;
            _downloadProgress = 0;
          });
          _whisperProgressSub?.cancel();
          _whisperProgressSub =
              WhisperModelManager.instance.progressStream.listen((progress) {
            if (mounted) {
              setState(() => _downloadProgress = progress);
            }
          });
          final whisperOk =
              await WhisperModelManager.instance.downloadModel();
          _whisperProgressSub?.cancel();
          if (!whisperOk) {
            throw Exception(
              WhisperModelManager.instance.error ??
                  l10n.voiceSttMacosDownloadWhisper,
            );
          }
        }
      }

      settingsProvider.updateVoiceTtsProvider('kokoro');
      if (!await _kokoroManager.isModelReady()) {
        setState(() {
          _downloadPhase = l10n.audioSetupDownloadingKokoro;
          _downloadProgress = 0;
        });
        _kokoroProgressSub?.cancel();
        _kokoroProgressSub = _kokoroManager.progressStream.listen((progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        });
        final kokoroOk = await _kokoroManager.downloadModel();
        _kokoroProgressSub?.cancel();
        if (!kokoroOk) {
          throw Exception(
              _kokoroManager.error ?? l10n.voiceKokoroDownloadFailed);
        }
      }

      if (!mounted) return;
      await _refreshStatus();
      setState(() {
        _downloading = false;
        _downloadProgress = 1;
        _downloadPhase = l10n.audioSetupDownloadComplete;
      });
      Navigator.pop(context, AudioSetupDialogResult.onDevice);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = e.toString();
      });
    }
  }

  void _useSystemSpeech() {
    // Sandboxed Mac: system STT is unavailable — never take this path.
    if (_whisperRequired) return;
    final settingsProvider = context.read<SettingsProvider>();
    settingsProvider.updateVoiceSttProvider('system');
    settingsProvider.updateVoiceTtsProvider('native');
    Navigator.pop(context, AudioSetupDialogResult.systemNative);
  }

  Future<void> _openVoiceSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoiceSettingsScreen()),
    );
    if (!mounted) return;
    await _refreshStatus();
    Navigator.pop(context, AudioSetupDialogResult.openSettings);
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    required bool ready,
    required AppLocalizations l10n,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Icon(
            ready ? Icons.check_circle : Icons.download_outlined,
            size: 18,
            color: ready ? Colors.green : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            ready ? l10n.audioSetupStatusReady : l10n.audioSetupStatusMissing,
            style: TextStyle(
              fontSize: 12,
              color: ready ? Colors.green : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.headset_mic_rounded, color: cs.primary, size: 36),
      title: Text(l10n.audioSetupTitle, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _whisperRequired
                  ? 'Mac App Store builds need an on-device Whisper speech model to listen. Download it below (Tiny is fine to start).'
                  : l10n.audioSetupMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_whisperRequired)
              _statusRow(
                icon: Icons.mic_rounded,
                label: 'Whisper speech model',
                ready: _whisperReady,
                l10n: l10n,
                cs: cs,
              ),
            _statusRow(
              icon: Icons.record_voice_over_rounded,
              label: l10n.audioSetupKokoroStatus,
              ready: _kokoroReady,
              l10n: l10n,
              cs: cs,
            ),
            if (_downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Text(
                _downloadPhase,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(fontSize: 12, color: cs.error),
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: _downloading
          ? const []
          : [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, AudioSetupDialogResult.cancelled),
                child: Text(l10n.audioSetupNotNow),
              ),
              if (_whisperRequired
                  ? _whisperReady
                  : _kokoroReady)
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, AudioSetupDialogResult.onDevice),
                  child: Text(l10n.audioSetupContinueButton),
                )
              else ...[
                if (!_whisperRequired)
                  OutlinedButton(
                    onPressed: _useSystemSpeech,
                    child: Text(l10n.audioSetupSystemButton),
                  ),
                FilledButton(
                  onPressed: _downloadOnDeviceModels,
                  child: Text(
                    _whisperRequired
                        ? l10n.voiceSttMacosDownloadWhisper
                        : l10n.audioSetupOnDeviceButton,
                  ),
                ),
              ],
              TextButton(
                onPressed: _openVoiceSettings,
                child: Text(l10n.audioSetupConfigureButton),
              ),
            ],
    );
  }
}
