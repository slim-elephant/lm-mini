import 'package:flutter/material.dart';

import '../utils/client_platform.dart';

/// Small platform chip shown on support tickets and comments.
class PlatformBadge extends StatelessWidget {
  final String? platform;
  final bool compact;

  const PlatformBadge({
    super.key,
    required this.platform,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final kind = ClientPlatform.parseStorageKey(platform);
    if (kind == null || kind == ClientPlatformKind.other) {
      return const SizedBox.shrink();
    }

    final (label, bg, fg, icon) = switch (kind) {
      ClientPlatformKind.ios => (
          'iOS',
          const Color(0xFF1C1C1E),
          Colors.white,
          Icons.phone_iphone,
        ),
      ClientPlatformKind.android => (
          'Android',
          const Color(0xFF3DDC84),
          const Color(0xFF073042),
          Icons.android,
        ),
      ClientPlatformKind.macos => (
          'macOS',
          const Color(0xFF555555),
          Colors.white,
          Icons.laptop_mac,
        ),
      ClientPlatformKind.other => ('', Colors.grey, Colors.white, Icons.devices),
    };

    return Tooltip(
      message: '$label app',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7,
          vertical: compact ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(compact ? 4 : 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 11 : 13, color: fg),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Optional app version suffix for admin detail views.
class AppVersionLabel extends StatelessWidget {
  final String? appVersion;

  const AppVersionLabel({super.key, required this.appVersion});

  @override
  Widget build(BuildContext context) {
    final v = appVersion?.trim();
    if (v == null || v.isEmpty) return const SizedBox.shrink();

    return Text(
      'v$v',
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
