import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'device_capability_service.dart';
import 'llm_endpoint.dart';

/// Adapter for Apple's on-device foundation model (Apple Intelligence /
/// `FoundationModels` framework, iOS 26+ / macOS 26+).
///
/// **Native bridge status:** like [OnDeviceMlxEndpoint], this Dart class
/// talks to a Swift module through a [MethodChannel] (`lm_mini/apple_ai`).
/// Until the Swift module ships, calls return a structured "not bundled"
/// error so the UI can show a "Requires iOS 26 / Apple Intelligence" hint.
///
/// Differences vs. the other on-device endpoints:
///   - No download, no model picker — Apple ships and updates the model.
///   - Always free (Apple-provided) and always small (~3B params).
///   - Tool calling is supported via Apple's `Tool` protocol; we expose
///     `supportsToolCalls = true` and let the bridge translate.
///   - Vision is supported on iOS 26+ device-class hardware.
class AppleIntelligenceEndpoint implements LLMEndpoint {
  static const MethodChannel _channel = MethodChannel('lm_mini/apple_ai');
  static const EventChannel _stream = EventChannel('lm_mini/apple_ai/stream');

  AppleIntelligenceEndpoint();

  @override
  String get id => 'apple_intelligence';

  @override
  EndpointKind get kind => EndpointKind.appleIntelligence;

  @override
  String get displayName => 'Apple Intelligence';

  @override
  EndpointTier get tier => EndpointTier.free;

  @override
  EndpointCapabilities get capabilities => const EndpointCapabilities(
        supportsToolCalls: true,
        supportsVision: true,
        supportsStreaming: true,
        isMetered: false,
      );

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    final cap = await DeviceCapabilityService.instance.get();
    if (!cap.supportsAppleIntelligence) return false;
    try {
      final available =
          await _channel.invokeMethod<bool>('isAvailable') ?? false;
      return available;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<EndpointModelInfo>> listModels() async => const [
        EndpointModelInfo(
          id: 'apple-intelligence-default',
          displayName: 'Apple Intelligence (system model)',
          supportsTools: true,
          supportsVision: true,
        ),
      ];

  /// Streams generated tokens from FoundationModels' `LanguageModelSession`.
  /// The Swift bridge sends `null` to signal completion.
  Stream<String> streamCompletion({
    required String prompt,
    int maxTokens = 1024,
    double temperature = 0.7,
  }) {
    final controller = StreamController<String>();
    StreamSubscription? sub;
    () async {
      try {
        sub = _stream.receiveBroadcastStream({
          'prompt': prompt,
          'maxTokens': maxTokens,
          'temperature': temperature,
        }).listen(
          (event) {
            if (event == null) {
              controller.close();
              return;
            }
            if (event is String) controller.add(event);
          },
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: true,
        );
      } catch (e) {
        controller.addError(e);
        await controller.close();
      }
    }();
    controller.onCancel = () async {
      await sub?.cancel();
      try {
        await _channel.invokeMethod('cancel');
      } on MissingPluginException {
        // bridge not installed
      }
    };
    return controller.stream;
  }
}
