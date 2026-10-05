import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show firebaseInitialized;
import '../screens/settings_screen.dart';
import '../services/feature_request_service.dart';
import '../utils/theme_extensions.dart';
import 'feature_request_unread_listener.dart';
import 'home_glass_header.dart';
import 'unread_dot.dart';

/// Settings icon for the home screen app bar, with an unread dot when support
/// tickets have new activity.
class FeatureRequestAwareSettingsButton extends StatefulWidget {
  /// When true, renders as a frosted glass circle (home glass header).
  final bool useGlass;

  const FeatureRequestAwareSettingsButton({
    super.key,
    this.useGlass = false,
  });

  @override
  State<FeatureRequestAwareSettingsButton> createState() =>
      _FeatureRequestAwareSettingsButtonState();
}

class _FeatureRequestAwareSettingsButtonState
    extends State<FeatureRequestAwareSettingsButton> {
  FeatureRequestService? _service;
  String? _userId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!firebaseInitialized) return;
    final service = FeatureRequestService();
    try {
      final userId = await service.getCurrentUserId();
      final isAdmin = await service.isAdmin;
      if (mounted) {
        setState(() {
          _service = service;
          _userId = userId;
          _isAdmin = isAdmin;
        });
      }
    } catch (_) {}
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Widget _buildButton({required Widget icon, required bool hasUnread}) {
    final child = UnreadDotOverlay(show: hasUnread, child: icon);
    if (widget.useGlass) {
      final iconColor = IconTheme.of(context).color ?? Colors.white;
      return GlassCircleIconButton(
        tooltip: AppLocalizations.of(context).settingsTitle,
        onTap: _openSettings,
        child: IconTheme(
          data: IconThemeData(
            color: iconColor,
            size: 22,
          ),
          child: child,
        ),
      );
    }
    return IconButton(icon: child, onPressed: _openSettings);
  }

  @override
  Widget build(BuildContext context) {
    final icon = context.themeIcon('home_settings', Icons.settings);

    if (_service == null || _userId == null || !firebaseInitialized) {
      return _buildButton(icon: icon, hasUnread: false);
    }

    return FeatureRequestUnreadListener(
      service: _service!,
      userId: _userId,
      isAdmin: _isAdmin,
      builder: (context, hasUnread) {
        return _buildButton(icon: icon, hasUnread: hasUnread);
      },
    );
  }
}
