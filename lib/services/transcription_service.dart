import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/chat_message.dart';
import '../models/transcription_job.dart';
import '../models/transcription_segment.dart';
import '../utils/srt_formatter.dart';
import 'audio_file_loader.dart';
import 'transcription_repository.dart';
import 'whisper_file_transcriber.dart';
import 'whisper_model_manager.dart';

/// Runs file transcriptions and exposes progress to the UI.
class TranscriptionService extends ChangeNotifier {
  TranscriptionService._();
  static final TranscriptionService instance = TranscriptionService._();

  TranscriptionJob? _activeJob;
  TranscriptionJob? get activeJob => _activeJob;

  bool isActiveForConversation(String? conversationId) =>
      _activeJob != null &&
      _activeJob!.conversationId == conversationId &&
      _activeJob!.status == TranscriptionJobStatus.running;

  Future<bool> ensureWhisperReady() async {
    if (await WhisperModelManager.instance.isModelReady()) {
      return await WhisperModelManager.instance.ensureVadModel();
    }
    return false;
  }

  Future<TranscriptionJob> createJob({
    required String sourcePath,
    required TranscriptionOptions options,
    String? conversationId,
  }) async {
    final stored = await AudioFileLoader.instance
        .copyToTranscriptionStorage(sourcePath);
    final now = DateTime.now();
    final job = TranscriptionJob(
      id: now.millisecondsSinceEpoch.toString(),
      title: p.basenameWithoutExtension(sourcePath),
      sourceAudioPath: sourcePath,
      storedAudioPath: stored,
      conversationId: conversationId,
      options: options,
      status: TranscriptionJobStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await TranscriptionRepository.instance.upsert(job);
    return job;
  }

  Future<void> runJob({
    required TranscriptionJob job,
    required Future<void> Function(
      ChatMessage userPlaceholder,
      ChatMessage assistantPlaceholder,
    ) onPlaceholdersReady,
    required Future<void> Function(
      String assistantMessageId,
      String displayMarkdown,
      Map<String, dynamic> conversationPatch,
    ) onComplete,
    required Future<void> Function(String messageId, String content)
        onUpdateAssistant,
  }) async {
    _activeJob = job.copyWith(
      status: TranscriptionJobStatus.running,
      progress: 0.02,
      progressLabel: 'Loading audio…',
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await TranscriptionRepository.instance.upsert(_activeJob!);

    final userPlaceholder = ChatMessage(
      id: '${job.id}_user',
      role: 'user',
      content: 'Audio: ${job.title}',
      timestamp: DateTime.now(),
    );
    final assistantPlaceholder = ChatMessage(
      id: '${job.id}_assistant',
      role: 'assistant',
      content: '_Transcription in progress…_',
      timestamp: DateTime.now(),
    );
    await onPlaceholdersReady(userPlaceholder, assistantPlaceholder);

    try {
      if (!await ensureWhisperReady()) {
        throw Exception(
          'Whisper model is not downloaded. Open Transcription settings to download it.',
        );
      }

      _patchJob(progress: 0.08, label: 'Decoding audio…');
      var samples = await AudioFileLoader.instance
          .load16kMono(job.storedAudioPath ?? job.sourceAudioPath);

      final trimStart = (job.options.trimStartMs * 16).round();
      final trimEnd = job.options.trimEndMs > 0
          ? (job.options.trimEndMs * 16).round()
          : samples.length;
      if (trimStart > 0 || trimEnd < samples.length) {
        final start = trimStart.clamp(0, samples.length);
        final end = trimEnd.clamp(start, samples.length);
        samples = Float32List.sublistView(samples, start, end);
      }

      final durationMs = (samples.length / 16).round();
      _patchJob(progress: 0.15, label: 'Transcribing…', durationMs: durationMs);

      final segments = await WhisperFileTranscriber.instance.transcribeSamples(
        samples: samples,
        language: job.options.language,
        includeTimestamps: job.options.includeTimestamps,
        timestampGranularity: job.options.timestampGranularity,
        onProgress: (p, label) {
          _patchJob(progress: 0.15 + p * 0.8, label: label);
        },
      );

      final plain = SrtFormatter.plainText(segments);
      final srt = job.options.includeTimestamps
          ? SrtFormatter.srt(segments)
          : null;

      final display = _formatDisplayMarkdown(
        job: job,
        segments: segments,
        plain: plain,
        srt: srt,
      );

      final completed = _activeJob!.copyWith(
        status: TranscriptionJobStatus.complete,
        progress: 1,
        progressLabel: 'Complete',
        plainText: plain,
        srtText: srt,
        segments: segments,
        durationMs: durationMs,
        updatedAt: DateTime.now(),
      );
      _activeJob = completed;
      await TranscriptionRepository.instance.upsert(completed);
      notifyListeners();

      await onUpdateAssistant(assistantPlaceholder.id, display);
      await onComplete(
        assistantPlaceholder.id,
        display,
        {
          'transcriptionPlainText': plain,
          if (srt != null) 'transcriptionSrtText': srt,
          'transcriptionJobId': job.id,
          'transcriptionTitle': job.title,
          'transcriptionStatus': 'complete',
          'transcriptionAudioPath':
              job.storedAudioPath ?? job.sourceAudioPath,
          'transcriptionOptions': job.options.toJson(),
          if (durationMs > 0) 'transcriptionDurationMs': durationMs,
        },
      );
    } catch (e, st) {
      debugPrint('TranscriptionService failed: $e\n$st');
      final failed = _activeJob!.copyWith(
        status: TranscriptionJobStatus.failed,
        progress: 0,
        progressLabel: null,
        error: e.toString(),
        updatedAt: DateTime.now(),
      );
      _activeJob = failed;
      await TranscriptionRepository.instance.upsert(failed);
      notifyListeners();
      final failDisplay = '**Transcription failed:** $e';
      await onUpdateAssistant(assistantPlaceholder.id, failDisplay);
      await onComplete(
        assistantPlaceholder.id,
        failDisplay,
        {
          'transcriptionJobId': job.id,
          'transcriptionTitle': job.title,
          'transcriptionStatus': 'failed',
          'transcriptionAudioPath':
              job.storedAudioPath ?? job.sourceAudioPath,
          'transcriptionOptions': job.options.toJson(),
        },
      );
    } finally {
      if (_activeJob?.id == job.id &&
          _activeJob!.status != TranscriptionJobStatus.running) {
        // Keep completed/failed job visible briefly; clear on next start.
      }
    }
  }

  void clearActiveIfDone() {
    if (_activeJob?.isTerminal == true) {
      _activeJob = null;
      notifyListeners();
    }
  }

  void _patchJob({
    required double progress,
    required String label,
    int? durationMs,
  }) {
    if (_activeJob == null) return;
    _activeJob = _activeJob!.copyWith(
      progress: progress,
      progressLabel: label,
      durationMs: durationMs ?? _activeJob!.durationMs,
      updatedAt: DateTime.now(),
    );
    unawaited(TranscriptionRepository.instance.upsert(_activeJob!));
    notifyListeners();
  }

  String _formatDisplayMarkdown({
    required TranscriptionJob job,
    required List<TranscriptionSegment> segments,
    required String plain,
    String? srt,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('## Transcription: ${job.title}');
    if (job.durationMs != null) {
      buffer.writeln(
          '_Duration: ${(job.durationMs! / 1000).toStringAsFixed(1)}s_');
    }
    buffer.writeln();

    if (srt != null && srt.isNotEmpty) {
      buffer.writeln('```srt');
      buffer.writeln(srt);
      buffer.writeln('```');
    } else {
      buffer.writeln(plain);
    }
    return buffer.toString().trim();
  }
}
