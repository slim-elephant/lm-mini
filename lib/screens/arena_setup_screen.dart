import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../models/arena_models.dart';
import '../models/local_model_spec.dart';
import '../models/lm_studio_model.dart';
import '../pro/pro_features.dart';
import '../providers/settings_provider.dart';
import '../services/arena_prompt_set.dart';
import '../services/device_capability_service.dart';
import '../services/lm_studio_service.dart';
import '../services/local_model_download_service.dart';
import '../services/on_device_llm_service.dart';
import '../utils/client_platform.dart';
import '../utils/remote_host_backends.dart';
import '../widgets/glass_page_header.dart';
import '../widgets/home_glass_header.dart';
import 'arena_history_screen.dart';
import 'arena_screen.dart';
import 'subscription_screen.dart';

/// Arena hub: pick models via Provider → Model (mix phone + desktop freely).
class ArenaSetupScreen extends StatefulWidget {
  final bool wizardMode;

  /// When true, skip the Scaffold/AppBar chrome for embedding in DesktopShell.
  final bool embedded;

  const ArenaSetupScreen(
      {super.key, this.wizardMode = false, this.embedded = false});

  @override
  State<ArenaSetupScreen> createState() => _ArenaSetupScreenState();
}

class _ArenaSetupScreenState extends State<ArenaSetupScreen> {
  static const List<int> _accents = [
    0xFF6C5CE7,
    0xFF00B894,
    0xFF0984E3,
    0xFFE17055,
    0xFFE84393,
  ];

  static const List<String> _promptIdeas = [
    'Explain quantum entanglement to a curious 12-year-old.',
    'Write a haiku about debugging at 3am.',
    'Summarize the pros and cons of remote work in 5 bullets.',
    'Give me a one-paragraph plot for a sci-fi short story.',
  ];

  final TextEditingController _promptController = TextEditingController();
  final List<ArenaContestant> _contestants = [];
  ArenaMode _mode = ArenaMode.benchmark;
  bool _useQuickSuite = true;
  ArenaSameProviderSchedule _sameProviderSchedule =
      ArenaSameProviderSchedule.parallel;
  bool _unloadBeforeRace = false;
  int _loadedLmStudioCount = 0;
  DeviceCapability? _device;
  bool _loadingDevice = true;

  bool get _isPremium => SubscriptionService().isPremium;
  int get _maxContestants => 4;

  @override
  void initState() {
    super.initState();
    if (widget.wizardMode) {
      _mode = ArenaMode.benchmark;
      _useQuickSuite = true;
    }
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    final cap = await DeviceCapabilityService.instance.get();
    if (!mounted) return;
    setState(() {
      _device = cap;
      _loadingDevice = false;
    });
    if (_contestants.isEmpty) {
      final picks = _suggestedContestants(limit: 2);
      if (picks.isNotEmpty) setState(() => _contestants.addAll(picks));
    }
    _refreshLoadedHint();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _selectMode(ArenaMode mode) {
    if (mode == ArenaMode.compare && !_isPremium) {
      _showUpgrade();
      return;
    }
    setState(() => _mode = mode);
  }

  void _addContestant(ArenaContestant c) {
    final dup = _contestants
        .any((e) => e.modelId == c.modelId && e.providerKind == c.providerKind);
    if (dup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already in this race.')),
      );
      return;
    }
    if (_contestants.length >= _maxContestants) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Up to $_maxContestants per race.')),
      );
      return;
    }
    if (c.isOnDevice && ClientPlatform.isIosSimulator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'On-device models need a real iPhone/iPad — the Simulator '
            'cannot run GGUF/MLX.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
    setState(() => _contestants.add(c));
    _refreshLoadedHint();
  }

  void _removeContestant(String id) {
    setState(() => _contestants.removeWhere((c) => c.id == id));
    _refreshLoadedHint();
  }

  bool get _showsUnloadOption => _contestants.any((c) =>
      c.providerKind == 'lmStudio' ||
      c.providerKind == 'ollama' ||
      c.providerKind == 'omlx' ||
      c.isOnDevice);

  Future<void> _refreshLoadedHint() async {
    if (!_contestants.any((c) => c.providerKind == 'lmStudio')) {
      if (mounted) setState(() => _loadedLmStudioCount = 0);
      return;
    }
    try {
      final settings = context.read<SettingsProvider>().settings;
      final models = await LMStudioService().getAvailableModels(
        baseUrl: settings.serverUrl,
        apiToken: settings.apiToken,
      );
      final n = models.where((m) => m.isLoaded && m.isLLM).length;
      if (mounted) {
        setState(() {
          _loadedLmStudioCount = n;
          if (n > 0) _unloadBeforeRace = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadedLmStudioCount = 0);
    }
  }

  Future<void> _unloadLoadedBeforeRace() async {
    final settings = context.read<SettingsProvider>().settings;
    final lm = LMStudioService();
    if (_contestants.any((c) => c.providerKind == 'lmStudio')) {
      try {
        final models = await lm.getAvailableModels(
          baseUrl: settings.serverUrl,
          apiToken: settings.apiToken,
        );
        for (final m in models.where((m) => m.isLoaded && m.isLLM)) {
          try {
            await lm.unloadModel(
              baseUrl: settings.serverUrl,
              instanceId: m.loadedInstanceId ?? m.id,
              apiToken: settings.apiToken,
            );
          } catch (_) {}
        }
      } catch (_) {}
    }
    if (_contestants.any((c) => c.isOnDevice)) {
      await OnDeviceLLMService.instance.prepareForModelSwitch();
    }
  }

  int _nextColor() => _accents[_contestants.length % _accents.length];

  Future<void> _openAddFlow() async {
    if (_contestants.length >= _maxContestants) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Up to $_maxContestants per race.')),
      );
      return;
    }
    final picked = await showModalBottomSheet<ArenaContestant>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _ProviderThenModelSheet(
        nextColor: _nextColor(),
        device: _device,
        isPremium: _isPremium,
      ),
    );
    if (picked != null && mounted) _addContestant(picked);
  }

  void _showUpgrade() {
    // Public build: no paywall (every caller is hidden there too).
    if (!ProFeatures.included) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<bool> _ensureConsent() async {
    final sp = context.read<SettingsProvider>();
    final s = sp.settings;
    final isPremium = _isPremium;

    // Free: anonymous speed share is mandatory. Keep the flag on even if an
    // older build left it off.
    if (!isPremium) {
      if (s.hasAcceptedArenaDataShare && s.arenaShareAnonymousResults) {
        return true;
      }
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Anonymous speed results'),
          content: const Text(
            'Free Arena races share anonymous speed data (device class, model, '
            'and tokens/sec). Prompts and answers are never uploaded.\n\n'
            'This builds a community leaderboard so others can pick models that '
            'fit their phones. Continue to start the race.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return false;
      await sp.updateSettings(
        s.copyWith(
          hasAcceptedArenaDataShare: true,
          arenaShareAnonymousResults: true,
        ),
      );
      return true;
    }

    // Pro: optional opt-in / opt-out.
    if (s.hasAcceptedArenaDataShare) return true;
    final share = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Share anonymous speed results?'),
        content: const Text(
          'Device class, model, and speed only — never prompts or answers. '
          'You can turn this off in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agree & continue'),
          ),
        ],
      ),
    );
    if (!mounted || share == null) return false;
    await sp.updateSettings(
      s.copyWith(
        hasAcceptedArenaDataShare: true,
        arenaShareAnonymousResults: share,
      ),
    );
    return true;
  }

  Future<void> _start() async {
    if (_mode == ArenaMode.compare && !_isPremium) {
      _showUpgrade();
      return;
    }
    if (_contestants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a model to race.')),
      );
      return;
    }
    if (_contestants.length < 2 &&
        _mode == ArenaMode.benchmark &&
        !widget.wizardMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two models to race.')),
      );
      return;
    }

    final ok = await _ensureConsent();
    if (!ok || !mounted) return;

    if (_unloadBeforeRace && _showsUnloadOption) {
      await _unloadLoadedBeforeRace();
      if (!mounted) return;
    }

    // Confirm LM Studio keys still exist (avoids stale picker IDs).
    final lmIds = _contestants
        .where((c) => c.providerKind == 'lmStudio')
        .map((c) => c.modelId)
        .toSet();
    if (lmIds.isNotEmpty) {
      try {
        final settings = context.read<SettingsProvider>().settings;
        final live = await LMStudioService().getAvailableModels(
          baseUrl: settings.serverUrl,
          apiToken: settings.apiToken,
        );
        final liveKeys = live.map((m) => m.id).toSet();
        final missing = lmIds.where((id) => !liveKeys.contains(id)).toList();
        if (missing.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'LM Studio no longer lists: ${missing.join(', ')}. '
                'Refresh models in Settings and re-add them to the race.',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      } catch (_) {
        // Offline / server down — let the race surface the real error.
      }
    }

    final List<String> prompts;
    String? promptSetId;
    int? promptSetVersion;
    if (_mode == ArenaMode.compare) {
      final prompt = _promptController.text.trim();
      if (prompt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a prompt.')),
        );
        return;
      }
      prompts = [prompt];
    } else {
      final set =
          _useQuickSuite ? ArenaPromptSet.quick : ArenaPromptSet.standard;
      prompts = set.prompts;
      promptSetId = set.id;
      promptSetVersion = set.version;
    }

    final settings = context.read<SettingsProvider>().settings;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArenaScreen(
          mode: _mode,
          prompts: prompts,
          promptSetId: promptSetId,
          promptSetVersion: promptSetVersion,
          contestants: List.unmodifiable(_contestants),
          settings: settings,
          sameProviderSchedule: _sameProviderSchedule,
        ),
      ),
    );
  }

  /// True when any single backend has 2+ contestants (needs schedule choice).
  bool get _hasSameProviderMulti {
    final counts = <String, int>{};
    for (final c in _contestants) {
      final key = c.cloudProviderId != null && c.cloudProviderId!.isNotEmpty
          ? '${c.providerKind}:${c.cloudProviderId}'
          : c.providerKind;
      if (c.isOnDevice) continue; // always sequential — see [_hasMultiOnDevice]
      counts[key] = (counts[key] ?? 0) + 1;
      if (counts[key]! >= 2) return true;
    }
    return false;
  }

  /// Two+ on-device models (GGUF and/or MLX) — always one-at-a-time with unload.
  bool get _hasMultiOnDevice =>
      _contestants.where((c) => c.isOnDevice).length >= 2;

  /// Prefer 1 on-device + 1 desktop when both exist.
  List<ArenaContestant> _suggestedContestants({int limit = 2}) {
    final out = <ArenaContestant>[];
    var i = 0;
    int color() => _accents[i++ % _accents.length];

    final ready = ClientPlatform.isIosSimulator
        ? <LocalModelEntry>[]
        : (LocalModelDownloadService.instance.readyEntries.toList()
          ..sort((a, b) => _fitScore(a.spec).compareTo(_fitScore(b.spec))));
    for (final e in ready) {
      if (_fitScore(e.spec) >= 3) continue;
      out.add(ArenaContestant.fromLocalSpec(
        id: 'sug_${e.spec.id}_$i',
        spec: e.spec,
        color: color(),
      ));
      break;
    }

    final settings = context.read<SettingsProvider>();
    final lm = settings.availableModels.where((m) => m.isLLM).toList();
    if (lm.isNotEmpty && out.length < limit) {
      out.add(ArenaContestant.fromLmStudio(
        id: 'sug_lm_${lm.first.id}_$i',
        model: lm.first,
        color: color(),
      ));
    }

    if (out.length < limit) {
      for (final p in CloudApiService().providers) {
        if (!p.type.isFreeLocalServer) {
          continue;
        }
        final model = p.selectedModel?.isNotEmpty == true
            ? p.selectedModel!
            : (p.suggestedModels.isNotEmpty ? p.suggestedModels.first : null);
        if (model == null) continue;
        out.add(ArenaContestant.fromLocalServerProvider(
          id: 'sug_${p.type.name}_${model}_$i',
          modelId: model,
          cloudProviderId: p.id,
          providerKind: p.type.providerKind,
          color: color(),
          displayName: model.split('/').last,
        ));
        break;
      }
    }

    if (out.length < limit) {
      for (final e in ready.skip(out.where((c) => c.isOnDevice).length)) {
        if (out.length >= limit) break;
        if (_fitScore(e.spec) >= 3) continue;
        if (out.any((c) => c.modelId == e.spec.id)) continue;
        out.add(ArenaContestant.fromLocalSpec(
          id: 'sug2_${e.spec.id}_$i',
          spec: e.spec,
          color: color(),
        ));
      }
    }

    return out.take(limit).toList();
  }

  int _fitScore(LocalModelSpec spec) {
    final cap = _device;
    if (cap == null) return 1;
    switch (DeviceCapabilityService.instance.verdict(spec, cap)) {
      case ModelFit.runs:
        return 0;
      case ModelFit.tight:
        return 1;
      case ModelFit.blocked:
        return 3;
    }
  }

  void _suggestMix() {
    final picks = _suggestedContestants(limit: 2);
    if (picks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Download an on-device model or connect a desktop server first.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _contestants
        ..clear()
        ..addAll(picks);
    });
    _refreshLoadedHint();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCompare = _mode == ArenaMode.compare;
    final headerH = GlassPageHeader.heightFor(context);
    final canvasBg = isDark ? const Color(0xFF080A0F) : scheme.surface;
    final iconFg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.88);

    final topPad = widget.embedded ? 16.0 : headerH + 12;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: canvasBg,
        body: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPad, 16, 120),
                children: [
                  Text(
                    "Who's racing?",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add any mix — phone, LM Studio, Ollama, cloud.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_maxContestants, (index) {
                    if (index < _contestants.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContestantSlot.filled(
                          index: index,
                          contestant: _contestants[index],
                          device: _device,
                          onRemove: () =>
                              _removeContestant(_contestants[index].id),
                        ),
                      );
                    }
                    if (index == _contestants.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContestantSlot.empty(
                          index: index,
                          onTap: _openAddFlow,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  TextButton.icon(
                    onPressed: _suggestMix,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Suggest phone + desktop'),
                  ),
                  const SizedBox(height: 20),
                  if (!widget.wizardMode) ...[
                    _compactModeRow(theme),
                    const SizedBox(height: 12),
                  ],
                  if (isCompare) ...[
                    TextField(
                      controller: _promptController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Prompt',
                        hintText: 'Same question for every model…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _promptIdeas
                          .map(
                            (s) => ActionChip(
                              label: Text(
                                s.length > 28 ? '${s.substring(0, 28)}…' : s,
                                style: theme.textTheme.bodySmall,
                              ),
                              onPressed: () => setState(
                                () => _promptController.text = s,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ] else
                    _quickToggle(theme),
                  if (_hasMultiOnDevice) ...[
                    const SizedBox(height: 12),
                    _onDeviceUnloadInfo(theme),
                  ],
                  if (_hasSameProviderMulti) ...[
                    const SizedBox(height: 12),
                    _sameProviderSchedulePicker(theme),
                  ],
                  if (_showsUnloadOption) ...[
                    const SizedBox(height: 12),
                    _unloadBeforeToggle(theme),
                  ],
                  if (_loadingDevice)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (_device != null) ...[
                    const SizedBox(height: 16),
                    _compactDeviceTip(theme, _device!),
                  ],
                  if (ProFeatures.included &&
                      !_isPremium &&
                      !widget.wizardMode) ...[
                    const SizedBox(height: 16),
                    _proHint(theme),
                  ],
                ],
              ),
            ),
            if (!widget.embedded)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GlassPageHeader(
                  title: widget.wizardMode ? 'Find your model' : 'Arena',
                  onBack: () => Navigator.pop(context),
                  onLightCanvas: !isDark,
                  actions: [
                    if (ProFeatures.included && !widget.wizardMode)
                      GlassCircleIconButton(
                        tooltip: 'History',
                        onTap: () {
                          if (!_isPremium) {
                            _showUpgrade();
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ArenaHistoryScreen(),
                            ),
                          );
                        },
                        child: Icon(Icons.history, size: 20, color: iconFg),
                      ),
                    GlassCircleIconButton(
                      tooltip: 'How it works',
                      onTap: _showHowItWorks,
                      child: Icon(Icons.info_outline, size: 20, color: iconFg),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  isCompare
                      ? 'Start compare'
                      : (_useQuickSuite ? 'Start quick race' : 'Start race'),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactModeRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            selected: _mode == ArenaMode.benchmark,
            label: 'Speed race',
            icon: Icons.speed,
            onTap: () => _selectMode(ArenaMode.benchmark),
          ),
        ),
        // Public build: custom-prompt mode is only a paywall for free users,
        // so it is hidden unless the entitlement is active.
        if (ProFeatures.included || _isPremium) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ModeChip(
              selected: _mode == ArenaMode.compare,
              label: _isPremium || !ProFeatures.included
                  ? 'Your prompt'
                  : 'Your prompt · Pro',
              icon: Icons.chat_bubble_outline,
              onTap: () => _selectMode(ArenaMode.compare),
            ),
          ),
        ],
      ],
    );
  }

  Widget _quickToggle(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            selected: _useQuickSuite,
            label: 'Quick · ~1 min',
            icon: Icons.bolt,
            onTap: () => setState(() => _useQuickSuite = true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeChip(
            selected: !_useQuickSuite,
            label: 'Full suite',
            icon: Icons.checklist_rtl,
            onTap: () => setState(() => _useQuickSuite = false),
          ),
        ),
      ],
    );
  }

  Widget _unloadBeforeToggle(ThemeData theme) {
    final scheme = theme.colorScheme;
    final subtitle = _loadedLmStudioCount > 0
        ? '$_loadedLmStudioCount model${_loadedLmStudioCount == 1 ? '' : 's'} '
            'currently loaded in LM Studio'
        : 'Clears LM Studio / on-device memory before the race starts';
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: CheckboxListTile(
        value: _unloadBeforeRace,
        onChanged: (v) => setState(() => _unloadBeforeRace = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Unload loaded models first'),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// On-device GGUF + MLX always serialize with an unload between models.
  Widget _onDeviceUnloadInfo(ThemeData theme) {
    final scheme = theme.colorScheme;
    final n = _contestants.where((c) => c.isOnDevice).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'On-device · unload between',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$n on-device models always run one at a time. '
            'Each model is unloaded before the next loads '
            '(GGUF and MLX share phone memory).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _sameProviderSchedulePicker(ThemeData theme) {
    final scheme = theme.colorScheme;
    final lmStudioMulti =
        _contestants.where((c) => c.providerKind == 'lmStudio').length >= 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Same provider · how to run',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lmStudioMulti
                ? 'Multiple LM Studio models always run one-at-a-time '
                    '(unload between). Parallel JIT-load often fails with '
                    '“Model does not exist.”'
                : 'Several models share one server. Parallel is faster; '
                    'unload between gives fairer VRAM use.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (!lmStudioMulti) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    selected: _sameProviderSchedule ==
                        ArenaSameProviderSchedule.parallel,
                    label: 'Run parallel',
                    icon: Icons.speed,
                    onTap: () => setState(() => _sameProviderSchedule =
                        ArenaSameProviderSchedule.parallel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    selected: _sameProviderSchedule ==
                        ArenaSameProviderSchedule.unloadBetween,
                    label: 'Unload between',
                    icon: Icons.swap_horiz,
                    onTap: () => setState(() => _sameProviderSchedule =
                        ArenaSameProviderSchedule.unloadBetween),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactDeviceTip(ThemeData theme, DeviceCapability cap) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Text(
        '${cap.deviceName} · ${cap.ramDisplayLabel}'
        '${cap.supportsVulkan ? ' · Vulkan' : ''} · ${cap.llmTierLabel}',
        style:
            theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget _proHint(ThemeData theme) {
    return InkWell(
      onTap: _showUpgrade,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pro: custom prompts, cloud models, history',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  void _showHowItWorks() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How Arena works'),
        content: const Text(
          '1. Tap Add → choose where the model runs → pick the model.\n'
          '2. Mix phone and desktop freely in one race.\n'
          '3. We measure speed and first-word time. You judge answer quality.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeChip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.14)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? scheme.primary : null,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContestantSlot extends StatelessWidget {
  final int index;
  final ArenaContestant? contestant;
  final DeviceCapability? device;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const _ContestantSlot.filled({
    required this.index,
    required ArenaContestant this.contestant,
    required this.device,
    required VoidCallback this.onRemove,
  }) : onTap = null;

  const _ContestantSlot.empty({
    required this.index,
    required VoidCallback this.onTap,
  })  : contestant = null,
        device = null,
        onRemove = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final letter = String.fromCharCode(65 + index); // A, B, C…

    if (contestant == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.45),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                _letterBadge(theme, letter, scheme.outline),
                const SizedBox(width: 14),
                Icon(Icons.add_circle_outline, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Add model',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final c = contestant!;
    final color = Color(c.color);
    final fit = c.spec != null && device != null
        ? DeviceCapabilityService.instance.verdict(c.spec!, device)
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        leading: _letterBadge(theme, letter, color),
        title: Text(
          c.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            c.providerLabel,
            if (c.specSummary.isNotEmpty && c.specSummary != c.providerLabel)
              c.specSummary,
            if (fit == ModelFit.tight) 'Tight on RAM',
            if (fit == ModelFit.blocked) 'May not fit',
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }

  Widget _letterBadge(ThemeData theme, String letter, Color color) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        letter,
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Provider → Model picker ─────────────────────────────────────────────

enum _ProviderId {
  onDevice,
  lmMiniHome,
  lmStudio,
  ollama,
  omlx,
  jan,
  unsloth,
  cloud,
}

class _ProviderOption {
  final _ProviderId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final int modelCount;
  final bool locked;
  final CloudApiProvider? cloudProvider;

  const _ProviderOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.modelCount,
    this.locked = false,
    this.cloudProvider,
  });
}

class _ProviderThenModelSheet extends StatefulWidget {
  final int nextColor;
  final DeviceCapability? device;
  final bool isPremium;

  const _ProviderThenModelSheet({
    required this.nextColor,
    required this.device,
    required this.isPremium,
  });

  @override
  State<_ProviderThenModelSheet> createState() =>
      _ProviderThenModelSheetState();
}

class _ProviderThenModelSheetState extends State<_ProviderThenModelSheet> {
  _ProviderOption? _selected;

  List<_ProviderOption> _providers(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final onDevice = LocalModelDownloadService.instance.readyEntries.length;
    final lmCount = settings.availableModels.where((m) => m.isLLM).length;

    final list = <_ProviderOption>[
      _ProviderOption(
        id: _ProviderId.onDevice,
        title: 'This phone',
        subtitle: ClientPlatform.isIosSimulator
            ? 'Needs a real device (not Simulator)'
            : onDevice == 0
                ? 'No downloads yet'
                : '$onDevice model${onDevice == 1 ? '' : 's'} ready',
        icon: Icons.smartphone,
        modelCount: ClientPlatform.isIosSimulator ? 0 : onDevice,
      ),
    ];
    if (settings.settings.isRemoteActive) {
      final advertised = settings.visibleRemoteBackends;
      for (final kind in advertised) {
        if (kind == RemoteHostBackends.lmMiniDesktop) {
          list.add(_ProviderOption(
            id: _ProviderId.lmMiniHome,
            title: RemoteHostBackends.remoteListLabel(
              kind,
              settings.settings,
            ),
            subtitle: 'Models on this Mac',
            icon: Icons.home_rounded,
            modelCount: lmCount,
          ));
        } else if (kind == RemoteHostBackends.lmStudio) {
          list.add(_ProviderOption(
            id: _ProviderId.lmStudio,
            title: RemoteHostBackends.remoteListLabel(
              kind,
              settings.settings,
            ),
            subtitle: lmCount == 0
                ? 'Connect in Settings'
                : '$lmCount model${lmCount == 1 ? '' : 's'}',
            icon: Icons.computer,
            modelCount: lmCount,
          ));
        } else if (kind == RemoteHostBackends.ollama ||
            kind == RemoteHostBackends.omlx ||
            kind == RemoteHostBackends.jan ||
            kind == RemoteHostBackends.unsloth) {
          final p = CloudApiService()
              .providers
              .where((x) => x.type.providerKind == kind)
              .firstOrNull;
          final n = p == null ? 0 : _cloudModelIds(p).length;
          list.add(_ProviderOption(
            id: switch (kind) {
              RemoteHostBackends.ollama => _ProviderId.ollama,
              RemoteHostBackends.omlx => _ProviderId.omlx,
              RemoteHostBackends.jan => _ProviderId.jan,
              _ => _ProviderId.unsloth,
            },
            title: RemoteHostBackends.remoteListLabel(
              kind,
              settings.settings,
            ),
            subtitle: n == 0 ? 'No models listed' : '$n models',
            icon: RemoteHostBackends.iconFor(kind),
            modelCount: n,
            cloudProvider: p,
          ));
        }
      }
    } else {
      list.add(_ProviderOption(
        id: _ProviderId.lmStudio,
        title: 'LM Studio',
        subtitle: lmCount == 0
            ? 'Connect in Settings'
            : '$lmCount model${lmCount == 1 ? '' : 's'}',
        icon: Icons.computer,
        modelCount: lmCount,
      ));
    }

    for (final p in CloudApiService().providers) {
      if (settings.settings.isRemoteActive && p.type.isFreeLocalServer) {
        continue;
      }
      if (p.type == CloudApiType.ollama) {
        final n = _cloudModelIds(p).length;
        list.add(_ProviderOption(
          id: _ProviderId.ollama,
          title: p.name.isNotEmpty ? p.name : 'Ollama',
          subtitle: n == 0 ? 'No models listed' : '$n models',
          icon: Icons.terminal,
          modelCount: n,
          cloudProvider: p,
        ));
      } else if (p.type == CloudApiType.omlx) {
        final n = _cloudModelIds(p).length;
        list.add(_ProviderOption(
          id: _ProviderId.omlx,
          title: p.name.isNotEmpty ? p.name : 'oMLX',
          subtitle: n == 0 ? 'No models listed' : '$n models',
          icon: Icons.memory,
          modelCount: n,
          cloudProvider: p,
        ));
      } else if (p.type == CloudApiType.jan) {
        final n = _cloudModelIds(p).length;
        list.add(_ProviderOption(
          id: _ProviderId.jan,
          title: p.name.isNotEmpty ? p.name : 'JAN AI',
          subtitle: n == 0 ? 'No models listed' : '$n models',
          icon: Icons.bolt_rounded,
          modelCount: n,
          cloudProvider: p,
        ));
      } else if (p.type == CloudApiType.unsloth) {
        final n = _cloudModelIds(p).length;
        list.add(_ProviderOption(
          id: _ProviderId.unsloth,
          title: p.name.isNotEmpty ? p.name : 'Unsloth',
          subtitle: n == 0 ? 'No models listed' : '$n models',
          icon: Icons.science_rounded,
          modelCount: n,
          cloudProvider: p,
        ));
      } else {
        // Public build: paid cloud contestants are only a lock for free users.
        if (!(ProFeatures.included || widget.isPremium)) continue;
        final n = _cloudModelIds(p).length;
        list.add(_ProviderOption(
          id: _ProviderId.cloud,
          title: p.name,
          subtitle:
              widget.isPremium ? (n == 0 ? 'No models' : '$n models') : 'Pro',
          icon: Icons.cloud_outlined,
          modelCount: n,
          locked: !widget.isPremium,
          cloudProvider: p,
        ));
      }
    }

    return list;
  }

  List<String> _cloudModelIds(CloudApiProvider p) => <String>{
        if (p.selectedModel != null && p.selectedModel!.isNotEmpty)
          p.selectedModel!,
        ...p.suggestedModels,
      }.toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(
              children: [
                if (_selected != null)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => setState(() => _selected = null),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected == null
                            ? '1 · Where does it run?'
                            : '2 · Pick a model',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_selected != null)
                        Text(
                          _selected!.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selected == null
                ? _buildProviderList(theme)
                : _buildModelList(theme, _selected!),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList(ThemeData theme) {
    final options = _providers(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final o = options[i];
        final enabled = !o.locked && o.modelCount > 0;
        return Material(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: o.locked
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cloud models in Arena need Pro.'),
                      ),
                    );
                  }
                : enabled
                    ? () => setState(() => _selected = o)
                    : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(o.icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          o.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (o.locked)
                    Icon(Icons.lock_outline,
                        size: 18, color: theme.colorScheme.outline)
                  else if (enabled)
                    Icon(Icons.chevron_right, color: theme.colorScheme.outline)
                  else
                    Icon(Icons.block,
                        size: 18,
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelList(ThemeData theme, _ProviderOption provider) {
    if (provider.id == _ProviderId.lmStudio ||
        provider.id == _ProviderId.lmMiniHome) {
      return FutureBuilder<List<_PickableModel>>(
        future: _liveLmStudioModels(
          kind: provider.id == _ProviderId.lmMiniHome
              ? RemoteHostBackends.lmMiniDesktop
              : RemoteHostBackends.lmStudio,
        ),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final models = snap.data ?? const <_PickableModel>[];
          return _modelListView(theme, provider, models);
        },
      );
    }
    return _modelListView(theme, provider, _modelsFor(provider));
  }

  Future<List<_PickableModel>> _liveLmStudioModels({
    String kind = RemoteHostBackends.lmStudio,
  }) async {
    final color = widget.nextColor;
    var n = 0;
    try {
      final live =
          await context.read<SettingsProvider>().fetchModelsForBackend(kind);
      return live.where((m) => m.isLLM).map((m) {
        final c = ArenaContestant.fromLmStudio(
          id: 'pick_lm_${n++}_$color',
          model: m,
          color: color,
          providerKind: kind,
        );
        return _PickableModel(
          displayName: c.displayName,
          subtitle: '${c.specSummary} · ${m.id}',
          contestant: c,
        );
      }).toList();
    } catch (_) {
      final settings = context.read<SettingsProvider>().settings;
      return _modelsFor(_ProviderOption(
        id: kind == RemoteHostBackends.lmMiniDesktop
            ? _ProviderId.lmMiniHome
            : _ProviderId.lmStudio,
        title: RemoteHostBackends.remoteListLabel(kind, settings),
        subtitle: '',
        icon: Icons.computer,
        modelCount: 1,
      ));
    }
  }

  Widget _modelListView(
    ThemeData theme,
    _ProviderOption provider,
    List<_PickableModel> models,
  ) {
    if (models.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No models here yet.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: models.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final m = models[i];
        return ListTile(
          leading: Icon(provider.icon),
          title:
              Text(m.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: m.subtitle == null ? null : Text(m.subtitle!),
          onTap: () => Navigator.pop(context, m.contestant),
        );
      },
    );
  }

  List<_PickableModel> _modelsFor(_ProviderOption provider) {
    final color = widget.nextColor;
    var n = 0;
    String uid() => 'pick_${provider.id.name}_${n++}_$color';

    switch (provider.id) {
      case _ProviderId.onDevice:
        return LocalModelDownloadService.instance.readyEntries.map((e) {
          final fit = widget.device == null
              ? null
              : DeviceCapabilityService.instance.verdict(e.spec, widget.device);
          final c = ArenaContestant.fromLocalSpec(
            id: uid(),
            spec: e.spec,
            color: color,
          );
          return _PickableModel(
            displayName: c.displayName,
            subtitle: [
              c.specSummary,
              if (fit == ModelFit.tight) 'Tight on RAM',
              if (fit == ModelFit.blocked) 'May not fit',
            ].where((s) => s.isNotEmpty).join(' · '),
            contestant: c,
          );
        }).toList();

      case _ProviderId.lmMiniHome:
      case _ProviderId.lmStudio:
        final models = context
            .read<SettingsProvider>()
            .availableModels
            .where((m) => m.isLLM)
            .toList();
        return models.map((LMStudioModel m) {
          final c = ArenaContestant.fromLmStudio(
            id: uid(),
            model: m,
            color: color,
            providerKind: provider.id == _ProviderId.lmMiniHome
                ? RemoteHostBackends.lmMiniDesktop
                : RemoteHostBackends.lmStudio,
          );
          return _PickableModel(
            displayName: c.displayName,
            subtitle: c.specSummary,
            contestant: c,
          );
        }).toList();

      case _ProviderId.ollama:
      case _ProviderId.omlx:
      case _ProviderId.jan:
      case _ProviderId.unsloth:
      case _ProviderId.cloud:
        final p = provider.cloudProvider;
        if (p == null) return const [];
        final kind = p.type.providerKind;
        return _cloudModelIds(p).map((model) {
          final c = kind == 'cloud'
              ? ArenaContestant.cloud(
                  id: uid(),
                  modelId: model,
                  cloudProviderId: p.id,
                  color: color,
                )
              : ArenaContestant.fromLocalServerProvider(
                  id: uid(),
                  modelId: model,
                  cloudProviderId: p.id,
                  providerKind: kind,
                  color: color,
                );
          return _PickableModel(
            displayName: c.displayName,
            subtitle: c.providerLabel,
            contestant: c,
          );
        }).toList();
    }
  }
}

class _PickableModel {
  final String displayName;
  final String? subtitle;
  final ArenaContestant contestant;

  const _PickableModel({
    required this.displayName,
    required this.subtitle,
    required this.contestant,
  });
}
