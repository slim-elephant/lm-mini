import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/connect_host_error.dart';
import '../utils/lan_server_error.dart';
import 'glass_blur.dart';

/// Frosted in-chat setup help (LAN / Connect / missing model). Not a support ticket.
class SetupHelpBanner extends StatelessWidget {
  final String title;
  final List<String> steps;
  final String? imageAsset;
  final String? imageLabel;
  final List<Widget> actions;
  final VoidCallback onDismiss;
  final IconData icon;

  const SetupHelpBanner({
    super.key,
    required this.title,
    required this.steps,
    required this.onDismiss,
    this.imageAsset,
    this.imageLabel,
    this.actions = const [],
    this.icon = Icons.desktop_windows_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF0B0E14).withValues(alpha: 0.88);
    final muted = ink.withValues(alpha: 0.72);
    final border = Colors.white.withValues(alpha: isDark ? 0.22 : 0.55);
    final fill = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.04),
            ]
          : [
              Colors.white.withValues(alpha: 0.42),
              Colors.white.withValues(alpha: 0.16),
            ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GlassBlur(
          sigmaX: 28,
          sigmaY: 28,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: fill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(icon, size: 20, color: ink),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: ink, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: l10n.dismiss,
                        onPressed: onDismiss,
                      ),
                    ],
                  ),
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...steps.asMap().entries.map((e) {
                      final numbered = steps.length > 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6, right: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (numbered)
                              SizedBox(
                                width: 18,
                                child: Text(
                                  '${e.key + 1}.',
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (imageAsset != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: LmStudioServeOnLanScreenshot(
                        assetPath: imageAsset!,
                        semanticLabel:
                            imageLabel ?? l10n.lmStudioServerSettingsImageLabel,
                      ),
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: actions,
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

/// Tappable LM Studio Developer → Server Settings screenshot.
class LmStudioServeOnLanScreenshot extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;

  const LmStudioServeOnLanScreenshot({
    super.key,
    this.assetPath = LanServerError.assetPath,
    required this.semanticLabel,
  });

  void _openFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black.withValues(alpha: 0.92),
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 3,
                child: Image.asset(assetPath, semanticLabel: semanticLabel),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: AppLocalizations.of(ctx).dismiss,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFull(context),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 168),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showLmStudioLanHelpDialog(
  BuildContext context, {
  required LanServerErrorKind kind,
  VoidCallback? onGoToSettings,
}) {
  final l10n = AppLocalizations.of(context);
  final hostDown = kind == LanServerErrorKind.hostDown;
  final title =
      hostDown ? l10n.lmStudioHostDownTitle : l10n.lmStudioPcNotAllowingTitle;
  final steps = hostDown
      ? [l10n.lmStudioHostDownStep1, l10n.lmStudioHostDownStep2]
      : [l10n.lmStudioPcNotAllowingBody];

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...steps.asMap().entries.map((e) {
                final numbered = steps.length > 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    numbered ? '${e.key + 1}. ${e.value}' : e.value,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                );
              }),
              const SizedBox(height: 8),
              LmStudioServeOnLanScreenshot(
                semanticLabel: l10n.lmStudioServerSettingsImageLabel,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.connectionPopupDismiss),
          ),
          if (onGoToSettings != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onGoToSettings();
              },
              child: Text(l10n.connectionPopupGoToSettings),
            ),
        ],
      );
    },
  );
}

Future<void> showConnectHostHelpDialog(
  BuildContext context, {
  required ConnectHostErrorKind kind,
  VoidCallback? onGoToSettings,
}) {
  if (kind == ConnectHostErrorKind.lanHostDown) {
    return showLmStudioLanHelpDialog(
      context,
      kind: LanServerErrorKind.hostDown,
      onGoToSettings: onGoToSettings,
    );
  }

  final l10n = AppLocalizations.of(context);
  final usb = kind == ConnectHostErrorKind.usb;
  final title = usb ? l10n.waitingForMac : l10n.cantReachMacTitle;
  final steps = usb
      ? [l10n.waitingForMacBody]
      : [l10n.cantReachMacStep1, l10n.cantReachMacStep2];

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...steps.asMap().entries.map((e) {
                final numbered = steps.length > 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    numbered ? '${e.key + 1}. ${e.value}' : e.value,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                );
              }),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.connectionPopupDismiss),
          ),
          if (onGoToSettings != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onGoToSettings();
              },
              child: Text(l10n.connectionPopupGoToSettings),
            ),
        ],
      );
    },
  );
}

/// Returns true if a Connect / USB / LAN-502 setup dialog was shown.
bool showConnectHostHelpIfNeeded(
  BuildContext context, {
  required Object error,
  String? serverUrl,
  bool isRemoteActive = false,
  bool usbModeEnabled = false,
  String? providerKind,
  VoidCallback? onGoToSettings,
}) {
  final kind = ConnectHostError.classify(
    error: error,
    serverUrl: serverUrl,
    isRemoteActive: isRemoteActive,
    usbModeEnabled: usbModeEnabled,
  );
  if (kind == null) return false;

  if (kind == ConnectHostErrorKind.lanHostDown &&
      providerKind != null &&
      providerKind != 'lmStudio') {
    showConnectHostHelpDialog(
      context,
      kind: ConnectHostErrorKind.shareWithPhone,
      onGoToSettings: onGoToSettings,
    );
    return true;
  }

  showConnectHostHelpDialog(
    context,
    kind: kind,
    onGoToSettings: onGoToSettings,
  );
  return true;
}
