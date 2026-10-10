import 'package:flutter/foundation.dart';

/// Who a memory item is visible to.
///
/// Mirrors the premium enum so app code can reference scopes without the real
/// package present.
enum MemoryScope {
  /// Visible in every chat, with or without a persona.
  global,

  /// A fact about the user that only one persona may see.
  private,

  /// An in-character fact established while roleplaying with one persona.
  lore,
}

/// Parse a persisted scope string. Unknown/missing values fall back to
/// [MemoryScope.global].
MemoryScope memoryScopeFromWire(Object? raw) {
  switch (raw?.toString()) {
    case 'private':
      return MemoryScope.private;
    case 'lore':
      return MemoryScope.lore;
    default:
      return MemoryScope.global;
  }
}

/// Stub memory service — all operations are no-ops.
///
/// In the real premium package, this stores persistent memory items
/// in a local SQLite database and injects them into the system prompt.
class MemoryService extends ChangeNotifier {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();

  List<MemoryItem> get items => const [];
  bool get isEnabled => false;
  bool get isLoaded => true;

  /// No-op in stub.
  Future<void> load() async {}

  /// No-op in stub.
  Future<void> reload() async {}

  /// No-op in stub.
  Future<int?> addItem(
    String content, {
    String? category,
    MemoryScope scope = MemoryScope.global,
    String? personaId,
  }) async =>
      null;

  /// No-op in stub.
  Future<bool> updateItem(
    String id, {
    String? content,
    String? category,
    MemoryScope? scope,
    String? personaId,
    bool clearPersonaId = false,
  }) async =>
      false;

  /// No-op in stub.
  Future<void> removeItem(String id) async {}

  /// No-op in stub.
  Future<bool> removeByContent(
    String content, {
    MemoryScope? scope,
    String? personaId,
  }) async =>
      false;

  /// No-op in stub — returns 0.
  Future<int> reassignPersona(String personaId, {String? toPersonaId}) async =>
      0;

  /// No-op in stub — returns 0.
  Future<int> removeItemsForPersona(String personaId) async => 0;

  /// No-op in stub.
  Future<void> clearAll() async {}

  /// Always empty in stub.
  List<MemoryItem> itemsVisibleForWrite(MemoryScope scope, String? personaId) =>
      const [];

  /// Always empty in stub.
  List<MemoryItem> itemsForDedupPrompt(
    MemoryScope scope,
    String? personaId,
    String snippet, {
    int limit = 50,
  }) =>
      const [];

  /// Always null in stub.
  MemoryItem? findUpsertTarget(
    String content, {
    String category = 'general',
    MemoryScope scope = MemoryScope.global,
    String? personaId,
    String? replaces,
  }) =>
      null;

  /// Exact match only in stub.
  static bool contentOverlaps(String a, String b) =>
      a.toLowerCase().trim() == b.toLowerCase().trim();

  /// No-op in stub.
  void debugReplaceItems(List<MemoryItem> items, {bool enabled = true}) {}

  /// Always false in stub.
  bool isDuplicate(String content, {MemoryScope? scope, String? personaId}) =>
      false;

  /// Always null in stub.
  MemoryItem? findByContent(
    String search, {
    MemoryScope? scope,
    String? personaId,
  }) =>
      null;

  /// No-op in stub.
  Future<MemoryUpsertResult?> upsertItem(
    String content, {
    String? category,
    MemoryScope scope = MemoryScope.global,
    String? personaId,
    String? replaces,
  }) async =>
      null;

  /// Always 0 in stub.
  int countForPersona(String personaId) => 0;

  /// Always empty in stub.
  List<MemoryItem> orphanedItems(Set<String> knownPersonaIds) => const [];

  /// No-op in stub — returns 0.
  Future<int> applyLegacyPersonaAssignments(
          Map<String, String> assignments) async =>
      0;

  /// No-op in stub.
  void setEnabled(bool value) {}

  /// Returns empty string in stub — no memory context.
  String buildMemoryContext({
    String? personaId,
    String? personaName,
    bool enforcePersonaScope = true,
    bool isolatePersona = false,
    List<String>? allowedCategories,
    int maxSharedItems = 30,
    int maxPersonaItems = 20,
    int maxLoreItems = 40,
  }) =>
      '';

  /// No-op in stub — returns empty list.
  Future<List<Map<String, dynamic>>> exportItems() async => [];

  /// No-op in stub — returns 0.
  Future<int> importItems(List<dynamic> items, {bool clearFirst = true}) async => 0;

  /// Extraction prompt (available even in stub for interface compatibility).
  static String get extractionPrompt => '';  // Stub — real prompt is in premium package

  /// Stub — real prompts are in the premium package.
  static String extractionPromptForScope(
    MemoryScope scope, {
    String? personaName,
  }) =>
      '';
}

/// Stub result — matches premium interface.
class MemoryUpsertResult {
  final String id;
  final bool wasUpdate;
  final String fact;
  final String category;
  final MemoryScope scope;
  final String? personaId;
  final String? previousContent;
  final bool unchanged;

  const MemoryUpsertResult({
    required this.id,
    required this.wasUpdate,
    this.unchanged = false,
    required this.fact,
    required this.category,
    this.scope = MemoryScope.global,
    this.personaId,
    this.previousContent,
  });
}

/// A single memory item.
class MemoryItem {
  final String id;
  final String content;
  final String category;
  final MemoryScope scope;
  final String? personaId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoryItem({
    required this.id,
    required this.content,
    required this.category,
    this.scope = MemoryScope.global,
    this.personaId,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  bool get isGlobal => scope == MemoryScope.global;
  bool get isLore => scope == MemoryScope.lore;

  MemoryItem copyWith({
    String? content,
    String? category,
    MemoryScope? scope,
    String? personaId,
    bool clearPersonaId = false,
    DateTime? updatedAt,
  }) {
    return MemoryItem(
      id: id,
      content: content ?? this.content,
      category: category ?? this.category,
      scope: scope ?? this.scope,
      personaId: clearPersonaId ? null : (personaId ?? this.personaId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
