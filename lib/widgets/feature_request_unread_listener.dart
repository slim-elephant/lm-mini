import 'package:flutter/material.dart';

import '../main.dart' show firebaseInitialized;
import '../models/feature_request.dart';
import '../services/feature_request_notification_service.dart';
import '../services/feature_request_service.dart';
import 'unread_dot.dart';

/// Listens for unread feature-request activity and exposes a green-dot badge.
///
/// For regular users, counts updates on their own tickets (admin replies,
/// status changes, new comments). For admins, counts unseen tickets and
/// tickets with new user comments.
class FeatureRequestUnreadListener extends StatefulWidget {
  final FeatureRequestService service;
  final String? userId;
  final bool isAdmin;
  final Widget Function(BuildContext context, bool hasUnread) builder;

  const FeatureRequestUnreadListener({
    super.key,
    required this.service,
    required this.userId,
    required this.isAdmin,
    required this.builder,
  });

  @override
  State<FeatureRequestUnreadListener> createState() =>
      _FeatureRequestUnreadListenerState();
}

class _FeatureRequestUnreadListenerState
    extends State<FeatureRequestUnreadListener> {
  final _notificationService = FeatureRequestNotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _notificationService.addListener(_onNotificationChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationChanged);
    super.dispose();
  }

  void _onNotificationChanged() {
    if (mounted) setState(() {});
  }

  bool _hasUnread(List<FeatureRequest> requests) {
    if (widget.isAdmin) {
      return _notificationService.countAdminUnreadSync(requests) > 0;
    }
    if (widget.userId == null) return false;
    return _notificationService.countUserUnreadSync(
          requests: requests,
          userId: widget.userId!,
        ) >
        0;
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized || widget.userId == null) {
      return widget.builder(context, false);
    }

    if (widget.isAdmin) {
      return StreamBuilder<List<FeatureRequest>>(
        stream: widget.service.getPopularRequests(),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const [];
          return widget.builder(context, _hasUnread(requests));
        },
      );
    }

    return StreamBuilder<List<FeatureRequest>>(
      stream: widget.service.getMyRequests(widget.userId!),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const [];
        return widget.builder(context, _hasUnread(requests));
      },
    );
  }
}

/// Green dot for inline use on a feature-request list card title row.
class FeatureRequestCardUnreadDot extends StatelessWidget {
  final FeatureRequest request;
  final String? currentUserId;
  final bool isAdmin;

  const FeatureRequestCardUnreadDot({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final notifications = FeatureRequestNotificationService();
    final show = isAdmin
        ? notifications.hasAdminUpdatesSync(request: request)
        : notifications.hasUserUpdatesSync(
            request: request,
            isOwnRequest: currentUserId == request.userId,
          );
    if (!show) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(left: 8),
      child: UnreadDot(),
    );
  }
}
