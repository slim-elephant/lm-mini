import 'package:flutter/material.dart';

import '../../models/pickable_model.dart';
import '../../utils/layout_utils.dart';
import '../glass_page_header.dart';
import '../glass_settings_scaffold.dart';
import '../global_download_fab.dart';
import 'model_catalog_card.dart';
import 'model_details_sheet.dart';
import 'model_row.dart';
import '../glass_blur.dart';

class ModelBrowserFilter {
  final String id;
  final String label;

  const ModelBrowserFilter({required this.id, required this.label});
}

/// Glass Settings shell: header, search, light filters, balanced model rows.
class ModelBrowserScreen extends StatefulWidget {
  final String title;
  final List<Widget> actions;
  final bool isLoading;
  final Widget? emptyState;
  final List<PickableModel> models;
  final String searchHint;
  final List<ModelBrowserFilter> filters;
  final String selectedFilterId;
  final ValueChanged<String>? onFilterChanged;

  /// Widget shown beside the filter chips (e.g. Group models checkbox).
  final Widget? filtersTrailing;
  final Widget? headerExtra;
  final ValueChanged<PickableModel>? onSelect;
  final ValueChanged<PickableModel>? onInfo;
  final Widget Function(BuildContext, PickableModel)? trailingBuilder;
  final bool showDownloadFab;
  final Widget? footer;

  /// Centered bottom action (e.g. Load Model FAB).
  final Widget? bottomAction;

  /// When true, list expands by [PickableModel.familyGroup].
  final bool groupByFamily;
  final List<String> familyOrder;

  /// Desktop on-device catalog: centered column, never the phone card grid.
  final bool centeredList;

  /// When true, omit glass header / navy wash (Settings right pane).
  final bool embedded;

  const ModelBrowserScreen({
    super.key,
    required this.title,
    this.actions = const [],
    this.isLoading = false,
    this.emptyState,
    required this.models,
    this.searchHint = 'Search models…',
    this.filters = const [],
    this.selectedFilterId = 'all',
    this.onFilterChanged,
    this.filtersTrailing,
    this.headerExtra,
    this.onSelect,
    this.onInfo,
    this.trailingBuilder,
    this.showDownloadFab = false,
    this.footer,
    this.bottomAction,
    this.groupByFamily = false,
    this.familyOrder = const [],
    this.centeredList = false,
    this.embedded = false,
  });

  @override
  State<ModelBrowserScreen> createState() => _ModelBrowserScreenState();
}

class _ModelBrowserScreenState extends State<ModelBrowserScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PickableModel> get _visible {
    final q = _query.trim().toLowerCase();
    var list = widget.models;
    if (widget.selectedFilterId != 'all') {
      list = list.where((m) => m.statusKey == widget.selectedFilterId).toList();
    }
    if (q.isEmpty) return list;
    return list.where((m) {
      bool hit(String? s) => s != null && s.toLowerCase().contains(q);
      return hit(m.id) ||
          hit(m.displayName) ||
          hit(m.subtitle) ||
          hit(m.familyGroup) ||
          hit(m.typeLabel) ||
          hit(m.sizeLabel) ||
          hit(m.quantLabel) ||
          m.details.any((d) => hit(d.label) || hit(d.value));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topBg = isDark ? const Color(0xFF1A202E) : const Color(0xFF243044);
    final headerH = GlassPageHeader.heightFor(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final visible = _visible;

    final useCards = prefersWideSettingsLayout(context) && !widget.centeredList;
    final list = widget.groupByFamily
        ? _GroupedModelList(
            models: visible,
            familyOrder: widget.familyOrder,
            bottomPadding: widget.bottomAction != null ? 96 : 28,
            footer: widget.footer,
            onSelect: widget.onSelect,
            onInfo: widget.onInfo,
            trailingBuilder: widget.trailingBuilder,
            useCards: useCards,
            expandActiveGroups: widget.centeredList,
          )
        : useCards
            ? _ModelCardGrid(
                models: visible,
                bottomPadding: widget.bottomAction != null ? 96 : 28,
                footer: widget.footer,
                onSelect: widget.onSelect,
                onInfo: widget.onInfo,
                trailingBuilder: widget.trailingBuilder,
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  14,
                  8,
                  14,
                  widget.bottomAction != null ? 96 : 28,
                ),
                itemCount: visible.length + (widget.footer != null ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (widget.footer != null && i == visible.length) {
                    return widget.footer!;
                  }
                  final m = visible[i];
                  return _buildRow(context, m);
                },
              );

    final sheetBody = widget.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  prefersWideSettingsLayout(context) && !widget.centeredList
                      ? 0
                      : 16,
                  16,
                  prefersWideSettingsLayout(context) && !widget.centeredList
                      ? 0
                      : 16,
                  8,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    filled: true,
                    fillColor:
                        cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              if (widget.filters.isNotEmpty || widget.filtersTrailing != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      if (widget.filters.isNotEmpty)
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _GlassFilterBar(
                              filters: widget.filters,
                              selectedId: widget.selectedFilterId,
                              onChanged: widget.onFilterChanged,
                            ),
                          ),
                        ),
                      if (widget.filtersTrailing != null) ...[
                        const SizedBox(width: 8),
                        widget.filtersTrailing!,
                      ],
                    ],
                  ),
                ),
              if (widget.headerExtra != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: widget.headerExtra!,
                ),
              Expanded(
                child: visible.isEmpty
                    ? (widget.emptyState ??
                        Center(
                          child: Text(
                            'No models found',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ))
                    : list,
              ),
            ],
          );

    final constrainedBody = widget.centeredList
        ? LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth > 640 ? 640.0 : constraints.maxWidth;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : null,
                  child: sheetBody,
                ),
              );
            },
          )
        : sheetBody;

    final scaffold = widget.embedded
        ? Scaffold(
            backgroundColor: cs.surface,
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
                            widget.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        ...widget.actions,
                      ],
                    ),
                  ),
                  Expanded(child: constrainedBody),
                ],
              ),
            ),
          )
        : Scaffold(
            backgroundColor: topBg,
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(headerH),
              child: GlassPageHeader(
                title: widget.title,
                onBack: () => Navigator.of(context).maybePop(),
                actions: widget.actions,
              ),
            ),
            body: Column(
              children: [
                SizedBox(height: headerH),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: constrainedBody,
                  ),
                ),
              ],
            ),
          );

    return Stack(
      children: [
        scaffold,
        if (widget.bottomAction != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Center(child: widget.bottomAction!),
          ),
        if (widget.showDownloadFab) const GlobalDownloadFAB(),
      ],
    );
  }

  Widget _buildRow(BuildContext context, PickableModel m) {
    return ModelRow(
      model: m,
      onTap: widget.onSelect == null ? null : () => widget.onSelect!(m),
      onInfo: () {
        if (widget.onInfo != null) {
          widget.onInfo!(m);
        } else {
          showModelDetailsSheet(context, m);
        }
      },
      trailing: widget.trailingBuilder?.call(context, m),
    );
  }
}

class _ModelCardGrid extends StatelessWidget {
  final List<PickableModel> models;
  final double bottomPadding;
  final Widget? footer;
  final ValueChanged<PickableModel>? onSelect;
  final ValueChanged<PickableModel>? onInfo;
  final Widget Function(BuildContext, PickableModel)? trailingBuilder;

  const _ModelCardGrid({
    required this.models,
    required this.bottomPadding,
    this.footer,
    this.onSelect,
    this.onInfo,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1200
            ? 3
            : w >= 720
                ? 2
                : 1;
        const gap = 14.0;
        final tileW = (w - gap * (cols - 1)) / cols;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final m in models)
                    SizedBox(
                      width: tileW,
                      height: 188,
                      child: ModelCatalogCard(
                        model: m,
                        onTap: onSelect == null ? null : () => onSelect!(m),
                        onInfo: () {
                          if (onInfo != null) {
                            onInfo!(m);
                          } else {
                            showModelDetailsSheet(context, m);
                          }
                        },
                        trailing: trailingBuilder?.call(context, m),
                      ),
                    ),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: 16),
                footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GroupedModelList extends StatelessWidget {
  final List<PickableModel> models;
  final List<String> familyOrder;
  final double bottomPadding;
  final Widget? footer;
  final ValueChanged<PickableModel>? onSelect;
  final ValueChanged<PickableModel>? onInfo;
  final Widget Function(BuildContext, PickableModel)? trailingBuilder;
  final bool useCards;
  final bool expandActiveGroups;

  const _GroupedModelList({
    required this.models,
    required this.familyOrder,
    required this.bottomPadding,
    this.footer,
    this.onSelect,
    this.onInfo,
    this.trailingBuilder,
    this.useCards = false,
    this.expandActiveGroups = false,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PickableModel>>{};
    for (final m in models) {
      final key = m.familyGroup ?? 'Other';
      groups.putIfAbsent(key, () => []).add(m);
    }

    final keys = <String>[
      ...familyOrder.where(groups.containsKey),
      ...groups.keys.where((k) => !familyOrder.contains(k)),
    ];

    if (useCards) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final cols = w >= 1200
              ? 3
              : w >= 720
                  ? 2
                  : 1;
          const gap = 14.0;
          final tileW = (w - gap * (cols - 1)) / cols;
          return ListView(
            padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
            children: [
              for (final family in keys) ...[
                Text(
                  family.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final m in groups[family]!)
                      SizedBox(
                        width: tileW,
                        height: 188,
                        child: ModelCatalogCard(
                          model: m,
                          onTap: onSelect == null ? null : () => onSelect!(m),
                          onInfo: () {
                            if (onInfo != null) {
                              onInfo!(m);
                            } else {
                              showModelDetailsSheet(context, m);
                            }
                          },
                          trailing: trailingBuilder?.call(context, m),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
              if (footer != null) footer!,
            ],
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPadding),
      itemCount: keys.length + (footer != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (footer != null && i == keys.length) return footer!;
        final family = keys[i];
        final items = groups[family]!;
        items.sort((a, b) {
          final ar = a.isRecommended ? 0 : 1;
          final br = b.isRecommended ? 0 : 1;
          if (ar != br) return ar - br;
          final at = a.typeLabel ?? '';
          final bt = b.typeLabel ?? '';
          if (at != bt) return at.compareTo(bt);
          return (a.quantLabel ?? '').compareTo(b.quantLabel ?? '');
        });
        final expand = expandActiveGroups
            ? items.any((m) =>
                m.isRecommended || m.isLoaded || m.isLoading || m.isSelected)
            : i == 0;
        final sizes = items
            .map((m) => m.sizeLabel)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
        final sizeHint = sizes.isEmpty
            ? null
            : sizes.length == 1
                ? sizes.first
                : '${sizes.first} – ${sizes.last}';
        final cs = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>('model-line-$family'),
            initiallyExpanded: expand,
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              family,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [
                '${items.length} ${items.length == 1 ? 'format' : 'formats'}',
                if (sizeHint != null) sizeHint,
              ].join(' · '),
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            children: [
              for (final m in items) ...[
                ModelRow(
                  model: m,
                  onTap: onSelect == null ? null : () => onSelect!(m),
                  onInfo: () {
                    if (onInfo != null) {
                      onInfo!(m);
                    } else {
                      showModelDetailsSheet(context, m);
                    }
                  },
                  trailing: trailingBuilder?.call(context, m),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Segmented glass bubble for All / Ready / Downloaded filters.
class _GlassFilterBar extends StatelessWidget {
  final List<ModelBrowserFilter> filters;
  final String selectedId;
  final ValueChanged<String>? onChanged;

  const _GlassFilterBar({
    required this.filters,
    required this.selectedId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: GlassBlur(
          sigmaX: 28,
          sigmaY: 28,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.42),
                      ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: filters.map((f) {
                final selected = f.id == selectedId;
                return _GlassFilterSegment(
                  label: f.label,
                  selected: selected,
                  onTap: onChanged == null ? null : () => onChanged!(f.id),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassFilterSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _GlassFilterSegment({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg =
        isDark ? const Color(0xFF0B0E14) : Colors.white.withValues(alpha: 0.95);
    final fg = selected
        ? (isDark ? Colors.white : Colors.black.withValues(alpha: 0.88))
        : (isDark
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.black.withValues(alpha: 0.55));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
