import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_sd_asset_spec.dart';
import 'model_download_service.dart';

/// State of a single on-device Stable Diffusion asset (checkpoint, LoRA, or
/// VAE). Mirrors [LocalModelStatus] on the LLM side.
enum LocalSdAssetStatus {
  notDownloaded,
  downloading,
  ready,
  failed,
}

/// Runtime record describing one SD asset that exists (or is being fetched)
/// on this device.
class LocalSdAssetEntry {
  final LocalSdAssetSpec spec;
  LocalSdAssetStatus status;

  /// Local filesystem path. For single-file assets (LoRA / VAE) this is the
  /// `.safetensors` file. For Core ML SD checkpoints it is the directory
  /// containing the compiled `.mlmodelc` bundles.
  String? localPath;

  /// 0.0 – 1.0 while [status] is `downloading`.
  double progress;

  int bytesDownloaded;
  int? bytesTotal;
  int bytesPerSecond;
  String? errorMessage;
  String? completedAt;

  LocalSdAssetEntry({
    required this.spec,
    this.status = LocalSdAssetStatus.notDownloaded,
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

  static LocalSdAssetEntry fromJson(Map<String, dynamic> json) {
    final spec =
        LocalSdAssetSpec.fromJson((json['spec'] as Map).cast<String, dynamic>());
    return LocalSdAssetEntry(
      spec: spec,
      status: LocalSdAssetStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'notDownloaded'),
        orElse: () => LocalSdAssetStatus.notDownloaded,
      ),
      localPath: json['localPath'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }
}

/// Coordinates downloading curated and user-added on-device Stable Diffusion
/// assets (checkpoints, LoRAs, VAEs) from Hugging Face into
/// `<documents>/local_sd_models/<kind>/<diskSlug>/`.
class LocalSdAssetDownloadService extends ChangeNotifier {
  LocalSdAssetDownloadService._();
  static final LocalSdAssetDownloadService instance =
      LocalSdAssetDownloadService._();

  static const String _prefsKey = 'local_sd_assets_v1';
  static const String _dirName = 'local_sd_models';

  static String _hfResolveUrl(String repo, String file) =>
      'https://huggingface.co/$repo/resolve/main/$file?download=true';

  final Map<String, LocalSdAssetEntry> _entries = {};
  bool _initialized = false;

  List<LocalSdAssetEntry> get entries =>
      _entries.values.toList(growable: false);

  List<LocalSdAssetEntry> get readyEntries => _entries.values
      .where((e) => e.status == LocalSdAssetStatus.ready)
      .toList(growable: false);

  List<LocalSdAssetEntry> readyByKind(SdAssetKind kind) =>
      readyEntries.where((e) => e.spec.kind == kind).toList(growable: false);

  LocalSdAssetEntry? entryById(String id) => _entries[id];

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await ModelDownloadService.instance.init();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final list = json.decode(raw) as List;
      for (final item in list) {
        if (item is! Map) continue;
        final entry =
            LocalSdAssetEntry.fromJson(item.cast<String, dynamic>());
        if (entry.status == LocalSdAssetStatus.ready) {
          final expected = await targetPathFor(entry.spec);
          final type = FileSystemEntity.typeSync(expected);
          if (type != FileSystemEntityType.notFound) {
            entry.localPath = expected;
            if (entry.spec.engine == SdEngine.coreml &&
                type == FileSystemEntityType.directory) {
              try {
                await _validateCoreMlCheckpoint(Directory(expected));
              } catch (e) {
                // Older builds dropped `.bin` weights — force a re-download.
                entry.status = LocalSdAssetStatus.failed;
                entry.errorMessage =
                    'Incomplete Core ML download (missing weights). Delete and download again.';
                if (kDebugMode) debugPrint('🎨 SD checkpoint invalid: $e');
              }
            }
          } else {
            final legacy = entry.localPath;
            if (legacy == null ||
                FileSystemEntity.typeSync(legacy) ==
                    FileSystemEntityType.notFound) {
              entry.status = LocalSdAssetStatus.notDownloaded;
              entry.localPath = null;
            }
          }
        } else if (entry.status == LocalSdAssetStatus.downloading) {
          unawaited(download(entry.spec));
        }
        _entries[entry.spec.id] = entry;
      }
      await _persist();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('🎨 LocalSdAssetDownload init failed: $e\n$st');
      }
    }
  }

  Future<Directory> assetsRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _dirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> targetPathFor(LocalSdAssetSpec spec) async {
    final root = await assetsRoot();
    final kindDir = p.join(root.path, spec.kind.name);
    final base = p.join(kindDir, spec.diskSlug);
    if (spec.hfFile != null && spec.hfFile!.isNotEmpty) {
      return p.join(base, p.basename(spec.hfFile!));
    }
    return base;
  }

  Future<void> download(LocalSdAssetSpec spec) async {
    await init();
    final existing = _entries[spec.id];
    if (existing != null &&
        existing.status == LocalSdAssetStatus.downloading &&
        (ModelDownloadService.instance.isTransferActive(spec.id) ||
            ModelDownloadService.instance.isJobActive(spec.id))) {
      return;
    }
    if (spec.hfFile != null && spec.hfFile!.isNotEmpty) {
      await _downloadSingleFile(spec, existing);
    } else {
      await _downloadDirectory(spec, existing);
    }
  }

  Future<void> _downloadSingleFile(
      LocalSdAssetSpec spec, LocalSdAssetEntry? existing) async {
    final entry = existing ?? LocalSdAssetEntry(spec: spec);
    ModelDownloadService.instance.resetCancelRequest(spec.id);
    entry.status = LocalSdAssetStatus.downloading;
    entry.progress = 0.0;
    entry.bytesDownloaded = 0;
    entry.bytesTotal = null;
    entry.bytesPerSecond = 0;
    entry.errorMessage = null;
    _entries[spec.id] = entry;
    notifyListeners();

    final url = _hfResolveUrl(spec.hfRepo, spec.hfFile!);
    final dest = File(await targetPathFor(spec));
    await dest.parent.create(recursive: true);

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

      entry.status = LocalSdAssetStatus.ready;
      entry.localPath = dest.path;
      entry.progress = 1.0;
      entry.completedAt = DateTime.now().toUtc().toIso8601String();
      await _persist();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        entry.status = LocalSdAssetStatus.notDownloaded;
        entry.progress = 0;
        notifyListeners();
        return;
      }
      entry.status = LocalSdAssetStatus.failed;
      entry.errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _downloadDirectory(
      LocalSdAssetSpec spec, LocalSdAssetEntry? existing) async {
    final entry = existing ?? LocalSdAssetEntry(spec: spec);
    ModelDownloadService.instance.resetCancelRequest(spec.id);
    entry.status = LocalSdAssetStatus.downloading;
    entry.progress = 0.0;
    entry.bytesDownloaded = 0;
    entry.bytesTotal = null;
    entry.bytesPerSecond = 0;
    entry.errorMessage = null;
    _entries[spec.id] = entry;
    notifyListeners();

    try {
      final targetDir = Directory(await targetPathFor(spec));
      await targetDir.create(recursive: true);

      final client = http.Client();
      try {
        final files = await _listHfRepoFiles(
          client,
          spec.hfRepo,
          rootPath: spec.hfSubfolder ?? '',
        );
        if (files.isEmpty) {
          throw StateError(
              'No files under ${spec.hfRepo}/${spec.hfSubfolder ?? ''}.');
        }

        final wanted = files.where(_isWantedSdFile).toList();
        final pruned = _dropRedundantUnetBundles(wanted);
        if (pruned.isEmpty) {
          throw StateError(
              'No Core ML files (.mlmodelc / .json / merges.txt) found.');
        }

        int total = 0;
        int alreadyOnDisk = 0;
        for (final f in pruned) {
          final relPath = spec.hfSubfolder == null
              ? f.path
              : f.path.replaceFirst('${spec.hfSubfolder}/', '');
          final dest = File(p.join(targetDir.path, relPath));
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
        for (final f in pruned) {
          final relPath = spec.hfSubfolder == null
              ? f.path
              : f.path.replaceFirst('${spec.hfSubfolder}/', '');
          final dest = File(p.join(targetDir.path, relPath));
          await dest.parent.create(recursive: true);

          if (await dest.exists() && await dest.length() > 0) {
            continue;
          }

          final tmp = File('${dest.path}.part');
          final url = _hfResolveUrl(spec.hfRepo, f.path);
          await ModelDownloadService.instance.downloadUrlToPartial(
            jobId: spec.id,
            displayName: spec.displayName,
            url: url,
            partialPath: tmp.path,
            onProgress: (fileDownloaded, fileTotal, bps) {
              final partialExtra = fileTotal != null
                  ? fileDownloaded.clamp(0, fileTotal)
                  : fileDownloaded;
              entry.bytesDownloaded = completedBytes + partialExtra;
              entry.bytesPerSecond = bps;
              if (entry.bytesTotal != null && entry.bytesTotal! > 0) {
                entry.progress =
                    (entry.bytesDownloaded / entry.bytesTotal!).clamp(0.0, 1.0);
              }
              notifyListeners();
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

      if (spec.engine == SdEngine.coreml) {
        await _validateCoreMlCheckpoint(targetDir);
      }

      entry.status = LocalSdAssetStatus.ready;
      entry.localPath = targetDir.path;
      entry.progress = 1.0;
      entry.completedAt = DateTime.now().toUtc().toIso8601String();
      await _persist();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        entry.status = LocalSdAssetStatus.notDownloaded;
        entry.progress = 0;
        notifyListeners();
        return;
      }
      entry.status = LocalSdAssetStatus.failed;
      entry.errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<List<_HfFile>> _listHfRepoFiles(
    http.Client client,
    String repo, {
    String rootPath = '',
  }) async {
    final out = <_HfFile>[];
    final queue = <String>[rootPath];
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

  bool _isWantedSdFile(_HfFile f) {
    final lower = f.path.toLowerCase();
    final base = p.basename(lower);
    const dropExact = {
      '.gitattributes',
      'readme.md',
      'license',
      'license.txt',
      'license.md',
    };
    if (dropExact.contains(base)) return false;
    // Analytics blobs inside .mlmodelc are unused at runtime.
    if (lower.contains('.mlmodelc/analytics/')) return false;
    // Core ML `.mlmodelc` bundles ship weights as `coremldata.bin` and
    // `weights/weight.bin`. Dropping `.bin` globally left only model.mil +
    // metadata, which Core ML rejects with "Compile the model…".
    if (lower.endsWith('.bin')) {
      return lower.contains('.mlmodelc/');
    }
    const dropExt = [
      '.pt',
      '.pth',
      '.onnx',
      '.h5',
      '.tflite',
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.mp4',
      '.webp',
    ];
    for (final ext in dropExt) {
      if (lower.endsWith(ext)) return false;
    }
    return true;
  }

  /// Apple's published trees include both a monolithic `Unet.mlmodelc` and
  /// chunked `UnetChunk1/2`. Our pipeline prefers chunks when both exist, so
  /// the full Unet is ~1.7 GB of dead weight on download/disk.
  List<_HfFile> _dropRedundantUnetBundles(List<_HfFile> files) {
    final hasChunks = files.any((f) {
      final lower = f.path.toLowerCase();
      return lower.contains('/unetchunk1.mlmodelc/') ||
          lower.endsWith('/unetchunk1.mlmodelc') ||
          lower.contains('unetchunk1.mlmodelc/');
    }) &&
        files.any((f) {
          final lower = f.path.toLowerCase();
          return lower.contains('/unetchunk2.mlmodelc/') ||
              lower.endsWith('/unetchunk2.mlmodelc') ||
              lower.contains('unetchunk2.mlmodelc/');
        });
    if (!hasChunks) return files;

    return files.where((f) {
      final lower = f.path.toLowerCase();
      // Drop only the monolithic Unet / ControlledUnet bundles — keep chunks.
      final isMonoUnet = (lower.contains('/unet.mlmodelc/') ||
              lower.endsWith('/unet.mlmodelc') ||
              lower.contains('unet.mlmodelc/')) &&
          !lower.contains('unetchunk');
      final isMonoControlled = (lower.contains('/controlledunet.mlmodelc/') ||
              lower.endsWith('/controlledunet.mlmodelc') ||
              lower.contains('controlledunet.mlmodelc/')) &&
          !lower.contains('controlledunetchunk');
      return !isMonoUnet && !isMonoControlled;
    }).toList();
  }

  /// Ensures each required `.mlmodelc` under [dir] has the compiled payload
  /// Core ML needs (not just `model.mil` / `metadata.json`).
  Future<void> _validateCoreMlCheckpoint(Directory dir) async {
    final bundles = dir
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.toLowerCase().endsWith('.mlmodelc'))
        .toList();
    if (bundles.isEmpty) {
      throw StateError(
          'Download incomplete: no .mlmodelc bundles in ${dir.path}.');
    }

    final names = bundles.map((b) => p.basename(b.path).toLowerCase()).toSet();
    final hasChunks =
        names.contains('unetchunk1.mlmodelc') &&
            names.contains('unetchunk2.mlmodelc');

    for (final bundle in bundles) {
      final name = p.basename(bundle.path).toLowerCase();
      // Monolithic Unet is unused when chunked Unet is present.
      if (hasChunks &&
          (name == 'unet.mlmodelc' || name == 'controlledunet.mlmodelc')) {
        continue;
      }
      final mil = File(p.join(bundle.path, 'model.mil'));
      final coremlData = File(p.join(bundle.path, 'coremldata.bin'));
      final weightsDir = Directory(p.join(bundle.path, 'weights'));
      final hasWeights = weightsDir.existsSync() &&
          weightsDir
              .listSync()
              .whereType<File>()
              .any((f) => f.path.toLowerCase().endsWith('.bin'));
      if (!await mil.exists() ||
          !await coremlData.exists() ||
          !hasWeights) {
        throw StateError(
          'Incomplete Core ML bundle "${p.basename(bundle.path)}". '
          'Missing weight binaries — delete and re-download.',
        );
      }
    }

    final required = <String>{
      'textencoder.mlmodelc',
      'vaedecoder.mlmodelc',
      if (hasChunks) 'unetchunk1.mlmodelc',
      if (hasChunks) 'unetchunk2.mlmodelc',
      if (!hasChunks) 'unet.mlmodelc',
    };
    for (final need in required) {
      if (!names.contains(need)) {
        throw StateError(
            'Download incomplete: missing $need under ${dir.path}.');
      }
    }
  }

  Future<void> cancel(String id) async {
    await ModelDownloadService.instance.cancel(id);
    final entry = _entries[id];
    if (entry == null) return;
    entry.status = LocalSdAssetStatus.notDownloaded;
    entry.progress = 0;
    entry.bytesPerSecond = 0;
    notifyListeners();
  }

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
      if (kDebugMode) debugPrint('🎨 SD delete failed: $e');
    }
    _entries.remove(id);
    await _persist();
    notifyListeners();
  }

  Future<int> totalDiskBytes() async {
    int total = 0;
    for (final e in _entries.values.toList(growable: false)) {
      if (e.status != LocalSdAssetStatus.ready || e.localPath == null) continue;
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

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _entries.values.map((e) => e.toJson()).toList();
      await prefs.setString(_prefsKey, json.encode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('🎨 SD persist failed: $e');
    }
  }
}

class _HfFile {
  final String path;
  final int? size;
  const _HfFile({required this.path, this.size});
}
