import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show firebaseInitialized;
import '../utils/firebase_auth_session.dart';
import '../models/feature_request.dart';
import '../services/feature_request_notification_service.dart';
import '../services/feature_request_service.dart';
import '../widgets/feature_request_unread_listener.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/platform_badge.dart';
import '../widgets/support_ticket_dialog.dart';
import '../widgets/unread_dot.dart';
import 'feature_request_detail_screen.dart';

class FeatureRequestsScreen extends StatefulWidget {
  final bool embedded;

  const FeatureRequestsScreen({super.key, this.embedded = false});

  @override
  State<FeatureRequestsScreen> createState() => _FeatureRequestsScreenState();
}

class _FeatureRequestsScreenState extends State<FeatureRequestsScreen>
    with SingleTickerProviderStateMixin {
  FeatureRequestService? _service;
  final _notificationService = FeatureRequestNotificationService();
  late TabController _tabController;
  String? _currentUserId;
  bool _isAdmin = false;
  bool _initError = false;

  // Cache streams to prevent recreation on tab switch
  Stream<List<FeatureRequest>>? _popularStream;
  Stream<List<FeatureRequest>>? _myRequestsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (firebaseInitialized) {
      _service = FeatureRequestService();
      _notificationService.init();
      _initUser();
    } else {
      _initError = true;
    }
  }

  Future<void> _initUser() async {
    try {
      final user = await FirebaseAuthSession.ensureUser();
      if (user == null) {
        if (mounted) setState(() => _initError = true);
        return;
      }
      final isAdmin = await _service!.isAdmin;
      if (mounted) {
        setState(() {
          _currentUserId = user.uid;
          _isAdmin = isAdmin;
          _popularStream = _service!.getPopularRequests();
          _myRequestsStream = _service!.getMyRequests(user.uid);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_initError || !firebaseInitialized) {
      return GlassSettingsScaffold(
        embedded: widget.embedded,
        title: l10n.featureRequestsTitle,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.featureRequestsUnavailable,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.featureRequestsUnavailableDetail,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _initError = false;
                    });
                    if (firebaseInitialized) {
                      _service ??= FeatureRequestService();
                      _initUser();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return GlassSettingsScaffold(
      embedded: widget.embedded,
      title: l10n.featureRequestsTitle,
      titleTrailing: (_currentUserId != null && _service != null)
          ? FeatureRequestUnreadListener(
              service: _service!,
              userId: _currentUserId,
              isAdmin: _isAdmin,
              builder: (context, hasUnread) {
                if (!hasUnread) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: UnreadDot(size: 9),
                );
              },
            )
          : null,
      actions: [
        if (_currentUserId != null && _service != null)
          StreamBuilder<int>(
            stream: _service!.getRemainingVotesStream(_currentUserId!),
            builder: (context, snapshot) {
              final remaining =
                  snapshot.data ?? FeatureRequestService.maxVotesPerUser;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.how_to_vote_rounded,
                      size: 16,
                      color: remaining > 0 ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$remaining ${l10n.votesLeft}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: remaining > 0 ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.submitIdea),
      ),
      body: Column(
        children: [
          Material(
            color: cs.surface,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.popular, icon: const Icon(Icons.trending_up)),
                Tab(text: l10n.myRequests, icon: const Icon(Icons.person)),
                Tab(text: l10n.completed, icon: const Icon(Icons.check_circle)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _KeepAliveTab(child: _buildPopularTab()),
                _KeepAliveTab(child: _buildMyRequestsTab()),
                _KeepAliveTab(
                  child: _service == null
                      ? const Center(child: CircularProgressIndicator())
                      : _CompletedRequestsTab(
                          service: _service!,
                          buildCard: _buildRequestCard,
                          emptyBuilder: () => _buildEmptyState(
                            icon: Icons.task_alt,
                            title: l10n.noCompletedRequests,
                            subtitle: l10n.completedRequestsAppear,
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

  Widget _buildPopularTab() {
    final l10n = AppLocalizations.of(context);
    if (_popularStream == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<List<FeatureRequest>>(
      stream: _popularStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // if debugging, print the error
          debugPrint('Error in popular requests stream: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.lightbulb_outline,
            title: l10n.noFeatureRequests,
            subtitle: l10n.beFirstToSubmit,
          );
        }
        return _buildRequestList(requests);
      },
    );
  }

  Widget _buildMyRequestsTab() {
    final l10n = AppLocalizations.of(context);
    if (_currentUserId == null || _myRequestsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<List<FeatureRequest>>(
      stream: _myRequestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Error in my requests stream: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: l10n.noRequestsSubmitted,
            subtitle: l10n.tapToSubmitFirst,
          );
        }
        return _buildRequestList(requests);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<FeatureRequest> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(FeatureRequest request) {
    final l10n = AppLocalizations.of(context);
    final hasVoted =
        _currentUserId != null && request.hasVoted(_currentUserId!);
    final isOwnRequest = _currentUserId == request.userId;
    final statusColor = Color(request.status.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSettingsCard(
        child: InkWell(
          onTap: () => _showRequestDetail(context, request),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Vote button
                    Column(
                      children: [
                        IconButton(
                          onPressed: isOwnRequest && hasVoted
                              ? null
                              : () => _toggleVote(request),
                          tooltip:
                              hasVoted ? l10n.votedTooltip : l10n.voteForThis,
                          icon: Icon(
                            hasVoted
                                ? Icons.arrow_upward
                                : Icons.arrow_upward_outlined,
                            color: hasVoted
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Text(
                          '${request.voteCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasVoted
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  request.status.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  request.category.displayName,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              if (isOwnRequest) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                              if (_isAdmin) ...[
                                const SizedBox(width: 6),
                                PlatformBadge(
                                  platform: request.platform,
                                  compact: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              FeatureRequestCardUnreadDot(
                                request: request,
                                currentUserId: _currentUserId,
                                isAdmin: _isAdmin,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.description,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (request.adminReply != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.adminReplied,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (request.commentCount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.commentsCount(request.commentCount),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleVote(FeatureRequest request) async {
    if (_currentUserId == null || _service == null) return;
    try {
      await _service!.toggleVote(request.id, _currentUserId!, request);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSubmitDialog(BuildContext context) {
    SupportTicketFlow.open(
      context,
      service: _service,
      onSubmitted: () {
        if (mounted) _tabController.animateTo(1);
      },
    );
  }

  void _showRequestDetail(BuildContext context, FeatureRequest request) {
    final isOwnRequest = _currentUserId == request.userId;
    if (isOwnRequest) {
      _notificationService.markAsSeen(request: request).then((_) {
        if (mounted) setState(() {});
      });
    }
    if (_isAdmin) {
      _notificationService.markAsSeenByAdmin(request: request).then((_) {
        if (mounted) setState(() {});
      });
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeatureRequestDetailScreen(
          request: request,
          currentUserId: _currentUserId,
          isAdmin: _isAdmin,
          service: _service!,
        ),
      ),
    );
  }
}

/// Helper widget to keep tab content alive when switching tabs
class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Completed/declined requests with cursor pagination.
class _CompletedRequestsTab extends StatefulWidget {
  final FeatureRequestService service;
  final Widget Function(FeatureRequest request) buildCard;
  final Widget Function() emptyBuilder;

  const _CompletedRequestsTab({
    required this.service,
    required this.buildCard,
    required this.emptyBuilder,
  });

  @override
  State<_CompletedRequestsTab> createState() => _CompletedRequestsTabState();
}

class _CompletedRequestsTabState extends State<_CompletedRequestsTab> {
  final _scrollController = ScrollController();
  final List<FeatureRequest> _items = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    try {
      final page = await widget.service.fetchCompletedPage();
      if (!mounted) return;
      setState(() {
        _items.addAll(page.requests);
        _lastDoc = page.lastDocument;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.service.fetchCompletedPage(
        startAfter: _lastDoc,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.requests);
        _lastDoc = page.lastDocument;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadInitial,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return widget.emptyBuilder();
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : TextButton(
                        onPressed: _loadMore,
                        child: const Text('Load more'),
                      ),
              ),
            );
          }
          return widget.buildCard(_items[index]);
        },
      ),
    );
  }
}
