import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../desktop/desktop_platform.dart';
import '../l10n/app_localizations.dart';
import '../models/local_model_spec.dart';
import '../models/pickable_model.dart';
import '../pro/pro_features.dart';
import '../providers/settings_provider.dart';
import '../services/device_capability_service.dart';
import '../services/local_model_catalog.dart';
import '../services/local_model_download_service.dart';
import '../services/on_device_llm_service.dart';
import '../services/on_device_mlx_endpoint.dart';
import '../widgets/home_glass_header.dart';
import '../widgets/huggingface_download_flow.dart';
import '../widgets/model_browser/model_browser_screen.dart';
import '../widgets/model_browser/on_device_adapter.dart';
import 'subscription_screen.dart';

enum _ImportKind { gguf, mlx }

/// On-device model catalog browser (Settings entry).
class LocalModelsScreen extends StatefulWidget {
  final bool embedded;
  const LocalModelsScreen({super.key, this.embedded = false});

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
  bool _groupModels = false;
  bool _showSmallModels = false;
  String? _activatingId;
  /// Catalog model focused for the Download FAB (not yet on device).
  LocalModelSpec? _pendingDownload;

  @override
  void dispose() {
    _downloads.removeListener(_refreshStorage);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _downloads.addListener(_refreshStorage);
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
  }

  bool _isFreeTierBlocked(LocalModelSpec spec) {
    if (ProFeatures.isPro) return false;
    return !spec.isFreeSlot;
  }

  /// Free-tier lock that may be shown as an upgrade prompt. The public build
  /// never shows one (and never lists Pro-tier rows, see [_listedInBuild]).
  bool _isUpsellBlocked(LocalModelSpec spec) =>
      ProFeatures.showUpsell && _isFreeTierBlocked(spec);

  /// The public build lists only the free-slot catalog models and the user's
  /// own imports; Pro-tier rows exist only where Pro can be bought.
  bool _listedInBuild(LocalModelSpec spec) =>
      ProFeatures.included || spec.isFreeSlot || spec.isImported;

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
        final recommendedIds = <String>{
          if (desktop && vramPick != null)
            vramPick.id
          else if (_cap != null)
            ...LocalModelCatalog.recommendationsFor(_cap!, limit: 3)
                .map((e) => e.id),
        };
        final best = _cap == null
            ? null
            : (desktop
                ? (vramPick ?? LocalModelCatalog.bestFor(_cap!))
                : LocalModelCatalog.bestFor(_cap!));

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
              final aRec = models
                  .any((m) => m.familyGroup == a.key && m.isRecommended);
              final bRec = models
                  .any((m) => m.familyGroup == b.key && m.isRecommended);
              if (aRec != bRec) return aRec ? -1 : 1;
              return b.value.compareTo(a.value);
            });
          lineOrder.addAll(ranked.map((e) => e.key));
        }

        return ModelBrowserScreen(
          embedded: widget.embedded,
          title: 'On-Device Models',
          isLoading: _initializing,
          models: models,
          showDownloadFab: true,
          centeredList: desktop,
          groupByFamily: desktop || _groupModels,
          familyOrder:
              desktop ? lineOrder : LocalModelCatalog.familyOrder,
          filters: const [
            ModelBrowserFilter(id: 'all', label: 'All'),
            ModelBrowserFilter(id: 'downloaded', label: 'Downloaded'),
          ],
          selectedFilterId: _filterId,
          onFilterChanged: (id) => setState(() => _filterId = id),
          filtersTrailing: desktop
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
                        child:
                            Icon(Icons.star, size: 14, color: Colors.amber),
                      ),
                  ],
                ),
              ),
          ],
          headerExtra: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (best != null && passEngine(best)) ...[
                _BestForYouCard(
                  spec: best,
                  cap: _cap!,
                  vramTarget: desktop,
                  onTap: () {
                    final entry = _downloads.entryById(best.id);
                    final status =
                        entry?.status ?? LocalModelStatus.notDownloaded;
                    if (status == LocalModelStatus.ready) {
                      _activate(best);
                    } else {
                      setState(() => _pendingDownload = best);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
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
              items.add(
                  const PopupMenuItem(value: 'use', child: Text('Use')));
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
              items.add(const PopupMenuItem(
                  value: 'cancel', child: Text('Cancel')));
            }
            if (status == LocalModelStatus.ready ||
                status == LocalModelStatus.failed) {
              items.add(const PopupMenuItem(
                  value: 'delete', child: Text('Delete')));
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
    if (mlxSupported && ProFeatures.isPro) {
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
      final upgrade = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import limit reached'),
          content: Text(
            showUpsell
                ? 'Free plan includes one imported model. Upgrade to '
                    'LM Mini Pro to import unlimited GGUF and MLX models '
                    'from Files.'
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
                    child: const Text('Upgrade'),
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

  Future<void> _importMlxFromDirectory() async {
    if (!ProFeatures.isPro) {
      _openPaywall();
      return;
    }
    if (!await _ensureImportAllowed()) return;

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

  Future<void> _showAddCustomDialog() async {
    if (!ProFeatures.isPro) {
      _openPaywall();
      return;
    }

    await HuggingFaceDownloadFlow.show(
      context: context,
      target: HuggingFaceDownloadTarget.onDevice,
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
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
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

class _BestForYouCard extends StatelessWidget {
  final LocalModelSpec spec;
  final DeviceCapability cap;
  final VoidCallback onTap;
  final bool vramTarget;

  const _BestForYouCard({
    required this.spec,
    required this.cap,
    required this.onTap,
    this.vramTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final engine = spec.engine == LocalEngine.mlx
        ? 'MLX'
        : spec.engine == LocalEngine.moeStream
            ? 'Stream'
            : 'GGUF';
    final why = vramTarget
        ? 'Recommended · ~70% of ${cap.ramGb.round()} GB unified memory'
        : [
            if (cap.supportsMlx && spec.engine == LocalEngine.mlx) 'MLX',
            if (cap.supportsVulkan && spec.engine == LocalEngine.fllama)
              'Vulkan',
            '${cap.ramGb.toStringAsFixed(0)} GB RAM',
          ].join(' · ');

    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best for this device',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${spec.displayName} · $engine',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      why,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
