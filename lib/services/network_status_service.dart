import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../utils/server_reachability.dart';

/// Immutable view of the phone's connections.
///
/// Unknown (plugin missing / errored) is treated as "online with Wi‑Fi" so
/// nothing is ever blocked because the plugin failed.
@immutable
class NetworkSnapshot {
  /// Null = unknown.
  final List<ConnectivityResult>? types;

  const NetworkSnapshot(this.types);

  static const unknown = NetworkSnapshot(null);

  bool get isKnown => types != null && types!.isNotEmpty;

  bool get isOffline {
    if (!isKnown) return false;
    return types!.every((t) => t == ConnectivityResult.none);
  }

  /// Wi‑Fi or Ethernet — the home LAN is reachable.
  bool get hasLocalNetwork {
    if (!isKnown) return true;
    return types!.contains(ConnectivityResult.wifi) ||
        types!.contains(ConnectivityResult.ethernet);
  }

  /// VPN. iOS / macOS report a VPN tunnel as [ConnectivityResult.other]
  /// (no separate interface type), so `other` counts too.
  bool get hasVpn {
    if (!isKnown) return false;
    return types!.contains(ConnectivityResult.vpn) ||
        types!.contains(ConnectivityResult.other);
  }

  bool get hasMobile =>
      isKnown && types!.contains(ConnectivityResult.mobile);

  @override
  bool operator ==(Object other) =>
      other is NetworkSnapshot &&
      listEquals(_sorted(types), _sorted(other.types));

  @override
  int get hashCode => Object.hashAll(_sorted(types) ?? const []);

  static List<ConnectivityResult>? _sorted(List<ConnectivityResult>? t) {
    if (t == null) return null;
    final out = t.toSet().toList()..sort((a, b) => a.index - b.index);
    return out;
  }

  @override
  String toString() =>
      'NetworkSnapshot(${types?.map((t) => t.name).join(',') ?? 'unknown'})';
}

/// App-wide Wi‑Fi / mobile / offline awareness (iOS, Android, macOS).
///
/// Initialized from `main()` without awaiting. Every plugin call is wrapped:
/// on error the service stays "unknown", which callers treat as online.
class NetworkStatusService extends ChangeNotifier {
  NetworkStatusService._();
  static final NetworkStatusService instance = NetworkStatusService._();

  Connectivity? _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  NetworkSnapshot _snapshot = NetworkSnapshot.unknown;

  /// Debug-only forced snapshot (see [debugOverride]). Wins over the OS.
  NetworkSnapshot? _override;
  final StreamController<NetworkSnapshot> _changes =
      StreamController<NetworkSnapshot>.broadcast();
  bool _initStarted = false;

  /// What every caller should use: the debug override when set, else the
  /// last OS reading. Preflight, banners and the model-list check all read
  /// this (directly or via [refresh]), so an override is seen everywhere.
  NetworkSnapshot get snapshot => _override ?? _snapshot;
  List<ConnectivityResult>? get connectionTypes => snapshot.types;
  bool get isOffline => snapshot.isOffline;
  bool get hasLocalNetwork => snapshot.hasLocalNetwork;
  bool get hasVpn => snapshot.hasVpn;
  bool get hasMobile => snapshot.hasMobile;

  /// True while [debugOverride] is forcing a snapshot.
  bool get isOverridden => _override != null;

  /// Emits each time the connection set changes.
  Stream<NetworkSnapshot> get changes => _changes.stream;

  Future<void> initialize() async {
    if (_initStarted) return;
    _initStarted = true;
    if (kIsWeb) return;
    try {
      _connectivity = Connectivity();
      _sub = _connectivity!.onConnectivityChanged.listen(
        _apply,
        onError: (Object e) =>
            debugPrint('NetworkStatusService: stream error $e'),
      );
      await refresh(timeout: const Duration(seconds: 3));
    } catch (e) {
      debugPrint('NetworkStatusService: init failed ($e) — assuming online');
    }
  }

  /// Ask the OS again (cheap). Falls back to the cached snapshot.
  Future<NetworkSnapshot> refresh({
    Duration timeout = const Duration(milliseconds: 1200),
  }) async {
    final c = _connectivity;
    if (c == null) return snapshot;
    try {
      final r = await c.checkConnectivity().timeout(timeout);
      _apply(r);
    } catch (e) {
      debugPrint('NetworkStatusService: check failed ($e)');
    }
    return snapshot;
  }

  void _apply(List<ConnectivityResult> results) {
    final next = NetworkSnapshot(List.unmodifiable(results));
    if (next == _snapshot) return;
    debugPrint('📶 Network: $_snapshot → $next'
        '${_override != null ? ' (overridden: $_override)' : ''}');
    _snapshot = next;
    // While overridden, keep tracking the OS silently; callers keep seeing
    // the forced snapshot until the override is cleared.
    if (_override != null) return;
    // A host that answered on Wi‑Fi may be unreachable on 5G (and back).
    ServerReachability.clearCache();
    if (!_changes.isClosed) _changes.add(next);
    notifyListeners();
  }

  /// Tests only: force a connection set (null = unknown).
  @visibleForTesting
  void debugSetTypes(List<ConnectivityResult>? types) {
    if (types == null) {
      _snapshot = NetworkSnapshot.unknown;
      notifyListeners();
      return;
    }
    _apply(types);
  }

  /// Debug builds / tests only: force the snapshot every caller sees
  /// (preflight, chat pill, Settings, model-list check) and emit a change,
  /// so mobile data / offline / Wi‑Fi can be simulated on a simulator.
  /// Pass null to go back to the real OS reading. No-op in release.
  ///
  /// ```dart
  /// NetworkStatusService.instance.debugOverride(
  ///     const NetworkSnapshot([ConnectivityResult.mobile])); // 5G
  /// NetworkStatusService.instance.debugOverride(
  ///     const NetworkSnapshot([ConnectivityResult.none]));   // offline
  /// NetworkStatusService.instance.debugOverride(null);       // real
  /// ```
  /// Settings shows a "Simulate network" row in debug builds that calls this.
  void debugOverride(NetworkSnapshot? snapshot) {
    if (!kDebugMode) return;
    final before = this.snapshot;
    _override = snapshot;
    final after = this.snapshot;
    debugPrint('📶 Network override: ${snapshot ?? 'cleared'} '
        '(effective $before → $after)');
    if (after == before) return;
    // Same as a real change: cached probe results belong to the old route.
    ServerReachability.clearCache();
    if (!_changes.isClosed) _changes.add(after);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _changes.close();
    super.dispose();
  }
}
