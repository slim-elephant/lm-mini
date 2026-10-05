import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'google_sign_in_helper.dart';
import '../utils/app_lock_recovery_types.dart';

/// Firebase account sign-in shared by the Account screen, App Lock and the
/// Pro cloud backup.
///
/// The encrypted backup engine itself (create / list / restore / delete,
/// passphrase cache, AES-256-GCM crypto) lives in the Pro overlay under
/// `lib/pro/` and is not part of the public build.
class CloudBackupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Auth helpers ─────────────────────────────────────────────

  /// Current Firebase user (may be anonymous or linked).
  User? get currentUser => _auth.currentUser;

  /// Whether the user has linked a real sign-in provider
  /// (not just anonymous).
  bool get isSignedIn {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (!user.isAnonymous) return true;
    // Anonymous user that has linked a provider
    return user.providerData.any((p) =>
        p.providerId == 'apple.com' ||
        p.providerId == 'google.com' ||
        p.providerId == 'password');
  }

  // ─── Sign-In Methods ──────────────────────────────────────────

  /// Sign in (or link) with Apple.
  /// Links to the existing anonymous account when possible.
  Future<bool> signInWithApple() async {
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        // Try to link to preserve UID / existing data
        try {
          await user.linkWithProvider(provider);
          return true;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Apple account already exists — sign in directly
            await _auth.signInWithProvider(provider);
            return true;
          }
          rethrow;
        }
      } else {
        await _auth.signInWithProvider(provider);
        return true;
      }
    } catch (e) {
      debugPrint('❌ Apple sign-in failed: $e');
      return false;
    }
  }

  /// Sign in (or link) with Google using native SDK.
  String? lastGoogleSignInError;

  Future<bool> signInWithGoogle() async {
    lastGoogleSignInError = null;
    try {
      return await GoogleSignInHelper.linkOrSignIn(_auth);
    } catch (e) {
      lastGoogleSignInError = GoogleSignInHelper.describeError(e);
      debugPrint('❌ Google sign-in failed: $e');
      return false;
    }
  }

  /// Sign in (or link) with email + password.
  /// Creates a new account if one doesn't exist.
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final credential =
          EmailAuthProvider.credential(email: email, password: password);

      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          await user.linkWithCredential(credential);
          return true;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            // Account exists — sign in directly
            await _auth.signInWithCredential(credential);
            return true;
          }
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            rethrow; // Let caller show error
          }
          rethrow;
        }
      } else if (user == null) {
        // No user at all — try sign in, fall back to create
        try {
          await _auth.signInWithCredential(credential);
          return true;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            return true;
          }
          rethrow;
        }
      } else {
        // Already signed in with a provider — reauthenticate
        await user.reauthenticateWithCredential(credential);
        return true;
      }
    } catch (e) {
      debugPrint('❌ Email sign-in failed: $e');
      return false;
    }
  }

  /// Signed-in Apple / Google / email account used for App Lock recovery.
  AppLockRecoveryIdentity? get recoveryIdentity {
    if (!isSignedIn) return null;
    final user = currentUser;
    if (user == null) return null;
    String? email = user.email;
    if (email == null || email.isEmpty) {
      for (final p in user.providerData) {
        final candidate = p.email;
        if (candidate != null && candidate.isNotEmpty) {
          email = candidate;
          break;
        }
      }
    }
    return AppLockRecoveryIdentity(
      uid: user.uid,
      email: email,
      emailVerified: user.emailVerified,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }

  /// Sends Firebase's password-reset email.
  ///
  /// After the Firebase Console action URL is set to
  /// `https://lmmini.com/auth/action.html`, the link opens the branded
  /// handler. Until then, Firebase's default reset page still works.
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out and revert to anonymous.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Re-establish anonymous session
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('❌ Sign-out failed: $e');
    }
  }

  /// Display-friendly sign-in method name.
  String get signInMethod {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous && user.providerData.isEmpty) {
      return 'Anonymous';
    }
    for (final p in user.providerData) {
      if (p.providerId == 'apple.com') return 'Apple';
      if (p.providerId == 'google.com') return 'Google';
      if (p.providerId == 'password') return 'Email';
    }
    return 'Unknown';
  }
}
