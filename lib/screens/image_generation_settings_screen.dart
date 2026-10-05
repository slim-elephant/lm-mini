import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/image_generation_service.dart';
import '../services/comfyui_service.dart';
import '../services/image_generation_facade.dart';
import '../services/local_sd_asset_catalog.dart';
import '../services/local_sd_asset_download_service.dart';
import '../utils/layout_utils.dart';
import '../utils/comfyui_catalog.dart';
import '../utils/remote_host_backends.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/shared_host_update_dialog.dart';
import 'local_sd_models_screen.dart';
import 'generated_images_library_screen.dart';

class ImageGenerationSettingsScreen extends StatefulWidget {
  final bool embedded;
  const ImageGenerationSettingsScreen({super.key, this.embedded = false});

  @override
  State<ImageGenerationSettingsScreen> createState() =>
      _ImageGenerationSettingsScreenState();
}

class _ImageGenerationSettingsScreenState
    extends State<ImageGenerationSettingsScreen> {
  static const String _noneComfyUiLoraValue = '__lmmini_none_comfyui_lora__';

  static const _imageModelHelp = '''
Weight files only (.safetensors, .ckpt, and similar). YAML files such as v1-inference.yaml are Stable Diffusion configs, not models — Mini hides those.

Pick the UNET or checkpoint your graph uses. Mini substitutes that filename into the selected workflow.''';

  static const _comfyWorkflowHelp = '''
Mini ships two built-in graphs:

• SD 1.5 / SDXL — one CheckpointLoaderSimple file.
• Z-Image Turbo — UNET + Qwen text encoder + VAE. “qwen_3_4b.safetensors” is the text encoder this model uses (CLIPLoader, type lumina2), not a Qwen chat model. It also needs ae.safetensors as VAE.

Width, height, and seed always come from Image Generation (and a persona’s seed when that persona is active). The built-in Z-Image Turbo graph keeps 8 steps, CFG 1, and res_multistep / simple.

Saved workflows and Last run use the Steps value from Image Generation. Tap “Load settings from workflow” to copy that graph’s CFG, sampler, scheduler, size, seed, model, and its other widgets (CLIP, VAE, shift, megapixels, …) into Mini. After that, edits to those controls are what get sent.

Type a name under “Save workflow as”. The next image you generate is stored under that name in the workflow list, so you can run it again. A new name is added. The same name updates that workflow. Leave the name blank to run without saving.

You can paste a Comfy canvas save (nodes + links) or API JSON. Edit the JSON field to save a copy.

The canvas open in Comfy Desktop is listed as “Last run” after you Run. Placeholders %PROMPT%, %NEGATIVE%, %SEED%, %STEPS%, %CFG%, %WIDTH%, %HEIGHT%, %BATCH%, %SAMPLER%, %SCHEDULER%, %CHECKPOINT%, %LORA%, %LORA_WEIGHT% work in custom JSON.''';

  final _serverUrlController = TextEditingController();
  final _negativePromptController = TextEditingController();
  final _stepsController = TextEditingController();
  final _cfgScaleController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _seedController = TextEditingController();
  final _batchSizeController = TextEditingController();
  final _hrScaleController = TextEditingController();
  final _denoisingController = TextEditingController();
  final _workflowJsonController = TextEditingController();
  final _workflowSaveNameController = TextEditingController();
  final Map<String, TextEditingController> _extraFieldControllers = {};
  bool _loadingWorkflowSettings = false;

  final _service = ImageGenerationService();
  bool _isTesting = false;
  String? _connectionStatus; // null = untested, '' = success, otherwise error

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>().settings;
    _serverUrlController.text = s.imageGenServerUrl;
    _negativePromptController.text = s.imageGenNegativePrompt;
    _stepsController.text = s.imageGenSteps.toString();
    _cfgScaleController.text = s.imageGenCfgScale.toString();
    _widthController.text = s.imageGenWidth.toString();
    _heightController.text = s.imageGenHeight.toString();
    _seedController.text = s.imageGenSeed.toString();
    _batchSizeController.text = s.imageGenBatchSize.toString();
    _hrScaleController.text = s.imageGenHrScale.toString();
    _denoisingController.text = s.imageGenDenoisingStrength.toString();
    _workflowJsonController.text = _workflowFieldTextFor(s);
    _workflowSaveNameController.text = s.comfyUiWorkflowSaveName ?? '';
    _syncExtraFieldControllers(s.comfyUiWorkflowFields, replace: true);

    // If already connected, refresh lists
    if (s.imageGenServerUrl.isNotEmpty || s.isRemoteActive) {
      _refreshLists();
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _negativePromptController.dispose();
    _stepsController.dispose();
    _cfgScaleController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _seedController.dispose();
    _batchSizeController.dispose();
    _hrScaleController.dispose();
    _denoisingController.dispose();
    _workflowJsonController.dispose();
    _workflowSaveNameController.dispose();
    for (final controller in _extraFieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _testConnection() async {
    final s = context.read<SettingsProvider>().settings;
    setState(() {
      _isTesting = true;
      _connectionStatus = null;
    });

    if (s.imageGenProvider == 'onDevice') {
      final err = await testBackendConnection(s);
      if (!mounted) return;
      setState(() {
        _connectionStatus = err ?? '';
        _isTesting = false;
      });
      return;
    }

    var url = s.isRemoteActive
        ? s.effectiveImageGenUrl
        : _serverUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isTesting = false;
        _connectionStatus =
            s.isRemoteActive ? 'Connect is not active' : 'Enter a server URL';
      });
      return;
    }

    // Normalize: strip trailing slash so endpoint paths concat cleanly.
    // Many proxies (RunPod, etc.) reject double-slash paths.
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!s.isRemoteActive && _serverUrlController.text != url) {
      _serverUrlController.text = url;
    }

    final previousImageUrl = s.imageGenServerUrl;
    final settingsProvider = context.read<SettingsProvider>();

    // Save URL first so facade sees the new value (LAN only).
    if (!s.isRemoteActive && s.imageGenServerUrl != url) {
      _save((s) => s.copyWith(imageGenServerUrl: url));
    }
    final probe = s.isRemoteActive
        ? s
        : context.read<SettingsProvider>().settings.copyWith(
              imageGenServerUrl: url,
            );
    final err = await testBackendConnection(probe);
    if (!mounted) return;

    if (err == null) {
      _connectionStatus = '';
      await _refreshLists();
    } else {
      _connectionStatus = err;
    }

    setState(() {
      _isTesting = false;
    });

    if (!mounted) return;
    if (s.isRemoteActive) return;
    final chatUrl = settingsProvider.lanChatBaseUrl();
    if (chatUrl != null && chatUrl.isNotEmpty) {
      await maybeOfferSharedHostUpdate(
        context,
        previousChangedUrl: previousImageUrl,
        newChangedUrl: url,
        peerUrl: chatUrl,
        peer: SharedHostPeer.chat,
        changedName: imageGenBackendLabel(probe),
        peerName: chatBackendDisplayName(settingsProvider),
      );
    }
  }

  Future<void> _refreshLists() async {
    final s = context.read<SettingsProvider>().settings;
    final url = s.isRemoteActive
        ? s.effectiveImageGenUrl.trim()
        : _serverUrlController.text.trim();
    if (url.isEmpty) return;

    await refreshBackendForSettings(s);
    if (!mounted) return;
    final comfy = ComfyUIService();
    final models = comfy.models;
    if (s.imageGenProvider == 'comfyui') {
      final selected = s.imageGenSelectedModel?.trim();
      if (models.isNotEmpty &&
          (selected == null ||
              selected.isEmpty ||
              !isComfyWeightFilename(selected) ||
              !models.any((m) => m.title == selected))) {
        final pick = models.first.title;
        _save((cur) => cur.copyWith(imageGenSelectedModel: pick));
        comfy.switchModel(
          url,
          pick,
          headers: s.imageGenRelayHeaders,
        );
      }
      if ((s.comfyUiWorkflowPath == null ||
              s.comfyUiWorkflowPath!.trim().isEmpty) &&
          !comfy.hasClassicCheckpoints) {
        _save((cur) =>
            cur.copyWith(comfyUiWorkflowPath: kComfyZImageTurboWorkflowPath));
      }
    }
    if (!mounted) return;
    _syncWorkflowJsonField(context.read<SettingsProvider>().settings);
    setState(() {});
  }

  void _save(AppSettings Function(AppSettings) updater) {
    final sp = context.read<SettingsProvider>();
    final updated = updater(sp.settings);
    sp.updateSettings(updated);
  }

  String _workflowFieldTextFor(AppSettings s) {
    final custom = s.comfyUiWorkflowJson;
    if (custom != null && custom.trim().isNotEmpty) return custom;
    final path = s.comfyUiWorkflowPath?.trim() ?? '';
    if (isComfyZImageTurboWorkflowPath(path) ||
        (path.isEmpty && !ComfyUIService().hasClassicCheckpoints)) {
      return kZImageTurboComfyUiWorkflow.trim();
    }
    if (path.isEmpty || isComfySdCheckpointWorkflowPath(path)) {
      return kDefaultComfyUiWorkflow.trim();
    }
    return '';
  }

  bool _workflowJsonEditable(String? path) {
    final value = path?.trim() ?? '';
    return value.isEmpty || isComfyBuiltinWorkflowPath(value);
  }

  void _resetWorkflowJsonToBuiltIn() {
    final path = context.read<SettingsProvider>().settings.comfyUiWorkflowPath;
    _workflowJsonController.text = isComfyZImageTurboWorkflowPath(path)
        ? kZImageTurboComfyUiWorkflow.trim()
        : kDefaultComfyUiWorkflow.trim();
    _save((s) => s.copyWith(comfyUiWorkflowJson: null));
  }

  void _syncWorkflowJsonField(AppSettings s) {
    final next = _workflowFieldTextFor(s);
    if (_workflowJsonController.text != next) {
      _workflowJsonController.text = next;
    }
  }

  void _onWorkflowJsonChanged(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty || isComfyDefaultWorkflowJson(trimmed)) {
      _save((s) => s.copyWith(comfyUiWorkflowJson: null));
    } else {
      _save((s) => s.copyWith(comfyUiWorkflowJson: v));
    }
  }

  String _extraFieldKey(Map<String, dynamic> field) =>
      '${field['nodeId']}|${field['name']}';

  void _syncExtraFieldControllers(
    List<Map<String, dynamic>> fields, {
    bool replace = false,
  }) {
    final live = <String>{};
    for (final field in fields) {
      if (field['value'] is bool) continue;
      final key = _extraFieldKey(field);
      live.add(key);
      final text = field['value']?.toString() ?? '';
      final existing = _extraFieldControllers[key];
      if (existing == null) {
        _extraFieldControllers[key] = TextEditingController(text: text);
      } else if (replace && existing.text != text) {
        existing.text = text;
      }
    }
    for (final key in _extraFieldControllers.keys.toList()) {
      if (live.contains(key)) continue;
      _extraFieldControllers.remove(key)?.dispose();
    }
  }

  Future<void> _loadWorkflowSettings() async {
    if (_loadingWorkflowSettings) return;
    setState(() => _loadingWorkflowSettings = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final s = context.read<SettingsProvider>().settings;
      final template = await _workflowTemplateFor(s);
      if (!mounted) return;
      final graph = comfyGraphFromWorkflowText(template);
      if (graph == null || graph.isEmpty) {
        throw Exception('That workflow has no prompt graph Mini can read.');
      }
      final controls = extractComfyWorkflowControls(graph);
      final fields = [for (final field in controls.fields) field.toJson()];
      _stepsController.text = (controls.steps ?? s.imageGenSteps).toString();
      _cfgScaleController.text =
          (controls.cfg ?? s.imageGenCfgScale).toString();
      _widthController.text = (controls.width ?? s.imageGenWidth).toString();
      _heightController.text = (controls.height ?? s.imageGenHeight).toString();
      if (controls.seed != null) {
        _seedController.text = controls.seed.toString();
      }
      if (controls.batchSize != null) {
        _batchSizeController.text = controls.batchSize.toString();
      }
      _syncExtraFieldControllers(fields, replace: true);
      _save(
        (current) => current.copyWith(
          imageGenSteps: controls.steps ?? current.imageGenSteps,
          imageGenCfgScale: controls.cfg ?? current.imageGenCfgScale,
          imageGenWidth: controls.width ?? current.imageGenWidth,
          imageGenHeight: controls.height ?? current.imageGenHeight,
          imageGenSeed: controls.seed ?? current.imageGenSeed,
          imageGenBatchSize: controls.batchSize ?? current.imageGenBatchSize,
          imageGenSamplerName: controls.sampler ?? current.imageGenSamplerName,
          imageGenScheduler: controls.scheduler ?? current.imageGenScheduler,
          imageGenSelectedModel:
              controls.modelName ?? current.imageGenSelectedModel,
          comfyUiControlsLoadedFrom: comfyWorkflowSettingsKey(
            current.comfyUiWorkflowPath,
            current.comfyUiWorkflowJson,
          ),
          comfyUiWorkflowFields: fields,
        ),
      );
      if (!mounted) return;
      final loadedPath =
          context.read<SettingsProvider>().settings.comfyUiWorkflowPath;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isComfyZImageTurboWorkflowPath(loadedPath)
                ? 'Loaded Z-Image settings. This built-in graph stays at 8 steps, CFG 1, and res_multistep.'
                : 'Loaded settings from the workflow',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load workflow settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingWorkflowSettings = false);
    }
  }

  Future<String> _workflowTemplateFor(AppSettings s) async {
    final path = s.comfyUiWorkflowPath?.trim() ?? '';
    final custom = s.comfyUiWorkflowJson?.trim() ?? '';
    if (path.isEmpty || isComfyBuiltinWorkflowPath(path)) {
      if (path.isEmpty && custom.isNotEmpty) return custom;
      final builtIn = _workflowFieldTextFor(s).trim();
      if (builtIn.isNotEmpty) return builtIn;
    }
    final url = s.isRemoteActive
        ? s.effectiveImageGenUrl.trim()
        : _serverUrlController.text.trim();
    if (url.isEmpty) {
      throw Exception('Set the ComfyUI server URL first.');
    }
    return ComfyUIService().fetchSavedWorkflowTemplate(
      url,
      path,
      headers: s.imageGenRelayHeaders,
    );
  }

  void _updateExtraField(Map<String, dynamic> field, Object value) {
    final key = _extraFieldKey(field);
    final current =
        context.read<SettingsProvider>().settings.comfyUiWorkflowFields;
    final next = [
      for (final entry in current)
        _extraFieldKey(entry) == key ? {...entry, 'value': value} : entry,
    ];
    _save((s) => s.copyWith(comfyUiWorkflowFields: next));
  }

  Object? _parseExtraFieldValue(Object? original, String text) {
    if (original is int) return int.tryParse(text);
    if (original is double) return double.tryParse(text);
    if (original is num) {
      return text.contains('.') ? double.tryParse(text) : int.tryParse(text);
    }
    return text;
  }

  Widget _testButton(AppLocalizations l10n) {
    return FilledButton.tonal(
      onPressed: _isTesting ? null : _testConnection,
      child: _isTesting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.test),
    );
  }

  Widget _connectionStatusText(
      ColorScheme cs, AppLocalizations l10n, AppSettings s) {
    if (_connectionStatus != null && _connectionStatus!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _connectionStatus!,
          style: TextStyle(color: cs.error, fontSize: 12),
        ),
      );
    }
    if (_connectionStatus == '') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '${l10n.connected}${_activeCurrentModel(s) != null ? " — ${_activeCurrentModel(s)}" : ""}',
          style: TextStyle(color: cs.primary, fontSize: 12),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _serverConnectionCard(
    AppSettings s,
    AppLocalizations l10n,
    ColorScheme cs,
    OutlineInputBorder fieldBorder,
  ) {
    return GlassSettingsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.isRemoteActive) ...[
            Text(
              'Using ${RemoteHostBackends.transportLabel(s)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Put the AUTOMATIC1111 or ComfyUI address in LM Mini Connect (or Home Share with phone) on your computer, then tap Test.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _testButton(l10n),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _serverUrlController,
                    decoration: InputDecoration(
                      labelText: l10n.serverUrl,
                      hintText: 'http://192.168.1.50:7860',
                      suffixIcon: _connectionStatusIcon(),
                      border: fieldBorder,
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _testConnection(),
                  ),
                ),
                const SizedBox(width: 8),
                _testButton(l10n),
              ],
            ),
          _connectionStatusText(cs, l10n, s),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final s = sp.settings;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final desktop = prefersWideSettingsLayout(context);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final backendSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, 'Backend'),
        const SizedBox(height: 10),
        GlassSettingsCard(
          padding: const EdgeInsets.all(14),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Image generation backend',
              border: fieldBorder,
              helperText: s.isRemoteActive
                  ? 'Reached through ${RemoteHostBackends.transportLabel(s)}. Set the address in Connect / Home on your computer.'
                  : 'AUTOMATIC1111, ComfyUI, or on-device Core ML (iOS)',
            ),
            value: s.imageGenProvider == 'comfyui'
                ? 'comfyui'
                : s.imageGenProvider == 'onDevice'
                    ? 'onDevice'
                    : 'a1111',
            items: [
              const DropdownMenuItem(
                value: 'a1111',
                child: Text('AUTOMATIC1111 / Forge'),
              ),
              const DropdownMenuItem(
                value: 'comfyui',
                child: Text('ComfyUI'),
              ),
              if (Platform.isIOS)
                const DropdownMenuItem(
                  value: 'onDevice',
                  child: Text('On-device (Core ML)'),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              _save((s) => s.copyWith(imageGenProvider: v));
              setState(() => _connectionStatus = null);
            },
          ),
        ),
      ],
    );

    final promptOptions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, l10n.promptOptions),
        const SizedBox(height: 10),
        GlassSettingsCard(
          child: DesktopSettingsGrid(
            children: [
              _toggleRow(
                context,
                icon: Icons.edit_note_rounded,
                title: l10n.reviewPromptBeforeSending,
                subtitle: 'Edit the image prompt before generating',
                value: s.imageGenReviewPrompt,
                onChanged: (v) =>
                    _save((s) => s.copyWith(imageGenReviewPrompt: v)),
              ),
              _toggleRow(
                context,
                icon: Icons.auto_awesome_rounded,
                title: l10n.autoGenerateImage,
                subtitle:
                    'Automatically generate image when AI provides a prompt',
                value: s.imageGenAutoGenerate,
                onChanged: (v) =>
                    _save((s) => s.copyWith(imageGenAutoGenerate: v)),
              ),
            ],
          ),
        ),
      ],
    );

    return GlassSettingsScaffold(
      embedded: widget.embedded,
      title: l10n.imageGeneration,
      body: DesktopSettingsForm(
        maxWidth: desktop ? 960 : double.infinity,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            desktop ? 0 : 16,
            desktop ? 12 : 20,
            desktop ? 0 : 16,
            36,
          ),
          children: [
            GlassSettingsCard(
              child: _toggleRow(
                context,
                icon: Icons.image_rounded,
                title: l10n.enableImageGeneration,
                subtitle: l10n.showImageButtons,
                value: s.imageGenEnabled,
                onChanged: (v) => _save((s) => s.copyWith(imageGenEnabled: v)),
              ),
            ),
            const SizedBox(height: 12),
            GlassSettingsCard(
              child: _navRow(
                context,
                icon: Icons.photo_library_outlined,
                title: l10n.generatedImagesLibrary,
                subtitle: l10n.generatedImagesLibrarySubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GeneratedImagesLibraryScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (Platform.isIOS) ...[
              _sectionLabel(context, 'On-device (beta)'),
              const SizedBox(height: 10),
              GlassSettingsCard(
                child: _navRow(
                  context,
                  icon: Icons.phone_iphone,
                  title: 'Browse on-device SD models',
                  subtitle:
                      'Download checkpoints, LoRAs, and VAEs to run Stable Diffusion locally.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LocalSdModelsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (s.imageGenProvider != 'onDevice' && desktop)
              SettingsTwoColumn(
                left: backendSection,
                right: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(context, l10n.serverConnection),
                    const SizedBox(height: 10),
                    _serverConnectionCard(s, l10n, cs, fieldBorder),
                  ],
                ),
              )
            else ...[
              backendSection,
              const SizedBox(height: 16),
            ],
            if (s.imageGenProvider == 'onDevice') ...[
              _sectionLabel(context, 'On-device checkpoint'),
              const SizedBox(height: 10),
              GlassSettingsCard(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Column(
                  children: [
                    _navRow(
                      context,
                      icon: Icons.image_outlined,
                      title: () {
                        final id = s.selectedLocalSdCheckpointId;
                        if (id == null || id.isEmpty) {
                          return 'No checkpoint selected';
                        }
                        final spec = LocalSdAssetCatalog.findById(id);
                        return spec?.displayName ?? id;
                      }(),
                      subtitle: () {
                        final id = s.selectedLocalSdCheckpointId;
                        if (id == null) {
                          return 'Download a 1.5–6 GB Core ML model, then tap Use';
                        }
                        final entry =
                            LocalSdAssetDownloadService.instance.entryById(id);
                        if (entry?.status == LocalSdAssetStatus.ready) {
                          return 'Ready on device';
                        }
                        return 'Not downloaded — open the model browser';
                      }(),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LocalSdModelsScreen(),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: _isTesting ? null : _testConnection,
                            child: _isTesting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(l10n.test),
                          ),
                          const SizedBox(width: 12),
                          if (_connectionStatus == '')
                            Text('Pipeline OK',
                                style:
                                    TextStyle(color: cs.primary, fontSize: 12)),
                          if (_connectionStatus != null &&
                              _connectionStatus!.isNotEmpty)
                            Expanded(
                              child: Text(
                                _connectionStatus!,
                                style: TextStyle(color: cs.error, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (s.imageGenProvider != 'onDevice') ...[
              if (!desktop) ...[
                _sectionLabel(context, l10n.serverConnection),
                const SizedBox(height: 10),
                _serverConnectionCard(s, l10n, cs, fieldBorder),
              ],
              if (s.imageGenProvider == 'comfyui' ||
                  _activeModels(s).isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._buildModelSection(s, cs, l10n, fieldBorder),
              ],
              if (s.imageGenProvider == 'comfyui') ...[
                const SizedBox(height: 16),
                ..._buildComfyUiSection(s, cs),
              ],
              const SizedBox(height: 16),
            ],
            promptOptions,
            if (sp.isAdvancedSettings) ...[
              const SizedBox(height: 16),
              GlassSettingsCard(
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const GlassSettingsIcon(Icons.tune_rounded),
                    title: Text(l10n.generationParameters,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Steps, size, sampler, and more'),
                    children: [
                      if (s.imageGenProvider == 'comfyui')
                        _toggleRow(
                          context,
                          icon: Icons.block,
                          title: l10n.comfyUiUseNegativePromptTitle,
                          subtitle: l10n.comfyUiUseNegativePromptSubtitle,
                          value: s.comfyUiUseNegativePrompt,
                          onChanged: (v) => _save(
                              (s) => s.copyWith(comfyUiUseNegativePrompt: v)),
                        ),
                      if (s.imageGenProvider != 'comfyui' ||
                          s.comfyUiUseNegativePrompt)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: TextField(
                            controller: _negativePromptController,
                            decoration: InputDecoration(
                              labelText: l10n.negativePrompt,
                              border: fieldBorder,
                            ),
                            maxLines: 2,
                            onChanged: (v) => _save(
                                (s) => s.copyWith(imageGenNegativePrompt: v)),
                          ),
                        ),
                      if (s.imageGenProvider != 'comfyui')
                        ..._generationControlFields(s, l10n, fieldBorder),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: DesktopSettingsGrid(
                          children: [
                            _toggleRow(
                              context,
                              icon: Icons.face_retouching_natural,
                              title: l10n.restoreFaces,
                              subtitle: 'Fix faces in generated images',
                              value: s.imageGenRestoreFaces,
                              onChanged: (v) => _save(
                                  (s) => s.copyWith(imageGenRestoreFaces: v)),
                            ),
                            _toggleRow(
                              context,
                              icon: Icons.grid_on_rounded,
                              title: l10n.tiling,
                              subtitle: 'Generate seamless tileable textures',
                              value: s.imageGenTiling,
                              onChanged: (v) =>
                                  _save((s) => s.copyWith(imageGenTiling: v)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.restore),
                          label: Text(l10n.resetToDefaults),
                          onPressed: _resetToDefaults,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _navRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _sectionLabel(
    BuildContext context,
    String title, {
    VoidCallback? onInfo,
  }) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        );
    if (onInfo == null) {
      return Text(title, style: style);
    }
    return Row(
      children: [
        Expanded(child: Text(title, style: style)),
        IconButton(
          tooltip: 'About',
          onPressed: onInfo,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Future<void> _showHelpDialog({
    required String title,
    required String body,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              body,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget? _connectionStatusIcon() {
    if (_isTesting) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_connectionStatus == '') {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (_connectionStatus != null && _connectionStatus!.isNotEmpty) {
      return const Icon(Icons.error, color: Colors.red);
    }
    return null;
  }

  String _resolveSampler(String name) {
    final trimmed = name.trim();
    final match = _service.samplers.where((s) => s.name == trimmed);
    if (match.isNotEmpty) return match.first.name;
    if (trimmed.isNotEmpty) return trimmed;
    return _service.samplers.isNotEmpty
        ? _service.samplers.first.name
        : trimmed;
  }

  String _resolveScheduler(String? name) {
    if (name == null || name.isEmpty) return '';
    final match = _service.schedulers.where((s) => s.name == name);
    if (match.isNotEmpty) return match.first.name;
    return name;
  }

  List<Widget> _comfyWorkflowSettings(AppSettings s, ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final loaded = s.comfyUiControlsLoadedFrom != null &&
        s.comfyUiControlsLoadedFrom ==
            comfyWorkflowSettingsKey(
              s.comfyUiWorkflowPath,
              s.comfyUiWorkflowJson,
            );
    final zImage = isComfyZImageTurboWorkflowPath(s.comfyUiWorkflowPath);
    final note = zImage
        ? 'Built-in Z-Image stays at 8 steps, CFG 1, and res_multistep / simple. Load still fills the fields below so you can see them.'
        : loaded
            ? 'Steps, CFG, sampler, and scheduler below are sent with each image. Other widgets from the workflow follow.'
            : 'The steps below are sent with each image. Load the workflow to copy its CFG, sampler, scheduler, size, and other widgets.';
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _loadingWorkflowSettings ? null : _loadWorkflowSettings,
          icon: _loadingWorkflowSettings
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded, size: 18),
          label: const Text('Load settings from workflow'),
        ),
      ),
      Text(
        note,
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
      const SizedBox(height: 8),
      ..._generationControlFields(s, l10n, fieldBorder),
      ..._extraWorkflowFields(s, cs, fieldBorder),
    ];
  }

  List<Widget> _extraWorkflowFields(
    AppSettings s,
    ColorScheme cs,
    OutlineInputBorder fieldBorder,
  ) {
    final fields = s.comfyUiWorkflowFields;
    if (fields.isEmpty) return const [];
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Text(
          'Other workflow fields',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    ];
    String? lastClass;
    for (final field in fields) {
      final classType = field['classType']?.toString() ?? '';
      if (classType.isNotEmpty && classType != lastClass) {
        lastClass = classType;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              classType,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      }
      final name = field['name']?.toString() ?? '';
      final label = name.replaceAll('_', ' ');
      final value = field['value'];
      if (value is bool) {
        children.add(
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            value: value,
            onChanged: (next) => _updateExtraField(field, next),
          ),
        );
        continue;
      }
      final key = _extraFieldKey(field);
      final controller = _extraFieldControllers.putIfAbsent(
        key,
        () => TextEditingController(text: value?.toString() ?? ''),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: fieldBorder,
            ),
            keyboardType: value is num
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            onChanged: (text) {
              final parsed = _parseExtraFieldValue(value, text);
              if (parsed == null) return;
              _updateExtraField(field, parsed);
            },
          ),
        ),
      );
    }
    return children;
  }

  List<Widget> _generationControlFields(
    AppSettings s,
    AppLocalizations l10n,
    OutlineInputBorder fieldBorder,
  ) {
    final samplerValue = _resolveSampler(s.imageGenSamplerName);
    final schedulerValue = _resolveScheduler(s.imageGenScheduler);
    final samplerItems = _service.samplers
        .map((m) => DropdownMenuItem(
              value: m.name,
              child: Text(m.name, overflow: TextOverflow.ellipsis),
            ))
        .toList();
    if (samplerValue.isNotEmpty &&
        !samplerItems.any((item) => item.value == samplerValue)) {
      samplerItems.insert(
        0,
        DropdownMenuItem(
          value: samplerValue,
          child: Text(samplerValue, overflow: TextOverflow.ellipsis),
        ),
      );
    }
    final schedulerItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text(l10n.automatic)),
      ..._service.schedulers.map((m) => DropdownMenuItem(
            value: m.name,
            child: Text(m.label, overflow: TextOverflow.ellipsis),
          )),
    ];
    if (schedulerValue.isNotEmpty &&
        !schedulerItems.any((item) => item.value == schedulerValue)) {
      schedulerItems.add(
        DropdownMenuItem(
          value: schedulerValue,
          child: Text(schedulerValue, overflow: TextOverflow.ellipsis),
        ),
      );
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: DesktopSettingsGrid(
          children: [
            TextField(
              controller: _stepsController,
              decoration: InputDecoration(
                labelText: l10n.steps,
                border: fieldBorder,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n > 0) {
                  _save((s) => s.copyWith(imageGenSteps: n));
                }
              },
            ),
            TextField(
              controller: _cfgScaleController,
              decoration: InputDecoration(
                labelText: l10n.cfgScale,
                border: fieldBorder,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null && n > 0) {
                  _save((s) => s.copyWith(imageGenCfgScale: n));
                }
              },
            ),
            TextField(
              controller: _widthController,
              decoration: InputDecoration(
                labelText: l10n.width,
                border: fieldBorder,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n >= 64) {
                  _save((s) => s.copyWith(imageGenWidth: n));
                }
              },
            ),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: l10n.height,
                border: fieldBorder,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n >= 64) {
                  _save((s) => s.copyWith(imageGenHeight: n));
                }
              },
            ),
            TextField(
              controller: _seedController,
              decoration: InputDecoration(
                labelText: l10n.seedLabel,
                border: fieldBorder,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null) {
                  _save((s) => s.copyWith(imageGenSeed: n));
                }
              },
            ),
            TextField(
              controller: _batchSizeController,
              decoration: InputDecoration(
                labelText: l10n.batchSize,
                border: fieldBorder,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n > 0) {
                  _save((s) => s.copyWith(imageGenBatchSize: n));
                }
              },
            ),
          ],
        ),
      ),
      if (samplerItems.isNotEmpty || schedulerItems.length > 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: DesktopSettingsGrid(
            children: [
              if (samplerItems.isNotEmpty)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.sampler,
                    border: fieldBorder,
                  ),
                  value: samplerValue,
                  items: samplerItems,
                  onChanged: (v) {
                    if (v != null) {
                      _save((s) => s.copyWith(imageGenSamplerName: v));
                    }
                  },
                ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.scheduler,
                  border: fieldBorder,
                ),
                value: schedulerValue,
                items: schedulerItems,
                onChanged: (v) {
                  _save((s) => s.copyWith(
                      imageGenScheduler: (v == null || v.isEmpty) ? null : v));
                },
              ),
            ],
          ),
        ),
    ];
  }

  // String? _resolveUpscaler(String? name) {
  //   if (name == null) {
  //     return _service.upscalers.isNotEmpty
  //         ? _service.upscalers.first.name
  //         : null;
  //   }
  //   final match = _service.upscalers.where((u) => u.name == name);
  //   if (match.isNotEmpty) return match.first.name;
  //   return _service.upscalers.isNotEmpty
  //       ? _service.upscalers.first.name
  //       : null;
  // }

  void _resetToDefaults() {
    final sp = context.read<SettingsProvider>();
    sp.updateSettings(sp.settings.copyWith(
      imageGenNegativePrompt: 'blurry, bad quality, worst quality, low quality',
      imageGenSteps: 20,
      imageGenCfgScale: 7.0,
      imageGenWidth: 512,
      imageGenHeight: 512,
      imageGenSamplerName: 'Euler a',
      imageGenScheduler: null,
      imageGenSeed: -1,
      imageGenBatchSize: 1,
      imageGenEnableHr: false,
      imageGenHrScale: 2.0,
      imageGenHrUpscaler: null,
      imageGenDenoisingStrength: 0.7,
      imageGenRestoreFaces: false,
      imageGenTiling: false,
    ));
    // Reload text fields
    _negativePromptController.text =
        'blurry, bad quality, worst quality, low quality';
    _stepsController.text = '20';
    _cfgScaleController.text = '7.0';
    _widthController.text = '512';
    _heightController.text = '512';
    _seedController.text = '-1';
    _batchSizeController.text = '1';
    _hrScaleController.text = '2.0';
    _denoisingController.text = '0.7';
    setState(() {});
  }

  // ── Provider-aware helpers ──────────────────────────────────────────

  List<SDModel> _activeModels(AppSettings s) {
    return s.imageGenProvider == 'comfyui'
        ? ComfyUIService().models
        : _service.models;
  }

  String? _activeCurrentModel(AppSettings s) {
    return s.imageGenProvider == 'comfyui'
        ? ComfyUIService().currentModel
        : _service.currentModel;
  }

  String? _modelDropdownValue(AppSettings s) {
    final selected = s.imageGenSelectedModel;
    if (s.imageGenProvider == 'comfyui' &&
        selected != null &&
        selected.trim().isNotEmpty &&
        !_activeModels(s).any((m) => m.title == selected)) {
      return selected;
    }
    return _resolveActiveModel(s, selected);
  }

  String? _resolveActiveModel(AppSettings s, String? title) {
    final models = _activeModels(s);
    if (models.isEmpty) return null;
    if (title != null && models.any((m) => m.title == title)) return title;
    final current = _activeCurrentModel(s);
    if (current != null && models.any((m) => m.title == current)) {
      return current;
    }
    return models.first.title;
  }

  List<Widget> _buildModelSection(
    AppSettings s,
    ColorScheme cs,
    AppLocalizations l10n,
    OutlineInputBorder fieldBorder,
  ) {
    final isComfy = s.imageGenProvider == 'comfyui';
    return [
      _sectionLabel(
        context,
        isComfy ? 'Image model' : l10n.model,
        onInfo: isComfy
            ? () => _showHelpDialog(
                  title: 'Image model',
                  body: _imageModelHelp,
                )
            : null,
      ),
      const SizedBox(height: 10),
      GlassSettingsCard(
        padding: const EdgeInsets.all(14),
        child: _activeModels(s).isEmpty &&
                !(isComfy && (s.imageGenSelectedModel ?? '').trim().isNotEmpty)
            ? Text(
                isComfy
                    ? 'No weight files listed yet. Tap Test connection or Refresh after ComfyUI has loaded a graph.'
                    : 'No models listed yet. Tap Test connection.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.35,
                ),
              )
            : DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: isComfy ? 'Image model' : l10n.checkpoint,
                  border: fieldBorder,
                ),
                value: _modelDropdownValue(s),
                items: [
                  if (isComfy &&
                      (s.imageGenSelectedModel ?? '').trim().isNotEmpty &&
                      !_activeModels(s)
                          .any((m) => m.title == s.imageGenSelectedModel))
                    DropdownMenuItem(
                      value: s.imageGenSelectedModel,
                      child: Text(
                        s.imageGenSelectedModel!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ..._activeModels(s).map((m) => DropdownMenuItem(
                        value: m.title,
                        child: Text(
                          m.modelName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _save((s) => s.copyWith(imageGenSelectedModel: v));
                  final settings = context.read<SettingsProvider>().settings;
                  final effectiveUrl = settings.isRemoteActive
                      ? settings.effectiveImageGenUrl
                      : _serverUrlController.text.trim();
                  if (settings.imageGenProvider == 'comfyui') {
                    ComfyUIService().switchModel(
                      effectiveUrl,
                      v,
                      headers: settings.imageGenRelayHeaders,
                    );
                  } else {
                    _service.switchModel(
                      effectiveUrl,
                      v,
                      headers: settings.imageGenRelayHeaders,
                    );
                  }
                },
              ),
      ),
    ];
  }

  // ── ComfyUI workflow editor ────────────────────────────────────────

  List<Widget> _buildComfyUiSection(AppSettings s, ColorScheme cs) {
    final savedWorkflows = ComfyUIService().savedWorkflows;
    final selectedWorkflowPath = s.comfyUiWorkflowPath;
    final workflowText = s.comfyUiWorkflowJson ?? '';
    final clientId = s.comfyUiClientId ?? '';
    final loras = ComfyUIService().loras;
    final selectedLora = s.comfyUiLoraName;
    final workflowDropdownItems = <DropdownMenuItem<String>>[
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
    final dropdownValue = () {
      if (selectedWorkflowPath == null || selectedWorkflowPath.isEmpty) {
        return ComfyUIService().hasClassicCheckpoints
            ? kComfySdCheckpointWorkflowPath
            : kComfyZImageTurboWorkflowPath;
      }
      return selectedWorkflowPath;
    }();
    final jsonEditable = _workflowJsonEditable(selectedWorkflowPath);
    if (selectedWorkflowPath != null &&
        selectedWorkflowPath.isNotEmpty &&
        !savedWorkflows
            .any((workflow) => workflow.path == selectedWorkflowPath)) {
      workflowDropdownItems.add(
        DropdownMenuItem<String>(
          value: selectedWorkflowPath,
          child: Text(
            isComfyLastRunWorkflowPath(selectedWorkflowPath)
                ? 'Last run in ComfyUI (run a graph, then Refresh)'
                : '$selectedWorkflowPath (currently unavailable)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final loraDropdownItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: _noneComfyUiLoraValue,
        child: Text('None'),
      ),
      ...loras.map(
        (name) => DropdownMenuItem<String>(
          value: name,
          child: Text(name, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];
    if (selectedLora != null &&
        selectedLora.isNotEmpty &&
        !loras.contains(selectedLora)) {
      loraDropdownItems.add(
        DropdownMenuItem<String>(
          value: selectedLora,
          child: Text(
            '$selectedLora (currently unavailable)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return [
      _sectionLabel(
        context,
        'ComfyUI workflow',
        onInfo: () => _showHelpDialog(
          title: 'ComfyUI workflow',
          body: _comfyWorkflowHelp,
        ),
      ),
      const SizedBox(height: 10),
      GlassSettingsCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loras.isNotEmpty ||
                (selectedLora != null && selectedLora.isNotEmpty))
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'LoRA (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                value: (selectedLora == null || selectedLora.isEmpty)
                    ? _noneComfyUiLoraValue
                    : selectedLora,
                items: loraDropdownItems,
                onChanged: (v) {
                  if (v == null) return;
                  _save(
                    (s) => s.copyWith(
                      comfyUiLoraName: v == _noneComfyUiLoraValue ? null : v,
                    ),
                  );
                },
              )
            else
              TextField(
                controller: TextEditingController(text: selectedLora ?? '')
                  ..selection = TextSelection.collapsed(
                      offset: (selectedLora ?? '').length),
                decoration: InputDecoration(
                  labelText: 'LoRA filename (optional)',
                  hintText: 'e.g. my_lora.safetensors',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (v) => _save(
                  (s) => s.copyWith(
                    comfyUiLoraName: v.trim().isEmpty ? null : v.trim(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'LoRA weight: ${s.comfyUiLoraWeight.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
            Slider(
              value: s.comfyUiLoraWeight.clamp(0.0, 2.0),
              min: 0.0,
              max: 2.0,
              divisions: 40,
              label: s.comfyUiLoraWeight.toStringAsFixed(2),
              onChanged: (v) => _save(
                (s) => s.copyWith(
                  comfyUiLoraWeight: double.parse(v.toStringAsFixed(2)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'ComfyUI workflow',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    value: dropdownValue,
                    items: workflowDropdownItems,
                    onChanged: (v) {
                      if (v == null) return;
                      _save(
                        (s) => s.copyWith(
                          comfyUiWorkflowPath: v,
                          comfyUiWorkflowJson: null,
                          comfyUiControlsLoadedFrom: null,
                          comfyUiWorkflowFields: const [],
                        ),
                      );
                      _syncExtraFieldControllers(const []);
                      _syncWorkflowJsonField(
                        context.read<SettingsProvider>().settings,
                      );
                      _loadWorkflowSettings();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh workflows',
                  onPressed: _refreshLists,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (!savedWorkflows.any((workflow) =>
                !isComfyBuiltinWorkflowPath(workflow.path) &&
                !isComfyLastRunWorkflowPath(workflow.path)))
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'No saved graphs yet. Name one below, then generate an image. Or run a graph in Comfy Desktop and tap Refresh.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _workflowSaveNameController,
              decoration: InputDecoration(
                labelText: 'Save workflow as',
                hintText: 'Qwen Image',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                helperMaxLines: 3,
                helperText:
                    'The next image you generate is saved under this name in the list above. A new name is added. The same name updates that workflow. Leave blank to run without saving.',
              ),
              onChanged: (value) => _save(
                (s) => s.copyWith(
                  comfyUiWorkflowSaveName: value.trim().isEmpty ? null : value,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._comfyWorkflowSettings(s, cs),
            const SizedBox(height: 8),
            TextField(
              enabled: jsonEditable,
              maxLines: 14,
              minLines: 8,
              controller: _workflowJsonController,
              decoration: InputDecoration(
                labelText: 'Workflow JSON',
                hintText: 'Mini’s built-in graph',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                alignLabelWithHint: true,
                helperMaxLines: 3,
                helperText: jsonEditable
                    ? ((workflowText.isNotEmpty &&
                            !isComfyDefaultWorkflowJson(workflowText))
                        ? 'Saved copy of the graph (${workflowText.length} chars)'
                        : 'Mini’s built-in graph. Seed, width, and height come from Image Generation. Edit to save your own copy.')
                    : 'Ignored while a saved or last-run workflow is selected',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              onChanged: _onWorkflowJsonChanged,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reset to Mini built-in'),
                onPressed: (workflowText.isNotEmpty &&
                        !isComfyDefaultWorkflowJson(workflowText))
                    ? _resetWorkflowJsonToBuiltIn
                    : null,
              ),
            ),
            TextField(
              controller: TextEditingController(text: clientId)
                ..selection = TextSelection.collapsed(offset: clientId.length),
              decoration: InputDecoration(
                labelText: 'Client ID (optional)',
                hintText: 'Leave empty to auto-generate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (v) => _save(
                (s) => s.copyWith(
                  comfyUiClientId: v.trim().isEmpty ? null : v,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
