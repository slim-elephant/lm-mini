import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/folder_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/adaptive_root.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_wizard_screen.dart';
import 'services/deep_link_service.dart';
import 'services/watch_bridge.dart';
import 'services/download_progress_activity.dart';
import 'services/error_report_service.dart';
import 'services/live_activity_service.dart';
import 'services/support_nudge_service.dart';
import 'utils/audio_session_busy_error.dart';
import 'utils/bundled_google_fonts.dart';
import 'utils/google_font_load_error.dart';
import 'utils/connect_host_error.dart';
import 'utils/localhost_connection_error.dart';
import 'utils/lan_server_error.dart';
import 'utils/server_unreachable_error.dart';
import 'utils/firebase_storage_error.dart';
import 'widgets/setup_help_banner.dart';
import 'services/changelog_service.dart';
import 'services/app_notification_service.dart';
import 'services/ops_alert_service.dart';
import 'services/promotional_premium_service.dart';
import 'services/local_model_download_service.dart';
import 'utils/image_picker_helper.dart';
import 'utils/app_navigator.dart';
import 'utils/pencil_friendly_scroll_behavior.dart';
import 'widgets/changelog_dialog.dart';
import 'widgets/watch_available_dialog.dart';
import 'widgets/crash_error_widget.dart';
import 'widgets/duplicate_subscription_dialog.dart';
import 'widgets/get_started_setup_dialog.dart';
import 'widgets/premium_grant_banner.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'services/widget_data_service.dart';
import 'services/news_widget_service.dart';
import 'services/icloud_sync_service.dart';
import 'services/home_sync_service.dart';
import 'widgets/home_sync_opt_in_dialog.dart';
import 'widgets/support_ticket_dialog.dart';
import 'services/macos_menu_service.dart';
import 'services/persona_analytics_service.dart';
import 'services/app_lock_service.dart';
import 'widgets/app_lock_gate.dart';
import 'desktop/desktop_platform.dart';
import 'desktop/debug_log_buffer.dart';
import 'desktop/host/desktop_host_service.dart';
import 'desktop/runtime/desktop_runtime_manager.dart';
import 'desktop/tray/desktop_tray_service.dart';
import 'services/network_status_service.dart';
import 'utils/client_platform.dart';
import 'dart:async';
import 'dart:io';

// Global variable to track Firebase initialization status
bool firebaseInitialized = false;

// Global deep link service instance
final deepLinkService = DeepLinkService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WatchBridge.install();
  ImagePickerHelper.useSystemPhotoPicker();
  BundledGoogleFonts.disableRuntimeFetching();
  LicenseRegistry.addLicense(() async* {
    try {
      final license = await rootBundle.loadString('google_fonts/OFL.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts'], license);
    } catch (_) {}
  });
  _installErrorHandlers();

  // Wi‑Fi / mobile / offline awareness for LAN chat preflight. Never blocks
  // startup; on plugin errors the service stays "unknown" (= online).
  unawaited(NetworkStatusService.instance.initialize());

  if (Platform.isMacOS) {
    MacosMenuService.instance.initialize();
  }
  if (DesktopPlatform.supportsHostMode) {
    unawaited(() async {
      await DesktopRuntimeManager.instance.reapStaleSidecar();
      await DesktopTrayService.instance.initialize();
      await DesktopHostService.instance.ensureLoaded();
    }());
  }

  // HomeWidget is iOS/Android only — skip on macOS/desktop.
  if (Platform.isIOS || Platform.isAndroid) {
    await WidgetDataService.initialize();
    await WidgetDataService.syncPremiumStatus();
    unawaited(NewsWidgetService.instance.refreshIfPossible());
  }

  // Initialize deep link service
  await deepLinkService.initialize();

  // Track first-use date for milestone nudges
  await SupportNudgeService().ensureFirstUseTracked();

  // Cache docs directory for synchronous image path resolution
  await ImagePickerHelper.cacheDocsDir();
  await AppLockService.instance.load();

  // Try to initialize Firebase, but don't block the app if it fails
  try {
    // Check if Firebase is already initialized (e.g., after hot restart)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    firebaseInitialized = true;
    PremiumConfig.firebaseReady = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    // Check if error is about duplicate app (iOS auto-initialization)
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase was auto-initialized, using existing instance');
      firebaseInitialized = true;
      PremiumConfig.firebaseReady = true;
    } else {
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Feature requests will be unavailable');
    }
  }

  // Sign in anonymously at app launch so Firestore/Storage work immediately.
  // This account will be upgraded to Apple/Google/Email if user subscribes.
  if (firebaseInitialized) {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        final cred = await auth.signInAnonymously();
        debugPrint('🔑 Anonymous auth: ${cred.user?.uid}');
      } else {
        debugPrint('🔑 Existing user: ${auth.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('⚠️ Anonymous auth failed (non-blocking): $e');
    }

    // Admin-only ops alert pushes: register now and whenever the user changes.
    unawaited(OpsAlertService.instance.syncForCurrentUser());
    FirebaseAuth.instance
        .authStateChanges()
        .map((user) => user?.uid)
        .distinct()
        .skip(1)
        .listen((_) => unawaited(OpsAlertService.instance.syncForCurrentUser()));

    // Firebase Analytics: log platform on every mobile session so Android and
    // iOS installs both appear in the Firebase / GA4 console.
    if (Platform.isIOS || Platform.isAndroid) {
      unawaited(_bootstrapFirebaseAnalytics());
    }
  }

  runApp(const MyApp());

  // Initialize premium services in the background (non-blocking).
  // Order matters: subscription first (gates the others), then memory & analytics.
  SubscriptionService().initialize().then((_) async {
    try {
      await AppNotificationService.instance.initialize();
    } catch (e) {
      debugPrint('⚠️ Notification bootstrap skipped: $e');
    }
    await PromotionalPremiumService.instance.initialize();
    // Re-sync premium status to the App Group once RevenueCat has
    // resolved the user's entitlements — otherwise the iOS widget would
    // keep the "Pro feature / locked" placeholder even for paying users
    // because the first sync at app launch runs before initialize() returns.
    WidgetDataService.syncPremiumStatus();
    MemoryService().load();
    AnalyticsService().load();
    CloudApiService().load();
    // Local persona usage (not gated) — Profile UI may still lock display.
    unawaited(PersonaAnalyticsService.instance.load());
  });
}

void _installErrorHandlers() {
  DebugLogBuffer.instance.install();

  FlutterError.onError = (details) {
    if (GoogleFontLoadError.matches(details.exception)) {
      debugPrint('⚠️ [font] ${details.exceptionAsString()}');
      return;
    }
    if (AudioSessionBusyError.matches(details.exception)) {
      debugPrint('⚠️ [audio] ${details.exceptionAsString()}');
      return;
    }
    if (ServerUnreachableError.matches(details.exception)) {
      debugPrint('⚠️ [net] ${details.exceptionAsString()}');
      return;
    }
    if (ConnectHostError.matches(details.exception)) {
      debugPrint('⚠️ [connect] ${details.exceptionAsString()}');
      return;
    }
    if (ErrorReportService.isIgnorable(details.exception)) {
      debugPrint('⚠️ [ignored] ${details.exceptionAsString()}');
      return;
    }
    ErrorReportService.instance.captureFlutter(details);
    FlutterError.presentError(details);
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    if (GoogleFontLoadError.matches(error)) {
      debugPrint('⚠️ [font] $error');
      return true;
    }
    if (AudioSessionBusyError.matches(error)) {
      debugPrint('⚠️ [audio] $error');
      return true;
    }
    if (ServerUnreachableError.matches(error) ||
        LocalhostConnectionError.matches(error)) {
      debugPrint('⚠️ [net] $error');
      return true;
    }
    if (ConnectHostError.matches(error)) {
      debugPrint('⚠️ [connect] $error');
      return true;
    }
    if (FirebaseStorageError.matches(error)) {
      debugPrint('⚠️ [storage] $error');
      return true;
    }
    if (ErrorReportService.isIgnorable(error)) {
      debugPrint('⚠️ [ignored] $error');
      return true;
    }
    ErrorReportService.instance.capture(error, stack, source: 'platform');
    SupportTicketFlow.scheduleUncaughtPrompt();
    return !kDebugMode;
  };

  ErrorWidget.builder = (details) {
    if (GoogleFontLoadError.matches(details.exception)) {
      debugPrint('⚠️ [font] ${details.exceptionAsString()}');
      return const SizedBox.shrink();
    }
    if (AudioSessionBusyError.matches(details.exception)) {
      debugPrint('⚠️ [audio] ${details.exceptionAsString()}');
      return const SizedBox.shrink();
    }
    if (ServerUnreachableError.matches(details.exception)) {
      debugPrint('⚠️ [net] ${details.exceptionAsString()}');
      return const SizedBox.shrink();
    }
    if (ConnectHostError.matches(details.exception)) {
      debugPrint('⚠️ [connect] ${details.exceptionAsString()}');
      return const SizedBox.shrink();
    }
    if (FirebaseStorageError.matches(details.exception)) {
      debugPrint('⚠️ [storage] ${details.exceptionAsString()}');
      return const SizedBox.shrink();
    }
    if (ErrorReportService.isIgnorable(details.exception)) {
      debugPrint('⚠️ [ignored] ${details.exceptionAsString()}');
      return const SizedBox.shrink();
    }
    ErrorReportService.instance.captureFlutter(details);
    return CrashErrorWidget(details: details);
  };
}

Future<void> _bootstrapFirebaseAnalytics() async {
  try {
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
    await analytics.logAppOpen();
    await analytics.setUserProperty(
      name: 'app_platform',
      value: ClientPlatform.storageKey,
    );
    debugPrint('📊 Firebase Analytics ready (${ClientPlatform.displayLabel})');
  } catch (e) {
    debugPrint('⚠️ Firebase Analytics bootstrap failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: SubscriptionService()),
        ChangeNotifierProvider.value(value: AppLockService.instance),
      ],
      child: Consumer2<SettingsProvider, ThemeProvider>(
        builder: (context, settingsProvider, themeProvider, child) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            title: 'LM Mini',
            debugShowCheckedModeBanner: false,
            // Apple Pencil long-press selects text; finger/mouse scroll lists.
            scrollBehavior: const AppScrollBehavior(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: settingsProvider.settings.locale != null
                ? Locale(settingsProvider.settings.locale!)
                : null,
            theme: themeProvider.buildThemeData(Brightness.light),
            darkTheme: themeProvider.buildThemeData(Brightness.dark),
            themeMode: settingsProvider.settings.themeMode,
            builder: (context, child) {
              final scaleFactor = settingsProvider.settings.chatFontSize / 14.0;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final overlayStyle = isDark
                  ? SystemUiOverlayStyle.light.copyWith(
                      statusBarColor: Colors.transparent,
                    )
                  : SystemUiOverlayStyle.dark.copyWith(
                      statusBarColor: Colors.transparent,
                    );
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyle,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scaleFactor),
                  ),
                  child: AppLockGate(child: child!),
                ),
              );
            },
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with WidgetsBindingObserver {
  bool _hasNavigatedToSettings = false;
  bool _showSplash = true;
  Timer? _syncDownTimer;
  VoidCallback? _premiumGrantListener;
  bool _desktopHostWasSuspended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial sync down when app opens natively
    _performSyncDown();
    _startSyncTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.loadSettings();
      if (mounted) {
        _attachHomeSync();
      }

      if (mounted) {
        final themeProvider = context.read<ThemeProvider>();
        await themeProvider.load(settingsProvider.settings.selectedThemeId);
      }

      _premiumGrantListener = () {
        _handlePremiumGrantUpdates();
        _checkPremiumGrantWelcome();
      };
      PromotionalPremiumService.instance.addListener(_premiumGrantListener!);
      await PromotionalPremiumService.instance.initialize();
      _handlePremiumGrantUpdates();
    });
  }

  bool _isGenerationInFlight() {
    if (!mounted) return false;
    try {
      return context.read<ChatProvider>().isGenerationInFlight;
    } catch (_) {
      return false;
    }
  }

  Future<void> _performSyncDown() async {
    if (_isGenerationInFlight()) return;
    bool hasChanges = await ICloudSyncService().syncDown();
    final homeChanged = await HomeSyncService.instance.syncNow();
    if ((hasChanges || homeChanged) && mounted) {
      final chatProvider = context.read<ChatProvider>();
      // Reload the conversations and active chat messages natively without user refresh
      await context.read<FolderProvider>().loadFolders();
      await chatProvider.loadConversations();
      if (chatProvider.currentConversation?.id != null) {
        await chatProvider
            .selectConversation(chatProvider.currentConversation!.id);
      }
    }
  }

  void _attachHomeSync() {
    final settings = context.read<SettingsProvider>();
    HomeSyncService.instance.attach(
      settings: () => settings.settings,
      shouldDefer: _isGenerationInFlight,
      applyPersonas: settings.applyHomeSyncPersonas,
      onApplied: () async {
        if (!mounted) return;
        await context.read<FolderProvider>().loadFolders(silent: true);
        if (!mounted) return;
        final chat = context.read<ChatProvider>();
        await chat.loadConversations(silent: true);
      },
    );
    HomeSyncService.instance.startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(maybeShowHomeSyncOptIn(context));
    });
  }

  @override
  void dispose() {
    if (_premiumGrantListener != null) {
      PromotionalPremiumService.instance.removeListener(_premiumGrantListener!);
    }
    WidgetsBinding.instance.removeObserver(this);
    _syncDownTimer?.cancel();
    HomeSyncService.instance.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (DesktopPlatform.supportsHostMode &&
        (state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused)) {
      _desktopHostWasSuspended = true;
    }
    if (state == AppLifecycleState.resumed) {
      // User came back from background, sync down immediately
      _performSyncDown();
      _startSyncTimer();
      unawaited(PromotionalPremiumService.instance.initialize());
      _handlePremiumGrantUpdates();
      // Refresh the Pro news widget content if stale (no-op for free users
      // or when no prompt is configured).
      unawaited(NewsWidgetService.instance.refreshIfPossible());
      // Connection may have changed while backgrounded (Wi‑Fi → 5G).
      unawaited(NetworkStatusService.instance.refresh());
      // Restore remote LM Connect if it dropped while backgrounded.
      if (mounted) {
        unawaited(context.read<SettingsProvider>().onAppResumed());
      }
      if (DesktopPlatform.supportsHostMode) {
        final fromSuspend = _desktopHostWasSuspended;
        _desktopHostWasSuspended = false;
        unawaited(
          DesktopHostService.instance.onAppResumed(fromSuspend: fromSuspend),
        );
      }
    } else if (state == AppLifecycleState.detached) {
      if (DesktopPlatform.supportsSidecarRuntime) {
        unawaited(DesktopRuntimeManager.instance.stop());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Don't poll in background
      _syncDownTimer?.cancel();
      if (mounted) {
        context.read<SettingsProvider>().onAppPaused();
      }
      // iOS ends Live Activities on become-active. Bring them back when the
      // user leaves again if a download or generation is still running.
      if (state == AppLifecycleState.paused) {
        unawaited(LiveActivityService.instance.reassertIfNeeded());
        unawaited(DownloadProgressActivity.instance.reassertIfNeeded());
      }
    }
  }

  void _startSyncTimer() {
    _syncDownTimer?.cancel();
    _syncDownTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _performSyncDown();
    });
  }

  void _onSplashFinished() {
    if (!mounted) return;
    setState(() => _showSplash = false);

    final settingsProvider = context.read<SettingsProvider>();

    // Show welcome wizard for first-time users
    if (!settingsProvider.settings.hasCompletedOnboarding) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeWizardScreen()),
      );
      return;
    }

    unawaited(_maybeShowProviderGuidance(settingsProvider));

    // Check for new changelog entry (non-blocking)
    _checkChangelog();

    // Complimentary Pro welcome dialog (non-blocking)
    _checkPremiumGrantWelcome();

    // Remind lifetime upgraders to cancel their still-active subscription.
    _checkDuplicateSubscriptionReminder();
  }

  Future<void> _maybeShowProviderGuidance(
      SettingsProvider settingsProvider) async {
    if (_hasNavigatedToSettings || !mounted) return;
    await LocalModelDownloadService.instance.init();
    if (!mounted || _hasNavigatedToSettings) return;

    // Friendly get-started when onboarding was skipped / no model; otherwise
    // the older connection popups for partial setups.
    if (settingsProvider.needsGetStartedGuidance) {
      _hasNavigatedToSettings = true;
      await showGetStartedSetupDialog(context);
    } else if (settingsProvider.needsSetup) {
      _hasNavigatedToSettings = true;
      _showConnectionPopup(context);
    } else if (settingsProvider.needsConnectionHelp) {
      _hasNavigatedToSettings = true;
      _showConnectionErrorPopup(context, settingsProvider);
    }
  }

  Future<void> _checkDuplicateSubscriptionReminder() async {
    if (_showSplash || !mounted) return;

    final sub = SubscriptionService();
    if (!sub.isInitialized) {
      await sub.initialize();
    }
    if (!mounted || !sub.hasBothSubscriptionAndLifetime) return;

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await DuplicateSubscriptionDialog.show(context);
  }

  Future<void> _checkPremiumGrantWelcome() async {
    if (_showSplash || !mounted) return;
    final promo = PromotionalPremiumService.instance;
    if (!await promo.shouldShowWelcomeDialog() || !mounted) return;
    final grant = promo.pendingWelcomeGrant;
    if (grant == null) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await PremiumGrantWelcomeDialog.show(context, grant);
    await promo.markWelcomeDialogShown();
  }

  Future<void> _handlePremiumGrantUpdates() async {
    if (!mounted || !firebaseInitialized) return;
    final grant = PromotionalPremiumService.instance.pendingWelcomeGrant;
    if (grant == null || grant.notificationSent) return;

    await AppNotificationService.instance.requestPermissionIfNeeded();
    final reason = grant.reason?.trim();
    final body = reason != null && reason.isNotEmpty
        ? 'Complimentary Pro for ${grant.durationLabel}. Reason: $reason'
        : 'Complimentary Pro access for ${grant.durationLabel}. Open the app to explore premium features.';
    await AppNotificationService.instance.showPremiumGrantNotification(
      title: 'You received LM Mini Pro',
      body: body,
    );
    await PromotionalPremiumService.instance.markNotificationHandled();
  }

  Future<void> _checkChangelog() async {
    final entry = await ChangelogService().checkForNewChangelog();
    if (entry != null && mounted) {
      // Small delay so the home screen is fully rendered
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ChangelogDialog.show(context, entry);
      }
      return;
    }
    await _maybeShowWatchAvailable();
  }

  Future<void> _maybeShowWatchAvailable() async {
    if (!mounted) return;
    final watch = await WatchBridge.watchAvailability();
    if (watch == null || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await WatchAvailableDialog.show(context, installed: watch.installed);
    await WatchBridge.markWatchNoticeShown();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onFinished: _onSplashFinished);
    }

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return const AdaptiveRoot();
      },
    );
  }

  void _showConnectionPopup(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.connectionPopupTitle),
        content: Text(
          l10n.connectionPopupBody,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.connectionPopupDismiss),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Text(l10n.connectionPopupGoToSettings),
          ),
        ],
      ),
    );
  }

  void _showConnectionErrorPopup(
      BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final error =
        settingsProvider.connectionError ?? l10n.connectionFailedMessage;
    if (settingsProvider.settings.usbModeEnabled) {
      showConnectHostHelpDialog(
        context,
        kind: ConnectHostErrorKind.usb,
        onGoToSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      );
      return;
    }
    if (showConnectHostHelpIfNeeded(
      context,
      error: error,
      serverUrl: settingsProvider.settings.serverUrl,
      isRemoteActive: settingsProvider.settings.isRemoteActive,
      usbModeEnabled: settingsProvider.settings.usbModeEnabled,
      providerKind: settingsProvider.settings.activeProviderKind,
      onGoToSettings: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
    )) {
      return;
    }
    if (LanServerError.shouldShowLmStudioLanHelp(
      error: error,
      serverUrl: settingsProvider.settings.serverUrl,
      providerKind: settingsProvider.settings.activeProviderKind,
    )) {
      showLmStudioLanHelpDialog(
        context,
        kind: LanServerError.classify(error) ??
            LanServerErrorKind.connectionRefused,
        onGoToSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      );
      return;
    }
    final body = LocalhostConnectionError.matches(
      error,
      serverUrl: settingsProvider.settings.serverUrl,
    )
        ? l10n.localhostConnectionHelp
        : l10n.connectionError(error);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.connectionFailed),
        content: Text(
          body,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.connectionPopupDismiss),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Text(l10n.connectionPopupGoToSettings),
          ),
        ],
      ),
    );
  }
}
