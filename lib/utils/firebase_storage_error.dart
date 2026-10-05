/// Firebase Storage auth / transient network errors are not Mini crashes.
///
/// After a dropped connection the iOS plugin can retry without a token and
/// surface `unauthenticated` even though [FirebaseAuth.currentUser] is set.
abstract final class FirebaseStorageError {
  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    if (!s.contains('firebase_storage') && !s.contains('firebase storage')) {
      return false;
    }
    return s.contains('unauthenticated') ||
        s.contains('unauthorized') ||
        s.contains('network connection was lost') ||
        s.contains('retry-limit-exceeded') ||
        s.contains('object-not-found');
  }
}
