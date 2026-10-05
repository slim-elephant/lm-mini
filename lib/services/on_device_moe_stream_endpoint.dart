import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

import '../models/local_model_spec.dart';
import 'llm_endpoint.dart';
import 'local_model_download_service.dart';

/// On-device GGUF Mixture-of-Experts streaming (BigMoeOnEdge).
///
/// iOS physical device only. Experts stay on flash; RAM holds dense weights
/// plus a ~2 GB expert cache. The native lib is optional — until
/// `ios/scripts/fetch_and_build_bmoe.sh` is run, [streamChat] throws a
/// message telling the developer to link it.
class OnDeviceMoeStreamEndpoint implements LLMEndpoint {
  final LocalModelSpec spec;
  final LocalModelDownloadService _downloads =
      LocalModelDownloadService.instance;

  static const MethodChannel _channel = MethodChannel('lm_mini/moe_stream');
  static const EventChannel _stream = EventChannel('lm_mini/moe_stream/stream');

  OnDeviceMoeStreamEndpoint(this.spec);

  @override
  String get id => 'moeStream:${spec.id}';

  @override
  EndpointKind get kind => EndpointKind.onDeviceGguf;

  @override
  String get displayName => '${spec.displayName} (stream)';

  @override
  EndpointTier get tier =>
      spec.tier == LocalModelTier.free ? EndpointTier.free : EndpointTier.pro;

  @override
  EndpointCapabilities get capabilities => EndpointCapabilities(
        supportsToolCalls: spec.supportsToolCalls,
        supportsVision: false,
        supportsStreaming: true,
        isMetered: false,
      );

  static Future<bool> isPlatformSupported() async {
    if (!Platform.isIOS) return false;
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      if (!info.isPhysicalDevice) return false;
    } catch (_) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> isAvailable() async {
    if (!await isPlatformSupported()) return false;
    await _downloads.init();
    final entry = _downloads.entryById(spec.id);
    if (entry == null || entry.status != LocalModelStatus.ready) return false;
    if (entry.localPath == null) return false;
    return File(entry.localPath!).exists();
  }

  @override
  Future<List<EndpointModelInfo>> listModels() async => [
        EndpointModelInfo(
          id: spec.id,
          displayName: spec.displayName,
          supportsTools: spec.supportsToolCalls,
          supportsVision: false,
        ),
      ];

  Future<void> load({int nCtx = 2048, int cacheMb = 0}) async {
    final entry = _downloads.entryById(spec.id);
    if (entry == null || entry.localPath == null) {
      throw StateError('MoE model "${spec.displayName}" is not downloaded.');
    }
    if (!await File(entry.localPath!).exists()) {
      throw StateError('Model file missing on disk: ${entry.localPath}');
    }
    if (!await isPlatformSupported()) {
      throw StateError(
        'MoE streaming is iPhone/iPad only (not Simulator, not Android).',
      );
    }
    try {
      final available = await _channel.invokeMethod<bool>('available');
      if (available != true) {
        throw StateError(
          'MoE stream native engine is not linked. On a Mac run '
          'ios/scripts/fetch_and_build_bmoe.sh then rebuild the iOS app.',
        );
      }
      await _channel.invokeMethod('load', {
        'modelPath': entry.localPath,
        'nCtx': nCtx,
        'nThreads': 4,
        'cacheMb': cacheMb,
      });
    } on PlatformException catch (e) {
      throw StateError(e.message ?? e.code);
    } on MissingPluginException {
      throw StateError(
        'MoE stream plugin missing. Rebuild the iOS Runner after adding '
        'MoeStreamBridge.swift.',
      );
    }
  }

  Stream<String> streamChat({
    required List<({String role, String content})> messages,
    int maxTokens = 1024,
    double temperature = 0.7,
    double topP = 0.95,
    int contextSize = 2048,
  }) async* {
    await load(nCtx: contextSize > 4096 ? 2048 : contextSize);
    final prompt = _toChatMl(messages);
    var completedNormally = false;
    try {
      await for (final event in _stream.receiveBroadcastStream({
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'topP': topP,
      })) {
        if (event == null) break;
        if (event is String && event.isNotEmpty) yield event;
      }
      completedNormally = true;
    } on PlatformException catch (e) {
      throw StateError(e.message ?? e.code);
    } on MissingPluginException {
      throw StateError('MoE stream plugin missing.');
    } finally {
      if (!completedNormally) {
        try {
          await _channel.invokeMethod('cancel');
        } catch (_) {}
      }
    }
  }

  void cancel() {
    unawaited(_channel.invokeMethod('cancel').catchError((_) {}));
  }

  Future<void> unload() async {
    try {
      await _channel.invokeMethod('unload');
    } catch (_) {}
  }

  static String _toChatMl(List<({String role, String content})> messages) {
    final buf = StringBuffer();
    for (final m in messages) {
      buf.writeln('<|im_start|>${m.role}');
      buf.writeln(m.content.trim());
      buf.writeln('<|im_end|>');
    }
    buf.write('<|im_start|>assistant\n');
    return buf.toString();
  }
}
