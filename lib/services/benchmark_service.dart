/// Firebase-backed persistence for **Arena mode**.
///
/// Two destinations:
///   1. **Private history** (`/users/{uid}/arena_runs/{id}`) — the user's own
///      saved comparisons. Pro-only; full fidelity. Lives in
///      [ArenaHistoryStore] (lib/pro; stubbed in the public export).
///   2. **Public benchmark pool** (`/benchmarks/{autoId}`) — one anonymized row
///      per qualifying contestant on every finished Arena run (compare or
///      benchmark). Carries metrics + device + model spec but NEVER prompt/
///      answer content. Used for device-class aggregation and recommendations.
///
/// All writes are best-effort and fully guarded so the app works offline / when
/// Firebase isn't configured.
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/arena_models.dart';
import '../models/arena_run.dart';
import '../pro/arena/arena_history_store.dart';
import 'arena_prompt_set.dart';

class BenchmarkService {
  BenchmarkService._();
  static final BenchmarkService instance = BenchmarkService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  String? _appVersionCache;

  Future<String?> _currentUserId() async {
    if (!_firebaseAvailable) return null;
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      return _auth.currentUser?.uid;
    } catch (e) {
      if (kDebugMode) debugPrint('BenchmarkService auth error: $e');
      return null;
    }
  }

  Future<String> _appVersion() async {
    if (_appVersionCache != null) return _appVersionCache!;
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersionCache = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersionCache = 'unknown';
    }
    return _appVersionCache!;
  }

  static String _platformName() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Persists a finished run. [savePrivate] writes the user's history (Pro).
  /// Anonymized per-model rows upload to the public pool only when
  /// [shareAnonymous] is true. Returns true if anything was written.
  Future<bool> saveRun(
    ArenaRun run, {
    required bool savePrivate,
    bool shareAnonymous = true,
  }) async {
    if (!_firebaseAvailable) return false;
    final uid = await _currentUserId();
    if (uid == null) return false;

    var wrote = false;

    if (savePrivate) {
      if (await ArenaHistoryStore.instance.savePrivate(run)) wrote = true;
    }

    if (!shareAnonymous) return wrote;

    // Public pool: one row per successful contestant (compare + benchmark).
    {
      final appVersion = await _appVersion();
      final batch = _db.batch();
      var queued = 0;
      for (final r in run.results) {
        if (r.status != ArenaContestantStatus.done || !r.hasContent) continue;
        final c = r.contestant;
        final ref = _db.collection('benchmarks').doc();
        batch.set(ref, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'appVersion': appVersion,
          'mode': run.mode.name,
          if (run.mode == ArenaMode.benchmark) ...{
            'promptSetId': run.promptSetId ?? ArenaPromptSet.standard.id,
            'promptSetVersion':
                run.promptSetVersion ?? ArenaPromptSet.standard.version,
          },
          // Device
          'platform': run.platform,
          'deviceClass': run.deviceClass,
          'deviceName': run.deviceName,
          'chip': run.chip,
          'ramGb': run.ramGb,
          // Model
          'modelId': c.modelId,
          'provider': c.providerKind,
          'engine': c.providerKind,
          'quant': c.quant,
          'paramsB': c.paramsB,
          'sizeMb': c.sizeMb,
          'arch': c.arch,
          // Metrics
          'tokensPerSecond': r.metrics.tokensPerSecond,
          'ttftMs': r.metrics.ttftMs,
          'outputTokens': r.metrics.outputTokens,
          'tokensEstimated': r.metrics.tokensEstimated,
          'fit': r.fit?.name,
        });
        queued++;
      }
      if (queued > 0) {
        try {
          await batch.commit();
          wrote = true;
        } catch (e) {
          if (kDebugMode) debugPrint('BenchmarkService public save error: $e');
        }
      }
    }

    return wrote;
  }

  /// Loads the user's saved runs, newest first. Empty when not signed in /
  /// Firebase unavailable (and always in the public build).
  Future<List<ArenaRun>> fetchHistory({int limit = 50}) =>
      ArenaHistoryStore.instance.fetch(limit: limit);

  Future<void> deleteRun(String runId) =>
      ArenaHistoryStore.instance.delete(runId);

  /// Builds an [ArenaRun] from a finished controller's state + device snapshot.
  static String platformName() => _platformName();
}
