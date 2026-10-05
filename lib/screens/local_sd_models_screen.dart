import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../models/local_model_spec.dart';
import '../models/local_sd_asset_spec.dart';
import '../pro/pro_features.dart';
import '../providers/settings_provider.dart';
import '../services/device_capability_service.dart';
import '../services/local_sd_asset_catalog.dart';
import '../services/local_sd_asset_download_service.dart';
import 'subscription_screen.dart';

/// User-facing browser for on-device Stable Diffusion assets — mirrors
/// `LocalModelsScreen` but for checkpoints, LoRAs, and VAEs.
///
/// Free-tier rules (enforced here, in the UI):
///   - Any user can download the single `isFreeSlot` entry for each kind
///     (1 checkpoint + 1 LoRA + 1 VAE).
///   - Other entries open the paywall when tapped.
///   - Activating a checkpoint sets [AppSettings.selectedLocalSdCheckpointId]
///     and switches image gen to on-device.
class LocalSdModelsScreen extends StatefulWidget {
  const LocalSdModelsScreen({super.key});

  @override
  State<LocalSdModelsScreen> createState() => _LocalSdModelsScreenState();
}

class _LocalSdModelsScreenState extends State<LocalSdModelsScreen> {
  final _downloads = LocalSdAssetDownloadService.instance;
  final _capability = DeviceCapabilityService.instance;
  DeviceCapability? _cap;
  bool _initializing = true;
  int _totalDiskBytes = 0;
  SdAssetKind? _kindFilter; // null = all kinds
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _downloads.addListener(_refreshStorage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _downloads.removeListener(_refreshStorage);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _downloads.init();
    final bytes = await _downloads.totalDiskBytes();
    final cap = await _capability.get();
    if (!mounted) return;
    setState(() {
      _totalDiskBytes = bytes;
      _cap = cap;
      _initializing = false;
    });
  }

  Future<void> _refreshStorage() async {
    final bytes = await _downloads.totalDiskBytes();
    if (!mounted) return;
    setState(() => _totalDiskBytes = bytes);
  }

  bool _isFreeTierBlocked(LocalSdAssetSpec spec) {
    if (SubscriptionService().isPremium) return false;
    return !spec.isFreeSlot;
  }

  void _openPaywall() {
    if (!ProFeatures.showUpsell) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<bool> _confirmTightFit(LocalSdAssetSpec spec, ModelFit fit) async {
    final cap = _cap;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(fit == ModelFit.blocked ? 'May not fit' : 'Tight fit'),
        content: Text(
          '${spec.displayName} wants ~${spec.minRamGb.toStringAsFixed(0)} GB RAM'
          '${cap != null ? " (this device: ${cap.ramDisplayLabel})" : ""}.\n\n'
          'Generation may be slow or fail under memory pressure. Continue?',
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
    return ok == true;
  }

  Future<void> _download(LocalSdAssetSpec spec) async {
    if (_isFreeTierBlocked(spec)) {
      _openPaywall();
      return;
    }
    final verdict =
        _cap == null ? ModelFit.runs : _capability.sdVerdict(spec, _cap);
    if (verdict == ModelFit.tight || verdict == ModelFit.blocked) {
      if (!await _confirmTightFit(spec, verdict)) return;
    }
    await _downloads.download(spec);
  }

  Future<void> _activate(LocalSdAssetSpec spec) async {
    if (spec.kind != SdAssetKind.checkpoint) return;
    final entry = _downloads.entryById(spec.id);
    if (entry?.status != LocalSdAssetStatus.ready) return;

    final verdict =
        _cap == null ? ModelFit.runs : _capability.sdVerdict(spec, _cap);
    if (verdict == ModelFit.tight || verdict == ModelFit.blocked) {
      if (!await _confirmTightFit(spec, verdict)) return;
    }

    final settings = context.read<SettingsProvider>();
    final res = spec.nativeResolution ?? 512;
    await settings.updateSettings(
      settings.settings.copyWith(
        selectedLocalSdCheckpointId: spec.id,
        imageGenProvider: 'onDevice',
        imageGenEnabled: true,
        imageGenWidth: res,
        imageGenHeight: res,
        imageGenSteps: spec.supportsNegativePrompt ? 20 : 4,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Using ${spec.displayName} for on-device image gen')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = SubscriptionService().isPremium;
    final selectedId =
        context.watch<SettingsProvider>().settings.selectedLocalSdCheckpointId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('On-Device Stable Diffusion'),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _downloads,
              builder: (context, _) {
                final q = _searchQuery;
                final entries = LocalSdAssetCatalog.entries
                    // Public builds list only the free-slot assets.
                    .where((e) => ProFeatures.included || e.isFreeSlot)
                    .where((e) =>
                        _kindFilter == null || e.kind == _kindFilter)
                    .where((e) {
                      if (q.isEmpty) return true;
                      bool hit(String? s) =>
                          s != null && s.toLowerCase().contains(q);
                      return hit(e.id) ||
                          hit(e.displayName) ||
                          hit(e.description) ||
                          hit(e.hfRepo);
                    })
                    .toList()
                  ..sort((a, b) {
                    final af = a.isFreeSlot ? 0 : 1;
                    final bf = b.isFreeSlot ? 0 : 1;
                    if (af != bf) return af - bf;
                    final ak = a.kind.index;
                    final bk = b.kind.index;
                    if (ak != bk) return ak - bk;
                    return 0;
                  });

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _storageBanner(theme),
                    if (_cap != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          '${_cap!.deviceName} · ${_cap!.ramDisplayLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    _searchAndFilter(theme),
                    if (!isPremium && ProFeatures.included)
                      _freeTierBanner(theme),
                    const SizedBox(height: 8),
                    ...entries.map((spec) {
                      final entry = _downloads.entryById(spec.id);
                      final fit = _cap == null
                          ? ModelFit.runs
                          : _capability.sdVerdict(spec, _cap);
                      return _SdAssetTile(
                        spec: spec,
                        entry: entry,
                        blockedByPlan: _isFreeTierBlocked(spec),
                        isActive: selectedId == spec.id,
                        fit: fit,
                        onDownload: () => _download(spec),
                        onCancel: () => _downloads.cancel(spec.id),
                        onDelete: () => _confirmDelete(spec),
                        onRetry: () => _download(spec),
                        onUse: spec.kind == SdAssetKind.checkpoint
                            ? () => _activate(spec)
                            : null,
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(LocalSdAssetSpec spec) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete asset?'),
        content: Text(
            'This removes ${spec.displayName} from disk. You can re-download it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final settings = context.read<SettingsProvider>();
      if (settings.settings.selectedLocalSdCheckpointId == spec.id) {
        await settings.updateSettings(
          settings.settings.copyWith(selectedLocalSdCheckpointId: null),
        );
      }
      await _downloads.delete(spec.id);
    }
  }

  Widget _storageBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.sd_storage_outlined,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage used',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatBytes(_totalDiskBytes),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search SD assets…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (v) =>
                setState(() => _searchQuery = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _filterChip(theme, label: 'All', value: null),
              _filterChip(theme,
                  label: 'Checkpoints', value: SdAssetKind.checkpoint),
              _filterChip(theme, label: 'LoRAs', value: SdAssetKind.lora),
              _filterChip(theme, label: 'VAEs', value: SdAssetKind.vae),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(ThemeData theme,
      {required String label, required SdAssetKind? value}) {
    final selected = _kindFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _kindFilter = value),
    );
  }

  Widget _freeTierBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: _openPaywall,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.amber.withOpacity(0.08),
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free tier',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '1 free checkpoint (~1.5 GB). Pro unlocks SDXL (~6 GB) and more.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SdAssetTile extends StatelessWidget {
  final LocalSdAssetSpec spec;
  final LocalSdAssetEntry? entry;
  final bool blockedByPlan;
  final bool isActive;
  final ModelFit fit;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onRetry;
  final VoidCallback? onUse;

  const _SdAssetTile({
    required this.spec,
    required this.entry,
    required this.blockedByPlan,
    required this.isActive,
    required this.fit,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    required this.onRetry,
    this.onUse,
  });

  String _kindLabel(SdAssetKind k) {
    switch (k) {
      case SdAssetKind.checkpoint:
        return 'Checkpoint';
      case SdAssetKind.lora:
        return 'LoRA';
      case SdAssetKind.vae:
        return 'VAE';
    }
  }

  IconData _kindIcon(SdAssetKind k) {
    switch (k) {
      case SdAssetKind.checkpoint:
        return Icons.image_outlined;
      case SdAssetKind.lora:
        return Icons.tune;
      case SdAssetKind.vae:
        return Icons.auto_awesome_motion;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = entry?.status ?? LocalSdAssetStatus.notDownloaded;
    final progress = entry?.progress ?? 0.0;
    final sizeLabel = spec.sizeMb >= 1024
        ? '${(spec.sizeMb / 1024).toStringAsFixed(1)} GB'
        : '${spec.sizeMb} MB';

    Widget trailing;
    switch (status) {
      case LocalSdAssetStatus.downloading:
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 3,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: onCancel,
            ),
          ],
        );
        break;
      case LocalSdAssetStatus.ready:
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onUse != null)
              FilledButton(
                onPressed: onUse,
                child: Text(isActive ? 'Active' : 'Use'),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        );
        break;
      case LocalSdAssetStatus.failed:
        trailing = IconButton(
          icon: const Icon(Icons.refresh, color: Colors.orange),
          tooltip: 'Retry',
          onPressed: onRetry,
        );
        break;
      case LocalSdAssetStatus.notDownloaded:
        trailing = FilledButton.tonalIcon(
          icon: Icon(
            blockedByPlan ? Icons.lock_outline : Icons.download_outlined,
            size: 18,
          ),
          label: Text(blockedByPlan ? 'Pro' : 'Download'),
          onPressed: onDownload,
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isActive
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(_kindIcon(spec.kind), color: theme.colorScheme.primary),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(spec.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (spec.isFreeSlot) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('FREE',
                    style: TextStyle(fontSize: 10, color: Colors.green)),
              ),
            ],
            if (fit == ModelFit.tight) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: Colors.orange.shade700),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${_kindLabel(spec.kind)} · $sizeLabel'
              '${spec.nativeResolution != null ? " · ${spec.nativeResolution}px" : ""}'
              '${spec.description != null ? "\n${spec.description}" : ""}',
              style: theme.textTheme.bodySmall,
            ),
            if (status == LocalSdAssetStatus.downloading)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                ),
              ),
          ],
        ),
        isThreeLine: spec.description != null,
        trailing: trailing,
      ),
    );
  }
}
