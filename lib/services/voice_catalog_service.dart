import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/voice_catalog_entry.dart';
import 'app_admin_config.dart';
import 'feature_request_service.dart';

/// Firestore-backed catalog of downloadable TTS voice packs.
///
/// Collection: `voice_catalog/{id}`
/// - Anyone may read published entries.
/// - App admins and community moderators may create / update / delete.
class VoiceCatalogService {
  VoiceCatalogService._();
  static final VoiceCatalogService instance = VoiceCatalogService._();

  static const _collection = 'voice_catalog';

  final _db = FirebaseFirestore.instance;

  bool get isAdmin {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return AppAdminConfig.isAdmin(uid);
  }

  /// Sync check (uses profile cache + legacy mod list). Prefer [canManage].
  bool get canManageSync {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    return FeatureRequestService.isUserModeratorSync(uid);
  }

  Future<bool> get canManage async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    if (AppAdminConfig.isAdmin(uid)) return true;
    return FeatureRequestService().isModerator;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  /// Published voices for the store UI (future consumer screen).
  Future<List<VoiceCatalogEntry>> fetchPublished() async {
    final snap = await _col.where('published', isEqualTo: true).get();
    final list = snap.docs
        .map((d) => VoiceCatalogEntry.fromJson({...d.data(), 'id': d.id}))
        .toList();
    list.sort((a, b) {
      final lang = a.language.compareTo(b.language);
      if (lang != 0) return lang;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  /// All catalog entries (admin list).
  Future<List<VoiceCatalogEntry>> fetchAll() async {
    final snap = await _col.get();
    final list = snap.docs
        .map((d) => VoiceCatalogEntry.fromJson({...d.data(), 'id': d.id}))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(0))
        .compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<void> publish(VoiceCatalogEntry entry) async {
    if (!await canManage) throw Exception('Admin or moderator only');
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = entry.toJson()
      ..['published'] = true
      ..['createdBy'] = uid
      ..['createdAt'] = (entry.createdAt ?? DateTime.now()).toIso8601String()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(entry.id).set(data, SetOptions(merge: true));
    debugPrint('VoiceCatalog: published ${entry.id} (${entry.name})');
  }

  Future<void> delete(String id) async {
    if (!await canManage) throw Exception('Admin or moderator only');
    await _col.doc(id).delete();
    debugPrint('VoiceCatalog: deleted $id');
  }
}
