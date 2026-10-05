import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/system_prompt.dart';
import '../providers/settings_provider.dart';
import '../utils/persona_palette.dart';
import 'lm_studio_service.dart';
import 'on_device_llm_service.dart';
import 'persona_pack_catalog.dart';

/// Draft produced by the model before the user confirms save.
class GeneratedPersonaDraft {
  final String name;
  final String systemPrompt;
  final String gender;
  final String shortBio;
  final PersonaPackEntry avatar;

  const GeneratedPersonaDraft({
    required this.name,
    required this.systemPrompt,
    required this.gender,
    required this.shortBio,
    required this.avatar,
  });

  int get kokoroSpeakerId =>
      gender == 'female' ? _bellaSpeakerId : _adamSpeakerId;

  static const _adamSpeakerId = 5;
  static const _bellaSpeakerId = 1;
}

/// Uses the active chat provider to invent a persona, then maps it onto a
/// pack avatar + Kokoro voice.
class PersonaGeneratorService {
  PersonaGeneratorService._();
  static final PersonaGeneratorService instance = PersonaGeneratorService._();

  final LMStudioService _lm = LMStudioService();

  /// Max completion tokens for persona JSON (+ optional thinking).
  static const int maxOutputTokens = 4092;

  Future<GeneratedPersonaDraft> generate({
    required AppSettings settings,
    required String userDescription,
    /// When null, follows [AppSettings.reasoning]. When set, forces on/off
    /// for this generation only (does not change global settings).
    bool? reasoningEnabled,
    /// When true, the model invents any persona (no user brief required).
    bool surprise = false,
    /// Prior surprise result — ask the model to invent something different.
    String? avoidPersonaHint,
  }) async {
    final description = userDescription.trim();
    if (!surprise && description.isEmpty) {
      throw StateError('Describe the persona you want.');
    }

    final systemPrompt = _buildSystemPrompt();
    final userPrompt = surprise
        ? _buildSurpriseUserPrompt(avoidPersonaHint: avoidPersonaHint)
        : 'Create a persona for this request:\n\n$description\n\n'
            'Do not make it religious or faith-based.\n'
            'Respond with JSON only.';

    final reasoning = reasoningEnabled == null
        ? settings.reasoning
        : (reasoningEnabled ? (settings.reasoning == 'off' ? 'on' : settings.reasoning) : 'off');

    final genSettings = settings.copyWith(
      maxTokens: maxOutputTokens,
      temperature: surprise ? 1.0 : 0.8,
      enableToolUse: false,
      reasoning: reasoning,
      systemPrompt: '',
      selectedSystemPromptId: null,
    );

    final kind = settings.activeProviderKind;
    String raw;
    if (kind == 'onDeviceGguf' || kind == 'onDeviceMlx') {
      raw = await _generateOnDevice(genSettings, systemPrompt, userPrompt);
    } else {
      raw = await _generateRemote(genSettings, systemPrompt, userPrompt);
    }

    return _parseDraft(
      raw,
      fallbackDescription: surprise
          ? 'a surprising original persona'
          : description,
    );
  }

  String _buildSurpriseUserPrompt({String? avoidPersonaHint}) {
    final avoid = (avoidPersonaHint ?? '').trim();
    final differ = avoid.isEmpty
        ? ''
        : '\nMake it clearly different from this previous persona: $avoid.\n';
    return 'Surprise me with a completely original chat persona. '
        'Invent something unexpected, creative, and fun — you choose the '
        'concept, personality, and speaking style.$differ'
        'Do not make it religious or faith-based.\n'
        'Respond with JSON only.';
  }

  /// Copy pack avatar into documents, cache palette, and add to settings.
  Future<SystemPrompt> saveDraft({
    required GeneratedPersonaDraft draft,
    required SettingsProvider settingsProvider,
    bool selectAfterSave = true,
    String? name,
    int? kokoroSpeakerId,
    int? color,
    bool useAutoColor = true,
    String? defaultModelId,
    String? defaultProviderKind,
    String? defaultCloudProviderId,
  }) async {
    final now = DateTime.now();
    final id = 'sp_${now.millisecondsSinceEpoch}';
    final relativeAvatar = await _copyPackAvatar(draft.avatar, id);

    var prompt = SystemPrompt(
      id: id,
      name: (name ?? draft.name).trim().isEmpty
          ? draft.name
          : (name ?? draft.name).trim(),
      content: draft.systemPrompt,
      boundModelIds: null,
      createdAt: now,
      updatedAt: now,
      avatarPath: relativeAvatar,
      // Pack art is a full bust — keep bubble crop gentle (profile uses contain).
      avatarFocusX: 0,
      avatarFocusY: -0.18,
      avatarFocusScale: 1.15,
      color: color,
      defaultModelId: defaultModelId,
      defaultProviderKind: defaultProviderKind,
      defaultCloudProviderId: defaultCloudProviderId,
      kokoroSpeakerId: kokoroSpeakerId ?? draft.kokoroSpeakerId,
      shareMemories: true,
    );
    prompt = await PersonaPalette.ensureCached(prompt);
    // Accent chip / glass tint from the avatar palette when user left color auto.
    if (useAutoColor && color == null && prompt.palettePrimary != null) {
      prompt = prompt.copyWith(color: prompt.palettePrimary);
    }

    settingsProvider.addSystemPrompt(prompt);
    if (selectAfterSave) {
      settingsProvider.selectSystemPrompt(prompt.id);
      settingsProvider.updateSystemPrompt(prompt.content);
    }
    return prompt;
  }

  Future<String> _generateOnDevice(
    AppSettings settings,
    String systemPrompt,
    String userPrompt,
  ) async {
    final ready = await OnDeviceLLMService.instance.isReady(settings);
    if (!ready) {
      throw StateError(
        'No on-device model is ready. Download one in Settings → On-Device Models.',
      );
    }
    final buffer = StringBuffer();
    await for (final delta in OnDeviceLLMService.instance.streamChat(
      settings: settings,
      history: const [],
      userMessage: userPrompt,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(delta);
    }
    return buffer.toString();
  }

  Future<String> _generateRemote(
    AppSettings settings,
    String systemPrompt,
    String userPrompt,
  ) async {
    final url = settings.serverUrl.trim();
    if (url.isEmpty) {
      throw StateError(
        'No model server configured. Connect LM Studio, a cloud provider, '
        'or use an on-device model.',
      );
    }
    if ((settings.selectedModel ?? '').isEmpty) {
      throw StateError('No model selected.');
    }

    final messages = [
      ChatMessage(
        id: 'persona_gen_sys',
        role: 'system',
        content: systemPrompt,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        id: 'persona_gen_usr',
        role: 'user',
        content: userPrompt,
        timestamp: DateTime.now(),
      ),
    ];

    try {
      final buf = StringBuffer();
      final reasoningBuf = StringBuffer();
      String? fromChatEnd;
      await for (final evt in _lm.streamChatCompletionV1(
        baseUrl: url,
        messages: messages,
        settings: settings,
        apiToken: settings.apiToken,
        omitLoadParams: true,
      )) {
        final err = evt['error'];
        if (err != null) throw StateError(err.toString());

        final content = evt['content'];
        if (content is String && content.isNotEmpty) buf.write(content);

        final reasoning = evt['reasoning'];
        if (reasoning is String && reasoning.isNotEmpty) {
          reasoningBuf.write(reasoning);
        }

        // chat.end carries the aggregated message when deltas were empty
        // (common when the model spent the turn in a reasoning channel).
        if (evt['type'] == 'chat.end') {
          final extracted = _messageTextFromChatEndOutput(evt['output']);
          if (extracted != null && extracted.isNotEmpty) {
            fromChatEnd = extracted;
          }
        }
      }

      final streamed = buf.toString().trim();
      if (streamed.isNotEmpty) return streamed;
      if (fromChatEnd != null && fromChatEnd.trim().isNotEmpty) {
        return fromChatEnd.trim();
      }
      // Last resort before V0: some models put the JSON only after thinking
      // and never emit message.delta — try parsing JSON out of reasoning.
      final fromReasoning = reasoningBuf.toString().trim();
      if (fromReasoning.isNotEmpty && fromReasoning.contains('{')) {
        try {
          _extractJsonMap(fromReasoning);
          return fromReasoning;
        } catch (_) {}
      }
      if (kDebugMode) {
        debugPrint(
          'PersonaGeneratorService: V1 returned no message content — '
          'falling back to V0 once',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'PersonaGeneratorService: V1 stream failed, falling back: $e');
      }
    }

    final response = await _lm.getChatCompletion(
      baseUrl: url,
      messages: messages,
      settings: settings,
      apiToken: settings.apiToken,
    );
    final choices = response['choices'];
    if (choices is List && choices.isNotEmpty) {
      final msg = choices.first['message'];
      if (msg is Map && msg['content'] is String) {
        return msg['content'] as String;
      }
    }
    final content = response['content'];
    if (content is String && content.trim().isNotEmpty) return content;
    throw StateError('Empty response from model.');
  }

  /// Pull assistant message text from a V1 `chat.end` `output` array.
  String? _messageTextFromChatEndOutput(dynamic output) {
    if (output is! List) return null;
    final parts = <String>[];
    for (final raw in output) {
      if (raw is! Map) continue;
      final type = raw['type']?.toString().toLowerCase() ?? '';
      if (type.contains('reason') ||
          type.contains('tool') ||
          type.contains('function')) {
        continue;
      }
      final content = raw['content'];
      if (content is String && content.trim().isNotEmpty) {
        parts.add(content.trim());
        continue;
      }
      if (content is List) {
        for (final part in content) {
          if (part is Map) {
            final t = part['text'] ?? part['content'];
            if (t is String && t.trim().isNotEmpty) parts.add(t.trim());
          } else if (part is String && part.trim().isNotEmpty) {
            parts.add(part.trim());
          }
        }
      }
      final text = raw['text'];
      if (text is String && text.trim().isNotEmpty) parts.add(text.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  String _buildSystemPrompt() {
    // Keep this short — small on-device contexts (~1k tokens) cannot fit a
    // full avatar catalog. We pick the avatar on-device after parsing JSON.
    return '''
You invent chat personas for LM Mini.
Do not create religious, spiritual, clergy, deity, scripture, or faith-based personas.
After any private thinking, return ONLY one JSON object (no markdown fence, no extra text) with keys:
- name: short display name (2-4 words)
- systemPrompt: 4-20 sentences, second person ("You are…")
- gender: "male" or "female"
- shortBio: one short sentence
The final answer must be the JSON object starting with {.
''';
  }

  GeneratedPersonaDraft _parseDraft(
    String raw, {
    required String fallbackDescription,
  }) {
    final backendError = _looksLikeBackendError(raw);
    if (backendError != null) {
      throw StateError(backendError);
    }

    final jsonMap = _extractJsonMap(raw);
    final name = (jsonMap['name'] as String?)?.trim();
    final systemPrompt = (jsonMap['systemPrompt'] as String?)?.trim() ??
        (jsonMap['system_prompt'] as String?)?.trim();
    var gender = (jsonMap['gender'] as String?)?.trim().toLowerCase();
    if (gender != 'male' && gender != 'female') gender = null;
    final avatarId = (jsonMap['avatarId'] as String?)?.trim() ??
        (jsonMap['avatar_id'] as String?)?.trim();
    final shortBio = (jsonMap['shortBio'] as String?)?.trim() ??
        (jsonMap['short_bio'] as String?)?.trim() ??
        '';

    var avatar = PersonaPackCatalog.byId(avatarId);
    avatar ??= PersonaPackCatalog.matchFromText(
      '$fallbackDescription ${name ?? ''} ${systemPrompt ?? ''} $shortBio',
      preferredGender: gender,
    );

    final resolvedGender = gender ?? avatar.gender;
    final resolvedName = (name != null && name.isNotEmpty)
        ? name
        : avatar.label;
    final resolvedPrompt = (systemPrompt != null && systemPrompt.isNotEmpty)
        ? systemPrompt
        : 'You are $resolvedName. Stay in character, be helpful, and match '
            'the user\'s request for: $fallbackDescription';

    return GeneratedPersonaDraft(
      name: resolvedName,
      systemPrompt: resolvedPrompt,
      gender: resolvedGender,
      shortBio: shortBio.isNotEmpty ? shortBio : 'A $resolvedName persona.',
      avatar: avatar,
    );
  }

  /// Plain-text engine errors (context too small, OOM, etc.) masquerading as
  /// model output — surface a friendly message instead of a JSON decode crash.
  String? _looksLikeBackendError(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final lower = t.toLowerCase();
    if (lower.contains('exceeds the available context') ||
        lower.contains('context size') ||
        lower.contains('context length') ||
        lower.contains('context window')) {
      return 'This model\'s context is too small for Persona Generator. '
          'Try a larger context model, or free memory and try again.';
    }
    if (lower.startsWith('error') ||
        lower.startsWith('request (') ||
        lower.contains('out of memory')) {
      // First line only — keep the dialog readable.
      final first = t.split(RegExp(r'[\r\n]')).first.trim();
      if (first.length > 180) {
        return '${first.substring(0, 177)}…';
      }
      return first;
    }
    return null;
  }

  Map<String, dynamic> _extractJsonMap(String raw) {
    var text = raw.trim();
    if (text.isEmpty) {
      throw StateError('Empty response from model.');
    }
    final backendError = _looksLikeBackendError(text);
    if (backendError != null) {
      throw StateError(backendError);
    }
    // Strip ```json ... ``` fences if present.
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
    final fenceMatch = fence.firstMatch(text);
    if (fenceMatch != null) {
      text = fenceMatch.group(1)!.trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw StateError(
        'The model didn\'t return a usable persona. Try again with a '
        'shorter description, or switch to a stronger model.',
      );
    }
    text = text.substring(start, end + 1);
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } on FormatException {
      throw StateError(
        'The model returned invalid data. Try again, or use a different model.',
      );
    }
    throw StateError('Model did not return a JSON object.');
  }

  Future<String> _copyPackAvatar(PersonaPackEntry entry, String personaId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final relative = 'images/persona_pack_${personaId}_${entry.id}.webp';
    final dest = File(p.join(appDir.path, relative));
    await dest.parent.create(recursive: true);
    final data = await rootBundle.load(entry.assetPath);
    await dest.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return relative;
  }
}
