import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../pro/config/google_sign_in_config.dart';

/// Firebase web client ID (type 3) from google-services.json / Firebase console.
/// Android needs this as [GoogleSignIn.serverClientId] to obtain an idToken.
///
/// Builds from source pass their own with
/// `--dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=...`; empty means unset.
const kGoogleSignInWebClientId = String.fromEnvironment(
  'GOOGLE_SIGN_IN_WEB_CLIENT_ID',
  defaultValue: kProGoogleSignInWebClientId,
);

/// Native Google Sign-In → Firebase Auth credential flow.
///
/// iOS reads the client ID from GIDClientID in Info.plist; Android must pass
/// [kGoogleSignInWebClientId] as serverClientId.
class GoogleSignInHelper {
  GoogleSignInHelper._();

  static GoogleSignIn _client() => GoogleSignIn(
        scopes: ['email'],
        serverClientId:
            Platform.isAndroid && kGoogleSignInWebClientId.isNotEmpty
                ? kGoogleSignInWebClientId
                : null,
      );

  /// Link, reauthenticate, or sign in with Google. Returns false if cancelled.
  static Future<bool> linkOrSignIn(FirebaseAuth auth) async {
    final googleSignIn = _client();

    // Clear stale cached account so account picker / token refresh works.
    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ Google sign-out before sign-in: $e');
    }

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('⚠️ Google sign-in cancelled by user');
      return false;
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw StateError(
        'Google Sign-In returned no ID token. '
        'On Android, add this build\'s SHA-1 fingerprint to Firebase '
        '(Project settings → Your apps → Android → Add fingerprint).',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final user = auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        await user.linkWithCredential(credential);
        return true;
      } on FirebaseAuthException catch (e) {
        // Google account already has an LM Mini account, or the same email
        // was used with email/Apple sign-in. Sign in to that account instead.
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          await auth.signInWithCredential(e.credential ?? credential);
          return true;
        }
        rethrow;
      }
    }

    if (user != null) {
      await user.reauthenticateWithCredential(credential);
      return true;
    }

    await auth.signInWithCredential(credential);
    return true;
  }

  /// Plain-language message for a failed Google sign-in.
  static String describeError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'This email already has an LM Mini account that uses a '
              'different sign-in (Apple or email). Sign in that way instead.';
        case 'network-request-failed':
          return 'No internet connection. Check your connection and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
      }
      return e.message ?? e.code;
    }
    if (e is StateError) return e.message;
    if (e is PlatformException) {
      final detail = '${e.code} ${e.message ?? ''}';
      if (detail.contains('ApiException: 7') || e.code == 'network_error') {
        return 'No internet connection. Check your connection and try again.';
      }
      if (detail.contains('ApiException: 10')) {
        return 'Google sign-in is not set up for this copy of the app '
            '(code 10). Install LM Mini from Google Play, or use email sign-in.';
      }
      if (detail.contains('ApiException: 12500') ||
          detail.contains('ApiException: 16')) {
        return 'Google Play services could not finish sign-in. Update Google '
            'Play services, or use email sign-in. (${e.code})';
      }
      return 'Google sign-in failed (${e.code}). Please try again, '
          'or use email sign-in.';
    }
    return 'Google sign-in failed. Please try again.';
  }
}
