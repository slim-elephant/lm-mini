import 'dart:convert';

import 'transcription_segment.dart';

enum TranscriptionJobStatus {
  pending,
  running,
  complete,
  failed,
}

/// User-facing options for a transcription run.
class TranscriptionOptions {
  final bool includeTimestamps;
  /// `phrase` is supported today; `word` reserved for a future upgrade.
  final String timestampGranularity;
  final String language;
  final double trimStartMs;
  final double trimEndMs;

  const TranscriptionOptions({
    this.includeTimestamps = true,
    this.timestampGranularity = 'phrase',
    this.language = 'en',
    this.trimStartMs = 0,
    this.trimEndMs = 0,
  });

  Map<String, dynamic> toJson() => {
        'includeTimestamps': includeTimestamps,
        'timestampGranularity': timestampGranularity,
        'language': language,
        'trimStartMs': trimStartMs,
        'trimEndMs': trimEndMs,
      };

  factory TranscriptionOptions.fromJson(Map<String, dynamic> json) {
    return TranscriptionOptions(
      includeTimestamps: json['includeTimestamps'] as bool? ?? true,
      timestampGranularity:
          json['timestampGranularity'] as String? ?? 'phrase',
      language: json['language'] as String? ?? 'en',
      trimStartMs: (json['trimStartMs'] as num?)?.toDouble() ?? 0,
      trimEndMs: (json['trimEndMs'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Persisted transcription record + in-flight progress.
class TranscriptionJob {
  final String id;
  final String title;
  final String sourceAudioPath;
  final String? storedAudioPath;
  final String? conversationId;
  final TranscriptionOptions options;
  final TranscriptionJobStatus status;
  final double progress;
  final String? progressLabel;
  final String? plainText;
  final String? srtText;
  final List<TranscriptionSegment> segments;
  final int? durationMs;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TranscriptionJob({
    required this.id,
    required this.title,
    required this.sourceAudioPath,
    this.storedAudioPath,
    this.conversationId,
    required this.options,
    this.status = TranscriptionJobStatus.pending,
    this.progress = 0,
    this.progressLabel,
    this.plainText,
    this.srtText,
    this.segments = const [],
    this.durationMs,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTerminal =>
      status == TranscriptionJobStatus.complete ||
      status == TranscriptionJobStatus.failed;

  TranscriptionJob copyWith({
    String? title,
    String? storedAudioPath,
    String? conversationId,
    TranscriptionOptions? options,
    TranscriptionJobStatus? status,
    double? progress,
    String? progressLabel,
    String? plainText,
    String? srtText,
    List<TranscriptionSegment>? segments,
    int? durationMs,
    String? error,
    DateTime? updatedAt,
  }) {
    return TranscriptionJob(
      id: id,
      title: title ?? this.title,
      sourceAudioPath: sourceAudioPath,
      storedAudioPath: storedAudioPath ?? this.storedAudioPath,
      conversationId: conversationId ?? this.conversationId,
      options: options ?? this.options,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      progressLabel: progressLabel ?? this.progressLabel,
      plainText: plainText ?? this.plainText,
      srtText: srtText ?? this.srtText,
      segments: segments ?? this.segments,
      durationMs: durationMs ?? this.durationMs,
      error: error ?? this.error,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDbRow() => {
        'id': id,
        'title': title,
        'source_audio_path': sourceAudioPath,
        'stored_audio_path': storedAudioPath,
        'conversation_id': conversationId,
        'options_json': jsonEncode(options.toJson()),
        'status': status.name,
        'progress': progress,
        'progress_label': progressLabel,
        'plain_text': plainText,
        'srt_text': srtText,
        'segments_json': jsonEncode(segments.map((s) => s.toJson()).toList()),
        'duration_ms': durationMs,
        'error': error,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory TranscriptionJob.fromDbRow(Map<String, dynamic> row) {
    final segmentsRaw = row['segments_json'] as String?;
    List<TranscriptionSegment> segments = const [];
    if (segmentsRaw != null && segmentsRaw.isNotEmpty) {
      final list = jsonDecode(segmentsRaw) as List<dynamic>;
      segments = list
          .map((e) => TranscriptionSegment.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    final optionsRaw = row['options_json'] as String? ?? '{}';
    return TranscriptionJob(
      id: row['id'] as String,
      title: row['title'] as String,
      sourceAudioPath: row['source_audio_path'] as String,
      storedAudioPath: row['stored_audio_path'] as String?,
      conversationId: row['conversation_id'] as String?,
      options: TranscriptionOptions.fromJson(
        Map<String, dynamic>.from(jsonDecode(optionsRaw) as Map),
      ),
      status: TranscriptionJobStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => TranscriptionJobStatus.pending,
      ),
      progress: (row['progress'] as num?)?.toDouble() ?? 0,
      progressLabel: row['progress_label'] as String?,
      plainText: row['plain_text'] as String?,
      srtText: row['srt_text'] as String?,
      segments: segments,
      durationMs: (row['duration_ms'] as num?)?.toInt(),
      error: row['error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
