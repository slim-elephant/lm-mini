import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/local_model_spec.dart';
import '../providers/settings_provider.dart';
import '../services/kokoro_tts_service.dart';
import '../services/local_model_download_service.dart';
import '../utils/kokoro_speaker_resolver.dart';
import '../utils/remote_host_backends.dart';

/// User choices collected before saving a generated persona.
class PersonaSaveOptions {
  final String name;
  final int? kokoroSpeakerId;
  final Color? accentColor;
  final String? defaultModelId;
  final String? defaultProviderKind;
  final String? defaultCloudProviderId;

  const PersonaSaveOptions({
    required this.name,
    this.kokoroSpeakerId,
    this.accentColor,
    this.defaultModelId,
    this.defaultProviderKind,
    this.defaultCloudProviderId,
  });
}

/// Edit name / voice / model / color before saving a generated persona.
class PersonaSaveOptionsDialog extends StatefulWidget {
  final String initialName;
  final int initialSpeakerId;
  final Color? initialColor;

  const PersonaSaveOptionsDialog({
    super.key,
    required this.initialName,
    required this.initialSpeakerId,
    this.initialColor,
  });

  static Future<PersonaSaveOptions?> show(
    BuildContext context, {
    required String initialName,
    required int initialSpeakerId,
    Color? initialColor,
  }) {
    return showDialog<PersonaSaveOptions>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PersonaSaveOptionsDialog(
        initialName: initialName,
        initialSpeakerId: initialSpeakerId,
        initialColor: initialColor,
      ),
    );
  }

  @override
  State<PersonaSaveOptionsDialog> createState() =>
      _PersonaSaveOptionsDialogState();
}

class _PersonaSaveOptionsDialogState extends State<PersonaSaveOptionsDialog> {
  late final TextEditingController _nameController;
  late int _speakerId;
  Color? _accentColor;
  String? _defaultModelId;
  String? _defaultProviderKind;
  String? _defaultCloudProviderId;

  static const _accentSwatches = <Color>[
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _speakerId = widget.initialSpeakerId;
    _accentColor = widget.initialColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _modelSubtitle(AppLocalizations l10n) {
    if (_defaultModelId == null || _defaultModelId!.isEmpty) {
      return l10n.preferredModelAny;
    }
    final label = _defaultModelId!.split('/').last;
    final kind = _defaultProviderKind;
    if (kind == null || kind.isEmpty) return label;
    final provider = switch (kind) {
      'lmStudio' => 'LM Studio',
      'lmMiniDesktop' => RemoteHostBackends.displayName(kind),
      'onDeviceGguf' => 'On-Device',
      'onDeviceMlx' => 'On-Device',
      'ollama' => 'Ollama',
      'omlx' => 'oMLX',
      'cloud' => 'Cloud',
      _ => kind,
    };
    return '$provider • $label';
  }

  Future<void> _pickModel() async {
    final sp = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final lmModels = sp.chatAvailableModels;
    final localReady = LocalModelDownloadService.instance.readyEntries;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollController) {
              return ListView(
                controller: scrollController,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.preferredModelLabel,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      _defaultModelId == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _defaultModelId == null
                          ? Theme.of(ctx).colorScheme.primary
                          : null,
                    ),
                    title: Text(l10n.preferredModelAny),
                    onTap: () {
                      setState(() {
                        _defaultModelId = null;
                        _defaultProviderKind = null;
                        _defaultCloudProviderId = null;
                      });
                      Navigator.pop(sheetCtx);
                    },
                  ),
                  if (lmModels.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(
                        RemoteHostBackends.displayName(
                          sp.settings.isRemoteActive &&
                                  RemoteHostBackends.usesLmStudioHttp(
                                      sp.settings.activeProviderKind)
                              ? sp.settings.activeProviderKind
                              : 'lmStudio',
                        ),
                        style: Theme.of(ctx).textTheme.labelMedium,
                      ),
                    ),
                    for (final model in lmModels)
                      ListTile(
                        leading: Icon(
                          RemoteHostBackends.usesLmStudioHttp(
                                    _defaultProviderKind ?? '') &&
                                  _defaultModelId == model.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: RemoteHostBackends.usesLmStudioHttp(
                                    _defaultProviderKind ?? '') &&
                                  _defaultModelId == model.id
                              ? Theme.of(ctx).colorScheme.primary
                              : null,
                        ),
                        title: Text(
                          model.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${model.arch} • ${model.quantization}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(ctx).colorScheme.outline,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _defaultProviderKind = sp.settings.isRemoteActive &&
                                    RemoteHostBackends.usesLmStudioHttp(
                                        sp.settings.activeProviderKind)
                                ? sp.settings.activeProviderKind
                                : 'lmStudio';
                            _defaultCloudProviderId = null;
                            _defaultModelId = model.id;
                          });
                          Navigator.pop(sheetCtx);
                        },
                      ),
                  ],
                  if (localReady.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(
                        'On-Device',
                        style: Theme.of(ctx).textTheme.labelMedium,
                      ),
                    ),
                    for (final entry in localReady)
                      ListTile(
                        leading: Icon(
                          (_defaultProviderKind == 'onDeviceGguf' ||
                                  _defaultProviderKind == 'onDeviceMlx') &&
                                  _defaultModelId == entry.spec.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: (_defaultProviderKind == 'onDeviceGguf' ||
                                      _defaultProviderKind == 'onDeviceMlx') &&
                                  _defaultModelId == entry.spec.id
                              ? Theme.of(ctx).colorScheme.primary
                              : null,
                        ),
                        title: Text(
                          entry.spec.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${entry.spec.engine.name.toUpperCase()} • ${entry.spec.quantization}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(ctx).colorScheme.outline,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _defaultProviderKind =
                                entry.spec.engine == LocalEngine.mlx
                                    ? 'onDeviceMlx'
                                    : 'onDeviceGguf';
                            _defaultCloudProviderId = null;
                            _defaultModelId = entry.spec.id;
                          });
                          Navigator.pop(sheetCtx);
                        },
                      ),
                  ],
                  if (lmModels.isEmpty && localReady.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.preferredModelAny,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickVoice() async {
    final l10n = AppLocalizations.of(context);
    const speakers = KokoroTtsService.speakers;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (ctx, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.personaKokoroVoicePickerTitle,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: speakers.length,
                      itemBuilder: (context, index) {
                        final speaker = speakers[index];
                        final id = speaker['id'] as int;
                        final name = speaker['name'] as String;
                        final gender = speaker['gender'] as String;
                        final code = speaker['code'] as String;
                        final isSelected = id == _speakerId;
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
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(ctx).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() => _speakerId = id);
                            Navigator.pop(sheetCtx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPromptName)),
      );
      return;
    }
    Navigator.of(context).pop(
      PersonaSaveOptions(
        name: name,
        kokoroSpeakerId: _speakerId,
        accentColor: _accentColor,
        defaultModelId: _defaultModelId,
        defaultProviderKind: _defaultProviderKind,
        defaultCloudProviderId: _defaultCloudProviderId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.savePersona),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.promptNameLabel,
                  hintText: l10n.promptNameHint,
                  prefixIcon: const Icon(Icons.label_outline),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.record_voice_over_outlined),
                title: Text(l10n.personaKokoroVoiceLabel),
                subtitle: Text(KokoroSpeakerResolver.displayName(_speakerId)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickVoice,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.smart_toy_outlined),
                title: Text(l10n.preferredModelLabel),
                subtitle: Text(_modelSubtitle(l10n)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_defaultModelId != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: l10n.preferredModelAny,
                        onPressed: () => setState(() {
                          _defaultModelId = null;
                          _defaultProviderKind = null;
                          _defaultCloudProviderId = null;
                        }),
                      ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onTap: _pickModel,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.accentColorLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _accentColor = null),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.5),
                        ),
                        color: cs.surfaceContainerHighest,
                      ),
                      child: _accentColor == null
                          ? Icon(Icons.check, size: 18, color: cs.primary)
                          : Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                    ),
                  ),
                  for (final color in _accentSwatches)
                    GestureDetector(
                      onTap: () => setState(() => _accentColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _accentColor?.toARGB32() == color.toARGB32()
                              ? Border.all(color: cs.onSurface, width: 3)
                              : null,
                        ),
                        child: _accentColor?.toARGB32() == color.toARGB32()
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
