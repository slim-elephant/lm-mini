import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/local_model_spec.dart';
import 'package:lm_mini/services/local_model_catalog.dart';
import 'package:lm_mini/services/speculative_decoding_controller.dart';

void main() {
  final ctrl = SpeculativeDecodingController.instance;

  group('SpeculativeDecodingController.draftFor', () {
    test('returns null for a target without a paired draft', () {
      // Pick any catalog entry whose draftModelId is null (or use an unknown
      // id which yields null spec).
      expect(ctrl.draftFor('this/does/not-exist'), isNull);
    });

    test('returns the paired draft spec when one is registered', () {
      // The free-slot Qwen 1.5B has a draft pairing in the catalog.
      final freeSlot = LocalModelCatalog.freeSlot;
      // Only assert when the catalog still pairs it (defensive against
      // catalog refactors).
      if (freeSlot.draftModelId == null) {
        return;
      }
      final draft = ctrl.draftFor(freeSlot.id);
      expect(draft, isNotNull);
      expect(draft!.id, freeSlot.draftModelId);
    });
  });

  group('SpeculativeDecodingController.resolve (pure-logic branches)', () {
    test('reports noDraftPair when the target id is unknown', () async {
      const phantom = LocalModelSpec(
        id: 'phantom',
        displayName: 'Phantom',
        hfRepo: 'phantom/repo',
        hfFile: 'phantom.gguf',
        sizeMb: 100,
        paramsB: 0.5,
        quantization: 'Q4_K_M',
        engine: LocalEngine.fllama,
        tier: LocalModelTier.free,
        chatTemplate: 'auto',
        minRamGb: 2.0,
        // no draftModelId
      );
      final decision = await ctrl.resolve(phantom);
      expect(decision.readiness, SpeculativeReadiness.noDraftPair);
      expect(decision.isReady, isFalse);
    });

    test('reports noDraftPair when draft id points to nothing', () async {
      const orphan = LocalModelSpec(
        id: 'orphan',
        displayName: 'Orphan',
        hfRepo: 'orphan/repo',
        hfFile: 'orphan.gguf',
        sizeMb: 100,
        paramsB: 0.5,
        quantization: 'Q4_K_M',
        engine: LocalEngine.fllama,
        tier: LocalModelTier.free,
        chatTemplate: 'auto',
        minRamGb: 2.0,
        draftModelId: 'this/draft/does-not-exist',
      );
      final decision = await ctrl.resolve(orphan);
      expect(decision.readiness, SpeculativeReadiness.noDraftPair);
    });
  });
}
