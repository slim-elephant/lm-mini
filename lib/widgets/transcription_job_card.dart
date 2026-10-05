import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import '../models/transcription_job.dart';
import '../services/transcription_repository.dart';
import '../services/transcription_service.dart';
import '../utils/whisper_languages.dart';

/// Compact “job done by the app” card for a transcription user message:
/// thin audio player + chips for subtitles / trim / granularity.
class TranscriptionJobCard extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic>? conversationSettings;
  final Color textColor;

  const TranscriptionJobCard({
    super.key,
    required this.jobId,
    required this.textColor,
    this.conversationSettings,
  });

  @override
  State<TranscriptionJobCard> createState() => _TranscriptionJobCardState();
}

class _TranscriptionJobCardState extends State<TranscriptionJobCard> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration>? _positionSub;

  String _title = 'Audio';
  String? _audioPath;
  TranscriptionOptions _options = const TranscriptionOptions();
  String _status = 'running';
  int? _durationMs;
  bool _loading = true;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    TranscriptionService.instance.addListener(_onServiceUpdate);
    _playerSub = _player.playerStateStream.listen((state) {
      final playing = state.playing &&
          state.processingState != ProcessingState.completed;
      if (!mounted) return;
      if (playing != _playing) setState(() => _playing = playing);
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
        unawaited(_player.seek(Duration(milliseconds: _trimStartMs.round())));
      }
    });
    _positionSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
      final end = _effectiveTrimEndMs;
      if (_playing && end > 0 && pos.inMilliseconds >= end.round()) {
        unawaited(_player.pause());
        unawaited(_player.seek(Duration(milliseconds: _trimStartMs.round())));
        setState(() => _playing = false);
      }
    });
    unawaited(_loadMeta());
  }

  @override
  void didUpdateWidget(covariant TranscriptionJobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId != widget.jobId ||
        oldWidget.conversationSettings != widget.conversationSettings) {
      unawaited(_loadMeta());
    }
  }

  @override
  void dispose() {
    TranscriptionService.instance.removeListener(_onServiceUpdate);
    _playerSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    final job = TranscriptionService.instance.activeJob;
    if (job == null || job.id != widget.jobId) return;
    if (!mounted) return;
    setState(() {
      _status = job.status.name;
      _title = job.title;
      _options = job.options;
      _audioPath ??= job.storedAudioPath ?? job.sourceAudioPath;
      if (job.durationMs != null) _durationMs = job.durationMs;
    });
  }

  Map<String, dynamic>? _entryFromSettings() {
    final raw = widget.conversationSettings?['transcriptions'];
    if (raw is! List) return null;
    for (final e in raw) {
      if (e is Map && e['jobId']?.toString() == widget.jobId) {
        return Map<String, dynamic>.from(e);
      }
    }
    return null;
  }

  Future<void> _loadMeta() async {
    final entry = _entryFromSettings();
    TranscriptionJob? job;
    try {
      job = await TranscriptionRepository.instance.getById(widget.jobId);
    } catch (_) {}

    final active = TranscriptionService.instance.activeJob;
    final live = active?.id == widget.jobId ? active : null;

    final optsJson = entry?['options'];
    final options = live?.options ??
        job?.options ??
        (optsJson is Map
            ? TranscriptionOptions.fromJson(Map<String, dynamic>.from(optsJson))
            : const TranscriptionOptions());

    final path = live?.storedAudioPath ??
        live?.sourceAudioPath ??
        job?.storedAudioPath ??
        job?.sourceAudioPath ??
        entry?['audioPath']?.toString();

    final title = live?.title ??
        job?.title ??
        entry?['title']?.toString() ??
        (path != null ? p.basenameWithoutExtension(path) : 'Audio');

    final status = live?.status.name ??
        job?.status.name ??
        entry?['status']?.toString() ??
        'complete';

    final durationMs = live?.durationMs ??
        job?.durationMs ??
        (entry?['durationMs'] as num?)?.toInt();

    if (!mounted) return;
    setState(() {
      _title = title;
      _audioPath = path;
      _options = options;
      _status = status;
      _durationMs = durationMs;
      _loading = false;
    });

    if (path != null && path.isNotEmpty && await File(path).exists()) {
      try {
        final total = await _player.setFilePath(path);
        if (!mounted) return;
        setState(() {
          _total = total ?? Duration.zero;
          if (_durationMs == null && _total.inMilliseconds > 0) {
            _durationMs = _total.inMilliseconds;
          }
        });
        final start = _trimStartMs.round();
        if (start > 0) {
          await _player.seek(Duration(milliseconds: start));
        }
      } catch (_) {
        // Playback optional — card still shows job meta.
      }
    }
  }

  double get _trimStartMs => _options.trimStartMs;

  double get _effectiveTrimEndMs {
    if (_options.trimEndMs > 0) return _options.trimEndMs;
    final d = _durationMs?.toDouble() ?? _total.inMilliseconds.toDouble();
    return d;
  }

  bool get _isTrimmed {
    final end = _options.trimEndMs;
    return _options.trimStartMs > 0 || (end > 0 && end < (_durationMs ?? end));
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    final start = _trimStartMs.round();
    final pos = _position.inMilliseconds;
    final end = _effectiveTrimEndMs.round();
    if (pos < start || (end > 0 && pos >= end)) {
      await _player.seek(Duration(milliseconds: start));
    }
    await _player.play();
  }

  String _formatMs(num ms) {
    final totalSec = (ms / 1000).floor().clamp(0, 999999);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = widget.textColor.withValues(alpha: 0.72);
    final chipBg = widget.textColor.withValues(alpha: 0.12);
    final activeJob = TranscriptionService.instance.activeJob;
    final showProgress = activeJob?.id == widget.jobId &&
        activeJob!.status == TranscriptionJobStatus.running;

    final lang = WhisperLanguage.all
        .where((l) => l.code == _options.language)
        .map((l) => l.name)
        .firstOrNull;
    final langLabel = (_options.language == 'auto')
        ? (lang ?? 'Auto')
        : (lang ?? _options.language.toUpperCase());

    final granularityLabel = _options.timestampGranularity == 'word'
        ? l10n.wordsLabel
        : l10n.phrasesLabel;

    final trimLabel = _isTrimmed
        ? '${_formatMs(_trimStartMs)} – ${_formatMs(_effectiveTrimEndMs)}'
        : l10n.transcriptionFullClip;

    final statusLabel = switch (_status) {
      'running' || 'pending' => l10n.transcriptionJobRunning,
      'failed' => l10n.transcriptionJobFailed,
      _ => l10n.transcriptionJobDone,
    };

    final displayPos = _playing || _position.inMilliseconds > 0
        ? _position.inMilliseconds
        : _trimStartMs;
    final displayTotal = _effectiveTrimEndMs > 0
        ? _effectiveTrimEndMs
        : (_total.inMilliseconds > 0
            ? _total.inMilliseconds.toDouble()
            : (_durationMs?.toDouble() ?? 0));

    return ListenableBuilder(
      listenable: TranscriptionService.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusLabel,
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            // Thin audio player
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: widget.textColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.textColor.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _audioPath == null ? null : _togglePlay,
                    borderRadius: BorderRadius.circular(16),
                    child: Icon(
                      _playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: widget.textColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loading ? '…' : _title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: () {
                              final span = displayTotal - _trimStartMs;
                              if (span <= 0) return 0.0;
                              return ((displayPos - _trimStartMs) / span)
                                  .clamp(0.0, 1.0);
                            }(),
                            backgroundColor:
                                widget.textColor.withValues(alpha: 0.15),
                            color: widget.textColor.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatMs(displayPos)} / ${_formatMs(displayTotal)}',
                          style: TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MetaChip(
                  label: _options.includeTimestamps
                      ? l10n.transcriptionSubtitlesOn
                      : l10n.transcriptionSubtitlesOff,
                  textColor: widget.textColor,
                  background: chipBg,
                ),
                if (_options.includeTimestamps)
                  _MetaChip(
                    label: granularityLabel,
                    textColor: widget.textColor,
                    background: chipBg,
                  ),
                _MetaChip(
                  label: trimLabel,
                  textColor: widget.textColor,
                  background: chipBg,
                ),
                _MetaChip(
                  label: langLabel,
                  textColor: widget.textColor,
                  background: chipBg,
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 10),
              Text(
                activeJob.progressLabel ?? l10n.transcriptionJobRunning,
                style: TextStyle(color: muted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: activeJob.progress.clamp(0.0, 1.0),
                  backgroundColor: widget.textColor.withValues(alpha: 0.15),
                  color: widget.textColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color background;

  const _MetaChip({
    required this.label,
    required this.textColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
