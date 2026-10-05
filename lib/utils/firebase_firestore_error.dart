/// Transient Cloud Firestore / Auth network errors are not Mini crashes.
///
/// Opening Voice settings calls [FeatureRequestService.isModerator], which
/// reads `user_community_profiles`. A brief Firebase outage used to surface
/// as Send to support.
abstract final class FirebaseFirestoreError {
  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    final firestore = s.contains('cloud_firestore') ||
        s.contains('firebasefirestore') ||
        s.contains('firebase_firestore');
    final auth = s.contains('firebase_auth') || s.contains('firebaseauth');
    if (!firestore && !auth) return false;
    return s.contains('unavailable') ||
        s.contains('deadline-exceeded') ||
        s.contains('network-request-failed') ||
        s.contains('too-many-requests') ||
        s.contains('cancelled');
  }
}
