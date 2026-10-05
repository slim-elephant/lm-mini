import '../models/local_model_spec.dart';
import 'device_capability_service.dart';
import 'local_model_catalog.dart';
import 'local_model_download_service.dart';

/// Result of asking "can/should we speculatively decode this target?"
enum SpeculativeReadiness {
  /// Spec doesn't reference a draft; no speculative pairing possible.
  noDraftPair,

  /// Draft pair exists but the device can't host target+draft simultaneously.
  insufficientMemory,

  /// Draft pair exists but the draft model isn't downloaded yet.
  draftMissing,

  /// All checks passed. The endpoint should pass the draft model path.
  ready,
}

/// Decision returned by [SpeculativeDecodingController.resolve].
class SpeculativeDecision {
  final SpeculativeReadiness readiness;

  /// Local path to the draft model file. Only non-null when
  /// [readiness] is [SpeculativeReadiness.ready].
  final String? draftPath;

  /// Human-readable diagnostic for the Settings/Local Models UI.
  final String? reason;

  const SpeculativeDecision._(this.readiness, {this.draftPath, this.reason});

  bool get isReady => readiness == SpeculativeReadiness.ready;
}

/// Centralises the rules for enabling speculative decoding on a target
/// model. Pure logic — no IO, no notifyListeners — so it can be unit tested.
///
/// Speculative decoding is **Pro-only**. Free-tier callers should never
/// reach this controller; the subscription check belongs in the UI/provider
/// layer that owns `SubscriptionService`.
class SpeculativeDecodingController {
  SpeculativeDecodingController._();
  static final SpeculativeDecodingController instance =
      SpeculativeDecodingController._();

  /// Decide whether [target] should run with its paired draft model.
  ///
  /// Independent of toggles — the caller (e.g. `ChatProvider`) layers the
  /// user's `AppSettings.speculativeDecodingEnabled` preference on top.
  Future<SpeculativeDecision> resolve(LocalModelSpec target) async {
    final draftId = target.draftModelId;
    if (draftId == null || draftId.isEmpty) {
      return const SpeculativeDecision._(
        SpeculativeReadiness.noDraftPair,
        reason: 'This model has no paired draft.',
      );
    }
    final draft = LocalModelCatalog.byId(draftId);
    if (draft == null) {
      return const SpeculativeDecision._(
        SpeculativeReadiness.noDraftPair,
        reason: 'Draft model not found in catalog.',
      );
    }

    final cap = await DeviceCapabilityService.instance.get();
    if (!DeviceCapabilityService.instance.canFitBoth(target, draft, cap)) {
      return SpeculativeDecision._(
        SpeculativeReadiness.insufficientMemory,
        reason:
            'Device has only ${cap.ramGb.toStringAsFixed(1)} GB RAM — not '
            'enough for target + draft.',
      );
    }

    final downloads = LocalModelDownloadService.instance;
    await downloads.init();
    final draftEntry = downloads.entryById(draftId);
    if (draftEntry == null ||
        draftEntry.status != LocalModelStatus.ready ||
        draftEntry.localPath == null) {
      return const SpeculativeDecision._(
        SpeculativeReadiness.draftMissing,
        reason: 'Draft model has not been downloaded yet.',
      );
    }

    return SpeculativeDecision._(
      SpeculativeReadiness.ready,
      draftPath: draftEntry.localPath,
      reason: 'Speculative decoding active with ${draft.displayName}.',
    );
  }

  /// Convenience: returns the paired draft spec for a given target id,
  /// or null if the target has no paired draft.
  LocalModelSpec? draftFor(String targetId) {
    final target = LocalModelCatalog.byId(targetId);
    final draftId = target?.draftModelId;
    if (draftId == null) return null;
    return LocalModelCatalog.byId(draftId);
  }
}
