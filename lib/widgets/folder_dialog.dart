import 'dart:io';

import 'package:flutter/material.dart';
import '../models/chat_folder.dart';
import '../utils/image_picker_helper.dart';

enum _FolderCoverMode { color, image }

class FolderDialog extends StatefulWidget {
  final ChatFolder? folder;
  final Function(String name, String? color) onSave;

  const FolderDialog({
    super.key,
    this.folder,
    required this.onSave,
  });

  @override
  State<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<FolderDialog> {
  late TextEditingController _nameController;
  late _FolderCoverMode _mode;
  String? _selectedColor;
  String? _imagePath;
  final List<String> _extraColors = [];

  static const List<String> _presetColors = [
    '#FF6B6B',
    '#4ECDC4',
    '#45B7D1',
    '#FFA07A',
    '#98D8C8',
    '#F7DC6F',
    '#BB8FCE',
    '#85C1E2',
    '#F8B88B',
    '#ABEBC6',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder?.name ?? '');
    final existing = widget.folder?.color;
    if (existing != null && existing.startsWith(ChatFolder.imagePrefix)) {
      _mode = _FolderCoverMode.image;
      _imagePath = existing.substring(ChatFolder.imagePrefix.length);
      _selectedColor = _presetColors.first;
    } else {
      _mode = _FolderCoverMode.color;
      _selectedColor = existing ?? _presetColors.first;
      if (existing != null &&
          existing.startsWith('#') &&
          !_presetColors.contains(existing.toUpperCase()) &&
          !_presetColors.contains(existing)) {
        _extraColors.add(existing.startsWith('#')
            ? existing.toUpperCase()
            : existing);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<String> get _allColors {
    final seen = <String>{};
    final out = <String>[];
    for (final c in [..._presetColors, ..._extraColors]) {
      final key = c.toUpperCase();
      if (seen.add(key)) out.add(key.startsWith('#') ? key : c);
    }
    return out;
  }

  Color get _previewColor {
    final hex = _selectedColor ?? _presetColors.first;
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  Future<void> _pickCustomColor() async {
    final initial = _previewColor;
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _FolderColorPickerDialog(initialColor: initial),
    );
    if (picked == null || !mounted) return;
    final hex = ChatFolder.encodeColor(picked);
    setState(() {
      _mode = _FolderCoverMode.color;
      _selectedColor = hex;
      if (!_allColors.contains(hex)) {
        _extraColors.add(hex);
      }
    });
  }

  Future<void> _pickImage() async {
    final file = await ImagePickerHelper.pickFromGallery(context);
    if (file == null || !mounted) return;
    // pickFromGallery already copies permanently; store a relative path.
    final relative = ImagePickerHelper.toRelativePath(file.path);
    if (relative == null || relative.isEmpty) return;
    setState(() {
      _mode = _FolderCoverMode.image;
      _imagePath = relative;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final value = _mode == _FolderCoverMode.image && _imagePath != null
        ? ChatFolder.encodeImage(_imagePath!)
        : _selectedColor;
    widget.onSave(name, value);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCreate = widget.folder == null;
    final resolvedImage = _imagePath != null
        ? ImagePickerHelper.resolveImagePathSync(_imagePath!)
        : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isCreate ? 'Create Folder' : 'Edit Folder',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Name it and pick a color or cover image.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: _FolderPreview(
                    color: _previewColor,
                    imagePath: _mode == _FolderCoverMode.image
                        ? resolvedImage
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Folder name',
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 18),
                SegmentedButton<_FolderCoverMode>(
                  segments: const [
                    ButtonSegment(
                      value: _FolderCoverMode.color,
                      label: Text('Color'),
                      icon: Icon(Icons.palette_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: _FolderCoverMode.image,
                      label: Text('Image'),
                      icon: Icon(Icons.image_outlined, size: 18),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (set) {
                    setState(() => _mode = set.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_mode == _FolderCoverMode.color) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in _allColors)
                        _ColorDot(
                          hex: color,
                          selected: color.toUpperCase() ==
                              (_selectedColor ?? '').toUpperCase(),
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                              _mode = _FolderCoverMode.color;
                            });
                          },
                        ),
                      _AddColorDot(onTap: _pickCustomColor),
                    ],
                  ),
                ] else ...[
                  Material(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: resolvedImage != null
                                  ? Image.file(
                                      File(resolvedImage),
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: scheme.primary,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resolvedImage != null
                                        ? 'Change cover image'
                                        : 'Choose cover image',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Used instead of a folder color',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _imagePath = null;
                            _mode = _FolderCoverMode.color;
                          });
                        },
                        child: const Text('Remove image'),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(isCreate ? 'Create' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderPreview extends StatelessWidget {
  final Color color;
  final String? imagePath;

  const _FolderPreview({required this.color, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: imagePath == null ? color : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (imagePath == null ? color : Colors.black)
                .withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        image: imagePath != null
            ? DecorationImage(
                image: FileImage(File(imagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imagePath == null
          ? const Icon(Icons.folder_rounded, color: Colors.white, size: 40)
          : null,
    );
  }
}

class _ColorDot extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white.withValues(alpha: 0.35),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 20,
                color: color.computeLuminance() > 0.55
                    ? Colors.black87
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}

class _AddColorDot extends StatelessWidget {
  final VoidCallback onTap;

  const _AddColorDot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.55),
            width: 1.5,
          ),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: Icon(Icons.add, color: scheme.onSurface.withValues(alpha: 0.7)),
      ),
    );
  }
}

class _FolderColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _FolderColorPickerDialog({required this.initialColor});

  @override
  State<_FolderColorPickerDialog> createState() =>
      _FolderColorPickerDialogState();
}

class _FolderColorPickerDialogState extends State<_FolderColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation.clamp(0.05, 1.0);
    _lightness = hsl.lightness.clamp(0.12, 0.92);
  }

  Color get _color =>
      HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom color'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.25),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sliderRow(
              label: 'Hue',
              value: _hue,
              max: 360,
              onChanged: (v) => setState(() => _hue = v),
            ),
            _sliderRow(
              label: 'Sat',
              value: _saturation,
              max: 1,
              onChanged: (v) => setState(() => _saturation = v),
            ),
            _sliderRow(
              label: 'Light',
              value: _lightness,
              max: 1,
              onChanged: (v) => setState(() => _lightness = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Use color'),
        ),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0, max),
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
