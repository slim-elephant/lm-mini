import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/app_settings.dart';
import '../models/lm_studio_model.dart';
import '../models/file_attachment.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/chat_reasoning_toggle.dart';
import '../utils/image_picker_helper.dart';
import '../utils/file_picker_helper.dart';
import '../services/stt_service.dart';
import '../services/mac_system_stt_service.dart';
import '../services/whisper_model_manager.dart';
import '../services/on_device_llm_service.dart';
import '../desktop/desktop_platform.dart';
import '../utils/audio_setup_gate.dart';
import '../utils/voice_stt_send_logic.dart';
import '../services/tool_support_resolver.dart';
import '../utils/transcription_launcher.dart';
import '../l10n/app_localizations.dart';
import '../utils/layout_utils.dart';
import '../utils/theme_extensions.dart';
import '../utils/context_fit.dart';
import '../utils/context_usage.dart';
import '../models/group_chat_participant.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'composer_shine_border.dart';
import 'glass_toast.dart';
import 'glass_blur.dart';
import 'pro_badge.dart';
import 'think_brain_icon.dart';
import '../screens/subscription_screen.dart';
import '../pro/pro_features.dart';

part '../pro/tools/message_input_pro.dart';

class MessageInput extends StatefulWidget {
  final Function(String,
      {List<String>? imageUrls,
      List<FileAttachment>? fileAttachments}) onSendMessage;
  final bool isLoading;
  final VoidCallback? onStopGeneration; // Callback to stop generation
  final VoidCallback? onStartVoiceMode;
  final MessageInputController? controller;
  final List<ChatMessage>? messages;
  final AppSettings? settings;
  final List<LMStudioModel>? availableModels;
  final int? actualModelContextLength; // Actual context length from model_info
  final int?
      selectedModelLoadedContextLength; // Loaded context length from models endpoint
  final List<File>?
      initialImages; // Images to pre-populate (e.g., from camera widget)
  final VoidCallback?
      onInitialImagesConsumed; // Callback when initial images are added

  /// The composer was disposed while the camera was open. The chat screen
  /// keeps the photo and feeds it back through [initialImages].
  final ValueChanged<File>? onCameraImageCaptured;
  final Function(String)?
      onToggleMcpServer; // Callback to toggle ephemeral MCP server
  final Function(String)?
      onToggleIntegratedMcp; // Callback to toggle integrated MCP
  final Function(bool)?
      onToggleProSearch; // Callback to toggle Pro Search per-chat
  final Function(bool)?
      onToggleSearxng; // Callback to toggle SearXNG per-chat (sets preferSearxng + enableWebSearch)
  final Function(bool)?
      onToggleCodeSandbox; // Callback to toggle Code Sandbox per-chat
  final Function(bool)?
      onToggleThinking; // Per-chat thinking on/off (reasoningEnabled)
  final List<GroupChatParticipant>? mentionableParticipants;
  final VoidCallback? onCompactChat;
  final bool isCompacting;
  final String? compactSummary;
  final String? compactThroughMessageId;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
    this.onStopGeneration,
    this.onStartVoiceMode,
    this.controller,
    this.messages,
    this.settings,
    this.availableModels,
    this.actualModelContextLength,
    this.selectedModelLoadedContextLength,
    this.initialImages,
    this.onInitialImagesConsumed,
    this.onCameraImageCaptured,
    this.onToggleMcpServer,
    this.onToggleIntegratedMcp,
    this.onToggleProSearch,
    this.onToggleSearxng,
    this.onToggleCodeSandbox,
    this.onToggleThinking,
    this.mentionableParticipants,
    this.onCompactChat,
    this.isCompacting = false,
    this.compactSummary,
    this.compactThroughMessageId,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<File> _selectedImages = [];
  final List<FileAttachment> _selectedFiles = [];
  List<File>? _consumedInitialImages;
  final SttService _stt = SttService();
  late final VoiceSttSendLogic _dictationLogic;
  String _dictationPrefix = '';
  bool _isRecording = false;
  bool _showInputActions = false;
  bool _barsExpanded = false; // Collapsed by default for compact view
  String? _activeMentionQuery; // non-null while @mention popup is visible

  /// Whether the user has explicitly chosen SearXNG over Pro Search.
  /// When true, SearXNG always wins even if Pro Search is also available.
  bool get _preferSearxng {
    final settings = widget.settings;
    if (settings == null) return false;
    return settings.preferSearxng && settings.searxngUrl?.isNotEmpty == true;
  }

  /// Whether the currently-selected model accepts tool calls. When false,
  /// every tool-related chip (Pro Search, MCP, SearXNG) is suppressed.
  bool get _modelSupportsTools {
    final settings = widget.settings;
    if (settings == null) return true;
    return ToolSupportResolver.instance.currentModelSupportsTools(
      settings,
      availableModels: widget.availableModels,
    );
  }

  /// Whether Pro Search icon should be visible (premium user with tool use capable).
  /// Hidden when the user has explicitly preferred SearXNG.
  /// Available on every tool-capable provider (LM Studio, Ollama, cloud, on-device).
  bool get _canShowProSearch => _proCanShowProSearch();

  /// Whether Pro Search is currently active for the current chat
  bool get _isProSearchActive {
    return _canShowProSearch && (widget.settings?.enableWebSearch ?? false);
  }

  /// Code Sandbox chip — premium + MCP URL configured + tool-capable model.
  bool get _canShowCodeSandbox => _proCanShowCodeSandbox();

  bool get _isCodeSandboxActive {
    return _canShowCodeSandbox && (widget.settings?.enableCodeSandbox ?? false);
  }

  static const _sandboxAccent = Color(0xFF14B8A6);
  static const _sandboxAccentDeep = Color(0xFF0F766E);

  Color get _sandboxFg {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF5EEAD4) : _sandboxAccentDeep;
  }

  Color get _sandboxBg => _sandboxAccent.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.14,
      );

  void _toggleCodeSandbox() {
    final newValue = !_isCodeSandboxActive;
    widget.onToggleCodeSandbox?.call(newValue);
    final l10n = AppLocalizations.of(context);
    GlassToast.show(
      context,
      message: newValue ? l10n.codeSandboxEnabled : l10n.codeSandboxDisabled,
      icon: Icons.terminal_rounded,
      accent: newValue ? _sandboxAccent : Theme.of(context).colorScheme.outline,
    );
  }

  /// Whether SearXNG search chip should be visible.
  /// Visible when: tool use on, searxng URL configured, MCP-only off, AND
  /// either user prefers SearXNG OR Pro Search isn't available for them.
  bool get _canShowSearxng {
    final settings = widget.settings;
    if (settings == null) return false;
    if (settings.searxngUrl?.isNotEmpty != true) return false;
    if (!settings.enableToolUse) return false;
    if (!_modelSupportsTools) return false;
    if (settings.useMcpToolsOnly) return false;
    // If user explicitly prefers SearXNG, always show it.
    if (_preferSearxng) return true;
    // Otherwise, hide when Pro Search is the active tool.
    return !_isProSearchActive;
  }

  /// Whether SearXNG is currently active for the current chat
  bool get _isSearxngActive {
    return _canShowSearxng && (widget.settings?.enableWebSearch ?? false);
  }

  /// Soft violet — readable on light & dark, matches LM Mini chrome.
  static const _proSearchAccent = Color(0xFF8B6CFF);
  static const _proSearchAccentDeep = Color(0xFF6B4CE6);

  Color get _proSearchFg {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFC4B5FF) : _proSearchAccentDeep;
  }

  Color get _proSearchBg => _proSearchAccent.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.16,
      );

  static const _proSearchToolIcon = Icons.search_rounded;
  static const _codeSandboxToolIcon = Icons.terminal_rounded;
  static const _searxngToolIcon = Icons.travel_explore_rounded;
  static const _genericMcpToolIcon = Icons.extension_rounded;

  bool get _hasOtherMcps {
    if (widget.settings?.enableToolUse != true) return false;
    if (widget.settings?.hasApiToken == true &&
        widget.settings?.integratedMcps != null) {
      for (final mcp in widget.settings!.integratedMcps!) {
        if (_isProSearchActive && _proSearchOverlapNames.contains(mcp.name)) {
          continue;
        }
        return true;
      }
    }
    if (widget.settings?.mcpServers != null) {
      final integratedNames = <String>{
        if (widget.settings?.integratedMcps != null)
          for (final m
              in widget.settings!.integratedMcps!.where((m) => m.enabled))
            m.name,
      };
      for (final server in widget.settings!.mcpServers!) {
        if (!integratedNames.contains(server.label)) return true;
      }
    }
    return false;
  }

  bool get _otherMcpsActive {
    if (widget.settings?.enableToolUse != true) return false;
    if (widget.settings?.hasApiToken == true &&
        widget.settings?.integratedMcps != null) {
      for (final mcp
          in widget.settings!.integratedMcps!.where((m) => m.enabled)) {
        if (_isProSearchActive && _proSearchOverlapNames.contains(mcp.name)) {
          continue;
        }
        return true;
      }
    }
    if (widget.settings?.mcpServers != null) {
      final integratedNames = <String>{
        if (widget.settings?.integratedMcps != null)
          for (final m
              in widget.settings!.integratedMcps!.where((m) => m.enabled))
            m.name,
      };
      for (final server in widget.settings!.mcpServers!) {
        if (integratedNames.contains(server.label)) continue;
        final labels = widget.settings!.activeMcpServerLabels;
        if (labels == null || labels.contains(server.label)) return true;
      }
    }
    return false;
  }

  bool get _hasMcpTools =>
      _canShowThinking ||
      _canShowProSearch ||
      _canShowCodeSandbox ||
      _canShowSearxng ||
      _hasOtherMcps;

  void _toggleBarsExpanded() {
    setState(() => _barsExpanded = !_barsExpanded);
  }

  Widget _mcpChipAvatar({
    required bool selected,
    required Color color,
    IconData? icon,
    Widget? idle,
  }) {
    if (selected) {
      return Icon(Icons.check_rounded, size: 14, color: color);
    }
    if (idle != null) return idle;
    return Icon(icon!, size: 14, color: color);
  }

  Color _collapsedToolOnColor(ColorScheme colorScheme) => colorScheme.onSurface;

  Color _collapsedToolOffColor(ColorScheme colorScheme) =>
      colorScheme.onSurfaceVariant.withValues(alpha: 0.42);

  Widget _collapsedToolIcon({
    required bool active,
    required ColorScheme colorScheme,
    required VoidCallback? onTap,
    IconData? icon,
    Widget? idle,
    String? tooltip,
  }) {
    final color = active
        ? _collapsedToolOnColor(colorScheme)
        : _collapsedToolOffColor(colorScheme);
    final child = idle ??
        Icon(
          icon!,
          size: 16,
          color: color,
        );
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: child,
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Color _contextMeterColor(double contextPercentage, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (contextPercentage > 0.8) return colorScheme.error;
    if (contextPercentage > 0.6) return colorScheme.primary;
    return colorScheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.7);
  }

  Widget _expandCaretIcon(ColorScheme colorScheme, {required bool expanded}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        expanded ? Icons.expand_more : Icons.expand_less,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  List<Widget> _buildCollapsedToolIcons(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final onColor = _collapsedToolOnColor(colorScheme);
    final offColor = _collapsedToolOffColor(colorScheme);
    return [
      if (_canShowThinking)
        _collapsedToolIcon(
          active: _isThinkingActive,
          colorScheme: colorScheme,
          onTap: _canControlThinking ? _toggleThinking : null,
          idle: ThinkBrainIcon(
            size: 16,
            filled: _isThinkingActive,
            color: _isThinkingActive ? onColor : offColor,
          ),
          tooltip: l10n.think,
        ),
      if (_canShowProSearch)
        _collapsedToolIcon(
          active: _isProSearchActive,
          colorScheme: colorScheme,
          onTap: _toggleProSearch,
          icon: _proSearchToolIcon,
          tooltip: 'Pro Search',
        ),
      if (_canShowCodeSandbox)
        _collapsedToolIcon(
          active: _isCodeSandboxActive,
          colorScheme: colorScheme,
          onTap: _toggleCodeSandbox,
          icon: _codeSandboxToolIcon,
          tooltip: l10n.codeSandbox,
        ),
      if (_hasOtherMcps)
        _collapsedToolIcon(
          active: _otherMcpsActive,
          colorScheme: colorScheme,
          onTap: () => setState(() => _barsExpanded = true),
          icon: _genericMcpToolIcon,
          tooltip: l10n.mcpLabel,
        ),
      if (_canShowSearxng)
        _collapsedToolIcon(
          active: _isSearxngActive,
          colorScheme: colorScheme,
          onTap: _toggleSearxng,
          icon: _searxngToolIcon,
          tooltip: 'SearXNG',
        ),
    ];
  }

  String? get _chatCloudProviderId {
    try {
      return context
          .read<ChatProvider>()
          .currentConversation
          ?.settings['cloudProviderId'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool get _canShowThinking {
    final settings = widget.settings;
    if (settings == null) return false;
    SettingsProvider? settingsProvider;
    try {
      settingsProvider = context.read<SettingsProvider>();
    } catch (_) {}
    return ChatReasoningToggle.shouldShow(
      settings: settings,
      chatCloudProviderId: _chatCloudProviderId,
      availableModels: widget.availableModels ?? const [],
      resolveLmStudioModel: settingsProvider?.resolveLmStudioModel,
    );
  }

  bool get _canControlThinking {
    final settings = widget.settings;
    if (settings == null) return true;
    return ChatReasoningToggle.canControl(
      settings: settings,
      chatCloudProviderId: _chatCloudProviderId,
    );
  }

  bool get _isThinkingActive => widget.settings?.isReasoningEnabled ?? false;

  void _toggleThinking() {
    if (!_canControlThinking) return;
    final newValue = !_isThinkingActive;
    widget.onToggleThinking?.call(newValue);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    GlassToast.show(
      context,
      message: newValue ? l10n.thinkingEnabled : l10n.thinkingDisabled,
      icon: Icons.psychology_outlined,
      accent: newValue
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline,
    );
  }

  void _toggleProSearch() {
    final newValue = !_isProSearchActive;
    widget.onToggleProSearch?.call(newValue);

    // When enabling Pro Search, deactivate SearXNG-conflicting state
    // (handled by Pro Search override in routing — UI just reflects it)

    final l10n = AppLocalizations.of(context);
    GlassToast.show(
      context,
      message: newValue ? l10n.proSearchEnabled : l10n.proSearchDisabled,
      icon: _proSearchToolIcon,
      accent:
          newValue ? _proSearchAccent : Theme.of(context).colorScheme.outline,
    );
  }

  void _toggleSearxng() {
    final newValue = !_isSearxngActive;
    // Use the dedicated SearXNG callback when wired (sets preferSearxng=true).
    // Fall back to the Pro Search callback for older call sites that haven't
    // been updated.
    if (widget.onToggleSearxng != null) {
      widget.onToggleSearxng!(newValue);
    } else {
      widget.onToggleProSearch?.call(newValue);
    }

    GlassToast.show(
      context,
      message: newValue ? 'SearXNG enabled' : 'SearXNG disabled',
      icon: Icons.travel_explore_rounded,
      accent: newValue
          ? Colors.tealAccent.shade400
          : Theme.of(context).colorScheme.outline,
    );
  }

  List<Shadow> _contextTextShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      Shadow(
        color: (isDark ? Colors.black : Colors.white)
            .withValues(alpha: isDark ? 0.85 : 0.65),
        blurRadius: isDark ? 10 : 8,
        offset: const Offset(0, 0.5),
      ),
      Shadow(
        color: (isDark ? Colors.black : Colors.white)
            .withValues(alpha: isDark ? 0.45 : 0.35),
        blurRadius: isDark ? 18 : 14,
      ),
    ];
  }

  void _onMentionTextChanged() {
    final participants = widget.mentionableParticipants;
    if (participants == null || participants.isEmpty) return;
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) {
      if (_activeMentionQuery != null) {
        setState(() => _activeMentionQuery = null);
      }
      return;
    }
    final before = _controller.text.substring(0, cursor);
    final match = RegExp(r'@(\w*)$').firstMatch(before);
    if (match != null) {
      final query = match.group(1)!;
      if (_activeMentionQuery != query) {
        setState(() => _activeMentionQuery = query);
      }
    } else {
      if (_activeMentionQuery != null) {
        setState(() => _activeMentionQuery = null);
      }
    }
  }

  void _completeMention(String name) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) return;
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final newBefore = before.replaceFirst(RegExp(r'@\w*$'), '@$name ');
    _controller.value = TextEditingValue(
      text: newBefore + after,
      selection: TextSelection.collapsed(offset: newBefore.length),
    );
    setState(() => _activeMentionQuery = null);
    _focusNode.requestFocus();
  }

  Widget _buildMentionSuggestions(ColorScheme colorScheme) {
    final query = _activeMentionQuery!.toLowerCase();
    final filtered = (widget.mentionableParticipants ?? [])
        .where((p) =>
            query.isEmpty || p.displayName.toLowerCase().startsWith(query))
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final p = filtered[index];
            final avatarBg = p.color != null
                ? Color(p.color!).withOpacity(0.25)
                : colorScheme.primaryContainer;
            final avatarFg =
                p.color != null ? Color(p.color!) : colorScheme.primary;
            return InkWell(
              onTap: () => _completeMention(p.displayName),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: avatarBg,
                      child: Text(
                        p.displayName.isNotEmpty
                            ? p.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: avatarFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      p.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.modelId,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _setComposerText(String text) {
    _focusNode.requestFocus();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    // Keep the caret at the end after the keyboard opens (iOS can otherwise
    // select-all when focus changes).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final end = _controller.text.length;
      _controller.selection = TextSelection.collapsed(offset: end);
    });
    setState(() {
      _showInputActions = false;
    });
  }

  Future<void> insertTranslatePromptFromClipboard() async {
    const prompt =
        'Translate the following and preserve the tone and formatting:\n\n';
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      final clipboardText = clipboardData?.text?.trim();
      if (clipboardText != null && clipboardText.isNotEmpty) {
        _setComposerText('$prompt$clipboardText');
        return;
      }
    } catch (_) {}

    _setComposerText(prompt);
  }

  @override
  void initState() {
    super.initState();
    _dictationLogic = VoiceSttSendLogic(
      onSend: (text) {
        if (!mounted) return;
        if (widget.settings?.voiceAutoSend == true && text.trim().isNotEmpty) {
          _controller.text = '$_dictationPrefix$text';
          _sendMessage();
        }
      },
      onDisplayTextChanged: (text) {
        if (!mounted) return;
        setState(() {
          _controller.text = '$_dictationPrefix$text';
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );
    widget.controller?._attach(this);
    _handleInitialImages();
    _controller.addListener(_onMentionTextChanged);
  }

  @override
  void didUpdateWidget(MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    _handleInitialImages();
  }

  void _handleInitialImages() {
    if (widget.initialImages != null &&
        widget.initialImages!.isNotEmpty &&
        widget.initialImages != _consumedInitialImages) {
      setState(() {
        _selectedImages.addAll(widget.initialImages!);
        _consumedInitialImages = widget.initialImages;
      });
      widget.onInitialImagesConsumed?.call();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _dictationLogic.dispose();
    _controller.removeListener(_onMentionTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isVisionModelSelected() {
    final settings = widget.settings;
    if (settings == null) return false;

    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      final spec = OnDeviceLLMService.instance.specForSettings(settings);
      return spec?.supportsVision == true;
    }

    final id = settings.selectedModel;
    if (id == null || id.isEmpty) return false;

    // Prefer SettingsProvider fuzzy resolve (path vs basename ids from
    // llama-server). Fall back to the passed-in list for exact/basename match.
    LMStudioModel? selectedModel;
    try {
      selectedModel = context.read<SettingsProvider>().resolveLmStudioModel(id);
    } catch (_) {
      selectedModel = null;
    }
    selectedModel ??= _resolveFromAvailableModels(id);

    if (selectedModel == null) return false;
    return selectedModel.isVLM || selectedModel.supportsVision;
  }

  LMStudioModel? _resolveFromAvailableModels(String id) {
    final models = widget.availableModels;
    if (models == null || models.isEmpty) return null;
    for (final model in models) {
      if (model.id == id) return model;
    }
    final needle = LMStudioModel.friendlyLabel(id).toLowerCase();
    for (final model in models) {
      if (LMStudioModel.friendlyLabel(model.id).toLowerCase() == needle) {
        return model;
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    final files = await ImagePickerHelper.pickMultipleFromGallery(context);
    if (files.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(files);
      });
    }
  }

  Future<void> _captureImage() async {
    final file = await ImagePickerHelper.captureFromCamera(context);
    if (!mounted) {
      final recovered = file ?? await _firstLostCameraImage();
      if (recovered != null) widget.onCameraImageCaptured?.call(recovered);
      return;
    }
    if (file == null) return;
    setState(() {
      _selectedImages.add(file);
    });
  }

  Future<File?> _firstLostCameraImage() async {
    final lost = await ImagePickerHelper.recoverLostImages();
    if (lost.isEmpty) return null;
    return lost.last;
  }

  Future<void> _pickImageFromFiles() async {
    final files = await ImagePickerHelper.pickMultipleFromFiles(context);
    if (files.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(files);
      });
    }
  }

  Future<void> _pickDocument([List<String>? extensions]) async {
    final attachments = await FilePickerHelper.pickDocuments(
      context,
      allowedExtensions: extensions,
    );
    if (attachments.isNotEmpty && mounted) {
      setState(() {
        _selectedFiles.addAll(attachments);
      });
    }
  }

  bool get _supportsFileDrop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _handleDroppedPaths(List<String> paths) async {
    for (final raw in paths) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      final file = File(p);
      if (!await file.exists()) continue;

      final ext = path.extension(p).toLowerCase();
      const imageExts = {
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.webp',
        '.heic',
        '.bmp',
      };
      if (imageExts.contains(ext)) {
        if (_isVisionModelSelected() && mounted) {
          setState(() => _selectedImages.add(file));
        }
        continue;
      }

      final attachment = await FilePickerHelper.attachFromPath(p);
      if (attachment != null && mounted) {
        setState(() => _selectedFiles.add(attachment));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_isRecording) {
      await _stt.stopListening();
      _dictationLogic.commitSession();
      setState(() => _isRecording = false);
      return;
    }

    if (!await ensureAudioSetup(context)) return;

    final settings = widget.settings;
    var sttProvider = settings?.voiceSttProvider ?? 'whisper';
    // Only force Whisper on Mac when the native speech bridge isn't available
    // (dev/IDE launches). Installed builds keep the user's "system" choice.
    final macNative = await MacSystemSttService.instance.isAvailable();
    final macWhisperOnly =
        DesktopPlatform.macListeningRequiresWhisper && !macNative;
    if (macWhisperOnly) {
      sttProvider = 'whisper';
      if (settings?.voiceSttProvider == 'system' && mounted) {
        context.read<SettingsProvider>().updateVoiceSttProvider('whisper');
      }
      final usable = await WhisperModelManager.instance.resolveUsableModelId(
        settings?.whisperModelId,
      );
      if (usable != null &&
          mounted &&
          context.read<SettingsProvider>().settings.whisperModelId != usable) {
        await context.read<SettingsProvider>().updateWhisperModelId(usable);
      }
    }

    final sttLocale =
        (settings?.voiceSttLanguage ?? settings?.voiceLanguage ?? 'en-US')
            .replaceAll('-', '_');
    final listenCap =
        Duration(seconds: settings?.voiceSttListenForSeconds ?? 60);
    final pauseForSeconds = settings?.voiceSttPauseForSeconds ?? 3;

    final available = await _stt.initialize(
      sttProvider: sttProvider,
      localeId: sttLocale,
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              macWhisperOnly
                  ? AppLocalizations.of(context).voiceSttMacosDownloadWhisper
                  : AppLocalizations.of(context).voiceNotAvailable,
            ),
          ),
        );
      }
      return;
    }

    final existingText = _controller.text;
    _dictationPrefix = existingText.isNotEmpty && !existingText.endsWith(' ')
        ? '$existingText '
        : existingText;
    _dictationLogic.reset();

    final started = await _stt.startListening(
      onResult: (result) {
        if (!mounted) return;
        _dictationLogic.handleResult(result, pauseForSeconds);
        if (result.finalResult) {
          Future.microtask(() {
            if (mounted && !_stt.isListening) {
              setState(() => _isRecording = false);
            }
          });
        }
      },
      listenFor: listenCap,
      pauseFor: listenCap,
      pauseForSeconds: pauseForSeconds,
      sttProvider: sttProvider,
      localeId: sttLocale,
    );
    if (!mounted) return;
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).voiceNotAvailable),
        ),
      );
      return;
    }
    setState(() => _isRecording = true);
  }

  // ── Compact bars (collapsed): context meter + dedicated tool icons ──
  Widget _buildCompactBars(double contextPercentage, ColorScheme colorScheme,
      AppLocalizations l10n) {
    final contextColor = _contextMeterColor(contextPercentage, colorScheme);
    final contextShadows = _contextTextShadows(context);
    final toolIcons = _buildCollapsedToolIcons(colorScheme, l10n);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleBarsExpanded,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(Icons.memory,
                      size: 14, color: contextColor, shadows: contextShadows),
                  const SizedBox(width: 4),
                  Text(
                    '${(contextPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: contextColor,
                      shadows: contextShadows,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: contextPercentage.clamp(0.0, 1.0),
                      backgroundColor:
                          colorScheme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(contextColor),
                    ),
                  ),
                  if (_shouldShowCompactButton(contextPercentage)) ...[
                    const SizedBox(width: 6),
                    _buildCompactChatControl(l10n, colorScheme, compact: true),
                  ],
                ],
              ),
            ),
          ),
          ...toolIcons,
          GestureDetector(
            onTap: _toggleBarsExpanded,
            behavior: HitTestBehavior.opaque,
            child: _expandCaretIcon(colorScheme, expanded: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMcpOnly(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleBarsExpanded,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(Icons.dns_outlined,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.mcpLabel,
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          ..._buildCollapsedToolIcons(colorScheme, l10n),
          GestureDetector(
            onTap: _toggleBarsExpanded,
            behavior: HitTestBehavior.opaque,
            child: _expandCaretIcon(colorScheme, expanded: false),
          ),
        ],
      ),
    );
  }

  // ── Expanded bars: full-width context row + MCP chips (no duplicate icons)
  Widget _buildExpandedBars(double contextPercentage, int usedContext,
      int maxContext, ColorScheme colorScheme, AppLocalizations l10n,
      {bool includeMcpBar = true}) {
    final contextColor = _contextMeterColor(contextPercentage, colorScheme);
    final contextShadows = _contextTextShadows(context);
    final hasMcp = includeMcpBar && _hasMcpTools;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleBarsExpanded,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.memory,
                    size: 14, color: contextColor, shadows: contextShadows),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Context: ${usedContext.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} / ${maxContext.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: contextColor,
                            shadows: contextShadows,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      if (widget.actualModelContextLength != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified,
                            size: 12, color: colorScheme.primary),
                      ] else if (widget.selectedModelLoadedContextLength !=
                          null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle,
                            size: 12, color: colorScheme.secondary),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: contextPercentage.clamp(0.0, 1.0),
                          backgroundColor:
                              colorScheme.outline.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            contextPercentage > 0.8
                                ? colorScheme.error
                                : contextPercentage > 0.6
                                    ? colorScheme.primary
                                    : colorScheme.primary
                                        .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(contextPercentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: contextColor,
                    shadows: contextShadows,
                  ),
                ),
                if (_shouldShowCompactButton(contextPercentage)) ...[
                  const SizedBox(width: 6),
                  _buildCompactChatControl(l10n, colorScheme, compact: false),
                ],
                _expandCaretIcon(colorScheme, expanded: true),
              ],
            ),
          ),
        ),
        if (hasMcp) ...[
          const SizedBox(height: 4),
          _buildFullMcpBar(colorScheme, l10n),
        ],
      ],
    );
  }

  Widget _buildExpandedMcpOnly(ColorScheme colorScheme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(child: _buildFullMcpBar(colorScheme, l10n)),
        GestureDetector(
          onTap: _toggleBarsExpanded,
          behavior: HitTestBehavior.opaque,
          child: _expandCaretIcon(colorScheme, expanded: true),
        ),
      ],
    );
  }

  // Integrated MCPs that overlap with Pro Search (web_search + read_url)
  static const _proSearchOverlapNames = {'web_search', 'read_url'};

  Widget _buildFullMcpBar(ColorScheme colorScheme, AppLocalizations l10n) {
    // Collect integrated MCP names for dedup check
    final integratedNames = <String>{};
    if (widget.settings?.hasApiToken == true &&
        widget.settings?.integratedMcps != null) {
      for (final m
          in widget.settings!.integratedMcps!.where((m) => m.enabled)) {
        integratedNames.add(m.name);
      }
    }

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Icon(Icons.dns_outlined, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            l10n.mcpLabel,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_canShowThinking)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      label: Text(
                        l10n.think,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isThinkingActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selected: _isThinkingActive,
                      onSelected: widget.isLoading || !_canControlThinking
                          ? null
                          : (_) => _toggleThinking(),
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.onPrimaryContainer,
                      showCheckmark: false,
                      avatar: _mcpChipAvatar(
                        selected: _isThinkingActive,
                        color: _isThinkingActive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        idle: ThinkBrainIcon(
                          size: 14,
                          filled: false,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                // Pro Search chip (premium only, when applicable)
                if (_canShowProSearch)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      label: Text(
                        'Pro Search',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isProSearchActive
                              ? _proSearchFg
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selected: _isProSearchActive,
                      onSelected:
                          widget.isLoading ? null : (_) => _toggleProSearch(),
                      selectedColor: _proSearchBg,
                      checkmarkColor: _proSearchFg,
                      showCheckmark: false,
                      side: BorderSide(
                        color: _isProSearchActive
                            ? _proSearchAccent.withValues(alpha: 0.45)
                            : colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      avatar: _mcpChipAvatar(
                        selected: _isProSearchActive,
                        color: _isProSearchActive
                            ? _proSearchFg
                            : colorScheme.onSurfaceVariant,
                        icon: _proSearchToolIcon,
                      ),
                    ),
                  ),
                // Code Sandbox chip (premium)
                if (_canShowCodeSandbox)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      label: Text(
                        l10n.codeSandbox,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isCodeSandboxActive
                              ? _sandboxFg
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selected: _isCodeSandboxActive,
                      onSelected:
                          widget.isLoading ? null : (_) => _toggleCodeSandbox(),
                      selectedColor: _sandboxBg,
                      checkmarkColor: _sandboxFg,
                      showCheckmark: false,
                      side: BorderSide(
                        color: _isCodeSandboxActive
                            ? _sandboxAccent.withValues(alpha: 0.45)
                            : colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      avatar: _mcpChipAvatar(
                        selected: _isCodeSandboxActive,
                        color: _isCodeSandboxActive
                            ? _sandboxFg
                            : colorScheme.onSurfaceVariant,
                        icon: _codeSandboxToolIcon,
                      ),
                    ),
                  ),
                // Integrated MCP chips — hide web_search/read_url when Pro Search active
                if (widget.settings?.hasApiToken == true &&
                    widget.settings?.integratedMcps?.isNotEmpty == true)
                  ...widget.settings!.integratedMcps!
                      .where((mcp) =>
                          !_isProSearchActive ||
                          !_proSearchOverlapNames.contains(mcp.name))
                      .map((mcp) {
                    final isActive = mcp.enabled;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        label: Text(
                          mcp.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        selected: isActive,
                        onSelected: widget.isLoading ||
                                widget.onToggleIntegratedMcp == null
                            ? null
                            : (_) => widget.onToggleIntegratedMcp!(mcp.name),
                        selectedColor: colorScheme.primaryContainer,
                        checkmarkColor: colorScheme.onPrimaryContainer,
                        showCheckmark: false,
                        avatar: _mcpChipAvatar(
                          selected: isActive,
                          color: isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          icon: _genericMcpToolIcon,
                        ),
                      ),
                    );
                  }),
                // Ephemeral MCP chips — hide if an enabled integrated MCP
                // shares the same name (integrated takes priority)
                if (widget.settings?.mcpServers?.isNotEmpty == true)
                  ...widget.settings!.mcpServers!
                      .where((s) => !integratedNames.contains(s.label))
                      .map((server) {
                    final isActive =
                        widget.settings!.activeMcpServerLabels == null ||
                            widget.settings!.activeMcpServerLabels!
                                .contains(server.label);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        label: Text(
                          server.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        selected: isActive,
                        onSelected: widget.isLoading ||
                                widget.onToggleMcpServer == null
                            ? null
                            : (_) => widget.onToggleMcpServer!(server.label),
                        selectedColor: colorScheme.secondaryContainer,
                        checkmarkColor: colorScheme.onSecondaryContainer,
                        showCheckmark: false,
                        avatar: _mcpChipAvatar(
                          selected: isActive,
                          color: isActive
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                          icon: _genericMcpToolIcon,
                        ),
                      ),
                    );
                  }),
                // SearXNG chip — hidden when Pro Search is active (via _canShowSearxng)
                if (_canShowSearxng)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      label: Text(
                        'SearXNG',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isSearxngActive
                              ? Colors.tealAccent.shade700
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selected: _isSearxngActive,
                      onSelected:
                          widget.isLoading ? null : (_) => _toggleSearxng(),
                      selectedColor: Colors.teal.withValues(alpha: 0.2),
                      checkmarkColor: Colors.tealAccent.shade700,
                      showCheckmark: false,
                      avatar: _mcpChipAvatar(
                        selected: _isSearxngActive,
                        color: _isSearxngActive
                            ? Colors.tealAccent.shade700
                            : colorScheme.onSurfaceVariant,
                        icon: _searxngToolIcon,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    final isVisionModel = _isVisionModelSelected();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // Capture the MessageInput context — the sheet builder's context is
    // unmounted after Navigator.pop, so anything that continues after the
    // sheet closes (e.g. Transcribe) must use this parent context.
    final hostContext = context;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.attachFile,
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Compact image actions — equal columns with icon + label.
              Row(
                children: [
                  Expanded(
                    child: _AttachGridTile(
                      icon: Icons.photo_library_outlined,
                      label: l10n.photoLibrary,
                      enabled: isVisionModel,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickImage();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttachGridTile(
                      icon: Icons.camera_alt_outlined,
                      label: l10n.takePhoto,
                      enabled: isVisionModel,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _captureImage();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttachGridTile(
                      icon: Icons.folder_open_outlined,
                      label: l10n.imageFromFiles,
                      enabled: isVisionModel,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickImageFromFiles();
                      },
                    ),
                  ),
                ],
              ),
              if (!isVisionModel) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.requiresVisionModel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Wider full-width actions for documents & transcription.
              _AttachWideTile(
                icon: Icons.description_outlined,
                title: l10n.attachDocuments,
                subtitle: l10n.attachDocumentsSubtitle,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickDocument();
                },
              ),
              const SizedBox(height: 8),
              _AttachWideTile(
                icon: Icons.transcribe_rounded,
                title: l10n.transcribeAudio,
                subtitle: l10n.transcribeAudioSubtitle,
                onTap: () {
                  Navigator.pop(sheetContext);
                  TranscriptionLauncher.openTranscribeFlow(hostContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps the text field with a hardware-keyboard listener so the user's
  /// configured Enter/Return key behavior is honoured for external keyboards.
  ///
  /// Behavior modes (from `AppSettings.enterKeyBehavior`):
  ///   - `'send'`    — Enter sends, Shift+Enter inserts newline
  ///   - `'newline'` — Enter always inserts newline (send button required)
  ///   - `'auto'`    — 'send' on desktop platforms or when a hardware keyboard
  ///                   is attached; 'newline' on mobile soft-keyboard-only
  ///
  /// Soft-keyboard Enter presses on iOS/Android normally don't produce a
  /// physical KeyDownEvent for the Enter key, so they fall through to the
  /// TextField's default newline behavior even when mode is 'send'.
  Widget _buildKeyListenerWrapper({required Widget child}) {
    return Focus(
      // Don't steal focus from the TextField; just observe key events.
      canRequestFocus: false,
      descendantsAreFocusable: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: child,
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (widget.isLoading) return KeyEventResult.ignored;

    final mode = _effectiveEnterMode();
    final shiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (mode == 'send') {
      if (shiftPressed) {
        // Shift+Enter → let TextField handle newline insertion
        return KeyEventResult.ignored;
      }
      // Enter → send
      _sendMessage();
      return KeyEventResult.handled;
    }
    // 'newline' — let TextField insert a newline as usual.
    return KeyEventResult.ignored;
  }

  /// Resolve the effective mode ('send' or 'newline') given the user's
  /// configured `enterKeyBehavior` setting and the current platform.
  String _effectiveEnterMode() {
    final configured = widget.settings?.enterKeyBehavior ?? 'auto';
    if (configured == 'send' || configured == 'newline') return configured;

    // 'auto': send on desktop / when a hardware keyboard is attached.
    // On mobile, Flutter doesn't expose a direct "is external keyboard
    // attached" API, but hardware Enter key events only arrive when there
    // IS a physical keyboard — so reaching this code path from a key event
    // is itself a strong signal. For the default we therefore treat every
    // hardware Enter as "send" in auto mode, which matches the user's
    // requested default for external keyboards. Soft-keyboard taps don't
    // generate KeyDownEvents for Enter, so they continue to insert newlines.
    return 'send';
  }

  bool get _hasSendableContent =>
      _controller.text.trim().isNotEmpty ||
      _selectedImages.isNotEmpty ||
      _selectedFiles.isNotEmpty;

  void _sendMessage() async {
    if (!_hasSendableContent || widget.isLoading) return;

    final text = _controller.text.trim();
    // Convert selected images to base64 data URLs
    final List<String>? imageUrls = _selectedImages.isNotEmpty
        ? await Future.wait(_selectedImages.map((file) async {
            final bytes = await file.readAsBytes();
            final base64String = base64Encode(bytes);
            final mimeType = _getMimeType(file.path);
            return 'data:$mimeType;base64,$base64String';
          }))
        : null;

    // Prepare file attachments
    final List<FileAttachment>? fileAttachments =
        _selectedFiles.isNotEmpty ? List.from(_selectedFiles) : null;

    widget.onSendMessage(text,
        imageUrls: imageUrls, fileAttachments: fileAttachments);
    _controller.clear();
    setState(() {
      _selectedImages.clear();
      _selectedFiles.clear();
    });
    // Dismiss the soft keyboard after send.
    _focusNode.unfocus();
  }

  String _getMimeType(String path) {
    if (path.toLowerCase().endsWith('.png')) return 'image/png';
    if (path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (path.toLowerCase().endsWith('.gif')) return 'image/gif';
    if (path.toLowerCase().endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // default
  }

  /// Compact is a Pro feature (free users see a PRO badge and the paywall);
  /// the open-source build has no Compact control at all.
  bool _shouldShowCompactButton(double contextPercentage) {
    return ProFeatures.included &&
        widget.onCompactChat != null &&
        contextPercentage >= ContextFit.fitFraction;
  }

  Widget _buildCompactChatControl(
    AppLocalizations l10n,
    ColorScheme colorScheme, {
    required bool compact,
  }) {
    return ListenableBuilder(
      listenable: SubscriptionService(),
      builder: (context, _) {
        final label =
            widget.isCompacting ? l10n.compactingChat : l10n.compactChat;
        final enabled = !widget.isLoading && !widget.isCompacting;
        final isPremium = SubscriptionService().isPremium;
        return Tooltip(
          message: l10n.compactChatHint,
          child: GestureDetector(
            onTap: enabled
                ? (isPremium ? widget.onCompactChat : _openCompactPaywall)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.compress_rounded,
                    size: compact ? 14 : 16,
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.45),
                    ),
                  ),
                  if (!isPremium) ...[
                    const SizedBox(width: 4),
                    const ProBadge(compact: true),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCompactPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  ContextUsageMessage _contextUsageMessage(ChatMessage message) {
    final stats = message.stats;
    if (stats?.inputTokens != null && stats?.totalOutputTokens != null) {
      return ContextUsageMessage(
        content: message.content,
        inputTokens: stats!.inputTokens,
        outputTokens: stats.totalOutputTokens,
      );
    }
    final usage = message.usage;
    if (usage != null) {
      return ContextUsageMessage(
        content: message.content,
        inputTokens: usage.promptTokens,
        outputTokens: usage.completionTokens,
      );
    }
    return ContextUsageMessage(content: message.content);
  }

  int _calculateUsedContext() {
    if (widget.messages == null || widget.settings == null) return 0;

    final messages = widget.messages!;
    final throughId = widget.compactThroughMessageId;
    var start = 0;
    if (throughId != null && throughId.isNotEmpty) {
      final idx = messages.indexWhere((m) => m.id == throughId);
      if (idx >= 0) start = idx + 1;
    }

    return ContextUsage.used(
      messages: [
        for (final message in messages.skip(start))
          _contextUsageMessage(message),
      ],
      systemPrompt: widget.settings!.systemPrompt,
      draft: _controller.text,
      compactSummary: widget.compactSummary,
    );
  }

  int _getMaxContextLength() {
    final settings = widget.settings;

    // 1) Last response's reported context (most accurate when present).
    if (widget.actualModelContextLength != null &&
        widget.actualModelContextLength! > 0) {
      return widget.actualModelContextLength!;
    }

    // 2) On-device: bar must match the clamped size used by inference — not the
    // desktop-sized global contextWindow (that made ~1k tokens look like "6%").
    final kind = settings?.activeProviderKind;
    if (settings != null && (kind == 'onDeviceGguf' || kind == 'onDeviceMlx')) {
      return OnDeviceLLMService.effectiveContextSize(settings);
    }

    // 3) LM Studio / server: prefer *loaded* context over the model's theoretical max.
    if (widget.selectedModelLoadedContextLength != null &&
        widget.selectedModelLoadedContextLength! > 0) {
      return widget.selectedModelLoadedContextLength!;
    }

    if (settings == null) return 4096;

    // 4) What we'll ask the server to load with (Model Loading config),
    //    never larger than Context Window's effective budget.
    return settings.effectiveContextWindow;
  }

  @override
  Widget build(BuildContext context) {
    final usedContext = _calculateUsedContext();
    final maxContext = _getMaxContextLength();
    final contextPercentage = maxContext > 0 ? (usedContext / maxContext) : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? colorScheme.surface.withValues(alpha: 0.05)
        : colorScheme.surface.withValues(alpha: 0.35);
    final inputFillColor = isDark
        ? colorScheme.surfaceVariant.withValues(alpha: 0.35)
        : colorScheme.surface.withValues(alpha: 0.55);
    final outlineColor =
        colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.3);
    final hintColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final textColor = colorScheme.onSurface;
    final l10n = AppLocalizations.of(context);

    if (!context.watch<SettingsProvider>().settings.useLegacyComposer) {
      return _buildDesktopShellInput(context, l10n, colorScheme, isDark);
    }

    final showComposerBars =
        widget.settings != null && (widget.messages != null || _hasMcpTools);

    final content = ClipRect(
      child: GlassBlur(
        sigmaX: 12,
        sigmaY: 12,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, showComposerBars ? 8 : 16, 16, 16),
          decoration: BoxDecoration(
            color: panelColor,
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Collapsible Context & MCP bars
                if (widget.messages != null && widget.settings != null) ...[
                  _barsExpanded
                      ? _buildExpandedBars(contextPercentage, usedContext,
                          maxContext, colorScheme, l10n)
                      : _buildCompactBars(contextPercentage, colorScheme, l10n),
                  const SizedBox(height: 8),
                ] else if (widget.settings != null && _hasMcpTools) ...[
                  _barsExpanded
                      ? _buildExpandedMcpOnly(colorScheme, l10n)
                      : _buildCompactMcpOnly(colorScheme, l10n),
                  const SizedBox(height: 8),
                ],

                // Image preview row
                if (_selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // File attachment preview row
                if (_selectedFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          final accent = _fileTypeAccent(file.type);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 200,
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 14, 10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getFileIcon(file.type),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              file.fileName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${file.typeDisplayName} · ${file.fileSizeDisplay}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme.outline,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => _removeFile(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.error,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // @mention autocomplete popup
                if (_activeMentionQuery != null)
                  _buildMentionSuggestions(colorScheme),

                // Message input row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildKeyListenerWrapper(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: TextStyle(color: textColor),
                          cursorColor: colorScheme.primary,
                          decoration: InputDecoration(
                            hintText: l10n.typeMessageHint,
                            hintStyle: TextStyle(color: hintColor),
                            filled: true,
                            fillColor: inputFillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: outlineColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: outlineColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.4),
                                  width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: _controller.text.isEmpty ||
                                    _showInputActions ||
                                    _isRecording
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Attachment menu button
                                      IconButton(
                                        onPressed: widget.isLoading
                                            ? null
                                            : _showAttachmentMenu,
                                        icon: Badge(
                                          isLabelVisible:
                                              _selectedImages.isNotEmpty ||
                                                  _selectedFiles.isNotEmpty,
                                          label: Text(
                                              '${_selectedImages.length + _selectedFiles.length}'),
                                          child: context.themeIcon(
                                            'input_attach',
                                            Icons.attach_file,
                                            size: 20,
                                            color: widget.isLoading
                                                ? hintColor
                                                : colorScheme.primary,
                                          ),
                                        ),
                                        tooltip: l10n.attachFilesTooltip,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      // Microphone button for voice input
                                      if (!widget.isLoading)
                                        IconButton(
                                          onPressed: _toggleVoiceInput,
                                          icon: context.themeIcon(
                                            'input_mic',
                                            Icons.mic,
                                            size: 20,
                                            color: _isRecording
                                                ? colorScheme.error
                                                : colorScheme.primary,
                                          ),
                                          tooltip: _isRecording
                                              ? l10n.voiceStopRecording
                                              : l10n.voiceStartRecording,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      const SizedBox(width: 2),
                                    ],
                                  )
                                : IconButton(
                                    onPressed: () => setState(
                                        () => _showInputActions = true),
                                    icon: Badge(
                                      isLabelVisible:
                                          _selectedImages.isNotEmpty ||
                                              _selectedFiles.isNotEmpty,
                                      label: Text(
                                          '${_selectedImages.length + _selectedFiles.length}'),
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        size: 22,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    tooltip: l10n.attachFilesTooltip,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                          ),
                          maxLines: 8,
                          minLines: 1,
                          textInputAction: _effectiveEnterMode() == 'send'
                              ? TextInputAction.send
                              : TextInputAction.newline,
                          onSubmitted: _effectiveEnterMode() == 'send'
                              ? (_) => _sendMessage()
                              : null,
                          onChanged: (_) => setState(() {
                            if (_controller.text.isNotEmpty) {
                              _showInputActions = false;
                            }
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send or Stop button
                    FloatingActionButton.small(
                      onPressed: widget.isLoading
                          ? (widget.onStopGeneration ?? () {})
                          : (_hasSendableContent ? _sendMessage : null),
                      backgroundColor:
                          widget.isLoading ? colorScheme.primary : null,
                      foregroundColor: widget.isLoading
                          ? Colors.black.withValues(alpha: 0.88)
                          : null,
                      child: widget.isLoading
                          ? const Icon(Icons.stop_rounded)
                          : context.themeIcon('input_send', Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!_supportsFileDrop) return content;
    return DropTarget(
      onDragDone: (detail) {
        final paths = detail.files
            .map((file) => file.path)
            .where((p) => p.isNotEmpty)
            .toList();
        if (paths.isNotEmpty) {
          _handleDroppedPaths(paths);
        }
      },
      child: content,
    );
  }

  Widget _buildDesktopShellInput(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    // Match chat header / shell surface so the composer doesn't float on a
    // different tone from the message list.
    final shellBg = isDark ? const Color(0xFF0E1117) : colorScheme.surface;
    final fieldBg = isDark
        // Nearly flush with shell — avoids a “lifted card / shadow” look.
        ? const Color(0xFF141820)
        : Colors.white.withValues(alpha: 0.9);
    final hintColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.65);
    final textColor = colorScheme.onSurface;
    final usedContext = _calculateUsedContext();
    final maxContext = _getMaxContextLength();
    final contextPercentage = maxContext > 0 ? (usedContext / maxContext) : 0.0;

    Widget wrapDrop(Widget child) {
      if (!_supportsFileDrop) return child;
      return DropTarget(
        onDragDone: (detail) {
          final paths = detail.files
              .map((file) => file.path)
              .where((p) => p.isNotEmpty)
              .toList();
          if (paths.isNotEmpty) _handleDroppedPaths(paths);
        },
        child: child,
      );
    }

    final isCompactComposer = !prefersDesktopShell(context);

    final actionChips = <Widget>[
      _DesktopActionChip(
        icon: Icons.attach_file_rounded,
        label: 'Attach',
        iconOnly: true,
        onTap: widget.isLoading ? null : _showAttachmentMenu,
      ),
      _DesktopActionChip(
        icon: Icons.content_paste_rounded,
        label: 'Paste',
        iconOnly: true,
        onTap: widget.isLoading
            ? null
            : () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text;
                if (text != null && text.isNotEmpty) {
                  _controller.text = text;
                  _controller.selection =
                      TextSelection.collapsed(offset: text.length);
                  setState(() {});
                }
              },
      ),
      if (_shouldShowCompactButton(contextPercentage))
        ListenableBuilder(
          listenable: SubscriptionService(),
          builder: (context, _) {
            final isPremium = SubscriptionService().isPremium;
            return _DesktopActionChip(
              icon: Icons.compress_rounded,
              label:
                  widget.isCompacting ? l10n.compactingChat : l10n.compactChat,
              selected: true,
              showProBadge: !isPremium,
              onTap: (widget.isLoading || widget.isCompacting)
                  ? null
                  : (isPremium ? widget.onCompactChat : _openCompactPaywall),
            );
          },
        ),
      if (_canShowProSearch)
        _DesktopActionChip(
          icon: _proSearchToolIcon,
          label: isCompactComposer ? 'Search' : 'Pro Search',
          iconOnly: isCompactComposer,
          selected: _isProSearchActive,
          selectedColor: _proSearchBg,
          foregroundColor: _isProSearchActive ? _proSearchFg : null,
          onTap: widget.isLoading ? null : _toggleProSearch,
        ),
      if (_canShowCodeSandbox)
        _DesktopActionChip(
          icon: Icons.terminal_rounded,
          label: isCompactComposer ? 'Code' : l10n.codeSandbox,
          iconOnly: isCompactComposer,
          selected: _isCodeSandboxActive,
          selectedColor: _sandboxBg,
          foregroundColor: _isCodeSandboxActive ? _sandboxFg : null,
          onTap: widget.isLoading ? null : _toggleCodeSandbox,
        ),
      if (_canShowSearxng)
        _DesktopActionChip(
          icon: _searxngToolIcon,
          label: 'SearXNG',
          iconOnly: isCompactComposer,
          selected: _isSearxngActive,
          onTap: widget.isLoading ? null : _toggleSearxng,
        ),
      if (_canShowThinking)
        _DesktopActionChip(
          iconWidget: const ThinkBrainIcon(size: 14),
          label: l10n.think,
          iconOnly: isCompactComposer,
          selected: _isThinkingActive,
          tooltip: _canControlThinking
              ? l10n.reasoningHelpShort
              : l10n.reasoningNotExposedChatHint,
          onTap:
              widget.isLoading || !_canControlThinking ? null : _toggleThinking,
        ),
    ];

    // Integrated / ephemeral MCP chips (same visibility rules as compact bar).
    final mcpChips = <Widget>[];
    if (widget.settings?.enableToolUse == true) {
      final integratedNames = <String>{};
      if (widget.settings?.integratedMcps != null) {
        for (final mcp
            in widget.settings!.integratedMcps!.where((m) => m.enabled)) {
          integratedNames.add(mcp.name);
          if (_isProSearchActive && _proSearchOverlapNames.contains(mcp.name)) {
            continue;
          }
          mcpChips.add(
            _DesktopActionChip(
              icon: Icons.extension_rounded,
              label: mcp.name,
              selected: true,
              onTap: widget.isLoading
                  ? null
                  : () => widget.onToggleIntegratedMcp?.call(mcp.name),
            ),
          );
        }
      }
      if (widget.settings?.mcpServers != null) {
        for (final server in widget.settings!.mcpServers!.where((s) =>
            !integratedNames.contains(s.label) &&
            (widget.settings!.activeMcpServerLabels == null ||
                widget.settings!.activeMcpServerLabels!.contains(s.label)))) {
          mcpChips.add(
            _DesktopActionChip(
              icon: Icons.extension_rounded,
              label: server.label,
              selected: true,
              onTap: widget.isLoading
                  ? null
                  : () => widget.onToggleMcpServer?.call(server.label),
            ),
          );
        }
      }
    }

    if (mcpChips.isNotEmpty) {
      if (isCompactComposer && mcpChips.length > 1) {
        // Phone: one hub chip instead of wrapping many MCP labels.
        actionChips.add(
          _DesktopActionChip(
            icon: Icons.extension_rounded,
            label: 'MCP ${mcpChips.length}',
            selected: true,
            onTap: widget.isLoading
                ? null
                : () => _showShineMcpSheet(context, colorScheme),
          ),
        );
      } else {
        actionChips.addAll(mcpChips);
      }
    }

    final showMic = !_hasSendableContent && !widget.isLoading;

    return wrapDrop(
      Container(
        padding: EdgeInsets.fromLTRB(
          prefersDesktopShell(context) ? 20 : 12,
          8,
          prefersDesktopShell(context) ? 20 : 12,
          prefersDesktopShell(context) ? 16 : 10,
        ),
        color: shellBg,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_activeMentionQuery != null)
                _buildMentionSuggestions(colorScheme),
              if (_barsExpanded &&
                  widget.messages != null &&
                  widget.settings != null) ...[
                _buildExpandedBars(contextPercentage, usedContext, maxContext,
                    colorScheme, l10n,
                    includeMcpBar: false),
                const SizedBox(height: 8),
              ],
              if (_selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedImages.removeAt(index)),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Flat fill + purple shine on TOP of the fill (foregroundPainter).
              CustomPaint(
                foregroundPainter: ComposerShineBorder(
                  color: isDark ? const Color(0xFF9B87F5) : colorScheme.primary,
                  radius: 20,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Text field alone on top.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color:
                                  colorScheme.primary.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildKeyListenerWrapper(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style:
                                    TextStyle(color: textColor, fontSize: 15),
                                cursorColor: colorScheme.primary,
                                decoration: InputDecoration(
                                  hintText: l10n.typeMessageHint,
                                  hintStyle: TextStyle(color: hintColor),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                maxLines: 6,
                                minLines: 2,
                                textInputAction: _effectiveEnterMode() == 'send'
                                    ? TextInputAction.send
                                    : TextInputAction.newline,
                                onSubmitted: _effectiveEnterMode() == 'send'
                                    ? (_) => _sendMessage()
                                    : null,
                                onChanged: (_) => setState(() {
                                  if (_controller.text.isNotEmpty) {
                                    _showInputActions = false;
                                  }
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Chips scroll on one line; context ring + mic/send stay pinned.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (var i = 0;
                                      i < actionChips.length;
                                      i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    actionChips[i],
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (widget.messages != null &&
                              widget.settings != null) ...[
                            const SizedBox(width: 8),
                            _ContextRingButton(
                              progress: contextPercentage.clamp(0.0, 1.0),
                              selected: _barsExpanded,
                              onTap: () => setState(
                                  () => _barsExpanded = !_barsExpanded),
                            ),
                          ],
                          const SizedBox(width: 8),
                          _DesktopRoundButton(
                            icon: widget.isLoading
                                ? Icons.stop_rounded
                                : (showMic
                                    ? (_isRecording
                                        ? Icons.stop_rounded
                                        : Icons.mic_none_rounded)
                                    : Icons.arrow_upward_rounded),
                            filled: true,
                            iconColor: Colors.black.withValues(alpha: 0.88),
                            color: (widget.isLoading || _isRecording)
                                ? colorScheme.error
                                : colorScheme.primary.withValues(alpha: 0.85),
                            onTap: widget.isLoading
                                ? (widget.onStopGeneration ?? () {})
                                : (showMic ? _toggleVoiceInput : _sendMessage),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShineMcpSheet(BuildContext context, ColorScheme colorScheme) {
    final settings = widget.settings;
    if (settings == null) return;

    final tiles = <Widget>[];
    final integratedNames = <String>{};
    if (settings.integratedMcps != null) {
      for (final mcp in settings.integratedMcps!.where((m) => m.enabled)) {
        integratedNames.add(mcp.name);
        if (_isProSearchActive && _proSearchOverlapNames.contains(mcp.name)) {
          continue;
        }
        tiles.add(
          ListTile(
            leading: Icon(Icons.extension_rounded, color: colorScheme.primary),
            title: Text(mcp.name),
            trailing: const Icon(Icons.check_circle_outline),
            onTap: () {
              Navigator.pop(context);
              widget.onToggleIntegratedMcp?.call(mcp.name);
            },
          ),
        );
      }
    }
    if (settings.mcpServers != null) {
      for (final server in settings.mcpServers!.where((s) =>
          !integratedNames.contains(s.label) &&
          (settings.activeMcpServerLabels == null ||
              settings.activeMcpServerLabels!.contains(s.label)))) {
        tiles.add(
          ListTile(
            leading: Icon(Icons.hub_rounded, color: colorScheme.primary),
            title: Text(server.label),
            trailing: const Icon(Icons.check_circle_outline),
            onTap: () {
              Navigator.pop(context);
              widget.onToggleMcpServer?.call(server.label);
            },
          ),
        );
      }
    }
    if (tiles.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Active tools',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ...tiles,
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  IconData _getFileIcon(FileAttachmentType type) {
    switch (type) {
      case FileAttachmentType.text:
        return Icons.description_outlined;
      case FileAttachmentType.csv:
        return Icons.table_chart_outlined;
      case FileAttachmentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileAttachmentType.image:
        return Icons.image_outlined;
    }
  }

  Color _fileTypeAccent(FileAttachmentType type) {
    switch (type) {
      case FileAttachmentType.pdf:
        return const Color(0xFFFF6B6B);
      case FileAttachmentType.csv:
        return const Color(0xFF4ADE80);
      case FileAttachmentType.text:
        return const Color(0xFF60A5FA);
      case FileAttachmentType.image:
        return const Color(0xFFFBBF24);
    }
  }
}

class MessageInputController {
  _MessageInputState? _state;

  void _attach(_MessageInputState state) {
    _state = state;
  }

  void _detach(_MessageInputState state) {
    if (_state == state) {
      _state = null;
    }
  }

  void showAttachmentMenu() {
    _state?._showAttachmentMenu();
  }

  Future<void> pickVisionImage() async {
    await _state?._pickImage();
  }

  Future<void> capturePhoto() async {
    await _state?._captureImage();
  }

  Future<void> insertTranslatePromptFromClipboard() async {
    await _state?.insertTranslatePromptFromClipboard();
  }

  /// Prefill the composer (e.g. from a suggested prompt card) and focus it.
  void setText(String text, {bool requestFocus = true}) {
    if (requestFocus) {
      _state?._setComposerText(text);
    } else {
      final state = _state;
      if (state == null) return;
      state._controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }
}

/// Compact icon + label tile used in the attach-sheet photo row.
class _AttachGridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _AttachGridTile({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = enabled ? cs.primary : cs.outline;
    final bg = enabled
        ? cs.primaryContainer.withValues(alpha: 0.45)
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: enabled ? cs.onSurface : cs.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextRingButton extends StatelessWidget {
  final double progress;
  final bool selected;
  final VoidCallback onTap;

  const _ContextRingButton({
    required this.progress,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = cs.onSurface.withValues(alpha: isDark ? 0.22 : 0.18);
    final fill = progress > 0.8
        ? cs.error
        : progress > 0.6
            ? cs.primary
            : cs.onSurfaceVariant;
    return Tooltip(
      message: 'Context ${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
      child: Material(
        color: selected
            ? cs.primary.withValues(alpha: isDark ? 0.18 : 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomPaint(
                painter: _ContextRingPainter(
                  progress: progress.clamp(0.0, 1.0),
                  trackColor: track,
                  progressColor: fill,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  const _ContextRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    stroke.color = trackColor;
    canvas.drawCircle(center, radius, stroke);

    if (progress <= 0) return;
    stroke.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57079632679, // top
      progress * 6.28318530718,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ContextRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _DesktopRoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool filled;

  const _DesktopRoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? (filled ? Colors.white : color),
          ),
        ),
      ),
    );
  }
}

class _DesktopActionChip extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool iconOnly;
  final bool showProBadge;
  final Color? selectedColor;
  final Color? foregroundColor;
  final String? tooltip;

  const _DesktopActionChip({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.iconOnly = false,
    this.showProBadge = false,
    this.selectedColor,
    this.foregroundColor,
    this.tooltip,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = foregroundColor ?? (selected ? cs.primary : cs.onSurfaceVariant);
    final bg = selected
        ? (selectedColor ?? cs.primary.withValues(alpha: isDark ? 0.18 : 0.12))
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05));
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Tooltip(
          message: tooltip ?? label,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 9 : 10,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: fg, size: 14),
                  child: (selected && !iconOnly)
                      ? Icon(Icons.check_rounded, size: 14, color: fg)
                      : (iconWidget ?? Icon(icon!, size: 14, color: fg)),
                ),
                if (!iconOnly) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
                if (showProBadge) ...[
                  const SizedBox(width: 4),
                  const ProBadge(compact: true),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width attach action (Documents / Transcribe).
class _AttachWideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachWideTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Equal-width 4-card starter row for macOS desktop empty chat (under composer).
class DesktopChatStarterCards extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onChatFiles;
  final VoidCallback? onTranslate;
  final VoidCallback? onTranscribe;
  final VoidCallback? onGeneratePersona;

  const DesktopChatStarterCards({
    super.key,
    required this.isLoading,
    this.onChatFiles,
    this.onTranslate,
    this.onTranscribe,
    this.onGeneratePersona,
  });

  List<_StarterAction> _actions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    // Soft, low-chroma wash so cards sit quietly under the composer.
    final wash = isDark
        ? const Color(0xFF0E1117).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.88);
    final softFill = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : colorScheme.onSurface.withValues(alpha: 0.04);
    final mutedAccent =
        colorScheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.45);
    return [
      _StarterAction(
        type: _StarterActionType.chatFiles,
        title: 'Chat Files',
        subtitle: 'PDF, MD, Excel, CSV…',
        chipIcon: Icons.description_outlined,
        chipLabel: l10n.starterAttach,
        gradient: [softFill, wash],
        accent: mutedAccent,
        icon: Icons.insert_drive_file_rounded,
        secondaryIcon: Icons.picture_as_pdf_rounded,
      ),
      _StarterAction(
        type: _StarterActionType.translate,
        title: 'Translate',
        subtitle: 'Paste text and convert',
        chipIcon: Icons.translate_rounded,
        chipLabel: 'Translate',
        gradient: [softFill, wash],
        accent: mutedAccent,
        icon: Icons.g_translate_rounded,
        secondaryIcon: Icons.swap_horiz_rounded,
      ),
      _StarterAction(
        type: _StarterActionType.transcribe,
        title: 'Transcribe',
        subtitle: 'Audio → text + Q&A',
        chipIcon: Icons.transcribe_rounded,
        chipLabel: 'Transcribe',
        gradient: [softFill, wash],
        accent: mutedAccent,
        icon: Icons.mic_rounded,
        secondaryIcon: Icons.subtitles_outlined,
      ),
      _StarterAction(
        type: _StarterActionType.generatePersona,
        title: 'New Persona',
        subtitle: 'AI avatar + prompt',
        chipIcon: Icons.auto_awesome_rounded,
        chipLabel: l10n.createLabel,
        gradient: [softFill, wash],
        accent: mutedAccent,
        icon: Icons.auto_awesome_rounded,
        secondaryIcon: Icons.face_retouching_natural_rounded,
      ),
    ];
  }

  VoidCallback? _callbackFor(_StarterActionType type) {
    if (isLoading) return null;
    switch (type) {
      case _StarterActionType.chatFiles:
        return onChatFiles;
      case _StarterActionType.translate:
        return onTranslate;
      case _StarterActionType.transcribe:
        return onTranscribe;
      case _StarterActionType.generatePersona:
        return onGeneratePersona;
      case _StarterActionType.images:
      case _StarterActionType.audioChat:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SizedBox(
        height: 118,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _DesktopStarterCard(
                  action: actions[i],
                  onTap: _callbackFor(actions[i].type),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopStarterCard extends StatelessWidget {
  final _StarterAction action;
  final VoidCallback? onTap;

  const _DesktopStarterCard({
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final ctaBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final ctaFg = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : colorScheme.onSurface.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF12151C)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: glassFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: glassBorder),
                    ),
                    child: Icon(
                      action.icon,
                      size: 17,
                      color: action.accent,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ctaBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: glassBorder),
                    ),
                    child: Text(
                      action.chipLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ctaFg,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.88),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatStarterTiles extends StatelessWidget {
  final bool showImages;
  final bool isLoading;
  final VoidCallback? onChatFiles;
  final VoidCallback? onImages;
  final VoidCallback? onTranslate;
  final VoidCallback? onAudioChat;
  final VoidCallback? onTranscribe;
  final VoidCallback? onGeneratePersona;

  const ChatStarterTiles({
    super.key,
    required this.showImages,
    required this.isLoading,
    this.onChatFiles,
    this.onImages,
    this.onTranslate,
    this.onAudioChat,
    this.onTranscribe,
    this.onGeneratePersona,
  });

  List<_StarterAction> _buildStarterActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final wash = isDark
        ? const Color(0xFF1A1428).withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.88);
    final actions = <_StarterAction>[
      _StarterAction(
        type: _StarterActionType.chatFiles,
        title: 'Chat Files',
        subtitle: 'PDF, MD, Excel, CSV…',
        chipIcon: Icons.description_outlined,
        chipLabel: l10n.starterAttach,
        gradient: [
          colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.16),
          wash,
        ],
        accent: colorScheme.primary.withValues(alpha: 0.85),
        icon: Icons.insert_drive_file_rounded,
        secondaryIcon: Icons.picture_as_pdf_rounded,
      ),
      _StarterAction(
        type: _StarterActionType.translate,
        title: 'Translate',
        subtitle: 'Paste text and convert',
        chipIcon: Icons.translate_rounded,
        chipLabel: 'Prompt',
        gradient: [
          const Color(0xFF6DA8FF).withValues(alpha: isDark ? 0.12 : 0.18),
          wash,
        ],
        accent: const Color(0xFF5A84D8),
        icon: Icons.g_translate_rounded,
        secondaryIcon: Icons.swap_horiz_rounded,
      ),
      _StarterAction(
        type: _StarterActionType.transcribe,
        title: 'Transcribe',
        subtitle: 'Audio → text + Q&A',
        chipIcon: Icons.transcribe_rounded,
        chipLabel: 'OnDevice',
        gradient: [
          const Color(0xFF9B7EDE).withValues(alpha: isDark ? 0.14 : 0.18),
          wash,
        ],
        accent: const Color(0xFF7B5EB8),
        icon: Icons.mic_rounded,
        secondaryIcon: Icons.subtitles_outlined,
      ),
      _StarterAction(
        type: _StarterActionType.audioChat,
        title: 'Audio Chat',
        subtitle: l10n.voiceMode,
        chipIcon: Icons.mic_none_rounded,
        chipLabel: l10n.starterMode,
        gradient: [
          colorScheme.onSurface.withValues(alpha: isDark ? 0.06 : 0.05),
          wash,
        ],
        accent: colorScheme.onSurface.withValues(alpha: 0.72),
        icon: Icons.graphic_eq_rounded,
        secondaryIcon: Icons.headset_mic_rounded,
      ),
      _StarterAction(
        type: _StarterActionType.generatePersona,
        title: 'New Persona',
        subtitle: 'AI avatar + prompt',
        chipIcon: Icons.auto_awesome_rounded,
        chipLabel: 'Create',
        gradient: [
          const Color(0xFF7C4DFF).withValues(alpha: isDark ? 0.16 : 0.18),
          wash,
        ],
        accent: const Color(0xFF7C4DFF),
        icon: Icons.auto_awesome_rounded,
        secondaryIcon: Icons.face_retouching_natural_rounded,
      ),
    ];

    if (showImages) {
      actions.insert(
        1,
        _StarterAction(
          type: _StarterActionType.images,
          title: 'Images',
          subtitle: l10n.photoLibrary,
          chipIcon: Icons.image_outlined,
          chipLabel: l10n.starterImages,
          gradient: [
            const Color(0xFF6ACF8B).withValues(alpha: isDark ? 0.12 : 0.18),
            wash,
          ],
          accent: const Color(0xFF3A8A65),
          icon: Icons.image_search_rounded,
          secondaryIcon: Icons.camera_alt_rounded,
        ),
      );
    }

    return actions;
  }

  VoidCallback? _callbackFor(_StarterActionType type) {
    if (isLoading) return null;
    switch (type) {
      case _StarterActionType.chatFiles:
        return onChatFiles;
      case _StarterActionType.images:
        return onImages;
      case _StarterActionType.translate:
        return onTranslate;
      case _StarterActionType.transcribe:
        return onTranscribe;
      case _StarterActionType.audioChat:
        return onAudioChat;
      case _StarterActionType.generatePersona:
        return onGeneratePersona;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _buildStarterActions(context);

    // Full-bleed row with edge fade (same treatment as scrolling prompt chips).
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 110,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0x00000000),
                Color(0xFF000000),
                Color(0xFF000000),
                Color(0x00000000),
              ],
              stops: [0.0, 0.06, 0.94, 1.0],
            ).createShader(bounds);
          },
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _StarterActionTile(
                action: action,
                onTap: _callbackFor(action.type),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _StarterActionType {
  chatFiles,
  images,
  translate,
  transcribe,
  audioChat,
  generatePersona,
}

class _StarterAction {
  final _StarterActionType type;
  final String title;
  final String subtitle;
  final IconData chipIcon;
  final String chipLabel;
  final List<Color> gradient;
  final Color accent;
  final IconData icon;
  final IconData secondaryIcon;

  const _StarterAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.chipIcon,
    required this.chipLabel,
    required this.gradient,
    required this.accent,
    required this.icon,
    required this.secondaryIcon,
  });
}

class _StarterActionTile extends StatelessWidget {
  final _StarterAction action;
  final VoidCallback? onTap;

  const _StarterActionTile({
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill = isDark
        ? const Color(0xFF1A1428).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.55);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.06);
    final sheenTop = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.65);
    final sheenBottom = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.white.withValues(alpha: 0.15);

    return SizedBox(
      width: 148,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: GlassBlur(
              sigmaX: 18,
              sigmaY: 18,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? null : Colors.white.withValues(alpha: 0.72),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: action.gradient,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [sheenTop, sheenBottom],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glassFill,
                          border: Border.all(color: glassBorder),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              action.secondaryIcon,
                              size: 13,
                              color: action.accent.withValues(alpha: 0.26),
                            ),
                            Icon(
                              action.icon,
                              size: 18,
                              color: action.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: glassFill,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              action.chipIcon,
                              size: 11,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.86),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              action.chipLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.86),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            action.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.92),
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            action.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}
