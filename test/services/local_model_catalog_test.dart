import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/local_model_spec.dart';
import 'package:lm_mini/services/device_capability_service.dart';
import 'package:lm_mini/services/local_model_catalog.dart';
import 'package:lm_mini/services/lm_studio_discovery_service.dart';

void main() {
  group('LocalModelCatalog desktop helpers', () {
    test('modelLine groups MLX and GGUF of the same named model', () {
      final mlx =
          LocalModelCatalog.byId('mlx-community/lfm2.5-2.6b-4bit/mlx')!;
      final gguf = LocalModelCatalog.byId('liquidai/lfm2.5-2.6b/Q4_K_M')!;
      expect(LocalModelCatalog.modelLine(mlx), 'LFM 2.5 2.6B');
      expect(LocalModelCatalog.modelLine(gguf), 'LFM 2.5 2.6B');
      expect(LocalModelCatalog.quantLabel(mlx), '4-bit');
      expect(LocalModelCatalog.quantLabel(gguf), 'Q4_K_M');
    });

    test('MoE stream catalog uses working-set RAM not file size', () {
      final spec =
          LocalModelCatalog.byId('qwen/qwen3-30b-a3b/Q4_K_M/stream')!;
      expect(spec.engine.name, 'moeStream');
      expect(spec.sizeMb, greaterThan(10000));
      expect(spec.estimatedRuntimeMb, lessThan(4000));
      expect(spec.minRamGb, lessThanOrEqualTo(4.0));
      expect(spec.isGguf, isTrue);
      expect(LocalModelCatalog.isListed(spec), isFalse);
    });

    test('hides phone-class models under 3B', () {
      final tiny = LocalModelCatalog.byId('qwen/qwen3.5-2b/Q4_K_M')!;
      final eight = LocalModelCatalog.byId('qwen/qwen3.5-9b/Q4_K_M')!;
      expect(LocalModelCatalog.isPhoneClass(tiny), isTrue);
      expect(LocalModelCatalog.isPhoneClass(eight), isFalse);
    });

    test('recommendedForVram picks ~70% of 36 GB unified memory', () {
      const cap = DeviceCapability(
        deviceName: 'Mac',
        hwMachine: '',
        chip: AppleChip.m4,
        chipLabel: 'M4',
        ramGb: 36,
        supportsAppleIntelligence: false,
        supportsMlx: true,
      );
      final pick = LocalModelCatalog.recommendedForVram(cap);
      expect(pick, isNotNull);
      expect(pick!.paramsB, greaterThanOrEqualTo(14));
      expect(pick.estimatedRuntimeMb, lessThanOrEqualTo(36 * 1024 * 0.70));
      expect(LocalModelCatalog.isPhoneClass(pick), isFalse);
    });

    test('recommendedForVram on 16 GB prefers a 12–14B class model', () {
      const cap = DeviceCapability(
        deviceName: 'Mac',
        hwMachine: '',
        chip: AppleChip.m3,
        chipLabel: 'M3',
        ramGb: 16,
        supportsAppleIntelligence: false,
        supportsMlx: true,
      );
      final pick = LocalModelCatalog.recommendedForVram(cap);
      expect(pick, isNotNull);
      expect(pick!.paramsB, inInclusiveRange(8, 16));
      expect(pick.estimatedRuntimeMb, lessThanOrEqualTo(16 * 1024 * 0.70));
    });
  });

  group('LocalModelCatalog Oct 2026 refresh', () {
    test('ids are unique', () {
      final ids = LocalModelCatalog.entries.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('free pick is Qwen 3.5 2B on GGUF', () {
      final free = LocalModelCatalog.freeSlot;
      expect(free.id, 'qwen/qwen3.5-2b/Q4_K_M');
      expect(free.engine.name, 'fllama');
    });

    test('no MLX builds for families the bundled MLX cannot load', () {
      for (final e in LocalModelCatalog.entries) {
        if (e.engine.name != 'mlx') continue;
        final id = e.id.toLowerCase();
        for (final unsupported in ['qwen3.5', 'gemma-4', 'ministral']) {
          expect(id.contains(unsupported), isFalse, reason: e.id);
        }
      }
    });

    test('GGUF entries name their file; vision entries carry a projector', () {
      for (final e in LocalModelCatalog.entries) {
        if (e.engine.name == 'fllama') {
          expect(e.hfFile, isNotNull, reason: e.id);
          expect(e.hfFile!.endsWith('.gguf'), isTrue, reason: e.id);
          if (e.supportsVision) {
            expect(e.mmprojHfFile, isNotNull, reason: e.id);
          }
        }
      }
    });

    test('only current families are listed', () {
      const families = {
        'Qwen', 'Google', 'Liquid AI', 'Mistral', 'IBM', 'Hugging Face',
        'OpenBMB', 'PrismML',
      };
      for (final e in LocalModelCatalog.entries.where(LocalModelCatalog.isListed)) {
        expect(families, contains(LocalModelCatalog.familyGroup(e)),
            reason: e.id);
      }
    });
  });

  group('LmStudioDiscoveryService', () {
    test('treats loopback as this machine', () {
      expect(LmStudioDiscoveryService.isLoopbackHost('127.0.0.1'), isTrue);
      expect(LmStudioDiscoveryService.isLoopbackHost('localhost'), isTrue);
      expect(LmStudioDiscoveryService.isLoopbackHost('192.168.1.10'), isFalse);
    });
  });

  test('free tier is 3B and under; bigger catalog models need Pro', () {
    for (final e in LocalModelCatalog.entries) {
      expect(LocalModelCatalog.isFreeTier(e), e.paramsB <= 3.0 || e.isFreeSlot,
          reason: e.id);
    }
    final byId = {for (final e in LocalModelCatalog.entries) e.id: e};
    expect(LocalModelCatalog.isFreeTier(byId['qwen/qwen3.5-4b/Q4_K_M']!),
        isFalse);
    expect(
        LocalModelCatalog.isFreeTier(byId['google/gemma-4-e4b-it/Q4_K_M']!),
        isFalse);
    expect(LocalModelCatalog.isFreeTier(byId['qwen/qwen3.5-2b/Q4_K_M']!),
        isTrue);
  });

  test('Apple chips get free MLX builds around 3B', () {
    final freeMlx = LocalModelCatalog.entries
        .where((e) => e.engine == LocalEngine.mlx && e.isFreeSlot)
        .toList();
    expect(freeMlx.map((e) => e.id), containsAll([
      'mlx-community/lfm2.5-2.6b-4bit/mlx',
      'mlx-community/smollm3-3b-4bit/mlx',
      'ibm-granite/granite-4.2-3b-q4-mlx/mlx',
    ]));
    for (final e in freeMlx) {
      expect(e.tier, LocalModelTier.free);
      expect(LocalModelCatalog.isFreeTier(e), isTrue);
    }
    // The first free slot (the default free download) stays the GGUF pick.
    expect(LocalModelCatalog.freeSlot.engine, LocalEngine.fllama);
  });
}
