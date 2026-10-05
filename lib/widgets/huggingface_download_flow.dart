import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/huggingface_hub_service.dart';
import '../utils/layout_utils.dart';
import '../utils/localhost_connection_error.dart';
import 'compact_error_banner.dart';

bool _looksLikeUnreachable(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('connection refused') ||
      s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('timed out') ||
      s.contains('timeout') ||
      s.contains('connection reset') ||
      s.contains('os error') ||
      s.contains('errno = 61') ||
      s.contains('errno = 111');
}

/// Where a Hugging Face download will be routed after the user picks a quant.
enum HuggingFaceDownloadTarget {
  onDevice,
  lmStudio,
}

/// Result of the full browse → quant selection flow.
class HuggingFaceDownloadSelection {
  final String repo;
  final HfGgufFile file;
  final HuggingFaceDownloadTarget target;
  final bool isPlainModelId;

  const HuggingFaceDownloadSelection({
    required this.repo,
    required this.file,
    required this.target,
    this.isPlainModelId = false,
  });

  String get repoUrl => HuggingFaceHubService.instance.repoUrl(repo);

  String get onDeviceRef =>
      HuggingFaceHubService.instance.downloadRef(repo, file);
}

/// Shared Hugging Face browse + quantization UI for on-device and LM Studio.
class HuggingFaceDownloadFlow {
  HuggingFaceDownloadFlow._();

  /// Shows the browser and keeps it open while downloads run in the background.
  static Future<void> show({
    required BuildContext context,
    required HuggingFaceDownloadTarget target,
    required Future<void> Function(HuggingFaceDownloadSelection selection)
        onDownload,
  }) {
    final isTablet = isTabletClassLayout(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => _HuggingFaceDownloadSheet(
        target: target,
        allowPlainModelId: target == HuggingFaceDownloadTarget.lmStudio,
        onDownload: onDownload,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        if (isTablet) {
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
              child: child,
            ),
          );
        }
        return SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

class _HuggingFaceDownloadSheet extends StatefulWidget {
  final HuggingFaceDownloadTarget target;
  final bool allowPlainModelId;
  final Future<void> Function(HuggingFaceDownloadSelection selection)
      onDownload;

  const _HuggingFaceDownloadSheet({
    required this.target,
    required this.allowPlainModelId,
    required this.onDownload,
  });

  @override
  State<_HuggingFaceDownloadSheet> createState() =>
      _HuggingFaceDownloadSheetState();
}

class _HuggingFaceDownloadSheetState extends State<_HuggingFaceDownloadSheet>
    with SingleTickerProviderStateMixin {
  final _hub = HuggingFaceHubService.instance;
  final _searchController = TextEditingController();
  final _pasteController = TextEditingController();
  late final TabController _tabs;

  Timer? _debounce;
  List<HfModelSummary> _models = [];
  List<HfModelSummary> _rawModels = [];
  bool _loading = true;
  String? _error;
  bool _lmStudioOnly = false;
  bool _chatOnly = true;
  String _lastQuery = '';

  /// When set, the quant picker replaces the browse UI (same dialog, back arrow).
  String? _quantRepo;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadModels('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _searchController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadModels(_searchController.text.trim());
    });
  }

  Future<void> _loadModels(String query) async {
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final results = await _hub.searchModels(
        query: query,
        lmStudioOnly: _lmStudioOnly,
      );
      if (!mounted || _lastQuery != query) return;
      setState(() {
        _rawModels = results;
        _models = _applyFilters(results);
        _loading = false;
      });
    } catch (e) {
      if (!mounted || _lastQuery != query) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<HfModelSummary> _applyFilters(List<HfModelSummary> raw) {
    if (!_chatOnly) return raw;
    return raw.where((m) => m.isTextGeneration).toList();
  }

  void _openQuantPicker(String repo) => setState(() => _quantRepo = repo);

  void _backToBrowse() => setState(() => _quantRepo = null);

  Future<void> _startDownload(HuggingFaceDownloadSelection selection) async {
    final l10n = AppLocalizations.of(context);
    try {
      await widget.onDownload(selection);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.hfDownloadInBackground),
          duration: const Duration(seconds: 3),
        ),
      );
      _backToBrowse();
    } catch (e) {
      if (!mounted) return;
      final details = e.toString();
      final localhost = LocalhostConnectionError.matches(e);
      final lmStudio = widget.target == HuggingFaceDownloadTarget.lmStudio;
      final message = localhost
          ? l10n.localhostConnectionHelp
          : (lmStudio && _looksLikeUnreachable(e)
              ? l10n.checkLmStudioRunning
              : l10n.couldNotStartDownload);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: localhost ? 8 : 6),
          action: localhost
              ? null
              : SnackBarAction(
                  label: l10n.showDetails,
                  onPressed: () {
                    if (!context.mounted) return;
                    CompactErrorBanner.showDetailsDialog(
                      context,
                      fullText: details,
                    );
                  },
                ),
        ),
      );
    }
  }

  void _submitPaste() {
    final raw = _pasteController.text.trim();
    if (raw.isEmpty) return;

    if (widget.allowPlainModelId && !_looksLikeHf(raw)) {
      _startDownload(HuggingFaceDownloadSelection(
        repo: raw,
        file: const HfGgufFile(
          path: '',
          size: 0,
          quantization: '',
          filename: '',
        ),
        target: widget.target,
        isPlainModelId: true,
      ));
      return;
    }

    try {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.host.contains('huggingface.co')) {
        final segs = uri.pathSegments;
        if (segs.length >= 2) {
          _openQuantPicker('${segs[0]}/${segs[1]}');
          return;
        }
      }
      if (raw.contains('/')) {
        final parts = raw.split('/');
        if (parts.length >= 2 && !parts[0].contains('.')) {
          _openQuantPicker('${parts[0]}/${parts[1]}');
          return;
        }
      }
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).hfInvalidRepo)),
    );
  }

  bool _looksLikeHf(String raw) {
    if (raw.contains('huggingface.co')) return true;
    final parts = raw.split('/');
    return parts.length >= 2 && !parts[0].contains('.');
  }

  Future<void> _showModelInfo(HfModelSummary model) async {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        builder: (_, scroll) => FutureBuilder<HfModelDetails>(
          future: _hub.fetchModelDetails(model.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.fetchQuantizationsFailed(
                    snapshot.error?.toString() ?? l10n.error)),
              );
            }
            final d = snapshot.data!;
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  model.shortName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  d.id,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.download_outlined,
                      label: l10n.hfDownloadsCount(
                        HuggingFaceHubService.formatDownloads(d.downloads),
                      ),
                    ),
                    _InfoChip(
                      icon: Icons.favorite_border,
                      label: l10n.hfLikesCount('${d.likes}'),
                    ),
                    if (d.pipelineTag != null)
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: l10n.hfPipelineTag(d.pipelineTag!),
                      ),
                    if (d.isLmStudioTagged)
                      _InfoChip(
                        icon: Icons.computer,
                        label: l10n.hfLmStudioBadge,
                      ),
                  ],
                ),
                if (d.baseModel != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.hfBaseModel(d.baseModel!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (d.license != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.hfLicense(d.license!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (d.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.hfTagsSection,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: d.tags.take(12).map((t) {
                      return Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = isTabletClassLayout(context);
    final size = MediaQuery.sizeOf(context);
    final maxW = isTablet ? 680.0 : size.width;
    final maxH = isTablet ? size.height * 0.84 : size.height * 0.92;
    final topBg = isDark ? const Color(0xFF1A202E) : const Color(0xFF243044);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 10,
            vertical: isTablet ? 20 : 6,
          ),
          child: Material(
            color: topBg,
            elevation: isTablet ? 14 : 0,
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _quantRepo != null
                            ? _QuantPickerPage(
                                key: ValueKey('quant-$_quantRepo'),
                                repo: _quantRepo!,
                                target: widget.target,
                                onBack: _backToBrowse,
                                onSelect: (file) =>
                                    _startDownload(HuggingFaceDownloadSelection(
                                  repo: _quantRepo!,
                                  file: file,
                                  target: widget.target,
                                )),
                                onClose: () => Navigator.pop(context),
                              )
                            : Column(
                                key: const ValueKey('browse'),
                                children: [
                                  _SheetHeader(
                                    title: l10n.hfBrowseTitle,
                                    subtitle: l10n.hfBrowseSubtitle,
                                    onClose: () => Navigator.pop(context),
                                  ),
                                  TabBar(
                                    controller: _tabs,
                                    tabs: [
                                      Tab(
                                        icon: const Icon(Icons.explore_outlined,
                                            size: 18),
                                        text: l10n.hfBrowseTab,
                                      ),
                                      Tab(
                                        icon: const Icon(Icons.link, size: 18),
                                        text: l10n.hfPasteTab,
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabs,
                                      children: [
                                        _buildBrowseTab(l10n, cs),
                                        _buildPasteTab(l10n, cs),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseTab(AppLocalizations l10n, ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.hfSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: Text(l10n.hfLmStudioFilter),
                    selected: _lmStudioOnly,
                    onSelected: (v) {
                      setState(() => _lmStudioOnly = v);
                      _loadModels(_searchController.text.trim());
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  FilterChip(
                    label: Text(l10n.hfChatModelsFilter),
                    selected: _chatOnly,
                    onSelected: (v) {
                      setState(() {
                        _chatOnly = v;
                        _models = _applyFilters(_rawModels);
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    tooltip: l10n.hfLmStudioFilterHint,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.hfLmStudioFilter),
                          content: Text(l10n.hfLmStudioFilterHint),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l10n.close),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (_lmStudioOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4),
                  child: Text(
                    l10n.hfLmStudioFilterHint,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _buildModelList(l10n, cs)),
      ],
    );
  }

  Widget _buildModelList(AppLocalizations l10n, ColorScheme cs) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.hfLoadingModels,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }
    if (_error != null) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.error,
        subtitle: _error!,
        actionLabel: l10n.retry,
        onAction: () => _loadModels(_searchController.text.trim()),
      );
    }
    if (_models.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off,
        title: l10n.hfNoModelsFound,
        subtitle: l10n.hfNoModelsHint,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadModels(_searchController.text.trim()),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: _models.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) {
          final m = _models[i];
          return _CompactModelTile(
            model: m,
            onTap: () => _openQuantPicker(m.id),
            onInfo: () => _showModelInfo(m),
          );
        },
      ),
    );
  }

  Widget _buildPasteTab(AppLocalizations l10n, ColorScheme cs) {
    final hint = widget.allowPlainModelId
        ? l10n.hfPasteInstructionsLmStudio
        : l10n.hfPasteInstructions;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(hint,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: cs.onSurfaceVariant,
              )),
          const SizedBox(height: 14),
          TextField(
            controller: _pasteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n.hfPasteUrlHint,
              labelText: l10n.hfPasteLabel,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _submitPaste(),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _submitPaste,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(l10n.continueAction),
          ),
        ],
      ),
    );
  }
}

// ── Quant picker (same dialog, back navigation) ────────────────────────────

class _QuantPickerPage extends StatefulWidget {
  final String repo;
  final HuggingFaceDownloadTarget target;
  final VoidCallback onBack;
  final Future<void> Function(HfGgufFile file) onSelect;
  final VoidCallback onClose;

  const _QuantPickerPage({
    super.key,
    required this.repo,
    required this.target,
    required this.onBack,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<_QuantPickerPage> createState() => _QuantPickerPageState();
}

class _QuantPickerPageState extends State<_QuantPickerPage> {
  late Future<List<HfGgufFile>> _filesFuture;
  String? _busyFileKey;

  @override
  void initState() {
    super.initState();
    _filesFuture = _loadFiles();
  }

  void _retry() {
    setState(() {
      _busyFileKey = null;
      _filesFuture = _loadFiles();
    });
  }

  String _fileKey(HfGgufFile f) =>
      f.path.isNotEmpty ? f.path : '${f.quantization}|${f.filename}';

  Future<void> _onSelect(HfGgufFile file) async {
    if (_busyFileKey != null) return;
    setState(() => _busyFileKey = _fileKey(file));
    try {
      await widget.onSelect(file);
    } finally {
      if (mounted) setState(() => _busyFileKey = null);
    }
  }

  Future<List<HfGgufFile>> _loadFiles() async {
    if (widget.target == HuggingFaceDownloadTarget.lmStudio) {
      final settings = context.read<SettingsProvider>();
      final quants = await settings.getLmStudioHfQuantizations(widget.repo);
      if (quants.isEmpty) {
        // Single-quant repo — LM Studio does not require a picker.
        return const [
          HfGgufFile(
            path: '',
            size: 0,
            quantization: '',
            filename: '',
          ),
        ];
      }
      return HuggingFaceHubService.instance
          .ggufFilesForLmStudioQuants(widget.repo, quants);
    }
    return HuggingFaceHubService.instance.listGgufFiles(widget.repo);
  }

  bool _isRecommended(HfGgufFile f) {
    final q = f.quantization.toUpperCase();
    return q.contains('Q4_K_M');
  }

  /// Plain-English quality tier; technical quant stays secondary.
  static String plainQuantLabel(String quantization) {
    final q = quantization.toUpperCase();
    if (q.contains('Q2') || q.contains('IQ2') || q.contains('Q3')) {
      return 'Smaller · faster';
    }
    if (q.contains('Q4') || q.contains('IQ4')) {
      return 'Balanced';
    }
    if (q.contains('Q5') ||
        q.contains('Q6') ||
        q.contains('Q8') ||
        q.contains('F16') ||
        q.contains('BF16') ||
        q.contains('FP16')) {
      return 'Higher quality';
    }
    return 'Download';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        _SheetHeader(
          title: l10n.selectQuantization,
          subtitle: widget.repo,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.hfBackToModels,
            onPressed: widget.onBack,
          ),
          onClose: widget.onClose,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            widget.target == HuggingFaceDownloadTarget.lmStudio
                ? l10n.hfQuantPickerHintLmStudio
                : l10n.hfQuantPickerHint,
            style: TextStyle(
                fontSize: 12, color: cs.onSurfaceVariant, height: 1.35),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<HfGgufFile>>(
            future: _filesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.loadingQuantizations),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return _FriendlyErrorState(
                  error: snapshot.error!,
                  lmStudioTarget:
                      widget.target == HuggingFaceDownloadTarget.lmStudio,
                  onBack: widget.onBack,
                  onRetry: _retry,
                );
              }
              final files = snapshot.data ?? [];
              if (files.isEmpty) {
                return _EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: l10n.noQuantizations,
                  subtitle: l10n.noGgufFiles,
                  actionLabel: l10n.hfBackToModels,
                  onAction: widget.onBack,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.hfGgufFilesCount(files.length),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final f = files[i];
                        final isDefaultOnly = f.quantization.isEmpty;
                        return _CompactQuantTile(
                          file: f,
                          recommended: !isDefaultOnly && _isRecommended(f),
                          labelOverride: isDefaultOnly
                              ? l10n.hfDownloadDefaultQuant
                              : null,
                          busy: _busyFileKey == _fileKey(f),
                          enabled: _busyFileKey == null,
                          onTap: () => _onSelect(f),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget? leading;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 4, 8),
      child: Row(
        children: [
          leading ?? const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontFamily: subtitle.contains('/') ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: AppLocalizations.of(context).close,
          ),
        ],
      ),
    );
  }
}

class _CompactModelTile extends StatelessWidget {
  final HfModelSummary model;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  const _CompactModelTile({
    required this.model,
    required this.onTap,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLow.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      model.owner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SoftMetaChip(
                          label: l10n.hfDownloadsCount(
                            HuggingFaceHubService.formatDownloads(
                                model.downloads),
                          ),
                        ),
                        if (model.isTextGeneration)
                          _SoftMetaChip(label: l10n.hfChatBadge),
                        if (model.isLmStudioTagged)
                          const _SoftMetaChip(label: 'GGUF'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline,
                    size: 20, color: cs.onSurfaceVariant),
                tooltip: l10n.hfModelInfo,
                visualDensity: VisualDensity.compact,
                onPressed: onInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactQuantTile extends StatelessWidget {
  final HfGgufFile file;
  final bool recommended;
  final String? labelOverride;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  const _CompactQuantTile({
    required this.file,
    required this.recommended,
    this.labelOverride,
    this.busy = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDefaultOnly = file.quantization.isEmpty;
    final plain = labelOverride ??
        _QuantPickerPageState.plainQuantLabel(file.quantization);
    final sizeLabel =
        file.size > 0 ? HuggingFaceHubService.formatBytes(file.size) : null;

    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: Material(
        color: recommended
            ? cs.primaryContainer.withValues(alpha: 0.32)
            : cs.surfaceContainerLow.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (!enabled || busy) ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plain,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isDefaultOnly
                            ? (sizeLabel ?? 'Default file')
                            : [
                                if (file.quantization.isNotEmpty)
                                  file.quantization,
                                if (sizeLabel != null) sizeLabel,
                              ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(height: 8),
                        _SoftMetaChip(label: l10n.hfRecommended),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: busy
                      ? CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: cs.primary,
                        )
                      : Icon(Icons.download_rounded,
                          color: cs.primary, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftMetaChip extends StatelessWidget {
  final String label;

  const _SoftMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FriendlyErrorState extends StatefulWidget {
  final Object error;
  final bool lmStudioTarget;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _FriendlyErrorState({
    required this.error,
    required this.lmStudioTarget,
    required this.onBack,
    required this.onRetry,
  });

  @override
  State<_FriendlyErrorState> createState() => _FriendlyErrorStateState();
}

class _FriendlyErrorStateState extends State<_FriendlyErrorState> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final raw = widget.error.toString();
    final localhost = LocalhostConnectionError.matches(raw);
    final unreachable = _looksLikeUnreachable(raw);
    final title = localhost
        ? l10n.localhostConnectionHelp
        : (widget.lmStudioTarget && unreachable
            ? l10n.checkLmStudioRunning
            : l10n.couldNotLoadQuantizations);
    final subtitle = localhost
        ? null
        : (widget.lmStudioTarget && unreachable
            ? l10n.couldNotReachLmStudio
            : null);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              child: Text(_showDetails ? l10n.hideDetails : l10n.showDetails),
            ),
            if (_showDetails) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: SelectableText(
                    raw,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      fontFamily: 'monospace',
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(onPressed: widget.onRetry, child: Text(l10n.retry)),
            TextButton(
              onPressed: widget.onBack,
              child: Text(l10n.hfBackToModels),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: cs.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
