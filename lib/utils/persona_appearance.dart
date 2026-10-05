import '../models/app_settings.dart';
import '../models/system_prompt.dart';
import '../services/builtin_persona_service.dart';

/// Avatar + accent color for the active Persona in a 1:1 chat.
class PersonaAppearance {
  final String? avatarPath;
  final int? color;

  const PersonaAppearance({this.avatarPath, this.color});

  bool get hasVisual => avatarPath != null || color != null;

  /// Resolve the persona look for a chat.
  ///
  /// When [conversationSettings] is provided, only that chat's bound
  /// `systemPromptId` is used — never the globally selected persona. Falling
  /// back to global made every conversation-list row show the last-used
  /// persona avatar.
  ///
  /// When [conversationSettings] is null, uses [AppSettings.selectedSystemPromptId]
  /// (current global selection — e.g. header chrome).
  static PersonaAppearance? resolve({
    required AppSettings settings,
    Map<String, dynamic>? conversationSettings,
    List<SystemPrompt>? savedSystemPrompts,
  }) {
    final prompts = savedSystemPrompts ?? settings.savedSystemPrompts;
    if (prompts == null || prompts.isEmpty) return null;

    String? personaId;
    final chat = conversationSettings;
    if (chat != null) {
      if (chat.containsKey('systemPromptId')) {
        personaId = chat['systemPromptId']?.toString();
        // Explicit empty / cleared saved persona.
        if (personaId == null || personaId.isEmpty) return null;
      } else {
        // No per-chat persona binding (and not using global — see above).
        return null;
      }
    } else {
      personaId = settings.selectedSystemPromptId;
    }
    if (personaId == null ||
        personaId.isEmpty ||
        personaId == BuiltinPersonaService.defaultPersonaId) {
      return null;
    }

    for (final p in prompts) {
      if (p.id == personaId) {
        if (p.avatarPath == null && p.color == null) return null;
        return PersonaAppearance(avatarPath: p.avatarPath, color: p.color);
      }
    }
    return null;
  }

  /// Bound [SystemPrompt] for a chat (by `systemPromptId`), if any.
  static SystemPrompt? boundPersona({
    required AppSettings settings,
    Map<String, dynamic>? conversationSettings,
    List<SystemPrompt>? savedSystemPrompts,
  }) {
    final prompts = savedSystemPrompts ?? settings.savedSystemPrompts;
    if (prompts == null || prompts.isEmpty) return null;

    String? personaId;
    final chat = conversationSettings;
    if (chat != null) {
      if (!chat.containsKey('systemPromptId')) return null;
      personaId = chat['systemPromptId']?.toString();
      if (personaId == null || personaId.isEmpty) return null;
    } else {
      personaId = settings.selectedSystemPromptId;
    }
    if (personaId == null ||
        personaId.isEmpty ||
        personaId == BuiltinPersonaService.defaultPersonaId) {
      return null;
    }

    for (final p in prompts) {
      if (p.id == personaId) return p;
    }
    return null;
  }

  /// Safe int parse for colors stored via JSON (may arrive as num).
  static int? parseColor(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}
