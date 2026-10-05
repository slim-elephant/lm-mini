import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/feature_request.dart';
import '../services/feature_attachment_service.dart';
import '../services/feature_request_notification_service.dart';
import '../services/feature_request_service.dart';
import '../services/community_admin_service.dart';
import '../widgets/attachment_display.dart';
import '../widgets/attachment_picker.dart';
import '../pro/admin/admin_user_manage_sheet.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/home_glass_header.dart';
import '../widgets/platform_badge.dart';

class FeatureRequestDetailScreen extends StatefulWidget {
  final FeatureRequest request;
  final String? currentUserId;
  final bool isAdmin;
  final FeatureRequestService service;

  const FeatureRequestDetailScreen({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.isAdmin,
    required this.service,
  });

  @override
  State<FeatureRequestDetailScreen> createState() =>
      _FeatureRequestDetailScreenState();
}

class _FeatureRequestDetailScreenState
    extends State<FeatureRequestDetailScreen> {
  final _commentController = TextEditingController();
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  final _replyController = TextEditingController();

  bool _isSending = false;
  List<File> _pendingAttachments = <File>[];
  final Set<String> _loadedProfileIds = {};

  static const _namePrefsKey = 'feature_request_user_name';

  @override
  void initState() {
    super.initState();
    _replyController.text = widget.request.adminReply ?? '';
    _loadSavedName();
    _markSeen();
    _preloadRequestAuthorProfile();
  }

  Future<void> _preloadRequestAuthorProfile() async {
    final profile =
        await CommunityAdminService.instance.getProfile(widget.request.userId);
    if (profile != null) {
      FeatureRequestService.cacheCommunityProfile(profile);
    }
  }

  Future<void> _preloadCommentProfiles(List<FeatureComment> comments) async {
    final ids = comments.map((c) => c.userId).toSet()
      ..add(widget.request.userId);
    final missing = ids.where((id) => !_loadedProfileIds.contains(id)).toList();
    if (missing.isEmpty) return;

    var changed = false;
    for (final id in missing) {
      _loadedProfileIds.add(id);
      final profile = await CommunityAdminService.instance.getProfile(id);
      if (profile != null) {
        FeatureRequestService.cacheCommunityProfile(profile);
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  Future<void> _markSeen() async {
    final notifications = FeatureRequestNotificationService();
    await notifications.init();
    final isOwnRequest = widget.currentUserId == widget.request.userId;
    if (isOwnRequest) {
      await notifications.markAsSeen(request: widget.request);
    }
    if (widget.isAdmin) {
      await notifications.markAsSeenByAdmin(request: widget.request);
    }
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_namePrefsKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _nameController.text = saved);
    }
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_namePrefsKey, name);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(widget.request.status.colorValue);
    final isOwnRequest = widget.currentUserId == widget.request.userId;
    final hasVoted = widget.currentUserId != null &&
        widget.request.hasVoted(widget.currentUserId!);
    final l10n = AppLocalizations.of(context);

    return GlassSettingsScaffold(
      title: l10n.featureRequest,
      actions: [
        if (widget.currentUserId != null)
          GlassCircleIconButton(
            tooltip: hasVoted ? l10n.votedTooltip : l10n.voteForThis,
            onTap: isOwnRequest && hasVoted ? null : _toggleVote,
            child: Icon(
              hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: hasVoted ? Colors.lightGreenAccent : Colors.white,
            ),
          ),
        if (widget.isAdmin)
          PopupMenuButton<String>(
            tooltip: l10n.adminControls,
            onSelected: (value) {
              switch (value) {
                case 'status':
                  _showStatusDialog();
                  break;
                case 'reply':
                  _showAdminReplyDialog();
                  break;
                case 'manage_submitter':
                  AdminUserManageSheet.show(
                    context,
                    userId: widget.request.userId,
                    displayName: widget.request.submitterName,
                  );
                  break;
                case 'delete':
                  _deleteRequest();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'status',
                child: ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(l10n.changeStatus),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'reply',
                child: ListTile(
                  leading: const Icon(Icons.reply),
                  title: Text(l10n.officialReply),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'manage_submitter',
                child: ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: Text(l10n.adminManageSubmitter),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(l10n.deleteRequest,
                      style: const TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.admin_panel_settings_rounded,
                  size: 20, color: Colors.white),
            ),
          ),
        if (isOwnRequest && !widget.isAdmin)
          GlassCircleIconButton(
            tooltip: l10n.deleteRequest,
            onTap: _deleteRequest,
            child: const Icon(Icons.delete_outline,
                size: 18, color: Colors.redAccent),
          ),
      ],
      body: Column(
        children: [
          // Scrollable content: header + official reply + comments
          Expanded(
            child: StreamBuilder<List<FeatureComment>>(
              stream: widget.service.getComments(widget.request.id),
              builder: (context, snapshot) {
                // Handle errors gracefully
                if (snapshot.hasError) {
                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      _buildRequestHeader(statusColor, hasVoted, isOwnRequest),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Unable to load comments',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  );
                }

                final comments = snapshot.data ?? [];
                _preloadCommentProfiles(comments);

                // Scroll to bottom when new comments arrive
                if (snapshot.hasData && comments.isNotEmpty) {
                  _scrollToBottom();
                }

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    // Request details header
                    _buildRequestHeader(statusColor, hasVoted, isOwnRequest),

                    const Divider(height: 1),

                    // Comments section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.commentsCount(comments.length),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Comments list
                    if (comments.isEmpty)
                      _buildEmptyComments()
                    else
                      ...comments.map((comment) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildCommentBubble(comment),
                          )),
                  ],
                );
              },
            ),
          ),

          // Comment input (fixed at bottom)
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildRequestHeader(
      Color statusColor, bool hasVoted, bool isOwnRequest) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and category badges
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.request.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.request.category.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (widget.request.isPremium && widget.isAdmin) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
              const Spacer(),
              // Vote count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasVoted
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: 14,
                      color: hasVoted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.request.voteCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasVoted
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title with delete button for own requests
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.request.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (isOwnRequest && !widget.isAdmin)
                IconButton(
                  onPressed: _deleteRequest,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: l10n.deleteYourRequest,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            widget.request.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (FeatureAttachment.visibleForViewer(
            widget.request.attachments,
            isAdmin: widget.isAdmin,
          ).isNotEmpty) ...[
            const SizedBox(height: 12),
            AttachmentDisplay(
              attachments: widget.request.attachments,
              showLogs: widget.isAdmin,
            ),
          ],
          const SizedBox(height: 12),
          // Submitter info
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                widget.request.submitterName ?? l10n.anonymous,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              PlatformBadge(platform: widget.request.platform),
              if (widget.isAdmin && widget.request.appVersion != null) ...[
                const SizedBox(width: 8),
                AppVersionLabel(appVersion: widget.request.appVersion),
              ],
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(widget.request.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          // Admin reply (if exists)
          if (widget.request.adminReply != null &&
              widget.request.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.officialResponse,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.request.adminReply!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noCommentsYet,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to share your thoughts!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBubble(FeatureComment comment) {
    final l10n = AppLocalizations.of(context);
    final isOwnComment = widget.currentUserId == comment.userId;
    final isOp = comment.userId == widget.request.userId;
    final canDelete = isOwnComment || widget.isAdmin;

    final bool commentIsAdmin = comment.isAdmin ||
        FeatureRequestService.isUserAdminSync(comment.userId);
    final bool commentIsModerator = comment.isModerator ||
        FeatureRequestService.isUserModeratorSync(comment.userId);
    final bool commentIsExperienced =
        FeatureRequestService.isUserExperiencedSync(comment.userId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: commentIsAdmin
                ? Theme.of(context).colorScheme.primary
                : (commentIsModerator
                    ? Colors.green
                    : Theme.of(context).colorScheme.surfaceContainerHighest),
            child: Icon(
              commentIsAdmin
                  ? Icons.admin_panel_settings
                  : (commentIsModerator ? Icons.shield : Icons.person),
              size: 18,
              color: commentIsAdmin
                  ? Theme.of(context).colorScheme.onPrimary
                  : (commentIsModerator
                      ? Colors.white
                      : Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 8),
          // Message bubble
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and badge
                Row(
                  children: [
                    Text(
                      comment.authorName ?? l10n.anonymous,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: commentIsAdmin
                            ? Theme.of(context).colorScheme.primary
                            : (commentIsModerator ? Colors.green : null),
                      ),
                    ),
                    if (commentIsAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.adminBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ] else if (commentIsModerator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.moderatorBadge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (commentIsExperienced && !commentIsAdmin) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: l10n.adminExperiencedUserRole,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.experiencedUserBadge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (comment.isPremium && widget.isAdmin) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                    ],
                    if (isOwnComment &&
                        !commentIsAdmin &&
                        !commentIsModerator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.youBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                    if (isOp && !commentIsAdmin && !commentIsModerator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 6),
                      PlatformBadge(platform: comment.platform, compact: true),
                      if (comment.appVersion != null) ...[
                        const SizedBox(width: 4),
                        AppVersionLabel(appVersion: comment.appVersion),
                      ],
                    ],
                    const Spacer(),
                    if (widget.isAdmin && !commentIsAdmin) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        tooltip: l10n.adminManageUserTitle,
                        icon: const Icon(Icons.manage_accounts, size: 18),
                        onPressed: () => AdminUserManageSheet.show(
                          context,
                          userId: comment.userId,
                          displayName: comment.authorName,
                        ),
                      ),
                    ],
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Message content with delete button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: commentIsAdmin
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.5)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _ExpandableSupportText(
                          text: comment.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        onPressed: () => _deleteComment(comment),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.7),
                        ),
                        tooltip: l10n.deleteComment,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (FeatureAttachment.visibleForViewer(
                  comment.attachments,
                  isAdmin: widget.isAdmin,
                ).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  AttachmentDisplay(
                    attachments: comment.attachments,
                    size: 72,
                    showLogs: widget.isAdmin,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spam warning
            FutureBuilder<bool>(
              future: widget.currentUserId != null
                  ? widget.service
                      .canUserComment(widget.request.id, widget.currentUserId!)
                  : Future.value(true),
              builder: (context, snapshot) {
                final canComment = snapshot.data ?? true;

                if (!canComment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.maxCommentsReached(
                                FeatureRequestService.maxConsecutiveComments),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Name field (non-admin only, always visible)
            if (!widget.isAdmin) ...[
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: l10n.yourNameOptional,
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
            // Comment input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: widget.isAdmin
                          ? 'Reply as Admin...'
                          : 'Write a comment...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                IconButton.filled(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
            // Attachment picker
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AttachmentPicker(
                files: _pendingAttachments,
                onChanged: (next) => setState(() => _pendingAttachments = next),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) _saveName(name);

      List<FeatureAttachment> uploaded = const [];
      if (_pendingAttachments.isNotEmpty) {
        uploaded = await FeatureAttachmentService.instance.upload(
          files: _pendingAttachments,
          folder:
              'comment_${widget.request.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      await widget.service.addComment(
        requestId: widget.request.id,
        content: text,
        authorName: name.isEmpty ? null : name,
        attachments: uploaded,
      );
      final notifications = FeatureRequestNotificationService();
      final updated = widget.request.copyWith(
        commentCount: widget.request.commentCount + 1,
      );
      if (widget.isAdmin) {
        await notifications.markAsSeenByAdmin(request: updated);
      } else if (widget.currentUserId == widget.request.userId) {
        await notifications.markAsSeen(request: updated);
      }
      _commentController.clear();
      setState(() {
        _pendingAttachments = <File>[];
      });
    } catch (e, st) {
      debugPrint('❌ Feature comment send failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not post comment: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _toggleVote() async {
    try {
      await widget.service.toggleVote(
        widget.request.id,
        widget.currentUserId!,
        widget.request,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showStatusDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FeatureStatus.values.map((status) {
            final isSelected = widget.request.status == status;
            final statusColor = Color(status.colorValue);
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(status.displayName),
              trailing: isSelected ? const Icon(Icons.check) : null,
              selected: isSelected,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await widget.service
                      .updateRequestStatus(widget.request.id, status);
                  await FeatureRequestNotificationService().markAsSeenByAdmin(
                    request: widget.request.copyWith(status: status),
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                          content:
                              Text(l10n.statusUpdated(status.displayName))),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAdminReplyDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.officialReply),
        content: TextField(
          controller: _replyController,
          decoration: InputDecoration(
            hintText: l10n.addOfficialResponse,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await widget.service.addAdminReply(
                  widget.request.id,
                  _replyController.text,
                );
                await FeatureRequestNotificationService().markAsSeenByAdmin(
                  request: widget.request.copyWith(
                    adminReply: _replyController.text,
                  ),
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.replySaved)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRequest() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRequest),
        content: Text(l10n.deleteRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.service.deleteRequest(widget.request.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.requestDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteComment(FeatureComment comment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCommentTitle),
        content: Text(l10n.deleteComment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.service.deleteComment(comment.id, widget.request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.commentDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Truncates long support-thread text with a tappable Read more / Show less.
class _ExpandableSupportText extends StatefulWidget {
  static const maxCollapsedLength = 200;

  final String text;
  final TextStyle? style;

  const _ExpandableSupportText({
    required this.text,
    this.style,
  });

  @override
  State<_ExpandableSupportText> createState() => _ExpandableSupportTextState();
}

class _ExpandableSupportTextState extends State<_ExpandableSupportText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needsTruncate =
        widget.text.length > _ExpandableSupportText.maxCollapsedLength;

    if (!needsTruncate) {
      return Text(widget.text, style: widget.style);
    }

    if (_expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.text, style: widget.style),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: Text(
              l10n.showLess,
              style: TextStyle(
                fontSize: widget.style?.fontSize ?? 14,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final preview = widget.text
        .substring(0, _ExpandableSupportText.maxCollapsedLength)
        .trimRight();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$preview… ', style: widget.style),
        GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Text(
            l10n.readMore,
            style: TextStyle(
              fontSize: widget.style?.fontSize ?? 14,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
