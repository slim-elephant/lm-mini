import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/system_prompt.dart';
import '../utils/persona_palette.dart';

/// Ships built-in personas: empty Default, plus Mini (avatar + prompt + voice).
class BuiltinPersonaService {
  BuiltinPersonaService._();

  static const defaultPersonaId = 'builtin_persona_default';
  static const personaId = 'builtin_persona_mini';
  static const _miniSeededKey = 'seeded_builtin_persona_mini_v1';
  static const assetAvatar = 'assets/images/mini_persona.png';
  static const docsAvatarRelative = 'images/builtin_mini_persona.png';

  /// Helpful default system prompt for Mini.
  static const promptContent =
      'You are Mini, a helpful AI assistant in the LM Mini app. '
      'Be clear, concise, and practical. Help with questions, writing, '
      'brainstorming, planning, and everyday tasks. Ask a short clarifying '
      'question when the request is ambiguous. Prefer actionable steps and '
      'plain language. Be warm and approachable without being overly casual. '
      'If you are unsure, say so and suggest what would help you answer better.';

  /// Kokoro male voice: Adam (`am_adam`).
  static const int kokoroSpeakerId = 5;

  /// Soft teal accent (eyes / cool tones from the portrait).
  static const int accentColor = 0xFF4A9BB5;

  static bool isDefaultId(String? id) =>
      id == null || id == defaultPersonaId;

  static SystemPrompt buildDefault({DateTime? now}) {
    final stamp = now ?? DateTime.fromMillisecondsSinceEpoch(0);
    return SystemPrompt(
      id: defaultPersonaId,
      name: 'Default',
      content: '',
      boundModelIds: null,
      createdAt: stamp,
      updatedAt: stamp,
      shareMemories: true,
    );
  }

  /// Ensure built-in personas exist. Mini is seeded once per install (not
  /// re-added if the user deleted it). Default is always present.
  static Future<AppSettings> ensureSeeded(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = List<SystemPrompt>.from(
        settings.savedSystemPrompts ?? const <SystemPrompt>[],
      );
      final libraryWasEmpty = existing.isEmpty;
      var changed = false;

      if (!existing.any((p) => p.id == defaultPersonaId)) {
        existing.insert(0, buildDefault(now: DateTime.now()));
        changed = true;
      }

      final miniSeeded = prefs.getBool(_miniSeededKey) == true;
      if (!miniSeeded && !existing.any((p) => p.id == personaId)) {
        await _ensureAvatarCopied();

        final now = DateTime.now();
        var mini = SystemPrompt(
          id: personaId,
          name: 'Mini',
          content: promptContent,
          boundModelIds: null,
          createdAt: now,
          updatedAt: now,
          avatarPath: docsAvatarRelative,
          avatarFocusX: 0,
          avatarFocusY: -0.38,
          avatarFocusScale: 1.5,
          color: accentColor,
          kokoroSpeakerId: kokoroSpeakerId,
          shareMemories: true,
        );
        mini = await PersonaPalette.ensureCached(mini);

        final defaultIndex =
            existing.indexWhere((p) => p.id == defaultPersonaId);
        existing.insert(defaultIndex >= 0 ? defaultIndex + 1 : 0, mini);
        changed = true;
      }
      if (existing.any((p) => p.id == personaId) || miniSeeded) {
        await prefs.setBool(_miniSeededKey, true);
      }

      var selectedId = settings.selectedSystemPromptId;
      var systemPrompt = settings.systemPrompt;
      // Brand-new library: Default is selected, empty prompt, no persona prefs.
      if (libraryWasEmpty && selectedId == null) {
        selectedId = defaultPersonaId;
        systemPrompt = '';
        changed = true;
      }

      if (!changed) return settings;
      return settings.copyWith(
        savedSystemPrompts: existing,
        selectedSystemPromptId: selectedId,
        systemPrompt: systemPrompt,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('BuiltinPersonaService.ensureSeeded failed: $e\n$st');
      }
      return settings;
    }
  }

  static Future<void> _ensureAvatarCopied() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dest = File(p.join(appDir.path, docsAvatarRelative));
    if (await dest.exists()) return;
    await dest.parent.create(recursive: true);
    final data = await rootBundle.load(assetAvatar);
    await dest.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }
}
