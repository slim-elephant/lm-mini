import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../models/memory_category.dart';
import '../models/system_prompt.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/persona_analytics_service.dart';
import '../utils/avatar_palette.dart';
import '../utils/image_picker_helper.dart';
import '../utils/kokoro_speaker_resolver.dart';
import '../utils/remote_host_backends.dart';
import '../utils/persona_palette.dart';
import '../utils/layout_utils.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/persona_avatar.dart';
import 'avatar_focus_screen.dart';
import 'chat_screen.dart';
import 'memory_screen.dart';
import 'subscription_screen.dart';
import 'system_prompts_screen.dart';
import '../widgets/glass_blur.dart';

part '../pro/personas/persona_profile_pro.dart';

/// Full-bleed glass persona profile: avatar BG, meta, analytics strip, composer.
class PersonaProfileScreen extends StatefulWidget {
  final SystemPrompt persona;

  /// When true, render as an inset portrait (Mac/iPad dialog) with close.
  final bool dialogMode;

  const PersonaProfileScreen({
    super.key,
    required this.persona,
    this.dialogMode = false,
  });

  static Future<void> open(BuildContext context, SystemPrompt persona) {
    if (prefersWideSettingsLayout(context)) {
      return showAdaptiveModal<void>(
        context: context,
        dialogMaxWidth: 440,
        dialogMaxHeightFraction: 0.92,
        backgroundColor: Colors.black,
        dialogBorderRadius: BorderRadius.circular(28),
        builder: (_) => PersonaProfileScreen(
          persona: persona,
          dialogMode: true,
        ),
      );
    }
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonaProfileScreen(persona: persona),
      ),
    );
  }

  @override
  State<PersonaProfileScreen> createState() => _PersonaProfileScreenState();
}

class _PersonaProfileScreenState extends State<PersonaProfileScreen> {
  final _composer = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  late AvatarPalette _palette;
  bool _palettePersistInFlight = false;

  /// Avoid scheduling palette extraction on every rebuild when no cache exists.
  bool _paletteEnsureScheduled = false;

  SystemPrompt _livePersona(BuildContext context, {bool listen = false}) {
    final settings = listen
        ? context.watch<SettingsProvider>().settings
        : context.read<SettingsProvider>().settings;
    final prompts = settings.savedSystemPrompts ?? const <SystemPrompt>[];
    for (final p in prompts) {
      if (p.id == widget.persona.id) return p;
    }
    return widget.persona;
  }

  @override
  void initState() {
    super.initState();
    // Prefer already-saved frame colors so the first frame isn't the blue fallback.
    final seed = widget.persona;
    final accent = seed.color != null
        ? Color(seed.color!)
        : AvatarPalette.fallback.primary;
    _palette = PersonaPalette.fallbackFor(seed, accent);
    PersonaAnalyticsService.instance.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePaletteCached());
  }

  @override
  void dispose() {
    _composer.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ensurePaletteCached() async {
    if (!mounted || _palettePersistInFlight) return;
    final persona = _livePersona(context, listen: false);
    final cached = PersonaPalette.cachedOf(persona);
    if (cached != null) {
      if (_palette.primary != cached.primary ||
          _palette.secondary != cached.secondary) {
        setState(() => _palette = cached);
      }
      return;
    }

    _palettePersistInFlight = true;
    try {
      final withPalette = await PersonaPalette.ensureCached(persona);
      if (!mounted) return;
      final next = PersonaPalette.cachedOf(withPalette);
      if (next != null) {
        setState(() => _palette = next);
      }
      // Persist only when we newly extracted colors.
      if (withPalette.palettePrimary != persona.palettePrimary ||
          withPalette.paletteSecondary != persona.paletteSecondary) {
        context.read<SettingsProvider>().updateSavedSystemPrompt(withPalette);
      }
    } finally {
      _palettePersistInFlight = false;
    }
  }

  Future<void> _startChatWithMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    setState(() => _sending = true);

    final settingsProvider = context.read<SettingsProvider>();
    final persona = _livePersona(context, listen: false);
    await settingsProvider.loadSettings();
    if (!mounted) return;

    await settingsProvider.applyPersonaPreferredSettings(persona);

    if (!mounted) return;
    if (widget.dialogMode) {
      Navigator.of(context).pop(); // close portrait dialog
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(initialSendMessage: trimmed),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(initialSendMessage: trimmed),
        ),
      );
    }
  }

  void _openEdit() {
    SystemPromptEditorScreen.open(
      context,
      prompt: _livePersona(context, listen: false),
    );
  }

  Future<void> _adjustFaceFocus() async {
    final persona = _livePersona(context, listen: false);
    final path = ImagePickerHelper.resolveImagePathSync(persona.avatarPath);
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an avatar first to choose a face.')),
      );
      return;
    }
    final result = await AvatarFocusScreen.open(
      context,
      imagePath: path,
      initialAlignment: PersonaAvatar.alignmentFromFocus(
        persona.avatarFocusX,
        persona.avatarFocusY,
      ),
      initialScale: PersonaAvatar.scaleFromFocus(persona.avatarFocusScale,
          fallback: 1.35),
    );
    if (result == null || !mounted) return;
    final updated = persona.copyWith(
      avatarFocusX: result.x,
      avatarFocusY: result.y,
      avatarFocusScale: result.scale,
      updatedAt: DateTime.now(),
    );
    context.read<SettingsProvider>().updateSavedSystemPrompt(updated);
  }

  /// Pack / generated avatars are square character busts — use contain hero.
  static bool _isPackAvatar(String? path) {
    if (path == null) return false;
    return path.contains('persona_pack_') ||
        path.contains('assets/images/persona_pack');
  }

  @override
  Widget build(BuildContext context) {
    final persona = _livePersona(context, listen: true);
    final avatarPath =
        ImagePickerHelper.resolveImagePathSync(persona.avatarPath);
    final cached = PersonaPalette.cachedOf(persona);
    if (cached != null &&
        (cached.primary != _palette.primary ||
            cached.secondary != _palette.secondary)) {
      _palette = cached;
    } else if (cached == null && !_paletteEnsureScheduled) {
      _paletteEnsureScheduled = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ensurePaletteCached());
    }

    final accent =
        persona.color != null ? Color(persona.color!) : _palette.primary;
    final dialog = widget.dialogMode;
    final top = dialog ? 12.0 : MediaQuery.paddingOf(context).top;
    final bottom = dialog ? 12.0 : MediaQuery.paddingOf(context).bottom;
    final glass = _GlassTheme.fromPalette(_palette);

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        if (avatarPath != null)
          _PersonaHeroBackdrop(
            path: avatarPath,
            accent: accent,
            isPackArt: _isPackAvatar(persona.avatarPath),
          )
        else
          _FallbackBg(accent: accent),

        // Light vignette only — dialog portrait stays visual-first.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: dialog ? 0.2 : 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: dialog ? 0.2 : 0.35),
                Colors.black.withValues(alpha: dialog ? 0.55 : 0.82),
              ],
              stops: const [0, 0.28, 0.55, 1],
            ),
          ),
        ),

        if (!dialog)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PaletteEdgeWashPainter(
                  primary: _palette.primary,
                  secondary: _palette.secondary,
                ),
              ),
            ),
          ),

        if (!dialog)
          Positioned(
            right: 12,
            top: top + 88,
            bottom: bottom + 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: _proAnalyticsStrip(context, persona.id, glass),
            ),
          ),

        Positioned(
          left: 18,
          right: dialog ? 18 : 88,
          top: top + (dialog ? 48 : 64),
          bottom: bottom + (dialog ? 72 : 88),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: dialog
                ? _DialogPersonaCaption(
                    name: persona.name,
                    accent: accent,
                  )
                : _PersonaMeta(
                    persona: persona,
                    accent: accent,
                    glass: glass,
                  ),
          ),
        ),

        Positioned(
          left: 14,
          right: 14,
          bottom: bottom + (dialog ? 8 : 12),
          child: dialog
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _openEdit,
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _startChatWithMessage('Hi'),
                        child: const Text('Chat'),
                      ),
                    ),
                  ],
                )
              : _GlassComposer(
                  glass: glass,
                  controller: _composer,
                  focusNode: _focus,
                  sending: _sending,
                  onSend: () => _startChatWithMessage(_composer.text),
                ),
        ),

        Positioned(
          top: top + (dialog ? 4 : 8),
          left: 14,
          right: 14,
          child: Row(
            children: [
              _GlassCircle(
                glass: glass,
                icon: dialog
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              if (avatarPath != null && !dialog) ...[
                _GlassCircle(
                  glass: glass,
                  icon: Icons.face_retouching_natural_rounded,
                  onTap: _adjustFaceFocus,
                ),
                const SizedBox(width: 10),
              ],
              if (!dialog)
                _GlassCircle(
                  glass: glass,
                  icon: Icons.edit_rounded,
                  onTap: _openEdit,
                ),
            ],
          ),
        ),
      ],
    );

    if (dialog) {
      return Material(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 3 / 4.2,
          child: stack,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: stack,
    );
  }
}

class _DialogPersonaCaption extends StatelessWidget {
  final String name;
  final Color accent;

  const _DialogPersonaCaption({
    required this.name,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            shadows: const [
              Shadow(blurRadius: 12, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _GlassTheme {
  final Color fill;
  final Color fillStrong;
  final Color border;
  final Color highlight;

  const _GlassTheme({
    required this.fill,
    required this.fillStrong,
    required this.border,
    required this.highlight,
  });

  factory _GlassTheme.fromPalette(AvatarPalette palette) {
    // Heavy white mix so accents tint frost, not paint mud over the photo.
    final tint = Color.lerp(palette.primary, palette.secondary, 0.4)!;
    final frost = Color.lerp(tint, Colors.white, 0.55)!;
    return _GlassTheme(
      fill: frost.withValues(alpha: 0.38),
      fillStrong:
          Color.lerp(frost, Colors.white, 0.12)!.withValues(alpha: 0.48),
      border: Color.lerp(tint, Colors.white, 0.7)!.withValues(alpha: 0.62),
      highlight: Color.lerp(palette.secondary, Colors.white, 0.55)!
          .withValues(alpha: 0.32),
    );
  }
}

/// Soft palette glow on all four edges (not just the top).
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
          // Fade out sooner so the wash stays nearer the edges.
          stops: const [0, 0.1, 0.6],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }

    // ~15% less inward reach than edge→center.
    wash(Alignment.topCenter, const Alignment(0, -0.15), primary, 0.55);
    wash(Alignment.bottomCenter, const Alignment(0, 0.15), secondary, 0.5);
    wash(Alignment.centerLeft, const Alignment(-0.15, 0), primary, 0.38);
    wash(Alignment.centerRight, const Alignment(0.15, 0), secondary, 0.38);

    // Soft rounded rim
    final inset = rect.deflate(3);
    final rrect = RRect.fromRectAndRadius(inset, const Radius.circular(26));
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.35),
          secondary.withValues(alpha: 0.7),
          primary.withValues(alpha: 0.55),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, rim);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.32),
          secondary.withValues(alpha: 0.26),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, glow);
  }

  @override
  bool shouldRepaint(covariant _PaletteEdgeWashPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}

/// Full-bleed hero: blurred fill + contained portrait for square pack art.
class _PersonaHeroBackdrop extends StatelessWidget {
  final String path;
  final Color accent;
  final bool isPackArt;

  const _PersonaHeroBackdrop({
    required this.path,
    required this.accent,
    required this.isPackArt,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final fallback = _FallbackBg(accent: accent);

    if (!isPackArt) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.2),
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft blurred wash from the same art (avoids harsh cover crop).
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: Transform.scale(
            scale: 1.18,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => fallback,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: 0.22),
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        // Full character bust centered (no midriff crop).
        SafeArea(
          bottom: false,
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 56, 12, 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackBg extends StatelessWidget {
  final Color accent;
  const _FallbackBg({required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.85),
            const Color(0xFF1A1428),
            accent.withValues(alpha: 0.45),
          ],
        ),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  final _GlassTheme glass;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassCircle({
    required this.glass,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: GlassBlur(
        sigmaX: 28,
        sigmaY: 28,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [glass.fillStrong, glass.fill],
                ),
                border: Border.all(color: glass.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: glass.highlight,
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonaMeta extends StatefulWidget {
  final SystemPrompt persona;
  final Color accent;
  final _GlassTheme glass;

  const _PersonaMeta({
    required this.persona,
    required this.accent,
    required this.glass,
  });

  @override
  State<_PersonaMeta> createState() => _PersonaMetaState();
}

class _PersonaMetaState extends State<_PersonaMeta> {
  static const int _collapsedLines = 5;
  bool _expanded = false;
  final _promptScroll = ScrollController();

  @override
  void dispose() {
    _promptScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PersonaMeta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.persona.id != widget.persona.id ||
        oldWidget.persona.content != widget.persona.content) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final persona = widget.persona;
    final accent = widget.accent;
    final glass = widget.glass;
    final voice = persona.kokoroSpeakerId != null
        ? KokoroSpeakerResolver.displayName(persona.kokoroSpeakerId!)
        : null;
    final model = persona.defaultModelId;
    final memoryCount = MemoryService().countForPersona(persona.id);
    final prompt = persona.content.trim().isEmpty
        ? 'No prompt yet'
        : persona.content.trim();

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final style = TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w500,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 8),
          ],
        );
        final painter = TextPainter(
          text: TextSpan(text: prompt, style: style),
          maxLines: _collapsedLines,
          textDirection: TextDirection.ltr,
          ellipsis: '…',
        )..layout(maxWidth: outerConstraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        // Cap expanded height so the block stays bottom-anchored (no Expanded
        // jump) and long prompts scroll inside this box.
        final expandedMaxH =
            (outerConstraints.maxHeight * 0.42).clamp(120.0, 240.0);

        final Widget promptBody;
        if (_expanded) {
          promptBody = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: expandedMaxH),
            child: Scrollbar(
              controller: _promptScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _promptScroll,
                child: Text(prompt, style: style),
              ),
            ),
          );
        } else {
          promptBody = Text(
            prompt,
            maxLines: _collapsedLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              persona.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.15,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 8),
            promptBody,
            if (overflows || _expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded
                        ? AppLocalizations.of(context).showLess
                        : AppLocalizations.of(context).readMore,
                    style: TextStyle(
                      color: Color.lerp(accent, Colors.white, 0.35),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  glass: glass,
                  icon: Icons.circle,
                  iconColor: accent,
                  label: 'Color',
                ),
                if (voice != null)
                  _MetaChip(
                    glass: glass,
                    icon: Icons.record_voice_over_rounded,
                    label: voice,
                  ),
                if (model != null && model.isNotEmpty)
                  _MetaChip(
                    glass: glass,
                    icon: Icons.memory_rounded,
                    label: model.split('/').last,
                  ),
                if (persona.defaultProviderKind != null)
                  _MetaChip(
                    glass: glass,
                    icon: Icons.dns_outlined,
                    label: RemoteHostBackends.displayName(
                        persona.defaultProviderKind!),
                  ),
                if (memoryCount > 0)
                  _MetaChip(
                    glass: glass,
                    icon: memoryScopeIcon(persona.memoryWriteScope),
                    label: AppLocalizations.of(context)
                        .memoryCountForPersona(memoryCount),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MemoryScreen(),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final _GlassTheme glass;
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _MetaChip({
    required this.glass,
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: GlassBlur(
        sigmaX: 22,
        sigmaY: 22,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [glass.fillStrong, glass.fill],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: glass.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor ?? Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded,
                    size: 14, color: Colors.white70),
              ],
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    );
  }
}

class _GlassComposer extends StatelessWidget {
  final _GlassTheme glass;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _GlassComposer({
    required this.glass,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: GlassBlur(
              sigmaX: 32,
              sigmaY: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [glass.fillStrong, glass.fill],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: glass.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: glass.highlight,
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !sending,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: Colors.white,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Message this persona…',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ClipOval(
          child: GlassBlur(
            sigmaX: 28,
            sigmaY: 28,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: sending ? null : onSend,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [glass.fillStrong, glass.fill],
                    ),
                    border: Border.all(color: glass.border),
                  ),
                  child: sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
