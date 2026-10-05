import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/model_download_job.dart';
import '../utils/tts_language_catalog.dart';
import 'model_download_service.dart';

/// Downloads and extracts on-device TTS language packs (Kokoro + Piper).
///
/// English / Spanish / French / Chinese share `kokoro-multi-lang-v1_0`.
/// German and Russian use smaller Piper VITS packs. The older
/// `kokoro-en-v0_19` folder still counts as English if already installed.
class KokoroModelManager {
  static final KokoroModelManager _instance = KokoroModelManager._internal();
  factory KokoroModelManager() => _instance;
  KokoroModelManager._internal();

  String? _error;

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  String? get error => _error;
  Stream<double> get progressStream => _progressController.stream;

  static const _jobIds = [
    ModelDownloadJobIds.kokoro,
    ModelDownloadJobIds.kokoroMulti,
    ModelDownloadJobIds.piperDe,
    ModelDownloadJobIds.piperRu,
  ];

  bool get isDownloading =>
      _jobIds.any(ModelDownloadService.instance.isJobActive);

  double get downloadProgress {
    for (final id in _jobIds) {
      final job = ModelDownloadService.instance.job(id);
      if (job != null && job.isActive) return job.progress;
    }
    return 0;
  }

  bool isDownloadingLanguage(String langId) {
    final lang = TtsLanguageCatalog.byId(langId);
    if (lang == null) return false;
    final ids = <String>{lang.assetId};
    if (lang.fallbackAssetId != null) ids.add(lang.fallbackAssetId!);
    return ids.any(
      (assetId) => ModelDownloadService.instance.isJobActive('asset:$assetId'),
    );
  }

  Future<Directory> _ttsRoot() async {
    final appDir = await getApplicationSupportDirectory();
    final root = Directory(p.join(appDir.path, 'tts_models'));
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    return root;
  }

  Future<Directory> _assetDirectory(String assetId) async {
    final root = await _ttsRoot();
    final dir = Directory(p.join(root.path, assetId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<bool> isAssetReady(String assetId) async {
    final spec = TtsLanguageCatalog.assetById(assetId);
    if (spec == null) return false;
    final dir = await _assetDirectory(assetId);
    return TtsLanguageCatalog.looksLikeModelDir(dir.path, spec);
  }

  Future<bool> isLanguageReady(String langId) async {
    return (await resolveAssetId(langId)) != null;
  }

  /// True if any language pack (including the legacy English model) is on disk.
  Future<bool> isModelReady() async {
    for (final lang in TtsLanguageCatalog.languages) {
      if (await isLanguageReady(lang.id)) return true;
    }
    return false;
  }

  Future<Map<String, bool>> languageReadyMap() async {
    final map = <String, bool>{};
    for (final lang in TtsLanguageCatalog.languages) {
      map[lang.id] = await isLanguageReady(lang.id);
    }
    return map;
  }

  Future<String?> resolveAssetId(String langId) async {
    final lang = TtsLanguageCatalog.byId(langId);
    if (lang == null) return null;
    if (await isAssetReady(lang.assetId)) return lang.assetId;
    if (lang.fallbackAssetId != null &&
        await isAssetReady(lang.fallbackAssetId!)) {
      return lang.fallbackAssetId;
    }
    return null;
  }

  Future<bool> usesLegacyEnglish(String langId) async {
    if (langId != 'en') return false;
    final resolved = await resolveAssetId('en');
    return resolved == TtsLanguageCatalog.englishId;
  }

  Future<String> getAssetPath(String assetId) async {
    final dir = await _assetDirectory(assetId);
    return dir.path;
  }

  /// Path of a ready pack (legacy English, then any installed). Used by
  /// voice-pack import for a shared `espeak-ng-data` directory.
  Future<String> getModelPath() async {
    for (final id in [
      TtsLanguageCatalog.englishId,
      TtsLanguageCatalog.multiLangId,
      TtsLanguageCatalog.piperDeId,
      TtsLanguageCatalog.piperRuId,
    ]) {
      if (await isAssetReady(id)) return getAssetPath(id);
    }
    return (await _assetDirectory(TtsLanguageCatalog.englishId)).path;
  }

  Future<String> emptyLexiconPath() async {
    final root = await _ttsRoot();
    final file = File(p.join(root.path, 'empty-lexicon.txt'));
    if (!file.existsSync()) {
      file.writeAsStringSync('');
    }
    return file.path;
  }

  /// Backward-compatible: download the shared Kokoro pack (English + zh/fr/es).
  Future<bool> downloadModel() => downloadLanguage('en');

  Future<bool> downloadLanguage(String langId) async {
    final lang = TtsLanguageCatalog.byId(langId);
    if (lang == null) {
      _error = 'Unknown TTS language: $langId';
      return false;
    }
    if (await isLanguageReady(langId)) return true;
    return downloadAsset(lang.assetId);
  }

  Future<bool> downloadAsset(String assetId) async {
    final spec = TtsLanguageCatalog.assetById(assetId);
    if (spec == null) {
      _error = 'Unknown TTS asset: $assetId';
      return false;
    }
    if (ModelDownloadService.instance.isJobActive(spec.jobId)) return false;
    if (await isAssetReady(assetId)) return true;

    _error = null;
    _progressController.add(0);

    try {
      final dir = await _assetDirectory(assetId);
      final archivePath = p.join(dir.parent.path, '$assetId.tar.bz2');

      final ok = await ModelDownloadService.instance.runArchive(
        id: spec.jobId,
        displayName: spec.name,
        url: spec.url,
        archivePath: archivePath,
        extractDir: dir.parent.path,
        postExtract: () => _ensureFilesInPlace(dir, spec),
        validateReady: () => isAssetReady(assetId),
        onProgress: (job) => _progressController.add(job.progress),
      );

      if (ok) {
        _progressController.add(1.0);
        debugPrint('KokoroModelManager: ${spec.name} ready at ${dir.path}');
      } else {
        final job = ModelDownloadService.instance.job(spec.jobId);
        _error = job?.errorMessage ?? 'Download failed';
        _progressController.add(0);
      }
      return ok;
    } catch (e) {
      debugPrint('KokoroModelManager: Download failed: $e');
      _error = e.toString();
      _progressController.add(0);
      return false;
    }
  }

  Future<void> _ensureFilesInPlace(
      Directory targetDir, TtsAssetSpec spec) async {
    if (TtsLanguageCatalog.looksLikeModelDir(targetDir.path, spec)) return;

    final parent = targetDir.parent;
    for (final entity in parent.listSync(recursive: false)) {
      if (entity is! Directory || entity.path == targetDir.path) continue;
      final dirName = p.basename(entity.path);
      if (!dirName.contains(spec.id) &&
          !dirName.contains('kokoro') &&
          !dirName.contains('vits-piper')) {
        continue;
      }
      if (!TtsLanguageCatalog.looksLikeModelDir(entity.path, spec) &&
          spec.engine != TtsEngineKind.vits &&
          !File(p.join(entity.path, 'model.onnx')).existsSync()) {
        continue;
      }
      for (final sub in entity.listSync(recursive: false)) {
        final dest = p.join(targetDir.path, p.basename(sub.path));
        if (!File(dest).existsSync() && !Directory(dest).existsSync()) {
          sub.renameSync(dest);
        }
      }
      if (entity.listSync().isEmpty) {
        entity.deleteSync();
      }
    }
  }

  /// Delete every TTS pack (advanced “remove Kokoro” action).
  Future<void> deleteModel() async {
    for (final spec in TtsLanguageCatalog.assets.values) {
      await deleteAsset(spec.id);
    }
    _progressController.add(0);
  }

  Future<void> deleteLanguage(String langId) async {
    final lang = TtsLanguageCatalog.byId(langId);
    if (lang == null) return;
    await deleteAsset(lang.assetId);
    if (lang.fallbackAssetId != null) {
      await deleteAsset(lang.fallbackAssetId!);
    }
  }

  Future<void> deleteAsset(String assetId) async {
    final dir = await _assetDirectory(assetId);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  Future<double> getModelSizeMB() async {
    final root = await _ttsRoot();
    if (!root.existsSync()) return 0;
    var totalBytes = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / 1024 / 1024;
  }

  void dispose() {
    _progressController.close();
  }
}
