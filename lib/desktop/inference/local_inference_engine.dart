import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/app_settings.dart';
import '../../models/chat_message.dart';
import '../../models/local_model_spec.dart';
import '../../services/local_model_download_service.dart';
import '../../services/on_device_llm_service.dart';
import '../desktop_platform.dart';
import '../runtime/desktop_runtime_manager.dart';
import 'desktop_sidecar_client.dart';

/// Platform-aware inference facade.
///
/// - **Phone / default:** delegates to existing [OnDeviceLLMService] (MLX/fllama)
///   with zero behavior change.
/// - **Desktop (when sidecar available):** loads GGUF into `llama-server` and
///   streams via OpenAI-compatible HTTP.
///
/// ChatProvider can keep calling [OnDeviceLLMService] on mobile. Desktop may
/// route through this engine when [preferDesktopSidecar] is true.
class LocalInferenceEngine {
  LocalInferenceEngine._();
  static final LocalInferenceEngine instance = LocalInferenceEngine._();

  final _runtime = DesktopRuntimeManager.instance;
  final _sidecar = DesktopSidecarClient();

  /// When true on desktop, use the sidecar if the binary is present.
  /// Falls back to [OnDeviceLLMService] if the sidecar cannot start.
  bool preferDesktopSidecar = true;

  LocalModelSpec? specForSettings(AppSettings settings) =>
      OnDeviceLLMService.instance.specForSettings(settings);

  Future<bool> isReady(AppSettings settings) =>
      OnDeviceLLMService.instance.isReady(settings);

  /// Whether desktop will attempt the sidecar for this turn.
  Future<bool> willUseSidecar(AppSettings settings) async {
    if (!DesktopPlatform.supportsSidecarRuntime || !preferDesktopSidecar) {
      return false;
    }
    final spec = specForSettings(settings);
    if (spec == null) return false;
    // Sidecar is GGUF/llama.cpp today; MLX stays on the native bridge.
    if (spec.engine == LocalEngine.mlx) return false;
    if (spec.engine == LocalEngine.moeStream) return false;
    return _runtime.isBinaryAvailable;
  }

  Stream<String> streamChat({
    required AppSettings settings,
    required List<ChatMessage> history,
    required String userMessage,
    String? systemPrompt,
    String? memoryContext,
    List<String>? imageUrls,
  }) {
    return Stream.fromFuture(_shouldUseSidecar(settings)).asyncExpand((use) {
      if (!use) {
        return OnDeviceLLMService.instance.streamChat(
          settings: settings,
          history: history,
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          memoryContext: memoryContext,
          imageUrls: imageUrls,
        );
      }
      return _streamViaSidecar(
        settings: settings,
        history: history,
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        memoryContext: memoryContext,
      );
    });
  }

  Future<bool> _shouldUseSidecar(AppSettings settings) async {
    try {
      return await willUseSidecar(settings);
    } catch (_) {
      return false;
    }
  }

  Stream<String> _streamViaSidecar({
    required AppSettings settings,
    required List<ChatMessage> history,
    required String userMessage,
    String? systemPrompt,
    String? memoryContext,
  }) async* {
    final spec = specForSettings(settings);
    if (spec == null) {
      throw StateError('No on-device model selected.');
    }

    await LocalModelDownloadService.instance.init();
    final entry = LocalModelDownloadService.instance.entryById(spec.id);
    final path = entry?.localPath;
    if (path == null || entry?.status != LocalModelStatus.ready) {
      throw StateError(
        'Model "${spec.displayName}" is not downloaded yet.',
      );
    }

    // GGUF file path — MLX dirs are not used here.
    var modelPath = path;
    if (!modelPath.toLowerCase().endsWith('.gguf')) {
      final dir = Directory(path);
      if (await dir.exists()) {
        final ggufs = await dir
            .list()
            .where((e) => e.path.toLowerCase().endsWith('.gguf'))
            .cast<FileSystemEntity>()
            .toList();
        if (ggufs.isNotEmpty) modelPath = ggufs.first.path;
      }
    }

    debugPrint(
      '🖥️ LocalInferenceEngine: desktop sidecar id=${spec.id} path=$modelPath',
    );

    final started = await _runtime.ensureStarted(
      modelPath: modelPath,
      contextSize: OnDeviceLLMService.onDeviceContextCap,
    );
    if (!started) {
      debugPrint(
        '🖥️ Sidecar failed (${_runtime.lastError}) — falling back to fllama',
      );
      yield* OnDeviceLLMService.instance.streamChat(
        settings: settings,
        history: history,
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        memoryContext: memoryContext,
      );
      return;
    }

    final msgs = <({String role, String content})>[];
    final sys = StringBuffer();
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      sys.writeln(systemPrompt.trim());
    }
    if (memoryContext != null && memoryContext.trim().isNotEmpty) {
      if (sys.isNotEmpty) sys.writeln();
      sys.writeln(memoryContext.trim());
    }
    if (sys.isNotEmpty) {
      msgs.add((role: 'system', content: sys.toString()));
    }
    final prior = List<ChatMessage>.from(history);
    if (prior.isNotEmpty && prior.last.role == 'user') {
      prior.removeLast();
    }
    for (final m in prior) {
      if (m.id.startsWith('temp_')) continue;
      if (m.role == 'system') continue;
      final content = m.content.trim();
      if (content.isEmpty) continue;
      msgs.add((role: m.role, content: content));
    }
    msgs.add((role: 'user', content: userMessage));

    yield* _sidecar.streamChat(
      messages: msgs,
      temperature: settings.temperature,
      maxTokens: settings.maxTokens <= 0
          ? OnDeviceLLMService.onDeviceDefaultMaxTokens
          : settings.maxTokens,
      topP: settings.topP,
    );
  }

  Future<void> unload() async {
    if (DesktopPlatform.supportsSidecarRuntime) {
      await _runtime.stop();
    }
    await OnDeviceLLMService.instance.unloadAll();
  }
}
