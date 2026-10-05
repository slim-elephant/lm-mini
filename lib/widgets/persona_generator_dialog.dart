import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/arena_models.dart';
import '../models/system_prompt.dart';
import '../providers/settings_provider.dart';
import '../services/on_device_llm_service.dart';
import '../services/persona_generator_service.dart';
import 'persona_save_options_dialog.dart';
import 'provider_model_setup_dialog.dart';
import 'glass_blur.dart';

/// Ask the loaded model to invent a persona, preview it, then save.
class PersonaGeneratorDialog extends StatefulWidget {
  const PersonaGeneratorDialog({super.key});

  /// Returns the saved [SystemPrompt], or null if cancelled.
  static Future<SystemPrompt?> show(BuildContext context) {
    return showGeneralDialog<SystemPrompt>(
      context: context,
      barrierDismissible: false,
      barrierLabel: AppLocalizations.of(context).promptPersonaGenerator,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => const PersonaGeneratorDialog(),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PersonaGeneratorDialog> createState() => _PersonaGeneratorDialogState();
}

class _PersonaGeneratorDialogState extends State<PersonaGeneratorDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  GeneratedPersonaDraft? _draft;
  bool _busy = false;
  String? _error;

  /// Local thinking override for this dialog (LM Studio reasoning models).
  bool? _thinkingEnabled;

  /// True when the current draft came from Surprise me (so Regenerate
  /// picks a new random seed instead of reusing the filled-in text).
  bool _lastWasSurprise = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDescriptionEdited);
  }

  void _onDescriptionEdited() {
    // Manual edits mean Regenerate should reuse the typed prompt, not
    // roll another surprise seed.
    if (_lastWasSurprise && !_busy) {
      _lastWasSurprise = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onDescriptionEdited);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _hasUsableModel(SettingsProvider sp) {
    final s = sp.settings;
    final kind = s.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      return (s.selectedLocalModelId ?? '').isNotEmpty;
    }
    return (s.selectedModel ?? '').isNotEmpty && s.serverUrl.trim().isNotEmpty;
  }

  String _modelDisplayName(SettingsProvider sp) {
    final s = sp.settings;
    final kind = s.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      final id = s.selectedLocalModelId ?? '';
      if (id.isEmpty) return 'No model selected';
      return id.split('/').last;
    }
    final id = s.selectedModel ?? '';
    if (id.isEmpty) return 'No model selected';
    final resolved = sp.resolveLmStudioModel(id) ?? sp.findModelById(id);
    return resolved?.displayName ?? id.split('/').last;
  }

  bool _modelLooksLikeReasoning(SettingsProvider sp) {
    final s = sp.settings;
    final kind = s.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      final id = s.selectedLocalModelId ?? '';
      return ArenaContestant.looksLikeReasoningModel(id);
    }
    if (kind != 'lmStudio') {
      final id = s.selectedModel ?? '';
      return ArenaContestant.looksLikeReasoningModel(id);
    }
    final id = s.selectedModel ?? '';
    if (id.isEmpty) return false;
    final resolved = sp.resolveLmStudioModel(id) ?? sp.findModelById(id);
    if (resolved != null) {
      if (resolved.isReasoningModel) return true;
      return ArenaContestant.looksLikeReasoningModel(
        resolved.id,
        resolved.displayName,
      );
    }
    return ArenaContestant.looksLikeReasoningModel(id);
  }

  bool _effectiveThinking(SettingsProvider sp) {
    if (_thinkingEnabled != null) return _thinkingEnabled!;
    return sp.settings.isReasoningEnabled;
  }

  Future<bool> _ensureReady(SettingsProvider sp) async {
    if (!_hasUsableModel(sp)) {
      final ok = await showProviderModelSetupDialog(context, sp);
      if (!ok || !_hasUsableModel(sp)) return false;
    }

    final s = sp.settings;
    if (s.activeProviderKind == 'onDeviceGguf' ||
        s.activeProviderKind == 'onDeviceMlx') {
      final ready = await OnDeviceLLMService.instance.isReady(s);
      if (!ready) {
        setState(() {
          _error =
              'No on-device model is ready. Download one in Settings → On-Device Models.';
        });
        return false;
      }
      return true;
    }

    if (s.activeProviderKind == 'lmStudio') {
      final modelId = s.selectedModel ?? '';
      if (modelId.isEmpty) return false;
      final prepared = await sp.prepareModelForLmStudioUse(
        modelId,
        uiContext: context,
      );
      if (!prepared) return false;
      final model =
          sp.resolveLmStudioModel(modelId) ?? sp.findModelById(modelId);
      final loadKey = model?.id ?? modelId;
      if (model == null || !model.isLoaded) {
        final loaded = await sp.loadSpecificModel(loadKey, uiContext: context);
        if (!loaded) {
          setState(() {
            _error = sp.connectionError ??
                'Could not load the selected model in LM Studio.';
          });
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _generate({bool random = false}) async {
    final surprise = random;
    if (surprise) {
      _lastWasSurprise = true;
    } else {
      _lastWasSurprise = false;
    }

    final text = _controller.text.trim();
    if (!surprise && text.isEmpty) {
      setState(() => _error = 'Describe the kind of persona you want.');
      return;
    }

    final previousHint = surprise && _draft != null
        ? '${_draft!.name}: ${_draft!.shortBio}'
        : null;

    final sp = context.read<SettingsProvider>();
    final showThinking = _modelLooksLikeReasoning(sp);
    final thinkingOn = showThinking ? _effectiveThinking(sp) : false;
    setState(() {
      _busy = true;
      _error = null;
      _draft = null;
    });

    try {
      final ready = await _ensureReady(sp);
      if (!ready) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      final draft = await PersonaGeneratorService.instance.generate(
        settings: sp.settings,
        userDescription: text,
        reasoningEnabled: thinkingOn,
        surprise: surprise,
        avoidPersonaHint: previousHint,
      );
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Exception: ', '')
            .replaceFirst('FormatException: ', '');
      });
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;

    final options = await PersonaSaveOptionsDialog.show(
      context,
      initialName: draft.name,
      initialSpeakerId: draft.kokoroSpeakerId,
    );
    if (!mounted || options == null) return;

    final sp = context.read<SettingsProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final prompt = await PersonaGeneratorService.instance.saveDraft(
        draft: draft,
        settingsProvider: sp,
        selectAfterSave: true,
        name: options.name,
        kokoroSpeakerId: options.kokoroSpeakerId,
        color: options.accentColor?.toARGB32(),
        useAutoColor: options.accentColor == null,
        defaultModelId: options.defaultModelId,
        defaultProviderKind: options.defaultProviderKind,
        defaultCloudProviderId: options.defaultCloudProviderId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(prompt);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final draft = _draft;
    final maxH = MediaQuery.sizeOf(context).height * 0.86;
    final sp = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final modelName = _modelDisplayName(sp);
    final showThinkingToggle = _modelLooksLikeReasoning(sp);
    final thinkingOn = _effectiveThinking(sp);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 440, maxHeight: maxH),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: GlassBlur(
                sigmaX: 28,
                sigmaY: 28,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF2A2140).withValues(alpha: 0.94),
                              const Color(0xFF16121F).withValues(alpha: 0.96),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.96),
                              const Color(0xFFF3EEFF).withValues(alpha: 0.96),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogHeader(
                        isDark: isDark,
                        onClose:
                            _busy ? null : () => Navigator.of(context).pop(),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Describe who you want to chat with. Your loaded '
                                'AI writes the prompt and picks a matching avatar.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _controller,
                                focusNode: _focus,
                                enabled: !_busy,
                                minLines: 2,
                                maxLines: 4,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _generate(),
                                decoration: InputDecoration(
                                  hintText:
                                      'e.g. a witty pirate captain who teaches history',
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.03),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: cs.outline.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: cs.outline.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: cs.primary,
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ModelThinkingRow(
                                modelName: modelName,
                                showThinkingToggle: showThinkingToggle,
                                thinkingOn: thinkingOn,
                                enabled: !_busy,
                                thinkingLabel: l10n.thinking,
                                onChanged: (v) =>
                                    setState(() => _thinkingEnabled = v),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: cs.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              if (_busy) ...[
                                const SizedBox(height: 28),
                                Center(
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 12),
                                      Text(AppLocalizations.of(context)
                                          .craftingPersona),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (!_busy && draft != null) ...[
                                const SizedBox(height: 16),
                                _DraftPreview(draft: draft, isDark: isDark),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context).cancel),
                            ),
                            const Spacer(),
                            if (draft == null) ...[
                              TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _generate(random: true),
                                icon:
                                    const Icon(Icons.casino_outlined, size: 18),
                                label: Text(
                                    AppLocalizations.of(context).randomPersona),
                              ),
                              const SizedBox(width: 6),
                              FilledButton.icon(
                                onPressed: _busy ? null : _generate,
                                icon: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                ),
                                label:
                                    Text(AppLocalizations.of(context).generate),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _generate(random: _lastWasSurprise),
                                child: Text(
                                    AppLocalizations.of(context).regenerate),
                              ),
                              const SizedBox(width: 6),
                              FilledButton.icon(
                                onPressed: _busy ? null : _save,
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                    AppLocalizations.of(context).savePersona),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onClose;

  const _DialogHeader({required this.isDark, this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.28),
                  Colors.transparent,
                ]
              : [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.14),
                  Colors.transparent,
                ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.18),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF7C4DFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.promptPersonaGenerator,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: l10n.close,
          ),
        ],
      ),
    );
  }
}

class _DraftPreview extends StatelessWidget {
  final GeneratedPersonaDraft draft;
  final bool isDark;

  const _DraftPreview({required this.draft, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  draft.avatar.assetPath,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      draft.shortBio,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(
                          icon: Icons.record_voice_over_rounded,
                          label: draft.gender == 'female' ? 'Bella' : 'Adam',
                        ),
                        _MiniChip(
                          icon: Icons.face_rounded,
                          label: draft.avatar.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).systemPromptLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          _ExpandableSystemPrompt(
            text: draft.systemPrompt,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ExpandableSystemPrompt extends StatefulWidget {
  final String text;
  final bool isDark;

  const _ExpandableSystemPrompt({
    required this.text,
    required this.isDark,
  });

  @override
  State<_ExpandableSystemPrompt> createState() =>
      _ExpandableSystemPromptState();
}

class _ExpandableSystemPromptState extends State<_ExpandableSystemPrompt> {
  static const int _collapsedLines = 7;
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _ExpandableSystemPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.35,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final showToggle = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : _collapsedLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: style,
            ),
            if (showToggle)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? l10n.showLess : l10n.readMore,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.primary.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelThinkingRow extends StatelessWidget {
  final String modelName;
  final bool showThinkingToggle;
  final bool thinkingOn;
  final bool enabled;
  final String thinkingLabel;
  final ValueChanged<bool> onChanged;

  const _ModelThinkingRow({
    required this.modelName,
    required this.showThinkingToggle,
    required this.thinkingOn,
    required this.enabled,
    required this.thinkingLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            modelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        if (showThinkingToggle) ...[
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                thinkingLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 28,
                child: Transform.scale(
                  scale: 0.78,
                  alignment: Alignment.center,
                  child: Switch.adaptive(
                    value: thinkingOn,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
