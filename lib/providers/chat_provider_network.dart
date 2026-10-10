part of 'chat_provider.dart';

/// LAN server a reply is streaming from (set after a successful preflight).
class _LanStreamTarget {
  final String provider;
  final String host;

  const _LanStreamTarget(this.provider, this.host);
}

/// Network preflight + mid-stream Wi‑Fi loss for server-backed chat sends.
///
/// Before any HTTP request to LM Studio / Ollama / Jan / oMLX / Unsloth /
/// OpenAI-compatible / cloud we check the phone's connection and, for LAN
/// hosts, open a short TCP probe. Failures throw [NetworkPreflightException]
/// so the caller's normal error path runs (user message kept, no placeholder,
/// Stop hidden, live activity released, banner shown in ≤ ~4 s).
extension _NetworkPreflight on ChatProvider {
  /// Friendly provider label for status + error copy ("LM Studio", "Ollama").
  String _preflightProviderName(AppSettings settings) {
    final kind = settings.activeProviderKind;
    if (kind == 'cloud') {
      return _resolveEffectiveCloudProvider(settings: settings)
              ?.type
              .displayName ??
          'the server';
    }
    return RemoteHostBackends.displayName(kind);
  }

  static Uri? _probeUri(String url) {
    var raw = url.trim();
    if (raw.isEmpty) return null;
    if (!raw.contains('://')) raw = 'http://$raw';
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;
    return uri;
  }

  /// Throws [NetworkPreflightException] when the chat server cannot be
  /// reached right now. No-op for on-device, Apple Intelligence and USB.
  ///
  /// [groupTurn] keeps an already-recorded LAN target (parallel group turns
  /// may stream from several backends at once). [quiet] skips the
  /// "Connecting to …" status (parallel group shows its own).
  Future<void> _preflightServer(
    AppSettings settings, {
    bool groupTurn = false,
    bool quiet = false,
  }) async {
    if (!groupTurn) _activeLanTarget = null;
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return;
    }
    // USB bridge works without any network.
    if (settings.usbModeEnabled) return;
    _ensureNetworkWatch();

    final url = settings.serverUrl.trim();
    // Remote Access relays through a public host — only the offline check.
    final scope =
        settings.isRemoteActive ? HostScope.public : classifyHost(url);
    if (scope == HostScope.loopback) return;

    final name = _preflightProviderName(settings);
    if (!quiet) {
      _setStreamingStatus('Connecting to $name…');
      notifyListeners();
    }

    // Always re-ask the OS: a stale reading must never block a send.
    final net = await NetworkStatusService.instance.refresh(
      timeout: const Duration(milliseconds: 800),
    );
    final decision = decide(
      hostScope: scope,
      isOffline: net.isOffline,
      hasLocalNetwork: net.hasLocalNetwork,
      hasVpn: net.hasVpn,
    );
    final host = hostOf(url) ?? url;
    const tag = NetworkPreflightError.detailPrefix;
    debugPrint('📶 Preflight $name ($host): scope=${scope.name} '
        'net=$net → ${decision.name}');

    switch (decision) {
      case PreflightDecision.proceed:
        return;
      case PreflightDecision.blockOffline:
        throw const NetworkPreflightException(
          NetworkPreflightError.offlineMessage,
          detail: '$tag no network connection.',
        );
      case PreflightDecision.blockNeedsWifi:
        throw NetworkPreflightException(
          NetworkPreflightError.needsWifiMessage(name, host),
          detail: '$tag mobile data only; $host is on a local network.',
        );
      case PreflightDecision.probe:
        break;
    }

    final uri = _probeUri(url);
    if (uri == null) return;
    final result = await ServerReachability.probe(uri);
    if (_shouldCancelGeneration) return;
    final hostPort = '${uri.host}:${portFor(uri)}';
    debugPrint('📶 Probe $hostPort → ${result.name}');

    if (result == ProbeResult.ok) {
      if (scope == HostScope.localNetwork) {
        _activeLanTarget = _LanStreamTarget(name, host);
      }
      return;
    }

    // VPN reported (iOS shows any tunnel as "other") but it does not route
    // the home LAN, and there is no Wi‑Fi: the mobile-data copy is clearer.
    if (scope == HostScope.localNetwork &&
        !net.hasLocalNetwork &&
        net.hasMobile) {
      throw NetworkPreflightException(
        NetworkPreflightError.needsWifiMessage(name, host),
        detail: '$tag mobile data only; $hostPort did not answer '
            '(${result.name}).',
      );
    }

    // iOS: the very first LAN connection can sit behind the Local Network
    // permission prompt. Let the real request (8 s connect cap) handle it.
    if (result == ProbeResult.timeout &&
        Platform.isIOS &&
        scope != HostScope.public &&
        !ServerReachability.hasEverReachedLocalHost) {
      debugPrint('📶 First LAN probe timed out on iOS — letting request run');
      return;
    }

    final isLmStudio = kind == 'lmStudio';
    if (result == ProbeResult.refused) {
      throw NetworkPreflightException(
        isLmStudio
            ? LanServerError.refusedUserMessage
            : _serverUnreachableMessage(settings),
        detail: 'SocketException: Connection refused ($tag $hostPort)',
      );
    }
    throw NetworkPreflightException(
      isLmStudio
          ? LanServerError.hostDownUserMessage
          : "Can't reach $name at $host. Make sure your computer is on and "
              'connected to the same network as this device.',
      detail: '$tag no answer from $hostPort (${result.name}).',
    );
  }

  /// Runs [_preflightServer] before regenerate / edit touch any messages.
  /// Returns false (with the error set and generation UI cleared) when the
  /// server is unreachable or the user pressed Stop, so nothing is deleted.
  Future<bool> _preflightBeforeRegenerate(AppSettings settings) async {
    _isSendingMessage = true;
    _shouldCancelGeneration = false;
    _error = null;
    _errorDetail = null;
    notifyListeners();
    try {
      await _preflightServer(settings);
    } on NetworkPreflightException catch (e) {
      _error = e.message;
      _errorDetail = e.detail;
      _isSendingMessage = false;
      _setStreamingStatus(null);
      notifyListeners();
      return false;
    }
    if (_shouldCancelGeneration) {
      _isSendingMessage = false;
      _setStreamingStatus(null);
      notifyListeners();
      return false;
    }
    return true;
  }

  void _ensureNetworkWatch() {
    _networkSub ??=
        NetworkStatusService.instance.changes.listen(_onNetworkChanged);
  }

  static bool _lostLan(NetworkSnapshot s) =>
      s.isOffline || (!s.hasLocalNetwork && !s.hasVpn);

  void _onNetworkChanged(NetworkSnapshot snap) {
    final target = _activeLanTarget;
    if (target == null || !_isSendingMessage) return;
    if (!_lostLan(snap)) {
      _networkLossTimer?.cancel();
      _networkLossTimer = null;
      return;
    }
    if (_networkLossTimer != null) return;
    // Hand-offs can report a sub-second gap; confirm once before stopping.
    _networkLossTimer = Timer(const Duration(milliseconds: 900), () async {
      _networkLossTimer = null;
      final now = await NetworkStatusService.instance.refresh(
        timeout: const Duration(milliseconds: 800),
      );
      if (!_lostLan(now)) return;
      if (!_isSendingMessage || !identical(_activeLanTarget, target)) return;
      if (!LMStudioService.hasActiveStreams &&
          !OllamaService.hasActiveStreams) {
        return;
      }
      _abortForNetworkLoss(target);
    });
  }

  /// Phone left Wi‑Fi while streaming from a LAN host: close the socket now
  /// (keeps the partial reply like Stop does) and explain why.
  void _abortForNetworkLoss(_LanStreamTarget target) {
    debugPrint('📶 Lost Wi‑Fi mid-stream from ${target.host} — stopping');
    final message = NetworkPreflightError.lostWifiMessage(target.provider);
    final detail = '${NetworkPreflightError.detailPrefix} Wi-Fi dropped '
        'while streaming from ${target.host}.';
    _activeLanTarget = null;
    _networkLossError = (message: message, detail: detail);
    stopGeneration();
    _error = message;
    _errorDetail = detail;
    notifyListeners();
  }

  /// Call at the end of a send flow: re-assert a lost-Wi‑Fi error that the
  /// unwinding stream may have overwritten, and forget the LAN target.
  void _finishNetworkWatchForSend() {
    _networkLossTimer?.cancel();
    _networkLossTimer = null;
    _activeLanTarget = null;
    final pending = _networkLossError;
    if (pending == null) return;
    _networkLossError = null;
    _error = pending.message;
    _errorDetail = pending.detail;
  }
}
