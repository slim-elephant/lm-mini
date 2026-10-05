import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../../l10n/app_localizations.dart';
import '../../models/system_prompt.dart';
import '../../providers/settings_provider.dart';
import '../../screens/chat_screen.dart';
import '../../screens/system_prompts_screen.dart';
import '../../utils/image_picker_helper.dart';
import '../../utils/persona_palette.dart';
import '../../widgets/home_glass_header.dart';
import '../../widgets/persona_generator_dialog.dart';

/// Two-column personas content for the desktop shell.
///
/// Column 2: minimal portrait grid (image + name).
/// Column 3: profile detail with image left, info right.
class PersonasShellContent extends StatefulWidget {
  const PersonasShellContent({super.key});

  @override
  State<PersonasShellContent> createState() => _PersonasShellContentState();
}

class _PersonasShellContentState extends State<PersonasShellContent> {
  String? _selectedPersonaId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? const Color(0xFF0E1117) : colorScheme.surface;

    return Row(
      children: [
        ColoredBox(
          color: panelBg,
          child: SizedBox(
            width: 300,
            child: _PersonaListPanel(
              selectedId: _selectedPersonaId,
              onSelectPersona: (id) => setState(() => _selectedPersonaId = id),
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        Expanded(
          child: ColoredBox(
            color: panelBg,
            child: _buildDetailPane(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final prompts = settings.savedSystemPrompts ?? [];
    final persona = _selectedPersonaId != null
        ? prompts.where((p) => p.id == _selectedPersonaId).firstOrNull
        : null;

    if (persona == null) {
      final l10n = AppLocalizations.of(context);
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 64,
                  color: colorScheme.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.systemPromptsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a persona to view their profile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return _PersonaShellDetailPane(
      key: ValueKey('persona-${persona.id}'),
      persona: persona,
    );
  }
}

class _PersonaListPanel extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelectPersona;

  const _PersonaListPanel({
    required this.selectedId,
    required this.onSelectPersona,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.systemPromptsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                GlassCircleIconButton(
                  tooltip: l10n.promptPersonaGenerator,
                  onTap: () => _openGenerator(context),
                  onLightCanvas: !isDark,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 22,
                    color: isDark
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                final prompts =
                    settingsProvider.settings.savedSystemPrompts ?? [];
                final personas = prompts.where((p) => p.isPersona).toList();

                if (personas.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No personas yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w >= 260 ? 2 : 1;
                    const spacing = 10.0;
                    final tileW = (w - spacing * (cols - 1) - 24) / cols;
                    // 9:16 portrait + room for the name label under the image.
                    final tileH = tileW * (16 / 9) + 28;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final persona in personas)
                            SizedBox(
                              width: tileW,
                              height: tileH,
                              child: _PersonaMinimalCard(
                                prompt: persona,
                                isSelected: selectedId == persona.id,
                                onTap: () => onSelectPersona(persona.id),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: GlassCircleIconButton(
        size: 52,
        tooltip: l10n.addSystemPromptTooltip,
        isActive: true,
        prominent: true,
        onLightCanvas: !isDark,
        onTap: () => SystemPromptEditorScreen.open(context),
        child: Icon(
          Icons.add_rounded,
          size: 26,
          color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.88),
        ),
      ),
    );
  }

  Future<void> _openGenerator(BuildContext context) async {
    final prompt = await PersonaGeneratorDialog.show(context);
    if (prompt == null || !context.mounted) return;
    await SystemPromptEditorScreen.open(context, prompt: prompt);
  }
}

/// Minimal persona tile: portrait image with bottom shadow fade + name only.
class _PersonaMinimalCard extends StatelessWidget {
  final SystemPrompt prompt;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonaMinimalCard({
    required this.prompt,
    required this.isSelected,
    required this.onTap,
  });

  static bool _isPackAvatar(String? path) {
    if (path == null) return false;
    return path.contains('persona_pack_') ||
        path.contains('assets/images/persona_pack');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = prompt.color != null
        ? Color(prompt.color!)
        : (PersonaPalette.cachedOf(prompt)?.primary ?? cs.primary);
    final avatarPath =
        ImagePickerHelper.resolveImagePathSync(prompt.avatarPath);
    final pack = _isPackAvatar(prompt.avatarPath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: cs.primary, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isSelected ? 14 : 16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PortraitArt(
                        path: avatarPath,
                        accent: accent,
                        isPackArt: pack,
                      ),
                      // Palette edge wash (same language as phone profile).
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _PaletteEdgeWashPainter(
                            primary: accent,
                            secondary: PersonaPalette.cachedOf(prompt)
                                    ?.secondary ??
                                Color.lerp(accent, const Color(0xFF2B6CFF), 0.45)!,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.72),
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
            const SizedBox(height: 8),
            Text(
              prompt.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitArt extends StatelessWidget {
  final String? path;
  final Color accent;
  final bool isPackArt;

  const _PortraitArt({
    required this.path,
    required this.accent,
    required this.isPackArt,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.85),
              accent.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.face_rounded, size: 48, color: Colors.white70),
        ),
      );
    }

    final file = File(path!);
    if (isPackArt) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: accent.withValues(alpha: 0.25)),
          Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.broken_image_outlined, color: accent),
          ),
        ],
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: accent.withValues(alpha: 0.3),
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

/// Detail pane: large portrait on the left, structured info on the right.
class _PersonaShellDetailPane extends StatefulWidget {
  final SystemPrompt persona;

  const _PersonaShellDetailPane({
    super.key,
    required this.persona,
  });

  @override
  State<_PersonaShellDetailPane> createState() => _PersonaShellDetailPaneState();
}

class _PersonaShellDetailPaneState extends State<_PersonaShellDetailPane> {
  bool _startingChat = false;

  SystemPrompt _livePersona(BuildContext context) {
    final prompts =
        context.watch<SettingsProvider>().settings.savedSystemPrompts ?? [];
    return prompts.firstWhere(
      (p) => p.id == widget.persona.id,
      orElse: () => widget.persona,
    );
  }

  Future<void> _startChat() async {
    if (_startingChat) return;
    setState(() => _startingChat = true);
    final persona = _livePersona(context);
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.loadSettings();
    if (!mounted) return;
    await settingsProvider.applyPersonaPreferredSettings(persona);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
    if (mounted) setState(() => _startingChat = false);
  }

  static bool _isPackAvatar(String? path) {
    if (path == null) return false;
    return path.contains('persona_pack_') ||
        path.contains('assets/images/persona_pack');
  }

  @override
  Widget build(BuildContext context) {
    final persona = _livePersona(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final palette = PersonaPalette.cachedOf(persona);
    final accent = persona.color != null
        ? Color(persona.color!)
        : (palette?.primary ?? cs.primary);
    final secondary = palette?.secondary ??
        Color.lerp(accent, const Color(0xFF2B6CFF), 0.45)!;
    final avatarPath =
        ImagePickerHelper.resolveImagePathSync(persona.avatarPath);
    final pack = _isPackAvatar(persona.avatarPath);
    final prompt = persona.content.trim();

    final tags = <String>[
      if (persona.defaultModelId != null) persona.defaultModelId!,
      if (persona.kokoroSpeakerId != null) 'Voice',
      if (persona.shareMemories && SubscriptionService().isPremium) 'Memory',
    ];

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final portraitH = (constraints.maxHeight - 48).clamp(280.0, 720.0);
          final portraitW = portraitH * (9 / 16);

          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: portraitW.clamp(180.0, constraints.maxWidth * 0.42),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: isDark ? 0.35 : 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _PortraitArt(
                            path: avatarPath,
                            accent: accent,
                            isPackArt: pack,
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _PaletteEdgeWashPainter(
                                primary: accent,
                                secondary: secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                persona.name,
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.edit,
                              onPressed: () => SystemPromptEditorScreen.open(
                                context,
                                prompt: persona,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Persona',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Role & Purpose',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prompt.isEmpty ? 'No system prompt yet.' : prompt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            color: cs.onSurface.withValues(alpha: 0.88),
                          ),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Skills & Tone',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in tags)
                                _TagPill(label: tag, color: accent),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _startingChat ? null : _startChat,
                            style: FilledButton.styleFrom(
                              foregroundColor:
                                  Colors.black.withValues(alpha: 0.88),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _startingChat
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Chat Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TagPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.85),
            ),
      ),
    );
  }
}

/// Soft palette glow on edges — matches phone [PersonaProfileScreen].
class _PaletteEdgeWashPainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  _PaletteEdgeWashPainter({
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    void wash(Alignment begin, Alignment end, Color color, double alpha) {
      final paint = Paint()
        ..shader = LinearGradient(
          begin: begin,
          end: end,
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.28),
            Colors.transparent,
          ],
          stops: const [0, 0.12, 0.55],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }

    wash(Alignment.topCenter, const Alignment(0, -0.2), primary, 0.5);
    wash(Alignment.bottomCenter, const Alignment(0, 0.2), secondary, 0.45);
    wash(Alignment.centerLeft, const Alignment(-0.2, 0), primary, 0.32);
    wash(Alignment.centerRight, const Alignment(0.2, 0), secondary, 0.32);

    final inset = rect.deflate(2);
    final rrect = RRect.fromRectAndRadius(inset, const Radius.circular(22));
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.28),
          secondary.withValues(alpha: 0.65),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, rim);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.28),
          secondary.withValues(alpha: 0.22),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, glow);
  }

  @override
  bool shouldRepaint(covariant _PaletteEdgeWashPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}
