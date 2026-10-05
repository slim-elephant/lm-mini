import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/model_download_job.dart';
import 'model_download_service.dart';

/// A sherpa-onnx Whisper multilingual package the user can download.
class WhisperModelSpec {
  final String id;
  final String displayName;
  final String description;
  final String sizeLabel;
  final String dirName;
  final String downloadUrl;
  final String jobId;

  const WhisperModelSpec({
    required this.id,
    required this.displayName,
    required this.description,
    required this.sizeLabel,
    required this.dirName,
    required this.downloadUrl,
    required this.jobId,
  });
}

/// Downloads and extracts sherpa-onnx Whisper multilingual models.
///
/// Models: https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models
class WhisperModelManager {
  WhisperModelManager._();
  static final WhisperModelManager instance = WhisperModelManager._();

  static const String defaultModelId = 'tiny';

  static const List<WhisperModelSpec> catalog = [
    WhisperModelSpec(
      id: 'tiny',
      displayName: 'Tiny',
      description: 'Fastest · lightest · good for short clear speech',
      sizeLabel: '~110 MB',
      dirName: 'sherpa-onnx-whisper-tiny',
      downloadUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-tiny.tar.bz2',
      jobId: ModelDownloadJobIds.whisperTiny,
    ),
    WhisperModelSpec(
      id: 'base',
      displayName: 'Base',
      description: 'Better accuracy · still quick on most phones',
      sizeLabel: '~200 MB',
      dirName: 'sherpa-onnx-whisper-base',
      downloadUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-base.tar.bz2',
      jobId: ModelDownloadJobIds.whisperBase,
    ),
    WhisperModelSpec(
      id: 'small',
      displayName: 'Small',
      description: 'Stronger on accents, quiet audio, and longer files',
      sizeLabel: '~610 MB',
      dirName: 'sherpa-onnx-whisper-small',
      downloadUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-small.tar.bz2',
      jobId: ModelDownloadJobIds.whisperSmall,
    ),
    WhisperModelSpec(
      id: 'medium',
      displayName: 'Medium',
      description: 'High accuracy · heavier than Small',
      sizeLabel: '~1.8 GB',
      dirName: 'sherpa-onnx-whisper-medium',
      downloadUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-medium.tar.bz2',
      jobId: ModelDownloadJobIds.whisperMedium,
    ),
    WhisperModelSpec(
      id: 'turbo',
      displayName: 'Large v3 Turbo',
      description:
          'Best big-model pick · much faster/smaller than full Large v3',
      sizeLabel: '~800 MB',
      dirName: 'sherpa-onnx-whisper-turbo',
      downloadUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-turbo.tar.bz2',
      jobId: ModelDownloadJobIds.whisperTurbo,
    ),
    WhisperModelSpec(
      id: 'large-v3',
      displayName: 'Large v3',
      description: 'Highest accuracy · slowest · needs the most storage & RAM',
      sizeLabel: '~3 GB',
      dirName: 'sherpa-onnx-whisper-large-v3',
      downloadUrl:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-large-v3.tar.bz2',
      jobId: ModelDownloadJobIds.whisperLargeV3,
    ),
  ];

  static const String vadModelFileName = 'silero_vad.onnx';
  static const String vadDownloadUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx';

  String _selectedModelId = defaultModelId;
  String? _error;

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  String get selectedModelId => _selectedModelId;

  WhisperModelSpec get selectedSpec =>
      byId(_selectedModelId) ?? catalog.first;

  static WhisperModelSpec? byId(String id) {
    for (final s in catalog) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Keep in sync with [AppSettings.whisperModelId].
  void setSelectedModelId(String id) {
    final spec = byId(id);
    _selectedModelId = spec?.id ?? defaultModelId;
  }

  bool get isDownloading =>
      ModelDownloadService.instance.isJobActive(selectedSpec.jobId);

  bool isDownloadingSpec(WhisperModelSpec spec) =>
      ModelDownloadService.instance.isJobActive(spec.jobId);

  double get downloadProgress =>
      ModelDownloadService.instance.job(selectedSpec.jobId)?.progress ?? 0;

  double downloadProgressFor(WhisperModelSpec spec) =>
      ModelDownloadService.instance.job(spec.jobId)?.progress ?? 0;

  String? get error => _error;
  Stream<double> get progressStream => _progressController.stream;

  Future<bool> isModelReady([String? modelId]) async {
    final paths = await resolveModelPaths(modelId);
    return paths != null;
  }

  /// Returns [preferredId] (or the current selection) when that model is on
  /// disk; otherwise the first catalog model that is ready. Updates
  /// [_selectedModelId] when falling back so STT uses a real download.
  ///
  /// Empty placeholder dirs (created by a cancelled download) are treated as
  /// not ready — common when Tiny was selected but only Turbo finished.
  Future<String?> resolveUsableModelId([String? preferredId]) async {
    final preferred = preferredId ?? _selectedModelId;
    if (await isModelReady(preferred)) {
      setSelectedModelId(preferred);
      return preferred;
    }
    const fallbackOrder = [
      'tiny',
      'base',
      'small',
      'turbo',
      'medium',
      'large-v3',
    ];
    for (final id in fallbackOrder) {
      if (id == preferred) continue;
      if (await isModelReady(id)) {
        debugPrint(
          'WhisperModelManager: selected "$preferred" missing — using "$id"',
        );
        setSelectedModelId(id);
        return id;
      }
    }
    return null;
  }

  Future<bool> hasAnyModelReady() async =>
      (await resolveUsableModelId()) != null;

  Future<Directory> _getModelDirectory(WhisperModelSpec spec) async {
    final appDir = await getApplicationSupportDirectory();
    final modelDir =
        Directory(p.join(appDir.path, 'stt_models', spec.dirName));
    if (!modelDir.existsSync()) {
      modelDir.createSync(recursive: true);
    }
    return modelDir;
  }

  Future<({String encoder, String decoder, String tokens})?> resolveModelPaths([
    String? modelId,
  ]) async {
    final spec = byId(modelId ?? _selectedModelId) ?? selectedSpec;
    final dir = await _getModelDirectory(spec);
    return _resolveOnnxPaths(dir);
  }

  Future<File> _vadModelFile() async {
    final appDir = await getApplicationSupportDirectory();
    return File(p.join(appDir.path, 'stt_models', vadModelFileName));
  }

  Future<String?> resolveVadModelPath() async {
    final file = await _vadModelFile();
    return file.existsSync() && file.lengthSync() > 0 ? file.path : null;
  }

  Future<bool> isVadModelReady() async => (await resolveVadModelPath()) != null;

  Future<bool> ensureVadModel() async {
    if (await isVadModelReady()) return true;

    final file = await _vadModelFile();
    file.parent.createSync(recursive: true);

    final ok = await ModelDownloadService.instance.runSingleFile(
      id: ModelDownloadJobIds.whisperVad,
      displayName: 'Silero VAD',
      url: vadDownloadUrl,
      destPath: file.path,
    );

    final ready = file.existsSync() && file.lengthSync() > 0;
    debugPrint(
        'WhisperModelManager: VAD model ${ready ? "ready" : "missing"} at ${file.path}');
    return ok && ready;
  }

  Future<({String encoder, String decoder, String tokens})?> _resolveOnnxPaths(
    Directory dir,
  ) async {
    String? encoder;
    String? decoder;
    String? tokens;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path).toLowerCase();

      if (_isTokensFile(name)) {
        tokens = entity.path;
      } else if (name.contains('encoder') && name.endsWith('.onnx')) {
        encoder = _preferInt8Onnx(encoder, entity.path, name);
      } else if (name.contains('decoder') && name.endsWith('.onnx')) {
        decoder = _preferInt8Onnx(decoder, entity.path, name);
      }
    }

    if (encoder == null || decoder == null || tokens == null) {
      if (kDebugMode) {
        debugPrint(
          'WhisperModelManager: Missing files under ${dir.path} '
          '(encoder=$encoder, decoder=$decoder, tokens=$tokens)',
        );
      }
      return null;
    }
    return (encoder: encoder, decoder: decoder, tokens: tokens);
  }

  static bool _isTokensFile(String fileName) {
    return fileName == 'tokens.txt' ||
        fileName.endsWith('-tokens.txt') ||
        fileName.endsWith('_tokens.txt');
  }

  static String _preferInt8Onnx(String? current, String candidate, String name) {
    if (current == null) return candidate;
    final currentName = p.basename(current).toLowerCase();
    if (name.contains('.int8.') && !currentName.contains('.int8.')) {
      return candidate;
    }
    return current;
  }

  Future<bool> downloadModel([String? modelId]) async {
    final spec = byId(modelId ?? _selectedModelId) ?? selectedSpec;
    if (isDownloadingSpec(spec)) return false;

    _error = null;
    _progressController.add(0);

    try {
      final dir = await _getModelDirectory(spec);
      final archivePath = p.join(dir.parent.path, '${spec.dirName}.tar.bz2');

      final ok = await ModelDownloadService.instance.runArchive(
        id: spec.jobId,
        displayName: 'Whisper ${spec.displayName}',
        url: spec.downloadUrl,
        archivePath: archivePath,
        extractDir: dir.parent.path,
        postExtract: () => _ensureFilesInPlace(dir, spec),
        validateReady: () => isModelReady(spec.id),
        onProgress: (job) => _progressController.add(job.progress),
      );

      if (ok) {
        _progressController.add(1.0);
        debugPrint('WhisperModelManager: Model ready at ${dir.path}');
      } else {
        final job = ModelDownloadService.instance.job(spec.jobId);
        _error = job?.errorMessage ?? 'Download failed';
        _progressController.add(0);
      }
      return ok;
    } catch (e) {
      debugPrint('WhisperModelManager: Download failed: $e');
      _error = e.toString();
      _progressController.add(0);
      return false;
    }
  }

  Future<void> _ensureFilesInPlace(
    Directory targetDir,
    WhisperModelSpec spec,
  ) async {
    if (await resolveModelPaths(spec.id) != null) return;

    final parent = targetDir.parent;
    final expected = spec.dirName.toLowerCase();
    final idToken = 'whisper-${spec.id}';
    for (final entity in parent.listSync(recursive: false)) {
      if (entity is! Directory || entity.path == targetDir.path) continue;
      final base = p.basename(entity.path).toLowerCase();
      if (base != expected && !base.contains(idToken)) continue;

      for (final sub in entity.listSync(recursive: true)) {
        if (sub is! File) continue;
        final dest = p.join(targetDir.path, p.basename(sub.path));
        if (!File(dest).existsSync()) {
          sub.copySync(dest);
        }
      }
      if (entity.path != targetDir.path) {
        entity.deleteSync(recursive: true);
      }
    }
  }

  Future<void> deleteModel([String? modelId]) async {
    final spec = byId(modelId ?? _selectedModelId) ?? selectedSpec;
    final dir = await _getModelDirectory(spec);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    _progressController.add(0);
  }

  Future<double> getModelSizeMB([String? modelId]) async {
    final spec = byId(modelId ?? _selectedModelId) ?? selectedSpec;
    final dir = await _getModelDirectory(spec);
    if (!dir.existsSync()) return 0;
    var totalBytes = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / 1024 / 1024;
  }
}
