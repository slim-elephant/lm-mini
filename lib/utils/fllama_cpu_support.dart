import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Whether this device's CPU can run the bundled llama.cpp (fllama) library.
///
/// fllama's Android arm64 build is compiled with
/// `-march=armv8.2-a+dotprod`, so it uses LSE atomics and SDOT/UDOT
/// instructions everywhere, including the background thread it starts as
/// soon as `libfllama.so` loads. ARMv8.0 phones (Cortex-A53/A57/A73 cores:
/// Galaxy A10/A20/A30/A50 and similar) crash with SIGILL the moment the
/// library is opened. Check this before any `package:fllama` call so the
/// library is never loaded on those devices.
///
/// 32-bit Android (armeabi-v7a) is not supported either: a 32-bit process
/// can't map a 1–2 GB model, and llama.cpp's failed-load cleanup then
/// crashes in `llama_free` (seen in Play pre-launch reports). Other
/// platforms are unaffected.
class FllamaCpuSupport {
  FllamaCpuSupport._();

  static bool? _cached;

  /// User-facing reason shown when on-device GGUF models can't run.
  static const unsupportedMessage =
      "This phone can't run on-device models (they need 64-bit Android on "
      'an ARMv8.2 CPU with dot-product support). Use LM Studio, Ollama or '
      'another server on your computer instead.';

  // Linux auxv / arm64 HWCAP bits (asm/hwcap.h).
  static const _atHwcap = 16;
  static const _hwcapAtomics = 1 << 8;
  static const _hwcapAsimddp = 1 << 20;

  static bool get isSupported => _cached ??= _detect();

  static bool _detect() {
    if (!Platform.isAndroid) return true;
    final abi = Abi.current();
    if (abi == Abi.androidArm || abi == Abi.androidIA32) return false;
    if (abi != Abi.androidArm64) return true; // x86_64 emulators, Chromebooks
    try {
      final getauxval = DynamicLibrary.process()
          .lookupFunction<Uint64 Function(Uint64), int Function(int)>(
              'getauxval');
      final hwcap = getauxval(_atHwcap);
      return supportsHwcap(hwcap);
    } catch (e) {
      debugPrint('FllamaCpuSupport: getauxval failed ($e), reading cpuinfo');
    }
    try {
      return supportsCpuinfo(File('/proc/cpuinfo').readAsStringSync());
    } catch (e) {
      debugPrint('FllamaCpuSupport: cpuinfo unreadable ($e)');
      // Unknown: loading the library could crash the app, so don't.
      return false;
    }
  }

  /// True when the kernel's HWCAP word has LSE atomics and dot product.
  @visibleForTesting
  static bool supportsHwcap(int hwcap) =>
      hwcap & _hwcapAtomics != 0 && hwcap & _hwcapAsimddp != 0;

  /// True when every CPU listed in /proc/cpuinfo reports `atomics` and
  /// `asimddp` (big.LITTLE cores can differ; threads run on any of them).
  @visibleForTesting
  static bool supportsCpuinfo(String cpuinfo) {
    final featureLines = cpuinfo
        .split('\n')
        .where((l) => l.toLowerCase().startsWith('features'))
        .toList();
    if (featureLines.isEmpty) return false;
    return featureLines.every((line) {
      final flags = line.split(':').last.trim().split(RegExp(r'\s+')).toSet();
      return flags.contains('atomics') && flags.contains('asimddp');
    });
  }
}
