import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import 'theme_creation_screen.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.themesTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Themes'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyThemesTab(context, colorScheme),
          _buildCommunityTab(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMyThemesTab(BuildContext context, ColorScheme colorScheme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final themes = themeProvider.availableThemes;
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = theme.id == themeProvider.selectedThemeId;
                return _ThemeCard(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () {
                    themeProvider.selectTheme(theme.id);
                    context
                        .read<SettingsProvider>()
                        .updateSelectedThemeId(theme.id);
                  },
                  onEdit: theme.isBuiltIn
                      ? null
                      : () => _editTheme(context, themeProvider, theme),
                  onDelete: theme.isBuiltIn
                      ? null
                      : () => _confirmDelete(context, themeProvider, theme),
                  onUpload: theme.isBuiltIn
                      ? null
                      : () => _uploadTheme(context, themeProvider, theme),
                  showUpload: !theme.isBuiltIn && !themeProvider.isThemeUploaded(theme.id),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                heroTag: 'createTheme',
                onPressed: () async {
                  final newTheme = await Navigator.push<AppTheme>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ThemeCreationScreen(),
                    ),
                  );
                  if (newTheme != null && context.mounted) {
                    themeProvider.addCustomTheme(newTheme);
                    themeProvider.selectTheme(newTheme.id);
                    context.read<SettingsProvider>().updateSelectedThemeId(newTheme.id);
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context).createLabel),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommunityTab(BuildContext context, ColorScheme colorScheme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final l10n = AppLocalizations.of(context);
        if (themeProvider.communityThemes.isEmpty &&
            !themeProvider.isLoadingCommunity) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.palette_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'Community themes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse and download themes shared by other users',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => themeProvider.fetchCommunityThemes(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.browseLabel),
                ),
              ],
            ),
          );
        }

        if (themeProvider.isLoadingCommunity) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => themeProvider.fetchCommunityThemes(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: themeProvider.communityThemes.length,
                itemBuilder: (context, index) {
                  final theme = themeProvider.communityThemes[index];
                  final alreadyDownloaded =
                      themeProvider.availableThemes.any((t) => t.id == theme.id);
                  return _CommunityThemeCard(
                    theme: theme,
                    alreadyDownloaded: alreadyDownloaded,
                    onDownload: () async {
                      final success =
                          await themeProvider.downloadAndInstallTheme(theme.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Theme "${theme.name}" downloaded!'
                                : 'Failed to download theme'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _uploadTheme(BuildContext context, ThemeProvider themeProvider, AppTheme theme) async {
    final l10n = AppLocalizations.of(context);
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signInToUploadThemes)),
      );
      return;
    }
    final success = await themeProvider.uploadTheme(theme);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '"${theme.name}" uploaded to community!'
              : 'Failed to upload theme'),
        ),
      );
      if (success) themeProvider.fetchCommunityThemes();
    }
  }

  void _editTheme(BuildContext context, ThemeProvider themeProvider, AppTheme theme) async {
    final editedTheme = await Navigator.push<AppTheme>(
      context,
      MaterialPageRoute(
        builder: (_) => ThemeCreationScreen(existingTheme: theme),
      ),
    );
    if (editedTheme != null && context.mounted) {
      await themeProvider.addCustomTheme(editedTheme);
      if (themeProvider.selectedThemeId == editedTheme.id) {
        themeProvider.selectTheme(editedTheme.id);
        context.read<SettingsProvider>().updateSelectedThemeId(editedTheme.id);
      }
    }
  }

  void _confirmDelete(
      BuildContext context, ThemeProvider provider, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteThemeTitle),
        content: Text(l10n.deleteThemeConfirm(theme.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.removeDownloadedTheme(theme.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

// ── Theme preview card ──────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpload;
  final bool showUpload;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpload,
    this.showUpload = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final themeColors =
        brightness == Brightness.light ? theme.lightColors : theme.darkColors;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color preview strip
            _buildColorPreview(themeColors),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              theme.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (theme.isBuiltIn) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Built-in',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle,
                                  size: 20, color: colorScheme.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          theme.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_outlined,
                          color: colorScheme.primary, size: 20),
                    ),
                  if (showUpload && onUpload != null)
                    IconButton(
                      onPressed: onUpload,
                      icon: Icon(Icons.upload_outlined,
                          color: colorScheme.tertiary, size: 20),
                      tooltip: l10n.uploadToCommunity,
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline,
                          color: colorScheme.error, size: 20),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreview(AppThemeColors colors) {
    // If there's a gradient, show it
    if (colors.backgroundGradient != null &&
        colors.backgroundGradient!.isNotEmpty) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          gradient: LinearGradient(colors: colors.backgroundGradient!),
        ),
      );
    }

    // Derive proper colors from seed when fields are null
    final cs = ColorScheme.fromSeed(seedColor: colors.seedColor);
    final previewColors = <Color>[
      colors.seedColor,
      colors.primary ?? cs.primary,
      colors.primaryContainer ?? cs.primaryContainer,
      colors.secondary ?? cs.secondary,
      colors.userBubbleColor ?? cs.primaryContainer,
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 48,
        child: Row(
          children: previewColors
              .map((c) => Expanded(child: ColoredBox(color: c)))
              .toList(),
        ),
      ),
    );
  }
}

// ── Community theme card ────────────────────────────────────────

class _CommunityThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool alreadyDownloaded;
  final VoidCallback onDownload;

  const _CommunityThemeCard({
    required this.theme,
    required this.alreadyDownloaded,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final themeColors =
        brightness == Brightness.light ? theme.lightColors : theme.darkColors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: themeColors.backgroundGradient != null
                  ? LinearGradient(colors: themeColors.backgroundGradient!)
                  : null,
              color: themeColors.backgroundGradient == null
                  ? themeColors.seedColor
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${theme.author}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                      if (theme.downloadCount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.download,
                                size: 14,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              '${theme.downloadCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (alreadyDownloaded)
                  Chip(
                    label: Text(l10n.installedLabel),
                    avatar: const Icon(Icons.check, size: 16),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.getLabel),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
