// LM-MINI-PRO-STUB
import 'package:flutter/foundation.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

/// Public-build stub: persona-scoped memory is a Pro feature that ships only
/// in the official LM Mini app. Scoping is always off, no memories are bound
/// to personas, and every mutation is a no-op.
class PersonaMemoryService extends ChangeNotifier {
  PersonaMemoryService._();
  static final PersonaMemoryService instance = PersonaMemoryService._();

  bool get isEnabled => false;
  bool get isLoaded => true;
  bool get onDeviceExtractionEnabled => false;

  Future<void> load() async {}

  Future<void> setEnabled(bool value) async {}

  Future<void> setOnDeviceExtractionEnabled(bool value) async {}

  int countForPersona(String personaId) => 0;

  List<MemoryItem> orphanedItems(Set<String> knownPersonaIds) => const [];

  Future<int> reassignMemoriesForDeletedPersona(
    String deletedPersonaId, {
    String? reassignTo,
    bool deleteItems = false,
  }) async =>
      0;
}
