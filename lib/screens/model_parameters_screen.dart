import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../l10n/app_localizations.dart';
import '../models/param_preset.dart';
import '../providers/settings_provider.dart';
import '../utils/layout_utils.dart';
import '../utils/param_preset_key.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_page_header.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/home_glass_header.dart';
import '../widgets/model_parameters_form.dart';
import '../widgets/pro_badge.dart';
import '../screens/subscription_screen.dart';
import '../pro/pro_features.dart';

part '../pro/params/model_parameters_screen_pro.dart';

enum _ParamsTab { model, global }

class ModelParametersScreen extends StatefulWidget {
  final bool embedded;
  const ModelParametersScreen({super.key, this.embedded = false});

  @override
  State<ModelParametersScreen> createState() => _ModelParametersScreenState();
}

class _ModelParametersScreenState extends State<ModelParametersScreen> {
  _ParamsTab _tab = _ParamsTab.global;
  _ParamsTab? _pendingTab;

  void _showParametersHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final entries = <(String, String)>[
      (l10n.reasoningMode, l10n.reasoningHelp),
      (l10n.maxOutputTokens, l10n.maxOutputTokensSubtitle),
      (l10n.loadContextLength, l10n.loadContextSubtitle),
      if (ProFeatures.included)
        (l10n.contextFitTitle, l10n.contextFitSubtitle),
      (l10n.temperature, l10n.temperatureSubtitle),
      (l10n.topP, l10n.topPSubtitle),
      ('Top K', l10n.topKHelp),
      (l10n.minP, l10n.minPSubtitle),
      (l10n.repeatPenalty, l10n.repeatPenaltySubtitle),
      (l10n.frequencyPenalty, l10n.frequencyPenaltySubtitle),
      (l10n.presencePenalty, l10n.presencePenaltySubtitle),
      (l10n.evalBatchSize, l10n.evalBatchSubtitle),
      (l10n.numExperts, l10n.numExpertsSubtitle),
      (l10n.flashAttention, l10n.flashAttentionSubtitle),
      (l10n.offloadKvCache, l10n.offloadKvCacheSubtitle),
      (
        l10n.resizeImageForPhysicalBatch,
        l10n.resizeImageForPhysicalBatchHelp,
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    l10n.modelParametersHelpTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.modelParametersHelpIntro,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in entries) ...[
                    Text(
                      entry.$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showScopeHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final entries = <(String, String)>[
      (l10n.paramPresetGlobalTab, l10n.paramPresetScopeHelpGlobal),
      (l10n.paramPresetSelectedModelTab, l10n.paramPresetScopeHelpModel),
      (l10n.paramPresetScopeHelpPersonaTitle, l10n.paramPresetScopeHelpPersona),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paramPresetScopeHelpTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.paramPresetScopeHelpIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 16),
                for (final entry in entries) ...[
                  Text(
                    entry.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.$2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _modelTabLabel(AppLocalizations l10n, String? modelId) {
    if (modelId == null || modelId.isEmpty) {
      return l10n.paramPresetSelectedModelTab;
    }
    return modelId.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topBg = isDark ? const Color(0xFF1A202E) : const Color(0xFF243044);
    final headerH = GlassPageHeader.heightFor(context);
    final helpAction = GlassCircleIconButton(
      tooltip: l10n.modelParametersHelpTooltip,
      onTap: () => _showParametersHelp(context),
      child: Icon(
        Icons.info_outline_rounded,
        size: 20,
        color: widget.embedded ? theme.colorScheme.onSurface : Colors.white,
      ),
    );

    final content = ListenableBuilder(
      listenable: SubscriptionService(),
      builder: (context, _) {
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            final isPremium = SubscriptionService().isPremium;
            final s = settingsProvider.settings;
            final isCloudRouted =
                SettingsProvider.isCloudProviderKind(s.activeProviderKind);
            final CloudApiType? providerType = isCloudRouted
                ? settingsProvider.resolveCloudProvider()?.requestApiType
                : null;

            final modelId = ParamPresetKey.selectedModelId(s);
            final hasModel = modelId != null && modelId.isNotEmpty;
            // Builds without the Pro parts only have the Global form.
            final tab = (!ProFeatures.included ||
                    (_tab == _ParamsTab.model && (!isPremium || !hasModel)))
                ? _ParamsTab.global
                : _tab;

            final key = settingsProvider.currentModelParamKey();
            final modelPreset = (key != null) ? s.modelParamPresets[key] : null;
            final visibility = ModelParametersVisibility.resolve(
              providerKind: s.activeProviderKind,
              providerType: providerType,
              isCloudRouted: isCloudRouted,
              modelId: modelId,
            );

            int modelMax = 0;
            if (modelId != null) {
              for (final m in settingsProvider.availableModels) {
                if (m.id == modelId) {
                  modelMax = m.maxContextLength;
                  break;
                }
              }
            }

            final desktop = prefersWideSettingsLayout(context);
            final showModelTab = tab == _ParamsTab.model && isPremium;
            final formValues = showModelTab
                ? (modelPreset ?? ParamPreset.fromSettings(s))
                : ParamPreset.fromSettings(s);

            Widget tabBar() {
              final modelLabel = _modelTabLabel(l10n, modelId);
              final modelBadge = _proModelSegmentBadge(context, isPremium);
              final cs = theme.colorScheme;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    desktop ? 0 : 16, 12, desktop ? 0 : 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.paramPresetSetFor,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.paramPresetScopeHelpTitle,
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
                          onPressed: () => _showScopeHelp(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<_ParamsTab>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: [
                        ButtonSegment(
                          value: _ParamsTab.model,
                          enabled: hasModel,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  modelLabel,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (modelBadge != null) ...[
                                const SizedBox(width: 4),
                                modelBadge,
                              ],
                            ],
                          ),
                        ),
                        ButtonSegment(
                          value: _ParamsTab.global,
                          label: Text(l10n.paramPresetGlobalTab),
                        ),
                      ],
                      selected: {_pendingTab ?? tab},
                      onSelectionChanged: (v) {
                        if (v.isEmpty) return;
                        final next = v.first;
                        if (next == (_pendingTab ?? _tab)) return;
                        if (next == _ParamsTab.model && !isPremium) {
                          _proOpenPaywall();
                          return;
                        }
                        // Commit the focused field to the current tab first.
                        // Switching immediately lets a deferred unfocus write
                        // the whole model snapshot onto Global.
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() => _pendingTab = next);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          final dest = _pendingTab;
                          if (dest == null || dest == _tab) {
                            if (_pendingTab != null) {
                              setState(() => _pendingTab = null);
                            }
                            return;
                          }
                          setState(() {
                            _tab = dest;
                            _pendingTab = null;
                          });
                        });
                      },
                    ),
                    if (showModelTab && hasModel) ...[
                      const SizedBox(height: 8),
                      Text(
                        modelPreset != null
                            ? l10n.paramPresetUsingCustom
                            : l10n.paramPresetUsingGlobal,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            final Widget? footer = _proModelFooter(
              context,
              showModelTab: showModelTab,
              hasModel: hasModel,
              presetKey: key,
              modelPreset: modelPreset,
              settingsProvider: settingsProvider,
            );

            Widget body;
            if (tab == _ParamsTab.model && !isPremium) {
              body = _proModelLockedBody(context, tabBar());
            } else if (tab == _ParamsTab.model && !hasModel) {
              body = Column(
                children: [
                  tabBar(),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.paramPresetNoModel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              body = Column(
                children: [
                  if (ProFeatures.included) tabBar(),
                  Expanded(
                    child: DesktopSettingsForm(
                      maxWidth: desktop ? 960 : double.infinity,
                      child: ModelParametersForm(
                        key: ValueKey(
                          'params-${tab.name}-${key ?? 'none'}',
                        ),
                        storageId: 'params-${tab.name}',
                        values: formValues,
                        visibility: visibility,
                        reasoningModelId: modelId ?? '',
                        modelMaxContextLength: modelMax,
                        contextFitLocked: !isPremium,
                        footer: footer,
                        onChanged: (next) {
                          // Bind this form instance to the tab it was built
                          // for. Unfocus after tapping the other tab can fire
                          // later; using live `_tab` would copy the snapshot
                          // onto Global.
                          if (tab == _ParamsTab.model) {
                            final presetKey =
                                settingsProvider.currentModelParamKey();
                            if (presetKey == null) return;
                            settingsProvider.upsertModelParamPreset(
                              presetKey,
                              next,
                            );
                          } else {
                            settingsProvider.applyGlobalParamPreset(next);
                          }
                        },
                        onContextLengthCommitted: () {
                          settingsProvider
                              .promptReloadIfLoadedContextStale(context);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            return body;
          },
        );
      },
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: GlassSettingsBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.modelParameters,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    helpAction,
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: topBg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(headerH),
        child: GlassPageHeader(
          title: l10n.modelParameters,
          onBack: () => Navigator.of(context).maybePop(),
          actions: [helpAction],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: headerH),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
