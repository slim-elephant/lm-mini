import 'dart:convert';

/// ComfyUI `/prompt` validation — usually a missing checkpoint, not a Mini crash.
enum ComfyUiPromptErrorKind {
  /// ComfyUI's checkpoint list is empty (`ckpt_name: '' not in []`).
  noCheckpoints,

  /// Mini sent an empty checkpoint name but the server does have models.
  noCheckpointSelected,

  /// Mini sent a name ComfyUI does not have.
  unknownCheckpoint,

  /// Comfy has UNET/diffusion models, but Mini's built-in graph wants a
  /// classic CheckpointLoaderSimple file.
  diffusionOnly,

  /// Other workflow validation (sampler, missing node, …).
  workflowRejected,
}

final class ComfyUiPromptError {
  final ComfyUiPromptErrorKind kind;
  final String? checkpointName;

  const ComfyUiPromptError({
    required this.kind,
    this.checkpointName,
  });

  bool get isCheckpointSetup => kind != ComfyUiPromptErrorKind.workflowRejected;

  static const noCheckpointsUserMessage =
      'ComfyUI has no checkpoint to load. Add a .safetensors file to ComfyUI’s '
      'models/checkpoints folder, then pick it in Image Generation settings.';

  static const noCheckpointSelectedUserMessage =
      'No image model is selected. Open Image Generation settings and pick a checkpoint.';

  static const unknownCheckpointUserMessage =
      "ComfyUI doesn't have that checkpoint. Pick another in Image Generation settings.";

  static const workflowRejectedUserMessage =
      'ComfyUI rejected the workflow. Check Image Generation settings.';

  static const diffusionOnlyUserMessage =
      "Mini's built-in ComfyUI workflow needs a classic Stable Diffusion "
      'checkpoint. Your ComfyUI is using diffusion/UNET models instead. '
      'Export your working graph as API Format (Workflow → Export) and pick '
      'it in Image Generation settings.';

  static String unknownCheckpointUserMessageFor(String? name) {
    final id = name?.trim() ?? '';
    if (id.isEmpty) return unknownCheckpointUserMessage;
    return 'ComfyUI doesn’t have checkpoint "$id". '
        'Pick another in Image Generation settings.';
  }

  String get userMessage => switch (kind) {
        ComfyUiPromptErrorKind.noCheckpoints => noCheckpointsUserMessage,
        ComfyUiPromptErrorKind.noCheckpointSelected =>
          noCheckpointSelectedUserMessage,
        ComfyUiPromptErrorKind.unknownCheckpoint =>
          unknownCheckpointUserMessageFor(checkpointName),
        ComfyUiPromptErrorKind.diffusionOnly => diffusionOnlyUserMessage,
        ComfyUiPromptErrorKind.workflowRejected => workflowRejectedUserMessage,
      };

  static bool matches(Object? error) => parse(error) != null;

  static String userMessageFor(Object? error) =>
      parse(error)?.userMessage ?? workflowRejectedUserMessage;

  static ComfyUiPromptError? parse(Object? error) {
    if (error == null) return null;

    final fromJson = _fromJson(_jsonFrom(error));
    if (fromJson != null) return fromJson;

    final lower = error.toString().toLowerCase();
    if (lower.isEmpty) return null;

    if (lower.contains('no checkpoint to load') ||
        lower.contains('models/checkpoints folder')) {
      return const ComfyUiPromptError(
        kind: ComfyUiPromptErrorKind.noCheckpoints,
      );
    }
    if (lower.contains('no image model is selected')) {
      return const ComfyUiPromptError(
        kind: ComfyUiPromptErrorKind.noCheckpointSelected,
      );
    }
    if (lower.contains("doesn't have checkpoint") ||
        lower.contains('doesn’t have checkpoint') ||
        lower.contains("doesn't have that checkpoint") ||
        lower.contains('doesn’t have that checkpoint')) {
      final named = RegExp(
        r'checkpoint\s+"([^"]+)"',
        caseSensitive: false,
      ).firstMatch(error.toString());
      return ComfyUiPromptError(
        kind: ComfyUiPromptErrorKind.unknownCheckpoint,
        checkpointName: named?.group(1),
      );
    }
    if (lower.contains('diffusion/unet') ||
        lower.contains('export your working graph as api format') ||
        lower.contains('load diffusion model')) {
      return const ComfyUiPromptError(
        kind: ComfyUiPromptErrorKind.diffusionOnly,
      );
    }
    if (lower.contains('rejected the workflow')) {
      return const ComfyUiPromptError(
        kind: ComfyUiPromptErrorKind.workflowRejected,
      );
    }
    if (_looksLikeComfyPrompt(lower)) {
      return const ComfyUiPromptError(
        kind: ComfyUiPromptErrorKind.workflowRejected,
      );
    }
    return null;
  }

  static bool _looksLikeComfyPrompt(String lower) {
    if (!lower.contains('comfyui')) return false;
    return lower.contains('/prompt failed') ||
        lower.contains('prompt_outputs_failed_validation') ||
        lower.contains('checkpointloadersimple') ||
        lower.contains('ckpt_name') ||
        lower.contains('unet_name');
  }

  static Map<String, dynamic>? _jsonFrom(Object? error) {
    if (error is Map<String, dynamic>) return error;
    if (error is Map) {
      return error.map((k, v) => MapEntry(k.toString(), v));
    }
    final text = error?.toString() ?? '';
    final idx = text.indexOf('{');
    if (idx < 0) return null;
    try {
      final decoded = jsonDecode(text.substring(idx));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return null;
  }

  static ComfyUiPromptError? _fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final nested = json['error'];
    final type =
        (nested is Map ? nested['type']?.toString() : json['type']?.toString())
            ?.toLowerCase();
    final isValidation = type == 'prompt_outputs_failed_validation' ||
        json.containsKey('node_errors');

    final ckpt = _checkpointIssue(json);
    if (ckpt != null) return ckpt;

    if (isValidation || _looksLikeComfyPrompt(json.toString().toLowerCase())) {
      return const ComfyUiPromptError(
        kind: ComfyUiPromptErrorKind.workflowRejected,
      );
    }
    return null;
  }

  static ComfyUiPromptError? _checkpointIssue(Map<String, dynamic> json) {
    final nodeErrors = json['node_errors'];
    if (nodeErrors is! Map) return null;

    for (final node in nodeErrors.values) {
      if (node is! Map) continue;
      final classType = node['class_type']?.toString() ?? '';
      final errors = node['errors'];
      if (errors is! List) continue;
      for (final err in errors) {
        if (err is! Map) continue;
        final extra = err['extra_info'];
        final extraMap = extra is Map
            ? extra.map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{};
        final inputName =
            (extraMap['input_name'] ?? '').toString().toLowerCase();
        final details = err['details']?.toString() ?? '';
        final received = extraMap['received_value']?.toString() ?? '';
        final isCkpt = inputName == 'ckpt_name' ||
            details.toLowerCase().contains('ckpt_name') ||
            classType == 'CheckpointLoaderSimple';
        if (!isCkpt) continue;

        final availableEmpty = _availableListIsEmpty(extraMap, details);
        if (availableEmpty) {
          return const ComfyUiPromptError(
            kind: ComfyUiPromptErrorKind.noCheckpoints,
          );
        }
        if (received.trim().isEmpty) {
          return const ComfyUiPromptError(
            kind: ComfyUiPromptErrorKind.noCheckpointSelected,
          );
        }
        return ComfyUiPromptError(
          kind: ComfyUiPromptErrorKind.unknownCheckpoint,
          checkpointName: received.trim(),
        );
      }
    }
    return null;
  }

  static bool _availableListIsEmpty(
    Map<String, dynamic> extra,
    String details,
  ) {
    if (RegExp(r"not in\s*\[\s*\]").hasMatch(details)) return true;
    final config = extra['input_config'];
    if (config is List && config.isNotEmpty) {
      final options = config.first;
      if (options is List && options.isEmpty) return true;
    }
    return false;
  }
}
