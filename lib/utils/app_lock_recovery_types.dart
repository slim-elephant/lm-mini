/// Public App Lock recovery types shared with `CloudBackupService` and the
/// account screen. The recovery rules themselves live in the Pro overlay.
class AppLockRecoveryIdentity {
  final String uid;
  final String? email;
  final bool emailVerified;
  final DateTime? lastSignInAt;

  const AppLockRecoveryIdentity({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.lastSignInAt,
  });
}
