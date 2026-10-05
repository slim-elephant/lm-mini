import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/community_user_profile.dart';
import '../models/premium_grant.dart';

/// Reads of community roles and complimentary premium grants, plus the
/// recipient-side grant acknowledgements.
///
/// The admin writes (roles, granting and revoking premium) live in the
/// private `lib/pro/admin/community_admin_writes.dart`.
class CommunityAdminService {
  CommunityAdminService._();
  static final CommunityAdminService instance = CommunityAdminService._();

  static const _profilesCollection = 'user_community_profiles';
  static const _grantsCollection = 'premium_grants';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _profileRef(String userId) =>
      _firestore.collection(_profilesCollection).doc(userId);

  DocumentReference<Map<String, dynamic>> _grantRef(String userId) =>
      _firestore.collection(_grantsCollection).doc(userId);

  Stream<CommunityUserProfile?> watchProfile(String userId) {
    return _profileRef(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CommunityUserProfile.fromFirestore(userId, doc.data()!);
    });
  }

  Future<CommunityUserProfile?> getProfile(String userId) async {
    try {
      final doc = await _profileRef(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CommunityUserProfile.fromFirestore(userId, doc.data()!);
    } catch (e) {
      debugPrint('CommunityAdmin: getProfile failed: $e');
      return null;
    }
  }

  Stream<PremiumGrant?> watchPremiumGrant(String userId) {
    return _grantRef(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PremiumGrant.fromFirestore(doc.data()!);
    });
  }

  Future<PremiumGrant?> getPremiumGrant(String userId) async {
    final doc = await _grantRef(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PremiumGrant.fromFirestore(doc.data()!);
  }

  /// Called by the recipient to dismiss the welcome banner/dialog.
  Future<void> acknowledgePremiumBanner(String userId, String grantId) async {
    if (_auth.currentUser?.uid != userId) return;
    final doc = await _grantRef(userId).get();
    if (!doc.exists || doc.data() == null) return;
    final grant = PremiumGrant.fromFirestore(doc.data()!);
    if (grant.grantId != grantId) return;
    await _grantRef(userId).update({'bannerAcknowledged': true});
  }

  /// Marks that the OS/in-app notification was shown for this grant.
  Future<void> markPremiumNotificationSent(String userId) async {
    if (_auth.currentUser?.uid != userId) return;
    await _grantRef(userId).update({'notificationSent': true});
  }
}
