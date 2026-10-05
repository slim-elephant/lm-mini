import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/model_download_job.dart';
import '../utils/tar_bz2_extractor.dart';
import 'model_download_platform.dart';
import 'download_progress_activity.dart';

class _SpeedSample {
  final DateTime at;
  final int bytes;
  _SpeedSample(this.at, this.bytes);
}

typedef ModelDownloadPostExtract = Future<void> Function();

/// Unified download queue for model assets (Kokoro, Whisper, GGUF).
///
/// Uses native background download backends on Android/iOS when available,
/// with in-process HTTP + Range resume as fallback on desktop.
class ModelDownloadService extends ChangeNotifier {
  ModelDownloadService._();
  static final ModelDownloadService instance = ModelDownloadService._();

  static const _prefsKey = 'model_download_jobs_v1';

  final Map<String, ModelDownloadJob> _jobs = {};
  final Map<String, HttpClient> _clients = {};
  final Map<String, _SpeedSample> _speedSamples = {};
  final Set<String> _running = {};
  final Set<String> _cancelRequested = {};
  bool _initialized = false;
  bool _nativeChecked = false;
  bool _nativeAvailable = false;

  List<ModelDownloadJob> get jobs =>
      _jobs.values.toList(growable: false);

  ModelDownloadJob? job(String id) => _jobs[id];

  ModelDownloadJob? get firstActiveJob {
    for (final job in _jobs.values) {
      if (job.isActive) return job;
    }
    return null;
  }

  bool isJobActive(String id) {
    final j = _jobs[id];
    return j != null && j.isActive;
  }

  /// True while a native or in-process transfer is running for [id].
  bool isTransferActive(String id) => _running.contains(id);

  Future<bool> _useNativeDownload() async {
    if (!_nativeChecked) {
      ModelDownloadPlatform.instance.ensureInitialized();
      _nativeAvailable = await ModelDownloadPlatform.instance.isAvailable();
      _nativeChecked = true;
    }
    return _nativeAvailable;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final list = json.decode(raw) as List;
      for (final item in list) {
        if (item is! Map) continue;
        final job = ModelDownloadJob.fromJson(item.cast<String, dynamic>());
        if (job.status == ModelDownloadJobStatus.downloading ||
            job.status == ModelDownloadJobStatus.extracting ||
            job.status == ModelDownloadJobStatus.queued) {
          job.status = ModelDownloadJobStatus.interrupted;
          job.errorMessage ??=
              'Download was interrupted. Resuming automatically…';
        }
        _jobs[job.id] = job;
      }
      await _persist();
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ModelDownloadService init failed: $e\n$st');
      }
    }
  }

  /// Download a single file to [destPath] (atomic rename from `.part`).
  Future<bool> runSingleFile({
    required String id,
    required String displayName,
    required String url,
    required String destPath,
    void Function(ModelDownloadJob job)? onProgress,
  }) {
    return _runJob(
      ModelDownloadJob(
        id: id,
        displayName: displayName,
        kind: ModelDownloadJobKind.singleFile,
        sourceUrl: url,
        destPath: destPath,
      ),
      onProgress: onProgress,
    );
  }

  /// Download an archive, extract it, then run [postExtract].
  Future<bool> runArchive({
    required String id,
    required String displayName,
    required String url,
    required String archivePath,
    required String extractDir,
    Future<bool> Function()? validateReady,
    ModelDownloadPostExtract? postExtract,
    void Function(ModelDownloadJob job)? onProgress,
    double downloadProgressWeight = 0.85,
  }) {
    return _runJob(
      ModelDownloadJob(
        id: id,
        displayName: displayName,
        kind: ModelDownloadJobKind.archive,
        sourceUrl: url,
        destPath: archivePath,
        extractDir: extractDir,
      ),
      onProgress: onProgress,
      downloadProgressWeight: downloadProgressWeight,
      postExtract: postExtract,
      validateReady: validateReady,
    );
  }

  Future<void> cancel(String id) async {
    _cancelRequested.add(id);
    if (await _useNativeDownload()) {
      await ModelDownloadPlatform.instance.cancel(id);
    }

    final client = _clients.remove(id);
    client?.close(force: true);
    _running.remove(id);
    _speedSamples.remove(id);

    if (DownloadProgressActivity.instance.isActive) {
      unawaited(DownloadProgressActivity.instance.end(success: false));
    }

    final job = _jobs[id];
    if (job != null) {
      job.status = ModelDownloadJobStatus.cancelled;
      job.progress = 0;
      job.bytesPerSecond = 0;
      job.errorMessage = null;

      try {
        final partial = File(job.partialPath);
        if (await partial.exists()) await partial.delete();
      } catch (_) {}

      await _persist();
    }
    notifyListeners();
  }

  /// Clears a prior user cancel so a new download for [id] can start.
  void resetCancelRequest(String id) => _cancelRequested.remove(id);

  /// Download [url] to [partialPath] using the native or in-process backend.
  ///
  /// Used by multi-file repo downloads (MLX, Core ML SD). [jobId] drives
  /// cancellation — call [cancel] with the same id to abort.
  Future<void> downloadUrlToPartial({
    required String jobId,
    required String displayName,
    required String url,
    required String partialPath,
    required void Function(int bytesDownloaded, int? bytesTotal, int bytesPerSecond)
        onProgress,
    bool showLiveActivity = true,
    bool updateExistingLiveActivity = false,
  }) async {
    if (_cancelRequested.contains(jobId)) {
      throw StateError('cancelled');
    }

    _running.add(jobId);
    final ephemeral = ModelDownloadJob(
      id: jobId,
      displayName: displayName,
      kind: ModelDownloadJobKind.singleFile,
      sourceUrl: url,
      destPath: partialPath.endsWith('.part')
          ? partialPath.substring(0, partialPath.length - 5)
          : partialPath,
      status: ModelDownloadJobStatus.downloading,
    );

    try {
      await _downloadUrlToFile(
        job: ephemeral,
        target: File(partialPath),
        progressScale: 1.0,
        showLiveActivity: showLiveActivity,
        updateExistingLiveActivity: updateExistingLiveActivity,
        onProgress: (_) {
          if (_cancelRequested.contains(jobId)) {
            throw StateError('cancelled');
          }
          onProgress(
            ephemeral.bytesDownloaded,
            ephemeral.bytesTotal,
            ephemeral.bytesPerSecond,
          );
        },
      );
    } finally {
      _running.remove(jobId);
      _clients.remove(jobId)?.close(force: true);
      _speedSamples.remove(jobId);
    }
  }

  Future<bool> _runJob(
    ModelDownloadJob job, {
    void Function(ModelDownloadJob job)? onProgress,
    double downloadProgressWeight = 1.0,
    ModelDownloadPostExtract? postExtract,
    Future<bool> Function()? validateReady,
  }) async {
    await init();
    if (_running.contains(job.id)) return false;

    _cancelRequested.remove(job.id);
    final partial = File(job.partialPath);
    final partialExists = await partial.exists();
    final partialBytes =
        partialExists ? await partial.length() : 0;
    final isResume = partialBytes > 0;

    job.status = ModelDownloadJobStatus.downloading;
    if (!isResume) {
      job.progress = 0;
      job.bytesDownloaded = 0;
      job.bytesTotal = null;
    }
    job.bytesPerSecond = 0;
    job.errorMessage = null;
    job.completedAt = null;
    _jobs[job.id] = job;
    _speedSamples.remove(job.id);
    await _persist();
    notifyListeners();
    onProgress?.call(job);

    _running.add(job.id);
    var success = false;

    try {
      final destFile = File(job.destPath);
      await destFile.parent.create(recursive: true);

      // If archive already downloaded, skip straight to extraction.
      final archiveReady = job.kind == ModelDownloadJobKind.archive &&
          await destFile.exists() &&
          !partialExists;

      if (!archiveReady) {
        if (!isResume && partialExists) {
          await partial.delete();
        }

        await _downloadUrlToFile(
          job: job,
          target: partial,
          progressScale: downloadProgressWeight,
          onProgress: onProgress,
        );

        if (job.kind == ModelDownloadJobKind.singleFile) {
          if (await destFile.exists()) await destFile.delete();
          await partial.rename(job.destPath);
        } else {
          await partial.rename(job.destPath);
        }
      }

      if (job.kind == ModelDownloadJobKind.archive) {
        job.status = ModelDownloadJobStatus.extracting;
        job.progress = downloadProgressWeight;
        notifyListeners();
        onProgress?.call(job);

        final extractSpan = (1.0 - downloadProgressWeight).clamp(0.05, 1.0);
        await extractTarBz2Archive(
          archivePath: job.destPath,
          targetDir: job.extractDir ?? destFile.parent.path,
          onProgress: (extractProgress) {
            job.progress =
                downloadProgressWeight + extractProgress * extractSpan;
            notifyListeners();
            onProgress?.call(job);
          },
        );

        if (await destFile.exists()) {
          await destFile.delete();
        }

        if (postExtract != null) {
          await postExtract();
        }

        if (validateReady != null) {
          final ready = await validateReady();
          if (!ready) {
            throw StateError('Files missing after extraction');
          }
        }
      }

      job.status = ModelDownloadJobStatus.ready;
      job.progress = 1.0;
      job.completedAt = DateTime.now().toUtc().toIso8601String();
      success = true;
    } catch (e) {
      if (job.status != ModelDownloadJobStatus.cancelled) {
        final message = e.toString();
        if (message.contains('cancelled')) {
          job.status = ModelDownloadJobStatus.cancelled;
        } else {
          job.status = ModelDownloadJobStatus.failed;
          job.progress = 0;
          job.errorMessage = message;
        }
      }
      success = false;
    } finally {
      _clients.remove(job.id)?.close(force: true);
      _running.remove(job.id);
      _speedSamples.remove(job.id);
      await _persist();
      notifyListeners();
      onProgress?.call(job);
    }

    return success;
  }

  Future<void> _downloadUrlToFile({
    required ModelDownloadJob job,
    required File target,
    required double progressScale,
    void Function(ModelDownloadJob job)? onProgress,
    bool showLiveActivity = true,
    bool updateExistingLiveActivity = false,
  }) async {
    if (await _useNativeDownload()) {
      await DownloadProgressActivity.instance.prepareAndroidPermission();
      await ModelDownloadPlatform.instance.downloadToPartial(
        jobId: job.id,
        displayName: job.displayName,
        url: job.sourceUrl,
        partialPath: target.path,
        showLiveActivity: showLiveActivity,
        updateExistingLiveActivity: updateExistingLiveActivity,
        onProgress: (bytesDownloaded, bytesTotal, bytesPerSecond) {
          if (job.status == ModelDownloadJobStatus.cancelled) return;
          job.bytesDownloaded = bytesDownloaded;
          job.bytesTotal = bytesTotal;
          if (bytesTotal != null && bytesTotal > 0) {
            job.progress = (bytesDownloaded / bytesTotal) * progressScale;
          }
          // Native iOS reports 0 B/s on most ticks — don't wipe a good sample.
          if (bytesPerSecond > 0) {
            job.bytesPerSecond = bytesPerSecond;
          }
          _touchSpeed(job);
          notifyListeners();
          onProgress?.call(job);
        },
      );
      return;
    }

    final dartOwnsLockScreen = showLiveActivity &&
        !kIsWeb &&
        (Platform.isIOS || Platform.isAndroid);
    if (dartOwnsLockScreen) {
      await DownloadProgressActivity.instance.start(
        displayName: job.displayName,
      );
    }
    try {
      await _downloadUrlToFileInProcess(
        job: job,
        target: target,
        progressScale: progressScale,
        onProgress: (j) {
          onProgress?.call(j);
          if (dartOwnsLockScreen) {
            unawaited(DownloadProgressActivity.instance.update(
              progress: j.progress,
              statusText: j.bytesTotal != null && j.bytesTotal! > 0
                  ? '${(j.progress * 100).round()}%'
                  : 'Downloading…',
            ));
          }
        },
      );
      if (dartOwnsLockScreen) {
        await DownloadProgressActivity.instance.end(success: true);
      }
    } catch (e) {
      if (dartOwnsLockScreen) {
        await DownloadProgressActivity.instance.end(success: false);
      }
      rethrow;
    }
  }

  Future<void> _downloadUrlToFileInProcess({
    required ModelDownloadJob job,
    required File target,
    required double progressScale,
    void Function(ModelDownloadJob job)? onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    _clients[job.id] = client;

    var existingBytes = 0;
    if (await target.exists()) {
      existingBytes = await target.length();
      if (existingBytes > 0) {
        job.bytesDownloaded = existingBytes;
      }
    }

    var uri = Uri.parse(job.sourceUrl);
    HttpClientResponse? response;

    for (var redirects = 0; redirects < 6; redirects++) {
      final request = await client.getUrl(uri);
      if (existingBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
      }
      final res = await request.close();
      if (res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers.value('location') != null) {
        uri = Uri.parse(res.headers.value('location')!);
        existingBytes = 0;
        continue;
      }
      if (res.statusCode == HttpStatus.partialContent ||
          res.statusCode == HttpStatus.ok) {
        if (res.statusCode == HttpStatus.ok && existingBytes > 0) {
          await target.delete();
          existingBytes = 0;
          job.bytesDownloaded = 0;
        }
        response = res;
        break;
      }
      throw HttpException('HTTP ${res.statusCode} for $uri');
    }

    if (response == null) {
      throw const HttpException('Too many redirects');
    }

    final contentLength = response.contentLength;
    if (response.statusCode == HttpStatus.partialContent) {
      final range = response.headers.value(HttpHeaders.contentRangeHeader);
      final totalFromRange = range?.split('/').last;
      final parsedTotal = int.tryParse(totalFromRange ?? '');
      job.bytesTotal = parsedTotal ??
          (contentLength > 0 ? existingBytes + contentLength : null);
    } else {
      job.bytesTotal = contentLength > 0 ? contentLength : null;
    }

    final sink = target.openWrite(
      mode: existingBytes > 0 ? FileMode.append : FileMode.write,
    );
    var received = existingBytes;

    try {
      await for (final chunk in response) {
        if (job.status == ModelDownloadJobStatus.cancelled) {
          throw StateError('cancelled');
        }
        sink.add(chunk);
        received += chunk.length;
        job.bytesDownloaded = received;
        if (job.bytesTotal != null && job.bytesTotal! > 0) {
          job.progress = (received / job.bytesTotal!) * progressScale;
        }
        _touchSpeed(job);
        notifyListeners();
        onProgress?.call(job);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  void _touchSpeed(ModelDownloadJob job) {
    final now = DateTime.now();
    final prev = _speedSamples[job.id];
    if (prev == null) {
      _speedSamples[job.id] = _SpeedSample(now, job.bytesDownloaded);
      return;
    }
    final elapsedMs = now.difference(prev.at).inMilliseconds;
    if (elapsedMs < 400) return;
    final delta = job.bytesDownloaded - prev.bytes;
    if (delta > 0) {
      job.bytesPerSecond = (delta * 1000 / elapsedMs).round();
    }
    _speedSamples[job.id] = _SpeedSample(now, job.bytesDownloaded);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload =
          _jobs.values.map((j) => j.toJson()).toList(growable: false);
      await prefs.setString(_prefsKey, json.encode(payload));
    } catch (e) {
      if (kDebugMode) debugPrint('ModelDownloadService persist failed: $e');
    }
  }
}
