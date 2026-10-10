import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_preflight_error.dart';
import '../providers/chat_provider.dart';
import '../models/chat_conversation.dart';
import '../models/chat_folder.dart';
import '../models/system_prompt.dart';
import '../providers/settings_provider.dart';
import '../providers/folder_provider.dart';
import '../services/deep_link_service.dart';
import '../services/shortcuts_handler.dart';
import '../main.dart' show deepLinkService;
import '../utils/chat_title.dart';
import '../utils/image_picker_helper.dart';
import '../utils/layout_utils.dart';
import '../utils/localhost_connection_error.dart';
import '../utils/lan_server_error.dart';
import '../widgets/compact_error_banner.dart';
import '../widgets/setup_help_banner.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'group_chat_setup_screen.dart';
import 'arena_setup_screen.dart';
import 'system_prompts_screen.dart';
import 'persona_profile_screen.dart';
import 'local_models_screen.dart';
import 'model_parameters_screen.dart';
import 'image_generation_settings_screen.dart';
import 'news_response_screen.dart';
import '../services/local_model_download_service.dart';
import '../widgets/conversation_list_item.dart';
import '../widgets/folder_list_item.dart';
import '../widgets/folder_dialog.dart';
import '../widgets/get_started_setup_dialog.dart';
import '../widgets/deprecation_banners.dart';
import '../widgets/premium_grant_banner.dart';
import '../services/promotional_premium_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feature_request_home_settings_button.dart';
import '../widgets/global_download_fab.dart';
import '../widgets/select_model_sheet.dart';
import '../widgets/desktop_shortcuts.dart';
import '../widgets/home_glass_header.dart';
import '../utils/theme_extensions.dart';
import '../utils/group_chat_pro_gate.dart';
import '../pro/pro_features.dart';

class HomeScreen extends StatefulWidget {
  /// When true, the HomeScreen is hosted inside the DesktopShell and should
  /// skip rendering its own navigation rail / shell chrome.
  final bool embeddedInShell;

  const HomeScreen({super.key, this.embeddedInShell = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String? _selectedFolderId;

  /// When the two-column iPad layout is active, the right (detail) pane
  /// renders a `ChatScreen` for this conversation. Null means "show empty
  /// state placeholder". On phone-sized devices this field is unused
  /// because we push `ChatScreen` onto the navigator instead.
  String? _selectedConversationId;
  bool _showSearch = false;
  bool _showFolders = false;
  bool _settingsLoadedFromDisk = false;

  /// When `true`, hides the master pane in the iPad two-column layout so
  /// the currently selected chat takes the entire window. Toggled by the
  /// expand/collapse icon overlay in `_buildDetailPane`.
  bool _detailFullScreen = false;
  bool _detailLaunchCamera = false;
  bool _personasExpanded = false;

  /// Guards auto-fill of the split detail pane (avoids dialog / create loops).
  bool _detailFillInFlight = false;

  /// Double-tap on + / New Chat used to push two ChatScreens in one ms.
  bool _createNewChatInFlight = false;
  StreamSubscription<DeepLinkActionEvent>? _deepLinkSubscription;

  // Bulk selection
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  /// Conversation id currently being opened after a list tap (subtle spinner).
  String? _openingConversationId;

  /// Home list filter: 1:1 chats vs group chats.
  HomeListTab _listTab = HomeListTab.chats;

  /// When true, column 3 shows [GroupChatSetupScreen] instead of a chat.
  bool _showGroupSetup = false;

  @override
  void initState() {
    super.initState();
    _loadPersonasExpandedPref();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FolderProvider>().loadFolders();
      if (!mounted) return;
      await context.read<ChatProvider>().loadConversations();
      // Add listener for settings changes - will fire when settings load from disk
      context.read<SettingsProvider>().addListener(_onSettingsChanged);

      // Handle pending deep link action (app was launched from widget)
      _handlePendingDeepLink();

      // Listen for future deep link actions (app was already running)
      _deepLinkSubscription =
          deepLinkService.actionStream.listen(_handleDeepLinkAction);
    });
  }

  Future<void> _loadPersonasExpandedPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _personasExpanded = prefs.getBool('personas_section_expanded') ?? false;
      });
    }
  }

  Future<void> _togglePersonasSection() async {
    final newVal = !_personasExpanded;
    setState(() => _personasExpanded = newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('personas_section_expanded', newVal);
  }

  void _handlePendingDeepLink() {
    final pendingAction = deepLinkService.pendingAction;
    if (pendingAction != null) {
      deepLinkService.clearPendingAction();
      // Delay slightly to ensure providers are loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _handleDeepLinkAction(pendingAction);
        }
      });
    }
  }

  void _handleDeepLinkAction(DeepLinkActionEvent event) {
    switch (event.action) {
      case DeepLinkAction.newChat:
        _createNewChat();
        break;
      case DeepLinkAction.newChatWithCamera:
        _createNewChatWithCamera();
        break;
      case DeepLinkAction.openChat:
        if (event.arg != null) _openChat(event.arg!);
        break;
      case DeepLinkAction.openFolder:
        _openFolderFromDeepLink(event.arg);
        break;
      case DeepLinkAction.startPersonaChat:
        _startPersonaChatById(event.arg);
        break;
      case DeepLinkAction.openNewsWidget:
        // Tap on the iOS News widget should open the latest briefing, not
        // the settings screen. Widget Settings is reachable from the
        // AppBar action on that page (and from Settings → Widgets).
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NewsResponseScreen(),
          ),
        );
        break;
      case DeepLinkAction.runShortcut:
        // Sent by iOS Shortcuts via `lmmini://shortcut/<path>?...` or by
        // an App Intent. ShortcutsHandler parses the URL, routes to the
        // right pipeline, and shows the result inline.
        ShortcutsHandler.instance.handle(context, event.arg);
        break;
    }
  }

  void _openFolderFromDeepLink(String? folderId) {
    if (folderId == null) return;
    final folders = context.read<FolderProvider>().folders;
    if (!folders.any((f) => f.id == folderId)) return;
    setState(() {
      _showFolders = true;
      _selectedFolderId = folderId;
    });
  }

  void _startPersonaChatById(String? personaId) {
    if (personaId == null) return;
    final settings = context.read<SettingsProvider>().settings;
    final personas = (settings.savedSystemPrompts ?? [])
        .where((p) => p.id == personaId)
        .toList();
    if (personas.isEmpty) return;
    _startPersonaChat(personas.first);
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    try {
      context.read<SettingsProvider>().removeListener(_onSettingsChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!_settingsLoadedFromDisk) {
      _loadViewPreference();
    }
  }

  void _loadViewPreference() {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>().settings;
    setState(() {
      _showFolders = settings.showFoldersView;
      _settingsLoadedFromDisk = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    context.watch<SettingsProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final voiceCallConvId = chatProvider.voiceCallConversationId;

    final gradientDecoration = context.themeGradientDecoration;
    final twoCol = _isTwoColumn(context);
    String? folderTitle;
    if (!_showFolders &&
        _selectedFolderId != null &&
        context.read<FolderProvider>().folders.isNotEmpty) {
      folderTitle = context
          .read<FolderProvider>()
          .folders
          .firstWhere(
            (f) => f.id == _selectedFolderId,
            orElse: () => context.read<FolderProvider>().folders.first,
          )
          .name;
    }

    // Public build: group replies are not available, so the Groups tab only
    // shows when restored group chats exist, and never offers "New group chat".
    final showGroupsTab = _groupsTabVisible(chatProvider);
    if (!showGroupsTab && _listTab == HomeListTab.groups) {
      _listTab = HomeListTab.chats;
    }
    final groupCreate = _listTab == HomeListTab.groups && ProFeatures.included;

    final headerH = HomeGlassHeader.heightFor(context,
        embeddedInShell: widget.embeddedInShell);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final phoneLandscapeSplit = isPhoneLandscapeSplit(context);
    // Folders mode uses its own surface (light sheet / near-black). Chats keep the navy top zone.
    final Color homeTopBg;
    if (widget.embeddedInShell) {
      homeTopBg = isDark ? const Color(0xFF0E1117) : colorScheme.surface;
    } else if (gradientDecoration != null) {
      homeTopBg = Colors.transparent;
    } else if (_showFolders) {
      homeTopBg = isDark ? const Color(0xFF080A0F) : colorScheme.surface;
    } else {
      // Rich navy top zone (header + personas) — readable white labels.
      homeTopBg = isDark ? const Color(0xFF1A202E) : const Color(0xFF243044);
    }
    // Folders light mode → dark status icons; navy top zone → light icons.
    final statusStyle = widget.embeddedInShell ||
            (_showFolders && !isDark) ||
            (gradientDecoration != null && !isDark)
        ? SystemUiOverlayStyle.dark
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          );

    if (twoCol && _selectedConversationId == null && !_showGroupSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_ensureDetailPaneFilled());
      });
    }

    final glassHeader = HomeGlassHeader(
      listTab: _listTab,
      showGroupsTab: showGroupsTab,
      onListTabChanged: (tab) => setState(() => _listTab = tab),
      showFolders: _showFolders,
      showSearch: _showSearch,
      selectionMode: _selectionMode,
      selectedCount: _selectedIds.length,
      folderTitle: folderTitle,
      onFolderBack: () {
        setState(() {
          _selectedFolderId = null;
          _showFolders = true;
        });
      },
      onSearchChanged: (value) {
        setState(() => _searchQuery = value.toLowerCase());
      },
      onEnterSelection: () => setState(() => _selectionMode = true),
      onExitSelection: () {
        setState(() {
          _selectionMode = false;
          _selectedIds.clear();
        });
      },
      onSelectAll: () {
        final chatProvider = context.read<ChatProvider>();
        var convos = _visibleConversations(chatProvider);
        setState(() {
          if (_selectedIds.length == convos.length) {
            _selectedIds.clear();
          } else {
            _selectedIds
              ..clear()
              ..addAll(convos.map((c) => c.id));
          }
        });
      },
      onBulkMove: _selectedIds.isEmpty ? null : _bulkMoveToFolder,
      onBulkDelete: _selectedIds.isEmpty ? null : _bulkDelete,
      onToggleFolders: () {
        setState(() {
          _showFolders = !_showFolders;
          if (_showFolders) {
            _showSearch = false;
          }
        });
        final settingsProvider = context.read<SettingsProvider>();
        settingsProvider.updateSettings(
          settingsProvider.settings.copyWith(showFoldersView: _showFolders),
        );
      },
      onToggleSearch: () {
        setState(() {
          _showSearch = !_showSearch;
          if (!_showSearch) {
            _searchQuery = '';
          }
          if (_showSearch) {
            _showFolders = false;
          }
        });
      },
      onOpenArena: widget.embeddedInShell ? null : _openArena,
      onNewGroupChat: ProFeatures.included ? _createNewGroupChat : null,
      settingsButton: widget.embeddedInShell
          ? const SizedBox.shrink()
          : const FeatureRequestAwareSettingsButton(useGlass: true),
      selectTooltip: l10n.select,
      foldersTooltip: l10n.foldersTooltip,
      chatsTooltip: l10n.homeTitle,
      searchHint: l10n.homeSearchHint,
      // Shell always shows Chats/Groups labels — compact icon-only is for
      // phone landscape / very narrow master panes only.
      compactTabs: !widget.embeddedInShell &&
          (phoneLandscapeSplit || (twoCol && _masterPaneWidth(context) <= 300)),
      embeddedInShell: widget.embeddedInShell,
    );

    final chatFab = _showFolders
        ? GlassCircleIconButton(
            size: phoneLandscapeSplit ? 50 : 58,
            tooltip: l10n.newFolder,
            isActive: true,
            prominent: true,
            onLightCanvas: !isDark,
            onTap: _createFolder,
            child: Icon(
              Icons.create_new_folder_outlined,
              size: phoneLandscapeSplit ? 22 : 26,
              color:
                  isDark ? Colors.white : Colors.black.withValues(alpha: 0.88),
            ),
          )
        : GlassCircleIconButton(
            size: phoneLandscapeSplit ? 50 : 58,
            tooltip: groupCreate ? l10n.newGroupChat : l10n.newChat,
            isActive: true,
            prominent: true,
            onLightCanvas: !isDark,
            onTap: groupCreate ? _createNewGroupChat : _createNewChat,
            child: Icon(
              groupCreate ? Icons.group_add_rounded : Icons.add_rounded,
              size: phoneLandscapeSplit ? 24 : 28,
              color:
                  isDark ? Colors.white : Colors.black.withValues(alpha: 0.88),
            ),
          );
    final masterFab = ListenableBuilder(
      listenable: LocalModelDownloadService.instance,
      builder: (context, _) {
        if (!_showFolders && _onDeviceNeedsModel()) {
          return const SizedBox.shrink();
        }
        return chatFab;
      },
    );

    final Widget masterScaffold;
    if (widget.embeddedInShell) {
      masterScaffold = Scaffold(
        backgroundColor: homeTopBg,
        body: Column(
          children: [
            glassHeader,
            if (voiceCallConvId != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: voiceCallConvId,
                        openInVoiceMode: true,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: Colors.red,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_in_talk,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        l10n.tapToReturnToCall,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child:
                  _showFolders ? _buildFolderView() : _buildConversationView(),
            ),
          ],
        ),
        floatingActionButton: masterFab,
      );
    } else if (phoneLandscapeSplit) {
      // iPhone landscape split: entire left column scrolls (no sticky header /
      // personas). iPad keeps the sticky duo-tone chrome below.
      // Pin + with Stack — Scaffold FAB mis-positions custom glass buttons
      // inside a narrow master pane.
      masterScaffold = Scaffold(
        backgroundColor: homeTopBg,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: statusStyle,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: glassHeader),
                    if (voiceCallConvId != null)
                      SliverToBoxAdapter(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  conversationId: voiceCallConvId,
                                  openInVoiceMode: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            color: Colors.red,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_in_talk,
                                    color: Colors.white, size: 13),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.tapToReturnToCall,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: ListenableBuilder(
                        listenable: PromotionalPremiumService.instance,
                        builder: (context, _) {
                          final grant = PromotionalPremiumService
                              .instance.pendingBannerGrant;
                          if (grant == null) return const SizedBox.shrink();
                          return PremiumGrantBanner(
                            grant: grant,
                            onDismiss: () async {
                              await PromotionalPremiumService.instance
                                  .acknowledgeWelcome();
                            },
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: DeprecationBanners()),
                    SliverToBoxAdapter(
                      child: _showFolders
                          ? SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.7,
                              child: _buildFolderView(),
                            )
                          : _buildConversationView(scrollableMaster: true),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12 + MediaQuery.paddingOf(context).right,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
              child: masterFab,
            ),
          ],
        ),
      );
    } else {
      masterScaffold = Scaffold(
        backgroundColor: homeTopBg,
        // Let wallpaper/gradient show through the transparent glass header.
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(headerH),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: statusStyle,
            child: glassHeader,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Reserve space under the overlay header (personas stay below it).
                SizedBox(height: headerH),
                // Thin call banner when voice is active
                if (voiceCallConvId != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversationId: voiceCallConvId,
                            openInVoiceMode: true,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      color: Colors.red,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_in_talk,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            l10n.tapToReturnToCall,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      ListenableBuilder(
                        listenable: PromotionalPremiumService.instance,
                        builder: (context, _) {
                          final grant = PromotionalPremiumService
                              .instance.pendingBannerGrant;
                          if (grant == null) return const SizedBox.shrink();
                          return PremiumGrantBanner(
                            grant: grant,
                            onDismiss: () async {
                              await PromotionalPremiumService.instance
                                  .acknowledgeWelcome();
                            },
                          );
                        },
                      ),
                      const DeprecationBanners(),
                      Expanded(
                        child: _showFolders
                            ? _buildFolderView()
                            : _buildConversationView(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 22 + MediaQuery.paddingOf(context).right,
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
              child: masterFab,
            ),
          ],
        ),
      );
    }

    final body =
        twoCol ? _buildTwoColumnBody(context, masterScaffold) : masterScaffold;

    return DesktopShortcuts(
      bindings: {
        desktopMeta(LogicalKeyboardKey.keyN): _createNewChat,
        desktopMeta(LogicalKeyboardKey.comma): _openSettings,
        desktopMeta(LogicalKeyboardKey.keyF): () {
          setState(() {
            _showSearch = true;
            _showFolders = false;
          });
        },
        desktopMeta(LogicalKeyboardKey.keyW): _handleCloseShortcut,
      },
      child: Stack(
        children: [
          if (gradientDecoration != null)
            Positioned.fill(
                child: DecoratedBox(decoration: gradientDecoration)),
          body,
          ListenableBuilder(
            listenable: LocalModelDownloadService.instance,
            builder: (context, _) {
              if (_showOnDeviceDownloadProgress() &&
                  !_showFolders &&
                  _visibleConversations(chatProvider).isEmpty) {
                return const SizedBox.shrink();
              }
              return GlobalDownloadFAB(headerBottom: headerH);
            },
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _handleCloseShortcut() {
    if (_isTwoColumn(context) && _showGroupSetup) {
      setState(() => _showGroupSetup = false);
      return;
    }
    if (_isTwoColumn(context) && _selectedConversationId != null) {
      setState(() {
        _selectedConversationId = null;
        _detailFullScreen = false;
      });
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// True when we should render the master/detail layout (iMessage / Mail style).
  ///
  /// Tablets (any orientation), wide macOS windows, and phones in landscape
  /// with enough width get the split.
  bool _isTwoColumn(BuildContext context) {
    if (widget.embeddedInShell) return true;
    return prefersMasterDetailLayout(context);
  }

  /// Build the iPad master/detail layout. Left pane is fixed-width and
  /// hosts the existing conversation list scaffold. Right pane shows the
  /// currently selected conversation, or an empty-state placeholder.
  Widget _buildTwoColumnBody(BuildContext context, Widget master) {
    final colorScheme = Theme.of(context).colorScheme;
    // When the user has explicitly expanded the chat to full screen, hide
    // the master pane entirely so the chat fills the whole window.
    if (_detailFullScreen &&
        _selectedConversationId != null &&
        !_showGroupSetup) {
      return _buildDetailPane(context);
    }
    // Narrower master on phone landscape / compact widths so chat stays readable.
    final masterWidth = _masterPaneWidth(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        Expanded(child: _buildDetailPane(context)),
      ],
    );
  }

  double _masterPaneWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 780) return 260;
    if (size.width < 900) return 300;
    return 360;
  }

  /// When split view has no selection, open a new chat in the detail pane
  /// (do not auto-select an existing conversation).
  Future<void> _ensureDetailPaneFilled() async {
    if (!mounted || !_isTwoColumn(context)) return;
    if (_showGroupSetup) return;
    if (_selectedConversationId != null || _detailFillInFlight) return;

    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.isLoading) return;

    _detailFillInFlight = true;
    try {
      if (!mounted || _selectedConversationId != null || _showGroupSetup) {
        return;
      }
      await _openNewChatInSplitView();
    } finally {
      _detailFillInFlight = false;
    }
  }

  Widget _buildDetailPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_showGroupSetup) {
      return GroupChatSetupScreen(
        key: const ValueKey('detail-group-setup'),
        folderId: _selectedFolderId,
        embedded: true,
        onDismiss: () {
          setState(() => _showGroupSetup = false);
          // Restore a chat in the pane if we cleared selection for setup.
          if (_selectedConversationId == null) {
            unawaited(_ensureDetailPaneFilled());
          }
        },
        onCreated: (conversationId) {
          setState(() {
            _showGroupSetup = false;
            _selectedConversationId = conversationId;
            _detailFullScreen = false;
            _listTab = HomeListTab.groups;
            _showFolders = false;
          });
          unawaited(context.read<ChatProvider>().loadConversations());
        },
      );
    }

    final selectedId = _selectedConversationId;
    if (selectedId == null) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: colorScheme.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.selectConversation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.selectConversationHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    // Use a ValueKey so the ChatScreen rebuilds with fresh state when the
    // selected conversation changes (otherwise Flutter would try to reuse
    // the controller, scroll position, etc).
    return ChatScreen(
      key: ValueKey('detail-$selectedId'),
      conversationId: selectedId,
      launchCamera: _detailLaunchCamera,
      showExpandToggle: true,
      showDownloadFab: false,
      embeddedInShell: widget.embeddedInShell,
      onConversationReplaced: (id) {
        setState(() {
          _selectedConversationId = id;
          _detailLaunchCamera = false;
        });
      },
      isExpanded: _detailFullScreen,
      onToggleExpanded: () =>
          setState(() => _detailFullScreen = !_detailFullScreen),
    );
  }

  Widget _buildFolderView() {
    return Consumer<FolderProvider>(
      builder: (context, folderProvider, child) {
        final l10n = AppLocalizations.of(context);
        if (folderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (folderProvider.folders.isEmpty) {
          final scheme = Theme.of(context).colorScheme;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 64,
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noFoldersTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noFoldersSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final conversations = context.read<ChatProvider>().listedConversations;

        // "All Conversations" header (not part of reorderable list)
        final allCount = conversations.where((c) => c.folderId == null).length;

        return Column(
          children: [
            // Fixed "All Conversations" item at top
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 5),
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.35),
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_rounded, color: Colors.white),
                ),
                title: Text(l10n.allConversations,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n.conversationCount(allCount)),
                onTap: () {
                  setState(() {
                    _showFolders = false;
                    _selectedFolderId = null;
                  });
                },
              ),
            ),
            // Reorderable folder list
            Expanded(
              child: ClipRect(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: folderProvider.folders.length,
                  onReorder: (oldIndex, newIndex) {
                    folderProvider.reorderFolders(oldIndex, newIndex);
                  },
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final folder = folderProvider.folders[index];
                    final count = conversations
                        .where((c) => c.folderId == folder.id)
                        .length;

                    return ReorderableDragStartListener(
                      key: ValueKey(folder.id),
                      index: index,
                      child: FolderListItem(
                        folder: folder,
                        conversationCount: count,
                        isSelected: _selectedFolderId == folder.id,
                        onTap: () {
                          setState(() {
                            _showFolders = false;
                            _selectedFolderId = folder.id;
                          });
                        },
                        onEdit: () => _editFolder(folder),
                        onDelete: () => _deleteFolder(folder.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConversationView({bool scrollableMaster = false}) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final l10n = AppLocalizations.of(context);
        if (chatProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final colorScheme = Theme.of(context).colorScheme;
        final hasBgGradient = context.hasBackgroundGradient;
        final sheetColor = hasBgGradient
            ? colorScheme.surface.withValues(alpha: 0.92)
            : colorScheme.surface;
        const sheetRadius = 28.0;
        final showPersonas = !scrollableMaster;
        final emptyList = _visibleConversations(chatProvider).isEmpty;

        Widget emptyState({required bool compact}) {
          return ListenableBuilder(
            listenable: LocalModelDownloadService.instance,
            builder: (context, _) {
              if (_showOnDeviceDownloadProgress()) {
                return _HomeWaitingForAi(
                  compact: compact,
                  entry: _firstOnDeviceWaitEntry(),
                  onRetry: _retryFirstOnDeviceDownload,
                );
              }
              if (_showOnDeviceDownloadPrompt()) {
                return _HomeDownloadOnDevicePrompt(
                  compact: compact,
                  onDownload: _openOnDeviceModels,
                );
              }
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: compact ? 32 : 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _listTab == HomeListTab.groups
                          ? Icons.groups_outlined
                          : Icons.chat_bubble_outline,
                      size: compact ? 48 : 72,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _listTab == HomeListTab.groups
                          ? l10n.noGroupChatsYet
                          : l10n.noConversationsTitle,
                      style: compact
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _listTab == HomeListTab.groups
                          ? l10n.noGroupChatsSubtitle
                          : l10n.noConversationsSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_listTab != HomeListTab.groups ||
                        ProFeatures.included) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _listTab == HomeListTab.groups
                            ? _createNewGroupChat
                            : _createNewChat,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _listTab == HomeListTab.groups
                              ? l10n.newGroupChat
                              : l10n.newChat,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        }

        Widget chatSheet({required bool expandList}) {
          final listChild = emptyList
              ? (expandList
                  ? Center(child: emptyState(compact: false))
                  : emptyState(compact: true))
              : _buildConversationsList(
                  chatProvider,
                  shrinkWrap: !expandList,
                  physics:
                      expandList ? null : const NeverScrollableScrollPhysics(),
                );

          if (widget.embeddedInShell) {
            return listChild;
          }

          return Material(
            color: sheetColor,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(sheetRadius),
              bottom: scrollableMaster
                  ? const Radius.circular(sheetRadius)
                  : Radius.zero,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: expandList ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (showPersonas)
                  // Full-width hit target: extra space above the pill so the
                  // open/close bar is easy to tap, not just the 4pt handle.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePersonasSection,
                    onVerticalDragEnd: (details) {
                      final dy = details.primaryVelocity ?? 0;
                      if (dy.abs() < 120) return;
                      // Drag down → show personas; drag up → hide.
                      final wantExpanded = dy > 0;
                      if (wantExpanded != _personasExpanded) {
                        _togglePersonasSection();
                      }
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _PersonaSheetHandle(
                            expanded: _personasExpanded,
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
                if (expandList) Expanded(child: listChild) else listChild,
              ],
            ),
          );
        }

        // Phone landscape split: no personas; sheet scrolls with the header.
        if (scrollableMaster) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chatProvider.error != null)
                _buildErrorBanner(context, chatProvider),
              chatSheet(expandList: false),
            ],
          );
        }

        // When embedded in shell, skip the personas row — it has its own tab.
        if (widget.embeddedInShell) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (chatProvider.error != null)
                _buildErrorBanner(context, chatProvider),
              Expanded(child: chatSheet(expandList: true)),
            ],
          );
        }

        // Reference layout: tight top (personas on shared scaffold tint) +
        // separate rounded chats sheet filling the rest — no empty band.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Offline / mobile-data send failures belong to the chat (pill +
            // "Not delivered" bubble), not a second banner here.
            if (chatProvider.error != null &&
                !NetworkPreflightError.matches(chatProvider.error))
              _buildErrorBanner(context, chatProvider),
            if (_personasExpanded) const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _personasExpanded
                  ? _buildPersonasRow(context)
                  : const SizedBox(width: double.infinity),
            ),
            if (_personasExpanded) const SizedBox(height: 22),
            Expanded(child: chatSheet(expandList: true)),
          ],
        );
      },
    );
  }

  Widget _buildErrorBanner(BuildContext context, ChatProvider chatProvider) {
    return CompactErrorBanner(
      error: chatProvider.error!,
      errorDetail: chatProvider.errorDetail,
      onDismiss: () => chatProvider.clearError(),
      onAdjustMaxTokens: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ModelParametersScreen()),
        );
      },
      onOpenImageSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ImageGenerationSettingsScreen(),
          ),
        );
      },
      onCompressAndResend: chatProvider.canCompressAndResendImages
          ? () {
              final settings = context.read<SettingsProvider>();
              chatProvider.compressLastImagesAndResend(
                settings.settings,
                settingsProvider: settings,
                uiContext: context,
              );
            }
          : null,
      largeImageBytes: chatProvider.latestLargeUserImageBytes,
    );
  }

  Widget _buildPersonasRow(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final personas = (settingsProvider.settings.savedSystemPrompts ?? [])
        .where((p) => p.isPersona)
        .toList();
    // Always render the row — even with no personas, the "New" button stays visible.

    // +15% vs previous 30px radius.
    const double avatarRadius = 34.5;
    const double ringPad = 2.0;
    const double innerPad = 1.5;
    const double labelWidth = 78.0;
    const avatarOuter = (avatarRadius + ringPad + innerPad) * 2;
    const double labelGap = 9;
    const double labelFontSize = 13;
    const double labelLineHeight = 1.2;
    const double verticalPadding = 6 + 4; // matches the scroll view padding
    // Size the row from the real label height so large system text can't
    // overflow it; the label itself stops growing past 1.3×.
    final labelScaler =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final labelHeight =
        labelScaler.scale(labelFontSize) * labelLineHeight;
    final rowHeight =
        avatarOuter + labelGap + labelHeight + verticalPadding + 2;

    // Navy top zone → bright labels. Gradient wallpaper → theme-aware.
    final hasGradient = context.hasBackgroundGradient;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = hasGradient
        ? (isDark ? Colors.white : Colors.black.withValues(alpha: 0.88))
        : const Color(0xFFF5F7FA);

    Widget personaColumn({required Widget avatar, required String label}) {
      return SizedBox(
        width: labelWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: labelGap),
            Text(
              label,
              textScaler: labelScaler,
              style: GoogleFonts.poppins(
                color: labelColor,
                height: labelLineHeight,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                shadows: hasGradient
                    ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: rowHeight,
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final persona in personas)
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: GestureDetector(
                    onTap: () => PersonaProfileScreen.open(context, persona),
                    child: personaColumn(
                      label: persona.name,
                      avatar: Builder(
                        builder: (context) {
                          final pColor = persona.color != null
                              ? Color(persona.color!)
                              : Theme.of(context).colorScheme.primary;
                          final resolvedAvatar = persona.avatarPath != null
                              ? ImagePickerHelper.resolveImagePathSync(
                                  persona.avatarPath!)
                              : null;
                          return Container(
                            padding: const EdgeInsets.all(ringPad),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [pColor, pColor.withValues(alpha: 0.4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(innerPad),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: CircleAvatar(
                                radius: avatarRadius - ringPad - innerPad,
                                backgroundColor: pColor.withValues(alpha: 0.18),
                                backgroundImage: resolvedAvatar != null
                                    ? FileImage(File(resolvedAvatar))
                                    : null,
                                child: resolvedAvatar == null
                                    ? Text(
                                        persona.name[0].toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: pColor,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const SystemPromptsScreen(openNewPersona: true)),
                  ),
                  child: personaColumn(
                    label: AppLocalizations.of(context).newPersonaShort,
                    avatar: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.add,
                        size: 28,
                        color: isDark
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startPersonaChat(SystemPrompt persona) async {
    if (_createNewChatInFlight) return;
    _createNewChatInFlight = true;
    try {
      await _startPersonaChatBody(persona);
    } finally {
      _createNewChatInFlight = false;
    }
  }

  Future<void> _startPersonaChatBody(SystemPrompt persona) async {
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.loadSettings();

    if (!mounted) return;

    // Apply persona preferred provider + model before readiness checks.
    await settingsProvider.applyPersonaPreferredSettings(persona);
    if (!mounted) return;

    if (!await _ensureProviderReady(settingsProvider)) return;

    if (!mounted) return;
    if (!await _ensureModelSelected(settingsProvider)) return;

    if (!mounted) return;
    if (_isTwoColumn(context)) {
      await _openNewChatInSplitView();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(folderId: _selectedFolderId),
      ),
    );
  }

  /// The Groups tab: always in the official app; in the public build only
  /// while restored group chats exist (they stay readable there).
  bool _groupsTabVisible(ChatProvider chatProvider) =>
      ProFeatures.included ||
      chatProvider.listedConversations.any((c) => c.isGroupChat);

  /// Conversations visible under the current home filters (tab / folder / search).
  List<ChatConversation> _visibleConversations(ChatProvider chatProvider) {
    var list = chatProvider.listedConversations;
    if (_listTab == HomeListTab.groups) {
      list = list.where((c) => c.isGroupChat).toList();
    } else {
      list = list.where((c) => !c.isGroupChat).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((c) => c.title.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (_selectedFolderId != null) {
      list = list.where((c) => c.folderId == _selectedFolderId).toList();
    }
    return list;
  }

  Widget _buildConversationsList(
    ChatProvider chatProvider, {
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    var filteredConversations = _visibleConversations(chatProvider);

    // Build grouped list: parent conversations + their branches
    // Parent = no parentConversationId. Branch = has parentConversationId.
    final parentConversations = filteredConversations
        .where((c) => c.parentConversationId == null)
        .toList();
    final branchMap = <String, List<ChatConversation>>{};
    for (final c in filteredConversations) {
      if (c.parentConversationId != null) {
        branchMap.putIfAbsent(c.parentConversationId!, () => []).add(c);
      }
    }

    // Also include orphan branches whose parent was deleted or not in filtered set
    final parentIds = parentConversations.map((c) => c.id).toSet();
    final orphanBranches = filteredConversations
        .where((c) =>
            c.parentConversationId != null &&
            !parentIds.contains(c.parentConversationId))
        .toList();

    // Build flat display list with items + indent flags
    final displayItems = <_ConversationDisplayItem>[];
    for (final parent in parentConversations) {
      displayItems
          .add(_ConversationDisplayItem(conversation: parent, isBranch: false));
      final branches = branchMap[parent.id];
      if (branches != null) {
        for (final branch in branches) {
          displayItems.add(
              _ConversationDisplayItem(conversation: branch, isBranch: true));
        }
      }
    }
    // Orphan branches appear at top level with branch indicator
    for (final orphan in orphanBranches) {
      displayItems
          .add(_ConversationDisplayItem(conversation: orphan, isBranch: true));
    }

    final titlesById = {
      for (final conversation in chatProvider.conversations)
        conversation.id: conversation,
    };
    final twoCol = _isTwoColumn(context);
    final bottomPad = twoCol ? 72.0 : 8.0;

    return ListView.builder(
      primary: false,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: EdgeInsets.fromLTRB(14, 0, 8, bottomPad),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final conversation = item.conversation;
        // Multi-select checkboxes vs active chat highlight in split view.
        final isSelected = _selectionMode
            ? _selectedIds.contains(conversation.id)
            : (twoCol && _selectedConversationId == conversation.id);
        final settings = context.watch<SettingsProvider>().settings;

        return ConversationListItem(
          conversation: conversation,
          isBranch: item.isBranch,
          hasUnread: chatProvider.hasUnread(conversation.id),
          isGenerating: chatProvider.backgroundGeneratingConversationId ==
              conversation.id,
          hasActiveCall:
              chatProvider.voiceCallConversationId == conversation.id,
          globalAssistantAvatar: settings.assistantAvatarPath,
          appSettings: settings,
          lastAssistantPreview:
              chatProvider.assistantPreviewFor(conversation.id),
          listTitle: ChatTitle.generatedTitle(conversation, titlesById),
          compact: twoCol,
          selectionMode: _selectionMode,
          isSelected: isSelected,
          isOpening: _openingConversationId == conversation.id,
          onTap: () {
            if (_selectionMode) {
              _toggleSelection(conversation.id);
            } else {
              _openChat(conversation.id);
            }
          },
          onDelete: () => _deleteConversation(conversation.id),
          onRename: (newTitle) =>
              _renameConversation(conversation.id, newTitle),
          onMoveToFolder: () => _showMoveToFolderDialog(conversation.id),
          onLongPress: () {
            setState(() {
              _selectionMode = true;
              _selectedIds.add(conversation.id);
            });
          },
        );
      },
    );
  }

  Future<void> _openNewChatInSplitView({bool launchCamera = false}) async {
    final chatProvider = context.read<ChatProvider>();
    final personaId =
        context.read<SettingsProvider>().settings.selectedSystemPromptId;
    await chatProvider.createNewConversation(
      folderId: _selectedFolderId,
      systemPromptId: personaId,
    );
    if (!mounted) return;
    final id = chatProvider.currentConversation?.id;
    if (id == null) return;
    setState(() {
      _selectedConversationId = id;
      _detailFullScreen = false;
      _detailLaunchCamera = launchCamera;
      _showFolders = false;
      _showGroupSetup = false;
    });
    if (launchCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _detailLaunchCamera = false);
      });
    }
  }

  void _createNewChat() async {
    if (_createNewChatInFlight) return;
    _createNewChatInFlight = true;
    try {
      await _createNewChatBody();
    } finally {
      _createNewChatInFlight = false;
    }
  }

  Future<void> _createNewChatBody() async {
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.loadSettings();

    if (!mounted) return;

    if (!await _ensureProviderReady(settingsProvider)) return;

    if (!mounted) return;

    if (!await _ensureModelSelected(settingsProvider)) return;

    if (!mounted) return;

    if (_isTwoColumn(context)) {
      await _openNewChatInSplitView();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(folderId: _selectedFolderId),
      ),
    );
  }

  void _openArena() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ArenaSetupScreen()),
    );
  }

  void _createNewGroupChat() async {
    if (!ProFeatures.included) {
      await GroupChatProGate.showUpgradeDialog(context);
      return;
    }
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.loadSettings();
    if (!mounted) return;

    if (!await _ensureProviderReady(settingsProvider)) return;

    if (!mounted) return;

    // Desktop shell / split view: open setup in column 3.
    if (_isTwoColumn(context)) {
      setState(() {
        _showGroupSetup = true;
        _listTab = HomeListTab.groups;
        _showFolders = false;
        _detailFullScreen = false;
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatSetupScreen(
          folderId: _selectedFolderId,
        ),
      ),
    );
  }

  bool _isOnDeviceSelected() {
    final kind = context.read<SettingsProvider>().settings.activeProviderKind;
    return kind == 'onDeviceGguf' || kind == 'onDeviceMlx';
  }

  bool _hasReadyOnDeviceModel() =>
      LocalModelDownloadService.instance.readyEntries.isNotEmpty;

  bool _onDeviceDownloadInFlight() {
    return LocalModelDownloadService.instance.entries.any((e) =>
        e.status == LocalModelStatus.downloading ||
        e.status == LocalModelStatus.failed);
  }

  /// On-device is selected and nothing is ready to chat with yet.
  bool _onDeviceNeedsModel() =>
      _isOnDeviceSelected() && !_hasReadyOnDeviceModel();

  /// Show the in-progress / failed download card on home.
  bool _showOnDeviceDownloadProgress() =>
      _onDeviceNeedsModel() && _onDeviceDownloadInFlight();

  /// On-device selected, no model, download not running — prompt to download.
  bool _showOnDeviceDownloadPrompt() =>
      _onDeviceNeedsModel() && !_onDeviceDownloadInFlight();

  LocalModelEntry? _firstOnDeviceWaitEntry() {
    final svc = LocalModelDownloadService.instance;
    for (final e in svc.entries) {
      if (e.status == LocalModelStatus.downloading) return e;
    }
    for (final e in svc.entries) {
      if (e.status == LocalModelStatus.failed) return e;
    }
    return null;
  }

  void _openOnDeviceModels() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocalModelsScreen()),
    );
  }

  void _retryFirstOnDeviceDownload() {
    final entry = _firstOnDeviceWaitEntry();
    if (entry == null) return;
    unawaited(LocalModelDownloadService.instance.download(entry.spec));
  }

  Future<bool> _ensureModelSelected(SettingsProvider sp) async {
    final s = sp.settings;
    final kind = s.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return true;
    }
    if (s.selectedModel != null && s.selectedModel!.isNotEmpty) return true;
    return showSelectModelSheet(context);
  }

  /// Returns true when the user can proceed to a chat screen. When the user
  /// has not configured any provider, shows the generic provider popup. When
  /// on-device is the active provider but no model has been downloaded yet,
  /// shows a download-prompt dialog instead.
  Future<bool> _ensureProviderReady(SettingsProvider sp) async {
    final s = sp.settings;
    final kind = s.activeProviderKind;
    final isOnDevice = kind == 'onDeviceGguf' || kind == 'onDeviceMlx';

    if (isOnDevice) {
      await LocalModelDownloadService.instance.init();
      final hasReady =
          LocalModelDownloadService.instance.readyEntries.isNotEmpty;
      if (!hasReady) {
        if (!_onDeviceDownloadInFlight()) {
          _showOnDeviceDownloadDialog();
        }
        return false;
      }
      final reconciled = await sp.reconcileOnDeviceSelection(s);
      if (reconciled != s) {
        await sp.updateSettings(reconciled);
      }
      return true;
    }

    if (kind == 'appleIntelligence') {
      return true;
    }

    if (SettingsProvider.isCloudProviderKind(kind)) {
      if (sp.isCloudProviderReady()) return true;
      _showProviderNotReadyDialog(sp);
      return false;
    }

    // LM Studio path: server URL saved. If models aren't cached yet (or the
    // last fetch failed), do a quick reconnect before nagging about settings.
    if (sp.isProviderConfigured()) {
      if (sp.availableModels.isNotEmpty) return true;
      final reconnected = await _quickCheckLmStudioConnection(sp);
      if (reconnected) return true;
    }
    _showProviderNotReadyDialog(sp);
    return false;
  }

  /// Brief model fetch / connection probe so a flaky first load doesn't
  /// immediately push users to Settings.
  Future<bool> _quickCheckLmStudioConnection(SettingsProvider sp) async {
    if (!mounted) return false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(AppLocalizations.of(context).connecting),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await sp.loadAvailableModels().timeout(const Duration(seconds: 6));
      return sp.availableModels.isNotEmpty && sp.connectionError == null;
    } catch (_) {
      // Fall through — caller shows the settings popup.
      return false;
    } finally {
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
    }
  }

  void _showOnDeviceDownloadDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.smartphone, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.downloadOnDeviceModelTitle)),
          ],
        ),
        content: Text(l10n.downloadOnDeviceModelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocalModelsScreen()),
              );
            },
            icon: const Icon(Icons.download),
            label: Text(l10n.browseModels),
          ),
        ],
      ),
    );
  }

  void _showProviderNotReadyDialog(SettingsProvider sp) {
    if (sp.needsGetStartedGuidance) {
      showGetStartedSetupDialog(context);
    } else if (sp.needsSetup) {
      _showConnectionPopup();
    } else {
      _showConnectionErrorPopup(sp);
    }
  }

  void _showConnectionErrorPopup(SettingsProvider sp) {
    final l10n = AppLocalizations.of(context);
    final error = sp.connectionError ?? l10n.connectionFailedMessage;
    if (sp.settings.usbModeEnabled) {
      _showUsbWaitingDialog();
      return;
    }
    if (showConnectHostHelpIfNeeded(
      context,
      error: error,
      serverUrl: sp.settings.serverUrl,
      isRemoteActive: sp.settings.isRemoteActive,
      usbModeEnabled: sp.settings.usbModeEnabled,
      providerKind: sp.settings.activeProviderKind,
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
      serverUrl: sp.settings.serverUrl,
      providerKind: sp.settings.activeProviderKind,
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
      serverUrl: sp.settings.serverUrl,
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

  void _showConnectionPopup() {
    // When USB Mode is on but the Mac peer isn't connected yet, the popup is
    // misleading ("go to server settings") because the user already configured
    // it via USB. Show a USB-specific message instead.
    final settings = context.read<SettingsProvider>().settings;
    if (settings.usbModeEnabled) {
      _showUsbWaitingDialog();
      return;
    }
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

  void _showUsbWaitingDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.usb, color: Colors.green),
            const SizedBox(width: 8),
            Text(l10n.waitingForMac),
          ],
        ),
        content: Text(l10n.waitingForMacBody),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Text(l10n.settingsTitle),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _createNewChatWithCamera() async {
    if (_createNewChatInFlight) return;
    _createNewChatInFlight = true;
    try {
      await _createNewChatWithCameraBody();
    } finally {
      _createNewChatInFlight = false;
    }
  }

  Future<void> _createNewChatWithCameraBody() async {
    final l10n = AppLocalizations.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.loadSettings();

    if (!mounted) return;

    if (!await _ensureProviderReady(settingsProvider)) return;
    if (!mounted) return;
    if (!await _ensureModelSelected(settingsProvider)) return;
    if (!mounted) return;

    // Vision check only applies to LM Studio/cloud paths that publish models.
    final kind = settingsProvider.settings.activeProviderKind;
    final isOnDevice = kind == 'onDeviceGguf' || kind == 'onDeviceMlx';
    if (!isOnDevice) {
      final hasVisionModel =
          settingsProvider.availableModels.any((m) => m.isVLM);
      if (!hasVisionModel) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noVisionModelAvailable),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    if (_isTwoColumn(context)) {
      await _openNewChatInSplitView(launchCamera: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(launchCamera: true, folderId: _selectedFolderId),
      ),
    );
  }

  void _openChat(String conversationId) {
    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.conversationById(conversationId) == null) return;

    setState(() => _openingConversationId = conversationId);

    // Kick off DB load immediately so the chat screen can show progress
    // without waiting for the first frame / route animation.
    final loadFuture = chatProvider.currentConversation?.id == conversationId
        ? Future<void>.value()
        : chatProvider.selectConversation(conversationId);

    void clearOpening() {
      if (!mounted) return;
      if (_openingConversationId == conversationId) {
        setState(() => _openingConversationId = null);
      }
    }

    // In the iPad master/detail layout we just swap the right pane instead
    // of pushing onto the navigator. This keeps the conversation list
    // visible (matching Mail / Messages on iPadOS).
    if (_isTwoColumn(context)) {
      setState(() {
        _selectedConversationId = conversationId;
        _detailFullScreen = false;
        _showGroupSetup = false;
      });
      loadFuture.whenComplete(clearOpening);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    ).whenComplete(clearOpening);
  }

  void _deleteConversation(String conversationId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConversationTitle),
        content: Text(l10n.deleteConversationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<ChatProvider>().deleteConversation(conversationId);
      // Clear the detail pane if it was showing the just-deleted chat.
      if (_selectedConversationId == conversationId) {
        setState(() => _selectedConversationId = null);
      }
    }
  }

  void _renameConversation(String conversationId, String currentTitle) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentTitle);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameConversationTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.conversationTitleLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != currentTitle &&
        mounted) {
      context
          .read<ChatProvider>()
          .updateConversationTitle(conversationId, newTitle);
    }
  }

  Widget _folderLeading(BuildContext context, ChatFolder folder,
      {double size = 32}) {
    final color =
        folder.parsedColor ?? Theme.of(context).colorScheme.primaryContainer;
    final imagePath = folder.imagePath != null
        ? ImagePickerHelper.resolveImagePathSync(folder.imagePath!)
        : null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imagePath == null ? color : null,
        borderRadius: BorderRadius.circular(size * 0.2),
        image: imagePath != null
            ? DecorationImage(
                image: FileImage(File(imagePath)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imagePath == null
          ? Icon(
              Icons.folder_rounded,
              color: color.computeLuminance() > 0.55
                  ? Colors.black87
                  : Colors.white,
              size: size * 0.56,
            )
          : null,
    );
  }

  void _createFolder() {
    showDialog(
      context: context,
      builder: (context) => FolderDialog(
        onSave: (name, color) async {
          await context.read<FolderProvider>().createFolder(name, color: color);
        },
      ),
    );
  }

  void _editFolder(folder) {
    showDialog(
      context: context,
      builder: (context) => FolderDialog(
        folder: folder,
        onSave: (name, color) async {
          await context.read<FolderProvider>().updateFolder(
                folder.copyWith(name: name, color: color),
              );
        },
      ),
    );
  }

  void _deleteFolder(String folderId) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFolderTitle),
        content: Text(l10n.deleteFolderMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<FolderProvider>().deleteFolder(folderId);
              Navigator.pop(context);
              setState(() {
                _selectedFolderId = null;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(String conversationId) {
    final l10n = AppLocalizations.of(context);
    final folderProvider = context.read<FolderProvider>();
    final chatProvider = context.read<ChatProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.moveToFolderTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_off),
                title: Text(l10n.noFolder),
                onTap: () async {
                  final conversation =
                      chatProvider.conversationById(conversationId);
                  if (conversation == null) {
                    Navigator.pop(dialogContext);
                    return;
                  }
                  await chatProvider.updateConversation(
                    conversation.copyWith(folderId: null),
                  );
                  Navigator.pop(dialogContext);
                },
              ),
              const Divider(),
              ...folderProvider.folders.map((folder) {
                return ListTile(
                  leading: _folderLeading(context, folder, size: 32),
                  title: Text(folder.name),
                  onTap: () async {
                    final conversation =
                        chatProvider.conversationById(conversationId);
                    if (conversation == null) {
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      return;
                    }
                    await chatProvider.updateConversation(
                      conversation.copyWith(folderId: folder.id),
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: Icon(Icons.create_new_folder,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(l10n.createNewFolder,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _createFolderThenMove(conversationIds: [conversationId]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Bulk selection helpers ----------

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _bulkDelete() async {
    final l10n = AppLocalizations.of(context);
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConversationTitle),
        content: Text(l10n.deleteConversations(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final chatProvider = context.read<ChatProvider>();
      for (final id in _selectedIds.toList()) {
        await chatProvider.deleteConversation(id);
      }
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    }
  }

  void _bulkMoveToFolder() {
    final l10n = AppLocalizations.of(context);
    final folderProvider = context.read<FolderProvider>();
    final chatProvider = context.read<ChatProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.moveToFolderTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_off),
                title: Text(l10n.noFolder),
                onTap: () async {
                  await _moveManyToFolder(chatProvider, null);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
              ),
              const Divider(),
              ...folderProvider.folders.map((folder) {
                return ListTile(
                  leading: _folderLeading(context, folder, size: 32),
                  title: Text(folder.name),
                  onTap: () async {
                    await _moveManyToFolder(chatProvider, folder.id);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: Icon(Icons.create_new_folder,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(l10n.createNewFolder,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _createFolderThenMove(conversationIds: _selectedIds.toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveManyToFolder(
      ChatProvider chatProvider, String? folderId) async {
    for (final id in _selectedIds.toList()) {
      final conversation = chatProvider.conversationById(id);
      if (conversation == null) continue;
      await chatProvider.updateConversation(
        conversation.copyWith(folderId: folderId),
      );
    }
    if (mounted) {
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    }
  }

  void _createFolderThenMove({required List<String> conversationIds}) {
    showDialog(
      context: context,
      builder: (context) => FolderDialog(
        onSave: (name, color) async {
          final folderProvider = this.context.read<FolderProvider>();
          final chatProvider = this.context.read<ChatProvider>();
          final newFolder =
              await folderProvider.createFolder(name, color: color);
          if (newFolder != null) {
            for (final id in conversationIds) {
              final conversation = chatProvider.conversationById(id);
              if (conversation == null) continue;
              await chatProvider.updateConversation(
                conversation.copyWith(folderId: newFolder.id),
              );
            }
          }
          if (mounted) {
            setState(() {
              _selectedIds.clear();
              _selectionMode = false;
            });
          }
        },
      ),
    );
  }
}

/// Helper class for grouped conversation list display.
class _ConversationDisplayItem {
  final ChatConversation conversation;
  final bool isBranch;
  const _ConversationDisplayItem(
      {required this.conversation, required this.isBranch});
}

/// Shallow chevron with the same visual weight as the old 36×4 grabber bar.
/// Points down when personas are hidden (open) and up when they are shown.
class _PersonaSheetHandle extends StatelessWidget {
  final bool expanded;
  final Color color;

  const _PersonaSheetHandle({
    required this.expanded,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      child: CustomPaint(
        size: const Size(36, 8),
        painter: _DownArrowBarPainter(color: color),
      ),
    );
  }
}

class _DownArrowBarPainter extends CustomPainter {
  final Color color;

  const _DownArrowBarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(1.75, 2.2)
      ..lineTo(size.width / 2, size.height - 1.75)
      ..lineTo(size.width - 1.75, 2.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DownArrowBarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HomeWaitingForAi extends StatefulWidget {
  final bool compact;
  final LocalModelEntry? entry;
  final VoidCallback onRetry;

  const _HomeWaitingForAi({
    required this.compact,
    required this.entry,
    required this.onRetry,
  });

  @override
  State<_HomeWaitingForAi> createState() => _HomeWaitingForAiState();
}

class _HomeWaitingForAiState extends State<_HomeWaitingForAi> {
  int? _heldSpeed;
  DateTime _heldAt = DateTime.fromMillisecondsSinceEpoch(0);

  String? _speedLabel(int bytesPerSecond) {
    final now = DateTime.now();
    var speed = bytesPerSecond;
    if (speed > 0) {
      _heldSpeed = speed;
      _heldAt = now;
    } else if (_heldSpeed != null &&
        now.difference(_heldAt) < const Duration(seconds: 2)) {
      speed = _heldSpeed!;
    } else {
      _heldSpeed = null;
      return null;
    }
    if (speed < 1024) return '$speed B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).round()} KB/s';
    final mb = (speed / (1024 * 1024) * 10).round() / 10;
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final failed = entry?.status == LocalModelStatus.failed;
    final progress = entry?.progress ?? 0.0;
    final pct = '${(progress * 100).clamp(0, 100).round()}%';
    final speed = _speedLabel(entry?.bytesPerSecond ?? 0);
    final status = failed
        ? l10n.welcomeWizardDownloadFailed
        : (speed != null ? '$pct · $speed' : pct);
    final name = (entry?.spec.displayName ?? '')
        .replaceAll(' (MLX)', '')
        .replaceAll(' Instruct', '');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: widget.compact ? 32 : 48,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            failed ? Icons.error_outline_rounded : Icons.downloading_rounded,
            size: widget.compact ? 48 : 64,
            color: failed ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.welcomeWizardAiDownloadingTitle,
            style: widget.compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.welcomeWizardAiDownloadingBody,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (entry != null) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: failed
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: failed || progress <= 0 ? null : progress,
                minHeight: 4,
              ),
            ),
          ],
          if (failed) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: widget.onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeDownloadOnDevicePrompt extends StatelessWidget {
  final bool compact;
  final VoidCallback onDownload;

  const _HomeDownloadOnDevicePrompt({
    required this.compact,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: compact ? 32 : 48,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_rounded,
            size: compact ? 48 : 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.downloadOnDeviceModelTitle,
            style: compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.downloadOnDeviceModelBody,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded),
            label: Text(l10n.homeDownloadModel),
          ),
        ],
      ),
    );
  }
}
