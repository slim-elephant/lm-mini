import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/fllama_cpu_support.dart';

void main() {
  // Exynos 9610 (Galaxy A50): Cortex-A73 + A53, ARMv8.0 — no LSE, no dotprod.
  const galaxyA50 = '''
processor	: 0
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32
CPU architecture: 8
CPU part	: 0xd03

processor	: 4
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32
CPU architecture: 8
CPU part	: 0xd09
''';

  // Snapdragon 855: Kryo 485 (A76/A55), ARMv8.2 with dotprod.
  const snapdragon855 = '''
processor	: 0
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp

processor	: 7
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp
''';

  test('cpuinfo: ARMv8.0 phone is not supported', () {
    expect(FllamaCpuSupport.supportsCpuinfo(galaxyA50), isFalse);
  });

  test('cpuinfo: ARMv8.2 + dotprod phone is supported', () {
    expect(FllamaCpuSupport.supportsCpuinfo(snapdragon855), isTrue);
  });

  test('cpuinfo: one core without dotprod makes the device unsupported', () {
    final mixed = snapdragon855.replaceFirst(' asimddp', '');
    expect(FllamaCpuSupport.supportsCpuinfo(mixed), isFalse);
  });

  test('cpuinfo: no Features lines is unsupported', () {
    expect(FllamaCpuSupport.supportsCpuinfo('Hardware : Qualcomm'), isFalse);
  });

  test('HWCAP bits: needs both atomics (bit 8) and asimddp (bit 20)', () {
    expect(FllamaCpuSupport.supportsHwcap((1 << 8) | (1 << 20)), isTrue);
    expect(FllamaCpuSupport.supportsHwcap(1 << 8), isFalse);
    expect(FllamaCpuSupport.supportsHwcap(1 << 20), isFalse);
    expect(FllamaCpuSupport.supportsHwcap(0xff), isFalse);
  });

  test('host test platform is not Android arm64, so it is supported', () {
    expect(FllamaCpuSupport.isSupported, isTrue);
  });
}
