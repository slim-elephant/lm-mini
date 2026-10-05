import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/local_model_spec.dart';
import 'package:lm_mini/services/device_capability_service.dart';

LocalModelSpec _spec({
  required String id,
  required int sizeMb,
  double paramsB = 1.5,
  LocalEngine engine = LocalEngine.fllama,
  double minRamGb = 2.0,
}) =>
    LocalModelSpec(
      id: id,
      displayName: id,
      hfRepo: 'test/$id',
      hfFile: '$id.gguf',
      sizeMb: sizeMb,
      paramsB: paramsB,
      quantization: 'Q4_K_M',
      engine: engine,
      tier: LocalModelTier.free,
      chatTemplate: 'auto',
      minRamGb: minRamGb,
    );

DeviceCapability _device({
  required double ramGb,
  bool mlx = true,
}) =>
    DeviceCapability(
      deviceName: 'TestDevice',
      hwMachine: 'iPhone0,0',
      chip: AppleChip.a17Pro,
      chipLabel: 'A17 Pro',
      ramGb: ramGb,
      supportsAppleIntelligence: false,
      supportsMlx: mlx,
    );

void main() {
  final svc = DeviceCapabilityService.instance;

  group('DeviceCapabilityService.verdict', () {
    test('runs comfortably when well under the 60% RAM line', () {
      // 8 GB device, 1 GB model file → ~1.3 GB runtime, well below 60%.
      final fit = svc.verdict(
        _spec(id: 'small', sizeMb: 1024),
        _device(ramGb: 8.0),
      );
      expect(fit, ModelFit.runs);
    });

    test('tight between 60% and 80% of RAM', () {
      // 4 GB device → 4096 MB. 60% = 2458 MB, 80% = 3277 MB.
      // 2400 MB GGUF → 2400 * 1.30 = 3120 MB runtime → tight.
      final fit = svc.verdict(
        _spec(id: 'mid', sizeMb: 2400),
        _device(ramGb: 4.0),
      );
      expect(fit, ModelFit.tight);
    });

    test('tight when runtime exceeds 55% of RAM (no hard block)', () {
      // 4 GB device, 3000 MB file → 3900 MB runtime → tight (warn, don't block).
      final fit = svc.verdict(
        _spec(id: 'large', sizeMb: 3000),
        _device(ramGb: 4.0),
      );
      expect(fit, ModelFit.tight);
    });

    test('MLX model is tight on non-MLX devices regardless of fit', () {
      final fit = svc.verdict(
        _spec(id: 'mlx-small', sizeMb: 500, engine: LocalEngine.mlx),
        _device(ramGb: 16.0, mlx: false),
      );
      expect(fit, ModelFit.tight);
    });

    test('minRamGb gate marks tiny models tight on tiny devices', () {
      // 3 GB device, tiny model but spec demands 6 GB → tight.
      final fit = svc.verdict(
        _spec(id: 'demanding', sizeMb: 100, minRamGb: 6.0),
        _device(ramGb: 3.0),
      );
      expect(fit, ModelFit.tight);
    });
  });

  group('DeviceCapabilityService.canFitBoth', () {
    test('returns true when target+draft fit under 70% RAM', () {
      // 8 GB device → 8192 MB. 70% = 5734 MB.
      // 2 GB target * 1.30 = 2662, 0.5 GB draft * 1.30 = 666 → 3328 MB total.
      final target = _spec(id: 'tgt', sizeMb: 2048);
      final draft = _spec(id: 'drf', sizeMb: 512);
      expect(svc.canFitBoth(target, draft, _device(ramGb: 8.0)), isTrue);
    });

    test('returns false when combined exceeds 70% RAM', () {
      // 4 GB device → 4096 MB. 70% = 2867 MB.
      // 2 GB target * 1.30 = 2662, 0.4 GB draft * 1.30 = 533 → 3195 MB.
      final target = _spec(id: 'tgt', sizeMb: 2048);
      final draft = _spec(id: 'drf', sizeMb: 400);
      expect(svc.canFitBoth(target, draft, _device(ramGb: 4.0)), isFalse);
    });
  });
}
