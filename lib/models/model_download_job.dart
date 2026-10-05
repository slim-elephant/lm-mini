/// Shared download job types for Kokoro, Whisper, GGUF, and future assets.
enum ModelDownloadJobKind {
  singleFile,
  archive,
  multiFile,
}

enum ModelDownloadJobStatus {
  queued,
  downloading,
  extracting,
  ready,
  failed,
  interrupted,
  cancelled,
}

/// Well-known job ids for bundled audio / STT assets.
abstract final class ModelDownloadJobIds {
  static const kokoro = 'asset:kokoro-en-v0_19';
  static const kokoroMulti = 'asset:kokoro-multi-lang-v1_0';
  static const piperDe = 'asset:vits-piper-de_DE-thorsten-medium-fp16';
  static const piperRu = 'asset:vits-piper-ru_RU-irina-medium-fp16';

  /// Legacy id kept so interrupted tiny downloads still resume.
  static const whisper = whisperTiny;
  static const whisperTiny = 'asset:whisper-tiny';
  static const whisperBase = 'asset:whisper-base';
  static const whisperSmall = 'asset:whisper-small';
  static const whisperMedium = 'asset:whisper-medium';
  static const whisperTurbo = 'asset:whisper-turbo';
  static const whisperLargeV3 = 'asset:whisper-large-v3';
  static const whisperVad = 'asset:whisper-vad';
}

class ModelDownloadJob {
  final String id;
  final String displayName;
  final ModelDownloadJobKind kind;
  final String sourceUrl;

  /// Final file path for [ModelDownloadJobKind.singleFile], or archive
  /// path on disk for [ModelDownloadJobKind.archive].
  final String destPath;

  /// Extraction target directory for archive jobs.
  final String? extractDir;

  ModelDownloadJobStatus status;
  double progress;
  int bytesDownloaded;
  int? bytesTotal;
  int bytesPerSecond;
  String? errorMessage;
  String? completedAt;

  ModelDownloadJob({
    required this.id,
    required this.displayName,
    required this.kind,
    required this.sourceUrl,
    required this.destPath,
    this.extractDir,
    this.status = ModelDownloadJobStatus.queued,
    this.progress = 0,
    this.bytesDownloaded = 0,
    this.bytesTotal,
    this.bytesPerSecond = 0,
    this.errorMessage,
    this.completedAt,
  });

  bool get isActive =>
      status == ModelDownloadJobStatus.queued ||
      status == ModelDownloadJobStatus.downloading ||
      status == ModelDownloadJobStatus.extracting;

  String get partialPath => '$destPath.part';

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'kind': kind.name,
        'sourceUrl': sourceUrl,
        'destPath': destPath,
        'extractDir': extractDir,
        'status': status.name,
        'progress': progress,
        'bytesDownloaded': bytesDownloaded,
        'bytesTotal': bytesTotal,
        'bytesPerSecond': bytesPerSecond,
        'errorMessage': errorMessage,
        'completedAt': completedAt,
      };

  factory ModelDownloadJob.fromJson(Map<String, dynamic> json) {
    return ModelDownloadJob(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? json['id'] as String,
      kind: ModelDownloadJobKind.values.firstWhere(
        (k) => k.name == (json['kind'] as String? ?? 'singleFile'),
        orElse: () => ModelDownloadJobKind.singleFile,
      ),
      sourceUrl: json['sourceUrl'] as String,
      destPath: json['destPath'] as String,
      extractDir: json['extractDir'] as String?,
      status: ModelDownloadJobStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'queued'),
        orElse: () => ModelDownloadJobStatus.queued,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      bytesDownloaded: json['bytesDownloaded'] as int? ?? 0,
      bytesTotal: json['bytesTotal'] as int?,
      bytesPerSecond: json['bytesPerSecond'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }
}
