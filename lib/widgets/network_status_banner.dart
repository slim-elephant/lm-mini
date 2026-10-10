import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/remote_access_screen.dart';
import '../services/network_status_service.dart';
import '../utils/network_preflight_error.dart';
import '../utils/server_reachability.dart';
import 'glass_blur.dart';
import 'setup_help_banner.dart';

/// Error banner for offline / mobile-data / lost-Wi‑Fi chat failures.
/// Frosted [SetupHelpBanner] — never offers Send to support.
class NetworkIssueBanner extends StatelessWidget {
  final NetworkIssue issue;
  final VoidCallback onDismiss;
  final VoidCallback? onSwitchProvider;

  const NetworkIssueBanner({
    super.key,
    required this.issue,
    required this.onDismiss,
    this.onSwitchProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = issue.provider.isEmpty ? 'LM Studio' : issue.provider;
    final host = issue.host;
    switch (issue.kind) {
      case NetworkIssueKind.offline:
        return SetupHelpBanner(
          icon: Icons.cloud_off_rounded,
          title: l10n.networkOfflineTitle,
          steps: [l10n.networkOfflineBody],
          onDismiss: onDismiss,
        );
      case NetworkIssueKind.needsWifi:
        return SetupHelpBanner(
          icon: Icons.wifi_off_rounded,
          title: l10n.networkNeedsWifiTitle(provider),
          steps: [l10n.networkNeedsWifiBody(provider, host)],
          actions: networkIssueActions(
            context,
            onSwitchProvider: onSwitchProvider,
            afterRemoteActivated: onDismiss,
          ),
          onDismiss: onDismiss,
        );
      case NetworkIssueKind.lostWifi:
        return SetupHelpBanner(
          icon: Icons.wifi_off_rounded,
          title: l10n.networkLostWifiTitle(provider),
          steps: [l10n.networkLostWifiBody],
          actions: networkIssueActions(
            context,
            onSwitchProvider: onSwitchProvider,
            afterRemoteActivated: onDismiss,
          ),
          onDismiss: onDismiss,
        );
    }
  }
}

/// "Use Remote Access" (already paired) or "Remote Access" (open setup),
/// plus "Switch provider" when the host can open the model/provider picker.
List<Widget> networkIssueActions(
  BuildContext context, {
  VoidCallback? onSwitchProvider,
  VoidCallback? afterRemoteActivated,
}) {
  final l10n = AppLocalizations.of(context);
  final sp = context.read<SettingsProvider>();
  final paired = (sp.settings.remoteServerUrl ?? '').trim().isNotEmpty;
  return [
    NetworkActionChip(
      icon: Icons.public_rounded,
      label: paired ? l10n.networkUseRemoteAccess : l10n.remoteAccess,
      onTap: () => _useRemoteAccess(
        context,
        paired: paired,
        afterActivated: afterRemoteActivated,
      ),
    ),
    if (onSwitchProvider != null)
      NetworkActionChip(
        icon: Icons.swap_horiz_rounded,
        label: l10n.networkSwitchProvider,
        onTap: onSwitchProvider,
      ),
  ];
}

Future<void> _useRemoteAccess(
  BuildContext context, {
  required bool paired,
  VoidCallback? afterActivated,
}) async {
  final sp = context.read<SettingsProvider>();
  if (paired) {
    try {
      await sp.reactivateRemoteAccess();
    } catch (e) {
      debugPrint('Use Remote Access failed: $e');
    }
    if (sp.settings.isRemoteActive) {
      ServerReachability.clearCache();
      sp.clearConnectionError();
      if (context.mounted) {
        context.read<ChatProvider>().clearError();
      }
      afterActivated?.call();
      return;
    }
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const RemoteAccessScreen()),
  );
}

/// Compact frosted pill above the composer while the phone is offline, or on
/// mobile data with a home-LAN provider. Hides itself when that clears.
class NetworkStatusBanner extends StatefulWidget {
  /// Chat target settings (per-chat overrides + cloud routing applied).
  final NetworkBannerTarget Function() resolveTarget;
  final bool isGroupChat;
  final VoidCallback? onSwitchProvider;

  const NetworkStatusBanner({
    super.key,
    required this.resolveTarget,
    this.isGroupChat = false,
    this.onSwitchProvider,
  });

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

/// The few fields the banner needs from the chat's effective settings.
class NetworkBannerTarget {
  final String providerKind;
  final String serverUrl;
  final bool isRemoteActive;
  final bool usbModeEnabled;
  final String providerName;

  const NetworkBannerTarget({
    required this.providerKind,
    required this.serverUrl,
    required this.isRemoteActive,
    required this.usbModeEnabled,
    required this.providerName,
  });
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  /// Dismissed for this exact condition; shows again once it changes.
  String? _dismissedKey;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkStatusService.instance,
      builder: (context, _) {
        final net = NetworkStatusService.instance.snapshot;
        // Cheap early out: nothing to say on Wi‑Fi / unknown.
        if (!net.isOffline && net.hasLocalNetwork) {
          return const SizedBox.shrink();
        }
        final target = widget.resolveTarget();
        final kind = proactiveNetworkIssue(
          providerKind: target.providerKind,
          serverUrl: target.serverUrl,
          isRemoteActive: target.isRemoteActive,
          usbModeEnabled: target.usbModeEnabled,
          isOffline: net.isOffline,
          hasLocalNetwork: net.hasLocalNetwork,
          hasVpn: net.hasVpn,
          lanCheck: !widget.isGroupChat,
        );
        final key = '${kind?.name}|${target.serverUrl}|$net';
        final visible = kind != null && _dismissedKey != key;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: visible
              ? _buildPill(context, kind, target, key)
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }

  Widget _buildPill(
    BuildContext context,
    NetworkIssueKind kind,
    NetworkBannerTarget target,
    String key,
  ) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF0B0E14).withValues(alpha: 0.88);
    final border = Colors.white.withValues(alpha: isDark ? 0.22 : 0.6);
    final fill = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.05),
            ]
          : [
              Colors.white.withValues(alpha: 0.42),
              Colors.white.withValues(alpha: 0.2),
            ],
    );
    final offline = kind == NetworkIssueKind.offline;
    final title = offline
        ? l10n.networkOfflineTitle
        : l10n.networkNeedsWifiTitle(target.providerName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GlassBlur(
          sigmaX: 30,
          sigmaY: 30,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: fill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        offline
                            ? Icons.cloud_off_rounded
                            : Icons.wifi_off_rounded,
                        size: 18,
                        color: ink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: ink, size: 16),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        tooltip: l10n.dismiss,
                        onPressed: () => setState(() => _dismissedKey = key),
                      ),
                    ],
                  ),
                  if (!offline) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: networkIssueActions(
                          context,
                          onSwitchProvider: widget.onSwitchProvider,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small frosted action pill used by the network banners.
class NetworkActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const NetworkActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF0B0E14).withValues(alpha: 0.88);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
