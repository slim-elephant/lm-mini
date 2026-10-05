import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/lm_studio_model.dart';
import '../models/pickable_model.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../services/ollama_model_catalog.dart';
import '../services/ollama_service.dart';
import '../widgets/home_glass_header.dart';
import '../widgets/huggingface_download_flow.dart';
import '../widgets/model_browser/lm_studio_adapter.dart';
import '../widgets/model_browser/model_browser_screen.dart';
import 'local_models_screen.dart';

class ModelManagementScreen extends StatefulWidget {
  final bool embedded;
  const ModelManagementScreen({super.key, this.embedded = false});

  @override
  State<ModelManagementScreen> createState() => _ModelManagementScreenState();
}

class _ModelManagementScreenState extends State<ModelManagementScreen> {
  String _filterId = 'all';
  bool _isUnloading = false;
  bool _didSilentRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didSilentRefresh) return;
      _didSilentRefresh = true;
      // Refresh from the active provider without blanking the list.
      context.read<SettingsProvider>().loadAvailableModels(silent: true);
    });
  }

  bool get _isCloudMode {
    if (!SubscriptionService().isPremium) return false;
    final cloud = CloudApiService();
    return cloud.isCloudActive && cloud.activeProvider != null;
  }

  CloudApiProvider? get _cloudProvider {
    if (!SubscriptionService().isPremium) return null;
    final cloud = CloudApiService();
    return cloud.isCloudActive ? cloud.activeProvider : null;
  }

  Future<void> _selectModel(
      String modelId, SettingsProvider settingsProvider) async {
    if (_isCloudMode) {
      final provider = _cloudProvider;
      if (provider != null) {
        CloudApiService().saveProvider(
          provider.copyWith(selectedModel: modelId),
        );
      }
    }
    settingsProvider.updateSelectedModel(modelId);
    // Keep the open chat's model override in sync so attach/send gates
    // match Model Management (chat overrides otherwise shadow the global pick).
    try {
      final chat = context.read<ChatProvider>();
      final conv = chat.currentConversation;
      if (conv != null && conv.settings.containsKey('model')) {
        final next = Map<String, dynamic>.from(conv.settings);
        next['model'] = modelId;
        await chat.updateChatSettings(next);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final kind = settingsProvider.settings.activeProviderKind;
    final isOllama = kind == 'ollama';
    final isUnsloth = kind == 'unsloth';
    final isOnDevice = kind == 'onDeviceGguf' || kind == 'onDeviceMlx';

    if (isOnDevice) {
      return ModelBrowserScreen(
        embedded: widget.embedded,
        title: l10n.modelManagement,
        models: const [],
        emptyState: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.smartphone,
                    size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(l10n.onDeviceManagedHere, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.onDeviceOpenBrowser),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const LocalModelsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selectedId = _isCloudMode
        ? (_cloudProvider?.selectedModel ??
            settingsProvider.settings.selectedModel)
        : settingsProvider.settings.selectedModel;

    final providerKind = _isCloudMode
        ? ModelProviderKind.cloud
        : (isOllama ? ModelProviderKind.ollama : ModelProviderKind.lmStudio);

    final loadingId = settingsProvider.loadingModelId;
    final models = settingsProvider.chatAvailableModels.map((m) {
      return mapLmStudioModel(
        model: m,
        selectedModelId: selectedId,
        isPinned: settingsProvider.isModelPinned(m.id),
        loadingModelId: loadingId,
        kind: providerKind,
      );
    }).toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        if (a.isLoaded != b.isLoaded) return a.isLoaded ? -1 : 1;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });

    final filters = <ModelBrowserFilter>[
      const ModelBrowserFilter(id: 'all', label: 'All'),
      if (!_isCloudMode && !isOllama && !isUnsloth) ...[
        const ModelBrowserFilter(id: 'ready', label: 'Ready'),
        const ModelBrowserFilter(id: 'downloaded', label: 'Downloaded'),
      ],
    ];

    final loadedModels =
        settingsProvider.chatAvailableModels.where((m) => m.isLoaded).toList();
    final selectedIsLoaded =
        selectedId != null && loadedModels.any((m) => m.id == selectedId);
    LMStudioModel? selectedModel;
    if (selectedId != null) {
      for (final m in settingsProvider.chatAvailableModels) {
        if (m.id == selectedId) {
          selectedModel = m;
          break;
        }
      }
    }
    final showLoadFab = (isUnsloth || (!_isCloudMode && !isOllama)) &&
        selectedModel != null &&
        !selectedIsLoaded &&
        loadingId == null;

    return ModelBrowserScreen(
      embedded: widget.embedded,
      title: l10n.modelManagement,
      // Keep the list visible while a specific model is loading so the card
      // progress bar can show (don't swap to a full-screen spinner).
      isLoading: settingsProvider.isLoadingModels &&
          loadingId == null &&
          models.isEmpty,
      models: models,
      filters: filters,
      selectedFilterId: _filterId,
      onFilterChanged: (id) => setState(() => _filterId = id),
      showDownloadFab: true,
      // Only show status when something is actually loaded (no empty/red card).
      headerExtra: ((isUnsloth || (!_isCloudMode && !isOllama)) &&
              loadedModels.isNotEmpty)
          ? _LoadedSelectionStatus(loaded: loadedModels)
          : null,
      bottomAction: showLoadFab
          ? FilledButton.icon(
              onPressed: () {
                final model = selectedModel;
                if (model == null) return;
                _showLoadModelDialog(context, model, settingsProvider);
              },
              icon: const Icon(Icons.rocket_launch_rounded, size: 20),
              label: const Text('Load Model'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                elevation: 4,
                shadowColor: Colors.black26,
              ),
            )
          : null,
      actions: [
        if (!_isCloudMode || isOllama)
          GlassCircleIconButton(
            tooltip: isOllama ? 'Pull Ollama model' : l10n.downloadNewModel,
            onTap: () => isOllama
                ? _showOllamaPullDialog(context)
                : _showDownloadDialog(context),
            child: const Icon(Icons.download_rounded,
                size: 22, color: Colors.white),
          ),
        GlassCircleIconButton(
          tooltip: l10n.refreshModels,
          onTap: () => settingsProvider.loadAvailableModels(),
          child: const Icon(Icons.refresh, size: 22, color: Colors.white),
        ),
      ],
      emptyState: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOllama ? Icons.download_outlined : Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                isOllama
                    ? 'No models available on Ollama'
                    : 'No models available',
                textAlign: TextAlign.center,
              ),
              if (isOllama) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Pull a model'),
                  onPressed: () => _showOllamaPullDialog(context),
                ),
              ],
            ],
          ),
        ),
      ),
      onSelect: (m) => _selectModel(m.id, settingsProvider),
      trailingBuilder: (context, m) {
        if ((_isCloudMode && !isUnsloth) || isOllama) {
          return const SizedBox.shrink();
        }
        final source = m.source;
        if (source is! LMStudioModel) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (source.isLoaded)
              IconButton(
                tooltip: l10n.unload,
                icon: Icon(
                  Icons.eject_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: _isUnloading
                    ? null
                    : () => _unloadModel(context, source, settingsProvider),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (action) async {
                switch (action) {
                  case 'load':
                    await _showLoadModelDialog(
                        context, source, settingsProvider);
                  case 'unload':
                    await _unloadModel(context, source, settingsProvider);
                  case 'pin':
                    settingsProvider.togglePinnedModel(source.id);
                }
              },
              itemBuilder: (ctx) => [
                if (!source.isLoaded)
                  const PopupMenuItem(value: 'load', child: Text('Load')),
                if (source.isLoaded)
                  PopupMenuItem(
                    value: 'unload',
                    enabled: !_isUnloading,
                    child: Text(l10n.unload),
                  ),
                PopupMenuItem(
                  value: 'pin',
                  child: Text(m.isPinned ? 'Unpin' : 'Pin'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDownloadDialog(BuildContext context) async {
    await HuggingFaceDownloadFlow.show(
      context: context,
      target: HuggingFaceDownloadTarget.lmStudio,
      onDownload: _handleHfDownloadSelection,
    );
  }

  Future<void> _showOllamaPullDialog(BuildContext context) async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final cloud = settingsProvider.resolveCloudProvider();
    if (cloud == null || cloud.effectiveBaseUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure an Ollama server URL in Settings first.'),
        ),
      );
      return;
    }

    final modelName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _OllamaCatalogSheet(),
    );

    if (modelName == null || modelName.isEmpty || !mounted) return;
    await _runOllamaPull(cloud, modelName);
  }

  Future<void> _runOllamaPull(CloudApiProvider cloud, String modelName) async {
    final result = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OllamaPullProgressDialog(
        modelName: modelName,
        baseUrl: cloud.effectiveBaseUrl,
        apiToken: cloud.apiKey,
      ),
    );

    if (!mounted) return;
    if (result is String) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (result != true) return;

    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.loadAvailableModels();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pulled $modelName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleHfDownloadSelection(
      HuggingFaceDownloadSelection selection) async {
    final l10n = AppLocalizations.of(context);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    final modelId =
        selection.isPlainModelId ? selection.repo : selection.repoUrl;
    final quant = selection.isPlainModelId
        ? null
        : (selection.file.quantization.isEmpty
            ? null
            : selection.file.quantization);
    final label = selection.isPlainModelId
        ? selection.repo
        : quant != null
            ? '${selection.repo.split('/').last} · $quant'
            : selection.repo.split('/').last;

    final result = await settingsProvider.downloadModel(
      modelId,
      quantization: quant,
      displayLabel: label,
    );

    if (result['status'] == 'already_downloaded' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.modelAlreadyDownloaded)),
      );
    }
  }

  Future<void> _showLoadModelDialog(
    BuildContext context,
    LMStudioModel model,
    SettingsProvider settingsProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final others = settingsProvider.availableModels
        .where((m) => m.isLoaded && m.id != model.id)
        .toList();

    // Single choice — picking an option starts the load (no second confirm).
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _LoadModelSheet(
        modelName: model.displayName,
        loadedNames: others.map((m) => m.displayName).toList(),
      ),
    );

    if (action == null || !context.mounted) return;

    if (action == 'swap') {
      for (final m in others) {
        await settingsProvider.unloadSpecificModel(m.id);
      }
    }

    if (!context.mounted) return;
    final success = await settingsProvider.loadSpecificModel(
      model.id,
      uiContext: context,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.modelLoadedSuccess : l10n.failedToLoadModel,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _unloadModel(
    BuildContext context,
    LMStudioModel model,
    SettingsProvider settingsProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.eject,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(l10n.unloadModelTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.unloadModelConfirm(model.displayName),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.freeResourcesTip,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.unload),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isUnloading = true);
      final success = await settingsProvider.unloadSpecificModel(model.id);
      if (!mounted) return;
      setState(() => _isUnloading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.modelUnloadedSuccess : l10n.failedToUnloadModel,
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// One-step load chooser: Load / Swap / Keep both — no second confirm.
class _LoadModelSheet extends StatelessWidget {
  final String modelName;
  final List<String> loadedNames;

  const _LoadModelSheet({
    required this.modelName,
    required this.loadedNames,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasOthers = loadedNames.isNotEmpty;
    final loadedLabel = loadedNames.length == 1
        ? loadedNames.first
        : '${loadedNames.length} models';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasOthers ? 'Switch models?' : 'Load this model?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasOthers
                  ? '$loadedLabel is already running. What should we do with “$modelName”?'
                  : 'Ready to start “$modelName” so you can chat with it.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasOthers)
              _LoadChoiceTile(
                icon: Icons.rocket_launch_rounded,
                title: 'Load model',
                subtitle: 'Start it now',
                emphasized: true,
                onTap: () => Navigator.pop(context, 'load'),
              )
            else ...[
              _LoadChoiceTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Swap',
                subtitle: 'Stop the current model, then load this one',
                emphasized: true,
                onTap: () => Navigator.pop(context, 'swap'),
              ),
              const SizedBox(height: 8),
              _LoadChoiceTile(
                icon: Icons.layers_outlined,
                title: 'Keep both',
                subtitle: 'Load this one too (uses more memory)',
                onTap: () => Navigator.pop(context, 'parallel'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  const _LoadChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: emphasized
          ? cs.primaryContainer.withValues(alpha: 0.55)
          : cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: emphasized
                      ? cs.primary.withValues(alpha: 0.18)
                      : cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: emphasized ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
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

/// Compact strip listing models currently loaded in LM Studio.
class _LoadedSelectionStatus extends StatelessWidget {
  final List<LMStudioModel> loaded;

  const _LoadedSelectionStatus({required this.loaded});

  @override
  Widget build(BuildContext context) {
    if (loaded.isEmpty) return const SizedBox.shrink();

    final loadedNames = loaded.map((m) => m.displayName).join(', ');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clear green “ready” signal (theme tertiary is often brown/maroon).
    const green = Color(0xFF2E7D4F);
    final greenFill = const Color(0xFF1B4332).withValues(alpha: 0.55);
    final greenBorder = green.withValues(alpha: 0.55);
    const greenFg = Color(0xFFB7F0C8);
    final fg = isDark ? greenFg : green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? greenFill : green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? greenBorder : green.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.memory_rounded, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loaded.length == 1
                  ? 'Loaded: $loadedNames'
                  : 'Loaded (${loaded.length}): $loadedNames',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OllamaPullProgressDialog extends StatefulWidget {
  final String modelName;
  final String? baseUrl;
  final String apiToken;

  const _OllamaPullProgressDialog({
    required this.modelName,
    required this.baseUrl,
    required this.apiToken,
  });

  @override
  State<_OllamaPullProgressDialog> createState() =>
      _OllamaPullProgressDialogState();
}

class _OllamaPullProgressDialogState extends State<_OllamaPullProgressDialog> {
  double? _progress;
  String _status = 'Starting…';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    final base = (widget.baseUrl ?? '').trim();
    if (base.isEmpty) {
      if (mounted) Navigator.of(context).pop('Ollama server URL is missing.');
      return;
    }
    try {
      await OllamaService.instance.pullModel(
        baseUrl: base,
        model: widget.modelName,
        apiToken: widget.apiToken.isEmpty ? null : widget.apiToken,
        onProgress: (progress, status) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            _status = status;
          });
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pulling ${widget.modelName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_progress == null)
            const LinearProgressIndicator()
          else
            LinearProgressIndicator(value: _progress),
          const SizedBox(height: 12),
          Text(_status, style: Theme.of(context).textTheme.bodyMedium),
          if (_progress != null) ...[
            const SizedBox(height: 4),
            Text(
              '${(_progress! * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _OllamaCatalogSheet extends StatefulWidget {
  const _OllamaCatalogSheet();

  @override
  State<_OllamaCatalogSheet> createState() => _OllamaCatalogSheetState();
}

class _OllamaCatalogSheetState extends State<_OllamaCatalogSheet> {
  final _customController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  List<OllamaCatalogEntry> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return List<OllamaCatalogEntry>.from(OllamaModelCatalog.entries);
    }
    return OllamaModelCatalog.entries
        .where((e) =>
            e.id.contains(q) ||
            e.displayName.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.category.contains(q))
        .toList();
  }

  Future<void> _openLibrary() async {
    final uri = Uri.parse('https://ollama.com/library');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _submitCustom() {
    final t = _customController.text.trim();
    if (t.isNotEmpty) Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _visible;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pull Ollama model',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Models download on the computer running Ollama. '
                      'Enter any library name, or pick a popular model below.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'e.g. gemma4:e4b or qwen3.6:4b',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submitCustom(),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _submitCustom,
                      child: const Text('Pull custom'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _openLibrary,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Browse ollama.com/library'),
                      ),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search catalog…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final e = visible[index];
                    return ModelRowLikeOllama(entry: e);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact Ollama catalog row matching the browser language.
class ModelRowLikeOllama extends StatelessWidget {
  final OllamaCatalogEntry entry;

  const ModelRowLikeOllama({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerLow.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(context, entry.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (entry.category == 'reasoning')
                            _chip(
                              context,
                              'Reasoning',
                              color: const Color(0xFFB39DDB),
                            ),
                          if (entry.category == 'vision')
                            _chip(
                              context,
                              'Images',
                              color: const Color(0xFF64B5F6),
                            ),
                          if (entry.sizeLabel.isNotEmpty)
                            _chip(context, entry.sizeLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.download_rounded, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c != null
            ? c.withValues(alpha: isDark ? 0.18 : 0.14)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: c != null
            ? Border.all(color: c.withValues(alpha: isDark ? 0.42 : 0.38))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c != null
              ? (isDark
                  ? Color.lerp(c, Colors.white, 0.35)!
                  : Color.lerp(c, Colors.black, 0.25)!)
              : null,
        ),
      ),
    );
  }
}
