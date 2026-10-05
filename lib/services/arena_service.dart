/// Backend dispatch + metrics collection for **Arena mode**.
///
/// Each contestant runs a *single isolated turn*: one prompt in, one answer
/// out, with no chat history and no cross-talk between models. That isolation
/// lets this service stay completely decoupled from `ChatProvider` while still
/// reusing the same backend engines (`OnDeviceLLMService`, `LMStudioService`,
/// and cloud via `streamChatCompletion`).
///
/// The service also centralizes the **client-side metrics collector**: because
/// the three backends report timing/usage unevenly (LM Studio V1 reports real
/// stats, on-device reports none, cloud is partial), we wrap every stream in a
/// `Stopwatch` and derive comparable TTFT / tokens / t/s here. Estimated values
/// are flagged via `ArenaMetrics.tokensEstimated`.
library;

import 'package:flutter/foundation.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../models/app_settings.dart';
import '../models/arena_models.dart';
import '../utils/stream_repetition_guard.dart';
import 'lm_studio_service.dart';
import 'on_device_llm_service.dart';

/// Event kinds emitted while a contestant streams.
enum ArenaStreamEventType { delta, reasoning, done, error }

/// A single normalized streaming event for one contestant.
class ArenaStreamEvent {
  final ArenaStreamEventType type;

  /// Visible answer text (for [ArenaStreamEventType.delta]) or reasoning text
  /// (for [ArenaStreamEventType.reasoning]).
  final String? text;

  /// Finalized metrics, present only on [ArenaStreamEventType.done].
  final ArenaMetrics? metrics;

  /// Error message, present only on [ArenaStreamEventType.error].
  final String? error;

  const ArenaStreamEvent._(this.type, {this.text, this.metrics, this.error});

  factory ArenaStreamEvent.delta(String t) =>
      ArenaStreamEvent._(ArenaStreamEventType.delta, text: t);
  factory ArenaStreamEvent.reasoning(String t) =>
      ArenaStreamEvent._(ArenaStreamEventType.reasoning, text: t);
  factory ArenaStreamEvent.done(ArenaMetrics m) =>
      ArenaStreamEvent._(ArenaStreamEventType.done, metrics: m);
  factory ArenaStreamEvent.error(String e) =>
      ArenaStreamEvent._(ArenaStreamEventType.error, error: e);
}

class ArenaService {
  ArenaService._();
  static final ArenaService instance = ArenaService._();

  final LMStudioService _lm = LMStudioService();

  /// Rough token estimate when the backend doesn't report usage. ~4 chars per
  /// token is the common heuristic for English text; good enough for a
  /// relative speed comparison (and always flagged as estimated in the UI).
  static int estimateTokens(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return (trimmed.length / 4).round().clamp(1, 1 << 30);
  }

  /// Default completion budget for Arena text races.
  static const int arenaMaxTokens = 3000;

  /// Extra headroom for reasoning/thinking models (thinking tokens count).
  static const int arenaReasoningMaxTokens = 5000;

  /// Settings for Arena: no persona, no image-gen IMG_PROMPT, no tool/MCP noise.
  /// Forces a higher [maxTokens] than typical chat defaults so answers aren't
  /// cut off mid-benchmark (reasoning models get a larger budget).
  AppSettings _arenaSettings(AppSettings s, {required bool reasoningModel}) =>
      s.copyWith(
        systemPrompt: '',
        selectedSystemPromptId: null,
        imageGenEnabled: false,
        enableToolUse: false,
        mcpServers: <McpServerConfig>[],
        integratedMcps: <IntegratedMcpConfig>[],
        maxTokens: reasoningModel ? arenaReasoningMaxTokens : arenaMaxTokens,
      );

  CloudApiProvider? _cloudProvider(String? id) {
    if (id == null) return null;
    for (final p in CloudApiService().providers) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Streams a single contestant's isolated turn, emitting deltas live and a
  /// final [ArenaStreamEvent.done] carrying computed [ArenaMetrics].
  ///
  /// [isCancelled] is polled between deltas so the controller can abort a run.
  Stream<ArenaStreamEvent> streamContestant({
    required ArenaContestant contestant,
    required String prompt,
    required AppSettings globalSettings,
    required bool Function() isCancelled,
  }) async* {
    final sw = Stopwatch()..start();
    double? ttftMs;
    double? loadMs;
    double? loadStartedAt;
    double? readyAtMs;
    final contentBuf = StringBuffer();
    int? serverTokens;
    double? serverTps;
    String? stopReason;

    final arenaSettings = _arenaSettings(
      globalSettings,
      reasoningModel: contestant.isReasoningModel,
    );

    void markFirstToken() {
      if (ttftMs != null) return;
      final now = sw.elapsedMilliseconds.toDouble();
      // Exclude model-load time when LM Studio reported load events.
      final base = readyAtMs ?? 0;
      ttftMs = (now - base).clamp(0, double.infinity);
    }

    try {
      final kind = contestant.providerKind;

      // ── On-device (fllama / MLX) ──────────────────────────────────────
      if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
        final s = arenaSettings.copyWith(
          activeProviderKind: kind,
          selectedLocalModelId: contestant.modelId,
        );
        await for (final delta in OnDeviceLLMService.instance.streamChat(
          settings: s,
          history: const [],
          userMessage: prompt,
          systemPrompt: '',
        )) {
          if (isCancelled()) break;
          if (delta.isEmpty) continue;
          markFirstToken();
          contentBuf.write(delta);
          yield ArenaStreamEvent.delta(delta);
          if (StreamRepetitionGuard.shouldStop(contentBuf.toString())) {
            stopReason = 'repetition';
            OnDeviceLLMService.instance.cancelActive();
            break;
          }
        }
      }

      // ── Cloud / Ollama / oMLX (CloudApiProvider) ──────────────────────
      else if (kind == 'cloud' || CloudApiType.isFreeLocalKind(kind)) {
        final cp = _cloudProvider(contestant.cloudProviderId);
        if (cp == null) {
          yield ArenaStreamEvent.error(
              'Cloud provider is not configured. Re-add this model in setup.');
          return;
        }
        final formatted = <Map<String, dynamic>>[
          {'role': 'user', 'content': prompt},
        ];

        final cloudSettings = arenaSettings.copyWith(
          serverUrl: cp.effectiveBaseUrl,
          apiToken: cp.apiKey,
          selectedModel: contestant.modelId,
        );

        await for (final chunk in _lm.streamChatCompletion(
          baseUrl: cloudSettings.serverUrl,
          formattedMessages: formatted,
          settings: cloudSettings,
          apiToken: cloudSettings.apiToken,
          cloudProviderType: cp.type,
          extraHeaders:
              cp.type.extraHeaders.isNotEmpty ? cp.type.extraHeaders : null,
        )) {
          if (isCancelled()) break;
          if (chunk.containsKey('error')) {
            final err = chunk['error'];
            yield ArenaStreamEvent.error(
                err is String ? err : (err?.toString() ?? 'Unknown error'));
            return;
          }
          final usage = chunk['usage'];
          if (usage is Map) {
            serverTokens =
                (usage['completion_tokens'] as num?)?.toInt() ?? serverTokens;
          }
          final reasoning = chunk['reasoning'];
          if (reasoning is String && reasoning.isNotEmpty) {
            markFirstToken();
            yield ArenaStreamEvent.reasoning(reasoning);
            continue;
          }
          final content = chunk['content'];
          if (content is String && content.isNotEmpty) {
            markFirstToken();
            contentBuf.write(content);
            yield ArenaStreamEvent.delta(content);
            if (StreamRepetitionGuard.shouldStop(contentBuf.toString())) {
              stopReason = 'repetition';
              break;
            }
          }
        }
      }

      // ── LM Studio (V1 stateful, non-persisted) ────────────────────────
      else {
        await for (final event in _lm.streamStatefulChat(
          baseUrl: arenaSettings.serverUrl,
          modelId: contestant.modelId,
          input: prompt,
          settings: arenaSettings,
          store: false,
          apiToken: arenaSettings.apiToken,
        )) {
          if (isCancelled()) break;
          final type = event['type'] as String?;
          switch (type) {
            case 'model_load.start':
              loadStartedAt ??= sw.elapsedMilliseconds.toDouble();
              break;
            case 'model_load.end':
              final end = sw.elapsedMilliseconds.toDouble();
              readyAtMs = end;
              final started = loadStartedAt;
              if (started != null) {
                final loadedIn = end - started;
                loadMs = loadedIn;
                if (kDebugMode) {
                  debugPrint(
                    'Arena load time for ${contestant.displayName}: '
                    '${loadedIn.toStringAsFixed(0)} ms',
                  );
                }
              }
              break;
            case 'reasoning.delta':
              markFirstToken();
              yield ArenaStreamEvent.reasoning(
                  event['content'] as String? ?? '');
              break;
            case 'message.delta':
              markFirstToken();
              final d = event['content'] as String? ?? '';
              contentBuf.write(d);
              yield ArenaStreamEvent.delta(d);
              if (StreamRepetitionGuard.shouldStop(contentBuf.toString())) {
                stopReason = 'repetition';
              }
              break;
            case 'error':
              final err = event['error'];
              final msg = err is Map
                  ? (err['message']?.toString() ?? 'Unknown error')
                  : (err?.toString() ?? 'Unknown error');
              yield ArenaStreamEvent.error(msg);
              return;
            case 'chat.end':
              final stats = event['stats'] as Map<String, dynamic>? ??
                  event['usage'] as Map<String, dynamic>?;
              if (stats != null) {
                serverTps = (stats['tokens_per_second'] as num?)?.toDouble();
                serverTokens =
                    (stats['total_output_tokens'] as num?)?.toInt() ??
                        (stats['completion_tokens'] as num?)?.toInt();
                stopReason = stats['stop_reason'] as String?;
              }
              break;
            default:
              // Some paths yield reasoning/content without a type field.
              final reasoning = event['reasoning'];
              if (reasoning is String && reasoning.isNotEmpty) {
                markFirstToken();
                yield ArenaStreamEvent.reasoning(reasoning);
              }
              final content = event['content'];
              if (content is String &&
                  content.isNotEmpty &&
                  event['reasoning'] == null) {
                markFirstToken();
                contentBuf.write(content);
                yield ArenaStreamEvent.delta(content);
                if (StreamRepetitionGuard.shouldStop(contentBuf.toString())) {
                  stopReason = 'repetition';
                }
              }
              break;
          }
          if (stopReason == 'repetition') break;
        }
      }

      sw.stop();
      if (isCancelled()) return;
      yield ArenaStreamEvent.done(_finalizeMetrics(
        totalMs: sw.elapsedMilliseconds.toDouble(),
        ttftMs: ttftMs,
        loadMs: loadMs,
        content: contentBuf.toString(),
        serverTokens: serverTokens,
        serverTps: serverTps,
        stopReason: stopReason,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ArenaService error (${contestant.displayName}): $e');
      }
      yield ArenaStreamEvent.error(e.toString());
    }
  }

  ArenaMetrics _finalizeMetrics({
    required double totalMs,
    required double? ttftMs,
    required double? loadMs,
    required String content,
    required int? serverTokens,
    required double? serverTps,
    required String? stopReason,
  }) {
    final estimated = serverTokens == null;
    final tokens = serverTokens ?? estimateTokens(content);

    double? tps = serverTps;
    if (tps == null && tokens > 0) {
      // Throughput should reflect generation only, excluding the initial
      // time-to-first-token latency (and load, which is already excluded from TTFT).
      final genMs = (ttftMs != null && ttftMs < totalMs)
          ? (totalMs - (loadMs ?? 0) - ttftMs)
          : totalMs - (loadMs ?? 0);
      final genSec = genMs > 0 ? genMs / 1000.0 : 0.001;
      if (genSec > 0) tps = tokens / genSec;
    }

    return ArenaMetrics(
      tokensPerSecond: tps,
      ttftMs: ttftMs,
      loadMs: loadMs,
      outputTokens: tokens,
      totalMs: totalMs,
      tokensEstimated: estimated,
      stopReason: stopReason,
    );
  }
}
