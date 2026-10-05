import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase ID tokens last ~1 hour. The refresh token does not expire on a
/// timer — a signed-in (including anonymous) session should survive until
/// sign-out, revoke, or a failed refresh after network loss.
///
/// Storage reports `unauthenticated` when it has no user / no ID token, not
/// when the ID token is merely stale. Call [ensureUser] before uploads so a
/// logged-in user is not treated as signed out.
abstract final class FirebaseAuthSession {
  static Future<User?> ensureUser({bool forceTokenRefresh = false}) async {
    final auth = FirebaseAuth.instance;
    var user = auth.currentUser;
    if (user == null) {
      try {
        user = (await auth.signInAnonymously()).user;
      } catch (e) {
        debugPrint('⚠️ FirebaseAuthSession: anonymous sign-in failed: $e');
        return null;
      }
    }
    try {
      await user?.getIdToken(forceTokenRefresh);
    } catch (e) {
      debugPrint('⚠️ FirebaseAuthSession: token refresh failed: $e');
      if (!forceTokenRefresh) {
        try {
          await user?.getIdToken(true);
        } catch (e2) {
          debugPrint(
              '⚠️ FirebaseAuthSession: forced token refresh failed: $e2');
        }
      }
    }
    return auth.currentUser;
  }

  /// Run a Storage/Firestore call, refreshing the ID token once if the
  /// plugin reports `unauthenticated` after a network blip.
  static Future<T> withFreshToken<T>(Future<T> Function() action) async {
    if (await ensureUser() == null) {
      throw StateError('You must be signed in.');
    }
    try {
      return await action();
    } on FirebaseException catch (e) {
      if (e.code != 'unauthenticated' && e.code != 'unauthorized') {
        rethrow;
      }
      debugPrint(
          '⚠️ FirebaseAuthSession: ${e.code} — refreshing token and retrying');
      if (await ensureUser(forceTokenRefresh: true) == null) rethrow;
      return action();
    }
  }
}
