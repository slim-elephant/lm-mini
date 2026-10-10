import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/network_status_service.dart';

void main() {
  test('debugOverride forces the snapshot everyone reads, then restores',
      () async {
    final s = NetworkStatusService.instance;
    s.debugSetTypes(const [ConnectivityResult.wifi]);
    final emitted = <NetworkSnapshot>[];
    final sub = s.changes.listen(emitted.add);

    s.debugOverride(const NetworkSnapshot([ConnectivityResult.mobile]));
    expect(s.isOverridden, isTrue);
    expect(s.hasLocalNetwork, isFalse);
    expect(s.hasMobile, isTrue);
    // refresh() with no plugin returns the effective (overridden) snapshot.
    expect((await s.refresh()).hasMobile, isTrue);

    // A real OS change while overridden is tracked but not reported.
    s.debugSetTypes(const [ConnectivityResult.ethernet]);
    expect(s.hasMobile, isTrue);

    s.debugOverride(const NetworkSnapshot([ConnectivityResult.none]));
    expect(s.isOffline, isTrue);

    s.debugOverride(null);
    expect(s.isOverridden, isFalse);
    expect(s.hasLocalNetwork, isTrue); // ethernet from the OS
    await Future<void>.delayed(Duration.zero);
    expect(emitted.length, 3);
    await sub.cancel();
  });
}
