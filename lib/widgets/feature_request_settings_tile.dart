import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show firebaseInitialized;
import '../screens/feature_requests_screen.dart';
import '../services/feature_request_service.dart';
import 'feature_request_unread_listener.dart';
import 'unread_dot.dart';

/// Settings row for Support / Feature Requests with an unread indicator.
class FeatureRequestSettingsTile extends StatefulWidget {
  /// When set (desktop pane), opens in-column instead of pushing a route.
  final VoidCallback? onOpen;

  const FeatureRequestSettingsTile({super.key, this.onOpen});

  @override
  State<FeatureRequestSettingsTile> createState() =>
      _FeatureRequestSettingsTileState();
}

class _FeatureRequestSettingsTileState extends State<FeatureRequestSettingsTile> {
  FeatureRequestService? _service;
  String? _userId;
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!firebaseInitialized) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final service = FeatureRequestService();
    try {
      final userId = await service.getCurrentUserId();
      final isAdmin = await service.isAdmin;
      if (mounted) {
        setState(() {
          _service = service;
          _userId = userId;
          _isAdmin = isAdmin;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget trailing = const Icon(Icons.chevron_right);
    if (!_loading &&
        _service != null &&
        _userId != null &&
        firebaseInitialized) {
      trailing = FeatureRequestUnreadListener(
        service: _service!,
        userId: _userId,
        isAdmin: _isAdmin,
        builder: (context, hasUnread) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasUnread) ...[
                const UnreadDot(size: 9),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right),
            ],
          );
        },
      );
    }

    return ListTile(
      leading: const Icon(Icons.lightbulb_outline),
      title: Text(l10n.featureRequests),
      subtitle: Text(l10n.featureRequestsSubtitle),
      trailing: trailing,
      onTap: () {
        if (widget.onOpen != null) {
          widget.onOpen!();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeatureRequestsScreen()),
        );
      },
    );
  }
}
