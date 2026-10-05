import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/local_model_spec.dart';
import '../models/local_sd_asset_spec.dart';

/// Reported chip family for an Apple device. Drives the recommended
/// max-model-size guidance and the speculative-decoding fit checks.
enum AppleChip {
  unknown,
  a13, // iPhone 11 series, SE2
  a14, // iPhone 12 series
  a15, // iPhone 13/14, SE3, iPad mini 6
  a16, // iPhone 14 Pro, iPhone 15
  a17Pro, // iPhone 15 Pro
  a18, // iPhone 16/16 Plus
  a18Pro, // iPhone 16 Pro
  a19, // iPhone 17 (hypothetical)
  a19Pro, // iPhone 17 Pro (hypothetical)
  m1,
  m2,
  m3,
  m4,
  m5,
}

/// Snapshot of the current device's relevant capabilities.
class DeviceCapability {
  /// Human-readable device name, e.g. "iPhone 15 Pro" or "iPad Pro (M2)".
  final String deviceName;

  /// Raw `utsname.machine` identifier (e.g. `iPhone16,1`). Empty on
  /// non-Apple platforms or when lookup fails.
  final String hwMachine;

  /// Inferred chip family.
  final AppleChip chip;

  /// Human-readable chip label, e.g. "M4 Max" or "A17 Pro".
  final String chipLabel;

  /// Approximate device RAM in GB. Defaults to a conservative estimate when
  /// the exact value can't be determined.
  final double ramGb;

  /// Whether the device supports Apple Intelligence (iOS 26+ on supported
  /// hardware). Always false on non-iOS platforms.
  final bool supportsAppleIntelligence;

  /// Whether the MLX-Swift engine is available on this platform/build.
  /// True on Apple Silicon iOS/iPadOS/macOS; false elsewhere (including
  /// Intel Macs and Android).
  final bool supportsMlx;

  /// Android: Vulkan hardware feature present. False on Apple / unknown.
  final bool supportsVulkan;

  const DeviceCapability({
    required this.deviceName,
    required this.hwMachine,
    required this.chip,
    required this.chipLabel,
    required this.ramGb,
    required this.supportsAppleIntelligence,
    required this.supportsMlx,
    this.supportsVulkan = false,
  });

  /// Human-readable RAM line for the Local Models device banner.
  /// iPad Pro storage tiers ship with different RAM (e.g. M5 1 TB → 16 GB)
  /// but iOS does not expose the exact value — show a range when relevant.
  String get ramDisplayLabel {
    final m = hwMachine.toLowerCase();
    if (m.startsWith('ipad17,') || m.startsWith('ipad16,')) {
      return '8–16 GB RAM';
    }
    if (ramGb >= 10) {
      return '${ramGb.round()} GB RAM';
    }
    return '${ramGb.toStringAsFixed(0)} GB RAM';
  }

  /// A safe "I have no idea" fallback used on web, desktop test runs, or
  /// when the platform plugin throws.
  static const DeviceCapability unknown = DeviceCapability(
    deviceName: 'Unknown device',
    hwMachine: '',
    chip: AppleChip.unknown,
    chipLabel: 'Unknown',
    ramGb: 4.0,
    supportsAppleIntelligence: false,
    supportsMlx: false,
    supportsVulkan: false,
  );

  /// Suggested on-device LLM size tier from RAM (and Vulkan on Android).
  String get llmTierLabel {
    if (ramGb < 4.5) return 'Up to ~1.5B GGUF';
    if (ramGb < 6.5) return 'Up to ~3B GGUF';
    if (ramGb < 8.5) {
      return supportsVulkan ? 'Up to ~7B Q4 (GPU)' : 'Up to ~4B GGUF';
    }
    return supportsVulkan ? 'Up to ~7–8B Q4' : 'Up to ~7B Q4 (CPU tight)';
  }

  /// Whisper size suggestion for this device.
  String get whisperSuggestion {
    if (ramGb < 4.5) return 'Whisper Tiny';
    if (ramGb < 6.5) return 'Whisper Base';
    return 'Whisper Small';
  }

  /// Kokoro TTS feasibility note.
  String get kokoroSuggestion {
    if (ramGb < 3.5) return 'Kokoro may be slow';
    if (ramGb < 5.5) return 'Kokoro OK';
    return 'Kokoro recommended';
  }
}

/// Resolves the current device's chip/RAM/AI-support and answers
/// "will this model run?" questions for the Local Models UI.
///
/// Lookup tables intentionally live in code (not a server fetch) so the
/// capability check works fully offline. When Apple ships a new device we
/// just add it here.
class DeviceCapabilityService {
  DeviceCapabilityService._();
  static final DeviceCapabilityService instance = DeviceCapabilityService._();

  static const MethodChannel _androidChannel =
      MethodChannel('net.neuro9.lmmini/device_capability');

  DeviceCapability? _cached;
  Future<DeviceCapability>? _inflight;

  /// Returns (and memoizes) the device capability snapshot.
  Future<DeviceCapability> get() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _inflight ??= _detect().then((cap) {
      _cached = cap;
      _inflight = null;
      return cap;
    });
  }

  /// Synchronous accessor — returns `null` until [get] has completed once.
  /// Use this in build methods where you've already awaited [get] elsewhere
  /// (e.g. in app startup).
  DeviceCapability? get cached => _cached;

  Future<DeviceCapability> _detect() async {
    try {
      if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        final machine = info.utsname.machine;
        final spec = _iPhoneSpec(machine) ?? _iPadSpec(machine);
        final name = info.name.isNotEmpty ? info.name : (info.utsname.machine);
        // Apple Intelligence requires iOS 26+. We can't trust the device's
        // OS version field for a feature check, but it's a useful prefilter.
        final iosMajor = _majorVersion(info.systemVersion);
        final aiSupported = (spec?.aiCapable ?? false) && iosMajor >= 26;
        return DeviceCapability(
          deviceName: name,
          hwMachine: machine,
          chip: spec?.chip ?? AppleChip.unknown,
          chipLabel: spec?.chipLabel ?? 'Unknown',
          ramGb: spec?.ramGb ?? 4.0,
          supportsAppleIntelligence: aiSupported,
          supportsMlx: true,
        );
      }
      if (Platform.isMacOS) {
        final info = await DeviceInfoPlugin().macOsInfo;
        final isAppleSilicon = info.arch.toLowerCase().contains('arm') ||
            (info.model.toLowerCase().contains('mac') &&
                !info.arch.toLowerCase().contains('x86'));
        // RAM in bytes → GB.
        final ramGb = info.memorySize > 0
            ? (info.memorySize / (1024 * 1024 * 1024))
            : 8.0;
        final macSpec = _macSpec(info.model, info.modelName);
        return DeviceCapability(
          deviceName: info.computerName,
          hwMachine: info.model,
          chip: isAppleSilicon
              ? (macSpec?.chip ?? AppleChip.unknown)
              : AppleChip.unknown,
          chipLabel: isAppleSilicon
              ? (macSpec?.chipLabel ?? 'Apple Silicon')
              : 'Intel',
          ramGb: ramGb,
          supportsAppleIntelligence: false,
          supportsMlx: isAppleSilicon,
        );
      }
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        var ramGb = 6.0;
        var supportsVulkan = false;
        var chipLabel = info.hardware;
        var hwMachine = info.hardware;
        try {
          final raw = await _androidChannel.invokeMethod<dynamic>(
            'getAndroidProfile',
          );
          if (raw is Map) {
            final map = raw.cast<String, dynamic>();
            final reported = (map['ramGb'] as num?)?.toDouble();
            if (reported != null && reported > 0.5) {
              ramGb = reported;
            }
            supportsVulkan = map['supportsVulkan'] == true;
            final soc = map['soc'] as String?;
            if (soc != null && soc.isNotEmpty) {
              chipLabel = soc;
              hwMachine = soc;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Android capability channel failed: $e');
          }
        }
        return DeviceCapability(
          deviceName: '${info.manufacturer} ${info.model}',
          hwMachine: hwMachine,
          chip: AppleChip.unknown,
          chipLabel: chipLabel,
          ramGb: ramGb,
          supportsAppleIntelligence: false,
          supportsMlx: false,
          supportsVulkan: supportsVulkan,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('DeviceCapability detect failed: $e');
    }
    return DeviceCapability.unknown;
  }

  /// Verdict for whether [spec] can run on the current device.
  ///
  /// Lenient on purpose: the UI warns with a confirm dialog instead of
  /// hard-blocking downloads/activation.
  ///
  ///   - `tight` if estimated runtime memory > `0.55 * RAM`, or
  ///     [LocalModelSpec.minRamGb] > `0.85 * device RAM`.
  ///   - `tight` if the spec is MLX and the device does not support MLX.
  ///   - `runs`  otherwise.
  ModelFit verdict(LocalModelSpec spec, [DeviceCapability? capOverride]) {
    final cap = capOverride ?? _cached ?? DeviceCapability.unknown;
    if (spec.engine == LocalEngine.mlx && !cap.supportsMlx) {
      return ModelFit.tight;
    }
    final ramMb = cap.ramGb * 1024;
    final runtime = spec.estimatedRuntimeMb;
    // Lenient: warn via dialog instead of hard-blocking downloads/activation.
    if (runtime > ramMb * 0.55 || spec.minRamGb > cap.ramGb * 0.85) {
      return ModelFit.tight;
    }
    return ModelFit.runs;
  }

  /// Verdict for an on-device Stable Diffusion asset.
  ModelFit sdVerdict(LocalSdAssetSpec spec, [DeviceCapability? capOverride]) {
    final cap = capOverride ?? _cached ?? DeviceCapability.unknown;
    if (!cap.supportsMlx && spec.engine == SdEngine.coreml) {
      // Core ML SD needs Apple Silicon / Neural Engine — treat as tight so
      // the UI still allows a confirm dialog rather than a hard block.
      return ModelFit.tight;
    }
    if (spec.minRamGb > cap.ramGb * 0.85) {
      return ModelFit.tight;
    }
    // Disk size is a rough proxy for peak RAM on split-einsum pipelines.
    final approxRuntimeMb = spec.sizeMb * 1.2;
    if (approxRuntimeMb > cap.ramGb * 1024 * 0.55) {
      return ModelFit.tight;
    }
    return ModelFit.runs;
  }

  /// Whether the device can hold both target and draft simultaneously for
  /// speculative decoding. Uses a 70% RAM budget for combined runtime.
  bool canFitBoth(LocalModelSpec target, LocalModelSpec draft,
      [DeviceCapability? capOverride]) {
    final cap = capOverride ?? _cached ?? DeviceCapability.unknown;
    final ramMb = cap.ramGb * 1024;
    final combined = target.estimatedRuntimeMb + draft.estimatedRuntimeMb;
    return combined <= ramMb * 0.70;
  }

  // ─── Static lookup tables ──────────────────────────────────────────

  static int _majorVersion(String v) {
    final dot = v.indexOf('.');
    final head = dot == -1 ? v : v.substring(0, dot);
    return int.tryParse(head) ?? 0;
  }

  static _DeviceSpec? _iPhoneSpec(String m) {
    // Source: theiphonewiki.com / Apple specs.
    // Conservative when uncertain; under-estimate RAM rather than over.
    switch (m) {
      // iPhone 11 series
      case 'iPhone12,1': // 11
      case 'iPhone12,3': // 11 Pro
      case 'iPhone12,5': // 11 Pro Max
        return const _DeviceSpec(AppleChip.a13, 4, aiCapable: false);
      case 'iPhone12,8': // SE 2
        return const _DeviceSpec(AppleChip.a13, 3, aiCapable: false);
      // iPhone 12 series
      case 'iPhone13,1': // 12 mini
        return const _DeviceSpec(AppleChip.a14, 4, aiCapable: false);
      case 'iPhone13,2': // 12
      case 'iPhone13,3': // 12 Pro
      case 'iPhone13,4': // 12 Pro Max
        return const _DeviceSpec(AppleChip.a14, 6, aiCapable: false);
      // iPhone 13 series
      case 'iPhone14,4': // 13 mini
      case 'iPhone14,5': // 13
        return const _DeviceSpec(AppleChip.a15, 4, aiCapable: false);
      case 'iPhone14,2': // 13 Pro
      case 'iPhone14,3': // 13 Pro Max
        return const _DeviceSpec(AppleChip.a15, 6, aiCapable: false);
      case 'iPhone14,6': // SE 3
        return const _DeviceSpec(AppleChip.a15, 4, aiCapable: false);
      // iPhone 14 series
      case 'iPhone14,7': // 14
      case 'iPhone14,8': // 14 Plus
        return const _DeviceSpec(AppleChip.a15, 6, aiCapable: false);
      case 'iPhone15,2': // 14 Pro
      case 'iPhone15,3': // 14 Pro Max
        return const _DeviceSpec(AppleChip.a16, 6, aiCapable: false);
      // iPhone 15 series
      case 'iPhone15,4': // 15
      case 'iPhone15,5': // 15 Plus
        return const _DeviceSpec(AppleChip.a16, 6, aiCapable: false);
      case 'iPhone16,1': // 15 Pro — Apple Intelligence ✓
      case 'iPhone16,2': // 15 Pro Max — Apple Intelligence ✓
        return const _DeviceSpec(AppleChip.a17Pro, 8, aiCapable: true);
      // iPhone 16 series — all four support Apple Intelligence
      case 'iPhone17,3': // 16
      case 'iPhone17,4': // 16 Plus
        return const _DeviceSpec(AppleChip.a18, 8, aiCapable: true);
      case 'iPhone17,1': // 16 Pro
      case 'iPhone17,2': // 16 Pro Max
        return const _DeviceSpec(AppleChip.a18Pro, 8, aiCapable: true);
      // iPhone 17 series (mapped speculatively; safe AI-capable defaults).
      case 'iPhone18,3':
      case 'iPhone18,4':
        return const _DeviceSpec(AppleChip.a19, 8, aiCapable: true);
      case 'iPhone18,1':
      case 'iPhone18,2':
        return const _DeviceSpec(AppleChip.a19Pro, 12, aiCapable: true);
    }
    // Unknown future iPhone — assume modern, AI-capable.
    if (m.startsWith('iPhone')) {
      return const _DeviceSpec(AppleChip.a18, 8, aiCapable: true);
    }
    return null;
  }

  static _DeviceSpec? _iPadSpec(String m) {
    if (!m.startsWith('iPad')) return null;
    // Source: theiphonewiki.com / Apple specs. Conservative when uncertain;
    // RAM is reported as the minimum SKU since storage/RAM tiers differ
    // on Pro models (e.g. 8GB on ≤1TB, 16GB on 2TB+) and we always want
    // the floor for fit checks.
    switch (m) {
      // iPad (entry) — A10/A12/A13/A14 — no AI.
      case 'iPad7,11': // iPad 7 (A10)
      case 'iPad7,12':
        return const _DeviceSpec(AppleChip.unknown, 3, aiCapable: false);
      case 'iPad11,6': // iPad 8 (A12)
      case 'iPad11,7':
        return const _DeviceSpec(AppleChip.unknown, 3, aiCapable: false);
      case 'iPad12,1': // iPad 9 (A13)
      case 'iPad12,2':
        return const _DeviceSpec(AppleChip.a13, 3, aiCapable: false);
      case 'iPad13,18': // iPad 10 (A14)
      case 'iPad13,19':
        return const _DeviceSpec(AppleChip.a14, 4, aiCapable: false);
      case 'iPad15,7': // iPad 11th gen (A16, 2025)
      case 'iPad15,8':
												  return const _DeviceSpec(AppleChip.a16, 6, aiCapable: false);

      // iPad mini.
      case 'iPad11,1': // mini 5 (A12)
      case 'iPad11,2':
        return const _DeviceSpec(AppleChip.unknown, 3, aiCapable: false);
      case 'iPad14,1': // mini 6 (A15)
      case 'iPad14,2':
        return const _DeviceSpec(AppleChip.a15, 4, aiCapable: false);
      case 'iPad16,1': // mini 7 (A17 Pro) — Apple Intelligence ✓
      case 'iPad16,2':
        return const _DeviceSpec(AppleChip.a17Pro, 8, aiCapable: true);

      // iPad Air.
      case 'iPad11,3': // Air 3 (A12)
      case 'iPad11,4':
        return const _DeviceSpec(AppleChip.unknown, 3, aiCapable: false);
      case 'iPad13,1': // Air 4 (A14)
      case 'iPad13,2':
        return const _DeviceSpec(AppleChip.a14, 4, aiCapable: false);
      case 'iPad13,16': // Air 5 (M1)
      case 'iPad13,17':
        return const _DeviceSpec(AppleChip.m1, 8, aiCapable: true);
      case 'iPad14,8': // Air 11" (M2) — AI ✓
      case 'iPad14,9':
        return const _DeviceSpec(AppleChip.m2, 8, aiCapable: true);
      case 'iPad14,10': // Air 13" (M2) — AI ✓
      case 'iPad14,11':
        return const _DeviceSpec(AppleChip.m2, 8, aiCapable: true);
      case 'iPad15,3': // Air 11" (M3, 2025) — AI ✓
      case 'iPad15,4':
        return const _DeviceSpec(AppleChip.m3, 8, aiCapable: true);
      case 'iPad15,5': // Air 13" (M3, 2025) — AI ✓
      case 'iPad15,6':
        return const _DeviceSpec(AppleChip.m3, 8, aiCapable: true);

      // iPad Pro.
      case 'iPad8,1': // Pro 11" 1st gen (A12X)
      case 'iPad8,2':
      case 'iPad8,3':
      case 'iPad8,4':
        return const _DeviceSpec(AppleChip.unknown, 4, aiCapable: false);
      case 'iPad8,5': // Pro 12.9" 3rd gen (A12X)
      case 'iPad8,6':
      case 'iPad8,7':
      case 'iPad8,8':
        return const _DeviceSpec(AppleChip.unknown, 4, aiCapable: false);
      case 'iPad8,9': // Pro 11" 2nd gen (A12Z)
      case 'iPad8,10':
      case 'iPad8,11': // Pro 12.9" 4th gen (A12Z)
      case 'iPad8,12':
        return const _DeviceSpec(AppleChip.unknown, 6, aiCapable: false);
      case 'iPad13,4': // Pro 11" 3rd gen (M1)
      case 'iPad13,5':
      case 'iPad13,6':
      case 'iPad13,7':
        return const _DeviceSpec(AppleChip.m1, 8, aiCapable: true);
      case 'iPad13,8': // Pro 12.9" 5th gen (M1)
      case 'iPad13,9':
      case 'iPad13,10':
      case 'iPad13,11':
        return const _DeviceSpec(AppleChip.m1, 8, aiCapable: true);
      case 'iPad14,3': // Pro 11" 4th gen (M2)
      case 'iPad14,4':
        return const _DeviceSpec(AppleChip.m2, 8, aiCapable: true);
      case 'iPad14,5': // Pro 12.9" 6th gen (M2)
      case 'iPad14,6':
        return const _DeviceSpec(AppleChip.m2, 8, aiCapable: true);
      case 'iPad16,3': // Pro 11" (M4) — AI ✓
      case 'iPad16,4':
        return const _DeviceSpec(AppleChip.m4, 8, aiCapable: true);
      case 'iPad16,5': // Pro 13" (M4) — AI ✓
      case 'iPad16,6':
        return const _DeviceSpec(AppleChip.m4, 8, aiCapable: true);
      // iPad Pro M5 — 8 GB (256/512 GB) or 16 GB (1/2 TB). Use 16 GB for
      // fit checks; [ramDisplayLabel] shows the 8–16 GB range in the UI.
      case 'iPad17,1':
      case 'iPad17,2':
      case 'iPad17,3':
      case 'iPad17,4':
        return const _DeviceSpec(AppleChip.m5, 16, aiCapable: true);
    }

    // Unknown / future iPad. Bias to AI-capable Apple-Silicon assumption so
    // M-series demos don't get locked out of features when the lookup table
    // is stale.
    final lower = m.toLowerCase();
    if (lower.startsWith('ipad17,') || lower.startsWith('ipad18,')) {
      return const _DeviceSpec(AppleChip.m5, 16, aiCapable: true);
    }
    if (lower.startsWith('ipad16,')) {
      return const _DeviceSpec(AppleChip.m4, 8, aiCapable: true);
    }
    if (lower.startsWith('ipad15,')) {
      return const _DeviceSpec(AppleChip.m3, 8, aiCapable: true);
    }
    if (lower.startsWith('ipad14,')) {
      return const _DeviceSpec(AppleChip.m2, 8, aiCapable: true);
    }
    if (lower.startsWith('ipad13,')) {
      return const _DeviceSpec(AppleChip.m1, 8, aiCapable: true);
    }
    // Truly unknown old iPad — safe conservative defaults.
    return const _DeviceSpec(AppleChip.unknown, 4, aiCapable: false);
  }

  static _DeviceSpec? _macSpec(String model, String modelName) {
    // Prefer explicit chip text from Apple's marketing name when present.
    final fromName = _chipLabelFromText(modelName);
    if (fromName != null) {
      return _DeviceSpec(fromName.$1, 8, chipLabelOverride: fromName.$2);
    }

    final m = model.toUpperCase();
    switch (m) {
      // MacBook Pro M4 (2024)
      case 'MAC16,1':
        return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4');
      case 'MAC16,2':
        return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4 Pro');
      case 'MAC16,3':
        return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4 Max');
      case 'MAC16,5':
        return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4 Pro');
      case 'MAC16,6':
        return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4 Max');
      // MacBook Pro M3 (2023)
      case 'MAC15,3':
      case 'MAC15,4':
        return const _DeviceSpec(AppleChip.m3, 8, chipLabelOverride: 'M3 Pro');
      case 'MAC15,6':
      case 'MAC15,7':
        return const _DeviceSpec(AppleChip.m3, 8, chipLabelOverride: 'M3 Max');
      case 'MAC15,8':
      case 'MAC15,9':
        return const _DeviceSpec(AppleChip.m3, 8, chipLabelOverride: 'M3 Pro');
      case 'MAC15,10':
      case 'MAC15,11':
        return const _DeviceSpec(AppleChip.m3, 8, chipLabelOverride: 'M3 Max');
      // MacBook Pro / Air M2
      case 'MAC14,5':
      case 'MAC14,6':
      case 'MAC14,9':
      case 'MAC14,10':
        return const _DeviceSpec(AppleChip.m2, 8, chipLabelOverride: 'M2');
      case 'MAC14,7':
      case 'MAC14,8':
        return const _DeviceSpec(AppleChip.m2, 8, chipLabelOverride: 'M2 Pro');
      case 'MAC14,11':
      case 'MAC14,12':
        return const _DeviceSpec(AppleChip.m2, 8, chipLabelOverride: 'M2 Max');
      // MacBook Pro M1
      case 'MACBOOKPRO17,1':
      case 'MACBOOKPRO18,1':
      case 'MACBOOKPRO18,2':
      case 'MACBOOKPRO18,3':
      case 'MACBOOKPRO18,4':
        return const _DeviceSpec(AppleChip.m1, 8, chipLabelOverride: 'M1 Pro');
      case 'MAC13,1':
      case 'MAC13,2':
        return const _DeviceSpec(AppleChip.m1, 8, chipLabelOverride: 'M1 Pro');
      case 'MAC13,3':
      case 'MAC13,4':
        return const _DeviceSpec(AppleChip.m1, 8, chipLabelOverride: 'M1 Max');
      // Mac Studio / mini / iMac M-series (conservative chip family)
      case 'MAC13,5':
      case 'MAC13,6':
      case 'MAC13,7':
        return const _DeviceSpec(AppleChip.m2, 8, chipLabelOverride: 'M2 Ultra');
      case 'MAC14,13':
      case 'MAC14,14':
        return const _DeviceSpec(AppleChip.m2, 8, chipLabelOverride: 'M2 Pro');
      case 'MAC14,15':
        return const _DeviceSpec(AppleChip.m2, 8, chipLabelOverride: 'M2');
      case 'MAC15,12':
      case 'MAC15,13':
        return const _DeviceSpec(AppleChip.m3, 8, chipLabelOverride: 'M3');
      case 'MAC16,7':
      case 'MAC16,8':
        return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4');
      case 'MAC16,9':
      case 'MAC16,10':
      case 'MAC16,11':
      case 'MAC16,12':
        return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4');
    }

    // Prefix fallbacks for unknown future Mac identifiers.
    if (m.startsWith('MAC17,')) {
      return const _DeviceSpec(AppleChip.m5, 8, chipLabelOverride: 'M5');
    }
    if (m.startsWith('MAC16,')) {
      return const _DeviceSpec(AppleChip.m4, 8, chipLabelOverride: 'M4');
    }
    if (m.startsWith('MAC15,')) {
      return const _DeviceSpec(AppleChip.m3, 8, chipLabelOverride: 'M3');
    }
    if (m.startsWith('MAC14,')) {
      return const _DeviceSpec(AppleChip.m2, 8, chipLabelOverride: 'M2');
    }
    if (m.startsWith('MAC13,') || m.startsWith('MACBOOKPRO')) {
      return const _DeviceSpec(AppleChip.m1, 8, chipLabelOverride: 'M1');
    }
    return null;
  }

  /// Parses strings like "MacBook Pro (16-inch, Nov 2024)" or marketing copy
  /// that embeds "M4 Max".
  static (AppleChip, String)? _chipLabelFromText(String text) {
    final match = RegExp(
      r'\b(M[1-9](?:\s+(Pro|Max|Ultra))?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    final label = match.group(1)!;
    final normalized = label.replaceAll(RegExp(r'\s+'), ' ');
    final parts = normalized.split(' ');
    final generation = parts.first.toUpperCase();
    final chip = switch (generation) {
      'M1' => AppleChip.m1,
      'M2' => AppleChip.m2,
      'M3' => AppleChip.m3,
      'M4' => AppleChip.m4,
      'M5' => AppleChip.m5,
      _ => AppleChip.unknown,
    };
    if (chip == AppleChip.unknown) return null;
    return (chip, normalized);
  }
}

class _DeviceSpec {
  final AppleChip chip;
  final double ramGb;
  final bool aiCapable;
  final String? chipLabelOverride;

  String get chipLabel => chipLabelOverride ?? _defaultChipLabel(chip);

  const _DeviceSpec(
    this.chip,
    double ram, {
    this.aiCapable = false,
    this.chipLabelOverride,
  }) : ramGb = ram + 0.0;

  static String _defaultChipLabel(AppleChip chip) {
    return switch (chip) {
      AppleChip.a17Pro => 'A17 Pro',
      AppleChip.a18Pro => 'A18 Pro',
      AppleChip.a19Pro => 'A19 Pro',
      AppleChip.a19 => 'A19',
      AppleChip.a18 => 'A18',
      AppleChip.a16 => 'A16',
      AppleChip.a15 => 'A15',
      AppleChip.a14 => 'A14',
      AppleChip.a13 => 'A13',
      AppleChip.m1 => 'M1',
      AppleChip.m2 => 'M2',
      AppleChip.m3 => 'M3',
      AppleChip.m4 => 'M4',
      AppleChip.m5 => 'M5',
      AppleChip.unknown => 'Unknown',
    };
  }
}
