// LM-MINI-PRO-STUB
import 'package:flutter/foundation.dart';

import '../../desktop/host/desktop_relay_backends.dart';

export '../../desktop/host/desktop_relay_backends.dart';

/// Relay client placeholder for the open-source build.
///
/// Internet pairing through the LM Mini relay is part of the official app.
/// USB mode and LAN servers do not use this client and keep working.
class DesktopRelayClient extends ChangeNotifier {
  DesktopRelayClient._();
  static final DesktopRelayClient instance = DesktopRelayClient._();

  static const String defaultRelayWsUrl = '';

  DesktopRelayBackends _backends = const DesktopRelayBackends();

  bool get isConnected => false;
  bool get isConnecting => false;
  String? get lastError =>
      'Internet pairing is available in the official LM Mini app.';
  String? get sessionId => null;
  DesktopRelayBackends get backends => _backends;

  void updateBackends(DesktopRelayBackends backends) {
    _backends = backends;
  }

  Future<void> connect({
    required String sessionId,
    required String authToken,
    String relayWsUrl = defaultRelayWsUrl,
    DesktopRelayBackends? backends,
  }) async {
    if (backends != null) _backends = backends;
  }

  Future<bool> reconnectNow({bool force = false}) async => false;

  Future<void> disconnect() async {}
}
