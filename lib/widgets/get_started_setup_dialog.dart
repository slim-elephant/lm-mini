import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../utils/fllama_cpu_support.dart';
import '../l10n/app_localizations.dart';
import '../models/local_model_spec.dart';
import '../models/server_profile.dart';
import '../pro/pro_features.dart';
import '../providers/settings_provider.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';
import '../services/device_capability_service.dart';
import '../services/local_model_catalog.dart';
import '../services/local_model_download_service.dart';
import 'onboarding_provider_connect_sheet.dart';
import 'glass_blur.dart';

/// Shown when the user skipped onboarding (or finished without a model) and
/// has no usable provider — offers a RAM-matched on-device download plus
/// Connect LM Studio, instead of a raw connection-error string.
Future<void> showGetStartedSetupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _GetStartedSetupDialog(),
  );
}

class _GetStartedSetupDialog extends StatefulWidget {
  const _GetStartedSetupDialog();

  @override
  State<_GetStartedSetupDialog> createState() => _GetStartedSetupDialogState();
}

class _GetStartedSetupDialogState extends State<_GetStartedSetupDialog> {
  final _downloads = LocalModelDownloadService.instance;

  DeviceCapability? _cap;
  LocalModelSpec? _recommended;
  bool _loading = true;
  bool _startingDownload = false;

  @override
  void initState() {
    super.initState();
    _downloads.addListener(_onDownloadTick);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _downloads.removeListener(_onDownloadTick);
    super.dispose();
  }

  void _onDownloadTick() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await _downloads.init();
    final cap = await DeviceCapabilityService.instance.get();
    if (!mounted) return;
    final freeOnly = !SubscriptionService().isPremium;
    final picks =
        LocalModelCatalog.onboardingPicks(cap, freeTierOnly: freeOnly);
    // Prefer "Best" for the device; fall back to Balanced / Faster / catalog.
    final recommended = picks?.best ??
        picks?.balanced ??
        picks?.faster ??
        LocalModelCatalog.bestFor(cap);
    setState(() {
      _cap = cap;
      _recommended = recommended;
      _loading = false;
    });
  }

  String _sizeLabel(LocalModelSpec spec) {
    if (spec.sizeMb >= 1000) {
      return '~${(spec.sizeMb / 1000).toStringAsFixed(1)} GB';
    }
    return '~${spec.sizeMb} MB';
  }

  Future<void> _downloadRecommended() async {
    final spec = _recommended;
    if (spec == null || _startingDownload) return;
    if (spec.engine == LocalEngine.fllama && !FllamaCpuSupport.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(FllamaCpuSupport.unsupportedMessage),
        duration: Duration(seconds: 6),
      ));
      return;
    }

    if (!SubscriptionService().isPremium && !spec.isFreeSlot) {
      // Public builds have no upgrade path; free-slot picks are offered instead.
      if (!ProFeatures.showUpsell) return;
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }

    setState(() => _startingDownload = true);
    final settings = context.read<SettingsProvider>();
    final kind =
        spec.engine == LocalEngine.mlx ? 'onDeviceMlx' : 'onDeviceGguf';
    await settings.updateSettings(
      settings.settings.copyWith(
        activeProviderKind: kind,
        selectedLocalModelId: spec.id,
        selectedModel: spec.displayName,
      ),
    );
    await settings.activateServerProfile(ServerProfile.onDeviceId);
    settings.clearConnectionError();

    final entry = _downloads.entryById(spec.id);
    if (entry?.status != LocalModelStatus.ready &&
        entry?.status != LocalModelStatus.downloading) {
      unawaited(_downloads.download(spec));
    }
    if (!mounted) return;
    setState(() => _startingDownload = false);

    // Keep dialog open while downloading so progress is visible; close when ready.
    final ready =
        _downloads.entryById(spec.id)?.status == LocalModelStatus.ready;
    if (ready) Navigator.pop(context);
  }

  Future<void> _connectLmStudio() async {
    final ok = await showOnboardingProviderConnectSheet(
      context: context,
      kind: OnboardingProviderKind.lmStudio,
      discovered: const [],
    );
    if (ok == true && mounted) {
      context.read<SettingsProvider>().clearConnectionError();
      Navigator.pop(context);
    }
  }

  void _openSettings() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry =
        _recommended != null ? _downloads.entryById(_recommended!.id) : null;
    final downloading = entry?.status == LocalModelStatus.downloading;
    final ready = entry?.status == LocalModelStatus.ready;
    final progress = entry?.progress ?? 0.0;
    final ramLabel = _cap == null
        ? null
        : '${_cap!.ramGb >= 10 ? _cap!.ramGb.round() : _cap!.ramGb.toStringAsFixed(0)} GB RAM';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: GlassBlur(
          sigmaX: 28,
          sigmaY: 28,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.05),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.92),
                          Colors.white.withValues(alpha: 0.78),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.55),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Get ready to chat',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No model is set up yet. Download one sized for this Mac, or connect LM Studio.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.62),
                          height: 1.35,
                        ),
                      ),
                      if (ramLabel != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Best for your device · $ramLabel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_recommended == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No on-device model fits this device. Connect LM Studio or browse models in Settings.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                      else
                        _RecommendedModelCard(
                          spec: _recommended!,
                          sizeLabel: _sizeLabel(_recommended!),
                          downloading: downloading,
                          ready: ready,
                          progress: progress,
                          onDownload: ready
                              ? () => Navigator.pop(context)
                              : _downloadRecommended,
                          busy: _startingDownload,
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _connectLmStudio,
                        icon: const Icon(Icons.desktop_windows_outlined),
                        label: Text(l10n.welcomeWizardConnectLmStudio),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.connectionPopupDismiss),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _openSettings,
                            child: Text(l10n.connectionPopupGoToSettings),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedModelCard extends StatelessWidget {
  final LocalModelSpec spec;
  final String sizeLabel;
  final bool downloading;
  final bool ready;
  final double progress;
  final VoidCallback onDownload;
  final bool busy;

  const _RecommendedModelCard({
    required this.spec,
    required this.sizeLabel,
    required this.downloading,
    required this.ready,
    required this.progress,
    required this.onDownload,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final engineLabel =
        spec.engine == LocalEngine.mlx ? 'MLX' : spec.quantization;
    final meta =
        '${spec.paramsB.toStringAsFixed(spec.paramsB < 10 ? 1 : 0)}B · $engineLabel · $sizeLabel';

    String buttonLabel;
    if (ready) {
      buttonLabel = 'Ready — continue';
    } else if (downloading || busy) {
      buttonLabel = 'Downloading… ${(progress * 100).clamp(0, 100).round()}%';
    } else {
      buttonLabel = 'Download ${spec.displayName}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.download_rounded,
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (spec.description != null && spec.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              spec.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
                height: 1.35,
              ),
            ),
          ],
          if (downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: (downloading || busy) ? null : onDownload,
            icon: Icon(
              ready ? Icons.check_circle_outline : Icons.download_rounded,
              size: 20,
            ),
            label: Text(buttonLabel),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
