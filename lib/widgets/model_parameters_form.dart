import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../l10n/app_localizations.dart';
import '../models/arena_models.dart';
import '../models/param_preset.dart';
import '../screens/subscription_screen.dart';
import '../services/reasoning_support_service.dart';
import '../models/model_load_config.dart';
import '../utils/chat_reasoning_toggle.dart';
import '../utils/context_fit.dart';
import '../utils/layout_utils.dart';
import '../utils/openai_compatible_params.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/pro_badge.dart';
import '../widgets/think_brain_icon.dart';
import '../pro/pro_features.dart';

part '../pro/params/model_parameters_form_pro.dart';

/// Which Model Parameters rows to show for the active backend.
class ModelParametersVisibility {
  final bool isOnDeviceGguf;
  final bool isOnDeviceMlx;
  final bool isCloudRouted;
  final CloudApiType? providerType;
  final bool showTopK;
  final bool showMinP;
  final bool showRepeatPenalty;
  final bool showFreqPenalty;
  final bool showPresencePenalty;
  final bool showContextWindow;
  final bool showLoadingConfig;
  final bool showResizeImagesForPhysicalBatch;
  final bool showReasoning;
  final bool showVerbosity;
  final bool omitCloudSampling;
  final bool isCloudReasoning;

  /// llama.cpp / vLLM OpenAI-compat: thinking is on/off, not LM Studio levels.
  final bool useOnOffReasoning;

  const ModelParametersVisibility({
    required this.isOnDeviceGguf,
    required this.isOnDeviceMlx,
    required this.isCloudRouted,
    required this.providerType,
    required this.showTopK,
    required this.showMinP,
    required this.showRepeatPenalty,
    required this.showFreqPenalty,
    required this.showPresencePenalty,
    required this.showContextWindow,
    required this.showLoadingConfig,
    required this.showResizeImagesForPhysicalBatch,
    required this.showReasoning,
    required this.showVerbosity,
    required this.omitCloudSampling,
    required this.isCloudReasoning,
    this.useOnOffReasoning = false,
  });

  bool get isOnDevice => isOnDeviceGguf || isOnDeviceMlx;

  factory ModelParametersVisibility.resolve({
    required String providerKind,
    CloudApiType? providerType,
    required bool isCloudRouted,
    String? modelId,
  }) {
    final isOnDeviceGguf = providerKind == 'onDeviceGguf';
    final isOnDeviceMlx = providerKind == 'onDeviceMlx';
    final isOnDevice = isOnDeviceGguf || isOnDeviceMlx;
    final isCloudReasoning = isCloudRouted &&
        providerType != null &&
        (providerType.supportsReasoningEffort ||
            providerType.supportsZAiThinking);
    // llama.cpp / Ollama / oMLX: enable_thinking or think bool — not LM Studio
    // off/low/medium/high/on. Home sidecar is llama-server too.
    final useOnOffReasoning = providerKind == 'lmMiniDesktop' ||
        (isCloudRouted &&
            providerType != null &&
            ChatReasoningToggle.requestTypeSupportsNativeThink(providerType));
    final looksReasoning = modelId == null ||
        modelId.isEmpty ||
        ArenaContestant.looksLikeReasoningModel(modelId);
    final isLocalServerThink = isCloudRouted &&
        providerType != null &&
        ChatReasoningToggle.requestTypeSupportsNativeThink(providerType);
    return ModelParametersVisibility(
      isOnDeviceGguf: isOnDeviceGguf,
      isOnDeviceMlx: isOnDeviceMlx,
      isCloudRouted: isCloudRouted,
      providerType: providerType,
      showTopK:
          !isOnDevice && (providerType == null || providerType.supportsTopK),
      showMinP:
          !isOnDevice && (providerType == null || providerType.supportsMinP),
      showRepeatPenalty: isOnDevice
          ? true
          : (providerType == null || providerType.supportsRepeatPenalty),
      showFreqPenalty: isOnDeviceGguf
          ? true
          : (!isOnDevice &&
              (providerType == null || providerType.supportsFrequencyPenalty)),
      showPresencePenalty: !isOnDevice &&
          (providerType == null || providerType.supportsPresencePenalty),
      showContextWindow: (!isCloudRouted && !isOnDeviceMlx) ||
          (providerType?.supportsContextWindow ?? false) ||
          providerType == CloudApiType.unsloth,
      showLoadingConfig: !isCloudRouted && !isOnDevice,
      showResizeImagesForPhysicalBatch: providerKind == 'lmStudio' ||
          providerKind == 'lmMiniDesktop' ||
          isOnDevice ||
          (providerType?.isFreeLocalServer ?? false),
      // Per-chat already offers thinking for llama.cpp OpenAI-compat when
      // the model looks like Qwen 3.x / R1 / etc. Global Model Parameters
      // used to hide the row because openaiCompatible has no
      // supportsReasoningEffort flag (that's GPT-5 / o-series).
      showReasoning: !isOnDevice &&
          (!isCloudRouted ||
              isCloudReasoning ||
              (isLocalServerThink && looksReasoning)),
      showVerbosity:
          isCloudRouted && (providerType?.supportsVerbosity ?? false),
      omitCloudSampling: isCloudRouted && openAiOmitsSamplingParams(modelId),
      isCloudReasoning: isCloudReasoning,
      useOnOffReasoning: useOnOffReasoning,
    );
  }
}

class ModelParametersForm extends StatelessWidget {
  final ParamPreset values;
  final ValueChanged<ParamPreset> onChanged;
  final ModelParametersVisibility visibility;
  final String reasoningModelId;
  final int modelMaxContextLength;
  final bool contextFitLocked;
  final Widget? footer;
  final String storageId;

  /// Fired when the context-length slider is released (not on every drag tick).
  final VoidCallback? onContextLengthCommitted;

  const ModelParametersForm({
    super.key,
    required this.values,
    required this.onChanged,
    required this.visibility,
    this.reasoningModelId = '',
    this.modelMaxContextLength = 0,
    this.contextFitLocked = false,
    this.footer,
    this.storageId = 'params',
    this.onContextLengthCommitted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final desktop = prefersWideSettingsLayout(context);
    final v = visibility;
    final s = values;

    return ListView(
      key: PageStorageKey<String>(storageId),
      primary: false,
      padding: EdgeInsets.fromLTRB(
        desktop ? 0 : 16,
        desktop ? 12 : 20,
        desktop ? 0 : 16,
        32,
      ),
      children: [
        if (v.isOnDevice) ...[
          _infoBanner(
            context,
            icon: Icons.memory,
            text: v.isOnDeviceMlx
                ? 'On-Device (MLX) — temperature, top-P, max tokens, repeat penalty'
                : 'On-Device (fllama) — LM Studio-only model-load options are hidden',
          ),
          const SizedBox(height: 14),
        ],
        if (v.isCloudRouted && v.providerType != null) ...[
          _infoBanner(
            context,
            emoji: v.providerType!.iconEmoji,
            text:
                '${v.providerType!.displayName} — unsupported parameters are hidden',
          ),
          const SizedBox(height: 14),
        ],
        if (v.showReasoning) ...[
          _sectionLabel(context, l10n.reasoningMode),
          const SizedBox(height: 10),
          _card(
            context,
            child: Padding(
              padding: EdgeInsets.all(desktop ? 8 : 0),
              child: _reasoningRow(context),
            ),
          ),
          const SizedBox(height: 22),
        ],
        if (v.showVerbosity) ...[
          _sectionLabel(context, 'Verbosity'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Padding(
              padding: EdgeInsets.all(desktop ? 8 : 0),
              child: _verbosityRow(context),
            ),
          ),
          const SizedBox(height: 22),
        ],
        _sectionLabel(context, l10n.tokenLimits),
        const SizedBox(height: 10),
        _card(
          context,
          child: Padding(
            padding: EdgeInsets.all(desktop ? 8 : 0),
            child: DesktopSettingsGrid(
              children: [
                _numberRow(
                  context,
                  icon: Icons.short_text_rounded,
                  title: l10n.maxOutputTokens,
                  subtitle: l10n.maxOutputTokensSubtitle,
                  value: s.maxTokens,
                  onChanged: (n) => onChanged(s.copyWith(maxTokens: n)),
                ),
                if (v.showContextWindow) _contextLengthSlider(context),
              ],
            ),
          ),
        ),
        if (ProFeatures.included) ...[
          const SizedBox(height: 10),
          _card(
            context,
            child: _proContextFitRow(context),
          ),
        ],
        const SizedBox(height: 22),
        _sectionLabel(context, l10n.generationParametersSection),
        const SizedBox(height: 10),
        _card(
          context,
          child: Padding(
            padding: EdgeInsets.all(desktop ? 8 : 0),
            child: DesktopSettingsGrid(
              children: [
                if (!v.omitCloudSampling) ...[
                  _sliderRow(
                    context,
                    icon: Icons.thermostat_outlined,
                    title: l10n.temperature,
                    subtitle: l10n.temperatureSubtitle,
                    valueLabel: s.temperature.toStringAsFixed(2),
                    value: s.temperature,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (n) => onChanged(s.copyWith(temperature: n)),
                  ),
                  _sliderRow(
                    context,
                    icon: Icons.filter_alt_outlined,
                    title: l10n.topP,
                    subtitle: l10n.topPSubtitle,
                    valueLabel: s.topP.toStringAsFixed(2),
                    value: s.topP,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (n) => onChanged(s.copyWith(topP: n)),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Sampling knobs are hidden for this model (GPT-5 / o-series). Use Reasoning and Verbosity instead.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                if (!v.omitCloudSampling && v.showTopK)
                  _intSliderRow(
                    context,
                    icon: Icons.filter_1_outlined,
                    title: 'Top K',
                    subtitle: l10n.topKHelp,
                    value: s.topK,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (n) => onChanged(s.copyWith(topK: n)),
                  ),
                if (!v.omitCloudSampling && v.showMinP)
                  _sliderRow(
                    context,
                    icon: Icons.tune,
                    title: l10n.minP,
                    subtitle: l10n.minPSubtitle,
                    valueLabel: s.minP.toStringAsFixed(2),
                    value: s.minP,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (n) => onChanged(s.copyWith(minP: n)),
                  ),
                if (!v.omitCloudSampling && v.showRepeatPenalty)
                  _sliderRow(
                    context,
                    icon: Icons.repeat,
                    title: l10n.repeatPenalty,
                    subtitle: l10n.repeatPenaltySubtitle,
                    valueLabel: s.repeatPenalty.toStringAsFixed(2),
                    value: s.repeatPenalty,
                    min: 1,
                    max: 2,
                    divisions: 20,
                    onChanged: (n) => onChanged(s.copyWith(repeatPenalty: n)),
                  ),
                if (!v.omitCloudSampling && v.showFreqPenalty)
                  _sliderRow(
                    context,
                    icon: Icons.trending_down,
                    title: l10n.frequencyPenalty,
                    subtitle: l10n.frequencyPenaltySubtitle,
                    valueLabel: s.frequencyPenalty.toStringAsFixed(2),
                    value: s.frequencyPenalty,
                    min: -2,
                    max: 2,
                    divisions: 40,
                    onChanged: (n) =>
                        onChanged(s.copyWith(frequencyPenalty: n)),
                  ),
                if (!v.omitCloudSampling && v.showPresencePenalty)
                  _sliderRow(
                    context,
                    icon: Icons.topic_outlined,
                    title: l10n.presencePenalty,
                    subtitle: l10n.presencePenaltySubtitle,
                    valueLabel: s.presencePenalty.toStringAsFixed(2),
                    value: s.presencePenalty,
                    min: -2,
                    max: 2,
                    divisions: 40,
                    onChanged: (n) => onChanged(s.copyWith(presencePenalty: n)),
                  ),
              ],
            ),
          ),
        ),
        if (v.showResizeImagesForPhysicalBatch) ...[
          const SizedBox(height: 22),
          _card(
            context,
            child: _toggleRow(
              context,
              icon: Icons.photo_size_select_large_outlined,
              title: l10n.resizeImageForPhysicalBatch,
              subtitle: l10n.resizeImageForPhysicalBatchSubtitle,
              value: s.resizeImageForPhysicalBatch,
              onChanged: (n) =>
                  onChanged(s.copyWith(resizeImageForPhysicalBatch: n)),
            ),
          ),
        ],
        if (v.showLoadingConfig) ...[
          const SizedBox(height: 22),
          _sectionLabel(context, l10n.modelLoadingConfig),
          const SizedBox(height: 10),
          _card(
            context,
            child: Padding(
              padding: EdgeInsets.all(desktop ? 8 : 0),
              child: DesktopSettingsGrid(
                children: [
                  _optionalNumberRow(
                    context,
                    icon: Icons.layers_outlined,
                    title: l10n.evalBatchSize,
                    subtitle: l10n.evalBatchSubtitle,
                    value: s.loadEvalBatchSize,
                    hint: '2048',
                    onChanged: (n) =>
                        onChanged(s.copyWith(loadEvalBatchSize: n)),
                  ),
                  _optionalNumberRow(
                    context,
                    icon: Icons.hub_outlined,
                    title: l10n.numExperts,
                    subtitle: l10n.numExpertsSubtitle,
                    value: s.loadNumExperts,
                    hint: 'Auto',
                    onChanged: (n) => onChanged(s.copyWith(loadNumExperts: n)),
                  ),
                  _toggleRow(
                    context,
                    icon: Icons.bolt_outlined,
                    title: l10n.flashAttention,
                    subtitle: l10n.flashAttentionSubtitle,
                    value: s.loadFlashAttention,
                    onChanged: (n) =>
                        onChanged(s.copyWith(loadFlashAttention: n)),
                  ),
                  _toggleRow(
                    context,
                    icon: Icons.memory_outlined,
                    title: l10n.offloadKvCache,
                    subtitle: l10n.offloadKvCacheSubtitle,
                    value: s.loadOffloadKvCache,
                    onChanged: (n) =>
                        onChanged(s.copyWith(loadOffloadKvCache: n)),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: 22),
          footer!,
        ],
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    final pretty = title
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return Text(
      pretty,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _softIcon(BuildContext context, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return _softIconChild(
      context,
      Icon(icon, color: cs.primary, size: 22),
    );
  }

  Widget _softIconChild(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _infoBanner(
    BuildContext context, {
    IconData? icon,
    String? emoji,
    required String text,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 18))
          else if (icon != null)
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _sliderRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return DesktopSliderField(
      icon: icon,
      title: title,
      subtitle: subtitle,
      valueLabel: valueLabel,
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    );
  }

  Widget _intSliderRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required int value,
    required int min,
    required int max,
    required int divisions,
    required ValueChanged<int> onChanged,
  }) {
    return _sliderRow(
      context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      valueLabel: value.toString(),
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      divisions: divisions,
      onChanged: (v) => onChanged(v.round()),
    );
  }

  Widget _numberRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return _ParamNumberRow(
      iconBuilder: () => _softIcon(context, icon),
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _optionalNumberRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int? value,
    required String hint,
    required ValueChanged<int?> onChanged,
  }) {
    return _ParamOptionalNumberRow(
      iconBuilder: () => _softIcon(context, icon),
      title: title,
      subtitle: subtitle,
      value: value,
      hint: hint,
      onChanged: onChanged,
    );
  }

  Widget _reasoningRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modelId = reasoningModelId;
    final looksReasoning =
        modelId.isEmpty || ArenaContestant.looksLikeReasoningModel(modelId);
    final catalogOptions =
        ReasoningSupportService.instance.dropdownOptionsSync(modelId);
    final notBlocklisted = catalogOptions.isNotEmpty;
    final isCloudReasoning = visibility.isCloudReasoning;
    final useOnOff = visibility.useOnOffReasoning;
    final modelSupportsReasoning = isCloudReasoning ||
        useOnOff ||
        looksReasoning ||
        modelId.isEmpty ||
        notBlocklisted;
    final cs = Theme.of(context).colorScheme;
    final s = values;
    final dropdownItems = useOnOff
        ? const ['off', 'on']
        : (isCloudReasoning
            ? ReasoningSupportService.allOptions
            : catalogOptions);
    final dropdownValue = ReasoningSupportService.dropdownValue(
      s.reasoning,
      dropdownItems,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 20, 12),
      child: Row(
        children: [
          _softIconChild(
            context,
            IconTheme(
              data: IconThemeData(color: cs.primary, size: 22),
              child: const ThinkBrainIcon(size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.reasoningMode,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.reasoningMode,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => _showReasoningHelp(context),
                    ),
                  ],
                ),
                Text(
                  isCloudReasoning
                      ? 'Controls reasoning effort for GPT-5 / o-series (and thinking for Z.AI).'
                      : (useOnOff
                          ? 'Turns think on or off for llama.cpp / Ollama / oMLX. Levels are LM Studio only.'
                          : (!notBlocklisted && !looksReasoning
                              ? l10n.reasoningNotExposedChatHint
                              : l10n.reasoningHelpShort)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (modelSupportsReasoning && dropdownItems.isNotEmpty)
            _ReasoningMenuButton(
              value: dropdownValue,
              items: dropdownItems,
              labelOf: (value) => _reasoningOptionLabel(l10n, value),
              tooltip: l10n.reasoningMode,
              onSelected: (value) => onChanged(s.copyWith(reasoning: value)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                l10n.off,
                textAlign: TextAlign.right,
                style: TextStyle(color: cs.outline),
              ),
            ),
        ],
      ),
    );
  }

  String _reasoningOptionLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'off' => l10n.reasoningOff,
      'low' => l10n.reasoningLow,
      'medium' => l10n.reasoningMedium,
      'high' => l10n.reasoningHigh,
      'on' => l10n.reasoningOn,
      _ => value,
    };
  }

  void _showReasoningHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.reasoningMode),
        content: Text(
          l10n.reasoningHelp,
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Widget _verbosityRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = values.verbosity;
    final safeValue = (value == 'low' || value == 'medium' || value == 'high')
        ? value
        : 'medium';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          _softIcon(context, Icons.subject_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verbosity',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'How long GPT-5 replies should be (low / medium / high).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              alignment: AlignmentDirectional.centerEnd,
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(
                  value: 'low',
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text('Low'),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text('High'),
                ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(values.copyWith(verbosity: v));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextLengthSlider(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnDevice = visibility.isOnDevice;
    const fallbackMax = 131072;
    final upper =
        modelMaxContextLength > 0 ? modelMaxContextLength : fallbackMax;
    const lower = 512;
    final clamped = values.contextWindow.clamp(lower, upper);
    final cs = Theme.of(context).colorScheme;
    final title = isOnDevice ? l10n.contextWindow : l10n.loadContextLength;
    final subtitle =
        isOnDevice ? l10n.contextWindowSubtitle : l10n.loadContextSubtitle;
    final subtitleWithMax = modelMaxContextLength > 0
        ? '$subtitle · model up to ${_formatTokens(modelMaxContextLength)}'
        : subtitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _softIcon(context, Icons.view_agenda_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      subtitleWithMax,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatTokens(clamped),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: clamped.toDouble(),
              min: lower.toDouble(),
              max: upper.toDouble(),
              onChanged: (v) {
                final rounded = (v.round() ~/ 256) * 256;
                onChanged(values.copyWith(
                  contextWindow: rounded.clamp(lower, upper),
                ));
              },
              onChangeEnd: (v) {
                final rounded = (v.round() ~/ 256) * 256;
                final next = rounded.clamp(lower, upper);
                if (next != values.contextWindow) {
                  onChanged(values.copyWith(contextWindow: next));
                }
                if (visibility.showLoadingConfig ||
                    visibility.providerType == CloudApiType.unsloth) {
                  onContextLengthCommitted?.call();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTokens(int n) => ModelLoadConfigHelper.formatTokenCount(n);
}

Future<void> showParamPresetDialog({
  required BuildContext context,
  required ParamPreset initial,
  required ValueChanged<ParamPreset> onChanged,
  required ModelParametersVisibility visibility,
  String reasoningModelId = '',
  int modelMaxContextLength = 0,
}) {
  var current = initial;
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final cs = Theme.of(ctx).colorScheme;
      final wide = MediaQuery.sizeOf(ctx).width >= 720;
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: wide ? 48 : 16,
          vertical: 24,
        ),
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 740),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.personaAdjustParams,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setLocal) {
                    return ModelParametersForm(
                      values: current,
                      visibility: visibility,
                      reasoningModelId: reasoningModelId,
                      modelMaxContextLength: modelMaxContextLength,
                      onChanged: (next) {
                        setLocal(() => current = next);
                        onChanged(next);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ParamNumberRow extends StatefulWidget {
  final Widget Function() iconBuilder;
  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  const _ParamNumberRow({
    required this.iconBuilder,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ParamNumberRow> createState() => _ParamNumberRowState();
}

class _ParamNumberRowState extends State<_ParamNumberRow> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_ParamNumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_focusNode.hasFocus) {
      final parsed = int.tryParse(_controller.text);
      final current = widget.value;
      final onChanged = widget.onChanged;
      if (parsed != null && parsed != current) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onChanged(parsed);
        });
      }
    }
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _saveValue();
  }

  void _saveValue() {
    final newValue = int.tryParse(_controller.text);
    if (newValue != null && newValue != widget.value) {
      widget.onChanged(newValue);
    } else if (newValue == null) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          widget.iconBuilder(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: cs.primary.withValues(alpha: 0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _saveValue(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParamOptionalNumberRow extends StatefulWidget {
  final Widget Function() iconBuilder;
  final String title;
  final String subtitle;
  final int? value;
  final String hint;
  final ValueChanged<int?> onChanged;

  const _ParamOptionalNumberRow({
    required this.iconBuilder,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_ParamOptionalNumberRow> createState() =>
      _ParamOptionalNumberRowState();
}

class _ParamOptionalNumberRowState extends State<_ParamOptionalNumberRow> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_ParamOptionalNumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_focusNode.hasFocus) {
      final text = _controller.text.trim();
      final current = widget.value;
      final onChanged = widget.onChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (text.isEmpty) {
          if (current != null) onChanged(null);
          return;
        }
        final parsed = int.tryParse(text);
        if (parsed != null && parsed != current) onChanged(parsed);
      });
    }
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _saveValue();
  }

  void _saveValue() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (widget.value != null) widget.onChanged(null);
    } else {
      final newValue = int.tryParse(text);
      if (newValue != null && newValue != widget.value) {
        widget.onChanged(newValue);
      } else if (newValue == null) {
        _controller.text = widget.value?.toString() ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          widget.iconBuilder(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (widget.value != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Auto',
              onPressed: () {
                _controller.clear();
                widget.onChanged(null);
              },
            ),
          SizedBox(
            width: 96,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: cs.primary.withValues(alpha: 0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.outline,
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _saveValue(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trailing On/Off (or LM Studio levels) control. [MenuAnchor] stays aligned
/// to the button instead of snapping the overlay to the screen edge.
class _ReasoningMenuButton extends StatelessWidget {
  const _ReasoningMenuButton({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onSelected,
    required this.tooltip,
  });

  final String value;
  final List<String> items;
  final String Function(String value) labelOf;
  final ValueChanged<String> onSelected;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MenuAnchor(
      consumeOutsideTap: true,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomEnd,
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.fromLTRB(6, 6, 6, 6),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      builder: (context, controller, child) {
        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labelOf(value),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            onPressed: () => onSelected(item),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 88),
              child: Text(labelOf(item)),
            ),
          ),
      ],
    );
  }
}
