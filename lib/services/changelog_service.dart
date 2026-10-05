import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../pro/admin/admin_ids.dart';
import '../utils/semver.dart';

/// A single changelog entry from Firestore.
class ChangelogEntry {
  final String id;
  final String version;
  final String title;
  final List<String> changes;
  final DateTime createdAt;
  final String? appStoreUrl;
  final String? playStoreUrl;

  ChangelogEntry({
    required this.id,
    required this.version,
    required this.title,
    required this.changes,
    required this.createdAt,
    this.appStoreUrl,
    this.playStoreUrl,
  });

  factory ChangelogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChangelogEntry(
      id: doc.id,
      version: data['version'] as String? ?? '',
      title: data['title'] as String? ?? '',
      changes: (data['changes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appStoreUrl: data['appStoreUrl'] as String?,
      playStoreUrl: data['playStoreUrl'] as String?,
    );
  }
}

/// Service that checks Firestore `changelog` collection for new entries
/// and tracks which ones the user has dismissed.
class ChangelogService {
  static final ChangelogService _instance = ChangelogService._internal();
  factory ChangelogService() => _instance;
  ChangelogService._internal();

  static const _dismissedKey = 'changelog_dismissed_id';

  final _firestore = FirebaseFirestore.instance;

  // Changelog editor UIDs live in the private overlay (empty in public builds).
  static const List<String> _adminUserIds = ProAdminIds.changelogAdmins;

  bool get isAdmin {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && _adminUserIds.contains(uid);
  }

  /// Latest changelog document, or null if Firebase is down / empty.
  Future<ChangelogEntry?> fetchLatest() async {
    if (!firebaseInitialized) return null;

    try {
      final snapshot = await _firestore
          .collection('changelog')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ChangelogEntry.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('⚠️ Changelog fetch failed: $e');
      return null;
    }
  }

  /// Checks for a new changelog entry the user hasn't dismissed yet.
  /// Returns the latest entry if unseen and newer than the installed app.
  Future<ChangelogEntry?> checkForNewChangelog() async {
    final entry = await fetchLatest();
    if (entry == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final dismissedId = prefs.getString(_dismissedKey);
    if (dismissedId == entry.id) return null;

    if (entry.version.isNotEmpty) {
      try {
        final installedVersion = (await PackageInfo.fromPlatform()).version;
        if (compareSemver(entry.version, installedVersion) <= 0) {
          return null;
        }
      } catch (_) {
        // If we can't determine the app version, fall through and show
      }
    }

    return entry;
  }

  /// Mark a changelog entry as dismissed so it won't show again.
  Future<void> dismiss(String changelogId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKey, changelogId);
  }

  /// Stream all changelog entries (newest first).
  Stream<List<ChangelogEntry>> getAllChangelogs() {
    return _firestore
        .collection('changelog')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChangelogEntry.fromFirestore(d)).toList());
  }
}
