import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/remote_host_backends.dart';
import '../services/export_service.dart';
import '../services/chat_import_service.dart';
import '../services/local_network_service.dart';
import '../services/review_service.dart';
import '../services/builtin_persona_service.dart';
import 'appearance_settings_screen.dart';
import '../widgets/feature_request_settings_tile.dart';
import 'feature_requests_screen.dart';
import 'model_parameters_screen.dart';
import 'model_management_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'tool_settings_screen.dart';
import 'system_prompts_screen.dart';
import 'voice_settings_screen.dart';
import 'transcription_settings_screen.dart';
import 'image_generation_settings_screen.dart';
import 'group_chat_setup_screen.dart';
import 'subscription_screen.dart';
import 'cloud_backup_screen.dart';
import 'account_screen.dart';
import 'analytics_screen.dart';
import 'memory_screen.dart';
import 'app_lock_settings_screen.dart';
import '../services/app_lock_service.dart';
import 'remote_access_screen.dart';
import 'changelog_screen.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/theme_extensions.dart';
import '../utils/layout_utils.dart';
import '../utils/localhost_connection_error.dart';
import '../utils/lan_server_error.dart';
import '../utils/on_device_engine_labels.dart';
import '../widgets/setup_help_banner.dart';
import '../l10n/app_localizations.dart';
import '../widgets/global_download_fab.dart';
import 'local_models_screen.dart';
import '../models/lm_studio_model.dart';
import '../services/on_device_llm_service.dart';
import '../services/on_device_mlx_endpoint.dart';
import '../services/local_model_download_service.dart';
import '../services/lm_studio_discovery_service.dart';
import '../services/lm_studio_service.dart';

import 'widget_settings_screen.dart';
import 'siri_shortcuts_screen.dart';
import 'watch_settings_screen.dart';
import '../services/network_status_service.dart';
import '../utils/connection_issue.dart';
import '../widgets/network_status_banner.dart';
import 'providers_screen.dart';
import '../models/server_profile.dart';
import '../services/server_profile_service.dart';
import '../widgets/add_server_sheet.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/on_device_engine_sheet.dart';
import '../widgets/server_connect_sheet.dart';
import '../widgets/shared_host_update_dialog.dart';
import '../services/image_generation_facade.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_blur.dart';
import '../widgets/glass_page_header.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/home_glass_header.dart';
import '../widgets/remote_access_switch.dart';
import '../desktop/desktop_platform.dart';
import '../desktop/ui/desktop_host_screen.dart';
import '../desktop/runtime/desktop_runtime_manager.dart';
import 'settings_nav.dart';
import '../pro/pro_features.dart';

part '../pro/settings/settings_screen_pro.dart';

/// Stable ids for settings sections whose localized titles could collide
/// after uppercasing (e.g. German voice "Sprache" vs language "SPRACHE").
abstract final class SettingsSectionId {
  static const voice = 'voice';
  static const transcription = 'transcription';
  static const language = 'language';
}

class SettingsScreen extends StatefulWidget {
  final bool showConnectionError;
  final String? connectionError;

  /// When true, skips the Scaffold/glass header chrome and renders the
  /// two-column settings layout directly (for embedding in DesktopShell).
  final bool embedded;
  final String? initialNavId;

  const SettingsScreen({
    super.key,
    this.showConnectionError = false,
    this.connectionError,
    this.embedded = false,
    this.initialNavId,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _apiTokenController = TextEditingController();
  final _cloudApiKeyController = TextEditingController();
  final _cloudBaseUrlController = TextEditingController();
  bool _showServerError = false;
  bool _isTestingConnection = false;
  bool _obscureApiToken = true;
  bool _obscureCloudKey = true;
  String _appVersion = '';
  // null = LM Studio (local), non-null = cloud provider
  CloudApiType? _selectedCloudType;
  // Remembers the LM Studio model while a cloud provider is active,
  // so switching back restores it automatically.
  String? _savedLocalModel;
  bool _isTestingCloudConnection = false;
  bool _isScanningServers = false;

  /// Per-profile connection probe results from "Test servers".
  /// `null` = not tested yet; `true`/`false` = last probe outcome.
  final Map<String, bool> _serverProbeResults = {};
  bool _probingServers = false;

  /// GlobalKeys for each top-level `_buildSection` so the iPad sidebar can
  /// scroll the right pane to a tapped section via `Scrollable.ensureVisible`.
  /// Keyed by stable section id (see [SettingsSectionId] or uppercased title).
  final Map<String, GlobalKey> _sectionKeys = {};

  /// Sidebar labels keyed by section id.
  final Map<String, String> _sectionLabels = {};

  /// Ordered list of section ids for the iPad sidebar.
  /// Populated in the same order as `_buildSection` calls during build.
  final List<String> _sectionOrder = [];

  /// Currently highlighted nav id in the Mac/iPad settings tree.
  String? _activeSidebarSection;

  /// Expanded group ids in the settings tree.
  final Set<String> _expandedNavGroups = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialNavId != null) {
      _activeSidebarSection = widget.initialNavId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.initialNavId == null) return;
        _selectNavId(
          widget.initialNavId!,
          kind: widget.initialNavId == SettingsNavId.support
              ? SettingsNavKind.hub
              : SettingsNavKind.screen,
        );
      });
    }
    final settingsProvider = context.read<SettingsProvider>();
    _serverUrlController.text = settingsProvider.settings.serverUrl;
    _apiTokenController.text = settingsProvider.settings.apiToken ?? '';
    // Restore active cloud provider selection
    _initCloudProviderState();
    // Load app version from package info
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _appVersion = 'Version ${info.version} (Build ${info.buildNumber})';
        });
      }
    });
    if (settingsProvider.settings.isRemoteActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settingsProvider.refreshRemoteHostStatus();
      });
    }
    // Show error state if navigated here due to connection issues
    if (widget.showConnectionError) {
      _showServerError = true;
      // Show the error dialog after a brief delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final kind = settingsProvider.settings.activeProviderKind;
          CloudApiType? localType = CloudApiType.forProviderKind(kind);
          _showConnectionHelpDialog(
            context,
            widget.connectionError ??
                settingsProvider.connectionError ??
                'Connection failed',
            isLocalServer: localType != null,
            localServerType: localType,
          );
        }
      });
    }
  }

  void _initCloudProviderState() {
    final cloud = CloudApiService();
    final isPremium = SubscriptionService().isPremium;
    final active = cloud.activeProvider;
    if (active != null && (isPremium || !active.type.isPremium)) {
      _selectedCloudType = active.type;
      _cloudApiKeyController.text = active.apiKey;
      _cloudBaseUrlController.text = active.baseUrl ?? '';
    }
    // Restore saved LM Studio model so switching back works even after restart.
    SharedPreferences.getInstance().then((prefs) {
      _savedLocalModel = prefs.getString('saved_local_model');
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiTokenController.dispose();
    _cloudApiKeyController.dispose();
    _cloudBaseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsProviderForError = context.watch<SettingsProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topBg = isDark
        ? GlassSettingsScaffold.defaultTopDark
        : GlassSettingsScaffold.defaultTopLight;
    final headerH = GlassPageHeader.heightFor(context);

    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Consumer<SettingsProvider>(
          builder: _buildSettingsContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: topBg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: headerH),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Consumer<SettingsProvider>(
                    builder: _buildSettingsContent,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildGlassHeader(context, l10n, settingsProviderForError),
          ),
          GlobalDownloadFAB(headerBottom: headerH),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(BuildContext context, AppLocalizations l10n,
      SettingsProvider settingsProviderForError) {
    return GlassPageHeader(
      title: l10n.settingsTitle,
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        Tooltip(
          message: l10n.settingsAdvancedModeTooltip,
          child: _SettingsAdvancedGlassToggle(
            value: settingsProviderForError.isAdvancedSettings,
            label: l10n.settingsAdvancedMode,
            onChanged: settingsProviderForError.setAdvancedSettings,
          ),
        ),
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, snap) {
            final user = snap.data;
            final signedIn = user != null &&
                !(user.isAnonymous && user.providerData.isEmpty);
            return _proAccountDecoration(
              context,
              button: (outline) => GlassCircleIconButton(
                tooltip: l10n.account,
                isActive: signedIn,
                outline: outline,
                onTap: () {
                  _openSettingsScreen(
                    SettingsNavId.account,
                    (_) => const AccountScreen(),
                  );
                },
                child: Icon(
                  signedIn
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        if (DesktopPlatform.supportsHostMode)
          GlassCircleIconButton(
            tooltip: 'Connect with phone',
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.desktopHost,
                (_) => const DesktopHostScreen(),
              );
            },
            child: const Icon(Icons.phonelink_rounded,
                size: 18, color: Colors.white),
          )
        else if (ProFeatures.isPro)
          Builder(
            builder: (context) {
              final remote = settingsProviderForError.settings;
              final paired = remote.remoteServerUrl != null;
              final connected = remote.isRemoteActive;
              return GlassCircleIconButton(
                tooltip: connected
                    ? l10n.connectedRemotely
                    : (paired ? l10n.remoteAccess : 'Pair with computer'),
                isActive: connected || paired,
                tint: (connected || paired) ? const Color(0xFF30D158) : null,
                onTap: () {
                  _openSettingsScreen(
                    SettingsNavId.remoteAccess,
                    (_) => RemoteAccessScreen(startScanning: !paired),
                  );
                },
                child: const Icon(Icons.phonelink_rounded,
                    size: 18, color: Colors.white),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSettingsContent(
      BuildContext context, SettingsProvider settingsProvider, Widget? child) {
    final l10n = AppLocalizations.of(context);
    final isOnDeviceProvider =
        settingsProvider.settings.activeProviderKind == 'onDeviceGguf' ||
            settingsProvider.settings.activeProviderKind == 'onDeviceMlx';
    final usbWaiting = settingsProvider.settings.usbModeEnabled &&
        !settingsProvider.isUsbPeerConnected;
    final hasConnectionError = !isOnDeviceProvider &&
        !usbWaiting &&
        (_showServerError || settingsProvider.connectionError != null);

    _syncProviderPickerState(settingsProvider);
    if (!settingsProvider.settings.isRemoteActive) {
      final currentUrl = settingsProvider.settings.serverUrl;
      if (_serverUrlController.text != currentUrl) {
        _serverUrlController.text = currentUrl;
      }
    }
    _sectionOrder.clear();
    _sectionLabels.clear();
    final isAdvanced = settingsProvider.isAdvancedSettings;
    final settingsSections = <Widget>[
      // Server Configuration Section
      _buildSection(
        context,
        title: l10n.serverSection,
        hasError: hasConnectionError,
        titleTrailing: _ServerSectionTestAction(
          probing: _probingServers,
          onTap: () => _probeAllServers(context),
        ),
        children: [
          _buildRecentServersSection(context, settingsProvider),
          // Debug builds only: fake mobile data / offline / Wi‑Fi so the
          // chat pill, preflight and "Not delivered" flow can be checked on
          // a simulator.
          if (kDebugMode) const _DebugNetworkSimulatorTile(),
        ],
      ),

      // Desktop host (Share with phone) — Mac/Windows only.
      // Phone Remote Access client stays in its own section below.
      if (DesktopPlatform.supportsHostMode)
        _buildSection(
          context,
          title: 'DESKTOP HOST',
          children: [
            ListTile(
              leading: Icon(
                Icons.phonelink_rounded,
                color: DesktopRuntimeManager.instance.isRunning
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Connect with phone'),
              subtitle: Text(
                'Host models on ${DesktopPlatform.thisMachine} for LM Mini on your phone',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSettingsScreen(
                SettingsNavId.desktopHost,
                (_) => const DesktopHostScreen(),
              ),
            ),
          ],
        ),

      // Remote Access Section (premium only, shown first after server)
      if (ProFeatures.isPro)
        _buildSection(
          context,
          title: l10n.remoteAccess,
          children: [
            if (settingsProvider.settings.activeProviderKind ==
                    'onDeviceGguf' ||
                settingsProvider.settings.activeProviderKind == 'onDeviceMlx')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.onDeviceRemoteImageOnly,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.cloud),
                  if (settingsProvider.settings.isRemoteActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(l10n.remoteAccess),
              subtitle: Text(
                RemoteAccessSwitch.isPaired(settingsProvider)
                    ? remoteAccessSwitchSubtitle(
                        l10n, settingsProvider.settings.isRemoteActive)
                    : settingsProvider.settings.isRemoteActive
                        ? l10n.connectedRemotely
                        : settingsProvider.settings.remoteServerUrl != null
                            ? l10n.pairedNotActive
                            : l10n.accessLmStudioAnywhere,
              ),
              // Paired: quick on/off without opening Remote Access.
              trailing: RemoteAccessSwitch.isPaired(settingsProvider)
                  ? const RemoteAccessSwitch()
                  : const Icon(Icons.chevron_right),
              onTap: () {
                _openSettingsScreen(
                  SettingsNavId.remoteAccess,
                  (_) => const RemoteAccessScreen(),
                );
              },
            ),
          ],
        ),

      // Model Management Section
      _buildSection(
        context,
        title: l10n.modelsSection,
        children: [
          if (settingsProvider.settings.activeProviderKind == 'onDeviceGguf' ||
              settingsProvider.settings.activeProviderKind == 'onDeviceMlx')
            ListenableBuilder(
              listenable: LocalModelDownloadService.instance,
              builder: (context, _) {
                final spec = OnDeviceLLMService.instance
                    .specForSettings(settingsProvider.settings);
                final isReady = spec != null &&
                    LocalModelDownloadService.instance
                            .entryById(spec.id)
                            ?.status ==
                        LocalModelStatus.ready;
                // Always reflect the user's CURRENT engine
                // selection, not the engine of the (possibly
                // stale) selected local model. Otherwise picking
                // MLX but having a fllama model id stored would
                // mis-label the row as "fllama".
                final engineLabel =
                    settingsProvider.settings.activeProviderKind ==
                            'onDeviceMlx'
                        ? 'MLX-Swift'
                        : 'fllama (llama.cpp)';
                final subtitle = spec == null
                    ? 'Engine: $engineLabel • ${l10n.noModelSelected}'
                    : isReady
                        ? 'Connected • Engine: $engineLabel • ${spec.displayName}'
                        : 'Engine: $engineLabel • ${spec.displayName} (not downloaded)';
                return ListTile(
                  leading: Stack(
                    children: [
                      Icon(
                        Icons.smartphone,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      if (isReady)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(l10n.onDeviceModels),
                  subtitle: Text(subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSettingsScreen(
                    SettingsNavId.modelsSelection,
                    (_) => const LocalModelsScreen(),
                  ),
                );
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.model_training),
              title: Text(l10n.modelSelection),
              subtitle: Text(
                () {
                  final cloud = CloudApiService();
                  final kind = settingsProvider.settings.activeProviderKind;
                  final useCloudModel =
                      SettingsProvider.isCloudProviderKind(kind) &&
                          settingsProvider.isCloudProviderReady();
                  final m = useCloudModel
                      ? (cloud.activeProvider!.selectedModel ??
                          settingsProvider.settings.selectedModel)
                      : settingsProvider.settings.selectedModel;
                  if (m == null) return l10n.noModelSelected;
                  // Prefer catalog displayName when available.
                  for (final model in settingsProvider.availableModels) {
                    if (model.id == m) return model.displayName;
                  }
                  return LMStudioModel.friendlyLabel(m);
                }(),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSettingsScreen(
                SettingsNavId.modelsSelection,
                (_) => const ModelManagementScreen(),
              ),
            ),
          if (isAdvanced)
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(l10n.modelParameters),
              subtitle: Text(l10n.modelParametersSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSettingsScreen(
                SettingsNavId.modelsParameters,
                (_) => const ModelParametersScreen(),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: Text(l10n.systemPrompts),
            subtitle: Text(
              BuiltinPersonaService.isDefaultId(
                      settingsProvider.settings.selectedSystemPromptId)
                  ? l10n.defaultPrompt
                  : (settingsProvider.settings.selectedSystemPrompt?.name ??
                      l10n.defaultPrompt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.modelsPersonas,
                (_) => const SystemPromptsScreen(),
              );
            },
          ),
        ],
      ),

      // Appearance Section
      _buildSection(
        context,
        title: l10n.appearanceSection,
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(l10n.appearance),
            subtitle: Text(l10n.appearanceSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.appearance,
                (_) => const AppearanceSettingsScreen(),
              );
            },
          ),
        ],
      ),

      // Image Generation Section
      _buildSection(
        context,
        title: l10n.imageGeneration,
        children: [
          ListTile(
            leading: Icon(
              Icons.image,
              color: settingsProvider.settings.imageGenEnabled
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(l10n.imageGeneration),
            subtitle: Text(
              settingsProvider.settings.imageGenEnabled
                  ? (settingsProvider.settings.isRemoteActive
                      ? '${imageGenBackendLabel(settingsProvider.settings)} via ${RemoteHostBackends.transportLabel(settingsProvider.settings)}'
                      : (settingsProvider.settings.imageGenServerUrl.isNotEmpty
                          ? l10n.imageGenEnabled(
                              settingsProvider.settings.imageGenServerUrl)
                          : l10n.imageGenNotConfigured))
                  : l10n.disabled,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.imageGeneration,
                (_) => const ImageGenerationSettingsScreen(),
              );
            },
          ),
        ],
      ),

      // Voice Section
      _buildSection(
        context,
        sectionId: SettingsSectionId.voice,
        title: l10n.voiceSection,
        children: [
          ListTile(
            leading: const Icon(Icons.headset_mic),
            title: Text(l10n.voiceSettings),
            subtitle: Text(l10n.voiceSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.voice,
                (_) => const VoiceSettingsScreen(),
              );
            },
          ),
        ],
      ),

      // Transcription Section
      _buildSection(
        context,
        sectionId: SettingsSectionId.transcription,
        title: l10n.transcription,
        children: [
          ListTile(
            leading: const Icon(Icons.transcribe_rounded),
            title: Text(l10n.transcription),
            subtitle: const Text(
              'Whisper downloads and transcribed files',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.transcription,
                (_) => const TranscriptionSettingsScreen(),
              );
            },
          ),
        ],
      ),

      // Widgets Section — iOS/Android home-screen widgets only.
      if (Platform.isIOS || Platform.isAndroid)
        _buildSection(
          context,
          title: l10n.widgetSettings,
          children: [
            ListTile(
              leading: const Icon(Icons.widgets),
              title: Text(l10n.widgetSettings),
              subtitle: Text(l10n.widgetSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _openSettingsScreen(
                  SettingsNavId.widgets,
                  (_) => const WidgetSettingsScreen(),
                );
              },
            ),
          ],
        ),

      if (Platform.isIOS)
        _buildSection(
          context,
          title: 'Apple Watch',
          children: [
            ListTile(
              leading: const Icon(Icons.watch),
              title: const Text('Apple Watch'),
              subtitle: const Text(
                'Personas on the watch home screen, and whether assistant replies use a bubble.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _openSettingsScreen(
                  SettingsNavId.appleWatch,
                  (_) => const WatchSettingsScreen(),
                );
              },
            ),
          ],
        ),

      // Siri Shortcuts — App Intents (iOS 16+) + URL deep links
      if (Platform.isIOS)
        _buildSection(
          context,
          title: 'Siri & Shortcuts',
          children: [
            ListTile(
              leading: const Icon(Icons.bolt),
              title: Text(l10n.setUpShortcuts),
              subtitle: const Text(
                'Voice search, voice chat, sample Shortcuts, and the lmmini:// URL scheme.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _openSettingsScreen(
                  SettingsNavId.siri,
                  (_) => const SiriShortcutsScreen(),
                );
              },
            ),
          ],
        ),

      // Language Section
      _buildSection(
        context,
        sectionId: SettingsSectionId.language,
        title: l10n.languageSection,
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle:
                Text(_getLanguageDisplayName(settingsProvider.settings.locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, settingsProvider),
          ),
        ],
      ),

      // Support Section
      _buildSection(
        context,
        title: l10n.supportSection,
        children: [
          // Rate the app
          ListTile(
            leading: const Icon(Icons.star_rate_rounded, color: Colors.amber),
            title: Text(l10n.rateApp),
            subtitle: Text(l10n.rateAppSubtitle),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => ReviewService().openStoreListing(),
          ),
          // Only show Buy Me a Coffee after 7 days of use
          // if (settingsProvider.showSupportSection)
          // ListTile(
          //   leading: const Text('☕', style: TextStyle(fontSize: 24)),
          //   title: Text(l10n.buyMeACoffee),
          //   subtitle: Text(l10n.buyMeACoffeeSubtitle),
          //   trailing: const Icon(Icons.favorite, color: Colors.pink),
          //   onTap: () => _launchBuyMeACoffee(),
          // ),
          FeatureRequestSettingsTile(
            onOpen: () => _openSettingsScreen(
              SettingsNavId.supportFeatureRequests,
              (_) => const FeatureRequestsScreen(),
            ),
          ),
        ],
      ),

      // Data Management Section
      _buildSection(
        context,
        title: l10n.dataSection,
        children: [
          // Cloud Backup — premium feature
          if (ProFeatures.isPro)
            ListTile(
              leading: const Icon(Icons.enhanced_encryption),
              title: _proTitle(l10n.cloudBackup),
              subtitle: Text(l10n.encryptedBackupRestore),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSettingsScreen(
                SettingsNavId.dataCloudBackup,
                (_) => const CloudBackupScreen(),
              ),
            ),
          // Analytics — premium + Advanced (technical dashboard)
          if (isAdvanced && ProFeatures.isPro)
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: _proTitle(l10n.analytics),
              subtitle: Text(l10n.analyticsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSettingsScreen(
                SettingsNavId.dataAnalytics,
                (_) => const AnalyticsScreen(),
              ),
            ),
          // Memory — premium feature
          if (ProFeatures.isPro)
            ListTile(
              leading: const Icon(Icons.psychology_outlined),
              title: _proTitle(l10n.memory),
              subtitle:
                  Text(l10n.memoryItemCount(MemoryService().items.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSettingsScreen(
                SettingsNavId.dataMemory,
                (_) => const MemoryScreen(),
              ),
            ),
          if (ProFeatures.included)
            ListenableBuilder(
              listenable: AppLockService.instance,
              builder: (context, _) {
                final lock = AppLockService.instance;
                return ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: _proTitle(l10n.appLock),
                  subtitle: Text(
                    lock.isEnabled
                        ? l10n.appLockSubtitleOn(
                            _appLockTimeoutLabel(l10n, lock.timeoutSeconds),
                          )
                        : l10n.appLockSubtitleOff,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSettingsScreen(
                    SettingsNavId.dataAppLock,
                    (_) => const AppLockSettingsScreen(),
                  ),
                );
              },
            ),
          if (isAdvanced) ...[
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(l10n.exportAllChats),
              subtitle: Text(l10n.exportAllChatsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportAllChats(context),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(l10n.importChats),
              subtitle: Text(l10n.importChatsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _importChats(context),
            ),
          ],
        ],
      ),

      // Advanced Features Section
      _buildSection(
        context,
        title: l10n.advancedSection,
        children: [
          if (isAdvanced)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.showRuntimeInfo),
              subtitle: Text(l10n.showRuntimeInfoSubtitle),
              trailing: Switch(
                value: settingsProvider.settings.showRuntimeInfo,
                onChanged: (value) =>
                    settingsProvider.updateShowRuntimeInfo(value),
              ),
            ),
          // Free users always share anonymized Arena speed rows.
          // Pro may opt out.
          if (SubscriptionService().isPremium)
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: Text(l10n.shareArenaSpeedResults),
              subtitle: const Text(
                'Anonymous device + model + speed only. No prompts or answers.',
              ),
              trailing: Switch(
                value: settingsProvider.settings.arenaShareAnonymousResults,
                onChanged: (value) => settingsProvider.updateSettings(
                  settingsProvider.settings.copyWith(
                    hasAcceptedArenaDataShare: true,
                    arenaShareAnonymousResults: value,
                  ),
                ),
              ),
            ),
          // Live Activity (iOS) / background generation (Android)
          if (ProFeatures.included &&
              (Platform.isIOS || Platform.isAndroid) &&
              SubscriptionService().isPremium)
            ListTile(
              leading: const Icon(Icons.broadcast_on_personal),
              title: Text(
                Platform.isAndroid
                    ? l10n.liveActivityTitleAndroid
                    : l10n.liveActivityTitle,
              ),
              subtitle: Text(
                Platform.isAndroid
                    ? l10n.liveActivityDescriptionAndroid
                    : l10n.liveActivityDescription,
              ),
              trailing: Switch(
                value: settingsProvider.settings.liveActivityEnabled,
                onChanged: (value) async {
                  if (Platform.isAndroid && value) {
                    final status = await Permission.notification.request();
                    if (!status.isGranted) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.liveActivityNotificationDenied,
                          ),
                        ),
                      );
                      return;
                    }
                  }
                  settingsProvider.updateLiveActivityEnabled(value);
                },
              ),
            ),
          // Embedding model & semantic search — only for LM Studio local
          // (skip when on-device active; embedding flows go through LM Studio).
          if (isAdvanced &&
              _selectedCloudType == null &&
              settingsProvider.settings.activeProviderKind != 'onDeviceGguf' &&
              settingsProvider.settings.activeProviderKind !=
                  'onDeviceMlx') ...[
            _buildEmbeddingModelTile(settingsProvider),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(l10n.enableSemanticSearch),
              subtitle: Text(l10n.enableSemanticSearchSubtitle),
              trailing: Switch(
                value: settingsProvider.settings.enableSemanticSearch,
                onChanged: (value) =>
                    settingsProvider.updateEnableSemanticSearch(value),
              ),
            ),
            _buildAutoUnloadTile(context, settingsProvider),
          ],

          // Tools & Advanced - Link to dedicated screen
          ListTile(
            leading: const Icon(Icons.build_circle),
            title: Text(l10n.toolCalling),
            subtitle: Text(
              settingsProvider.settings.enableToolUse
                  ? l10n.toolCallingEnabled
                  : l10n.toolCallingDisabled,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.advancedTools,
                (_) => const ToolSettingsScreen(),
              );
            },
          ),
        ],
      ),

      // Pro Features Section (shown for non-premium users; premium users see features inline)
      ..._proFeaturesSection(context),

      // Legal Section
      _buildSection(
        context,
        title: l10n.legalSection,
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(l10n.documentationTitle),
            subtitle: Text(l10n.documentationSubtitle),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final Uri url = Uri.parse('https://lmmini.com/docs.html');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.couldNotOpenLink)),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.privacyPolicy),
            subtitle: Text(l10n.privacyPolicySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.legalPrivacy,
                (_) => const PrivacyPolicyScreen(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(l10n.termsOfService),
            subtitle: Text(l10n.termsOfServiceSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.legalTerms,
                (_) => const TermsOfServiceScreen(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.changelogTitle),
            subtitle: Text(l10n.changelogSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openSettingsScreen(
                SettingsNavId.legalChangelog,
                (_) => const ChangelogScreen(),
              );
            },
          ),
          if (!ProFeatures.included)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('LM Mini Pro'),
              subtitle: const Text('Available in the official app'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSettingsScreen(
                SettingsNavId.pro,
                (_) => const SubscriptionScreen(),
              ),
            ),
        ],
      ),

      // App Version Footer
      const SizedBox(height: 48),
      Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final Uri url = Uri.parse('https://neuro9.net');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.couldNotOpenLink)),
                  );
                }
              }
            },
            child: Column(
              children: [
                Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _appVersion.isEmpty ? '...' : _appVersion,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appTagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.7),
                        decoration: TextDecoration.none,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 32),
    ];

    // Mac / iPad: tree sidebar + detail pane.
    if (widget.embedded || prefersWideSettingsLayout(context)) {
      return _buildTwoColumnSettings(
        context,
        settingsSections,
        isAdvanced: isAdvanced,
      );
    }
    // Sheet already sits below the glass header — strip status-bar
    // padding so ListView doesn't leave a blank band above SERVER.
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        children: settingsSections,
      ),
    );
  }

  Widget _buildApiTokenField(SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final hasToken = _apiTokenController.text.isNotEmpty;
    return Column(
      children: [
        const Divider(height: 1),
        ExpansionTile(
          leading: Icon(
            Icons.key,
            color: hasToken ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(l10n.apiToken),
          subtitle: Text(
            hasToken ? l10n.tokenConfigured : l10n.optionalAuthentication,
            style: TextStyle(
              color: hasToken
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            hasToken ? Icons.check_circle : Icons.expand_more,
            color: hasToken ? Theme.of(context).colorScheme.primary : null,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _apiTokenController,
                    obscureText: _obscureApiToken,
                    decoration: InputDecoration(
                      labelText: l10n.apiTokenLabel,
                      hintText: l10n.apiTokenHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_obscureApiToken
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _obscureApiToken = !_obscureApiToken),
                          ),
                          if (_apiTokenController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _apiTokenController.clear();
                                settingsProvider.updateApiToken(null);
                              },
                            ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      settingsProvider
                          .updateApiToken(value.isEmpty ? null : value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.apiTokenHelp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.apiTokenInfo,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  _buildCustomHeadersInline(context, settingsProvider),
                  if (Platform.isIOS &&
                      !settingsProvider.settings.isRemoteActive) ...[
                    const Divider(height: 1),
                    _buildUsbModeToggle(context, settingsProvider),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomHeadersInline(
      BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final s = settingsProvider.settings;
    final headers = Map<String, String>.from(s.customRequestHeaders ?? {});
    final headerEntries = headers.entries.toList();
    final enabled = s.customHeadersEnabled;

    final headersSubtitle = enabled && headerEntries.isNotEmpty
        ? l10n.headersConfigured(headerEntries.length)
        : l10n.enableCustomHeadersSubtitle;
    final headersSwitch = Switch(
      value: enabled,
      onChanged: (v) => settingsProvider.updateSettings(
        s.copyWith(customHeadersEnabled: v),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (useDesktopSettingsControls(context))
          DesktopPreferenceRow(
            icon: Icons.http,
            title: l10n.enableCustomHeaders,
            subtitle: headersSubtitle,
            trailing: headersSwitch,
          )
        else
          SwitchListTile(
            secondary: Icon(
              Icons.http,
              color: enabled ? cs.primary : null,
            ),
            title: Text(l10n.enableCustomHeaders),
            subtitle: Text(
              headersSubtitle,
              style: TextStyle(
                color: enabled ? cs.primary : cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            value: enabled,
            onChanged: (v) => settingsProvider.updateSettings(
              s.copyWith(customHeadersEnabled: v),
            ),
          ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customRequestHeadersHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                if (headerEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.noCustomHeaders,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ...headerEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              key: ValueKey('header-name-$index-${e.key}'),
                              controller: TextEditingController(text: e.key)
                                ..selection = TextSelection.collapsed(
                                    offset: e.key.length),
                              decoration: InputDecoration(
                                labelText: l10n.headerNameLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (newKey) {
                                final trimmed = newKey.trim();
                                if (trimmed.isEmpty || trimmed == e.key) return;
                                final updated =
                                    Map<String, String>.from(headers);
                                final value = updated.remove(e.key) ?? '';
                                updated[trimmed] = value;
                                settingsProvider.updateSettings(
                                  s.copyWith(customRequestHeaders: updated),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              key: ValueKey('header-value-$index-${e.key}'),
                              controller: TextEditingController(text: e.value)
                                ..selection = TextSelection.collapsed(
                                    offset: e.value.length),
                              decoration: InputDecoration(
                                labelText: l10n.headerValueLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                final updated =
                                    Map<String, String>.from(headers);
                                updated[e.key] = v;
                                settingsProvider.updateSettings(
                                  s.copyWith(customRequestHeaders: updated),
                                );
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.removeHeader,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              final updated = Map<String, String>.from(headers);
                              updated.remove(e.key);
                              settingsProvider.updateSettings(
                                s.copyWith(
                                  customRequestHeaders:
                                      updated.isEmpty ? null : updated,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addHeader),
                    onPressed: () {
                      final updated = Map<String, String>.from(headers);
                      var i = 1;
                      while (updated.containsKey('X-Custom-Header-$i')) {
                        i++;
                      }
                      updated['X-Custom-Header-$i'] = '';
                      settingsProvider.updateSettings(
                        s.copyWith(customRequestHeaders: updated),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// True when the LM Studio chip is the active provider (not on-device/cloud).
  bool _isLmStudioChipActive(SettingsProvider settingsProvider) {
    final kind = settingsProvider.settings.activeProviderKind;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') return false;
    if (kind == 'lmMiniDesktop') return false;
    if (SettingsProvider.isCloudProviderKind(kind)) return false;
    return _selectedCloudType == null;
  }

  /// Keep the provider chip UI aligned with persisted [activeProviderKind].
  /// Needed when remote access is activated from another screen (QR scan).
  void _syncProviderPickerState(SettingsProvider settingsProvider) {
    final kind = settingsProvider.settings.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'lmStudio' ||
        kind == 'lmMiniDesktop') {
      if (_selectedCloudType != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCloudType = null);
        });
      }
      return;
    }
    if (SettingsProvider.isCloudProviderKind(kind)) {
      final cloud = CloudApiService();
      final active = cloud.activeProvider;
      final isPremium = SubscriptionService().isPremium;
      CloudApiType? chipType;
      if (active != null && (isPremium || !active.type.isPremium)) {
        chipType = active.type;
      } else {
        chipType = switch (kind) {
          'ollama' => CloudApiType.ollama,
          'omlx' => CloudApiType.omlx,
          'jan' => CloudApiType.jan,
          'unsloth' => CloudApiType.unsloth,
          _ => null,
        };
      }
      if (chipType != null && _selectedCloudType != chipType) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedCloudType = chipType;
            if (active != null && chipType == active.type) {
              _cloudApiKeyController.text = active.apiKey;
              _cloudBaseUrlController.text = active.baseUrl ?? '';
            }
          });
        });
      }
    }
  }

  /// Horizontal picker for choosing a provider: On-Device (local LLM),
  /// LM Studio (local server) or cloud types.
  Widget _buildRecentServersSection(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final profiles = ServerProfileService.instance;
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: profiles,
      builder: (context, _) {
        // Keep the USB row present while the bridge is on (e.g. mid-session).
        if (settingsProvider.settings.usbModeEnabled &&
            profiles.byId(ServerProfile.usbId) == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            profiles.ensureUsbProfile();
          });
        }
        final recent = profiles.recent(limit: 3);
        final activeId = profiles.activeId;
        final remote = settingsProvider.settings.isRemoteActive;
        final pairedHome =
            RemoteHostBackends.isPairedHome(settingsProvider.settings);
        final advertised =
            remote ? settingsProvider.visibleRemoteBackends : const <String>[];
        final activeKind = settingsProvider.settings.activeProviderKind;
        final onDeviceActive =
            activeKind == 'onDeviceGguf' || activeKind == 'onDeviceMlx';
        final homeSelected = !onDeviceActive &&
            remote &&
            activeKind == RemoteHostBackends.lmMiniDesktop;
        final onDeviceProfile =
            profiles.byId(ServerProfile.onDeviceId) ?? ServerProfile.onDevice();
        final localRecent = recent.where((p) => !p.isOnDevice).toList();
        final showMore = remote ? false : profiles.profiles.length > 3;

        Widget onDeviceTile() {
          final profile = onDeviceProfile;
          return ListTile(
            leading: _serverLeadingWithProbe(
              icon: OnDeviceEngineLabels.serverListIcon,
              color: onDeviceActive ? cs.primary : null,
              probeOk: _serverProbeResults[profile.id],
            ),
            title: Text(
              profile.displayTitle,
              style: TextStyle(
                fontWeight: onDeviceActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _onDeviceSubtitle(settingsProvider),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onDeviceActive)
                  Icon(Icons.check_circle, color: cs.primary, size: 22),
                _settingsTrailingIconButton(
                  tooltip: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: () => _editServerProfile(context, profile),
                ),
              ],
            ),
            onTap: () async {
              if (onDeviceActive) return;
              await settingsProvider.activateServerProfile(profile.id);
            },
          );
        }

        Widget homeTile() {
          final probe =
              _serverProbeResults['remote:${RemoteHostBackends.lmMiniDesktop}'];
          final subtitle = probe == false
              ? RemoteHostBackends.remoteStatusSubtitle(reachable: false)
              : (remote
                  ? RemoteHostBackends.remoteStatusSubtitle(reachable: true)
                  : 'Paired · tap to use');
          return ListTile(
            leading: _serverLeadingWithProbe(
              icon:
                  RemoteHostBackends.iconFor(RemoteHostBackends.lmMiniDesktop),
              color: homeSelected ? cs.primary : null,
              probeOk: probe,
            ),
            title: Text(
              RemoteHostBackends.displayName(RemoteHostBackends.lmMiniDesktop),
              style: TextStyle(
                fontWeight: homeSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: homeSelected
                ? Icon(Icons.check_circle, color: cs.primary, size: 22)
                : null,
            onTap: () async {
              if (homeSelected) return;
              await settingsProvider.activatePairedHome();
            },
          );
        }

        Widget remoteTile(String kind) {
          if (kind == RemoteHostBackends.lmMiniDesktop) {
            return const SizedBox.shrink();
          }
          final selected = !onDeviceActive && activeKind == kind;
          final probe = _serverProbeResults['remote:$kind'];
          return ListTile(
            leading: _serverLeadingWithProbe(
              icon: RemoteHostBackends.iconFor(kind),
              color: selected ? cs.primary : null,
              probeOk: probe,
            ),
            title: Text(
              RemoteHostBackends.remoteListLabel(
                kind,
                settingsProvider.settings,
              ),
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Paired via ${RemoteHostBackends.transportLabel(settingsProvider.settings)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: selected
                ? Icon(Icons.check_circle, color: cs.primary, size: 22)
                : null,
            onTap: () async {
              await settingsProvider.switchRemoteBackend(kind);
            },
          );
        }

        Widget imageRemoteTile(String kind) {
          final selected = settingsProvider.settings.imageGenEnabled &&
              settingsProvider.settings.imageGenProvider == kind;
          return ListTile(
            leading: _serverLeadingWithProbe(
              icon: RemoteHostBackends.iconFor(kind),
              color: selected ? cs.primary : null,
            ),
            title: Text(
              RemoteHostBackends.remoteListLabel(
                kind,
                settingsProvider.settings,
              ),
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Image generation · paired via ${RemoteHostBackends.transportLabel(settingsProvider.settings)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: selected
                ? Icon(Icons.check_circle, color: cs.primary, size: 22)
                : null,
            onTap: () async {
              await settingsProvider.updateSettings(
                settingsProvider.settings.copyWith(
                  imageGenEnabled: true,
                  imageGenProvider: kind,
                ),
              );
              if (!context.mounted) return;
              _openSettingsScreen(
                SettingsNavId.imageGeneration,
                (_) => const ImageGenerationSettingsScreen(),
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            onDeviceTile(),
            if (pairedHome) homeTile(),
            if (remote) ...[
              for (final kind in advertised) remoteTile(kind),
              for (final kind in RemoteHostBackends.connectImageKinds)
                imageRemoteTile(kind),
            ] else
              for (final profile in localRecent) ...[
                if (profile.isUsb)
                  StreamBuilder<bool>(
                    stream: settingsProvider.usbConnectionStream,
                    initialData: settingsProvider.isUsbPeerConnected,
                    builder: (context, snap) {
                      final connected = snap.data == true;
                      final isActive = profile.id == activeId;
                      final probe = _serverProbeResults[profile.id];
                      return ListTile(
                        leading: _serverLeadingWithProbe(
                          icon: connected ? Icons.usb : Icons.usb_off,
                          color: connected
                              ? Colors.green
                              : (isActive ? cs.primary : null),
                          probeOk: probe,
                        ),
                        title: Text(
                          profile.displayTitle,
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: connected ? Colors.green : null,
                          ),
                        ),
                        subtitle: Text(
                          connected
                              ? 'Connected via USB'
                              : (isActive
                                  ? 'Waiting for LM Mini Connect on Mac…'
                                  : profile.subtitle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              Icon(Icons.check_circle,
                                  color: connected ? Colors.green : cs.primary,
                                  size: 22),
                            _settingsTrailingIconButton(
                              tooltip: 'Delete',
                              icon: Icons.delete_outline,
                              color: cs.error,
                              onPressed: () => _deleteUsbServerProfile(context),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (isActive) return;
                          await settingsProvider
                              .activateServerProfile(profile.id);
                        },
                      );
                    },
                  )
                else
                  ListTile(
                    leading: _serverLeadingWithProbe(
                      icon: _iconForServerProfile(profile),
                      color: profile.id == activeId ? cs.primary : null,
                      probeOk: _serverProbeResults[profile.id],
                    ),
                    title: Text(
                      profile.displayTitle,
                      style: TextStyle(
                        fontWeight: profile.id == activeId
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      profile.isOnDevice
                          ? _onDeviceSubtitle(settingsProvider)
                          : profile.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (profile.id == activeId)
                          Icon(Icons.check_circle, color: cs.primary, size: 22),
                        _settingsTrailingIconButton(
                          tooltip: 'Edit',
                          icon: Icons.edit_outlined,
                          onPressed: () => _editServerProfile(context, profile),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (profile.id == activeId) return;
                      final ok = await settingsProvider
                          .activateServerProfile(profile.id);
                      if (!mounted) return;
                      if (ProFeatures.included && !ok && profile.isPremium) {
                        _openSettingsScreen(
                          SettingsNavId.pro,
                          (_) => const SubscriptionScreen(),
                        );
                      }
                    },
                  ),
              ],
            if (showMore)
              ListTile(
                leading: Icon(Icons.dns_outlined, color: cs.primary),
                title: const Text(
                  'More servers',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  remote
                      ? 'Cloud providers and saved phone servers'
                      : 'Add, rename, or manage all servers',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProvidersScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('Add Server'),
              subtitle: remote
                  ? const Text('Cloud APIs — local apps stay on Connect')
                  : null,
              onTap: () => _quickAddServer(context),
            ),
          ],
        );
      },
    );
  }

  /// Trailing action matching [Icons.chevron_right] footprint on other rows.
  Widget _settingsTrailingIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(24, 24),
        maximumSize: const Size(24, 24),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 24, color: color),
    );
  }

  /// Same leading footprint as Remote Access / Models (`Icon` + status dot).
  Widget _serverLeadingWithProbe({
    required IconData icon,
    Color? color,
    bool? probeOk,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color),
        if (probeOk != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                probeOk ? Icons.check_circle : Icons.cancel,
                size: 12,
                color: probeOk ? Colors.green : Colors.redAccent,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _probeAllServers(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final profiles = ServerProfileService.instance.profiles;
    final remote = settings.settings.isRemoteActive;

    setState(() {
      _probingServers = true;
      _serverProbeResults.clear();
    });

    final cloud = CloudApiService();
    final results = <String, bool>{};

    if (remote) {
      await settings.refreshRemoteHostStatus();
      final advertised = RemoteHostBackends.advertisedOf(settings.settings);
      await Future.wait([
        () async {
          final onDevice = profiles.where((p) => p.isOnDevice).firstOrNull;
          if (onDevice != null) {
            results[onDevice.id] =
                await _probeServerProfile(onDevice, settings, cloud);
          }
        }(),
        ...advertised.map((kind) async {
          final url = settings.settings.remoteServerUrl;
          final token = settings.settings.remoteAuthToken;
          if (url == null || token == null) {
            results['remote:$kind'] = false;
            return;
          }
          final ok = await settings.remoteAccessService.testConnection(
            url,
            token,
            backend: kind,
          );
          results['remote:$kind'] = ok;
        }),
      ]);
    } else {
      if (profiles.isEmpty) {
        if (mounted) setState(() => _probingServers = false);
        return;
      }
      await Future.wait(profiles.map((profile) async {
        final ok = await _probeServerProfile(profile, settings, cloud);
        results[profile.id] = ok;
      }));
    }

    if (!mounted) return;
    setState(() {
      _serverProbeResults
        ..clear()
        ..addAll(results);
      _probingServers = false;
    });

    final passed = results.values.where((v) => v).length;
    final total = results.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          passed == total
              ? 'All $total servers responded'
              : '$passed of $total servers OK',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _probeServerProfile(
    ServerProfile profile,
    SettingsProvider settings,
    CloudApiService cloud,
  ) async {
    try {
      switch (profile.kind) {
        case ServerProfileKind.onDevice:
          final kind = settings.settings.activeProviderKind;
          if (kind == 'onDeviceMlx') {
            return await OnDeviceMlxEndpoint.isPlatformSupported();
          }
          // fllama / default — available whenever the app runs.
          return true;
        case ServerProfileKind.usb:
          if (!settings.settings.usbModeEnabled) return false;
          return settings.isUsbPeerConnected;
        case ServerProfileKind.lmStudio:
          final url = (profile.baseUrl ?? settings.settings.serverUrl).trim();
          if (url.isEmpty) return false;
          final result = await LMStudioService().testConnection(
            url,
            apiToken: profile.apiKey ?? settings.settings.apiToken,
          );
          return result['success'] == true;
        case ServerProfileKind.cloud:
          final existing =
              cloud.providers.where((p) => p.id == profile.id).firstOrNull;
          if (existing == null) return false;
          return cloud.testConnection(existing);
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteUsbServerProfile(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete server?'),
        content: const Text(
          'Remove “LM Studio via USB” from this device? '
          'You can add it again later from Add Server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final settings = context.read<SettingsProvider>();
    final wasActive =
        ServerProfileService.instance.activeId == ServerProfile.usbId;
    await settings.removeUsbServerProfile();
    if (wasActive && mounted) {
      await settings.activateServerProfile(ServerProfile.onDeviceId);
    }
  }

  Future<void> _editServerProfile(
    BuildContext context,
    ServerProfile profile,
  ) async {
    if (profile.isUsb) return;
    if (profile.isOnDevice) {
      await _showOnDeviceEngineDialog(context);
      return;
    }
    final ServerConnectTarget target =
        profile.kind == ServerProfileKind.lmStudio
            ? const ServerConnectLmStudio()
            : ServerConnectCloud(
                profile.cloudType ?? CloudApiType.openaiCompatible);
    await showServerConnectSheet(
      context,
      target: target,
      existing: profile,
    );
  }

  Future<void> _showOnDeviceEngineDialog(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    // Ensure on-device is the active server when editing its engine.
    if (ServerProfileService.instance.activeId != ServerProfile.onDeviceId) {
      await settingsProvider.activateServerProfile(ServerProfile.onDeviceId);
    }
    if (!mounted) return;
    await showOnDeviceEngineSheet(context);
  }

  IconData _iconForServerProfile(ServerProfile profile) {
    switch (profile.kind) {
      case ServerProfileKind.onDevice:
        return OnDeviceEngineLabels.serverListIcon;
      case ServerProfileKind.lmStudio:
        return Icons.desktop_windows_rounded;
      case ServerProfileKind.usb:
        return Icons.usb;
      case ServerProfileKind.cloud:
        if (profile.cloudType == CloudApiType.ollama) {
          return Icons.terminal_rounded;
        }
        if (profile.cloudType == CloudApiType.omlx) {
          return Icons.memory_rounded;
        }
        if (profile.cloudType == CloudApiType.jan) {
          return Icons.bolt_rounded;
        }
        if (profile.cloudType == CloudApiType.unsloth) {
          return Icons.science_rounded;
        }
        return Icons.cloud_rounded;
    }
  }

  Future<void> _quickAddServer(BuildContext context) async {
    final remote = context.read<SettingsProvider>().settings.isRemoteActive;
    final selection = await showAddServerSheet(
      context,
      hideLocalNetwork: remote,
    );
    if (selection == null || !mounted) return;
    switch (selection) {
      case AddServerUsb():
        await _enableUsbFromAddServer(context);
      case AddServerLmStudio():
        await showServerConnectSheet(
          context,
          target: const ServerConnectLmStudio(),
        );
      case AddServerCloud(:final type):
        await showServerConnectSheet(
          context,
          target: ServerConnectCloud(type),
        );
    }
  }

  Future<void> _enableUsbFromAddServer(BuildContext context) async {
    if (!Platform.isIOS) return;
    final settingsProvider = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    if (settingsProvider.settings.isRemoteActive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.switchToUsbTitle),
          content: const Text(
              'LM Studio via USB is exclusive — Remote Access will be turned off while it is on.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.switchLabel)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    try {
      await settingsProvider.enableUsbServerProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('LM Studio via USB on — open LM Mini Connect on your Mac'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usbModeStartFailed(e.toString()))),
      );
    }
  }

  Future<void> _onRemoteBackendSelected(
    String kind,
    SettingsProvider settingsProvider,
  ) async {
    setState(() => _selectedCloudType = null);
    await settingsProvider.switchRemoteBackend(kind);
  }

  String _onDeviceSubtitle(SettingsProvider settingsProvider) {
    final kind = settingsProvider.settings.activeProviderKind;
    if (kind == 'onDeviceMlx') return 'Engine: MLX • Apple Silicon';
    if (kind == 'onDeviceGguf') {
      return 'Engine: ${AppLocalizations.of(context).onDeviceEngineFllamaLabel}';
    }
    return OnDeviceEngineLabels.serverIdleSubtitle;
  }

  Future<void> _onOnDeviceEngineSelected(
      SettingsProvider settingsProvider, String kind) async {
    assert(kind == 'onDeviceGguf' || kind == 'onDeviceMlx');
    if (settingsProvider.settings.activeProviderKind == kind) return;

    final before = settingsProvider.settings;
    await OnDeviceLLMService.instance.unloadAll();

    await settingsProvider.updateSettings(
      before.copyWith(activeProviderKind: kind),
      keepOnDeviceEngineChoice: true,
    );

    if (!mounted) return;
    final after = settingsProvider.settings;
    final l10n = AppLocalizations.of(context);
    final engineLabel =
        kind == 'onDeviceMlx' ? 'MLX' : l10n.onDeviceEngineFllamaLabel;
    final clearedModel = before.selectedLocalModelId != null &&
        after.selectedLocalModelId == null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clearedModel
              ? l10n.onDeviceEngineSwitchedCleared(engineLabel)
              : l10n.onDeviceEngineSwitched(engineLabel),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Called when the user taps the unified On-Device provider chip.
  /// Switches the active provider to whichever on-device engine was active
  /// last. When this is the first time switching to On-Device, default to
  /// MLX on devices that support it (Apple Silicon iOS/iPadOS/macOS) and
  /// fall back to fllama/GGUF elsewhere. The user can still flip engines
  /// via the sub-selector beneath the provider strip.
  Future<void> _onOnDeviceSelected(SettingsProvider settingsProvider) async {
    final current = settingsProvider.settings.activeProviderKind;
    // If we're already on an on-device engine, leave it alone.
    String kind;
    if (current == 'onDeviceGguf' || current == 'onDeviceMlx') {
      kind = current;
      if (Platform.isAndroid && kind == 'onDeviceMlx') {
        kind = 'onDeviceGguf';
      }
    } else {
      // Prefer MLX on supported hardware (faster on Apple Silicon).
      final mlxOk = await OnDeviceMlxEndpoint.isPlatformSupported();
      kind = mlxOk ? 'onDeviceMlx' : 'onDeviceGguf';
    }
    await settingsProvider.updateSettings(
      settingsProvider.settings.copyWith(activeProviderKind: kind),
    );
    CloudApiService().setActiveProvider(null);
    if (!mounted) return;
    setState(() {
      _selectedCloudType = null;
    });
  }

  /// Called when the user taps a provider chip.
  void _onProviderSelected(
      CloudApiType? type, SettingsProvider settingsProvider) {
    // Leaving on-device mode if it was active.
    final wasOnDevice =
        settingsProvider.settings.activeProviderKind == 'onDeviceGguf' ||
            settingsProvider.settings.activeProviderKind == 'onDeviceMlx';
    if (wasOnDevice) {
      settingsProvider.updateSettings(
        settingsProvider.settings.copyWith(
          activeProviderKind: type == null ? 'lmStudio' : type.providerKind,
        ),
      );
    } else {
      // Keep activeProviderKind in sync (lmStudio vs cloud).
      final kind = type == null ? 'lmStudio' : type.providerKind;
      if (settingsProvider.settings.activeProviderKind != kind) {
        settingsProvider.updateSettings(
          settingsProvider.settings.copyWith(activeProviderKind: kind),
        );
      }
    }

    setState(() {
      _selectedCloudType = type;
    });

    if (type == null) {
      // Switching back to LM Studio local
      CloudApiService().setActiveProvider(null);
      _cloudApiKeyController.clear();
      _cloudBaseUrlController.clear();
      // Restore the LM Studio model that was active before switching away.
      if (_savedLocalModel != null) {
        settingsProvider.updateSelectedModel(_savedLocalModel!);
        _savedLocalModel = null;
        SharedPreferences.getInstance()
            .then((p) => p.remove('saved_local_model'));
      }
      if (settingsProvider.settings.isRemoteActive) {
        settingsProvider.loadAvailableModels();
      }
    } else {
      // Save the current model so we can restore it when switching back
      // to LM Studio or to a different cloud provider.
      if (_selectedCloudType == null) {
        // Leaving LM Studio → save its model
        _savedLocalModel = settingsProvider.settings.selectedModel;
        SharedPreferences.getInstance().then((p) {
          if (_savedLocalModel != null) {
            p.setString('saved_local_model', _savedLocalModel!);
          }
        });
      }

      // Populate fields from saved provider (if any), or blank
      final cloud = CloudApiService();
      final existing = cloud.providers.where((p) => p.type == type).firstOrNull;
      if (existing != null) {
        _cloudApiKeyController.text = existing.apiKey;
        _cloudBaseUrlController.text = existing.baseUrl ?? '';
        // Re-activate the saved provider so the user doesn't have to
        // re-submit the form. This also restores the last-selected model.
        cloud.setActiveProvider(existing.id);
        if (existing.selectedModel != null) {
          settingsProvider.updateSelectedModel(existing.selectedModel!);
        }
      } else {
        _cloudApiKeyController.clear();
        _cloudBaseUrlController.text =
            type == CloudApiType.jan || type == CloudApiType.unsloth
                ? type.defaultBaseUrl
                : '';
        // No saved provider for this type — deactivate cloud so requests
        // don't go to a stale provider while the user fills in credentials.
        cloud.setActiveProvider(null);
      }
    }
  }

  /// Saves the cloud provider config and tests the connection.
  Future<void> _saveAndTestCloudProvider(
      SettingsProvider settingsProvider) async {
    final l10n = AppLocalizations.of(context);
    final type = _selectedCloudType!;
    final cloud = CloudApiService();
    final apiKey = _cloudApiKeyController.text.trim();
    final customBase = _cloudBaseUrlController.text.trim();

    // Build or update the provider
    final existing = cloud.providers.where((p) => p.type == type).firstOrNull;
    final previousChatUrl =
        existing?.baseUrl ?? settingsProvider.lanChatBaseUrl() ?? '';
    final previousImageUrl = settingsProvider.settings.imageGenServerUrl;
    final provider = CloudApiProvider(
      id: existing?.id ??
          '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      name: type.displayName,
      type: type,
      apiKey: apiKey,
      baseUrl: customBase.isNotEmpty ? customBase : null,
      selectedModel: existing?.selectedModel,
      isEnabled: true,
    );

    setState(() => _isTestingCloudConnection = true);

    try {
      // Save first
      await cloud.saveProvider(provider);

      // Test connection
      final success = await cloud.testConnection(provider);

      if (!mounted) return;

      if (success) {
        // Activate this provider
        await cloud.setActiveProvider(provider.id);

        final providerKind = type.providerKind;
        await settingsProvider.updateSettings(
          settingsProvider.settings.copyWith(activeProviderKind: providerKind),
        );

        // Try to load models
        final models = await cloud.fetchModels(provider);
        final chatIds = LMStudioModel.chatModelIds(models);
        if (chatIds.isNotEmpty && provider.selectedModel == null) {
          // Auto-select first chat model (skip embeddings).
          final updated = provider.copyWith(selectedModel: chatIds.first);
          await cloud.saveProvider(updated);
        }
        await settingsProvider.loadAvailableModels();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.connectedTo(type.displayName)),
              backgroundColor: Colors.green,
            ),
          );
          if (type == CloudApiType.ollama && models.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Connected to Ollama, but no models are available yet. '
                  'Pull a model from Model Management, or run '
                  '`ollama pull <model>` on your computer.',
                ),
                duration: Duration(seconds: 6),
              ),
            );
          }
          final newUrl = provider.baseUrl ?? customBase;
          if (newUrl.isNotEmpty) {
            await maybeOfferSharedHostUpdate(
              context,
              previousChangedUrl: previousChatUrl,
              newChangedUrl: newUrl,
              peerUrl: previousImageUrl,
              peer: SharedHostPeer.imageGen,
              changedName: type.displayName,
              peerName: imageGenBackendLabel(settingsProvider.settings),
            );
          }
        }
      } else {
        if (mounted) {
          final error = cloud.lastConnectionError ??
              l10n.connectionToFailed(type.displayName);
          _showConnectionHelpDialog(
            context,
            error,
            isAuthError: error.contains('401') ||
                error.contains('403') ||
                error.toLowerCase().contains('authentication'),
            serverUrlOverride: provider.effectiveBaseUrl,
            isLocalServer: type.isLocalOpenAiCompatible,
            localServerType: type.isLocalOpenAiCompatible ? type : null,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingCloudConnection = false);
      }
    }
  }

  /// USB Mode toggle — iOS-only, free, no premium gate. Lives inside the
  /// Providers/Server section. When on, USB bridge starts and the rest of the
  /// server config is hidden in favor of a "Connected via USB" tile.
  Widget _buildUsbModeToggle(
      BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final isOn = settingsProvider.settings.usbModeEnabled;
    return StreamBuilder<bool>(
      stream: settingsProvider.usbConnectionStream,
      initialData: settingsProvider.isUsbPeerConnected,
      builder: (context, snap) {
        final connected = snap.data == true;
        final subtitle = isOn
            ? (connected
                ? 'Connected via USB'
                : 'Waiting for LM Mini on Mac (USB bridge)…')
            : 'Use desktop models over a USB cable (no Wi-Fi needed)';
        Future<void> onChanged(bool v) async {
          if (v) {
            if (settingsProvider.settings.isRemoteActive) {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.switchToUsbTitle),
                  content: const Text(
                      'USB Mode is exclusive — Remote Access will be turned off while USB Mode is on.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.switchLabel)),
                  ],
                ),
              );
              if (ok != true) return;
            }
            try {
              await settingsProvider.activateUsbMode();
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.usbModeStartFailed(e.toString()))));
            }
          } else {
            await settingsProvider.deactivateUsbMode();
          }
        }

        if (useDesktopSettingsControls(context)) {
          return DesktopPreferenceRow(
            icon: Icons.usb,
            title: '${l10n.usbMode} · BETA',
            subtitle: subtitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 18,
                  tooltip: l10n.usbModeHowItWorks,
                  onPressed: () => _showUsbHelpDialog(context),
                  icon: const Icon(Icons.help_outline),
                ),
                Switch(value: isOn, onChanged: onChanged),
              ],
            ),
          );
        }

        return SwitchListTile(
          secondary: Stack(
            children: [
              const Icon(Icons.usb),
              if (connected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Text(l10n.usbMode),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.help_outline),
                tooltip: l10n.usbModeHowItWorks,
                onPressed: () => _showUsbHelpDialog(context),
              ),
            ],
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: connected
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          value: isOn,
          onChanged: onChanged,
        );
      },
    );
  }

  void _showUsbHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.usbMode),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'USB Mode lets your iPhone use LM Studio on a Mac without any internet '
                'or Wi-Fi — perfect for flights or air-gapped networks.',
              ),
              const SizedBox(height: 12),
              Text(l10n.usbModeHowToUse,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                  '1. Install LM Mini on your Mac (Share with phone → USB bridge)'),
              const Text(
                  '2. Start LM Studio / Ollama or load a builtin model on the Mac'),
              const Text(
                  '3. Plug iPhone into Mac with a cable & trust the computer'),
              const Text('4. Toggle USB Mode on here in the app'),
              const SizedBox(height: 12),
              const Text(
                'Note: Mac App Store builds are sandboxed and cannot use USB. '
                'On those builds use Share with phone (QR). '
                'For USB, download LM Mini for Mac from lmmini.com '
                '(full desktop build). Enter any LM Studio API token in the Mac host settings if required.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          FilledButton(
            onPressed: () {
              launchUrl(Uri.parse('https://lmmini.com/download.html'),
                  mode: LaunchMode.externalApplication);
            },
            child: Text(l10n.openLmminiCom),
          ),
        ],
      ),
    );
  }

  /// Builds the Account section showing sign-in status and link to account screen.
  Widget _buildAccountSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!firebaseInitialized) {
      return _buildSection(
        context,
        title: l10n.accountSection,
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_off),
            title: Text(l10n.signIn),
            subtitle: Text(l10n.cloudServicesUnavailable),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSettingsScreen(
              SettingsNavId.account,
              (_) => const AccountScreen(),
            ),
          ),
        ],
      );
    }

    // Wrap with _buildSection at top level so the iPad sidebar registers
    // the ACCOUNT title eagerly (the StreamBuilder used previously only
    // registered after first build, so the sidebar missed it on first frame).
    return _buildSection(
      context,
      title: l10n.accountSection,
      children: [
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isAnonymous =
                user == null || (user.isAnonymous && user.providerData.isEmpty);

            IconData leadingIcon;
            Color? iconColor;

            if (isAnonymous) {
              leadingIcon = Icons.person_outline;
              iconColor = null;
            } else {
              leadingIcon = Icons.check_circle;
              iconColor = Colors.green;
            }

            // Build title and subtitle for signed-in users
            final String titleText;
            final String subtitleText;
            if (isAnonymous) {
              titleText = l10n.signIn;
              subtitleText = l10n.signInSubtitle;
            } else {
              final displayName = user.displayName;
              final email = user.email;
              final method = _signInMethodName(user);
              titleText = displayName ?? email ?? l10n.signedInVia(method);
              if (displayName != null && email != null) {
                subtitleText = email;
              } else {
                subtitleText = l10n.signedInVia(method);
              }
            }

            return ListTile(
              leading: Icon(leadingIcon, color: iconColor),
              title: Text(
                titleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                subtitleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _openSettingsScreen(
                  SettingsNavId.account,
                  (_) => const AccountScreen(),
                );
                if (mounted) setState(() {});
              },
            );
          },
        ),
      ],
    );
  }

  String _signInMethodName(User? user) {
    if (user == null) return 'Anonymous';
    for (final p in user.providerData) {
      if (p.providerId == 'apple.com') return 'Apple';
      if (p.providerId == 'google.com') return 'Google';
      if (p.providerId == 'password') return 'Email';
    }
    return 'Anonymous';
  }

  /// Right-pane widget for a settings-tree nav id, or null for hub scroll.
  Widget? _widgetForNavId(String navId, BuildContext context) {
    final settings = context.read<SettingsProvider>().settings;
    final onDevice = settings.activeProviderKind == 'onDeviceGguf' ||
        settings.activeProviderKind == 'onDeviceMlx';

    switch (navId) {
      case SettingsNavId.desktopHost:
        return const DesktopHostScreen(embedded: true);
      case SettingsNavId.remoteAccess:
        return const RemoteAccessScreen(embedded: true);
      case SettingsNavId.account:
        return const AccountScreen(embedded: true);
      case SettingsNavId.appearance:
        return const AppearanceSettingsScreen(embedded: true);
      case SettingsNavId.voice:
        return const VoiceSettingsScreen(embedded: true);
      case SettingsNavId.transcription:
        return const TranscriptionSettingsScreen(embedded: true);
      case SettingsNavId.widgets:
        return const WidgetSettingsScreen(embedded: true);
      case SettingsNavId.siri:
        return const SiriShortcutsScreen(embedded: true);
      case SettingsNavId.appleWatch:
        return const WatchSettingsScreen(embedded: true);
      case SettingsNavId.imageGeneration:
        return const ImageGenerationSettingsScreen(embedded: true);
      case SettingsNavId.modelsSelection:
        return onDevice
            ? const LocalModelsScreen(embedded: true)
            : const ModelManagementScreen(embedded: true);
      case SettingsNavId.modelsParameters:
        return const ModelParametersScreen(embedded: true);
      case SettingsNavId.modelsPersonas:
        return const SystemPromptsScreen(embedded: true);
      case SettingsNavId.dataCloudBackup:
        return const CloudBackupScreen(embedded: true);
      case SettingsNavId.dataAnalytics:
        return const AnalyticsScreen(embedded: true);
      case SettingsNavId.dataMemory:
        return const MemoryScreen(embedded: true);
      case SettingsNavId.dataAppLock:
        return const AppLockSettingsScreen(embedded: true);
      case SettingsNavId.advancedTools:
        return const ToolSettingsScreen(embedded: true);
      case SettingsNavId.supportFeatureRequests:
        return const FeatureRequestsScreen(embedded: true);
      case SettingsNavId.legalPrivacy:
        return const PrivacyPolicyScreen(embedded: true);
      case SettingsNavId.legalTerms:
        return const TermsOfServiceScreen(embedded: true);
      case SettingsNavId.legalChangelog:
        return const ChangelogScreen(embedded: true);
      case SettingsNavId.pro:
        return const SubscriptionScreen(embedded: true);
      default:
        return null;
    }
  }

  /// Prefer column-3 pane navigation on desktop shell / wide layout.
  void _openSettingsScreen(String navId, WidgetBuilder builder) {
    if (widget.embedded || prefersWideSettingsLayout(context)) {
      if (_widgetForNavId(navId, context) != null) {
        _selectNavId(navId, kind: SettingsNavKind.screen);
        return;
      }
    }
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  Widget _buildTwoColumnSettings(
    BuildContext context,
    List<Widget> sections, {
    required bool isAdvanced,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final tree = buildSettingsNavTree(context, isAdvanced: isAdvanced);
    final activeId = _activeSidebarSection ?? SettingsNavId.server;
    final activeGroup = groupIdForNavId(activeId, tree);
    final expanded = {..._expandedNavGroups};
    if (activeGroup != null) expanded.add(activeGroup);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 272,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            children: [
              for (final group in tree) ...[
                _buildNavGroupTile(
                  context,
                  group: group,
                  activeId: activeId,
                  expanded: expanded.contains(group.id),
                  onToggleExpand: () {
                    setState(() {
                      if (_expandedNavGroups.contains(group.id)) {
                        _expandedNavGroups.remove(group.id);
                      } else {
                        _expandedNavGroups.add(group.id);
                      }
                    });
                  },
                  onSelectGroup: () {
                    // Single screen leaf (e.g. Appearance) → open that screen.
                    if (group.leaves.length == 1 &&
                        group.leaves.first.kind == SettingsNavKind.screen) {
                      _selectNavId(
                        group.leaves.first.id,
                        kind: SettingsNavKind.screen,
                      );
                      return;
                    }
                    if (_widgetForNavId(group.id, context) != null) {
                      _selectNavId(group.id, kind: SettingsNavKind.screen);
                      return;
                    }
                    _selectNavId(group.id, kind: SettingsNavKind.hub);
                  },
                  onSelectLeaf: (leaf) {
                    if (leaf.kind == SettingsNavKind.action) {
                      _handleNavAction(leaf.id);
                      return;
                    }
                    _selectNavId(leaf.id, kind: leaf.kind);
                  },
                ),
              ],
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        Expanded(
          child: Builder(builder: (context) {
            final inner = _widgetForNavId(activeId, context);
            if (inner != null) {
              return KeyedSubtree(
                key: ValueKey('inner-$activeId'),
                child: inner,
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: DesktopSettingsForm(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sections,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNavGroupTile(
    BuildContext context, {
    required SettingsNavGroup group,
    required String activeId,
    required bool expanded,
    required VoidCallback onToggleExpand,
    required VoidCallback onSelectGroup,
    required void Function(SettingsNavLeaf leaf) onSelectLeaf,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupActive =
        activeId == group.id || group.leaves.any((l) => l.id == activeId);
    final hasLeaves = group.leaves.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: activeId == group.id
              ? colorScheme.primaryContainer.withValues(alpha: 0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (hasLeaves && !expanded) onToggleExpand();
              onSelectGroup();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  if (hasLeaves)
                    InkWell(
                      onTap: onToggleExpand,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          expanded ? Icons.expand_more : Icons.chevron_right,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 22),
                  Expanded(
                    child: Text(
                      group.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                groupActive ? FontWeight.w700 : FontWeight.w600,
                            color: groupActive
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          for (final leaf in group.leaves)
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Material(
                color: activeId == leaf.id
                    ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelectLeaf(leaf),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      leaf.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: activeId == leaf.id
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: activeId == leaf.id
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  void _handleNavAction(String navId) {
    if (navId == SettingsNavId.serverAdd) {
      setState(() => _activeSidebarSection = SettingsNavId.server);
      showAddServerSheet(context);
    }
  }

  void _selectNavId(String navId, {required SettingsNavKind kind}) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _activeSidebarSection = navId;
      final group = groupIdForNavId(
          navId,
          buildSettingsNavTree(
            context,
            isAdvanced: context.read<SettingsProvider>().isAdvancedSettings,
          ));
      if (group != null) _expandedNavGroups.add(group);
    });

    if (kind == SettingsNavKind.screen ||
        _widgetForNavId(navId, context) != null) {
      return;
    }

    final hubId = hubSectionIdForNav(navId, l10n) ?? navId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _sectionKeys[hubId];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

  String _appLockTimeoutLabel(AppLocalizations l10n, int seconds) {
    switch (seconds) {
      case 15:
        return l10n.appLockTimeout15s;
      case 60:
        return l10n.appLockTimeout1m;
      case 300:
        return l10n.appLockTimeout5m;
      case 900:
        return l10n.appLockTimeout15m;
      case 3600:
        return l10n.appLockTimeout1h;
      default:
        return l10n.appLockTimeoutImmediate;
    }
  }

  Widget _buildSection(BuildContext context,
      {String? sectionId,
      required String title,
      required List<Widget> children,
      bool hasError = false,
      Widget? titleTrailing}) {
    final hasCustomSectionColor =
        context.appThemeColors.settingsListTileColor != null;
    final sectionBackground = context.appThemeColors.settingsListTileColor ??
        (context.hasBackgroundGradient
            ? Theme.of(context).colorScheme.surface.withOpacity(0.75)
            : null);

    // Register this section for the iPad sidebar (first build pass only).
    final displayTitle = title.toUpperCase();
    final registryId = sectionId ?? displayTitle;
    final sectionKey = _sectionKeys.putIfAbsent(registryId, () => GlobalKey());
    _sectionLabels[registryId] = displayTitle;
    if (!_sectionOrder.contains(registryId)) {
      _sectionOrder.add(registryId);
    }

    return KeyedSubtree(
      key: sectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              // First section sits right under the glass sheet edge.
              _sectionOrder.length <= 1 ? 12 : 20,
              16,
              8,
            ),
            child: SizedBox(
              height: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasError) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: hasError
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                  ),
                  if (hasError) ...[
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).actionRequired,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                    ),
                  ],
                  const Spacer(),
                  if (titleTrailing != null) titleTrailing,
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: sectionBackground,
            clipBehavior: Clip.antiAlias,
            elevation: hasCustomSectionColor ? 0 : null,
            shadowColor: hasCustomSectionColor ? Colors.transparent : null,
            surfaceTintColor: hasCustomSectionColor ? Colors.transparent : null,
            shape: hasError
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.5),
                      width: 1,
                    ),
                  )
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddingModelTile(SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final embeddingModels = settingsProvider.embeddingAvailableModels;

    return PopupMenuButton<String>(
      onSelected: (value) =>
          settingsProvider.updateSelectedEmbeddingModel(value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: '',
          child: Text(l10n.none),
        ),
        ...embeddingModels.map((model) => PopupMenuItem(
              value: model.id,
              child: Text(model.id),
            )),
      ],
      child: ListTile(
        leading: const Icon(Icons.view_in_ar),
        title: Text(l10n.embeddingModel),
        subtitle:
            Text(settingsProvider.settings.selectedEmbeddingModel ?? l10n.none),
        trailing: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _buildAutoUnloadTile(
      BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final currentValue = settingsProvider.settings.autoUnloadTtlMinutes;
    String subtitleText;
    if (currentValue == null) {
      subtitleText = l10n.idleTtlDefault;
    } else if (currentValue < 60) {
      subtitleText = l10n.autoUnloadAfter('$currentValue min');
    } else {
      final hours = currentValue ~/ 60;
      final mins = currentValue % 60;
      subtitleText = mins > 0
          ? l10n.autoUnloadAfter('$hours hr $mins min')
          : l10n.autoUnloadAfter('$hours hour${hours > 1 ? 's' : ''}');
    }

    return PopupMenuButton<int?>(
      onSelected: (value) => settingsProvider.updateAutoUnloadTtlMinutes(value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text(l10n.lmStudioDefault),
        ),
        PopupMenuItem(
          value: 5,
          child: Text(l10n.fiveMinutes),
        ),
        PopupMenuItem(
          value: 15,
          child: Text(l10n.fifteenMinutes),
        ),
        PopupMenuItem(
          value: 30,
          child: Text(l10n.thirtyMinutes),
        ),
        PopupMenuItem(
          value: 60,
          child: Text(l10n.oneHour),
        ),
        PopupMenuItem(
          value: 120,
          child: Text(l10n.twoHours),
        ),
      ],
      child: ListTile(
        leading: const Icon(Icons.timer_off),
        title: Text(l10n.idleTtl),
        subtitle: Text(subtitleText),
        trailing: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _launchBuyMeACoffee() async {
    final l10n = AppLocalizations.of(context);
    final Uri url = Uri.parse('https://buymeacoffee.com/slimelephant');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenLink)),
        );
      }
    }
  }

  Future<void> _testConnection(
      BuildContext context, SettingsProvider settingsProvider) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isTestingConnection = true);
    try {
      await settingsProvider.loadAvailableModels();
      if (!context.mounted) return;
      final err = settingsProvider.connectionError;
      if (err != null) {
        setState(() {
          _showServerError = true;
          _isTestingConnection = false;
        });
        _showConnectionHelpDialog(
          context,
          err,
          isAuthError: err.contains('invalid_api_key') || err.contains('401'),
        );
        return;
      }
      setState(() {
        _showServerError = false;
        _isTestingConnection = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.connectionSuccess(settingsProvider.availableModels.length),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _showServerError = true;
          _isTestingConnection = false;
        });
        _showConnectionHelpDialog(context, e.toString(),
            isAuthError: e.toString().contains('invalid_api_key') ||
                e.toString().contains('401'));
      }
    }
  }

  Future<void> _scanLocalNetworkServers(
    SettingsProvider settingsProvider, {
    DiscoveredServerKind? kindFilter,
  }) async {
    if (_isScanningServers) return;
    setState(() => _isScanningServers = true);

    final parsedPort = int.tryParse(
      kindFilter == DiscoveredServerKind.ollama
          ? Uri.tryParse(_cloudBaseUrlController.text.trim())
                  ?.port
                  .toString() ??
              ''
          : Uri.tryParse(_serverUrlController.text.trim())?.port.toString() ??
              '',
    );
    final servers = await LmStudioDiscoveryService.instance.scanLocalNetwork(
      preferredPorts: parsedPort == null ? null : [parsedPort],
    );

    if (!mounted) return;
    setState(() => _isScanningServers = false);

    final filtered = kindFilter == null
        ? servers
        : servers.where((s) => s.kind == kindFilter).toList();

    if (filtered.isEmpty) {
      final emptyMessage = kindFilter == DiscoveredServerKind.ollama
          ? 'No Ollama servers found on this Wi-Fi network.'
          : kindFilter == DiscoveredServerKind.lmStudio
              ? 'No LM Studio servers found on this Wi-Fi network.'
              : 'No LM Studio or Ollama servers found on this Wi-Fi network.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emptyMessage)),
      );
      return;
    }

    final sheetTitle = kindFilter == DiscoveredServerKind.ollama
        ? 'Found ${filtered.length} Ollama server(s)'
        : kindFilter == DiscoveredServerKind.lmStudio
            ? 'Found ${filtered.length} LM Studio server(s)'
            : 'Found ${filtered.length} local server(s)';

    final picked = await showAdaptiveModal<DiscoveredLmStudioServer>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      dialogMaxWidth: 480,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wifi_find),
              title: Text(sheetTitle),
              subtitle: Text(AppLocalizations.of(context).tapToUseServer),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  return ListTile(
                    leading: Icon(
                      s.kind == DiscoveredServerKind.ollama
                          ? Icons.smart_toy_outlined
                          : Icons.dns,
                    ),
                    title: Text(s.listTitle),
                    subtitle: Text(s.listSubtitle),
                    trailing: s.requiresApiKey
                        ? const Icon(Icons.key, size: 18)
                        : null,
                    onTap: () => Navigator.pop(sheetCtx, s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    if (picked.kind == DiscoveredServerKind.ollama) {
      await _applyDiscoveredOllamaServer(picked, settingsProvider);
      return;
    }

    if (picked.requiresApiKey) {
      await _showLmStudioScanApiKeyDialog(picked, settingsProvider);
      return;
    }

    _serverUrlController.text = picked.url;
    final previous = settingsProvider.settings.serverUrl;
    settingsProvider.updateServerUrl(picked.url);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Using ${picked.url}')),
    );
    if (mounted) {
      await maybeOfferSharedHostUpdate(
        context,
        previousChangedUrl: previous,
        newChangedUrl: picked.url,
        peerUrl: settingsProvider.settings.imageGenServerUrl,
        peer: SharedHostPeer.imageGen,
        changedName: 'LM Studio',
        peerName: imageGenBackendLabel(settingsProvider.settings),
      );
    }
  }

  Future<void> _applyDiscoveredOllamaServer(
    DiscoveredLmStudioServer server,
    SettingsProvider settingsProvider,
  ) async {
    _onProviderSelected(CloudApiType.ollama, settingsProvider);
    _cloudBaseUrlController.text = server.url;
    setState(() {});
    await _saveAndTestCloudProvider(settingsProvider);
  }

  Future<void> _showLmStudioScanApiKeyDialog(
    DiscoveredLmStudioServer server,
    SettingsProvider settingsProvider,
  ) async {
    final token = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => _LmStudioScanApiKeyDialog(
        server: server,
        initialToken: _apiTokenController.text,
      ),
    );

    if (token == null || token.isEmpty || !mounted) return;

    final previous = settingsProvider.settings.serverUrl;
    _serverUrlController.text = server.url;
    _apiTokenController.text = token;
    settingsProvider.updateServerUrl(server.url);
    settingsProvider.updateApiToken(token);
    setState(() {});

    await _testConnection(context, settingsProvider);
    if (mounted) {
      await maybeOfferSharedHostUpdate(
        context,
        previousChangedUrl: previous,
        newChangedUrl: server.url,
        peerUrl: settingsProvider.settings.imageGenServerUrl,
        peer: SharedHostPeer.imageGen,
        changedName: 'LM Studio',
        peerName: imageGenBackendLabel(settingsProvider.settings),
      );
    }
  }

  void _showConnectionHelpDialog(BuildContext context, String error,
      {bool isAuthError = false,
      String? serverUrlOverride,
      bool isLocalServer = false,
      CloudApiType? localServerType}) {
    final l10n = AppLocalizations.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    final serverUrl = serverUrlOverride ?? settingsProvider.settings.serverUrl;
    if (showConnectHostHelpIfNeeded(
      context,
      error: error,
      serverUrl: serverUrl,
      isRemoteActive: settingsProvider.settings.isRemoteActive,
      usbModeEnabled: settingsProvider.settings.usbModeEnabled,
      providerKind: settingsProvider.settings.activeProviderKind,
    )) {
      return;
    }
    // Same single-issue rules as the chat banner: offline / mobile data
    // get the network explanation (never "Connection failed" or the iOS
    // Local Network hint), and that hint only shows on Wi‑Fi.
    final issue = isAuthError
        ? null
        : settingsProvider.resolveGlobalConnectionIssue(error: error);
    if (issue != null && issue.isNetworkState) {
      showNetworkIssueDialog(context, issue);
      return;
    }
    final isLocalUrl = LocalNetworkService.isLocalNetworkUrl(serverUrl);
    final isLikelyPermissionIssue =
        issue?.kind == ConnectionIssueKind.localNetworkPermission;
    final lanKind = LanServerError.classify(error);
    final showLmStudioLanHelp = LanServerError.shouldShowLmStudioLanHelp(
      error: error,
      serverUrl: serverUrl,
      providerKind: settingsProvider.settings.activeProviderKind,
    );

    String ipPlaceholder = '192.168.1.xx';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Very briefly guess local subnet synchronously if we can (e.g., from serverUrl)
            final parsed = Uri.tryParse(serverUrl);
            if (parsed != null &&
                parsed.host.isNotEmpty &&
                parsed.host != 'localhost') {
              final parts = parsed.host.split('.');
              if (parts.length == 4) {
                ipPlaceholder = '${parts[0]}.${parts[1]}.${parts[2]}.xx';
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isAuthError ? Icons.info_outline : Icons.error_outline,
                    color: isAuthError
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAuthError
                          ? l10n.lmStudioAuthDialogTitle
                          : l10n.connectionFailed,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error.contains('invalid_api_key') ||
                        isAuthError ||
                        error.toLowerCase().contains('authentication')) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.key,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.lmStudioServerFoundNeedsKey,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.lmStudioAuthDialogMessage,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.lmStudioAuthHelpHint,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (showLmStudioLanHelp) ...[
                      Text(
                        lanKind == LanServerErrorKind.hostDown
                            ? l10n.lmStudioHostDownTitle
                            : l10n.lmStudioPcNotAllowingTitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else
                      Text(
                        LocalhostConnectionError.matches(
                          error,
                          serverUrl: serverUrl,
                        )
                            ? l10n.localhostConnectionHelp
                            : l10n.errorGeneric(error),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    if (isLocalServer &&
                        error.toLowerCase().contains('connection refused')) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.dns,
                                    size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    localServerType == CloudApiType.ollama
                                        ? 'Ollama not reachable on the network'
                                        : localServerType == CloudApiType.jan
                                            ? 'JAN AI not reachable on the network'
                                            : localServerType ==
                                                    CloudApiType.unsloth
                                                ? 'Unsloth not reachable on the network'
                                                : 'Local server not reachable on the network',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localServerType == CloudApiType.ollama
                                  ? 'By default Ollama listens on localhost only. On the computer running Ollama:\n\n'
                                      '1. Confirm Ollama is running (app icon or `ollama serve`)\n'
                                      '2. Use your computer\'s LAN IP with port 11434 (e.g. http://192.168.1.100:11434)\n'
                                      '3. Both devices must be on the same Wi‑Fi\n'
                                      '4. Allow incoming connections in the PC firewall for Ollama\n\n'
                                      'For Ollama cloud models, add a Bearer API key from ollama.com/settings/keys.'
                                  : localServerType == CloudApiType.jan
                                      ? 'By default JAN AI listens on localhost only. On the computer running JAN AI:\n\n'
                                          '1. Open JAN AI → Settings → Local API Server and start it\n'
                                          '2. Bind to 0.0.0.0 (not only localhost) on port 1337\n'
                                          '3. Use your computer\'s LAN IP (e.g. http://192.168.1.100:1337)\n'
                                          '4. Both devices must be on the same Wi‑Fi; allow JAN AI through the PC firewall\n'
                                          '5. Leave Execute Tools on Server off — LM Mini runs tools. API key is optional.'
                                      : localServerType == CloudApiType.unsloth
                                          ? 'By default Unsloth listens on localhost only. On the computer running Unsloth Desktop:\n\n'
                                              '1. Start Unsloth Studio and load a model\n'
                                              '2. Bind the API to 0.0.0.0 on port 8888 so phones can connect\n'
                                              '3. Use your computer\'s LAN IP (e.g. http://192.168.1.100:8888)\n'
                                              '4. Both devices must be on the same Wi‑Fi; allow Unsloth through the PC firewall\n'
                                              '5. API key is optional. Paste the sk-unsloth-… key only if Unsloth asks for one. Leave Unsloth’s bash/python tools off — Mini runs tools.'
                                          : 'By default oMLX only listens on localhost. On the computer running oMLX, start it with:\n\n'
                                              'omlx serve --host 0.0.0.0 --port 8000 --api-key 1234\n\n'
                                              'Then confirm the computer\'s LAN IP, both devices are on the same Wi‑Fi, and the PC firewall allows incoming connections for oMLX.',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // iOS Local Network Permission Warning
                    if (isLikelyPermissionIssue) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wifi_lock,
                                    size: 18, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Local Network access may be blocked',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.localNetworkFix,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.settings, size: 16),
                                label: Text(l10n.openAppSettings),
                                onPressed: () async {
                                  // This opens the app's settings page in iOS Settings
                                  final uri = Uri.parse('app-settings:');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      l10n.troubleshootingSteps,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    if (localServerType == CloudApiType.ollama) ...[
                      _buildHelpStep(
                        context,
                        number: '1',
                        text: 'Make sure Ollama is running on your computer',
                      ),
                      _buildHelpStep(
                        context,
                        number: '2',
                        text:
                            'Ollama must listen on your LAN (not only localhost). Set OLLAMA_HOST=0.0.0.0:11434, then restart Ollama',
                        highlight: true,
                      ),
                      _buildHelpStep(
                        context,
                        number: '3',
                        text:
                            'Use your computer\'s LAN IP with port 11434 (e.g. http://$ipPlaceholder:11434)',
                      ),
                      _buildHelpStep(
                        context,
                        number: '4',
                        text:
                            'Both devices must be on the same Wi‑Fi; allow Ollama through the PC firewall if prompted',
                      ),
                      _buildHelpStep(
                        context,
                        number: '5',
                        text:
                            'For Ollama cloud models, add a Bearer API key from ollama.com/settings/keys',
                      ),
                    ] else if (localServerType == CloudApiType.omlx) ...[
                      _buildHelpStep(
                        context,
                        number: '1',
                        text: 'Make sure oMLX is running on your computer',
                      ),
                      _buildHelpStep(
                        context,
                        number: '2',
                        text:
                            'Start it bound to all interfaces: omlx serve --host 0.0.0.0 --port 8000 --api-key YOUR_KEY',
                        highlight: true,
                      ),
                      _buildHelpStep(
                        context,
                        number: '3',
                        text:
                            'Use your computer\'s LAN IP with port 8000 (e.g. http://$ipPlaceholder:8000)',
                      ),
                      _buildHelpStep(
                        context,
                        number: '4',
                        text:
                            'Both devices must be on the same Wi‑Fi; allow oMLX through the PC firewall if prompted',
                      ),
                      _buildHelpStep(
                        context,
                        number: '5',
                        text:
                            'Confirm the API key in LM Mini matches the oMLX --api-key value',
                      ),
                    ] else if (localServerType == CloudApiType.jan) ...[
                      _buildHelpStep(
                        context,
                        number: '1',
                        text: 'Make sure JAN AI is running on your computer',
                      ),
                      _buildHelpStep(
                        context,
                        number: '2',
                        text:
                            'Settings → Local API Server: bind to 0.0.0.0 and start it on port 1337',
                        highlight: true,
                      ),
                      _buildHelpStep(
                        context,
                        number: '3',
                        text:
                            'Use your computer\'s LAN IP with port 1337 (e.g. http://$ipPlaceholder:1337)',
                      ),
                      _buildHelpStep(
                        context,
                        number: '4',
                        text:
                            'Both devices must be on the same Wi‑Fi; allow JAN AI through the PC firewall if prompted',
                      ),
                      _buildHelpStep(
                        context,
                        number: '5',
                        text:
                            'API key is optional. Leave Execute Tools on Server off — LM Mini runs tools',
                      ),
                    ] else if (localServerType == CloudApiType.unsloth) ...[
                      _buildHelpStep(
                        context,
                        number: '1',
                        text:
                            'Make sure Unsloth Desktop is running with a model loaded',
                      ),
                      _buildHelpStep(
                        context,
                        number: '2',
                        text:
                            'Bind the API to 0.0.0.0 on port 8888 so phones on Wi‑Fi can connect',
                        highlight: true,
                      ),
                      _buildHelpStep(
                        context,
                        number: '3',
                        text:
                            'Use your computer\'s LAN IP with port 8888 (e.g. http://$ipPlaceholder:8888)',
                      ),
                      _buildHelpStep(
                        context,
                        number: '4',
                        text:
                            'Both devices must be on the same Wi‑Fi; allow Unsloth through the PC firewall if prompted',
                      ),
                      _buildHelpStep(
                        context,
                        number: '5',
                        text:
                            'API key is optional. If Unsloth asks for one, paste the sk-unsloth-… key. LM Mini runs tools — leave Unsloth’s bash and python off',
                      ),
                    ] else ...[
                      _buildHelpStep(
                        context,
                        number: '1',
                        text: lanKind == LanServerErrorKind.hostDown
                            ? l10n.lmStudioHostDownStep1
                            : l10n.troubleshootStep1,
                        highlight: lanKind == LanServerErrorKind.hostDown,
                      ),
                      _buildHelpStep(
                        context,
                        number: '2',
                        text: l10n.troubleshootStep2,
                      ),
                      _buildHelpStep(
                        context,
                        number: '3',
                        text: lanKind == LanServerErrorKind.hostDown
                            ? l10n.lmStudioHostDownStep2
                            : l10n.troubleshootStep3,
                        highlight:
                            lanKind == LanServerErrorKind.connectionRefused ||
                                lanKind == LanServerErrorKind.hostDown,
                      ),
                      _buildHelpStep(
                        context,
                        number: '4',
                        text: l10n.troubleshootStep4,
                      ),
                      _buildHelpStep(
                        context,
                        number: '5',
                        text: l10n
                            .troubleshootStep5('http://$ipPlaceholder:1234'),
                      ),
                    ],
                    // iOS-specific step for local network permission
                    if (Platform.isIOS && isLocalUrl)
                      _buildHelpStep(
                        context,
                        number: '6',
                        text:
                            'Check that Local Network access is enabled for LM Mini in iOS Settings → Privacy & Security → Local Network',
                        highlight: isLikelyPermissionIssue,
                      ),
                    if (Platform.isMacOS && isLocalUrl)
                      _buildHelpStep(
                        context,
                        number: '6',
                        text:
                            'Allow incoming connections if prompted by the firewall, and ensure the server is listening on localhost or your LAN IP',
                      ),
                    const SizedBox(height: 16),
                    if (localServerType == null ||
                        localServerType == CloudApiType.openaiCompatible) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LM Studio Settings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'The "Serve on Local Network" toggle should be enabled (shown in orange/green) in the LM Studio Developer tab.',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            LmStudioServeOnLanScreenshot(
                              semanticLabel:
                                  l10n.lmStudioServerSettingsImageLabel,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Network Connections:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '• Replace "localhost" with your computer\'s IP address\n'
                        '• Ensure both devices are on the same network\n'
                        '• Check firewall settings for port 1234',
                        style: TextStyle(fontSize: 12),
                      ),
                    ] else ...[
                      Text(
                        localServerType == CloudApiType.ollama
                            ? 'Ollama tips'
                            : localServerType == CloudApiType.jan
                                ? 'JAN AI tips'
                                : localServerType == CloudApiType.unsloth
                                    ? 'Unsloth tips'
                                    : 'oMLX tips',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        localServerType == CloudApiType.ollama
                            ? '• Prefer your computer/PC LAN IP over localhost from a phone\n'
                                '• Same Wi‑Fi for both devices\n'
                                '• Firewall must allow port 11434'
                            : localServerType == CloudApiType.jan
                                ? '• Prefer your computer/PC LAN IP over localhost from a phone\n'
                                    '• Same Wi‑Fi for both devices\n'
                                    '• Firewall must allow port 1337\n'
                                    '• Leave Execute Tools on Server off'
                                : localServerType == CloudApiType.unsloth
                                    ? '• Prefer your computer/PC LAN IP over localhost from a phone\n'
                                        '• Same Wi‑Fi for both devices\n'
                                        '• Firewall must allow port 8888\n'
                                        '• API key is required (sk-unsloth-…)'
                                    : '• Prefer your computer/PC LAN IP over localhost from a phone\n'
                                        '• Same Wi‑Fi for both devices\n'
                                        '• Firewall must allow port 8000',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Retry connection
                    _testConnection(context, context.read<SettingsProvider>());
                  },
                  child: Text(l10n.retry),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHelpStep(
    BuildContext context, {
    required String number,
    required String text,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: highlight
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                  color:
                      highlight ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tool/MCP methods moved to tool_settings_screen.dart

  Future<void> _exportAllChats(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    // Get count of conversations for the loading message
    final chatProvider = context.read<ChatProvider>();
    final conversationCount = chatProvider.conversations.length;

    if (conversationCount == 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noConversationsToExport)),
        );
      }
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.exportingConversations(conversationCount)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final exportService = ExportService();
      await exportService.exportAllChats();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess(conversationCount)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importChats(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final importService = ChatImportService();
    final result = await importService.pickAndImport();

    if (result == null) return; // User cancelled

    if (!context.mounted) return;

    if (result.importedCount > 0) {
      // Refresh conversation list
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.loadConversations();

      if (!context.mounted) return;

      if (result.skippedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                l10n.importPartial(result.importedCount, result.skippedCount)),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importSuccess(result.importedCount)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errors.isNotEmpty
              ? '${l10n.importFailed}: ${result.errors.first}'
              : l10n.importFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getLanguageDisplayName(String? locale) {
    switch (locale) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'ru':
        return 'Русский';
      case 'zh':
        return '中文';
      default:
        return 'System Default';
    }
  }

  void _showLanguagePicker(
      BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = settingsProvider.settings.locale;

    showAdaptiveModal(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      dialogMaxWidth: 420,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectLanguage,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildLanguageOption(context, settingsProvider, null,
                  'System Default', Icons.settings, currentLocale),
              _buildLanguageOption(context, settingsProvider, 'en', 'English',
                  null, currentLocale),
              _buildLanguageOption(context, settingsProvider, 'es', 'Español',
                  null, currentLocale),
              _buildLanguageOption(context, settingsProvider, 'de', 'Deutsch',
                  null, currentLocale),
              _buildLanguageOption(context, settingsProvider, 'fr', 'Français',
                  null, currentLocale),
              _buildLanguageOption(context, settingsProvider, 'ru', 'Русский',
                  null, currentLocale),
              _buildLanguageOption(
                  context, settingsProvider, 'zh', '中文', null, currentLocale),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    SettingsProvider settingsProvider,
    String? localeCode,
    String displayName,
    IconData? icon,
    String? currentLocale,
  ) {
    final isSelected = localeCode == currentLocale;
    return ListTile(
      leading: icon != null
          ? Icon(icon)
          : Text(
              _getFlag(localeCode),
              style: const TextStyle(fontSize: 24),
            ),
      title: Text(displayName),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        settingsProvider.updateSettings(
          settingsProvider.settings.copyWith(locale: localeCode),
        );
        Navigator.pop(context);
      },
    );
  }

  String _getFlag(String? locale) {
    switch (locale) {
      case 'en':
        return '🇬🇧';
      case 'es':
        return '🇪🇸';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'ru':
        return '🇷🇺';
      case 'zh':
        return '🇨🇳';
      default:
        return '🌐';
    }
  }
}

class _LmStudioScanApiKeyDialog extends StatefulWidget {
  final DiscoveredLmStudioServer server;
  final String initialToken;

  const _LmStudioScanApiKeyDialog({
    required this.server,
    required this.initialToken,
  });

  @override
  State<_LmStudioScanApiKeyDialog> createState() =>
      _LmStudioScanApiKeyDialogState();
}

class _LmStudioScanApiKeyDialogState extends State<_LmStudioScanApiKeyDialog> {
  late final TextEditingController _tokenController;
  var _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.key,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.lmStudioAuthDialogTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.server.url,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(l10n.lmStudioAuthDialogMessage),
            const SizedBox(height: 8),
            Text(
              l10n.lmStudioAuthHelpHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              obscureText: _obscureToken,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.apiTokenLabel,
                hintText: l10n.apiTokenHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureToken ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureToken = !_obscureToken),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final token = _tokenController.text.trim();
            if (token.isEmpty) return;
            Navigator.pop(context, token);
          },
          child: Text(l10n.testConnection),
        ),
      ],
    );
  }
}

/// Section-header action that matches [labelSmall] metrics used by SERVER.
class _ServerSectionTestAction extends StatelessWidget {
  final bool probing;
  final VoidCallback onTap;

  const _ServerSectionTestAction({
    required this.probing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
        );

    if (probing) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text('Test servers', style: style),
    );
  }
}

/// Frosted glass pill for the Settings header Advanced switch.
class _SettingsAdvancedGlassToggle extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _SettingsAdvancedGlassToggle({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg =
        isDark ? const Color(0xFF0B0E14) : Colors.white.withValues(alpha: 0.95);
    final pillFg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.9);

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: GlassBlur(
            sigmaX: 32,
            sigmaY: 32,
            child: Container(
              height: HomeGlassHeader.iconSize + 4,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.04),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0.14),
                        ],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.6),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.only(left: 10, right: 4),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(999),
                  border: isDark
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.55 : 0.10),
                      blurRadius: isDark ? 10 : 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: pillFg,
                            fontSize: 12,
                            letterSpacing: -0.1,
                          ),
                    ),
                    Transform.scale(
                      scale: 0.72,
                      alignment: Alignment.centerRight,
                      child: Switch.adaptive(
                        value: value,
                        onChanged: onChanged,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

/// Debug-only row that cycles [NetworkStatusService.debugOverride]:
/// real → mobile data → offline → Wi‑Fi → real.
class _DebugNetworkSimulatorTile extends StatelessWidget {
  const _DebugNetworkSimulatorTile();

  static const _modes = <(String, NetworkSnapshot?)>[
    ('Real network', null),
    ('Mobile data (5G)', NetworkSnapshot([ConnectivityResult.mobile])),
    ('Offline', NetworkSnapshot([ConnectivityResult.none])),
    ('Wi-Fi', NetworkSnapshot([ConnectivityResult.wifi])),
  ];

  @override
  Widget build(BuildContext context) {
    final service = NetworkStatusService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final current = service.isOverridden ? service.snapshot : null;
        var index = _modes.indexWhere((m) => m.$2 == current);
        if (index < 0) index = 0;
        return ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Simulate network (debug)'),
          subtitle: Text(_modes[index].$1),
          trailing: const Icon(Icons.sync_alt_rounded),
          onTap: () {
            final next = _modes[(index + 1) % _modes.length];
            service.debugOverride(next.$2);
          },
        );
      },
    );
  }
}
