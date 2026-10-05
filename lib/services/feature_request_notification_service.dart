import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feature_request.dart';

/// Tracks which feature requests the user and admins have seen, so we can show
/// unread indicators when status changes, admin replies, or new comments arrive.
class FeatureRequestNotificationService extends ChangeNotifier {
  static const _userPrefsKey = 'feature_request_seen_state';
  static const _adminPrefsKey = 'feature_request_admin_seen_state';

  /// Only notify for ticket activity after this date (feature launch).
  /// Existing comments/tickets from before this cutoff are ignored.
  static final DateTime notificationCutoffUtc = DateTime.utc(2026, 6, 13);

  Map<String, Map<String, dynamic>> _userSeenState = {};
  Map<String, Map<String, dynamic>> _adminSeenState = {};
  bool _loaded = false;

  static final FeatureRequestNotificationService _instance =
      FeatureRequestNotificationService._();
  factory FeatureRequestNotificationService() => _instance;
  FeatureRequestNotificationService._();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _userSeenState = _decodeMap(prefs.getString(_userPrefsKey));
    _adminSeenState = _decodeMap(prefs.getString(_adminPrefsKey));
    _loaded = true;
  }

  Map<String, Map<String, dynamic>> _decodeMap(String? json) {
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPrefsKey, jsonEncode(_userSeenState));
  }

  Future<void> _saveAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminPrefsKey, jsonEncode(_adminSeenState));
  }

  bool _hasEligibleActivity(FeatureRequest request) {
    return !request.updatedAt.isBefore(notificationCutoffUtc);
  }

  Map<String, dynamic> _snapshotFor(FeatureRequest request) => {
        'status': request.status.name,
        'commentCount': request.commentCount,
        'adminReply': request.adminReply ?? '',
      };

  Future<bool> hasUserUpdates({
    required FeatureRequest request,
    required bool isOwnRequest,
  }) async {
    await _ensureLoaded();
    return hasUserUpdatesSync(request: request, isOwnRequest: isOwnRequest);
  }

  bool hasUserUpdatesSync({
    required FeatureRequest request,
    required bool isOwnRequest,
  }) {
    if (!isOwnRequest) return false;
    if (!_hasEligibleActivity(request)) return false;
    final seen = _userSeenState[request.id];
    if (seen == null) {
      // Never opened — only notify for post-cutoff admin activity.
      return request.commentCount > 0 ||
          (request.adminReply != null && request.adminReply!.isNotEmpty) ||
          request.status != FeatureStatus.pending;
    }
    return seen['status'] != request.status.name ||
        (seen['commentCount'] as int? ?? 0) < request.commentCount ||
        (seen['adminReply'] as String? ?? '') != (request.adminReply ?? '');
  }

  Future<bool> hasAdminUpdates({required FeatureRequest request}) async {
    await _ensureLoaded();
    return hasAdminUpdatesSync(request: request);
  }

  bool hasAdminUpdatesSync({required FeatureRequest request}) {
    if (!_hasEligibleActivity(request)) return false;
    final seen = _adminSeenState[request.id];
    if (seen == null) {
      return !request.createdAt.isBefore(notificationCutoffUtc);
    }
    return (seen['commentCount'] as int? ?? 0) < request.commentCount;
  }

  int countUserUnreadSync({
    required List<FeatureRequest> requests,
    required String userId,
  }) {
    return requests
        .where((r) => hasUserUpdatesSync(
              request: r,
              isOwnRequest: r.userId == userId,
            ))
        .length;
  }

  int countAdminUnreadSync(List<FeatureRequest> requests) {
    return requests.where((r) => hasAdminUpdatesSync(request: r)).length;
  }

  Future<void> markAsSeen({required FeatureRequest request}) async {
    await _ensureLoaded();
    _userSeenState[request.id] = _snapshotFor(request);
    await _saveUser();
    notifyListeners();
  }

  Future<void> markAsSeenByAdmin({required FeatureRequest request}) async {
    await _ensureLoaded();
    _adminSeenState[request.id] = _snapshotFor(request);
    await _saveAdmin();
    notifyListeners();
  }

  Future<void> markAsSeenOnSubmit({required FeatureRequest request}) async {
    await markAsSeen(request: request);
  }

  Future<void> remove(String requestId) async {
    await _ensureLoaded();
    _userSeenState.remove(requestId);
    _adminSeenState.remove(requestId);
    await _saveUser();
    await _saveAdmin();
    notifyListeners();
  }

  Future<void> init() => _ensureLoaded();
}
