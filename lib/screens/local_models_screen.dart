import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../desktop/desktop_platform.dart';
import '../l10n/app_localizations.dart';
import '../models/local_model_spec.dart';
import '../models/pickable_model.dart';
import '../pro/pro_features.dart';
import '../providers/settings_provider.dart';
import '../services/device_capability_service.dart';
import '../services/local_model_catalog.dart';
import '../services/local_model_download_service.dart';
import '../services/mlx_folder_import.dart';
import '../services/on_device_llm_service.dart';
import '../services/on_device_mlx_endpoint.dart';
import '../services/apple_intelligence_endpoint.dart';
import '../utils/mlx_model_types.dart';
import '../widgets/apple_intelligence_card.dart';
import '../widgets/home_glass_header.dart';
import '../widgets/huggingface_download_flow.dart';
import '../widgets/model_browser/model_browser_screen.dart';
import '../widgets/model_browser/model_family_card.dart';
import '../widgets/model_browser/on_device_adapter.dart';
import '../widgets/pro_feature_teaser.dart';
import '../widgets/pro_price_button.dart';
import 'subscription_screen.dart';

enum _ImportKind { gguf, mlx }

/// Marks the built-in Apple Intelligence row in the on-device list.
class _AppleIntelligenceChoice {
  const _AppleIntelligenceChoice();
}

/// On-device model catalog browser (Settings entry).
class LocalModelsScreen extends StatefulWidget {
  final bool embedded;

  /// Set when opened from a family card: only that family's models.
  final String? familyFilter;
  const LocalModelsScreen(
      {super.key, this.embedded = false, this.familyFilter});

  @override
  State<LocalModelsScreen> createState() => _LocalModelsScreenState();
}

class _LocalModelsScreenState extends State<LocalModelsScreen> {
  final _downloads = LocalModelDownloadService.instance;
  final _capability = DeviceCapabilityService.instance;
  DeviceCapability? _cap;
  bool _initializing = true;
  int _totalDiskBytes = 0;
  LocalEngine? _engineFilter;
  String _filterId = 'all';
  bool _importing = false;
  bool _groupModels = true;
  AppleIntelligenceStatus? _appleStatus;

  /// Free plan: keep the screen awake while a model downloads here.
  bool _holdingWakelock = false;
  bool _showSmallModels = false;
  String? _activatingId;

  /// Catalog model focused for the Download FAB (not yet on device).
  LocalModelSpec? _pendingDownload;

  @override
  void dispose() {
    _downloads.removeListener(_refreshStorage);
    _downloads.removeListener(_syncWakelock);
    if (_holdingWakelock) unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _downloads.addListener(_refreshStorage);
    _downloads.addListener(_syncWakelock);
  }

  /// Free plan downloads stop when the phone locks, so hold the screen on
  /// while one is running and this screen is open.
  void _syncWakelock() {
    final want = !ProFeatures.isPro &&
        _downloads.entries.any((e) => e.status == LocalModelStatus.downloading);
    if (want == _holdingWakelock) return;
    _holdingWakelock = want;
    unawaited(want ? WakelockPlus.enable() : WakelockPlus.disable());
  }

  Future<void> _refreshStorage() async {
    final bytes = await _downloads.totalDiskBytes();
    if (!mounted) return;
    setState(() => _totalDiskBytes = bytes);
  }

  Future<void> _bootstrap() async {
    await _downloads.init();
    final cap = await _capability.get();
    final bytes = await _downloads.totalDiskBytes();
    if (!mounted) return;
    setState(() {
      _cap = cap;
      _totalDiskBytes = bytes;
      _initializing = false;
    });
    _syncWakelock();
    if (widget.familyFilter != null) return;
    final apple = await AppleIntelligenceCard.status(refresh: true);
    if (!mounted) return;
    setState(() => _appleStatus = apple);
    await _maybeAutoSelectApple(apple);
  }

  /// No model downloaded and chat is set to on-device: Apple's built-in
  /// model is the only thing that can answer, so use it.
  Future<void> _maybeAutoSelectApple(AppleIntelligenceStatus status) async {
    if (status != AppleIntelligenceStatus.available) return;
    final sp = context.read<SettingsProvider>();
    final kind = sp.settings.activeProviderKind;
    if (kind == 'appleIntelligence') return;
    final onDevice = kind == 'onDeviceGguf' || kind == 'onDeviceMlx';
    if (!onDevice && sp.isProviderConfigured()) return;
    if (_downloads.readyEntries.isNotEmpty) return;
    await _useAppleIntelligence();
  }

  Future<void> _useAppleIntelligence() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    await context.read<SettingsProvider>().activateAppleIntelligence();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.appleIntelligenceNowUsing),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _pageTitle(BuildContext context) {
    final family = widget.familyFilter;
    if (family == null) return 'On-Device Models';
    if (family == LocalModelCatalog.olderModelsFamily) {
      return AppLocalizations.of(context).olderModelsTitle;
    }
    final line = LocalModelCatalog.familyLines(family);
    return line.isEmpty ? family : line;
  }

  /// The Apple Intelligence row, or null where it can't be used.
  PickableModel? _appleRow(BuildContext context, String activeKind) {
    final status = _appleStatus;
    if (status == null || !AppleIntelligenceCard.isOffered(status)) {
      return null;
    }
    final l10n = AppLocalizations.of(context);
    final active = activeKind == 'appleIntelligence';
    final subtitle = switch (status) {
      AppleIntelligenceStatus.appleIntelligenceNotEnabled =>
        l10n.appleIntelligenceTurnOn,
      AppleIntelligenceStatus.modelNotReady =>
        l10n.appleIntelligenceGettingReady,
      _ =>
        active ? l10n.appleIntelligenceInUse : l10n.appleIntelligenceSubtitle,
    };
    return PickableModel(
      id: 'apple-intelligence',
      displayName: 'Apple Intelligence',
      subtitle: subtitle,
      isLoaded: active,
      isSelected: active,
      familyGroup: 'Apple',
      typeLabel: l10n.appleIntelligenceBadge,
      providerKind: ModelProviderKind.onDevice,
      statusKey: 'downloaded',
      details: const [
        ModelDetailRow('Engine', 'Apple Foundation Models'),
        ModelDetailRow(
            'Context', '${AppleIntelligenceEndpoint.contextTokens} tokens'),
        ModelDetailRow('Download', 'None, built into the OS'),
      ],
      source: const _AppleIntelligenceChoice(),
    );
  }

  bool _isFreeTierBlocked(LocalModelSpec spec) {
    if (ProFeatures.isPro) return false;
    return !LocalModelCatalog.isFreeTier(spec);
  }

  /// Free-tier lock that may be shown as an upgrade prompt. The public build
  /// never shows one (and never lists Pro-tier rows, see [_listedInBuild]).
  bool _isUpsellBlocked(LocalModelSpec spec) =>
      ProFeatures.showUpsell && _isFreeTierBlocked(spec);

  /// The public build lists only the free-slot catalog models and the user's
  /// own imports; Pro-tier rows exist only where Pro can be bought.
  bool _listedInBuild(LocalModelSpec spec) =>
      ProFeatures.included || LocalModelCatalog.isFreeTier(spec);

  String _formatDisk(int bytes) {
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final activeLocalId =
        context.watch<SettingsProvider>().settings.selectedLocalModelId;
    final showMlx = !Platform.isAndroid;
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _downloads,
      builder: (context, _) {
        final models = <PickableModel>[];

        bool passEngine(LocalModelSpec s) {
          if (!LocalModelCatalog.isListed(s)) return false;
          if (!_listedInBuild(s)) return false;
          if (!showMlx && s.engine == LocalEngine.mlx) return false;
          if (s.engine == LocalEngine.moeStream && !Platform.isIOS) {
            return false;
          }
          if (_engineFilter != null && s.engine != _engineFilter) return false;
          final family = widget.familyFilter;
          if (family != null && LocalModelCatalog.familyGroup(s) != family) {
            return false;
          }
          return true;
        }

        final desktop = DesktopPlatform.isDesktop;
        bool passDesktopCatalog(LocalModelSpec s) {
          if (!desktop) return true;
          if (_showSmallModels) return true;
          if (LocalModelCatalog.isDraft(s)) {
            final e = _downloads.entryById(s.id);
            return e != null && e.status != LocalModelStatus.notDownloaded;
          }
          if (!LocalModelCatalog.isPhoneClass(s)) return true;
          final e = _downloads.entryById(s.id);
          return e != null && e.status != LocalModelStatus.notDownloaded;
        }

        final vramPick =
            _cap == null ? null : LocalModelCatalog.recommendedForVram(_cap!);
        final best = _cap == null
            ? null
            : (desktop
                ? (vramPick ?? LocalModelCatalog.bestFor(_cap!))
                : LocalModelCatalog.bestFor(_cap!));
        // One "Recommended" badge: the best fit for this device.
        final recommendedIds = <String>{
          if (best != null && passEngine(best)) best.id,
        };

        final downloaded = _downloads.entries
            .where((e) =>
                e.status == LocalModelStatus.ready ||
                e.status == LocalModelStatus.downloading ||
                e.status == LocalModelStatus.failed)
            .map((e) => _downloads.effectiveSpec(e))
            .where(passEngine)
            .where(passDesktopCatalog)
            .toList()
          ..sort((a, b) {
            final ar = recommendedIds.contains(a.id) ? 0 : 1;
            final br = recommendedIds.contains(b.id) ? 0 : 1;
            if (ar != br) return ar - br;
            return a.displayName.compareTo(b.displayName);
          });

        for (final spec in downloaded) {
          models.add(mapOnDeviceModel(
            spec: spec,
            entry: _downloads.entryById(spec.id),
            activeLocalId: activeLocalId,
            cap: _cap,
            capability: _capability,
            isRecommended: recommendedIds.contains(spec.id),
            isFocused: _pendingDownload?.id == spec.id,
            isLoading: _activatingId == spec.id,
            compactQuantName: desktop,
          ));
        }

        final catalog = LocalModelCatalog.entries
            .where((s) => _downloads.entryById(s.id) == null)
            .where(passEngine)
            .where(passDesktopCatalog)
            .toList()
          ..sort((a, b) {
            final ar = recommendedIds.contains(a.id) ? 0 : 1;
            final br = recommendedIds.contains(b.id) ? 0 : 1;
            if (ar != br) return ar - br;
            if (_cap != null) {
              final as = LocalModelCatalog.fitScore(a, _cap!);
              final bs = LocalModelCatalog.fitScore(b, _cap!);
              if (as != bs) return bs.compareTo(as);
            }
            return a.displayName.compareTo(b.displayName);
          });

        for (final spec in catalog) {
          models.add(mapOnDeviceModel(
            spec: spec,
            entry: null,
            activeLocalId: activeLocalId,
            cap: _cap,
            capability: _capability,
            isRecommended: recommendedIds.contains(spec.id),
            isProLocked: _isUpsellBlocked(spec),
            isFocused: _pendingDownload?.id == spec.id,
            isLoading: _activatingId == spec.id,
            compactQuantName: desktop,
          ));
        }

        // Clear pending if it finished downloading or disappeared.
        final pending = _pendingDownload;
        if (pending != null) {
          final entry = _downloads.entryById(pending.id);
          if (entry?.status == LocalModelStatus.ready ||
              entry?.status == LocalModelStatus.downloading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pendingDownload?.id == pending.id) {
                setState(() => _pendingDownload = null);
              }
            });
          }
        }

        final showDownloadFab = pending != null &&
            (_downloads.entryById(pending.id)?.status ??
                    LocalModelStatus.notDownloaded) !=
                LocalModelStatus.ready &&
            (_downloads.entryById(pending.id)?.status ??
                    LocalModelStatus.notDownloaded) !=
                LocalModelStatus.downloading;

        final lineOrder = <String>[];
        if (desktop) {
          final lines = <String, double>{};
          for (final m in models) {
            final spec = m.source;
            if (spec is! LocalModelSpec) continue;
            final line = LocalModelCatalog.modelLine(spec);
            final prev = lines[line] ?? 0;
            if (spec.paramsB > prev) lines[line] = spec.paramsB;
          }
          final ranked = lines.entries.toList()
            ..sort((a, b) {
              final aRec =
                  models.any((m) => m.familyGroup == a.key && m.isRecommended);
              final bRec =
                  models.any((m) => m.familyGroup == b.key && m.isRecommended);
              if (aRec != bRec) return aRec ? -1 : 1;
              return b.value.compareTo(a.value);
            });
          lineOrder.addAll(ranked.map((e) => e.key));
        }

        // Top of the list: Apple's built-in model, then the recommended
        // pick, then what's already on this device. In grouped mode the
        // families below still list every model.
        final familyPage = widget.familyFilter != null;
        final grouped = !familyPage && (desktop || _groupModels);
        final pinned = <PickableModel>[];
        if (!familyPage && !desktop) {
          final apple = _appleRow(context,
              context.read<SettingsProvider>().settings.activeProviderKind);
          if (apple != null) pinned.add(apple);
          // Grouped: what's on this device stays on top; the best-quality
          // pick is badged on its family card instead of pinned.
          if (grouped) {
            pinned.addAll(models.where((m) =>
                m.statusKey == 'downloaded' &&
                m.familyGroup != LocalModelCatalog.olderModelsFamily));
          } else {
            pinned.addAll(models.where((m) => m.isRecommended));
          }
        }
        final pinnedIds = pinned.map((m) => m.id).toSet();
        final listed = grouped
            ? models
            : models.where((m) => !pinnedIds.contains(m.id)).toList();

        return ModelBrowserScreen(
          embedded: widget.embedded && !familyPage,
          title: _pageTitle(context),
          isLoading: _initializing,
          models: listed,
          pinned: pinned,
          showDownloadFab: true,
          centeredList: desktop,
          onOpenFamily: desktop
              ? null
              : (family) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LocalModelsScreen(familyFilter: family),
                    ),
                  ),
          familyLeadingBuilder: (family) =>
              family == LocalModelCatalog.olderModelsFamily
                  ? Icon(Icons.history_rounded, color: cs.onSurfaceVariant)
                  : BrandLogo.forAsset(
                      context, LocalModelCatalog.familyLogo(family), family),
          familyTitleBuilder: (family) {
            if (family == LocalModelCatalog.olderModelsFamily) {
              return AppLocalizations.of(context).olderModelsTitle;
            }
            final line = LocalModelCatalog.familyLines(family);
            return line.isEmpty ? family : line;
          },
          familySubtitleBuilder: (family, items) {
            final l10n = AppLocalizations.of(context);
            final count = l10n.aiModelsCount(items.length);
            if (family == LocalModelCatalog.olderModelsFamily) {
              return '${l10n.olderModelsSubtitle} · $count';
            }
            // The title shows the model line; the company goes here.
            final company = LocalModelCatalog.familyCompany(family);
            return company.isEmpty ? count : '$company · $count';
          },
          groupByFamily: grouped,
          familyOrder: desktop ? lineOrder : LocalModelCatalog.familyOrder,
          filters: const [
            ModelBrowserFilter(id: 'all', label: 'All'),
            ModelBrowserFilter(id: 'downloaded', label: 'Downloaded'),
          ],
          selectedFilterId: _filterId,
          onFilterChanged: (id) => setState(() => _filterId = id),
          filtersTrailing: familyPage
              ? null
              : desktop
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _showSmallModels,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) =>
                                setState(() => _showSmallModels = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(
                              () => _showSmallModels = !_showSmallModels),
                          child: Text(
                            'Small models',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _groupModels,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) =>
                                setState(() => _groupModels = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _groupModels = !_groupModels),
                          child: Text(
                            'Group',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
          actions: [
            GlassCircleIconButton(
              tooltip: 'Import model from Files',
              onTap: _importing ? null : _showImportOptions,
              child: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file,
                      size: 22, color: Colors.white),
            ),
            if (ProFeatures.included)
              GlassCircleIconButton(
                tooltip: 'Download from Hugging Face',
                onTap: _showAddCustomDialog,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.add_link, size: 22, color: Colors.white),
                    if (ProFeatures.showUpsell)
                      const Positioned(
                        right: -4,
                        bottom: -4,
                        child: Icon(Icons.star, size: 14, color: Colors.amber),
                      ),
                  ],
                ),
              ),
          ],
          headerExtra: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<LocalEngine?>(
                segments: [
                  const ButtonSegment(value: null, label: Text('All')),
                  const ButtonSegment(
                      value: LocalEngine.fllama, label: Text('GGUF')),
                  if (Platform.isIOS && LocalModelCatalog.listsMoeStream)
                    const ButtonSegment(
                        value: LocalEngine.moeStream, label: Text('Stream')),
                  if (showMlx)
                    const ButtonSegment(
                        value: LocalEngine.mlx, label: Text('MLX')),
                ],
                selected: {_engineFilter},
                onSelectionChanged: (s) =>
                    setState(() => _engineFilter = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              if (_cap != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_cap!.ramDisplayLabel}'
                  '${_cap!.supportsMlx ? ' · MLX ready' : ''}'
                  '${_cap!.supportsVulkan ? ' · Vulkan' : ''}'
                  '${_totalDiskBytes > 0 ? ' · ${_formatDisk(_totalDiskBytes)} used' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          bottomAction: showDownloadFab
              ? FilledButton.icon(
                  onPressed: () {
                    final spec = _pendingDownload;
                    if (spec == null) return;
                    if (_isFreeTierBlocked(spec)) {
                      _openPaywall();
                      return;
                    }
                    _onDownload(spec);
                  },
                  icon: Icon(
                    _isUpsellBlocked(pending)
                        ? Icons.star_rounded
                        : Icons.download_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isUpsellBlocked(pending)
                        ? 'Upgrade to Download'
                        : 'Download Model',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                )
              : null,
          onSelect: (m) {
            final spec = m.source;
            if (spec is _AppleIntelligenceChoice) {
              if (_appleStatus == AppleIntelligenceStatus.available &&
                  !m.isLoaded) {
                unawaited(_useAppleIntelligence());
              }
              return;
            }
            if (spec is! LocalModelSpec) return;
            final entry = _downloads.entryById(spec.id);
            final status = entry?.status ?? LocalModelStatus.notDownloaded;
            if (status == LocalModelStatus.ready) {
              setState(() => _pendingDownload = null);
              if (activeLocalId == spec.id) return;
              _activate(spec);
            } else if (status == LocalModelStatus.downloading) {
              // no-op while downloading
            } else {
              setState(() => _pendingDownload = spec);
            }
          },
          trailingBuilder: (context, m) {
            final spec = m.source;
            if (spec is! LocalModelSpec) return const SizedBox.shrink();
            final entry = _downloads.entryById(spec.id);
            final status = entry?.status ?? LocalModelStatus.notDownloaded;
            final blocked = _isFreeTierBlocked(spec);

            final items = <PopupMenuEntry<String>>[];
            if (status == LocalModelStatus.ready && !m.isSelected) {
              items.add(const PopupMenuItem(value: 'use', child: Text('Use')));
            }
            if ((status == LocalModelStatus.notDownloaded ||
                    status == LocalModelStatus.failed) &&
                (!blocked || ProFeatures.showUpsell)) {
              items.add(PopupMenuItem(
                value: blocked ? 'upgrade' : 'download',
                child: Text(blocked ? 'Upgrade to download' : 'Download'),
              ));
            }
            if (status == LocalModelStatus.downloading) {
              items.add(
                  const PopupMenuItem(value: 'cancel', child: Text('Cancel')));
            }
            if (status == LocalModelStatus.ready ||
                status == LocalModelStatus.failed) {
              items.add(
                  const PopupMenuItem(value: 'delete', child: Text('Delete')));
            }
            if (items.isEmpty) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (action) {
                switch (action) {
                  case 'use':
                    _activate(spec);
                  case 'download':
                    if (blocked) {
                      _openPaywall();
                    } else {
                      _onDownload(spec);
                    }
                  case 'cancel':
                    _downloads.cancel(spec.id);
                  case 'delete':
                    _confirmDelete(spec);
                  case 'upgrade':
                    _openPaywall();
                }
              },
              itemBuilder: (ctx) => items,
            );
          },
        );
      },
    );
  }

  Future<void> _showImportOptions() async {
    if (!mounted) return;
    final mlxSupported = (Platform.isIOS || Platform.isMacOS) &&
        (_cap?.supportsMlx ?? false) &&
        await OnDeviceMlxEndpoint.isPlatformSupported();

    if (!mounted) return;
    _ImportKind kind;
    if (mlxSupported) {
      final picked = await showModalBottomSheet<_ImportKind>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Import GGUF file'),
                subtitle: const Text('Single .gguf model file'),
                onTap: () => Navigator.pop(ctx, _ImportKind.gguf),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Import MLX folder'),
                subtitle: const Text(
                  'Folder with config.json and *.safetensors (Apple Silicon)',
                ),
                onTap: () => Navigator.pop(ctx, _ImportKind.mlx),
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      kind = picked;
    } else {
      kind = _ImportKind.gguf;
    }

    if (kind == _ImportKind.mlx) {
      await _importMlxFromDirectory();
    } else {
      await _importGgufFromFile();
    }
  }

  Future<bool> _ensureImportAllowed() async {
    if (!ProFeatures.isPro && _downloads.importedModelCount >= 1) {
      final showUpsell = ProFeatures.showUpsell;
      final l10n = AppLocalizations.of(context);
      final billed = ProPriceButton.billedYearly(l10n);
      final upgrade = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import limit reached'),
          content: Text(
            showUpsell
                ? 'Free plan includes one imported model. Upgrade to '
                    'LM Mini Pro to import unlimited GGUF and MLX models '
                    'from Files.${billed == null ? '' : '\n\n$billed'}'
                : 'This build includes one imported model. Delete it to '
                    'import a different one.',
          ),
          actions: showUpsell
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(ProPriceButton.label(l10n)),
                  ),
                ]
              : [
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('OK'),
                  ),
                ],
        ),
      );
      if (upgrade == true) _openPaywall();
      return false;
    }
    return true;
  }

  Future<void> _importGgufFromFile() async {
    if (!await _ensureImportAllowed()) return;

    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      final name = picked.name.toLowerCase();
      if (!name.endsWith('.gguf')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a .gguf model file.'),
            ),
          );
        }
        return;
      }
      final path = picked.path;
      if (path == null || path.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not read the selected file. Try again from Files.'),
            ),
          );
        }
        return;
      }

      final spec = await _downloads.importFromFile(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${spec.displayName}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// One imported model (GGUF or MLX) is free; Pro removes the limit.
  Future<void> _importMlxFromDirectory() async {
    if (!await _ensureImportAllowed()) return;

    if (Platform.isIOS) {
      await _importMlxFromPickedFolderIos();
      return;
    }

    setState(() => _importing = true);
    try {
      final dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null || dirPath.isEmpty) return;

      final spec = await _downloads.importMlxFromDirectory(dirPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported MLX model ${spec.displayName}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MLX import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// iOS can only read a picked folder while the native picker holds its
  /// security scope, so the model files are copied into the app first and
  /// then moved into place.
  Future<void> _importMlxFromPickedFolderIos() async {
    void show(String text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
      );
    }

    PickedMlxFolder? folder;
    try {
      folder = await MlxFolderImport.pick();
    } on PlatformException catch (e) {
      show('MLX import failed: ${e.message ?? e.code}');
      return;
    }
    if (folder == null) return;

    final problem = mlxConfigProblem(folder.configJson);
    if (problem != null) {
      await MlxFolderImport.release(folder);
      show(problem);
      return;
    }

    setState(() => _importing = true);
    String? stage;
    try {
      stage = await MlxFolderImport.copyInto(folder);
      final spec = await _downloads.importMlxFromDirectory(
        stage,
        displayName: folder.name.replaceAll('_', ' '),
        moveFiles: true,
      );
      show('Imported MLX model ${spec.displayName}');
    } on PlatformException catch (e) {
      show('MLX import failed: ${e.message ?? e.code}');
    } catch (e) {
      show('MLX import failed: $e');
    } finally {
      if (stage != null) await MlxFolderImport.deleteStage(stage);
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Browsing Hugging Face is free; downloading to the device needs Pro.
  Future<void> _showAddCustomDialog() async {
    if (!ProFeatures.isPro && !ProFeatures.showUpsell) return;

    await HuggingFaceDownloadFlow.show(
      context: context,
      target: HuggingFaceDownloadTarget.onDevice,
      beforeDownload: (sheetContext) async {
        if (ProFeatures.isPro) return true;
        await showProFeatureTeaser(sheetContext, PaywallFeature.huggingFace);
        return false;
      },
      onDownload: (selection) async {
        if (selection.isPlainModelId) return;
        await _downloads.addCustomFromHuggingFace(selection.onDeviceRef);
      },
    );
  }

  Future<bool> _confirmRiskyModel(LocalModelSpec spec) async {
    final l10n = AppLocalizations.of(context);
    final ramGb = _cap?.ramGb ?? 0;
    final runtimeGb = spec.estimatedRuntimeMb / 1024;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.onDeviceModelMayCrashTitle),
            content: Text(
              l10n.onDeviceModelMayCrashMessage(
                spec.displayName,
                runtimeGb.toStringAsFixed(1),
                ramGb.toStringAsFixed(0),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.onDeviceContinueLoading),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onDownload(LocalModelSpec spec) async {
    if (_isFreeTierBlocked(spec)) {
      _openPaywall();
      return;
    }
    final verdict =
        _cap == null ? ModelFit.runs : _capability.verdict(spec, _cap);
    if (verdict == ModelFit.tight || verdict == ModelFit.blocked) {
      if (!await _confirmRiskyModel(spec)) return;
    }
    unawaited(_downloads.download(spec).catchError((error, stack) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $error')),
      );
    }));
  }

  Future<void> _confirmDelete(LocalModelSpec spec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${spec.displayName}?'),
        content: const Text(
          'The model file will be removed from this device. You can '
          'redownload it at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _downloads.delete(spec.id);
    }
  }

  void _openPaywall() {
    // No paywall in the public build: Pro-tier rows and Pro actions are not
    // offered there, so this is a backstop only.
    if (!ProFeatures.included) return;
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(
              highlight: PaywallFeature.onDeviceModels)),
    );
  }

  Future<void> _activate(LocalModelSpec spec) async {
    final verdict =
        _cap == null ? ModelFit.runs : _capability.verdict(spec, _cap);
    if (verdict == ModelFit.tight || verdict == ModelFit.blocked) {
      if (!await _confirmRiskyModel(spec)) return;
    }
    if (!mounted) return;
    if (Platform.isAndroid && spec.engine == LocalEngine.mlx) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MLX is not available on Android.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _activatingId = spec.id);
    try {
      final settingsProvider = context.read<SettingsProvider>();
      await OnDeviceLLMService.instance.unloadAll();
      if (!mounted) return;
      final kind =
          spec.engine == LocalEngine.mlx ? 'onDeviceMlx' : 'onDeviceGguf';
      final updated = settingsProvider.settings.copyWith(
        activeProviderKind: kind,
        selectedLocalModelId: spec.id,
        selectedModel: spec.displayName,
      );
      await settingsProvider.updateSettings(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).onDeviceNowUsing(spec.displayName)),
          duration: const Duration(seconds: 2),
        ),
      );

      // Warm the MLX runtime immediately so the first chat turn is instant and
      // any flaky cold-load surfaces here (with the built-in retry) instead of
      // mid-conversation — this is what used to force the "switch engines" dance.
      if (kind == 'onDeviceMlx') {
        await _warmLoadMlx(spec);
      }
    } finally {
      if (mounted) setState(() => _activatingId = null);
    }
  }

  Future<void> _warmLoadMlx(LocalModelSpec spec) async {
    try {
      await OnDeviceMlxEndpoint(spec).load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MLX model failed to load: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
