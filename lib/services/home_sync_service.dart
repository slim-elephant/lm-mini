import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/system_prompt.dart';
import 'builtin_persona_service.dart';
import '../utils/image_picker_helper.dart';
import '../utils/remote_host_backends.dart';
import 'database_service.dart';
import 'home_sync_snapshot.dart';
import 'remote_connection_info.dart';

part '../pro/remote_access/home_sync_client.dart';

/// Syncs chats and folders between the phone and LM Mini Home over the
/// existing encrypted relay (same pairing as Share with phone).
class HomeSyncService {
  HomeSyncService._();
  static final HomeSyncService instance = HomeSyncService._();

  static const syncPath = '/lm-mini/sync';
  static const _tombstoneConvosKey = 'home_sync_deleted_convos';
  static const _tombstoneFoldersKey = 'home_sync_deleted_folders';

  final DatabaseService _db = DatabaseService();
  Timer? _debounce;
  Timer? _poll;
  bool _busy = false;
  AppSettings Function()? _settings;
  Future<void> Function()? _onApplied;
  bool Function()? _shouldDefer;
  Future<void> Function({
    required List<SystemPrompt> prompts,
    required List<String> syncIds,
    required bool enabled,
    DateTime? updatedAt,
  })? _applyPersonas;
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  static const _maxAvatarBytes = 700000;

  void attach({
    required AppSettings Function() settings,
    Future<void> Function()? onApplied,
    bool Function()? shouldDefer,
    Future<void> Function({
      required List<SystemPrompt> prompts,
      required List<String> syncIds,
      required bool enabled,
      DateTime? updatedAt,
    })? applyPersonas,
  }) {
    _settings = settings;
    _onApplied = onApplied;
    _shouldDefer = shouldDefer;
    _applyPersonas = applyPersonas;
  }

  void schedule() {
    // Don't queue another round-trip while a sync (and its UI reload) is
    // in flight — ChatProvider.notifyListeners would otherwise loop every ~3s.
    if (_busy || _shouldDefer?.call() == true) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () {
      unawaited(syncNow());
    });
  }

  /// Drop a debounce armed before send so a 3s timer cannot fire mid-stream.
  void cancelPendingSchedule() {
    _debounce?.cancel();
    _debounce = null;
  }

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(syncNow());
    });
    unawaited(syncNow());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  /// True until the user answers the first-connect merge prompt.
  static bool shouldPrompt(AppSettings settings) {
    if (!RemoteHostBackends.isPairedHome(settings)) return false;
    if (settings.homeSyncEnabled) return false;
    if (settings.homeSyncPrompted) return false;
    return true;
  }

  /// Peek at Mac chats without merging — used by the opt-in dialog.
  Future<HomeSyncPreview> preview() => _proPreview();

  Future<HomeSyncSnapshot?> fetchRemoteSnapshot() =>
      _proFetchRemoteSnapshot();

  Future<void> rememberDeletedConversation(String id) async {
    await _addTombstone(_tombstoneConvosKey, id);
    schedule();
  }

  Future<void> rememberDeletedFolder(String id) async {
    await _addTombstone(_tombstoneFoldersKey, id);
    schedule();
  }

  /// Mac host: merge a phone snapshot into this Mac's DB and return the result.
  Future<({int status, Map<String, dynamic> body})> handleHostHttp({
    required String method,
    String? body,
  }) async {
    try {
      if (method == 'GET' || method == 'HEAD') {
        final local = await _loadLocalSnapshot();
        return (status: 200, body: local.toJson());
      }
      if (method != 'POST' && method != 'PUT') {
        return (status: 405, body: {'error': 'Method not allowed'});
      }
      final incoming = body == null || body.isEmpty
          ? const HomeSyncSnapshot()
          : HomeSyncSnapshot.fromJson(
              Map<String, dynamic>.from(jsonDecode(body) as Map),
            );
      final local = await _loadLocalSnapshot(
        extraPackIds:
            incoming.personasEnabled ? incoming.syncPersonaIds.toSet() : null,
      );
      final merged = HomeSyncMerge.merge(local, incoming);
      final changed = await _proApplySnapshot(local, merged);
      if (changed) {
        await _onApplied?.call();
      }
      return (status: 200, body: merged.toJson());
    } catch (e, st) {
      debugPrint('HomeSync host error: $e\n$st');
      return (status: 500, body: {'error': e.toString()});
    }
  }

  Future<bool> syncNow() => _proSyncNow();

  Future<HomeSyncSnapshot> _loadLocalSnapshot({
    Set<String>? extraPackIds,
  }) async {
    final convos = await _db.getAllConversations();
    final packed = <HomeSyncConversation>[];
    for (final convo in convos) {
      packed.add(HomeSyncConversation(
        conversation: convo,
        messages: await _db.getMessagesForConversation(convo.id),
      ));
    }
    final settings = _settings?.call();
    final enabled = settings?.homeSyncPersonasEnabled ?? false;
    final ids = <String>{
      ...?settings?.homeSyncPersonaIds,
      ...?extraPackIds,
    };
    final pack = enabled || (extraPackIds != null && extraPackIds.isNotEmpty);
    final catalog = <HomeSyncPersonaInfo>[];
    final packedPersonas = <HomeSyncPersona>[];
    for (final prompt
        in settings?.savedSystemPrompts ?? const <SystemPrompt>[]) {
      if (BuiltinPersonaService.isDefaultId(prompt.id)) continue;
      final memories = await _memoriesFor(prompt.id);
      catalog.add(HomeSyncPersonaInfo(
        id: prompt.id,
        name: prompt.name,
        updatedAt: prompt.updatedAt,
        memoryCount: memories.length,
        hasAvatar: prompt.avatarPath != null && prompt.avatarPath!.isNotEmpty,
        color: prompt.color,
      ));
      if (pack && ids.contains(prompt.id)) {
        packedPersonas.add(await _packPersona(prompt, memories));
      }
    }

    return HomeSyncSnapshot(
      folders: await _db.getAllFolders(),
      conversations: packed,
      deletedConversations: await _readTombstones(_tombstoneConvosKey),
      deletedFolders: await _readTombstones(_tombstoneFoldersKey),
      personaCatalog: catalog,
      personas: packedPersonas,
      syncPersonaIds:
          List<String>.from(settings?.homeSyncPersonaIds ?? const []),
      personasEnabled: enabled,
      personasUpdatedAt: settings?.homeSyncPersonasUpdatedAt,
    );
  }

  Future<HomeSyncPersona> _packPersona(
    SystemPrompt prompt,
    List<Map<String, dynamic>> memories,
  ) async {
    String? b64;
    String? ext;
    final path = prompt.avatarPath;
    if (path != null &&
        path.isNotEmpty &&
        !_isBundledAvatar(path)) {
      try {
        final abs = await ImagePickerHelper.resolveImagePath(path);
        if (abs != null) {
          final file = File(abs);
          final len = await file.length();
          if (len > 0 && len <= _maxAvatarBytes) {
            b64 = base64Encode(await file.readAsBytes());
            ext = p.extension(abs);
            if (ext.isEmpty) ext = '.jpg';
          }
        }
      } catch (e) {
        debugPrint('HomeSync persona avatar skip: $e');
      }
    }
    return HomeSyncPersona(
      prompt: prompt,
      avatarBase64: b64,
      avatarExt: ext,
      memories: memories,
    );
  }

  bool _isBundledAvatar(String path) {
    return path.startsWith('assets/') ||
        path.contains('persona_pack_') ||
        path.contains('persona_pack');
  }

  Future<List<Map<String, dynamic>>> _memoriesFor(String personaId) async {
    final mem = MemoryService();
    await mem.load();
    try {
      final exported = await mem.exportItems();
      if (exported.isNotEmpty) {
        return [
          for (final item in exported)
            if (item['personaId']?.toString() == personaId)
              Map<String, dynamic>.from(item),
        ];
      }
    } catch (_) {}
    return [
      for (final item in mem.items)
        if (item.personaId == personaId)
          {
            'id': item.id,
            'content': item.content,
            'category': item.category,
            'scope': item.scope.name,
            'personaId': item.personaId,
            'createdAt': item.createdAt.toIso8601String(),
            'updatedAt': item.updatedAt.toIso8601String(),
          },
    ];
  }

  Future<void> _addTombstone(String key, String id) async {
    final existing = await _readTombstones(key);
    final next = [
      ...existing.where((t) => t.id != id),
      HomeSyncTombstone(id: id, deletedAt: DateTime.now()),
    ];
    if (next.length > 400) {
      next.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
      next.removeRange(400, next.length);
    }
    await _writeTombstones(key, next);
  }

  Future<List<HomeSyncTombstone>> _readTombstones(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is Map)
            HomeSyncTombstone.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeTombstones(
    String key,
    List<HomeSyncTombstone> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(items.map((t) => t.toJson()).toList()),
    );
  }
}
