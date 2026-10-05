import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_capability_service.dart';
import 'local_sd_asset_catalog.dart';
import 'on_device_sd_endpoint.dart';

/// Bundled Core ML Stable Diffusion variants offered to Pro users.
///
/// Deprecated in favor of the HF catalog + [OnDeviceSdEndpoint]. Kept as a
/// thin compatibility wrapper so older call sites keep compiling.
@Deprecated('Use OnDeviceSdEndpoint + LocalSdAssetCatalog instead')
enum SdCoreMlModel {
  /// Stable Diffusion 1.5, Apple's Core ML conversion. ~1.7 GB on disk.
  sd15,

  /// SDXL Turbo, Core ML conversion. ~6 GB on disk; M-series only.
  sdxlTurbo,
}

@Deprecated('Use OnDeviceSdEndpoint + LocalSdAssetCatalog instead')
extension SdCoreMlModelInfo on SdCoreMlModel {
  String get displayName => switch (this) {
        SdCoreMlModel.sd15 => 'Stable Diffusion 1.5 (Core ML)',
        SdCoreMlModel.sdxlTurbo => 'SDXL Turbo (Core ML)',
      };
  double get minRamGb => switch (this) {
        SdCoreMlModel.sd15 => 6.0,
        SdCoreMlModel.sdxlTurbo => 12.0,
      };

  String get catalogCheckpointId => switch (this) {
        SdCoreMlModel.sd15 => 'apple/coreml-sd-1-5/split-einsum',
        SdCoreMlModel.sdxlTurbo => 'apple/coreml-sdxl-turbo/split-einsum',
      };
}

/// On-device image generation via Core ML Stable Diffusion.
///
/// Deprecated wrapper around [OnDeviceSdEndpoint]. Prefer calling that
/// service (and the HF asset catalog) directly.
@Deprecated('Use OnDeviceSdEndpoint instead')
class SdCoreMlService {
  SdCoreMlService._();
  static final SdCoreMlService instance = SdCoreMlService._();

  Future<bool> canRun(SdCoreMlModel model) async {
    if (!Platform.isIOS) return false;
    final cap = await DeviceCapabilityService.instance.get();
    if (!cap.supportsMlx) return false;
    if (cap.ramGb + 0.1 < model.minRamGb) return false;
    return true;
  }

  Future<bool> isAvailable(SdCoreMlModel model) async {
    if (!await canRun(model)) return false;
    final spec = LocalSdAssetCatalog.findById(model.catalogCheckpointId);
    if (spec == null) return false;
    return OnDeviceSdEndpoint.instance.isNativeAvailable();
  }

  Future<Uint8List> generate({
    required SdCoreMlModel model,
    required String prompt,
    String? negativePrompt,
    int? steps,
    double? guidanceScale,
    int width = 512,
    int height = 512,
    int? seed,
  }) async {
    try {
      final result = await OnDeviceSdEndpoint.instance.txt2img(
        OnDeviceSdRequest(
          prompt: prompt,
          negativePrompt: negativePrompt,
          steps: steps ?? 20,
          cfgScale: guidanceScale ?? 7.0,
          width: width,
          height: height,
          seed: seed,
          checkpointAssetId: model.catalogCheckpointId,
        ),
      );
      return result.pngBytes;
    } on MissingPluginException {
      throw StateError(
          'On-device SD native bridge is not bundled in this build.');
    } catch (e) {
      debugPrint('SdCoreMlService.generate failed: $e');
      rethrow;
    }
  }
}
