import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/lm_studio_model.dart';
import '../providers/settings_provider.dart';
import 'adaptive_modal.dart';
import 'home_glass_header.dart';

/// Pick a model for the currently selected server.
///
/// Returns `true` when a model was saved.
Future<bool> showSelectModelSheet(BuildContext context) async {
  final result = await showAdaptiveModal<bool>(
    context: context,
    builder: (_) => const _SelectModelSheet(),
  );
  return result == true;
}

class _SelectModelSheet extends StatefulWidget {
  const _SelectModelSheet();

  @override
  State<_SelectModelSheet> createState() => _SelectModelSheetState();
}

class _SelectModelSheetState extends State<_SelectModelSheet> {
  bool _loading = true;
  List<LMStudioModel> _models = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final sp = context.read<SettingsProvider>();
    setState(() => _loading = true);
    try {
      if (sp.availableModels.isEmpty) {
        await sp.loadAvailableModels(silent: true);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _models = sp.chatAvailableModels;
      _loading = false;
    });
  }

  Future<void> _pick(LMStudioModel model) async {
    context.read<SettingsProvider>().updateSelectedModel(model.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final fg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.88);
    final muted = fg.withValues(alpha: 0.62);
    final canvas = isDark ? const Color(0xFF12151C) : const Color(0xFFF4F6FA);
    final maxH = MediaQuery.sizeOf(context).height * 0.62;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget body;
    if (_loading) {
      body = const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    } else if (_models.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Text(
          l10n.noModelSelectedSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        itemCount: _models.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: cs.outline.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, index) {
          final m = _models[index];
          final title = m.displayName.split('/').last;
          return ListTile(
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            subtitle: m.isLoaded
                ? Text(
                    l10n.loaded,
                    style: const TextStyle(
                      color: Color(0xFF00B894),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  )
                : (m.id != title
                    ? Text(
                        m.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      )
                    : null),
            onTap: () => _pick(m),
          );
        },
      );
    }

    return GlassCanvas(
      onLightCanvas: !isDark,
      child: SizedBox(
        height: maxH,
        child: Material(
          color: canvas.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l10n.selectModel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
