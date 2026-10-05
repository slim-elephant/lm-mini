import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../models/lm_studio_model.dart';
import '../providers/settings_provider.dart';
import '../services/local_model_download_service.dart';

/// Prompt the user to pick a provider, then a model, before chatting.
///
/// Returns `true` when a usable selection was saved.
Future<bool> showProviderModelSetupDialog(
  BuildContext context,
  SettingsProvider settingsProvider,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: settingsProvider,
      child: const _ProviderModelSetupDialog(),
    ),
  );
  return result == true;
}

class _ProviderModelSetupDialog extends StatefulWidget {
  const _ProviderModelSetupDialog();

  @override
  State<_ProviderModelSetupDialog> createState() =>
      _ProviderModelSetupDialogState();
}

class _ProviderModelSetupDialogState extends State<_ProviderModelSetupDialog> {
  late String _providerKind;
  String? _selectedModelId;
  bool _loadingModels = false;
  List<LMStudioModel> _lmModels = const [];
  List<LocalModelEntry> _localModels = const [];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _providerKind = settings.activeProviderKind;
    _selectedModelId = _isOnDevice(_providerKind)
        ? settings.selectedLocalModelId
        : settings.selectedModel;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadModels());
  }

  bool _isOnDevice(String kind) =>
      kind == 'onDeviceGguf' || kind == 'onDeviceMlx';

  Future<void> _reloadModels() async {
    final sp = context.read<SettingsProvider>();
    setState(() => _loadingModels = true);
    try {
      if (_isOnDevice(_providerKind)) {
        final entries = LocalModelDownloadService.instance.readyEntries;
        if (!mounted) return;
        setState(() {
          _localModels = entries;
          _lmModels = const [];
          _selectedModelId ??= sp.settings.selectedLocalModelId ??
              (entries.isNotEmpty ? entries.first.spec.id : null);
        });
      } else {
        await sp.loadAvailableModels();
        if (!mounted) return;
        final models = sp.chatAvailableModels;
        setState(() {
          _lmModels = models;
          _localModels = const [];
          _selectedModelId ??= sp.settings.selectedModel ??
              (models.isNotEmpty ? models.first.id : null);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _lmModels = sp.chatAvailableModels);
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _selectProvider(String kind) async {
    final sp = context.read<SettingsProvider>();
    setState(() {
      _providerKind = kind;
      _selectedModelId = null;
    });
    await sp.updateSettings(
      sp.settings.copyWith(activeProviderKind: kind),
    );
    await _reloadModels();
  }

  Future<void> _confirm() async {
    final sp = context.read<SettingsProvider>();
    final modelId = _selectedModelId;
    if (modelId == null || modelId.isEmpty) return;

    if (_isOnDevice(_providerKind)) {
      await sp.updateSettings(
        sp.settings.copyWith(
          activeProviderKind: _providerKind,
          selectedLocalModelId: modelId,
        ),
      );
    } else {
      await sp.updateSettings(
        sp.settings.copyWith(activeProviderKind: _providerKind),
      );
      sp.updateSelectedModel(modelId);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cloud = CloudApiService();
    final providers = <(String, String)>[
      ('lmStudio', 'LM Studio'),
      (
        context.read<SettingsProvider>().settings.activeProviderKind ==
                'onDeviceMlx'
            ? 'onDeviceMlx'
            : 'onDeviceGguf',
        'On-Device',
      ),
      if (cloud.providers.any((p) => p.type == CloudApiType.ollama))
        ('ollama', 'Ollama'),
      if (cloud.providers.any((p) => p.type == CloudApiType.omlx))
        ('omlx', 'oMLX'),
      if (cloud.providers.any((p) => p.type == CloudApiType.jan))
        ('jan', 'JAN AI'),
      if (cloud.providers.any((p) => p.type == CloudApiType.unsloth))
        ('unsloth', 'Unsloth'),
      if (SubscriptionService().isPremium &&
          cloud.providers.any((p) => p.type.isPremium))
        ('cloud', 'Cloud'),
    ];

    final options = _modelOptions;

    return AlertDialog(
      title: const Text('Choose provider & model'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'A provider and model are required before chatting.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text('Provider', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (kind, label) in providers)
                  ChoiceChip(
                    label: Text(label),
                    selected: _providerKind == kind ||
                        (_isOnDevice(_providerKind) && _isOnDevice(kind)),
                    onSelected: (_) => _selectProvider(kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Model', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_loadingModels)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _isOnDevice(_providerKind)
                      ? 'No on-device models installed yet.'
                      : 'No models available. Check that the server is running.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    return RadioListTile<String>(
                      value: opt.id,
                      groupValue: _selectedModelId,
                      onChanged: (v) => setState(() => _selectedModelId = v),
                      title: Text(opt.label, maxLines: 2),
                      subtitle:
                          opt.subtitle == null ? null : Text(opt.subtitle!),
                      dense: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedModelId == null || _selectedModelId!.isEmpty
              ? null
              : _confirm,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  List<_ModelOption> get _modelOptions {
    if (_isOnDevice(_providerKind)) {
      return _localModels
          .map((e) => _ModelOption(id: e.spec.id, label: e.spec.displayName))
          .toList();
    }
    return _lmModels
        .map(
          (m) => _ModelOption(
            id: m.id,
            label: m.id.split('/').last,
            subtitle: m.isLoaded ? 'Loaded' : 'Available',
          ),
        )
        .toList();
  }
}

class _ModelOption {
  final String id;
  final String label;
  final String? subtitle;
  const _ModelOption({required this.id, required this.label, this.subtitle});
}
