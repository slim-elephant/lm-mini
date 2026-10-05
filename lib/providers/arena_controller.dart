/// Orchestrates a single **Arena mode** run and exposes live state to the UI.
///
/// Scheduling rules:
///   - **On-device** contestants run *strictly sequentially* — a phone can't
///     hold two GGUF/MLX models in memory at once, so they take turns.
///   - **LM Studio / cloud** contestants run *concurrently* (network-bound),
///     and may overlap with the on-device chain.
///   - In **benchmark mode** each contestant runs the whole prompt set; its
///     per-prompt metrics are aggregated into one summary.
///
/// The controller is created per-run and scoped to the Arena screen (no global
/// registration), so it can be disposed cleanly when the user leaves.
library;

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/arena_models.dart';
import '../models/local_model_spec.dart';
import '../services/arena_scoring.dart';
import '../utils/remote_host_backends.dart';
import '../services/arena_service.dart';
import '../services/device_capability_service.dart';
import '../services/lm_studio_service.dart';
import '../services/on_device_llm_service.dart';

class ArenaController extends ChangeNotifier {
  final ArenaMode mode;

  /// One prompt for compare mode; the full prompt set for benchmark mode.
  final List<String> prompts;

  /// The benchmark prompt-set id + version (null for compare mode). Recorded
  /// with public benchmark submissions for apples-to-apples aggregation.
  final String? promptSetId;
  final int? promptSetVersion;

  /// When multiple contestants share LM Studio (or another server), whether
  /// to race them concurrently or unload between loads.
  final ArenaSameProviderSchedule sameProviderSchedule;

  final AppSettings settings;
  final List<ArenaContestantResult> results;

  final LMStudioService _lm = LMStudioService();

  ArenaController({
    required this.mode,
    required this.prompts,
    required this.settings,
    required List<ArenaContestant> contestants,
    this.promptSetId,
    this.promptSetVersion,
    this.sameProviderSchedule = ArenaSameProviderSchedule.parallel,
  }) : results = contestants
            .map((c) => ArenaContestantResult(
                  contestant: c,
                  promptCount: prompts.length,
                ))
            .toList(growable: false);

  bool _running = false;
  bool _cancelled = false;
  bool _finished = false;
  ArenaScoreboard? _scoreboard;
  String? _userPickId;
  DeviceCapability? _device;
  DateTime? _startedAt;

  bool get isRunning => _running;
  bool get isFinished => _finished;
  bool get isCancelled => _cancelled;
  ArenaScoreboard? get scoreboard => _scoreboard;
  DateTime? get startedAt => _startedAt;

  /// The user's subjective "best answer" pick (quality), independent of the
  /// objective performance [winnerId].
  String? get userPickId => _userPickId;

  /// Auto-selected performance winner id, available once the run finishes.
  String? get winnerId => _scoreboard?.winnerId;

  DeviceCapability? get device => _device;

  /// The representative prompt shown in the UI (first prompt).
  String get displayPrompt => prompts.isNotEmpty ? prompts.first : '';

  ArenaContestantResult? resultFor(String contestantId) {
    for (final r in results) {
      if (r.contestant.id == contestantId) return r;
    }
    return null;
  }

  /// Starts the run. Safe to call once.
  Future<void> start() async {
    if (_running || _finished) return;
    _running = true;
    _cancelled = false;
    _startedAt = DateTime.now();
    notifyListeners();

    _device = await DeviceCapabilityService.instance.get();

    final onDevice = results.where((r) => r.contestant.isOnDevice).toList();
    final networked = results.where((r) => !r.contestant.isOnDevice).toList();

    Future<void> onDeviceChain() async {
      for (final r in onDevice) {
        if (_cancelled) {
          _markCancelled(r);
          continue;
        }
        await _runContestant(r);
      }
    }

    // Group networked contestants by provider so we can parallelize across
    // backends while optionally serializing within one (LM Studio, etc.).
    final byProvider = <String, List<ArenaContestantResult>>{};
    for (final r in networked) {
      final key = _providerGroupKey(r.contestant);
      byProvider.putIfAbsent(key, () => []).add(r);
    }

    Future<void> runProviderGroup(List<ArenaContestantResult> group) async {
      final isLmStudio = group.isNotEmpty &&
          RemoteHostBackends.usesLmStudioHttp(
              group.first.contestant.providerKind);
      // LM Studio cannot reliably JIT-load two unloaded models at once — the
      // second request often returns "Model does not exist." Always serialize
      // LM Studio races; honor the user's parallel/unload choice for others.
      final serialize = group.length > 1 &&
          (isLmStudio ||
              sameProviderSchedule ==
                  ArenaSameProviderSchedule.unloadBetween);
      if (!serialize) {
        await Future.wait(group.map(_runContestant));
        return;
      }
      // Only unload between models — do NOT call loadModel here. Chat will
      // load once; a separate load created a second LM Studio instance.
      String? previousLmStudioId;
      for (final r in group) {
        if (_cancelled) {
          _markCancelled(r);
          continue;
        }
        if (r.contestant.providerKind == 'lmStudio') {
          if (previousLmStudioId != null &&
              previousLmStudioId != r.contestant.modelId) {
            await _tryUnloadLmStudio(previousLmStudioId);
          }
          previousLmStudioId = r.contestant.modelId;
        }
        await _runContestant(r);
      }
      if (previousLmStudioId != null) {
        await _tryUnloadLmStudio(previousLmStudioId);
      }
    }

    await Future.wait(<Future<void>>[
      onDeviceChain(),
      ...byProvider.values.map(runProviderGroup),
    ]);

    if (!_cancelled) {
      _scoreboard = ArenaScoring.score(results);
    }
    _running = false;
    _finished = true;
    notifyListeners();
  }

  String _providerGroupKey(ArenaContestant c) {
    if (c.cloudProviderId != null && c.cloudProviderId!.isNotEmpty) {
      return '${c.providerKind}:${c.cloudProviderId}';
    }
    return c.providerKind;
  }

  Future<void> _tryUnloadLmStudio(String instanceId) async {
    try {
      await _lm.unloadModel(
        baseUrl: settings.serverUrl,
        instanceId: instanceId,
        apiToken: settings.apiToken,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Arena LM Studio unload failed ($instanceId): $e');
      }
    }
  }

  /// Runs every prompt for one contestant and aggregates the metrics.
  Future<void> _runContestant(ArenaContestantResult r) async {
    if (_cancelled) {
      _markCancelled(r);
      return;
    }
    // Only one on-device model can sit in memory at a time — unload the
    // previous contestant's weights before loading the next.
    if (r.contestant.isOnDevice) {
      await OnDeviceLLMService.instance.prepareForModelSwitch();
    }
    r.status = ArenaContestantStatus.streaming;
    notifyListeners();

    for (var i = 0; i < prompts.length; i++) {
      if (_cancelled) break;
      r.promptIndex = i;
      r.content = '';
      r.reasoning = '';
      notifyListeners();

      final outcome = await _streamOnePrompt(r, prompts[i]);
      if (outcome.error != null) {
        r.error = outcome.error;
        r.status = ArenaContestantStatus.error;
        notifyListeners();
        return;
      }
      if (outcome.metrics != null) r.samples.add(outcome.metrics!);
      if (i == 0) r.sampleAnswer = r.content;
    }

    if (_cancelled) {
      _markCancelled(r);
      notifyListeners();
      return;
    }

    r.metrics = ArenaMetrics.aggregate(r.samples);
    r.fit = _fitFor(r);
    r.status = r.hasContent
        ? ArenaContestantStatus.done
        : ArenaContestantStatus.error;
    if (r.status == ArenaContestantStatus.error) {
      r.error ??= 'No response';
    }
    notifyListeners();

    if (r.contestant.isOnDevice) {
      await OnDeviceLLMService.instance.prepareForModelSwitch();
    }
  }

  Future<_PromptOutcome> _streamOnePrompt(
      ArenaContestantResult r, String prompt) async {
    ArenaMetrics? metrics;
    String? error;
    final sw = Stopwatch()..start();
    double? liveTtftMs;
    try {
      await for (final event in ArenaService.instance.streamContestant(
        contestant: r.contestant,
        prompt: prompt,
        globalSettings: settings,
        isCancelled: () => _cancelled,
      )) {
        switch (event.type) {
          case ArenaStreamEventType.delta:
            r.content += event.text ?? '';
            liveTtftMs ??= sw.elapsedMilliseconds.toDouble();
            _publishLiveMetrics(r, sw, liveTtftMs);
            notifyListeners();
            break;
          case ArenaStreamEventType.reasoning:
            r.reasoning += event.text ?? '';
            liveTtftMs ??= sw.elapsedMilliseconds.toDouble();
            notifyListeners();
            break;
          case ArenaStreamEventType.done:
            metrics = event.metrics;
            if (metrics != null) r.metrics = metrics;
            break;
          case ArenaStreamEventType.error:
            error = event.error;
            break;
        }
      }
    } catch (e) {
      error = e.toString();
    }
    return _PromptOutcome(metrics: metrics, error: error);
  }

  void _publishLiveMetrics(
    ArenaContestantResult r,
    Stopwatch sw,
    double ttftMs,
  ) {
    final tokens = ArenaService.estimateTokens(r.content);
    final totalMs = sw.elapsedMilliseconds.toDouble();
    final genMs = totalMs > ttftMs ? totalMs - ttftMs : totalMs;
    final genSec = genMs > 0 ? genMs / 1000.0 : 0.001;
    r.metrics = ArenaMetrics(
      tokensPerSecond: tokens > 0 ? tokens / genSec : null,
      ttftMs: ttftMs,
      loadMs: r.metrics.loadMs,
      outputTokens: tokens,
      totalMs: totalMs,
      tokensEstimated: true,
    );
  }

  /// Unload every currently loaded LM Studio model (best-effort).
  Future<void> unloadAllLmStudioModels() async {
    try {
      final models = await _lm.getAvailableModels(
        baseUrl: settings.serverUrl,
        apiToken: settings.apiToken,
      );
      for (final m in models.where((m) => m.isLoaded && m.isLLM)) {
        final id = m.loadedInstanceId ?? m.id;
        await _tryUnloadLmStudio(id);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Arena unloadAllLmStudioModels: $e');
    }
  }

  ModelFit? _fitFor(ArenaContestantResult r) {
    final spec = r.contestant.spec;
    if (spec == null) return null;
    return DeviceCapabilityService.instance.verdict(spec, _device);
  }

  void _markCancelled(ArenaContestantResult r) {
    if (r.isTerminal) return;
    r.status = ArenaContestantStatus.cancelled;
  }

  /// Records the user's subjective best-answer pick. Toggling clears it.
  void setUserPick(String contestantId) {
    _userPickId = _userPickId == contestantId ? null : contestantId;
    notifyListeners();
  }

  /// Requests cancellation of any in-flight streams.
  void cancel() {
    if (!_running) return;
    _cancelled = true;
    for (final r in results) {
      if (!r.isTerminal && r.status == ArenaContestantStatus.pending) {
        r.status = ArenaContestantStatus.cancelled;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }
}

class _PromptOutcome {
  final ArenaMetrics? metrics;
  final String? error;
  const _PromptOutcome({this.metrics, this.error});
}
