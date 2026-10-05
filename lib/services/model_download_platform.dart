import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native background download bridge (Android foreground service, iOS URLSession).
class ModelDownloadPlatform {
  ModelDownloadPlatform._();
  static final ModelDownloadPlatform instance = ModelDownloadPlatform._();

  static const _channel = MethodChannel('net.neuro9.lmmini/model_download');

  final Map<String, _ActiveDownload> _active = {};

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Register handlers for native progress / completion callbacks.
  void ensureInitialized() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onProgress':
          final args = call.arguments as Map?;
          if (args == null) return;
          final jobId = args['jobId'] as String?;
          if (jobId == null) return;
          final active = _active[jobId];
          if (active == null) return;
          // Android may send 64-bit counts as num; avoid hard `as int` casts.
          active.onProgress(
            _asInt(args['bytesDownloaded']),
            _asIntOrNull(args['bytesTotal']),
            _asInt(args['bytesPerSecond']),
          );
          break;
        case 'onComplete':
          final args = call.arguments as Map?;
          final jobId = args?['jobId'] as String?;
          if (jobId == null) return;
          _active.remove(jobId)?.complete();
          break;
        case 'onError':
          final args = call.arguments as Map?;
          final jobId = args?['jobId'] as String?;
          if (jobId == null) return;
          final message = args?['message'] as String? ?? 'Download failed';
          _active.remove(jobId)?.completeError(message);
          break;
        case 'onCancelled':
          final jobId = call.arguments as String?;
          if (jobId == null) return;
          _active.remove(jobId)?.completeError('cancelled');
          break;
      }
    });
  }

  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Download [url] to [partialPath], resuming if the partial file exists.
  Future<void> downloadToPartial({
    required String jobId,
    required String displayName,
    required String url,
    required String partialPath,
    required void Function(
            int bytesDownloaded, int? bytesTotal, int bytesPerSecond)
        onProgress,
    bool showLiveActivity = true,
    bool updateExistingLiveActivity = false,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('Native downloads unavailable on this platform');
    }

    ensureInitialized();

    final completer = Completer<void>();
    _active[jobId] = _ActiveDownload(
      completer: completer,
      onProgress: onProgress,
    );

    try {
      await _channel.invokeMethod('startDownload', {
        'jobId': jobId,
        'displayName': displayName,
        'url': url,
        'partialPath': partialPath,
        'showLiveActivity': showLiveActivity,
        'updateExistingLiveActivity': updateExistingLiveActivity,
      });
      await completer.future;
    } finally {
      _active.remove(jobId);
    }
  }

  Future<void> cancel(String jobId) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('cancelDownload', {'jobId': jobId});
    } catch (_) {}
    _active.remove(jobId);
  }

  Future<void> startDownloadLiveActivity({
    required String displayName,
    double progress = 0,
    String statusText = 'Starting…',
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('startDownloadLiveActivity', {
        'displayName': displayName,
        'progress': progress,
        'statusText': statusText,
      });
    } catch (e) {
      debugPrint('ModelDownloadPlatform: Live Activity start failed: $e');
    }
  }

  Future<void> updateDownloadLiveActivity({
    required String displayName,
    required double progress,
    required String statusText,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('updateDownloadLiveActivity', {
        'displayName': displayName,
        'progress': progress,
        'statusText': statusText,
      });
    } catch (_) {}
  }

  Future<void> endDownloadLiveActivity({bool success = true}) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('endDownloadLiveActivity', {
        'success': success,
      });
    } catch (_) {}
  }
}

class _ActiveDownload {
  final Completer<void> completer;
  final void Function(int bytesDownloaded, int? bytesTotal, int bytesPerSecond)
      onProgress;

  _ActiveDownload({
    required this.completer,
    required this.onProgress,
  });

  void complete() {
    if (!completer.isCompleted) completer.complete();
  }

  void completeError(Object error) {
    if (!completer.isCompleted) completer.completeError(error);
  }
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
