// LM-MINI-PRO-STUB
/// Public-build stub: private Arena history is a Pro feature that ships only
/// in the official LM Mini app. Nothing is stored; the anonymized public pool
/// in BenchmarkService is unaffected.
library;

import '../../models/arena_run.dart';

class ArenaHistoryStore {
  ArenaHistoryStore._();
  static final ArenaHistoryStore instance = ArenaHistoryStore._();

  /// Writes [run] to the user's private history. Returns true on success.
  Future<bool> savePrivate(ArenaRun run) async => false;

  /// Loads the user's saved runs, newest first. Always empty here.
  Future<List<ArenaRun>> fetch({int limit = 50}) async => const [];

  Future<void> delete(String runId) async {}
}
