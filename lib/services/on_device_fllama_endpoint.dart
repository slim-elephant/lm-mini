import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fllama/fllama.dart' as fllama;

import '../models/local_model_spec.dart';
import '../utils/fllama_cpu_support.dart';
import 'llm_endpoint.dart';
import 'local_model_download_service.dart';
import 'device_capability_service.dart';

/// Adapter that runs inference locally via the fllama (llama.cpp) plugin.
///
/// Wraps fllama's callback-based streaming API into a Dart [Stream] of
/// content deltas that `ChatProvider` can append to the temp assistant
/// message just like it does for LM Studio events.
class OnDeviceFllamaEndpoint implements LLMEndpoint {
  final LocalModelSpec spec;
  final LocalModelDownloadService _downloads =
      LocalModelDownloadService.instance;

  /// Outstanding fllama request id, so we can call
  /// [fllama.fllamaCancelInference] when the user taps Stop.
  int? _activeRequestId;

  OnDeviceFllamaEndpoint(this.spec);

  @override
  String get id => 'fllama:${spec.id}';

  @override
  EndpointKind get kind => EndpointKind.onDeviceGguf;

  @override
  String get displayName => '${spec.displayName} (on-device)';

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

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isAndroid && !Platform.isMacOS) {
      return false;
    }
    if (!FllamaCpuSupport.isSupported) return false;
    await _downloads.init();
    final entry = _downloads.entryById(spec.id);
    if (entry == null || entry.status != LocalModelStatus.ready) return false;
    final path = entry.localPath;
    if (path == null) return false;
    return File(path).exists();
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

  /// Streams content deltas (just the newly-generated text since the last
  /// callback) for a multi-turn chat.
  ///
  /// `messages` should already include the system prompt as the first entry
  /// when one is desired; this method does not auto-inject anything.
  Stream<String> streamChat({
    required List<({String role, String content})> messages,
    int maxTokens = 1024,
    double temperature = 0.7,
    double topP = 0.95,
    int contextSize = 4096,
    int numGpuLayers = 99, // honored on platforms that support GPU offload
    double frequencyPenalty = 0.0,
    // llama.cpp's default penalty_repeat is 1.1; fllama maps `presencePenalty`
    // onto that knob, so 1.1 keeps parity with chat-template-trained models.
    double presencePenalty = 1.1,
    /// Multimodal projector path for vision GGUFs (optional).
    String? mmprojPath,
  }) {
    final controller = StreamController<String>();
    () async {
      // Must run before any package:fllama call: opening libfllama.so on
      // an ARMv8.0 Android phone crashes the whole app (SIGILL).
      if (!FllamaCpuSupport.isSupported) {
        controller.addError(StateError(FllamaCpuSupport.unsupportedMessage));
        await controller.close();
        return;
      }
      if (Platform.isIOS && await _isIosSimulator()) {
        controller.addError(StateError(
          'GGUF (fllama) inference is not available in the iOS Simulator — '
          'the native fllama library is not bundled for simulator builds. '
          'Run on a physical iPhone/iPad to test on-device chat.',
        ));
        await controller.close();
        return;
      }
      final entry = _downloads.entryById(spec.id);
      if (entry == null || entry.localPath == null) {
        controller.addError(StateError(
          'On-device model "${spec.displayName}" is not downloaded.',
        ));
        await controller.close();
        return;
      }
      final path = entry.localPath!;
      if (!await File(path).exists()) {
        controller.addError(StateError('Model file missing on disk: $path'));
        await controller.close();
        return;
      }
      // A model that doesn't fit makes llama.cpp's failed-load cleanup crash
      // the app natively, so refuse it in Dart first.
      if (Platform.isAndroid) {
        final cap = await DeviceCapabilityService.instance.get();
        var bytes = await File(path).length();
        if (mmprojPath != null && await File(mmprojPath).exists()) {
          bytes += await File(mmprojPath).length();
        }
        if (cap.ramGb > 0 && bytes > cap.ramGb * 1e9 * 0.45) {
          controller.addError(StateError(
            '"${spec.displayName}" needs more memory than this phone has '
            '(${cap.ramGb.toStringAsFixed(0)} GB RAM). Pick a smaller model.',
          ));
          await controller.close();
          return;
        }
      }

      // Map our role strings → fllama's Role enum.
      fllama.Role roleFor(String r) {
        switch (r) {
          case 'system':
            return fllama.Role.system;
          case 'assistant':
            return fllama.Role.assistant;
          case 'tool':
            // fllama lacks a dedicated tool role; fold into user so the
            // model still sees the content.
            return fllama.Role.user;
          case 'user':
          default:
            return fllama.Role.user;
        }
      }

      final fllamaMessages = messages
          .map((m) => fllama.Message(roleFor(m.role), m.content))
          .toList();

      final request = fllama.OpenAiRequest(
        modelPath: path,
        mmprojPath: mmprojPath,
        messages: fllamaMessages,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
        contextSize: contextSize,
        numGpuLayers: numGpuLayers,
        frequencyPenalty: frequencyPenalty,
        presencePenalty: presencePenalty,
      );

      // fllama's callback delivers the *full* response so far on every tick;
      // we diff against the previous snapshot to emit incremental deltas.
      String previous = '';
      try {
        final reqId = await fllama.fllamaChat(request, (response, _, done) {
          if (controller.isClosed) return;
          if (response.length > previous.length) {
            controller.add(response.substring(previous.length));
            previous = response;
          }
          if (done) {
            _activeRequestId = null;
            controller.close();
          }
        });
        _activeRequestId = reqId;
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
          await controller.close();
        }
      }
    }();
    return controller.stream;
  }

  /// Cancel any in-flight inference on this endpoint. Safe to call when no
  /// request is active.
  void cancel() {
    final id = _activeRequestId;
    if (id != null) {
      try {
        fllama.fllamaCancelInference(id);
      } catch (_) {/* native may not expose cancel on every platform */}
      _activeRequestId = null;
    }
  }

  static Future<bool> _isIosSimulator() async {
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      return !info.isPhysicalDevice;
    } catch (_) {
      return false;
    }
  }
}
