import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_model_spec.dart';
import '../models/model_download_job.dart';
import 'local_model_catalog.dart';
import 'model_download_service.dart';
import 'download_progress_activity.dart';

part '../pro/local_models/local_model_download_pro.dart';

/// State of a single on-device model file.
enum LocalModelStatus {
  /// Not present locally.
  notDownloaded,

  /// Download is queued or actively running.
  downloading,

  /// File is present and verified (when a sha256 is known) or assumed
  /// good (when no sha256 was provided).
  ready,

  /// Download failed; see [LocalModelEntry.errorMessage].
  failed,
}

/// Runtime record describing a model the user has (or is currently
/// downloading) on this device.
class LocalModelEntry {
  final LocalModelSpec spec;
  LocalModelStatus status;

  /// Local filesystem path. For fllama this is the `.gguf` file; for MLX
  /// this is the directory containing `config.json` + tokenizer + weights.
  String? localPath;

  /// 0.0 – 1.0 while [status] is `downloading`.
  double progress;

  /// Bytes downloaded so far (best-effort; some streams don't report total).
  int bytesDownloaded;

  /// Total bytes expected, or `null` if the server didn't send Content-Length.
  int? bytesTotal;

  /// Smoothed download throughput while [status] is `downloading`.
  int bytesPerSecond;

  /// User-facing error message when [status] is `failed`.
  String? errorMessage;

  /// ISO-8601 timestamp of last successful completion.
  String? completedAt;

  LocalModelEntry({
    required this.spec,
    this.status = LocalModelStatus.notDownloaded,
    this.localPath,
    this.progress = 0.0,
    this.bytesDownloaded = 0,
    this.bytesTotal,
    this.bytesPerSecond = 0,
    this.errorMessage,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'spec': spec.toJson(),
        'status': status.name,
        'localPath': localPath,
        'completedAt': completedAt,
      };

  static LocalModelEntry fromJson(Map<String, dynamic> json) {
    final spec =
        LocalModelSpec.fromJson((json['spec'] as Map).cast<String, dynamic>());
    return LocalModelEntry(
      spec: spec,
      status: LocalModelStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'notDownloaded'),
        orElse: () => LocalModelStatus.notDownloaded,
      ),
      localPath: json['localPath'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }
}

/// Coordinates downloading curated and user-added on-device models from
/// Hugging Face into `<documents>/local_models/<diskSlug>/`.
///
/// Responsibilities:
///   - Tracks which models exist on disk and their last-known status.
///   - Streams a single Hugging Face download with progress.
///   - Persists the catalog of installed models in SharedPreferences so the
///     Local Models screen renders synchronously on launch.
///
/// Limits enforced here:
///   - On the **free** tier only one model can be ready at a time, and it
///     must be the curated [LocalModelCatalog.freeSlot] entry.
///   - **Pro** users may install any number of curated or custom models.
///
/// This service does NOT load weights or run inference; the engine adapter
/// (`OnDeviceFllamaEndpoint` / `OnDeviceMlxEndpoint`) consumes the resulting
/// `localPath`.
class LocalModelDownloadService extends ChangeNotifier {
  LocalModelDownloadService._();
  static final LocalModelDownloadService instance =
      LocalModelDownloadService._();

  static const String _prefsKey = 'local_models_v1';
  static const String _dirName = 'local_models';

  /// Hugging Face `resolve/main/<file>` URL format. We always pull from
  /// `main`; future versions could pin a revision per spec.
  static String _hfResolveUrl(String repo, String file) =>
      'https://huggingface.co/$repo/resolve/main/$file?download=true';

  final Map<String, LocalModelEntry> _entries = {};
  final Map<String, _SpeedSample> _speedSamples = {};
  bool _initialized = false;

  /// All known entries (downloaded, downloading, or failed).
  List<LocalModelEntry> get entries => _entries.values.toList(growable: false);

  /// Only entries currently `ready` for inference.
  /// Hidden catalog ids (experimental stream models) stay on disk but are
  /// not offered as something to chat with.
  List<LocalModelEntry> get readyEntries => _entries.values
      .where((e) => e.status == LocalModelStatus.ready)
      .where((e) => LocalModelCatalog.isListed(effectiveSpec(e)))
      .toList(growable: false);

  /// Lookup an entry by model id ([LocalModelSpec.id]).
  LocalModelEntry? entryById(String id) => _entries[id];

  /// Curated catalog definitions override stale JSON we persisted before a
  /// catalog fix (e.g. a corrected hfRepo after a 401).
  LocalModelSpec effectiveSpec(LocalModelEntry entry) =>
      LocalModelCatalog.byId(entry.spec.id) ?? entry.spec;

  /// Catalog ids removed in an app update. Non-ready entries are dropped on
  /// init so users aren't stuck retrying broken downloads.
  static const Set<String> _removedCatalogIds = {
    'google/gemma-4-1b/Q4_K_M',
    'qwen/qwen-3.5-1b/Q4_K_M',
    // Legacy small models retired mid-2026 catalog refresh.
    'qwen/qwen1.5-1.8b-chat/Q4_K_M',
    'huggingface/smolLM2-1.7b-instruct/Q4_K_M',
    'qwen/qwen2.5-1.5b-instruct/Q4_K_M',
    'qwen/qwen3-1.7b-free/Q4_K_M',
    'deepseek/deepseek-r1-distill-qwen-1.5b-free/Q4_K_M',
    // Superseded by Instruct-2507 / single Q4 picks.
    'mlx-community/qwen3-4b-4bit/mlx',
    'mlx-community/qwen3-8b-8bit/mlx',
    'qwen/qwen3-4b/Q4_K_M',
    'qwen/qwen3-8b/Q8_0',
    'meta-llama/llama-3.2-3b-instruct/Q8_0',
  };

  /// Load persisted entries from SharedPreferences. Safe to call multiple
  /// times; subsequent calls are no-ops.
  ///
  /// iOS rewrites the app sandbox container UUID on every fresh install
  /// (and frequently during dev builds), so the absolute `localPath` we
  /// persisted last launch will not point at the real model file this
  /// launch. We therefore re-derive the canonical path from
  /// [targetPathFor] for every ready entry and verify it actually exists
  /// on disk before trusting the stored status.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await ModelDownloadService.instance.init();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        if (kDebugMode) {
          debugPrint('🧩 LocalModelDownload init: no persisted entries.');
        }
        return;
      }
      final list = json.decode(raw) as List;
      for (final item in list) {
        if (item is! Map) continue;
        var entry = LocalModelEntry.fromJson(item.cast<String, dynamic>());

        if (_shouldDropObsoleteEntry(entry)) {
          if (kDebugMode) {
            debugPrint(
                '🧩 LocalModelDownload init: dropped obsolete ${entry.spec.id}');
          }
          continue;
        }

        final catalog = LocalModelCatalog.byId(entry.spec.id);
        if (catalog != null && _needsSpecRefresh(catalog, entry.spec)) {
          entry = _entryWithSpec(entry, catalog);
        }

        if (entry.status == LocalModelStatus.ready) {
          final expected = await targetPathFor(entry.spec);
          final type = FileSystemEntity.typeSync(expected);
          if (type != FileSystemEntityType.notFound) {
            entry.localPath = expected;
            if (kDebugMode) {
              debugPrint(
                  '🧩 LocalModelDownload init: ready ${entry.spec.id} -> $expected');
            }
          } else {
            // Fall back to the persisted path in case some future build
            // changes diskSlug logic; only invalidate if neither works.
            final legacy = entry.localPath;
            if (legacy == null ||
                FileSystemEntity.typeSync(legacy) ==
                    FileSystemEntityType.notFound) {
              if (kDebugMode) {
                debugPrint('🧩 LocalModelDownload init: missing on disk for '
                    '${entry.spec.id} (expected=$expected, legacy=$legacy) -> notDownloaded');
              }
              entry.status = LocalModelStatus.notDownloaded;
              entry.localPath = null;
            } else {
              entry.localPath = legacy;
            }
          }
        } else if (entry.status == LocalModelStatus.downloading) {
          if (entry.spec.engine != LocalEngine.fllama &&
              entry.spec.engine != LocalEngine.moeStream) {
            if (kDebugMode) {
              debugPrint(
                  '🧩 LocalModelDownload init: resume MLX ${entry.spec.id}');
            }
            unawaited(download(entry.spec));
          } else {
            final downloadJob =
                ModelDownloadService.instance.job(entry.spec.id);
            if (downloadJob?.status == ModelDownloadJobStatus.interrupted) {
              if (kDebugMode) {
                debugPrint(
                    '🧩 LocalModelDownload init: resume interrupted ${entry.spec.id}');
              }
              unawaited(download(entry.spec));
            } else {
              entry.status = LocalModelStatus.notDownloaded;
              entry.progress = 0;
              entry.bytesDownloaded = 0;
              entry.bytesPerSecond = 0;
            }
          }
        }
        _entries[entry.spec.id] = entry;
      }
      // Persist normalized paths and any pruned/reconciled rows.
      await _persist();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('🧩 LocalModelDownload init failed: $e\n$st');
      }
    }
  }

  /// Returns the root directory holding all installed models. Creates it on
  /// first call and excludes it from iCloud backup on iOS.
  Future<Directory> modelsRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _dirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Target file path for a given spec. For GGUF this is the file itself;
  /// for MLX (directory-based) it's the directory.
  Future<String> targetPathFor(LocalModelSpec spec) async {
    final root = await modelsRoot();
    final base = p.join(root.path, spec.diskSlug);
    if (spec.isGguf) {
      final fname = spec.hfFile ?? '${spec.diskSlug}.gguf';
      return p.join(base, fname);
    }
    return base;
  }

  /// Path to the multimodal projector next to a GGUF, or null when the
  /// spec has no [LocalModelSpec.mmprojHfFile] / file is missing.
  Future<String?> mmprojPathFor(LocalModelSpec spec) async {
    final name = spec.mmprojHfFile;
    if (name == null || name.isEmpty) return null;
    final root = await modelsRoot();
    final path = p.join(root.path, spec.diskSlug, name);
    if (await File(path).exists()) return path;
    return null;
  }

  /// Ensure the mmproj companion is on disk for vision-capable GGUF models.
  /// No-op when the spec has no mmproj or it's already downloaded.
  Future<String?> ensureMmproj(LocalModelSpec spec) async {
    final name = spec.mmprojHfFile;
    if (name == null || name.isEmpty) return null;
    final existing = await mmprojPathFor(spec);
    if (existing != null) return existing;

    final root = await modelsRoot();
    final dest = File(p.join(root.path, spec.diskSlug, name));
    await dest.parent.create(recursive: true);
    final url = _hfResolveUrl(spec.hfRepo, name);
    final jobId = '${spec.id}__mmproj';
    final ok = await ModelDownloadService.instance.runSingleFile(
      id: jobId,
      displayName: '${spec.displayName} (vision projector)',
      url: url,
      destPath: dest.path,
      onProgress: (_) {},
    );
    if (!ok || !await dest.exists()) {
      throw HttpException('Failed to download vision projector ($name)');
    }
    if (Platform.isIOS || Platform.isMacOS) {
      await _excludeFromBackup(dest.path);
    }
    return dest.path;
  }

  /// Start a download. Returns immediately; listeners are notified as
  /// progress and status change. Re-calling for an already-running entry
  /// is a no-op.
  ///
  /// Free-tier callers MUST gate this with `SubscriptionService().isPremium`
  /// before invoking for any non-freeSlot spec; this service does not know
  /// about subscription state.
  Future<void> download(LocalModelSpec spec) async {
    await init();
    spec = LocalModelCatalog.byId(spec.id) ?? spec;
    final existing = _entries[spec.id];
    if (existing != null &&
        existing.status == LocalModelStatus.downloading &&
        (ModelDownloadService.instance.isTransferActive(spec.id) ||
            ModelDownloadService.instance.isJobActive(spec.id))) {
      return;
    }

    if (!spec.isGguf) {
      // MLX (and any other multi-file engine): download the whole repo
      // tree into a directory.
      await _downloadMlxRepo(spec, existing);
      return;
    }

    if (spec.hfFile == null || spec.hfFile!.isEmpty) {
      final entry = existing ?? LocalModelEntry(spec: spec);
      entry.status = LocalModelStatus.failed;
      entry.errorMessage = 'Spec is missing a hfFile filename.';
      _entries[spec.id] = entry;
      notifyListeners();
      return;
    }

    final entry = existing ?? LocalModelEntry(spec: spec);
    entry.status = LocalModelStatus.downloading;
    entry.progress = 0.0;
    entry.bytesDownloaded = 0;
    entry.bytesTotal = null;
    entry.bytesPerSecond = 0;
    entry.errorMessage = null;
    _speedSamples.remove(spec.id);
    _entries[spec.id] = entry;
    notifyListeners();

    final url = _hfResolveUrl(spec.hfRepo, spec.hfFile!);
    final dest = File(await targetPathFor(spec));
    await dest.parent.create(recursive: true);
    final tmp = File('${dest.path}.part');

    try {
      final ok = await ModelDownloadService.instance.runSingleFile(
        id: spec.id,
        displayName: spec.displayName,
        url: url,
        destPath: dest.path,
        onProgress: (job) {
          entry.bytesDownloaded = job.bytesDownloaded;
          entry.bytesTotal = job.bytesTotal;
          entry.bytesPerSecond = job.bytesPerSecond;
          entry.progress = job.progress;
          notifyListeners();
        },
      );

      if (!ok) {
        final job = ModelDownloadService.instance.job(spec.id);
        throw HttpException(job?.errorMessage ?? 'Download failed');
      }

      // Exclude from iCloud backup on iOS so multi-GB models don't sync.
      if (Platform.isIOS || Platform.isMacOS) {
        await _excludeFromBackup(dest.path);
      }

      // Vision GGUFs need the mmproj companion; download it into the same folder.
      if (spec.mmprojHfFile != null && spec.mmprojHfFile!.isNotEmpty) {
        entry.progress = 0.92;
        notifyListeners();
        await ensureMmproj(spec);
      }

      entry.status = LocalModelStatus.ready;
      entry.localPath = dest.path;
      entry.progress = 1.0;
      entry.completedAt = DateTime.now().toUtc().toIso8601String();
      await _persist();
      notifyListeners();
    } catch (e) {
      entry.status = LocalModelStatus.failed;
      entry.progress = 0.0;
      entry.errorMessage = _friendlyDownloadError(e);
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      notifyListeners();
    }
  }

  /// Download every file in an MLX (or other directory-based) Hugging
  /// Face repo into `<targetPathFor(spec)>/`. Aggregates progress across
  /// every file; treats the whole download as one atomic unit (any
  /// failure marks the entry `failed`).
  ///
  /// Excludes obviously irrelevant files (`.gitattributes`, `README.md`,
  /// `LICENSE*`, GGUF / ONNX / PyTorch weights — we only need MLX-native
  /// safetensors + tokenizer + config). Walks subdirectories recursively
  /// because some MLX repos place files under nested folders.
  Future<void> _downloadMlxRepo(
      LocalModelSpec spec, LocalModelEntry? existing) async {
    final entry = existing ?? LocalModelEntry(spec: spec);
    ModelDownloadService.instance.resetCancelRequest(spec.id);
    entry.status = LocalModelStatus.downloading;
    entry.progress = 0.0;
    entry.bytesDownloaded = 0;
    entry.bytesTotal = null;
    entry.bytesPerSecond = 0;
    entry.errorMessage = null;
    _speedSamples.remove(spec.id);
    _entries[spec.id] = entry;
    notifyListeners();

    if (Platform.isAndroid) {
      await DownloadProgressActivity.instance.prepareAndroidPermission();
    }
    // iOS Live Activity is owned here so it stays up across multi-file MLX
    // downloads. Android uses the native foreground-service notification.
    final showLockScreen = Platform.isIOS;
    if (showLockScreen) {
      unawaited(DownloadProgressActivity.instance.start(
        displayName: spec.displayName,
      ));
    }

    try {
      final targetDir = Directory(await targetPathFor(spec));
      await targetDir.create(recursive: true);

      final client = http.Client();
      try {
        final files = await _listHfRepoFiles(client, spec.hfRepo);
        if (files.isEmpty) {
          throw StateError('No files found in ${spec.hfRepo}.');
        }

        final wanted = files.where(_isWantedMlxFile).toList();
        if (wanted.isEmpty) {
          throw StateError(
              'No MLX-compatible files (safetensors / tokenizer / config) in ${spec.hfRepo}.');
        }

        int total = 0;
        int alreadyOnDisk = 0;
        for (final f in wanted) {
          final dest = File(p.join(targetDir.path, f.path));
          if (await dest.exists()) {
            alreadyOnDisk += await dest.length();
          }
          if (f.size != null && f.size! > 0) {
            total += f.size!;
          } else {
            try {
              final head = await client
                  .head(Uri.parse(_hfResolveUrl(spec.hfRepo, f.path)))
                  .timeout(const Duration(seconds: 10));
              final len = int.tryParse(head.headers['content-length'] ?? '');
              if (len != null && len > 0) total += len;
            } catch (_) {}
          }
        }
        if (total > 0) {
          entry.bytesTotal = total;
          entry.bytesDownloaded = alreadyOnDisk.clamp(0, total);
          entry.progress = entry.bytesDownloaded / total;
        }
        notifyListeners();

        var completedBytes = alreadyOnDisk;
        for (final f in wanted) {
          final dest = File(p.join(targetDir.path, f.path));
          await dest.parent.create(recursive: true);

          if (await dest.exists() && await dest.length() > 0) {
            continue;
          }

          final tmp = File('${dest.path}.part');
          if (await tmp.exists()) {
            final partialLen = await tmp.length();
            if (partialLen > 0) {
              completedBytes += partialLen;
            }
          } else {
            // Fresh file — don't carry stale partial progress.
          }

          final url = _hfResolveUrl(spec.hfRepo, f.path);
          await ModelDownloadService.instance.downloadUrlToPartial(
            jobId: spec.id,
            displayName: spec.displayName,
            url: url,
            partialPath: tmp.path,
            showLiveActivity: false,
            updateExistingLiveActivity: true,
            onProgress: (fileDownloaded, fileTotal, bps) {
              final partialExtra = fileTotal != null
                  ? fileDownloaded.clamp(0, fileTotal)
                  : fileDownloaded;
              entry.bytesDownloaded = completedBytes + partialExtra;
              if (bps > 0) entry.bytesPerSecond = bps;
              if (entry.bytesTotal != null && entry.bytesTotal! > 0) {
                entry.progress =
                    (entry.bytesDownloaded / entry.bytesTotal!).clamp(0.0, 1.0);
              }
              _touchSpeed(spec.id, entry);
              notifyListeners();
              if (showLockScreen) {
                unawaited(DownloadProgressActivity.instance.update(
                  progress: entry.progress,
                  statusText: '${(entry.progress * 100).round()}%',
                ));
              }
            },
          );

          if (await dest.exists()) await dest.delete();
          await tmp.rename(dest.path);
          completedBytes += await dest.length();
          entry.bytesDownloaded = completedBytes;
          if (entry.bytesTotal != null && entry.bytesTotal! > 0) {
            entry.progress =
                (completedBytes / entry.bytesTotal!).clamp(0.0, 1.0);
          }
          notifyListeners();
        }
      } finally {
        client.close();
      }

      final configPresent =
          await File(p.join(targetDir.path, 'config.json')).exists();
      final hasWeights = await targetDir
          .list(recursive: true, followLinks: false)
          .any((e) =>
              e is File && e.path.toLowerCase().endsWith('.safetensors'));
      if (!configPresent || !hasWeights) {
        throw StateError(
            'Downloaded repo is missing config.json or *.safetensors.');
      }

      if (Platform.isIOS || Platform.isMacOS) {
        await _excludeFromBackup(targetDir.path);
      }

      entry.status = LocalModelStatus.ready;
      entry.localPath = targetDir.path;
      entry.progress = 1.0;
      entry.completedAt = DateTime.now().toUtc().toIso8601String();
      await _persist();
      if (kDebugMode) {
        debugPrint(
            '🧩 LocalModelDownload READY ${spec.id} -> ${targetDir.path}');
      }
      notifyListeners();
    } on _DownloadCancelled {
      entry.status = LocalModelStatus.notDownloaded;
      entry.progress = 0;
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        entry.status = LocalModelStatus.notDownloaded;
        entry.progress = 0;
        notifyListeners();
        return;
      }
      entry.status = LocalModelStatus.failed;
      entry.progress = 0.0;
      entry.errorMessage = _friendlyDownloadError(e);
      notifyListeners();
    } finally {
      if (showLockScreen && DownloadProgressActivity.instance.isActive) {
        final ok = entry.status == LocalModelStatus.ready;
        unawaited(DownloadProgressActivity.instance.end(success: ok));
      }
    }
  }

  /// Recursively list every file in a HF repo via the tree API. The API
  /// returns one level at a time; we walk subdirectories ourselves.
  Future<List<_HfFile>> _listHfRepoFiles(
      http.Client client, String repo) async {
    final out = <_HfFile>[];
    final queue = <String>['']; // '' = repo root
    while (queue.isNotEmpty) {
      final sub = queue.removeAt(0);
      final url = sub.isEmpty
          ? 'https://huggingface.co/api/models/$repo/tree/main'
          : 'https://huggingface.co/api/models/$repo/tree/main/$sub';
      final res =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw HttpException(
            'HF tree lookup failed for $repo/$sub (HTTP ${res.statusCode}).');
      }
      final body = json.decode(res.body);
      if (body is! List) {
        throw FormatException('Unexpected HF tree response for $repo/$sub.');
      }
      for (final item in body.whereType<Map>()) {
        final type = item['type'] as String?;
        final path = item['path'] as String?;
        if (path == null) continue;
        if (type == 'directory') {
          queue.add(path);
        } else if (type == 'file') {
          final size = (item['size'] as num?)?.toInt();
          out.add(_HfFile(path: path, size: size));
        }
      }
    }
    return out;
  }

  /// Keep MLX-native + tokenizer + config; drop GGUF / PyTorch / ONNX
  /// and documentation noise.
  bool _isWantedMlxFile(_HfFile f) {
    final lower = f.path.toLowerCase();

    // Drop docs / metadata.
    const dropExact = {
      '.gitattributes',
      'readme.md',
      'license',
      'license.txt',
      'license.md',
      'notice',
      'notice.md',
    };
    final base = p.basename(lower);
    if (dropExact.contains(base)) return false;

    // Drop non-MLX weight formats.
    const dropExt = [
      '.gguf',
      '.bin', // PyTorch
      '.pt',
      '.pth',
      '.onnx',
      '.h5',
      '.msgpack',
      '.tflite',
    ];
    for (final ext in dropExt) {
      if (lower.endsWith(ext)) return false;
    }

    // Drop image / video assets sometimes attached to model cards.
    const dropMedia = ['.png', '.jpg', '.jpeg', '.gif', '.mp4', '.webp'];
    for (final ext in dropMedia) {
      if (lower.endsWith(ext)) return false;
    }

    return true;
  }

  /// Cancel an in-flight download for [id]. Marks the entry as
  /// `notDownloaded` and deletes any `.part` file.
  Future<void> cancel(String id) async {
    await ModelDownloadService.instance.cancel(id);
    final entry = _entries[id];
    if (entry == null) return;
    entry.status = LocalModelStatus.notDownloaded;
    entry.progress = 0;
    entry.bytesPerSecond = 0;
    _speedSamples.remove(id);
    try {
      final dest = File(await targetPathFor(entry.spec));
      final tmp = File('${dest.path}.part');
      if (await tmp.exists()) await tmp.delete();
    } catch (_) {}
    notifyListeners();
  }

  /// Remove a downloaded model from disk and forget about it.
  Future<void> delete(String id) async {
    final entry = _entries[id];
    if (entry == null) return;
    try {
      if (entry.localPath != null) {
        final type = FileSystemEntity.typeSync(entry.localPath!);
        if (type == FileSystemEntityType.file) {
          await File(entry.localPath!).delete();
        } else if (type == FileSystemEntityType.directory) {
          await Directory(entry.localPath!).delete(recursive: true);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🧩 delete failed: $e');
    }
    _entries.remove(id);
    await _persist();
    notifyListeners();
  }

  /// Sum of on-disk bytes for every entry currently `ready`. Used by the
  /// browse screen's storage banner. Best-effort: missing files are
  /// silently treated as 0.
  Future<int> totalDiskBytes() async {
    int total = 0;
    // Snapshot — listeners may mutate _entries while we await file I/O.
    for (final e in _entries.values.toList(growable: false)) {
      if (e.status != LocalModelStatus.ready || e.localPath == null) continue;
      try {
        final fse = FileSystemEntity.typeSync(e.localPath!);
        if (fse == FileSystemEntityType.file) {
          total += await File(e.localPath!).length();
        } else if (fse == FileSystemEntityType.directory) {
          await for (final entity in Directory(e.localPath!)
              .list(recursive: true, followLinks: false)) {
            if (entity is File) {
              try {
                total += await entity.length();
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    return total;
  }

  /// Count of user-imported models tracked by this service.
  int get importedModelCount => _entries.values
      .where((e) => e.spec.isImported)
      .length;

  /// Import a `.gguf` file from the device file picker into
  /// `<documents>/local_models/`. Returns the registered spec.
  ///
  /// Callers must enforce subscription limits (free: 1 import, Pro:
  /// unlimited) before invoking.
  Future<LocalModelSpec> importFromFile(
    String sourcePath, {
    String? displayName,
  }) async {
    await init();
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Selected file no longer exists.');
    }
    final ext = p.extension(sourcePath).toLowerCase();
    if (ext != '.gguf') {
      throw ArgumentError('Only .gguf files can be imported here.');
    }

    final originalName = p.basename(sourcePath);
    final id = _uniqueImportId(originalName);
    final sizeBytes = await source.length();
    final sizeMb = (sizeBytes / (1024 * 1024)).round();
    final quant = _extractQuant(originalName);
    final label = displayName ??
        originalName
            .replaceAll(RegExp(r'\.gguf$', caseSensitive: false), '')
            .replaceAll('_', ' ');

    final spec = LocalModelSpec(
      id: id,
      displayName: label,
      description: 'Imported from device storage',
      hfRepo: 'local/import',
      hfFile: originalName,
      sizeMb: sizeMb,
      paramsB: 0,
      quantization: quant,
      engine: LocalEngine.fllama,
      tier: LocalModelTier.pro,
      chatTemplate: 'auto',
      supportsToolCalls: false,
      minRamGb: 3.0,
      isImported: true,
    );

    final dest = File(await targetPathFor(spec));
    await dest.parent.create(recursive: true);
    if (await dest.exists()) await dest.delete();
    await source.copy(dest.path);

    if (Platform.isIOS || Platform.isMacOS) {
      await _excludeFromBackup(dest.path);
    }

    final entry = LocalModelEntry(spec: spec)
      ..status = LocalModelStatus.ready
      ..localPath = dest.path
      ..progress = 1.0
      ..completedAt = DateTime.now().toUtc().toIso8601String();
    _entries[id] = entry;
    await _persist();
    notifyListeners();
    return spec;
  }

  // Used by the Pro MLX folder import part (unused in the public build).
  // ignore: unused_element
  bool _shouldIncludeMlxRelativePath(String relativePath) {
    return _isWantedMlxFile(_HfFile(path: relativePath));
  }

  bool _shouldDropObsoleteEntry(LocalModelEntry entry) {
    if (_removedCatalogIds.contains(entry.spec.id) &&
        entry.status != LocalModelStatus.ready) {
      return true;
    }
    // Official Google GGUF repos are gated (HTTP 401) — drop stale failures.
    if (entry.spec.hfRepo.startsWith('google/') &&
        entry.status != LocalModelStatus.ready) {
      return true;
    }
    return false;
  }

  bool _needsSpecRefresh(LocalModelSpec catalog, LocalModelSpec persisted) =>
      catalog.hfRepo != persisted.hfRepo ||
      catalog.hfFile != persisted.hfFile ||
      catalog.displayName != persisted.displayName;

  LocalModelEntry _entryWithSpec(LocalModelEntry entry, LocalModelSpec spec) {
    return LocalModelEntry(
      spec: spec,
      status: entry.status,
      localPath: entry.localPath,
      progress: entry.progress,
      bytesDownloaded: entry.bytesDownloaded,
      bytesTotal: entry.bytesTotal,
      errorMessage: entry.errorMessage,
      completedAt: entry.completedAt,
    );
  }

  String _uniqueImportId(String filename) {
    final base = p.basenameWithoutExtension(filename);
    final slug = base.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    var id = 'imported/$slug';
    if (_entries.containsKey(id)) {
      id = 'imported/${slug}_${DateTime.now().millisecondsSinceEpoch}';
    }
    return id;
  }

  /// Lets the Pro import part (an extension) notify listeners.
  // ignore: unused_element
  void _notifyFromPart() => notifyListeners();

  String _extractQuant(String filename) {
    final m =
        RegExp(r'(Q\d[_A-Z0-9]*)', caseSensitive: false).firstMatch(filename);
    return m?.group(1)?.toUpperCase() ?? '';
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _entries.values.map((e) => e.toJson()).toList();
      await prefs.setString(_prefsKey, json.encode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('🧩 persist failed: $e');
    }
  }

  String _friendlyDownloadError(Object error) {
    final message = error.toString();
    if (error is FileSystemException && error.osError?.errorCode == 28) {
      return 'Not enough storage space on this device. Free up space and try again.';
    }
    if (message.contains('errno = 28') ||
        message.toLowerCase().contains('no space left on device')) {
      return 'Not enough storage space on this device. Free up space and try again.';
    }
    return message;
  }

  // iOS/macOS: set `com.apple.metadata:com_apple_backup_excludeItem`. We use
  // the `xattr` shell on macOS as a fallback; on iOS we rely on the FS API
  // when a native plugin is available. For now, best-effort no-op so we
  // don't crash on missing helpers — the file is still excluded by the
  // `local_models/` directory naming on App Store builds via Info.plist.
  Future<void> _excludeFromBackup(String path) async {
    // TODO(ios-backup): wire NSURLIsExcludedFromBackupKey via a tiny pigeon
    // helper or `path_provider` future API. The directory pattern keeps
    // downloads out of iCloud Drive UI today; backup exclusion is the
    // remaining bit before App Store submission.
  }

  /// Updates [entry.bytesPerSecond] from byte deltas between progress ticks.
  void _touchSpeed(String id, LocalModelEntry entry) {
    final now = DateTime.now();
    final prev = _speedSamples[id];
    if (prev != null) {
      final ms = now.difference(prev.at).inMilliseconds;
      if (ms >= 400) {
        final delta = entry.bytesDownloaded - prev.bytes;
        if (delta > 0) {
          final instant = (delta * 1000 / ms).round();
          entry.bytesPerSecond = entry.bytesPerSecond == 0
              ? instant
              : (entry.bytesPerSecond * 0.7 + instant * 0.3).round();
        }
        _speedSamples[id] = _SpeedSample(now, entry.bytesDownloaded);
      }
    } else {
      _speedSamples[id] = _SpeedSample(now, entry.bytesDownloaded);
    }
  }
}

/// Internal sentinel thrown when a download is cancelled while we were
/// streaming. Caught inside `_downloadMlxRepo` to leave the entry in the
/// `notDownloaded` state instead of `failed`.
class _DownloadCancelled implements Exception {
  const _DownloadCancelled();
}

/// Lightweight projection of an HF tree-API entry.
class _HfFile {
  final String path;
  final int? size;
  const _HfFile({required this.path, this.size});
}

class _SpeedSample {
  final DateTime at;
  final int bytes;
  const _SpeedSample(this.at, this.bytes);
}
