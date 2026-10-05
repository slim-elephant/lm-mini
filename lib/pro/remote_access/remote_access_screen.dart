// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Public-build stub: Remote Access (relay pairing with LM Mini Home /
/// LM Mini Connect) ships only in the official LM Mini app. Renders an
/// informational placeholder; wizard pairing ([popWhenDone]) pops `false`.
class RemoteAccessScreen extends StatefulWidget {
  final bool startScanning;
  final bool embedded;

  /// Wizard pairing: show only the camera, then pop `true`/`false`.
  final bool popWhenDone;
  const RemoteAccessScreen({
    super.key,
    this.startScanning = false,
    this.embedded = false,
    this.popWhenDone = false,
  });

  @override
  State<RemoteAccessScreen> createState() => _RemoteAccessScreenState();
}

class _RemoteAccessScreenState extends State<RemoteAccessScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.popWhenDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const body = Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Remote Access is available in the official LM Mini app. LAN '
          'connections to LM Studio, Ollama, oMLX, Jan and Unsloth work in '
          'this build.',
          textAlign: TextAlign.center,
        ),
      ),
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).remoteAccess)),
      body: body,
    );
  }
}
