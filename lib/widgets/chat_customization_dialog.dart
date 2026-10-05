import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_conversation.dart';
import '../utils/chat_font_helper.dart';
import '../utils/image_picker_helper.dart';
import 'glass_blur.dart';

/// Per-chat appearance editor.
///
/// Background states:
/// - key missing → use global wallpaper
/// - `chatBackground: ''` → no wallpaper for this chat
/// - `chatBackground: '<path>'` → custom wallpaper
class ChatCustomizationDialog extends StatefulWidget {
  final ChatConversation conversation;
  final String? globalChatBackground;
  final String? globalUserAvatar;
  final String? globalAssistantAvatar;
  final double globalBackgroundOverlayOpacity;

  const ChatCustomizationDialog({
    super.key,
    required this.conversation,
    this.globalChatBackground,
    this.globalUserAvatar,
    this.globalAssistantAvatar,
    this.globalBackgroundOverlayOpacity = 15.0,
  });

  @override
  State<ChatCustomizationDialog> createState() =>
      _ChatCustomizationDialogState();
}

class _ChatCustomizationDialogState extends State<ChatCustomizationDialog> {
  /// null = use global; '' = none; path = custom
  String? _chatBackground;
  bool _explicitNoBackground = false;

  String? _userAvatar;
  String? _assistantAvatar;
  Color? _userBubbleColor;
  Color? _userTextColor;
  Color? _assistantBubbleColor;
  Color? _assistantTextColor;
  String? _chatFontFamily;
  double _backgroundOverlayOpacity = 15.0;

  @override
  void initState() {
    super.initState();
    final settings = widget.conversation.settings;

    if (settings.containsKey('chatBackground')) {
      final v = settings['chatBackground'] as String?;
      if (v == null || v.isEmpty) {
        _chatBackground = null;
        _explicitNoBackground = true;
      } else {
        _chatBackground = v;
        _explicitNoBackground = false;
      }
    } else {
      _chatBackground = null;
      _explicitNoBackground = false;
    }

    _userAvatar = settings['userAvatar'] as String?;
    _assistantAvatar = settings['assistantAvatar'] as String?;

    final userBubbleValue = settings['userBubbleColor'] as int?;
    _userBubbleColor = userBubbleValue != null ? Color(userBubbleValue) : null;

    final userTextValue = settings['userTextColor'] as int?;
    _userTextColor = userTextValue != null ? Color(userTextValue) : null;

    final assistantBubbleValue = settings['assistantBubbleColor'] as int?;
    _assistantBubbleColor =
        assistantBubbleValue != null ? Color(assistantBubbleValue) : null;

    final assistantTextValue = settings['assistantTextColor'] as int?;
    _assistantTextColor =
        assistantTextValue != null ? Color(assistantTextValue) : null;

    _chatFontFamily = settings['chatFontFamily'] as String?;
    _backgroundOverlayOpacity =
        (settings['backgroundOverlayOpacity'] as num?)?.toDouble() ??
            widget.globalBackgroundOverlayOpacity;
  }

  Map<String, dynamic> _buildResult() {
    final updated = Map<String, dynamic>.from(widget.conversation.settings);

    if (_explicitNoBackground) {
      updated['chatBackground'] = '';
    } else if (_chatBackground != null && _chatBackground!.isNotEmpty) {
      updated['chatBackground'] = _chatBackground;
    } else {
      updated.remove('chatBackground');
    }

    void setOrRemove(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        updated[key] = value;
      } else {
        updated.remove(key);
      }
    }

    setOrRemove('userAvatar', _userAvatar);
    setOrRemove('assistantAvatar', _assistantAvatar);

    void setColor(String key, Color? color) {
      if (color != null) {
        updated[key] = color.value;
      } else {
        updated.remove(key);
      }
    }

    setColor('userBubbleColor', _userBubbleColor);
    setColor('userTextColor', _userTextColor);
    setColor('assistantBubbleColor', _assistantBubbleColor);
    setColor('assistantTextColor', _assistantTextColor);

    if (_chatFontFamily != null && _chatFontFamily!.isNotEmpty) {
      updated['chatFontFamily'] = _chatFontFamily;
    } else {
      updated.remove('chatFontFamily');
    }

    updated['backgroundOverlayOpacity'] = _backgroundOverlayOpacity;
    return updated;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassBlur(
          sigmaX: 24,
          sigmaY: 24,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxH, maxWidth: 440),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.customizeChat,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.overrideGlobalAppearance,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel(context, l10n.background),
                        const SizedBox(height: 8),
                        _buildBackgroundCard(context),
                        const SizedBox(height: 10),
                        _buildOverlayRow(context),
                        const SizedBox(height: 18),
                        _sectionLabel(context, 'Avatars'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAvatarCard(
                                context,
                                title: l10n.userAvatar,
                                currentPath: _userAvatar,
                                globalPath: widget.globalUserAvatar,
                                placeholder: Icons.person_rounded,
                                onPick: () async {
                                  final file =
                                      await ImagePickerHelper.pickFromGallery(
                                          context);
                                  if (file != null) {
                                    setState(() => _userAvatar =
                                        ImagePickerHelper.toRelativePath(
                                            file.path));
                                  }
                                },
                                onClear: () =>
                                    setState(() => _userAvatar = null),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildAvatarCard(
                                context,
                                title: l10n.assistantAvatar,
                                currentPath: _assistantAvatar,
                                globalPath: widget.globalAssistantAvatar,
                                placeholder: Icons.smart_toy_rounded,
                                onPick: () async {
                                  final file =
                                      await ImagePickerHelper.pickFromGallery(
                                          context);
                                  if (file != null) {
                                    setState(() => _assistantAvatar =
                                        ImagePickerHelper.toRelativePath(
                                            file.path));
                                  }
                                },
                                onClear: () =>
                                    setState(() => _assistantAvatar = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _sectionLabel(context, 'Chat Font'),
                        const SizedBox(height: 8),
                        _buildFontPicker(context),
                        const SizedBox(height: 18),
                        _sectionLabel(context, l10n.colorsSection),
                        const SizedBox(height: 8),
                        _buildColorGrid(context),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, _buildResult()),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildBackgroundCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final String? previewPath;
    final String statusLabel;
    if (_explicitNoBackground) {
      previewPath = null;
      statusLabel = 'No background';
    } else if (_chatBackground != null && _chatBackground!.isNotEmpty) {
      previewPath = _chatBackground;
      statusLabel = l10n.custom;
    } else {
      previewPath = widget.globalChatBackground;
      statusLabel = l10n.usingGlobal;
    }

    final resolved = ImagePickerHelper.resolveImagePathSync(previewPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (resolved != null)
              Image.file(
                File(resolved),
                fit: BoxFit.cover,
                color: Colors.black
                    .withValues(alpha: _backgroundOverlayOpacity / 100.0),
                colorBlendMode: BlendMode.srcOver,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surfaceContainerHighest,
                      cs.surfaceContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _explicitNoBackground
                        ? Icons.hide_image_outlined
                        : Icons.image_outlined,
                    size: 36,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Clear background for this chat (keeps global intact).
            if (!_explicitNoBackground &&
                (resolved != null ||
                    (_chatBackground != null && _chatBackground!.isNotEmpty) ||
                    (widget.globalChatBackground != null &&
                        widget.globalChatBackground!.isNotEmpty)))
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        _chatBackground = null;
                        _explicitNoBackground = true;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_explicitNoBackground ||
                      (_chatBackground != null && _chatBackground!.isNotEmpty))
                    _miniChip(
                      context,
                      icon: Icons.public_rounded,
                      label: l10n.useGlobal,
                      onTap: () {
                        setState(() {
                          _chatBackground = null;
                          _explicitNoBackground = false;
                        });
                      },
                    ),
                  const SizedBox(width: 6),
                  _miniChip(
                    context,
                    icon: Icons.photo_library_outlined,
                    label:
                        (_chatBackground != null && _chatBackground!.isNotEmpty)
                            ? l10n.change
                            : l10n.setCustom,
                    onTap: () async {
                      final file =
                          await ImagePickerHelper.pickFromGallery(context);
                      if (file != null) {
                        setState(() {
                          _chatBackground =
                              ImagePickerHelper.toRelativePath(file.path);
                          _explicitNoBackground = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.opacity, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.darkOverlay,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${_backgroundOverlayOpacity.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _backgroundOverlayOpacity,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: _explicitNoBackground
                  ? null
                  : (value) =>
                      setState(() => _backgroundOverlayOpacity = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(
    BuildContext context, {
    required String title,
    required String? currentPath,
    required String? globalPath,
    required IconData placeholder,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final effective = currentPath ?? globalPath;
    final resolved = ImagePickerHelper.resolveImagePathSync(effective);
    final isCustom = currentPath != null;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.surfaceContainerHigh,
                    backgroundImage:
                        resolved != null ? FileImage(File(resolved)) : null,
                    child: resolved == null
                        ? Icon(placeholder, color: cs.onSurfaceVariant)
                        : null,
                  ),
                  if (isCustom)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Material(
                        color: cs.surface,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onClear,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCustom ? l10n.custom : l10n.usingGlobal,
                style: TextStyle(
                  fontSize: 11,
                  color: isCustom ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewStyle = ChatFontHelper.apply(
      _chatFontFamily,
      TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _chatFontFamily ?? '',
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: cs.surface.withValues(alpha: 0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text(ChatFontHelper.systemDefaultLabel),
              ),
              ...ChatFontHelper.supportedFonts.map(
                (font) => DropdownMenuItem<String>(
                  value: font,
                  child: Text(
                    font,
                    style: ChatFontHelper.apply(
                        font, const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _chatFontFamily =
                    (value == null || value.isEmpty) ? null : value;
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Preview: Hello! How can I assist you today?',
            style: previewStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _colorRow(
            context,
            title: l10n.userBubble,
            current: _userBubbleColor,
            fallback: cs.primary,
            onChanged: (c) => setState(() => _userBubbleColor = c),
            onReset: () => setState(() => _userBubbleColor = null),
          ),
          const SizedBox(height: 8),
          _colorRow(
            context,
            title: l10n.userText,
            current: _userTextColor,
            fallback: cs.onPrimary,
            onChanged: (c) => setState(() => _userTextColor = c),
            onReset: () => setState(() => _userTextColor = null),
          ),
          const SizedBox(height: 8),
          _colorRow(
            context,
            title: l10n.assistantBubble,
            current: _assistantBubbleColor,
            fallback: cs.surfaceContainerHighest,
            onChanged: (c) => setState(() => _assistantBubbleColor = c),
            onReset: () => setState(() => _assistantBubbleColor = null),
          ),
          const SizedBox(height: 8),
          _colorRow(
            context,
            title: l10n.assistantText,
            current: _assistantTextColor,
            fallback: cs.onSurfaceVariant,
            onChanged: (c) => setState(() => _assistantTextColor = c),
            onReset: () => setState(() => _assistantTextColor = null),
          ),
        ],
      ),
    );
  }

  Widget _colorRow(
    BuildContext context, {
    required String title,
    required Color? current,
    required Color fallback,
    required ValueChanged<Color> onChanged,
    required VoidCallback onReset,
  }) {
    final cs = Theme.of(context).colorScheme;
    final effective = current ?? fallback;
    final isCustom = current != null;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
          ),
        ),
        if (isCustom)
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            tooltip: AppLocalizations.of(context).resetToDefault,
            onPressed: onReset,
            icon: Icon(Icons.restart_alt_rounded, color: cs.onSurfaceVariant),
          ),
        GestureDetector(
          onTap: () => _showColorPicker(context, effective, onChanged),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: effective,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color initialColor,
    ValueChanged<Color> onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).pickAColor),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in const [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
                Colors.black,
                Colors.white,
              ])
                GestureDetector(
                  onTap: () {
                    onColorChanged(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
