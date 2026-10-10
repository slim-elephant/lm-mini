import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/param_preset.dart';
import '../models/local_model_spec.dart';
import '../models/lm_studio_model.dart';
import '../models/model_download_job.dart';
import '../models/server_profile.dart';
import '../utils/tts_language_catalog.dart';
import '../services/kokoro_model_manager.dart';
import '../services/whisper_model_manager.dart';
import '../services/whisper_stt_service.dart';
import '../services/whisper_file_transcriber.dart';
import '../services/local_model_download_service.dart';
import '../services/local_sd_asset_download_service.dart';
import '../services/model_download_service.dart';
import '../services/on_device_llm_service.dart';
import '../services/reasoning_support_service.dart';
import '../models/system_prompt.dart';
import '../services/lm_studio_service.dart';
import '../services/ollama_service.dart';
import '../services/server_profile_service.dart';
import '../services/settings_service.dart';
import '../services/remote_access_service.dart';
import '../services/usb_bridge_service.dart';
import '../utils/connect_host_error.dart';
import '../utils/lm_studio_download_cancel.dart';
import '../utils/image_picker_helper.dart';
import '../utils/app_navigator.dart';
import '../utils/remote_host_backends.dart';
import '../utils/server_reachability.dart';
import '../utils/network_preflight_error.dart';
import '../utils/connection_issue.dart';
import '../services/network_status_service.dart';
import '../utils/server_model_memory.dart';
import '../utils/param_preset_key.dart';
import '../utils/unsloth_load.dart';
import '../utils/param_preset_resolver.dart';
import '../models/model_load_config.dart';
import '../widgets/model_load_params_conflict_dialog.dart';
import '../widgets/reload_model_for_context_dialog.dart';
import '../l10n/app_localizations.dart';
import '../services/widget_data_service.dart';
import '../services/home_sync_service.dart';
import '../services/siri_intent_bridge.dart';
import '../services/builtin_persona_service.dart';
import '../services/download_progress_activity.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

part '../pro/remote_access/settings_provider_remote.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = AppSettings();
  List<LMStudioModel> _availableModels = [];
  bool _isLoadingModels = false;
  bool _isTestingConnection = false;
  String? _connectionError;
  bool _hasAttemptedConnection = false;
  bool _showSupportSection = false;

  /// The model id currently being loaded (null when idle).
  String? _loadingModelId;
  String? get loadingModelId => _loadingModelId;

  /// Models for which chat should omit `context_length` / load params so LM
  /// Studio keeps its already-loaded instance settings.
  final Set<String> _useLoadedParamsInChat = {};

  /// In-flight `/models/load` calls keyed by model id — coalesce concurrent loads
  /// so voice/chat cannot spawn `:2` / `:3` instances of the same model.
  final Map<String, Future<bool>> _loadInFlight = {};

  /// Guard so releasing the context slider cannot stack reload dialogs.
  bool _reloadContextPromptInFlight = false;

  /// Unsloth context Mini already applied, or the user declined reloading.
  String? _unslothAppliedContextKey;
  String? _unslothDeclinedContextKey;

  // Download tracking
  String? _downloadJobId;
  Map<String, dynamic>? _downloadStatus;
  bool _isDownloading = false;
  Future<bool>? _lmStudioCancelInFlight;
  String? _downloadModelLabel;
  Offset _fabPosition = const Offset(0, 0);

  final LMStudioService _lmStudioService = LMStudioService();
  final SettingsService _settingsService = SettingsService();
  StreamSubscription<RemoteConnectionStatus>? _healthSubscription;
  int _consecutiveHealthFailures = 0;
  bool _remoteHealthPausedForBackground = false;
  StreamSubscription<bool>? _usbConnectionSubscription;
  bool _lastKnownPremium = false;
  VoidCallback? _subscriptionListener;

  AppSettings get settings => _settings;
  List<LMStudioModel> get availableModels => _availableModels;
  List<LMStudioModel> get chatAvailableModels =>
      _availableModels.where((m) => !m.isEmbedding).toList();
  List<LMStudioModel> get embeddingAvailableModels =>
      _availableModels.where((m) => m.isEmbedding).toList();
  bool get isLoadingModels => _isLoadingModels;
  bool get isTestingConnection => _isTestingConnection;
  String? get connectionError => _connectionError;
  bool get hasAttemptedConnection => _hasAttemptedConnection;
  bool get showSupportSection => _showSupportSection;

  /// The single issue Settings / launch popups should explain for the
  /// global provider (same rules as the chat banner). [error] defaults to
  /// [connectionError].
  ConnectionIssue? resolveGlobalConnectionIssue({String? error}) {
    final kind = _settings.activeProviderKind;
    final isCloud = isCloudProviderKind(kind);
    final cp = isCloud ? resolveCloudProvider() : null;
    final target = cp == null
        ? _settings
        : _settings.copyWith(serverUrl: cp.effectiveBaseUrl);
    return resolveConnectionIssue(
      settings: target,
      net: NetworkStatusService.instance.snapshot,
      providerName: kind == 'cloud'
          ? (cp?.type.displayName ?? 'the server')
          : RemoteHostBackends.displayName(kind),
      connectionError: error ?? _connectionError,
      localAccessProven: ServerReachability.hasEverReachedLocalHost,
    );
  }

  /// Dismiss the chat/settings connection error banner.
  void clearConnectionError() {
    if (_connectionError == null) return;
    _connectionError = null;
    notifyListeners();
  }

  String _friendlyConnectionError(Object e) {
    return ConnectHostError.userMessageFor(
          e,
          serverUrl: _settings.serverUrl,
          isRemoteActive: _settings.isRemoteActive,
          usbModeEnabled: _settings.usbModeEnabled,
        ) ??
        e.toString();
  }

  /// Whether [kind] routes requests through [CloudApiService] (incl. oMLX/Ollama/Jan).
  static bool isCloudProviderKind(String kind) =>
      kind == 'cloud' || CloudApiType.isFreeLocalKind(kind);

  /// Resolves the configured cloud/Ollama/oMLX provider for
  /// [AppSettings.activeProviderKind]. Prefers the active provider when it
  /// matches the selected kind; otherwise falls back to the saved entry.
  CloudApiProvider? resolveCloudProvider([CloudApiService? cloud]) {
    cloud ??= CloudApiService();
    final kind = _settings.activeProviderKind;
    if (!isCloudProviderKind(kind)) return null;

    bool allowed(CloudApiProvider p) =>
        !p.type.isPremium || SubscriptionService().isPremium;

    final active = cloud.activeProvider;
    if (active != null && allowed(active)) {
      final activeKind = active.type.providerKind;
      if (activeKind == kind) return active;
    }

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

  /// True when a cloud/oMLX/Ollama provider is active and allowed.
  /// Free local OpenAI-compatible types work without Pro; paid cloud APIs require Pro.
  bool isCloudProviderReady([CloudApiService? cloud]) {
    if (!isCloudProviderKind(_settings.activeProviderKind)) return false;
    return resolveCloudProvider(cloud) != null;
  }

  /// Whether the user's selected provider has minimum configuration saved.
  bool isProviderConfigured() {
    final kind = _settings.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return true;
    }
    if (isCloudProviderKind(kind)) {
      return isCloudProviderReady();
    }
    if (_settings.isRemoteActive &&
        (_settings.remoteServerUrl?.isNotEmpty ?? false)) {
      return true;
    }
    return _settings.serverUrl.isNotEmpty;
  }

  /// No provider credentials/server URL saved yet — show the setup popup.
  bool get needsSetup => !isProviderConfigured();

  /// LAN/base URL of the active chat backend (LM Studio, Ollama, …).
  /// Null for on-device, USB, or Share with phone relay.
  String? lanChatBaseUrl() {
    final kind = _settings.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return null;
    }
    if (_settings.isRemoteActive || _settings.usbModeEnabled) return null;
    if (kind == 'lmStudio') {
      final url = _settings.serverUrl.trim();
      return url.isEmpty ? null : url;
    }
    final base = resolveCloudProvider()?.baseUrl?.trim();
    if (base == null || base.isEmpty) return null;
    return base;
  }

  /// Provider is configured but the last connection/model fetch failed.
  bool get needsConnectionHelp =>
      isProviderConfigured() && _connectionError != null;

  /// Skipped onboarding / dead default LM Studio with no on-device model —
  /// show the friendly get-started dialog instead of a SocketException.
  bool get needsGetStartedGuidance {
    final hasLocalModel =
        LocalModelDownloadService.instance.readyEntries.isNotEmpty;
    if (hasLocalModel) return false;
    if (needsSetup) return true;
    if (!needsConnectionHelp) return false;
    final kind = _settings.activeProviderKind;
    return kind == 'lmStudio' ||
        kind == 'ollama' ||
        kind == 'omlx' ||
        kind == 'jan' ||
        kind == 'unsloth' ||
        kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx';
  }

  // Download getters
  String? get downloadJobId => _downloadJobId;
  Map<String, dynamic>? get downloadStatus => _downloadStatus;
  bool get isDownloading => _isDownloading;
  String? get downloadModelLabel => _downloadModelLabel;
  Offset get fabPosition => _fabPosition;

  // Get the loaded context length for the currently selected model
  int? get selectedModelLoadedContextLength {
    if (_settings.selectedModel == null) return null;

    final selectedModel = _availableModels.firstWhere(
      (model) => model.id == _settings.selectedModel,
      orElse: () => LMStudioModel(
        id: '',
        object: '',
        type: '',
        publisher: '',
        arch: '',
        compatibilityType: '',
        quantization: '',
        state: '',
        maxContextLength: 0,
      ),
    );

    return selectedModel.loadedContextLength;
  }

  /// Aligns [activeProviderKind] with [selectedLocalModelId] so the first chat
  /// turn after picking On-Device + MLX does not route a GGUF file through MLX
  /// (or vice versa). Prefers keeping the user's engine choice when a matching
  /// downloaded model exists; otherwise falls back to the engine that fits the
  /// active model, or auto-selects a ready model.
  ///
  /// When [keepEngineChoice] is true (user tapped the fllama/MLX engine chip),
  /// an incompatible model is cleared instead of flipping the engine away from
  /// what they selected.
  Future<AppSettings> reconcileOnDeviceSelection(
    AppSettings settings, {
    bool keepEngineChoice = false,
  }) async {
    var kind = settings.activeProviderKind;
    if (kind != 'onDeviceGguf' && kind != 'onDeviceMlx') return settings;

    await LocalModelDownloadService.instance.init();
    await ModelDownloadService.instance.init();
    final ready = LocalModelDownloadService.instance.readyEntries;

    var localId = settings.selectedLocalModelId;
    var modelName = settings.selectedModel;

    LocalModelSpec? spec = (localId != null && localId.isNotEmpty)
        ? OnDeviceLLMService.instance.specForSettings(settings)
        : null;

    bool isMlxSpec(LocalModelSpec s) => s.engine == LocalEngine.mlx;

    if (spec != null) {
      final modelIsMlx = isMlxSpec(spec);
      if (kind == 'onDeviceMlx' && !modelIsMlx) {
        final mlxReady =
            ready.where((e) => isMlxSpec(e.spec)).toList(growable: false);
        if (mlxReady.isNotEmpty) {
          localId = mlxReady.first.spec.id;
          modelName = mlxReady.first.spec.displayName;
        } else if (keepEngineChoice) {
          localId = null;
          modelName = '';
        } else {
          kind = 'onDeviceGguf';
        }
      } else if (kind == 'onDeviceGguf' && modelIsMlx) {
        final ggufReady =
            ready.where((e) => !isMlxSpec(e.spec)).toList(growable: false);
        if (ggufReady.isNotEmpty) {
          localId = ggufReady.first.spec.id;
          modelName = ggufReady.first.spec.displayName;
        } else if (keepEngineChoice) {
          localId = null;
          modelName = '';
        } else {
          kind = 'onDeviceMlx';
        }
      }
    } else if (ready.isNotEmpty) {
      if (kind == 'onDeviceMlx') {
        final mlxReady =
            ready.where((e) => isMlxSpec(e.spec)).toList(growable: false);
        if (mlxReady.isNotEmpty) {
          localId = mlxReady.first.spec.id;
          modelName = mlxReady.first.spec.displayName;
        } else {
          kind = 'onDeviceGguf';
          localId = ready.first.spec.id;
          modelName = ready.first.spec.displayName;
        }
      } else {
        final ggufReady =
            ready.where((e) => !isMlxSpec(e.spec)).toList(growable: false);
        if (ggufReady.isNotEmpty) {
          localId = ggufReady.first.spec.id;
          modelName = ggufReady.first.spec.displayName;
        } else {
          kind = 'onDeviceMlx';
          localId = ready.first.spec.id;
          modelName = ready.first.spec.displayName;
        }
      }
    }

    if (kind == settings.activeProviderKind &&
        localId == settings.selectedLocalModelId &&
        modelName == settings.selectedModel) {
      return settings;
    }
    return settings.copyWith(
      activeProviderKind: kind,
      selectedLocalModelId: localId,
      selectedModel: modelName,
    );
  }

  Future<void> _resumeInterruptedDownloads() async {
    final svc = ModelDownloadService.instance;
    void resume(String id, Future<bool> Function() start) {
      final job = svc.job(id);
      if (job?.status == ModelDownloadJobStatus.interrupted) {
        unawaited(start());
      }
    }

    resume(ModelDownloadJobIds.kokoro,
        () => KokoroModelManager().downloadAsset(TtsLanguageCatalog.englishId));
    resume(
        ModelDownloadJobIds.kokoroMulti,
        () =>
            KokoroModelManager().downloadAsset(TtsLanguageCatalog.multiLangId));
    resume(ModelDownloadJobIds.piperDe,
        () => KokoroModelManager().downloadAsset(TtsLanguageCatalog.piperDeId));
    resume(ModelDownloadJobIds.piperRu,
        () => KokoroModelManager().downloadAsset(TtsLanguageCatalog.piperRuId));
    for (final spec in WhisperModelManager.catalog) {
      resume(spec.jobId,
          () => WhisperModelManager.instance.downloadModel(spec.id));
    }
    resume(
      ModelDownloadJobIds.whisperVad,
      () => WhisperModelManager.instance.ensureVadModel(),
    );
    await _resumeLmStudioDownloadIfNeeded();
  }

  static const _lmStudioDownloadJobKey = 'lm_studio_download_job_id';
  static const _lmStudioDownloadLabelKey = 'lm_studio_download_label';

  Future<void> _persistLmStudioDownloadJob() async {
    final prefs = await SharedPreferences.getInstance();
    if (_downloadJobId != null && _downloadJobId!.isNotEmpty) {
      await prefs.setString(_lmStudioDownloadJobKey, _downloadJobId!);
      if (_downloadModelLabel != null) {
        await prefs.setString(_lmStudioDownloadLabelKey, _downloadModelLabel!);
      }
    } else {
      await prefs.remove(_lmStudioDownloadJobKey);
      await prefs.remove(_lmStudioDownloadLabelKey);
    }
  }

  Future<void> _resumeLmStudioDownloadIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final jobId = prefs.getString(_lmStudioDownloadJobKey);
    if (jobId == null || jobId.isEmpty || _isDownloading) return;

    _downloadJobId = jobId;
    _downloadModelLabel = prefs.getString(_lmStudioDownloadLabelKey);
    _isDownloading = true;
    notifyListeners();
    unawaited(DownloadProgressActivity.instance.start(
      displayName: _downloadModelLabel ?? 'Hugging Face',
    ));
    unawaited(_pollDownloadStatus());
  }

  Future<void> _clearLmStudioDownloadJob() async {
    _downloadJobId = null;
    _downloadModelLabel = null;
    await _persistLmStudioDownloadJob();
  }

  /// Persisted settings reconciliation on startup / after provider changes.
  Future<void> _reconcileOnDeviceEngineSelection() async {
    final reconciled = await reconcileOnDeviceSelection(_settings);
    if (reconciled == _settings) return;
    _settings = reconciled;
    await _settingsService.saveSettings(_settings);
  }

  Future<void> loadSettings() async {
    _settings = (await _settingsService.loadSettings()).repairListFields();
    _reconcileContextWindowWithLoad();
    _useLoadedParamsInChat
      ..clear()
      ..addAll(_settings.modelsPreferLoadedParams);

    WhisperModelManager.instance.setSelectedModelId(_settings.whisperModelId);

    // Android-only default: start first-time users on on-device inference.
    // iOS keeps LM Studio as the default provider.
    if (Platform.isAndroid &&
        !_settings.hasCompletedOnboarding &&
        _settings.activeProviderKind == 'lmStudio') {
      _settings = _settings.copyWith(activeProviderKind: 'onDeviceGguf');
      await _settingsService.saveSettings(_settings);
    }

    await _reconcileOnDeviceEngineSelection();

    await ModelDownloadService.instance.init();
    await LocalModelDownloadService.instance.init();
    unawaited(LocalSdAssetDownloadService.instance.init());
    unawaited(_resumeInterruptedDownloads());

    // Preload models that reject LM Studio reasoning controls.
    await ReasoningSupportService.instance
        .isSupported(_settings.selectedModel ?? '');

    // Migrate legacy absolute image paths to relative paths.
    // On iOS, the app sandbox UUID changes between updates, so
    // absolute paths become stale. Relative paths survive updates.
    _migrateImagePathsToRelative();

    // Ship built-in Mini persona (once per install).
    final withBuiltin = await BuiltinPersonaService.ensureSeeded(_settings);
    if (!identical(withBuiltin, _settings)) {
      _settings = withBuiltin;
      await _settingsService.saveSettings(_settings);
    }

    // Sync remote auth token to LMStudioService
    _syncRemoteAuthToken();

    // Verify or restore remote LM Connect on startup (same path as foreground resume).
    if (_settings.remoteServerUrl != null &&
        _settings.remoteAuthToken != null &&
        (_settings.isRemoteActive || _settings.remoteAutoReconnect)) {
      unawaited(onAppResumed());
    }

    // If USB Mode was previously enabled, bring the in-process bridge back up
    // and ensure serverUrl points at it. Best-effort — failure logs and skips.
    if (_settings.usbModeEnabled) {
      try {
        await UsbBridgeService.instance.start();
        if (_settings.serverUrl != UsbBridgeService.baseUrl) {
          _settings = _settings.copyWith(serverUrl: UsbBridgeService.baseUrl);
        }
        _listenToUsbConnection();
      } catch (e) {
        debugPrint('SettingsProvider: USB bridge auto-start failed: $e');
        _settings = _settings.copyWith(
          usbModeEnabled: false,
          serverUrl: _settings.savedLocalServerUrl ?? _settings.serverUrl,
        );
        await _settingsService.saveSettings(_settings);
      }
    }

    // Check if user has used the app for at least 7 days
    _showSupportSection = await _settingsService.hasUsedAppForDays(7);

    // Push initial personas to native widget bridge
    WidgetDataService.updatePersonas(_settings.savedSystemPrompts ?? []);

    // Load saved cloud credentials before premium restore / readiness checks.
    await CloudApiService().load();
    await ServerProfileService.instance.load(
      settings: _settings,
      cloud: CloudApiService(),
    );
    if (!SubscriptionService().isInitialized) {
      await SubscriptionService().initialize();
    }

    _attachSubscriptionListener();

    // If user lost premium, revert cloud model → saved LM Studio model
    await restoreLocalModelIfNeeded();

    unawaited(SiriIntentBridge.syncFromSettings(
      _settings,
      cloud: resolveCloudProvider(),
    ));

    notifyListeners();

    final providerKind = _settings.activeProviderKind;
    final isOnDevice = providerKind == 'onDeviceGguf' ||
        providerKind == 'onDeviceMlx' ||
        providerKind == 'appleIntelligence';

    if (isOnDevice) {
      // On-device provider doesn't talk to any HTTP server. Skip the
      // LM Studio fetch entirely so we never surface a misleading
      // "Cannot connect to LM Studio" banner.
      _connectionError = null;
      _hasAttemptedConnection = true;
      notifyListeners();
    } else if (isCloudProviderKind(providerKind)) {
      _hasAttemptedConnection = true;
      if (isCloudProviderReady()) {
        unawaited(_loadModelsAfterStartup());
      } else {
        _connectionError = 'No cloud provider configured';
        notifyListeners();
      }
    } else if (_settings.serverUrl.isNotEmpty ||
        (_settings.isRemoteActive &&
            (_settings.remoteServerUrl?.isNotEmpty ?? false))) {
      // Do network model fetch in the background so app theme/settings apply
      // immediately on startup even when server connection is slow.
      unawaited(_loadModelsAfterStartup());
    } else {
      _connectionError = 'No server URL configured';
      _hasAttemptedConnection = true;
      notifyListeners();
    }
  }

  Future<void> _loadModelsAfterStartup() async {
    try {
      await loadAvailableModels();
    } catch (e) {
      _hasAttemptedConnection = true;
    }
    notifyListeners();
  }

  /// Deactivates paid cloud providers and restores the LM Studio model when
  /// premium is lost. Free local providers ([CloudApiType.omlx], [CloudApiType.ollama],
  /// [CloudApiType.jan], [CloudApiType.unsloth]) stay active.
  Future<void> restoreLocalModelIfNeeded() async {
    if (SubscriptionService().isPremium) return;

    final cloud = CloudApiService();
    final active = cloud.activeProvider;

    if (active != null && active.type.isPremium) {
      await cloud.setActiveProvider(null);
    }

    // Only revert the paid `'cloud'` umbrella kind — not ollama/omlx/lmStudio.
    if (_settings.activeProviderKind != 'cloud') return;

    final prefs = await SharedPreferences.getInstance();
    final savedLocal = prefs.getString('saved_local_model');
    _settings = _settings.copyWith(
      activeProviderKind: 'lmStudio',
      selectedModel: savedLocal ?? _settings.selectedModel,
    );
    await _settingsService.saveSettings(_settings);
    if (savedLocal != null) {
      await prefs.remove('saved_local_model');
    }
    notifyListeners();
  }

  // Refresh models to get updated loaded_context_length
  Future<void> refreshModels() async {
    if (_settings.serverUrl.isEmpty) return;

    try {
      _availableModels = await _lmStudioService.getAvailableModels(
        baseUrl: _settings.serverUrl,
        apiToken: _settings.apiToken,
      );
      ReasoningSupportService.instance.ingestCatalog(_availableModels);
      _connectionError = null;
      notifyListeners();
    } catch (e) {
      _connectionError = _friendlyConnectionError(e);
    }
  }

  Future<void> updateSettings(
    AppSettings newSettings, {
    bool keepOnDeviceEngineChoice = false,
  }) async {
    final previousKind = _settings.activeProviderKind;
    final fromKey = ServerModelMemory.keyFor(_settings);
    final fromModel = _settings.selectedModel;
    _settings = newSettings;
    if (_settings.activeProviderKind == 'onDeviceGguf' ||
        _settings.activeProviderKind == 'onDeviceMlx') {
      _settings = await reconcileOnDeviceSelection(
        _settings,
        keepEngineChoice: keepOnDeviceEngineChoice,
      );
    }
    // Re-sync any service-side header state that depends on settings.
    _lmStudioService.customHeaders = _settings.effectiveExtraHeaders;
    final toKey = ServerModelMemory.keyFor(_settings);
    if (toKey != fromKey) {
      _rememberSelectedModel(key: fromKey, modelId: fromModel);
      final explicit = newSettings.selectedModel != fromModel
          ? newSettings.selectedModel
          : null;
      _restoreSelectedModel(toKey, fallback: explicit);
    }
    await _settingsService.saveSettings(_settings);
    unawaited(SiriIntentBridge.syncFromSettings(
      _settings,
      cloud: resolveCloudProvider(),
    ));

    // Clear stale LM Studio connection errors when switching to a provider
    // that doesn't depend on the LM Studio HTTP endpoint.
    final newKind = _settings.activeProviderKind;
    if (newKind != previousKind &&
        (newKind == 'onDeviceGguf' ||
            newKind == 'onDeviceMlx' ||
            newKind == 'appleIntelligence')) {
      _connectionError = null;
    }
    notifyListeners();
  }

  Future<void> loadAvailableModels({bool silent = false}) async {
    final providerKind = _settings.activeProviderKind;
    final isOnDevice = providerKind == 'onDeviceGguf' ||
        providerKind == 'onDeviceMlx' ||
        providerKind == 'appleIntelligence';
    if (isOnDevice) {
      // On-device engines don't expose a model-listing HTTP endpoint.
      // The local-models browser owns the catalog; clear any stale
      // connection error so banners don't appear in the chat UI.
      _availableModels = [];
      _connectionError = null;
      _isLoadingModels = false;
      notifyListeners();
      return;
    }

    // Silent refresh keeps the existing list visible (e.g. opening Model
    // Management) instead of flashing a full-screen loading state.
    final showLoading = !silent || _availableModels.isEmpty;
    if (showLoading) {
      _isLoadingModels = true;
    }
    _connectionError = null;
    notifyListeners();

    // Offline / mobile data with a home-LAN server / host down: say so in
    // seconds instead of waiting ~60 s for the OS connect timeout.
    final blocked = await _modelListPreflight(providerKind);
    if (blocked != null) {
      _connectionError = blocked;
      _availableModels = [];
      _isLoadingModels = false;
      notifyListeners();
      return;
    }

    try {
      final cloud = CloudApiService();
      if (isCloudProviderKind(providerKind)) {
        final cp = resolveCloudProvider(cloud);
        if (cp == null) {
          _connectionError =
              'No ${_settings.activeProviderKind} provider configured';
          _availableModels = [];
        } else {
          if (cloud.activeProviderId != cp.id) {
            await cloud.setActiveProvider(cp.id);
          }
          final cloudModels = await cloud.fetchModelsDetailed(cp);
          // Unsloth's catalog is every downloaded model. Only the one
          // reported by /api/inference/status is actually in memory.
          // Marking the whole catalog loaded built a banner tall enough
          // to push the list off the screen.
          Map<String, dynamic>? unslothStatus;
          if (cp.type == CloudApiType.unsloth) {
            try {
              unslothStatus =
                  await _lmStudioService.fetchUnslothInferenceStatus(
                baseUrl: cp.effectiveBaseUrl,
                apiToken: cp.apiKey.trim().isEmpty ? null : cp.apiKey,
              );
            } catch (e) {
              debugPrint('Unsloth status during model list: $e');
            }
          }
          _availableModels = cloudModels.map((info) {
            final quant = cp.type == CloudApiType.unsloth
                ? UnslothLoad.quantFromModelId(info.id)
                : '';
            final unslothLoaded = cp.type == CloudApiType.unsloth &&
                UnslothLoad.catalogModelIsLoaded(unslothStatus, info.id);
            return LMStudioModel(
              id: info.id,
              object: 'model',
              type: LMStudioModel.looksLikeEmbeddingModel(info.id)
                  ? 'embedding'
                  : (info.supportsVision ? 'vlm' : 'llm'),
              publisher: cp.type.displayName,
              arch: '',
              compatibilityType: 'gguf',
              quantization: quant,
              state: cp.type == CloudApiType.unsloth
                  ? (unslothLoaded ? 'loaded' : 'not-loaded')
                  : 'loaded',
              maxContextLength: 128000,
              loadedContextLength: unslothLoaded
                  ? UnslothLoad.loadedContextLength(unslothStatus)
                  : null,
              v1DisplayName:
                  quant.isEmpty ? null : UnslothLoad.modelPath(info.id),
              visionCapability: info.supportsVision,
              toolUseCapability: info.supportsTools,
              capabilities: [
                if (info.supportsTools) 'tool_use',
                if (info.supportsThinking) 'thinking',
              ],
            );
          }).toList();
          _connectionError = null;
        }
      } else {
        // LM Studio local — fetch from local server
        _availableModels = await _lmStudioService.getAvailableModels(
          baseUrl: _settings.serverUrl,
          apiToken: _settings.apiToken,
        );
        ReasoningSupportService.instance.ingestCatalog(_availableModels);
        _connectionError = null;
      }
    } catch (e) {
      _connectionError = _friendlyConnectionError(e);
      _availableModels = [];
      _isLoadingModels = false;
      notifyListeners();
      // Callers use [connectionError], not a thrown exception. Rethrowing
      // turned LAN drops (EBADF, refused) into uncaught platform crashes.
      return;
    }

    _isLoadingModels = false;
    if (_reconcileSelectedModelWithCatalog()) {
      await _settingsService.saveSettings(_settings);
    }
    notifyListeners();
  }

  /// Network check before listing models. Returns a user-facing error, or
  /// null to go ahead. Never throws.
  Future<String?> _modelListPreflight(String providerKind) async {
    try {
      if (_settings.usbModeEnabled) return null;
      final isCloud = isCloudProviderKind(providerKind);
      final cp = isCloud ? resolveCloudProvider() : null;
      final url = (isCloud ? cp?.effectiveBaseUrl : _settings.serverUrl) ?? '';
      if (url.trim().isEmpty) return null;
      final scope =
          _settings.isRemoteActive ? HostScope.public : classifyHost(url);
      if (scope == HostScope.loopback) return null;

      final net = await NetworkStatusService.instance.refresh(
        timeout: const Duration(milliseconds: 800),
      );
      final decision = decide(
        hostScope: scope,
        isOffline: net.isOffline,
        hasLocalNetwork: net.hasLocalNetwork,
        hasVpn: net.hasVpn,
      );
      final name = providerKind == 'cloud'
          ? (cp?.type.displayName ?? 'the server')
          : RemoteHostBackends.displayName(providerKind);
      final host = hostOf(url) ?? url;
      switch (decision) {
        case PreflightDecision.proceed:
          return null;
        case PreflightDecision.blockOffline:
          return NetworkPreflightError.offlineMessage;
        case PreflightDecision.blockNeedsWifi:
          return NetworkPreflightError.needsWifiMessage(name, host);
        case PreflightDecision.probe:
          break;
      }

      var raw = url.trim();
      if (!raw.contains('://')) raw = 'http://$raw';
      final uri = Uri.tryParse(raw);
      if (uri == null || uri.host.isEmpty) return null;
      final result = await ServerReachability.probe(uri);
      if (result == ProbeResult.ok) return null;
      if (scope == HostScope.localNetwork &&
          !net.hasLocalNetwork &&
          net.hasMobile) {
        return NetworkPreflightError.needsWifiMessage(name, host);
      }
      if (result == ProbeResult.timeout &&
          Platform.isIOS &&
          scope != HostScope.public &&
          !ServerReachability.hasEverReachedLocalHost) {
        // First LAN connection may be waiting on the Local Network prompt.
        return null;
      }
      const tag = NetworkPreflightError.detailPrefix;
      final hostPort = '${uri.host}:${portFor(uri)}';
      return _friendlyConnectionError(
        result == ProbeResult.refused
            ? 'SocketException: Connection refused ($tag $hostPort)'
            : 'SocketException: Host is down ($tag $hostPort)',
      );
    } catch (e) {
      debugPrint('Model list preflight skipped: $e');
      return null;
    }
  }

  /// Load a specific model
  ///
  /// Note: LM Studio API doesn't support TTL or automatic unloading.
  /// Models stay loaded until manually unloaded via LM Studio UI or CLI.
  ///
  /// When the model is already loaded with different params than LM Mini's
  /// Model Loading Config, [uiContext] is used to prompt the user (falls back
  /// to [rootNavigatorKey]).
  Future<bool> loadSpecificModel(
    String modelPath, {
    BuildContext? uiContext,
  }) async {
    if (_settings.activeProviderKind == 'unsloth') {
      return _loadUnslothFromSelection(modelPath);
    }

    if (_settings.activeProviderKind == 'lmStudio') {
      try {
        await loadAvailableModels();
      } catch (_) {}
    }

    // Chat/settings may store a short name; the load API needs LM Studio's key.
    final resolved = resolveLmStudioModel(modelPath);
    if (resolved == null) {
      _connectionError =
          'Model "$modelPath" was not found in LM Studio’s downloaded models. '
          'Open Model Management and pick a model that is installed.';
      notifyListeners();
      return false;
    }
    final loadKey = resolved.id;
    if (loadKey != modelPath && _settings.selectedModel == modelPath) {
      // Heal stale short-name selection so later loads/chats use the real key.
      _settings = _settings.copyWith(selectedModel: loadKey);
      _rememberSelectedModel(modelId: loadKey);
      unawaited(_settingsService.saveSettings(_settings));
    }

    if (resolved.isLoaded) {
      if (_useLoadedParamsInChat.contains(loadKey) ||
          _useLoadedParamsInChat.contains(modelPath)) {
        return true;
      }
      final diff = ModelLoadConfigHelper.diffLoadedVsDesired(
          resolved, settingsForModelLoad(loadKey));
      if (diff.hasMismatch) {
        final action = await _promptLoadConfigConflict(
          uiContext,
          model: resolved,
          diff: diff,
        );
        if (action == null) return false;
        return _applyLoadConflictAction(
          action,
          resolved,
          uiContext: uiContext,
        );
      }
      // Already loaded with matching params — nothing to do.
      return true;
    }

    return _loadModelWithMiniConfig(loadKey);
  }

  Map<String, dynamic> buildLoadConfig({String? modelId}) =>
      ModelLoadConfigHelper.buildConfig(settingsForModelLoad(modelId));

  LMStudioModel? findModelById(String modelId) => _findModel(modelId);

  /// Resolve a stored model id / display name to an LM Studio catalog entry.
  ///
  /// Load API requires the model `key` from `/api/v1/models`. Selection can
  /// drift to a short name (e.g. from chat overrides or older settings).
  LMStudioModel? resolveLmStudioModel(String? modelId) {
    if (modelId == null || modelId.isEmpty) return null;
    final exact = _findModel(modelId);
    if (exact != null) return exact;

    final needle = modelId.toLowerCase();
    final needleBase = needle.split('/').last;

    for (final m in _availableModels) {
      final id = m.id.toLowerCase();
      final display = m.displayName.toLowerCase();
      final idBase = id.split('/').last;
      if (display == needle || idBase == needle || idBase == needleBase) {
        return m;
      }
    }
    for (final m in _availableModels) {
      final id = m.id.toLowerCase();
      final display = m.displayName.toLowerCase();
      final idBase = id.split('/').last;
      if (id.endsWith(needle) ||
          needle.endsWith(idBase) ||
          display.contains(needleBase) ||
          needleBase.contains(idBase)) {
        return m;
      }
    }
    return null;
  }

  bool shouldOmitLoadParamsInChat(String modelId) {
    if (modelId.isEmpty) return false;
    if (_useLoadedParamsInChat.contains(modelId)) return true;
    final resolved = resolveLmStudioModel(modelId);
    if (resolved == null) return false;
    if (_useLoadedParamsInChat.contains(resolved.id)) return true;
    // Already in LM Studio memory → reuse that instance (never send
    // context_length that would JIT-load a parallel copy).
    return resolved.isLoaded;
  }

  /// Remember to reuse LM Studio's in-memory instance for [modelId] in chat.
  void preferLoadedParamsForChat(String modelId) {
    final resolved = resolveLmStudioModel(modelId);
    final key = resolved?.id ?? modelId;
    if (key.isEmpty) return;
    if (_useLoadedParamsInChat.contains(key)) return;
    _useLoadedParamsInChat.add(key);
    if (modelId != key) _useLoadedParamsInChat.add(modelId);
    _persistModelsPreferLoadedParams();
  }

  /// Before chatting or auto-loading, resolve load-param conflicts.
  ///
  /// When [reuseLoadedWithoutPrompt] is true (chat / voice send path), an
  /// already-loaded model is always reused — never `POST /models/load`, which
  /// would create parallel `:2` / `:3` instances.
  /// Returns false if the user cancelled.
  Future<bool> prepareModelForLmStudioUse(
    String modelId, {
    BuildContext? uiContext,
    bool refreshModels = true,
    bool reuseLoadedWithoutPrompt = false,
  }) async {
    if (refreshModels && _settings.activeProviderKind == 'lmStudio') {
      try {
        await loadAvailableModels();
      } catch (_) {
        // Proceed with cached list if refresh fails (offline banner elsewhere).
      }
    }

    final model = resolveLmStudioModel(modelId);
    if (model == null || !model.isLoaded) {
      _useLoadedParamsInChat.remove(modelId);
      if (model != null) _useLoadedParamsInChat.remove(model.id);
      _persistModelsPreferLoadedParams();
      return true;
    }

    // Chat/voice: always stick to the instance already in memory.
    if (reuseLoadedWithoutPrompt) {
      preferLoadedParamsForChat(model.id);
      return true;
    }

    if (_useLoadedParamsInChat.contains(modelId) ||
        _useLoadedParamsInChat.contains(model.id)) {
      return true;
    }

    final diff = ModelLoadConfigHelper.diffLoadedVsDesired(
        model, settingsForModelLoad(model.id));
    if (!diff.hasMismatch) {
      preferLoadedParamsForChat(model.id);
      return true;
    }

    final action = await _promptLoadConfigConflict(
      uiContext,
      model: model,
      diff: diff,
    );
    if (action == null) return false;
    return _applyLoadConflictAction(action, model, uiContext: uiContext);
  }

  LMStudioModel? _findModel(String modelId) {
    for (final m in _availableModels) {
      if (m.id == modelId) return m;
    }
    return null;
  }

  Future<ModelLoadConflictAction?> _promptLoadConfigConflict(
    BuildContext? uiContext, {
    required LMStudioModel model,
    required ModelLoadConfigDiff diff,
  }) async {
    final context = uiContext ?? rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint(
          'SettingsProvider: no context for load-param conflict — using LM Studio settings');
      return ModelLoadConflictAction.useExistingLoaded;
    }
    return showModelLoadParamsConflictDialog(
      context,
      model: model,
      diff: diff,
    );
  }

  Future<bool> _applyLoadConflictAction(
    ModelLoadConflictAction action,
    LMStudioModel model, {
    BuildContext? uiContext,
  }) async {
    switch (action) {
      case ModelLoadConflictAction.useExistingLoaded:
        _settings =
            ModelLoadConfigHelper.syncSettingsFromLoadedModel(_settings, model);
        _useLoadedParamsInChat.add(model.id);
        _persistModelsPreferLoadedParams();
        return true;
      case ModelLoadConflictAction.reloadWithMiniParams:
        _useLoadedParamsInChat.remove(model.id);
        _persistModelsPreferLoadedParams();
        await _unloadLmStudioModel(model);
        final still = resolveLmStudioModel(model.id);
        if (still != null && still.isLoaded) {
          await _unloadLmStudioModel(still);
        }
        return _loadModelWithMiniConfig(model.id);
      case ModelLoadConflictAction.loadParallelWithMiniParams:
        _useLoadedParamsInChat.remove(model.id);
        _persistModelsPreferLoadedParams();
        return _loadModelWithMiniConfig(model.id);
    }
  }

  /// Load the selected Unsloth model at Mini's context length when chat
  /// starts, unless that exact load is already active or the user declined it.
  Future<void> ensureUnslothLoadContext(
    AppSettings settings, {
    void Function()? onLoading,
  }) async {
    if (settings.activeProviderKind != 'unsloth') return;
    final modelId = settings.selectedModel?.trim() ?? '';
    if (modelId.isEmpty) return;
    final desired = settings.loadContextLength ?? settings.contextWindow;
    if (desired <= 0) return;
    final key = UnslothLoad.contextKey(modelId, desired);
    if (_unslothDeclinedContextKey == key) return;
    if (_unslothAppliedContextKey == key) return;

    Map<String, dynamic>? status;
    try {
      status = await _lmStudioService.fetchUnslothInferenceStatus(
        baseUrl: settings.serverUrl,
        apiToken: settings.apiToken,
      );
    } catch (e) {
      debugPrint('Unsloth status: $e');
    }
    if (UnslothLoad.alreadyLoaded(status, modelId, desired)) {
      _unslothAppliedContextKey = key;
      return;
    }

    onLoading?.call();
    try {
      await _lmStudioService.loadUnslothModel(
        baseUrl: settings.serverUrl,
        modelId: modelId,
        maxSeqLength: desired,
        apiToken: settings.apiToken,
      );
      _unslothAppliedContextKey = key;
      _unslothDeclinedContextKey = null;
    } catch (e) {
      // Don't block every later message on a load that already failed.
      _unslothAppliedContextKey = key;
      debugPrint('Unsloth load: $e');
    }
  }

  Future<void> _promptUnslothContextReload(BuildContext? uiContext) async {
    if (_reloadContextPromptInFlight) return;
    final modelId = _settings.selectedModel?.trim() ?? '';
    if (modelId.isEmpty) return;
    final desired = _settings.loadContextLength ?? _settings.contextWindow;
    if (desired <= 0) return;
    final cp = resolveCloudProvider();
    if (cp == null || cp.type != CloudApiType.unsloth) return;

    _reloadContextPromptInFlight = true;
    try {
      Map<String, dynamic>? status;
      try {
        status = await _lmStudioService.fetchUnslothInferenceStatus(
          baseUrl: cp.effectiveBaseUrl,
          apiToken: cp.apiKey,
        );
      } catch (e) {
        debugPrint('Unsloth status: $e');
        return;
      }
      final loaded = UnslothLoad.loadedContextLength(status);
      if (loaded == null ||
          loaded == desired ||
          !UnslothLoad.statusIsModel(status, modelId)) {
        return;
      }

      final context = uiContext ?? rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      final model = resolveLmStudioModel(modelId);
      final reload = await showReloadModelForContextDialog(
        context,
        modelName: model?.displayName ?? modelId,
        loadedContextLength: loaded,
        desiredContextLength: desired,
      );
      final key = UnslothLoad.contextKey(modelId, desired);
      if (reload != true) {
        _unslothDeclinedContextKey = key;
        return;
      }

      final overlayContext = rootNavigatorKey.currentContext ?? context;
      var showedProgress = false;
      if (overlayContext.mounted) {
        showedProgress = true;
        showDialog<void>(
          context: overlayContext,
          barrierDismissible: false,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      var ok = false;
      try {
        await _lmStudioService.loadUnslothModel(
          baseUrl: cp.effectiveBaseUrl,
          modelId: modelId,
          maxSeqLength: desired,
          apiToken: cp.apiKey,
        );
        _unslothAppliedContextKey = key;
        _unslothDeclinedContextKey = null;
        ok = true;
      } catch (e) {
        _connectionError = 'Failed to reload model: $e';
        notifyListeners();
      } finally {
        if (showedProgress) {
          final navContext = rootNavigatorKey.currentContext ?? overlayContext;
          if (navContext.mounted) {
            Navigator.of(navContext, rootNavigator: true).pop();
          }
        }
      }

      final snackContext = uiContext ?? rootNavigatorKey.currentContext;
      if (snackContext == null || !snackContext.mounted) return;
      final l10n = AppLocalizations.of(snackContext);
      ScaffoldMessenger.of(snackContext).showSnackBar(
        SnackBar(
          content: Text(ok ? l10n.modelLoadedSuccess : l10n.failedToLoadModel),
        ),
      );
    } finally {
      _reloadContextPromptInFlight = false;
    }
  }

  /// After the user commits a new Context Length, offer to unload & reload
  /// the LM Studio instance so `n_ctx` actually changes.
  ///
  /// "Not now" keeps Mini's setting for the next explicit load. Chat send
  /// still reuses the instance already in memory.
  Future<void> promptReloadIfLoadedContextStale(BuildContext? uiContext) async {
    if (_reloadContextPromptInFlight) return;
    if (_loadingModelId != null) return;
    if (_settings.activeProviderKind == 'unsloth') {
      await _promptUnslothContextReload(uiContext);
      return;
    }
    if (_settings.activeProviderKind != 'lmStudio') return;

    _reloadContextPromptInFlight = true;
    try {
      final modelId = ParamPresetKey.selectedModelId(_settings);
      final model = resolveLmStudioModel(modelId);
      final loadSettings = settingsForModelLoad(model?.id ?? modelId);
      final desired =
          loadSettings.loadContextLength ?? loadSettings.contextWindow;
      if (!ModelLoadConfigHelper.shouldOfferContextReload(
        providerKind: _settings.activeProviderKind,
        model: model,
        desiredContextLength: desired,
      )) {
        return;
      }

      final context = uiContext ?? rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final reload = await showReloadModelForContextDialog(
        context,
        modelName: model!.displayName,
        loadedContextLength: model.loadedContextLength!,
        desiredContextLength: desired,
      );
      if (reload != true) return;

      final overlayContext = rootNavigatorKey.currentContext ?? context;
      var showedProgress = false;
      if (overlayContext.mounted) {
        showedProgress = true;
        showDialog<void>(
          context: overlayContext,
          barrierDismissible: false,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      var ok = false;
      try {
        ok = await _applyLoadConflictAction(
          ModelLoadConflictAction.reloadWithMiniParams,
          model,
          uiContext: overlayContext,
        );
      } catch (e) {
        _connectionError = 'Failed to reload model: $e';
        notifyListeners();
      } finally {
        if (showedProgress) {
          final navContext = rootNavigatorKey.currentContext ?? overlayContext;
          if (navContext.mounted) {
            Navigator.of(navContext, rootNavigator: true).pop();
          }
        }
      }

      final snackContext = uiContext ?? rootNavigatorKey.currentContext;
      if (snackContext == null || !snackContext.mounted) return;
      final l10n = AppLocalizations.of(snackContext);
      ScaffoldMessenger.of(snackContext).showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.modelLoadedSuccess : l10n.failedToLoadModel,
          ),
        ),
      );
    } finally {
      _reloadContextPromptInFlight = false;
    }
  }

  Future<void> _unloadLmStudioModel(LMStudioModel m) async {
    final instanceId = m.loadedInstanceId ?? m.id;
    await _lmStudioService.unloadModel(
      baseUrl: _settings.serverUrl,
      instanceId: instanceId,
      apiToken: _settings.apiToken,
    );
    await loadAvailableModels();
  }

  void _persistModelsPreferLoadedParams() {
    _settings = _settings.copyWith(
      modelsPreferLoadedParams: _useLoadedParamsInChat.toList(),
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void _clearModelsPreferLoadedParams() {
    if (_useLoadedParamsInChat.isEmpty &&
        _settings.modelsPreferLoadedParams.isEmpty) {
      return;
    }
    _useLoadedParamsInChat.clear();
    _settings = _settings.copyWith(modelsPreferLoadedParams: const []);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<bool> _loadModelWithMiniConfig(String modelPath) {
    final existing = _loadInFlight[modelPath];
    if (existing != null) return existing;

    final future = _loadModelWithMiniConfigImpl(modelPath);
    _loadInFlight[modelPath] = future;
    return future.whenComplete(() {
      if (identical(_loadInFlight[modelPath], future)) {
        _loadInFlight.remove(modelPath);
      }
    });
  }

  Future<bool> _loadModelWithMiniConfigImpl(String modelPath) async {
    // Re-check after coalescing — another load may have finished.
    try {
      await loadAvailableModels();
    } catch (_) {}
    final already = resolveLmStudioModel(modelPath);
    if (already != null && already.isLoaded) {
      preferLoadedParamsForChat(already.id);
      return true;
    }

    _loadingModelId = modelPath;
    notifyListeners();
    try {
      final config = buildLoadConfig(modelId: modelPath);

      await _lmStudioService.loadModel(
        baseUrl: _settings.serverUrl,
        modelPath: modelPath,
        config: config,
        apiToken: _settings.apiToken,
      );

      // Refresh the models list to get the new loaded state
      await loadAvailableModels();
      preferLoadedParamsForChat(modelPath);
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('model_not_found') ||
          msg.contains('not found in downloaded') ||
          msg.contains('Failed to load model: 404')) {
        _connectionError = 'Model "$modelPath" is not downloaded in LM Studio. '
            'Download it there, or pick another model in Model Management.';
      } else {
        _connectionError = 'Failed to load model: $e';
      }
      notifyListeners();
      return false;
    } finally {
      _loadingModelId = null;
      notifyListeners();
    }
  }

  /// Load the selected Unsloth catalog model into memory at Mini's context length.
  Future<bool> _loadUnslothFromSelection(String modelPath) async {
    final resolved = resolveLmStudioModel(modelPath);
    final modelId = resolved?.id ?? modelPath.trim();
    if (modelId.isEmpty) return false;
    final cp = resolveCloudProvider();
    if (cp == null || cp.type != CloudApiType.unsloth) {
      _connectionError = 'No Unsloth server configured';
      notifyListeners();
      return false;
    }
    final desired = _settings.loadContextLength ?? _settings.contextWindow;
    if (resolved != null &&
        resolved.isLoaded &&
        (desired <= 0 || resolved.loadedContextLength == desired)) {
      return true;
    }

    _loadingModelId = modelId;
    notifyListeners();
    try {
      await _lmStudioService.loadUnslothModel(
        baseUrl: cp.effectiveBaseUrl,
        modelId: modelId,
        maxSeqLength: desired > 0 ? desired : 0,
        apiToken: cp.apiKey.trim().isEmpty ? null : cp.apiKey,
      );
      if (desired > 0) {
        _unslothAppliedContextKey = UnslothLoad.contextKey(modelId, desired);
        _unslothDeclinedContextKey = null;
      }
      await loadAvailableModels();
      return true;
    } catch (e) {
      _connectionError = 'Failed to load model: $e';
      notifyListeners();
      return false;
    } finally {
      _loadingModelId = null;
      notifyListeners();
    }
  }

  /// Unload a specific model from memory
  Future<bool> unloadSpecificModel(String instanceId) async {
    if (_settings.activeProviderKind == 'unsloth') {
      return _unloadUnslothFromSelection(instanceId);
    }
    try {
      await _lmStudioService.unloadModel(
        baseUrl: _settings.serverUrl,
        instanceId: instanceId,
        apiToken: _settings.apiToken,
      );

      // Refresh the models list to get the updated state
      await loadAvailableModels();
      return true;
    } catch (e) {
      _connectionError = 'Failed to unload model: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _unloadUnslothFromSelection(String modelId) async {
    final cp = resolveCloudProvider();
    if (cp == null || cp.type != CloudApiType.unsloth) {
      _connectionError = 'No Unsloth server configured';
      notifyListeners();
      return false;
    }
    try {
      await _lmStudioService.unloadUnslothModel(
        baseUrl: cp.effectiveBaseUrl,
        modelId: modelId,
        apiToken: cp.apiKey.trim().isEmpty ? null : cp.apiKey,
      );
      _unslothAppliedContextKey = null;
      await loadAvailableModels();
      return true;
    } catch (e) {
      _connectionError = 'Failed to unload model: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> testConnection() async {
    _isTestingConnection = true;
    _connectionError = null;
    notifyListeners();

    bool isConnected = false;
    try {
      final result = await _lmStudioService.testConnection(
        _settings.serverUrl,
        apiToken: _settings.apiToken,
      );
      isConnected = result['success'] as bool;
      if (!isConnected) {
        _connectionError = ConnectHostError.userMessageFor(
              result['error'],
              serverUrl: _settings.serverUrl,
              isRemoteActive: _settings.isRemoteActive,
              usbModeEnabled: _settings.usbModeEnabled,
            ) ??
            result['error'] as String? ??
            'Unable to connect to LM Studio server';
      }
    } catch (e) {
      _connectionError = _friendlyConnectionError(e);
    }

    _isTestingConnection = false;
    notifyListeners();
    return isConnected;
  }

  void updateServerUrl(String url) {
    // Block free users from manually entering relay server URLs
    if (_isRelayUrl(url) && !SubscriptionService().isPremium) {
      return;
    }
    _settings = _settings.copyWith(serverUrl: url);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  // ── Named server profiles ──────────────────────────────────────────────

  /// Persist [profile] and make it the active provider.
  Future<bool> saveAndActivateServerProfile(ServerProfile profile) async {
    if (profile.isPremium && !SubscriptionService().isPremium) {
      return false;
    }

    final cloud = CloudApiService();
    final profiles = ServerProfileService.instance;
    // Reuse an existing row for the same endpoint (avoids duplicate LM Studios).
    final duplicate = profiles.findDuplicateOf(profile);
    final resolved = duplicate == null
        ? profile
        : ServerProfile(
            id: duplicate.id,
            name:
                profile.name.trim().isNotEmpty ? profile.name : duplicate.name,
            kind: profile.kind,
            cloudType: profile.cloudType,
            baseUrl: profile.baseUrl ?? duplicate.baseUrl,
            apiKey: profile.apiKey ?? duplicate.apiKey,
            customHeaders: profile.customHeaders ?? duplicate.customHeaders,
            customHeadersEnabled: profile.customHeadersEnabled,
            lastUsedAt: DateTime.now(),
          );

    if (resolved.kind == ServerProfileKind.cloud &&
        resolved.cloudType != null) {
      final existing =
          cloud.providers.where((p) => p.id == resolved.id).firstOrNull;
      await cloud.saveProvider(CloudApiProvider(
        id: resolved.id,
        name: resolved.name,
        type: resolved.cloudType!,
        apiKey: resolved.apiKey ?? '',
        baseUrl: resolved.baseUrl,
        selectedModel: existing?.selectedModel,
        isEnabled: true,
        customHeaders: resolved.customHeaders,
        customHeadersEnabled: resolved.customHeadersEnabled,
      ));
    }

    await profiles.upsert(resolved);
    return activateServerProfile(resolved.id);
  }

  /// Switch the app to an already-saved profile.
  Future<bool> activateServerProfile(String id) async {
    final profiles = ServerProfileService.instance;
    final profile = await profiles.markActive(id);
    if (profile == null) return false;

    if (profile.isPremium && !SubscriptionService().isPremium) {
      return false;
    }

    // Leaving USB for any other server turns the bridge off first.
    if (!profile.isUsb && _settings.usbModeEnabled) {
      await deactivateUsbMode();
    }

    // Local/cloud/USB profiles must not keep the relay URL as serverUrl.
    if (!profile.isOnDevice && _settings.isRemoteActive) {
      await deactivateRemoteAccess();
    }

    final cloud = CloudApiService();

    switch (profile.kind) {
      case ServerProfileKind.onDevice:
        final kind = (_settings.activeProviderKind == 'onDeviceMlx')
            ? 'onDeviceMlx'
            : 'onDeviceGguf';
        await cloud.setActiveProvider(null);
        await updateSettings(_settings.copyWith(activeProviderKind: kind));
        await _reconcileOnDeviceEngineSelection();
        break;

      case ServerProfileKind.lmStudio:
        // Clear stale cloud/OpenAI-Compatible active flag so chat doesn't keep
        // routing to the previous provider (e.g. llama-server on :8080).
        await cloud.setActiveProvider(null);
        await updateSettings(_settings.copyWith(
          activeProviderKind: 'lmStudio',
          serverUrl: profile.baseUrl?.trim().isNotEmpty == true
              ? profile.baseUrl!.trim()
              : _settings.serverUrl,
          apiToken: profile.apiKey?.isEmpty == true ? null : profile.apiKey,
          customRequestHeaders: profile.customHeaders,
          customHeadersEnabled: profile.customHeadersEnabled,
        ));
        break;

      case ServerProfileKind.usb:
        await cloud.setActiveProvider(null);
        await profiles.ensureUsbProfile();
        await activateUsbMode();
        await updateSettings(
          _settings.copyWith(activeProviderKind: 'lmStudio'),
        );
        break;

      case ServerProfileKind.cloud:
        if (profile.cloudType == null) return false;
        final existing =
            cloud.providers.where((p) => p.id == profile.id).firstOrNull;
        await cloud.saveProvider(CloudApiProvider(
          id: profile.id,
          name: profile.name,
          type: profile.cloudType!,
          apiKey: profile.apiKey ?? existing?.apiKey ?? '',
          baseUrl: profile.baseUrl ?? existing?.baseUrl,
          selectedModel: existing?.selectedModel,
          isEnabled: true,
          customHeaders: profile.customHeaders ?? existing?.customHeaders,
          customHeadersEnabled: profile.customHeadersEnabled,
        ));
        await cloud.setActiveProvider(profile.id);
        await updateSettings(_settings.copyWith(
          activeProviderKind: profile.cloudType!.providerKind,
          selectedModel: existing?.selectedModel ?? _settings.selectedModel,
        ));
        break;
    }

    _hasAttemptedConnection = true;
    // USB models only load once the Mac peer is attached.
    if (profile.isUsb && !UsbBridgeService.instance.isPeerConnected) {
      _connectionError = null;
      notifyListeners();
      return true;
    }
    try {
      await loadAvailableModels();
    } catch (_) {}
    notifyListeners();
    return true;
  }

  /// When on-device has no ready model (or one is still downloading), chat
  /// should use a configured desktop server instead.
  /// Priority: LM Studio → Ollama → on-device.
  Future<void> preferReadyDesktopServer() async {
    final downloads = LocalModelDownloadService.instance;
    await downloads.init();
    if (downloads.readyEntries.isNotEmpty) return;

    final profiles = ServerProfileService.instance;
    if (!profiles.isLoaded) {
      await profiles.load(settings: _settings);
    }

    ServerProfile? lmStudio;
    ServerProfile? ollama;
    for (final p in profiles.profiles) {
      final url = p.baseUrl?.trim() ?? '';
      if (url.isEmpty) continue;
      if (p.kind == ServerProfileKind.lmStudio) {
        lmStudio ??= p;
      } else if (p.kind == ServerProfileKind.cloud &&
          p.cloudType == CloudApiType.ollama) {
        ollama ??= p;
      }
    }

    if (lmStudio != null) {
      if (_settings.activeProviderKind == 'lmStudio' &&
          profiles.activeId == lmStudio.id) {
        return;
      }
      await activateServerProfile(lmStudio.id);
      return;
    }
    if (ollama != null) {
      if (_settings.activeProviderKind == 'ollama' &&
          profiles.activeId == ollama.id) {
        return;
      }
      await activateServerProfile(ollama.id);
    }
  }

  /// Add/activate the LM Studio via USB profile from Add Server.
  Future<bool> enableUsbServerProfile() async {
    final profile = await ServerProfileService.instance.ensureUsbProfile();
    return activateServerProfile(profile.id);
  }

  void updateApiToken(String? token) {
    _settings =
        _settings.copyWith(apiToken: token?.isEmpty == true ? null : token);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  // ── Remote Access ──────────────────────────────────────────────────────

  final RemoteAccessService _remoteAccessService = RemoteAccessService();
  RemoteAccessService get remoteAccessService => _remoteAccessService;

  /// Last host-status reachability map (`lmStudio` → true, `kokoro` → false).
  Map<String, bool> _remoteReachable = {};
  Map<String, bool> get remoteReachable => Map.unmodifiable(_remoteReachable);

  String? _remoteHostPlatform;
  String? get remoteHostPlatform => _remoteHostPlatform;

  bool _remoteKokoroReady = false;
  bool get remoteKokoroReady => _remoteKokoroReady;

  String get remoteHostLocationTitle =>
      RemoteHostBackends.homeLocationTitle(_remoteHostPlatform);

  bool _remoteHostStatusOk = false;
  bool get remoteHostStatusOk => _remoteHostStatusOk;
  String? _remoteHostStatusError;
  String? get remoteHostStatusError => _remoteHostStatusError;

  bool isRemoteBackendReachable(String kind) {
    // Empty / failed probes must not look like "everything is up".
    if (!_remoteHostStatusOk) return false;
    if (kind == 'kokoro') {
      if (_remoteKokoroReady) return true;
      return _remoteReachable['kokoro'] == true;
    }
    if (kind == RemoteHostBackends.lmMiniDesktop) {
      return _remoteReachable[kind] ?? true;
    }
    return _remoteReachable[kind] == true;
  }

  /// Advertised QR backends that should appear in Servers / provider chips.
  List<String> get visibleRemoteBackends => RemoteHostBackends.visibleOf(
        _settings,
        hostStatusOk: _remoteHostStatusOk,
        reachable: isRemoteBackendReachable,
      );

  /// Check if a URL points to the relay server (premium-only feature).
  bool _isRelayUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('lm-mini-relay') ||
        lower.contains('connect.lmmini.com') ||
        lower.contains('relay.lmmini.com') ||
        RegExp(r'run\.app/s/').hasMatch(lower);
  }

  /// True when the active remote URL points at the legacy Cloud Run relay
  /// (deprecated 2026-05-10). Used to surface an in-app deprecation banner.
  bool get isUsingLegacyRelay {
    if (!_settings.isRemoteActive) return false;
    final url = (_settings.remoteServerUrl ?? '').toLowerCase();
    return url.contains('lm-mini-relay-') && RegExp(r'run\.app/').hasMatch(url);
  }

  /// Activate remote access mode with relay URL and auth token from QR code.
  /// Saves the current local server URL so it can be restored later.
  /// Requires premium subscription.
  ///
  /// Preserves Ollama / oMLX when Connect advertises those backends (QR v5+).
  /// Older Connect builds force LM Studio.
  Future<void> activateRemoteAccess(RemoteConnectionInfo info) async {
    if (!SubscriptionService().isPremium) return;
    await _proActivateRemoteAccess(info);
  }

  /// Re-enable an already-paired remote session without re-parsing a QR.
  Future<void> reactivateRemoteAccess() async {
    if (!SubscriptionService().isPremium) return;
    await _proReactivateRemoteAccess();
  }

  void applyRemoteReachable(Map<String, bool> reachable) {
    _proApplyRemoteReachable(reachable);
  }

  void applyHostStatus({
    required Map<String, bool> reachable,
    String? platform,
    bool? kokoroReady,
    bool? hostStatusOk,
    String? hostStatusError,
  }) {
    _proApplyHostStatus(
      reachable: reachable,
      platform: platform,
      kokoroReady: kokoroReady,
      hostStatusOk: hostStatusOk,
      hostStatusError: hostStatusError,
    );
  }

  /// Refresh which Home backends are actually up (via `/lm-mini/host-status`).
  Future<void> refreshRemoteHostStatus() async {
    await _proRefreshRemoteHostStatus();
  }

  /// Backend label for relay routing (`lmStudio` / `ollama` / `omlx` / `jan` / `unsloth` / `lmMiniDesktop`).
  String get remoteBackendKind {
    final kind = _settings.activeProviderKind;
    if (kind == 'ollama' ||
        kind == 'omlx' ||
        kind == 'jan' ||
        kind == 'unsloth' ||
        kind == 'lmMiniDesktop') {
      return kind;
    }
    return 'lmStudio';
  }

  /// Switch to the paired LM Mini Home backend (reactivates relay if needed).
  Future<void> activatePairedHome() async {
    if (!RemoteHostBackends.isPairedHome(_settings)) return;
    if (!_settings.isRemoteActive) {
      await reactivateRemoteAccess();
    }
    if (!_settings.isRemoteActive) return;
    if (_settings.activeProviderKind == RemoteHostBackends.lmMiniDesktop) {
      try {
        await loadAvailableModels();
      } catch (_) {}
      return;
    }
    await switchRemoteBackend(RemoteHostBackends.lmMiniDesktop);
  }

  /// Opt in or out of chat/folder sync with LM Mini Home.
  /// [enabled] false still records that the first-connect prompt was answered.
  Future<void> setHomeSyncEnabled(bool enabled) async {
    _settings = _settings.copyWith(
      homeSyncEnabled: enabled,
      homeSyncPrompted: true,
    );
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setHomeSyncPersonasEnabled(bool enabled) async {
    _settings = _settings.copyWith(
      homeSyncPersonasEnabled: enabled,
      homeSyncPersonasUpdatedAt: DateTime.now(),
    );
    await _settingsService.saveSettings(_settings);
    notifyListeners();
    if (enabled && _settings.homeSyncEnabled) {
      HomeSyncService.instance.schedule();
    }
  }

  Future<void> setHomeSyncPersonaIds(List<String> ids) async {
    _settings = _settings.copyWith(
      homeSyncPersonaIds: List<String>.from(ids),
      homeSyncPersonasEnabled: true,
      homeSyncPersonasUpdatedAt: DateTime.now(),
    );
    await _settingsService.saveSettings(_settings);
    notifyListeners();
    if (_settings.homeSyncEnabled) {
      HomeSyncService.instance.schedule();
    }
  }

  /// Upsert personas copied from the other device without deleting local-only ones.
  Future<void> applyHomeSyncPersonas({
    required List<SystemPrompt> prompts,
    required List<String> syncIds,
    required bool enabled,
    DateTime? updatedAt,
  }) async {
    final current = List<SystemPrompt>.from(_settings.savedSystemPrompts ?? []);
    final byId = {for (final p in current) p.id: p};
    var changed = _settings.homeSyncPersonasEnabled != enabled ||
        !_sameIdList(_settings.homeSyncPersonaIds, syncIds) ||
        _settings.homeSyncPersonasUpdatedAt != updatedAt;
    for (final incoming in prompts) {
      final existing = byId[incoming.id];
      if (existing == null ||
          !incoming.updatedAt.isBefore(existing.updatedAt)) {
        if (existing == null ||
            existing.toJson().toString() != incoming.toJson().toString()) {
          byId[incoming.id] = incoming;
          changed = true;
        }
      }
    }
    if (!changed) return;
    final next = byId.values.toList();
    _settings = _settings.copyWith(
      savedSystemPrompts: next,
      homeSyncPersonasEnabled: enabled,
      homeSyncPersonaIds: List<String>.from(syncIds),
      homeSyncPersonasUpdatedAt: updatedAt,
    );
    await _settingsService.saveSettings(_settings);
    WidgetDataService.updatePersonas(next);
    notifyListeners();
  }

  bool _sameIdList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final other = b.toSet();
    return a.every(other.contains);
  }

  void _maybeSchedulePersonaSync() {
    if (_settings.homeSyncEnabled && _settings.homeSyncPersonasEnabled) {
      HomeSyncService.instance.schedule();
    }
  }

  /// Switch which Connect / Home backend the phone talks to, then reload models.
  Future<void> switchRemoteBackend(String kind) async {
    await _proSwitchRemoteBackend(kind);
  }

  /// List models for a specific host backend without changing the global
  /// selection (used by Group / Arena / chat pickers).
  Future<List<LMStudioModel>> fetchModelsForBackend(String kind) async {
    final localType = CloudApiType.forProviderKind(kind);
    if (localType != null) {
      final cloud = CloudApiService();
      final type = localType;
      var cp = cloud.providers.where((p) => p.type == type).firstOrNull;
      // Rewrite advertised local servers onto the relay so JAN/Unsloth/Ollama
      // chat goes through Connect/Home instead of the phone's LAN URL.
      if (_settings.isRemoteActive && visibleRemoteBackends.contains(kind)) {
        final url = _settings.remoteServerUrl ?? _settings.serverUrl;
        cp = (cp ??
                CloudApiProvider(
                  id: kind,
                  name: type.displayName,
                  type: type,
                  apiKey: '',
                  baseUrl: url,
                  isEnabled: true,
                ))
            .copyWith(baseUrl: url, isEnabled: true);
      }
      if (cp == null) return const [];
      final ids = await cloud.fetchModels(cp);
      return ids
          .where((id) => !LMStudioModel.looksLikeEmbeddingModel(id))
          .map((id) => LMStudioModel(
                id: id,
                object: 'model',
                type: 'llm',
                publisher: type.displayName,
                arch: '',
                compatibilityType: '',
                quantization: '',
                state: 'loaded',
                maxContextLength: 0,
              ))
          .toList();
    }

    final client = LMStudioService();
    RemoteHostBackends.configureLmStudioClient(
      client,
      _settings,
      backend: kind,
    );
    final models = await client.getAvailableModels(
      baseUrl: _settings.serverUrl,
      apiToken: _settings.apiToken,
    );
    return models.where((m) => !m.isEmbedding).toList();
  }

  /// True when paired Connect is older than multi-backend support.
  bool get isUsingOutdatedConnect {
    if (_settings.remoteServerUrl == null) return false;
    final version = _settings.remoteConnectVersion;
    if (version == null || version.isEmpty) {
      // Pre-v5 QR / unknown Connect build.
      return true;
    }
    return ConnectCompatibility.connectNeedsUpgrade(version);
  }

  /// Deactivate remote access and restore the saved local server URL.
  /// When [userInitiated] is false (health-check dropout), we remember to
  /// auto-reconnect when the app returns to the foreground.
  Future<void> deactivateRemoteAccess({bool userInitiated = true}) async {
    _remoteAccessService.stopHealthCheck();
    _healthSubscription?.cancel();
    _healthSubscription = null;
    _consecutiveHealthFailures = 0;
    _remoteHealthPausedForBackground = false;
    final localUrl = _settings.savedLocalServerUrl ?? 'http://localhost:1234';
    final savedCloudBase = _settings.savedLocalCloudBaseUrl;
    final fromKey = ServerModelMemory.keyFor(_settings);
    final fromModel = _settings.selectedModel;

    _settings = _settings.copyWith(
      isRemoteActive: false,
      serverUrl: localUrl,
      remoteAutoReconnect: userInitiated ? false : true,
    );
    _rememberSelectedModel(key: fromKey, modelId: fromModel);
    _restoreSelectedModel(ServerModelMemory.keyFor(_settings));
    _syncRemoteAuthToken();
    if (savedCloudBase != null && savedCloudBase.isNotEmpty) {
      final cloud = CloudApiService();
      final cp = resolveCloudProvider(cloud);
      if (cp != null && cp.type.isFreeLocalServer) {
        await cloud.saveProvider(cp.copyWith(baseUrl: savedCloudBase));
      }
    }

    await _settingsService.saveSettings(_settings);
    notifyListeners();

    // Reload models from local server
    try {
      await loadAvailableModels();
    } catch (_) {}
  }

  /// Pause remote health polling while the app is backgrounded so transient
  /// network suspension does not count as disconnects.
  void onAppPaused() {
    if (!_settings.isRemoteActive) return;
    _remoteHealthPausedForBackground = true;
    _remoteAccessService.stopHealthCheck();
    _healthSubscription?.cancel();
    _healthSubscription = null;
    _consecutiveHealthFailures = 0;
  }

  /// Re-verify (or restore) the remote LM Studio connection when the app
  /// returns to the foreground.
  Future<void> onAppResumed() async {
    if (!SubscriptionService().isPremium) return;
    await _proOnAppResumed();
  }

  /// Clear all saved remote access data (unpair).
  Future<void> clearRemoteAccess() async {
    _remoteAccessService.stopHealthCheck();
    _healthSubscription?.cancel();
    _healthSubscription = null;
    _consecutiveHealthFailures = 0;
    final localUrl = _settings.savedLocalServerUrl ?? _settings.serverUrl;
    final savedCloudBase = _settings.savedLocalCloudBaseUrl;
    final fromKey = ServerModelMemory.keyFor(_settings);
    final fromModel = _settings.selectedModel;

    if (savedCloudBase != null && savedCloudBase.isNotEmpty) {
      final cloud = CloudApiService();
      final cp = resolveCloudProvider(cloud);
      if (cp != null && cp.type.isFreeLocalServer) {
        await cloud.saveProvider(cp.copyWith(baseUrl: savedCloudBase));
      }
    }

    _settings = _settings.copyWith(
      remoteServerUrl: null,
      remoteAuthToken: null,
      isRemoteActive: false,
      remoteAutoReconnect: false,
      remoteLastConnected: null,
      savedLocalServerUrl: null,
      savedLocalCloudBaseUrl: null,
      remoteConnectVersion: null,
      remoteBackends: const [],
      remoteEncryptionKey: null,
      homeSyncEnabled: false,
      homeSyncPrompted: false,
      homeSyncPersonasEnabled: false,
      homeSyncPersonaIds: const [],
      homeSyncPersonasUpdatedAt: null,
      serverUrl: localUrl,
    );
    _rememberSelectedModel(key: fromKey, modelId: fromModel);
    _restoreSelectedModel(ServerModelMemory.keyFor(_settings));
    _syncRemoteAuthToken();
    _remoteReachable = {};
    _remoteKokoroReady = false;
    _remoteHostPlatform = null;
    _remoteHostStatusOk = false;
    _remoteHostStatusError = null;
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Lets Pro parts notify without touching the protected member directly.
  void _notifyFromPart() => notifyListeners();

  /// Sync remote auth token on LMStudioService / Ollama / CloudApi (startup).
  void _syncRemoteAuthToken() {
    final token = _settings.isRemoteActive ? _settings.remoteAuthToken : null;
    final relayUrl =
        _settings.isRemoteActive ? _settings.remoteServerUrl : null;
    _lmStudioService.remoteAuthToken = token;
    _lmStudioService.remoteRelayBaseUrl = relayUrl;
    _lmStudioService.remoteBackend =
        _settings.isRemoteActive ? remoteBackendKind : null;
    _lmStudioService.customHeaders = _settings.effectiveExtraHeaders;
    OllamaService.instance.remoteAuthToken =
        (_settings.isRemoteActive && _settings.activeProviderKind == 'ollama')
            ? token
            : null;
    OllamaService.instance.remoteRelayBaseUrl = relayUrl;
    CloudApiService().remoteAuthToken = token;
    CloudApiService().remoteRelayBaseUrl = relayUrl;
  }

  // ── USB Mode ────────────────────────────────────────────────

  /// True when USB Mode is currently active. While active, all LM Studio
  /// traffic is routed through the on-device USB bridge to LM Mini Connect.
  bool get isUsbModeActive => _settings.usbModeEnabled;

  /// Live stream of USB peer-attached state. UI can `StreamBuilder` on this.
  Stream<bool> get usbConnectionStream =>
      UsbBridgeService.instance.connectionStream;

  bool get isUsbPeerConnected => UsbBridgeService.instance.isPeerConnected;

  /// Turn USB Mode on. Saves the current local server URL, switches
  /// `serverUrl` to the in-process bridge URL, and starts the bridge.
  /// Mutually exclusive with remote-relay mode — deactivates that first.
  Future<void> activateUsbMode() async {
    if (_settings.usbModeEnabled) return;

    if (_settings.isRemoteActive) {
      await deactivateRemoteAccess();
    }

    final savedLocal = _settings.savedLocalServerUrl ?? _settings.serverUrl;
    final fromKey = ServerModelMemory.keyFor(_settings);
    final fromModel = _settings.selectedModel;

    try {
      await UsbBridgeService.instance.start();
    } catch (e) {
      _connectionError = 'Failed to start USB bridge: $e';
      notifyListeners();
      rethrow;
    }

    _settings = _settings.copyWith(
      usbModeEnabled: true,
      savedLocalServerUrl: savedLocal,
      serverUrl: UsbBridgeService.baseUrl,
      activeProviderKind: 'lmStudio',
    );
    _rememberSelectedModel(key: fromKey, modelId: fromModel);
    _restoreSelectedModel(ServerModelMemory.keyFor(_settings));
    await _settingsService.saveSettings(_settings);
    await ServerProfileService.instance.ensureUsbProfile();
    await ServerProfileService.instance.markActive(ServerProfile.usbId);
    _connectionError = null;
    _listenToUsbConnection();
    notifyListeners();

    // Models can only load once a Mac peer is attached; UsbBridgeService
    // emits `true` on the connection stream when that happens, and our
    // listener will reload models then.
    if (UsbBridgeService.instance.isPeerConnected) {
      try {
        await loadAvailableModels();
      } catch (_) {}
    }
  }

  /// Turn USB Mode off. Stops the bridge and restores the saved local URL.
  Future<void> deactivateUsbMode() async {
    if (!_settings.usbModeEnabled) return;
    final localUrl = _settings.savedLocalServerUrl ?? 'http://localhost:1234';
    final fromKey = ServerModelMemory.keyFor(_settings);
    final fromModel = _settings.selectedModel;
    _usbConnectionSubscription?.cancel();
    _usbConnectionSubscription = null;
    await UsbBridgeService.instance.stop();
    _settings = _settings.copyWith(
      usbModeEnabled: false,
      serverUrl: localUrl,
    );
    _rememberSelectedModel(key: fromKey, modelId: fromModel);
    _restoreSelectedModel(ServerModelMemory.keyFor(_settings));
    await _settingsService.saveSettings(_settings);
    notifyListeners();
    try {
      await loadAvailableModels();
    } catch (_) {}
  }

  /// Remove USB from the server list and turn the bridge off.
  Future<void> removeUsbServerProfile() async {
    await deactivateUsbMode();
    await ServerProfileService.instance.delete(ServerProfile.usbId);
  }

  void _listenToUsbConnection() {
    _usbConnectionSubscription?.cancel();
    _usbConnectionSubscription =
        UsbBridgeService.instance.connectionStream.listen((connected) async {
      // Notify so any UI watching `isUsbPeerConnected` rebuilds even if it
      // isn't using a StreamBuilder directly.
      notifyListeners();
      if (connected) {
        try {
          await loadAvailableModels();
        } catch (_) {}
      }
    });
  }

  void _rememberSelectedModel({String? key, String? modelId}) {
    final slot = key ?? ServerModelMemory.keyFor(_settings);
    final id = modelId ?? _settings.selectedModel;
    final map = Map<String, String>.from(_settings.selectedModelByServer);
    if (id == null || id.isEmpty) {
      if (!map.containsKey(slot)) return;
      map.remove(slot);
    } else if (map[slot] == id) {
      return;
    } else {
      map[slot] = id;
    }
    _settings = _settings.copyWith(selectedModelByServer: map);
  }

  void _restoreSelectedModel(String key, {String? fallback}) {
    final next = _settings.selectedModelByServer.containsKey(key)
        ? _settings.selectedModelByServer[key]
        : fallback;
    if (next == _settings.selectedModel) return;
    _settings = _settings.copyWith(selectedModel: next);
  }

  /// Returns true when persisted selection changed so the caller can save.
  bool _reconcileSelectedModelWithCatalog() {
    if (_availableModels.isEmpty) return false;
    final key = ServerModelMemory.keyFor(_settings);
    final next = ServerModelMemory.pick(
      remembered: _settings.selectedModelByServer[key],
      current: _settings.selectedModel,
      availableIds: _availableModels.map((m) => m.id),
    );
    var changed = false;
    if (next != _settings.selectedModel) {
      _settings = _settings.copyWith(selectedModel: next);
      changed = true;
    }
    final remembered = _settings.selectedModelByServer[key];
    if (next != null) {
      if (remembered != next) {
        _rememberSelectedModel(key: key, modelId: next);
        changed = true;
      }
    } else if (remembered != null) {
      _rememberSelectedModel(key: key, modelId: null);
      changed = true;
    }
    return changed;
  }

  void updateSelectedModel(String? modelId) {
    // Update the selected model
    _settings = _settings.copyWith(selectedModel: modelId);
    _rememberSelectedModel(modelId: modelId);

    // If a model is selected, ensure the user-chosen context window still
    // fits this model. We clamp (not overwrite) so the user's preference
    // — typically 16K — carries between models. Loading max context by
    // default would waste RAM and slow first-token latency.
    // Skip clamp when the catalog is empty or the id isn't listed yet
    // (e.g. starting a chat from a persona before models have loaded).
    if (modelId != null && _availableModels.isNotEmpty) {
      final matched =
          _availableModels.where((model) => model.id == modelId).firstOrNull;
      if (matched != null) {
        final modelMax = matched.maxContextLength;
        if (modelMax > 0 && _settings.contextWindow > modelMax) {
          _settings = _settings.copyWith(
            contextWindow: modelMax,
            loadContextLength: modelMax,
          );
        }
      }
    }

    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateTemperature(double temperature) {
    _settings = _settings.copyWith(temperature: temperature);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateMaxTokens(int maxTokens) {
    _settings = _settings.copyWith(maxTokens: maxTokens);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateContextWindow(int contextWindow) {
    // Single context control: chat budget and LM Studio load size stay equal.
    _clearModelsPreferLoadedParams();
    _settings = _settings.copyWith(
      contextWindow: contextWindow,
      loadContextLength: contextWindow,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateSystemPrompt(String systemPrompt) {
    _settings = _settings.copyWith(systemPrompt: systemPrompt);
    final selectedId = _settings.selectedSystemPromptId;
    if (selectedId == BuiltinPersonaService.defaultPersonaId) {
      final current =
          List<SystemPrompt>.from(_settings.savedSystemPrompts ?? []);
      final index = current
          .indexWhere((p) => p.id == BuiltinPersonaService.defaultPersonaId);
      if (index >= 0) {
        current[index] = current[index].copyWith(
          content: systemPrompt,
          updatedAt: DateTime.now(),
        );
        _settings = _settings.copyWith(savedSystemPrompts: current);
      }
    }
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  // --- System Prompt Library Management ---

  /// Add a new saved system prompt
  void addSystemPrompt(SystemPrompt prompt) {
    final current = List<SystemPrompt>.from(_settings.savedSystemPrompts ?? []);
    current.add(prompt);
    _settings = _settings.copyWith(savedSystemPrompts: current);
    _settingsService.saveSettings(_settings);
    WidgetDataService.updatePersonas(current);
    notifyListeners();
    _maybeSchedulePersonaSync();
  }

  /// Update an existing saved system prompt
  void updateSavedSystemPrompt(SystemPrompt prompt) {
    final current = List<SystemPrompt>.from(_settings.savedSystemPrompts ?? []);
    final index = current.indexWhere((p) => p.id == prompt.id);
    if (index >= 0) {
      current[index] = prompt;
      _settings = _settings.copyWith(savedSystemPrompts: current);
      _settingsService.saveSettings(_settings);
      WidgetDataService.updatePersonas(current);
      notifyListeners();
      _maybeSchedulePersonaSync();
    }
  }

  /// Delete a saved system prompt
  void deleteSystemPrompt(String promptId) {
    if (promptId == BuiltinPersonaService.defaultPersonaId) return;

    final current = List<SystemPrompt>.from(_settings.savedSystemPrompts ?? []);
    current.removeWhere((p) => p.id == promptId);

    // If the deleted prompt was selected, fall back to Default.
    String? selectedId = _settings.selectedSystemPromptId;
    if (selectedId == promptId) {
      selectedId =
          current.any((p) => p.id == BuiltinPersonaService.defaultPersonaId)
              ? BuiltinPersonaService.defaultPersonaId
              : null;
    }

    final nextIds =
        _settings.homeSyncPersonaIds.where((id) => id != promptId).toList();
    final idsChanged = nextIds.length != _settings.homeSyncPersonaIds.length;

    _settings = _settings.copyWith(
      savedSystemPrompts: current,
      selectedSystemPromptId: selectedId,
      systemPrompt: selectedId == BuiltinPersonaService.defaultPersonaId
          ? ''
          : _settings.systemPrompt,
      homeSyncPersonaIds: nextIds,
      homeSyncPersonasUpdatedAt:
          idsChanged ? DateTime.now() : _settings.homeSyncPersonasUpdatedAt,
    );
    _settingsService.saveSettings(_settings);
    WidgetDataService.updatePersonas(current);
    notifyListeners();
    _maybeSchedulePersonaSync();
  }

  /// Select a saved system prompt as the active one.
  /// Pass null to select the built-in Default persona (empty prompt, no prefs).
  void selectSystemPrompt(String? promptId) {
    final prompts = _settings.savedSystemPrompts ?? const <SystemPrompt>[];
    final resolvedId = promptId ??
        (prompts.any((p) => p.id == BuiltinPersonaService.defaultPersonaId)
            ? BuiltinPersonaService.defaultPersonaId
            : null);
    _settings = _settings.copyWith(selectedSystemPromptId: resolvedId);

    // Keep inline systemPrompt in sync so send paths that read it directly match.
    if (resolvedId != null) {
      final prompt = prompts.where((p) => p.id == resolvedId);
      if (prompt.isNotEmpty) {
        _settings = _settings.copyWith(systemPrompt: prompt.first.content);
      }
    }

    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Apply a persona's preferred provider + model for the next 1:1 chat.
  ///
  /// Switches [activeProviderKind] (and cloud selection when needed) before
  /// setting the model, so messaging from the persona panel uses that
  /// persona's preferences instead of the global default.
  Future<void> applyPersonaPreferredSettings(SystemPrompt persona) async {
    selectSystemPrompt(persona.id);

    final kind = persona.defaultProviderKind;
    final modelId = persona.defaultModelId;
    final cloudId = persona.defaultCloudProviderId;

    if (kind != null && kind.isNotEmpty) {
      await _activatePersonaProviderKind(kind, cloudProviderId: cloudId);
    }

    if (modelId == null || modelId.isEmpty) return;

    final activeKind = _settings.activeProviderKind;
    final onDevice = activeKind == 'onDeviceGguf' ||
        activeKind == 'onDeviceMlx' ||
        kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx';

    if (onDevice) {
      await LocalModelDownloadService.instance.init();
      final entry = LocalModelDownloadService.instance.readyEntries
          .where((e) => e.spec.id == modelId)
          .firstOrNull;
      if (entry == null) return;
      final engineKind =
          entry.spec.engine == LocalEngine.mlx ? 'onDeviceMlx' : 'onDeviceGguf';
      await updateSettings(_settings.copyWith(
        activeProviderKind: engineKind,
        selectedLocalModelId: entry.spec.id,
        selectedModel: entry.spec.displayName,
      ));
      return;
    }

    updateSelectedModel(modelId);

    // Keep cloud provider's selectedModel in sync when applicable.
    if (isCloudProviderKind(_settings.activeProviderKind)) {
      final cloud = CloudApiService();
      final cp = resolveCloudProvider(cloud);
      if (cp != null && cp.selectedModel != modelId) {
        await cloud.saveProvider(cp.copyWith(selectedModel: modelId));
      }
    }
  }

  /// Switch the global active provider to [kind] for persona defaults.
  Future<void> _activatePersonaProviderKind(
    String kind, {
    String? cloudProviderId,
  }) async {
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      if (_settings.activeProviderKind == kind) return;
      await OnDeviceLLMService.instance.unloadAll();
      await updateSettings(
        _settings.copyWith(activeProviderKind: kind),
        keepOnDeviceEngineChoice: true,
      );
      CloudApiService().setActiveProvider(null);
      return;
    }

    if (kind == 'lmStudio' || kind == 'lmMiniDesktop') {
      if (_settings.isRemoteActive) {
        await switchRemoteBackend(kind);
        return;
      }
      if (_settings.activeProviderKind != kind) {
        await updateSettings(_settings.copyWith(activeProviderKind: kind));
      }
      CloudApiService().setActiveProvider(null);
      if (_availableModels.isEmpty) {
        try {
          await loadAvailableModels();
        } catch (_) {}
      }
      return;
    }

    if (!isCloudProviderKind(kind)) return;

    final cloud = CloudApiService();
    CloudApiProvider? cp;
    if (cloudProviderId != null && cloudProviderId.isNotEmpty) {
      cp = cloud.providers.where((p) => p.id == cloudProviderId).firstOrNull;
    }
    cp ??= resolveCloudProviderForKind(kind, cloud);
    if (cp == null) return;

    await cloud.setActiveProvider(cp.id);
    await updateSettings(_settings.copyWith(
      activeProviderKind: kind == 'cloud' ? cp.type.providerKind : kind,
    ));
    try {
      await loadAvailableModels();
    } catch (_) {}
  }

  /// Resolve a cloud profile for a persona provider kind when no explicit id.
  CloudApiProvider? resolveCloudProviderForKind(
    String kind,
    CloudApiService cloud,
  ) {
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
        return cloud.providers.where((p) => p.type.isPremium).firstOrNull ??
            cloud.providers.where((p) => !p.type.isFreeLocalServer).firstOrNull;
      default:
        return cloud.providers
            .where((p) => p.type.providerKind == kind)
            .firstOrNull;
    }
  }

  /// Duplicate a saved system prompt
  void duplicateSystemPrompt(String promptId) {
    final source = _settings.savedSystemPrompts?.where((p) => p.id == promptId);
    if (source == null || source.isEmpty) return;

    final now = DateTime.now();
    final src = source.first;
    final newPrompt = SystemPrompt(
      id: 'sp_${now.millisecondsSinceEpoch}',
      name: '${src.name} (Copy)',
      content: src.content,
      boundModelIds:
          src.boundModelIds != null ? List.from(src.boundModelIds!) : null,
      createdAt: now,
      updatedAt: now,
      avatarPath: src.avatarPath,
      avatarFocusX: src.avatarFocusX,
      avatarFocusY: src.avatarFocusY,
      avatarFocusScale: src.avatarFocusScale,
      palettePrimary: src.palettePrimary,
      paletteSecondary: src.paletteSecondary,
      color: src.color,
      defaultModelId: src.defaultModelId,
      defaultProviderKind: src.defaultProviderKind,
      defaultCloudProviderId: src.defaultCloudProviderId,
      imageGenSeed: src.imageGenSeed,
      comfyUiWorkflowPath: src.comfyUiWorkflowPath,
      comfyUiWorkflowJson: src.comfyUiWorkflowJson,
      kokoroSpeakerId: src.kokoroSpeakerId,
      kokoroSpeed: src.kokoroSpeed,
      elevenLabsVoiceId: src.elevenLabsVoiceId,
      grokVoiceId: src.grokVoiceId,
      shareMemories: src.shareMemories,
      sharedMemoryCategories: src.sharedMemoryCategories != null
          ? List.from(src.sharedMemoryCategories!)
          : null,
      memoryWriteScope: src.memoryWriteScope,
      useCustomParams: src.useCustomParams,
      customParams: src.customParams,
      greeting: src.greeting,
      alternateGreetings: src.alternateGreetings != null
          ? List.from(src.alternateGreetings!)
          : null,
      expressionSprites: src.expressionSprites != null
          ? Map.from(src.expressionSprites!)
          : null,
    );
    addSystemPrompt(newPrompt);
  }

  /// `'off'`, `'panel'`, `'avatar'` or `'both'`.
  void updateExpressionSpriteMode(String mode) {
    if (!const ['off', 'panel', 'avatar', 'both'].contains(mode)) return;
    _settings = _settings.copyWith(expressionSpriteMode: mode);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void setSpritePanelCollapsed(bool collapsed) {
    if (_settings.spritePanelCollapsed == collapsed) return;
    _settings = _settings.copyWith(spritePanelCollapsed: collapsed);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateTopP(double topP) {
    _settings = _settings.copyWith(topP: topP);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateTopK(int topK) {
    _settings = _settings.copyWith(topK: topK);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateMinP(double minP) {
    _settings = _settings.copyWith(minP: minP);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateRepeatPenalty(double repeatPenalty) {
    _settings = _settings.copyWith(repeatPenalty: repeatPenalty);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateFrequencyPenalty(double value) {
    _settings = _settings.copyWith(frequencyPenalty: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updatePresencePenalty(double value) {
    _settings = _settings.copyWith(presencePenalty: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Toggle pinned/favorite state for a given model id. Pinned models are
  /// displayed at the top of the model list.
  void togglePinnedModel(String modelId) {
    final pinned = List<String>.from(_settings.pinnedModels);
    if (pinned.contains(modelId)) {
      pinned.remove(modelId);
    } else {
      pinned.add(modelId);
    }
    _settings = _settings.copyWith(pinnedModels: pinned);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  bool isModelPinned(String modelId) =>
      _settings.pinnedModels.contains(modelId);

  void updateReasoning(String reasoning) {
    _settings = _settings.copyWith(reasoning: reasoning);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVerbosity(String verbosity) {
    _settings = _settings.copyWith(verbosity: verbosity);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateContextFitMode(String mode) {
    if (mode != 'off' && !SubscriptionService().isPremium) return;
    _settings = _settings.copyWith(contextFitMode: mode);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  String? _activeCloudProviderId() {
    if (!ParamPresetKey.usesCloudProviderId(_settings.activeProviderKind)) {
      return null;
    }
    return resolveCloudProvider(CloudApiService())?.id;
  }

  /// Global + this model's Pro preset (no persona, no chat overlay).
  AppSettings settingsForModelLoad([String? modelId]) {
    final id =
        (modelId ?? ParamPresetKey.selectedModelId(_settings) ?? '').trim();
    final key = ParamPresetKey.build(
      providerKind: _settings.activeProviderKind,
      modelId: id.isEmpty ? null : id,
      cloudProviderId: _activeCloudProviderId(),
    );
    return ParamPresetResolver.overlay(
      global: _settings,
      isPremium: SubscriptionService().isPremium,
      modelKey: key,
    );
  }

  void applyGlobalParamPreset(ParamPreset preset) {
    final loadChanged = preset.contextWindow != _settings.contextWindow ||
        preset.loadContextLength != _settings.loadContextLength ||
        preset.loadEvalBatchSize != _settings.loadEvalBatchSize ||
        preset.loadFlashAttention != _settings.loadFlashAttention ||
        preset.loadNumExperts != _settings.loadNumExperts ||
        preset.loadOffloadKvCache != _settings.loadOffloadKvCache;
    if (loadChanged) _clearModelsPreferLoadedParams();
    final presets = Map<String, ParamPreset>.from(_settings.modelParamPresets);
    _settings = preset.applyTo(_settings).copyWith(modelParamPresets: presets);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  String? currentModelParamKey() {
    return ParamPresetKey.fromSettings(
      _settings,
      cloudProviderId: _activeCloudProviderId(),
    );
  }

  void upsertModelParamPreset(String key, ParamPreset preset) {
    if (key.isEmpty || !SubscriptionService().isPremium) return;
    final existing = _settings.modelParamPresets[key];
    final baseline = existing ?? ParamPreset.fromSettings(_settings);
    final loadChanged = preset.contextWindow != baseline.contextWindow ||
        preset.loadContextLength != baseline.loadContextLength ||
        preset.loadEvalBatchSize != baseline.loadEvalBatchSize ||
        preset.loadFlashAttention != baseline.loadFlashAttention ||
        preset.loadNumExperts != baseline.loadNumExperts ||
        preset.loadOffloadKvCache != baseline.loadOffloadKvCache;
    if (loadChanged) _clearModelsPreferLoadedParams();
    final next = Map<String, ParamPreset>.from(_settings.modelParamPresets);
    next[key] = preset;
    _settings = _settings.copyWith(modelParamPresets: next);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void clearModelParamPreset(String key) {
    if (key.isEmpty || !SubscriptionService().isPremium) return;
    if (!_settings.modelParamPresets.containsKey(key)) return;
    final next = Map<String, ParamPreset>.from(_settings.modelParamPresets);
    next.remove(key);
    _settings = _settings.copyWith(modelParamPresets: next);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateThemeMode(ThemeMode themeMode) {
    _settings = _settings.copyWith(themeMode: themeMode);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateGlassEffectsEnabled(bool value) {
    _settings = _settings.copyWith(glassEffectsEnabled: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateLowBatteryMode(bool value) {
    _settings = _settings.copyWith(lowBatteryMode: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateUserAvatar(String? path) {
    _settings = _settings.copyWith(userAvatarPath: path);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateAssistantAvatar(String? path) {
    _settings = _settings.copyWith(assistantAvatarPath: path);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateChatBackground(String? path) {
    _settings = _settings.copyWith(chatBackgroundPath: path);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateChatBackgroundOverlayOpacity(double value) {
    _settings = _settings.copyWith(
      chatBackgroundOverlayOpacity: value.clamp(0.0, 100.0),
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateShowRuntimeInfo(bool value) {
    _settings = _settings.copyWith(showRuntimeInfo: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Convert legacy absolute image paths to relative paths.
  void _migrateImagePathsToRelative() {
    final u = ImagePickerHelper.toRelativePath(_settings.userAvatarPath);
    final a = ImagePickerHelper.toRelativePath(_settings.assistantAvatarPath);
    final b = ImagePickerHelper.toRelativePath(_settings.chatBackgroundPath);
    if (u != _settings.userAvatarPath ||
        a != _settings.assistantAvatarPath ||
        b != _settings.chatBackgroundPath) {
      _settings = _settings.copyWith(
        userAvatarPath: u,
        assistantAvatarPath: a,
        chatBackgroundPath: b,
      );
      _settingsService.saveSettings(_settings);
      debugPrint('🖼️ Migrated image paths to relative');
    }
  }

  void updateLiveActivityEnabled(bool value) {
    _settings = _settings.copyWith(liveActivityEnabled: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateSelectedEmbeddingModel(String? modelId) {
    _settings = _settings.copyWith(selectedEmbeddingModel: modelId);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateEnableSemanticSearch(bool value) {
    _settings = _settings.copyWith(enableSemanticSearch: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateUseStructuredOutput(bool value) {
    _settings = _settings.copyWith(useStructuredOutput: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateResponseFormat(String? format) {
    _settings = _settings.copyWith(responseFormat: format);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateHideAvatars(bool value) {
    _settings = _settings.copyWith(hideAvatars: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateAutoScrollEnabled(bool value) {
    _settings = _settings.copyWith(autoScrollEnabled: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateShowChatStarters(bool value) {
    _settings = _settings.copyWith(showChatStarters: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateUseLegacyComposer(bool value) {
    _settings = _settings.copyWith(useLegacyComposer: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateChatFontSize(double size) {
    _settings = _settings.copyWith(chatFontSize: size.clamp(10.0, 24.0));
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateChatIconSize(double size) {
    _settings = _settings.copyWith(chatIconSize: size.clamp(10.0, 24.0));
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateSelectedThemeId(String themeId) {
    _settings = _settings.copyWith(selectedThemeId: themeId);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateShowChatHeaderAvatar(bool value) {
    _settings = _settings.copyWith(showChatHeaderAvatar: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateChatBubbleAvatarRadius(double value) {
    _settings = _settings.copyWith(chatBubbleAvatarRadius: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateAvatarAboveMessage(bool value) {
    _settings = _settings.copyWith(avatarAboveMessage: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateFullWidthAssistant(bool value) {
    _settings = _settings.copyWith(fullWidthAssistant: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateWatchShowPersonas(bool value) {
    _settings = _settings.copyWith(watchShowPersonas: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateWatchAssistantInBubble(bool value) {
    _settings = _settings.copyWith(watchAssistantInBubble: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void markFullWidthAssistantNudgeShown() {
    if (_settings.fullWidthAssistantNudgeShown) return;
    _settings = _settings.copyWith(fullWidthAssistantNudgeShown: true);
    _settingsService.saveSettings(_settings);
  }

  void updateEnableToolUse(bool value) {
    _settings = _settings.copyWith(enableToolUse: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateEnableWebSearch(bool value) {
    _settings = _settings.copyWith(enableWebSearch: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updatePreferSearxng(bool value) {
    _settings = _settings.copyWith(preferSearxng: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateEnableCodeSandbox(bool value) {
    _settings = _settings.copyWith(
      enableCodeSandbox: value,
      enableToolUse: value ? true : _settings.enableToolUse,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Enable Pro Search and disable all conflicting search sources.
  /// Pro Search overrides SearXNG and any MCP servers that provide web_search/read_url.
  void enableProSearch() {
    _settings = _settings.copyWith(
      enableToolUse: true,
      enableWebSearch: true,
      preferSearxng: false,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void _attachSubscriptionListener() {
    final sub = SubscriptionService();
    _lastKnownPremium = sub.isPremium;
    _subscriptionListener ??= _onSubscriptionChanged;
    sub.removeListener(_subscriptionListener!);
    sub.addListener(_subscriptionListener!);
  }

  void _onSubscriptionChanged() {
    final isPremium = SubscriptionService().isPremium;
    if (isPremium && !_lastKnownPremium) {
      _enableProSearchAfterPremiumUpgrade();
    } else if (!isPremium && _lastKnownPremium) {
      unawaited(restoreLocalModelIfNeeded());
    }
    _lastKnownPremium = isPremium;
  }

  /// Turn on tool calling + Pro Search the first time a user becomes premium.
  void _enableProSearchAfterPremiumUpgrade() {
    var next = _settings;
    var changed = false;

    if (!next.enableToolUse) {
      next = next.copyWith(enableToolUse: true);
      changed = true;
    }
    if (!next.enableWebSearch || next.preferSearxng) {
      next = next.copyWith(enableWebSearch: true, preferSearxng: false);
      changed = true;
    }
    if (!next.enableCodeSandbox &&
        PremiumConfig.resolvedCodeSandboxMcpUrl.isNotEmpty) {
      next = next.copyWith(enableCodeSandbox: true);
      changed = true;
    }

    if (!changed) return;

    _settings = next;
    _settingsService.saveSettings(_settings);
    notifyListeners();
    debugPrint(
        '🔍 Auto-enabled Pro Search + Code Sandbox after premium upgrade');
  }

  /// Disable Pro Search (just turns off enableWebSearch for premium users).
  void disableProSearch() {
    _settings = _settings.copyWith(enableWebSearch: false);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Enable SearXNG search and disable conflicting search MCPs.
  /// When SearXNG is selected, deactivate ephemeral MCPs that duplicate search/read_url.
  void enableSearxngSearch() {
    _settings = _settings.copyWith(enableWebSearch: true);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Disable SearXNG search.
  void disableSearxngSearch() {
    _settings = _settings.copyWith(enableWebSearch: false);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateUseMcpToolsOnly(bool value) {
    _settings = _settings.copyWith(useMcpToolsOnly: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateUnlimitedToolCalls(bool value) {
    _settings = _settings.copyWith(unlimitedToolCalls: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateMcpServers(List<McpServerConfig> servers) {
    _settings = _settings.copyWith(mcpServers: servers);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateActiveMcpServerLabels(List<String>? labels) {
    _settings = _settings.copyWith(activeMcpServerLabels: labels);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateIntegratedMcps(List<IntegratedMcpConfig> mcps) {
    _settings = _settings.copyWith(integratedMcps: mcps);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void toggleIntegratedMcp(String name) {
    final currentMcps = _settings.integratedMcps ?? [];
    final updatedMcps = currentMcps.map((m) {
      if (m.name == name) {
        return IntegratedMcpConfig(name: m.name, enabled: !m.enabled);
      }
      return m;
    }).toList();

    _settings = _settings.copyWith(integratedMcps: updatedMcps);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void addIntegratedMcp(String name) {
    final currentMcps =
        List<IntegratedMcpConfig>.from(_settings.integratedMcps ?? []);
    if (!currentMcps.any((m) => m.name == name)) {
      currentMcps.add(IntegratedMcpConfig(name: name, enabled: true));
      _settings = _settings.copyWith(integratedMcps: currentMcps);
      _settingsService.saveSettings(_settings);
      notifyListeners();
    }
  }

  /// Rename an integrated MCP entry. Preserves enabled state.
  /// No-op if [oldName] is missing or [newName] already exists.
  void renameIntegratedMcp(String oldName, String newName) {
    if (oldName == newName) return;
    final currentMcps =
        List<IntegratedMcpConfig>.from(_settings.integratedMcps ?? []);
    if (currentMcps.any((m) => m.name == newName)) return;
    final idx = currentMcps.indexWhere((m) => m.name == oldName);
    if (idx < 0) return;
    currentMcps[idx] = currentMcps[idx].copyWith(name: newName);
    _settings = _settings.copyWith(integratedMcps: currentMcps);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void removeIntegratedMcp(String name) {
    final currentMcps =
        List<IntegratedMcpConfig>.from(_settings.integratedMcps ?? []);
    currentMcps.removeWhere((m) => m.name == name);
    _settings = _settings.copyWith(integratedMcps: currentMcps);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void toggleMcpServer(String label) {
    final currentActive = _settings.activeMcpServerLabels ??
        _settings.mcpServers?.map((s) => s.label).toList() ??
        [];

    final newActive = currentActive.contains(label)
        ? currentActive.where((l) => l != label).toList()
        : [...currentActive, label];

    // If all servers are now active, set to null (default = all active)
    final allLabels = _settings.mcpServers?.map((s) => s.label).toSet() ?? {};
    final isAllActive = newActive.toSet().containsAll(allLabels) &&
        allLabels.containsAll(newActive.toSet());

    _settings = _settings.copyWith(
      activeMcpServerLabels: isAllActive ? null : newActive,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateSearXngUrl(String? value) {
    _settings =
        _settings.copyWith(searxngUrl: value?.isEmpty == true ? null : value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateSearchResultsCount(int value) {
    _settings = _settings.copyWith(searchResultsCount: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateAutoUnloadTtlMinutes(int? minutes) {
    _settings = _settings.copyWith(autoUnloadTtlMinutes: minutes);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateLoadContextLength(int? contextLength) {
    // Kept for callers; always mirrors [updateContextWindow] so the two
    // settings cannot diverge.
    if (contextLength == null || contextLength <= 0) {
      updateContextWindow(_settings.contextWindow);
      return;
    }
    updateContextWindow(contextLength);
  }

  /// Keep chat + load context sizes identical (legacy settings may differ).
  void _reconcileContextWindowWithLoad() {
    final load = _settings.loadContextLength;
    final unified = (load != null && load > 0) ? load : _settings.contextWindow;
    if (_settings.contextWindow == unified &&
        _settings.loadContextLength == unified) {
      return;
    }
    _settings = _settings.copyWith(
      contextWindow: unified,
      loadContextLength: unified,
    );
    _settingsService.saveSettings(_settings);
  }

  void updateLoadEvalBatchSize(int? batchSize) {
    _clearModelsPreferLoadedParams();
    _settings = _settings.copyWith(loadEvalBatchSize: batchSize);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateLoadFlashAttention(bool value) {
    _clearModelsPreferLoadedParams();
    _settings = _settings.copyWith(loadFlashAttention: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateLoadNumExperts(int? numExperts) {
    _clearModelsPreferLoadedParams();
    _settings = _settings.copyWith(loadNumExperts: numExperts);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateLoadOffloadKvCache(bool value) {
    _clearModelsPreferLoadedParams();
    _settings = _settings.copyWith(loadOffloadKvCache: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  // --- Voice Settings ---

  void updateVoiceAutoRead(bool value) {
    _settings = _settings.copyWith(voiceAutoRead: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceSpeechRate(double value) {
    _settings = _settings.copyWith(voiceSpeechRate: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoicePitch(double value) {
    _settings = _settings.copyWith(voicePitch: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceName(String? value) {
    _settings = _settings.copyWith(voiceName: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceLanguage(String value) {
    _settings = _settings.copyWith(voiceLanguage: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceSttLanguage(String value) {
    _settings = _settings.copyWith(voiceSttLanguage: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceAutoSend(bool value) {
    _settings = _settings.copyWith(voiceAutoSend: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceSttPauseForSeconds(int value) {
    _settings = _settings.copyWith(voiceSttPauseForSeconds: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceSttListenForSeconds(int value) {
    _settings = _settings.copyWith(voiceSttListenForSeconds: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceSttProvider(String value) {
    _settings = _settings.copyWith(voiceSttProvider: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateWhisperModelId(String value) async {
    if (_settings.whisperModelId == value) return;
    WhisperModelManager.instance.setSelectedModelId(value);
    _settings = _settings.copyWith(whisperModelId: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
    // Drop any loaded Whisper workers so the next listen/transcribe uses
    // the newly selected size.
    try {
      await WhisperSttService.instance.resetEngine();
    } catch (_) {}
    try {
      await WhisperFileTranscriber.instance.disposeWorkerForModelChange();
    } catch (_) {}
  }

  void updateVoiceContinuousConversation(bool value) {
    _settings = _settings.copyWith(voiceContinuousConversation: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceTtsProvider(String value) {
    _settings = _settings.copyWith(voiceTtsProvider: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceKokoroSpeakerId(int value) {
    _settings = _settings.copyWith(voiceKokoroSpeakerId: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceKokoroSpeed(double value) {
    _settings = _settings.copyWith(voiceKokoroSpeed: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceElevenLabsApiKey(String? value) {
    final trimmed = value?.trim();
    _settings = _settings.copyWith(
      voiceElevenLabsApiKey:
          (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceElevenLabsVoiceId(String? value) {
    final trimmed = value?.trim();
    _settings = _settings.copyWith(
      voiceElevenLabsVoiceId:
          (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceElevenLabsModelId(String value) {
    _settings = _settings.copyWith(voiceElevenLabsModelId: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceGrokApiKey(String? value) {
    final trimmed = value?.trim();
    _settings = _settings.copyWith(
      voiceGrokApiKey: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceGrokVoiceId(String? value) {
    final trimmed = value?.trim();
    _settings = _settings.copyWith(
      voiceGrokVoiceId: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceRemoteKokoroUrl(String? value) {
    _settings = _settings.copyWith(voiceRemoteKokoroUrl: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceRemoteKokoroModel(String? value) {
    _settings = _settings.copyWith(voiceRemoteKokoroModel: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateVoiceCallMode(bool value) {
    _settings = _settings.copyWith(voiceCallMode: value);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void completeOnboarding() {
    _settings = _settings.copyWith(hasCompletedOnboarding: true);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateAiExperienceLevel(String? level) {
    _settings = _settings.copyWith(aiExperienceLevel: level);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Settings Basic vs Advanced (see [AppSettings.isAdvancedSettings]).
  bool get isAdvancedSettings => _settings.isAdvancedSettings;

  void setAdvancedSettings(bool advanced) {
    updateAiExperienceLevel(advanced ? 'power' : 'beginner');
  }

  void updatePreferredUserName(String? name) {
    final trimmed = name?.trim();
    _settings = _settings.copyWith(
      preferredUserName: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void completeAudioSetup() {
    _settings = _settings.copyWith(hasCompletedAudioSetup: true);
    _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Download a model from LM Studio catalog or Hugging Face
  Future<Map<String, dynamic>> downloadModel(String modelId,
      {String? quantization, String? displayLabel}) async {
    try {
      _downloadModelLabel = displayLabel ?? modelId.split('/').last;
      final result = await _lmStudioService.downloadModel(
        baseUrl: _settings.serverUrl,
        model: modelId,
        quantization: quantization,
        apiToken: _settings.apiToken,
      );

      // Start tracking download
      if (result['status'] != 'already_downloaded') {
        _downloadJobId = result['job_id'] as String?;
        _isDownloading = true;
        notifyListeners();
        await _persistLmStudioDownloadJob();
        unawaited(DownloadProgressActivity.instance.start(
          displayName: _downloadModelLabel ?? 'Hugging Face',
        ));
        _pollDownloadStatus();
      }

      return result;
    } catch (e) {
      _connectionError = 'Failed to download model: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get download status for a job
  Future<Map<String, dynamic>> getDownloadStatus(String jobId) async {
    try {
      return await _lmStudioService.getDownloadStatus(
        baseUrl: _settings.serverUrl,
        jobId: jobId,
        apiToken: _settings.apiToken,
      );
    } catch (e) {
      _connectionError = 'Failed to get download status: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update FAB position
  void updateFabPosition(Offset position) {
    _fabPosition = position;
    notifyListeners();
  }

  /// Poll download status
  Future<void> _pollDownloadStatus() async {
    if (_downloadJobId == null) return;

    var consecutiveFailures = 0;
    while (_isDownloading) {
      try {
        // LM Studio often returns an empty completion if a status GET overlaps
        // an in-flight chat stream. Wait it out; the download still runs on LMS.
        if (LMStudioService.hasActiveStreams) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        final status = await _lmStudioService.getDownloadStatus(
          baseUrl: _settings.serverUrl,
          jobId: _downloadJobId!,
          apiToken: _settings.apiToken,
        );
        if (!_isDownloading) break;
        consecutiveFailures = 0;

        // debugPrint('Download Status Response: $status');

        _downloadStatus = status;
        notifyListeners();

        final downloaded = status['downloaded_bytes'] as num?;
        final total = status['total_size_bytes'] as num?;
        final progress = (downloaded != null && total != null && total > 0)
            ? downloaded / total
            : 0.0;
        final pct = (progress * 100).round();
        unawaited(DownloadProgressActivity.instance.update(
          progress: progress,
          statusText: pct > 0 ? '$pct%' : 'Downloading…',
        ));

        final statusStr = status['status'] as String?;
        if (lmStudioDownloadStatusIsTerminal(statusStr)) {
          _isDownloading = false;
          _downloadModelLabel = null;
          await _clearLmStudioDownloadJob();
          notifyListeners();
          final cancelled = statusStr == 'cancelled' || statusStr == 'canceled';
          unawaited(DownloadProgressActivity.instance.end(
            success: statusStr == 'completed',
            cancelled: cancelled,
          ));

          if (!cancelled) {
            await loadAvailableModels();
          }
          break;
        }

        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        consecutiveFailures++;
        debugPrint('Status check failed ($consecutiveFailures): $e');
        if (consecutiveFailures >= 5) {
          _isDownloading = false;
          await _clearLmStudioDownloadJob();
          notifyListeners();
          unawaited(DownloadProgressActivity.instance.end(success: false));
          break;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Stop an in-flight LM Studio / Hugging Face download.
  ///
  /// Returns true when LM Studio accepted the cancel.
  Future<bool> cancelLmStudioDownload() {
    final existing = _lmStudioCancelInFlight;
    if (existing != null) return existing;
    final future = _cancelLmStudioDownloadImpl();
    _lmStudioCancelInFlight = future;
    unawaited(future.whenComplete(() {
      if (identical(_lmStudioCancelInFlight, future)) {
        _lmStudioCancelInFlight = null;
      }
    }));
    return future;
  }

  Future<bool> _cancelLmStudioDownloadImpl() async {
    final jobId = _downloadJobId;
    if (jobId == null || jobId.isEmpty || !_isDownloading) return false;
    try {
      final ok = await _lmStudioService.cancelDownload(
        baseUrl: _settings.serverUrl,
        jobId: jobId,
        apiToken: _settings.apiToken,
      );
      if (!ok) return false;
      _isDownloading = false;
      _downloadStatus = null;
      _downloadModelLabel = null;
      await _clearLmStudioDownloadJob();
      notifyListeners();
      unawaited(DownloadProgressActivity.instance.end(
        success: false,
        cancelled: true,
      ));
      return true;
    } catch (e) {
      debugPrint('SettingsProvider: cancel download failed: $e');
      return false;
    }
  }

  /// Get available quantizations from Hugging Face via LM Studio's parser.
  Future<List<String>> getLmStudioHfQuantizations(String repoOrUrl) async {
    try {
      final hfUrl = repoOrUrl.startsWith('http')
          ? repoOrUrl
          : 'https://huggingface.co/$repoOrUrl';
      return await _lmStudioService.listHfDownloadQuantizations(
        baseUrl: _settings.serverUrl,
        modelUrl: hfUrl,
        apiToken: _settings.apiToken,
      );
    } catch (e) {
      debugPrint('SettingsProvider: LM Studio HF quants failed: $e');
      rethrow;
    }
  }

  /// Get available quantizations from HuggingFace repository
  Future<List<Map<String, dynamic>>> getHuggingFaceQuantizations(
      String repoUrl) async {
    try {
      return await _lmStudioService.getHuggingFaceQuantizations(repoUrl);
    } catch (e) {
      _connectionError = 'Failed to fetch quantizations: $e';
      notifyListeners();
      rethrow;
    }
  }
}
