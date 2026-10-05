import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/community_user_profile.dart';
import '../models/feature_request.dart';
import '../pro/admin/admin_ids.dart';
import '../utils/client_platform.dart';
import '../utils/firebase_auth_session.dart';
import 'app_admin_config.dart';
import 'community_admin_service.dart';
import 'error_report_service.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

class FeatureRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Legacy hardcoded moderators — merged with Firestore [CommunityUserProfile].
  static const List<String> _legacyModeratorUserIds =
      ProAdminIds.legacyModerators;

  static final Map<String, CommunityUserProfile> _profileCache = {};

  static void cacheCommunityProfile(CommunityUserProfile profile) {
    _profileCache[profile.userId] = profile;
  }

  static bool isUserAdminSync(String userId) =>
      AppAdminConfig.isAdmin(userId);

  static bool isUserModeratorSync(String userId) =>
      AppAdminConfig.isAdmin(userId) ||
      _legacyModeratorUserIds.contains(userId) ||
      (_profileCache[userId]?.isModerator ?? false);

  static bool isUserExperiencedSync(String userId) =>
      _profileCache[userId]?.isExperiencedUser ?? false;

  // Maximum votes per user (only counts active/non-completed requests)
  static const int maxVotesPerUser = 5;
  
  // Maximum consecutive comments by same user (anti-spam)
  static const int maxConsecutiveComments = 5;

  String get _collectionPath => 'feature_requests';
  String get _commentsCollectionPath => 'feature_comments';

  /// Firestore rules allow this collection only when the request carries an
  /// auth token. Anonymous sign-in at launch can still leave the first listen
  /// without a token, which comes back as permission-denied.
  Future<void> _ensureSignedIn() async {
    if (await FirebaseAuthSession.ensureUser() == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Not signed in',
      );
    }
  }

  Stream<T> _afterSignIn<T>(Stream<T> Function() query) {
    return Stream.fromFuture(_ensureSignedIn())
        .asyncExpand((_) => query())
        .asBroadcastStream();
  }

  // Get current user ID, sign in anonymously if needed
  Future<String?> getCurrentUserId() async {
    if (_auth.currentUser == null) {
      try {
        final userCredential = await _auth.signInAnonymously();
        debugPrint('🔑 Firebase Anonymous Auth Success!');
        debugPrint('🔑 Your User ID: ${userCredential.user?.uid}');
        debugPrint('🔑 Add this ID to AppAdminConfig.adminUserIds to become admin');
      } catch (e) {
        debugPrint('❌ Firebase Auth Error: $e');
        return null;
      }
    } else {
      debugPrint('🔑 Current User ID: ${_auth.currentUser?.uid}');
    }
    return _auth.currentUser?.uid;
  }

  // Check if current user is admin
  Future<bool> get isAdmin async {
    final userId = await getCurrentUserId();
    return userId != null && AppAdminConfig.isAdmin(userId);
  }

  Future<bool> get isModerator async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return false;
      if (AppAdminConfig.isAdmin(userId)) return true;
      if (_legacyModeratorUserIds.contains(userId)) return true;
      final profile = await CommunityAdminService.instance.getProfile(userId);
      if (profile != null) {
        cacheCommunityProfile(profile);
        return profile.isModerator;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ isModerator: $e');
      return false;
    }
  }

  // Get the number of active votes a user has used (excluding completed/declined)
  Future<int> getActiveVoteCount(String userId) async {
    await _ensureSignedIn();
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('voterIds', arrayContains: userId)
        .where('status', whereIn: [
          FeatureStatus.pending.name,
          FeatureStatus.underReview.name,
          FeatureStatus.planned.name,
          FeatureStatus.inProgress.name,
          FeatureStatus.testing.name,
        ])
        .get();
    return snapshot.docs.length;
  }

  // Stream of active vote count for a user
  Stream<int> getActiveVoteCountStream(String userId) {
    return _afterSignIn(() {
      return _firestore
          .collection(_collectionPath)
          .where('voterIds', arrayContains: userId)
          .where('status', whereIn: [
            FeatureStatus.pending.name,
            FeatureStatus.underReview.name,
            FeatureStatus.planned.name,
            FeatureStatus.inProgress.name,
            FeatureStatus.testing.name,
          ])
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    });
  }

  // Get remaining votes for a user
  Future<int> getRemainingVotes(String userId) async {
    final activeVotes = await getActiveVoteCount(userId);
    return maxVotesPerUser - activeVotes;
  }

  // Stream of remaining votes
  Stream<int> getRemainingVotesStream(String userId) {
    return getActiveVoteCountStream(userId)
        .map((activeVotes) => maxVotesPerUser - activeVotes)
        .asBroadcastStream();
  }

  // Stream of popular requests (pending, sorted by votes)
  Stream<List<FeatureRequest>> getPopularRequests() {
    return _afterSignIn(() {
      return _firestore
          .collection(_collectionPath)
          .where('status', whereIn: [
            FeatureStatus.pending.name,
            FeatureStatus.underReview.name,
            FeatureStatus.planned.name,
            FeatureStatus.inProgress.name,
            FeatureStatus.testing.name,
          ])
          .orderBy('voteCount', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FeatureRequest.fromFirestore(doc))
              .toList());
    });
  }

  // Stream of user's own requests
  Stream<List<FeatureRequest>> getMyRequests(String userId) {
    return _afterSignIn(() {
      return _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FeatureRequest.fromFirestore(doc))
              .toList());
    });
  }

  // Stream of completed/declined requests (unbounded — prefer [fetchCompletedPage]).
  Stream<List<FeatureRequest>> getCompletedRequests() {
    return _afterSignIn(() {
      return _firestore
          .collection(_collectionPath)
          .where('status', whereIn: [
            FeatureStatus.completed.name,
            FeatureStatus.declined.name,
          ])
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FeatureRequest.fromFirestore(doc))
              .toList());
    });
  }

  static const int completedPageSize = 20;

  /// Paged fetch for completed/declined requests (newest [updatedAt] first).
  Future<FeatureRequestPage> fetchCompletedPage({
    DocumentSnapshot? startAfter,
    int limit = completedPageSize,
  }) async {
    await _ensureSignedIn();
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collectionPath)
        .where('status', whereIn: [
          FeatureStatus.completed.name,
          FeatureStatus.declined.name,
        ])
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final requests =
        snapshot.docs.map((doc) => FeatureRequest.fromFirestore(doc)).toList();
    return FeatureRequestPage(
      requests: requests,
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      hasMore: snapshot.docs.length >= limit,
    );
  }

  /// Open (not completed/declined) statuses — a new error report should attach
  /// to one of these instead of opening a second ticket.
  static const List<FeatureStatus> openSupportStatuses = [
    FeatureStatus.pending,
    FeatureStatus.underReview,
    FeatureStatus.planned,
    FeatureStatus.inProgress,
    FeatureStatus.testing,
  ];

  /// Same user's open Bug Fix ticket for this error, if any.
  Future<FeatureRequest?> findOpenDuplicateBug({
    required String fingerprint,
    String? title,
  }) async {
    if (fingerprint.isEmpty) return null;
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .get();

    for (final doc in snapshot.docs) {
      final req = FeatureRequest.fromFirestore(doc);
      if (!openSupportStatuses.contains(req.status)) continue;
      if (req.category != FeatureCategory.bugFix) continue;
      if (ErrorReportService.looksLikeSameOpenBug(
        incomingFingerprint: fingerprint,
        storedFingerprint: req.errorFingerprint,
        ticketTitle: req.title,
        incomingTitle: title,
      )) {
        return req;
      }
    }
    return null;
  }

  // Submit a new feature request
  Future<void> submitRequest({
    required String title,
    required String description,
    required FeatureCategory category,
    String? submitterName,
    List<FeatureAttachment> attachments = const [],
    String? errorFingerprint,
  }) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Unable to authenticate');

    if (category == FeatureCategory.bugFix &&
        errorFingerprint != null &&
        errorFingerprint.isNotEmpty) {
      final existing = await findOpenDuplicateBug(
        fingerprint: errorFingerprint,
        title: title,
      );
      if (existing != null) {
        throw DuplicateOpenBugException(existing);
      }
    }

    final isUserPremium = SubscriptionService().isPremium;
    final clientMeta = await ClientPlatform.supportMetadata();

    final now = DateTime.now();
    final request = FeatureRequest(
      id: '',
      userId: userId,
      submitterName: submitterName?.trim().isEmpty == true ? null : submitterName?.trim(),
      title: title.trim(),
      description: description.trim(),
      category: category,
      status: FeatureStatus.pending,
      voteCount: 1, // Auto-vote for own request
      voterIds: [userId], // User automatically votes for their own request
      adminReply: null,
      isPremium: isUserPremium,
      createdAt: now,
      updatedAt: now,
      attachments: attachments,
      platform: clientMeta['platform'],
      appVersion: clientMeta['appVersion'],
      errorFingerprint: errorFingerprint,
    );

    await _firestore.collection(_collectionPath).add(request.toFirestore());
  }

  // Vote for a request
  Future<void> voteForRequest(String requestId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Unable to authenticate');

    // Check if user has remaining votes
    final remainingVotes = await getRemainingVotes(userId);
    if (remainingVotes <= 0) {
      throw Exception('No votes remaining. Remove a vote from another request first.');
    }

    final docRef = _firestore.collection(_collectionPath).doc(requestId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Request not found');

      final request = FeatureRequest.fromFirestore(snapshot);
      if (request.voterIds.contains(userId)) {
        throw Exception('Already voted');
      }

      transaction.update(docRef, {
        'voteCount': FieldValue.increment(1),
        'voterIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
    });
  }

  // Remove vote from a request
  Future<void> removeVote(String requestId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Unable to authenticate');

    final docRef = _firestore.collection(_collectionPath).doc(requestId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Request not found');

      final request = FeatureRequest.fromFirestore(snapshot);
      if (!request.voterIds.contains(userId)) {
        throw Exception('Haven\'t voted yet');
      }
      
      // Don't allow removing vote from own request
      if (request.userId == userId) {
        throw Exception('Cannot remove vote from own request');
      }



      transaction.update(docRef, {
        'voteCount': FieldValue.increment(-1),
        'voterIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
    });
  }

  // Toggle vote (vote if not voted, remove if voted)
  Future<void> toggleVote(String requestId, String currentUserId, FeatureRequest request) async {
    if (request.hasVoted(currentUserId)) {
      // Don't allow removing vote from own request
      if (request.userId == currentUserId) return;
      await removeVote(requestId);
    } else {
      await voteForRequest(requestId);
    }
  }

  // Admin: Update request status
  Future<void> updateRequestStatus(String requestId, FeatureStatus newStatus) async {
    if (!await isAdmin) throw Exception('Not authorized');

    await _firestore.collection(_collectionPath).doc(requestId).update({
      'status': newStatus.name,
      'updatedAt': Timestamp.now(),
    });
  }

  // Admin: Add reply to request
  Future<void> addAdminReply(String requestId, String reply) async {
    if (!await isAdmin) throw Exception('Not authorized');

    await _firestore.collection(_collectionPath).doc(requestId).update({
      'adminReply': reply.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  // Delete a request (admin or owner only)
  Future<void> deleteRequest(String requestId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Unable to authenticate');

    final doc = await _firestore.collection(_collectionPath).doc(requestId).get();
    if (!doc.exists) return;

    final request = FeatureRequest.fromFirestore(doc);
    final isUserAdmin = await isAdmin;
    
    if (request.userId != userId && !isUserAdmin) {
      throw Exception('Not authorized to delete this request');
    }

    // Delete all comments for this request
    final commentsSnapshot = await _firestore
        .collection(_commentsCollectionPath)
        .where('requestId', isEqualTo: requestId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection(_collectionPath).doc(requestId));
    await batch.commit();
  }

  // ============ COMMENT METHODS ============

  /// Stream of comments for a specific request
  Stream<List<FeatureComment>> getComments(String requestId) {
    // Query without orderBy to avoid requiring composite index
    // Sort client-side instead
    return _firestore
        .collection(_commentsCollectionPath)
        .where('requestId', isEqualTo: requestId)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => FeatureComment.fromFirestore(doc))
              .toList();
          // Sort by createdAt ascending (oldest first)
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        })
        .handleError((error) {
          debugPrint('Error loading comments: $error');
          return <FeatureComment>[];
        });
  }

  /// Check if user can post a comment (anti-spam: max 3 consecutive comments)
  Future<bool> canUserComment(String requestId, String userId) async {
    // Admin and Moderators can always comment
    if (await isAdmin || await isModerator) return true;

    // Get the last N comments to check for consecutive posts
    final snapshot = await _firestore
        .collection(_commentsCollectionPath)
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .limit(maxConsecutiveComments)
        .get();

    if (snapshot.docs.isEmpty) return true;

    // Check if all recent comments are from this user
    int consecutiveCount = 0;
    for (final doc in snapshot.docs) {
      final comment = FeatureComment.fromFirestore(doc);
      if (comment.userId == userId) {
        consecutiveCount++;
      } else {
        break; // Another user posted, so this user can comment again
      }
    }

    return consecutiveCount < maxConsecutiveComments;
  }

  /// Get count of consecutive comments by user
  Future<int> getConsecutiveCommentCount(String requestId, String userId) async {
    final snapshot = await _firestore
        .collection(_commentsCollectionPath)
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .limit(maxConsecutiveComments)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final comment = FeatureComment.fromFirestore(doc);
      if (comment.userId == userId) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Add a comment to a feature request
  Future<void> addComment({
    required String requestId,
    required String content,
    String? authorName,
    List<FeatureAttachment> attachments = const [],
  }) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Unable to authenticate');

    // Check if user can comment (anti-spam)
    final canComment = await canUserComment(requestId, userId);
    if (!canComment) {
      throw Exception(
        'You\'ve posted $maxConsecutiveComments comments in a row. '
        'Please wait for another user to reply before commenting again.'
      );
    }

    final isUserAdmin = await isAdmin;
    final isUserModerator = await isModerator;
    final isUserPremium = SubscriptionService().isPremium;
    final clientMeta = await ClientPlatform.supportMetadata();
    final now = DateTime.now();

    final comment = FeatureComment(
      id: '',
      requestId: requestId,
      userId: userId,
      authorName: isUserAdmin ? 'Admin' : (authorName?.trim().isEmpty == true ? null : authorName?.trim()),
      content: content.trim(),
      isAdmin: isUserAdmin,
      isModerator: isUserModerator,
      isPremium: isUserPremium,
      createdAt: now,
      attachments: attachments,
      platform: clientMeta['platform'],
      appVersion: clientMeta['appVersion'],
    );

    // Add comment and increment comment count in a batch
    final batch = _firestore.batch();
    
    final commentRef = _firestore.collection(_commentsCollectionPath).doc();
    batch.set(commentRef, comment.toFirestore());
    
    final requestRef = _firestore.collection(_collectionPath).doc(requestId);
    batch.update(requestRef, {
      'commentCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
    
    await batch.commit();
  }

  /// Delete a comment (admin or comment author only)
  Future<void> deleteComment(String commentId, String requestId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Unable to authenticate');

    final doc = await _firestore.collection(_commentsCollectionPath).doc(commentId).get();
    if (!doc.exists) return;

    final comment = FeatureComment.fromFirestore(doc);
    final isUserAdmin = await isAdmin;

    if (comment.userId != userId && !isUserAdmin) {
      throw Exception('Not authorized to delete this comment');
    }

    // Delete comment and decrement count in a batch
    final batch = _firestore.batch();
    
    batch.delete(_firestore.collection(_commentsCollectionPath).doc(commentId));
    
    final requestRef = _firestore.collection(_collectionPath).doc(requestId);
    batch.update(requestRef, {
      'commentCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    });
    
    await batch.commit();
  }
}

/// Thrown when this user already has an open Bug Fix ticket for the same error.
class DuplicateOpenBugException implements Exception {
  final FeatureRequest existing;
  DuplicateOpenBugException(this.existing);

  @override
  String toString() => 'Duplicate open bug ticket ${existing.id}';
}

/// One page of feature requests from a cursor-based Firestore query.
class FeatureRequestPage {
  final List<FeatureRequest> requests;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const FeatureRequestPage({
    required this.requests,
    required this.lastDocument,
    required this.hasMore,
  });
}
