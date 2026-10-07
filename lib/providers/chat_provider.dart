import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:provider/provider.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import '../models/group_chat_participant.dart';
import '../utils/response_parser.dart';
import '../utils/chat_title.dart';
import '../utils/chat_image_payload.dart';
import '../utils/chat_image_compress.dart';
import '../utils/host_inference_error.dart';
import '../utils/chat_message_normalizer.dart';
import '../utils/pro_search_result_logger.dart';
import '../utils/remote_host_backends.dart';
import '../utils/stream_repetition_guard.dart';
import '../utils/context_fit.dart';
import '../utils/param_preset_key.dart';
import '../utils/param_preset_resolver.dart';
import '../utils/connect_host_error.dart';
import '../utils/localhost_connection_error.dart';
import '../utils/lan_server_error.dart';
import '../utils/model_not_found_error.dart';
import '../utils/output_token_limit_error.dart';
import '../utils/thinking_budget.dart';
import '../utils/expression_tags.dart';
import '../utils/persona_greeting.dart';
import '../utils/image_gen_prompt.dart';
import '../utils/comfyui_prompt_error.dart';
import '../utils/comfyui_catalog.dart';
import '../utils/image_gen_unreachable_error.dart';
import '../utils/lms_mcp_error.dart';
import '../utils/server_unreachable_error.dart';
import '../utils/lms_http_error.dart';
import '../utils/unique_id.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/memory_category.dart';
import '../models/message_stats.dart';
import '../models/file_attachment.dart';
import '../services/database_service.dart';
import '../services/generated_image_library_service.dart';
import '../models/generated_image_library_item.dart';
import '../services/lm_studio_service.dart';
import '../services/ollama_service.dart';
import '../services/mcp_http_client.dart';
import '../services/tool_support_resolver.dart';
import '../desktop/inference/local_inference_engine.dart';
import '../services/on_device_llm_service.dart';
import '../services/persona_memory_service.dart';
import '../services/persona_analytics_service.dart';
import '../services/builtin_persona_service.dart';
import '../services/reasoning_support_service.dart';
import '../services/review_service.dart';
import '../services/live_activity_service.dart';
import '../services/tool_service.dart';
import '../services/branching_service.dart';
import '../services/image_generation_service.dart';
import '../services/image_generation_facade.dart';
import '../services/widget_data_service.dart';
import '../services/icloud_sync_service.dart';
import '../services/home_sync_service.dart';
import '../models/app_settings.dart';
import '../models/param_preset.dart';
import '../models/system_prompt.dart';
import '../utils/group_chat_pro_gate.dart';
import '../utils/group_participant_backend.dart';
import '../utils/on_device_attachments.dart';
import '../utils/app_navigator.dart';
import '../utils/streaming_phase.dart';
import '../models/model_load_config.dart';
import '../widgets/provider_model_setup_dialog.dart';
import 'settings_provider.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

part '../pro/group_chat/chat_provider_group.dart';
part '../pro/chat/chat_provider_memory.dart';
part '../pro/chat/chat_provider_compact.dart';
part '../pro/tools/chat_provider_pro_tools.dart';

/// One-shot toast shown by [ChatScreen] after the provider handles an event.
enum ChatToast {
  reasoningUnsupported,
  transcriptionContextLarge,
  compactFailed,
  compactNeedModel,
}

/// A single memory extraction event — displayed as a chip with undo.
class MemoryEvent {
  final String id;
  final bool wasUpdate;
  final String fact;
  final String category;

  /// Where the item was filed, so the undo chip can show "character note"
  /// rather than implying the model learned something about the user.
  final MemoryScope scope;
  final String? previousContent;

  const MemoryEvent({
    required this.id,
    required this.wasUpdate,
    required this.fact,
    required this.category,
    this.scope = MemoryScope.global,
    this.previousContent,
  });
}

/// Monotonic id for messages and conversations (same-ms New Chat used to collide).
String _uid() => uniqueTimeId();

class ChatProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LMStudioService _lmStudioService = LMStudioService();
  final ReviewService _reviewService = ReviewService();
  final LiveActivityService _liveActivityService = LiveActivityService();

  @override
  void notifyListeners() {
    super.notifyListeners();
    // Token-by-token notifies would queue a Home/iCloud round-trip every
    // chunk. Drop any 3s debounce already armed and wait until the reply
    // (including background generation after switching chats) is idle.
    if (isGenerationInFlight) {
      ICloudSyncService().cancelPendingSyncUp();
      HomeSyncService.instance.cancelPendingSchedule();
      return;
    }
    ICloudSyncService().scheduleSyncUp();
    HomeSyncService.instance.schedule();
  }

  // Live Activity state
  String? _liveActivityModelName;
  int _liveActivityTokens = 0;
  DateTime? _lastLiveActivityUpdate;

  List<ChatConversation> _conversations = [];
  ChatConversation? _currentConversation;
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  bool _isSendingMessage = false;
  bool _isCompacting = false;
  bool _isAutonomousCycling = false;
  bool _shouldCancelAutonomous = false;

  /// Manual ("I choose who speaks") group chat: waiting for user to tap a name.
  Timer? _manualAskNudgeTimer;
  bool _showManualAskNudge = false;
  String? _manualAskNudgeConversationId;

  /// Participant ids currently streaming a reply in a group chat.
  final Set<String> _groupReplyInFlight = {};

  /// Memory extraction, title gen, and other one-shots share this chain so
  /// LM Studio (especially MLX) never sees two predictions on the same model.
  Future<void> _exclusiveInferenceJob = Future<void>.value();
  String? _error;
  String? _errorDetail; // Technical error details for advanced users
  ChatToast? _pendingToast;
  int? _actualModelContextLength; // Actual context length from model_info
  DateTime? _streamStartAt; // For measuring thinking/response duration
  DateTime? _thinkingEndAt; // Marks when </think> is seen
  final Map<String, int> _thinkingDurationsMs = {}; // messageId -> ms

  // Memory extraction events — shown as chips with undo below assistant messages
  // Key = assistant message ID, Value = list of events for that response
  final Map<String, List<MemoryEvent>> _memoryEvents = {};

  // For saving multiple outputs when regenerating responses
  List<ChatMessage>? _pendingAlternatives;

  // Streaming status indicators
  String?
      _streamingStatus; // e.g., "Loading model...", "Processing prompt...", "Thinking..."
  final List<String> _streamingPhaseLog = [];
  double? _streamingProgress; // 0.0 to 1.0 for progress bars
  String? _currentReasoning; // Accumulated reasoning content
  bool _isInReasoningMode = false;
  bool _shouldCancelGeneration = false; // Flag to cancel ongoing generation
  bool _reviewEligibleReply = false; // Clean sendMessage reply, for review prompt
  bool _isModelLoading = false; // True when model is being loaded
  double? _modelLoadingProgress; // 0.0 to 1.0 for model loading

  // Wake lock & background support
  Timer? _partialSaveTimer; // Periodically saves partial response to DB
  String? _partialResponseTempId; // Temp message ID for partial saves
  String _partialResponseContent = ''; // Accumulated content for partial saves

  // In-flight image generation (auto or tap). Owned here so sending another
  // chat message or leaving the screen cannot drop progress or the result.
  // ComfyUI/A1111 run one graph at a time, so extra Generates queue instead
  // of interrupting — otherwise the previous image is discarded.
  _ImageGenJob? _imageGenJob;
  final List<_ImageGenJob> _imageGenQueue = [];
  bool _imageGenPumping = false;
  AppSettings? _imageGenSettings;
  int _imageGenSeq = 0;

  // Voice mode flag — when true, defer auto image generation until TTS finishes
  // to avoid notifyListeners() storms that interrupt audio playback.
  bool _voiceModeActive = false;

  /// Set for the duration of [sendMessage] so nested LM Studio paths can
  /// resolve load-param conflicts via [SettingsProvider].
  SettingsProvider? _activeSettingsProvider;
  BuildContext? _activeUiContext;

  bool _modelSupportsTools(AppSettings settings) =>
      ToolSupportResolver.instance.currentModelSupportsTools(
        settings,
        availableModels: _activeSettingsProvider?.availableModels,
      );

  /// LM Studio REST (`/api/v1/chat` and `/v1/chat/completions`). Home
  /// (`lmMiniDesktop`) speaks the same API. Ollama / oMLX / cloud must never
  /// fall through to this path.
  bool _usesLmStudioChatApi(AppSettings settings) {
    final kind = settings.activeProviderKind;
    return kind == 'lmStudio' || kind == 'lmMiniDesktop';
  }

  /// Ollama, oMLX, Jan, and paid cloud providers. Always stay on that backend —
  /// even when Tool Use is off or the model cannot take tools.
  bool _usesCloudOrLocalOpenAiBackend(AppSettings settings) {
    return SettingsProvider.isCloudProviderKind(settings.activeProviderKind) ||
        _resolveEffectiveCloudProvider(settings: settings) != null;
  }

  /// Connection-refused copy for the active backend — never blame LM Studio
  /// when the user is on Ollama / oMLX / cloud / Home.
  String _serverUnreachableMessage(AppSettings settings) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      return 'On-device inference failed. Try unloading other apps or selecting a smaller model.';
    }
    if (kind == 'appleIntelligence') {
      return 'Apple Intelligence is unavailable on this device or build.';
    }
    if (kind == 'cloud') {
      return 'Network error. Make sure your device is connected to the internet.';
    }
    final name = RemoteHostBackends.displayName(kind);
    final extra = kind == 'ollama'
        ? ' (default port 11434)'
        : kind == 'jan'
            ? ' (default port 1337)'
            : kind == 'unsloth'
                ? ' (default port 8888)'
                : '';
    return 'Cannot connect to $name. Make sure the server is running$extra.';
  }

  bool _isToolsUnsupportedError(Object error) {
    final lower = error.toString().toLowerCase();
    return lower.contains('does not support tools') ||
        lower.contains("doesn't support tools") ||
        lower.contains('does not support function') ||
        lower.contains('tool calling is not supported') ||
        lower.contains('tool use is not supported') ||
        lower.contains('tools are not supported') ||
        lower.contains('model does not support tool') ||
        lower.contains('tools not supported');
  }

  Future<void> _routeNetworkAssistantReply({
    required String content,
    required AppSettings settings,
    List<String>? imageUrls,
    String? userDisplayContent,
    String? memoryContext,
  }) async {
    final isGroupChat = _currentConversation!.settings['isGroupChat'] == true;
    if (isGroupChat) {
      await _proSendGroupMessage(
        content,
        settings,
        imageUrls,
        userDisplayContent: userDisplayContent,
        memoryContext: memoryContext,
      );
      return;
    }
    final lmStudioStateful = _usesLmStudioChatApi(settings) &&
        !(settings.enableToolUse && _modelSupportsTools(settings));
    if (lmStudioStateful && !_usesCloudOrLocalOpenAiBackend(settings)) {
      await _sendMessageStateful(
        content,
        settings,
        imageUrls,
        userDisplayContent: userDisplayContent,
        memoryContext: memoryContext,
      );
      return;
    }
    await _sendMessageWithTools(
      content,
      settings,
      imageUrls,
      userDisplayContent: userDisplayContent,
      memoryContext: memoryContext,
    );
  }

  // Voice call — tracks which conversation has an active voice/call session
  String? _voiceCallConversationId;

  // Context injection guard — prevents re-injecting history on every message.
  // Set to true after the first successful response in a conversation session.
  // Reset when switching/loading a different conversation.
  bool _sessionWarm = false;

  // Background generation tracking — when user switches conversations mid-stream
  String? _backgroundGeneratingConversationId;
  String?
      _sendMessageOriginId; // Tracks which conversation started the current sendMessage
  final Set<String> _unreadConversationIds = {};

  List<ChatConversation> get conversations => _conversations;

  /// Home-screen list: hide empty 1:1 drafts until the user sends a message.
  List<ChatConversation> get listedConversations =>
      _conversations.where((c) => !isEmptyDraftConversation(c)).toList();

  ChatConversation? conversationById(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    return index == -1 ? null : _conversations[index];
  }

  ChatConversation? get currentConversation => _currentConversation;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;

  bool get currentConversationHasGeneratedImages =>
      messagesHaveGeneratedImages(_currentMessages);

  List<GeneratedImageLibraryItem> generatedImagesForCurrentConversation() {
    final conv = _currentConversation;
    if (conv == null) return const [];
    return libraryItemsFromMessages(
      _currentMessages,
      conversationId: conv.id,
      conversationTitle: conv.title,
    );
  }

  /// True while tokens are arriving here or in a chat the user navigated away from.
  bool get isGenerationInFlight =>
      _isSendingMessage || _backgroundGeneratingConversationId != null;
  bool get isCompacting => _isCompacting;
  String? get compactSummary =>
      _currentConversation?.settings['compactSummary'] as String?;
  String? get compactThroughMessageId =>
      _currentConversation?.settings['compactThroughMessageId'] as String?;
  bool get isAutonomousCycling => _isAutonomousCycling;

  /// True after ~3s in manual group mode with no reply yet — UI should pulse Ask chips.
  bool get showManualAskNudge =>
      _showManualAskNudge &&
      _manualAskNudgeConversationId != null &&
      _currentConversation?.id == _manualAskNudgeConversationId;

  /// Participants currently generating a group reply.
  Set<String> get groupParticipantsInFlight =>
      Set<String>.unmodifiable(_groupReplyInFlight);

  /// Whether an Ask chip should be disabled: this participant is busy, or
  /// another in-flight participant shares the same provider backend.
  bool isGroupParticipantAskDisabled(
    GroupChatParticipant participant,
    AppSettings settings,
  ) {
    if (_groupReplyInFlight.isEmpty) return false;
    if (_groupReplyInFlight.contains(participant.id)) return true;
    final targetKind = _resolveParticipantProviderKind(participant, settings);
    for (final id in _groupReplyInFlight) {
      final busy = groupParticipants.where((p) => p.id == id).firstOrNull;
      if (busy == null) continue;
      if (_resolveParticipantProviderKind(busy, settings) == targetKind) {
        return true;
      }
    }
    return false;
  }

  /// Public provider kind for a group participant (for UI).
  String providerKindForGroupParticipant(
    GroupChatParticipant participant,
    AppSettings settings,
  ) =>
      _resolveParticipantProviderKind(participant, settings);
  String? get error => _error;
  String? get errorDetail => _errorDetail; // Technical error details

  int? get latestLargeUserImageBytes =>
      ChatImagePayload.largeBytesOrNull(_latestUserImageUrls());

  bool get canCompressAndResendImages {
    if (!HostInferenceError.isTerminated(_error) &&
        !HostInferenceError.isTerminated(_errorDetail)) {
      return false;
    }
    return latestLargeUserImageBytes != null;
  }

  /// Returns a pending toast once, so the UI can show it exactly one time.
  ChatToast? takePendingToast() {
    final toast = _pendingToast;
    _pendingToast = null;
    return toast;
  }

  /// True once after a [sendMessage] reply finished without error or cancel.
  /// The chat screen consumes it to decide whether a review prompt may show.
  bool takeReviewEligibleReply() {
    final eligible = _reviewEligibleReply;
    _reviewEligibleReply = false;
    return eligible;
  }

  int? get actualModelContextLength => _actualModelContextLength;
  int? thinkingDurationFor(String messageId) => _thinkingDurationsMs[messageId];
  bool hasUnread(String conversationId) =>
      _unreadConversationIds.contains(conversationId);
  String? get backgroundGeneratingConversationId =>
      _backgroundGeneratingConversationId;

  // Streaming status getters
  String? get streamingStatus => _streamingStatus;

  /// High thinking filled the output cap; this turn is retried at low effort.
  bool get thinkingBudgetNotice => _thinkingBudgetNotice;
  bool _thinkingBudgetNotice = false;

  void dismissThinkingBudgetNotice() {
    if (!_thinkingBudgetNotice) return;
    _thinkingBudgetNotice = false;
    notifyListeners();
  }

  List<String> get streamingPhaseLog =>
      List<String>.unmodifiable(_streamingPhaseLog);
  double? get streamingProgress => _streamingProgress;
  String? get currentReasoning => _currentReasoning;
  bool get isInReasoningMode => _isInReasoningMode;
  bool get isModelLoading => _isModelLoading;
  double? get modelLoadingProgress => _modelLoadingProgress;

  // Image generation getters (auto-gen and the bubble button share this job)
  bool get isAutoGeneratingImage =>
      _imageGenJob != null || _imageGenQueue.isNotEmpty;
  double get autoGenImageProgress => _imageGenJob?.progress ?? 0;
  String? get autoGenImageMessageId => _imageGenJob?.messageId;

  bool isImageGenQueued(String messageId) =>
      _imageGenQueue.any((j) => j.messageId == messageId);

  bool isImageGeneratingFor(String messageId) =>
      _imageGenJob?.messageId == messageId || isImageGenQueued(messageId);

  double imageGenProgressFor(String messageId) {
    if (_imageGenJob?.messageId == messageId) return _imageGenJob!.progress;
    return 0;
  }

  // Voice mode control — prevents auto image gen notifications from interrupting TTS
  bool get isVoiceModeActive => _voiceModeActive;
  void setVoiceModeActive(bool active) => _voiceModeActive = active;

  // Voice call tracking — which conversation has an active call/voice session
  String? get voiceCallConversationId => _voiceCallConversationId;
  bool get hasActiveVoiceCall => _voiceCallConversationId != null;
  void setVoiceCallConversationId(String? id) {
    if (_voiceCallConversationId == id) return;
    _voiceCallConversationId = id;
    _notifySafely();
  }

  /// notifyListeners() that is safe to call while the widget tree is locked
  /// (e.g. from a State.dispose() that runs during finalizeTree). Calling
  /// notifyListeners() there throws "setState()/markNeedsBuild() called when
  /// widget tree was locked". When mid-frame we defer to the next frame.
  void _notifySafely() {
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  Map<String, dynamic> _withLastUsedModel(
      Map<String, dynamic> settings, String? modelId) {
    if (modelId == null || modelId.isEmpty) return settings;
    final updatedSettings = Map<String, dynamic>.from(settings);
    updatedSettings['lastUsedModel'] = modelId;
    return updatedSettings;
  }

  /// Strip LM Studio parallel-instance suffixes (`model:2`) and normalize case.
  String _normalizeModelId(String? id) {
    if (id == null || id.isEmpty) return '';
    var s = id.trim().toLowerCase();
    s = s.replaceFirst(RegExp(r':\d+$'), '');
    return s;
  }

  /// True when two ids refer to the same LM Studio / catalog model.
  bool _isSameModelId(String? a, String? b) {
    final na = _normalizeModelId(a);
    final nb = _normalizeModelId(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    final aBase = na.split('/').last;
    final bBase = nb.split('/').last;
    if (aBase.isNotEmpty && aBase == bBase) return true;
    // Resolve short names against the loaded catalog when available.
    final sp = _activeSettingsProvider;
    if (sp != null) {
      final ra = sp.resolveLmStudioModel(a);
      final rb = sp.resolveLmStudioModel(b);
      if (ra != null && rb != null && ra.id == rb.id) return true;
    }
    return false;
  }

  /// Last model that produced an assistant turn in this chat (message field,
  /// then conversation settings fallback).
  String? _lastUsedModelId() {
    for (int i = _currentMessages.length - 1; i >= 0; i--) {
      final m = _currentMessages[i];
      if (m.role == 'assistant' &&
          m.model != null &&
          m.model!.isNotEmpty &&
          !m.id.startsWith('temp_')) {
        return m.model;
      }
    }
    final fromSettings = _currentConversation?.settings['lastUsedModel'];
    if (fromSettings is String && fromSettings.isNotEmpty) return fromSettings;
    return null;
  }

  /// If the selected model differs from the last one used in this chat,
  /// drop `previous_response_id` so the next send reinjects full history.
  /// Returns true when a switch was detected.
  Future<bool> _invalidateSessionIfModelChanged(String? selectedModel) async {
    if (_currentConversation == null ||
        selectedModel == null ||
        selectedModel.isEmpty) {
      return false;
    }
    final lastUsed = _lastUsedModelId();
    if (lastUsed == null || _isSameModelId(lastUsed, selectedModel)) {
      return false;
    }
    debugPrint(
        '🔄 Model changed: "$lastUsed" → "$selectedModel" — invalidating session '
        '(will reinject full history)');
    _currentConversation = _currentConversation!.copyWith(
      clearLastResponseId: true,
      updatedAt: DateTime.now(),
    );
    _sessionWarm = false;
    await _databaseService.updateConversation(_currentConversation!);
    _syncConversationInList(_currentConversation!);
    return true;
  }

  /// Keep the home-list copy of a conversation in sync (e.g. lastResponseId).
  /// Switching chats reads from this list, not from `_currentConversation`.
  /// A newer [ChatConversation.updatedAt] moves the row to the top, matching
  /// the database order used on the next launch.
  void _syncConversationInList(ChatConversation conv) {
    final index = _conversations.indexWhere((c) => c.id == conv.id);
    if (index == -1) {
      _conversations.insert(0, conv);
      return;
    }
    final moved =
        conv.updatedAt.isAfter(_conversations[index].updatedAt) && index != 0;
    if (moved) {
      _conversations.removeAt(index);
      _conversations.insert(0, conv);
      unawaited(
          WidgetDataService.updateRecentConversations(listedConversations));
    } else {
      _conversations[index] = conv;
    }
  }

  bool _setContextOverflowError(Object? error) {
    if (LMStudioService.isStreamClosedAfterStart(error)) return false;
    if (!LMStudioService.isContextOverflowError(error)) return false;
    _error = LMStudioService.contextOverflowUserMessage(
      error,
      largeImageBytes:
          ChatImagePayload.largeBytesOrNull(_latestUserImageUrls()),
    );
    _errorDetail = error.toString();
    return true;
  }

  /// LM Studio plugin / MCP failures. Unknown plugins get a setup message and
  /// are not support tickets. Pro Search and Code Sandbox stay reportable.
  bool _applyLmsPluginError(
    Object? error,
    AppSettings settings, {
    String? errorType,
  }) {
    if (!_usesLmStudioChatApi(settings)) return false;
    final known = LmsMcpError.isUnrecognizedPlugin(
          error,
          errorType: errorType,
        ) ||
        LmsMcpError.isEphemeralConnection(error, errorType: errorType) ||
        LmsMcpError.isProToolFailure(error);
    if (!known) return false;
    _error = LmsMcpError.userMessage(
      error,
      errorType: errorType,
      lmStudio: settings.activeProviderKind == 'lmStudio',
    );
    _errorDetail = LmsMcpError.isUnrecognizedPlugin(
      error,
      errorType: errorType,
    )
        ? error.toString()
        : null;
    return true;
  }

  bool _setHostInferenceError(Object? error) {
    if (!HostInferenceError.matches(error)) return false;
    _error = HostInferenceError.userMessage(
      error,
      largeImageBytes:
          ChatImagePayload.largeBytesOrNull(_latestUserImageUrls()),
    );
    _errorDetail = error.toString();
    return true;
  }

  bool _setStreamClosedAfterStartError(Object? error, AppSettings settings) {
    if (!LMStudioService.isStreamClosedAfterStart(error)) return false;
    final ctx = LMStudioService.contextOverflowTokens(error).contextTokens ??
        _loadedContextTokens(settings);
    _error = LMStudioService.streamClosedAfterStartUserMessage(
      contextTokens: ctx > 0 ? ctx : null,
      largeImageBytes:
          ChatImagePayload.largeBytesOrNull(_latestUserImageUrls()),
    );
    final detail = error is Map
        ? (error['error']?.toString() ?? error.toString())
        : error.toString();
    _errorDetail = detail;
    return true;
  }

  List<String>? _latestUserImageUrls() {
    for (final m in _currentMessages.reversed) {
      if (m.role != 'user') continue;
      if (m.imageUrls != null && m.imageUrls!.isNotEmpty) return m.imageUrls;
    }
    return null;
  }

  bool _isModelNotFoundChunk(
    String? errorType,
    String errorMsg,
    Map<String, dynamic> chunk,
  ) {
    return errorType == ModelNotFoundError.type ||
        ModelNotFoundError.matches(errorMsg) ||
        ModelNotFoundError.matches(chunk);
  }

  /// Localhost / LMS LAN / Connect 502 / missing-model — in-app help, not a crash dump.
  bool _setSetupGuidanceError(
    Object? error,
    AppSettings settings, {
    String? modelId,
  }) {
    final raw = error?.toString() ?? '';
    final clean = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
    if (clean.isEmpty) return false;

    if (LocalhostConnectionError.matches(
      clean,
      serverUrl: settings.serverUrl,
    )) {
      _error = LocalhostConnectionError.userMessage;
      _errorDetail = clean;
      return true;
    }
    if (DroppedRequestBodyError.matches(error) ||
        DroppedRequestBodyError.matches(clean)) {
      _error = DroppedRequestBodyError.userMessage;
      _errorDetail = clean;
      return true;
    }
    if (ModelNotFoundError.matches(error) ||
        ModelNotFoundError.matches(clean)) {
      _error = ModelNotFoundError.userMessageFor(
        modelId ?? settings.selectedModel,
      );
      _errorDetail = clean;
      return true;
    }
    if (LanServerError.shouldShowLmStudioLanHelp(
      error: clean,
      serverUrl: settings.serverUrl,
      providerKind: settings.activeProviderKind,
    )) {
      final kind = LanServerError.classify(clean);
      _error = kind == LanServerErrorKind.hostDown
          ? LanServerError.hostDownUserMessage
          : LanServerError.refusedUserMessage;
      _errorDetail = clean;
      return true;
    }
    final connectMessage = ConnectHostError.userMessageFor(
      clean,
      serverUrl: settings.serverUrl,
      isRemoteActive: settings.isRemoteActive,
      usbModeEnabled: settings.usbModeEnabled,
    );
    if (connectMessage != null) {
      _error = connectMessage;
      _errorDetail = clean;
      return true;
    }
    if (ServerUnreachableError.matches(clean) ||
        clean.contains('SocketException') ||
        clean.contains('Connection refused')) {
      _error = _serverUnreachableMessage(settings);
      _errorDetail = clean;
      return true;
    }
    return false;
  }

  /// Drop JIT / streaming chrome so the header progress bar cannot stick
  /// after an error return that skips the normal tool-loop cleanup.
  void _stopGenerationUi() {
    _isSendingMessage = false;
    _setStreamingStatus(null);
    _streamingProgress = null;
    _isModelLoading = false;
    _modelLoadingProgress = null;
    _endLiveActivity(force: true);
  }

  void _setStreamingStatus(String? value) {
    if (value == null) {
      _streamingStatus = null;
      _streamingPhaseLog.clear();
      return;
    }
    _streamingStatus = value;
    final phase = StreamingPhase.canonical(value);
    if (phase == null) return;
    if (StreamingPhase.shouldRecord(_streamingPhaseLog, phase)) {
      _streamingPhaseLog.add(phase);
    }
  }

  /// LM Studio no longer has this chat's `previous_response_id`.
  /// Next V1 send must inject the full transcript.
  Future<void> _dropStalePreviousResponseId() async {
    if (_currentConversation == null) return;
    debugPrint(
        '🔄 Stale previous_response_id — clearing session, will reinject history');
    if (_currentConversation!.lastResponseId != null) {
      _currentConversation = _currentConversation!.copyWith(
        clearLastResponseId: true,
        updatedAt: DateTime.now(),
      );
      await _databaseService.updateConversation(_currentConversation!);
      _syncConversationInList(_currentConversation!);
    }
    _sessionWarm = false;
  }

  /// Loaded context window for packing / compact. Prefer the running model's
  /// reported size, then the selected loaded instance, then load settings.
  int _loadedContextTokens(AppSettings settings) {
    if (_actualModelContextLength != null && _actualModelContextLength! > 0) {
      return _actualModelContextLength!;
    }
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      return OnDeviceLLMService.effectiveContextSize(settings);
    }
    final loaded = _activeSettingsProvider?.selectedModelLoadedContextLength;
    if (loaded != null && loaded > 0) return loaded;
    final chatOverride = _currentConversation?.settings['contextLength'];
    if (chatOverride is num && chatOverride > 0) return chatOverride.toInt();
    return settings.loadContextLength ?? settings.contextWindow;
  }

  int _historyBudget(AppSettings settings, {required int extraTokens}) {
    final loaded = _loadedContextTokens(settings);
    var budget = ContextFit.budgetFor(loaded) - extraTokens;
    final sys = settings.effectiveSystemPrompt;
    if (sys.isNotEmpty) {
      budget -= ContextFit.estimateTokens(sys);
    }
    if (budget < 0) return 0;
    return budget;
  }

  bool _isContextNoise(ChatMessage msg) {
    if (msg.id.startsWith('temp_')) return true;
    if (msg.role != 'user' && msg.role != 'assistant') return true;
    final c = msg.content;
    return c.startsWith('Tool call:') ||
        c.startsWith('MCP call:') ||
        c.startsWith('🔧 MCP call:');
  }

  List<ChatMessage> _messagesAfterCompact(List<ChatMessage> messages) {
    final throughId = compactThroughMessageId;
    if (throughId == null || throughId.isEmpty) return messages;
    final idx = messages.indexWhere((m) => m.id == throughId);
    if (idx < 0) return messages;
    return messages.sublist(idx + 1);
  }

  /// Prior turns Mini should pack: skip temp bubbles and the live user turn.
  List<ChatMessage> _priorMessagesForPacking() {
    final history = <ChatMessage>[];
    for (final m in _currentMessages) {
      if (m.id.startsWith('temp_')) continue;
      history.add(m);
    }
    if (history.isNotEmpty && history.last.role == 'user') {
      history.removeLast();
    }
    return history;
  }

  List<ContextTurn> _turnsFromMessages(
    List<ChatMessage> messages, {
    bool includeImagePrompts = false,
  }) {
    final names = <String, String>{};
    if (isGroupChat) {
      for (final p in _getGroupParticipants()) {
        names[p.id] = p.displayName;
      }
    }
    final turns = <ContextTurn>[];
    for (final msg in messages) {
      if (_isContextNoise(msg)) continue;
      if (msg.role == 'user') {
        turns.add(ContextTurn(role: 'user', text: msg.content));
      } else if (msg.role == 'assistant') {
        var text = assistantTurnForHistory(
          ResponseParser.answerOnly(msg.content),
          includeImagePrompts ? msg.imagePrompt : null,
        );
        final speakerId = msg.participantId;
        final name = speakerId == null ? null : names[speakerId];
        if (name != null && name.isNotEmpty) {
          text = '[$name]: $text';
        }
        turns.add(ContextTurn(role: 'assistant', text: text));
      }
    }
    return turns;
  }

  List<ChatMessage> _summaryStubMessages(String summary) {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'compact_user',
        role: 'user',
        content: '[Conversation summary]\n\n$summary',
        timestamp: now,
      ),
      ChatMessage(
        id: 'compact_assistant',
        role: 'assistant',
        content: 'Understood. I will continue from that summary.',
        timestamp: now,
      ),
    ];
  }

  List<ChatMessage> _chatMessagesFromTurns(List<ContextTurn> turns) {
    final now = DateTime.now();
    final out = <ChatMessage>[];
    var i = 0;
    for (final turn in turns) {
      if (turn.role == 'summary') {
        out.addAll(_summaryStubMessages(turn.text));
        continue;
      }
      out.add(ChatMessage(
        id: 'ctx_${i++}',
        role: turn.role == 'assistant' ? 'assistant' : 'user',
        content: turn.text,
        timestamp: now,
      ));
    }
    return out;
  }

  List<ChatMessage> _packedHistoryMessages(
    List<ChatMessage> history,
    AppSettings settings, {
    required int extraTokens,
  }) {
    final live = _messagesAfterCompact(history);
    final fitted = ContextFit.fit(
      turns: _turnsFromMessages(
        live,
        includeImagePrompts: settings.imageGenEnabled,
      ),
      maxTokens: _historyBudget(settings, extraTokens: extraTokens),
      mode: _contextFitMode(settings),
      compactSummary: compactSummary,
    );
    return _chatMessagesFromTurns(fitted);
  }

  ContextFitMode _contextFitMode(AppSettings settings) {
    if (!SubscriptionService().isPremium) return ContextFitMode.off;
    return ContextFitMode.parse(settings.contextFitMode);
  }

  String _formatTurnsAsTranscript(List<ContextTurn> turns) {
    final buffer = StringBuffer();
    for (final turn in turns) {
      if (turn.role == 'summary') {
        buffer.writeln('Previous summary:');
        buffer.writeln(turn.text);
        buffer.writeln();
        continue;
      }
      final label = turn.role == 'user' ? 'User' : 'Assistant';
      buffer.writeln('$label: ${turn.text}');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// Dump prior turns into a V1 `input` string (used when the server
  /// session is missing). Applies compact summary + roll / cut-middle.
  String _injectedHistoryInput(String content, AppSettings settings) {
    final historyMessages = _priorMessagesForPacking();
    if (historyMessages.isEmpty &&
        (compactSummary == null || compactSummary!.trim().isEmpty)) {
      return content;
    }
    final live = _messagesAfterCompact(historyMessages);
    final fitted = ContextFit.fit(
      turns: _turnsFromMessages(
        live,
        includeImagePrompts: settings.imageGenEnabled,
      ),
      maxTokens: _historyBudget(
        settings,
        extraTokens: ContextFit.estimateTokens(content),
      ),
      mode: _contextFitMode(settings),
      compactSummary: compactSummary,
    );
    return ContextFit.formatForStatefulInput(
      fitted,
      newUserContent: content,
    );
  }

  // Memory event getters & undo
  List<MemoryEvent> memoryEventsFor(String messageId) =>
      _memoryEvents[messageId] ?? const [];

  /// Undo a memory event — deletes or reverts the memory item.
  Future<void> undoMemoryEvent(String messageId, MemoryEvent event) async {
    final memory = MemoryService();
    if (event.wasUpdate && event.previousContent != null) {
      // Revert to previous content
      await memory.updateItem(event.id,
          content: event.previousContent!, category: event.category);
    } else {
      // Was a new save — delete it
      await memory.removeItem(event.id);
    }
    // Remove from the events list
    final events = _memoryEvents[messageId];
    if (events != null) {
      events.remove(event);
      if (events.isEmpty) _memoryEvents.remove(messageId);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Wake lock & partial-save helpers
  // ---------------------------------------------------------------------------

  Future<void> _beginGenerationSession(
    AppSettings settings, {
    String kind = kLiveActivityKindChat,
  }) async {
    _liveActivityTokens = 0;
    _lastLiveActivityUpdate = null;
    _liveActivityModelName = kind == kLiveActivityKindImage
        ? imageGenerationLiveActivityModelName(settings)
        : (settings.selectedModel ?? 'AI Model');
    await _liveActivityService.acquire(
      settings: settings,
      modelName: _liveActivityModelName!,
      chatTitle: _currentConversation?.title ?? 'Chat',
      kind: kind,
    );
  }

  /// Start a timer that periodically saves the partial response to the DB
  /// so that if the app is killed or the connection is lost the user still
  /// has whatever was generated so far.
  void _startPartialSaveTimer() {
    _partialSaveTimer?.cancel();
    _partialSaveTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _savePartialResponse(),
    );
  }

  /// Persist the current partial response to the database.
  /// Called periodically and also when the app goes to the background.
  Future<void> _savePartialResponse() async {
    if (_currentConversation == null) return;
    if (_partialResponseContent.isEmpty) return;
    if (!_isSendingMessage) return;

    try {
      // If we haven't saved a partial message yet, insert one
      if (_partialResponseTempId == null) {
        final partialId = 'partial_${DateTime.now().millisecondsSinceEpoch}';
        final partialMessage = ChatMessage(
          id: partialId,
          content: _partialResponseContent,
          role: 'assistant',
          timestamp: DateTime.now(),
        );
        await _databaseService.insertMessage(
            partialMessage, _currentConversation!.id);
        _partialResponseTempId = partialId;
        debugPrint(
            '💾 Partial response saved (new): ${_partialResponseContent.length} chars');
      } else {
        // Update the existing partial message
        final partialMessage = ChatMessage(
          id: _partialResponseTempId!,
          content: _partialResponseContent,
          role: 'assistant',
          timestamp: DateTime.now(),
        );
        await _databaseService.updateMessage(partialMessage);
        // debugPrint(
        //     '💾 Partial response updated: ${_partialResponseContent.length} chars');
        // debugPrint('💾 Partial response: ${_partialResponseContent}');
      }
    } catch (e) {
      debugPrint('⚠️ Partial save failed: $e');
    }
  }

  /// Called when the app is paused / backgrounded while streaming.
  /// Does a final save of the partial content immediately.
  Future<void> onAppPaused() async {
    if (_isSendingMessage && _partialResponseContent.isNotEmpty) {
      debugPrint('📱 App paused during streaming – saving partial response');
      await _savePartialResponse();
    }
  }

  /// Stop the periodic save timer and clean up any partial message from DB.
  Future<void> _stopPartialSaveTimer() async {
    _partialSaveTimer?.cancel();
    _partialSaveTimer = null;

    // Remove the partial message from DB since the final message will be saved
    if (_partialResponseTempId != null) {
      try {
        await _databaseService.deleteMessage(_partialResponseTempId!);
        debugPrint('🗑️ Cleaned up partial message: $_partialResponseTempId');
      } catch (e) {
        debugPrint('⚠️ Could not clean up partial message: $e');
      }
      _partialResponseTempId = null;
    }
    _partialResponseContent = '';
  }

  /// Get effective settings for the current conversation
  /// Merges global settings with chat-level overrides, then model/persona
  /// param presets (Pro): chat sampler → persona custom → model preset → global.
  AppSettings getEffectiveSettings(AppSettings globalSettings) {
    return _withExpressionLabels(
      _effectiveSettingsBase(globalSettings),
      globalSettings,
    );
  }

  /// When the chat's persona has expression sprites (and sprites are on),
  /// lists the expressions the model may use and asks for the hidden
  /// `[EXPRESSION: …]` tag in the system prompt.
  AppSettings _withExpressionLabels(
    AppSettings effective,
    AppSettings globalSettings, {
    String? personaId,
  }) {
    final id = personaId ?? effective.selectedSystemPromptId;
    SystemPrompt? persona;
    if (globalSettings.expressionSpriteMode != 'off' && id != null) {
      for (final p in globalSettings.savedSystemPrompts ?? const []) {
        if (p.id == id) {
          persona = p;
          break;
        }
      }
    }
    final labels = expressionLabelsForSprites(persona?.expressionSprites);
    if (labels.isEmpty) {
      return effective.expressionLabels == null
          ? effective
          : effective.copyWith(expressionLabels: null);
    }
    return effective.copyWith(
      expressionLabels: labels,
      systemPrompt:
          applyExpressionInstructionToSystem(effective.systemPrompt, labels),
    );
  }

  AppSettings _effectiveSettingsBase(AppSettings globalSettings) {
    final chatSettings =
        _currentConversation?.settings ?? const <String, dynamic>{};
    final layered = _withParamPresets(globalSettings, chatSettings);

    if (_currentConversation == null) {
      return _applyCloudRouting(_withTranscriptionContext(layered));
    }

    // If no chat-level overrides, still keep model/persona param overlays.
    if (chatSettings.isEmpty ||
        !chatSettings.keys.any((k) => [
              'model',
              'providerKind',
              'cloudProviderId',
              'systemPrompt',
              'systemPromptId',
              'temperature',
              'maxTokens',
              'topP',
              'topK',
              'minP',
              'repeatPenalty',
              'reasoningEnabled',
              'enableToolUse',
              'enableWebSearch',
              'preferSearxng',
              'enableCodeSandbox',
              'activeMcpServerLabels',
              'activeIntegratedNames'
            ].contains(k))) {
      return _applyCloudRouting(_withTranscriptionContext(layered));
    }

    // Resolve system prompt: prefer systemPromptId lookup, fall back to systemPrompt text
    String resolvedSystemPrompt = layered.systemPrompt;
    String? resolvedSystemPromptId = layered.selectedSystemPromptId;
    int? resolvedPersonaImageGenSeed; // Per-persona seed override for image gen
    String? resolvedPersonaComfyWorkflowPath;
    String? resolvedPersonaComfyWorkflowJson;
    if (chatSettings.containsKey('systemPromptId')) {
      final promptId = chatSettings['systemPromptId']?.toString();
      resolvedSystemPromptId = promptId;
      if (promptId != null && globalSettings.savedSystemPrompts != null) {
        final matches =
            globalSettings.savedSystemPrompts!.where((p) => p.id == promptId);
        if (matches.isNotEmpty) {
          resolvedSystemPrompt = matches.first.content;
          resolvedPersonaImageGenSeed = matches.first.imageGenSeed;
          resolvedPersonaComfyWorkflowPath = matches.first.comfyUiWorkflowPath;
          resolvedPersonaComfyWorkflowJson = matches.first.comfyUiWorkflowJson;
        } else if (chatSettings.containsKey('systemPrompt')) {
          // Saved prompt was deleted; fall back to stored content
          resolvedSystemPrompt =
              chatSettings['systemPrompt']?.toString() ?? resolvedSystemPrompt;
        }
      }
    } else if (chatSettings.containsKey('systemPrompt')) {
      // Custom inline prompt for this chat — not a saved persona.
      resolvedSystemPromptId = null;
      resolvedSystemPrompt =
          chatSettings['systemPrompt']?.toString() ?? resolvedSystemPrompt;
    }

    final personaComfy = _resolvePersonaComfyOverrides(
      layered,
      workflowPath: resolvedPersonaComfyWorkflowPath,
      workflowJson: resolvedPersonaComfyWorkflowJson,
    );

    // Provider routing for this chat (LM Studio / on-device / cloud*).
    final chatProviderKind = chatSettings['providerKind']?.toString();
    final effectiveProviderKind =
        (chatProviderKind != null && chatProviderKind.isNotEmpty)
            ? chatProviderKind
            : layered.activeProviderKind;
    final isChatOnDevice = effectiveProviderKind == 'onDeviceGguf' ||
        effectiveProviderKind == 'onDeviceMlx';
    final chatModel = chatSettings.containsKey('model')
        ? chatSettings['model']?.toString()
        : null;

    // Sampler knobs are already on [layered]. Overlay the rest of the chat.
    return _applyCloudRouting(_withTranscriptionContext(layered.copyWith(
      activeProviderKind: effectiveProviderKind,
      selectedModel: isChatOnDevice
          ? layered.selectedModel
          : (chatModel ?? layered.selectedModel),
      selectedLocalModelId: isChatOnDevice && chatModel != null
          ? chatModel
          : layered.selectedLocalModelId,
      systemPrompt: resolvedSystemPrompt,
      selectedSystemPromptId: resolvedSystemPromptId,
      enableToolUse: chatSettings.containsKey('enableToolUse')
          ? chatSettings['enableToolUse'] as bool? ?? layered.enableToolUse
          : layered.enableToolUse,
      enableWebSearch: chatSettings.containsKey('enableWebSearch')
          ? chatSettings['enableWebSearch'] as bool? ?? layered.enableWebSearch
          : layered.enableWebSearch,
      preferSearxng: chatSettings.containsKey('preferSearxng')
          ? chatSettings['preferSearxng'] as bool? ?? layered.preferSearxng
          : layered.preferSearxng,
      enableCodeSandbox: chatSettings.containsKey('enableCodeSandbox')
          ? chatSettings['enableCodeSandbox'] as bool? ??
              layered.enableCodeSandbox
          : layered.enableCodeSandbox,
      activeMcpServerLabels: chatSettings.containsKey('activeMcpServerLabels')
          ? (chatSettings['activeMcpServerLabels'] as List<dynamic>?)
                  ?.cast<String>() ??
              layered.activeMcpServerLabels
          : layered.activeMcpServerLabels,
      integratedMcps: chatSettings.containsKey('activeIntegratedNames')
          ? layered.integratedMcps?.map((m) {
              final activeNames =
                  (chatSettings['activeIntegratedNames'] as List<dynamic>?)
                          ?.cast<String>() ??
                      [];
              return m.copyWith(enabled: activeNames.contains(m.name));
            }).toList()
          : layered.integratedMcps,
      imageGenSeed: resolvedPersonaImageGenSeed ?? layered.imageGenSeed,
      comfyUiWorkflowPath: personaComfy.path,
      comfyUiWorkflowJson: personaComfy.json,
    )));
  }

  AppSettings _withParamPresets(
    AppSettings global,
    Map<String, dynamic> chatSettings,
  ) {
    final identity = _identitySettingsForPresets(global, chatSettings);
    final routed = _applyCloudRouting(identity);
    final key = ParamPresetKey.fromSettings(
      routed,
      cloudProviderId: _presetCloudProviderId(routed, chatSettings),
    );
    final persona = _personaForParamOverlay(global, chatSettings);
    return ParamPresetResolver.overlay(
      global: global,
      isPremium: SubscriptionService().isPremium,
      modelKey: key,
      persona: persona,
      chatSettings: chatSettings,
    );
  }

  AppSettings _identitySettingsForPresets(
    AppSettings global,
    Map<String, dynamic> chatSettings,
  ) {
    final chatProviderKind = chatSettings['providerKind']?.toString();
    final effectiveProviderKind =
        (chatProviderKind != null && chatProviderKind.isNotEmpty)
            ? chatProviderKind
            : global.activeProviderKind;
    final isChatOnDevice = effectiveProviderKind == 'onDeviceGguf' ||
        effectiveProviderKind == 'onDeviceMlx';
    final chatModel = chatSettings.containsKey('model')
        ? chatSettings['model']?.toString()
        : null;
    return global.copyWith(
      activeProviderKind: effectiveProviderKind,
      selectedModel: isChatOnDevice
          ? global.selectedModel
          : (chatModel ?? global.selectedModel),
      selectedLocalModelId: isChatOnDevice && chatModel != null
          ? chatModel
          : global.selectedLocalModelId,
    );
  }

  String? _presetCloudProviderId(
    AppSettings settings,
    Map<String, dynamic> chatSettings,
  ) {
    if (!ParamPresetKey.usesCloudProviderId(settings.activeProviderKind)) {
      return null;
    }
    final fromChat = chatSettings['cloudProviderId']?.toString().trim();
    if (fromChat != null && fromChat.isNotEmpty) return fromChat;
    return _resolveEffectiveCloudProvider(settings: settings)?.id;
  }

  SystemPrompt? _systemPromptById(AppSettings settings, String? id) {
    if (id == null || id.isEmpty) return null;
    final list = settings.savedSystemPrompts;
    if (list == null) return null;
    for (final p in list) {
      if (p.id == id) return p;
    }
    return null;
  }

  SystemPrompt? _personaForParamOverlay(
    AppSettings global,
    Map<String, dynamic> chatSettings,
  ) {
    if (chatSettings.containsKey('systemPrompt') &&
        !chatSettings.containsKey('systemPromptId')) {
      return null;
    }
    final chatId = chatSettings['systemPromptId']?.toString();
    if (chatId != null && chatId.isNotEmpty) {
      return _systemPromptById(global, chatId);
    }
    return _systemPromptById(global, global.selectedSystemPromptId);
  }

  AppSettings _participantParamSettings(
    AppSettings global,
    GroupChatParticipant participant,
  ) {
    final chat = _currentConversation?.settings ?? const <String, dynamic>{};
    final kind = _resolveParticipantProviderKind(participant, global);
    final key = ParamPresetKey.build(
      providerKind: kind,
      modelId: participant.modelId,
      cloudProviderId: participant.cloudProviderId,
    );
    final persona = _systemPromptById(global, participant.personaId);
    return ParamPresetResolver.overlay(
      global: global,
      isPremium: SubscriptionService().isPremium,
      modelKey: key,
      persona: persona,
      chatSettings: chat,
    );
  }

  /// Resolve persona Comfy overrides over [base].
  /// Path wins over JSON; persona JSON clears a global saved path.
  static ({String? path, String? json}) _resolvePersonaComfyOverrides(
    AppSettings base, {
    String? workflowPath,
    String? workflowJson,
  }) {
    final path = workflowPath?.trim();
    final json = workflowJson?.trim();
    final hasPath = path != null && path.isNotEmpty;
    final hasJson = json != null && json.isNotEmpty;
    if (hasPath) {
      return (path: path, json: base.comfyUiWorkflowJson);
    }
    if (hasJson) {
      return (path: null, json: json);
    }
    return (path: base.comfyUiWorkflowPath, json: base.comfyUiWorkflowJson);
  }

  /// Settings for image generation for [message] in the current conversation.
  ///
  /// Starts from [getEffectiveSettings] (1:1 persona seed/workflow), then for
  /// group chats overlays the speaker participant's persona seed + Comfy
  /// workflow path when present.
  AppSettings settingsForImageGeneration(
    AppSettings globalSettings, {
    ChatMessage? message,
  }) {
    var effective = getEffectiveSettings(globalSettings);

    final isGroup = _currentConversation?.settings['isGroupChat'] == true;
    final participantId = message?.participantId;
    if (!isGroup || participantId == null || participantId.isEmpty) {
      return effective;
    }

    final participants = _getGroupParticipants();
    GroupChatParticipant? participant;
    for (final p in participants) {
      if (p.id == participantId) {
        participant = p;
        break;
      }
    }
    final personaId = participant?.personaId;
    if (personaId == null || personaId.isEmpty) return effective;

    final prompts = globalSettings.savedSystemPrompts;
    if (prompts == null) return effective;
    SystemPrompt? persona;
    for (final p in prompts) {
      if (p.id == personaId) {
        persona = p;
        break;
      }
    }
    if (persona == null) return effective;

    if (persona.imageGenSeed != null) {
      effective = effective.copyWith(imageGenSeed: persona.imageGenSeed);
    }
    final personaComfy = _resolvePersonaComfyOverrides(
      effective,
      workflowPath: persona.comfyUiWorkflowPath,
      workflowJson: persona.comfyUiWorkflowJson,
    );
    final hasPersonaComfy = (persona.comfyUiWorkflowPath != null &&
            persona.comfyUiWorkflowPath!.trim().isNotEmpty) ||
        (persona.comfyUiWorkflowJson != null &&
            persona.comfyUiWorkflowJson!.trim().isNotEmpty);
    if (hasPersonaComfy) {
      effective = effective.copyWith(
        comfyUiWorkflowPath: personaComfy.path,
        comfyUiWorkflowJson: personaComfy.json,
      );
    }
    return effective;
  }

  /// Transcript entries stored on the current conversation (multi-file).
  /// Migrates legacy single-key settings when needed.
  List<Map<String, dynamic>> _readTranscriptionEntries() {
    final settings = _currentConversation?.settings;
    if (settings == null) return const [];
    final list = <Map<String, dynamic>>[];
    final raw = settings['transcriptions'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }
    if (list.isEmpty) {
      final plain = settings['transcriptionPlainText']?.toString();
      if (plain != null && plain.trim().isNotEmpty) {
        list.add({
          'jobId': settings['transcriptionJobId'],
          'title': settings['transcriptionTitle']?.toString() ?? 'Transcript',
          'plainText': plain,
          if (settings['transcriptionSrtText'] != null)
            'srtText': settings['transcriptionSrtText'],
        });
      }
    }
    return list;
  }

  int _transcriptionPlainCharCount() {
    var total = 0;
    for (final e in _readTranscriptionEntries()) {
      total += e['plainText']?.toString().length ?? 0;
    }
    return total;
  }

  int _effectiveContextTokens(AppSettings settings) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      return OnDeviceLLMService.effectiveContextSize(settings);
    }
    return settings.effectiveContextWindow;
  }

  /// Warn when attached transcripts may crowd out chat + reply tokens.
  void _maybeWarnTranscriptionContext(AppSettings settings) {
    final chars = _transcriptionPlainCharCount();
    if (chars == 0) return;
    // ~4 chars/token; leave ~55% of the window for history, system, and output.
    final budgetChars = (_effectiveContextTokens(settings) * 4 * 0.45).round();
    if (chars > budgetChars) {
      _pendingToast = ChatToast.transcriptionContextLarge;
    }
  }

  AppSettings _withTranscriptionContext(AppSettings settings) {
    final entries = _readTranscriptionEntries();
    if (entries.isEmpty) return settings;

    final buffer = StringBuffer();
    if (entries.length == 1) {
      buffer.writeln(
        'The user uploaded an audio file that was transcribed on-device. '
        'Use the transcript below when answering follow-up questions:',
      );
      buffer.writeln();
      buffer.write(entries.first['plainText']?.toString() ?? '');
    } else {
      buffer.writeln(
        'The user has ${entries.length} on-device audio transcriptions in this '
        'chat. Use all of them when answering follow-up questions:',
      );
      for (var i = 0; i < entries.length; i++) {
        final title = entries[i]['title']?.toString().trim().isNotEmpty == true
            ? entries[i]['title'].toString()
            : 'Transcript ${i + 1}';
        buffer.writeln();
        buffer.writeln('--- Transcript ${i + 1}: $title ---');
        buffer.writeln(entries[i]['plainText']?.toString() ?? '');
      }
    }

    return settings.copyWith(
      systemPrompt: '${settings.systemPrompt}\n\n${buffer.toString()}',
    );
  }

  /// Resolve the cloud provider for this chat: per-chat override > global active
  /// > saved provider matching [settings.activeProviderKind].
  /// Paid cloud APIs require Pro; free local types (oMLX, Ollama) always resolve.
  CloudApiProvider? _resolveEffectiveCloudProvider({AppSettings? settings}) {
    final cloudService = CloudApiService();
    final chatCloudProviderId =
        _currentConversation?.settings['cloudProviderId'] as String?;

    // Explicit per-chat cloud provider always wins.
    if (chatCloudProviderId != null) {
      final byChat = cloudService.providers
          .where((p) => p.id == chatCloudProviderId)
          .firstOrNull;
      if (byChat != null) {
        if (byChat.type.isPremium && !SubscriptionService().isPremium) {
          return null;
        }
        return byChat;
      }
    }

    // Local LM Studio / on-device modes must not inherit a stale
    // CloudApiService.activeProvider from a previous OpenAI Compatible session.
    final kind = settings?.activeProviderKind;
    if (kind == 'lmStudio' ||
        kind == 'lmMiniDesktop' ||
        kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return null;
    }

    CloudApiProvider? effective =
        cloudService.isCloudActive ? cloudService.activeProvider : null;

    if (effective == null && settings != null) {
      effective = _resolveCloudProviderByKind(
        settings.activeProviderKind,
        cloudService,
      );
    }

    if (effective == null) return null;
    if (effective.type.isPremium && !SubscriptionService().isPremium) {
      return null;
    }
    return effective;
  }

  CloudApiProvider? _resolveCloudProviderByKind(
    String kind,
    CloudApiService cloud,
  ) {
    if (!SettingsProvider.isCloudProviderKind(kind)) return null;
    switch (kind) {
      case 'ollama':
        return cloud.providers
            .where((p) => p.type == CloudApiType.ollama)
            .firstOrNull;
      case 'omlx':
        return cloud.providers
            .where((p) => p.type == CloudApiType.omlx)
            .firstOrNull;
      case 'jan':
        return cloud.providers
            .where((p) => p.type == CloudApiType.jan)
            .firstOrNull;
      case 'unsloth':
        return cloud.providers
            .where((p) => p.type == CloudApiType.unsloth)
            .firstOrNull;
      case 'cloud':
        if (!SubscriptionService().isPremium) return null;
        return cloud.providers.where((p) => p.type.isPremium).firstOrNull;
      default:
        return null;
    }
  }

  AppSettings _patchSettingsForCloudProvider(
    AppSettings settings,
    CloudApiProvider cloudProvider,
  ) {
    final hasChatModelOverride =
        _currentConversation?.settings.containsKey('model') ?? false;
    final apiKey = cloudProvider.apiKey.trim();
    // Preserve the user's Tool Use toggle when the provider supports tools.
    // Only force-off for providers that cannot accept a tools array.
    final enableToolUse =
        cloudProvider.type.supportsTools ? settings.enableToolUse : false;
    return settings.copyWith(
      activeProviderKind: cloudProvider.type.providerKind,
      serverUrl: cloudProvider.effectiveBaseUrl,
      apiToken: apiKey.isEmpty ? null : apiKey,
      selectedModel: hasChatModelOverride
          ? settings.selectedModel
          : (cloudProvider.selectedModel ?? settings.selectedModel),
      enableToolUse: enableToolUse,
    );
  }

  /// Apply cloud provider routing to effective settings.
  /// Per-chat cloud provider override takes priority over global active provider.
  /// Also used by UI (attach sheet / starters) so selectedModel matches send.
  AppSettings _applyCloudRouting(AppSettings effectiveSettings) {
    // Explicit LM Studio / on-device (chat override or global) must not be
    // rewritten by a stale CloudApiService active provider.
    final chatKind = _currentConversation?.settings['providerKind']?.toString();
    final kind = chatKind ?? effectiveSettings.activeProviderKind;
    if (kind == 'lmStudio' ||
        kind == 'lmMiniDesktop' ||
        kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return effectiveSettings;
    }
    final effectiveCloudProvider =
        _resolveEffectiveCloudProvider(settings: effectiveSettings);
    if (effectiveCloudProvider != null) {
      return _patchSettingsForCloudProvider(
          effectiveSettings, effectiveCloudProvider);
    }
    return effectiveSettings;
  }

  /// Check if chat has any setting overrides
  bool get hasSettingOverrides {
    if (_currentConversation == null) return false;
    final chatSettings = _currentConversation!.settings;
    return chatSettings.keys.any((k) => [
          'model',
          'cloudProviderId',
          'providerKind',
          'systemPrompt',
          'systemPromptId',
          'temperature',
          'maxTokens',
          'topP',
          'topK',
          'minP',
          'repeatPenalty',
          'enableToolUse',
          'enableWebSearch',
          'memoryEnabled',
          'reasoningEnabled',
        ].contains(k));
  }

  /// Persist [selectedSystemPromptId] onto the chat once, if unbound.
  /// The persona greeting shown in an empty 1:1 chat (SillyTavern
  /// `first_mes`). Not saved until the first message is sent.
  ChatMessage? greetingPreview(AppSettings globalSettings) {
    final conv = _currentConversation;
    if (conv == null || _currentMessages.isNotEmpty) return null;
    if (conv.settings['isGroupChat'] == true) return null;
    // A custom inline prompt replaces the persona.
    if (conv.settings.containsKey('systemPrompt')) return null;
    final id = conv.settings['systemPromptId']?.toString() ??
        globalSettings.selectedSystemPromptId;
    SystemPrompt? persona;
    for (final p in globalSettings.savedSystemPrompts ?? const []) {
      if (p.id == id) {
        persona = p;
        break;
      }
    }
    final text = greetingForConversation(persona, conv.id);
    if (text == null) return null;
    return ChatMessage(
      id: 'greeting_${conv.id}',
      content: text,
      role: 'assistant',
      timestamp: conv.createdAt,
    );
  }

  /// Saves the greeting as the first assistant message, so the model sees
  /// it as context, right before the user's first message.
  Future<void> _materializeGreetingIfNeeded(AppSettings globalSettings) async {
    final preview = greetingPreview(globalSettings);
    final conv = _currentConversation;
    if (preview == null || conv == null) return;
    final message = preview.copyWith(
      id: _uid(),
      timestamp: DateTime.now().subtract(const Duration(milliseconds: 1)),
    );
    try {
      await _databaseService.insertMessage(message, conv.id);
      _currentMessages.add(message);
    } catch (e) {
      debugPrint('ChatProvider: saving persona greeting failed: $e');
    }
  }

  Future<void> _ensureConversationPersonaBound(AppSettings settings) async {
    final conv = _currentConversation;
    if (conv == null) return;
    if (conv.settings['isGroupChat'] == true) return;
    if (conv.settings.containsKey('systemPromptId') ||
        conv.settings.containsKey('systemPrompt')) {
      return;
    }
    final id = settings.selectedSystemPromptId;
    if (id == null || id.isEmpty) return;
    final next = Map<String, dynamic>.from(conv.settings);
    next['systemPromptId'] = id;
    await updateChatSettings(next);
  }

  /// Update chat-specific settings
  Future<void> updateChatSettings(Map<String, dynamic> newSettings) async {
    if (_currentConversation == null) return;

    final oldSettings = _currentConversation!.settings;
    final personaChanged =
        oldSettings['systemPromptId'] != newSettings['systemPromptId'] ||
            oldSettings['systemPrompt'] != newSettings['systemPrompt'];

    var updatedConversation = _currentConversation!.copyWith(
      settings: newSettings,
      updatedAt: DateTime.now(),
    );

    // Mid-chat persona / system-prompt change: clear the V1 session so the
    // next request sends the new system (+ memories) as a leading message
    // instead of leaving the old persona bound to previous_response_id.
    if (personaChanged) {
      _sessionWarm = false;
      if (updatedConversation.lastResponseId != null) {
        updatedConversation = updatedConversation.copyWith(
          clearLastResponseId: true,
        );
      }
    }

    await _databaseService.updateConversation(updatedConversation);
    _currentConversation = updatedConversation;

    // Update in conversations list
    final index =
        _conversations.indexWhere((c) => c.id == updatedConversation.id);
    if (index != -1) {
      _conversations[index] = updatedConversation;
    }

    notifyListeners();
  }

  /// The persona record backing [personaId], or the chat's active persona when
  /// [personaId] is omitted. Null when no persona applies or it was deleted.
  SystemPrompt? _memoryPersona(
    AppSettings settings, {
    String? personaId,
  }) {
    final id = personaId ?? settings.selectedSystemPromptId;
    if (id == null || id.isEmpty) return null;
    final prompts = settings.savedSystemPrompts ?? const <SystemPrompt>[];
    for (final p in prompts) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Whether the given persona allows memory inject/extract.
  /// Unknown / missing persona defaults to true (share).
  bool _personaAllowsMemoryShare(
    AppSettings settings, {
    String? personaId,
  }) =>
      _memoryPersona(settings, personaId: personaId)?.shareMemories ?? true;

  /// Category allow-list for a persona (`null` = all categories).
  List<String>? _memoryCategoriesForPersona(
    AppSettings settings, {
    String? personaId,
  }) =>
      _memoryPersona(settings, personaId: personaId)?.sharedMemoryCategories;

  /// Scope newly-learned memories are filed under while this persona is
  /// active. Personas without an explicit choice keep the global pool.
  MemoryScope _memoryWriteScopeFor(
    AppSettings settings, {
    String? personaId,
  }) {
    final persona = _memoryPersona(settings, personaId: personaId);
    if (persona == null) return MemoryScope.global;
    return persona.memoryWriteScope;
  }

  /// Whether the chat currently open allows memory at all.
  bool get _chatMemoryEnabled =>
      _currentConversation?.settings['memoryEnabled'] as bool? ?? true;

  /// Scope for memory tool calls made during the open chat. Group chats have no
  /// single owning persona, so they write to the shared pool.
  MemoryScope _toolMemoryScope(AppSettings settings) =>
      _currentConversation?.settings['isGroupChat'] == true
          ? MemoryScope.global
          : _memoryWriteScopeFor(settings);

  String? _toolMemoryPersonaId(AppSettings settings) =>
      _currentConversation?.settings['isGroupChat'] == true
          ? null
          : settings.selectedSystemPromptId;

  /// Memory writes made by tool calls during the current turn, held until the
  /// final assistant message exists to anchor the undo chip to.
  final List<MemoryEvent> _pendingToolMemoryEvents = [];

  void _recordToolMemoryWrite(MemoryUpsertResult result) {
    _pendingToolMemoryEvents.add(MemoryEvent(
      id: result.id,
      wasUpdate: result.wasUpdate,
      fact: result.fact,
      category: result.category,
      scope: result.scope,
      previousContent: result.previousContent,
    ));
  }

  /// Attach any tool-driven memory writes to the assistant message that caused
  /// them, so they get the same undo affordance as auto-extraction.
  void _flushToolMemoryEvents() {
    if (_pendingToolMemoryEvents.isEmpty) return;
    final events = List<MemoryEvent>.from(_pendingToolMemoryEvents);
    _pendingToolMemoryEvents.clear();
    if (_currentMessages.isEmpty) return;
    final anchor = _currentMessages.lastWhere(
      (m) => m.role == 'assistant' && !m.id.startsWith('temp_'),
      orElse: () => _currentMessages.last,
    );
    _memoryEvents.putIfAbsent(anchor.id, () => []).addAll(events);
  }

  /// Build the memory block(s) for the system prompt of the chat that is open.
  ///
  /// Every send path must go through here. The previous code duplicated this
  /// logic at six call sites and two of them (regenerate, edit-and-regenerate)
  /// silently dropped memory entirely.
  ///
  /// Returns null when nothing should be injected.
  Future<String?> _buildMemoryContextForChat(
    AppSettings settings, {
    String? personaIdOverride,
  }) async {
    if (!_chatMemoryEnabled) return null;

    // Group chats resolve memory per participant in _sendToParticipant, so the
    // shared pass only needs the global pool as a fallback.
    final isGroupChat = _currentConversation?.settings['isGroupChat'] == true;
    final personaId = isGroupChat
        ? null
        : (personaIdOverride ?? settings.selectedSystemPromptId);

    if (!isGroupChat &&
        !_personaAllowsMemoryShare(settings, personaId: personaId)) {
      return null;
    }

    await PersonaMemoryService.instance.load();
    final persona =
        isGroupChat ? null : _memoryPersona(settings, personaId: personaId);
    final context = MemoryService().buildMemoryContext(
      personaId: personaId,
      personaName: persona?.name,
      enforcePersonaScope: PersonaMemoryService.instance.isEnabled,
      allowedCategories: isGroupChat
          ? null
          : _memoryCategoriesForPersona(settings, personaId: personaId),
    );
    return context.isEmpty ? null : context;
  }

  Future<void> _recordPersonaAnalytics({
    required AppSettings settings,
    required String assistantText,
    double? tokensPerSecond,
  }) async {
    final personaId = settings.selectedSystemPromptId;
    if (personaId == null ||
        personaId.isEmpty ||
        personaId == BuiltinPersonaService.defaultPersonaId) {
      return;
    }
    await PersonaAnalyticsService.instance.recordAssistantTurn(
      personaId: personaId,
      assistantText: assistantText,
      tokensPerSecond: tokensPerSecond,
    );
  }

  /// Cached last-assistant previews for home list rows.
  final Map<String, String?> _assistantPreviews = {};

  String? assistantPreviewFor(String conversationId) =>
      _assistantPreviews[conversationId];

  Future<void> refreshAssistantPreviews({Iterable<String>? ids}) async {
    final targets =
        ids?.toList() ?? listedConversations.map((c) => c.id).take(40).toList();
    var changed = false;
    for (final id in targets) {
      try {
        final preview = await _databaseService.getLastAssistantPreview(id);
        if (_assistantPreviews[id] != preview) {
          _assistantPreviews[id] = preview;
          changed = true;
        }
      } catch (_) {}
    }
    if (changed) notifyListeners();
  }

  void setAssistantPreview(String conversationId, String? preview) {
    var cleaned = preview == null
        ? null
        : ChatTitle.displayLabel(ResponseParser.answerOnly(preview));
    if (cleaned != null && cleaned.isEmpty) cleaned = null;
    final value = cleaned == null
        ? null
        : (cleaned.length > 100
            ? '${cleaned.substring(0, 100).trimRight()}…'
            : cleaned);
    if (_assistantPreviews[conversationId] == value) return;
    _assistantPreviews[conversationId] = value;
    notifyListeners();
  }

  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final next = await _databaseService.getAllConversations();
      final listUnchanged = _sameConversationList(_conversations, next);
      _conversations = next;
      await _pruneEmptyDraftConversations();
      // Push the most-recent conversations into the home-screen widget so
      // the "Recent Chats" widget reflects current data.
      unawaited(
          WidgetDataService.updateRecentConversations(listedConversations));
      unawaited(refreshAssistantPreviews());
      if (silent && listUnchanged) {
        return;
      }
    } catch (e) {
      _error = 'Failed to load conversations: $e';
    }

    if (!silent) _isLoading = false;
    notifyListeners();
  }

  bool _sameConversationList(
    List<ChatConversation> a,
    List<ChatConversation> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
      if (a[i].title != b[i].title) return false;
      if (a[i].folderId != b[i].folderId) return false;
      if (a[i].updatedAt.millisecondsSinceEpoch !=
          b[i].updatedAt.millisecondsSinceEpoch) {
        return false;
      }
    }
    return true;
  }

  /// True when a 1:1 chat was opened as a draft and never sent a message.
  ///
  /// Uses an explicit `isDraft` flag — do NOT infer from empty [messageIds],
  /// because many older chats never persisted that list and would vanish
  /// from the home screen.
  static bool isEmptyDraftConversation(ChatConversation conversation) {
    return conversation.settings['isDraft'] == true;
  }

  bool _canDiscardEmptyDraft(ChatConversation conversation) {
    if (!isEmptyDraftConversation(conversation)) return false;
    if (_voiceCallConversationId == conversation.id) return false;
    if (_backgroundGeneratingConversationId == conversation.id) return false;
    if (_isSendingMessage && _sendMessageOriginId == conversation.id) {
      return false;
    }
    return true;
  }

  Future<void> _clearDraftFlagIfNeeded(String conversationId) async {
    ChatConversation? conversation;
    if (_currentConversation?.id == conversationId) {
      conversation = _currentConversation;
    } else {
      for (final c in _conversations) {
        if (c.id == conversationId) {
          conversation = c;
          break;
        }
      }
    }
    if (conversation == null) return;
    if (conversation.settings['isDraft'] != true) return;

    final nextSettings = Map<String, dynamic>.from(conversation.settings)
      ..remove('isDraft');
    final updated = conversation.copyWith(
      settings: nextSettings,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(updated);
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) _conversations[index] = updated;
    if (_currentConversation?.id == conversationId) {
      _currentConversation = updated;
    }
    unawaited(WidgetDataService.updateRecentConversations(listedConversations));
    notifyListeners();
  }

  /// Delete the current chat if the user left without sending anything.
  Future<void> discardEmptyCurrentConversationIfNeeded() async {
    final current = _currentConversation;
    if (current == null) return;
    if (_currentMessages.isNotEmpty) return;
    if (!_canDiscardEmptyDraft(current)) return;
    await deleteConversation(current.id);
  }

  Future<void> _pruneEmptyDraftConversations() async {
    final candidates =
        _conversations.where(_canDiscardEmptyDraft).toList(growable: false);
    if (candidates.isEmpty) return;

    // Keep the open draft so New Chat in split view still works.
    final currentId = _currentConversation?.id;
    for (final conversation in candidates) {
      if (conversation.id == currentId) continue;
      final messages =
          await _databaseService.getMessagesForConversation(conversation.id);
      if (messages.isNotEmpty) continue;
      await _databaseService.deleteConversation(conversation.id);
      _conversations.removeWhere((c) => c.id == conversation.id);
    }
  }

  Future<void>? _createConversationInFlight;

  bool _isReusableEmptyDraft(
    ChatConversation conversation, {
    String? folderId,
  }) {
    if (!_canDiscardEmptyDraft(conversation)) return false;
    if (conversation.isGroupChat) return false;
    if (folderId != null && conversation.folderId != folderId) return false;
    return true;
  }

  Future<void> createNewConversation({
    String? title,
    AppSettings? settings,
    String? folderId,

    /// Bind this chat to a saved persona so list avatars stay correct.
    String? systemPromptId,
  }) async {
    if (_createConversationInFlight != null) {
      await _createConversationInFlight;
      final current = _currentConversation;
      if (current != null &&
          _currentMessages.isEmpty &&
          _isReusableEmptyDraft(current, folderId: folderId)) {
        await _bindDraftPersonaIfNeeded(
          current,
          systemPromptId ?? settings?.selectedSystemPromptId,
        );
        return;
      }
    }

    late final Future<void> future;
    future = _createNewConversationBody(
      title: title,
      settings: settings,
      folderId: folderId,
      systemPromptId: systemPromptId,
    );
    _createConversationInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_createConversationInFlight, future)) {
        _createConversationInFlight = null;
      }
    }
  }

  Future<void> _bindDraftPersonaIfNeeded(
    ChatConversation draft,
    String? systemPromptId,
  ) async {
    if (systemPromptId == null || systemPromptId.isEmpty) return;
    if (draft.settings['systemPromptId'] == systemPromptId) return;
    final nextSettings = Map<String, dynamic>.from(draft.settings)
      ..['systemPromptId'] = systemPromptId;
    final updated = draft.copyWith(
      settings: nextSettings,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(updated);
    final index = _conversations.indexWhere((c) => c.id == draft.id);
    if (index != -1) _conversations[index] = updated;
    if (_currentConversation?.id == draft.id) {
      _currentConversation = updated;
    }
    notifyListeners();
  }

  Future<void> _createNewConversationBody({
    String? title,
    AppSettings? settings,
    String? folderId,
    String? systemPromptId,
  }) async {
    // If a generation is active, let it continue in the background
    if (_isSendingMessage) {
      _backgroundGeneratingConversationId = _currentConversation?.id;
      _isSendingMessage = false;
      _setStreamingStatus(null);
      _streamingProgress = null;
      _currentReasoning = null;
      _isInReasoningMode = false;
    }

    final current = _currentConversation;
    if (current != null &&
        _currentMessages.isEmpty &&
        _isReusableEmptyDraft(current, folderId: folderId)) {
      await _bindDraftPersonaIfNeeded(
        current,
        systemPromptId ?? settings?.selectedSystemPromptId,
      );
      clearManualAskNudge();
      notifyListeners();
      return;
    }

    // Drop previous empty draft before starting another.
    await discardEmptyCurrentConversationIfNeeded();
    clearManualAskNudge();

    var conversationId = _uid();
    final boundPersonaId = systemPromptId ?? settings?.selectedSystemPromptId;
    final draftSettings = <String, dynamic>{
      'isDraft': true,
      if (boundPersonaId != null && boundPersonaId.isNotEmpty)
        'systemPromptId': boundPersonaId,
    };
    var conversation = ChatConversation(
      id: conversationId,
      title: title ?? 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageIds: [],
      settings: draftSettings,
      folderId: folderId,
    );

    try {
      await _databaseService.insertConversation(conversation);
    } catch (e) {
      if (!isSqliteUniqueConstraint(e)) {
        _error = 'Failed to create conversation: $e';
        notifyListeners();
        return;
      }
      conversationId = _uid();
      conversation = conversation.copyWith(id: conversationId);
      try {
        await _databaseService.insertConversation(conversation);
      } catch (e2) {
        _error = 'Failed to create conversation: $e2';
        notifyListeners();
        return;
      }
    }

    _conversations.insert(0, conversation);
    _currentConversation = conversation;
    AnalyticsService().recordConversation();
    _currentMessages = [];
    _sessionWarm = false; // New conversation — no session yet
    notifyListeners();
  }

  Future<void>? _selectConversationInFlight;
  String? _selectConversationInFlightId;

  Future<void> selectConversation(String conversationId) async {
    // Deduplicate concurrent opens (list tap + ChatScreen init).
    if (_selectConversationInFlight != null &&
        _selectConversationInFlightId == conversationId) {
      return _selectConversationInFlight!;
    }
    if (_currentConversation?.id == conversationId && !_isLoading) {
      return;
    }

    late final Future<void> future;
    future = _selectConversationBody(conversationId);
    _selectConversationInFlight = future;
    _selectConversationInFlightId = conversationId;
    try {
      await future;
    } finally {
      if (identical(_selectConversationInFlight, future)) {
        _selectConversationInFlight = null;
        _selectConversationInFlightId = null;
      }
    }
  }

  Future<void> _selectConversationBody(String conversationId) async {
    // Leaving an untouched New Chat should not keep it in the list.
    if (_currentConversation?.id != conversationId) {
      await discardEmptyCurrentConversationIfNeeded();
    }

    // If a generation is active, let it continue in the background
    if (_isSendingMessage) {
      _backgroundGeneratingConversationId = _currentConversation?.id;
      _isSendingMessage = false;
      _setStreamingStatus(null);
      _streamingProgress = null;
      _currentReasoning = null;
      _isInReasoningMode = false;
    }

    // Clear unread badge for this conversation
    _unreadConversationIds.remove(conversationId);
    clearManualAskNudge();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var conversation = conversationById(conversationId);
      if (conversation == null) {
        // List can be empty or stale (startup race, Home sync, deleted).
        await loadConversations(silent: true);
        conversation = conversationById(conversationId);
      }
      if (conversation == null) {
        _currentConversation = null;
        _currentMessages = [];
        _sessionWarm = false;
        debugPrint(
          '⚠️ Conversation $conversationId is no longer available',
        );
        return;
      }
      _currentConversation = conversation;
      _currentMessages =
          await _databaseService.getMessagesForConversation(conversationId);
      // LM Studio keeps multiple response chains. Reuse this chat's stored
      // id so we don't re-inject history; a different chat keeps its own.
      _sessionWarm = _currentConversation!.lastResponseId != null;
    } catch (e) {
      _error = 'Failed to load conversation: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a branch (fork) from a specific message in the current conversation.
  ///
  /// Copies all messages up to and including [messageId], creates a new
  /// conversation, and switches to it. Premium feature.
  Future<String?> branchFromMessage(String messageId) async {
    if (_currentConversation == null) return null;

    final branchingService = BranchingService();
    final newId = await branchingService.createBranch(
      sourceConversationId: _currentConversation!.id,
      branchFromMessageId: messageId,
      sourceSettings: _currentConversation!.settings,
    );
    if (newId == null) return null;

    // Reload conversations and switch to the new branch
    await loadConversations();
    await selectConversation(newId);
    return newId;
  }

  // ── Live Activity helpers ──────────────────────────────────────────────

  /// Push current streaming status to the Live Activity.
  /// Throttles updates to max once per 500ms unless [force] is true.
  void _updateLiveActivity(
      {int? tokenCount,
      double? tokensPerSecond,
      DateTime? firstTokenTime,
      bool force = false}) {
    if (!_liveActivityService.isActive) return;
    if (_liveActivityService.kind == kLiveActivityKindImage) return;

    if (tokenCount != null) _liveActivityTokens = tokenCount;

    // Compute tokens-per-second on the fly when caller provides a start
    // time but no explicit rate. This is what makes the Live Activity feel
    // alive — previously it always showed 0.0 t/s and looked empty.
    double? computedTps = tokensPerSecond;
    if (computedTps == null &&
        firstTokenTime != null &&
        _liveActivityTokens > 0) {
      final elapsedMs =
          DateTime.now().difference(firstTokenTime).inMilliseconds;
      if (elapsedMs > 200) {
        computedTps = _liveActivityTokens / (elapsedMs / 1000.0);
      }
    }

    // Throttle non-forced updates
    if (!force) {
      final now = DateTime.now();
      if (_lastLiveActivityUpdate != null &&
          now.difference(_lastLiveActivityUpdate!).inMilliseconds < 500) {
        return;
      }
      _lastLiveActivityUpdate = now;
    }

    String activityStatus;
    final status = _streamingStatus ?? '';
    if (status.contains('Loading model')) {
      activityStatus = 'loading';
    } else if (status.contains('Processing prompt')) {
      activityStatus = 'processing';
    } else {
      activityStatus = 'generating';
    }

    // Make the lock-screen status text more informative when we have a
    // running token count — the bare "Generating response..." string
    // looked like nothing was happening.
    String statusText = status.isNotEmpty ? status : 'Generating...';
    if (activityStatus == 'generating' && _liveActivityTokens > 0) {
      if ((computedTps ?? 0) > 0) {
        statusText =
            'Generating · $_liveActivityTokens tokens · ${computedTps!.toStringAsFixed(1)} t/s';
      } else {
        statusText = 'Generating · $_liveActivityTokens tokens';
      }
    }

    _liveActivityService.updateActivity(
      status: activityStatus,
      statusText: statusText,
      modelName: _liveActivityModelName ?? 'AI Model',
      tokenCount: _liveActivityTokens,
      tokensPerSecond: computedTps ?? 0.0,
      kind: kLiveActivityKindChat,
    );
  }

  void _endLiveActivity({bool force = false}) {
    _liveActivityService.release(force: force);
  }

  Future<void> sendMessage(String content, AppSettings settings,
      {List<String>? imageUrls,
      List<FileAttachment>? fileAttachments,
      SettingsProvider? settingsProvider,
      BuildContext? uiContext}) async {
    if (_currentConversation == null) return;

    // Voice mode fire-and-forget can overlap turns; stacking sends causes
    // concurrent /models/load → duplicate instances (model:2, model:3).
    if (_isSendingMessage || _isCompacting) {
      debugPrint('ChatProvider: Ignoring send — already generating');
      return;
    }

    if (GroupChatProGate.isLocked(this)) {
      _isSendingMessage = false;
      notifyListeners();
      if (uiContext != null && uiContext.mounted) {
        await GroupChatProGate.showUpgradeDialog(uiContext);
      }
      return;
    }

    _activeSettingsProvider = settingsProvider;
    _activeUiContext = uiContext;

    _isSendingMessage = true;
    _shouldCancelGeneration = false; // Reset cancellation flag
    _reviewEligibleReply = false;
    _sendMessageOriginId = _currentConversation!.id;
    _error = null;
    _thinkingBudgetNotice = false;
    _setStreamingStatus(null);
    _streamingProgress = null;
    _currentReasoning = null;
    _isInReasoningMode = false;
    notifyListeners();

    // First send promotes the draft into a real listed conversation.
    await _clearDraftFlagIfNeeded(_currentConversation!.id);

    // Get effective settings (global + chat-level overrides)
    var effectiveSettings = getEffectiveSettings(settings);

    // Bind the active persona to this conversation so the home list avatar
    // stays tied to this chat (not whatever persona is selected later).
    await _ensureConversationPersonaBound(effectiveSettings);
    effectiveSettings = getEffectiveSettings(settings);

    imageUrls =
        await _shrinkImagesForPhysicalBatch(effectiveSettings, imageUrls);

    // Transcripts are injected into the system prompt on send — warn if they
    // may exceed what the model can keep in context.
    _maybeWarnTranscriptionContext(effectiveSettings);
    if (_pendingToast == ChatToast.transcriptionContextLarge) {
      notifyListeners();
    }

    // Start Live Activity / Android foreground service before any network or
    // on-device stream so the process stays alive when the user leaves the app.
    await _beginGenerationSession(effectiveSettings);

    CloudApiProvider? effectiveCloudProvider =
        _resolveEffectiveCloudProvider(settings: effectiveSettings);

    if (effectiveCloudProvider != null) {
      final hasChatModelOverride =
          _currentConversation!.settings.containsKey('model');
      debugPrint(
          '☁️ Cloud routing active: ${effectiveCloudProvider.type.displayName} → ${effectiveCloudProvider.effectiveBaseUrl}${hasChatModelOverride ? " (per-chat model: ${effectiveSettings.selectedModel})" : ""}');
      effectiveSettings = _patchSettingsForCloudProvider(
          effectiveSettings, effectiveCloudProvider);
    }

    RemoteHostBackends.configureLmStudioClient(
      _lmStudioService,
      effectiveSettings,
    );

    // ── Model-change detection ───────────────────────────────────────────
    // If the user switched models mid-conversation, the old
    // previous_response_id belongs to the previous model. Clear it so we
    // reinject the *full* chat history for the new model (1→2, 2→3, …).
    if (_currentMessages.isNotEmpty) {
      await _invalidateSessionIfModelChanged(effectiveSettings.selectedModel);
    }

    try {
      // Build the message content with file attachments
      String messageContent = content;
      String displayContent = content; // What user sees in chat
      final isOnDeviceProvider =
          effectiveSettings.activeProviderKind == 'onDeviceGguf' ||
              effectiveSettings.activeProviderKind == 'onDeviceMlx';

      // If there are file attachments, add their content to the message for the API
      if (fileAttachments != null && fileAttachments.isNotEmpty) {
        debugPrint(
            'ChatProvider: Processing ${fileAttachments.length} file attachment(s)');

        if (isOnDeviceProvider) {
          // On-device: plain text + hard char budget (4k context). Heavy
          // markdown/emoji scaffolding confuses small local models.
          final budget = OnDeviceAttachments.attachmentCharBudget(
            OnDeviceLLMService.effectiveContextSize(effectiveSettings),
          );
          messageContent = OnDeviceAttachments.withFileText(
            content,
            files: fileAttachments,
            maxChars: budget,
          );
        } else {
          final fileContents = StringBuffer();
          fileContents.writeln('\n\n---\n📎 Attached Files:\n');

          for (final file in fileAttachments) {
            debugPrint(
                'ChatProvider: File "${file.fileName}" - extractedText length: ${file.extractedText?.length ?? 0}');

            fileContents.writeln(
                '**File: ${file.fileName}** (${file.typeDisplayName}, ${file.fileSizeDisplay})');
            if (file.extractedText != null && file.extractedText!.isNotEmpty) {
              fileContents.writeln('```');
              fileContents.writeln(file.extractedText);
              fileContents.writeln('```');
            } else {
              fileContents.writeln('(Unable to extract text content)');
            }
            fileContents.writeln('');
          }
          fileContents.writeln('---');

          messageContent = content + fileContents.toString();
        }
        debugPrint(
            'ChatProvider: Final messageContent length: ${messageContent.length}');
      }

      await _materializeGreetingIfNeeded(settings);

      // Add user message (display content only, not file contents)
      final userMessage = ChatMessage(
        id: _uid(),
        content: displayContent,
        role: 'user',
        timestamp: DateTime.now(),
        imageUrls: imageUrls,
        fileAttachments: fileAttachments,
      );

      try {
        await _databaseService.insertMessage(
            userMessage, _currentConversation!.id);
      } catch (e, st) {
        debugPrint('ChatProvider: insertMessage failed: $e\n$st');
        rethrow;
      }
      _currentMessages.add(userMessage);
      // Touch updatedAt now so the home list (and a relaunch) puts this
      // chat first even if the reply is still streaming.
      _currentConversation = _currentConversation!.copyWith(
        updatedAt: userMessage.timestamp,
      );
      await _databaseService.updateConversation(_currentConversation!);
      _syncConversationInList(_currentConversation!);
      notifyListeners();
      debugPrint('ChatProvider: user message saved; '
          'provider=${effectiveSettings.activeProviderKind}');

      // Build memory context for premium users (per-chat toggle).
      // Honors persona scoping when enabled — single chats use the active
      // system-prompt id (persona). Group chats override this per-participant
      // inside _sendToParticipant below.
      // Memories are merged into the first system prompt only (see normalizer /
      // V1 skipContextInjection); never as a mid-history system message.
      final memoryContext = await _buildMemoryContextForChat(effectiveSettings);

      // Decide which API to use based on chat type and settings
      final isGroupChat = _currentConversation!.settings['isGroupChat'] == true;
      // On-device routing: when the user has selected an on-device provider,
      // bypass the cloud/LM-Studio paths entirely and stream from the local
      // engine (fllama or MLX).
      final providerKind = effectiveSettings.activeProviderKind;
      if (providerKind == 'onDeviceGguf' || providerKind == 'onDeviceMlx') {
        await _sendMessageOnDevice(
          messageContent,
          effectiveSettings,
          memoryContext: memoryContext,
          imageUrls: imageUrls,
        );
      } else if (providerKind == 'appleIntelligence') {
        // Apple Intelligence bridge ships separately; surface a friendly
        // message until its Swift module is bundled.
        final assistant = ChatMessage(
          id: _uid(),
          content: 'Apple Intelligence support requires iOS 26+ and the '
              'Foundation Models Swift bridge, which is not bundled in '
              'this build. Switch to an on-device GGUF model or a cloud '
              'provider to continue chatting.',
          role: 'assistant',
          timestamp: DateTime.now(),
        );
        await _databaseService.insertMessage(
            assistant, _currentConversation!.id);
        _currentMessages.add(assistant);
        notifyListeners();
      } else if (isGroupChat) {
        // Group chat: route to all participants sequentially or in parallel
        await _proSendGroupMessage(messageContent, effectiveSettings, imageUrls,
            userDisplayContent: displayContent, memoryContext: memoryContext);
      } else {
        final readySettings = await _ensureChatBackendReady(effectiveSettings);
        if (readySettings == null) {
          await _databaseService.deleteMessage(userMessage.id);
          _currentMessages.removeWhere((m) => m.id == userMessage.id);
          notifyListeners();
          return;
        }
        effectiveSettings = readySettings;
        // Cloud provider may change if user picked one in the setup dialog.
        effectiveCloudProvider =
            _resolveEffectiveCloudProvider(settings: effectiveSettings);
        await _routeNetworkAssistantReply(
          content: messageContent,
          settings: effectiveSettings,
          imageUrls: imageUrls,
          userDisplayContent: displayContent,
          memoryContext: memoryContext,
        );
      }
    } catch (e) {
      // Only set error if not already set by inner handler (e.g., streaming error event)
      if (_error == null) {
        final errStr = e.toString();
        // Strip 'Exception: ' prefix if present
        final cleanErr =
            errStr.startsWith('Exception: ') ? errStr.substring(11) : errStr;
        _errorDetail = cleanErr;
        if (_setContextOverflowError(cleanErr)) {
          // User-facing overflow message is already set.
        } else if (_setHostInferenceError(cleanErr)) {
          // Host llama.cpp / LM Studio process died.
        } else if (_setSetupGuidanceError(
          cleanErr,
          effectiveSettings,
        )) {
          // Localhost / LMS LAN / missing model.
        } else if (_applyLmsPluginError(cleanErr, effectiveSettings)) {
          // Unknown MCP setup, or Pro Search / Code Sandbox.
        } else {
          _error = cleanErr;
          _errorDetail = null;
        }
      }
    } finally {
      await _stopPartialSaveTimer();
      _endLiveActivity();
      _clearModelLoadingBanner();
      _activeSettingsProvider = null;
      _activeUiContext = null;
    }

    // Track successful chat completion for review prompting.
    // Stop / repetition-loop cancels are not successes.
    if (_error == null) {
      if (!_shouldCancelGeneration) {
        await _reviewService.recordSuccessfulChat();
        // Only when the screen will see this send finish; a reply that lands
        // after a conversation switch would leave a stale flag for a later
        // (possibly cancelled) regenerate to pick up.
        _reviewEligibleReply =
            _currentConversation?.id == _sendMessageOriginId;
      }

      // Update widget stats
      int tokensIn = 0;
      int tokensOut = 0;
      if (_currentMessages.isNotEmpty && _currentMessages.last.stats != null) {
        tokensIn = _currentMessages.last.stats!.inputTokens ?? 0;
        tokensOut = _currentMessages.last.stats!.totalOutputTokens ?? 0;
      }
      WidgetDataService.updateStats(
        messageCountIncrement: 1,
        tokensInIncrement: tokensIn,
        tokensOutIncrement: tokensOut,
      );

      // Attach memory writes the model made via tools to the assistant message
      // that made them, now that it exists.
      _flushToolMemoryEvents();

      // Auto-extract memories after the reply. Queued so it cannot overlap
      // the chat stream or title generation on the same LM Studio model.
      // Stop/cancel must not fire a second inference pass on the same model.
      if (!_shouldCancelGeneration) {
        _proMaybeExtractMemories(effectiveSettings);
      }
    }

    // Only clear _isSendingMessage if user is still on the originating conversation.
    // If they switched away, we already cleared it in selectConversation/createNewConversation.
    if (_currentConversation?.id == _sendMessageOriginId) {
      _isSendingMessage = false;
      _setStreamingStatus(null);
    }
    _backgroundGeneratingConversationId = null;

    // We capture the origin ID so we can pass it before nullifying
    final executedOriginId = _sendMessageOriginId;
    _sendMessageOriginId = null;
    notifyListeners();

    if (_currentConversation?.id == executedOriginId &&
        _currentConversation?.settings['autonomousMode'] == true) {
      _proRunAutonomousCycle(effectiveSettings);
    }
  }

  void _enqueueExclusiveInferenceJob(Future<void> Function() job) {
    _exclusiveInferenceJob = _exclusiveInferenceJob.then((_) async {
      await LMStudioService.waitForStreamsIdle();
      await job();
    }).catchError((Object e) {
      debugPrint('⚠️ Exclusive inference job failed: $e');
    });
  }

  // ── Group Chat ─────────────────────────────────────────────────────────

  /// Get participants for the current group chat conversation.
  List<GroupChatParticipant> _getGroupParticipants() {
    final participantsJson =
        _currentConversation?.settings['participants'] as List?;
    if (participantsJson == null) return [];
    return participantsJson
        .map((p) =>
            GroupChatParticipant.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Update a single participant's data in conversation settings (e.g. lastResponseId).
  Future<void> _updateParticipantInSettings(String participantId,
      GroupChatParticipant Function(GroupChatParticipant) updater) async {
    if (_currentConversation == null) return;
    final participants = _getGroupParticipants();
    final idx = participants.indexWhere((p) => p.id == participantId);
    if (idx == -1) return;
    participants[idx] = updater(participants[idx]);
    final updatedSettings =
        Map<String, dynamic>.from(_currentConversation!.settings);
    updatedSettings['participants'] =
        participants.map((p) => p.toJson()).toList();
    _currentConversation = _currentConversation!.copyWith(
      settings: updatedSettings,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(_currentConversation!);
    // Update in conversations list
    final listIdx =
        _conversations.indexWhere((c) => c.id == _currentConversation!.id);
    if (listIdx != -1) _conversations[listIdx] = _currentConversation!;
  }

  /// Resolve the effective backend for a group-chat participant.
  ///
  /// Stored [GroupChatParticipant.providerKind] wins. If it was never written
  /// (Add persona with no preferred provider, or a chat created before binding
  /// was persisted), infer from the persona / model id — not whoever the user
  /// chatted with last in 1:1.
  String _resolveParticipantProviderKind(
    GroupChatParticipant participant,
    AppSettings globalSettings,
  ) {
    final persona = _systemPromptById(globalSettings, participant.personaId);
    final cloud = _resolveParticipantCloudProvider(participant);
    return GroupParticipantBackend.resolve(
      storedKind: participant.providerKind,
      personaKind: persona?.defaultProviderKind,
      cloudProviderKind: cloud?.type.providerKind,
      modelId: participant.modelId,
      globalKind: globalSettings.activeProviderKind,
      isLocalMlx: GroupParticipantBackend.isLocalMlxId,
      isLocalGguf: GroupParticipantBackend.isLocalGgufId,
      isLmStudioModel: (id) =>
          _activeSettingsProvider?.resolveLmStudioModel(id) != null,
    );
  }

  /// Persist inferred backends onto the group so later turns don't depend on
  /// global Settings. One write for the whole list — parallel replies must not
  /// race [ _updateParticipantInSettings ].
  Future<List<GroupChatParticipant>> _healGroupParticipantKinds(
    List<GroupChatParticipant> participants,
    AppSettings globalSettings,
  ) async {
    var changed = false;
    final next = <GroupChatParticipant>[];
    for (final p in participants) {
      final kind = _resolveParticipantProviderKind(p, globalSettings);
      if (p.providerKind == kind) {
        next.add(p);
      } else {
        changed = true;
        next.add(p.copyWith(providerKind: kind));
      }
    }
    if (!changed || _currentConversation == null) return next;
    final updatedSettings =
        Map<String, dynamic>.from(_currentConversation!.settings);
    updatedSettings['participants'] = next.map((p) => p.toJson()).toList();
    _currentConversation = _currentConversation!.copyWith(
      settings: updatedSettings,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(_currentConversation!);
    final listIdx =
        _conversations.indexWhere((c) => c.id == _currentConversation!.id);
    if (listIdx != -1) _conversations[listIdx] = _currentConversation!;
    return next;
  }

  /// Find the [CloudApiProvider] a participant should use, or `null` when
  /// premium is unavailable or the configured provider has been removed.
  CloudApiProvider? _resolveParticipantCloudProvider(
      GroupChatParticipant participant) {
    final id = participant.cloudProviderId;
    if (id == null) return null;
    final cp = CloudApiService().providers.where((p) => p.id == id).firstOrNull;
    if (cp == null) return null;
    if (cp.type.isPremium && !SubscriptionService().isPremium) return null;
    return cp;
  }

  Future<bool> _prepareLmStudioModel(String modelId) async {
    final sp = _activeSettingsProvider;
    if (sp == null) return true;
    return sp.prepareModelForLmStudioUse(
      modelId,
      uiContext: _activeUiContext,
      reuseLoadedWithoutPrompt: true,
    );
  }

  bool _hasUsableModelSelection(AppSettings settings) {
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      return (settings.selectedLocalModelId ?? '').isNotEmpty;
    }
    if (kind == 'appleIntelligence') return true;
    return (settings.selectedModel ?? '').isNotEmpty;
  }

  /// Ensure provider/model are selected, then auto-load LM Studio models
  /// that are selected but not yet loaded. Returns updated settings, or
  /// `null` if the user cancelled / load failed.
  Future<AppSettings?> _ensureChatBackendReady(AppSettings settings) async {
    var current = settings;
    var sp = _activeSettingsProvider;
    final uiContext = _activeUiContext ?? rootNavigatorKey.currentContext;
    // Voice (and some other callers) historically omitted settingsProvider —
    // recover it from the widget tree so we can see isLoaded and skip reload.
    if (sp == null && uiContext != null && uiContext.mounted) {
      try {
        sp = Provider.of<SettingsProvider>(uiContext, listen: false);
        _activeSettingsProvider = sp;
      } catch (_) {}
    }

    if (!_hasUsableModelSelection(current)) {
      if (sp == null || uiContext == null || !uiContext.mounted) {
        _error = 'Select a provider and model in Settings before chatting.';
        _errorDetail = null;
        notifyListeners();
        return null;
      }
      final ok = await showProviderModelSetupDialog(uiContext, sp);
      if (!ok) return null;
      current = getEffectiveSettings(sp.settings);
      if (!_hasUsableModelSelection(current)) {
        _error = 'No model selected.';
        _errorDetail = null;
        notifyListeners();
        return null;
      }
    }

    if (current.activeProviderKind != 'lmStudio') {
      return current;
    }

    final modelId = current.selectedModel ?? '';
    if (modelId.isEmpty) {
      _error = 'No model selected.';
      _errorDetail = null;
      notifyListeners();
      return null;
    }

    // Chat/voice: if already in memory, reuse it — never POST /models/load
    // (that always creates a new parallel instance like model:2, model:3).
    if (sp != null) {
      final prepared = await sp.prepareModelForLmStudioUse(
        modelId,
        uiContext: uiContext,
        reuseLoadedWithoutPrompt: true,
      );
      if (!prepared) return null;
      current = getEffectiveSettings(sp.settings);
    }

    final model =
        sp?.resolveLmStudioModel(modelId) ?? sp?.findModelById(modelId);
    final loadKey = model?.id ?? modelId;

    // Already in memory → reuse that instance (never POST /models/load).
    if (model != null && model.isLoaded) {
      sp?.preferLoadedParamsForChat(loadKey);
      return current;
    }

    // Not loaded: do NOT block on POST /api/v1/models/load. That endpoint has
    // no progress events, so the UI only showed an indeterminate spinner.
    // V1 chat JIT-loads with model_load.progress SSE (percent in the header).
    // Heal short / stale ids so the chat request uses LM Studio's real key.
    if (sp != null && model != null && loadKey != modelId) {
      if (sp.settings.selectedModel == modelId) {
        sp.updateSelectedModel(loadKey);
      }
      current = getEffectiveSettings(sp.settings);
      if ((current.selectedModel ?? '') == modelId) {
        current = current.copyWith(selectedModel: loadKey);
      }
    } else if (model == null && sp != null) {
      // Catalog miss after refresh — fail early with a clear message rather
      // than hanging on a chat request for an unknown model.
      try {
        await sp.loadAvailableModels();
      } catch (_) {}
      final retry = sp.resolveLmStudioModel(modelId);
      if (retry == null) {
        _error = 'Model "$modelId" is not downloaded in LM Studio. '
            'Pick an installed model in Model Management.';
        _errorDetail = null;
        notifyListeners();
        return null;
      }
      if (retry.id != modelId && sp.settings.selectedModel == modelId) {
        sp.updateSelectedModel(retry.id);
      }
      current = getEffectiveSettings(sp.settings);
      if ((current.selectedModel ?? '') == modelId) {
        current = current.copyWith(selectedModel: retry.id);
      }
    }

    return current;
  }

  bool _omitLoadParamsForModel(String modelId) =>
      _activeSettingsProvider?.shouldOmitLoadParamsInChat(modelId) ?? false;

  /// Show the loading banner immediately when chat will JIT-load the model.
  /// V1 SSE upgrades this to a percent; V0 stays indeterminate until tokens.
  void _beginPendingModelLoadIfNeeded(AppSettings settings) {
    if (settings.activeProviderKind != 'lmStudio') return;
    final id = settings.selectedModel ?? '';
    if (id.isEmpty || _omitLoadParamsForModel(id)) return;
    _streamingPhaseLog.clear();
    _isModelLoading = true;
    _modelLoadingProgress = null;
    _setStreamingStatus('Loading model...');
    notifyListeners();
  }

  void _clearModelLoadingBanner() {
    if (!_isModelLoading &&
        _modelLoadingProgress == null &&
        _streamingProgress == null) {
      return;
    }
    _isModelLoading = false;
    _modelLoadingProgress = null;
    _streamingProgress = null;
    notifyListeners();
  }

  /// Trigger a specific participant to respond in a group chat (manual mode).
  Future<void> triggerParticipantResponse(
      String participantId, AppSettings settings,
      {BuildContext? uiContext}) async {
    if (_currentConversation == null) return;
    if (_currentConversation!.settings['isGroupChat'] != true) return;
    if (GroupChatProGate.isLocked(this)) {
      if (uiContext != null && uiContext.mounted) {
        await GroupChatProGate.showUpgradeDialog(uiContext);
      }
      return;
    }

    await _proTriggerParticipantResponse(participantId, settings);
  }

  /// Create a new group chat conversation with participants.
  Future<void> createGroupChat({
    required List<GroupChatParticipant> participants,
    String turnMode = 'roundRobin',
    bool parallelStreaming = false,
    bool autoLoadUnload = false,
    bool respondToUserOnly = false,
    bool autonomousMode = false,
    String? userName,
    String? scenario,
    String? folderId,
  }) async {
    await discardEmptyCurrentConversationIfNeeded();

    final settings = <String, dynamic>{
      'isGroupChat': true,
      'turnMode': turnMode,
      'parallelStreaming': parallelStreaming,
      'autoLoadUnload': autoLoadUnload,
      'respondToUserOnly': respondToUserOnly,
      'autonomousMode': autonomousMode,
      'memoryEnabled': false, // off by default in group chats — too noisy
      if (userName != null && userName.isNotEmpty) 'userName': userName,
      if (scenario != null && scenario.isNotEmpty) 'scenario': scenario,
      'participants': participants.map((p) => p.toJson()).toList(),
    };

    final conversationId = _uid();
    final conversation = ChatConversation(
      id: conversationId,
      title: 'Group Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageIds: [],
      settings: settings,
      folderId: folderId,
    );

    await _databaseService.insertConversation(conversation);
    _conversations.insert(0, conversation);
    _currentConversation = conversation;
    _currentMessages = [];
    _sessionWarm = false;
    notifyListeners();
  }

  /// Update group chat settings (turn mode, parallel streaming, auto load/unload, participants).
  Future<void> updateGroupChatSettings({
    List<GroupChatParticipant>? participants,
    String? turnMode,
    bool? parallelStreaming,
    bool? autoLoadUnload,
  }) async {
    if (_currentConversation == null) return;
    final settings = Map<String, dynamic>.from(_currentConversation!.settings);
    if (participants != null) {
      settings['participants'] = participants.map((p) => p.toJson()).toList();
    }
    if (turnMode != null) settings['turnMode'] = turnMode;
    if (parallelStreaming != null) {
      settings['parallelStreaming'] = parallelStreaming;
    }
    if (autoLoadUnload != null) settings['autoLoadUnload'] = autoLoadUnload;
    await updateChatSettings(settings);
  }

  void _notifyFromPart() => notifyListeners();

  /// Whether the current conversation is a group chat
  bool get isGroupChat => _currentConversation?.settings['isGroupChat'] == true;

  /// Get current group chat participants (public getter)
  List<GroupChatParticipant> get groupParticipants => _getGroupParticipants();

  /// Get the current turn mode for group chat
  String get groupTurnMode =>
      _currentConversation?.settings['turnMode'] as String? ?? 'roundRobin';

  void _armManualAskNudge(String conversationId) {
    _manualAskNudgeTimer?.cancel();
    _showManualAskNudge = false;
    _manualAskNudgeConversationId = conversationId;
    _manualAskNudgeTimer = Timer(const Duration(seconds: 3), () {
      if (_manualAskNudgeConversationId == conversationId &&
          _currentConversation?.id == conversationId &&
          !_isSendingMessage &&
          _groupReplyInFlight.isEmpty) {
        _showManualAskNudge = true;
        notifyListeners();
      }
    });
  }

  void clearManualAskNudge() {
    final hadNudge = _showManualAskNudge || _manualAskNudgeTimer != null;
    _manualAskNudgeTimer?.cancel();
    _manualAskNudgeTimer = null;
    _showManualAskNudge = false;
    _manualAskNudgeConversationId = null;
    if (hadNudge) notifyListeners();
  }

  /// Creates a temporary assistant message and consumes pending alternatives
  ChatMessage _createTempAssistantMessage(String id, String content,
      {String? participantId}) {
    final msg = ChatMessage(
      id: id,
      content: content,
      role: 'assistant',
      timestamp: DateTime.now(),
      participantId: participantId,
      alternatives: _pendingAlternatives,
      alternativeIndex: _pendingAlternatives?.length,
    );
    _pendingAlternatives = null; // Consume
    return msg;
  }

  /// Local servers share llama.cpp's default physical batch of 512.
  bool _shouldResizeImagesForPhysicalBatch(AppSettings settings) {
    if (!settings.resizeImageForPhysicalBatch) return false;
    switch (settings.activeProviderKind) {
      case 'lmStudio':
      case 'lmMiniDesktop':
      case 'onDeviceGguf':
      case 'onDeviceMlx':
      case 'ollama':
      case 'omlx':
      case 'jan':
      case 'unsloth':
        return true;
      default:
        return false;
    }
  }

  /// Shrink photos that would exceed the physical batch. A full-size
  /// attachment makes vision models emit more tokens than that batch, and
  /// the server process aborts.
  Future<List<String>?> _shrinkImagesForPhysicalBatch(
    AppSettings settings,
    List<String>? imageUrls,
  ) async {
    if (imageUrls == null || imageUrls.isEmpty) return imageUrls;
    if (!_shouldResizeImagesForPhysicalBatch(settings)) return imageUrls;
    _setStreamingStatus('Preparing image…');
    notifyListeners();
    final shrunk = await ChatImageCompress.shrinkUrlsToPhysicalBatch(imageUrls);
    return shrunk ?? imageUrls;
  }

  /// Send message using v1/chat stateful API (no tools)
  Future<void> _sendMessageStateful(
      String content, AppSettings settings, List<String>? imageUrls,
      {String? userDisplayContent, String? memoryContext}) async {
    if (!_usesLmStudioChatApi(settings) ||
        _usesCloudOrLocalOpenAiBackend(settings)) {
      await _sendMessageWithTools(
        content,
        settings,
        imageUrls,
        userDisplayContent: userDisplayContent,
        memoryContext: memoryContext,
      );
      return;
    }
    imageUrls = await _shrinkImagesForPhysicalBatch(settings, imageUrls);
    final originConversationId =
        _currentConversation!.id; // Lock to this conversation
    final titleContent =
        userDisplayContent ?? content; // Use display content for title

    // Empty assistant bubble first so full-width Load / Process status has a
    // home before JIT load and SSE events. History packing skips temp_ ids.
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempAssistantMessage = _createTempAssistantMessage(
      tempMessageId,
      '',
    );
    _currentMessages.add(tempAssistantMessage);
    _partialResponseContent = '';
    _startPartialSaveTimer();
    _beginPendingModelLoadIfNeeded(settings);
    if (_streamingStatus == null || _streamingStatus!.isEmpty) {
      _setStreamingStatus('Sending request...');
    }
    notifyListeners();

    // No server-side session → send the full conversation (all models' turns).
    // Do not gate on `_sessionWarm`: that flag used to skip reinjection after
    // a model switch when response_id was missing, leaving only the prior
    // model's server memory (or nothing).
    dynamic effectiveInput = content;
    var previousResponseId = _currentConversation!.lastResponseId;
    final hasCompact =
        compactSummary != null && compactSummary!.trim().isNotEmpty;
    if (previousResponseId == null &&
        (_currentMessages.length > 1 || hasCompact)) {
      effectiveInput = _injectedHistoryInput(content, settings);
      if (effectiveInput != content) {
        debugPrint('📜 No valid session — injected compact/history as context');
      }
    }
    if (effectiveInput is String) {
      effectiveInput = appendImageGenTurnReminder(
        effectiveInput,
        enabled: settings.imageGenEnabled,
      );
      // Stateful sessions only send the system prompt once.
      if (previousResponseId != null) {
        effectiveInput = appendExpressionTurnReminder(
          effectiveInput as String,
          settings.expressionLabels,
        );
      }
    }

    String aiResponse = '';
    String? responseId;
    String? modelInstanceId;
    Map<String, dynamic>? stats;
    // Client-side timing for fallback stats
    DateTime? firstTokenTime;
    int outputTokenCount = 0;
    final streamStartTime = DateTime.now();

    // Use streaming stateful chat API with progress events.
    // Retry once without reasoning when LM Studio rejects the parameter.
    // Retry once with full history when previous_response_id is gone.
    AppSettings streamSettings = settings;
    final showReasoning = settings.isReasoningEnabled;
    var staleRetried = false;
    var reasoningRetried = false;
    var lowThinkingRetried = false;
    try {
      for (var attempt = 0; attempt < 4; attempt++) {
        try {
          await for (final event in _lmStudioService.streamStatefulChat(
            baseUrl: settings.serverUrl,
            modelId: settings.selectedModel ?? '',
            input: effectiveInput,
            previousResponseId: previousResponseId,
            settings: streamSettings,
            imageUrls: imageUrls,
            apiToken: settings.apiToken,
            memoryContext: memoryContext,
            omitLoadParams:
                _omitLoadParamsForModel(settings.selectedModel ?? ''),
          )) {
            // Check for cancellation
            if (_shouldCancelGeneration) {
              debugPrint('🛑 Generation cancelled by user');
              break;
            }

            // Handle auth errors
            if (event['type'] == 'error') {
              final err = event['error'];
              final msg = ReasoningSupportService.extractMessage(err) ??
                  'Unknown error';
              if (!staleRetried &&
                  LMStudioService.isStalePreviousResponseId(event)) {
                staleRetried = true;
                await _dropStalePreviousResponseId();
                previousResponseId = null;
                effectiveInput = _injectedHistoryInput(content, settings);
                _setStreamingStatus(
                    'Session expired — resending with full history...');
                notifyListeners();
                throw _StalePreviousResponseRetry();
              }
              final isReasoningError =
                  ReasoningSupportService.isReasoningConfigError(err) ||
                      (err is Map && err['reasoning_config_error'] == true);
              if (!reasoningRetried && isReasoningError) {
                reasoningRetried = true;
                streamSettings = await _prepareReasoningConfigRetry(
                  streamSettings,
                  err,
                );
                throw _ReasoningConfigRetry();
              }
              final mcpType = event['error_type'] as String?;
              if (_applyLmsPluginError(
                msg,
                streamSettings,
                errorType: mcpType,
              )) {
                notifyListeners();
                throw Exception(msg);
              }
              throw Exception(msg);
            }

            final eventType = event['type'] as String?;
            if (eventType == null) {
              // Malformed event without type — skip it
              debugPrint('⚠️ Skipping event without type: $event');
              continue;
            }

            switch (eventType) {
              case 'chat.start':
                _setStreamingStatus('Starting chat...');
                modelInstanceId = event['model_instance_id'] as String?;
                notifyListeners();
                break;

              case 'model_load.start':
                _setStreamingStatus('Loading model...');
                _streamingProgress = 0.0;
                _isModelLoading = true;
                _modelLoadingProgress = 0.0;
                _updateLiveActivity(force: true);
                notifyListeners();
                break;

              case 'model_load.progress':
                final progress = (event['progress'] as num?)?.toDouble();
                _streamingProgress = progress;
                _modelLoadingProgress = progress;
                _setStreamingStatus(progress != null
                    ? 'Loading model... ${(progress * 100).toStringAsFixed(0)}%'
                    : 'Loading model...');
                _updateLiveActivity();
                notifyListeners();
                break;

              case 'model_load.end':
                final loadTime = event['load_time_seconds'] as num?;
                _setStreamingStatus(loadTime != null
                    ? 'Model loaded in ${loadTime.toStringAsFixed(1)}s'
                    : 'Model loaded');
                _streamingProgress = 1.0;
                _isModelLoading = false;
                _modelLoadingProgress = null;
                _updateLiveActivity(force: true);
                notifyListeners();
                break;

              case 'prompt_processing.start':
                if (_isModelLoading) _clearModelLoadingBanner();
                _setStreamingStatus('Processing prompt...');
                _streamingProgress = 0.0;
                _updateLiveActivity(force: true);
                notifyListeners();
                break;

              case 'prompt_processing.progress':
                _setStreamingStatus('Processing prompt...');
                _streamingProgress = (event['progress'] as num?)?.toDouble();
                _updateLiveActivity();
                notifyListeners();
                break;

              case 'prompt_processing.end':
                _setStreamingStatus('Generating response...');
                _streamingProgress = null;
                _updateLiveActivity(force: true);
                notifyListeners();
                break;

              case 'reasoning.start':
                _isInReasoningMode = true;
                _currentReasoning = '';
                _streamStartAt = DateTime.now();
                if (showReasoning) {
                  _setStreamingStatus('Thinking...');
                  notifyListeners();
                }
                break;

              case 'reasoning.delta':
                _currentReasoning = (_currentReasoning ?? '') +
                    (event['content'] as String? ?? '');
                if (!showReasoning) break;
                // Update temp message so the collapsible thinking section shows live
                if (_currentConversation?.id == originConversationId &&
                    _currentMessages.isNotEmpty &&
                    _currentMessages.last.id == tempMessageId) {
                  final thinkingDisplay = '<think>$_currentReasoning</think>';
                  _currentMessages.last =
                      _currentMessages.last.copyWith(content: thinkingDisplay);
                }
                notifyListeners();
                break;

              case 'reasoning.end':
                _isInReasoningMode = false;
                _thinkingEndAt = DateTime.now();
                if (!showReasoning) break;
                _setStreamingStatus('Writing response...');
                notifyListeners();
                break;

              case 'tool_call.start':
                final tool = event['tool'] as String?;
                final providerInfo =
                    event['provider_info'] as Map<String, dynamic>?;
                final providerType = providerInfo?['type'] as String?;
                final serverLabel = providerInfo?['server_label'] as String?;
                final pluginId = providerInfo?['plugin_id'] as String?;

                if (tool == 'web_search') {
                  _setStreamingStatus('🔍 Searching the web...');
                } else if (providerType == 'ephemeral_mcp') {
                  _setStreamingStatus('🔧 ${serverLabel ?? 'MCP'}: $tool');
                } else if (providerType == 'plugin') {
                  _setStreamingStatus('🔌 ${pluginId ?? 'Plugin'}: $tool');
                } else {
                  _setStreamingStatus('🔧 Calling tool: $tool');
                }
                notifyListeners();
                break;

              case 'tool_call.arguments':
                // Arguments being passed to the tool (e.g., search query)
                final args = event['arguments'] as Map<String, dynamic>?;
                final tool = event['tool'] as String?;
                if (args != null && args['query'] != null) {
                  _setStreamingStatus('🔍 Searching: "${args['query']}"');
                } else if (args != null) {
                  _setStreamingStatus('🔧 Running $tool...');
                }
                notifyListeners();
                break;

              case 'tool_call.success':
                final tool = event['tool'] as String?;
                final args = event['arguments'] as Map<String, dynamic>?;
                final query = args?['query']?.toString();
                if (tool == 'web_search' || tool == 'read_url') {
                  ProSearchResultLogger.logToolOutput(
                    tool: tool!,
                    output: event['output'],
                    query: query ?? args?['url']?.toString(),
                  );
                }
                _setStreamingStatus('✓ $tool completed');
                if (tool != null) AnalyticsService().recordToolUse(tool);
                notifyListeners();
                break;

              case 'tool_call.failure':
                final reason = event['reason'] as String?;
                final metadata = event['metadata'] as Map<String, dynamic>?;
                final errorType = metadata?['type'] as String?;
                if (errorType == 'invalid_name') {
                  _setStreamingStatus(
                      '⚠️ Tool not found: ${metadata?['tool_name']}');
                } else if (errorType == 'invalid_arguments') {
                  _setStreamingStatus('⚠️ Invalid arguments for tool');
                } else {
                  _setStreamingStatus('⚠️ Tool error: ${reason ?? 'Unknown'}');
                }
                notifyListeners();
                break;

              case 'message.start':
                _setStreamingStatus('Writing response...');
                notifyListeners();
                break;

              case 'message.delta':
                final delta = event['content'] as String? ?? '';
                aiResponse += delta;
                _partialResponseContent = aiResponse; // Track for partial saves
                // Track first token time and approximate token count
                firstTokenTime ??= DateTime.now();
                if (delta.isNotEmpty) outputTokenCount++;
                _updateLiveActivity(
                    tokenCount: outputTokenCount,
                    firstTokenTime: firstTokenTime);

                // Build display content with thinking tags if we have reasoning
                final displayContent = _formatAssistantWithReasoning(
                  aiResponse,
                  reasoning: _currentReasoning,
                  showReasoning: showReasoning,
                );

                // Only update UI if we're still on the originating conversation
                if (_currentConversation?.id == originConversationId &&
                    _currentMessages.isNotEmpty &&
                    _currentMessages.last.id == tempMessageId) {
                  _currentMessages.last =
                      _currentMessages.last.copyWith(content: displayContent);
                  notifyListeners();
                }
                break;

              case 'message.end':
                _setStreamingStatus('Complete');
                notifyListeners();
                break;

              case 'error':
                final errorData = event['error'] as Map<String, dynamic>?;
                final errorMsg =
                    errorData?['message'] as String? ?? 'Unknown error';
                final errorType = errorData?['type'] as String? ?? '';
                debugPrint('❌ V1 error event: $errorMsg');
                if (_setContextOverflowError(errorData ?? errorMsg)) {
                  _errorDetail = errorMsg;
                } else if (_setHostInferenceError(errorData ?? errorMsg)) {
                  // Host llama.cpp / LM Studio process died.
                } else if (LmsMcpError.shouldWaitForChatEnd(
                  errorMsg,
                  errorType: errorType,
                )) {
                  _error = LmsMcpError.userMessage(
                    errorMsg,
                    errorType: errorType,
                    lmStudio: streamSettings.activeProviderKind == 'lmStudio',
                  );
                  _errorDetail = LmsMcpError.isUnrecognizedPlugin(
                    errorMsg,
                    errorType: errorType,
                  )
                      ? errorMsg
                      : null;
                } else if (_setContextOverflowError(errorMsg)) {
                  // User-facing overflow message is already set.
                } else if (_setHostInferenceError(errorMsg)) {
                  // Host llama.cpp / LM Studio process died.
                } else if (_setSetupGuidanceError(
                  errorData ?? errorMsg,
                  streamSettings,
                )) {
                  // Localhost / LMS LAN / missing model.
                } else {
                  // Strip any URLs from error messages for safety
                  _error = errorMsg.replaceAll(
                      RegExp(r"https?://[^\s']+"), '[server]');
                  _errorDetail = null;
                }
                notifyListeners();
                break;

              case 'chat.end':
                // Final result with response_id and stats
                responseId = event['response_id'] as String?;
                modelInstanceId = event['model_instance_id'] as String?;
                stats = event['usage'] as Map<String, dynamic>? ??
                    event['stats'] as Map<String, dynamic>?;

                // Extract final content from output if aiResponse is still empty
                if (aiResponse.isEmpty) {
                  final output = event['output'] as List?;
                  if (output != null) {
                    for (var item in output) {
                      if (item is Map &&
                          item['type'] == 'message' &&
                          item['content'] != null) {
                        aiResponse += item['content'].toString();
                      }
                    }
                  }
                }
                final lowThinking = _lowThinkingRetrySettings(
                  settings: streamSettings,
                  alreadyRetried: lowThinkingRetried,
                  stats: stats,
                  answerEmpty: aiResponse.trim().isEmpty,
                  hadReasoning: (_currentReasoning ?? '').trim().isNotEmpty,
                );
                if (lowThinking != null) {
                  lowThinkingRetried = true;
                  streamSettings = lowThinking;
                  throw _LowThinkingRetry();
                }
                break;
            }
          }
          break; // stream completed successfully
        } on _ReasoningConfigRetry {
          if (attempt >= 3) rethrow;
          aiResponse = '';
          responseId = null;
          modelInstanceId = null;
          stats = null;
          _currentReasoning = null;
          _isInReasoningMode = false;
          firstTokenTime = null;
          outputTokenCount = 0;
          continue;
        } on _StalePreviousResponseRetry {
          if (attempt >= 3) rethrow;
          aiResponse = '';
          responseId = null;
          modelInstanceId = null;
          stats = null;
          _currentReasoning = null;
          _isInReasoningMode = false;
          firstTokenTime = null;
          outputTokenCount = 0;
          continue;
        } on _LowThinkingRetry {
          if (attempt >= 3) rethrow;
          aiResponse = '';
          responseId = null;
          modelInstanceId = null;
          stats = null;
          _currentReasoning = null;
          _isInReasoningMode = false;
          firstTokenTime = null;
          outputTokenCount = 0;
          continue;
        }
      }
    } catch (e) {
      // Clean up temp message on any streaming error to avoid ghost messages
      if (_currentConversation?.id == originConversationId &&
          _currentMessages.isNotEmpty &&
          _currentMessages.last.id == tempMessageId) {
        _currentMessages.removeLast();
      }
      rethrow;
    }

    // Remove temp message (only if still on the same conversation)
    if (_currentConversation?.id == originConversationId &&
        _currentMessages.isNotEmpty &&
        _currentMessages.last.id == tempMessageId) {
      _currentMessages.removeLast();
    }

    // If user switched conversations mid-stream, save response to the
    // original conversation in DB but don't touch _currentMessages (which
    // now belongs to a different conversation).
    if (_currentConversation?.id != originConversationId) {
      debugPrint(
          '⚠️ Conversation switched during generation — saving response to original conversation $originConversationId');
      if (aiResponse.isNotEmpty) {
        final assembled = _assistantContentWithImagePrompt(
          message: aiResponse,
          reasoning: _currentReasoning,
          showReasoning: showReasoning,
        );
        final orphanMessage = ChatMessage(
          id: _uid(),
          content: assembled.content,
          role: 'assistant',
          timestamp: DateTime.now(),
          responseId: responseId,
          stats: stats != null ? MessageStats.fromJson(stats) : null,
          imagePrompt: assembled.imagePrompt,
          expression: assembled.expression,
        );
        await _databaseService.insertMessage(
            orphanMessage, originConversationId);
        if (assembled.imagePrompt != null &&
            assembled.imagePrompt!.isNotEmpty &&
            settings.imageGenAutoGenerate &&
            settings.isImageGenReady) {
          _autoGenerateImage(orphanMessage, settings);
        }
        // Update the original conversation's response_id in DB
        if (responseId != null) {
          final origIdx =
              _conversations.indexWhere((c) => c.id == originConversationId);
          if (origIdx != -1) {
            final updated = _conversations[origIdx].copyWith(
                lastResponseId: responseId, updatedAt: DateTime.now());
            await _databaseService.updateConversation(updated);
            _conversations[origIdx] = updated;
          }
        }
      }
      // Mark as unread so the user sees the response arrived
      _unreadConversationIds.add(originConversationId);
      _backgroundGeneratingConversationId = null;
      notifyListeners();
      return; // Don't touch current UI state
    }

    if (aiResponse.trim().isEmpty && !_shouldCancelGeneration) {
      _thinkingBudgetNotice = false;
      if (_error == null) {
        _error = OutputTokenLimitError.userMessage;
      }
      if ((_currentReasoning ?? '').trim().isEmpty) {
        _stopGenerationUi();
        notifyListeners();
        return;
      }
    }

    // Prepend thinking content when reasoning is enabled for this chat.
    final assembled = _assistantContentWithImagePrompt(
      message: aiResponse,
      reasoning: _currentReasoning,
      showReasoning: showReasoning,
    );
    var finalContent = assembled.content;
    final extractedImagePrompt = assembled.imagePrompt;

    // ── Log exact AI response ────────────────────────────────────────
    debugPrint('📝 ═══════════════ AI RESPONSE (stateful) ═══════════════');
    debugPrint(finalContent);
    debugPrint('📝 ═══════════════ END AI RESPONSE ═══════════════════════');

    if (settings.imageGenEnabled) {
      debugPrint(
          '🎨 [IMG] imageGenEnabled: true, serverUrl: ${settings.imageGenServerUrl}');
      debugPrint('🎨 [IMG] autoGenerate: ${settings.imageGenAutoGenerate}');
      debugPrint(
          '🎨 [IMG] extractedImagePrompt: ${extractedImagePrompt ?? "NULL - model did not include [IMG_PROMPT: ...] tag"}');
      if (extractedImagePrompt == null) {
        // Log the tail of the response to help debug why the tag was missing
        final tail = aiResponse;
        debugPrint(tail);
      }
    }

    // ── Log exact AI response ────────────────────────────────────────────
    debugPrint('📝 ═══════════════ AI RESPONSE (tools) ═══════════════');
    debugPrint(finalContent);
    debugPrint('📝 ═══════════════ END AI RESPONSE ═══════════════════════');

    // Create final assistant message with response_id and stats
    // If server didn't return stats, build fallback from client-side timing
    if (stats == null && firstTokenTime != null && outputTokenCount > 0) {
      final ttft = firstTokenTime.difference(streamStartTime);
      final generationDuration = DateTime.now().difference(firstTokenTime);
      final generationSeconds = generationDuration.inMilliseconds / 1000.0;
      final tps =
          generationSeconds > 0 ? outputTokenCount / generationSeconds : 0.0;
      stats = {
        'total_output_tokens': outputTokenCount,
        'time_to_first_token_seconds': ttft.inMilliseconds / 1000.0,
        'tokens_per_second': tps,
        'generation_time': generationSeconds,
      };
    }
    // Prefer the app's selected model id for switch detection; fall back to
    // LM Studio's instance id when selection is missing.
    final trackedModel = settings.selectedModel ?? modelInstanceId;
    final assistantMessage = ChatMessage(
      id: _uid(),
      content: finalContent,
      role: 'assistant',
      timestamp: DateTime.now(),
      model: trackedModel,
      responseId: responseId,
      stats: stats != null ? MessageStats.fromJson(stats) : null,
      imagePrompt: extractedImagePrompt,
      expression: assembled.expression,
      alternatives: tempAssistantMessage.alternatives,
      alternativeIndex: tempAssistantMessage.alternativeIndex,
    );

    await _databaseService.insertMessage(
        assistantMessage, originConversationId);
    if (_currentConversation?.id == originConversationId) {
      _currentMessages.add(assistantMessage);
    }

    // Record analytics
    final responseMs = _streamStartAt != null
        ? DateTime.now().difference(_streamStartAt!).inMilliseconds.toDouble()
        : null;
    AnalyticsService().recordMessage(
      modelId: trackedModel ?? 'unknown',
      promptTokens: stats?['input_tokens'] as int? ?? 0,
      completionTokens: stats?['total_output_tokens'] as int? ?? 0,
      responseTimeMs: responseMs,
    );
    unawaited(_recordPersonaAnalytics(
      settings: settings,
      assistantText: finalContent,
      tokensPerSecond: (stats?['tokens_per_second'] as num?)?.toDouble() ??
          assistantMessage.stats?.tokensPerSecond,
    ));

    // Store thinking duration if we had reasoning
    if (showReasoning &&
        _streamStartAt != null &&
        _thinkingEndAt != null &&
        _currentReasoning != null &&
        _currentReasoning!.isNotEmpty) {
      _thinkingDurationsMs[assistantMessage.id] =
          _thinkingEndAt!.difference(_streamStartAt!).inMilliseconds;
    }

    // Update conversation with latest response_id for continuation
    if (_currentConversation?.id == originConversationId) {
      _currentConversation = _currentConversation!.copyWith(
        lastResponseId: responseId,
        updatedAt: DateTime.now(),
        settings:
            _withLastUsedModel(_currentConversation!.settings, trackedModel),
      );
      await _databaseService.updateConversation(_currentConversation!);
      _syncConversationInList(_currentConversation!);
      // Only warm when LM Studio gave us a continuable session id.
      _sessionWarm = responseId != null;
    } else {
      // Conversation was switched — update DB directly for the original
      if (responseId != null) {
        final origIdx =
            _conversations.indexWhere((c) => c.id == originConversationId);
        if (origIdx != -1) {
          final updated = _conversations[origIdx].copyWith(
            lastResponseId: responseId,
            updatedAt: DateTime.now(),
            settings: _withLastUsedModel(
                _conversations[origIdx].settings, assistantMessage.model),
          );
          await _databaseService.updateConversation(updated);
          _syncConversationInList(updated);
        }
      }
      // Mark as unread so the user sees the response arrived
      _unreadConversationIds.add(originConversationId);
      _backgroundGeneratingConversationId = null;
      notifyListeners();
      return; // Don't touch UI — user is in a different conversation
    }

    // Update title if still default / greeting provisional (AI + fallback).
    // Not limited to length == 2: short openers defer until a later user turn.
    if (_currentMessages.length >= 2) {
      await _autoTitleIfNeeded(
        conversationId: _currentConversation!.id,
        titleContent: titleContent,
        settings: settings,
      );
    }

    // Clear streaming status and timing
    _setStreamingStatus(null);
    _streamingProgress = null;
    _currentReasoning = null;
    _streamStartAt = null;
    _thinkingEndAt = null;

    // Auto-generate image if enabled and prompt was extracted
    if (extractedImagePrompt != null &&
        extractedImagePrompt.isNotEmpty &&
        settings.imageGenAutoGenerate &&
        settings.isImageGenReady) {
      debugPrint(
          '🎨 [IMG] ✅ Auto-generating image with prompt: $extractedImagePrompt');
      _autoGenerateImage(assistantMessage, settings);
    } else if (settings.imageGenAutoGenerate && settings.imageGenEnabled) {
      debugPrint(
          '🎨 [IMG] ⚠️ Auto-generate ON but no image prompt extracted from response');
    }
  }

  // Extract assistant/reasoning text from LM Studio chat.end output items.
  // Handles both plain-string and structured content payloads.
  Map<String, String> _extractTextFromChatEndOutput(
    List<dynamic> outputItems, {
    bool includeReasoning = true,
  }) {
    final messageSegments = <String>[];
    final reasoningSegments = <String>[];

    for (final rawItem in outputItems) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final type = item['type']?.toString().toLowerCase();

      // Skip tool/function payloads; we only want assistant/reasoning text.
      final isToolPayload = type != null &&
          (type.startsWith('tool') ||
              type.contains('function_call') ||
              type.contains('mcp'));
      if (isToolPayload) continue;

      final isReasoning = type?.contains('reason') ?? false;
      if (isReasoning && !includeReasoning) continue;

      final targetSegments = isReasoning ? reasoningSegments : messageSegments;

      final before = targetSegments.length;
      _collectTextSegments(item['content'], targetSegments);
      if (targetSegments.length == before) {
        // Fallback for alternate output schemas.
        _collectTextSegments(item['text'], targetSegments);
        _collectTextSegments(item['delta'], targetSegments);
        _collectTextSegments(item['message'], targetSegments);
      }
    }

    return {
      'message': _joinUniqueSegments(messageSegments),
      'reasoning': _joinUniqueSegments(reasoningSegments),
    };
  }

  String _formatAssistantWithReasoning(
    String message, {
    String? reasoning,
    required bool showReasoning,
  }) {
    if (!showReasoning || reasoning == null || reasoning.isEmpty) {
      return message;
    }
    return '<think>$reasoning</think>\n$message';
  }

  ({String content, String? imagePrompt, String? expression})
      _assistantContentWithImagePrompt({
    required String message,
    String? reasoning,
    required bool showReasoning,
  }) {
    final fromMessage = extractExpressionTag(message);
    final fromReasoning = extractExpressionTag(reasoning ?? '');
    final img = extractImagePromptFromAssistant(
      message: fromMessage.cleanContent,
      reasoning: fromReasoning.cleanContent,
    );
    return (
      content: _formatAssistantWithReasoning(
        img.cleanContent,
        reasoning: extractImagePrompt(fromReasoning.cleanContent).cleanContent,
        showReasoning: showReasoning,
      ),
      imagePrompt: img.imagePrompt,
      expression: fromMessage.expression ?? fromReasoning.expression,
    );
  }

  /// Whether to show the thinking accordion while streaming / in saved bubbles.
  ///
  /// LM Studio's reasoning toggle controls both the API param and the UI.
  /// oMLX always emits thinking via `reasoning_content` regardless of that
  /// setting, so we always surface it for oMLX responses.
  bool _shouldShowReasoningInUi(
    AppSettings settings, {
    CloudApiProvider? cloudProvider,
  }) {
    if (settings.isReasoningEnabled) return true;
    if (cloudProvider?.type.isLocalOpenAiCompatible == true) return true;
    if (SettingsProvider.isCloudProviderKind(settings.activeProviderKind)) {
      final active = CloudApiService().activeProvider;
      if (active?.type.isLocalOpenAiCompatible == true) return true;
    }
    return false;
  }

  void _collectTextSegments(dynamic node, List<String> sink) {
    if (node == null) return;

    if (node is String) {
      final text = node.trim();
      if (text.isNotEmpty) sink.add(text);
      return;
    }

    if (node is List) {
      for (final part in node) {
        _collectTextSegments(part, sink);
      }
      return;
    }

    if (node is Map) {
      final map = Map<String, dynamic>.from(node);
      _collectTextSegments(map['text'], sink);
      _collectTextSegments(map['content'], sink);
      _collectTextSegments(map['delta'], sink);
      _collectTextSegments(map['output_text'], sink);
      _collectTextSegments(map['value'], sink);
      _collectTextSegments(map['message'], sink);
      _collectTextSegments(map['parts'], sink);
      _collectTextSegments(map['items'], sink);
    }
  }

  String _joinUniqueSegments(List<String> segments) {
    if (segments.isEmpty) return '';
    final seen = <String>{};
    final ordered = <String>[];
    for (final segment in segments) {
      if (seen.add(segment)) {
        ordered.add(segment);
      }
    }
    return ordered.join('\n\n').trim();
  }

  /// Send message using v1/chat/completions with tools
  Future<void> _sendMessageWithTools(
      String content, AppSettings settings, List<String>? imageUrls,
      {String? userDisplayContent, String? memoryContext}) async {
    imageUrls = await _shrinkImagesForPhysicalBatch(settings, imageUrls);
    final originConversationId =
        _currentConversation!.id; // Lock to this conversation
    final earlyTempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final earlyTemp = _createTempAssistantMessage(earlyTempId, '');
    _currentMessages.add(earlyTemp);
    if (!SettingsProvider.isCloudProviderKind(settings.activeProviderKind) &&
        _resolveEffectiveCloudProvider(settings: settings) == null) {
      _beginPendingModelLoadIfNeeded(settings);
    }
    if (_streamingStatus == null || _streamingStatus!.isEmpty) {
      _setStreamingStatus('Sending request...');
    }
    notifyListeners();
    int maxToolLoops =
        10; // Default: allow up to 10 tool calls before requiring final answer
    final hasSearxngParam = settings.searxngUrl?.isNotEmpty == true;
    if (settings.unlimitedToolCalls && !_proExemptFromToolLoopCap(settings)) {
      maxToolLoops =
          1000; // Effectively unlimited for Integrated & Ephemeral MCPs
    }
    int loopCount = 0;
    bool abortedByToolError = false;
    String? toolAbortSummary;
    String? toolAbortDetail;
    Map<String, int> toolCallCounts =
        {}; // Track how many times each tool is called
    final titleContent =
        userDisplayContent ?? content; // Use display content for title
    AppSettings streamSettings = settings;

    // Check if this is being routed to a cloud provider (per-chat > global > kind).
    CloudApiProvider? effectiveCloudProvider =
        _resolveEffectiveCloudProvider(settings: settings);
    final isCloudRouted = effectiveCloudProvider != null ||
        SettingsProvider.isCloudProviderKind(settings.activeProviderKind);
    final modelAllowsTools = _modelSupportsTools(settings);
    final toolsEnabled = settings.enableToolUse && modelAllowsTools;

    // Build messages for API
    List<Map<String, dynamic>> messages = [];

    final isProSearch =
        _proIsProSearchActive(settings, toolsEnabled: toolsEnabled);

    // SearXNG mode: non-premium user (or premium user who explicitly prefers SearXNG)
    // with local SearXNG URL needs V0 for client-side web_search/read_url execution.
    final isSearxngSearch = toolsEnabled &&
        !isProSearch &&
        settings.enableWebSearch &&
        hasSearxngParam &&
        !settings.useMcpToolsOnly;

    final hasMcpIntegrations = toolsEnabled &&
        !isCloudRouted &&
        !isSearxngSearch &&
        (settings.activeMcpServers.isNotEmpty ||
            settings.activeIntegratedMcps.isNotEmpty);

    // Add system prompt if present.
    //
    // We always inject the current local date/time into the system prompt
    // because the V1 stateful endpoint does not accept the OpenAI-style
    // `tools` array, so `get_current_time` is effectively unreachable on
    // that path. Injecting the timestamp gives the model temporal context
    // for free, on every API route (V0, V1, MCP, Cloud).
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final tzName = now.timeZoneName;
    final dateTimeLine = 'Current date: $dateStr, Time: $timeStr ($tzName)';

    if (settings.systemPrompt.isNotEmpty) {
      String sysPrompt = settings.systemPrompt;
      sysPrompt += '\n\n$dateTimeLine';
      // Append image-generation instruction when the feature is enabled
      sysPrompt = applyImageGenInstructionToSystem(
        sysPrompt,
        enabled: settings.imageGenEnabled,
      );
      messages.add({
        'role': 'system',
        'content': sysPrompt,
      });
    } else if (settings.imageGenEnabled) {
      // Even without a user system prompt, inject image gen instruction
      final sysPrompt = applyImageGenInstructionToSystem(
        dateTimeLine,
        enabled: true,
      );
      messages.add({
        'role': 'system',
        'content': sysPrompt,
      });
    } else {
      // No custom system prompt and no image gen — still inject date/time so
      // the model can answer "what time/date is it?" without a tool call.
      messages.add({
        'role': 'system',
        'content': dateTimeLine,
      });
    }

    // Conversation history (except the current user message we just added).
    // Compact summary + later turns, then roll / cut-middle to 90% of loaded
    // context when previous_response_id is not carrying the session.
    // Skip the empty streaming bubble so packing still treats the last real
    // turn as the user message.
    final packedHistory = _packedHistoryMessages(
      _priorMessagesForPacking(),
      settings,
      extraTokens: ContextFit.estimateTokens(content),
    );

    final shrunkHistoryImages = <String, List<String>>{};
    if (_shouldResizeImagesForPhysicalBatch(settings)) {
      for (final msg in packedHistory) {
        final urls = msg.imageUrls;
        if (urls == null || urls.isEmpty) continue;
        final shrunk = await ChatImageCompress.shrinkUrlsToPhysicalBatch(urls);
        if (shrunk != null) shrunkHistoryImages[msg.id] = shrunk;
      }
    }

    for (final msg in packedHistory) {
      if (msg.role == 'user') {
        if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
          final urls = shrunkHistoryImages[msg.id] ?? msg.imageUrls!;
          // Vision message
          messages.add({
            'role': 'user',
            'content': [
              {'type': 'text', 'text': msg.content},
              ...urls.map((url) => {
                    'type': 'image_url',
                    'image_url': {'url': url},
                  }),
            ],
          });
        } else {
          messages.add({'role': 'user', 'content': msg.content});
        }
      } else if (msg.role == 'assistant') {
        // Strip thinking / Gemma channel traces — they bloat context and
        // Gemma docs say prior thoughts must not be re-fed.
        messages.add({
          'role': 'assistant',
          'content': ResponseParser.answerOnly(msg.content),
        });
      }
    }

    // Add the CURRENT user message with the full content (including file attachments)
    final userApiContent = appendImageGenTurnReminder(
      content,
      enabled: settings.imageGenEnabled,
    );
    if (imageUrls != null && imageUrls.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userApiContent},
          ...imageUrls.map((url) => {
                'type': 'image_url',
                'image_url': {'url': url},
              }),
        ],
      });
    } else {
      messages.add({'role': 'user', 'content': userApiContent});
    }

    // Log active MCP servers (they will be handled via the v1 API integrations)
    final activeMcpServers = settings.activeMcpServers;
    if (activeMcpServers.isNotEmpty) {
      debugPrint(
          '🔌 Active MCP servers (${activeMcpServers.length}): ${activeMcpServers.map((s) => s.label).join(", ")}');
    }

    // Get available tools - only if NOT using MCP tools only mode
    // When useMcpToolsOnly is true, we don't send local tool definitions,
    // allowing LM Studio's MCP servers to provide tools instead
    debugPrint(
        '🔧 useMcpToolsOnly: ${settings.useMcpToolsOnly}, enableWebSearch: ${settings.enableWebSearch}');
    List<Map<String, dynamic>>? tools;
    // Client-side MCP registry (Ollama / backends without server-side MCP).
    Map<String, McpToolRef> clientMcpRegistry = {};
    final cloudType = effectiveCloudProvider?.type ??
        CloudApiType.forProviderKind(settings.activeProviderKind);
    final isNativeOllama = cloudType == CloudApiType.ollama ||
        settings.activeProviderKind == 'ollama';
    final providerAllowsTools =
        !isCloudRouted || cloudType == null || cloudType.supportsTools;
    if ((!settings.useMcpToolsOnly || isNativeOllama) &&
        providerAllowsTools &&
        toolsEnabled) {
      // When Pro Search MCP handles search server-side (LM Studio V1 only),
      // suppress local web_search/read_url tools. On Ollama / cloud routes,
      // Pro Search uses the client-side tool loop (PremiumToolDelegate).
      final proSearchUsesMcp = _proProSearchUsesMcp(
          isProSearch: isProSearch, isCloudRouted: isCloudRouted);
      final isCodeSandbox = _proIsCodeSandboxActive(settings);
      final codeSandboxUsesMcp =
          _proCodeSandboxUsesMcp(settings, isCloudRouted: isCloudRouted);
      final effectiveWebSearch =
          (isProSearch && proSearchUsesMcp) ? false : settings.enableWebSearch;
      // Client-side run_code when sandbox is on but V1 MCP is not (Ollama/cloud).
      tools = ToolService.getAvailableTools(
        enableWebSearch: effectiveWebSearch,
        enableCodeSandbox: isCodeSandbox && !codeSandboxUsesMcp,
      );

      // Remove built-in tools that overlap with active integrated MCPs
      // (server-side MCP takes priority over client-side implementation)
      final activeIntegratedNames =
          settings.activeIntegratedMcps.map((m) => m.name).toSet();
      if (activeIntegratedNames.isNotEmpty && hasMcpIntegrations) {
        final before = tools.length;
        tools.removeWhere((t) {
          final name = (t['function'] as Map?)?['name'] as String?;
          return name != null && activeIntegratedNames.contains(name);
        });
        if (tools.length < before) {
          debugPrint(
              '🔌 Suppressed ${before - tools.length} built-in tool(s) in favor of integrated MCPs: ${activeIntegratedNames.join(", ")}');
        }
      }

      // When Pro Search MCP is active on LM Studio, suppress web_search/read_url
      // from the local tools list (they're handled by the Pro Search MCP).
      if (proSearchUsesMcp) {
        tools.removeWhere((t) {
          final name = (t['function'] as Map?)?['name'] as String?;
          return name == 'web_search' || name == 'read_url';
        });
        debugPrint(
            '🔍 Pro Search MCP active: suppressed local web_search/read_url tools');
      }
      if (codeSandboxUsesMcp) {
        tools.removeWhere((t) {
          final name = (t['function'] as Map?)?['name'] as String?;
          return name == 'run_code';
        });
        debugPrint(
            '🧪 Code Sandbox MCP active: suppressed local run_code tool');
      }

      // Ollama (and useMcpToolsOnly on Ollama): discover ephemeral MCP tools
      // client-side — Ollama has no server-side integrations array.
      if (isNativeOllama &&
          settings.enableToolUse &&
          settings.activeMcpServers.isNotEmpty) {
        try {
          final catalog = await McpHttpClient.instance
              .collectTools(settings.activeMcpServers);
          if (catalog.isNotEmpty) {
            clientMcpRegistry = catalog.registry;
            if (settings.useMcpToolsOnly) {
              tools = List<Map<String, dynamic>>.from(catalog.tools);
            } else {
              tools = [...tools, ...catalog.tools];
            }
            debugPrint(
                '🔌 Ollama client MCP: added ${catalog.tools.length} tool(s)');
          }
        } catch (e) {
          debugPrint('⚠️ Ollama client MCP discovery failed: $e');
        }
      }
    } else if (isCloudRouted && cloudType != null && !cloudType.supportsTools) {
      debugPrint(
          '🔧 Tools disabled for ${cloudType.displayName} (provider does not support tool calls)');
    } else if (!settings.enableToolUse) {
      debugPrint('🔧 Tools disabled — Tool Use is off');
    } else if (!modelAllowsTools) {
      debugPrint(
          '🔧 Tools disabled — selected model does not support tool calling');
    }
    debugPrint(
        '🔧 Sending tools: ${tools != null ? tools.length : "none (MCP mode)"}');

    // When the model returns empty after a tool call, we retry without tools
    // but must stay on V0 so the messages array (with tool results) is used.
    bool forceV0 = false;
    // Track whether we already tried rewriting tool messages as plain context
    bool triedPlainRewrite = false;
    // After plain rewrite, switch from V0 to V1 for the response
    bool useV1Fallback = false;
    // Auto-retry once on empty response before showing error to user
    bool retriedEmptyResponse = false;
    // This send already got chat.start. A later model_not_found is LM Studio
    // still tearing down that reply, not a missing model.
    var modelAcceptedThisSend = false;
    var retriedTransientModelMiss = false;
    // High thinking filled max output — one retry at low effort.
    var retriedLowThinking = false;
    // Backend rejected the tools array — retry once on the same provider.
    var retriedWithoutTools = false;

    // Tool calling loop
    while (loopCount < maxToolLoops) {
      loopCount++;
      debugPrint('🔄 Tool loop iteration $loopCount of $maxToolLoops');

      // Qwen (and similar) templates allow only one leading system message.
      // Coalesce before every request so memory / rewrite paths can't break it.
      final normalized = ChatMessageNormalizer.coalesceSystemMessages(messages);
      messages
        ..clear()
        ..addAll(normalized);

      try {
        _setStreamingStatus('Sending request...');
        _updateLiveActivity(force: true);
        notifyListeners();

        // Reuse the empty assistant bubble on the first loop so full-width
        // Load / Process status can show before the first token.
        final tempMessageId = loopCount == 1
            ? earlyTempId
            : 'temp_${DateTime.now().millisecondsSinceEpoch}';
        ChatMessage? tempMessage = loopCount == 1 ? earlyTemp : null;
        String accumulatedContent = '';
        String accumulatedReasoning = '';
        bool shouldStopRetrying = false;
        bool receivedToolCall = false; // Track if we received a local tool call
        bool receivedMcpToolCall = false; // Track if MCP handled a tool call
        bool mcpConnectionFailed =
            false; // Track if MCP connection error was non-fatal
        String? mcpFailureUserMessage; // Friendly banner when MCP fails
        String? mcpFailureDetail;
        Map<String, dynamic>? chatEndStats;
        String? chatEndResponseId;
        List<dynamic>? chatEndOutput;
        // Client-side timing for fallback stats
        DateTime? firstTokenTime;
        int outputTokenCount = 0;
        final streamStartTime = DateTime.now();
        final streamChunkLog = <String>[];
        _partialResponseContent = '';
        _currentReasoning = null;
        _isInReasoningMode = false;
        final showReasoning = _shouldShowReasoningInUi(
          settings,
          cloudProvider: effectiveCloudProvider,
        );
        // Don't restart the partial save timer if we're continuing a tool loop
        // with content already accumulated — just keep the existing timer.
        if (loopCount == 1) {
          _startPartialSaveTimer();
        }

        // Clean up any temp messages left over from previous tool loop iterations
        // (e.g., when the model streamed content + tool_call in the same response)
        // We track whether cleanup is needed but defer actual removal until new
        // content starts streaming, so the old message stays visible longer.
        final needsTempCleanup = loopCount > 1;

        // Choose API based on what tools are active:
        // - V1 API: stateful (uses previous_response_id to avoid resending full
        //   context). Supports MCP integrations via 'integrations' key, but does
        //   NOT support OpenAI-compatible 'tools'/'tool_choice'.
        // - V0 API: stateless (sends full message history each time). Supports
        //   OpenAI 'tools'/'tool_choice' for local function calling.
        //
        // Strategy:
        //   1. Cloud providers → always V0 (OpenAI-compatible only).
        //   2. Pro Search (premium + local LM Studio) → V1 with ephemeral MCP
        //      (stateful chats + server-side tool loop).
        //   3. MCP integrations active → V1 (they need it).
        //   4. Local LM Studio with user-facing tools (web_search, read_url)
        //      → V0 (non-premium users with local SearXNG).
        //   5. Local LM Studio with ONLY background/memory tools → V1 stateful.
        //   6. No tools at all → V1 stateful.
        final hasLocalTools = tools != null && tools.isNotEmpty;

        // SearXNG mode: non-premium user (or premium user who explicitly prefers SearXNG)
        // with local SearXNG URL needs V0 for client-side web_search/read_url execution.
        // When Pro Search is active, SearXNG is NEVER used (Pro Search overrides).
        // When active, SearXNG V0 takes priority over MCP integrations.
        // (Determined globally above)

        // (Determined globally above)

        // Check if any *user-facing* tools require V0.
        // Memory/time tools don't need V0 — they're handled by background
        // extraction. web_search/read_url are handled by Pro Search MCP
        // (ephemeral MCP on V1) for premium users.
        // For SearXNG users (non-premium), web_search/read_url need V0.
        // RULE: Local LM Studio chat uses V1 unless SearXNG is active.
        final backgroundOnlyTools = {
          'save_memory',
          'update_memory',
          'delete_memory',
          'get_current_time',
          if (!isSearxngSearch) 'web_search',
          if (!isSearxngSearch) 'read_url',
        };
        final hasUserFacingTools = hasLocalTools &&
            tools.any((t) {
              final name = (t['function'] as Map?)?['name'] as String?;
              return name != null && !backgroundOnlyTools.contains(name);
            });

        // Pro hosted tools are attached via _ProToolsRouting (official build only).
        final proSearchIntegrations = await _proBuildEphemeralIntegrations(
          settings: settings,
          isProSearch: isProSearch,
          isCloudRouted: isCloudRouted,
          onAuthFailed: (message) {
            _setStreamingStatus(message);
            notifyListeners();
          },
        );

        AppSettings loopStreamSettings = streamSettings;
        var staleRetried = false;
        var reasoningRetried = false;

        for (var reasoningAttempt = 0;
            reasoningAttempt < 4;
            reasoningAttempt++) {
          final Stream<Map<String, dynamic>> streamMethod;
          if (isCloudRouted) {
            // Cloud / oMLX / Ollama — provider-specific endpoint.
            final cp = effectiveCloudProvider ??
                _resolveEffectiveCloudProvider(settings: settings);
            if (cp == null) {
              throw Exception(
                  'No ${settings.activeProviderKind} provider configured. '
                  'Open Settings and save your server URL.');
            }
            final cloudSettings = _patchSettingsForCloudProvider(settings, cp);
            if (reasoningAttempt == 0 && cp.type == CloudApiType.unsloth) {
              await _activeSettingsProvider?.ensureUnslothLoadContext(
                cloudSettings,
                onLoading: () {
                  _isModelLoading = true;
                  _modelLoadingProgress = null;
                  _setStreamingStatus('Loading model...');
                  notifyListeners();
                },
              );
            }
            if (cp.type.usesNativeChatApi) {
              debugPrint('🦙 Using native Ollama /api/chat');
              streamMethod = OllamaService.instance.streamChat(
                baseUrl: cloudSettings.serverUrl,
                messages: messages,
                settings: cloudSettings,
                tools: hasLocalTools ? tools : null,
                apiToken: cloudSettings.apiToken,
                memoryContext: memoryContext,
              );
            } else {
              debugPrint('☁️ Using cloud API (${cp.type.displayName})');
              streamMethod = _lmStudioService.streamChatCompletion(
                baseUrl: cloudSettings.serverUrl,
                formattedMessages: messages,
                settings: cloudSettings,
                tools: hasLocalTools ? tools : null,
                apiToken: cloudSettings.apiToken,
                cloudProviderType: cp.type,
                extraHeaders: cp.type.extraHeaders.isNotEmpty
                    ? cp.type.extraHeaders
                    : null,
                memoryContext: memoryContext,
              );
            }
          } else if (!_usesLmStudioChatApi(settings)) {
            throw Exception(
                'No ${settings.activeProviderKind} provider configured. '
                'Open Settings and save your server URL.');
          } else if (proSearchIntegrations != null) {
            // V1 API — Pro Search via ephemeral MCP (server handles tool loop)
            // This gives us stateful chats + server-side search execution.
            final proSearchRespId = _currentConversation!.lastResponseId;
            debugPrint(
                '🔍 Using V1 API (Pro Search MCP + ${hasMcpIntegrations ? "user MCP integrations" : "no other MCPs"}, respId=${proSearchRespId != null ? "yes" : "null"})');
            streamMethod = _lmStudioService.streamChatCompletionV1(
              baseUrl: settings.serverUrl,
              formattedMessages: messages,
              settings: loopStreamSettings,
              apiToken: settings.apiToken,
              previousResponseId: proSearchRespId,
              skipContextInjection: _sessionWarm && proSearchRespId != null,
              memoryContext: memoryContext,
              extraIntegrations: proSearchIntegrations,
              omitLoadParams:
                  _omitLoadParamsForModel(settings.selectedModel ?? ''),
            );
          } else if (hasMcpIntegrations) {
            // V1 API — MCP integrations handle tool calls server-side
            final mcpRespId = _currentConversation!.lastResponseId;
            debugPrint(
                '🔌 Using V1 API (MCP integrations active, respId=${mcpRespId != null ? "yes" : "null"})');
            streamMethod = _lmStudioService.streamChatCompletionV1(
              baseUrl: settings.serverUrl,
              formattedMessages: messages,
              settings: loopStreamSettings,
              tools: tools,
              apiToken: settings.apiToken,
              previousResponseId: mcpRespId,
              skipContextInjection: _sessionWarm && mcpRespId != null,
              memoryContext: memoryContext,
              omitLoadParams:
                  _omitLoadParamsForModel(settings.selectedModel ?? ''),
            );
          } else if (useV1Fallback) {
            // V1 API — fallback after V0 failed to produce response with
            // search results. Messages have been rewritten as plain
            // system+user (no tool_calls/tool roles). Use fresh session.
            debugPrint(
                '🔄 Using V1 API (fallback — V0 failed after search results)');
            streamMethod = _lmStudioService.streamChatCompletionV1(
              baseUrl: settings.serverUrl,
              formattedMessages: messages,
              settings: loopStreamSettings,
              apiToken: settings.apiToken,
              previousResponseId: null,
              skipContextInjection: false,
              memoryContext: memoryContext,
              omitLoadParams:
                  _omitLoadParamsForModel(settings.selectedModel ?? ''),
            );
          } else if (hasUserFacingTools || forceV0) {
            // V0 API — user-facing tools (web_search, read_url) need
            // OpenAI-compatible function calling format.
            // Also used when retrying after empty tool response (forceV0)
            // to keep the messages array with tool results intact.
            if (forceV0) {
              debugPrint(
                  '🔧 Using V0 API (forced — retrying with tool results in messages, no tools)');
            } else {
              debugPrint(
                  '🔧 Using V0 API (user-facing tools: ${tools!.map((t) => (t['function'] as Map?)?['name']).join(", ")})');
            }
            streamMethod = _lmStudioService.streamChatCompletion(
              baseUrl: settings.serverUrl,
              formattedMessages: messages,
              settings: settings,
              tools: hasLocalTools ? tools : null,
              apiToken: settings.apiToken,
              memoryContext: memoryContext,
            );
          } else {
            // V1 stateful — no user-facing tools needed (memory tools
            // are handled by background extraction). This saves tokens by
            // leveraging previous_response_id instead of resending history.
            final statefulRespId = _currentConversation!.lastResponseId;
            debugPrint(
                '📡 Using V1 API (stateful${hasLocalTools ? ", background-only tools skipped" : ""}, respId=${statefulRespId != null ? "yes" : "null"})');
            streamMethod = _lmStudioService.streamChatCompletionV1(
              baseUrl: settings.serverUrl,
              formattedMessages: messages,
              settings: loopStreamSettings,
              apiToken: settings.apiToken,
              previousResponseId: statefulRespId,
              skipContextInjection: _sessionWarm && statefulRespId != null,
              memoryContext: memoryContext,
              omitLoadParams:
                  _omitLoadParamsForModel(settings.selectedModel ?? ''),
            );
          }

          // Call chat completions API with streaming
          try {
            await for (final chunk in streamMethod) {
              streamChunkLog.add(
                chunk['type']?.toString() ??
                    (chunk.containsKey('error')
                        ? 'error:${chunk['error_type'] ?? 'unknown'}'
                        : chunk.keys.join('+')),
              );
              // Check for cancellation
              if (_shouldCancelGeneration) {
                debugPrint('🛑 Tool generation cancelled by user');
                break;
              }

              // Handle errors from LM Studio (e.g., context overflow)
              if (chunk.containsKey('error')) {
                final rawError = chunk['error'];
                final errorMsg = rawError is String
                    ? rawError
                    : ReasoningSupportService.extractMessage(rawError) ??
                        rawError.toString();
                final errorType = chunk['error_type'] as String?;
                debugPrint('❌ LM Studio error: $errorMsg (type: $errorType)');
                debugPrint('❌ LM Studio error exact: ${jsonEncode(chunk)}');

                if (!staleRetried &&
                    LMStudioService.isStalePreviousResponseId(chunk)) {
                  staleRetried = true;
                  await _dropStalePreviousResponseId();
                  _currentMessages.removeWhere((m) => m.id == tempMessageId);
                  tempMessage = null;
                  accumulatedContent = '';
                  accumulatedReasoning = '';
                  _currentReasoning = null;
                  _isInReasoningMode = false;
                  _setStreamingStatus(
                      'Session expired — resending with full history...');
                  notifyListeners();
                  throw _StalePreviousResponseRetry();
                }

                if (!reasoningRetried &&
                    !isCloudRouted &&
                    (chunk['reasoning_config_error'] == true ||
                        ReasoningSupportService.isReasoningConfigError(
                            rawError))) {
                  reasoningRetried = true;
                  loopStreamSettings = await _prepareReasoningConfigRetry(
                    loopStreamSettings,
                    rawError ?? chunk,
                  );
                  streamSettings = loopStreamSettings;
                  _currentMessages.removeWhere((m) => m.id == tempMessageId);
                  tempMessage = null;
                  accumulatedContent = '';
                  accumulatedReasoning = '';
                  _currentReasoning = null;
                  _isInReasoningMode = false;
                  notifyListeners();
                  throw _ReasoningConfigRetry();
                }

                if (_setStreamClosedAfterStartError(
                        chunk, loopStreamSettings) ||
                    _setStreamClosedAfterStartError(
                        errorMsg, loopStreamSettings)) {
                  _currentMessages.removeWhere((m) => m.id == tempMessageId);
                  _stopGenerationUi();
                  notifyListeners();
                  return;
                }

                if (_setContextOverflowError(chunk) ||
                    _setContextOverflowError(errorMsg) ||
                    _setContextOverflowError(rawError) ||
                    _setHostInferenceError(chunk) ||
                    _setHostInferenceError(errorMsg) ||
                    _setHostInferenceError(rawError)) {
                  _currentMessages.removeWhere((m) => m.id == tempMessageId);
                  _stopGenerationUi();
                  notifyListeners();
                  return;
                }

                // For MCP / plugin errors, don't abort immediately — LM Studio
                // docs say "chat.end" is still sent after errors with whatever was
                // generated. The model may have reasoning we can show.
                if (LmsMcpError.shouldWaitForChatEnd(
                  errorMsg,
                  errorType: errorType,
                )) {
                  debugPrint(
                      '⚠️ MCP connection error — continuing to wait for chat.end');
                  mcpConnectionFailed = true;
                  mcpFailureUserMessage = LmsMcpError.userMessage(
                    errorMsg,
                    errorType: errorType,
                    lmStudio:
                        loopStreamSettings.activeProviderKind == 'lmStudio',
                  );
                  mcpFailureDetail = LmsMcpError.isUnrecognizedPlugin(
                    errorMsg,
                    errorType: errorType,
                  )
                      ? errorMsg
                      : null;
                  _setStreamingStatus(
                      LmsMcpError.streamingStatus(mcpFailureUserMessage));
                  notifyListeners();
                  continue; // Don't return — let chat.end deliver any generated content
                }

                if (_isModelNotFoundChunk(errorType, errorMsg, chunk) &&
                    modelAcceptedThisSend) {
                  _currentMessages.removeWhere((m) => m.id == tempMessageId);
                  if (!retriedTransientModelMiss && !_shouldCancelGeneration) {
                    retriedTransientModelMiss = true;
                    _setStreamingStatus('Reply dropped — trying again…');
                    notifyListeners();
                    await Future.delayed(const Duration(milliseconds: 1200));
                    if (_shouldCancelGeneration) {
                      _stopGenerationUi();
                      notifyListeners();
                      return;
                    }
                    throw _TransientModelRetry();
                  }
                  _stopGenerationUi();
                  _error = ModelNotFoundError.interruptedReplyMessage;
                  _errorDetail = errorMsg;
                  notifyListeners();
                  return;
                }

                if (!retriedWithoutTools &&
                    tools != null &&
                    tools.isNotEmpty &&
                    _isToolsUnsupportedError(errorMsg)) {
                  retriedWithoutTools = true;
                  tools = null;
                  _currentMessages.removeWhere((m) => m.id == tempMessageId);
                  tempMessage = null;
                  accumulatedContent = '';
                  accumulatedReasoning = '';
                  _currentReasoning = null;
                  _isInReasoningMode = false;
                  _setStreamingStatus('Retrying without tools...');
                  notifyListeners();
                  throw _RetryWithoutTools();
                }

                // Clean up temp message
                _currentMessages.removeWhere((m) => m.id == tempMessageId);
                _stopGenerationUi();

                // Parse and show user-friendly error message
                if (ChatMessageNormalizer.isSystemMessageOrderError(errorMsg)) {
                  _error =
                      'This model rejected the message layout (system message must be first). '
                      'Try starting a new chat, or disable Pro Search / tools for this turn.';
                  _errorDetail = errorMsg;
                  if (_currentConversation != null) {
                    final cleared = _currentConversation!.copyWith(
                      clearLastResponseId: true,
                    );
                    _currentConversation = cleared;
                    await _databaseService.updateConversation(cleared);
                  }
                  _sessionWarm = false;
                } else if (errorMsg.contains('context') &&
                    errorMsg.contains('overflow')) {
                  _error =
                      "The file content is too large for this model's context window. Try using a model with larger context or uploading a smaller file.";
                } else if (_setContextOverflowError(errorMsg)) {
                  // message set
                } else if (_setHostInferenceError(errorMsg)) {
                  // Host llama.cpp / LM Studio process died.
                } else if (_setSetupGuidanceError(
                  errorMsg,
                  loopStreamSettings,
                )) {
                  // Localhost / LMS LAN / missing model.
                } else if (_applyLmsPluginError(
                  errorMsg,
                  loopStreamSettings,
                  errorType: errorType,
                )) {
                  // Unknown MCP setup, or Pro Search / Code Sandbox.
                } else {
                  // Strip any URLs from error messages for safety
                  _error = errorMsg.replaceAll(
                      RegExp(r"https?://[^\s']+"), '[server]');
                  _errorDetail =
                      null; // No need for detail if we're showing raw error
                }
                notifyListeners();
                return; // Exit the method — never keep looping on hard API errors
              }

              // Handle reasoning chunks (thinking from reasoning models)
              if (chunk.containsKey('reasoning') && showReasoning) {
                final reasoning = chunk['reasoning'] as String;
                accumulatedReasoning += reasoning;
                _currentReasoning = accumulatedReasoning;
                _isInReasoningMode = true;
                _setStreamingStatus('Thinking...');
                // Start timing on first reasoning chunk
                _streamStartAt ??= DateTime.now();

                // Update temp message with thinking-only content so the collapsible
                // thinking section shows live in the message bubble
                final thinkingDisplay = '<think>$accumulatedReasoning</think>';
                if (tempMessage == null) {
                  if (needsTempCleanup) {
                    _currentMessages
                        .removeWhere((m) => m.id.startsWith('temp_'));
                  }
                  tempMessage = _createTempAssistantMessage(
                    tempMessageId,
                    thinkingDisplay,
                  );
                  if (_currentConversation?.id == originConversationId) {
                    _currentMessages.add(tempMessage);
                  }
                } else if (_currentConversation?.id == originConversationId) {
                  final index =
                      _currentMessages.indexWhere((m) => m.id == tempMessageId);
                  if (index != -1) {
                    _currentMessages[index] =
                        tempMessage.copyWith(content: thinkingDisplay);
                  }
                }

                notifyListeners();
                continue;
              }

              // Only handle bare 'content' chunks (V0 format). V1 chunks with a
              // 'type' field (reasoning.delta, content.delta, message.delta, etc.)
              // are handled by the chunkType switch below.
              if (chunk.containsKey('content') && !chunk.containsKey('type')) {
                // V0 has no model_load.* events — drop the JIT banner on first token.
                if (_isModelLoading) _clearModelLoadingBanner();
                final content = chunk['content'] as String;
                _isInReasoningMode = false;
                // Track first token time and approximate token count
                if (content.isNotEmpty) {
                  firstTokenTime ??= DateTime.now();
                  outputTokenCount++;
                }
                // Record thinking end time on first content chunk after reasoning
                if (accumulatedReasoning.isNotEmpty && _thinkingEndAt == null) {
                  _thinkingEndAt = DateTime.now();
                }
                accumulatedContent += content;
                _partialResponseContent =
                    accumulatedContent; // Track for partial saves
                if (_stopIfRepetitionLoop(accumulatedContent)) break;

                // During MCP tool call flow, don't update the display with
                // whitespace-only content (the model emits empty newlines between
                // tool call rounds, causing the message to appear blank/disappear).
                if (receivedMcpToolCall && accumulatedContent.trim().isEmpty) {
                  continue;
                }

                // Build display content with thinking tags if we have reasoning
                // Strip [IMG_PROMPT: ...] from display so it doesn't flash on screen
                // Also strip truncated tags (no closing ]) when output limit is hit
                String displayText = stripExpressionTagsForDisplay(
                        accumulatedContent)
                    .replaceAll(
                        RegExp(r'\[IMG_PROMPT:\s*.+?\]', dotAll: true), '')
                    .replaceAll(
                        RegExp(r'\[IMG_PROMPT:[^\]]*$', dotAll: true), '')
                    .trim();
                final displayContent = _formatAssistantWithReasoning(
                  displayText,
                  reasoning: accumulatedReasoning,
                  showReasoning: showReasoning,
                );

                // Update or create temp message (only if still on same conversation)
                if (tempMessage == null) {
                  // Clean up any leftover temp messages from previous iterations
                  if (needsTempCleanup) {
                    _currentMessages
                        .removeWhere((m) => m.id.startsWith('temp_'));
                  }
                  tempMessage = _createTempAssistantMessage(
                    tempMessageId,
                    displayContent,
                  );
                  if (_currentConversation?.id == originConversationId) {
                    _currentMessages.add(tempMessage);
                  }
                } else {
                  // Update existing temp message
                  if (_currentConversation?.id == originConversationId) {
                    final index = _currentMessages
                        .indexWhere((m) => m.id == tempMessageId);
                    if (index != -1) {
                      _currentMessages[index] =
                          tempMessage.copyWith(content: displayContent);
                    }
                  }
                }

                _setStreamingStatus('Writing response...');
                notifyListeners();
              }

              // Capture V0 usage stats (TokenUsage from streamChatCompletion)
              // V0 API yields {'usage': TokenUsage(...)} in its final chunk.
              // Convert to a Map so it can populate chatEndStats for MessageStats.
              if (chunk.containsKey('usage') &&
                  chunk['usage'] is TokenUsage &&
                  chatEndStats == null) {
                final tokenUsage = chunk['usage'] as TokenUsage;
                chatEndStats = {
                  'input_tokens': tokenUsage.promptTokens,
                  'total_output_tokens': tokenUsage.completionTokens,
                };
                debugPrint(
                    '📊 V0 usage captured: ${tokenUsage.promptTokens} in, ${tokenUsage.completionTokens} out');
              }

              // Handle tool calls (streaming format)
              // Execute locally for V0 / Ollama native. Skip only when LM Studio
              // MCP-only mode is active WITHOUT a client-side MCP registry
              // (server-side integrations handle tools instead).
              if (chunk.containsKey('tool_call') &&
                  (!settings.useMcpToolsOnly ||
                      clientMcpRegistry.isNotEmpty ||
                      isNativeOllama)) {
                receivedToolCall = true;
                // V0 often emits tool_call with no content tokens — clear the
                // JIT model-loading banner so it can't stick forever.
                if (_isModelLoading) _clearModelLoadingBanner();
                final toolName = chunk['tool_call'] as String;
                final args = chunk['arguments'] as String? ?? '{}';
                debugPrint('📥 Received tool call: $toolName');

                // Track tool call counts
                toolCallCounts[toolName] = (toolCallCounts[toolName] ?? 0) + 1;

                // If same tool called 3+ times, force stop
                if (toolCallCounts[toolName]! >= 3) {
                  debugPrint(
                      '🛑 Tool $toolName called ${toolCallCounts[toolName]} times, forcing final answer');
                  shouldStopRetrying = true;

                  final warningMessage = ChatMessage(
                    id: _uid(),
                    content:
                        'Note: The model called the $toolName tool ${toolCallCounts[toolName]} times. Please try rephrasing your question or use a different model.',
                    role: 'assistant',
                    timestamp: DateTime.now(),
                  );
                  await _databaseService.insertMessage(
                      warningMessage, originConversationId);
                  if (_currentConversation?.id == originConversationId) {
                    _currentMessages.add(warningMessage);
                  }
                  break;
                }

                _setStreamingStatus(
                    '🔧 Calling tool: $toolName (attempt ${toolCallCounts[toolName]})');
                notifyListeners();

                // If the model streamed partial content before the tool call,
                // keep the temp message visible (don't remove it) so the user
                // doesn't see the response flash and disappear.
                // It will be replaced by the final response in a later iteration.
                if (tempMessage != null &&
                    (accumulatedContent.trim().isNotEmpty ||
                        accumulatedReasoning.trim().isNotEmpty)) {
                  // Keep temp message visible — just update status
                  debugPrint(
                      '📎 Keeping temp message visible during tool call (${accumulatedContent.length} chars, ${accumulatedReasoning.length} reasoning)');
                } else if (tempMessage != null) {
                  // Empty content + tool call (and no reasoning): remove temp
                  if (_currentConversation?.id == originConversationId) {
                    _currentMessages.removeWhere((m) => m.id == tempMessageId);
                  }
                  tempMessage = null;
                }

                // Parse arguments
                Map<String, dynamic> toolArgs;
                try {
                  // Handle empty or whitespace-only strings
                  final trimmedArgs = args.trim();
                  if (trimmedArgs.isEmpty || trimmedArgs == '{}') {
                    toolArgs = {};
                  } else {
                    toolArgs = jsonDecode(trimmedArgs);
                  }
                } catch (e) {
                  debugPrint('Failed to parse tool arguments "$args": $e');
                  // Try to extract from malformed JSON
                  toolArgs = {};
                }

                // Execute tool - APP handles tool execution (not the model server)
                debugPrint(
                    '╔═══════════════════════════════════════════════════════════╗');
                debugPrint(
                    '║  📱 APP IS HANDLING TOOL CALL (CLIENT-SIDE)               ║');
                debugPrint(
                    '╚═══════════════════════════════════════════════════════════╝');
                final mcpRef = clientMcpRegistry[toolName];
                if (toolName == 'web_search' && isProSearch) {
                  final searchQuery = toolArgs['query'] as String? ?? '';
                  _setStreamingStatus('⚡ Pro Search: "$searchQuery"');
                } else if (mcpRef != null) {
                  _setStreamingStatus(
                      '🔌 MCP ${mcpRef.server.label}: $toolName...');
                } else {
                  _setStreamingStatus('⚙️ Executing $toolName...');
                }
                notifyListeners();

                String toolResult;
                try {
                  if (mcpRef != null) {
                    toolResult = await McpHttpClient.instance.callTool(
                      ref: mcpRef,
                      arguments: toolArgs,
                    );
                  } else {
                    toolResult = await ToolService.executeTool(
                      toolName: toolName,
                      arguments: toolArgs,
                      searxngUrl: settings.searxngUrl,
                      searchResultsCount: settings.searchResultsCount,
                      preferSearxng: settings.preferSearxng,
                      memoryScope: _toolMemoryScope(settings),
                      memoryPersonaId: _toolMemoryPersonaId(settings),
                      onMemoryWrite: _recordToolMemoryWrite,
                    );
                  }
                  if (isProSearch &&
                      (toolName == 'web_search' || toolName == 'read_url')) {
                    ProSearchResultLogger.logToolOutput(
                      tool: toolName,
                      output: toolResult,
                      query: toolArgs['query']?.toString() ??
                          toolArgs['url']?.toString(),
                    );
                  }
                  AnalyticsService().recordToolUse(toolName);

                  // Soft vs hard tool failures:
                  // - read_url / flaky page fetches: feed the error to the model
                  //   and keep going so it can answer from earlier web_search.
                  // - Only abort the loop for hard search/provider failures.
                  if (_isHardToolFailure(toolName, toolResult)) {
                    shouldStopRetrying = true;
                    toolAbortDetail = toolResult;
                    toolAbortSummary = _summarizeToolFailure(
                      toolName: toolName,
                      toolResult: toolResult,
                    );
                    debugPrint(
                        '❌ Tool returned hard error, will stop after this attempt');
                  } else if (_isSoftToolFailure(toolName, toolResult)) {
                    debugPrint(
                        '⚠️ Soft tool failure for $toolName — continuing so the model can answer');
                    // Drop tools next turn so small models don't keep
                    // retrying the same broken URL.
                    if (toolName == 'read_url' &&
                        tools != null &&
                        tools.isNotEmpty) {
                      tools = null;
                      forceV0 = true;
                    }
                  }
                } catch (e) {
                  // Thrown failures: soft for read_url, hard for search/others.
                  toolResult =
                      'Could not complete $toolName: $e. Answer with any information already available from earlier tool results.';
                  if (toolName == 'read_url') {
                    debugPrint('⚠️ read_url threw — soft-continuing: $e');
                    if (tools != null && tools.isNotEmpty) {
                      tools = null;
                      forceV0 = true;
                    }
                  } else {
                    shouldStopRetrying = true;
                    toolAbortDetail = toolResult;
                    toolAbortSummary = _summarizeToolFailure(
                      toolName: toolName,
                      toolResult: toolResult,
                    );
                    debugPrint('❌ Tool execution failed, stopping retries: $e');
                  }
                }

                // Add tool call message to conversation
                final toolCallMessage = ChatMessage(
                  id: _uid(),
                  content: 'Tool call: $toolName(${jsonEncode(toolArgs)})',
                  role: 'assistant',
                  timestamp: DateTime.now(),
                );
                await _databaseService.insertMessage(
                    toolCallMessage, originConversationId);
                if (_currentConversation?.id == originConversationId) {
                  _currentMessages.add(toolCallMessage);
                }

                // Add tool result message
                final toolResultMessage = ChatMessage(
                  id: _uid(),
                  content: toolResult,
                  role: 'tool',
                  timestamp: DateTime.now(),
                );
                await _databaseService.insertMessage(
                    toolResultMessage, originConversationId);
                if (_currentConversation?.id == originConversationId) {
                  _currentMessages.add(toolResultMessage);
                }

                // Add to messages for next request
                messages.add({
                  'role': 'assistant',
                  'tool_calls': [
                    {
                      'id': toolCallMessage.id,
                      'type': 'function',
                      'function': {
                        'name': toolName,
                        'arguments': jsonEncode(toolArgs),
                      },
                    },
                  ],
                });
                messages.add({
                  'role': 'tool',
                  'tool_call_id': toolCallMessage.id,
                  'name': toolName,
                  'content': toolResult,
                });

                // If tool failed, stop the loop
                if (shouldStopRetrying) {
                  debugPrint('🛑 Stopping tool loop due to error');
                  abortedByToolError = true;
                  loopCount = maxToolLoops; // Force exit from while loop
                }

                notifyListeners();
                break; // Break streaming loop to make next request
              }

              // Handle MCP / tool call events from v1 API
              // Per LM Studio streaming-events spec:
              // tool_call.start, tool_call.arguments, tool_call.success, tool_call.failure
              final chunkType = chunk['type'] as String?;
              if (chunkType != null) {
                switch (chunkType) {
                  case 'tool_call.start':
                    // LM Studio sends tool_call.start as a bare event (no tool field),
                    // followed by tool_call.name with the actual tool name.
                    // Mark that we're in an MCP tool call flow.
                    receivedMcpToolCall = true;
                    final tool = chunk['tool'] as String?;
                    if (tool != null) {
                      // Some versions include tool in tool_call.start directly
                      final providerInfo =
                          chunk['provider_info'] as Map<String, dynamic>?;
                      final providerType = providerInfo?['type'] as String?;
                      final serverLabel =
                          providerInfo?['server_label'] as String?;
                      final pluginId = providerInfo?['plugin_id'] as String?;

                      String source;
                      if (providerType == 'ephemeral_mcp') {
                        source = serverLabel ?? 'MCP';
                      } else if (providerType == 'plugin') {
                        source = pluginId ?? 'Plugin';
                      } else {
                        source = 'MCP';
                      }

                      debugPrint(
                          '🔧 MCP tool call started: $tool from $source');
                      _setStreamingStatus('🔧 $source: $tool');

                      final mcpCallMessage = ChatMessage(
                        id: _uid(),
                        content: '🔧 MCP call: $tool@$source',
                        role: 'assistant',
                        timestamp: DateTime.now(),
                      );
                      await _databaseService.insertMessage(
                          mcpCallMessage, originConversationId);
                      if (_currentConversation?.id == originConversationId) {
                        _currentMessages.add(mcpCallMessage);
                      }
                    } else {
                      debugPrint(
                          '🔧 MCP tool call starting (awaiting tool_call.name)...');
                      _setStreamingStatus('🔧 Calling tool...');
                    }
                    notifyListeners();
                    break;

                  case 'tool_call.name':
                    // Separate event with tool name + provider info
                    receivedMcpToolCall = true;
                    final toolName = chunk['tool'] as String?;
                    final providerInfo =
                        chunk['provider_info'] as Map<String, dynamic>?;
                    final providerType = providerInfo?['type'] as String?;
                    final serverLabel =
                        providerInfo?['server_label'] as String?;
                    final pluginId = providerInfo?['plugin_id'] as String?;

                    String source;
                    if (providerType == 'ephemeral_mcp') {
                      source = serverLabel ?? 'MCP';
                    } else if (providerType == 'plugin') {
                      source = pluginId ?? 'Plugin';
                    } else {
                      source = 'MCP';
                    }

                    debugPrint(
                        '🔧 MCP tool identified: $toolName from $source');
                    _setStreamingStatus('🔧 $source: $toolName');

                    if (toolName != null) {
                      final mcpCallMessage = ChatMessage(
                        id: _uid(),
                        content: '🔧 MCP call: $toolName@$source',
                        role: 'assistant',
                        timestamp: DateTime.now(),
                      );
                      await _databaseService.insertMessage(
                          mcpCallMessage, originConversationId);
                      if (_currentConversation?.id == originConversationId) {
                        _currentMessages.add(mcpCallMessage);
                      }
                    }
                    notifyListeners();
                    break;

                  case 'tool_call.arguments':
                    final tool = chunk['tool'] as String?;
                    final args = chunk['arguments'] as Map<String, dynamic>?;
                    if (args != null && args['query'] != null) {
                      _setStreamingStatus('🔍 Searching: "${args['query']}"');
                    } else {
                      _setStreamingStatus('🔧 Running $tool...');
                    }
                    notifyListeners();
                    break;

                  case 'tool_call.success':
                    final tool = chunk['tool'] as String?;
                    final output = chunk['output'];
                    final args = chunk['arguments'] as Map<String, dynamic>?;
                    final outputStr =
                        output is String ? output : jsonEncode(output ?? '');
                    if (tool == 'web_search' || tool == 'read_url') {
                      ProSearchResultLogger.logToolOutput(
                        tool: tool!,
                        output: output,
                        query: args?['query']?.toString() ??
                            args?['url']?.toString(),
                      );
                    } else {
                      debugPrint(
                          '✅ MCP tool $tool completed: ${outputStr.length} chars');
                    }
                    _setStreamingStatus('✅ $tool completed');

                    // Keep enough of the payload to rebuild source piles later.
                    final plain =
                        ProSearchResultLogger.extractPlainText(output);
                    const maxStore = 24000;
                    final stored = plain.length > maxStore
                        ? '${plain.substring(0, maxStore)}\n…'
                        : plain;
                    final mcpResultMessage = ChatMessage(
                      id: _uid(),
                      content: '✅ MCP result ($tool): $stored',
                      role: 'tool',
                      timestamp: DateTime.now(),
                    );
                    await _databaseService.insertMessage(
                        mcpResultMessage, originConversationId);
                    if (_currentConversation?.id == originConversationId) {
                      _currentMessages.add(mcpResultMessage);
                    }
                    notifyListeners();
                    break;

                  case 'tool_call.failure':
                    final reason = chunk['reason'] as String?;
                    final metadata = chunk['metadata'] as Map<String, dynamic>?;
                    final errorType = metadata?['type'] as String?;
                    final toolName = metadata?['tool_name'] as String?;
                    debugPrint('❌ MCP tool call failed: $reason ($errorType)');
                    if (errorType == 'invalid_name') {
                      _setStreamingStatus('⚠️ Tool not found: $toolName');
                    } else if (errorType == 'invalid_arguments') {
                      _setStreamingStatus('⚠️ Invalid arguments for $toolName');
                    } else {
                      _setStreamingStatus(
                          '⚠️ Tool error: ${reason ?? 'Unknown'}');
                    }
                    notifyListeners();
                    break;
                  case 'chat.end':
                    // chat.end contains the full result with output array, stats, and response_id
                    chatEndStats = chunk['usage'] as Map<String, dynamic>? ??
                        chunk['stats'] as Map<String, dynamic>?;
                    chatEndResponseId = chunk['response_id'] as String?;
                    debugPrint(
                        '📡 chat.end: response_id=${chatEndResponseId ?? "NULL"}, stats=${chatEndStats != null}');
                    final output = chunk['output'] as List<dynamic>?;
                    chatEndOutput = output;

                    // For MCP tool call flows, the model emits intermediate content
                    // between each tool call round via streaming deltas. The chat.end
                    // output array contains ALL segments (reasoning, message, tool_call,
                    // tool_result) in order. We concatenate all message/reasoning
                    // segments from chat.end to get the complete response.
                    final preferChatEndContent =
                        receivedMcpToolCall && output != null;

                    if (output != null &&
                        (accumulatedContent.trim().isEmpty ||
                            preferChatEndContent)) {
                      debugPrint(
                          '📡 chat.end: extracting content from result.output (${output.length} items, mcpOverride=$preferChatEndContent)');
                      final extracted = _extractTextFromChatEndOutput(
                        output,
                        includeReasoning: showReasoning,
                      );
                      final combinedReasoning = extracted['reasoning'] ?? '';
                      final combinedMessages = extracted['message'] ?? '';

                      if (showReasoning && combinedReasoning.isNotEmpty) {
                        accumulatedReasoning = combinedReasoning;
                        _currentReasoning = accumulatedReasoning;
                      }
                      if (combinedMessages.isNotEmpty) {
                        accumulatedContent = combinedMessages;
                        _partialResponseContent = accumulatedContent;
                      }
                      // Update/create temp message with the recovered content
                      if (accumulatedContent.isNotEmpty) {
                        final displayContent = _formatAssistantWithReasoning(
                          accumulatedContent,
                          reasoning: accumulatedReasoning,
                          showReasoning: showReasoning,
                        );
                        if (tempMessage == null) {
                          tempMessage = _createTempAssistantMessage(
                            tempMessageId,
                            displayContent,
                          );
                          _currentMessages.add(tempMessage);
                        } else {
                          final index = _currentMessages
                              .indexWhere((m) => m.id == tempMessageId);
                          if (index != -1) {
                            _currentMessages[index] =
                                tempMessage.copyWith(content: displayContent);
                          }
                        }
                        debugPrint(
                            '✅ Recovered ${accumulatedContent.length} chars from chat.end result');
                      }
                    } else {
                      debugPrint(
                          '📡 Chat event: chat.end (streamed ${accumulatedContent.length} chars)');
                    }
                    break;
                  case 'reasoning.delta':
                    // Always keep thinking text so [IMG_PROMPT] hidden in
                    // the reasoning channel can still be extracted.
                    final reasoningContent = chunk['content'] as String? ?? '';
                    if (reasoningContent.isNotEmpty) {
                      accumulatedReasoning += reasoningContent;
                      _currentReasoning = accumulatedReasoning;
                      _isInReasoningMode = true;
                      _streamStartAt ??= DateTime.now();
                    }
                    if (!showReasoning) break;
                    if (reasoningContent.isNotEmpty) {
                      _setStreamingStatus('Thinking...');

                      // Update temp message with live thinking display
                      final thinkingDisplay =
                          '<think>$accumulatedReasoning</think>';
                      if (tempMessage == null) {
                        if (needsTempCleanup) {
                          _currentMessages
                              .removeWhere((m) => m.id.startsWith('temp_'));
                        }
                        tempMessage = _createTempAssistantMessage(
                          tempMessageId,
                          thinkingDisplay,
                        );
                        if (_currentConversation?.id == originConversationId) {
                          _currentMessages.add(tempMessage);
                        }
                      } else if (_currentConversation?.id ==
                          originConversationId) {
                        final index = _currentMessages
                            .indexWhere((m) => m.id == tempMessageId);
                        if (index != -1) {
                          _currentMessages[index] =
                              tempMessage.copyWith(content: thinkingDisplay);
                        }
                      }
                      notifyListeners();
                    }
                    break;

                  case 'content.delta':
                  case 'message.delta':
                    // V1 message content delta
                    final msgContent = chunk['content'] as String? ?? '';
                    if (msgContent.isNotEmpty) {
                      _isInReasoningMode = false;
                      // Track first token time and approximate token count
                      firstTokenTime ??= DateTime.now();
                      outputTokenCount++;
                      _updateLiveActivity(
                          tokenCount: outputTokenCount,
                          firstTokenTime: firstTokenTime);
                      if (accumulatedReasoning.isNotEmpty &&
                          _thinkingEndAt == null) {
                        _thinkingEndAt = DateTime.now();
                      }
                      accumulatedContent += msgContent;
                      _partialResponseContent = accumulatedContent;
                      if (_stopIfRepetitionLoop(accumulatedContent)) break;

                      // Skip whitespace-only updates during MCP tool rounds
                      if (receivedMcpToolCall &&
                          accumulatedContent.trim().isEmpty) {
                        break;
                      }

                      // Build display (strip IMG_PROMPT flash + truncated tag)
                      String displayText = stripExpressionTagsForDisplay(
                              accumulatedContent)
                          .replaceAll(
                              RegExp(r'\[IMG_PROMPT:\s*.+?\]', dotAll: true),
                              '')
                          .replaceAll(
                              RegExp(r'\[IMG_PROMPT:[^\]]*$', dotAll: true), '')
                          .trim();
                      final displayContent = _formatAssistantWithReasoning(
                        displayText,
                        reasoning: accumulatedReasoning,
                        showReasoning: showReasoning,
                      );

                      if (tempMessage == null) {
                        if (needsTempCleanup) {
                          _currentMessages
                              .removeWhere((m) => m.id.startsWith('temp_'));
                        }
                        tempMessage = _createTempAssistantMessage(
                          tempMessageId,
                          displayContent,
                        );
                        if (_currentConversation?.id == originConversationId) {
                          _currentMessages.add(tempMessage);
                        }
                      } else if (_currentConversation?.id ==
                          originConversationId) {
                        final index = _currentMessages
                            .indexWhere((m) => m.id == tempMessageId);
                        if (index != -1) {
                          _currentMessages[index] =
                              tempMessage.copyWith(content: displayContent);
                        }
                      }
                      _setStreamingStatus('Writing response...');
                      notifyListeners();
                    }
                    break;

                  case 'chat.start':
                  case 'reasoning.start':
                  case 'message.start':
                    modelAcceptedThisSend = true;
                    debugPrint('📡 Chat event: $chunkType');
                    break;

                  case 'reasoning.end':
                  case 'message.end':
                    // Lifecycle events - just log
                    debugPrint('📡 Chat event: $chunkType');
                    break;

                  case 'model_load.start':
                    _setStreamingStatus('Loading model...');
                    _streamingProgress = 0.0;
                    _isModelLoading = true;
                    _modelLoadingProgress = 0.0;
                    _updateLiveActivity(force: true);
                    notifyListeners();
                    break;

                  case 'model_load.progress':
                    final progress = (chunk['progress'] as num?)?.toDouble();
                    _streamingProgress = progress;
                    _modelLoadingProgress = progress;
                    _setStreamingStatus(progress != null
                        ? 'Loading model... ${(progress * 100).toStringAsFixed(0)}%'
                        : 'Loading model...');
                    _updateLiveActivity();
                    notifyListeners();
                    break;

                  case 'model_load.end':
                    final loadTime = chunk['load_time_seconds'] as num?;
                    _setStreamingStatus(loadTime != null
                        ? 'Model loaded in ${loadTime.toStringAsFixed(1)}s'
                        : 'Model loaded');
                    _streamingProgress = 1.0;
                    _isModelLoading = false;
                    _modelLoadingProgress = null;
                    _updateLiveActivity(force: true);
                    notifyListeners();
                    break;

                  case 'prompt_processing.start':
                    if (_isModelLoading) _clearModelLoadingBanner();
                    _setStreamingStatus('Processing prompt...');
                    _streamingProgress = 0.0;
                    _updateLiveActivity(force: true);
                    notifyListeners();
                    break;

                  case 'prompt_processing.progress':
                    _setStreamingStatus('Processing prompt...');
                    _streamingProgress =
                        (chunk['progress'] as num?)?.toDouble();
                    _updateLiveActivity();
                    notifyListeners();
                    break;

                  case 'prompt_processing.end':
                    _setStreamingStatus('Generating response...');
                    _streamingProgress = null;
                    _updateLiveActivity(force: true);
                    notifyListeners();
                    break;
                }
              }
            }
            break;
          } on _ReasoningConfigRetry {
            if (reasoningRetried && reasoningAttempt >= 3) {
              _currentMessages.removeWhere((m) => m.id == tempMessageId);
              _setStreamingStatus(null);
              _isSendingMessage = false;
              _error =
                  'This model does not support Reasoning settings in LM Studio.';
              _errorDetail = null;
              notifyListeners();
              return;
            }
            continue;
          } on _StalePreviousResponseRetry {
            if (reasoningAttempt >= 3) {
              _currentMessages.removeWhere((m) => m.id == tempMessageId);
              _setStreamingStatus(null);
              _isSendingMessage = false;
              _error =
                  'Previous response was not found on the server. Try sending again.';
              _errorDetail = null;
              notifyListeners();
              return;
            }
            continue;
          } on _TransientModelRetry {
            continue;
          }
        }

        // If MCP handled tool calls and we have content, we're done (no looping needed for MCP)
        // MCP tool execution happens server-side, so we just need the final message
        if (receivedMcpToolCall &&
            accumulatedContent.isEmpty &&
            tempMessage == null) {
          // MCP tools ran but model didn't produce a final message.
          // This can happen when output tokens are exhausted during tool calling.
          debugPrint('⚠️ MCP tools ran but no final message content received');
          // Don't set error - this might be followed by more iterations
          // But mark that tool calls happened so we don't hit the empty-response break
        }

        // Strip common model artifact tokens that small models emit.
        // These look like content but carry no useful information.
        var strippedContent = accumulatedContent
            .replaceAll(RegExp(r'<\|?/?assistant\|?>'), '')
            .replaceAll(RegExp(r'<\|im_(start|end)\|?>'), '')
            .replaceAll(RegExp(r'<\|eot_id\|>'), '')
            .replaceAll(RegExp(r'<\|end\|>'), '')
            .trim();

        // If deltas were empty/garbled, try one more recovery pass from chat.end output.
        final outputItems = chatEndOutput;
        if (strippedContent.isEmpty &&
            outputItems != null &&
            outputItems.isNotEmpty) {
          final extracted = _extractTextFromChatEndOutput(
            outputItems,
            includeReasoning: showReasoning,
          );
          final recoveredMessage = extracted['message'] ?? '';
          final recoveredReasoning = extracted['reasoning'] ?? '';

          if (showReasoning &&
              recoveredReasoning.isNotEmpty &&
              accumulatedReasoning.isEmpty) {
            accumulatedReasoning = recoveredReasoning;
          }
          if (recoveredMessage.isNotEmpty) {
            accumulatedContent = recoveredMessage;
            strippedContent = recoveredMessage
                .replaceAll(RegExp(r'<\|?/?assistant\|?>'), '')
                .replaceAll(RegExp(r'<\|im_(start|end)\|?>'), '')
                .replaceAll(RegExp(r'<\|eot_id\|>'), '')
                .replaceAll(RegExp(r'<\|end\|>'), '')
                .trim();
            debugPrint(
                '✅ Recovered ${strippedContent.length} chars from fallback chat.end parsing');
          }
        }

        // If after stripping the content is empty but tool calls ran
        // in a previous iteration, the tool result messages are already
        // visible — just exit the loop without saving an empty bubble.
        if (strippedContent.isEmpty && tempMessage != null && loopCount > 1) {
          final lowThinking = _lowThinkingRetrySettings(
            settings: streamSettings,
            alreadyRetried: retriedLowThinking,
            stats: chatEndStats,
            answerEmpty: true,
            hadReasoning: accumulatedReasoning.trim().isNotEmpty,
          );
          if (lowThinking != null) {
            retriedLowThinking = true;
            streamSettings = lowThinking;
            _currentMessages.removeWhere((m) => m.id == tempMessageId);
            continue;
          }
          _currentMessages.removeWhere((m) => m.id == tempMessageId);

          // Small models sometimes emit only artifact tokens when the
          // tools array is still present in the follow-up request.
          // Retry once without tools to force a text response.
          if (tools != null && tools.isNotEmpty) {
            debugPrint(
                '🔄 Model returned empty after tool call — retrying without tools (staying on V0)');
            tools = null;
            forceV0 = true;
            continue;
          }

          // If still empty without tools, the model can't handle the
          // assistant+tool_calls / tool role format at all. Rewrite the
          // messages: collapse tool call + result into a plain user
          // message so the model sees it as normal conversation context.
          if (forceV0 && !triedPlainRewrite) {
            debugPrint(
                '🔄 Model still empty — rewriting tool messages as plain context, switching to V1');
            triedPlainRewrite = true;
            useV1Fallback = true;
            forceV0 = false;
            // Find and extract tool result content from messages
            final toolResults = <String>[];
            messages.removeWhere((m) {
              if (m['role'] == 'tool') {
                final content = m['content'] as String? ?? '';
                if (content.isNotEmpty) toolResults.add(content);
                return true;
              }
              if (m['role'] == 'assistant' && m.containsKey('tool_calls')) {
                return true;
              }
              return false;
            });
            // Re-add tool results as a USER message (never system — Qwen
            // templates reject non-leading system roles).
            if (toolResults.isNotEmpty) {
              messages.add({
                'role': 'user',
                'content':
                    'Here are the web search results:\n\n${toolResults.join('\n\n')}',
              });
              // Re-add the original user query so the model knows what to answer
              final originalUserMsg = messages.lastWhere(
                (m) =>
                    m['role'] == 'user' &&
                    !(m['content'] as String? ?? '')
                        .startsWith('Here are the web search results:'),
                orElse: () => <String, dynamic>{},
              );
              if (originalUserMsg.isNotEmpty) {
                messages.add({
                  'role': 'user',
                  'content':
                      'Based on the search results above, please answer my question: ${originalUserMsg['content']}',
                });
              }
            }
            continue;
          }

          debugPrint(
              '⚠️ Empty assistant payload after tool flow — asking for a higher max token limit');
          _thinkingBudgetNotice = false;
          _error = OutputTokenLimitError.userMessage;
          _errorDetail = null;
          _setStreamingStatus(null);
          notifyListeners();
          break; // exit tool loop
        }

        // If we got content (no tool calls), save and exit
        if (tempMessage != null && strippedContent.isNotEmpty) {
          // Check if content is just a tool call text (model outputting tool call as text)
          // Only handle locally if NOT in MCP-only mode
          final trimmedContent = strippedContent;
          if (trimmedContent.startsWith('Tool call:') &&
              !settings.useMcpToolsOnly) {
            // Remove temp message
            _currentMessages.removeWhere((m) => m.id == tempMessageId);

            // Parse the tool call text: "Tool call: tool_name({json})"
            try {
              final match = RegExp(r'Tool call:\s*(\w+)\((.*)\)')
                  .firstMatch(trimmedContent);
              if (match != null) {
                final toolName = match.group(1)!;
                final argsJson = match.group(2)!.trim();

                // Track tool call counts
                toolCallCounts[toolName] = (toolCallCounts[toolName] ?? 0) + 1;

                // If same tool called 3+ times, force stop
                if (toolCallCounts[toolName]! >= 3) {
                  debugPrint(
                      '🛑 Tool $toolName called ${toolCallCounts[toolName]} times, forcing final answer');
                  shouldStopRetrying = true;

                  final warningMessage = ChatMessage(
                    id: _uid(),
                    content:
                        'Note: The model called the $toolName tool ${toolCallCounts[toolName]} times. Please try rephrasing your question or use a different model.',
                    role: 'assistant',
                    timestamp: DateTime.now(),
                  );
                  await _databaseService.insertMessage(
                      warningMessage, originConversationId);
                  if (_currentConversation?.id == originConversationId) {
                    _currentMessages.add(warningMessage);
                  }
                  break;
                }

                _setStreamingStatus(
                    '🔧 Calling tool: $toolName (attempt ${toolCallCounts[toolName]})');
                notifyListeners();

                // Parse arguments
                Map<String, dynamic> toolArgs;
                try {
                  toolArgs = argsJson.isEmpty || argsJson == '{}'
                      ? {}
                      : jsonDecode(argsJson);
                } catch (e) {
                  toolArgs = {};
                }

                // Execute tool - APP handles tool execution (client-side)
                debugPrint(
                    '╔═══════════════════════════════════════════════════════════╗');
                debugPrint(
                    '║  📱 APP IS HANDLING TOOL CALL (CLIENT-SIDE) [STREAM]      ║');
                debugPrint(
                    '╚═══════════════════════════════════════════════════════════╝');
                final mcpRef = clientMcpRegistry[toolName];
                if (toolName == 'web_search' && isProSearch) {
                  final searchQuery = toolArgs['query'] as String? ?? '';
                  _setStreamingStatus('⚡ Pro Search: "$searchQuery"');
                } else if (mcpRef != null) {
                  _setStreamingStatus(
                      '🔌 MCP ${mcpRef.server.label}: $toolName...');
                } else {
                  _setStreamingStatus('⚙️ Executing $toolName...');
                }
                notifyListeners();

                String toolResult;
                try {
                  if (mcpRef != null) {
                    toolResult = await McpHttpClient.instance.callTool(
                      ref: mcpRef,
                      arguments: toolArgs,
                    );
                  } else {
                    toolResult = await ToolService.executeTool(
                      toolName: toolName,
                      arguments: toolArgs,
                      searxngUrl: settings.searxngUrl,
                      searchResultsCount: settings.searchResultsCount,
                      preferSearxng: settings.preferSearxng,
                      memoryScope: _toolMemoryScope(settings),
                      memoryPersonaId: _toolMemoryPersonaId(settings),
                      onMemoryWrite: _recordToolMemoryWrite,
                    );
                  }
                  if (isProSearch &&
                      (toolName == 'web_search' || toolName == 'read_url')) {
                    ProSearchResultLogger.logToolOutput(
                      tool: toolName,
                      output: toolResult,
                      query: toolArgs['query']?.toString() ??
                          toolArgs['url']?.toString(),
                    );
                  }
                  AnalyticsService().recordToolUse(toolName);

                  if (_isHardToolFailure(toolName, toolResult)) {
                    shouldStopRetrying = true;
                    toolAbortDetail = toolResult;
                    toolAbortSummary = _summarizeToolFailure(
                      toolName: toolName,
                      toolResult: toolResult,
                    );
                  } else if (_isSoftToolFailure(toolName, toolResult)) {
                    debugPrint(
                        '⚠️ Soft tool failure for $toolName — continuing so the model can answer');
                    if (toolName == 'read_url' &&
                        tools != null &&
                        tools.isNotEmpty) {
                      tools = null;
                      forceV0 = true;
                    }
                  }
                } catch (e) {
                  toolResult =
                      'Could not complete $toolName: $e. Answer with any information already available from earlier tool results.';
                  if (toolName == 'read_url') {
                    if (tools != null && tools.isNotEmpty) {
                      tools = null;
                      forceV0 = true;
                    }
                  } else {
                    shouldStopRetrying = true;
                    toolAbortDetail = toolResult;
                    toolAbortSummary = _summarizeToolFailure(
                      toolName: toolName,
                      toolResult: toolResult,
                    );
                  }
                }

                // Add tool call message
                final toolCallMessage = ChatMessage(
                  id: _uid(),
                  content: 'Tool call: $toolName(${jsonEncode(toolArgs)})',
                  role: 'assistant',
                  timestamp: DateTime.now(),
                );
                await _databaseService.insertMessage(
                    toolCallMessage, originConversationId);
                if (_currentConversation?.id == originConversationId) {
                  _currentMessages.add(toolCallMessage);
                }

                // Add tool result message
                final toolResultMessage = ChatMessage(
                  id: _uid(),
                  content: toolResult,
                  role: 'tool',
                  timestamp: DateTime.now(),
                );
                await _databaseService.insertMessage(
                    toolResultMessage, originConversationId);
                if (_currentConversation?.id == originConversationId) {
                  _currentMessages.add(toolResultMessage);
                }

                // Add to messages for next request
                messages.add({
                  'role': 'assistant',
                  'tool_calls': [
                    {
                      'id': toolCallMessage.id,
                      'type': 'function',
                      'function': {
                        'name': toolName,
                        'arguments': jsonEncode(toolArgs),
                      },
                    },
                  ],
                });
                messages.add({
                  'role': 'tool',
                  'tool_call_id': toolCallMessage.id,
                  'name': toolName,
                  'content': toolResult,
                });

                notifyListeners();

                // If tool failed, stop the loop
                if (shouldStopRetrying) {
                  abortedByToolError = true;
                  loopCount = maxToolLoops;
                  break; // Exit while loop
                }

                // Continue to next iteration of while loop to get response
                continue;
              }
            } catch (e) {
              // Error parsing tool call - will save as regular message
            }

            // If we reach here without breaking, continue the loop
            continue;
          }

          // Remove temp message
          _currentMessages.removeWhere((m) => m.id == tempMessageId);

          // Build final content with reasoning when enabled for this chat.
          final assembled = _assistantContentWithImagePrompt(
            message: strippedContent,
            reasoning: accumulatedReasoning,
            showReasoning: showReasoning,
          );
          var finalContent = assembled.content;
          final extractedImagePrompt = assembled.imagePrompt;

          if (settings.imageGenEnabled) {
            debugPrint(
                '🎨 [IMG/Tools] imageGenEnabled: true, serverUrl: ${settings.imageGenServerUrl}');
            debugPrint(
                '🎨 [IMG/Tools] autoGenerate: ${settings.imageGenAutoGenerate}');
            debugPrint(
                '🎨 [IMG/Tools] extractedImagePrompt: ${extractedImagePrompt ?? "NULL - model did not include [IMG_PROMPT: ...] tag"}');
            if (extractedImagePrompt == null) {
              final tail = accumulatedContent.length > 200
                  ? accumulatedContent
                      .substring(accumulatedContent.length - 200)
                  : accumulatedContent;
              debugPrint(
                  '🎨 [IMG/Tools] Response tail (last 200 chars): $tail');
            }
          }

          // Create final message with stats from chat.end
          // If server didn't return stats, build fallback from client-side timing
          if (chatEndStats == null &&
              firstTokenTime != null &&
              outputTokenCount > 0) {
            final ttft = firstTokenTime.difference(streamStartTime);
            final generationDuration =
                DateTime.now().difference(firstTokenTime);
            final generationSeconds =
                generationDuration.inMilliseconds / 1000.0;
            final tps = generationSeconds > 0
                ? outputTokenCount / generationSeconds
                : 0.0;
            chatEndStats = {
              'total_output_tokens': outputTokenCount,
              'time_to_first_token_seconds': ttft.inMilliseconds / 1000.0,
              'tokens_per_second': tps,
              'generation_time': generationSeconds,
            };
          }
          final finalMessage = ChatMessage(
            id: _uid(),
            content: finalContent,
            role: 'assistant',
            timestamp: DateTime.now(),
            model: settings.selectedModel,
            stats: chatEndStats != null
                ? MessageStats.fromJson(chatEndStats)
                : null,
            responseId: chatEndResponseId,
            imagePrompt: extractedImagePrompt,
            expression: assembled.expression,
            alternatives: tempMessage.alternatives,
            alternativeIndex: tempMessage.alternativeIndex,
          );

          await _databaseService.insertMessage(
              finalMessage, originConversationId);
          if (_currentConversation?.id == originConversationId) {
            _currentMessages.add(finalMessage);
          }

          // Store thinking duration if we had reasoning
          if (showReasoning &&
              _streamStartAt != null &&
              _thinkingEndAt != null &&
              accumulatedReasoning.isNotEmpty) {
            _thinkingDurationsMs[finalMessage.id] =
                _thinkingEndAt!.difference(_streamStartAt!).inMilliseconds;
          }

          // Record analytics
          final toolResponseMs = _streamStartAt != null
              ? DateTime.now()
                  .difference(_streamStartAt!)
                  .inMilliseconds
                  .toDouble()
              : null;
          AnalyticsService().recordMessage(
            modelId: settings.selectedModel ?? 'unknown',
            promptTokens: chatEndStats?['input_tokens'] as int? ?? 0,
            completionTokens: chatEndStats?['total_output_tokens'] as int? ?? 0,
            responseTimeMs: toolResponseMs,
          );
          unawaited(_recordPersonaAnalytics(
            settings: settings,
            assistantText: finalContent,
            tokensPerSecond:
                (chatEndStats?['tokens_per_second'] as num?)?.toDouble() ??
                    finalMessage.stats?.tokensPerSecond,
          ));

          // Update conversation with response_id for stateful continuation
          if (chatEndResponseId != null) {
            debugPrint('📡 [Tools] Saving response_id: $chatEndResponseId');
            if (_currentConversation?.id == originConversationId) {
              _currentConversation = _currentConversation!.copyWith(
                lastResponseId: chatEndResponseId,
                updatedAt: DateTime.now(),
                settings: _withLastUsedModel(
                    _currentConversation!.settings, finalMessage.model),
              );
              await _databaseService.updateConversation(_currentConversation!);
              _syncConversationInList(_currentConversation!);
            } else {
              // Conversation switched — save response_id to original in DB
              final origIdx = _conversations
                  .indexWhere((c) => c.id == originConversationId);
              if (origIdx != -1) {
                final updated = _conversations[origIdx].copyWith(
                  lastResponseId: chatEndResponseId,
                  updatedAt: DateTime.now(),
                  settings: _withLastUsedModel(
                      _conversations[origIdx].settings, finalMessage.model),
                );
                await _databaseService.updateConversation(updated);
                _syncConversationInList(updated);
              }
              // Mark as unread and clear background indicator
              _unreadConversationIds.add(originConversationId);
              _backgroundGeneratingConversationId = null;
              notifyListeners();
            }
          } else {
            debugPrint(
                '⚠️ [Tools] chat.end had NO response_id — next message will lose context!');
          }

          // Warm only when we have a continuable response_id.
          if (_currentConversation?.id == originConversationId) {
            _sessionWarm = _currentConversation!.lastResponseId != null;
            await _autoTitleIfNeeded(
              conversationId: _currentConversation!.id,
              titleContent: titleContent,
              settings: settings,
            );
          }

          // Clear status
          _setStreamingStatus(null);
          notifyListeners();

          // Auto-generate image if enabled and prompt was extracted
          if (extractedImagePrompt != null &&
              extractedImagePrompt.isNotEmpty &&
              settings.imageGenAutoGenerate &&
              settings.isImageGenReady) {
            debugPrint(
                '🎨 [IMG/Tools] ✅ Auto-generating image with prompt: $extractedImagePrompt');
            _autoGenerateImage(finalMessage, settings);
          } else if (settings.imageGenAutoGenerate &&
              settings.imageGenEnabled) {
            debugPrint(
                '🎨 [IMG/Tools] ⚠️ Auto-generate ON but no image prompt extracted from response');
          }

          break; // Exit tool loop
        }

        // Clean up any remaining temp messages if we didn't save
        // BUT: if we received a tool call while having content, keep the temp
        // message visible so it doesn't flash/disappear between iterations.
        if (tempMessage != null && !receivedToolCall) {
          _currentMessages.removeWhere((m) => m.id == tempMessageId);
        } else if (tempMessage != null && receivedToolCall) {
          // Tool call with content — we'll clean this up at the start of
          // the next iteration when new streaming content replaces it.
          debugPrint('📎 Preserving temp message across tool iteration');
        }

        // If cancelled, exit the tool loop
        if (_shouldCancelGeneration) {
          // Clean up any preserved temp messages
          _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
          break;
        }

        // If we got here with no content and no tool calls were received this iteration,
        // the model failed to respond - break to avoid infinite loop
        if (accumulatedContent.isEmpty &&
            !receivedToolCall &&
            !receivedMcpToolCall) {
          // Before giving up, try rewriting tool messages as plain context
          // (the model may not be able to process tool_calls/tool role format)
          if (forceV0 && !triedPlainRewrite && loopCount > 1) {
            debugPrint(
                '🔄 Model returned zero content — rewriting tool messages as plain context, switching to V1');
            triedPlainRewrite = true;
            useV1Fallback = true;
            forceV0 = false;
            final toolResults = <String>[];
            messages.removeWhere((m) {
              if (m['role'] == 'tool') {
                final content = m['content'] as String? ?? '';
                if (content.isNotEmpty) toolResults.add(content);
                return true;
              }
              if (m['role'] == 'assistant' && m.containsKey('tool_calls')) {
                return true;
              }
              return false;
            });
            if (toolResults.isNotEmpty) {
              // Use user role — mid-history system breaks Qwen templates.
              messages.add({
                'role': 'user',
                'content':
                    'Here are the web search results:\n\n${toolResults.join('\n\n')}',
              });
              final originalUserMsg = messages.lastWhere(
                (m) =>
                    m['role'] == 'user' &&
                    !(m['content'] as String? ?? '')
                        .startsWith('Here are the web search results:'),
                orElse: () => <String, dynamic>{},
              );
              if (originalUserMsg.isNotEmpty) {
                messages.add({
                  'role': 'user',
                  'content':
                      'Based on the search results above, please answer my question: ${originalUserMsg['content']}',
                });
              }
            }
            continue;
          }
          // Auto-retry once on empty response before giving up — but not when
          // LM Studio hung up during prompt ingest (that's context overflow).
          if (LMStudioService.isIngestOnlyStream(streamChunkLog)) {
            debugPrint(
                '🛑 V1 stream closed during prompt ingest with no LM Studio error body (chunks: $streamChunkLog)');
            _setStreamClosedAfterStartError(
              LMStudioService.streamClosedAfterChatStartChunk(
                contextTokens: _loadedContextTokens(settings),
              ),
              settings,
            );
            _currentMessages.removeWhere((m) => m.id == tempMessageId);
            _stopGenerationUi();
            notifyListeners();
            return;
          }
          final lowThinking = _lowThinkingRetrySettings(
            settings: streamSettings,
            alreadyRetried: retriedLowThinking,
            stats: chatEndStats,
            answerEmpty: true,
            hadReasoning: accumulatedReasoning.trim().isNotEmpty,
          );
          if (lowThinking != null) {
            retriedLowThinking = true;
            streamSettings = lowThinking;
            _currentMessages.removeWhere((m) => m.id == tempMessageId);
            continue;
          }
          if (!retriedEmptyResponse &&
              !(mcpConnectionFailed &&
                  LmsMcpError.isUnrecognizedPlugin(
                    mcpFailureDetail ?? mcpFailureUserMessage,
                  ))) {
            debugPrint(
                '🔄 Empty response — auto-retrying once (chunks: $streamChunkLog)');
            retriedEmptyResponse = true;
            _setStreamingStatus('Reply dropped — trying again…');
            notifyListeners();
            await Future.delayed(const Duration(milliseconds: 800));
            if (_shouldCancelGeneration) {
              _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
              _stopGenerationUi();
              notifyListeners();
              return;
            }
            continue;
          }
          debugPrint(
              '🛑 Model returned empty response with no tool calls (iteration $loopCount, chunks: $streamChunkLog)');
          // Only set error if not already set by the stream error handler
          if (_error == null) {
            if (mcpConnectionFailed) {
              _error =
                  mcpFailureUserMessage ?? LmsMcpError.proSearchUserMessage;
              _errorDetail = mcpFailureDetail;
            } else {
              _thinkingBudgetNotice = false;
              _error = OutputTokenLimitError.userMessage;
            }
          }
          break;
        }

        // If MCP tools ran but we got no content, the model may have exhausted tokens
        // during reasoning/tool calls. Don't loop again — MCP is handled server-side.
        if (receivedMcpToolCall && accumulatedContent.trim().isEmpty) {
          final lowThinking = _lowThinkingRetrySettings(
            settings: streamSettings,
            alreadyRetried: retriedLowThinking,
            stats: chatEndStats,
            answerEmpty: true,
            hadReasoning: accumulatedReasoning.trim().isNotEmpty,
          );
          if (lowThinking != null) {
            retriedLowThinking = true;
            streamSettings = lowThinking;
            _currentMessages.removeWhere((m) => m.id == tempMessageId);
            continue;
          }
          debugPrint(
              '⚠️ MCP tools completed but no final answer. Model may need more output tokens.');
          // Check if we at least have reasoning to show
          if (showReasoning && accumulatedReasoning.isNotEmpty) {
            // Save what we have (reasoning only) so the user sees the thinking
            final thinkingOnlyContent = '<think>$accumulatedReasoning</think>';
            // Build fallback stats if server didn't provide them
            if (chatEndStats == null &&
                firstTokenTime != null &&
                outputTokenCount > 0) {
              final ttft = firstTokenTime.difference(streamStartTime);
              final generationDuration =
                  DateTime.now().difference(firstTokenTime);
              final generationSeconds =
                  generationDuration.inMilliseconds / 1000.0;
              final tps = generationSeconds > 0
                  ? outputTokenCount / generationSeconds
                  : 0.0;
              chatEndStats = {
                'total_output_tokens': outputTokenCount,
                'time_to_first_token_seconds': ttft.inMilliseconds / 1000.0,
                'tokens_per_second': tps,
                'generation_time': generationSeconds,
              };
            }
            final partialMessage = ChatMessage(
              id: _uid(),
              content: thinkingOnlyContent,
              role: 'assistant',
              timestamp: DateTime.now(),
              stats: chatEndStats != null
                  ? MessageStats.fromJson(chatEndStats)
                  : null,
              responseId: chatEndResponseId,
            );
            _currentMessages.removeWhere((m) => m.id == tempMessageId);
            await _databaseService.insertMessage(
                partialMessage, originConversationId);
            if (_currentConversation?.id == originConversationId) {
              _currentMessages.add(partialMessage);
            }
            _thinkingBudgetNotice = false;
            _error = OutputTokenLimitError.userMessage;
          } else {
            _thinkingBudgetNotice = false;
            _error = OutputTokenLimitError.userMessage;
          }
          break;
        }

        debugPrint(
            '📋 End of iteration $loopCount: content=${accumulatedContent.length} chars, toolCall=$receivedToolCall, mcpToolCall=$receivedMcpToolCall');
      } catch (e) {
        if (e is _RetryWithoutTools ||
            (!retriedWithoutTools &&
                tools != null &&
                tools.isNotEmpty &&
                _isToolsUnsupportedError(e))) {
          retriedWithoutTools = true;
          tools = null;
          _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
          debugPrint(
              '🔄 Model rejected tools — retrying on the same provider without tools');
          continue;
        }
        // Show the actual error, not a generic wrapper
        final errStr = e.toString();
        final cleanErr =
            errStr.startsWith('Exception: ') ? errStr.substring(11) : errStr;
        _errorDetail = cleanErr;
        if (ChatMessageNormalizer.isSystemMessageOrderError(e)) {
          // Don't keep looping — each retry would hit the same Qwen template error.
          _error =
              'This model rejected the message layout (system message must be first). '
              'Try starting a new chat, or disable Pro Search / tools for this turn.';
          _errorDetail = cleanErr;
          // Drop the broken stateful session so the next send starts clean.
          if (_currentConversation != null) {
            final cleared = _currentConversation!.copyWith(
              clearLastResponseId: true,
            );
            _currentConversation = cleared;
            await _databaseService.updateConversation(cleared);
          }
          _sessionWarm = false;
        } else if (_setContextOverflowError(cleanErr)) {
          // message set
        } else if (_setHostInferenceError(cleanErr)) {
          // Host llama.cpp / LM Studio process died.
        } else if (_setSetupGuidanceError(cleanErr, settings)) {
          // Localhost / LMS LAN / missing model.
        } else {
          _error = cleanErr;
          _errorDetail = null;
        }

        // Remove any temp messages
        _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
        notifyListeners();
        break;
      }
    }

    if (loopCount >= maxToolLoops && !abortedByToolError) {
      _error = 'Maximum tool calling iterations reached';

      // If we have tool results but no final response, create a placeholder message
      final hasToolResults = _currentMessages.any((m) =>
          m.role == 'tool' &&
          m.timestamp
              .isAfter(DateTime.now().subtract(const Duration(seconds: 30))));

      if (hasToolResults) {
        final placeholderMessage = ChatMessage(
          id: _uid(),
          content:
              'I gathered some information but reached the tool calling limit. Please try rephrasing your question.',
          role: 'assistant',
          timestamp: DateTime.now(),
        );
        await _databaseService.insertMessage(
            placeholderMessage, originConversationId);
        if (_currentConversation?.id == originConversationId) {
          _currentMessages.add(placeholderMessage);
        }
      }
    }

    if (abortedByToolError && _error == null) {
      _error = toolAbortSummary ??
          'A tool failed, so the search was stopped. Check Settings → Tools → Web Search.';
      _errorDetail = toolAbortDetail;
    }

    // Always drop JIT loading / status chrome when the tool loop ends —
    // V0 tool-only turns never emit content tokens that would clear them.
    _clearModelLoadingBanner();
    _setStreamingStatus(null);
    _streamingProgress = null;
  }

  /// Short banner text for a failed client-side tool (SearXNG, etc.).
  String _summarizeToolFailure({
    required String toolName,
    required String toolResult,
  }) {
    final lower = toolResult.toLowerCase();
    if (toolName == 'web_search' || lower.contains('searxng')) {
      if (lower.contains('connection refused') ||
          lower.contains('socketexception')) {
        return 'SearXNG is unreachable (connection refused). '
            'Start SearXNG or turn off “Prefer SearXNG” to use Pro Search.';
      }
      return 'Web search failed. Check SearXNG in Settings → Tools → Web Search, '
          'or turn off “Prefer SearXNG”.';
    }
    if (toolName == 'read_url') {
      return 'Failed to read the URL. The page may be unreachable or blocked.';
    }
    // Keep the banner short; full text goes in errorDetail.
    final firstLine = toolResult.split('\n').first.trim();
    if (firstLine.length <= 160) return firstLine;
    return '${firstLine.substring(0, 157).trimRight()}…';
  }

  /// True when a tool result should abort the tool loop (no point continuing).
  ///
  /// Intentionally strict: page snippets often contain the words "error" /
  /// "failed", and `read_url` failures should not kill a turn that already
  /// has useful `web_search` results.
  bool _isHardToolFailure(String toolName, String toolResult) {
    final trimmed = toolResult.trimLeft();
    final lower = trimmed.toLowerCase();
    if (toolName == 'read_url') return false;
    if (toolName == 'web_search') {
      return lower.startsWith('searxng search failed') ||
          lower.startsWith('no search provider') ||
          lower.startsWith('search temporarily unavailable') ||
          lower.startsWith('error:') ||
          lower.startsWith('tool execution failed');
    }
    return lower.startsWith('error:') ||
        lower.startsWith('tool execution failed') ||
        lower.startsWith('could not complete');
  }

  /// Soft failures are returned to the model so it can recover / answer.
  bool _isSoftToolFailure(String toolName, String toolResult) {
    if (toolName != 'read_url') return false;
    final lower = toolResult.trimLeft().toLowerCase();
    return lower.startsWith('error') ||
        lower.startsWith('could not') ||
        lower.contains('header overflow') ||
        lower.contains('blocked') ||
        lower.contains('failed');
  }

  /// DEPRECATED: This method used /v1/responses endpoint which has different tool format
  /// Now MCP is handled through the v1 API (/api/v1/chat) with integrations array
  /// Kept for reference in case /v1/responses is needed in the future
  // ignore: unused_element
  Future<void> _sendMessageWithMcp(
      String content, AppSettings settings, List<String>? imageUrls,
      {String? userDisplayContent}) async {
    final originConversationId = _currentConversation!.id;
    final titleContent = userDisplayContent ?? content;

    debugPrint('🔌 Using /v1/responses endpoint with Remote MCP servers');

    // Build MCP tools array from active servers only
    final mcpTools = settings.activeMcpServers
        .map((server) => server.toApiFormat())
        .toList();
    debugPrint(
        '🔧 MCP tools: ${mcpTools.map((t) => t['server_label']).join(', ')}');

    // Build messages list
    List<ChatMessage> messagesForApi = [];

    // Add system prompt
    if (settings.systemPrompt.isNotEmpty) {
      messagesForApi.add(ChatMessage(
        id: 'system',
        content: settings.systemPrompt,
        role: 'system',
        timestamp: DateTime.now(),
      ));
    }

    // Full conversation history (except current user turn added below).
    final recentMessages = _currentMessages.length > 1
        ? _currentMessages.sublist(0, _currentMessages.length - 1)
        : <ChatMessage>[];
    for (final msg in recentMessages) {
      if (msg.role == 'assistant') {
        messagesForApi.add(msg.copyWith(
          content: ResponseParser.answerOnly(msg.content),
        ));
      } else {
        messagesForApi.add(msg);
      }
    }

    // Add current user message
    messagesForApi.add(ChatMessage(
      id: _uid(),
      content: content,
      role: 'user',
      timestamp: DateTime.now(),
      imageUrls: imageUrls,
    ));

    try {
      final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      ChatMessage? tempMessage = _createTempAssistantMessage(tempMessageId, '');
      if (_currentConversation?.id == originConversationId) {
        _currentMessages.add(tempMessage);
      }
      _setStreamingStatus('Connecting to MCP...');
      notifyListeners();
      String accumulatedContent = '';
      String? currentMcpTool;
      String? currentMcpServer;
      Map<String, dynamic>? currentMcpArgs;
      List<ChatMessage> mcpMessages = []; // Track MCP call/result messages

      await for (final chunk in _lmStudioService.streamResponsesWithMcp(
        baseUrl: settings.serverUrl,
        modelId: settings.selectedModel ?? '',
        messages: messagesForApi,
        mcpTools: mcpTools,
        settings: settings,
      )) {
        if (_shouldCancelGeneration) {
          debugPrint('🛑 MCP generation cancelled');
          break;
        }

        final type = chunk['type'] as String?;

        switch (type) {
          case 'response.created':
            debugPrint('📡 MCP response created: ${chunk['id']}');
            break;

          case 'response.in_progress':
            _setStreamingStatus('Processing...');
            notifyListeners();
            break;

          case 'content':
            final delta = chunk['content'] as String?;
            if (delta != null && delta.isNotEmpty) {
              accumulatedContent += delta;
              if (_stopIfRepetitionLoop(accumulatedContent)) break;

              if (tempMessage == null) {
                tempMessage = _createTempAssistantMessage(
                  tempMessageId,
                  accumulatedContent,
                );
                _currentMessages.add(tempMessage);
              } else {
                final index =
                    _currentMessages.indexWhere((m) => m.id == tempMessageId);
                if (index != -1) {
                  _currentMessages[index] =
                      tempMessage.copyWith(content: accumulatedContent);
                }
              }

              _setStreamingStatus('Generating response...');
              notifyListeners();
            }
            break;

          case 'mcp_call.start':
            currentMcpTool = chunk['tool'] as String?;
            currentMcpServer = chunk['server'] as String?;
            currentMcpArgs = chunk['arguments'] as Map<String, dynamic>?;
            _setStreamingStatus('🔧 MCP: $currentMcpTool ($currentMcpServer)');
            debugPrint(
                '🔧 MCP tool call started: $currentMcpTool on $currentMcpServer');

            // Save MCP tool call message
            if (currentMcpTool != null) {
              final mcpCallMessage = ChatMessage(
                id: _uid(),
                content:
                    'MCP call: $currentMcpTool@$currentMcpServer(${jsonEncode(currentMcpArgs ?? {})})',
                role: 'assistant',
                timestamp: DateTime.now(),
              );
              await _databaseService.insertMessage(
                  mcpCallMessage, _currentConversation!.id);
              mcpMessages.add(mcpCallMessage);
              _currentMessages.add(mcpCallMessage);
            }
            notifyListeners();
            break;

          case 'mcp_call.result':
            final tool = chunk['tool'] as String?;
            final output = chunk['output'];
            final outputStr = output is String ? output : jsonEncode(output);
            debugPrint('✅ MCP tool $tool completed: ${outputStr.length} chars');
            _setStreamingStatus('✅ MCP: $tool completed');

            // Save MCP result message
            final mcpResultMessage = ChatMessage(
              id: _uid(),
              content: outputStr,
              role:
                  'mcp', // Use 'mcp' role to distinguish from regular tool results
              timestamp: DateTime.now(),
            );
            await _databaseService.insertMessage(
                mcpResultMessage, _currentConversation!.id);
            mcpMessages.add(mcpResultMessage);
            _currentMessages.add(mcpResultMessage);
            notifyListeners();
            break;

          case 'mcp_call.error':
            final tool = chunk['tool'] as String?;
            final error = chunk['error'];
            debugPrint('❌ MCP tool $tool failed: $error');
            _setStreamingStatus('❌ MCP: $tool failed');

            // Save MCP error as result message
            final mcpErrorMessage = ChatMessage(
              id: _uid(),
              content: 'MCP Error: $error',
              role: 'mcp',
              timestamp: DateTime.now(),
            );
            await _databaseService.insertMessage(
                mcpErrorMessage, _currentConversation!.id);
            mcpMessages.add(mcpErrorMessage);
            _currentMessages.add(mcpErrorMessage);
            notifyListeners();
            break;

          case 'content.done':
            debugPrint('✅ Content streaming complete');
            break;

          case 'done':
            debugPrint('✅ MCP response complete');
            break;

          case 'error':
            final errorMsg = chunk['error']?.toString() ?? 'Unknown MCP error';
            debugPrint('❌ MCP error: $errorMsg');
            if (!_applyLmsPluginError(errorMsg, settings)) {
              _error = errorMsg;
            }

            // Clean up temp message
            _currentMessages.removeWhere((m) => m.id == tempMessageId);
            notifyListeners();
            return;
        }
      }

      // Remove temp message and create final message
      _currentMessages.removeWhere((m) => m.id == tempMessageId);

      if (accumulatedContent.isNotEmpty) {
        final finalMessage = ChatMessage(
          id: _uid(),
          content: accumulatedContent,
          role: 'assistant',
          timestamp: DateTime.now(),
          model: settings.selectedModel,
          alternatives: tempMessage?.alternatives,
          alternativeIndex: tempMessage?.alternativeIndex,
        );

        await _databaseService.insertMessage(
            finalMessage, _currentConversation!.id);
        _currentMessages.add(finalMessage);

        _currentConversation = _currentConversation!.copyWith(
          updatedAt: DateTime.now(),
          settings: _withLastUsedModel(
              _currentConversation!.settings, finalMessage.model),
        );
        await _databaseService.updateConversation(_currentConversation!);
        _syncConversationInList(_currentConversation!);

        // Update title if needed (AI-generated, with message fallback)
        await _autoTitleIfNeeded(
          conversationId: _currentConversation!.id,
          titleContent: titleContent,
          settings: settings,
        );
      }

      _setStreamingStatus(null);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ MCP streaming error: $e');
      _error = 'MCP error: $e';
      _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
      _setStreamingStatus(null);
      notifyListeners();
    }
  }

  /// Legacy method using old API - kept for fallback
  Future<void> sendMessageLegacy(String content, AppSettings settings) async {
    if (_currentConversation == null) return;
    if (!_usesLmStudioChatApi(settings) ||
        _usesCloudOrLocalOpenAiBackend(settings)) {
      await sendMessage(content, settings);
      return;
    }

    // Sync remote auth token for relay authentication
    RemoteHostBackends.configureLmStudioClient(_lmStudioService, settings);

    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    try {
      await _materializeGreetingIfNeeded(settings);

      // Add user message
      final userMessage = ChatMessage(
        id: _uid(),
        content: content,
        role: 'user',
        timestamp: DateTime.now(),
      );

      await _databaseService.insertMessage(
          userMessage, _currentConversation!.id);
      _currentMessages.add(userMessage);
      _currentConversation = _currentConversation!.copyWith(
        updatedAt: userMessage.timestamp,
      );
      await _databaseService.updateConversation(_currentConversation!);
      _syncConversationInList(_currentConversation!);
      notifyListeners();

      // Prepare messages for API (including system prompt if set)
      List<ChatMessage> messagesForAPI = [];

      if (settings.systemPrompt.isNotEmpty) {
        messagesForAPI.add(ChatMessage(
          id: 'system',
          content: settings.systemPrompt,
          role: 'system',
          timestamp: DateTime.now(),
        ));
      }

      // Add context messages (fit within ~80% of context window). Prefer
      // answer-only for assistant turns so thinking doesn't burn budget.
      final contextMessages =
          _currentMessages.where((m) => m.role != 'system').toList();

      // Simple token estimation: ~4 characters per token
      int estimatedTokens = 0;
      List<ChatMessage> contextToSend = [];

      for (int i = contextMessages.length - 1; i >= 0; i--) {
        final msg = contextMessages[i];
        final text = msg.role == 'assistant'
            ? ResponseParser.answerOnly(msg.content)
            : msg.content;
        final msgTokens = (text.length / 4).ceil();
        if (estimatedTokens + msgTokens > settings.contextWindow * 0.8) break;
        contextToSend.insert(
          0,
          msg.role == 'assistant' ? msg.copyWith(content: text) : msg,
        );
        estimatedTokens += msgTokens;
      }

      messagesForAPI.addAll(contextToSend);

      // Get AI response
      String aiResponse = '';
      TokenUsage? responseUsage;
      _streamStartAt = DateTime.now();

      try {
        // Always use v1 API - it has automatic fallback to v0 if unsupported
        var staleRetried = false;
        legacyV1:
        for (var attempt = 0; attempt < 2; attempt++) {
          final legacyRespId =
              staleRetried ? null : _currentConversation!.lastResponseId;
          final streamMethod = _lmStudioService.streamChatCompletionV1(
            baseUrl: settings.serverUrl,
            messages: messagesForAPI,
            settings: settings,
            apiToken: settings.apiToken,
            previousResponseId: legacyRespId,
            skipContextInjection:
                !staleRetried && _sessionWarm && legacyRespId != null,
            omitLoadParams:
                _omitLoadParamsForModel(settings.selectedModel ?? ''),
          );

          await for (final chunk in streamMethod) {
            if (chunk.containsKey('error') &&
                !staleRetried &&
                LMStudioService.isStalePreviousResponseId(chunk)) {
              staleRetried = true;
              await _dropStalePreviousResponseId();
              aiResponse = '';
              continue legacyV1;
            }
            // Handle content chunks
            if (chunk['content'] != null) {
              aiResponse += chunk['content'] as String;

              // Detect when thinking starts and ends based on tags during streaming
              if (_streamStartAt != null && _thinkingEndAt == null) {
                final hasOpen =
                    RegExp(r'<think>|<thinking>|\[think\]|\[thinking\]')
                        .hasMatch(aiResponse);
                if (hasOpen && _streamStartAt != null) {
                  // already set _streamStartAt at stream start; we could set a separate
                  // thinkingStartAt here if desired. For now, keep using _streamStartAt.
                }
              }
              if (_thinkingEndAt == null &&
                  ResponseParser.containsClosedThink(aiResponse)) {
                _thinkingEndAt = DateTime.now();
              }

              // Update the UI with partial response
              if (_currentMessages.isNotEmpty &&
                  _currentMessages.last.role == 'assistant' &&
                  _currentMessages.last.id.startsWith('temp_')) {
                _currentMessages.last =
                    _currentMessages.last.copyWith(content: aiResponse);
              } else {
                final tempAssistantMessage = ChatMessage(
                  id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                  content: aiResponse,
                  role: 'assistant',
                  timestamp: DateTime.now(),
                  model: settings.selectedModel,
                );
                _currentMessages.add(tempAssistantMessage);
              }
              notifyListeners();
            }

            // Capture usage from the stream
            if (chunk['usage'] != null) {
              responseUsage = chunk['usage'] as TokenUsage?;
            }
          }
          break;
        }
      } catch (e) {
        // Fallback to non-streaming if streaming fails
        final response = await _lmStudioService.getChatCompletion(
          baseUrl: settings.serverUrl,
          messages: messagesForAPI,
          settings: settings,
        );
        aiResponse = response['content'] as String;

        // Capture usage from non-streaming response
        responseUsage = response['usage'] as TokenUsage?;
      }

      // ── Log exact AI response ────────────────────────────────────────────
      debugPrint('📝 ═══════════════ AI RESPONSE (legacy) ═══════════════');
      debugPrint(aiResponse);
      debugPrint('📝 ═══════════════ END AI RESPONSE ═══════════════════════');

      // Save the final AI response with usage info
      final assistantMessage = ChatMessage(
        id: _uid(),
        content: aiResponse,
        role: 'assistant',
        timestamp: DateTime.now(),
        model: settings.selectedModel,
        usage: responseUsage,
      );

      int? thinkingDurationMs;
      if (_streamStartAt != null) {
        if (_thinkingEndAt != null) {
          thinkingDurationMs =
              _thinkingEndAt!.difference(_streamStartAt!).inMilliseconds;
        } else {
          thinkingDurationMs =
              DateTime.now().difference(_streamStartAt!).inMilliseconds;
        }
      }
      _streamStartAt = null;
      _thinkingEndAt = null;

      // Remove temp message if it exists
      if (_currentMessages.isNotEmpty &&
          _currentMessages.last.id.startsWith('temp_')) {
        _currentMessages.removeLast();
      }

      await _databaseService.insertMessage(
          assistantMessage, _currentConversation!.id);
      if (thinkingDurationMs != null) {
        _thinkingDurationsMs[assistantMessage.id] = thinkingDurationMs;
      }
      _currentMessages.add(assistantMessage);

      // Update conversation timestamp
      final updatedConversation = _currentConversation!.copyWith(
        updatedAt: DateTime.now(),
        messageIds: [
          ..._currentConversation!.messageIds,
          userMessage.id,
          assistantMessage.id
        ],
        settings: _withLastUsedModel(
            _currentConversation!.settings, assistantMessage.model),
      );

      await _databaseService.updateConversation(updatedConversation);
      _currentConversation = updatedConversation;
      _syncConversationInList(updatedConversation);
    } catch (e) {
      _error = 'Failed to send message: $e';

      // Remove temp message if error occurs
      if (_currentMessages.isNotEmpty &&
          _currentMessages.last.id.startsWith('temp_')) {
        _currentMessages.removeLast();
      }
    }

    _isSendingMessage = false;
    _setStreamingStatus(null);
    _cacheCurrentAssistantPreview();
    notifyListeners();
  }

  void _cacheCurrentAssistantPreview() {
    final convId = _currentConversation?.id;
    if (convId == null) return;
    for (var i = _currentMessages.length - 1; i >= 0; i--) {
      final m = _currentMessages[i];
      if (m.role == 'assistant' && m.content.trim().isNotEmpty) {
        setAssistantPreview(convId, m.content);
        return;
      }
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _databaseService.deleteConversation(conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);

      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
        _currentMessages = [];
      }

      unawaited(
          HomeSyncService.instance.rememberDeletedConversation(conversationId));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete conversation: $e';
      notifyListeners();
    }
  }

  Future<void> updateConversationTitle(
    String conversationId,
    String newTitle, {
    String? titleSource,
  }) async {
    try {
      // Use _currentConversation if it matches, to preserve in-memory state
      // like lastResponseId (which may not be in the _conversations list yet).
      final conversation = (_currentConversation?.id == conversationId)
          ? _currentConversation!
          : conversationById(conversationId);
      if (conversation == null) return;
      final cleaned = ChatTitle.displayLabel(newTitle);
      if (cleaned.isEmpty) return;
      final source = titleSource ?? ChatTitle.sourceUser;
      final updatedConversation = conversation.copyWith(
        title: cleaned,
        settings: ChatTitle.withSource(conversation.settings, source),
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateConversation(updatedConversation);

      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = updatedConversation;
      }

      if (_currentConversation?.id == conversationId) {
        _currentConversation = updatedConversation;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update conversation title: $e';
      notifyListeners();
    }
  }

  /// Set a provisional title from the first user message, then ask the active
  /// model for a short title in the background (non-blocking).
  Future<void> _autoTitleIfNeeded({
    required String conversationId,
    required String titleContent,
    required AppSettings settings,
  }) async {
    ChatConversation? conv;
    if (_currentConversation?.id == conversationId) {
      conv = _currentConversation;
    } else {
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) conv = _conversations[idx];
    }
    if (conv == null) return;
    // Transcription / suggested titles are set explicitly — don't overwrite.
    if (conv.settings['isTranscriptionChat'] == true) return;
    if (ChatTitle.isLocked(conv.settings) && !ChatTitle.isJunk(conv.title)) {
      return;
    }

    final userMessages =
        _currentMessages.where((m) => m.role == 'user').map((m) => m.content);
    final userCount = userMessages.where((c) => c.trim().isNotEmpty).length;
    // Short "hi"/"hello" openers: wait for a second user message.
    if (ChatTitle.isTrivialSeed(titleContent) && userCount < 2) {
      debugPrint('🏷️ Auto title deferred (trivial first message)');
      return;
    }

    final seed = ChatTitle.firstSubstantialSeed(userMessages, titleContent);

    if (!ChatTitle.isProvisional(
      currentTitle: conv.title,
      settings: conv.settings,
      seed: seed,
    )) {
      return;
    }

    final fallback = ChatTitle.fallbackFromUserMessage(seed);
    if (conv.title != fallback) {
      await updateConversationTitle(
        conversationId,
        fallback,
        titleSource: ChatTitle.sourceAuto,
      );
    }

    _enqueueExclusiveInferenceJob(
      () => _generateAiChatTitle(
        conversationId: conversationId,
        titleContent: seed,
        settings: settings,
        expectedCurrentTitle: fallback,
      ),
    );
  }

  /// Background one-shot completion that upgrades the provisional title.
  /// Never throws; keeps the fallback title on any failure.
  Future<void> _generateAiChatTitle({
    required String conversationId,
    required String titleContent,
    required AppSettings settings,
    required String expectedCurrentTitle,
  }) async {
    try {
      final snippet = titleContent.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (snippet.isEmpty) return;
      final capped =
          snippet.length > 400 ? '${snippet.substring(0, 400)}…' : snippet;

      const systemPrompt =
          'You invent short chat titles. Reply with ONLY a concise title '
          '(3–6 words). Match the language of the user message. '
          'No quotes, no trailing punctuation, no explanation.';
      final userPrompt = 'Create a title for this chat:\n\n$capped';

      final titleSettings = settings.copyWith(
        temperature: 0.3,
        // Thinking models often spend hundreds of tokens before content;
        // 128 was entirely consumed by reasoning_content (finish_reason=length).
        maxTokens: 512,
        reasoning: 'off',
        enableToolUse: false,
        enableWebSearch: false,
        useStructuredOutput: false,
        responseFormat: null,
        systemPrompt: '',
        selectedSystemPromptId: null,
      );

      final kind = settings.activeProviderKind;
      final isOnDevice = kind == 'onDeviceGguf' || kind == 'onDeviceMlx';
      final isOllama = kind == 'ollama';
      final isCloud = SettingsProvider.isCloudProviderKind(kind);

      // Title often starts from inside the chat.end handler while the main
      // SSE client is still open — overlapping requests come back empty.
      if (!isOnDevice && !isOllama) {
        await LMStudioService.waitForStreamsIdle();
      }

      String raw;
      if (isOnDevice) {
        final ready = await OnDeviceLLMService.instance.isReady(settings);
        if (!ready) return;
        final buf = StringBuffer();
        await for (final delta in LocalInferenceEngine.instance.streamChat(
          settings: titleSettings,
          history: const [],
          userMessage: userPrompt,
          systemPrompt: systemPrompt,
        )) {
          buf.write(delta);
        }
        raw = buf.toString();
      } else if (isOllama) {
        final messages = <Map<String, dynamic>>[
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ];
        final contentBuffer = StringBuffer();
        await for (final event in OllamaService.instance.streamChat(
          baseUrl: settings.serverUrl,
          messages: messages,
          settings: titleSettings,
          apiToken: settings.apiToken,
        )) {
          if (event['content'] != null) {
            contentBuffer.write(event['content']);
          }
          if (event['error'] != null) {
            debugPrint('🏷️ Title generation error: ${event['error']}');
            return;
          }
        }
        raw = contentBuffer.toString();
      } else if (isCloud) {
        final messages = <Map<String, dynamic>>[
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ];
        final contentBuffer = StringBuffer();
        final reasoningBuffer = StringBuffer();
        final cp = _resolveEffectiveCloudProvider(settings: settings);
        await for (final event in _lmStudioService.streamChatCompletion(
          baseUrl: settings.serverUrl,
          formattedMessages: messages,
          settings: titleSettings,
          apiToken: settings.apiToken,
          cloudProviderType: cp?.type,
          extraHeaders: cp?.type.extraHeaders.isNotEmpty == true
              ? cp!.type.extraHeaders
              : null,
        )) {
          if (event['content'] != null) {
            contentBuffer.write(event['content']);
          }
          if (event['reasoning'] != null) {
            reasoningBuffer.write(event['reasoning']);
          }
          if (event['error'] != null) {
            debugPrint('🏷️ Title generation error: ${event['error']}');
            return;
          }
        }
        raw = contentBuffer.toString();
        if (raw.trim().isEmpty) raw = reasoningBuffer.toString();
      } else {
        // Local LM Studio: non-streaming one-shot after the main SSE is idle.
        final result = await _lmStudioService.getChatCompletion(
          baseUrl: settings.serverUrl,
          messages: [
            ChatMessage(
              id: 'title_sys',
              role: 'system',
              content: systemPrompt,
              timestamp: DateTime.now(),
            ),
            ChatMessage(
              id: 'title_usr',
              role: 'user',
              content: userPrompt,
              timestamp: DateTime.now(),
            ),
          ],
          settings: titleSettings,
          apiToken: settings.apiToken,
        );
        raw = (result['content'] as String?) ?? '';
        if (raw.trim().isEmpty) {
          final reasoning = (result['reasoning'] as String?) ?? '';
          raw = _titleCandidateFromReasoning(reasoning) ?? '';
          if (raw.isNotEmpty) {
            debugPrint(
              '🏷️ Title from reasoning_content (content empty, '
              'finish=${result['finish_reason']})',
            );
          }
        }
      }

      final generated = ChatTitle.sanitizeGenerated(raw);
      if (generated == null) {
        debugPrint(
          '🏷️ Title generation empty/invalid raw="${raw.length > 120 ? '${raw.substring(0, 120)}…' : raw}"',
        );
        return;
      }

      // Prefer a real summary — don't "upgrade" to the same typed message.
      final seedNorm = snippet.toLowerCase();
      final genNorm = generated.toLowerCase();
      if (genNorm == seedNorm ||
          (seedNorm.startsWith(genNorm) && generated.length > 40)) {
        debugPrint('🏷️ Title generation echoed seed; keeping fallback');
        return;
      }

      // Don't overwrite a manual rename (or a newer auto-title).
      ChatConversation? current;
      if (_currentConversation?.id == conversationId) {
        current = _currentConversation;
      } else {
        final idx = _conversations.indexWhere((c) => c.id == conversationId);
        if (idx != -1) current = _conversations[idx];
      }
      if (current == null) return;
      if (ChatTitle.sourceOf(current.settings) == ChatTitle.sourceUser) {
        return;
      }
      if (current.title != expectedCurrentTitle &&
          !ChatTitle.isProvisional(
            currentTitle: current.title,
            settings: current.settings,
            seed: titleContent,
          )) {
        return;
      }

      await updateConversationTitle(
        conversationId,
        generated,
        titleSource: ChatTitle.sourceAi,
      );
      debugPrint('🏷️ Auto title: "$generated"');
    } catch (e) {
      debugPrint('🏷️ Title generation failed (keeping fallback): $e');
    }
  }

  /// Pull a short title out of truncated reasoning when content was empty.
  String? _titleCandidateFromReasoning(String reasoning) {
    final t = reasoning.trim();
    if (t.isEmpty) return null;

    // Prefer the last quoted phrase ("Global Consequences of Laziness").
    final quoted =
        RegExp(r'''["“«]([^"”»\n]{3,60})["”»]''').allMatches(t).toList();
    for (final m in quoted.reversed) {
      final candidate = (m.group(1) ?? '').trim();
      final sanitized = ChatTitle.sanitizeGenerated(candidate);
      if (sanitized != null) return sanitized;
    }

    // "Maybe something like Global Consequences of Laziness."
    final like = RegExp(
      r'(?:something like|title(?:\s+(?:is|could be|should be))?|call it)\s+'
      r'["“]?([^"”.\n!]{3,60})',
      caseSensitive: false,
    ).firstMatch(t);
    if (like != null) {
      final sanitized =
          ChatTitle.sanitizeGenerated((like.group(1) ?? '').trim());
      if (sanitized != null) return sanitized;
    }

    return null;
  }

  Future<void> updateConversation(ChatConversation conversation) async {
    try {
      final updatedConversation =
          conversation.copyWith(updatedAt: DateTime.now());

      await _databaseService.updateConversation(updatedConversation);

      final index = _conversations.indexWhere((c) => c.id == conversation.id);
      if (index != -1) {
        _conversations[index] = updatedConversation;
      }

      if (_currentConversation?.id == conversation.id) {
        _currentConversation = updatedConversation;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update conversation: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _errorDetail = null;
    notifyListeners();
  }

  /// Image-gen HTTP / ComfyUI dumps — short banner, JSON in details.
  void reportImageGenerationFailure(Object error) {
    final raw = error.toString();
    final clean = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (ComfyUiPromptError.matches(error) ||
        ComfyUiPromptError.matches(clean)) {
      _error = ComfyUiPromptError.userMessageFor(error);
      _errorDetail = clean;
      notifyListeners();
      return;
    }
    if (ImageGenUnreachableError.matches(error) ||
        ImageGenUnreachableError.matches(clean)) {
      _error = ImageGenUnreachableError.parse(error)?.userMessage ??
          ImageGenUnreachableError.parse(clean)?.userMessage ??
          clean;
      _errorDetail = clean;
      notifyListeners();
      return;
    }
    const prefix = 'Image generation failed';
    final withoutJson = clean.split(RegExp(r'[\n{]')).first.trim();
    var summary = withoutJson.isEmpty ? prefix : '$prefix: $withoutJson';
    if (summary.length > 180) {
      summary = '${summary.substring(0, 177).trimRight()}…';
    }
    _error = summary;
    _errorDetail = clean;
    notifyListeners();
  }

  /// Returns true and requests cancel when the model is stuck repeating.
  bool _stopIfRepetitionLoop(String accumulated) {
    if (!StreamRepetitionGuard.shouldStop(accumulated)) return false;
    debugPrint('🛑 Stopping generation: repetition loop detected');
    _shouldCancelGeneration = true;
    OnDeviceLLMService.instance.cancelActive();
    LMStudioService.cancelAllActiveStreams();
    OllamaService.cancelAllActiveStreams();
    return true;
  }

  /// Stop ongoing generation
  void stopGeneration() {
    if (!_isSendingMessage &&
        _backgroundGeneratingConversationId == null &&
        !_isAutonomousCycling) {
      return;
    }

    _shouldCancelGeneration = true;
    _shouldCancelAutonomous = true;
    _isAutonomousCycling = false;
    _isSendingMessage = false;
    _isCompacting = false;
    _backgroundGeneratingConversationId = null;
    _sendMessageOriginId = null;
    _setStreamingStatus('Cancelled');

    // Tell the on-device engine to stop too (no-op if nothing is running).
    OnDeviceLLMService.instance.cancelActive();

    // Force-close any in-flight LM Studio / Ollama streams. Closing the HTTP
    // connection is the documented way to interrupt generation on both.
    LMStudioService.cancelAllActiveStreams();
    OllamaService.cancelAllActiveStreams();

    // Remove any temp messages
    _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));

    notifyListeners();

    // Clear cancelled status after a brief moment
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_streamingStatus == 'Cancelled') {
        _setStreamingStatus(null);
        notifyListeners();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // On-device send path (fllama / MLX)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Streams a reply from the active on-device engine. Mirrors the
  /// LM-Studio path enough to feed the same temp-message + partial-save UI.
  Future<void> _sendMessageOnDevice(
    String content,
    AppSettings settings, {
    String? memoryContext,
    List<String>? imageUrls,
  }) async {
    final originConversationId = _currentConversation!.id;

    // Temp assistant message so the chat UI shows the spinner immediately.
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempAssistant = _createTempAssistantMessage(
      tempMessageId,
      '',
    );
    _currentMessages.add(tempAssistant);
    _partialResponseContent = '';
    _startPartialSaveTimer();
    // Distinguish "still loading the GGUF/MLX weights into RAM" from
    // "tokens are now streaming". The user sees the second message as
    // soon as the first delta arrives.
    _setStreamingStatus('Loading model…');
    notifyListeners();

    final history = List<ChatMessage>.from(_currentMessages)
      ..removeWhere((m) => m.id == tempMessageId);
    if (history.isNotEmpty && history.last.role == 'user') {
      history.removeLast();
    }
    final userApiContent = appendImageGenTurnReminder(
      content,
      enabled: settings.imageGenEnabled,
    );
    final packedHistory = _packedHistoryMessages(
      history,
      settings,
      extraTokens: ContextFit.estimateTokens(userApiContent),
    );

    final buffer = StringBuffer();
    var outputTokenCount = 0;
    DateTime? firstTokenTime;
    try {
      var firstDelta = true;
      await for (final delta in LocalInferenceEngine.instance.streamChat(
        settings: settings,
        history: packedHistory,
        userMessage: userApiContent,
        systemPrompt: applyExpressionInstructionToSystem(
          applyImageGenInstructionToSystem(
            settings.effectiveSystemPrompt,
            enabled: settings.imageGenEnabled,
          ),
          settings.expressionLabels,
        ),
        memoryContext: memoryContext,
        imageUrls: imageUrls,
      )) {
        if (_shouldCancelGeneration) {
          OnDeviceLLMService.instance.cancelActive();
          break;
        }
        if (_currentConversation?.id != originConversationId) break;
        if (firstDelta) {
          firstDelta = false;
          _setStreamingStatus('Writing response...');
          _updateLiveActivity(force: true);
        }
        buffer.write(delta);
        if (delta.trim().isNotEmpty) {
          firstTokenTime ??= DateTime.now();
          outputTokenCount++;
          _updateLiveActivity(
            tokenCount: outputTokenCount,
            firstTokenTime: firstTokenTime,
          );
        }
        _partialResponseContent = buffer.toString();
        // Update the temp message in-place so the UI shows the stream.
        final idx = _currentMessages.indexWhere((m) => m.id == tempMessageId);
        if (idx >= 0) {
          _currentMessages[idx] = _currentMessages[idx].copyWith(
              content: stripExpressionTagsForDisplay(buffer.toString()));
          notifyListeners();
        }
      }

      // Finalise — promote the temp message to a saved one.
      await _stopPartialSaveTimer();
      final rawText = buffer.toString();
      final assembled = _assistantContentWithImagePrompt(
        message: rawText,
        reasoning: null,
        showReasoning: false,
      );
      final idx = _currentMessages.indexWhere((m) => m.id == tempMessageId);
      final finalMessage = ChatMessage(
        id: _uid(),
        content: assembled.content.isEmpty
            ? '_(no output — the model returned nothing)_'
            : assembled.content,
        role: 'assistant',
        timestamp: DateTime.now(),
        alternatives: idx >= 0 ? _currentMessages[idx].alternatives : null,
        alternativeIndex:
            idx >= 0 ? _currentMessages[idx].alternativeIndex : null,
        imagePrompt: assembled.imagePrompt,
        expression: assembled.expression,
      );
      if (idx >= 0) {
        _currentMessages[idx] = finalMessage;
      } else {
        _currentMessages.add(finalMessage);
      }
      await _databaseService.insertMessage(finalMessage, originConversationId);
      _setStreamingStatus(null);
      notifyListeners();
      if (assembled.imagePrompt != null &&
          assembled.imagePrompt!.isNotEmpty &&
          settings.imageGenAutoGenerate &&
          settings.isImageGenReady) {
        _autoGenerateImage(finalMessage, settings);
      }
    } catch (e) {
      await _stopPartialSaveTimer();
      final errorMessage = ChatMessage(
        id: _uid(),
        content: 'On-device inference failed: $e',
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      final idx = _currentMessages.indexWhere((m) => m.id == tempMessageId);
      if (idx >= 0) {
        _currentMessages[idx] = errorMessage;
      } else {
        _currentMessages.add(errorMessage);
      }
      await _databaseService.insertMessage(errorMessage, originConversationId);
      _setStreamingStatus(null);
      notifyListeners();
    }
  }

  /// Ask the loaded model to summarize this chat, store the summary, and
  /// clear the server session so the next send uses summary + later turns.
  Future<void> compactCurrentConversation(
    AppSettings settings, {
    SettingsProvider? settingsProvider,
    BuildContext? uiContext,
  }) async {
    if (_currentConversation == null) return;
    if (_isSendingMessage || _isCompacting) return;
    if (!SubscriptionService().isPremium) return;
    await _proCompactCurrentConversation(
      settings,
      settingsProvider: settingsProvider,
      uiContext: uiContext,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Message actions: regenerate, edit, delete
  // ─────────────────────────────────────────────────────────────────────────────

  /// Swap the main text of an assistant message with one of its alternatives
  Future<void> setActiveAlternative(String messageId, int targetIndex) async {
    final msgIdx = _currentMessages.indexWhere((m) => m.id == messageId);
    if (msgIdx < 0) return;

    final message = _currentMessages[msgIdx];
    final alts = message.alternatives ?? [];

    final currentAltIndex = message.alternativeIndex ?? alts.length;
    if (targetIndex == currentAltIndex) return; // Already active

    // The total pool of variants is the current message + its alternatives
    final allVariants = [
      message.copyWith(alternatives: [], alternativeIndex: currentAltIndex),
      ...alts,
    ];

    // Find the one that corresponds to the target conceptual index
    final chosenIdx = allVariants.indexWhere((m) {
      if (m.alternativeIndex != null) return m.alternativeIndex == targetIndex;
      if (m == allVariants.first) return currentAltIndex == targetIndex;
      // Fallback for legacy messages that were saved before alternativeIndex was enforced
      return (allVariants.indexOf(m) - 1) == targetIndex;
    });
    if (chosenIdx < 0) return; // not found

    final chosenAlt = allVariants[chosenIdx];

    // The new alternatives list is everyone EXCEPT the chosen one
    allVariants.removeAt(chosenIdx);

    final newActiveMessage = chosenAlt.copyWith(
      id: message.id,
      alternatives: allVariants,
      alternativeIndex: targetIndex,
      participantId: message.participantId, // keep group context stable
    );

    _currentMessages[msgIdx] = newActiveMessage;
    notifyListeners();
    unawaited(_databaseService.updateMessage(newActiveMessage));
  }

  /// Regenerate the last assistant response.
  /// Deletes the current assistant message and re-sends the preceding user
  /// message through the normal send flow.
  Future<void> regenerateLastResponse(
    AppSettings settings, {
    SettingsProvider? settingsProvider,
    BuildContext? uiContext,
  }) async {
    if (_currentConversation == null || _currentMessages.isEmpty) return;
    if (_isSendingMessage) return;

    _activeSettingsProvider = settingsProvider;
    _activeUiContext = uiContext;
    int lastAssistantIdx = -1;
    for (int i = _currentMessages.length - 1; i >= 0; i--) {
      final msg = _currentMessages[i];
      if (msg.role == 'assistant' &&
          !msg.content.startsWith('Tool call:') &&
          !msg.content.startsWith('MCP call:') &&
          !msg.content.startsWith('🔧 MCP call:')) {
        lastAssistantIdx = i;
        break;
      }
    }
    if (lastAssistantIdx < 0) return;

    // Find the user message that prompted this response
    int userMsgIdx = -1;
    for (int i = lastAssistantIdx - 1; i >= 0; i--) {
      if (_currentMessages[i].role == 'user') {
        userMsgIdx = i;
        break;
      }
    }
    if (userMsgIdx < 0) return;

    final userMessage = _currentMessages[userMsgIdx];

    // Find the previous response_id to branch from (the assistant message
    // before the user msg we're regenerating from, if any).
    String? previousResponseId;
    for (int i = userMsgIdx - 1; i >= 0; i--) {
      final msg = _currentMessages[i];
      if (msg.role == 'assistant' &&
          msg.responseId != null &&
          !msg.content.startsWith('Tool call:') &&
          !msg.content.startsWith('MCP call:') &&
          !msg.content.startsWith('🔧 MCP call:')) {
        previousResponseId = msg.responseId;
        break;
      }
    }

    // Save the old assistant message as an alternative
    final lastAssistantMessage = _currentMessages[lastAssistantIdx];
    final currentAltIndex = lastAssistantMessage.alternativeIndex ??
        (lastAssistantMessage.alternatives?.length ?? 0);
    _pendingAlternatives = [
      ...(lastAssistantMessage.alternatives ?? []),
      lastAssistantMessage
          .copyWith(alternatives: [], alternativeIndex: currentAltIndex),
    ];

    // Remove everything after the user message (tool calls, tool results,
    // and the assistant response) so the user message is the last item
    // in _currentMessages — which is what _sendMessageWithTools expects.
    final messagesToDelete = _currentMessages.sublist(userMsgIdx + 1);
    for (final m in messagesToDelete) {
      await _databaseService.deleteMessage(m.id);
    }
    _currentMessages.removeRange(userMsgIdx + 1, _currentMessages.length);

    // Reset conversation's lastResponseId so stateful API branches correctly
    _currentConversation = _currentConversation!.copyWith(
      lastResponseId: previousResponseId,
      clearLastResponseId: previousResponseId == null,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(_currentConversation!);

    notifyListeners();

    // Re-send through the normal flow (this re-adds the streaming message etc.)
    // We need to re-insert the user message content without creating a new user
    // message (it's still in the list). So we call the internal send methods
    // directly.
    _isSendingMessage = true;
    _shouldCancelGeneration = false;
    _sendMessageOriginId = _currentConversation!.id;
    _error = null;
    _setStreamingStatus(null);
    _streamingProgress = null;
    _currentReasoning = null;
    _isInReasoningMode = false;
    notifyListeners();

    var effectiveSettings = _applyCloudRouting(getEffectiveSettings(settings));
    RemoteHostBackends.configureLmStudioClient(
      _lmStudioService,
      effectiveSettings,
    );
    await _invalidateSessionIfModelChanged(effectiveSettings.selectedModel);
    await _beginGenerationSession(effectiveSettings);

    try {
      final readySettings = await _ensureChatBackendReady(effectiveSettings);
      if (readySettings != null) {
        effectiveSettings = readySettings;

        final providerKind = effectiveSettings.activeProviderKind;
        final memoryContext =
            await _buildMemoryContextForChat(effectiveSettings);

        if (providerKind == 'onDeviceGguf' || providerKind == 'onDeviceMlx') {
          final regenContent = OnDeviceAttachments.withFileText(
            userMessage.content,
            files: userMessage.fileAttachments,
            maxChars: OnDeviceAttachments.attachmentCharBudget(
              OnDeviceLLMService.effectiveContextSize(effectiveSettings),
            ),
          );
          await _sendMessageOnDevice(
            regenContent,
            effectiveSettings,
            memoryContext: memoryContext,
            imageUrls: userMessage.imageUrls,
          );
        } else {
          await _routeNetworkAssistantReply(
            content: userMessage.content,
            settings: effectiveSettings,
            imageUrls: userMessage.imageUrls,
            userDisplayContent: userMessage.content,
            memoryContext: memoryContext,
          );
        }
      }
    } catch (e) {
      if (_setContextOverflowError(e) ||
          _setHostInferenceError(e) ||
          _setSetupGuidanceError(e, settings)) {
        // User-facing host / setup message is already set.
      } else {
        _error = 'Failed to regenerate: $e';
      }
    } finally {
      await _stopPartialSaveTimer();
      _endLiveActivity();
      _activeSettingsProvider = null;
      _activeUiContext = null;
    }

    if (_currentConversation?.id == _sendMessageOriginId) {
      _isSendingMessage = false;
      _setStreamingStatus(null);
    }
    _backgroundGeneratingConversationId = null;
    _sendMessageOriginId = null;
    notifyListeners();
  }

  /// Shrink the last user turn's attached photos in place, then replay that
  /// turn without adding another user bubble. Used when LM Studio `terminated`
  /// a huge vision request.
  Future<void> compressLastImagesAndResend(
    AppSettings settings, {
    SettingsProvider? settingsProvider,
    BuildContext? uiContext,
  }) async {
    if (_currentConversation == null || _currentMessages.isEmpty) return;
    if (_isSendingMessage) return;

    int userMsgIdx = -1;
    for (int i = _currentMessages.length - 1; i >= 0; i--) {
      if (_currentMessages[i].role == 'user') {
        userMsgIdx = i;
        break;
      }
    }
    if (userMsgIdx < 0) return;

    var userMessage = _currentMessages[userMsgIdx];
    final urls = userMessage.imageUrls;
    if (urls == null || urls.isEmpty) return;

    // Group replies need Pro. Check before compressing or deleting anything,
    // so a locked group chat keeps its replies.
    if (GroupChatProGate.isLocked(this)) {
      if (uiContext != null && uiContext.mounted) {
        await GroupChatProGate.showUpgradeDialog(uiContext);
      }
      return;
    }

    _activeSettingsProvider = settingsProvider;
    _activeUiContext = uiContext;
    _isSendingMessage = true;
    _shouldCancelGeneration = false;
    _sendMessageOriginId = _currentConversation!.id;
    _error = null;
    _errorDetail = null;
    _setStreamingStatus('Compressing image…');
    _streamingProgress = null;
    _currentReasoning = null;
    _isInReasoningMode = false;
    notifyListeners();

    try {
      var compressed = await ChatImageCompress.compressUrls(urls);
      if (compressed != null &&
          ChatImagePayload.largeBytesOrNull(compressed) != null) {
        compressed = await ChatImageCompress.compressUrls(
              compressed,
              edge: ChatImageCompress.aggressiveMaxEdge,
              quality: ChatImageCompress.aggressiveJpegQuality,
            ) ??
            compressed;
      }
      compressed ??= await ChatImageCompress.compressUrls(
        urls,
        edge: ChatImageCompress.aggressiveMaxEdge,
        quality: ChatImageCompress.aggressiveJpegQuality,
      );
      if (compressed == null) {
        _error = ChatImageCompress.failedUserMessage;
        return;
      }

      userMessage = userMessage.copyWith(imageUrls: compressed);
      await _databaseService.updateMessage(userMessage);
      _currentMessages[userMsgIdx] = userMessage;

      String? previousResponseId;
      for (int i = userMsgIdx - 1; i >= 0; i--) {
        final msg = _currentMessages[i];
        if (msg.role == 'assistant' &&
            msg.responseId != null &&
            !msg.content.startsWith('Tool call:') &&
            !msg.content.startsWith('MCP call:') &&
            !msg.content.startsWith('🔧 MCP call:')) {
          previousResponseId = msg.responseId;
          break;
        }
      }

      final messagesToDelete = _currentMessages.sublist(userMsgIdx + 1);
      for (final m in messagesToDelete) {
        await _databaseService.deleteMessage(m.id);
      }
      if (messagesToDelete.isNotEmpty) {
        _currentMessages.removeRange(userMsgIdx + 1, _currentMessages.length);
      }

      _currentConversation = _currentConversation!.copyWith(
        lastResponseId: previousResponseId,
        clearLastResponseId: previousResponseId == null,
        updatedAt: DateTime.now(),
      );
      await _databaseService.updateConversation(_currentConversation!);
      _pendingAlternatives = null;
      notifyListeners();

      var effectiveSettings =
          _applyCloudRouting(getEffectiveSettings(settings));
      RemoteHostBackends.configureLmStudioClient(
        _lmStudioService,
        effectiveSettings,
      );
      await _invalidateSessionIfModelChanged(effectiveSettings.selectedModel);
      await _beginGenerationSession(effectiveSettings);

      final readySettings = await _ensureChatBackendReady(effectiveSettings);
      if (readySettings == null) return;
      effectiveSettings = readySettings;

      final providerKind = effectiveSettings.activeProviderKind;
      final memoryContext = await _buildMemoryContextForChat(effectiveSettings);

      if (providerKind == 'onDeviceGguf' || providerKind == 'onDeviceMlx') {
        final regenContent = OnDeviceAttachments.withFileText(
          userMessage.content,
          files: userMessage.fileAttachments,
          maxChars: OnDeviceAttachments.attachmentCharBudget(
            OnDeviceLLMService.effectiveContextSize(effectiveSettings),
          ),
        );
        await _sendMessageOnDevice(
          regenContent,
          effectiveSettings,
          memoryContext: memoryContext,
          imageUrls: userMessage.imageUrls,
        );
      } else if (isGroupChat) {
        await _proSendGroupMessage(
          userMessage.content,
          effectiveSettings,
          userMessage.imageUrls,
          userDisplayContent: userMessage.content,
          memoryContext: memoryContext,
        );
      } else {
        await _routeNetworkAssistantReply(
          content: userMessage.content,
          settings: effectiveSettings,
          imageUrls: userMessage.imageUrls,
          userDisplayContent: userMessage.content,
          memoryContext: memoryContext,
        );
      }
    } catch (e) {
      if (_setContextOverflowError(e) ||
          _setHostInferenceError(e) ||
          _setSetupGuidanceError(e, settings)) {
        // User-facing host / setup message is already set.
      } else {
        _error = 'Failed to resend: $e';
      }
    } finally {
      await _stopPartialSaveTimer();
      _endLiveActivity();
      _activeSettingsProvider = null;
      _activeUiContext = null;
      if (_currentConversation?.id == _sendMessageOriginId) {
        _isSendingMessage = false;
        _setStreamingStatus(null);
      }
      _backgroundGeneratingConversationId = null;
      _sendMessageOriginId = null;
      notifyListeners();
    }
  }

  /// Regenerate from a specific participant message in a group chat.
  /// Deletes this message and all subsequent participant messages, then
  /// re-sends to this participant and all participants after it in order.
  Future<void> regenerateFromGroupMessage(
      String messageId, AppSettings settings,
      {BuildContext? uiContext}) async {
    if (_currentConversation == null || _currentMessages.isEmpty) return;
    if (_isSendingMessage) return;
    if (_currentConversation!.settings['isGroupChat'] != true) return;
    if (GroupChatProGate.isLocked(this)) {
      if (uiContext != null && uiContext.mounted) {
        await GroupChatProGate.showUpgradeDialog(uiContext);
      }
      return;
    }

    await _proRegenerateFromGroupMessage(messageId, settings);
  }

  /// Edit a message's content (user or assistant).
  /// For user messages this just updates the text in place.
  /// Pass [andRegenerate] = true to also delete everything after the user
  /// message and regenerate the response.
  Future<void> editMessage(
    String messageId,
    String newContent,
    AppSettings settings, {
    bool andRegenerate = false,
    SettingsProvider? settingsProvider,
    BuildContext? uiContext,
  }) async {
    if (_currentConversation == null) return;
    if (_isSendingMessage) return;

    _activeSettingsProvider = settingsProvider;
    _activeUiContext = uiContext;

    final idx = _currentMessages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    final message = _currentMessages[idx];
    final updated = message.copyWith(content: newContent);

    // Persist
    await _databaseService.updateMessage(updated);
    _currentMessages[idx] = updated;
    notifyListeners();

    if (andRegenerate && message.role == 'user') {
      // Delete everything after this user message
      final toDelete = _currentMessages.sublist(idx + 1);
      for (final m in toDelete) {
        await _databaseService.deleteMessage(m.id);
      }
      _currentMessages.removeRange(idx + 1, _currentMessages.length);

      // Find previous response_id (from the assistant message before this user msg)
      String? previousResponseId;
      for (int i = idx - 1; i >= 0; i--) {
        final msg = _currentMessages[i];
        if (msg.role == 'assistant' &&
            msg.responseId != null &&
            !msg.content.startsWith('Tool call:') &&
            !msg.content.startsWith('MCP call:') &&
            !msg.content.startsWith('🔧 MCP call:')) {
          previousResponseId = msg.responseId;
          break;
        }
      }

      _currentConversation = _currentConversation!.copyWith(
        lastResponseId: previousResponseId,
        clearLastResponseId: previousResponseId == null,
        updatedAt: DateTime.now(),
      );
      await _databaseService.updateConversation(_currentConversation!);
      notifyListeners();

      // Re-send
      _isSendingMessage = true;
      _shouldCancelGeneration = false;
      _sendMessageOriginId = _currentConversation!.id;
      _error = null;
      _setStreamingStatus(null);
      _streamingProgress = null;
      _currentReasoning = null;
      _isInReasoningMode = false;
      notifyListeners();

      var effectiveSettings =
          _applyCloudRouting(getEffectiveSettings(settings));
      RemoteHostBackends.configureLmStudioClient(
        _lmStudioService,
        effectiveSettings,
      );
      await _invalidateSessionIfModelChanged(effectiveSettings.selectedModel);
      await _beginGenerationSession(effectiveSettings);

      try {
        final readySettings = await _ensureChatBackendReady(effectiveSettings);
        if (readySettings != null) {
          effectiveSettings = readySettings;

          final providerKind = effectiveSettings.activeProviderKind;
          final memoryContext =
              await _buildMemoryContextForChat(effectiveSettings);

          if (providerKind == 'onDeviceGguf' || providerKind == 'onDeviceMlx') {
            final editContent = OnDeviceAttachments.withFileText(
              newContent,
              files: updated.fileAttachments,
              maxChars: OnDeviceAttachments.attachmentCharBudget(
                OnDeviceLLMService.effectiveContextSize(effectiveSettings),
              ),
            );
            await _sendMessageOnDevice(
              editContent,
              effectiveSettings,
              memoryContext: memoryContext,
              imageUrls: updated.imageUrls,
            );
          } else {
            await _routeNetworkAssistantReply(
              content: newContent,
              settings: effectiveSettings,
              imageUrls: updated.imageUrls,
              userDisplayContent: newContent,
              memoryContext: memoryContext,
            );
          }
        }
      } catch (e) {
        _error = 'Failed to regenerate after edit: $e';
      } finally {
        await _stopPartialSaveTimer();
        _endLiveActivity();
        _activeSettingsProvider = null;
        _activeUiContext = null;
      }

      if (_currentConversation?.id == _sendMessageOriginId) {
        _isSendingMessage = false;
        _setStreamingStatus(null);
      }
      _backgroundGeneratingConversationId = null;
      _sendMessageOriginId = null;
      notifyListeners();
    }
  }

  /// Delete a single message from the current conversation.
  Future<void> deleteSingleMessage(String messageId) async {
    if (_currentConversation == null) return;

    final idx = _currentMessages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    await _databaseService.deleteMessage(messageId);
    _currentMessages.removeAt(idx);
    notifyListeners();
  }

  /// Auto-generate an image when the AI provides an imagePrompt and auto-generate is enabled.
  Future<void> _autoGenerateImage(
      ChatMessage message, AppSettings baseSettings) async {
    final prompt = message.imagePrompt?.trim() ?? '';
    if (prompt.isEmpty) return;
    await generateImageForMessage(
      message: message,
      baseSettings: baseSettings,
      prompt: prompt,
      deferForVoice: true,
      settingsProvider: _activeSettingsProvider,
    );
  }

  /// Generate an image for [message] and keep the job on this provider.
  ///
  /// Progress survives sending another chat turn, scrolling the bubble off
  /// screen, or leaving the conversation. The finished image is always
  /// written to the database by message id — not only when that chat is open.
  /// A second Generate queues behind the current ComfyUI/A1111 job instead of
  /// interrupting it, and new files are appended so earlier images stay.
  Future<void> generateImageForMessage({
    required ChatMessage message,
    required AppSettings baseSettings,
    required String prompt,
    bool deferForVoice = false,
    SettingsProvider? settingsProvider,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;
    if (isImageGeneratingFor(message.id)) return;

    final settings = settingsForImageGeneration(baseSettings, message: message);
    try {
      await ensureImageBackendReachable(settings);
    } catch (e) {
      reportImageGenerationFailure(e);
      return;
    }

    _imageGenQueue.add(_ImageGenJob(
      id: ++_imageGenSeq,
      messageId: message.id,
      settings: settings,
      prompt: trimmed,
      deferForVoice: deferForVoice,
      settingsProvider: settingsProvider ?? _activeSettingsProvider,
    ));
    notifyListeners();
    await _pumpImageGenQueue();
  }

  Future<void> _pumpImageGenQueue() async {
    if (_imageGenPumping) return;
    _imageGenPumping = true;
    try {
      while (_imageGenQueue.isNotEmpty) {
        final job = _imageGenQueue.removeAt(0);
        if (job.cancelled) continue;
        await _runImageGenJob(job);
      }
    } finally {
      _imageGenPumping = false;
      if (_imageGenQueue.isNotEmpty) {
        unawaited(_pumpImageGenQueue());
      }
    }
  }

  Future<void> _selectSavedComfyWorkflow(
    SettingsProvider? settingsProvider,
    AppSettings ranWith,
    String info,
  ) async {
    if (ranWith.imageGenProvider != 'comfyui') return;
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(info);
      if (decoded is! Map) return;
      data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }
    final saved = data['saved_workflow_path']?.toString().trim() ?? '';
    final error = data['saved_workflow_error']?.toString().trim() ?? '';
    if (saved.isEmpty) {
      if (error.isNotEmpty) {
        _error = error.length > 180
            ? '${error.substring(0, 177).trimRight()}…'
            : error;
        _errorDetail = error;
        notifyListeners();
      }
      return;
    }
    final sp = settingsProvider ?? _activeSettingsProvider;
    if (sp == null) return;
    final live = sp.settings;
    final ranKey = comfyWorkflowSettingsKey(
      ranWith.comfyUiWorkflowPath,
      ranWith.comfyUiWorkflowJson,
    );
    final keepLoaded = live.comfyUiControlsLoadedFrom == ranKey;
    if (live.comfyUiWorkflowPath == saved &&
        (live.comfyUiWorkflowJson == null ||
            live.comfyUiWorkflowJson!.isEmpty) &&
        (!keepLoaded || live.comfyUiControlsLoadedFrom == saved)) {
      return;
    }
    await sp.updateSettings(
      keepLoaded
          ? live.copyWith(
              comfyUiWorkflowPath: saved,
              comfyUiWorkflowJson: null,
              comfyUiControlsLoadedFrom: saved,
            )
          : live.copyWith(
              comfyUiWorkflowPath: saved,
              comfyUiWorkflowJson: null,
            ),
    );
  }

  Future<void> _runImageGenJob(_ImageGenJob job) async {
    if (job.cancelled) return;
    final settings = job.settings;
    _imageGenSettings = settings;
    _imageGenJob = job;
    notifyListeners();

    try {
      await _beginGenerationSession(settings, kind: kLiveActivityKindImage);
      if (job.cancelled) return;
      if (job.deferForVoice && _voiceModeActive) {
        await Future.delayed(const Duration(seconds: 2));
        if (job.cancelled) return;
      }

      final params = Txt2ImgParams(
        prompt: job.prompt,
        negativePrompt: settings.effectiveImageGenNegativePrompt,
        steps: settings.imageGenSteps,
        cfgScale: settings.imageGenCfgScale,
        width: settings.imageGenWidth,
        height: settings.imageGenHeight,
        samplerName: settings.imageGenSamplerName,
        scheduler: settings.imageGenScheduler,
        seed: settings.imageGenSeed,
        batchSize: settings.imageGenBatchSize,
        enableHr: settings.imageGenEnableHr,
        hrScale: settings.imageGenHrScale,
        hrUpscaler: settings.imageGenHrUpscaler,
        denoisingStrength: settings.imageGenDenoisingStrength,
        restoreFaces: settings.imageGenRestoreFaces,
        tiling: settings.imageGenTiling,
        loraName: settings.comfyUiLoraName,
        loraWeight: settings.comfyUiLoraWeight,
      );

      debugPrint('🎨 [IMG] Generating with seed=${settings.imageGenSeed} '
          'comfyWorkflow=${settings.comfyUiWorkflowPath ?? "(global/default)"} '
          'provider=${settings.imageGenProvider}');

      final result = await generateImageForSettings(
        settings: settings,
        params: params,
        onProgress: (p) {
          if (_imageGenJob != job || job.cancelled) return;
          job.progress = p.progress;
          _liveActivityService.updateImageProgress(p.progress);
          notifyListeners();
        },
      );
      if (job.cancelled) return;

      await _selectSavedComfyWorkflow(
        job.settingsProvider,
        settings,
        result.info,
      );
      final paths = await ImageGenerationService()
          .saveImages(result.allImages, job.messageId);
      if (job.cancelled) return;
      await attachGeneratedImagesToMessage(
        messageId: job.messageId,
        paths: paths,
        info: result.info,
      );
    } on ImageGenerationCancelled {
      debugPrint('🎨 [IMG] cancelled');
    } catch (e) {
      debugPrint('⚠️ Image generation failed: $e');
      reportImageGenerationFailure(e);
    } finally {
      if (_imageGenJob == job) {
        _imageGenJob = null;
        _imageGenSettings = null;
        _endLiveActivity();
        notifyListeners();
      }
    }
  }

  Future<void> cancelImageGeneration({String? messageId}) async {
    final id = messageId ?? _imageGenJob?.messageId;
    if (id == null) return;
    _imageGenQueue.removeWhere((j) => j.messageId == id);
    final running = _imageGenJob;
    if (running != null && running.messageId == id) {
      running.cancelled = true;
      final settings = _imageGenSettings;
      if (settings != null) {
        try {
          await interruptBackend(settings);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /// Persist generated images by message id even if that chat is not open.
  Future<void> attachGeneratedImagesToMessage({
    required String messageId,
    required List<String> paths,
    String? info,
  }) async {
    if (paths.isEmpty) return;
    final existing = await _existingGeneratedImagePaths(messageId);
    final merged = [...existing];
    for (final path in paths) {
      if (path.isNotEmpty && !merged.contains(path)) merged.add(path);
    }
    await _databaseService.updateMessageGeneratedImages(
      messageId: messageId,
      paths: merged,
      info: info,
    );
    final idx = _currentMessages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      _currentMessages[idx] = _currentMessages[idx].copyWith(
        generatedImagePath: merged.first,
        generatedImagePaths: merged,
        generatedImageInfo: info,
      );
    }
    notifyListeners();
  }

  /// Remove generated files from disk and unlink them from messages.
  Future<int> deleteGeneratedLibraryItems(
      List<GeneratedImageLibraryItem> items) async {
    final n = await GeneratedImageLibraryService(database: _databaseService)
        .deleteItems(items);
    _currentMessages = applyGeneratedImageDeletes(_currentMessages, items);
    notifyListeners();
    return n;
  }

  Future<List<String>> _existingGeneratedImagePaths(String messageId) async {
    final idx = _currentMessages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      return List<String>.from(_currentMessages[idx].allGeneratedImagePaths);
    }
    return _databaseService.getGeneratedImagePaths(messageId);
  }

  /// Update a message in-place (e.g. after image generation sets generatedImagePath).
  Future<void> updateMessageInPlace(ChatMessage updated) async {
    await _databaseService.updateMessage(updated);
    final idx = _currentMessages.indexWhere((m) => m.id == updated.id);
    if (idx >= 0) {
      _currentMessages[idx] = updated;
      notifyListeners();
    }
  }

  /// Ensures a conversation exists for a transcription job without clearing
  /// the current chat. Creates one only when there is no open conversation.
  ///
  /// Promotes empty drafts into listed chats (clears `isDraft`) so a
  /// transcription started as the first action appears in the home list.
  Future<String?> ensureTranscriptionConversation({
    required String jobId,
    String? suggestedTitle,
  }) async {
    if (_currentConversation == null) {
      await createNewConversation(title: suggestedTitle ?? 'New Chat');
    }
    if (_currentConversation == null) return null;

    final isEmpty = _currentMessages.isEmpty;
    final currentTitle = _currentConversation!.title;
    final shouldSetTitle = isEmpty &&
        suggestedTitle != null &&
        (currentTitle == 'New Chat' ||
            currentTitle.startsWith('Transcription:'));

    final nextSettings = Map<String, dynamic>.from(
      _currentConversation!.settings,
    )
      ..remove('isDraft')
      ..['isTranscriptionChat'] = true
      ..['hasTranscriptions'] = true
      ..['transcriptionJobId'] = jobId;

    final conv = _currentConversation!.copyWith(
      title: shouldSetTitle ? suggestedTitle : currentTitle,
      settings: nextSettings,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(conv);
    _currentConversation = conv;
    final idx = _conversations.indexWhere((c) => c.id == conv.id);
    if (idx >= 0) _conversations.removeAt(idx);
    _conversations.insert(0, conv);
    unawaited(WidgetDataService.updateRecentConversations(listedConversations));
    notifyListeners();
    return conv.id;
  }

  /// Creates or updates a transcription job entry on the current conversation
  /// (audio path, options, status). Used when a job starts and when it finishes.
  Future<void> upsertTranscriptionJobMeta({
    required String jobId,
    required String title,
    String? audioPath,
    Map<String, dynamic>? options,
    String status = 'running',
    int? durationMs,
    String? plainText,
    String? srtText,
  }) async {
    if (_currentConversation == null) return;
    final entries = _readTranscriptionEntries();
    final idx = entries.indexWhere((e) => e['jobId']?.toString() == jobId);
    final existing = idx >= 0
        ? Map<String, dynamic>.from(entries[idx])
        : <String, dynamic>{};
    final merged = <String, dynamic>{
      ...existing,
      'jobId': jobId,
      'title': title,
      'status': status,
      if (audioPath != null) 'audioPath': audioPath,
      if (options != null) 'options': options,
      if (durationMs != null) 'durationMs': durationMs,
      if (plainText != null) 'plainText': plainText,
      if (srtText != null) 'srtText': srtText,
    };
    if (idx >= 0) {
      entries[idx] = merged;
    } else {
      entries.add(merged);
    }
    await patchCurrentConversationSettings({
      'isTranscriptionChat': true,
      'hasTranscriptions': true,
      'transcriptions': entries,
      'transcriptionJobId': jobId,
      'transcriptionTitle': title,
      if (plainText != null) 'transcriptionPlainText': plainText,
      if (srtText != null) 'transcriptionSrtText': srtText,
    });
  }

  /// Appends (or replaces) a completed transcript on the current conversation.
  Future<void> appendTranscriptionResult({
    required String jobId,
    required String title,
    required String plainText,
    String? srtText,
    String? audioPath,
    Map<String, dynamic>? options,
    int? durationMs,
    String status = 'complete',
  }) async {
    if (_currentConversation == null) return;
    await upsertTranscriptionJobMeta(
      jobId: jobId,
      title: title,
      audioPath: audioPath,
      options: options,
      status: status,
      durationMs: durationMs,
      plainText: plainText,
      srtText: srtText,
    );
    if (status != 'complete' || plainText.trim().isEmpty) return;
    final base = _activeSettingsProvider?.settings;
    if (base != null) {
      _maybeWarnTranscriptionContext(getEffectiveSettings(base));
    } else {
      final budgetChars =
          (OnDeviceLLMService.onDeviceContextCap * 4 * 0.45).round();
      if (_transcriptionPlainCharCount() > budgetChars) {
        _pendingToast = ChatToast.transcriptionContextLarge;
      }
    }
    if (_pendingToast == ChatToast.transcriptionContextLarge) {
      notifyListeners();
    }
  }

  Future<void> appendMessagesToCurrent(List<ChatMessage> messages) async {
    if (_currentConversation == null) return;
    for (final msg in messages) {
      await _databaseService.insertMessage(msg, _currentConversation!.id);
      _currentMessages.add(msg);
    }
    // Transcription (and similar) can be the first content in a draft chat —
    // promote it so it shows in the home list.
    await _clearDraftFlagIfNeeded(_currentConversation!.id);
    if (_currentConversation == null) return;
    final conv = _currentConversation!.copyWith(
      updatedAt: DateTime.now(),
      messageIds: _currentMessages.map((m) => m.id).toList(),
    );
    await _databaseService.updateConversation(conv);
    _currentConversation = conv;
    final idx = _conversations.indexWhere((c) => c.id == conv.id);
    if (idx >= 0) _conversations[idx] = conv;
    notifyListeners();
  }

  Future<void> patchCurrentConversationSettings(
      Map<String, dynamic> patch) async {
    if (_currentConversation == null) return;
    final conv = _currentConversation!.copyWith(
      settings: {..._currentConversation!.settings, ...patch},
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateConversation(conv);
    _currentConversation = conv;
    notifyListeners();
  }

  /// One automatic retry when high thinking filled the output cap.
  /// Returns settings with reasoning forced to `low`, or null to keep going.
  AppSettings? _lowThinkingRetrySettings({
    required AppSettings settings,
    required bool alreadyRetried,
    required Map<String, dynamic>? stats,
    required bool answerEmpty,
    required bool hadReasoning,
  }) {
    if (alreadyRetried) return null;
    if (!ThinkingBudget.shouldRetryWithLowEffort(
      reasoning: settings.reasoning,
      stats: stats,
      maxTokens: settings.maxTokens,
      answerEmpty: answerEmpty,
      hadReasoning: hadReasoning,
    )) {
      return null;
    }
    final nextEffort = ThinkingBudget.retryEffort(
      settings.reasoning,
      ReasoningSupportService.instance
          .allowedOptionsSync(settings.selectedModel ?? ''),
    );
    if (nextEffort == null || nextEffort == settings.reasoning) return null;
    debugPrint(
        '🔄 Thinking filled max output (${settings.maxTokens}) — retrying with $nextEffort effort');
    _thinkingBudgetNotice = true;
    _setStreamingStatus('Retrying with low thinking...');
    notifyListeners();
    return settings.copyWith(reasoning: nextEffort);
  }

  /// Retry a 400 on `reasoning`: remap to a value the model lists, or omit
  /// the field when it has no reasoning API. Does not change the user's saved
  /// Off/On preference.
  Future<AppSettings> _prepareReasoningConfigRetry(
    AppSettings settings,
    dynamic error,
  ) async {
    final mapped = ReasoningSupportService.retryApiValue(
      settings.reasoning,
      error,
    );
    if (mapped != null) {
      final supported = ReasoningSupportService.parseSupportedSettings(error);
      if (ReasoningSupportService.isOnOffOnlyList(supported)) {
        await ReasoningSupportService.instance
            .markOnOffOnly(settings.selectedModel ?? '');
      }
      debugPrint(
          '🔄 Reasoning retry: ${settings.reasoning} → $mapped (${ReasoningSupportService.extractMessage(error)})');
      _setStreamingStatus('Retrying with supported reasoning setting...');
      notifyListeners();
      return settings.copyWith(reasoning: mapped);
    }
    final modelId = settings.selectedModel ?? '';
    await ReasoningSupportService.instance.markUnsupported(modelId);
    _pendingToast = ChatToast.reasoningUnsupported;
    _setStreamingStatus('Retrying without reasoning parameter...');
    notifyListeners();
    return settings;
  }
}

class _ImageGenJob {
  _ImageGenJob({
    required this.id,
    required this.messageId,
    required this.settings,
    required this.prompt,
    this.deferForVoice = false,
    this.settingsProvider,
  });

  final int id;
  final String messageId;
  final AppSettings settings;
  final String prompt;
  final bool deferForVoice;
  final SettingsProvider? settingsProvider;
  double progress = 0;
  bool cancelled = false;
}

/// Internal signal to retry a stateful chat without the reasoning parameter.
class _ReasoningConfigRetry implements Exception {}

/// High thinking filled the output cap. Retry the same turn at low effort.
class _LowThinkingRetry implements Exception {}

/// Internal signal to retry V1 chat after LM Studio dropped previous_response_id.
class _StalePreviousResponseRetry implements Exception {}

/// Internal signal to retry the same backend without a tools array.
class _RetryWithoutTools implements Exception {}

/// LM Studio rejected a model id that this turn had already started.
class _TransientModelRetry implements Exception {}
