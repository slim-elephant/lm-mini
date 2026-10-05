import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../desktop/inference/local_inference_engine.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../screens/local_models_screen.dart';
import '../services/on_device_llm_service.dart';
import '../services/on_device_mlx_endpoint.dart';
import '../utils/on_device_engine_labels.dart';
import 'home_glass_header.dart';

/// Bottom sheet to pick the on-device engine (fllama GGUF / MLX).
Future<void> showOnDeviceEngineSheet(BuildContext context) {
  final settings = context.read<SettingsProvider>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _OnDeviceEngineSheet(settingsProvider: settings),
  );
}

class _OnDeviceEngineSheet extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const _OnDeviceEngineSheet({required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final canvas = isDark ? const Color(0xFF12151C) : const Color(0xFFF4F6FA);
    final fg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.88);
    final muted = fg.withValues(alpha: 0.62);

    return GlassCanvas(
      onLightCanvas: !isDark,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: canvas.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'On-device engine',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                      GlassCircleIconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onTap: () => Navigator.of(context).maybePop(),
                        onLightCanvas: !isDark,
                        child: Icon(Icons.close_rounded, size: 18, color: fg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how models run on this device.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: settingsProvider,
                    builder: (context, _) {
                      final activeKind =
                          settingsProvider.settings.activeProviderKind;
                      return FutureBuilder<bool>(
                        future: OnDeviceMlxEndpoint.isPlatformSupported(),
                        builder: (context, snap) {
                          final mlxOk = snap.data ?? false;
                          return Column(
                            children: [
                              _EngineOption(
                                title: l10n.onDeviceEngineFllamaLabel,
                                subtitle: Platform.isAndroid
                                    ? 'Cross-platform'
                                    : OnDeviceEngineLabels.fllamaSubtitle,
                                selected: activeKind == 'onDeviceGguf',
                                enabled: true,
                                onTap: () => _select(
                                  context,
                                  'onDeviceGguf',
                                ),
                              ),
                              if (!Platform.isAndroid) ...[
                                const SizedBox(height: 10),
                                _EngineOption(
                                  title: 'MLX',
                                  subtitle: OnDeviceEngineLabels.mlxSubtitle(
                                    supported: mlxOk,
                                  ),
                                  selected: activeKind == 'onDeviceMlx',
                                  enabled: mlxOk,
                                  onTap: () => _select(
                                    context,
                                    'onDeviceMlx',
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LocalModelsScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.cloud_download_outlined,
                        size: 18, color: cs.primary),
                    label: Text(l10n.browseOnDeviceModels),
                  ),
                  const Divider(height: 20),
                  Text(
                    'The model stays loaded in memory between messages so '
                    'replies are fast. Unload it to free RAM/GPU memory; it '
                    'reloads automatically on your next message.',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _unloadModel(context),
                    icon: Icon(Icons.eject_outlined, size: 18, color: fg),
                    label: Text('Unload model (free memory)',
                        style: TextStyle(color: fg)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unloadModel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // Stops the desktop llama-server sidecar (if any) and frees MLX weights;
    // fllama's native cache is released on its next idle sweep.
    await LocalInferenceEngine.instance.unload();
    await OnDeviceLLMService.instance.unloadAll();
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Model unloaded. It will reload on your next message.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _select(BuildContext context, String kind) async {
    assert(kind == 'onDeviceGguf' || kind == 'onDeviceMlx');
    if (settingsProvider.settings.activeProviderKind == kind) {
      Navigator.of(context).maybePop();
      return;
    }

    final before = settingsProvider.settings;
    await OnDeviceLLMService.instance.unloadAll();
    await settingsProvider.updateSettings(
      before.copyWith(activeProviderKind: kind),
      keepOnDeviceEngineChoice: true,
    );

    if (!context.mounted) return;
    final after = settingsProvider.settings;
    final l10n = AppLocalizations.of(context);
    final engineLabel =
        kind == 'onDeviceMlx' ? 'MLX' : l10n.onDeviceEngineFllamaLabel;
    final clearedModel = before.selectedLocalModelId != null &&
        after.selectedLocalModelId == null;
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clearedModel
              ? l10n.onDeviceEngineSwitchedCleared(engineLabel)
              : l10n.onDeviceEngineSwitched(engineLabel),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _EngineOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _EngineOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected
            ? cs.primaryContainer
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.55),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
