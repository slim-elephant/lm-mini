import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/image_gen_unreachable_error.dart';
import '../utils/json_list.dart';
import '../utils/media_type_utils.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AUTOMATIC1111 / Stable Diffusion WebUI  API Client
// ═══════════════════════════════════════════════════════════════════════════

/// Holds one generation result (image bytes + metadata).
class GeneratedImage {
  final Uint8List bytes;
  final List<Uint8List> allImages; // All images from batch
  final String info; // JSON string with seed, prompt, etc.
  final int seed;

  GeneratedImage(
      {required this.bytes,
      required this.info,
      required this.seed,
      List<Uint8List>? allImages})
      : allImages = allImages ?? [bytes];
}

/// Live progress during generation.
class GenerationProgress {
  final double progress; // 0.0 – 1.0
  final double etaSeconds;
  final Uint8List? previewImage; // optional live preview

  GenerationProgress({
    required this.progress,
    required this.etaSeconds,
    this.previewImage,
  });
}

/// User tapped cancel (or Comfy interrupted the graph).
class ImageGenerationCancelled implements Exception {
  @override
  String toString() => 'Image generation cancelled';
}

/// Lightweight model descriptor returned by `/sdapi/v1/sd-models`.
class SDModel {
  final String title;
  final String modelName;
  final String? hash;
  final String filename;

  SDModel({
    required this.title,
    required this.modelName,
    this.hash,
    required this.filename,
  });

  factory SDModel.fromJson(Map<String, dynamic> json) => SDModel(
        title: json['title'] ?? '',
        modelName: json['model_name'] ?? '',
        hash: json['hash'],
        filename: json['filename'] ?? '',
      );
}

/// Sampler info from `/sdapi/v1/samplers`.
class SDSampler {
  final String name;
  final List<String> aliases;

  SDSampler({required this.name, required this.aliases});

  factory SDSampler.fromJson(Map<String, dynamic> json) => SDSampler(
        name: json['name'] ?? '',
        aliases: (json['aliases'] as List?)?.cast<String>() ?? [],
      );
}

/// Scheduler info from `/sdapi/v1/schedulers`.
class SDScheduler {
  final String name;
  final String label;

  SDScheduler({required this.name, required this.label});

  factory SDScheduler.fromJson(Map<String, dynamic> json) => SDScheduler(
        name: json['name'] ?? '',
        label: json['label'] ?? json['name'] ?? '',
      );
}

/// Upscaler info from `/sdapi/v1/upscalers`.
class SDUpscaler {
  final String name;
  final String? modelName;

  SDUpscaler({required this.name, this.modelName});

  factory SDUpscaler.fromJson(Map<String, dynamic> json) => SDUpscaler(
        name: json['name'] ?? '',
        modelName: json['model_name'],
      );
}

/// Parameters sent with txt2img requests.
class Txt2ImgParams {
  final String prompt;
  final String negativePrompt;
  final int steps;
  final double cfgScale;
  final int width;
  final int height;
  final String samplerName;
  final String? scheduler;
  final int seed;
  final int batchSize;
  final bool enableHr;
  final double hrScale;
  final String? hrUpscaler;
  final double denoisingStrength;
  final bool restoreFaces;
  final bool tiling;
  final Map<String, dynamic>? overrideSettings;

  /// ComfyUI LoRA filename for `%LORA%` substitution (ignored by A1111/on-device).
  final String? loraName;

  /// ComfyUI LoRA strength for `%LORA_WEIGHT%` (default 1.0).
  final double loraWeight;

  const Txt2ImgParams({
    required this.prompt,
    this.negativePrompt = '',
    this.steps = 20,
    this.cfgScale = 7.0,
    this.width = 512,
    this.height = 512,
    this.samplerName = 'Euler a',
    this.scheduler,
    this.seed = -1,
    this.batchSize = 1,
    this.enableHr = false,
    this.hrScale = 2.0,
    this.hrUpscaler,
    this.denoisingStrength = 0.7,
    this.restoreFaces = false,
    this.tiling = false,
    this.overrideSettings,
    this.loraName,
    this.loraWeight = 1.0,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'prompt': prompt,
      'negative_prompt': negativePrompt,
      'steps': steps,
      'cfg_scale': cfgScale,
      'width': width,
      'height': height,
      'sampler_name': samplerName,
      'seed': seed,
      'batch_size': batchSize,
      'enable_hr': enableHr,
      'hr_scale': hrScale,
      'denoising_strength': denoisingStrength,
      'restore_faces': restoreFaces,
      'tiling': tiling,
    };
    if (scheduler != null) json['scheduler'] = scheduler;
    if (hrUpscaler != null) json['hr_upscaler'] = hrUpscaler;
    if (overrideSettings != null) {
      json['override_settings'] = overrideSettings;
    }
    return json;
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Service
// ─────────────────────────────────────────────────────────────────────────

class ImageGenerationService {
  // Singleton
  static final ImageGenerationService _instance = ImageGenerationService._();
  factory ImageGenerationService() => _instance;
  ImageGenerationService._();

  final http.Client _client = http.Client();

  // Cached lists (refreshed on connect / explicit refresh)
  List<SDModel> _models = [];
  List<SDSampler> _samplers = [];
  List<SDScheduler> _schedulers = [];
  List<SDUpscaler> _upscalers = [];
  String? _currentModel; // currently loaded checkpoint title

  List<SDModel> get models => _models;
  List<SDSampler> get samplers => _samplers;
  List<SDScheduler> get schedulers => _schedulers;
  List<SDUpscaler> get upscalers => _upscalers;
  String? get currentModel => _currentModel;

  // Active generation tracking
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // ── Connection test ────────────────────────────────────────────────

  /// Test connection and fetch server info.
  /// Returns null on success, or error string on failure.
  Future<String?> testConnection(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$serverUrl/sdapi/v1/options');
      final res = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!looksLikeA1111Options(data)) {
          return ImageGenUnreachableError.wrongServerUserMessage;
        }
        final map = data as Map;
        _currentModel = map['sd_model_checkpoint'] as String?;
        return null; // success
      }
      return 'HTTP ${res.statusCode}';
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 61 ||
          e.toString().contains('Connection refused')) {
        return 'Connection refused. Ensure A1111 is running with the --api and --listen flags.';
      }
      return e.toString();
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        return 'Connection refused. Ensure A1111 is running with the --api and --listen flags.';
      }
      return e.toString();
    }
  }

  // ── Listing endpoints ──────────────────────────────────────────────

  /// Refresh all lists (models, samplers, schedulers, upscalers).
  Future<void> refreshAll(String serverUrl,
      {Map<String, String>? headers}) async {
    await Future.wait([
      _fetchModels(serverUrl, headers: headers),
      _fetchSamplers(serverUrl, headers: headers),
      _fetchSchedulers(serverUrl, headers: headers),
      _fetchUpscalers(serverUrl, headers: headers),
    ]);
  }

  Future<void> _fetchModels(String url, {Map<String, String>? headers}) async {
    try {
      final res = await _client
          .get(Uri.parse('$url/sdapi/v1/sd-models'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _models = _sdModelsFromBody(res.body);
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch SD models: $e');
    }
  }

  Future<void> _fetchSamplers(String url,
      {Map<String, String>? headers}) async {
    try {
      final res = await _client
          .get(Uri.parse('$url/sdapi/v1/samplers'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _samplers =
            _mapsFromListBody(res.body).map(SDSampler.fromJson).toList();
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch samplers: $e');
    }
  }

  Future<void> _fetchSchedulers(String url,
      {Map<String, String>? headers}) async {
    try {
      final res = await _client
          .get(Uri.parse('$url/sdapi/v1/schedulers'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _schedulers =
            _mapsFromListBody(res.body).map(SDScheduler.fromJson).toList();
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch schedulers: $e');
    }
  }

  static List<Map<String, dynamic>> _mapsFromListBody(String body) {
    final list = jsonAsList(jsonDecode(body));
    if (list == null) return const [];
    return [
      for (final item in list)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  static List<SDModel> _sdModelsFromBody(String body) =>
      _mapsFromListBody(body).map(SDModel.fromJson).toList();

  static List<String> _txt2imgImages(Map<String, dynamic> map) {
    final raw = map['images'];
    if (raw is String && raw.trim().isNotEmpty) return [raw];
    final list = jsonAsList(raw);
    if (list == null) return const [];
    return [
      for (final item in list)
        if (item is String && item.isNotEmpty) item,
    ];
  }

  Future<void> _fetchUpscalers(String url,
      {Map<String, String>? headers}) async {
    try {
      final res = await _client
          .get(Uri.parse('$url/sdapi/v1/upscalers'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _upscalers =
            _mapsFromListBody(res.body).map(SDUpscaler.fromJson).toList();
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch upscalers: $e');
    }
  }

  // ── Switch model ───────────────────────────────────────────────────

  /// Ask the server to load a different checkpoint.
  Future<void> switchModel(String serverUrl, String modelTitle,
      {Map<String, String>? headers}) async {
    final allHeaders = {'Content-Type': 'application/json', ...?headers};
    final res = await _client
        .post(
          Uri.parse('$serverUrl/sdapi/v1/options'),
          headers: allHeaders,
          body: jsonEncode({'sd_model_checkpoint': modelTitle}),
        )
        .timeout(const Duration(minutes: 5));
    if (res.statusCode == 200) {
      _currentModel = modelTitle;
    } else {
      throw Exception('Failed to switch model: HTTP ${res.statusCode}');
    }
  }

  // ── txt2img ────────────────────────────────────────────────────────

  /// Generate an image. Returns the decoded image bytes.
  /// Calls [onProgress] periodically if provided.
  Future<GeneratedImage> generateImage(
    String serverUrl,
    Txt2ImgParams params, {
    void Function(GenerationProgress)? onProgress,
    Map<String, String>? headers,
  }) async {
    _isGenerating = true;
    Timer? progressTimer;

    try {
      // Start polling progress
      if (onProgress != null) {
        progressTimer =
            Timer.periodic(const Duration(milliseconds: 500), (_) async {
          try {
            final p = await _pollProgress(serverUrl, headers: headers);
            if (p != null) onProgress(p);
          } catch (_) {}
        });
      }

      final allHeaders = {'Content-Type': 'application/json', ...?headers};
      final res = await _client
          .post(
            Uri.parse('$serverUrl/sdapi/v1/txt2img'),
            headers: allHeaders,
            body: jsonEncode(params.toJson()),
          )
          .timeout(const Duration(minutes: 10));

      progressTimer?.cancel();

      if (res.statusCode != 200) {
        throw Exception('txt2img failed: HTTP ${res.statusCode} — ${res.body}');
      }

      final data = jsonDecode(res.body);
      if (data is! Map) {
        throw ImageGenUnreachableError(
          providerLabel: 'AUTOMATIC1111',
          url: serverUrl,
          kind: ImageGenUnreachableKind.wrongServer,
        );
      }
      final map = Map<String, dynamic>.from(data);
      final images = _txt2imgImages(map);
      if (images.isEmpty) {
        throw ImageGenUnreachableError(
          providerLabel: 'AUTOMATIC1111',
          url: serverUrl,
          kind: looksLikeA1111Options(map)
              ? ImageGenUnreachableKind.noImage
              : ImageGenUnreachableKind.wrongServer,
          detail: map['error']?.toString() ?? map['detail']?.toString(),
        );
      }

      // Decode ALL images from the batch
      final allImageBytes = images.map((img) => base64Decode(img)).toList();
      final imageBytes = allImageBytes.first;
      final info = map['info']?.toString() ?? '{}';

      // Parse seed from info
      int seed = -1;
      try {
        final infoJson = jsonDecode(info) as Map<String, dynamic>;
        seed = (infoJson['seed'] as num?)?.toInt() ?? -1;
      } catch (_) {}

      return GeneratedImage(
          bytes: imageBytes, info: info, seed: seed, allImages: allImageBytes);
    } finally {
      progressTimer?.cancel();
      _isGenerating = false;
    }
  }

  // ── Progress polling ───────────────────────────────────────────────

  Future<GenerationProgress?> _pollProgress(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      final res = await _client
          .get(Uri.parse('$serverUrl/sdapi/v1/progress'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      Uint8List? preview;
      if (data['current_image'] != null) {
        try {
          preview = base64Decode(data['current_image'] as String);
        } catch (_) {}
      }

      return GenerationProgress(
        progress: (data['progress'] as num?)?.toDouble() ?? 0,
        etaSeconds: (data['eta_relative'] as num?)?.toDouble() ?? 0,
        previewImage: preview,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Interrupt ──────────────────────────────────────────────────────

  /// Cancel the current generation.
  Future<void> interrupt(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      await _client.post(Uri.parse('$serverUrl/sdapi/v1/interrupt'),
          headers: headers);
    } catch (e) {
      debugPrint('❌ Interrupt failed: $e');
    }
  }

  // ── Save image to disk ─────────────────────────────────────────────

  /// Save generated image bytes to app documents and return the file path.
  Future<String> saveImage(Uint8List bytes, String messageId) async {
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/generated_images');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    final ext = mediaExtensionForBytes(bytes);
    final file = File(
        '${imgDir.path}/${messageId}_${DateTime.now().millisecondsSinceEpoch}$ext');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Save all batch images to app documents and return all file paths.
  Future<List<String>> saveImages(
      List<Uint8List> imageList, String messageId) async {
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/generated_images');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    final paths = <String>[];
    for (int i = 0; i < imageList.length; i++) {
      final ext = mediaExtensionForBytes(imageList[i]);
      final file = File(
          '${imgDir.path}/${messageId}_${DateTime.now().millisecondsSinceEpoch}_$i$ext');
      await file.writeAsBytes(imageList[i]);
      paths.add(file.path);
    }
    return paths;
  }

  /// Delete all generated image files for a given message ID.
  Future<void> deleteImagesForMessage(List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('⚠️ Failed to delete image: $path — $e');
      }
    }
  }
}
