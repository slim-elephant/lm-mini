import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/settings_provider.dart';
import '../services/version_check_service.dart';
import '../utils/remote_host_backends.dart';

/// Compact banner stack shown at the top of the home screen.
class DeprecationBanners extends StatefulWidget {
  const DeprecationBanners({super.key});

  @override
  State<DeprecationBanners> createState() => _DeprecationBannersState();
}

class _DeprecationBannersState extends State<DeprecationBanners> {
  AppVersionInfo? _versionInfo;
  bool _versionDismissed = false;
  bool _homeHintDismissed = false;
  bool _legacyDismissed = false;

  @override
  void initState() {
    super.initState();
    _runVersionCheck();
  }

  Future<void> _runVersionCheck() async {
    final info = await VersionCheckService.instance.check();
    if (!mounted) return;
    final dismissed = info == null
        ? false
        : await VersionCheckService.instance.isDismissed(info.latestVersion);
    final homeHintDismissed =
        await VersionCheckService.instance.isConnectDismissed('lm-mini-home');
    final legacyDismissed =
        await VersionCheckService.instance.isConnectDismissed('legacy-relay');
    if (!mounted) return;
    setState(() {
      _versionInfo = info;
      _versionDismissed = dismissed;
      _homeHintDismissed = homeHintDismissed;
      _legacyDismissed = legacyDismissed;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final showLegacy = settings.isUsingLegacyRelay && !_legacyDismissed;
    final v = _versionInfo;
    final showAppUpdate = v != null && v.hasUpdate && !_versionDismissed;
    final paired = settings.settings.remoteServerUrl != null;
    final onHome = RemoteHostBackends.isHomeHost(settings.settings);
    final showHomeHint =
        paired && !onHome && !showLegacy && !_homeHintDismissed;

    if (!showLegacy && !showAppUpdate && !showHomeHint) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (showLegacy)
          _BannerTile(
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            title: 'This relay is retiring',
            message:
                'The older Cloud Run relay shuts down on May 10, 2026. Pair again from LM Mini Home on your Mac.',
            actionLabel: 'Learn more',
            onAction: () => _openUrl('https://lmmini.com/download.html#mac'),
            onDismiss: () async {
              await VersionCheckService.instance
                  .dismissConnect('legacy-relay');
              if (mounted) setState(() => _legacyDismissed = true);
            },
          ),
        if (showHomeHint)
          _BannerTile(
            compact: true,
            icon: Icons.home_rounded,
            color: Theme.of(context).colorScheme.primary,
            title: 'LM Mini Home is available',
            message:
                'A nicer way to share this Mac with your phone — optional, Connect still works.',
            actionLabel: 'Get LM Mini Home',
            onAction: () => _openUrl('https://lmmini.com/download.html#mac'),
            onDismiss: () async {
              await VersionCheckService.instance
                  .dismissConnect('lm-mini-home');
              if (mounted) setState(() => _homeHintDismissed = true);
            },
          ),
        if (showAppUpdate)
          _BannerTile(
            icon: v.isUnsupported
                ? Icons.error_outline
                : Icons.system_update_alt,
            color: v.isUnsupported ? Colors.red : Colors.blue,
            title: v.isUnsupported
                ? 'Update required'
                : 'Update available (${v.latestVersion})',
            message: v.notes ??
                (v.isUnsupported
                    ? 'This version of the app is no longer supported. Please update to continue using all features.'
                    : 'A newer version of the app is available.'),
            actionLabel: 'Get Update',
            onAction: () => _openUrl(v.downloadUrl),
            onDismiss: v.isUnsupported
                ? null
                : () async {
                    await VersionCheckService.instance
                        .dismiss(v.latestVersion);
                    if (mounted) setState(() => _versionDismissed = true);
                  },
          ),
      ],
    );
  }
}

class _BannerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;
  final bool compact;

  const _BannerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.onDismiss,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.fromLTRB(12, compact ? 6 : 8, 12, 0),
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 4, compact ? 8 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: compact ? 0.07 : 0.10),
        border: Border(left: BorderSide(color: color, width: compact ? 2 : 3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: compact ? 18 : 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 13 : null,
                        ),
                      ),
                    ),
                    if (onDismiss != null)
                      IconButton(
                        tooltip: 'Hide for 7 days',
                        onPressed: onDismiss,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    fontSize: compact ? 12 : null,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
