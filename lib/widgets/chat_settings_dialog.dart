import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/chat_conversation.dart';
import '../models/lm_studio_model.dart';
import '../models/local_model_spec.dart';
import '../models/system_prompt.dart';
import '../providers/settings_provider.dart';
import '../utils/chat_reasoning_toggle.dart';
import '../utils/remote_host_backends.dart';
import '../services/lm_studio_service.dart';
import '../services/local_model_download_service.dart';
import '../services/tool_support_resolver.dart';
import '../utils/image_picker_helper.dart';
import 'glass_blur.dart';

/// Dialog for overriding global settings at the chat level
class ChatSettingsDialog extends StatefulWidget {
  final ChatConversation conversation;

  const ChatSettingsDialog({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<ChatSettingsDialog> {
  static const _onDeviceProviderKey = '__on_device__';

  final _systemPromptController = TextEditingController();
  final _userNameController = TextEditingController();

  // Override flags
  bool _overrideModel = false;
  bool _overrideSystemPrompt = false;
  bool _overrideTemperature = false;

  // System prompt override mode: 'saved' or 'custom'
  String _systemPromptMode = 'saved';
  String? _selectedSystemPromptId;
  bool _overrideMaxTokens = false;
  bool _overrideTopP = false;
  bool _overrideTopK = false;
  bool _overrideMinP = false;
  bool _overrideRepeatPenalty = false;
  bool _overrideContextLength = false;
  bool _overrideMemory = false;
  bool _overrideToolUse = false;
  bool _overrideWebSearch = false;

  // Override values
  String? _selectedModel;
  double _temperature = 0.8;
  int _maxTokens = 2048;
  double _topP = 0.9;
  int _topK = 40;
  double _minP = 0.05;
  double _repeatPenalty = 1.1;
  int _contextLength = 4096;
  bool _enableToolUse = true;
  bool _enableWebSearch = true;
  bool _reasoningEnabled = true;

  // Group chat settings
  String _turnMode = 'roundRobin';
  bool _autonomousMode = false;
  bool _parallelStreaming = false;
  bool _autoLoadUnload = false;
  bool _respondToUserOnly = false;

  List<LMStudioModel> _availableModels = [];
  List<String> _cloudModelIds = [];
  List<LocalModelEntry> _onDeviceModels = [];
  bool _loadingModels = true;

  /// `null` = LM Studio, [_onDeviceProviderKey] = on-device, else cloud provider id.
  String? _selectedProviderId;
  bool _modelNotFound = false; // True if saved model no longer exists

  bool get _isOnDeviceProvider => _selectedProviderId == _onDeviceProviderKey;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadModels();
  }

  void _loadSettings() {
    final settings = widget.conversation.settings;
    final globalSettings = context.read<SettingsProvider>().settings;
    final isGroup = settings['isGroupChat'] == true;

    // Check which settings are overridden
    _overrideModel = settings.containsKey('model');
    _overrideTemperature = settings.containsKey('temperature');

    if (isGroup) {
      // Group wizard stores scene/context in `scenario` (+ optional `userName`).
      // Chat Settings used to bind this section to `systemPrompt`, which made
      // the wizard values look "ignored" and showed the global Mini persona.
      final scenario = (settings['scenario'] as String?)?.trim() ?? '';
      final legacyPrompt = (settings['systemPrompt'] as String?)?.trim() ?? '';
      final globalPrompt = globalSettings.systemPrompt.trim();
      final legacyIsCustom =
          legacyPrompt.isNotEmpty && legacyPrompt != globalPrompt;
      _overrideSystemPrompt = scenario.isNotEmpty || legacyIsCustom;
      _systemPromptMode = 'custom';
      _systemPromptController.text =
          scenario.isNotEmpty ? scenario : (legacyIsCustom ? legacyPrompt : '');
      _selectedSystemPromptId = null;
    } else {
      _overrideSystemPrompt = settings.containsKey('systemPrompt') ||
          settings.containsKey('systemPromptId');
      if (settings.containsKey('systemPromptId')) {
        _systemPromptMode = 'saved';
        _selectedSystemPromptId = settings['systemPromptId'] as String?;
        _systemPromptController.text =
            settings['systemPrompt'] as String? ?? globalSettings.systemPrompt;
      } else if (settings.containsKey('systemPrompt')) {
        _systemPromptMode = 'custom';
        _systemPromptController.text =
            settings['systemPrompt'] as String? ?? globalSettings.systemPrompt;
      } else {
        _systemPromptController.text = globalSettings.systemPrompt;
      }
    }
    _overrideMaxTokens = settings.containsKey('maxTokens');
    _overrideTopP = settings.containsKey('topP');
    _overrideTopK = settings.containsKey('topK');
    _overrideMinP = settings.containsKey('minP');
    _overrideRepeatPenalty = settings.containsKey('repeatPenalty');
    _overrideContextLength = settings.containsKey('contextLength');
    _overrideMemory = settings.containsKey('memoryEnabled');
    _overrideToolUse = settings.containsKey('enableToolUse');
    _overrideWebSearch = settings.containsKey('enableWebSearch');

    // Load provider (chat override if present, else mirror global so the
    // picker opens on the right backend — including on-device).
    // Prefer providerKind over a stale cloudProviderId leftover — the latter
    // used to hide LM Studio-only controls (e.g. Reasoning) incorrectly.
    final providerKind = settings['providerKind']?.toString();
    if (_overrideModel) {
      if (providerKind == 'onDeviceGguf' || providerKind == 'onDeviceMlx') {
        _selectedProviderId = _onDeviceProviderKey;
      } else if (providerKind == 'lmStudio') {
        _selectedProviderId = null;
      } else if (providerKind == 'lmMiniDesktop') {
        _selectedProviderId = RemoteHostBackends.lmMiniDesktop;
      } else if (providerKind == 'ollama' ||
          providerKind == 'omlx' ||
          providerKind == 'jan' ||
          providerKind == 'unsloth') {
        _selectedProviderId = globalSettings.isRemoteActive
            ? providerKind
            : (settings['cloudProviderId'] as String? ?? providerKind);
      } else if (providerKind == 'cloud' ||
          settings['cloudProviderId'] != null) {
        _selectedProviderId = settings['cloudProviderId'] as String?;
      } else {
        _selectedProviderId = null;
      }
    } else {
      final gk = globalSettings.activeProviderKind;
      if (gk == 'onDeviceGguf' || gk == 'onDeviceMlx') {
        _selectedProviderId = _onDeviceProviderKey;
      } else if (gk == 'lmMiniDesktop') {
        _selectedProviderId = RemoteHostBackends.lmMiniDesktop;
      } else if (globalSettings.isRemoteActive &&
          RemoteHostBackends.isLlmKind(gk) &&
          gk != 'lmStudio') {
        _selectedProviderId = gk;
      } else if (SettingsProvider.isCloudProviderKind(gk)) {
        _selectedProviderId =
            context.read<SettingsProvider>().resolveCloudProvider()?.id;
      } else {
        _selectedProviderId = null;
      }
    }

    // Load values (use override if exists, otherwise global)
    if (_isOnDeviceProvider) {
      _selectedModel =
          settings['model'] as String? ?? globalSettings.selectedLocalModelId;
    } else {
      _selectedModel =
          settings['model'] as String? ?? globalSettings.selectedModel;
    }
    _temperature = (settings['temperature'] as num?)?.toDouble() ??
        globalSettings.temperature;
    _maxTokens =
        (settings['maxTokens'] as num?)?.toInt() ?? globalSettings.maxTokens;
    _topP = (settings['topP'] as num?)?.toDouble() ?? globalSettings.topP;
    _topK = (settings['topK'] as num?)?.toInt() ?? globalSettings.topK;
    _minP = (settings['minP'] as num?)?.toDouble() ?? globalSettings.minP;
    _repeatPenalty = (settings['repeatPenalty'] as num?)?.toDouble() ??
        globalSettings.repeatPenalty;
    _contextLength = (settings['contextLength'] as num?)?.toInt() ??
        globalSettings.loadContextLength ??
        globalSettings.contextWindow;
    _enableToolUse =
        settings['enableToolUse'] as bool? ?? globalSettings.enableToolUse;
    _enableWebSearch =
        settings['enableWebSearch'] as bool? ?? globalSettings.enableWebSearch;
    _reasoningEnabled = settings.containsKey('reasoningEnabled')
        ? (settings['reasoningEnabled'] as bool? ?? true)
        : globalSettings.reasoning != 'off';

    // Group chat settings
    _turnMode = settings['turnMode'] as String? ?? 'roundRobin';
    _autonomousMode = settings['autonomousMode'] as bool? ?? false;
    _parallelStreaming = settings['parallelStreaming'] as bool? ?? false;
    _autoLoadUnload = settings['autoLoadUnload'] as bool? ?? false;
    _respondToUserOnly = settings['respondToUserOnly'] as bool? ?? false;
    _userNameController.text = (settings['userName'] as String?) ?? '';
  }

  Future<void> _loadModels() async {
    final settingsProvider = context.read<SettingsProvider>();
    final isPremium = SubscriptionService().isPremium;

    try {
      if (_isOnDeviceProvider) {
        final svc = LocalModelDownloadService.instance;
        if (!svc.entries.any((e) => e.status == LocalModelStatus.ready)) {
          // Ensure catalog is hydrated before listing ready models.
          await svc.init();
        }
        _onDeviceModels = List<LocalModelEntry>.from(svc.readyEntries)
          ..sort((a, b) => a.spec.displayName.toLowerCase().compareTo(
                b.spec.displayName.toLowerCase(),
              ));
        _availableModels = [];
        _cloudModelIds = [];
      } else if (_selectedProviderId == RemoteHostBackends.lmMiniDesktop) {
        _availableModels = await settingsProvider
            .fetchModelsForBackend(RemoteHostBackends.lmMiniDesktop);
        _cloudModelIds = [];
        _onDeviceModels = [];
      } else if (_selectedProviderId != null &&
          settingsProvider.settings.isRemoteActive &&
          RemoteHostBackends.isLlmKind(_selectedProviderId!)) {
        _availableModels =
            await settingsProvider.fetchModelsForBackend(_selectedProviderId!);
        _cloudModelIds = [];
        _onDeviceModels = [];
      } else if (_selectedProviderId != null) {
        final cloudService = CloudApiService();
        final provider = cloudService.providers
            .where((p) => p.id == _selectedProviderId)
            .firstOrNull;
        if (provider != null && (isPremium || !provider.type.isPremium)) {
          _cloudModelIds = (await cloudService.fetchModels(provider))
              .where((id) => !LMStudioModel.looksLikeEmbeddingModel(id))
              .toList();
          _availableModels = [];
          _onDeviceModels = [];
        } else {
          _cloudModelIds = [];
          _availableModels = [];
          _onDeviceModels = [];
        }
      } else {
        final kind =
            settingsProvider.settings.isRemoteActive ? 'lmStudio' : 'lmStudio';
        _availableModels = await settingsProvider.fetchModelsForBackend(kind);
        _cloudModelIds = [];
        _onDeviceModels = [];
      }

      // Validate selected model exists
      _validateSelectedModel();

      if (mounted) {
        setState(() {
          _loadingModels = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading models in chat settings: $e');
      if (mounted) {
        setState(() {
          _loadingModels = false;
        });
      }
    }
  }

  void _validateSelectedModel() {
    if (!_overrideModel || _selectedModel == null) {
      _modelNotFound = false;
      return;
    }
    if (_isOnDeviceProvider) {
      _modelNotFound = _onDeviceModels.isEmpty ||
          !_onDeviceModels.any((e) => e.spec.id == _selectedModel);
    } else if (_selectedProviderId != null) {
      _modelNotFound =
          _cloudModelIds.isEmpty || !_cloudModelIds.contains(_selectedModel);
    } else {
      _modelNotFound = _availableModels.isEmpty ||
          !_availableModels.any((m) => m.id == _selectedModel);
    }
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildSettingsOverrides() {
    final overrides = Map<String, dynamic>.from(widget.conversation.settings);
    final globalSettings = context.read<SettingsProvider>().settings;
    final globalReasoningOn = globalSettings.reasoning != 'off';
    final gateSettings = _reasoningGateSettings(globalSettings);
    final chatCloudId = _reasoningChatCloudProviderId();
    final showReasoningToggle = ChatReasoningToggle.shouldShow(
      settings: gateSettings,
      chatCloudProviderId: chatCloudId,
      availableModels: _availableModels,
      resolveLmStudioModel:
          context.read<SettingsProvider>().resolveLmStudioModel,
    );

    // Model + Provider
    if (_overrideModel && _selectedModel != null) {
      overrides['model'] = _selectedModel;
      if (_isOnDeviceProvider) {
        final entry = _onDeviceModels
            .where((e) => e.spec.id == _selectedModel)
            .firstOrNull;
        final engine = entry?.spec.engine ?? LocalEngine.fllama;
        overrides['providerKind'] =
            engine == LocalEngine.mlx ? 'onDeviceMlx' : 'onDeviceGguf';
        overrides.remove('cloudProviderId');
      } else if (_selectedProviderId == RemoteHostBackends.lmMiniDesktop) {
        overrides['providerKind'] = RemoteHostBackends.lmMiniDesktop;
        overrides.remove('cloudProviderId');
      } else if (_selectedProviderId != null &&
          RemoteHostBackends.isLlmKind(_selectedProviderId!)) {
        overrides['providerKind'] = _selectedProviderId;
        final cloudId = CloudApiService()
            .providers
            .where((p) => p.type.providerKind == _selectedProviderId)
            .firstOrNull
            ?.id;
        if (cloudId != null) {
          overrides['cloudProviderId'] = cloudId;
        } else {
          overrides.remove('cloudProviderId');
        }
      } else if (_selectedProviderId != null) {
        overrides['cloudProviderId'] = _selectedProviderId;
        final provider = CloudApiService()
            .providers
            .where((p) => p.id == _selectedProviderId)
            .firstOrNull;
        overrides['providerKind'] = provider?.type.providerKind ?? 'cloud';
      } else {
        overrides['providerKind'] = 'lmStudio';
        overrides.remove('cloudProviderId');
      }
    } else {
      overrides.remove('model');
      overrides.remove('cloudProviderId');
      overrides.remove('providerKind');
    }

    // System Prompt / Group scenario
    final isGroupChat = widget.conversation.settings['isGroupChat'] == true;
    if (isGroupChat) {
      // Persist wizard-compatible keys used by group send prompts.
      final scenarioText = _systemPromptController.text.trim();
      if (_overrideSystemPrompt && scenarioText.isNotEmpty) {
        overrides['scenario'] = scenarioText;
      } else {
        overrides.remove('scenario');
      }
      // Don't keep a mistaken systemPrompt override as the "scenario".
      overrides.remove('systemPrompt');
      overrides.remove('systemPromptId');

      final userName = _userNameController.text.trim();
      if (userName.isNotEmpty) {
        overrides['userName'] = userName;
      } else {
        overrides.remove('userName');
      }
    } else if (_overrideSystemPrompt) {
      if (_systemPromptMode == 'saved' && _selectedSystemPromptId != null) {
        overrides['systemPromptId'] = _selectedSystemPromptId;
        // Also store the actual content so it works even if the saved prompt is deleted
        final savedPrompts =
            context.read<SettingsProvider>().settings.savedSystemPrompts ?? [];
        final matches =
            savedPrompts.where((p) => p.id == _selectedSystemPromptId);
        if (matches.isNotEmpty) {
          overrides['systemPrompt'] = matches.first.content;
        }
      } else {
        overrides['systemPrompt'] = _systemPromptController.text;
        overrides.remove('systemPromptId');
      }
    } else {
      overrides.remove('systemPrompt');
      overrides.remove('systemPromptId');
    }

    // Temperature
    if (_overrideTemperature) {
      overrides['temperature'] = _temperature;
    } else {
      overrides.remove('temperature');
    }

    // Max Tokens
    if (_overrideMaxTokens) {
      overrides['maxTokens'] = _maxTokens;
    } else {
      overrides.remove('maxTokens');
    }

    // Top P
    if (_overrideTopP) {
      overrides['topP'] = _topP;
    } else {
      overrides.remove('topP');
    }

    // Top K
    if (_overrideTopK) {
      overrides['topK'] = _topK;
    } else {
      overrides.remove('topK');
    }

    // Memory (per-chat toggle — only stored when explicitly overridden)
    if (_overrideMemory) {
      overrides['memoryEnabled'] =
          false; // Override = memory disabled for this chat
    } else {
      overrides.remove('memoryEnabled');
    }

    // Min P
    if (_overrideMinP) {
      overrides['minP'] = _minP;
    } else {
      overrides.remove('minP');
    }

    // Repeat Penalty
    if (_overrideRepeatPenalty) {
      overrides['repeatPenalty'] = _repeatPenalty;
    } else {
      overrides.remove('repeatPenalty');
    }

    // Context Length
    if (_overrideContextLength) {
      overrides['contextLength'] = _contextLength;
    } else {
      overrides.remove('contextLength');
    }

    // Tool Use (enable/disable tool calling for this chat)
    if (_overrideToolUse) {
      overrides['enableToolUse'] = _enableToolUse;
    } else {
      overrides.remove('enableToolUse');
    }

    // Web Search: when Global is on, turning the chat toggle off only disables
    // this chat (persist false). On = follow global (remove override).
    if (globalSettings.enableWebSearch) {
      if (!_enableWebSearch) {
        overrides['enableWebSearch'] = false;
      } else {
        overrides.remove('enableWebSearch');
      }
    }

    // Reasoning: persist when different from global so chat can turn ON
    // even when Generation Parameters has Reasoning Mode set to Off.
    // Skip when this LM Studio model has no reasoning API — the switch is
    // informational only and sending off/on would 400.
    final canControlReasoning = ChatReasoningToggle.canControl(
      settings: gateSettings,
      chatCloudProviderId: chatCloudId,
    );
    if (showReasoningToggle && canControlReasoning) {
      if (_reasoningEnabled != globalReasoningOn) {
        overrides['reasoningEnabled'] = _reasoningEnabled;
      } else {
        overrides.remove('reasoningEnabled');
      }
    } else {
      overrides.remove('reasoningEnabled');
    }

    // Group chat settings (only persist if this is a group chat)
    if (widget.conversation.settings['isGroupChat'] == true) {
      overrides['turnMode'] = _turnMode;
      overrides['autonomousMode'] = _autonomousMode;
      overrides['parallelStreaming'] = _parallelStreaming;
      overrides['autoLoadUnload'] = _autoLoadUnload;
      overrides['respondToUserOnly'] = _respondToUserOnly;
    }

    return overrides;
  }

  @override
  Widget build(BuildContext context) {
    final globalSettings = context.watch<SettingsProvider>().settings;
    final l10n = AppLocalizations.of(context);
    // On-device engines don't expose every advanced sampler the LM Studio
    // server does, so we hide overrides that would be silently ignored
    // (Min P, Context Length). Repeat-penalty IS honored by fllama/MLX
    // and stays visible.
    final isOnDevice = globalSettings.activeProviderKind == 'onDeviceGguf' ||
        globalSettings.activeProviderKind == 'onDeviceMlx';
    final effectiveModelId = _effectiveModelId(globalSettings);
    final gateSettings = _reasoningGateSettings(globalSettings);
    final chatCloudId = _reasoningChatCloudProviderId();
    final showReasoningToggle = ChatReasoningToggle.shouldShow(
      settings: gateSettings,
      chatCloudProviderId: chatCloudId,
      availableModels: _availableModels,
      resolveLmStudioModel:
          context.read<SettingsProvider>().resolveLmStudioModel,
    );
    final canControlReasoning = ChatReasoningToggle.canControl(
      settings: gateSettings,
      chatCloudProviderId: chatCloudId,
    );
    final modelExposesReasoningConfig = effectiveModelId.isEmpty ||
        LMStudioService.modelLikelyExposesReasoningConfig(effectiveModelId);

    final cs = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.9;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassBlur(
          sigmaX: 24,
          sigmaY: 24,
          child: Container(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: maxH),
            decoration: BoxDecoration(
              color: cs.surface.withValues(
                alpha: GlassBlur.enabledOf(context) ? 0.94 : 1,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.tune_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.chatSettingsTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.overrideGlobalSettings,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllOverrides,
                        child: Text(l10n.resetAll),
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

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Model Selection
                        if (widget.conversation.settings['isGroupChat'] !=
                            true) ...[
                          _buildOverrideSection(
                            title: l10n.modelOverride,
                            subtitle:
                                'Global: ${_globalModelLabel(globalSettings, l10n)}',
                            isOverridden: _overrideModel,
                            onToggle: (value) =>
                                setState(() => _overrideModel = value),
                            child: _buildModelSelectionChild(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Persona (saved prompt / custom system prompt for this chat)
                        // — or group scenario/user name for group chats.
                        _buildOverrideSection(
                          title: widget.conversation.settings['isGroupChat'] ==
                                  true
                              ? 'Group Chat Scenario'
                              : l10n.systemPromptOverride,
                          subtitle: widget
                                      .conversation.settings['isGroupChat'] ==
                                  true
                              ? 'Shared scene/context for every participant'
                              : 'Global: "${_truncate(globalSettings.systemPrompt, 40)}"',
                          isOverridden: _overrideSystemPrompt,
                          onToggle: (value) =>
                              setState(() => _overrideSystemPrompt = value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.conversation.settings['isGroupChat'] ==
                                  true) ...[
                                TextField(
                                  controller: _userNameController,
                                  enabled: _overrideSystemPrompt,
                                  decoration: const InputDecoration(
                                    labelText: 'Your name (optional)',
                                    hintText: 'How AIs should address you',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              // Mode selector (hide in group chat)
                              if (widget.conversation.settings['isGroupChat'] !=
                                  true) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: SegmentedButton<String>(
                                        segments: [
                                          ButtonSegment(
                                              value: 'saved',
                                              label: Text(l10n.saved,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              icon: const Icon(Icons.bookmark,
                                                  size: 16)),
                                          ButtonSegment(
                                              value: 'custom',
                                              label: Text(l10n.custom,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              icon: const Icon(Icons.edit,
                                                  size: 16)),
                                        ],
                                        selected: {_systemPromptMode},
                                        onSelectionChanged:
                                            _overrideSystemPrompt
                                                ? (values) => setState(() =>
                                                    _systemPromptMode =
                                                        values.first)
                                                : null,
                                        style: const ButtonStyle(
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (_systemPromptMode == 'saved' &&
                                  widget.conversation.settings['isGroupChat'] !=
                                      true) ...[
                                Builder(
                                  builder: (context) {
                                    final savedPrompts = context
                                            .watch<SettingsProvider>()
                                            .settings
                                            .savedSystemPrompts ??
                                        [];
                                    return _buildPersonaPicker(savedPrompts);
                                  },
                                ),
                              ] else ...[
                                // Custom text input / group scenario
                                TextField(
                                  controller: _systemPromptController,
                                  enabled: _overrideSystemPrompt,
                                  maxLines: widget.conversation
                                              .settings['isGroupChat'] ==
                                          true
                                      ? null
                                      : 3,
                                  minLines: widget.conversation
                                              .settings['isGroupChat'] ==
                                          true
                                      ? 3
                                      : 1,
                                  decoration: InputDecoration(
                                    hintText: widget.conversation
                                                .settings['isGroupChat'] ==
                                            true
                                        ? 'Enter chat scenario (affects all participants)'
                                        : l10n.enterCustomPromptHint,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Web Search — shown when Global is on; off = this chat only.
                        if (SubscriptionService().isPremium &&
                            globalSettings.enableWebSearch) ...[
                          const SizedBox(height: 16),
                          _buildWebSearchChatToggle(context, l10n: l10n),
                        ],

                        // Reasoning / Thinking — same gate as the composer chip.
                        // Shown for Qwen 3.x / R1 / catalog thinking on Ollama,
                        // llama.cpp, LM Studio, and cloud effort models.
                        if (showReasoningToggle) ...[
                          const SizedBox(height: 16),
                          _buildReasoningChatToggle(
                            context,
                            l10n: l10n,
                            globalSettings: globalSettings,
                            modelExposesReasoningConfig:
                                modelExposesReasoningConfig,
                            canControlReasoning: canControlReasoning,
                          ),
                        ],

                        if (globalSettings.isAdvancedSettings) ...[
                          const SizedBox(height: 16),

                          // Temperature
                          _buildOverrideSection(
                            title: l10n.temperatureOverride,
                            subtitle:
                                'Global: ${globalSettings.temperature.toStringAsFixed(2)}',
                            isOverridden: _overrideTemperature,
                            onToggle: (value) =>
                                setState(() => _overrideTemperature = value),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _temperature.clamp(0.0, 2.0),
                                    min: 0.0,
                                    max: 2.0,
                                    divisions: 40,
                                    label: _temperature.toStringAsFixed(2),
                                    onChanged: _overrideTemperature
                                        ? (value) =>
                                            setState(() => _temperature = value)
                                        : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    _temperature.toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Max Tokens
                          _buildOverrideSection(
                            title: l10n.maxTokensOverride,
                            subtitle: 'Global: ${globalSettings.maxTokens}',
                            isOverridden: _overrideMaxTokens,
                            onToggle: (value) =>
                                setState(() => _overrideMaxTokens = value),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _maxTokens
                                        .toDouble()
                                        .clamp(1.0, 131072.0),
                                    min: 1,
                                    max: 131072,
                                    label: _maxTokens.toString(),
                                    onChanged: _overrideMaxTokens
                                        ? (value) => setState(
                                            () => _maxTokens = value.toInt())
                                        : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    _maxTokens.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Top P
                          _buildOverrideSection(
                            title: l10n.topPOverride,
                            subtitle:
                                'Global: ${globalSettings.topP.toStringAsFixed(2)}',
                            isOverridden: _overrideTopP,
                            onToggle: (value) =>
                                setState(() => _overrideTopP = value),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _topP.clamp(0.0, 1.0),
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 20,
                                    label: _topP.toStringAsFixed(2),
                                    onChanged: _overrideTopP
                                        ? (value) =>
                                            setState(() => _topP = value)
                                        : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    _topP.toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Top K
                          _buildOverrideSection(
                            title: l10n.topKOverride,
                            subtitle: 'Global: ${globalSettings.topK}',
                            isOverridden: _overrideTopK,
                            onToggle: (value) =>
                                setState(() => _overrideTopK = value),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _topK.toDouble().clamp(1.0, 100.0),
                                    min: 1,
                                    max: 100,
                                    divisions: 99,
                                    label: _topK.toString(),
                                    onChanged: _overrideTopK
                                        ? (value) => setState(
                                            () => _topK = value.toInt())
                                        : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    _topK.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Min P (LM Studio only — on-device samplers ignore it)
                          if (!isOnDevice)
                            _buildOverrideSection(
                              title: l10n.minPOverride,
                              subtitle:
                                  'Global: ${globalSettings.minP.toStringAsFixed(2)}',
                              isOverridden: _overrideMinP,
                              onToggle: (value) =>
                                  setState(() => _overrideMinP = value),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: _minP.clamp(0.0, 1.0),
                                      min: 0.0,
                                      max: 1.0,
                                      divisions: 20,
                                      label: _minP.toStringAsFixed(2),
                                      onChanged: _overrideMinP
                                          ? (value) =>
                                              setState(() => _minP = value)
                                          : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      _minP.toStringAsFixed(2),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (!isOnDevice) const SizedBox(height: 16),

                          // Repeat Penalty
                          _buildOverrideSection(
                            title: l10n.repeatPenaltyOverride,
                            subtitle:
                                'Global: ${globalSettings.repeatPenalty.toStringAsFixed(2)}',
                            isOverridden: _overrideRepeatPenalty,
                            onToggle: (value) =>
                                setState(() => _overrideRepeatPenalty = value),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _repeatPenalty.clamp(1.0, 2.0),
                                    min: 1.0,
                                    max: 2.0,
                                    divisions: 20,
                                    label: _repeatPenalty.toStringAsFixed(2),
                                    onChanged: _overrideRepeatPenalty
                                        ? (value) => setState(
                                            () => _repeatPenalty = value)
                                        : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    _repeatPenalty.toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Context Length (LM Studio load setting — not exposed
                          // by on-device runtimes which use a fixed compile-time
                          // context window per model).
                          if (!isOnDevice)
                            _buildOverrideSection(
                              title: l10n.contextLengthOverride,
                              subtitle:
                                  'Global: ${globalSettings.loadContextLength ?? "Auto"}',
                              isOverridden: _overrideContextLength,
                              onToggle: (value) => setState(
                                  () => _overrideContextLength = value),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: _contextLength
                                          .toDouble()
                                          .clamp(512.0, 131072.0),
                                      min: 512,
                                      max: 131072,
                                      divisions: 255,
                                      label: _contextLength >= 1024
                                          ? '${(_contextLength / 1024).toStringAsFixed(0)}K'
                                          : _contextLength.toString(),
                                      onChanged: _overrideContextLength
                                          ? (value) => setState(() =>
                                              _contextLength = value.toInt())
                                          : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      _contextLength >= 1024
                                          ? '${(_contextLength / 1024).toStringAsFixed(0)}K'
                                          : _contextLength.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // Tool Use toggle (per-chat)
                        const SizedBox(height: 16),
                        Builder(builder: (context) {
                          // Auto-disable when the active model can't honor tool
                          // calls (e.g. on-device GGUF without a tools chat
                          // template). Users can still flip the override, but
                          // the switch is greyed out and a hint explains why.
                          final modelSupportsTools = ToolSupportResolver
                              .instance
                              .currentModelSupportsTools(globalSettings);
                          return _buildOverrideSection(
                            title: l10n.toolCallingLabel,
                            subtitle: modelSupportsTools
                                ? 'Global: ${globalSettings.enableToolUse ? l10n.on : l10n.off}'
                                : 'Selected model doesn\u2019t support tool calling',
                            isOverridden: _overrideToolUse,
                            onToggle: (value) => setState(() {
                              _overrideToolUse = value;
                              if (!value) {
                                _enableToolUse = globalSettings.enableToolUse;
                              }
                            }),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                !modelSupportsTools
                                    ? 'Unavailable for this model'
                                    : (_enableToolUse ? 'Enabled' : 'Disabled'),
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                !modelSupportsTools
                                    ? 'Switch to a tools-capable model to enable.'
                                    : (_enableToolUse
                                        ? l10n.aiCanUseTools
                                        : 'Tools disabled for this chat'),
                                style: const TextStyle(fontSize: 11),
                              ),
                              value: modelSupportsTools && _enableToolUse,
                              onChanged:
                                  (_overrideToolUse && modelSupportsTools)
                                      ? (value) =>
                                          setState(() => _enableToolUse = value)
                                      : null,
                            ),
                          );
                        }),

                        // Memory toggle (premium only)
                        if (SubscriptionService().isPremium &&
                            MemoryService().items.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildOverrideSection(
                            title: l10n.disableMemory,
                            subtitle: l10n.memoryItemsActive(
                                MemoryService().items.length),
                            isOverridden: _overrideMemory,
                            onToggle: (value) =>
                                setState(() => _overrideMemory = value),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Memory is disabled for this chat. The AI won\'t see your saved memory items.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                        ],

                        // Group Chat Settings (only shown for group chats)
                        if (widget.conversation.settings['isGroupChat'] ==
                            true) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.group,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Group Chat',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Turn Mode',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    _turnMode == 'roundRobin'
                                        ? 'Every participant replies to each of your messages, in order.'
                                        : _turnMode == 'random'
                                            ? 'One AI is chosen at random each turn.'
                                            : 'Only @mentioned participants reply. If no one is mentioned, everyone replies.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<String>(
                                    segments: [
                                      const ButtonSegment(
                                          value: 'roundRobin',
                                          label: Text('Auto')),
                                      const ButtonSegment(
                                          value: 'manual',
                                          label: Text('Manual')),
                                      if (_autonomousMode)
                                        const ButtonSegment(
                                            value: 'random',
                                            label: Text('Random')),
                                    ],
                                    selected: {_turnMode},
                                    onSelectionChanged: (v) =>
                                        setState(() => _turnMode = v.first),
                                    style: const ButtonStyle(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.alternate_email,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Tip: type @Name (e.g. @Aziz) to address only that participant in any mode.',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text(
                                        'Autonomous AI Conversations'),
                                    subtitle: const Text(
                                      'AIs can organically continue the conversation without you typing.',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    value: _autonomousMode,
                                    onChanged: (v) => setState(() {
                                      _autonomousMode = v;
                                      if (!v && _turnMode == 'random') {
                                        _turnMode = 'roundRobin';
                                      }
                                    }),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  SwitchListTile(
                                    title: const Text('Reply to user only'),
                                    subtitle: const Text(
                                      'Each participant ignores other AIs entirely. Stops cross-talk on small models.',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    value: _respondToUserOnly,
                                    onChanged: (v) =>
                                        setState(() => _respondToUserOnly = v),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  SwitchListTile(
                                    title: const Text('Parallel Streaming'),
                                    subtitle: const Text(
                                      'Stream all participants simultaneously (faster, more memory).',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    value: _parallelStreaming,
                                    onChanged: (v) =>
                                        setState(() => _parallelStreaming = v),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  SwitchListTile(
                                    title: const Text('Auto Load/Unload'),
                                    subtitle: const Text(
                                      'Load each model on demand, unload when done. Saves VRAM.',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    value: _autoLoadUnload,
                                    onChanged: (v) =>
                                        setState(() => _autoLoadUnload = v),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context, _buildSettingsOverrides());
                          },
                          child: Text(l10n.save),
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

  /// Provider chips + selectable model list (no emoji labels).
  Widget _buildModelSelectionChild() {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isPremium = SubscriptionService().isPremium;
    final selectableProviders = CloudApiService()
        .providers
        .where((p) => isPremium || !p.type.isPremium)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.providerLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (context.read<SettingsProvider>().settings.isRemoteActive) ...[
              for (final kind in context
                  .read<SettingsProvider>()
                  .visibleRemoteBackends)
                _providerChip(
                  label: RemoteHostBackends.remoteListLabel(
                    kind,
                    context.read<SettingsProvider>().settings,
                  ),
                  icon: RemoteHostBackends.iconFor(kind),
                  selected: kind == RemoteHostBackends.lmMiniDesktop
                      ? _selectedProviderId == RemoteHostBackends.lmMiniDesktop
                      : kind == RemoteHostBackends.lmStudio
                          ? _selectedProviderId == null
                          : _selectedProviderId == kind,
                  onTap: _overrideModel
                      ? () {
                          setState(() {
                            _selectedProviderId =
                                kind == RemoteHostBackends.lmMiniDesktop
                                    ? RemoteHostBackends.lmMiniDesktop
                                    : kind == RemoteHostBackends.lmStudio
                                        ? null
                                        : kind;
                            _selectedModel = null;
                            _modelNotFound = false;
                            _loadingModels = true;
                          });
                          _loadModels();
                        }
                      : null,
                ),
            ] else
              _providerChip(
                label: 'LM Studio',
                icon: Icons.computer_rounded,
                selected: _selectedProviderId == null,
                onTap: _overrideModel
                    ? () {
                        setState(() {
                          _selectedProviderId = null;
                          _selectedModel = null;
                          _modelNotFound = false;
                          _loadingModels = true;
                        });
                        _loadModels();
                      }
                    : null,
              ),
            _providerChip(
              label: l10n.onDeviceProviderLabel,
              icon: Icons.phone_iphone_rounded,
              selected: _isOnDeviceProvider,
              onTap: _overrideModel
                  ? () {
                      setState(() {
                        _selectedProviderId = _onDeviceProviderKey;
                        _selectedModel = null;
                        _modelNotFound = false;
                        _loadingModels = true;
                      });
                      _loadModels();
                    }
                  : null,
            ),
            ...selectableProviders
                .where((p) =>
                    !context.read<SettingsProvider>().settings.isRemoteActive ||
                    !p.type.isFreeLocalServer)
                .map(
              (p) => _providerChip(
                // Prefer type display name (no emoji); fall back to clean name.
                label: _stripEmoji(p.type.displayName),
                icon: p.type.isLocalOpenAiCompatible
                    ? Icons.dns_outlined
                    : Icons.cloud_outlined,
                selected: _selectedProviderId == p.id,
                onTap: _overrideModel
                    ? () {
                        setState(() {
                          _selectedProviderId = p.id;
                          _selectedModel = null;
                          _modelNotFound = false;
                          _loadingModels = true;
                        });
                        _loadModels();
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_modelNotFound && _overrideModel) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.modelNoLongerAvailable,
                    style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_loadingModels)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          _buildModelPickerList(),
      ],
    );
  }

  Widget _providerChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: selected ? cs.onPrimary : cs.primary),
      label: Text(label),
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
        color: selected ? cs.onPrimary : cs.onSurface,
      ),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
      side: BorderSide(
        color: selected ? cs.primary : cs.outline.withValues(alpha: 0.18),
      ),
      onSelected: onTap == null ? null : (_) => onTap(),
    );
  }

  Widget _buildModelPickerList() {
    final cs = Theme.of(context).colorScheme;
    final entries = <({String id, String title, String? subtitle})>[];

    if (_isOnDeviceProvider) {
      for (final e in _onDeviceModels) {
        entries.add((
          id: e.spec.id,
          title: _stripEmoji(e.spec.displayName),
          subtitle: e.spec.engine == LocalEngine.mlx
              ? 'MLX · On device'
              : 'GGUF · On device',
        ));
      }
    } else if (_selectedProviderId != null) {
      for (final id in _cloudModelIds) {
        final short = _stripEmoji(id.split('/').last);
        entries.add((
          id: id,
          title: short,
          subtitle: id.contains('/') ? _stripEmoji(id) : null,
        ));
      }
    } else {
      for (final m in _availableModels.where((m) => !m.isEmbedding)) {
        entries.add((
          id: m.id,
          title: _stripEmoji(m.displayName.split('/').last),
          subtitle: m.isLoaded ? 'Loaded' : null,
        ));
      }
    }

    if (entries.isEmpty) {
      final message = _isOnDeviceProvider
          ? 'No on-device models ready. Download one in Local Models.'
          : (_selectedProviderId != null
              ? 'No models found for this provider. Check API key.'
              : 'No models found. Check LM Studio connection.');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: cs.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: entries.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: cs.outline.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, index) {
          final item = entries[index];
          final selected = item.id == _selectedModel;
          return ListTile(
            dense: true,
            enabled: _overrideModel,
            selected: selected,
            selectedTileColor: cs.primaryContainer.withValues(alpha: 0.35),
            leading: Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
            subtitle: item.subtitle == null
                ? null
                : Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
            onTap: _overrideModel
                ? () => setState(() {
                      _selectedModel = item.id;
                      _modelNotFound = false;
                    })
                : null,
          );
        },
      ),
    );
  }

  Widget _buildPersonaPicker(List<SystemPrompt> savedPrompts) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    if (savedPrompts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: cs.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.noSavedPromptsInfo,
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ),
          ],
        ),
      );
    }

    SystemPrompt? selected;
    for (final p in savedPrompts) {
      if (p.id == _selectedSystemPromptId) {
        selected = p;
        break;
      }
    }

    // Keep grid height reasonable when there are many personas.
    final rows = (savedPrompts.length / 4).ceil().clamp(1, 3);
    final gridHeight = rows * 96.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: savedPrompts.length > 12
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: savedPrompts.length,
            itemBuilder: (context, index) {
              final prompt = savedPrompts[index];
              final isSelected = prompt.id == _selectedSystemPromptId;
              final accent =
                  prompt.color != null ? Color(prompt.color!) : cs.primary;
              final avatarPath =
                  ImagePickerHelper.resolveImagePathSync(prompt.avatarPath);

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _overrideSystemPrompt
                    ? () => setState(() {
                          _selectedSystemPromptId = prompt.id;
                          _systemPromptController.text = prompt.content;
                        })
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? cs.primary : Colors.transparent,
                          width: 2.2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: accent.withValues(alpha: 0.22),
                        backgroundImage: avatarPath != null
                            ? FileImage(File(avatarPath))
                            : null,
                        child: avatarPath == null
                            ? Text(
                                prompt.name.isNotEmpty
                                    ? prompt.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prompt.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? cs.primary : cs.onSurface,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              selected.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWebSearchChatToggle(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    final differsFromGlobal = !_enableWebSearch;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: differsFromGlobal
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: differsFromGlobal
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5))
            : null,
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.webSearchChat,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          differsFromGlobal
              ? l10n.webSearchOffForThisChat
              : 'Global: ${l10n.on}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        value: _enableWebSearch,
        onChanged: (value) => setState(() => _enableWebSearch = value),
      ),
    );
  }

  Widget _buildReasoningChatToggle(
    BuildContext context, {
    required AppLocalizations l10n,
    required AppSettings globalSettings,
    required bool modelExposesReasoningConfig,
    required bool canControlReasoning,
  }) {
    final globalReasoningOn = globalSettings.reasoning != 'off';
    final globalLabel =
        globalSettings.reasoning == 'off' ? l10n.off : globalSettings.reasoning;
    final cannotControlReasoning = !canControlReasoning;
    final differsFromGlobal =
        !cannotControlReasoning && _reasoningEnabled != globalReasoningOn;

    String subtitle;
    if (cannotControlReasoning) {
      subtitle = l10n.reasoningNotExposedChatHint;
    } else if (!modelExposesReasoningConfig) {
      subtitle = 'Global: $globalLabel · thinking hidden in chat when off';
    } else if (differsFromGlobal) {
      subtitle = _reasoningEnabled
          ? '${l10n.on} · ${l10n.reasoningDescOn}'
          : l10n.reasoningOffForThisChat;
    } else {
      subtitle = 'Global: $globalLabel';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: differsFromGlobal
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: differsFromGlobal
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5))
            : null,
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.reasoningMode,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        value: _reasoningEnabled,
        onChanged: cannotControlReasoning
            ? null
            : (value) => setState(() => _reasoningEnabled = value),
      ),
    );
  }

  String _effectiveModelId(AppSettings globalSettings) {
    if (_overrideModel && _selectedModel != null) return _selectedModel!;
    if (_isOnDeviceProvider) {
      return globalSettings.selectedLocalModelId ??
          globalSettings.selectedModel ??
          '';
    }
    return globalSettings.selectedModel ?? '';
  }

  String _effectiveProviderKind(AppSettings globalSettings) {
    if (!_overrideModel) return globalSettings.activeProviderKind;
    if (_isOnDeviceProvider) {
      final entry =
          _onDeviceModels.where((e) => e.spec.id == _selectedModel).firstOrNull;
      final engine = entry?.spec.engine ?? LocalEngine.fllama;
      return engine == LocalEngine.mlx ? 'onDeviceMlx' : 'onDeviceGguf';
    }
    if (_selectedProviderId == RemoteHostBackends.lmMiniDesktop) {
      return RemoteHostBackends.lmMiniDesktop;
    }
    if (_selectedProviderId != null &&
        RemoteHostBackends.isLlmKind(_selectedProviderId!)) {
      return _selectedProviderId!;
    }
    if (_selectedProviderId != null) {
      final provider = CloudApiService()
          .providers
          .where((p) => p.id == _selectedProviderId)
          .firstOrNull;
      return provider?.type.providerKind ?? 'cloud';
    }
    return 'lmStudio';
  }

  String? _reasoningChatCloudProviderId() {
    if (_isOnDeviceProvider) return null;
    if (_selectedProviderId == RemoteHostBackends.lmMiniDesktop) return null;
    return _selectedProviderId;
  }

  AppSettings _reasoningGateSettings(AppSettings globalSettings) {
    return globalSettings.copyWith(
      selectedModel: _effectiveModelId(globalSettings),
      activeProviderKind: _effectiveProviderKind(globalSettings),
    );
  }

  Widget _buildOverrideSection({
    required String title,
    required String subtitle,
    required bool isOverridden,
    required ValueChanged<bool> onToggle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: isOverridden
            ? cs.primaryContainer.withValues(alpha: 0.28)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverridden
              ? cs.primary.withValues(alpha: 0.45)
              : cs.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isOverridden,
                onChanged: onToggle,
              ),
            ],
          ),
          if (isOverridden) ...[
            const SizedBox(height: 10),
            child,
          ],
        ],
      ),
    );
  }

  void _clearAllOverrides() {
    final globalSettings = context.read<SettingsProvider>().settings;
    setState(() {
      _overrideModel = false;
      _overrideSystemPrompt = false;
      _overrideTemperature = false;
      _overrideMaxTokens = false;
      _overrideTopP = false;
      _overrideTopK = false;
      _overrideMinP = false;
      _overrideRepeatPenalty = false;
      _overrideContextLength = false;
      _overrideMemory = false;
      _overrideToolUse = false;
      _overrideWebSearch = false;
      _systemPromptMode = 'saved';
      _selectedSystemPromptId = null;

      // Reset to global values
      final gk = globalSettings.activeProviderKind;
      if (gk == 'onDeviceGguf' || gk == 'onDeviceMlx') {
        _selectedProviderId = _onDeviceProviderKey;
        _selectedModel = globalSettings.selectedLocalModelId;
      } else if (SettingsProvider.isCloudProviderKind(gk)) {
        _selectedProviderId =
            context.read<SettingsProvider>().resolveCloudProvider()?.id;
        _selectedModel = globalSettings.selectedModel;
      } else {
        _selectedProviderId = null;
        _selectedModel = globalSettings.selectedModel;
      }
      _modelNotFound = false;
      _systemPromptController.text = globalSettings.systemPrompt;
      _temperature = globalSettings.temperature;
      _maxTokens = globalSettings.maxTokens;
      _topP = globalSettings.topP;
      _topK = globalSettings.topK;
      _minP = globalSettings.minP;
      _repeatPenalty = globalSettings.repeatPenalty;
      _contextLength =
          globalSettings.loadContextLength ?? globalSettings.contextWindow;
      _enableToolUse = globalSettings.enableToolUse;
      _enableWebSearch = globalSettings.enableWebSearch;
      _reasoningEnabled = globalSettings.reasoning != 'off';
    });
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _globalModelLabel(AppSettings global, AppLocalizations l10n) {
    final gk = global.activeProviderKind;
    if (gk == 'onDeviceGguf' || gk == 'onDeviceMlx') {
      final id = global.selectedLocalModelId;
      if (id == null || id.isEmpty) return l10n.noneSelected;
      return _stripEmoji(id);
    }
    final model = global.selectedModel;
    if (model == null || model.isEmpty) return l10n.noneSelected;
    return _stripEmoji(model);
  }

  /// Remove emoji / pictographs from labels (providers used iconEmoji before).
  static String _stripEmoji(String input) {
    return input
        .replaceAll(
          RegExp(
            r'[\u{1F1E6}-\u{1F1FF}'
            r'\u{1F300}-\u{1F5FF}'
            r'\u{1F600}-\u{1F64F}'
            r'\u{1F680}-\u{1F6FF}'
            r'\u{1F700}-\u{1F77F}'
            r'\u{1F780}-\u{1F7FF}'
            r'\u{1F800}-\u{1F8FF}'
            r'\u{1F900}-\u{1F9FF}'
            r'\u{1FA00}-\u{1FAFF}'
            r'\u{2600}-\u{26FF}'
            r'\u{2700}-\u{27BF}'
            r'\u{200D}'
            r'\u{FE0E}'
            r'\u{FE0F}]+',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
