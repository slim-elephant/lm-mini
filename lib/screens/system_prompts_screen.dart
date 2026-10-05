import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import '../l10n/app_localizations.dart';
import '../models/local_model_spec.dart';
import '../models/lm_studio_model.dart';
import '../models/memory_category.dart';
import '../models/param_preset.dart';
import '../models/system_prompt.dart';
import '../providers/settings_provider.dart';
import '../services/builtin_persona_service.dart';
import '../services/comfyui_service.dart';
import '../services/local_model_download_service.dart';
import '../services/persona_memory_service.dart';
import '../utils/image_picker_helper.dart';
import '../utils/kokoro_speaker_resolver.dart';
import '../utils/persona_model_label.dart';
import '../utils/persona_palette.dart';
import '../utils/tts_engine.dart';
import '../services/kokoro_tts_service.dart';
import '../services/elevenlabs_tts_service.dart';
import '../services/grok_tts_service.dart';
import '../utils/comfyui_catalog.dart';
import '../utils/layout_utils.dart';
import '../utils/param_preset_key.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_page_header.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/home_glass_header.dart';
import '../widgets/persona_avatar.dart';
import '../widgets/persona_generator_dialog.dart';
import '../widgets/persona_portrait_card.dart';
import '../widgets/model_parameters_form.dart';
import '../widgets/pro_badge.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'avatar_focus_screen.dart';
import 'persona_profile_screen.dart';
import 'subscription_screen.dart';
import '../pro/pro_features.dart';

part '../pro/personas/persona_editor_pro.dart';

Widget _promptsSoftCard(
  BuildContext context, {
  required Widget child,
  bool selected = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      color: isDark
          ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
          : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: selected
            ? cs.primary
            : cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        width: selected ? 2 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

Widget _promptsSectionLabel(BuildContext context, String title) {
  return Text(
    title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
  );
}

InputDecoration _promptsFieldDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
  Widget? prefixIcon,
  bool alignLabelWithHint = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: cs.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.55),
    ),
  );
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: isDark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
        : cs.surface.withValues(alpha: 0.9),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
  );
}

class SystemPromptsScreen extends StatefulWidget {
  /// When true, opens the new prompt/persona editor once after the screen loads.
  final bool openNewPersona;
  final bool embedded;
  const SystemPromptsScreen({
    super.key,
    this.openNewPersona = false,
    this.embedded = false,
  });

  @override
  State<SystemPromptsScreen> createState() => _SystemPromptsScreenState();
}

class _SystemPromptsScreenState extends State<SystemPromptsScreen> {
  /// Prevents re-pushing the editor on every rebuild (e.g. keyboard insets).
  bool _didAutoOpenNewPersona = false;

  @override
  void initState() {
    super.initState();
    if (widget.openNewPersona) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didAutoOpenNewPersona) return;
        _didAutoOpenNewPersona = true;
        _showPromptEditor(context);
      });
    }
  }

  Future<void> _openPersonaGenerator(BuildContext context) async {
    final prompt = await PersonaGeneratorDialog.show(context);
    if (prompt == null || !context.mounted) return;
    await PersonaProfileScreen.open(context, prompt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topBg = isDark ? const Color(0xFF1A202E) : const Color(0xFF243044);
    final headerH = GlassPageHeader.heightFor(context);
    final cs = theme.colorScheme;
    final embedded = widget.embedded;

    final generatorAction = GlassCircleIconButton(
      tooltip: l10n.promptPersonaGenerator,
      onTap: () => _openPersonaGenerator(context),
      onLightCanvas: embedded ? true : null,
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 22,
        color: embedded
            ? (isDark ? Colors.white : Colors.black.withValues(alpha: 0.88))
            : Colors.white,
      ),
    );
    final fab = GlassCircleIconButton(
      size: 58,
      tooltip: l10n.addSystemPromptTooltip,
      isActive: true,
      prominent: true,
      onLightCanvas: !isDark,
      onTap: () => _showPromptEditor(context),
      child: Icon(
        Icons.add_rounded,
        size: 28,
        color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.88),
      ),
    );

    final content = Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final prompts = (settingsProvider.settings.savedSystemPrompts ?? [])
            .where((p) => p.id != BuiltinPersonaService.defaultPersonaId)
            .toList();
        final selectedId = settingsProvider.settings.selectedSystemPromptId;
        final defaultPersona =
            (settingsProvider.settings.savedSystemPrompts ?? [])
                .where((p) => p.id == BuiltinPersonaService.defaultPersonaId);
        final inlinePrompt = defaultPersona.isNotEmpty
            ? defaultPersona.first.content
            : settingsProvider.settings.systemPrompt;
        final wide = prefersWideSettingsLayout(context);
        final personas = prompts.where((p) => p.isPersona).toList();
        final plainPrompts = prompts.where((p) => !p.isPersona).toList();

        final desktop = prefersWideSettingsLayout(context);
        return ListView(
          padding: EdgeInsets.fromLTRB(
            desktop ? 4 : 16,
            desktop ? 12 : 20,
            desktop ? 4 : 16,
            100,
          ),
          children: [
            DesktopSettingsForm(
              maxWidth: desktop ? 640 : double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.systemPromptsInfoText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _promptsSoftCard(
                    context,
                    child: InkWell(
                      onTap: () => _openPersonaGenerator(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: cs.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.promptPersonaGenerator,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _promptsSectionLabel(context, l10n.defaultPrompt),
                  const SizedBox(height: 10),
                  _InlinePromptCard(
                    isSelected: BuiltinPersonaService.isDefaultId(selectedId),
                    currentPrompt: inlinePrompt,
                    onSelect: () => settingsProvider.selectSystemPrompt(null),
                    onEdit: () =>
                        _showInlinePromptEditor(context, inlinePrompt),
                  ),
                ],
              ),
            ),
            if (personas.isNotEmpty) ...[
              const SizedBox(height: 22),
              _promptsSectionLabel(context, l10n.savedPromptsSection),
              const SizedBox(height: 10),
              if (wide)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    // Fill the detail pane — more columns as width grows.
                    final cols = w >= 1400
                        ? 5
                        : w >= 1100
                            ? 4
                            : w >= 720
                                ? 3
                                : 2;
                    const spacing = 16.0;
                    final tileW = (w - spacing * (cols - 1)) / cols;
                    final tileH = tileW * 1.38;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final prompt in personas)
                          SizedBox(
                            width: tileW,
                            height: tileH,
                            child: PersonaPortraitCard(
                              prompt: prompt,
                              isSelected: selectedId == prompt.id,
                              onSelect: () => settingsProvider
                                  .selectSystemPrompt(prompt.id),
                              onView: () =>
                                  PersonaProfileScreen.open(context, prompt),
                              onEdit: () =>
                                  _showPromptEditor(context, prompt: prompt),
                              onDuplicate: () => settingsProvider
                                  .duplicateSystemPrompt(prompt.id),
                              onDelete: () => _confirmDelete(context, prompt),
                            ),
                          ),
                      ],
                    );
                  },
                )
              else
                ...personas.map(
                  (prompt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SystemPromptCard(
                      prompt: prompt,
                      isSelected: selectedId == prompt.id,
                      onSelect: () =>
                          settingsProvider.selectSystemPrompt(prompt.id),
                      onView: () => PersonaProfileScreen.open(context, prompt),
                      onEdit: () => _showPromptEditor(context, prompt: prompt),
                      onDuplicate: () =>
                          settingsProvider.duplicateSystemPrompt(prompt.id),
                      onDelete: () => _confirmDelete(context, prompt),
                    ),
                  ),
                ),
            ],
            if (plainPrompts.isNotEmpty) ...[
              const SizedBox(height: 22),
              _promptsSectionLabel(context, 'System prompts'),
              const SizedBox(height: 10),
              ...plainPrompts.map(
                (prompt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SystemPromptCard(
                    prompt: prompt,
                    isSelected: selectedId == prompt.id,
                    onSelect: () =>
                        settingsProvider.selectSystemPrompt(prompt.id),
                    onView: () => PersonaProfileScreen.open(context, prompt),
                    onEdit: () => _showPromptEditor(context, prompt: prompt),
                    onDuplicate: () =>
                        settingsProvider.duplicateSystemPrompt(prompt.id),
                    onDelete: () => _confirmDelete(context, prompt),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );

    if (embedded) {
      return Scaffold(
        backgroundColor: cs.surface,
        floatingActionButton: fab,
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
                        l10n.systemPromptsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    generatorAction,
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: topBg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(headerH),
        child: GlassPageHeader(
          title: l10n.systemPromptsTitle,
          onBack: () => Navigator.of(context).maybePop(),
          actions: [generatorAction],
        ),
      ),
      floatingActionButton: fab,
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
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  void _showInlinePromptEditor(BuildContext context, String currentPrompt) {
    final controller = TextEditingController(text: currentPrompt);
    final settingsProvider = context.read<SettingsProvider>();

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit),
              const SizedBox(width: 12),
              Text(l10n.defaultPrompt),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              maxLines: 8,
              minLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.systemPromptEditorHint,
                labelText: l10n.systemPromptLabel,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                settingsProvider.updateSystemPrompt(controller.text);
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _showPromptEditor(BuildContext context, {SystemPrompt? prompt}) {
    // Always push with chrome — editor is a full route, not a settings pane.
    SystemPromptEditorScreen.open(context, prompt: prompt);
  }

  void _confirmDelete(BuildContext context, SystemPrompt prompt) async {
    // First, check if any memories are bound to this persona. When persona
    // scoping is enabled, we ask the user whether to reassign or delete them.
    final assignments = PersonaMemoryService.instance;
    await assignments.load();
    final memoryCount = assignments.countForPersona(prompt.id);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteSystemPromptTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteSystemPromptMessage(prompt.name)),
              if (memoryCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.personaMemoriesAssignedHint(memoryCount, prompt.name),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            if (memoryCount > 0)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final target = await _pickReassignTarget(context, prompt);
                  if (target == null) return;
                  await assignments.reassignMemoriesForDeletedPersona(
                    prompt.id,
                    reassignTo: target == '__global__' ? null : target,
                  );
                  if (!context.mounted) return;
                  context
                      .read<SettingsProvider>()
                      .deleteSystemPrompt(prompt.id);
                },
                child: Text(l10n.moveMemories),
              ),
            FilledButton(
              onPressed: () async {
                if (memoryCount > 0) {
                  await assignments.reassignMemoriesForDeletedPersona(
                    prompt.id,
                    deleteItems: true,
                  );
                }
                if (!context.mounted) return;
                context.read<SettingsProvider>().deleteSystemPrompt(prompt.id);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                memoryCount > 0 ? l10n.deletePersonaAndMemories : l10n.delete,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Asks the user which persona (or "Global") to move memories to.
  Future<String?> _pickReassignTarget(
      BuildContext context, SystemPrompt deletingPrompt) async {
    final l10n = AppLocalizations.of(context);
    final personas =
        (context.read<SettingsProvider>().settings.savedSystemPrompts ??
                const <SystemPrompt>[])
            .where((p) => p.isPersona && p.id != deletingPrompt.id)
            .toList();
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.moveMemoriesTo),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '__global__'),
            child: Text(l10n.globalSharedMemories),
          ),
          for (final p in personas)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p.id),
              child: Text(p.name),
            ),
        ],
      ),
    );
  }
}

// --- Inline (Default) Prompt Card ---

class _InlinePromptCard extends StatelessWidget {
  final bool isSelected;
  final String currentPrompt;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  const _InlinePromptCard({
    required this.isSelected,
    required this.currentPrompt,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _promptsSoftCard(
      context,
      selected: isSelected,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.defaultPrompt,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.active,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentPrompt.isEmpty ? l10n.noPromptSet : currentPrompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                tooltip: l10n.edit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Saved System Prompt Card ---

class _SystemPromptCard extends StatelessWidget {
  final SystemPrompt prompt;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _SystemPromptCard({
    required this.prompt,
    required this.isSelected,
    required this.onSelect,
    required this.onView,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _promptsSoftCard(
      context,
      selected: isSelected,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar or radio indicator
              if (prompt.isPersona && prompt.avatarPath != null)
                Builder(
                  builder: (context) {
                    final resolved = ImagePickerHelper.resolveImagePathSync(
                        prompt.avatarPath!);
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: prompt.color != null
                          ? Color(prompt.color!).withValues(alpha: 0.2)
                          : colorScheme.surfaceContainerHighest,
                      backgroundImage:
                          resolved != null ? FileImage(File(resolved)) : null,
                      child: resolved == null
                          ? Icon(Icons.face,
                              size: 20,
                              color: prompt.color != null
                                  ? Color(prompt.color!)
                                  : colorScheme.onSurfaceVariant)
                          : null,
                    );
                  },
                )
              else if (prompt.isPersona && prompt.color != null)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(prompt.color!).withValues(alpha: 0.2),
                  child:
                      Icon(Icons.face, size: 20, color: Color(prompt.color!)),
                )
              else
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  size: 22,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            prompt.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? colorScheme.primary : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.active,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 6),
                    // Bound models and persona badges
                    Row(
                      children: [
                        if (prompt.isPersona) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: (prompt.color != null
                                      ? Color(prompt.color!)
                                      : colorScheme.tertiary)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.systemPromptOverride,
                              style: TextStyle(
                                fontSize: 10,
                                color: prompt.color != null
                                    ? Color(prompt.color!)
                                    : colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (prompt.kokoroSpeakerId != null ||
                              prompt.kokoroSpeed != null ||
                              prompt.elevenLabsVoiceId != null ||
                              prompt.grokVoiceId != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                [
                                  if (prompt.elevenLabsVoiceId != null)
                                    ElevenLabsTtsService().displayNameFor(
                                          prompt.elevenLabsVoiceId,
                                        ) ??
                                        'ElevenLabs',
                                  if (prompt.grokVoiceId != null)
                                    GrokTtsService().displayNameFor(
                                          prompt.grokVoiceId,
                                        ) ??
                                        'Grok',
                                  if (prompt.kokoroSpeakerId != null)
                                    KokoroSpeakerResolver.displayName(
                                        prompt.kokoroSpeakerId!),
                                  if (prompt.kokoroSpeed != null)
                                    KokoroSpeakerResolver.speedLabel(
                                        prompt.kokoroSpeed!),
                                ].join(' · '),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                        Icon(
                          prompt.boundModelIds == null ||
                                  prompt.boundModelIds!.isEmpty
                              ? Icons.public
                              : Icons.link,
                          size: 13,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            prompt.boundModelsDisplay,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.viewProfile,
                onPressed: onView,
                icon: Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: l10n.edit,
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 20, color: colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 18),
                        const SizedBox(width: 12),
                        Text(l10n.duplicate),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 12),
                        Text(l10n.delete,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- System Prompt Editor Screen ---

/// Public persona / system-prompt editor (new or edit).
class SystemPromptEditorScreen extends StatefulWidget {
  final SystemPrompt? prompt; // null for new, non-null for edit
  final bool embedded;

  const SystemPromptEditorScreen({
    super.key,
    this.prompt,
    this.embedded = false,
  });

  static Future<void> open(
    BuildContext context, {
    SystemPrompt? prompt,
    bool embedded = false,
  }) {
    // Desktop / wide: modal so we stay in the shell (no broken full-window push).
    if (prefersWideSettingsLayout(context) || prefersDesktopShell(context)) {
      return showAdaptiveModal<void>(
        context: context,
        dialogMaxWidth: 720,
        dialogMaxHeightFraction: 0.92,
        builder: (_) => SystemPromptEditorScreen(
          prompt: prompt,
          embedded: false,
        ),
      );
    }
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => SystemPromptEditorScreen(
          prompt: prompt,
          embedded: embedded,
        ),
      ),
    );
  }

  @override
  State<SystemPromptEditorScreen> createState() =>
      _SystemPromptEditorScreenState();
}

class _SystemPromptEditorScreenState extends State<SystemPromptEditorScreen> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _boundModelIds = [];
  bool _bindToModels = false;

  // Persona fields
  String? _avatarPath;
  double? _avatarFocusX;
  double? _avatarFocusY;
  double? _avatarFocusScale;
  Color? _accentColor;
  String? _defaultModelId;

  /// Backend kind this persona prefers. One of:
  /// `null` (use chat-wide default) | `'lmStudio'` | `'onDeviceGguf'` |
  /// `'onDeviceMlx'` | `'cloud'`.
  String? _defaultProviderKind;

  /// Cloud provider id when [_defaultProviderKind] is `'cloud'`.
  String? _defaultCloudProviderId;
  int? _imageGenSeed; // null = use global setting
  String? _comfyUiWorkflowPath; // null = use global Comfy workflow
  String? _comfyUiWorkflowJson; // null = use global Comfy JSON
  bool _refreshingComfyWorkflows = false;
  int? _kokoroSpeakerId; // null = use global voice setting
  double? _kokoroSpeed; // null = use global speed setting
  String? _elevenLabsVoiceId; // null = use global ElevenLabs voice
  String? _grokVoiceId; // null = use global Grok voice
  /// Which TTS engine this persona is editing. Null = use global settings.
  String? _personaVoiceProvider;
  bool _shareMemories = true;
  MemoryScope _memoryWriteScope = MemoryScope.global;
  bool _showPersonaFields = false;
  bool _useCustomParams = false;
  ParamPreset? _customParams;

  static const _comfyWorkflowGlobalValue = '__persona_comfy_global__';

  /// Memory categories this persona may receive. All selected ⇔ share all
  /// (persisted as null). Subset is persisted as the list of keys.
  static const _memoryCategoryKeys = MemoryCategories.all;
  late Set<String> _sharedMemoryCategories;

  bool get _isEditing => widget.prompt != null;

  /// Lets the Pro part ([_ProPersonaEditor]) rebuild this state.
  void _setStateFromPart(VoidCallback fn) => setState(fn);

  bool get _saveKokoroVoice =>
      _showPersonaFields && _personaVoiceProvider == TtsEngine.kokoro;

  bool get _saveElevenLabsVoice =>
      _showPersonaFields && _personaVoiceProvider == TtsEngine.elevenLabs;

  bool get _saveGrokVoice =>
      _showPersonaFields && _personaVoiceProvider == TtsEngine.grok;

  String? _inferPersonaVoiceProvider({
    int? kokoroSpeakerId,
    double? kokoroSpeed,
    String? elevenLabsVoiceId,
    String? grokVoiceId,
  }) {
    if (elevenLabsVoiceId != null && elevenLabsVoiceId.isNotEmpty) {
      return TtsEngine.elevenLabs;
    }
    if (grokVoiceId != null && grokVoiceId.isNotEmpty) {
      return TtsEngine.grok;
    }
    if (kokoroSpeakerId != null || kokoroSpeed != null) {
      return TtsEngine.kokoro;
    }
    return null;
  }

  String _personaVoiceProviderLabel(AppLocalizations l10n) {
    switch (_personaVoiceProvider) {
      case TtsEngine.kokoro:
        return l10n.personaVoiceProviderKokoro;
      case TtsEngine.elevenLabs:
        return l10n.voiceTtsProviderElevenLabs;
      case TtsEngine.grok:
        return l10n.voiceTtsProviderGrok;
      default:
        return l10n.personaVoiceProviderGlobal;
    }
  }

  IconData _personaVoiceProviderIcon() {
    switch (_personaVoiceProvider) {
      case TtsEngine.kokoro:
        return Icons.record_voice_over_outlined;
      case TtsEngine.elevenLabs:
        return Icons.graphic_eq_outlined;
      case TtsEngine.grok:
        return Icons.auto_awesome_outlined;
      default:
        return Icons.settings_voice_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    final existingCats = widget.prompt?.sharedMemoryCategories;
    _sharedMemoryCategories = existingCats == null
        ? _memoryCategoryKeys.toSet()
        : existingCats.toSet();
    if (widget.prompt != null) {
      _nameController.text = widget.prompt!.name;
      _contentController.text = widget.prompt!.content;
      _boundModelIds = List.from(widget.prompt!.boundModelIds ?? []);
      _bindToModels = _boundModelIds.isNotEmpty;
      _avatarPath = widget.prompt!.avatarPath;
      _avatarFocusX = widget.prompt!.avatarFocusX;
      _avatarFocusY = widget.prompt!.avatarFocusY;
      _avatarFocusScale = widget.prompt!.avatarFocusScale;
      _accentColor =
          widget.prompt!.color != null ? Color(widget.prompt!.color!) : null;
      _defaultModelId = widget.prompt!.defaultModelId;
      _defaultProviderKind = widget.prompt!.defaultProviderKind;
      _defaultCloudProviderId = widget.prompt!.defaultCloudProviderId;
      _showPersonaFields = widget.prompt!.isPersona;
      _imageGenSeed = widget.prompt!.imageGenSeed;
      _comfyUiWorkflowPath = widget.prompt!.comfyUiWorkflowPath;
      _comfyUiWorkflowJson = widget.prompt!.comfyUiWorkflowJson;
      _kokoroSpeakerId = widget.prompt!.kokoroSpeakerId;
      _kokoroSpeed = widget.prompt!.kokoroSpeed;
      _elevenLabsVoiceId = widget.prompt!.elevenLabsVoiceId;
      _grokVoiceId = widget.prompt!.grokVoiceId;
      _personaVoiceProvider = _inferPersonaVoiceProvider(
        kokoroSpeakerId: _kokoroSpeakerId,
        kokoroSpeed: _kokoroSpeed,
        elevenLabsVoiceId: _elevenLabsVoiceId,
        grokVoiceId: _grokVoiceId,
      );
      _shareMemories = widget.prompt!.shareMemories;
      _memoryWriteScope = widget.prompt!.memoryWriteScope;
      _useCustomParams = widget.prompt!.useCustomParams;
      _customParams = widget.prompt!.customParams;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_maybeRefreshComfyWorkflows());
    });
  }

  Future<void> _maybeRefreshComfyWorkflows() async {
    final settings = context.read<SettingsProvider>().settings;
    final url = settings.effectiveImageGenUrl;
    if (url.isEmpty) return;
    if (_refreshingComfyWorkflows) return;
    setState(() => _refreshingComfyWorkflows = true);
    try {
      // Always hit Comfy's workflow list (even if provider isn't ComfyUI yet)
      // so personas can be assigned before switching the global provider.
      await ComfyUIService().refreshAll(
        url,
        headers: settings.imageGenRelayHeaders,
      );
    } catch (_) {
      // Keep any previously cached workflow list; picker still works offline.
    } finally {
      if (mounted) setState(() => _refreshingComfyWorkflows = false);
    }
  }

  /// Persist null when all categories are selected (share everything).
  List<String>? get _sharedMemoryCategoriesToSave {
    if (!_shareMemories) return null;
    if (_sharedMemoryCategories.length >= _memoryCategoryKeys.length) {
      return null;
    }
    return _memoryCategoryKeys.where(_sharedMemoryCategories.contains).toList();
  }

  bool get _personaUseCustomParamsToSave {
    final isPremium = SubscriptionService().isPremium;
    if (!isPremium) return widget.prompt?.useCustomParams ?? false;
    if (!_showPersonaFields || _defaultModelId == null) return false;
    return _useCustomParams;
  }

  ParamPreset? get _personaCustomParamsToSave {
    final isPremium = SubscriptionService().isPremium;
    if (!isPremium) return widget.prompt?.customParams;
    if (!_showPersonaFields) return null;
    return _customParams;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPersonaAvatar() async {
    await ImagePickerHelper.dismissKeyboardForPicker();
    if (!mounted) return;
    final file = await ImagePickerHelper.pickFromGallery(context);
    if (file == null || !mounted) return;
    final permanentPath =
        await ImagePickerHelper.copyToPermanentLocation(file.path);
    if (!mounted) return;
    final resolved =
        ImagePickerHelper.resolveImagePathSync(permanentPath) ?? permanentPath;
    final focus = await AvatarFocusScreen.open(
      context,
      imagePath: resolved,
    );
    if (!mounted) return;
    setState(() {
      _avatarPath = permanentPath;
      _avatarFocusX = focus?.x ?? 0;
      _avatarFocusY = focus?.y ?? -0.28;
      _avatarFocusScale = focus?.scale ?? 1.35;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    final l10n = AppLocalizations.of(context);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPromptName)),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPromptContent)),
      );
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final now = DateTime.now();
    final hasAvatar = _showPersonaFields && _avatarPath != null;
    final avatarChanged = _avatarPath != widget.prompt?.avatarPath;

    if (_isEditing) {
      var updated = widget.prompt!.copyWith(
        name: name,
        content: content,
        boundModelIds: _bindToModels ? _boundModelIds : null,
        clearBoundModels: !_bindToModels,
        updatedAt: now,
        avatarPath: _showPersonaFields ? _avatarPath : null,
        clearAvatar: !hasAvatar,
        avatarFocusX: hasAvatar ? _avatarFocusX : null,
        avatarFocusY: hasAvatar ? _avatarFocusY : null,
        avatarFocusScale: hasAvatar ? _avatarFocusScale : null,
        clearAvatarFocus: !hasAvatar,
        clearPalette: !hasAvatar || avatarChanged,
        color: _showPersonaFields ? _accentColor?.toARGB32() : null,
        clearColor: !_showPersonaFields || _accentColor == null,
        defaultModelId: _showPersonaFields ? _defaultModelId : null,
        clearDefaultModel: !_showPersonaFields || _defaultModelId == null,
        defaultProviderKind: _showPersonaFields ? _defaultProviderKind : null,
        clearDefaultProvider:
            !_showPersonaFields || _defaultProviderKind == null,
        defaultCloudProviderId:
            _showPersonaFields ? _defaultCloudProviderId : null,
        clearDefaultCloudProvider:
            !_showPersonaFields || _defaultCloudProviderId == null,
        imageGenSeed: _showPersonaFields ? _imageGenSeed : null,
        clearImageGenSeed: !_showPersonaFields || _imageGenSeed == null,
        comfyUiWorkflowPath: _showPersonaFields ? _comfyUiWorkflowPath : null,
        clearComfyUiWorkflowPath:
            !_showPersonaFields || _comfyUiWorkflowPath == null,
        comfyUiWorkflowJson: _showPersonaFields ? _comfyUiWorkflowJson : null,
        clearComfyUiWorkflowJson:
            !_showPersonaFields || _comfyUiWorkflowJson == null,
        kokoroSpeakerId: _saveKokoroVoice ? _kokoroSpeakerId : null,
        clearKokoroSpeaker: !_saveKokoroVoice || _kokoroSpeakerId == null,
        kokoroSpeed: _saveKokoroVoice ? _kokoroSpeed : null,
        clearKokoroSpeed: !_saveKokoroVoice || _kokoroSpeed == null,
        elevenLabsVoiceId: _saveElevenLabsVoice ? _elevenLabsVoiceId : null,
        clearElevenLabsVoice:
            !_saveElevenLabsVoice || _elevenLabsVoiceId == null,
        grokVoiceId: _saveGrokVoice ? _grokVoiceId : null,
        clearGrokVoice: !_saveGrokVoice || _grokVoiceId == null,
        shareMemories: _shareMemories,
        sharedMemoryCategories: _sharedMemoryCategoriesToSave,
        clearSharedMemoryCategories: _sharedMemoryCategoriesToSave == null,
        memoryWriteScope: _memoryWriteScope,
        useCustomParams: _personaUseCustomParamsToSave,
        customParams: _personaCustomParamsToSave,
        clearCustomParams: _personaCustomParamsToSave == null,
      );
      if (hasAvatar && (avatarChanged || updated.palettePrimary == null)) {
        updated = await PersonaPalette.ensureCached(updated);
      }
      if (!mounted) return;
      settingsProvider.updateSavedSystemPrompt(updated);

      // If this prompt is currently selected, also update the inline systemPrompt
      if (settingsProvider.settings.selectedSystemPromptId == updated.id) {
        settingsProvider.updateSystemPrompt(content);
      }
    } else {
      var prompt = SystemPrompt(
        id: 'sp_${now.millisecondsSinceEpoch}',
        name: name,
        content: content,
        boundModelIds: _bindToModels ? _boundModelIds : null,
        createdAt: now,
        updatedAt: now,
        avatarPath: hasAvatar ? _avatarPath : null,
        avatarFocusX: hasAvatar ? _avatarFocusX : null,
        avatarFocusY: hasAvatar ? _avatarFocusY : null,
        avatarFocusScale: hasAvatar ? _avatarFocusScale : null,
        color: _showPersonaFields ? _accentColor?.toARGB32() : null,
        defaultModelId: _showPersonaFields ? _defaultModelId : null,
        defaultProviderKind: _showPersonaFields ? _defaultProviderKind : null,
        defaultCloudProviderId:
            _showPersonaFields ? _defaultCloudProviderId : null,
        imageGenSeed: _showPersonaFields ? _imageGenSeed : null,
        comfyUiWorkflowPath: _showPersonaFields ? _comfyUiWorkflowPath : null,
        comfyUiWorkflowJson: _showPersonaFields ? _comfyUiWorkflowJson : null,
        kokoroSpeakerId: _saveKokoroVoice ? _kokoroSpeakerId : null,
        kokoroSpeed: _saveKokoroVoice ? _kokoroSpeed : null,
        elevenLabsVoiceId: _saveElevenLabsVoice ? _elevenLabsVoiceId : null,
        grokVoiceId: _saveGrokVoice ? _grokVoiceId : null,
        shareMemories: _shareMemories,
        sharedMemoryCategories: _sharedMemoryCategoriesToSave,
        memoryWriteScope: _memoryWriteScope,
        useCustomParams: _personaUseCustomParamsToSave,
        customParams: _personaCustomParamsToSave,
      );
      if (hasAvatar) {
        prompt = await PersonaPalette.ensureCached(prompt);
      }
      if (!mounted) return;
      settingsProvider.addSystemPrompt(prompt);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final availableModels = settingsProvider.chatAvailableModels;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final wide = prefersWideSettingsLayout(context);

    final nameAndPromptCard = _promptsSoftCard(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: _promptsFieldDecoration(
                context,
                labelText: l10n.promptNameLabel,
                hintText: l10n.promptNameHint,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contentController,
              decoration: _promptsFieldDecoration(
                context,
                labelText: l10n.systemPromptLabel,
                hintText: l10n.systemPromptEditorHint,
                alignLabelWithHint: true,
              ),
              maxLines: wide ? 16 : 10,
              minLines: wide ? 8 : 5,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );

    final personaModeStart = <Widget>[
      _promptsSectionLabel(context, l10n.personaModeLabel),
      const SizedBox(height: 10),
      _promptsSoftCard(
        context,
        child: DesktopPreferenceRow(
          icon: Icons.face,
          title: l10n.personaModeLabel,
          subtitle: l10n.personaModeSubtitle,
          trailing: Switch(
            value: _showPersonaFields,
            onChanged: (value) => setState(() => _showPersonaFields = value),
          ),
        ),
      ),
      ..._proPersonaMemorySection(context),
      if (_showPersonaFields) ...[
        const SizedBox(height: 22),
        _promptsSectionLabel(context, l10n.avatarLabel),
        const SizedBox(height: 10),
        _promptsSoftCard(
          context,
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  final resolvedAvatar = _avatarPath != null
                      ? ImagePickerHelper.resolveImagePathSync(_avatarPath!)
                      : null;
                  return Column(
                    children: [
                      ListTile(
                        leading: _personaAvatarPreview(
                          context,
                          colorScheme,
                          resolvedAvatar,
                        ),
                        title: Text(l10n.avatarLabel),
                        subtitle: Text(
                          _avatarPath != null
                              ? l10n.customAvatarSet
                              : l10n.noAvatar,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_avatarPath != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() {
                                  _avatarPath = null;
                                  _avatarFocusX = null;
                                  _avatarFocusY = null;
                                  _avatarFocusScale = null;
                                }),
                              ),
                            IconButton(
                              icon: const Icon(Icons.photo_library, size: 18),
                              onPressed: _pickPersonaAvatar,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accentColor ?? colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                title: Text(l10n.accentColorLabel),
                subtitle: Text(
                  _accentColor != null ? l10n.customColor : l10n.defaultLabel,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_accentColor != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _accentColor = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.palette, size: 18),
                      onPressed: () => _showColorPicker(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 22),
      _promptsSectionLabel(
        context,
        _showPersonaFields ? l10n.preferredModelLabel : l10n.bindToModels,
      ),
      const SizedBox(height: 10),
      if (!_showPersonaFields)
        _promptsSoftCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopPreferenceRow(
                title: l10n.bindToModels,
                subtitle: l10n.bindToModelsSubtitle,
                trailing: Switch(
                  value: _bindToModels,
                  onChanged: (value) => setState(() => _bindToModels = value),
                ),
              ),
              if (_bindToModels) ...[
                if (useDesktopSettingsControls(context))
                  const SizedBox(height: 2)
                else
                  const Divider(height: 1),
                if (availableModels.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.noModelsLoaded,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: useDesktopSettingsControls(context) ? 4 : 0,
                      vertical: 4,
                    ),
                    child: DesktopSettingsGrid(
                      children:
                          availableModels.where((m) => m.isLLM).map((model) {
                        final isChecked = _boundModelIds.contains(model.id);
                        return DesktopPreferenceRow(
                          title: model.id.split('/').last,
                          subtitle: '${model.arch} • ${model.quantization}',
                          trailing: Checkbox(
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _boundModelIds.add(model.id);
                                } else {
                                  _boundModelIds.remove(model.id);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _boundModelIds.remove(model.id);
                              } else {
                                _boundModelIds.add(model.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ],
          ),
        )
      else
        _promptsSoftCard(
          context,
          child: ListTile(
            leading: const Icon(Icons.smart_toy),
            title: Text(l10n.preferredModelLabel),
            subtitle: Text(_personaModelSubtitle(l10n)),
            onTap: () => _showProviderAndModelPicker(context, availableModels),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_defaultModelId != null || _defaultProviderKind != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() {
                      _defaultModelId = null;
                      _defaultProviderKind = null;
                      _defaultCloudProviderId = null;
                    }),
                  ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      if (ProFeatures.included &&
          _showPersonaFields &&
          _defaultModelId != null) ...[
        const SizedBox(height: 10),
        _promptsSoftCard(
          context,
          child: _proCustomParamsTile(context),
        ),
      ],
      if (_showPersonaFields) ...[
        const SizedBox(height: 22),
        _promptsSectionLabel(context, l10n.personaVoiceSection),
        const SizedBox(height: 10),
        _promptsSoftCard(
          context,
          child: Column(
            children: [
              ListTile(
                leading: Icon(_personaVoiceProviderIcon()),
                title: Text(l10n.personaVoiceProviderLabel),
                subtitle: Text(_personaVoiceProviderLabel(l10n)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _showVoiceProviderPicker(context),
              ),
              if (_personaVoiceProvider == TtsEngine.kokoro) ...[
                if (useDesktopSettingsControls(context))
                  const SizedBox(height: 2)
                else
                  const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: Text(l10n.personaKokoroVoiceLabel),
                  subtitle: Text(
                    _kokoroSpeakerId != null
                        ? KokoroSpeakerResolver.displayName(_kokoroSpeakerId!)
                        : l10n.personaKokoroVoiceGlobal,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_kokoroSpeakerId != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: l10n.resetToGlobal,
                          onPressed: () =>
                              setState(() => _kokoroSpeakerId = null),
                        ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  onTap: () => _showKokoroSpeakerPicker(context),
                ),
                if (useDesktopSettingsControls(context))
                  const SizedBox(height: 2)
                else
                  const Divider(height: 1),
                DesktopSliderField(
                  icon: Icons.speed,
                  title: l10n.personaKokoroSpeedLabel,
                  subtitle: _kokoroSpeed != null
                      ? KokoroSpeakerResolver.speedLabel(_kokoroSpeed!)
                      : l10n.personaKokoroSpeedGlobal,
                  valueLabel: KokoroSpeakerResolver.speedLabel(
                    _kokoroSpeed ?? settingsProvider.settings.voiceKokoroSpeed,
                  ),
                  value: (_kokoroSpeed ??
                          settingsProvider.settings.voiceKokoroSpeed)
                      .clamp(0.5, 2.0),
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) => setState(() {
                    _kokoroSpeed = double.parse(value.toStringAsFixed(1));
                  }),
                ),
                if (_kokoroSpeed != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _kokoroSpeed = null),
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text(l10n.resetToGlobal),
                    ),
                  ),
              ],
              ..._proCloudVoiceRows(context),
            ],
          ),
        ),
        // Per-persona ComfyUI workflow is free (still only shown in
        // persona mode). Image seed stays Pro.
        const SizedBox(height: 16),
        _buildPersonaComfyWorkflowCard(
          context,
          l10n,
          settingsProvider,
          colorScheme,
        ),
        ..._proImageSeedSection(context),
      ],
    ];

    final templates = <Widget>[
      if (!_isEditing) ...[
        const SizedBox(height: 22),
        _promptsSectionLabel(context, l10n.templatesSection),
        const SizedBox(height: 10),
        _promptsSoftCard(
          context,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getTemplates(l10n).map((template) {
                return ActionChip(
                  avatar: Icon(template.icon, size: 16),
                  label:
                      Text(template.name, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _nameController.text = template.name;
                    _contentController.text = template.content;
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ];

    final body = wide
        ? SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 36),
            child: SettingsTwoColumn(
              leftFlex: 5,
              rightFlex: 4,
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameAndPromptCard,
                  ...templates,
                ],
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: personaModeStart,
              ),
            ),
          )
        : ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
            children: [
              nameAndPromptCard,
              const SizedBox(height: 22),
              ...personaModeStart,
              ...templates,
            ],
          );

    return GlassSettingsScaffold(
      title: _isEditing ? l10n.editSystemPrompt : l10n.newSystemPrompt,
      embedded: widget.embedded,
      actions: [
        GlassCircleIconButton(
          tooltip: l10n.save,
          onTap: _save,
          onLightCanvas: widget.embedded ? true : null,
          child: Icon(
            Icons.check_rounded,
            size: 22,
            color: widget.embedded
                ? (theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.88))
                : Colors.white,
          ),
        ),
      ],
      body: body,
    );
  }

  void _showColorPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = [
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
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pickAccentColor),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = _accentColor?.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () {
                  setState(() => _accentColor = color);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaComfyWorkflowCard(
    BuildContext context,
    AppLocalizations l10n,
    SettingsProvider settingsProvider,
    ColorScheme colorScheme,
  ) {
    final settings = settingsProvider.settings;
    final isComfy = settings.imageGenProvider == 'comfyui';
    final savedWorkflows = ComfyUIService().savedWorkflows;
    final selected = _comfyUiWorkflowPath;
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: _comfyWorkflowGlobalValue,
        child: Text(
          l10n.personaComfyWorkflowUseGlobal,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ...savedWorkflows.map(
        (workflow) => DropdownMenuItem<String>(
          value: workflow.path,
          child: Text(
            workflow.displayName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];
    if (selected != null &&
        selected.isNotEmpty &&
        !savedWorkflows.any((w) => w.path == selected)) {
      items.add(
        DropdownMenuItem<String>(
          value: selected,
          child: Text(
            l10n.personaComfyWorkflowUnavailable(selected),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final dropdownValue = (selected == null || selected.isEmpty)
        ? _comfyWorkflowGlobalValue
        : selected;

    return _promptsSoftCard(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.personaComfyWorkflowLabel,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (selected != null && selected.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () =>
                        setState(() => _comfyUiWorkflowPath = null),
                    tooltip: l10n.resetToGlobal,
                  ),
                IconButton(
                  icon: _refreshingComfyWorkflows
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  onPressed: _refreshingComfyWorkflows
                      ? null
                      : () => unawaited(_maybeRefreshComfyWorkflows()),
                  tooltip: l10n.personaComfyWorkflowRefresh,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: dropdownValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: items,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _comfyUiWorkflowPath =
                      v == _comfyWorkflowGlobalValue ? null : v;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: selected == null ||
                  selected.isEmpty ||
                  isComfyBuiltinWorkflowPath(selected),
              maxLines: 6,
              minLines: 3,
              controller:
                  TextEditingController(text: _comfyUiWorkflowJson ?? '')
                    ..selection = TextSelection.collapsed(
                        offset: (_comfyUiWorkflowJson ?? '').length),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                alignLabelWithHint: true,
                labelText: l10n.personaComfyWorkflowJsonLabel,
                hintText: l10n.personaComfyWorkflowJsonHint,
                helperText: (selected != null &&
                        selected.isNotEmpty &&
                        !isComfyBuiltinWorkflowPath(selected))
                    ? l10n.personaComfyWorkflowJsonIgnored
                    : ((_comfyUiWorkflowJson == null ||
                            _comfyUiWorkflowJson!.isEmpty)
                        ? l10n.personaComfyWorkflowJsonHelper
                        : l10n.personaComfyWorkflowJsonActive(
                            _comfyUiWorkflowJson!.length)),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              onChanged: (v) {
                final trimmed = v.trim();
                setState(() {
                  _comfyUiWorkflowJson = trimmed.isEmpty ? null : v;
                });
              },
            ),
            if (_comfyUiWorkflowJson != null &&
                _comfyUiWorkflowJson!.isNotEmpty &&
                (selected == null ||
                    selected.isEmpty ||
                    isComfyBuiltinWorkflowPath(selected)))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: Text(l10n.personaComfyWorkflowJsonClear),
                  onPressed: () => setState(() => _comfyUiWorkflowJson = null),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              isComfy
                  ? l10n.personaComfyWorkflowHelper
                  : l10n.personaComfyWorkflowNotComfy,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _personaModelSubtitle(AppLocalizations l10n) {
    return personaPreferredBackendLabel(
          providerKind: _defaultProviderKind,
          cloudProviderId: _defaultCloudProviderId,
          modelId: _defaultModelId,
          anyModelLabel: l10n.preferredModelAny,
        ) ??
        l10n.preferredModelAny;
  }

  /// Two-step picker: first choose the backend, then choose a model from
  /// that backend's catalog. Cloud options are gated behind premium.
  /// Local servers (Ollama, JAN, oMLX) live with LM Studio — not under Cloud.
  void _showProviderAndModelPicker(BuildContext context, List availableModels) {
    final l10n = AppLocalizations.of(context);
    final isPremium = SubscriptionService().isPremium;
    final configured = CloudApiService().providers;
    final localConfigured =
        configured.where((p) => p.type.isFreeLocalServer).toList();
    final cloudConfigured = configured.where((p) => p.type.isPremium).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.personaChooseProviderTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.personaChooseProviderSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('LM Studio'),
                  subtitle: const Text('Use the connected LM Studio server'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickLmStudioModel(context, availableModels);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.phone_iphone),
                  title: const Text('On-Device'),
                  subtitle: const Text('Downloaded local models (GGUF/MLX)'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickOnDeviceModel(context);
                  },
                ),
                ...localConfigured.map((cp) {
                  return ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: Text(cp.name),
                    subtitle: Text(cp.type.displayName),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickCloudModel(context, cp);
                    },
                  );
                }),
                if (isPremium) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      l10n.personaCloudProvidersSection,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  ...cloudConfigured.map((cp) {
                    return ListTile(
                      leading: const Icon(Icons.cloud_outlined),
                      title: Text(cp.name),
                      subtitle: Text(cp.type.displayName),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _pickCloudModel(context, cp);
                      },
                    );
                  }),
                  if (cloudConfigured.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'No cloud providers configured. Add one in Settings → Cloud Providers.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(l10n.cancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickLmStudioModel(BuildContext context, List availableModels) {
    final l10n = AppLocalizations.of(context);
    final llmModels = availableModels.where((m) => m.isLLM).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectPreferredModelTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: llmModels.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                      'No LM Studio models available. Connect to a server in Settings.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: llmModels.length,
                  itemBuilder: (context, index) {
                    final model = llmModels[index];
                    final isSelected = _defaultProviderKind == 'lmStudio' &&
                        _defaultModelId == model.id;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        model.id.split('/').last,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${model.arch} • ${model.quantization}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      dense: true,
                      onTap: () {
                        setState(() {
                          _defaultProviderKind = 'lmStudio';
                          _defaultCloudProviderId = null;
                          _defaultModelId = model.id;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _pickOnDeviceModel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = LocalModelDownloadService.instance.readyEntries;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select on-device model'),
        content: SizedBox(
          width: double.maxFinite,
          child: ready.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                      'No downloaded models. Download one from Settings → Local Models.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: ready.length,
                  itemBuilder: (context, index) {
                    final entry = ready[index];
                    final kind = entry.spec.engine == LocalEngine.mlx
                        ? 'onDeviceMlx'
                        : 'onDeviceGguf';
                    final isSelected = _defaultProviderKind == kind &&
                        _defaultModelId == entry.spec.id;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        entry.spec.displayName,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${entry.spec.engine.name.toUpperCase()} • ${entry.spec.quantization}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      dense: true,
                      onTap: () {
                        setState(() {
                          _defaultProviderKind = kind;
                          _defaultCloudProviderId = null;
                          _defaultModelId = entry.spec.id;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _pickCloudModel(BuildContext context, CloudApiProvider cp) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Select model from ${cp.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<String>>(
              future: CloudApiService().fetchModels(cp),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Failed to load models: ${snap.error}'),
                  );
                }
                final models = LMStudioModel.chatModelIds(
                    snap.data ?? const <String>[]);
                if (models.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No models returned by this provider.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final mid = models[index];
                    final providerKind = cp.type.providerKind;
                    final isSelected = _defaultProviderKind == providerKind &&
                        _defaultCloudProviderId == cp.id &&
                        _defaultModelId == mid;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        mid,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      dense: true,
                      onTap: () {
                        setState(() {
                          _defaultProviderKind = providerKind;
                          _defaultCloudProviderId = cp.id;
                          _defaultModelId = mid;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _personaAvatarPreview(
    BuildContext context,
    ColorScheme colorScheme,
    String? resolvedAvatar,
  ) {
    final avatar = PersonaAvatar(
      imagePath: _avatarPath,
      radius: 22,
      backgroundColor: _accentColor?.withValues(alpha: 0.2) ??
          colorScheme.surfaceContainerHighest,
      alignment: PersonaAvatar.alignmentFromFocus(
        _avatarFocusX,
        _avatarFocusY,
      ),
      scale: PersonaAvatar.scaleFromFocus(_avatarFocusScale),
      fallbackIcon: Icons.face,
      fallbackIconColor: _accentColor ?? colorScheme.onSurfaceVariant,
    );
    if (resolvedAvatar == null) return avatar;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: avatar),
          Positioned(
            right: -1,
            bottom: -1,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _editAvatarFocus(context, resolvedAvatar),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAvatarFocus(BuildContext context, String imagePath) async {
    final focus = await AvatarFocusScreen.open(
      context,
      imagePath: imagePath,
      initialAlignment: PersonaAvatar.alignmentFromFocus(
        _avatarFocusX,
        _avatarFocusY,
      ),
      initialScale: PersonaAvatar.scaleFromFocus(
        _avatarFocusScale,
        fallback: 1.35,
      ),
    );
    if (focus == null || !mounted) return;
    setState(() {
      _avatarFocusX = focus.x;
      _avatarFocusY = focus.y;
      _avatarFocusScale = focus.scale;
    });
  }

  void _showVoiceProviderPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsProvider>().settings;
    final elevenLabsReady = settings.hasElevenLabsApiKey;
    final grokReady = settings.hasGrokApiKey;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        Widget option({
          required String? id,
          required IconData icon,
          required String title,
          required bool enabled,
          String? disabledSubtitle,
        }) {
          final selected = _personaVoiceProvider == id;
          return ListTile(
            enabled: enabled,
            leading: Icon(icon),
            title: Text(title),
            subtitle: enabled
                ? null
                : Text(
                    disabledSubtitle ?? l10n.personaVoiceConfigureInSettings),
            trailing: selected
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: enabled
                ? () {
                    setState(() => _personaVoiceProvider = id);
                    Navigator.pop(sheetCtx);
                  }
                : null,
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.personaVoiceProviderLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                option(
                  id: null,
                  icon: Icons.settings_voice_outlined,
                  title: l10n.personaVoiceProviderGlobal,
                  enabled: true,
                ),
                option(
                  id: TtsEngine.kokoro,
                  icon: Icons.record_voice_over_outlined,
                  title: l10n.personaVoiceProviderKokoro,
                  enabled: true,
                ),
                ..._proCloudVoiceProviderChoices(
                  sheetCtx,
                  option,
                  l10n,
                  elevenLabsReady,
                  grokReady,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showKokoroSpeakerPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const speakers = KokoroTtsService.speakers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.personaKokoroVoicePickerTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    // +1 for "use global" option
                    itemCount: speakers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _kokoroSpeakerId == null;
                        return ListTile(
                          leading: Icon(
                            Icons.settings_voice_outlined,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          title: Text(l10n.personaKokoroVoiceGlobal),
                          subtitle: Text(l10n.personaKokoroVoiceSubtitle),
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () {
                            setState(() => _kokoroSpeakerId = null);
                            Navigator.pop(context);
                          },
                        );
                      }

                      final speaker = speakers[index - 1];
                      final id = speaker['id'] as int;
                      final name = speaker['name'] as String;
                      final gender = speaker['gender'] as String;
                      final code = speaker['code'] as String;
                      final isSelected = id == _kokoroSpeakerId;

                      return ListTile(
                        leading: Icon(
                          gender == 'female' ? Icons.face_3 : Icons.face,
                          color: gender == 'female'
                              ? Colors.pink.shade300
                              : Colors.blue.shade300,
                        ),
                        title: Text(name),
                        subtitle: Text(code),
                        trailing: isSelected
                            ? Icon(Icons.check,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          setState(() => _kokoroSpeakerId = id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- Prompt Templates ---

class _PromptTemplate {
  final String name;
  final String content;
  final IconData icon;

  const _PromptTemplate({
    required this.name,
    required this.content,
    required this.icon,
  });
}

List<_PromptTemplate> _getTemplates(AppLocalizations l10n) => [
      _PromptTemplate(
        name: l10n.templateCodeAssistant,
        content:
            'You are an expert programming assistant. You write clean, efficient, and well-documented code. When explaining code, be concise but thorough. Always consider edge cases and best practices.',
        icon: Icons.code,
      ),
      _PromptTemplate(
        name: l10n.templateCreativeWriter,
        content:
            'You are a creative writing assistant. You help craft engaging stories, poems, and other creative content. Your writing is vivid, imaginative, and emotionally resonant.',
        icon: Icons.edit_note,
      ),
      _PromptTemplate(
        name: l10n.templateConciseExpert,
        content:
            'You are a helpful assistant that provides brief, direct answers. Avoid unnecessary elaboration. Use bullet points when listing multiple items. Get straight to the point.',
        icon: Icons.short_text,
      ),
      _PromptTemplate(
        name: l10n.templateResearcher,
        content:
            'You are a thorough research assistant. You analyze information critically, cite your reasoning, and present balanced viewpoints. When uncertain, clearly state your confidence level.',
        icon: Icons.science,
      ),
      _PromptTemplate(
        name: l10n.templateTutor,
        content:
            'You are a patient and encouraging tutor. You explain concepts step by step, use analogies to make complex topics accessible, and check for understanding. Adapt your explanations to the student\'s level.',
        icon: Icons.school,
      ),
      _PromptTemplate(
        name: l10n.templateTechnicalWriter,
        content:
            'You are a technical documentation specialist. You write clear, structured documentation with proper headings, code examples, and step-by-step instructions. Use markdown formatting.',
        icon: Icons.description,
      ),
    ];
