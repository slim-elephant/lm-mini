import '../models/app_settings.dart';
import '../utils/comfyui_catalog.dart';
import '../utils/image_gen_unreachable_error.dart';
import 'comfyui_service.dart';
import 'image_generation_service.dart';
import 'local_sd_asset_download_service.dart';
import 'on_device_sd_endpoint.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Image Generation Facade
// ═══════════════════════════════════════════════════════════════════════════
//
// Thin routing layer over AUTOMATIC1111, ComfyUI, and on-device Core ML so
// call sites can generate an image with a single call regardless of which
// backend the user has selected under Settings → Image Generation.
// ═══════════════════════════════════════════════════════════════════════════

String imageGenBackendLabel(AppSettings settings) {
  switch (settings.imageGenProvider) {
    case 'comfyui':
      return 'ComfyUI';
    case 'onDevice':
      return 'On-device';
    default:
      return 'AUTOMATIC1111';
  }
}

/// Fail fast when ComfyUI / A1111 is down instead of waiting on a 10-minute
/// txt2img / prompt timeout.
Future<void> ensureImageBackendReachable(AppSettings settings) async {
  if (settings.imageGenProvider == 'onDevice') return;
  final label = imageGenBackendLabel(settings);
  final url = settings.effectiveImageGenUrl.trim();
  if (url.isEmpty) {
    throw ImageGenUnreachableError(providerLabel: label, url: '');
  }
  String? err;
  try {
    err = await testBackendConnection(settings).timeout(
      const Duration(seconds: 8),
      onTimeout: () => 'Timed out after 8 seconds',
    );
  } catch (e) {
    err = e.toString();
  }
  if (err != null && err.trim().isNotEmpty) {
    final parsed = ImageGenUnreachableError.parse(err);
    throw ImageGenUnreachableError(
      providerLabel: parsed?.providerLabel ?? label,
      url: url,
      detail: err,
      kind: parsed?.kind ?? ImageGenUnreachableKind.down,
    );
  }
}

/// Dispatch a text-to-image generation request to whichever backend is
/// currently selected in [AppSettings.imageGenProvider].
Future<GeneratedImage> generateImageForSettings({
  required AppSettings settings,
  required Txt2ImgParams params,
  void Function(GenerationProgress)? onProgress,
}) async {
  if (settings.imageGenProvider == 'onDevice') {
    return _generateOnDevice(settings, params, onProgress);
  }

  await ensureImageBackendReachable(settings);

  final url = settings.effectiveImageGenUrl;
  final headers = settings.imageGenRelayHeaders;

  if (settings.imageGenProvider == 'comfyui') {
    return ComfyUIService().generateImage(
      url,
      params,
      workflowJson: settings.comfyUiWorkflowJson,
      workflowPath: settings.comfyUiWorkflowPath,
      checkpoint: _checkpointFrom(settings),
      configuredClientId: settings.comfyUiClientId,
      onProgress: onProgress,
      headers: headers,
      followFormSampler: settings.comfyUiControlsLoadedFrom != null &&
          settings.comfyUiControlsLoadedFrom ==
              comfyWorkflowSettingsKey(
                settings.comfyUiWorkflowPath,
                settings.comfyUiWorkflowJson,
              ),
      workflowFields: settings.comfyUiWorkflowFields,
      saveWorkflowName: settings.comfyUiWorkflowSaveName,
    );
  }

  return ImageGenerationService().generateImage(
    url,
    params,
    onProgress: onProgress,
    headers: headers,
  );
}

Future<GeneratedImage> _generateOnDevice(
  AppSettings settings,
  Txt2ImgParams params,
  void Function(GenerationProgress)? onProgress,
) async {
  final checkpointId = settings.selectedLocalSdCheckpointId;
  if (checkpointId == null || checkpointId.isEmpty) {
    throw StateError(
        'No on-device SD checkpoint selected. Open Settings → Image Generation '
        '→ Browse on-device SD models and tap Use on a downloaded checkpoint.');
  }

  final result = await OnDeviceSdEndpoint.instance.txt2img(
    OnDeviceSdRequest(
      prompt: params.prompt,
      negativePrompt: params.negativePrompt,
      steps: params.steps,
      cfgScale: params.cfgScale,
      width: params.width,
      height: params.height,
      seed: params.seed < 0 ? null : params.seed,
      checkpointAssetId: checkpointId,
    ),
    onProgress: onProgress == null
        ? null
        : (p) => onProgress(GenerationProgress(progress: p, etaSeconds: 0)),
  );

  return GeneratedImage(
    bytes: result.pngBytes,
    info: '{"seed":${result.seed},"on_device":true}',
    seed: result.seed,
  );
}

/// Refresh model/sampler/scheduler lists for whichever provider is active.
Future<void> refreshBackendForSettings(AppSettings settings) async {
  if (settings.imageGenProvider == 'onDevice') return;

  final url = settings.effectiveImageGenUrl;
  final headers = settings.imageGenRelayHeaders;
  if (url.isEmpty) return;

  if (settings.imageGenProvider == 'comfyui') {
    await ComfyUIService().refreshAll(url, headers: headers);
  } else {
    await ImageGenerationService().refreshAll(url, headers: headers);
  }
}

/// Test connectivity to the active image-gen backend.
/// Returns null on success, or an error message string.
Future<String?> testBackendConnection(AppSettings settings) async {
  if (settings.imageGenProvider == 'onDevice') {
    if (!OnDeviceSdEndpoint.instance.isPlatformSupported) {
      return 'On-device SD is only available on iOS / iPadOS.';
    }
    final id = settings.selectedLocalSdCheckpointId;
    if (id == null || id.isEmpty) {
      return 'Select a downloaded on-device checkpoint first.';
    }
    final entry = LocalSdAssetDownloadService.instance.entryById(id);
    if (entry == null ||
        entry.status != LocalSdAssetStatus.ready ||
        entry.localPath == null) {
      return 'Checkpoint is not downloaded yet.';
    }
    try {
      final ok = await OnDeviceSdEndpoint.instance.isNativeAvailable();
      if (!ok) {
        return 'Native Core ML bridge is not available. Rebuild with '
            'ios/scripts/add_stable_diffusion_to_runner.rb.';
      }
      await OnDeviceSdEndpoint.instance.load(id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  final url = settings.effectiveImageGenUrl;
  final headers = settings.imageGenRelayHeaders;
  if (settings.imageGenProvider == 'comfyui') {
    return ComfyUIService().testConnection(url, headers: headers);
  }
  return ImageGenerationService().testConnection(url, headers: headers);
}

/// Interrupt the active job on whichever backend is selected.
Future<void> interruptBackend(AppSettings settings) async {
  if (settings.imageGenProvider == 'onDevice') {
    await OnDeviceSdEndpoint.instance.cancel();
    return;
  }
  final url = settings.effectiveImageGenUrl;
  final headers = settings.imageGenRelayHeaders;
  if (url.isEmpty) return;
  if (settings.imageGenProvider == 'comfyui') {
    await ComfyUIService().interrupt(url, headers: headers);
  } else {
    await ImageGenerationService().interrupt(url, headers: headers);
  }
}

String? _checkpointFrom(AppSettings settings) {
  // Prefer the checkpoint saved in Settings → Image Generation, then the
  // in-memory ComfyUIService pick, then the first model from refreshAll.
  final selected = settings.imageGenSelectedModel?.trim();
  if (selected != null && selected.isNotEmpty) return selected;
  final cur = ComfyUIService().currentModel?.trim();
  if (cur != null && cur.isNotEmpty) return cur;
  final models = ComfyUIService().models;
  if (models.isNotEmpty) return models.first.title;
  return null;
}
