import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/device_capability_service.dart';
import 'package:lm_mini/services/local_model_catalog.dart';
import 'package:lm_mini/services/lm_studio_discovery_service.dart';

void main() {
  group('LocalModelCatalog desktop helpers', () {
    test('modelLine groups MLX and GGUF of the same named model', () {
      final mlx = LocalModelCatalog.byId('mlx-community/qwen3-8b-4bit/mlx')!;
      final gguf = LocalModelCatalog.byId('qwen/qwen3-8b/Q4_K_M')!;
      expect(LocalModelCatalog.modelLine(mlx), 'Qwen 3 8B');
      expect(LocalModelCatalog.modelLine(gguf), 'Qwen 3 8B');
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
      final tiny = LocalModelCatalog.byId('qwen/qwen3-1.7b/Q4_K_M')!;
      final eight = LocalModelCatalog.byId('qwen/qwen3-8b/Q4_K_M')!;
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

  group('LmStudioDiscoveryService', () {
    test('treats loopback as this machine', () {
      expect(LmStudioDiscoveryService.isLoopbackHost('127.0.0.1'), isTrue);
      expect(LmStudioDiscoveryService.isLoopbackHost('localhost'), isTrue);
      expect(LmStudioDiscoveryService.isLoopbackHost('192.168.1.10'), isFalse);
    });
  });
}
