import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../utils/web_search_sources.dart';

/// ChatGPT-style stacked favicon pile for web search sources.
///
/// Tap once to expand a horizontal carousel of icon + site name.
/// Tap a site (or tap again) to open the results dialog.
class SearchSourcePile extends StatefulWidget {
  final List<WebSearchSource> sources;
  final bool compact;
  final Color textColor;

  const SearchSourcePile({
    super.key,
    required this.sources,
    required this.textColor,
    this.compact = false,
  });

  @override
  State<SearchSourcePile> createState() => _SearchSourcePileState();
}

class _SearchSourcePileState extends State<SearchSourcePile> {
  bool _expanded = false;

  static const _maxPile = 5;

  void _onPileTap() {
    if (!_expanded) {
      setState(() => _expanded = true);
      return;
    }
    _openResults();
  }

  void _openResults() {
    showSearchSourcesDialog(context, sources: widget.sources);
  }

  Color _discColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.50)
        : Colors.black.withValues(alpha: 0.10);
  }

  @override
  Widget build(BuildContext context) {
    final sources = widget.sources;
    if (sources.isEmpty) return const SizedBox.shrink();
    final size = widget.compact ? 22.0 : 24.0;
    final overlap = widget.compact ? 11.0 : 12.0;
    final shown = sources.take(_maxPile).toList();
    final pileW = size + (shown.length - 1) * overlap;
    final disc = _discColor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canExpand = constraints.maxWidth.isFinite;
        final carouselW = canExpand
            ? constraints.maxWidth.clamp(80.0, constraints.maxWidth)
            : 240.0;

        if (_expanded) {
          return SizedBox(
            width: carouselW,
            height: size + 4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: sources.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final source = sources[i];
                return GestureDetector(
                  onTap: _openResults,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FaviconCircle(
                        source: source,
                        size: size,
                        discColor: disc,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        source.siteName,
                        style: TextStyle(
                          fontSize: widget.compact ? 12 : 13,
                          color: widget.textColor.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return GestureDetector(
          onTap: _onPileTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: pileW,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * overlap,
                    child: _FaviconCircle(
                      source: shown[i],
                      size: size,
                      discColor: disc,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FaviconCircle extends StatefulWidget {
  final WebSearchSource source;
  final double size;
  final Color discColor;

  const _FaviconCircle({
    required this.source,
    required this.size,
    required this.discColor,
  });

  @override
  State<_FaviconCircle> createState() => _FaviconCircleState();
}

class _FaviconCircleState extends State<_FaviconCircle> {
  var _useGoogle = false;

  Widget _letter(bool isDark) {
    return Text(
      widget.source.letter,
      style: TextStyle(
        fontSize: widget.size * 0.42,
        fontWeight: FontWeight.w700,
        color: isDark
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.45),
        height: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url =
        _useGoogle ? widget.source.googleFaviconUrl : widget.source.faviconUrl;
    final inset = widget.size * 0.08;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: widget.source.siteName,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.discColor,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: ClipOval(
            child: Image.network(
              url,
              width: widget.size - inset * 2,
              height: widget.size - inset * 2,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) {
                if (!_useGoogle) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _useGoogle = true);
                  });
                }
                return Center(child: _letter(isDark));
              },
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showSearchSourcesDialog(
  BuildContext context, {
  required List<WebSearchSource> sources,
}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final disc = isDark
      ? Colors.white.withValues(alpha: 0.50)
      : Colors.black.withValues(alpha: 0.10);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final screenWidth = MediaQuery.sizeOf(ctx).width;
      final dialogWidth = screenWidth < 600 ? screenWidth * 0.92 : 500.0;
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: (screenWidth - dialogWidth) / 2,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.webSearchSourcesTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: sources.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final source = sources[i];
                    return Material(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final uri = Uri.tryParse(source.url);
                          if (uri != null) launchUrl(uri);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FaviconCircle(
                                source: source,
                                size: 28,
                                discColor: disc,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      source.siteName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      source.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                    if (source.snippet.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        source.snippet,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.72),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      source.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.primary.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
