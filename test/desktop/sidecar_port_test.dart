import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/desktop/runtime/sidecar_port.dart';

void main() {
  test('parseLsofPids ignores pid 1 and junk', () {
    expect(SidecarPort.parseLsofPids('88662\n'), {88662});
    expect(SidecarPort.parseLsofPids('1\n2\n'), {2});
    expect(SidecarPort.parseLsofPids(''), isEmpty);
  });

  test('parseNetstatListeningPids matches only that listen port', () {
    const out = '''
  TCP    127.0.0.1:8741         0.0.0.0:0              LISTENING       88662
  TCP    127.0.0.1:8080         0.0.0.0:0              LISTENING       99
  TCP    127.0.0.1:87410        0.0.0.0:0              LISTENING       7
  TCP    127.0.0.1:8741         127.0.0.1:52344        ESTABLISHED     88662
''';
    expect(SidecarPort.parseNetstatListeningPids(out, 8741), {88662});
  });
}
