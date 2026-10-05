import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/app_theme.dart';
import '../utils/image_picker_helper.dart';
import '../utils/bundled_google_fonts.dart';

class ThemeCreationScreen extends StatefulWidget {
  final AppTheme? existingTheme;

  const ThemeCreationScreen({super.key, this.existingTheme});

  @override
  State<ThemeCreationScreen> createState() => _ThemeCreationScreenState();
}

class _ThemeCreationScreenState extends State<ThemeCreationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Meta
  final _nameController = TextEditingController(text: 'My Theme');
  final _descController = TextEditingController();
  final _authorController = TextEditingController();

  // Colors (light mode)
  Color _seedColor = Colors.deepPurple;
  Color? _userBubbleColor;
  Color? _userBubbleTextColor;
  Color? _assistantBubbleColor;
  Color? _assistantBubbleTextColor;
  Color? _scaffoldBackground;
  Color? _settingsListTileColor;
  final List<Color> _gradientColors = [];

  // Style options
  BubbleStyle _bubbleStyle = BubbleStyle.rounded;
  bool _showProfileImages = true;
  double _profileImageRadius = 22;
  String? _fontFamily;
  bool _isDarkTheme = false;
  String? _editingThemeId;
  final Map<String, String> _customIcons = {};

  // Font list (subset of popular Google Fonts)
  static const _popularFonts = [
    null, // system default
    ...BundledGoogleFonts.families,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final existing = widget.existingTheme;
    if (existing != null) {
      _editingThemeId = existing.id;
      _nameController.text = existing.name;
      _descController.text = existing.description;
      _authorController.text = existing.author;
      _bubbleStyle = existing.bubbleStyle;
      _showProfileImages = existing.showProfileImages;
      _profileImageRadius = existing.profileImageRadius;
      _fontFamily = existing.fontFamily;
      _isDarkTheme = existing.isDarkTheme;

      // Load colors from the editing mode
      final colors = _isDarkTheme ? existing.darkColors : existing.lightColors;
      _seedColor = colors.seedColor;
      _userBubbleColor = colors.userBubbleColor;
      _userBubbleTextColor = colors.userBubbleTextColor;
      _assistantBubbleColor = colors.assistantBubbleColor;
      _assistantBubbleTextColor = colors.assistantBubbleTextColor;
      _scaffoldBackground = colors.scaffoldBackground;
      _settingsListTileColor = colors.settingsListTileColor;
      if (colors.backgroundGradient != null) {
        _gradientColors.addAll(colors.backgroundGradient!);
      }
      if (existing.customIcons != null) {
        _customIcons.addAll(existing.customIcons!);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  AppTheme _buildPreviewTheme() {
    final editedColors = AppThemeColors(
      seedColor: _seedColor,
      userBubbleColor: _userBubbleColor,
      userBubbleTextColor: _userBubbleTextColor,
      assistantBubbleColor: _assistantBubbleColor,
      assistantBubbleTextColor: _assistantBubbleTextColor,
      scaffoldBackground: _scaffoldBackground,
      settingsListTileColor: _settingsListTileColor,
      backgroundGradient: _gradientColors.isNotEmpty ? _gradientColors : null,
    );
    // Auto-derive the opposite mode
    final derivedColors = AppThemeColors(
      seedColor: _seedColor,
      userBubbleColor: _userBubbleColor != null
          ? _shiftBrightness(_userBubbleColor!, !_isDarkTheme)
          : null,
      userBubbleTextColor: _userBubbleTextColor,
      assistantBubbleColor: _assistantBubbleColor != null
          ? _shiftBrightness(_assistantBubbleColor!, !_isDarkTheme)
          : null,
      assistantBubbleTextColor: _assistantBubbleTextColor,
      scaffoldBackground: _scaffoldBackground != null
          ? _shiftBrightness(_scaffoldBackground!, !_isDarkTheme)
          : null,
      settingsListTileColor: _settingsListTileColor != null
          ? _shiftBrightness(_settingsListTileColor!, !_isDarkTheme)
          : null,
      backgroundGradient: _gradientColors.isNotEmpty
          ? _gradientColors
              .map((c) => _shiftBrightness(c, !_isDarkTheme))
              .toList()
          : null,
    );

    return AppTheme(
      id: _editingThemeId ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim().isEmpty
          ? 'My Theme'
          : _nameController.text.trim(),
      description: _descController.text.trim(),
      author: _authorController.text.trim().isEmpty
          ? 'Unknown'
          : _authorController.text.trim(),
      version: '1.0.0',
      lightColors: _isDarkTheme ? derivedColors : editedColors,
      darkColors: _isDarkTheme ? editedColors : derivedColors,
      bubbleStyle: _bubbleStyle,
      fontFamily: _fontFamily,
      showProfileImages: _showProfileImages,
      profileImageRadius: _profileImageRadius,
      customIcons: _customIcons.isNotEmpty ? Map.from(_customIcons) : null,
      isDarkTheme: _isDarkTheme,
      createdAt: DateTime.now(),
    );
  }

  Color _shiftBrightness(Color c, bool toDark) {
    final hsl = HSLColor.fromColor(c);
    if (toDark) {
      return hsl.withLightness((hsl.lightness * 0.4).clamp(0.0, 1.0)).toColor();
    } else {
      return hsl
          .withLightness((1.0 - (1.0 - hsl.lightness) * 0.4).clamp(0.0, 1.0))
          .toColor();
    }
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme name is required')),
      );
      return false;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existingTheme != null ? 'Edit Theme' : 'Create Theme'),
        actions: [
          TextButton(
            onPressed: () {
              if (!_validate()) return;
              final theme = _buildPreviewTheme();
              Navigator.pop(context, theme);
            },
            child: const Text('Save'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Colors'),
            Tab(text: 'Style'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildColorsTab(),
          _buildStyleTab(),
          _buildPreviewTab(),
        ],
      ),
    );
  }

  // ── Colors Tab ──────────────────────────────────────────────

  Widget _buildColorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Name & description
        TextField(
          controller: _nameController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Theme Name *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Description *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _authorController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Author',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Dark/Light toggle
        SwitchListTile(
          title: const Text('Dark Theme'),
          subtitle: Text(_isDarkTheme
              ? 'Designing for dark mode'
              : 'Designing for light mode'),
          secondary: Icon(_isDarkTheme ? Icons.dark_mode : Icons.light_mode),
          value: _isDarkTheme,
          onChanged: (v) => setState(() => _isDarkTheme = v),
        ),
        const SizedBox(height: 16),

        // Seed color
        _ColorPickerTile(
          label: 'Seed Color',
          color: _seedColor,
          onColorChanged: (c) => setState(() => _seedColor = c),
        ),
        const SizedBox(height: 12),

        // User bubble
        _ColorPickerTile(
          label: 'User Bubble',
          color: _userBubbleColor,
          placeholder: 'Auto from seed',
          onColorChanged: (c) => setState(() => _userBubbleColor = c),
        ),
        const SizedBox(height: 8),
        _ColorPickerTile(
          label: 'User Bubble Text',
          color: _userBubbleTextColor,
          placeholder: 'Auto',
          onColorChanged: (c) => setState(() => _userBubbleTextColor = c),
        ),
        const SizedBox(height: 12),

        // Assistant bubble
        _ColorPickerTile(
          label: 'Assistant Bubble',
          color: _assistantBubbleColor,
          placeholder: 'Auto from seed',
          onColorChanged: (c) => setState(() => _assistantBubbleColor = c),
        ),
        const SizedBox(height: 8),
        _ColorPickerTile(
          label: 'Assistant Bubble Text',
          color: _assistantBubbleTextColor,
          placeholder: 'Auto',
          onColorChanged: (c) => setState(() => _assistantBubbleTextColor = c),
        ),
        const SizedBox(height: 12),

        // Background
        _ColorPickerTile(
          label: 'Scaffold Background',
          color: _scaffoldBackground,
          placeholder: 'Auto',
          onColorChanged: (c) => setState(() => _scaffoldBackground = c),
        ),
        const SizedBox(height: 8),
        _ColorPickerTile(
          label: 'Settings List Tiles',
          color: _settingsListTileColor,
          placeholder: 'Auto',
          showAlpha: true,
          onColorChanged: (c) => setState(() => _settingsListTileColor = c),
        ),
        const SizedBox(height: 16),

        // Gradient
        Text('Background Gradient',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _gradientColors.length; i++)
              _GradientChip(
                color: _gradientColors[i],
                onTap: () => _pickColor(_gradientColors[i], (c) {
                  setState(() => _gradientColors[i] = c);
                }),
                onRemove: () => setState(() => _gradientColors.removeAt(i)),
              ),
            if (_gradientColors.length < 5)
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                onPressed: () {
                  setState(() => _gradientColors.add(_seedColor));
                },
              ),
          ],
        ),
      ],
    );
  }

  // ── Style Tab ───────────────────────────────────────────────

  Widget _buildStyleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bubble style
        Text('Bubble Style',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _BubbleStylePicker(
          selected: _bubbleStyle,
          seedColor: _seedColor,
          onChanged: (s) => setState(() => _bubbleStyle = s),
        ),
        const SizedBox(height: 24),

        // Font family
        Text('Font Family',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _popularFonts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final font = _popularFonts[index];
              final isSelected = _fontFamily == font;
              final textStyle = font != null
                  ? BundledGoogleFonts.styleOrFallback(
                      font, const TextStyle(fontSize: 13))
                  : const TextStyle(fontSize: 13);
              return ChoiceChip(
                label: Text(font ?? 'System', style: textStyle),
                selected: isSelected,
                onSelected: (_) => setState(() => _fontFamily = font),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Show profile images
        SwitchListTile(
          title: const Text('Show Profile Images'),
          subtitle: const Text('Display avatars in conversation list and chat'),
          value: _showProfileImages,
          onChanged: (v) => setState(() => _showProfileImages = v),
        ),

        // Profile image size
        if (_showProfileImages) ...[
          const SizedBox(height: 8),
          Text('Avatar Size',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Smaller'),
              Expanded(
                child: Slider(
                  value: _profileImageRadius,
                  min: 17,
                  max: 27,
                  divisions: 10,
                  label: _profileImageRadius.round().toString(),
                  onChanged: (v) => setState(() => _profileImageRadius = v),
                ),
              ),
              const Text('Larger'),
            ],
          ),
          Center(
            child: CircleAvatar(
              radius: _profileImageRadius,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.smart_toy,
                  size: _profileImageRadius - 6,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
        ],

        // Custom icons section
        const SizedBox(height: 24),
        Text('Custom Icons',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Upload custom images to replace default icons',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 12),
        _buildIconSlotSection(context, 'Conversation List', const [
          _IconSlot('home_filter', 'Filter', Icons.checklist),
          _IconSlot('home_folder', 'Folders', Icons.folder_outlined),
          _IconSlot('home_search', 'Search', Icons.search),
          _IconSlot('home_settings', 'Settings', Icons.settings),
        ]),
        const SizedBox(height: 16),
        _buildIconSlotSection(context, 'Chat Window', const [
          _IconSlot('chat_voice', 'Voice', Icons.headset_mic),
          _IconSlot('chat_menu', 'Menu', Icons.more_vert),
          _IconSlot('chat_settings', 'Settings', Icons.settings),
        ]),
        const SizedBox(height: 16),
        _buildIconSlotSection(context, 'Message Input', const [
          _IconSlot('input_attach', 'Attach', Icons.attach_file),
          _IconSlot('input_mic', 'Mic', Icons.mic),
          _IconSlot('input_send', 'Send', Icons.send),
        ]),
      ],
    );
  }

  Widget _buildIconSlotSection(
      BuildContext context, String title, List<_IconSlot> slots) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((slot) {
            final hasCustom = _customIcons.containsKey(slot.key);
            return GestureDetector(
              onTap: () => _pickIconImage(slot.key),
              onLongPress: hasCustom
                  ? () {
                      setState(() => _customIcons.remove(slot.key));
                    }
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: hasCustom
                          ? Border.all(color: cs.primary, width: 2)
                          : Border.all(color: cs.outline.withOpacity(0.2)),
                    ),
                    child: hasCustom
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_customIcons[slot.key]!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  slot.defaultIcon,
                                  size: 22,
                                  color: cs.onSurface),
                            ),
                          )
                        : Icon(slot.defaultIcon,
                            size: 22, color: cs.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 4),
                  Text(slot.label,
                      style: TextStyle(
                          fontSize: 10, color: cs.onSurface.withOpacity(0.6))),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickIconImage(String slotKey) async {
    final file = await ImagePickerHelper.pickFromGallery(context);
    if (file == null) return;

    // Copy to app documents for persistence
    final docsDir = await getApplicationDocumentsDirectory();
    final themeId =
        _editingThemeId ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final iconsDir = Directory('${docsDir.path}/theme_icons/$themeId');
    if (!await iconsDir.exists()) {
      await iconsDir.create(recursive: true);
    }
    final ext = file.path.split('.').last;
    final dest = File('${iconsDir.path}/$slotKey.$ext');
    await file.copy(dest.path);

    setState(() {
      _customIcons[slotKey] = dest.path;
    });
  }

  // ── Preview Tab ─────────────────────────────────────────────

  Widget _buildPreviewTab() {
    final theme = _buildPreviewTheme();
    final brightness = _isDarkTheme ? Brightness.dark : Brightness.light;
    final previewThemeData = theme.toThemeData(brightness);
    final colors = _isDarkTheme ? theme.darkColors : theme.lightColors;
    final cs = previewThemeData.colorScheme;

    final textTheme = BundledGoogleFonts.textThemeOrNull(_fontFamily);

    return Theme(
      data: previewThemeData.copyWith(textTheme: textTheme),
      child: Container(
        decoration: colors.backgroundGradient != null
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors.backgroundGradient!,
                ),
              )
            : BoxDecoration(
                color: colors.scaffoldBackground ?? cs.surface,
              ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Mock app bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: colors.appBarBackground ??
                    (colors.backgroundGradient != null
                        ? Colors.transparent
                        : cs.surface.withOpacity(0.85)),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: cs.onSurface, size: 22),
                  const SizedBox(width: 12),
                  if (theme.showProfileImages) ...[
                    CircleAvatar(
                      radius: theme.profileImageRadius.clamp(14.0, 20.0),
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        Icons.smart_toy,
                        size: theme.profileImageRadius.clamp(14.0, 20.0) * 0.6,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      _nameController.text.trim().isEmpty
                          ? 'My Theme'
                          : _nameController.text.trim(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        fontFamily: textTheme?.bodyLarge?.fontFamily,
                      ),
                    ),
                  ),
                  Icon(Icons.more_vert, color: cs.onSurface, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Conversation list preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Conversation List',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      fontFamily: textTheme?.bodyLarge?.fontFamily,
                      color: cs.onSurface.withOpacity(0.6))),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PreviewConversationList(
                colors: colors,
                cs: cs,
                showProfileImages: theme.showProfileImages,
                profileRadius: theme.profileImageRadius,
                fontFamily: textTheme?.bodyLarge?.fontFamily,
              ),
            ),
            const SizedBox(height: 24),

            // Chat bubbles preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Chat Bubbles',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      fontFamily: textTheme?.bodyLarge?.fontFamily,
                      color: cs.onSurface.withOpacity(0.6))),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PreviewChatBubbles(
                colors: colors,
                cs: cs,
                bubbleStyle: theme.bubbleStyle,
                showProfileImages: theme.showProfileImages,
                profileRadius: theme.profileImageRadius,
                fontFamily: textTheme?.bodyLarge?.fontFamily,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Color picker dialog ──────────────────────────────────────

  Future<void> _pickColor(Color current, ValueChanged<Color> onPicked) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => _SimpleColorPickerDialog(initialColor: current),
    );
    if (result != null) onPicked(result);
  }
}

// ── Color Picker Tile ──────────────────────────────────────────

class _ColorPickerTile extends StatelessWidget {
  final String label;
  final Color? color;
  final String? placeholder;
  final ValueChanged<Color> onColorChanged;
  final bool showAlpha;

  const _ColorPickerTile({
    required this.label,
    required this.color,
    this.placeholder,
    required this.onColorChanged,
    this.showAlpha = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showDialog<Color>(
          context: context,
          builder: (ctx) => _SimpleColorPickerDialog(
            initialColor: color ?? Colors.deepPurple,
            showAlpha: showAlpha,
          ),
        );
        if (result != null) onColorChanged(result);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color ?? Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: color == null
                  ? const Icon(Icons.auto_awesome, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              color != null
                  ? '#${color!.value.toRadixString(16).substring(2).toUpperCase()}'
                  : placeholder ?? 'Auto',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Gradient chip ──────────────────────────────────────────────

class _GradientChip extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _GradientChip({
    required this.color,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        label: Text(
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
          style: const TextStyle(fontSize: 11),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
      ),
    );
  }
}

// ── Bubble style picker ────────────────────────────────────────

class _BubbleStylePicker extends StatelessWidget {
  final BubbleStyle selected;
  final Color seedColor;
  final ValueChanged<BubbleStyle> onChanged;

  const _BubbleStylePicker({
    required this.selected,
    required this.seedColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Use a 2x2 grid so tiles fill the available width
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: BubbleStyle.values.map((style) {
        final isSelected = style == selected;
        return GestureDetector(
          onTap: () => onChanged(style),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mini bubble preview
                _MiniBubble(
                  style: style,
                  color: seedColor,
                  isUser: true,
                ),
                const SizedBox(height: 4),
                _MiniBubble(
                  style: style,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  isUser: false,
                ),
                const SizedBox(height: 6),
                Text(
                  _styleName(style),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _styleName(BubbleStyle style) {
    switch (style) {
      case BubbleStyle.rounded:
        return 'Rounded';
      case BubbleStyle.tail:
        return 'Tail';
      case BubbleStyle.flat:
        return 'Flat';
      case BubbleStyle.pill:
        return 'Pill';
    }
  }
}

class _MiniBubble extends StatelessWidget {
  final BubbleStyle style;
  final Color color;
  final bool isUser;

  const _MiniBubble({
    required this.style,
    required this.color,
    required this.isUser,
  });

  BorderRadius get _radius {
    switch (style) {
      case BubbleStyle.rounded:
        return BorderRadius.circular(10);
      case BubbleStyle.tail:
        return BorderRadius.only(
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
          bottomLeft:
              isUser ? const Radius.circular(10) : const Radius.circular(2),
          bottomRight:
              isUser ? const Radius.circular(2) : const Radius.circular(10),
        );
      case BubbleStyle.flat:
        return BorderRadius.circular(3);
      case BubbleStyle.pill:
        return BorderRadius.circular(16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        height: 18,
        width: isUser ? 70 : 90,
        decoration: BoxDecoration(
          color: color,
          borderRadius: _radius,
        ),
      ),
    );
  }
}

// ── Preview: conversation list ─────────────────────────────────

class _PreviewConversationList extends StatelessWidget {
  final AppThemeColors colors;
  final ColorScheme cs;
  final bool showProfileImages;
  final double profileRadius;
  final String? fontFamily;

  const _PreviewConversationList({
    required this.colors,
    required this.cs,
    required this.showProfileImages,
    this.profileRadius = 20,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Weekend plans', 'Sure! Here are some ideas...', '2:45 PM'),
      ('Flutter project', 'The build succeeded.', 'Yesterday'),
      ('Recipe ideas', 'Try the pasta recipe I...', 'Mon'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.conversationListBackground ?? cs.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: profileRadius.clamp(17.0, 27.0),
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    showProfileImages
                        ? Icons.smart_toy
                        : Icons.chat_bubble_outline,
                    size: profileRadius.clamp(17.0, 27.0) - 6,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: cs.onSurface,
                          fontFamily: fontFamily,
                        ),
                      ),
                      Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.5),
                            fontFamily: fontFamily),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.$3,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Preview: chat bubbles ──────────────────────────────────────

class _PreviewChatBubbles extends StatelessWidget {
  final AppThemeColors colors;
  final ColorScheme cs;
  final BubbleStyle bubbleStyle;
  final bool showProfileImages;
  final double profileRadius;
  final String? fontFamily;

  const _PreviewChatBubbles({
    required this.colors,
    required this.cs,
    required this.bubbleStyle,
    required this.showProfileImages,
    this.profileRadius = 14,
    this.fontFamily,
  });

  BorderRadius _radius(bool isUser) {
    switch (bubbleStyle) {
      case BubbleStyle.rounded:
        return BorderRadius.circular(16);
      case BubbleStyle.tail:
        return BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              isUser ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight:
              isUser ? const Radius.circular(4) : const Radius.circular(18),
        );
      case BubbleStyle.flat:
        return BorderRadius.circular(4);
      case BubbleStyle.pill:
        return BorderRadius.circular(28);
    }
  }

  EdgeInsets get _padding {
    switch (bubbleStyle) {
      case BubbleStyle.rounded:
      case BubbleStyle.tail:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case BubbleStyle.flat:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case BubbleStyle.pill:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userBg = colors.userBubbleColor ?? cs.primary;
    final userFg = colors.userBubbleTextColor ?? cs.onPrimary;
    final assistBg = colors.assistantBubbleColor ?? cs.surfaceContainerHighest;
    final assistFg = colors.assistantBubbleTextColor ?? cs.onSurfaceVariant;

    final messages = [
      (true, 'Hey! What should I cook for dinner?'),
      (
        false,
        'How about a simple pasta aglio e olio? It only takes 20 minutes and needs garlic, olive oil, chili flakes, and spaghetti.'
      ),
      (true, 'That sounds great, thanks!'),
    ];

    return Column(
      children: messages.map((msg) {
        final isUser = msg.$1;
        final text = msg.$2;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser && showProfileImages) ...[
                CircleAvatar(
                  radius: profileRadius.clamp(10.0, 20.0),
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.smart_toy,
                    size: profileRadius.clamp(10.0, 20.0) * 0.6,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? userBg : assistBg,
                    borderRadius: _radius(isUser),
                  ),
                  padding: _padding,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? userFg : assistFg,
                      fontSize: 14,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              ),
              if (isUser && showProfileImages) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: profileRadius.clamp(10.0, 20.0),
                  backgroundColor: cs.secondaryContainer,
                  child: Icon(
                    Icons.person,
                    size: profileRadius.clamp(10.0, 20.0) * 0.6,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Simple color picker dialog ─────────────────────────────────

class _SimpleColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final bool showAlpha;

  const _SimpleColorPickerDialog(
      {required this.initialColor, this.showAlpha = false});

  @override
  State<_SimpleColorPickerDialog> createState() =>
      _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState extends State<_SimpleColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;
  late double _alpha;
  final _hexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
    _alpha = widget.initialColor.a;
    _updateHex();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(_alpha, _hue, _saturation, _lightness).toColor();

  void _updateHex() {
    _hexController.text =
        '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Preset palette
  static const _presetColors = [
    Color(0xFFE91E63), // Pink
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFFFFC107), // Amber
    Color(0xFF4CAF50), // Green
    Color(0xFF009688), // Teal
    Color(0xFF2196F3), // Blue
    Color(0xFF3F51B5), // Indigo
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF9C27B0), // Purple
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF000000), // Black
    Color(0xFF424242), // Dark Grey
    Color(0xFF9E9E9E), // Grey
    Color(0xFFFFFFFF), // White
    Color(0xFFE8D5F5), // Lavender
    Color(0xFFFCE4F3), // Light Pink
    Color(0xFFD5E8FC), // Light Blue
    Color(0xFFE8F5E9), // Light Green
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.pickColor),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current color preview
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),

            // Presets
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presetColors.map((c) {
                return GestureDetector(
                  onTap: () {
                    final hsl = HSLColor.fromColor(c);
                    setState(() {
                      _hue = hsl.hue;
                      _saturation = hsl.saturation;
                      _lightness = hsl.lightness;
                      _updateHex();
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Hue
            Row(
              children: [
                SizedBox(width: 100, child: Text(l10n.hueLabel)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 8,
                      activeTrackColor: _currentColor,
                    ),
                    child: Slider(
                      value: _hue,
                      min: 0,
                      max: 360,
                      onChanged: (v) => setState(() {
                        _hue = v;
                        _updateHex();
                      }),
                    ),
                  ),
                ),
              ],
            ),

            // Saturation
            Row(
              children: [
                SizedBox(width: 100, child: Text(l10n.saturationLabel)),
                Expanded(
                  child: Slider(
                    value: _saturation,
                    min: 0,
                    max: 1,
                    onChanged: (v) => setState(() {
                      _saturation = v;
                      _updateHex();
                    }),
                  ),
                ),
              ],
            ),

            // Lightness
            Row(
              children: [
                SizedBox(width: 100, child: Text(l10n.lightnessLabel)),
                Expanded(
                  child: Slider(
                    value: _lightness,
                    min: 0,
                    max: 1,
                    onChanged: (v) => setState(() {
                      _lightness = v;
                      _updateHex();
                    }),
                  ),
                ),
              ],
            ),

            // Alpha (optional)
            if (widget.showAlpha)
              Row(
                children: [
                  SizedBox(width: 100, child: Text(l10n.alphaLabel)),
                  Expanded(
                    child: Slider(
                      value: _alpha,
                      min: 0,
                      max: 1,
                      onChanged: (v) => setState(() {
                        _alpha = v;
                        _updateHex();
                      }),
                    ),
                  ),
                  Text('${(_alpha * 100).round()}%',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            const SizedBox(height: 8),

            // Hex input
            TextField(
              controller: _hexController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: l10n.hexLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (value) {
                final hex = value.replaceAll('#', '');
                if (hex.length == 6) {
                  final parsed = int.tryParse('FF$hex', radix: 16);
                  if (parsed != null) {
                    final c = Color(parsed);
                    final hsl = HSLColor.fromColor(c);
                    setState(() {
                      _hue = hsl.hue;
                      _saturation = hsl.saturation;
                      _lightness = hsl.lightness;
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _currentColor),
          child: Text(l10n.select),
        ),
      ],
    );
  }
}

// ── Icon slot descriptor ───────────────────────────────────────

class _IconSlot {
  final String key;
  final String label;
  final IconData defaultIcon;
  const _IconSlot(this.key, this.label, this.defaultIcon);
}
