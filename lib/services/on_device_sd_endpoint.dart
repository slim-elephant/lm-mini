import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/local_sd_asset_spec.dart';
import 'local_sd_asset_download_service.dart';

/// Parameters accepted by the on-device Stable Diffusion pipeline. Mirrors
/// the subset of AUTOMATIC1111 params that map cleanly to Apple Core ML SD.
class OnDeviceSdRequest {
  final String prompt;
  final String? negativePrompt;
  final int steps;
  final double cfgScale;
  final int? seed;
  final int width;
  final int height;
  final String checkpointAssetId;
  final String? loraAssetId;
  final String? vaeAssetId;
  final double? loraScale;

  const OnDeviceSdRequest({
    required this.prompt,
    required this.checkpointAssetId,
    this.negativePrompt,
    this.steps = 25,
    this.cfgScale = 7.0,
    this.seed,
    this.width = 512,
    this.height = 512,
    this.loraAssetId,
    this.vaeAssetId,
    this.loraScale,
  });
}

/// Result of an on-device SD txt2img call.
class OnDeviceSdResult {
  /// PNG-encoded bytes ready to display or save.
  final Uint8List pngBytes;
  final int width;
  final int height;
  final int seed;
  const OnDeviceSdResult({
    required this.pngBytes,
    required this.width,
    required this.height,
    required this.seed,
  });
}

/// Adapter that runs Stable Diffusion entirely on device via Core ML.
///
/// Talks to [OnDeviceSdBridge.swift] through [MethodChannel]
/// `lm_mini/on_device_sd`. Checkpoints must be downloaded first via
/// [LocalSdAssetDownloadService] (Apple compiled `.mlmodelc` trees).
///
/// v1: checkpoints only — LoRA/VAE args are rejected with a clear error
/// because catalog LoRAs are PyTorch `.safetensors`, not Core ML adapters.
class OnDeviceSdEndpoint {
  OnDeviceSdEndpoint._();
  static final OnDeviceSdEndpoint instance = OnDeviceSdEndpoint._();

  static const MethodChannel _channel = MethodChannel('lm_mini/on_device_sd');
  static const EventChannel _progress =
      EventChannel('lm_mini/on_device_sd/progress');

  StreamSubscription? _progressSub;

  /// True only on iOS / iPadOS where Core ML SD can run.
  bool get isPlatformSupported => Platform.isIOS;

  /// Resolve the local file/dir for a given asset id, or throw if the user
  /// hasn't downloaded it yet.
  String _resolvePath(String assetId, SdAssetKind expectedKind) {
    final entry = LocalSdAssetDownloadService.instance.entryById(assetId);
    if (entry == null ||
        entry.status != LocalSdAssetStatus.ready ||
        entry.localPath == null) {
      throw StateError(
          'SD asset "$assetId" is not downloaded. Open On-Device SD models and download it first.');
    }
    if (entry.spec.kind != expectedKind) {
      throw ArgumentError(
          'Asset "$assetId" is a ${entry.spec.kind.name}, expected ${expectedKind.name}.');
    }
    return entry.localPath!;
  }

  /// Whether the native bridge is present (SPM attached).
  Future<bool> isNativeAvailable() async {
    if (!isPlatformSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      if (e.code == 'sd_not_bundled' || e.code == 'sd_unsupported_os') {
        return false;
      }
      rethrow;
    }
  }

  /// Pre-load a checkpoint pipeline (optional — [txt2img] loads on demand).
  Future<void> load(String checkpointAssetId) async {
    final path = _resolvePath(checkpointAssetId, SdAssetKind.checkpoint);
    await _channel.invokeMethod('load', {'checkpointPath': path});
  }

  Future<void> unload() async {
    try {
      await _channel.invokeMethod('unload');
    } on MissingPluginException {
      // ignore
    }
  }

  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } on MissingPluginException {
      // ignore
    }
  }

  /// Generate an image entirely on device.
  Future<OnDeviceSdResult> txt2img(
    OnDeviceSdRequest req, {
    void Function(double progress)? onProgress,
  }) async {
    if (!isPlatformSupported) {
      throw UnsupportedError(
          'On-device Stable Diffusion is only available on iOS / iPadOS.');
    }
    if (req.loraAssetId != null || req.vaeAssetId != null) {
      throw UnsupportedError(
          'On-device LoRA/VAE adapters are not supported yet. '
          'Use a Core ML checkpoint only.');
    }

    final checkpointPath =
        _resolvePath(req.checkpointAssetId, SdAssetKind.checkpoint);

    await _progressSub?.cancel();
    if (onProgress != null) {
      _progressSub = _progress.receiveBroadcastStream().listen((event) {
        if (event is num) onProgress(event.toDouble().clamp(0.0, 1.0));
      });
    }

    try {
      final raw = await _channel.invokeMethod<dynamic>('generate', {
        'checkpointPath': checkpointPath,
        'prompt': req.prompt,
        if (req.negativePrompt != null && req.negativePrompt!.isNotEmpty)
          'negativePrompt': req.negativePrompt,
        'steps': req.steps,
        'guidanceScale': req.cfgScale,
        'width': req.width,
        'height': req.height,
        if (req.seed != null) 'seed': req.seed,
      });

      if (raw is! Map) {
        throw StateError('Native SD bridge returned unexpected payload.');
      }
      final map = Map<String, dynamic>.from(raw);
      final pngData = map['png'];
      final Uint8List bytes;
      if (pngData is Uint8List) {
        bytes = pngData;
      } else if (pngData is ByteData) {
        bytes = pngData.buffer.asUint8List();
      } else if (pngData is List<int>) {
        bytes = Uint8List.fromList(pngData);
      } else {
        throw StateError('Native SD bridge returned no PNG bytes.');
      }

      return OnDeviceSdResult(
        pngBytes: bytes,
        width: (map['width'] as num?)?.toInt() ?? req.width,
        height: (map['height'] as num?)?.toInt() ?? req.height,
        seed: (map['seed'] as num?)?.toInt() ?? (req.seed ?? 0),
      );
    } on PlatformException catch (e) {
      debugPrint('OnDeviceSdEndpoint: ${e.code} ${e.message}');
      rethrow;
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
    }
  }
}
