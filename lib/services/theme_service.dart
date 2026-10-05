import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_theme.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._();
  factory ThemeService() => _instance;
  ThemeService._();

  Directory? _cacheDir;

  Future<Directory> get _themeCacheDir async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/themes');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  // ── Local cache ──────────────────────────────────────────────

  /// Load a theme from local cache by ID.
  Future<AppTheme?> loadCachedTheme(String id) async {
    try {
      final dir = await _themeCacheDir;
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        return AppTheme.fromJson(json as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('ThemeService: failed to load cached theme $id: $e');
    }
    return null;
  }

  /// Save a theme to local cache.
  Future<void> cacheTheme(AppTheme theme) async {
    try {
      final dir = await _themeCacheDir;
      final file = File('${dir.path}/${theme.id}.json');
      await file.writeAsString(jsonEncode(theme.toJson()));
    } catch (e) {
      debugPrint('ThemeService: failed to cache theme ${theme.id}: $e');
    }
  }

  /// List all locally cached (downloaded) theme IDs.
  Future<List<String>> listCachedThemeIds() async {
    try {
      final dir = await _themeCacheDir;
      final files = await dir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete a locally cached theme.
  Future<void> deleteCachedTheme(String id) async {
    try {
      final dir = await _themeCacheDir;
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  // ── Firebase: Browse & Download ──────────────────────────────

  /// Fetch the list of community themes from Firestore.
  ///
  /// Defensively dedupes results client-side. Historically a few users
  /// ended up with two Firestore docs for the same theme (one keyed by
  /// `theme.id`, one keyed by an auto-id) when the composite index for
  /// `uploadedBy + originalThemeId` was missing. Even after that's fixed
  /// the old duplicate docs persist, so we collapse them here keyed by
  /// `(uploadedBy, originalThemeId)` and keep the most-downloaded copy.
  Future<List<AppTheme>> fetchCommunityThemes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('themes')
          .orderBy('downloadCount', descending: true)
          .limit(100)
          .get();

      final seen = <String, AppTheme>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final theme = AppTheme.fromJson(data);
        // Compose a dedup key. Prefer (uploadedBy + originalThemeId);
        // fall back to the theme id so very old docs still pass through.
        final uploadedBy = data['uploadedBy'] as String? ?? '';
        final originalId =
            data['originalThemeId'] as String? ?? theme.id;
        final key = uploadedBy.isEmpty
            ? 'id:${theme.id}'
            : 'own:$uploadedBy:$originalId';
        // First write wins because the query is ordered by downloadCount
        // desc, so the duplicate with fewer downloads gets dropped.
        seen.putIfAbsent(key, () => theme);
      }
      return seen.values.toList();
    } catch (e) {
      debugPrint('ThemeService: failed to fetch community themes: $e');
      return [];
    }
  }

  /// Download a theme from Firestore and cache it locally.
  Future<AppTheme?> downloadTheme(String themeId) async {
    try {
      AppTheme? theme;

      final doc = await FirebaseFirestore.instance
          .collection('themes')
          .doc(themeId)
          .get();
      if (doc.exists && doc.data() != null) {
        theme = AppTheme.fromJson(doc.data()!);
      }

      if (theme == null) {
        debugPrint('ThemeService: theme $themeId not found in Firestore');
        return null;
      }

      await cacheTheme(theme);

      // Increment download counter
      try {
        await FirebaseFirestore.instance
            .collection('themes')
            .doc(themeId)
            .update({'downloadCount': FieldValue.increment(1)});
      } catch (_) {}

      return theme;
    } catch (e) {
      debugPrint('ThemeService: failed to download theme $themeId: $e');
      return null;
    }
  }

  // ── Firebase: Upload ─────────────────────────────────────────

  /// Upload a user-created theme to Firestore.
  ///
  /// Uses a deterministic doc id of the form `${uploadedBy}__${theme.id}`
  /// so re-shares always upsert into the same row and we can never accrue
  /// duplicate community entries for the same logical theme. Older docs
  /// that may exist under different ids are deduped at fetch time by
  /// [fetchCommunityThemes] (see that method for the dedup key).
  Future<bool> uploadTheme(AppTheme theme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final collection = FirebaseFirestore.instance.collection('themes');
      final communityThemeId = '${user.uid}__${theme.id}';
      final docRef = collection.doc(communityThemeId);
      final existing = await docRef.get();

      // Best-effort cleanup of any legacy duplicate documents for the same
      // (user, originalThemeId). These came from earlier code paths that
      // used either `theme.id` directly or an auto-id as the doc id.
      // We only attempt cleanup when the canonical doc already exists so
      // the very first publish doesn't try (and fail) to query before the
      // composite index is hot.
      if (existing.exists) {
        try {
          final legacy = await collection
              .where('uploadedBy', isEqualTo: user.uid)
              .where('originalThemeId', isEqualTo: theme.id)
              .get();
          for (final doc in legacy.docs) {
            if (doc.id != communityThemeId) {
              await doc.reference.delete();
            }
          }
        } catch (_) {
          // Missing index or permission \u2014 not fatal, we still upsert.
        }
      }

      await docRef.set({
        ...theme.toJson(),
        'id': communityThemeId,
        'originalThemeId': theme.id,
        'uploadedBy': user.uid,
        if (!existing.exists) 'uploadedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'downloadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('ThemeService: failed to upload theme ${theme.id}: $e');
      return false;
    }
  }
}
