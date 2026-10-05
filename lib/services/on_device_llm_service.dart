import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/local_model_spec.dart';
import '../utils/chat_message_normalizer.dart';
import '../utils/on_device_attachments.dart';
import '../utils/stream_repetition_guard.dart';
import 'local_model_catalog.dart';
import 'local_model_download_service.dart';
import 'on_device_fllama_endpoint.dart';
import 'on_device_mlx_endpoint.dart';
import 'on_device_moe_stream_endpoint.dart';

/// High-level facade that turns the per-chat message list into a stream of
/// content deltas from whichever on-device engine matches the user's
/// `activeProviderKind` + `selectedLocalModelId`.
///
/// `ChatProvider` calls [streamChat] and writes the deltas straight into
/// the temp assistant message, identical to how it handles LM Studio chunks.
class OnDeviceLLMService {
  OnDeviceLLMService._();
  static final OnDeviceLLMService instance = OnDeviceLLMService._();

  OnDeviceFllamaEndpoint? _activeFllama;
  OnDeviceMlxEndpoint? _activeMlx;
  OnDeviceMoeStreamEndpoint? _activeMoe;

  /// Returns the [LocalModelSpec] currently selected for on-device chat, or
  /// null when no on-device provider/model is active. The catalog is the
  /// source of truth — the persisted setting holds only the id.
  LocalModelSpec? specForSettings(AppSettings settings) {
    final id = settings.selectedLocalModelId;
    if (id == null || id.isEmpty) return null;
    // Catalog lookup first, then downloaded entry (covers custom imports).
    final catalog = LocalModelCatalog.byId(id);
    if (catalog != null) return catalog;
    final entry = LocalModelDownloadService.instance.entryById(id);
    return entry?.spec;
  }

  /// Whether the active on-device provider has a model that is downloaded
  /// and ready to chat. Used by the UI to decide whether to enable the
  /// send button when the user picks On-Device.
  Future<bool> isReady(AppSettings settings) async {
    final spec = specForSettings(settings);
    if (spec == null) return false;
    await LocalModelDownloadService.instance.init();
    final entry = LocalModelDownloadService.instance.entryById(spec.id);
    return entry?.status == LocalModelStatus.ready && entry?.localPath != null;
  }

  /// On-device KV / context size (fllama `contextSize`). Fixed at 8192 —
  /// large enough for PDFs/history, still safe on phone RAM. Higher global
  /// [AppSettings.contextWindow] values (desktop LM Studio) are not used.
  static const int onDeviceContextCap = 8192;

  /// Default max output tokens when [AppSettings.maxTokens] is unset/zero.
  static const int onDeviceDefaultMaxTokens = 2048;

  /// Context size actually used for on-device inference.
  static int effectiveContextSize(AppSettings settings) => onDeviceContextCap;

  /// Streams content deltas for a full chat turn.
  ///
  /// Builds the message list as:
  ///   1. system prompt (when provided)
  ///   2. memory context (when provided) — appended to the system message
  ///   3. each prior chat message in order (with file text re-injected)
  ///   4. the new user message (already includes attachment text from caller)
  Stream<String> streamChat({
    required AppSettings settings,
    required List<ChatMessage> history,
    required String userMessage,
    String? systemPrompt,
    String? memoryContext,
    List<String>? imageUrls,
  }) {
    // Ensure persisted download entries are loaded before we look up paths.
    // Without this, a first chat turn right after install can fail even though
    // the model finished downloading.
    return Stream.fromFuture(LocalModelDownloadService.instance.init())
        .asyncExpand(
      (_) => _streamChatImpl(
        settings: settings,
        history: history,
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        memoryContext: memoryContext,
        imageUrls: imageUrls,
      ),
    );
  }

  Stream<String> _streamChatImpl({
    required AppSettings settings,
    required List<ChatMessage> history,
    required String userMessage,
    String? systemPrompt,
    String? memoryContext,
    List<String>? imageUrls,
  }) async* {
    final spec = specForSettings(settings);
    if (spec == null) {
      throw StateError(
        'No on-device model selected. Open Settings → On-Device Models to '
        'download and activate one.',
      );
    }

    final ctx = effectiveContextSize(settings);
    final attachBudget = OnDeviceAttachments.attachmentCharBudget(ctx);

    // Build messages list. Use records so endpoints don't depend on
    // ChatMessage.
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
      msgs.add((role: 'system', content: sys.toString().trim()));
    }

    // ChatProvider already inserts the current user turn (display text only)
    // into `_currentMessages` before calling us, and passes the full
    // attachment-bearing text as [userMessage]. Drop that trailing duplicate
    // user bubble so the model doesn't see two consecutive user turns.
    final prior = List<ChatMessage>.from(history);
    if (prior.isNotEmpty && prior.last.role == 'user') {
      prior.removeLast();
    }

    for (final m in prior) {
      if (m.id.startsWith('temp_')) continue;
      if (m.role == 'system') continue;
      final rebuilt = OnDeviceAttachments.contentForHistoryMessage(
        m.content,
        files: m.fileAttachments,
        maxChars: attachBudget,
      );
      msgs.add((role: m.role, content: rebuilt));
    }

    var finalUser = userMessage;
    // Prefer plain attachment formatting if the caller still used the
    // markdown/emoji scaffolding from the shared LM Studio path.
    if (finalUser.contains('📎 Attached Files:')) {
      // Leave as-is if already truncated/rebuilt by ChatProvider for on-device;
      // otherwise the shared formatter is fine for a single turn.
    }
    msgs.add((role: 'user', content: finalUser));

    // Gemma 3's chat template throws Jinja.TemplateException unless turns
    // alternate user/assistant after the optional system message.
    final promptMessages = ChatMessageNormalizer.strictTurnOrder(msgs);

    final maxOut =
        settings.maxTokens > 0 ? settings.maxTokens : onDeviceDefaultMaxTokens;
    final temp = settings.temperature;
    final topP = settings.topP;

    final providerKind = settings.activeProviderKind;
    final useMlx = providerKind == 'onDeviceMlx';

    if (useMlx && spec.engine != LocalEngine.mlx) {
      throw StateError(
        'Engine is set to MLX but "${spec.displayName}" is a GGUF model. '
        'Open On-Device Models and activate a GGUF/imported model, or switch '
        'Engine to fllama (GGUF) in Settings.',
      );
    }
    if (!useMlx && spec.engine == LocalEngine.mlx) {
      throw StateError(
        'Engine is set to fllama (GGUF) but "${spec.displayName}" requires '
        'MLX. Activate a GGUF or imported model in On-Device Models, or '
        'switch Engine to MLX in Settings.',
      );
    }

    final hasImages = imageUrls != null && imageUrls.isNotEmpty;
    if (hasImages && !spec.supportsVision) {
      throw StateError(
        '"${spec.displayName}" does not support images. Switch to a vision '
        'on-device model (for example Gemma 3) or remove the image.',
      );
    }

    late final Stream<String> raw;
    if (spec.engine == LocalEngine.moeStream) {
      debugPrint('🧠 OnDeviceLLM streamChat: engine=moeStream id=${spec.id} '
          'msgs=${promptMessages.length} maxOut=$maxOut');
      final ep = _activeMoe = OnDeviceMoeStreamEndpoint(spec);
      raw = ep.streamChat(
        messages: promptMessages,
        maxTokens: maxOut,
        temperature: temp,
        topP: topP,
        contextSize: 2048,
      );
    } else if (useMlx) {
      List<String>? imagePaths;
      if (hasImages) {
        imagePaths = await _materializeImagePaths(imageUrls);
      }
      debugPrint('🧠 OnDeviceLLM streamChat: engine=mlx id=${spec.id} '
          'msgs=${promptMessages.length} '
          'roles=${promptMessages.map((m) => m.role).join(",")} '
          'images=${imagePaths?.length ?? 0} '
          'maxOut=$maxOut temp=$temp topP=$topP');
      final ep = _activeMlx = OnDeviceMlxEndpoint(spec);
      raw = ep.streamChat(
        messages: promptMessages,
        maxTokens: maxOut,
        temperature: temp,
        topP: topP,
        repetitionPenalty:
            settings.repeatPenalty > 0 ? settings.repeatPenalty : 1.1,
        imagePaths: imagePaths,
      );
    } else {
      String? mmprojPath;
      if (hasImages || spec.supportsVision) {
        try {
          mmprojPath =
              await LocalModelDownloadService.instance.ensureMmproj(spec);
        } catch (e) {
          if (hasImages) {
            throw StateError(
              'Vision projector missing for "${spec.displayName}". '
              'Re-download the model from On-Device Models. ($e)',
            );
          }
        }
      }

      // fllama expects images as <img src="data:..."> inside the user text.
      final fllamaMsgs = hasImages
          ? _embedImagesInLastUserMessage(promptMessages, imageUrls)
          : promptMessages;

      debugPrint('🧠 OnDeviceLLM streamChat: engine=fllama id=${spec.id} '
          'msgs=${fllamaMsgs.length} images=${hasImages ? imageUrls.length : 0} '
          'mmproj=${mmprojPath != null} maxOut=$maxOut ctx=$ctx '
          '(settings=${settings.contextWindow})');
      final ep = _activeFllama = OnDeviceFllamaEndpoint(spec);
      raw = ep.streamChat(
        messages: fllamaMsgs,
        maxTokens: maxOut,
        temperature: temp,
        topP: topP,
        contextSize: ctx,
        mmprojPath: mmprojPath,
        // llama.cpp's penalty_repeat (1.1 default) is mapped onto fllama's
        // `presencePenalty`. Honor the user's `repeatPenalty` setting so
        // the on-device knob in Model Parameters has an effect.
        presencePenalty:
            settings.repeatPenalty > 0 ? settings.repeatPenalty : 1.1,
        frequencyPenalty: settings.frequencyPenalty,
      );
    }
    yield* _guardAgainstRepetition(raw);
  }

  List<({String role, String content})> _embedImagesInLastUserMessage(
    List<({String role, String content})> messages,
    List<String> imageUrls,
  ) {
    if (messages.isEmpty) return messages;
    final out = List<({String role, String content})>.from(messages);
    final lastIdx = out.length - 1;
    if (out[lastIdx].role != 'user') return out;

    final imgBlock = StringBuffer();
    for (final url in imageUrls) {
      final dataUrl = _normalizeDataUrl(url);
      if (dataUrl == null) continue;
      imgBlock.writeln('<img src="$dataUrl">');
    }
    if (imgBlock.isEmpty) return out;
    final text = out[lastIdx].content.trim();
    out[lastIdx] = (
      role: 'user',
      content: imgBlock.toString().trim() + (text.isEmpty ? '' : '\n\n$text'),
    );
    return out;
  }

  String? _normalizeDataUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image/')) return trimmed;
    // Already raw base64 — assume jpeg.
    if (RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(trimmed) &&
        trimmed.length > 64) {
      return 'data:image/jpeg;base64,${trimmed.replaceAll(RegExp(r'\s'), '')}';
    }
    return null;
  }

  /// Write data-URL / base64 images to temp files for the MLX bridge.
  Future<List<String>> _materializeImagePaths(List<String> imageUrls) async {
    final dir = await getTemporaryDirectory();
    final out = <String>[];
    var i = 0;
    for (final url in imageUrls) {
      try {
        final bytes = _decodeImageBytes(url);
        if (bytes == null || bytes.isEmpty) continue;
        final ext = _guessImageExt(url);
        final file = File(
            '${dir.path}/on_device_img_${DateTime.now().microsecondsSinceEpoch}_$i.$ext');
        await file.writeAsBytes(bytes, flush: true);
        out.add(file.path);
        i++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🧠 OnDeviceLLM: failed to materialize image: $e');
        }
      }
    }
    return out;
  }

  List<int>? _decodeImageBytes(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image/')) {
      final comma = trimmed.indexOf(',');
      if (comma < 0) return null;
      return base64Decode(trimmed.substring(comma + 1));
    }
    if (trimmed.startsWith('/') || trimmed.startsWith('file://')) {
      final path = trimmed.startsWith('file://')
          ? Uri.parse(trimmed).toFilePath()
          : trimmed;
      final f = File(path);
      if (f.existsSync()) return f.readAsBytesSync();
      return null;
    }
    try {
      return base64Decode(trimmed.replaceAll(RegExp(r'\s'), ''));
    } catch (_) {
      return null;
    }
  }

  String _guessImageExt(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('image/png')) return 'png';
    if (lower.contains('image/webp')) return 'webp';
    if (lower.contains('image/gif')) return 'gif';
    return 'jpg';
  }

  /// Cuts the stream when the model loops the same letter/word/tag.
  Stream<String> _guardAgainstRepetition(Stream<String> source) async* {
    final buf = StringBuffer();
    await for (final delta in source) {
      if (delta.isEmpty) {
        yield delta;
        continue;
      }
      buf.write(delta);
      yield delta;
      if (StreamRepetitionGuard.shouldStop(buf.toString())) {
        if (kDebugMode) {
          debugPrint('🛑 OnDeviceLLM: stopping — repeated output detected '
              '(${buf.length} chars)');
        }
        cancelActive();
        break;
      }
    }
  }

  /// Cancel any active on-device generation. Hooked into the chat Stop button.
  void cancelActive() {
    _activeFllama?.cancel();
    _activeMlx?.cancel();
    _activeMoe?.cancel();
  }

  /// Release native weights and cancel any in-flight generation before loading
  /// a different on-device model (Arena sequential runs, model picker, etc.).
  Future<void> prepareForModelSwitch() async {
    cancelActive();
    await unloadAll();
    // Native runtimes (especially MLX / Metal) need a beat to free GPU memory.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  /// Drop loaded weights from both engines. Call when the user switches
  /// fllama ↔ MLX so the next turn loads on the correct backend.
  Future<void> unloadAll() async {
    _activeFllama?.cancel();
    _activeFllama = null;
    _activeMoe?.cancel();
    final moe = _activeMoe;
    _activeMoe = null;
    if (moe != null) {
      try {
        await moe.unload();
      } catch (e) {
        if (kDebugMode) debugPrint('🧠 OnDeviceLLM unload MoE: $e');
      }
    }
    final mlx = _activeMlx;
    _activeMlx = null;
    if (mlx != null) {
      try {
        await mlx.unload();
      } catch (e) {
        if (kDebugMode) debugPrint('🧠 OnDeviceLLM unload MLX: $e');
      }
    }
  }

  /// Whether [spec] can run under [settings.activeProviderKind].
  bool specMatchesEngine(LocalModelSpec spec, AppSettings settings) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceMlx') return spec.engine == LocalEngine.mlx;
    if (kind == 'onDeviceGguf') {
      return spec.engine == LocalEngine.fllama ||
          spec.engine == LocalEngine.moeStream;
    }
    return true;
  }
}
