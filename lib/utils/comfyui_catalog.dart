import 'dart:convert';

/// Synthetic path for the most recent `/history` graph (API format).
const kComfyLastRunWorkflowPath = '__lmmini_comfy_last_run__';

/// Settings key used when the graph lives in the JSON box, not a saved path.
const kComfyCustomJsonWorkflowKey = '__lmmini_comfy_custom_json__';

/// Mini built-in CheckpointLoaderSimple graph (SD 1.5 / SDXL).
const kComfySdCheckpointWorkflowPath = '__lmmini_comfy_sd_checkpoint__';

/// Mini built-in Z-Image Turbo graph (UNET + Qwen CLIP + VAE).
const kComfyZImageTurboWorkflowPath = '__lmmini_comfy_z_image_turbo__';

bool isComfyLastRunWorkflowPath(String? path) {
  final value = path?.trim() ?? '';
  return value == kComfyLastRunWorkflowPath ||
      value.startsWith('__lmmini_comfy_history__:');
}

bool isComfySdCheckpointWorkflowPath(String? path) {
  final value = path?.trim() ?? '';
  return value == kComfySdCheckpointWorkflowPath ||
      value == '__lmmini_default_comfyui_workflow__';
}

bool isComfyZImageTurboWorkflowPath(String? path) {
  return (path?.trim() ?? '') == kComfyZImageTurboWorkflowPath;
}

bool isComfyBuiltinWorkflowPath(String? path) {
  return isComfySdCheckpointWorkflowPath(path) ||
      isComfyZImageTurboWorkflowPath(path);
}

/// Weight files Mini can load. Comfy also lists SD config YAML next to
/// checkpoints — those are not models.
bool isComfyWeightFilename(String name) {
  final base = name.trim().split('/').last.split('\\').last.toLowerCase();
  if (base.isEmpty || !base.contains('.')) return false;
  const configs = ['.yaml', '.yml', '.json', '.txt', '.md', '.csv'];
  if (configs.any(base.endsWith)) return false;
  const weights = [
    '.safetensors',
    '.ckpt',
    '.pt',
    '.pth',
    '.bin',
    '.gguf',
    '.sft',
    '.onnx',
  ];
  return weights.any(base.endsWith);
}

/// Parse `GET /models/{folder}` / `GET /models` bodies.
List<String> parseComfyModelFolderResponse(Object? decoded) {
  final names = <String>[];
  void add(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      names.add(value.trim());
    }
  }

  if (decoded is List) {
    for (final entry in decoded) {
      if (entry is String) {
        add(entry);
      } else if (entry is Map) {
        add(entry['name'] ?? entry['filename'] ?? entry['path']);
      }
    }
    return names;
  }
  if (decoded is Map) {
    for (final key in const ['models', 'files', 'items', 'names']) {
      final nested = decoded[key];
      if (nested != null) return parseComfyModelFolderResponse(nested);
    }
    for (final value in decoded.values) {
      if (value is String) add(value);
    }
  }
  return names;
}

/// Combo / enum lists from one `object_info` node definition.
List<String> extractComfyInputEnum(Object? node, String inputName) {
  if (node is! Map) return const [];
  final input = node['input'];
  if (input is! Map) return const [];
  for (final key in const ['required', 'optional']) {
    final section = input[key];
    if (section is! Map) continue;
    final names = _comboNames(section[inputName]);
    if (names.isNotEmpty) return names;
  }
  return const [];
}

List<String> scanComfyObjectInfoForInput(
  Map objectInfo,
  String inputName,
) {
  final out = <String>{};
  for (final value in objectInfo.values) {
    out.addAll(extractComfyInputEnum(value, inputName));
  }
  return out.toList();
}

List<String> _comboNames(Object? entry) {
  if (entry is List && entry.isNotEmpty) {
    final first = entry.first;
    if (first is List) {
      return first.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (first == 'COMBO' && entry.length > 1 && entry[1] is Map) {
      final opts = (entry[1] as Map)['options'];
      if (opts is List) {
        return opts
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
  }
  if (entry is Map) {
    final opts = entry['options'] ?? entry['choices'];
    if (opts is List) {
      return opts.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
  }
  return const [];
}

class ComfyHistoryGraph {
  final String promptId;
  final Map<String, dynamic> graph;

  const ComfyHistoryGraph({
    required this.promptId,
    required this.graph,
  });

  String get json => jsonEncode(graph);

  String? get loaderLabel {
    final unet = firstInputValue(graph, 'unet_name');
    if (unet != null && unet.isNotEmpty) return unet;
    return firstInputValue(graph, 'ckpt_name');
  }
}

/// Newest-first graphs from `GET /history`.
List<ComfyHistoryGraph> parseComfyHistory(Object? decoded) {
  if (decoded is! Map) return const [];
  final entries = <({int order, ComfyHistoryGraph graph})>[];
  decoded.forEach((key, value) {
    if (value is! Map) return;
    final graph = extractComfyPromptGraph(value);
    if (graph == null || graph.isEmpty) return;
    final promptId = key.toString();
    var order = 0;
    final prompt = value['prompt'];
    if (prompt is List && prompt.isNotEmpty && prompt.first is num) {
      order = (prompt.first as num).toInt();
    }
    entries.add((
      order: order,
      graph: ComfyHistoryGraph(promptId: promptId, graph: graph),
    ));
  });
  entries.sort((a, b) => b.order.compareTo(a.order));
  return [for (final e in entries) e.graph];
}

Map<String, dynamic>? extractComfyPromptGraph(Object? historyEntry) {
  if (historyEntry is! Map) return null;
  final prompt = historyEntry['prompt'];
  if (prompt is List && prompt.length > 2 && prompt[2] is Map) {
    return _stringKeyMap(prompt[2] as Map);
  }
  if (prompt is Map) {
    final nested = prompt['prompt'];
    if (nested is Map) return _stringKeyMap(nested);
    final asGraph = _stringKeyMap(prompt);
    if (_looksLikePromptGraph(asGraph)) return asGraph;
  }
  final workflow = historyEntry['workflow'];
  if (workflow is Map) {
    final asGraph = _stringKeyMap(workflow);
    if (_looksLikePromptGraph(asGraph)) return asGraph;
  }
  return null;
}

String? firstInputValue(Map<String, dynamic> graph, String inputName) {
  for (final value in graph.values) {
    if (value is! Map) continue;
    final inputs = value['inputs'];
    if (inputs is! Map) continue;
    final raw = inputs[inputName];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  }
  return null;
}

bool _looksLikePromptGraph(Map<String, dynamic> workflow) {
  return workflow.values.any(
    (value) => value is Map && value['class_type'] is String,
  );
}

/// True when a `/history/{id}` entry is an interrupted/cancelled run.
bool comfyHistoryWasInterrupted(Object? historyEntry) {
  if (historyEntry is! Map) return false;
  bool interrupted(Object? value) {
    final text = value?.toString().toLowerCase() ?? '';
    return text.contains('interrupt');
  }

  if (interrupted(historyEntry['status_str'])) return true;
  final status = historyEntry['status'];
  if (status is Map) {
    if (interrupted(status['status_str'])) return true;
    final messages = status['messages'];
    if (messages is List) {
      for (final message in messages) {
        if (interrupted(message)) return true;
        if (message is List &&
            message.isNotEmpty &&
            interrupted(message.first)) {
          return true;
        }
      }
    }
  }
  return false;
}

/// Real-time sampler progress from ComfyUI's `/ws` JSON messages.
class ComfyProgressEvent {
  final double? samplerFraction;
  final bool finished;

  const ComfyProgressEvent({this.samplerFraction, this.finished = false});
}

ComfyProgressEvent? parseComfyProgressEvent(
  Object? decoded, {
  String? promptId,
}) {
  Object? message = decoded;
  if (message is String) {
    try {
      message = jsonDecode(message);
    } catch (_) {
      return null;
    }
  }
  if (message is! Map) return null;
  final type = message['type']?.toString();
  final data = message['data'];

  bool matchesPrompt(Object? rawId) {
    if (promptId == null || promptId.isEmpty) return true;
    final id = rawId?.toString() ?? '';
    return id.isEmpty || id == promptId;
  }

  if (type == 'progress' && data is Map) {
    if (!matchesPrompt(data['prompt_id'])) return null;
    final value = _comfyProgressNumber(data['value']);
    final max = _comfyProgressNumber(data['max']);
    // CLIP/VAE often emit 1/1 — that is not sampler progress.
    if (value == null || max == null || max <= 1) return null;
    return ComfyProgressEvent(samplerFraction: (value / max).clamp(0.0, 1.0));
  }

  if (type == 'progress_state' && data is Map) {
    if (!matchesPrompt(data['prompt_id'])) return null;
    final nodes = data['nodes'];
    if (nodes is Map) {
      Map? best;
      var bestMax = 1.0;
      for (final node in nodes.values) {
        if (node is! Map) continue;
        final max = _comfyProgressNumber(node['max']) ?? 0;
        if (max > bestMax) {
          bestMax = max;
          best = node;
        }
      }
      if (best != null) {
        final value = _comfyProgressNumber(best['value']) ?? 0;
        return ComfyProgressEvent(
          samplerFraction: (value / bestMax).clamp(0.0, 1.0),
        );
      }
    }
  }

  if (type == 'executing' && data is Map) {
    if (!matchesPrompt(data['prompt_id'])) return null;
    final node = data['node'];
    if (node == null || node.toString().isEmpty) {
      return const ComfyProgressEvent(finished: true);
    }
  }

  return null;
}

double? _comfyProgressNumber(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double comfyDisplayProgressFromSampler(double samplerFraction) {
  return (0.06 + 0.84 * samplerFraction.clamp(0.0, 1.0)).clamp(0.0, 0.9);
}

/// Widget order for Comfy canvas `widgets_values` (UI workflow → API).
const kComfyUiWidgetInputOrder = <String, List<String>>{
  'UNETLoader': ['unet_name', 'weight_dtype'],
  'CLIPLoader': ['clip_name', 'type', 'device'],
  'VAELoader': ['vae_name'],
  'CLIPTextEncode': ['text'],
  'EmptyLatentImage': ['width', 'height', 'batch_size'],
  'EmptySD3LatentImage': ['width', 'height', 'batch_size'],
  'ModelSamplingAuraFlow': ['shift'],
  'KSampler': [
    'seed',
    'control_after_generate',
    'steps',
    'cfg',
    'sampler_name',
    'scheduler',
    'denoise',
  ],
  'SaveImage': ['filename_prefix'],
  'CheckpointLoaderSimple': ['ckpt_name'],
  'LoraLoader': ['lora_name', 'strength_model', 'strength_clip'],
};

bool looksLikeComfyUiWorkflow(Object? decoded) {
  if (decoded is! Map) return false;
  return decoded['nodes'] is List && decoded.containsKey('links');
}

/// Node id referenced by an API input link `[nodeId, slot]`.
String? comfyLinkNodeId(Object? value) {
  if (value is List && value.isNotEmpty) {
    final nodeId = value.first;
    if (nodeId is String && nodeId.isNotEmpty) return nodeId;
    if (nodeId is int) return nodeId.toString();
  }
  return null;
}

/// Writes [positivePrompt] onto the positive conditioning branch and
/// [negativePrompt] onto text encoders that are only on the negative branch.
///
/// Z-Image's official graph (and a lot of saved / last-run graphs) does not
/// have a second text encoder. The sampler's negative input is
/// ConditioningZeroOut of the positive CLIPTextEncode. Walking that link and
/// writing the negative string replaces the prompt. With ComfyUI negatives
/// off, that string is empty, and an empty Z-Image prompt renders as a monkey.
void applyComfyConditioningPrompts(
  Map<String, dynamic> workflow, {
  required String? positiveNodeId,
  required String? negativeNodeId,
  required String positivePrompt,
  required String negativePrompt,
}) {
  final protected = <String>{};
  if (positiveNodeId != null && positiveNodeId.isNotEmpty) {
    _walkComfyPromptBranch(workflow, positiveNodeId, (id, inputs, classType) {
      protected.add(id);
    }, <String>{});
    _walkComfyPromptBranch(workflow, positiveNodeId, (id, inputs, classType) {
      _writeComfyPrompt(
        inputs,
        positivePrompt,
        _kPositivePromptKeys,
        classType,
      );
    }, <String>{});
  }
  if (negativeNodeId != null && negativeNodeId.isNotEmpty) {
    _walkComfyPromptBranch(workflow, negativeNodeId, (id, inputs, classType) {
      if (protected.contains(id)) return;
      _writeComfyPrompt(
        inputs,
        negativePrompt,
        _kNegativePromptKeys,
        classType,
      );
    }, <String>{});
  }
}

const _kPositivePromptKeys = [
  'text',
  'text_g',
  'text_l',
  'prompt',
  'positive_prompt',
  'value',
  'string',
];

const _kNegativePromptKeys = [
  'text',
  'text_g',
  'text_l',
  'prompt',
  'negative_prompt',
  'value',
  'string',
];

const _kUiOnlyComfyNodes = {'MarkdownNote', 'Note', 'Note+'};

/// Convert a Comfy canvas save (`nodes` + `links`) into an API prompt graph.
/// Returns null when [decoded] is not UI format.
///
/// Subgraph workflows (the official Z-Image template) are inlined first. The
/// real CLIPTextEncode / KSampler live inside `definitions.subgraphs`; the
/// top-level node is only a UUID wrapper with an empty widget list.
Map<String, dynamic>? convertComfyUiWorkflowToApi(Object? decoded) {
  if (!looksLikeComfyUiWorkflow(decoded) || decoded is! Map) return null;
  final flat = _flattenComfySubgraphs(decoded);
  final nodes = flat['nodes'];
  final links = flat['links'];
  if (nodes is! List) return null;

  final byLinkId = <int, List<dynamic>>{};
  if (links is List) {
    for (final link in links) {
      if (link is! List || link.length < 5) continue;
      final id = _asInt(link[0]);
      if (id == null) continue;
      byLinkId[id] = link;
    }
  }

  final graph = <String, dynamic>{};
  for (final node in nodes) {
    if (node is! Map) continue;
    final id = node['id'];
    if (id == null) continue;
    final classType = node['type']?.toString() ?? '';
    if (classType.isEmpty || _kUiOnlyComfyNodes.contains(classType)) continue;
    final inputs = <String, dynamic>{};

    final nodeInputs = node['inputs'];
    if (nodeInputs is List) {
      for (final input in nodeInputs) {
        if (input is! Map) continue;
        final name = input['name']?.toString();
        if (name == null || name.isEmpty) continue;
        final linkId = _asInt(input['link']);
        if (linkId == null) continue;
        final link = byLinkId[linkId];
        if (link == null) continue;
        final srcId = link[1];
        if (_isComfyBoundaryId(srcId)) continue;
        final srcSlot = _asInt(link[2]) ?? 0;
        inputs[name] = [srcId.toString(), srcSlot];
      }
    }

    final widgets = node['widgets_values'];
    final order = kComfyUiWidgetInputOrder[classType] ?? const <String>[];
    if (widgets is List && order.isNotEmpty) {
      var widgetIndex = 0;
      for (final key in order) {
        if (widgetIndex >= widgets.length) break;
        if (key == 'control_after_generate') {
          widgetIndex++;
          continue;
        }
        // A linked widget is still present in widgets_values. Skip the slot
        // or cfg/sampler slide onto the seed's "randomize" control.
        if (inputs.containsKey(key)) {
          widgetIndex++;
          continue;
        }
        inputs[key] = widgets[widgetIndex];
        widgetIndex++;
      }
    }

    graph[id.toString()] = {
      'class_type': classType,
      'inputs': inputs,
    };
  }
  return graph.isEmpty ? null : graph;
}

Map _flattenComfySubgraphs(Map decoded) {
  var flat = decoded;
  for (var depth = 0; depth < 4; depth++) {
    final next = _flattenComfySubgraphsOnce(flat);
    if (identical(next, flat)) break;
    flat = next;
  }
  return flat;
}

Map _flattenComfySubgraphsOnce(Map decoded) {
  final subgraphs = _comfySubgraphIndex(decoded['definitions']);
  final nodes = decoded['nodes'];
  if (subgraphs.isEmpty || nodes is! List) return decoded;
  final used = nodes.any(
    (node) => node is Map && subgraphs.containsKey(node['type']?.toString()),
  );
  if (!used) return decoded;

  final subgraphNodeIds = <String>{
    for (final node in nodes)
      if (node is Map && subgraphs.containsKey(node['type']?.toString()))
        node['id'].toString(),
  };

  final outNodes = <Object?>[];
  final outLinks = <List<dynamic>>[
    for (final link in _normalizeComfyLinks(decoded['links']))
      List<dynamic>.from(link),
  ];
  var nextLinkId = 1;
  for (final link in outLinks) {
    final id = _asInt(link[0]);
    if (id != null && id >= nextLinkId) nextLinkId = id + 1;
  }

  final outputSources = <String, List<Object?>>{};

  for (final node in nodes) {
    if (node is! Map) continue;
    final type = node['type']?.toString() ?? '';
    final subgraph = subgraphs[type];
    if (subgraph == null) {
      outNodes.add(node);
      continue;
    }

    final outerId = node['id'].toString();
    final prefix = '${outerId}_';
    final innerNodes = subgraph['nodes'];
    final innerById = <String, Map>{};
    if (innerNodes is List) {
      for (final inner in innerNodes) {
        if (inner is Map && inner['id'] != null) {
          innerById[inner['id'].toString()] = inner;
        }
      }
    }

    final sgInputs = subgraph['inputs'];
    final inputBySlot = <int, Map>{};
    if (sgInputs is List) {
      for (var i = 0; i < sgInputs.length; i++) {
        final input = sgInputs[i];
        if (input is Map) inputBySlot[i] = input;
      }
    }
    final outerInputs = <String, Map>{};
    final rawOuterInputs = node['inputs'];
    if (rawOuterInputs is List) {
      for (final input in rawOuterInputs) {
        if (input is Map && input['name'] != null) {
          outerInputs[input['name'].toString()] = input;
        }
      }
    }
    final outerWidgets = node['widgets_values'];

    final dropLinks = <int>{};
    final keepAsOuterLink = <int, int>{};
    final widgetOverrides = <String, Map<String, Object?>>{};

    for (final link in _normalizeComfyLinks(subgraph['links'])) {
      final linkId = _asInt(link[0]);
      if (linkId == null) continue;
      if (_isComfyBoundaryId(link[3])) {
        outputSources['$outerId:${link[4]}'] = [
          '$prefix${link[1]}',
          link[2],
        ];
        continue;
      }
      if (!_isComfyBoundaryId(link[1])) continue;

      final slot = _asInt(link[2]) ?? 0;
      final inputName = inputBySlot[slot]?['name']?.toString();
      final outerLinkId = _asInt(
        inputName == null ? null : outerInputs[inputName]?['link'],
      );
      if (outerLinkId != null) {
        for (final outerLink in outLinks) {
          if (_asInt(outerLink[0]) != outerLinkId) continue;
          outerLink[3] = '$prefix${link[3]}';
          outerLink[4] = link[4];
          break;
        }
        keepAsOuterLink[linkId] = outerLinkId;
      } else {
        dropLinks.add(linkId);
        final targetId = link[3].toString();
        final target = innerById[targetId];
        final widgetName =
            target == null ? null : _comfyInputNameForLink(target, linkId);
        final override = outerWidgets is List && slot < outerWidgets.length
            ? outerWidgets[slot]
            : null;
        if (widgetName != null && override != null) {
          (widgetOverrides[targetId] ??= {})[widgetName] = override;
        }
      }
    }

    final remap = <int, int>{};
    for (final link in _normalizeComfyLinks(subgraph['links'])) {
      if (_isComfyBoundaryId(link[1]) || _isComfyBoundaryId(link[3])) continue;
      final oldId = _asInt(link[0]);
      if (oldId == null) continue;
      final newId = nextLinkId++;
      remap[oldId] = newId;
      outLinks.add([
        newId,
        '$prefix${link[1]}',
        link[2],
        '$prefix${link[3]}',
        link[4],
        link.length > 5 ? link[5] : null,
      ]);
    }

    if (innerNodes is! List) continue;
    for (final raw in innerNodes) {
      if (raw is! Map) continue;
      final clone = _deepCopy(raw);
      final rawId = raw['id'].toString();
      clone['id'] = '$prefix$rawId';
      _retargetComfyInputLinks(clone, remap, dropLinks, keepAsOuterLink);
      final overrides = widgetOverrides[rawId];
      if (overrides != null) {
        _applyWidgetOverrides(
          clone,
          clone['type']?.toString() ?? '',
          overrides,
        );
      }
      outNodes.add(clone);
    }
  }

  for (final link in outLinks) {
    final origin = link[1].toString();
    if (!subgraphNodeIds.contains(origin)) continue;
    final source = outputSources['$origin:${link[2]}'];
    if (source == null) continue;
    link[1] = source[0];
    link[2] = source[1];
  }

  return {
    'nodes': outNodes,
    'links': outLinks,
    if (decoded['definitions'] != null) 'definitions': decoded['definitions'],
  };
}

Map<String, Map> _comfySubgraphIndex(Object? definitions) {
  if (definitions is! Map) return const {};
  final raw = definitions['subgraphs'];
  final out = <String, Map>{};
  if (raw is List) {
    for (final subgraph in raw) {
      if (subgraph is Map && subgraph['id'] != null) {
        out[subgraph['id'].toString()] = subgraph;
      }
    }
  } else if (raw is Map) {
    for (final entry in raw.entries) {
      if (entry.value is Map) out[entry.key.toString()] = entry.value as Map;
    }
  }
  return out;
}

List<List<dynamic>> _normalizeComfyLinks(Object? raw) {
  if (raw is! List) return const [];
  final out = <List<dynamic>>[];
  for (final link in raw) {
    if (link is List && link.length >= 5) {
      final id = _asInt(link[0]);
      final originSlot = _asInt(link[2]);
      final targetSlot = _asInt(link[4]);
      if (id == null || link[1] == null || originSlot == null) continue;
      if (link[3] == null || targetSlot == null) continue;
      out.add([
        id,
        link[1],
        originSlot,
        link[3],
        targetSlot,
        if (link.length > 5) link[5],
      ]);
    } else if (link is Map) {
      final id = _asInt(link['id']);
      final originSlot = _asInt(link['origin_slot']);
      final targetSlot = _asInt(link['target_slot']);
      final origin = link['origin_id'];
      final target = link['target_id'];
      if (id == null || origin == null || originSlot == null) continue;
      if (target == null || targetSlot == null) continue;
      out.add([
        id,
        origin,
        originSlot,
        target,
        targetSlot,
        link['type'],
      ]);
    }
  }
  return out;
}

bool _isComfyBoundaryId(Object? id) {
  if (id is num) return id < 0;
  final parsed = int.tryParse(id?.toString() ?? '');
  return parsed != null && parsed < 0;
}

String? _comfyInputNameForLink(Map node, int linkId) {
  final inputs = node['inputs'];
  if (inputs is! List) return null;
  for (final input in inputs) {
    if (input is Map && _asInt(input['link']) == linkId) {
      final name = input['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
    }
  }
  return null;
}

void _retargetComfyInputLinks(
  Map node,
  Map<int, int> remap,
  Set<int> dropLinks,
  Map<int, int> keepAsOuterLink,
) {
  final inputs = node['inputs'];
  if (inputs is! List) return;
  for (final input in inputs) {
    if (input is! Map) continue;
    final linkId = _asInt(input['link']);
    if (linkId == null) continue;
    final outer = keepAsOuterLink[linkId];
    if (outer != null) {
      input['link'] = outer;
    } else if (dropLinks.contains(linkId)) {
      input['link'] = null;
    } else {
      final mapped = remap[linkId];
      if (mapped != null) input['link'] = mapped;
    }
  }
}

void _applyWidgetOverrides(
  Map node,
  String classType,
  Map<String, Object?> overrides,
) {
  final order = kComfyUiWidgetInputOrder[classType];
  final widgets = node['widgets_values'];
  if (order == null || widgets is! List) return;
  for (final entry in overrides.entries) {
    final index = order.indexOf(entry.key);
    if (index < 0 || index >= widgets.length || entry.value == null) continue;
    widgets[index] = entry.value;
  }
}

Map<String, dynamic> _deepCopy(Map value) {
  final copy = <String, dynamic>{};
  for (final entry in value.entries) {
    copy[entry.key.toString()] = _deepCopyValue(entry.value);
  }
  return copy;
}

Object? _deepCopyValue(Object? value) {
  if (value is Map) return _deepCopy(value);
  if (value is List) {
    return [for (final item in value) _deepCopyValue(item)];
  }
  return value;
}

void _walkComfyPromptBranch(
  Map<String, dynamic> workflow,
  String nodeId,
  void Function(String id, Map inputs, String classType) onHolder,
  Set<String> visited,
) {
  if (!visited.add(nodeId)) return;
  final node = workflow[nodeId];
  if (node is! Map) return;
  final inputs = node['inputs'];
  if (inputs is! Map) return;
  final classType = node['class_type']?.toString() ?? '';
  if (_comfyNodeHoldsPrompt(classType, inputs)) {
    onHolder(nodeId, inputs, classType);
    return;
  }
  for (final value in inputs.values) {
    final next = comfyLinkNodeId(value);
    if (next != null) {
      _walkComfyPromptBranch(workflow, next, onHolder, visited);
    }
  }
}

bool _comfyNodeHoldsPrompt(String classType, Map inputs) {
  final type = classType.toLowerCase();
  if (type.contains('textencode')) return true;
  final textual = type.contains('string') ||
      type.contains('primitive') ||
      type.contains('prompt') ||
      type.contains('text');
  if (!textual) return false;
  for (final key in _kPositivePromptKeys) {
    if (inputs.containsKey(key)) return true;
  }
  return false;
}

void _writeComfyPrompt(
  Map inputs,
  String prompt,
  List<String> keys,
  String classType,
) {
  var wrote = false;
  for (final key in keys) {
    if (!inputs.containsKey(key)) continue;
    final current = inputs[key];
    if (current is String || current is List) {
      inputs[key] = prompt;
      wrote = true;
    }
  }
  if (!wrote && classType.toLowerCase().contains('textencode')) {
    inputs['text'] = prompt;
  }
}

/// One editable widget value from a Comfy graph.
class ComfyWorkflowField {
  final String nodeId;
  final String classType;
  final String name;
  final Object value;

  const ComfyWorkflowField({
    required this.nodeId,
    required this.classType,
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'classType': classType,
        'name': name,
        'value': value,
      };
}

/// Sampler, size, and model values read off a prompt graph, plus the other
/// scalar widgets that Mini does not already have a control for.
class ComfyWorkflowControls {
  final int? steps;
  final double? cfg;
  final String? sampler;
  final String? scheduler;
  final int? seed;
  final int? width;
  final int? height;
  final int? batchSize;
  final String? modelName;
  final List<ComfyWorkflowField> fields;

  const ComfyWorkflowControls({
    this.steps,
    this.cfg,
    this.sampler,
    this.scheduler,
    this.seed,
    this.width,
    this.height,
    this.batchSize,
    this.modelName,
    this.fields = const [],
  });
}

const _kComfyPromptInputNames = {
  'text',
  'text_g',
  'text_l',
  'prompt',
  'positive_prompt',
  'negative_prompt',
  'filename_prefix',
  'control_after_generate',
};

const _kComfyStandardInputNames = {
  'steps',
  'cfg',
  'sampler_name',
  'sampler',
  'scheduler',
  'seed',
  'noise_seed',
  'width',
  'height',
  'batch_size',
  'ckpt_name',
  'unet_name',
};

/// Label for a saved workflow file, without the `.json` suffix.
String comfyWorkflowDisplayName(String fileName) {
  final trimmed = fileName.trim();
  if (trimmed.toLowerCase().endsWith('.json')) {
    return trimmed.substring(0, trimmed.length - 5);
  }
  return trimmed;
}

/// File stem for a workflow name the user typed. Throws if nothing usable remains.
String comfyWorkflowFileStem(String name) {
  var stem = name.trim();
  if (stem.toLowerCase().endsWith('.json')) {
    stem = stem.substring(0, stem.length - 5).trim();
  }
  stem = stem.replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001f]'), ' ');
  stem = stem.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (stem.isEmpty || stem == '.' || stem == '..') {
    throw const FormatException('Enter a workflow name');
  }
  return stem;
}

/// Path under Comfy userdata for [name]. Reuses an existing file with the same
/// stem so a second run updates that workflow instead of adding a duplicate.
String comfyNamedWorkflowPath(String name, Iterable<String> existingPaths) {
  final stem = comfyWorkflowFileStem(name);
  final wanted = stem.toLowerCase();
  for (final path in existingPaths) {
    if (isComfyBuiltinWorkflowPath(path) || isComfyLastRunWorkflowPath(path)) {
      continue;
    }
    final file = path.split('/').last;
    try {
      if (comfyWorkflowFileStem(file).toLowerCase() == wanted) return path;
    } on FormatException {
      continue;
    }
  }
  return 'workflows/$stem.json';
}

String comfyWorkflowSettingsKey(String? path, String? json) {
  final trimmedPath = path?.trim() ?? '';
  if (trimmedPath.isNotEmpty) return trimmedPath;
  if ((json ?? '').trim().isNotEmpty) return kComfyCustomJsonWorkflowKey;
  return '';
}

/// API graph from either an API prompt or a Comfy canvas save.
Map<String, dynamic>? comfyGraphFromWorkflowText(String template) {
  Object? decoded;
  try {
    decoded = jsonDecode(template);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;
  if (looksLikeComfyUiWorkflow(decoded)) {
    return convertComfyUiWorkflowToApi(decoded);
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

/// Workflow text Mini can queue. Null when [raw] is empty or has no prompt node.
String? comfyUsableWorkflowText(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  final graph = comfyGraphFromWorkflowText(text);
  if (graph == null || graph.isEmpty) return null;
  final hasNode = graph.values.any(
    (value) => value is Map && value['class_type'] is String,
  );
  if (!hasNode) return null;
  return text;
}

/// The file name Comfy sends back from `POST /userdata`, not a prompt graph.
///
/// A successful save responds with the relative path, for example
/// `"workflows/Qwen Image.json"`. That string must not be queued as the next
/// workflow.
String? comfyWorkflowNameOnly(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty || text.startsWith('{') || text.startsWith('[')) {
    return null;
  }
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    decoded = text;
  }
  if (decoded is! String) return null;
  final value = decoded.trim();
  if (value.isEmpty ||
      value.length > 300 ||
      value.contains('\n') ||
      value.startsWith('{') ||
      value.startsWith('[')) {
    return null;
  }
  final lower = value.toLowerCase();
  if (!lower.endsWith('.json') && !lower.contains('/')) return null;
  return value;
}

/// Reads steps, sampler, scheduler, size, model, and the other scalar widgets.
ComfyWorkflowControls extractComfyWorkflowControls(
    Map<String, dynamic> workflow) {
  int? steps;
  double? cfg;
  String? sampler;
  String? scheduler;
  int? seed;
  int? width;
  int? height;
  int? batchSize;
  String? modelName;
  final fields = <ComfyWorkflowField>[];

  for (final entry in workflow.entries) {
    final node = entry.value;
    if (node is! Map) continue;
    final inputs = node['inputs'];
    if (inputs is! Map) continue;
    final classType = node['class_type']?.toString() ?? '';
    if (classType.isEmpty) continue;
    final takesControls = comfyNodeTakesGenerationControls(classType, inputs);

    if (takesControls) {
      steps ??= _comfyIntInput(inputs, const ['steps']);
      cfg ??= _comfyDoubleInput(inputs, const ['cfg']);
      sampler ??= _comfyStringInput(inputs, const ['sampler_name', 'sampler']);
      scheduler ??= _comfyStringInput(inputs, const ['scheduler']);
      seed ??= _comfyIntInput(inputs, const ['seed', 'noise_seed']);
      width ??= _comfyIntInput(inputs, const ['width']);
      height ??= _comfyIntInput(inputs, const ['height']);
      batchSize ??= _comfyIntInput(inputs, const ['batch_size']);
    }
    if (classType.startsWith('Empty')) {
      width ??= _comfyIntInput(inputs, const ['width']);
      height ??= _comfyIntInput(inputs, const ['height']);
      batchSize ??= _comfyIntInput(inputs, const ['batch_size']);
    }
    modelName ??= _comfyStringInput(inputs, const ['unet_name', 'ckpt_name']);

    for (final input in inputs.entries) {
      final name = input.key.toString();
      if (_kComfyPromptInputNames.contains(name) ||
          _kComfyStandardInputNames.contains(name)) {
        continue;
      }
      final value = input.value;
      if (!_comfyScalarValue(value)) continue;
      if (value is String && value.length > 180) continue;
      fields.add(
        ComfyWorkflowField(
          nodeId: entry.key.toString(),
          classType: classType,
          name: name,
          value: value as Object,
        ),
      );
    }
  }

  return ComfyWorkflowControls(
    steps: steps,
    cfg: cfg,
    sampler: sampler,
    scheduler: scheduler,
    seed: seed,
    width: width,
    height: height,
    batchSize: batchSize,
    modelName: modelName,
    fields: fields,
  );
}

/// Writes Mini's generation controls onto sampler nodes and latent size nodes.
///
/// Linked widgets are replaced with the literal value, so a Resolution
/// Selector wire does not keep the graph's old steps.
void applyComfyGenerationControls(
  Map<String, dynamic> workflow, {
  int? steps,
  double? cfg,
  String? samplerName,
  String? schedulerName,
  int? seed,
  int? width,
  int? height,
  int? batchSize,
}) {
  for (final node in workflow.values) {
    if (node is! Map) continue;
    final inputs = node['inputs'];
    if (inputs is! Map) continue;
    final classType = node['class_type']?.toString() ?? '';
    final takesControls = comfyNodeTakesGenerationControls(classType, inputs);
    final sizesLatent = takesControls || classType.startsWith('Empty');
    if (takesControls) {
      if (steps != null) _writeComfyControl(inputs, 'steps', steps);
      if (cfg != null) _writeComfyControl(inputs, 'cfg', cfg);
      if (samplerName != null && samplerName.trim().isNotEmpty) {
        final name = samplerName.trim();
        _writeComfyControl(inputs, 'sampler_name', name);
        _writeComfyControl(inputs, 'sampler', name);
      }
      if (schedulerName != null && schedulerName.trim().isNotEmpty) {
        _writeComfyControl(inputs, 'scheduler', schedulerName.trim());
      }
      if (seed != null) {
        _writeComfyControl(inputs, 'seed', seed);
        _writeComfyControl(inputs, 'noise_seed', seed);
      }
    }
    if (sizesLatent) {
      // Leave wired width/height alone so a Resolution Selector keeps control.
      if (width != null) {
        _writeComfyControl(inputs, 'width', width, replaceLinks: false);
      }
      if (height != null) {
        _writeComfyControl(inputs, 'height', height, replaceLinks: false);
      }
      if (batchSize != null) {
        _writeComfyControl(inputs, 'batch_size', batchSize,
            replaceLinks: false);
      }
    }
  }
}

/// Writes saved extra widgets (CLIP, VAE, shift, megapixels, …) back onto
/// the nodes they came from. Wires are left alone.
void applyComfyWorkflowFields(
  Map<String, dynamic> workflow,
  List<Map<String, dynamic>> fields,
) {
  for (final field in fields) {
    final nodeId = field['nodeId']?.toString();
    final name = field['name']?.toString();
    final value = field['value'];
    if (nodeId == null || nodeId.isEmpty || name == null || name.isEmpty) {
      continue;
    }
    if (value == null || value is List || value is Map) continue;
    final node = workflow[nodeId];
    if (node is! Map) continue;
    final inputs = node['inputs'];
    if (inputs is! Map || !inputs.containsKey(name)) continue;
    final current = inputs[name];
    if (current is List || current is Map) continue;
    inputs[name] = value;
  }
}

bool comfyNodeTakesGenerationControls(String classType, Map inputs) {
  final type = classType.toLowerCase();
  if (type == 'ksampler' || type == 'ksampleradvanced') return true;
  if (type.contains('scheduler') &&
      (inputs.containsKey('steps') || inputs.containsKey('scheduler'))) {
    return true;
  }
  if (type.contains('sampler') &&
      (inputs.containsKey('steps') ||
          inputs.containsKey('sampler_name') ||
          inputs.containsKey('sampler') ||
          inputs.containsKey('cfg'))) {
    return true;
  }
  if (type.contains('guider') && inputs.containsKey('cfg')) return true;
  final hasSteps = inputs.containsKey('steps');
  final hasSampler =
      inputs.containsKey('sampler_name') || inputs.containsKey('sampler');
  return hasSteps && hasSampler;
}

bool _comfyScalarValue(Object? value) =>
    value is num || value is String || value is bool;

int? _comfyIntInput(Map inputs, List<String> keys) {
  for (final key in keys) {
    final value = inputs[key];
    if (value is int) return value;
    if (value is num) return value.round();
  }
  return null;
}

double? _comfyDoubleInput(Map inputs, List<String> keys) {
  for (final key in keys) {
    final value = inputs[key];
    if (value is num) return value.toDouble();
  }
  return null;
}

String? _comfyStringInput(Map inputs, List<String> keys) {
  for (final key in keys) {
    final value = inputs[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

void _writeComfyControl(
  Map inputs,
  String key,
  Object value, {
  bool replaceLinks = true,
}) {
  if (!inputs.containsKey(key)) return;
  final current = inputs[key];
  if (current is List) {
    if (replaceLinks) inputs[key] = value;
    return;
  }
  if (current is num || current is String || current is bool) {
    inputs[key] = value;
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

Map<String, dynamic> _stringKeyMap(Map map) {
  return map.map((k, v) => MapEntry(k.toString(), v));
}
