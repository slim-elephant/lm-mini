import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/local_model_spec.dart';
import 'device_capability_service.dart';
import 'llm_endpoint.dart';
import 'local_model_download_service.dart';

/// Adapter that runs inference on Apple Silicon via the MLX-Swift framework.
///
/// **Native bridge status:** the Swift module that hosts MLX is a separate
/// piece of work (an iOS/macOS-only Pod that wraps `mlx-swift-examples`'
/// `LLM` package). This Dart class talks to that module through a
/// [MethodChannel] called `lm_mini/mlx`. Until the Swift side ships, every
/// method returns a structured "not bundled" error so the UI can show a
/// friendly message instead of crashing.
///
/// Why MLX in addition to fllama?
///   - On A17 Pro / M-series, MLX is ~1.5–2× faster than llama.cpp at the
///     same quantization and uses unified memory, which matters on 8 GB
///     iPhones where every spare MB counts.
///   - MLX 4-bit models are smaller than the equivalent GGUF Q4_K_M, which
///     helps free-tier device fit.
///
/// The bridge intentionally exposes ONLY the calls the app needs:
///   - `mlx.load({modelPath})` → opens the model and tokenizer once.
///   - `mlx.generate({prompt, maxTokens, temperature, topP})` → streams
///     chunks back via an event channel `lm_mini/mlx/stream`.
///   - `mlx.unload()` → frees memory when the user switches models.
class OnDeviceMlxEndpoint implements LLMEndpoint {
  final LocalModelSpec spec;
  final LocalModelDownloadService _downloads =
      LocalModelDownloadService.instance;

  static const MethodChannel _channel = MethodChannel('lm_mini/mlx');
  static const EventChannel _stream = EventChannel('lm_mini/mlx/stream');

  OnDeviceMlxEndpoint(this.spec);

  @override
  String get id => 'mlx:${spec.id}';

  @override
  EndpointKind get kind => EndpointKind.onDeviceMlx;

  @override
  String get displayName => '${spec.displayName} (MLX)';

  @override
  EndpointTier get tier =>
      spec.tier == LocalModelTier.free ? EndpointTier.free : EndpointTier.pro;

  @override
  EndpointCapabilities get capabilities => EndpointCapabilities(
        supportsToolCalls: spec.supportsToolCalls,
        supportsVision: spec.supportsVision,
        supportsStreaming: true,
        isMetered: false,
      );

  /// Whether the platform can host MLX at all (Apple Silicon iOS/iPadOS/macOS).
  ///
  /// MLX is intentionally disabled on the iOS Simulator: MLX-Swift's Metal
  /// kernels assume direct Apple-GPU access and crash the app process
  /// during model load on the simulator (no recoverable error reaches
  /// Dart — the Flutter engine just reports "Lost connection to device").
  static Future<bool> isPlatformSupported() async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    if (await _isIosSimulator()) return false;
    final cap = await DeviceCapabilityService.instance.get();
    return cap.supportsMlx;
  }

  static Future<bool> _isIosSimulator() async {
    if (!Platform.isIOS) return false;
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      return !info.isPhysicalDevice;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!await isPlatformSupported()) return false;
    await _downloads.init();
    final entry = _downloads.entryById(spec.id);
    if (entry == null || entry.status != LocalModelStatus.ready) return false;
    if (entry.localPath == null) return false;
    return Directory(entry.localPath!).exists();
  }

  @override
  Future<List<EndpointModelInfo>> listModels() async => [
        EndpointModelInfo(
          id: spec.id,
          displayName: spec.displayName,
          supportsTools: spec.supportsToolCalls,
          supportsVision: spec.supportsVision,
        ),
      ];

  /// Load the model into MLX's memory. Cheap to call repeatedly; the Swift
  /// side keeps a single LRU slot. Throws if the bridge isn't installed.
  Future<void> load() async {
    final entry = _downloads.entryById(spec.id);
    if (entry == null || entry.localPath == null) {
      debugPrint(
          '🧠 MLX load aborted: entry=${entry == null ? 'null' : 'present'} '
          'localPath=${entry?.localPath}');
      throw StateError('MLX model "${spec.displayName}" is not downloaded.');
    }
    final dir = Directory(entry.localPath!);
    final exists = dir.existsSync();
    int fileCount = 0;
    bool hasConfig = false;
    bool hasWeights = false;
    if (exists) {
      try {
        for (final e in dir.listSync(recursive: true, followLinks: false)) {
          if (e is File) {
            fileCount++;
            final name = e.path.toLowerCase();
            if (name.endsWith('/config.json')) hasConfig = true;
            if (name.endsWith('.safetensors')) hasWeights = true;
          }
        }
      } catch (_) {}
    }
    debugPrint(
        '🧠 MLX load: spec=${spec.id} path=${entry.localPath} '
        'exists=$exists files=$fileCount config=$hasConfig weights=$hasWeights');
    if (!exists || !hasConfig || !hasWeights) {
      throw StateError(
          'MLX model directory is incomplete (config=$hasConfig, weights=$hasWeights). '
          'Please re-download the model.');
    }
    if (await _isIosSimulator()) {
      throw StateError(
          'MLX inference is not supported on the iOS Simulator. '
          'MLX-Swift requires Apple GPU access that the simulator does not '
          'provide and the process crashes during model load. Run on a '
          'physical iPhone/iPad, or switch to a GGUF (fllama) model for '
          'simulator testing.');
    }
    // MLX-Swift's Metal init has global state that is flaky on the very first
    // model load in a fresh process (ggml/Metal one-time setup). That cold
    // failure is exactly why users found they had to "switch engines" — an
    // unload + retry clears the bad state. Do that automatically here so the
    // first on-device turn after install is reliable.
    const maxAttempts = 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _channel.invokeMethod('load', {'modelPath': entry.localPath!});
        debugPrint('🧠 MLX load ok: ${spec.id} (attempt $attempt)');
        return;
      } on MissingPluginException {
        throw UnimplementedError(_bridgeMissingMessage);
      } on PlatformException catch (e) {
        debugPrint(
            '🧠 MLX load failed (attempt $attempt/$maxAttempts): '
            '${e.code} ${e.message}');
        // Backgrounded app: iOS forbids GPU work. Not a cold-start glitch, so
        // don't unload the model and retry — just report it.
        if (attempt >= maxAttempts || e.code == 'background') rethrow;
        // Drop any half-initialized native state, give Metal a beat, retry.
        try {
          await _channel.invokeMethod('unload');
        } catch (_) {/* best-effort */}
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
  }

  /// Streams generated tokens. The Swift bridge ends the EventChannel when
  /// generation finishes. When [messages] is provided it is forwarded so the
  /// MLX-side tokenizer applies the model's own chat template; otherwise
  /// [prompt] is sent verbatim (legacy completion path).
  ///
  /// Implemented as `async*` (not a [StreamController] wrapper) so we never
  /// fire a native `cancel` during `load()` — that race was aborting MLX
  /// generations with zero tokens ("no output — the model returned nothing").
  Stream<String> streamCompletion({
    String? prompt,
    List<Map<String, String>>? messages,
    List<String>? imagePaths,
    int maxTokens = 1024,
    double temperature = 0.7,
    double topP = 0.95,
    double repetitionPenalty = 1.1,
  }) async* {
    assert(prompt != null || (messages != null && messages.isNotEmpty),
        'streamCompletion requires either prompt or messages');
    await load();
    final args = <String, dynamic>{
      if (prompt != null) 'prompt': prompt,
      if (messages != null) 'messages': messages,
      if (imagePaths != null && imagePaths.isNotEmpty) 'imagePaths': imagePaths,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'topP': topP,
      'repetitionPenalty': repetitionPenalty,
    };
    var emitted = 0;
    var completedNormally = false;
    try {
      await for (final event in _stream.receiveBroadcastStream(args)) {
        if (event == null) break;
        if (event is String) {
          if (event.isNotEmpty) {
            emitted++;
            yield event;
          }
        }
      }
      completedNormally = true;
    } on MissingPluginException {
      throw UnimplementedError(_bridgeMissingMessage);
    } finally {
      // Only force-cancel when the Dart consumer aborts mid-stream. A normal
      // EndOfEventStream already finished native work — cancelling then just
      // races the next turn and adds noise to device logs.
      if (!completedNormally) {
        try {
          await _channel.invokeMethod('cancel');
        } on MissingPluginException {
          // bridge not installed
        } catch (_) {}
      }
      if (kDebugMode && emitted == 0) {
        debugPrint(
            '🧠 MLX streamCompletion finished with 0 chunks '
            '(maxTokens=$maxTokens msgs=${messages?.length ?? 0})');
      }
    }
  }

  /// Free model weights from memory. Call when the user switches models or
  /// sends the app to the background under memory pressure.
  Future<void> unload() async {
    try {
      await _channel.invokeMethod('unload');
    } on MissingPluginException {
      // no-op
    }
  }

  /// Multi-turn streaming chat. Forwards the messages array to the MLX
  /// bridge so the native side can apply the model's tokenizer chat
  /// template (which varies by family — ChatML / Llama 3 / Qwen / Gemma).
  /// Building the prompt in Dart with a generic ChatML wrapper, as we used
  /// to, produced gibberish on non-ChatML models.
  Stream<String> streamChat({
    required List<({String role, String content})> messages,
    List<String>? imagePaths,
    int maxTokens = 1024,
    double temperature = 0.7,
    double topP = 0.95,
    double repetitionPenalty = 1.1,
  }) {
    final wire = messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    return streamCompletion(
      messages: wire,
      imagePaths: imagePaths,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      repetitionPenalty: repetitionPenalty,
    );
  }

  /// Cancel any in-flight MLX inference. Safe to call when none is active.
  void cancel() {
    try {
      _channel.invokeMethod('cancel');
    } on MissingPluginException {
      // bridge not installed
    } catch (_) {
      // best-effort
    }
  }

  static const String _bridgeMissingMessage =
      'MLX bridge is not bundled in this build. The Swift module under '
      'ios/Runner/MLXBridge.swift (iOS) or macos/Runner/MLXBridge.swift (macOS) '
      'is required for on-device MLX inference; install the MLX SPM packages '
      'and rebuild. Falling back to GGUF (fllama) is recommended in the '
      'meantime.';
}
