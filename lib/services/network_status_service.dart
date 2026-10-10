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
  final StreamController<NetworkSnapshot> _changes =
      StreamController<NetworkSnapshot>.broadcast();
  bool _initStarted = false;

  NetworkSnapshot get snapshot => _snapshot;
  List<ConnectivityResult>? get connectionTypes => _snapshot.types;
  bool get isOffline => _snapshot.isOffline;
  bool get hasLocalNetwork => _snapshot.hasLocalNetwork;
  bool get hasVpn => _snapshot.hasVpn;
  bool get hasMobile => _snapshot.hasMobile;

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
    if (c == null) return _snapshot;
    try {
      final r = await c.checkConnectivity().timeout(timeout);
      _apply(r);
    } catch (e) {
      debugPrint('NetworkStatusService: check failed ($e)');
    }
    return _snapshot;
  }

  void _apply(List<ConnectivityResult> results) {
    final next = NetworkSnapshot(List.unmodifiable(results));
    if (next == _snapshot) return;
    debugPrint('📶 Network: $_snapshot → $next');
    _snapshot = next;
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

  @override
  void dispose() {
    _sub?.cancel();
    _changes.close();
    super.dispose();
  }
}
