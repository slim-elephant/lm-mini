import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/transcription_job.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/chat_screen.dart';
import '../services/transcription_repository.dart';
import '../services/transcription_service.dart';
import '../services/whisper_model_manager.dart';
import '../utils/layout_utils.dart';
import '../utils/srt_formatter.dart';
import '../utils/share_helper.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';

class TranscriptionSettingsScreen extends StatefulWidget {
  final bool embedded;
  const TranscriptionSettingsScreen({super.key, this.embedded = false});

  @override
  State<TranscriptionSettingsScreen> createState() =>
      _TranscriptionSettingsScreenState();
}

class _TranscriptionSettingsScreenState
    extends State<TranscriptionSettingsScreen> {
  final WhisperModelManager _whisper = WhisperModelManager.instance;
  Map<String, bool> _readyById = {};
  bool _downloading = false;
  double _progress = 0;
  String? _error;
  List<TranscriptionJob> _jobs = [];
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    TranscriptionService.instance.addListener(_onServiceUpdate);
    _refresh();
  }

  @override
  void dispose() {
    TranscriptionService.instance.removeListener(_onServiceUpdate);
    _progressSub?.cancel();
    super.dispose();
  }

  void _onServiceUpdate() {
    final active = TranscriptionService.instance.activeJob;
    if (active == null) return;
    final idx = _jobs.indexWhere((j) => j.id == active.id);
    if (idx >= 0) {
      _jobs[idx] = active;
    } else {
      _jobs.insert(0, active);
    }
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>().settings;
    _whisper.setSelectedModelId(settings.whisperModelId);
    final readyMap = <String, bool>{};
    for (final spec in WhisperModelManager.catalog) {
      readyMap[spec.id] = await _whisper.isModelReady(spec.id);
    }
    _jobs = await TranscriptionRepository.instance.listAll();
    if (!mounted) return;
    setState(() {
      _readyById = readyMap;
    });
  }

  Future<void> _selectModel(String id) async {
    if (!mounted) return;
    await context.read<SettingsProvider>().updateWhisperModelId(id);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _downloadWhisper([String? modelId]) async {
    if (!mounted) return;
    final id =
        modelId ?? context.read<SettingsProvider>().settings.whisperModelId;
    await context.read<SettingsProvider>().updateWhisperModelId(id);

    if (!mounted) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    _progressSub?.cancel();
    _progressSub = _whisper.progressStream.listen((p) {
      if (mounted) setState(() => _progress = p);
    });
    final ok = await _whisper.downloadModel(id);
    await _whisper.ensureVadModel();
    _progressSub?.cancel();
    if (!mounted) return;
    setState(() {
      _downloading = false;
      if (!ok) _error = _whisper.error ?? 'Download failed';
    });
    await _refresh();
  }

  void _showAccuracyInfo() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.voiceWhisperBiggerBetterTitle),
        content: Text(l10n.voiceWhisperBiggerBetterBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _openJob(TranscriptionJob job) async {
    if (job.conversationId == null) return;
    final chat = context.read<ChatProvider>();
    await chat.selectConversation(job.conversationId!);
    if (!mounted) return;
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: job.conversationId),
      ),
    );
  }

  Future<void> _sharePlain(TranscriptionJob job) async {
    final text = job.plainText ?? '';
    if (text.isEmpty) return;
    await shareTextFromContext(context, text, subject: job.title);
  }

  Future<void> _shareSrt(TranscriptionJob job) async {
    final srt = job.srtText ??
        (job.segments.isNotEmpty ? SrtFormatter.srt(job.segments) : '');
    if (srt.isEmpty) return;
    await shareTextFromContext(context, srt, subject: '${job.title}.srt');
  }

  Future<void> _copyPlain(TranscriptionJob job) async {
    final text = job.plainText ?? '';
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transcript copied')),
    );
  }

  /// Friendlier quality label than raw model names.
  String _qualityLabel(WhisperModelSpec spec) {
    return switch (spec.id) {
      'tiny' => 'Fastest',
      'base' => 'Balanced',
      'small' => 'Accurate',
      'medium' => 'Very accurate',
      'turbo' => 'Best quality',
      'large-v3' => 'Maximum accuracy',
      _ => spec.displayName,
    };
  }

  String _qualityHint(WhisperModelSpec spec) {
    return switch (spec.id) {
      'tiny' => 'Quick results for short, clear audio',
      'base' => 'Good everyday pick — recommended',
      'small' => 'Better with accents, quiet audio, and longer clips',
      'medium' => 'High accuracy — needs more storage',
      'turbo' => 'Top quality without the full Large download',
      'large-v3' => 'Highest accuracy — slowest and heaviest',
      _ => spec.description,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>().settings;
    final selectedId = settings.whisperModelId;
    final selectedReady = _readyById[selectedId] ?? false;
    final selectedSpec = WhisperModelManager.byId(selectedId);

    return GlassSettingsScaffold(
      embedded: widget.embedded,
      title: l10n.transcription,
      body: Builder(
        builder: (context) {
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
                  'Turn voice memos and audio files into text — privately, on your device.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // ── Status hero ──────────────────────────────────────────
                GlassSettingsCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GlassSettingsIcon(
                        selectedReady
                            ? Icons.graphic_eq_rounded
                            : Icons.download_for_offline_outlined,
                        color: selectedReady
                            ? const Color(0xFF10B981)
                            : cs.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedReady
                                  ? 'Ready to transcribe'
                                  : 'Download a model',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedReady
                                  ? '${_qualityLabel(selectedSpec ?? WhisperModelManager.catalog.first)} · ${selectedSpec?.sizeLabel ?? ''}'
                                  : 'Pick a quality below, then download once.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Accuracy picker ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _sectionLabel(context, 'Accuracy')),
                    TextButton.icon(
                      onPressed: _showAccuracyInfo,
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Help'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Bigger models hear better but take more space. Start with Balanced.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                GlassSettingsCard(
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < WhisperModelManager.catalog.length;
                          i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 66,
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                          ),
                        _modelRow(
                          context,
                          WhisperModelManager.catalog[i],
                          selectedId: selectedId,
                          ready:
                              _readyById[WhisperModelManager.catalog[i].id] ==
                                  true,
                        ),
                      ],
                      if (_downloading || !selectedReady || _error != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_downloading) ...[
                                LinearProgressIndicator(
                                  value: _progress > 0 ? _progress : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _progress >= 0.85
                                      ? 'Finishing up… ${(_progress * 100).toStringAsFixed(0)}%'
                                      : _progress > 0
                                          ? 'Downloading… ${(_progress * 100).toStringAsFixed(0)}%'
                                          : 'Starting download…',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ] else if (!selectedReady)
                                FilledButton.icon(
                                  onPressed: () => _downloadWhisper(selectedId),
                                  icon: const Icon(Icons.download_rounded),
                                  label: Text(
                                    'Download ${_qualityLabel(selectedSpec ?? WhisperModelManager.catalog.first)}',
                                  ),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(_error!,
                                    style: TextStyle(color: cs.error)),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── History ──────────────────────────────────────────────
                _sectionLabel(context, 'Your transcripts'),
                const SizedBox(height: 10),
                if (_jobs.isEmpty)
                  GlassSettingsCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GlassSettingsIcon(Icons.mic_none_rounded,
                            color: cs.onSurfaceVariant),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Nothing yet. Use Transcribe audio from a chat to get started.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._jobs.map((job) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _jobCard(job),
                      )),
              ],
            ),
          );
        },
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

  Widget _modelRow(
    BuildContext context,
    WhisperModelSpec spec, {
    required String selectedId,
    required bool ready,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selected = selectedId == spec.id;
    final isRecommended = spec.id == 'base';

    final titleLabel = isRecommended
        ? '${_qualityLabel(spec)} · Recommended'
        : _qualityLabel(spec);
    final subtitle =
        '${_qualityHint(spec)} · ${spec.sizeLabel}${ready ? ' · Downloaded' : ''}';

    if (useDesktopSettingsControls(context)) {
      return DesktopPreferenceRow(
        title: titleLabel,
        subtitle: subtitle,
        onTap: _downloading ? null : () => _selectModel(spec.id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: spec.id,
              groupValue: selectedId,
              onChanged: _downloading
                  ? null
                  : (v) {
                      if (v != null) _selectModel(v);
                    },
            ),
            if (ready)
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 22)
            else
              IconButton(
                tooltip: 'Download',
                icon: Icon(Icons.download_rounded, color: cs.primary),
                onPressed:
                    _downloading ? null : () => _downloadWhisper(spec.id),
              ),
          ],
        ),
      );
    }

    return ListTile(
      onTap: _downloading ? null : () => _selectModel(spec.id),
      leading: Radio<String>(
        value: spec.id,
        groupValue: selectedId,
        onChanged: _downloading
            ? null
            : (v) {
                if (v != null) _selectModel(v);
              },
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              _qualityLabel(spec),
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          if (isRecommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Recommended',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
      trailing: ready
          ? Icon(Icons.check_circle_rounded,
              color: Colors.green.shade600, size: 22)
          : IconButton(
              tooltip: 'Download',
              icon: Icon(Icons.download_rounded, color: cs.primary),
              onPressed: _downloading ? null : () => _downloadWhisper(spec.id),
            ),
    );
  }

  Widget _jobCard(TranscriptionJob job) {
    final cs = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String statusLabel) =
        switch (job.status) {
      TranscriptionJobStatus.running => (
          Icons.hourglass_top_rounded,
          cs.primary,
          job.progressLabel ?? 'Transcribing…',
        ),
      TranscriptionJobStatus.complete => (
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
          'Complete',
        ),
      TranscriptionJobStatus.failed => (
          Icons.error_outline_rounded,
          cs.error,
          'Failed',
        ),
      TranscriptionJobStatus.pending => (
          Icons.schedule_rounded,
          cs.onSurfaceVariant,
          'Pending',
        ),
    };

    return GlassSettingsCard(
      child: ListTile(
        leading: GlassSettingsIcon(icon, color: color),
        title: Text(job.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusLabel),
            if (job.status == TranscriptionJobStatus.running)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: job.progress,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        onTap: job.conversationId != null ? () => _openJob(job) : null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'copy':
                await _copyPlain(job);
              case 'share':
                await _sharePlain(job);
              case 'srt':
                await _shareSrt(job);
              case 'delete':
                await TranscriptionRepository.instance.delete(job.id);
                final path = job.storedAudioPath;
                if (path != null) {
                  try {
                    final f = File(path);
                    if (f.existsSync()) f.deleteSync();
                  } catch (_) {}
                }
                if (!mounted) return;
                await _refresh();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'copy', child: Text('Copy text')),
            const PopupMenuItem(value: 'share', child: Text('Share text')),
            if (job.srtText != null || job.segments.isNotEmpty)
              const PopupMenuItem(
                  value: 'srt', child: Text('Export subtitles (SRT)')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
