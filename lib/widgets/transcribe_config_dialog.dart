import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import '../models/transcription_job.dart';
import '../services/transcription_preferences.dart';
import '../utils/file_picker_path_error.dart';
import '../utils/whisper_languages.dart';

/// Result returned when the user confirms transcribe settings.
class TranscribeConfigResult {
  final String path;
  final TranscriptionOptions options;
  const TranscribeConfigResult({required this.path, required this.options});
}

/// Transcription setup shown as a dialog over the current chat.
class TranscribeConfigDialog extends StatefulWidget {
  const TranscribeConfigDialog({super.key});

  static Future<TranscribeConfigResult?> show(BuildContext context) {
    return showDialog<TranscribeConfigResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const TranscribeConfigDialog(),
    );
  }

  @override
  State<TranscribeConfigDialog> createState() => _TranscribeConfigDialogState();
}

class _TranscribeConfigDialogState extends State<TranscribeConfigDialog> {
  String? _filePath;
  bool _includeTimestamps = true;
  String _granularity = 'phrase';
  String _language = 'auto';
  double _durationMs = 0;
  double _trimStartMs = 0;
  double _trimEndMs = 0;
  bool _loadingDuration = false;
  bool _previewPlaying = false;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration>? _positionSub;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _playerSub = _player.playerStateStream.listen((state) {
      final playing =
          state.playing && state.processingState != ProcessingState.completed;
      if (mounted && playing != _previewPlaying) {
        setState(() => _previewPlaying = playing);
      }
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _previewPlaying = false);
      }
    });
    _positionSub = _player.positionStream.listen((pos) {
      if (!_previewPlaying) return;
      final end = _trimEndMs > 0 ? _trimEndMs : _durationMs;
      if (end > 0 && pos.inMilliseconds >= end.round()) {
        _player.pause();
        if (mounted) setState(() => _previewPlaying = false);
      }
    });
  }

  Future<void> _loadPrefs() async {
    final ts = await TranscriptionPreferences.includeTimestamps();
    final gran = await TranscriptionPreferences.timestampGranularity();
    final lang = await TranscriptionPreferences.language();
    if (!mounted) return;
    setState(() {
      _includeTimestamps = ts;
      _granularity = gran;
      _language = lang;
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result;
    try {
      // `FileType.audio` uses Android's audio/* picker so MediaStore recordings
      // copy into cache. Custom MIME filters often pick Drive/Recents URIs
      // that throw `unknown_path`.
      result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: true,
      );
    } on PlatformException catch (e) {
      debugPrint('⚠️ File picker: $e');
      if (mounted && FilePickerPathError.matches(e)) {
        _showPickerFailed();
      }
      return;
    } catch (e) {
      debugPrint('⚠️ File picker: $e');
      if (mounted && FilePickerPathError.matches(e)) {
        _showPickerFailed();
      }
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final path = await _localPathFor(picked);
    if (path == null) {
      if (mounted) _showPickerFailed();
      return;
    }
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _filePath = path;
      _loadingDuration = true;
      _trimStartMs = 0;
      _trimEndMs = 0;
      _previewPlaying = false;
    });
    try {
      await _player.setFilePath(path);
      final d = _player.duration?.inMilliseconds.toDouble() ?? 0;
      if (!mounted) return;
      setState(() {
        _durationMs = d;
        _trimEndMs = d;
        _loadingDuration = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDuration = false);
    }
  }

  void _showPickerFailed() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.filePickerCouldNotCopy)),
    );
  }

  Future<String?> _localPathFor(PlatformFile file) async {
    final existing = file.path;
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    final dir = await Directory.systemTemp.createTemp('lmmini_audio_');
    final name = file.name.trim().isEmpty ? 'audio.bin' : file.name;
    final dest = File(p.join(dir.path, p.basename(name)));
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  Future<void> _togglePreview() async {
    if (_filePath == null) return;
    if (_previewPlaying) {
      await _player.pause();
      setState(() => _previewPlaying = false);
      return;
    }
    await _player.setFilePath(_filePath!);
    await _player.seek(Duration(milliseconds: _trimStartMs.round()));
    await _player.play();
    setState(() => _previewPlaying = true);
  }

  Future<void> _seekPreviewToTrimStart() async {
    if (!_previewPlaying || _filePath == null) return;
    await _player.seek(Duration(milliseconds: _trimStartMs.round()));
    if (!_player.playing) await _player.play();
  }

  void _onTrimChanged(RangeValues v) {
    final startMoved = v.start != _trimStartMs;
    setState(() {
      _trimStartMs = v.start;
      _trimEndMs = v.end;
    });
    if (startMoved && _previewPlaying) {
      _seekPreviewToTrimStart();
    }
  }

  Future<void> _pickLanguage() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => _LanguageSearchDialog(selected: _language),
    );
    if (picked != null) setState(() => _language = picked);
  }

  Future<void> _start() async {
    if (_filePath == null) return;
    await _player.stop();
    await TranscriptionPreferences.setIncludeTimestamps(_includeTimestamps);
    await TranscriptionPreferences.setTimestampGranularity(_granularity);
    await TranscriptionPreferences.setLanguage(_language);

    if (!mounted) return;
    Navigator.pop(
      context,
      TranscribeConfigResult(
        path: _filePath!,
        options: TranscriptionOptions(
          includeTimestamps: _includeTimestamps,
          timestampGranularity: _granularity,
          language: _language,
          trimStartMs: _trimStartMs,
          trimEndMs: _trimEndMs > 0 ? _trimEndMs : _durationMs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final langLabel = WhisperLanguage.findByCode(_language)?.name ?? _language;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.transcribe_rounded),
          const SizedBox(width: 10),
          Text(l10n.transcribeAudio),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(Icons.audio_file_rounded, color: cs.primary),
                  title: Text(
                    _filePath == null
                        ? 'Choose audio file'
                        : p.basename(_filePath!),
                  ),
                  subtitle: Text(
                    _filePath == null
                        ? 'WAV, MP3, M4A, AAC, CAF, FLAC…'
                        : _durationMs > 0
                            ? 'Duration: ${(_durationMs / 1000).toStringAsFixed(1)}s'
                            : 'Tap to change file',
                  ),
                  trailing: const Icon(Icons.folder_open),
                  onTap: _pickFile,
                ),
              ),
              if (_filePath != null && _durationMs > 0) ...[
                const SizedBox(height: 12),
                Text(l10n.trimSection,
                    style: Theme.of(context).textTheme.titleSmall),
                RangeSlider(
                  values: RangeValues(_trimStartMs, _trimEndMs),
                  min: 0,
                  max: _durationMs,
                  onChanged: _onTrimChanged,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatMs(_trimStartMs)),
                    Text(_formatMs(_trimEndMs)),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _togglePreview,
                    icon: Icon(_previewPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(_previewPlaying
                        ? 'Pause preview'
                        : 'Preview selection'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.includeTimestamps),
                subtitle: Text(_granularity == 'word'
                    ? 'Word-level timing for subtitles'
                    : 'Phrase-level timing for subtitles'),
                value: _includeTimestamps,
                onChanged: (v) => setState(() => _includeTimestamps = v),
              ),
              if (_includeTimestamps)
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'phrase', label: Text(l10n.phrasesLabel)),
                    ButtonSegment(value: 'word', label: Text(l10n.wordsLabel)),
                  ],
                  selected: {_granularity},
                  onSelectionChanged: (s) =>
                      setState(() => _granularity = s.first),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.language),
                subtitle: Text(langLabel),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickLanguage,
              ),
              if (!Platform.isIOS && !Platform.isAndroid && !Platform.isMacOS)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Non-WAV formats require iOS, Android, or macOS for '
                    'conversion. Use .wav on other desktop platforms.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _filePath == null || _loadingDuration ? null : _start,
          icon: const Icon(Icons.transcribe_rounded),
          label: Text(l10n.transcribe),
        ),
      ],
    );
  }

  String _formatMs(double ms) {
    final s = (ms / 1000).floor();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}

class _LanguageSearchDialog extends StatefulWidget {
  final String selected;
  const _LanguageSearchDialog({required this.selected});

  @override
  State<_LanguageSearchDialog> createState() => _LanguageSearchDialogState();
}

class _LanguageSearchDialogState extends State<_LanguageSearchDialog> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _query.toLowerCase();
    final filtered = WhisperLanguage.all.where((lang) {
      if (q.isEmpty) return true;
      return lang.name.toLowerCase().contains(q) ||
          lang.code.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      title: Text(l10n.transcriptionLanguage),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.searchLanguages,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final lang = filtered[i];
                  return RadioListTile<String>(
                    value: lang.code,
                    groupValue: widget.selected,
                    title: Text(lang.name),
                    subtitle: lang.code == 'auto'
                        ? null
                        : Text(lang.code.toUpperCase()),
                    onChanged: (v) => Navigator.pop(context, v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
