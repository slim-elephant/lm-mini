import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/comfyui_prompt_error.dart';
import '../utils/comfyui_catalog.dart';
import 'image_generation_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ComfyUI API Client
// ═══════════════════════════════════════════════════════════════════════════
//
// ComfyUI exposes a prompt-graph API that's very different from the flat
// AUTOMATIC1111 /sdapi/v1/txt2img endpoint. This service adapts a simple
// parameter set (prompt, negative prompt, size, steps, etc.) onto a
// workflow JSON graph so the rest of the app (and LM Mini Connect) can
// treat ComfyUI exactly like A1111.
//
// Endpoints used:
//   GET  /system_stats                       — health / capability probe
//   POST /prompt                             — queue a workflow, returns prompt_id
//   GET  /history/{prompt_id}                — poll job status & outputs
//   WS   /ws?clientId=                       — sampler progress (not /queue)
//   GET  /view?filename=...&type=...         — download a generated image
//   POST /interrupt                          — cancel active job
//   GET  /object_info                        — returns info on all nodes,
//                                              including checkpoints/samplers/etc.
//
// All methods accept an optional `headers` map so remote access via
// LM Mini Connect's relay works identically to A1111.
// ═══════════════════════════════════════════════════════════════════════════

/// Default built-in SD 1.5 / SDXL text-to-image workflow
/// (`CheckpointLoaderSimple` + `EmptyLatentImage`).
/// Not for UNET + CLIP + VAE graphs (Z-Image, Flux, SD3, etc.).
///
/// The string placeholders (`%PROMPT%`, `%LORA%`, `%LORA_WEIGHT%`, etc.)
/// are substituted by [ComfyUIService._buildWorkflow] before sending.
/// Users can supply their own workflow JSON via
/// [AppSettings.comfyUiWorkflowJson] and the same placeholder substitution
/// applies.
const String kDefaultComfyUiWorkflow = r'''
{
  "3": {
    "class_type": "KSampler",
    "inputs": {
      "cfg": %CFG%,
      "denoise": 1,
      "latent_image": ["5", 0],
      "model": ["4", 0],
      "negative": ["7", 0],
      "positive": ["6", 0],
      "sampler_name": "%SAMPLER%",
      "scheduler": "%SCHEDULER%",
      "seed": %SEED%,
      "steps": %STEPS%
    }
  },
  "4": {
    "class_type": "CheckpointLoaderSimple",
    "inputs": {"ckpt_name": "%CHECKPOINT%"}
  },
  "5": {
    "class_type": "EmptyLatentImage",
    "inputs": {"batch_size": %BATCH%, "height": %HEIGHT%, "width": %WIDTH%}
  },
  "6": {
    "class_type": "CLIPTextEncode",
    "inputs": {"clip": ["4", 1], "text": "%PROMPT%"}
  },
  "7": {
    "class_type": "CLIPTextEncode",
    "inputs": {"clip": ["4", 1], "text": "%NEGATIVE%"}
  },
  "8": {
    "class_type": "VAEDecode",
    "inputs": {"samples": ["3", 0], "vae": ["4", 2]}
  },
  "9": {
    "class_type": "SaveImage",
    "inputs": {"filename_prefix": "lmmini", "images": ["8", 0]}
  }
}
''';

/// Built-in Z-Image Turbo graph (UNET + Qwen 3 4B text encoder + AuraFlow VAE).
///
/// `qwen_3_4b.safetensors` is the **text encoder** this model family uses
/// (CLIPLoader type `lumina2`), not a Qwen chat LLM.
const String kZImageTurboComfyUiWorkflow = r'''
{
  "62": {
    "class_type": "CLIPLoader",
    "inputs": {
      "clip_name": "qwen_3_4b.safetensors",
      "type": "lumina2",
      "device": "default"
    }
  },
  "63": {
    "class_type": "VAELoader",
    "inputs": {"vae_name": "ae.safetensors"}
  },
  "66": {
    "class_type": "UNETLoader",
    "inputs": {
      "unet_name": "%CHECKPOINT%",
      "weight_dtype": "default"
    }
  },
  "67": {
    "class_type": "CLIPTextEncode",
    "inputs": {"clip": ["62", 0], "text": "%PROMPT%"}
  },
  "71": {
    "class_type": "CLIPTextEncode",
    "inputs": {"clip": ["62", 0], "text": "%NEGATIVE%"}
  },
  "68": {
    "class_type": "EmptySD3LatentImage",
    "inputs": {"batch_size": %BATCH%, "height": %HEIGHT%, "width": %WIDTH%}
  },
  "69": {
    "class_type": "ModelSamplingAuraFlow",
    "inputs": {"model": ["66", 0], "shift": 3}
  },
  "70": {
    "class_type": "KSampler",
    "inputs": {
      "cfg": 1,
      "denoise": 1,
      "latent_image": ["68", 0],
      "model": ["69", 0],
      "negative": ["71", 0],
      "positive": ["67", 0],
      "sampler_name": "res_multistep",
      "scheduler": "simple",
      "seed": %SEED%,
      "steps": 8
    }
  },
  "65": {
    "class_type": "VAEDecode",
    "inputs": {"samples": ["70", 0], "vae": ["63", 0]}
  },
  "9": {
    "class_type": "SaveImage",
    "inputs": {"filename_prefix": "lmmini", "images": ["65", 0]}
  }
}
''';

bool isComfyDefaultWorkflowJson(String? text) {
  final trimmed = text?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  return trimmed == kDefaultComfyUiWorkflow.trim() ||
      trimmed == kZImageTurboComfyUiWorkflow.trim();
}

class ComfyUiSavedWorkflow {
  final String name;
  final String path;

  const ComfyUiSavedWorkflow({
    required this.name,
    required this.path,
  });

  String get displayName {
    if (isComfyZImageTurboWorkflowPath(path)) {
      return 'Mini built-in (Z-Image Turbo)';
    }
    if (isComfySdCheckpointWorkflowPath(path)) {
      return 'Mini built-in (SD 1.5 / SDXL checkpoint)';
    }
    if (isComfyLastRunWorkflowPath(path)) return name;
    if (path.startsWith('workflows/') ||
        path.startsWith('user/default/workflows/')) {
      return comfyWorkflowDisplayName(path.split('/').last);
    }
    final label = name.isNotEmpty ? name : path.split('/').last;
    return label.toLowerCase().endsWith('.json')
        ? comfyWorkflowDisplayName(label)
        : label;
  }
}

class ComfyUIService {
  static final ComfyUIService _instance = ComfyUIService._();
  factory ComfyUIService() => _instance;
  ComfyUIService._();

  static const Map<String, List<String>> _samplerAliases = {
    'euler': ['Euler'],
    'euler_ancestral': ['Euler a', 'Euler ancestral'],
    'heun': ['Heun'],
    'heunpp2': ['HeunPP2'],
    'dpm_2': ['DPM2'],
    'dpm_2_ancestral': ['DPM2 a', 'DPM2 ancestral'],
    'lms': ['LMS'],
    'dpm_fast': ['DPM fast'],
    'dpm_adaptive': ['DPM adaptive'],
    'dpmpp_2s_ancestral': ['DPM++ 2S a', 'DPM++ 2S ancestral'],
    'dpmpp_sde': ['DPM++ SDE'],
    'dpmpp_sde_gpu': ['DPM++ SDE GPU'],
    'dpmpp_2m': ['DPM++ 2M'],
    'dpmpp_2m_sde': ['DPM++ 2M SDE'],
    'dpmpp_2m_sde_gpu': ['DPM++ 2M SDE GPU'],
    'ddim': ['DDIM'],
    'uni_pc': ['UniPC', 'Uni PC'],
    'uni_pc_bh2': ['UniPC BH2', 'Uni PC BH2'],
    'lcm': ['LCM'],
    'restart': ['Restart'],
    'deis': ['DEIS'],
    'ddpm': ['DDPM'],
    'ipndm': ['iPNDM', 'IPNDM'],
    'ipndm_v': ['iPNDM_V', 'IPNDM_V'],
    'gradient_estimation': ['Gradient Estimation'],
    'er_sde': ['ER-SDE', 'ER SDE'],
    'res_multistep': ['res_multistep', 'Res Multistep'],
  };

  static const Map<String, List<String>> _schedulerAliases = {
    'normal': ['Automatic', 'Normal'],
    'karras': ['Karras'],
    'exponential': ['Exponential'],
    'sgm_uniform': ['SGM Uniform'],
    'simple': ['Simple'],
    'ddim_uniform': ['DDIM Uniform'],
    'beta': ['Beta'],
  };

  final http.Client _client = http.Client();

  // Cached object_info — populated on first refresh and reused for
  // checkpoint / sampler / scheduler lookups.
  List<SDModel> _models = [];
  final Set<String> _classicCheckpointNames = {};
  List<SDSampler> _samplers = [];
  List<SDScheduler> _schedulers = [];
  List<SDUpscaler> _upscalers = [];
  List<String> _loras = [];
  List<ComfyUiSavedWorkflow> _savedWorkflows = [];
  final Map<String, String> _namedWorkflowBodies = {};
  ComfyHistoryGraph? _lastRun;
  String? _currentModel;
  String? _activePromptId;
  String? _clientId;
  bool _cancelRequested = false;

  List<SDModel> get models => _models;
  List<SDSampler> get samplers => _samplers;
  List<SDScheduler> get schedulers => _schedulers;
  List<SDUpscaler> get upscalers => _upscalers;

  /// LoRA filenames from `GET /models/loras`, with `LoraLoader` enum fallback.
  List<String> get loras => _loras;
  List<ComfyUiSavedWorkflow> get savedWorkflows => workflowOptions;
  List<ComfyUiSavedWorkflow> get workflowOptions {
    final last = _lastRun;
    return [
      const ComfyUiSavedWorkflow(
        name: 'Mini built-in (SD 1.5 / SDXL checkpoint)',
        path: kComfySdCheckpointWorkflowPath,
      ),
      const ComfyUiSavedWorkflow(
        name: 'Mini built-in (Z-Image Turbo)',
        path: kComfyZImageTurboWorkflowPath,
      ),
      if (last != null)
        ComfyUiSavedWorkflow(
          name: last.loaderLabel == null || last.loaderLabel!.isEmpty
              ? 'Last run in ComfyUI'
              : 'Last run in ComfyUI — ${last.loaderLabel}',
          path: kComfyLastRunWorkflowPath,
        ),
      ..._savedWorkflows,
    ];
  }

  bool get hasClassicCheckpoints => _classicCheckpointNames.isNotEmpty;
  bool get hasLastRunWorkflow => _lastRun != null;
  String? get currentModel => _currentModel;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  /// Ensure we have a stable client_id for ComfyUI's history API.
  String _getClientId(String? configured) {
    if (configured != null && configured.isNotEmpty) {
      _clientId = configured;
      return configured;
    }
    _clientId ??=
        'lmmini-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    return _clientId!;
  }

  // ── Connection test ────────────────────────────────────────────────

  /// Returns null on success, or an error message on failure.
  Future<String?> testConnection(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      final res = await _client
          .get(Uri.parse('$serverUrl/system_stats'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return null;
      }
      return 'HTTP ${res.statusCode}';
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 61 ||
          e.toString().contains('Connection refused')) {
        return 'Connection refused. Ensure ComfyUI is running with the --listen flag.';
      }
      return e.toString();
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        return 'Connection refused. Ensure ComfyUI is running with the --listen flag.';
      }
      return e.toString();
    }
  }

  // ── Listing / object_info ──────────────────────────────────────────

  /// Fetch checkpoints, samplers, schedulers, LoRAs, and upscalers.
  Future<void> refreshAll(String serverUrl,
      {Map<String, String>? headers}) async {
    _models = [];
    _classicCheckpointNames.clear();
    // Model folders + history are small. object_info can be huge and slow,
    // so fill the dropdowns first.
    await Future.wait([
      _refreshModelFolders(serverUrl, headers: headers),
      _refreshSavedWorkflows(serverUrl, headers: headers),
      _refreshLastRun(serverUrl, headers: headers),
    ]);
    await Future.wait([
      _refreshObjectInfo(serverUrl, headers: headers),
      _refreshLoras(serverUrl, headers: headers),
    ]);
  }

  Future<http.Response> _comfyGet(
    String serverUrl,
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final normalized = path.startsWith('/') ? path : '/$path';
    var res = await _client
        .get(Uri.parse('$serverUrl$normalized'), headers: headers)
        .timeout(timeout);
    if (res.statusCode == 404 && !normalized.startsWith('/api/')) {
      res = await _client
          .get(Uri.parse('$serverUrl/api$normalized'), headers: headers)
          .timeout(timeout);
    }
    return res;
  }

  Future<http.Response> _comfyPost(
    String serverUrl,
    String path, {
    Map<String, String>? headers,
    Object? body,
    String contentType = 'application/json',
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final normalized = path.startsWith('/') ? path : '/$path';
    final hdrs = <String, String>{
      if (body != null) 'Content-Type': contentType,
      ...?headers,
    };
    var res = await _client
        .post(
          Uri.parse('$serverUrl$normalized'),
          headers: hdrs,
          body: body,
        )
        .timeout(timeout);
    if (res.statusCode == 404 && !normalized.startsWith('/api/')) {
      res = await _client
          .post(
            Uri.parse('$serverUrl/api$normalized'),
            headers: hdrs,
            body: body,
          )
          .timeout(timeout);
    }
    return res;
  }

  void _throwIfCancelled() {
    if (_cancelRequested) throw ImageGenerationCancelled();
  }

  Future<void> _refreshModelFolders(String serverUrl,
      {Map<String, String>? headers}) async {
    final folders = <String>{
      'checkpoints',
      'diffusion_models',
      'unet',
      ...await _listModelFolderNames(serverUrl, headers: headers),
    };
    for (final folder in folders) {
      // `configs` is SD YAML (v1-inference.yaml, etc.), not weights.
      if (folder == 'configs') continue;
      final classic = folder == 'checkpoints';
      if (!classic &&
          folder != 'diffusion_models' &&
          folder != 'unet' &&
          !folder.contains('unet')) {
        continue;
      }
      await _mergeModelFolder(
        serverUrl,
        folder,
        classic: classic,
        headers: headers,
      );
    }
    if (_currentModel == null && _models.isNotEmpty) {
      _currentModel = _models.first.title;
    }
  }

  Future<Set<String>> _listModelFolderNames(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      final res = await _comfyGet(serverUrl, '/models', headers: headers);
      if (res.statusCode != 200) return {};
      return parseComfyModelFolderResponse(jsonDecode(res.body)).toSet();
    } catch (e) {
      debugPrint('⚠️ ComfyUI /models: $e');
      return {};
    }
  }

  Future<void> _refreshLastRun(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      final res = await _comfyGet(
        serverUrl,
        '/history?max_items=8',
        headers: headers,
      );
      if (res.statusCode != 200) {
        _lastRun = null;
        return;
      }
      final graphs = parseComfyHistory(jsonDecode(res.body));
      _lastRun = graphs.isEmpty ? null : graphs.first;
    } catch (e) {
      debugPrint('⚠️ ComfyUI /history: $e');
    }
  }

  Future<void> _refreshObjectInfo(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      final res = await _comfyGet(
        serverUrl,
        '/object_info',
        headers: headers,
        timeout: const Duration(seconds: 45),
      );
      if (res.statusCode != 200) {
        debugPrint('⚠️ ComfyUI object_info failed: ${res.statusCode}');
        await _refreshNamedNodeInfo(serverUrl, headers: headers);
        return;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        await _refreshNamedNodeInfo(serverUrl, headers: headers);
        return;
      }
      final data = Map<String, dynamic>.from(decoded);

      _addModelNames(
        [
          ..._extractEnum(data, 'CheckpointLoaderSimple', 'ckpt_name'),
          ..._extractEnum(data, 'CheckpointLoader', 'ckpt_name'),
          ...scanComfyObjectInfoForInput(data, 'ckpt_name'),
        ],
        classic: true,
      );
      _addModelNames(
        [
          ..._extractEnum(data, 'UNETLoader', 'unet_name'),
          ..._extractEnum(data, 'UNETLoaderGGUF', 'unet_name'),
          ...scanComfyObjectInfoForInput(data, 'unet_name'),
        ],
        classic: false,
      );
      _samplers = _extractEnumSamplers(data, 'KSampler', 'sampler_name');
      _schedulers = _extractEnumSchedulers(data, 'KSampler', 'scheduler');
      _upscalers = _extractEnumUpscalers(data);
      _loras = _extractEnum(data, 'LoraLoader', 'lora_name');
      if (_currentModel == null && _models.isNotEmpty) {
        _currentModel = _models.first.title;
      }
      final hasUnet =
          _models.any((m) => !_classicCheckpointNames.contains(m.title));
      if (!hasUnet) {
        await _refreshNamedNodeInfo(serverUrl, headers: headers);
      }
    } catch (e) {
      debugPrint('❌ ComfyUI refreshAll/object_info: $e');
      await _refreshNamedNodeInfo(serverUrl, headers: headers);
    }
  }

  Future<void> _refreshNamedNodeInfo(String serverUrl,
      {Map<String, String>? headers}) async {
    for (final klass in const [
      'UNETLoader',
      'UNETLoaderGGUF',
      'CheckpointLoaderSimple',
      'KSampler',
    ]) {
      try {
        final res = await _comfyGet(
          serverUrl,
          '/object_info/$klass',
          headers: headers,
        );
        if (res.statusCode != 200) continue;
        final decoded = jsonDecode(res.body);
        if (decoded is! Map) continue;
        final node = decoded.containsKey('input') ? decoded : decoded[klass];
        if (node is! Map) continue;
        _addModelNames(
          extractComfyInputEnum(node, 'ckpt_name'),
          classic: true,
        );
        _addModelNames(
          extractComfyInputEnum(node, 'unet_name'),
          classic: false,
        );
        if (klass == 'KSampler' && _samplers.isEmpty) {
          _samplers = extractComfyInputEnum(node, 'sampler_name')
              .map((n) => SDSampler(name: n, aliases: const []))
              .toList();
          _schedulers = extractComfyInputEnum(node, 'scheduler')
              .map((n) => SDScheduler(name: n, label: n))
              .toList();
        }
      } catch (e) {
        debugPrint('⚠️ ComfyUI object_info/$klass: $e');
      }
    }
  }

  void _addModelNames(Iterable<String> names, {required bool classic}) {
    final existing = _models.map((m) => m.title).toSet();
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty || !isComfyWeightFilename(name)) continue;
      if (classic) _classicCheckpointNames.add(name);
      if (!existing.add(name)) continue;
      _models.add(SDModel(title: name, modelName: name, filename: name));
    }
    _models.sort((a, b) {
      final aClassic = _classicCheckpointNames.contains(a.title);
      final bClassic = _classicCheckpointNames.contains(b.title);
      if (aClassic != bClassic) return aClassic ? -1 : 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    if (_currentModel == null ||
        !_models.any((m) => m.title == _currentModel)) {
      _currentModel = _models.isNotEmpty ? _models.first.title : null;
    }
  }

  /// Prefer the dedicated model folder listing (`GET /models/loras`).
  /// On success, replaces any LoraLoader enum list from object_info.
  /// Older Comfy builds without this endpoint keep the object_info fallback.
  Future<void> _refreshLoras(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      final res = await _comfyGet(serverUrl, '/models/loras', headers: headers);
      if (res.statusCode != 200) {
        debugPrint('⚠️ ComfyUI /models/loras failed: ${res.statusCode}');
        return;
      }
      _loras = parseComfyModelFolderResponse(jsonDecode(res.body));
    } catch (e) {
      debugPrint('⚠️ ComfyUI /models/loras: $e');
    }
  }

  Future<void> _mergeModelFolder(
    String serverUrl,
    String folder, {
    required bool classic,
    Map<String, String>? headers,
  }) async {
    final names = await _fetchModelFolder(serverUrl, folder, headers: headers);
    if (names.isEmpty) return;
    _addModelNames(names, classic: classic);
  }

  Future<List<String>> _fetchModelFolder(
    String serverUrl,
    String folder, {
    Map<String, String>? headers,
  }) async {
    try {
      final res =
          await _comfyGet(serverUrl, '/models/$folder', headers: headers);
      if (res.statusCode != 200) return const [];
      return parseComfyModelFolderResponse(jsonDecode(res.body));
    } catch (e) {
      debugPrint('⚠️ ComfyUI /models/$folder: $e');
      return const [];
    }
  }

  Future<void> _refreshSavedWorkflows(String serverUrl,
      {Map<String, String>? headers}) async {
    try {
      _savedWorkflows = await fetchSavedWorkflows(serverUrl, headers: headers);
    } catch (e) {
      debugPrint('❌ ComfyUI refreshAll/workflows: $e');
    }
    await _mergeLocalNamedWorkflows();
  }

  void _sortSavedWorkflows() {
    _savedWorkflows.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
  }

  void _rememberSavedWorkflow(String path) {
    final file = path.split('/').last;
    _savedWorkflows = [
      ..._savedWorkflows.where((workflow) => workflow.path != path),
      ComfyUiSavedWorkflow(name: file, path: path),
    ];
    _sortSavedWorkflows();
  }

  Future<Directory> _namedWorkflowDirectory({bool create = false}) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/comfy_named_workflows');
    if (create && !await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _writeLocalNamedWorkflow(
    String workflowPath,
    String body,
  ) async {
    final dir = await _namedWorkflowDirectory(create: true);
    final file = File('${dir.path}/${Uri.encodeComponent(workflowPath)}');
    await file.writeAsString(body);
  }

  Future<String?> _readLocalNamedWorkflow(String workflowPath) async {
    try {
      final dir = await _namedWorkflowDirectory();
      if (!await dir.exists()) return null;
      final file = File('${dir.path}/${Uri.encodeComponent(workflowPath)}');
      if (!await file.exists()) return null;
      final body = await file.readAsString();
      if (body.trim().isEmpty) return null;
      return body;
    } catch (e) {
      debugPrint('⚠️ ComfyUI local workflow read: $e');
      return null;
    }
  }

  Future<void> _mergeLocalNamedWorkflows() async {
    try {
      final dir = await _namedWorkflowDirectory();
      if (!await dir.exists()) return;
      final known = _savedWorkflows.map((workflow) => workflow.path).toSet();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final encoded = entity.uri.pathSegments.last;
        final path = Uri.decodeComponent(encoded);
        if (!path.toLowerCase().endsWith('.json') || known.contains(path)) {
          continue;
        }
        known.add(path);
        _savedWorkflows.add(
          ComfyUiSavedWorkflow(
            name: path.split('/').last,
            path: path,
          ),
        );
      }
      _sortSavedWorkflows();
    } catch (e) {
      debugPrint('⚠️ ComfyUI local workflows: $e');
    }
  }

  /// Writes [workflow] to Comfy userdata and to a local copy so the name stays
  /// in the workflow list after a restart. Returns the userdata path.
  Future<String> saveNamedWorkflow(
    String serverUrl,
    String name,
    Map<String, dynamic> workflow, {
    Map<String, String>? headers,
  }) async {
    final path = comfyNamedWorkflowPath(
      name,
      _savedWorkflows.map((workflow) => workflow.path),
    );
    final body = const JsonEncoder.withIndent('  ').convert(workflow);
    _rememberWorkflowBody(path, body);
    Object? serverError;
    try {
      await _postUserdataFile(
        serverUrl,
        path,
        body,
        headers: headers,
      );
    } catch (e) {
      serverError = e;
      debugPrint('⚠️ ComfyUI userdata save: $e');
    }
    try {
      await _writeLocalNamedWorkflow(path, body);
    } catch (e) {
      if (serverError != null) {
        throw Exception(
          'Could not save workflow "$name" ($serverError; local copy: $e)',
        );
      }
      debugPrint('⚠️ ComfyUI local workflow save: $e');
    }
    if (serverError != null) {
      debugPrint(
        '⚠️ ComfyUI stored "$path" in Mini only. Comfy Desktop did not keep it.',
      );
    }
    _rememberSavedWorkflow(path);
    return path;
  }

  Future<void> _postUserdataFile(
    String serverUrl,
    String workflowPath,
    String body, {
    Map<String, String>? headers,
  }) async {
    final encoded = Uri.encodeComponent(workflowPath);
    // Comfy answers this POST with the relative path (`"workflows/Name.json"`),
    // not the file. The bytes above are what gets stored. Send them as a raw
    // file so a JSON parser cannot replace the graph with that path string.
    var res = await _comfyPost(
      serverUrl,
      '/userdata/$encoded?overwrite=true',
      headers: headers,
      body: body,
      contentType: 'application/octet-stream',
      timeout: const Duration(seconds: 30),
    );
    if (res.statusCode == 404 || res.statusCode == 405) {
      res = await _comfyPost(
        serverUrl,
        '/userdata/$workflowPath?overwrite=true',
        headers: headers,
        body: body,
        contentType: 'application/octet-stream',
        timeout: const Duration(seconds: 30),
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
  }

  Future<List<ComfyUiSavedWorkflow>> fetchSavedWorkflows(String serverUrl,
      {Map<String, String>? headers}) async {
    final found = <String, ComfyUiSavedWorkflow>{};
    for (final path in const [
      'workflows',
      'user/default/workflows',
    ]) {
      for (final workflow in await _listUserdataWorkflows(
        serverUrl,
        path,
        headers: headers,
      )) {
        found[workflow.path] = workflow;
      }
    }
    final workflows = found.values.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    return workflows;
  }

  Future<List<ComfyUiSavedWorkflow>> _listUserdataWorkflows(
    String serverUrl,
    String dir, {
    Map<String, String>? headers,
    int depth = 0,
  }) async {
    final workflows = <ComfyUiSavedWorkflow>[];
    try {
      var res = await _comfyGet(
        serverUrl,
        '/v2/userdata?path=${Uri.encodeQueryComponent(dir)}',
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          for (final entry in data) {
            if (entry is! Map) continue;
            final type = entry['type']?.toString();
            final path = entry['path']?.toString() ?? '';
            if (path.isEmpty) continue;
            if (type == 'directory') {
              if (path == dir || depth >= 2) continue;
              workflows.addAll(
                await _listUserdataWorkflows(
                  serverUrl,
                  path,
                  headers: headers,
                  depth: depth + 1,
                ),
              );
              continue;
            }
            if (type != null && type != 'file') continue;
            if (!path.toLowerCase().endsWith('.json')) continue;
            workflows.add(
              ComfyUiSavedWorkflow(
                name: entry['name']?.toString() ?? path.split('/').last,
                path: path,
              ),
            );
          }
          return workflows;
        }
      }

      res = await _comfyGet(
        serverUrl,
        '/userdata?dir=${Uri.encodeQueryComponent(dir)}',
        headers: headers,
      );
      if (res.statusCode != 200) return workflows;
      final data = jsonDecode(res.body);
      if (data is! List) return workflows;
      for (final entry in data) {
        final name = entry is String
            ? entry
            : (entry is Map ? entry['name']?.toString() : null);
        if (name == null || !name.toLowerCase().endsWith('.json')) continue;
        final path = name.contains('/') ? name : '$dir/$name';
        workflows.add(
          ComfyUiSavedWorkflow(
            name: path.split('/').last,
            path: path,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ ComfyUI userdata $dir: $e');
    }
    return workflows;
  }

  Future<String> fetchSavedWorkflowTemplate(
      String serverUrl, String workflowPath,
      {Map<String, String>? headers}) async {
    if (isComfyZImageTurboWorkflowPath(workflowPath)) {
      return kZImageTurboComfyUiWorkflow;
    }
    if (isComfySdCheckpointWorkflowPath(workflowPath)) {
      return kDefaultComfyUiWorkflow;
    }
    if (isComfyLastRunWorkflowPath(workflowPath)) {
      final json = _lastRun?.json;
      if (json != null && json.isNotEmpty) return json;
      await _refreshLastRun(serverUrl, headers: headers);
      final retry = _lastRun?.json;
      if (retry != null && retry.isNotEmpty) return retry;
      throw Exception(
        'ComfyUI has not run a graph yet. Run once in Comfy Desktop, '
        'then tap Refresh in Image Generation settings.',
      );
    }
    final encodedPath = Uri.encodeComponent(workflowPath);
    String? serverBody;
    var status = 0;
    try {
      final res = await _comfyGet(
        serverUrl,
        '/userdata/$encodedPath',
        headers: headers,
      );
      status = res.statusCode;
      if (res.statusCode == 200) serverBody = res.body;
    } catch (e) {
      debugPrint('⚠️ ComfyUI userdata read "$workflowPath": $e');
    }

    final fromServer = comfyUsableWorkflowText(serverBody);
    if (fromServer != null) {
      _rememberWorkflowBody(workflowPath, fromServer);
      return fromServer;
    }
    // POST /userdata answers with the file name. A missing file does too.
    // Either way, queue the graph that was saved with the image.
    final nameOnly = comfyWorkflowNameOnly(serverBody);
    final raw = serverBody?.trim() ?? '';
    if (nameOnly != null || raw.isEmpty) {
      final remembered =
          comfyUsableWorkflowText(_namedWorkflowBodies[workflowPath]);
      if (remembered != null) return remembered;
      final local = comfyUsableWorkflowText(
        await _readLocalNamedWorkflow(workflowPath),
      );
      if (local != null) {
        _rememberWorkflowBody(workflowPath, local);
        return local;
      }
    }
    if (nameOnly != null) {
      throw Exception(
        'ComfyUI returned the workflow name for "$workflowPath" instead of '
        'the workflow JSON ($nameOnly).',
      );
    }
    if (raw.isNotEmpty) return serverBody!;
    throw Exception(
        'ComfyUI saved workflow fetch failed for "$workflowPath": HTTP $status');
  }

  void _rememberWorkflowBody(String workflowPath, String body) {
    final usable = comfyUsableWorkflowText(body);
    if (usable == null) return;
    _namedWorkflowBodies[workflowPath] = usable;
  }

  List<SDSampler> _extractEnumSamplers(
      Map<String, dynamic> objectInfo, String nodeClass, String inputName) {
    final enums = _extractEnum(objectInfo, nodeClass, inputName);
    return enums.map((n) => SDSampler(name: n, aliases: const [])).toList();
  }

  List<SDScheduler> _extractEnumSchedulers(
      Map<String, dynamic> objectInfo, String nodeClass, String inputName) {
    final enums = _extractEnum(objectInfo, nodeClass, inputName);
    return enums.map((n) => SDScheduler(name: n, label: n)).toList();
  }

  List<SDUpscaler> _extractEnumUpscalers(Map<String, dynamic> objectInfo) {
    // Try both common upscaler loader nodes
    for (final klass in const [
      'UpscaleModelLoader',
      'ImageUpscaleWithModel',
      'LatentUpscale',
    ]) {
      final enums = _extractEnum(objectInfo, klass, 'model_name');
      if (enums.isNotEmpty) {
        return enums.map((n) => SDUpscaler(name: n, modelName: n)).toList();
      }
    }
    return const [];
  }

  /// Extract an enum list from an /object_info node-class input definition.
  /// Shape:
  ///   { "NodeClass": { "input": { "required": { "inputName": [ [ "a", "b", ... ], {...} ] } } } }
  List<String> _extractEnum(
      Map<String, dynamic> objectInfo, String nodeClass, String inputName) {
    return extractComfyInputEnum(objectInfo[nodeClass], inputName);
  }

  // ── Switch model ───────────────────────────────────────────────────
  //
  // ComfyUI doesn't have a concept of "the active checkpoint" — it's set
  // per-workflow. We just cache the name here so the UI displays it and
  // the next generateImage() substitutes it into the workflow.
  Future<void> switchModel(String serverUrl, String modelTitle,
      {Map<String, String>? headers}) async {
    _currentModel = modelTitle;
  }

  // ── Generate ───────────────────────────────────────────────────────

  Future<GeneratedImage> generateImage(
    String serverUrl,
    Txt2ImgParams params, {
    String? workflowJson,
    String? workflowPath,
    String? checkpoint,
    String? configuredClientId,
    void Function(GenerationProgress)? onProgress,
    Map<String, String>? headers,
    bool followFormSampler = false,
    List<Map<String, dynamic>> workflowFields = const [],
    String? saveWorkflowName,
  }) async {
    _cancelRequested = false;
    _isGenerating = true;
    WebSocket? progressSocket;
    StreamSubscription<dynamic>? progressSub;
    Future<WebSocket?>? progressSocketFuture;
    var progressClosed = false;
    try {
      _throwIfCancelled();
      if (_models.isEmpty || _samplers.isEmpty || _schedulers.isEmpty) {
        await refreshAll(serverUrl, headers: headers);
      } else if (_lastRun == null) {
        await _refreshLastRun(serverUrl, headers: headers);
      }
      _throwIfCancelled();

      final clientId = _getClientId(configuredClientId);
      var peakProgress = 0.0;
      void emitProgress(double next) {
        if (onProgress == null) return;
        if (next + 0.001 < peakProgress) return;
        peakProgress = next.clamp(0.0, 1.0);
        onProgress(GenerationProgress(progress: peakProgress, etaSeconds: 0));
      }

      String? livePromptId;
      final socketFuture = _openProgressSocket(
        serverUrl,
        clientId,
        headers: headers,
      );
      progressSocketFuture = socketFuture;
      void attachProgressSocket(WebSocket? socket) {
        if (socket == null || progressClosed || _cancelRequested) {
          socket?.close();
          return;
        }
        progressSocket = socket;
        progressSub = socket.listen(
          (event) {
            if (livePromptId == null) return;
            if (event is List<int>) return;
            final parsed = parseComfyProgressEvent(
              event is String ? event : event.toString(),
              promptId: livePromptId,
            );
            if (parsed == null) return;
            if (parsed.finished) {
              emitProgress(0.92);
              return;
            }
            final fraction = parsed.samplerFraction;
            if (fraction != null) {
              emitProgress(comfyDisplayProgressFromSampler(fraction));
            }
          },
          onError: (Object e) {
            debugPrint('⚠️ ComfyUI progress ws: $e');
          },
          cancelOnError: true,
        );
      }

      unawaited(
        socketFuture.then(
          attachProgressSocket,
          onError: (Object e, StackTrace _) {
            debugPrint('⚠️ ComfyUI progress ws: $e');
          },
        ),
      );
      final actualSeed =
          params.seed < 0 ? Random().nextInt(1 << 31) : params.seed;
      var selectedWorkflowPath =
          (workflowPath != null && workflowPath.trim().isNotEmpty)
              ? workflowPath.trim()
              : null;
      final customJson =
          (workflowJson != null && workflowJson.trim().isNotEmpty)
              ? workflowJson
              : null;

      final pathIsExternal = selectedWorkflowPath != null &&
          !isComfyBuiltinWorkflowPath(selectedWorkflowPath);
      final useZImageBuiltin = !pathIsExternal &&
          (customJson == null) &&
          (isComfyZImageTurboWorkflowPath(selectedWorkflowPath) ||
              ((selectedWorkflowPath == null || selectedWorkflowPath.isEmpty) &&
                  !hasClassicCheckpoints));
      final useSdBuiltin =
          !pathIsExternal && customJson == null && !useZImageBuiltin;

      final matchedSampler = _tryResolveSamplerName(params.samplerName);
      final matchedScheduler = _tryResolveSchedulerName(params.scheduler);
      final resolvedSamplerName = matchedSampler ??
          (useSdBuiltin
              ? _resolveSamplerName(params.samplerName)
              : params.samplerName);
      final resolvedSchedulerName = matchedScheduler ??
          (useSdBuiltin
              ? _resolveSchedulerName(params.scheduler)
              : (params.scheduler ?? 'simple'));

      late final String workflowTemplate;
      if (pathIsExternal) {
        workflowTemplate = await fetchSavedWorkflowTemplate(
          serverUrl,
          selectedWorkflowPath,
          headers: headers,
        );
      } else if (customJson != null) {
        workflowTemplate = customJson;
      } else if (useZImageBuiltin) {
        workflowTemplate = kZImageTurboComfyUiWorkflow;
      } else {
        workflowTemplate = kDefaultComfyUiWorkflow;
      }
      _throwIfCancelled();

      var ckpt = (checkpoint ?? _currentModel ?? '').trim();
      if (ckpt.isEmpty ||
          (useZImageBuiltin && _classicCheckpointNames.contains(ckpt))) {
        if (useZImageBuiltin) {
          final unets = _models.where(
            (m) => !_classicCheckpointNames.contains(m.title),
          );
          if (unets.isNotEmpty) {
            ckpt = unets.first.title;
            _currentModel ??= ckpt;
          }
        } else {
          final classic = _models.where(
            (m) => _classicCheckpointNames.contains(m.title),
          );
          if (classic.isNotEmpty) {
            ckpt = classic.first.title;
            _currentModel ??= ckpt;
          } else if (_models.isNotEmpty) {
            ckpt = _models.first.title;
            _currentModel ??= ckpt;
          }
        }
      }
      if (useSdBuiltin) {
        final isClassic =
            ckpt.isNotEmpty && _classicCheckpointNames.contains(ckpt);
        if (!isClassic) {
          throw Exception(
            _models.isNotEmpty
                ? ComfyUiPromptError.diffusionOnlyUserMessage
                : ComfyUiPromptError.noCheckpointsUserMessage,
          );
        }
      }

      // Build workflow by substituting params into a template
      final workflow = _buildWorkflow(
        template: workflowTemplate,
        params: params,
        actualSeed: actualSeed,
        checkpoint: ckpt,
        samplerName: resolvedSamplerName,
        schedulerName: resolvedSchedulerName,
        sourceDescription: selectedWorkflowPath != null
            ? 'ComfyUI workflow "$selectedWorkflowPath"'
            : 'ComfyUI workflow JSON',
        // Built-in Z-Image stays at 8 steps, CFG 1, res_multistep / simple.
        // Every other graph takes Image Generation's steps. Sampler, CFG, and
        // scheduler are replaced only after "Load settings from workflow",
        // so a Qwen graph is not smashed with Euler / CFG 7 by default.
        followFormSampler: followFormSampler && !useZImageBuiltin,
        applySteps: !useZImageBuiltin,
        workflowFields: workflowFields,
      );

      final body = jsonEncode({
        'prompt': workflow,
        'client_id': clientId,
      });

      final res = await _client
          .post(
            Uri.parse('$serverUrl/prompt'),
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        throw Exception(
            'ComfyUI /prompt failed: HTTP ${res.statusCode} — ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final promptId = data['prompt_id']?.toString();
      if (promptId == null || promptId.isEmpty) {
        throw Exception('ComfyUI did not return a prompt_id: ${res.body}');
      }
      _activePromptId = promptId;
      livePromptId = promptId;
      _throwIfCancelled();

      // Wait for the job to complete, then download images from /view
      final outputs =
          await _waitForOutputs(serverUrl, promptId, headers: headers);
      emitProgress(0.93);
      if (outputs.isEmpty) {
        throw Exception('ComfyUI returned no images for prompt $promptId');
      }

      final imageList = <Uint8List>[];
      for (final out in outputs) {
        _throwIfCancelled();
        final uri = Uri.parse('$serverUrl/view').replace(queryParameters: {
          'filename': out.filename,
          if (out.subfolder.isNotEmpty) 'subfolder': out.subfolder,
          'type': out.type,
        });
        final imgRes = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(minutes: 2));
        if (imgRes.statusCode == 200) {
          imageList.add(Uint8List.fromList(imgRes.bodyBytes));
        }
      }
      if (imageList.isEmpty) {
        throw Exception('Failed to download ComfyUI output images');
      }
      emitProgress(1.0);

      String? savedWorkflowPath;
      String? savedWorkflowError;
      final saveName = saveWorkflowName?.trim() ?? '';
      if (saveName.isNotEmpty) {
        try {
          savedWorkflowPath = await saveNamedWorkflow(
            serverUrl,
            saveName,
            workflow,
            headers: headers,
          );
        } catch (e) {
          savedWorkflowError =
              e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          debugPrint('⚠️ ComfyUI save workflow: $e');
        }
      }

      return GeneratedImage(
        bytes: imageList.first,
        info: jsonEncode({
          'provider': 'comfyui',
          'prompt_id': promptId,
          'client_id': clientId,
          'seed': actualSeed,
          'prompt': params.prompt,
          'negative_prompt': params.negativePrompt,
          'steps': params.steps,
          'cfg_scale': params.cfgScale,
          'width': params.width,
          'height': params.height,
          'sampler_name': resolvedSamplerName,
          'scheduler': resolvedSchedulerName,
          'checkpoint': checkpoint ?? _currentModel,
          'workflow_path': selectedWorkflowPath,
          if (savedWorkflowPath != null)
            'saved_workflow_path': savedWorkflowPath,
          if (savedWorkflowError != null)
            'saved_workflow_error': savedWorkflowError,
          'lora_name': params.loraName,
          'lora_weight': params.loraWeight,
          'workflow': workflow,
        }),
        seed: actualSeed,
        allImages: imageList,
      );
    } finally {
      progressClosed = true;
      try {
        await progressSub?.cancel();
      } catch (_) {}
      try {
        await progressSocket?.close();
      } catch (_) {}
      final pendingSocket = progressSocketFuture;
      if (pendingSocket != null) {
        unawaited(() async {
          try {
            final socket = await pendingSocket;
            if (socket != null && !identical(socket, progressSocket)) {
              await socket.close();
            }
          } catch (_) {}
        }());
      }
      _isGenerating = false;
      _activePromptId = null;
      _cancelRequested = false;
    }
  }

  /// Substitute the user-facing parameters into the workflow JSON template.
  Map<String, dynamic> _buildWorkflow({
    required String template,
    required Txt2ImgParams params,
    required int actualSeed,
    required String checkpoint,
    required String samplerName,
    required String schedulerName,
    required String sourceDescription,
    required bool followFormSampler,
    required bool applySteps,
    required List<Map<String, dynamic>> workflowFields,
  }) {
    String substituted = template
        .replaceAll('%PROMPT%', _jsonEscape(params.prompt))
        .replaceAll('%NEGATIVE%', _jsonEscape(params.negativePrompt))
        .replaceAll('%SEED%', actualSeed.toString())
        .replaceAll('%STEPS%', params.steps.toString())
        .replaceAll('%CFG%', params.cfgScale.toString())
        .replaceAll('%WIDTH%', params.width.toString())
        .replaceAll('%HEIGHT%', params.height.toString())
        .replaceAll('%BATCH%', params.batchSize.toString())
        .replaceAll('%SAMPLER%', _jsonEscape(samplerName))
        .replaceAll('%SCHEDULER%', _jsonEscape(schedulerName))
        .replaceAll('%CHECKPOINT%', _jsonEscape(checkpoint))
        .replaceAll('%LORA%', _jsonEscape(params.loraName ?? ''))
        .replaceAll('%LORA_WEIGHT%', params.loraWeight.toString());

    try {
      var decoded = jsonDecode(substituted);
      if (decoded is Map && looksLikeComfyUiWorkflow(decoded)) {
        final converted = convertComfyUiWorkflowToApi(decoded);
        if (converted == null) {
          throw Exception(
            '$sourceDescription is a ComfyUI canvas save that could not be '
            'converted. Export API Format (Workflow → Export) if this fails.',
          );
        }
        decoded = converted;
      }
      if (decoded is Map && decoded is! Map<String, dynamic>) {
        decoded = Map<String, dynamic>.from(decoded);
      }
      if (decoded is! Map<String, dynamic>) {
        throw Exception('$sourceDescription must decode to a JSON object');
      }
      final graph = decoded;
      if (!_looksLikePromptGraph(graph)) {
        throw Exception(
          '$sourceDescription is not a valid ComfyUI API prompt graph.',
        );
      }
      _applyRuntimeOverrides(
        graph,
        params: params,
        actualSeed: actualSeed,
        checkpoint: checkpoint,
        samplerName: samplerName,
        followFormSampler: followFormSampler,
        applySteps: applySteps,
        workflowFields: workflowFields,
      );
      return graph;
    } catch (e) {
      throw Exception(
          'ComfyUI workflow JSON is invalid after substitution: $e\n$substituted');
    }
  }

  bool _looksLikePromptGraph(Map<String, dynamic> workflow) {
    if (workflow.isEmpty) return false;
    return workflow.values.any(
      (value) => value is Map && value['class_type'] is String,
    );
  }

  void _applyRuntimeOverrides(
    Map<String, dynamic> workflow, {
    required Txt2ImgParams params,
    required int actualSeed,
    required String checkpoint,
    required String samplerName,
    required bool followFormSampler,
    required bool applySteps,
    required List<Map<String, dynamic>> workflowFields,
  }) {
    final found = extractComfyWorkflowControls(workflow);
    if (applySteps) {
      final formScheduler = params.scheduler?.trim() ?? '';
      applyComfyGenerationControls(
        workflow,
        steps: params.steps,
        cfg: followFormSampler ? params.cfgScale : found.cfg,
        samplerName: followFormSampler ? samplerName : found.sampler,
        schedulerName: followFormSampler
            ? (formScheduler.isNotEmpty ? formScheduler : found.scheduler)
            : found.scheduler,
        seed: actualSeed,
        width: params.width,
        height: params.height,
        batchSize: params.batchSize,
      );
    }
    if (workflowFields.isNotEmpty) {
      applyComfyWorkflowFields(workflow, workflowFields);
    }
    for (final entry in workflow.entries) {
      final node = entry.value;
      if (node is! Map<String, dynamic>) continue;
      final inputs = node['inputs'];
      if (inputs is! Map<String, dynamic>) continue;

      final classType = node['class_type']?.toString() ?? '';

      if (classType == 'KSampler' || classType == 'KSamplerAdvanced') {
        if (inputs.containsKey('seed')) inputs['seed'] = actualSeed;
        if (inputs.containsKey('noise_seed')) inputs['noise_seed'] = actualSeed;

        applyComfyConditioningPrompts(
          workflow,
          positiveNodeId: comfyLinkNodeId(inputs['positive']),
          negativeNodeId: comfyLinkNodeId(inputs['negative']),
          positivePrompt: params.prompt,
          negativePrompt: params.negativePrompt,
        );
      }

      if (classType.startsWith('Empty') &&
          inputs.containsKey('width') &&
          inputs.containsKey('height')) {
        inputs['width'] = params.width;
        inputs['height'] = params.height;
        if (inputs.containsKey('batch_size')) {
          inputs['batch_size'] = params.batchSize;
        }
      }

      if (checkpoint.isNotEmpty) {
        if (inputs.containsKey('ckpt_name') &&
            _classicCheckpointNames.contains(checkpoint)) {
          inputs['ckpt_name'] = checkpoint;
        }
        if (inputs.containsKey('unet_name') &&
            !_classicCheckpointNames.contains(checkpoint)) {
          inputs['unet_name'] = checkpoint;
        }
      }
    }
  }

  /// Escape a user string for safe embedding inside a JSON string literal.
  String _jsonEscape(String s) {
    // jsonEncode wraps the string in quotes; strip them so callers can keep
    // their own surrounding quotes in the template.
    final encoded = jsonEncode(s);
    return encoded.substring(1, encoded.length - 1);
  }

  String _resolveSamplerName(String samplerName) {
    final available = _samplers.map((sampler) => sampler.name).toList();
    final fallback = available.isNotEmpty ? available.first : samplerName;
    return _resolveOption(
          kind: 'sampler',
          requestedValue: samplerName,
          availableValues: available,
          aliasesByCanonicalTarget: _samplerAliases,
          fallbackValue: fallback,
        ) ??
        fallback;
  }

  String? _tryResolveSamplerName(String samplerName) {
    final available = _samplers.map((sampler) => sampler.name).toList();
    return _resolveOption(
      kind: 'sampler',
      requestedValue: samplerName,
      availableValues: available,
      aliasesByCanonicalTarget: _samplerAliases,
      allowFallback: false,
    );
  }

  String _resolveSchedulerName(String? schedulerName) {
    final available = _schedulers.map((scheduler) => scheduler.name).toList();
    final fallback = available.contains('normal')
        ? 'normal'
        : (available.isNotEmpty ? available.first : 'normal');
    return _resolveOption(
          kind: 'scheduler',
          requestedValue: schedulerName ?? fallback,
          availableValues: available,
          aliasesByCanonicalTarget: _schedulerAliases,
          fallbackValue: fallback,
        ) ??
        fallback;
  }

  String? _tryResolveSchedulerName(String? schedulerName) {
    if (schedulerName == null || schedulerName.trim().isEmpty) return null;
    final available = _schedulers.map((scheduler) => scheduler.name).toList();
    return _resolveOption(
      kind: 'scheduler',
      requestedValue: schedulerName,
      availableValues: available,
      aliasesByCanonicalTarget: _schedulerAliases,
      allowFallback: false,
    );
  }

  String? _resolveOption({
    required String kind,
    required String requestedValue,
    required List<String> availableValues,
    required Map<String, List<String>> aliasesByCanonicalTarget,
    String? fallbackValue,
    bool allowFallback = true,
  }) {
    final requested = requestedValue.trim();
    if (requested.isEmpty) {
      return allowFallback ? fallbackValue : null;
    }

    if (availableValues.contains(requested)) {
      return requested;
    }

    final requestedKey = _canonicalizeOption(requested);
    final availableByKey = {
      for (final value in availableValues) _canonicalizeOption(value): value,
    };

    final directMatch = availableByKey[requestedKey];
    if (directMatch != null) {
      return directMatch;
    }

    for (final entry in aliasesByCanonicalTarget.entries) {
      final aliases = <String>{entry.key, ...entry.value};
      final matchesAlias = aliases.any(
        (alias) => _canonicalizeOption(alias) == requestedKey,
      );
      if (!matchesAlias) continue;

      final resolved = availableByKey[_canonicalizeOption(entry.key)];
      if (resolved == null) continue;
      if (resolved != requested) {
        debugPrint('ℹ️ ComfyUI normalized $kind "$requested" -> "$resolved"');
      }
      return resolved;
    }

    if (!allowFallback) return null;
    if (requested != fallbackValue) {
      debugPrint(
          '⚠️ ComfyUI $kind "$requested" is unavailable; falling back to "$fallbackValue"');
    }
    return fallbackValue;
  }

  String _canonicalizeOption(String value) {
    return value
        .toLowerCase()
        .replaceAll('++', 'pp')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  // ── Polling ────────────────────────────────────────────────────────

  Future<List<_ComfyOutput>> _waitForOutputs(
    String serverUrl,
    String promptId, {
    Map<String, String>? headers,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      _throwIfCancelled();
      await Future<void>.delayed(const Duration(milliseconds: 750));
      _throwIfCancelled();
      try {
        final res = await _client
            .get(Uri.parse('$serverUrl/history/$promptId'), headers: headers)
            .timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final entry = data[promptId] as Map<String, dynamic>?;
        if (entry == null) continue;
        if (comfyHistoryWasInterrupted(entry)) {
          throw ImageGenerationCancelled();
        }
        final outputs = entry['outputs'] as Map<String, dynamic>?;
        if (outputs == null || outputs.isEmpty) continue;

        final result = <_ComfyOutput>[];
        for (final nodeOutputs in outputs.values) {
          if (nodeOutputs is! Map<String, dynamic>) continue;
          // Image nodes report under `images`; video/animation nodes (e.g.
          // VHS_VideoCombine) report their playable file under `gifs`, and some
          // custom nodes use `videos`. Collect all of them so MP4/WebM/GIF
          // outputs are downloaded, not just static images.
          for (final key in const ['images', 'gifs', 'videos']) {
            final media = nodeOutputs[key] as List<dynamic>?;
            if (media == null) continue;
            for (final item in media) {
              if (item is! Map<String, dynamic>) continue;
              final filename = item['filename']?.toString() ?? '';
              if (filename.isEmpty) continue;
              result.add(_ComfyOutput(
                filename: filename,
                subfolder: item['subfolder']?.toString() ?? '',
                type: item['type']?.toString() ?? 'output',
              ));
            }
          }
        }
        if (result.isNotEmpty) return result;
      } on ImageGenerationCancelled {
        rethrow;
      } catch (e) {
        debugPrint('⚠️ ComfyUI history poll: $e');
      }
    }
    throw Exception('ComfyUI prompt $promptId timed out');
  }

  Future<WebSocket?> _openProgressSocket(
    String serverUrl,
    String clientId, {
    Map<String, String>? headers,
  }) async {
    final httpUri = Uri.parse(serverUrl);
    if (httpUri.host.isEmpty) return null;
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final paths = <String>['/ws', '/api/ws'];
    for (final path in paths) {
      final wsUri = Uri(
        scheme: wsScheme,
        userInfo: httpUri.userInfo,
        host: httpUri.host,
        port: httpUri.hasPort ? httpUri.port : (wsScheme == 'wss' ? 443 : 80),
        path: path,
        queryParameters: {'clientId': clientId},
      );
      try {
        return await WebSocket.connect(
          wsUri.toString(),
          headers: headers,
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('⚠️ ComfyUI $path: $e');
      }
    }
    return null;
  }

  // ── Interrupt ──────────────────────────────────────────────────────

  Future<void> interrupt(String serverUrl,
      {Map<String, String>? headers}) async {
    _cancelRequested = true;
    final promptId = _activePromptId;
    try {
      await _comfyPost(
        serverUrl,
        '/interrupt',
        headers: headers,
        body: '{}',
      );
    } catch (e) {
      debugPrint('❌ ComfyUI interrupt: $e');
    }
    if (promptId == null || promptId.isEmpty) return;
    try {
      await _comfyPost(
        serverUrl,
        '/queue',
        headers: headers,
        body: jsonEncode({
          'delete': [promptId],
        }),
      );
    } catch (e) {
      debugPrint('❌ ComfyUI queue delete: $e');
    }
  }
}

class _ComfyOutput {
  final String filename;
  final String subfolder;
  final String type;
  const _ComfyOutput({
    required this.filename,
    required this.subfolder,
    required this.type,
  });
}
