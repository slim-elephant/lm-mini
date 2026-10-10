import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/remote_host_backends.dart';
import '../utils/server_reachability.dart';
import 'pro_badge.dart';

/// On / off switch for an already-paired Remote Access session.
///
/// Off goes back to the saved home-network server and keeps the pairing.
/// On reconnects the same pairing (no QR rescan) and checks the computer
/// answers. Turning on needs Pro; turning off always works.
class RemoteAccessSwitch extends StatefulWidget {
  const RemoteAccessSwitch({super.key});

  /// True when there is a saved pairing the switch can turn on and off.
  static bool isPaired(SettingsProvider sp) {
    final s = sp.settings;
    return (s.remoteServerUrl?.isNotEmpty ?? false) &&
        (s.remoteAuthToken?.isNotEmpty ?? false);
  }

  @override
  State<RemoteAccessSwitch> createState() => _RemoteAccessSwitchState();
}

class _RemoteAccessSwitchState extends State<RemoteAccessSwitch> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    if (_busy) return;
    final sp = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    String? error;
    try {
      if (on) {
        await sp.reactivateRemoteAccess();
        final s = sp.settings;
        if (!s.isRemoteActive) {
          error = l10n.remoteAccessTurnOnFailed;
        } else {
          final ok = await sp.remoteAccessService.testConnection(
            s.remoteServerUrl!,
            s.remoteAuthToken!,
            backend: RemoteHostBackends.probeKind(s),
          );
          if (ok) {
            ServerReachability.clearCache();
            sp.clearConnectionError();
          } else {
            error = l10n.remoteAccessUnreachable;
          }
        }
      } else {
        await sp.deactivateRemoteAccess();
      }
    } catch (e) {
      debugPrint('Remote Access switch failed: $e');
      error =
          on ? l10n.remoteAccessTurnOnFailed : l10n.remoteAccessTurnOffFailed;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      messenger?.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final active = sp.settings.isRemoteActive;
    if (_busy) {
      return Semantics(
        label: AppLocalizations.of(context).remoteAccessSwitchConnecting,
        child: const SizedBox(
          width: 52,
          height: 32,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    final isPro = SubscriptionService().isPremium;
    final paired = RemoteAccessSwitch.isPaired(sp);
    // Off always works; on needs Pro.
    final canChange = paired && (active || isPro);
    final toggle = Switch(
      value: active,
      onChanged: canChange ? _toggle : null,
    );
    if (isPro || active) return toggle;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ProBadge(),
        const SizedBox(width: 6),
        toggle,
      ],
    );
  }
}

/// Plain-language subtitle for [RemoteAccessSwitch].
String remoteAccessSwitchSubtitle(AppLocalizations l10n, bool active) => active
    ? l10n.remoteAccessSwitchOnSubtitle
    : l10n.remoteAccessSwitchOffSubtitle;
