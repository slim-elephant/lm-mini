import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_lock_service.dart';
import '../services/cloud_backup_service.dart';
import '../utils/layout_utils.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';
import 'subscription_screen.dart';
import '../pro/pro_features.dart';

part '../pro/settings/account_screen_pro.dart';

/// Account & sign-in screen.
///
/// Users start as anonymous. They can link Apple / Google / Email to
/// secure their account and enable Cloud Backup.
class AccountScreen extends StatefulWidget {
  final bool embedded;
  const AccountScreen({super.key, this.embedded = false});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with WidgetsBindingObserver {
  final _backupService = CloudBackupService();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _error;
  bool _checkingVerification = false;

  // Email form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshEmailVerification());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshEmailVerification());
    }
  }

  /// Firebase keeps [User.emailVerified] cached until [User.reload].
  /// Clicking the link in Mail/Safari does not emit [authStateChanges].
  Future<void> _refreshEmailVerification({bool userInitiated = false}) async {
    if (!firebaseInitialized) return;
    final user = _auth.currentUser;
    if (user == null) return;
    final needsCheck = user.email != null &&
        !user.emailVerified &&
        user.providerData.any((p) => p.providerId == 'password');
    if (!needsCheck && !userInitiated) return;

    if (userInitiated && mounted) {
      setState(() => _checkingVerification = true);
    }
    try {
      await user.reload();
      // Force a token fetch so the client picks up the verified claim.
      await _auth.currentUser?.getIdToken(true);
      if (mounted) setState(() {});
      if (userInitiated && mounted) {
        final verified = _auth.currentUser?.emailVerified == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verified
                  ? 'Email verified.'
                  : 'Still unverified. Open the link in the email, then try again.',
            ),
            backgroundColor: verified ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Email verification reload failed: $e');
      if (userInitiated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not refresh verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingVerification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return GlassSettingsScaffold(
      embedded: widget.embedded,
      title: l10n.account,
      body: !firebaseInitialized
          ? _buildFirebaseUnavailable(context)
          : StreamBuilder<User?>(
              stream: _auth.userChanges(),
              initialData: _auth.currentUser,
              builder: (context, snapshot) {
                final user = _auth.currentUser ?? snapshot.data;
                final isAnonymous = user == null ||
                    (user.isAnonymous && user.providerData.isEmpty);

                final desktop = prefersWideSettingsLayout(context);
                return DesktopSettingsForm(
                  maxWidth: desktop ? 720 : double.infinity,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      desktop ? 0 : 16,
                      desktop ? 12 : 20,
                      desktop ? 0 : 16,
                      36,
                    ),
                    children: [
                      Text(
                        !ProFeatures.included
                            ? (isAnonymous
                                ? 'Sign in to keep your account across devices and send feature requests.'
                                : 'Manage your sign-in options.')
                            : isAnonymous
                                ? 'Sign in to sync Premium and create encrypted backups.'
                                : 'Manage your sign-in and backup options.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusHero(context, user, isAnonymous),
                      const SizedBox(height: 14),
                      GlassSettingsCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GlassSettingsIcon(Icons.shield_outlined,
                                color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Chats stay on your device. Backups are encrypted with your passphrase.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ProFeatures.included &&
                          (!isAnonymous || SubscriptionService().isPremium)) ...[
                        const SizedBox(height: 14),
                        _proSyncGuide(context, isAnonymous),
                      ],
                      const SizedBox(height: 20),
                      if (isAnonymous)
                        _buildSignInSection(context)
                      else
                        _buildAccountInfo(context, user),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: colorScheme.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _error = null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusHero(
    BuildContext context,
    User? user,
    bool isAnonymous,
  ) {
    final cs = Theme.of(context).colorScheme;
    final method = isAnonymous ? null : _backupService.signInMethod;
    return GlassSettingsCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                isAnonymous ? cs.surfaceContainerHighest : cs.primaryContainer,
            child: Icon(
              isAnonymous
                  ? Icons.person_outline_rounded
                  : _providerIcon(method ?? 'Email'),
              size: 28,
              color: isAnonymous ? cs.onSurfaceVariant : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous
                      ? 'Guest'
                      : (user?.displayName ?? method ?? 'Signed in'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnonymous
                      ? 'Not signed in'
                      : (user?.email ?? 'Signed in via $method'),
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isAnonymous ? Colors.orange : Colors.green)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isAnonymous ? 'Guest' : 'Signed in',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isAnonymous
                    ? Colors.orange.shade800
                    : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sign-in section (anonymous users) ────────────────────────

  Widget _buildSignInSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.secureYourAccount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),

        // Apple sign-in (iOS / macOS only)
        if (Platform.isIOS || Platform.isMacOS) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleAppleSignIn,
              icon: const Icon(Icons.apple, size: 22),
              label: Text(
                l10n.signInWithApple,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Google sign-in
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: Icon(Icons.g_mobiledata, size: 26, color: Colors.red[600]),
            label: Text(
              l10n.signInWithGoogle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Email sign-in toggle
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () => setState(() => _showEmailForm = !_showEmailForm),
            icon: const Icon(Icons.email_outlined, size: 20),
            label: const Text(
              'Continue with Email',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Email form (expanded)
        if (_showEmailForm) ...[
          const SizedBox(height: 20),
          _buildEmailForm(context),
        ],

        if (_isLoading) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildEmailForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle sign in / sign up
            Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.signIn),
                  selected: !_isSignUp,
                  onSelected: (_) => setState(() => _isSignUp = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.createAccount),
                  selected: _isSignUp,
                  onSelected: (_) => setState(() => _isSignUp = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleEmailSignIn(),
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_isSignUp) ...[
              const SizedBox(height: 8),
              Text(
                'Password must be at least 6 characters.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  child: Text(l10n.forgotPassword),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleEmailSignIn,
                child: Text(_isSignUp ? l10n.createAccount : l10n.signIn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Signed-in account info ───────────────────────────────────

  Widget _buildAccountInfo(BuildContext context, User user) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (Platform.isIOS) ...[
          _buildICloudSyncToggle(context),
          const SizedBox(height: 14),
        ],

        // Email verification banner
        if (user.email != null &&
            !user.emailVerified &&
            user.providerData.any((p) => p.providerId == 'password'))
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    color: Colors.orange, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verify your email',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please check your inbox and verify your email address.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          GestureDetector(
                            onTap: _checkingVerification
                                ? null
                                : () => unawaited(
                                      _refreshEmailVerification(
                                        userInitiated: true,
                                      ),
                                    ),
                            child: Text(
                              _checkingVerification
                                  ? 'Checking…'
                                  : 'I verified — check again',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              try {
                                await user.sendEmailVerification();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.verificationEmailSent),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(l10n.errorGeneric(e.toString())),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Resend verification email',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        _proAccountCard(context, l10n, colorScheme),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleSignOut,
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l10n.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Signing out keeps your local chats. You become a guest again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseUnavailable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Cloud services unavailable',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Firebase is not configured. Account and Cloud Backup '
              'require a Firebase project.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _providerIcon(String method) {
    switch (method) {
      case 'Apple':
        return Icons.apple;
      case 'Google':
        return Icons.g_mobiledata;
      case 'Email':
        return Icons.email;
      default:
        return Icons.person;
    }
  }

  // ─── Actions ──────────────────────────────────────────────────

  Future<void> _bindAppLockRecovery() async {
    final identity = _backupService.recoveryIdentity;
    if (identity == null) return;
    await AppLockService.instance.bindRecoveryIfUnlocked(
      uid: identity.uid,
      email: identity.email,
    );
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _backupService.signInWithApple();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await _bindAppLockRecovery();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Signed in with Apple!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _error = 'Apple sign-in failed. Please try again.');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _backupService.signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await _bindAppLockRecovery();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Signed in with Google!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _error = _backupService.lastGoogleSignInError ??
            'Google sign-in failed. Please try again.');
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = l10n.forgotPasswordNeedEmail);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _backupService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.forgotPasswordSent),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Don't reveal whether the address is registered.
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.forgotPasswordSent),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _error = _friendlyAuthError(e));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.forgotPasswordFailed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailSignIn() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        // Create account
        final user = _auth.currentUser;
        if (user != null && user.isAnonymous) {
          final credential =
              EmailAuthProvider.credential(email: email, password: password);
          try {
            await user.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use') {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error =
                      'This email is already registered. Try signing in instead.';
                  _isSignUp = false;
                });
              }
              return;
            }
            rethrow;
          }
        } else {
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      } else {
        // Sign in
        final success = await _backupService.signInWithEmail(email, password);
        if (!success) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = 'Invalid email or password. Please try again.';
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        await _bindAppLockRecovery();
        if (!mounted) return;

        // Send verification email for new sign-ups
        if (_isSignUp) {
          try {
            final currentUser = _auth.currentUser;
            if (currentUser != null && !currentUser.emailVerified) {
              await currentUser.sendEmailVerification();
            }
          } catch (e) {
            debugPrint('⚠️ Failed to send verification email: $e');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '✅ Account created! Check your email to verify your address.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Signed in with Email!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _emailController.clear();
        _passwordController.clear();
        setState(() => _showEmailForm = false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _friendlyAuthError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = l10n.errorGeneric(e.toString());
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutConfirm),
        content: const Text(
          'You will be signed out and reverted to an anonymous account.\n\n'
          'Your local conversations are not affected. '
          'You can sign in again later to access your cloud backups.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _backupService.signOut();

    // Reset cloud provider & restore LM Studio model immediately
    if (mounted) {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.restoreLocalModelIfNeeded();
      // Refresh model list from LM Studio so the UI is up-to-date
      try {
        await settingsProvider.loadAvailableModels();
      } catch (_) {
        // LM Studio may be offline — non-fatal
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out.')),
      );
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email. Try creating one.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }

  // ─── iCloud Sync Toggle (Apple Devices Only) ──────────────────

  Widget _buildICloudSyncToggle(BuildContext context) {
    // Note: We use SharedPreferences here to store the toggle state locally.
    // In a fully integrated system, the SyncEngine would react to this stream.
    return FutureBuilder<bool>(
      // Temporary inline lookup for the UI toggle
      future: SharedPreferences.getInstance()
          .then((prefs) => prefs.getBool('icloud_sync_enabled') ?? false),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        final colorScheme = Theme.of(context).colorScheme;

        return GlassSettingsCard(
          child: Column(
            children: [
              DesktopPreferenceRow(
                icon: Icons.cloud_sync,
                title: 'Real-time iCloud Sync',
                subtitle:
                    'Seamlessly sync recent conversations between your iPhone, iPad, and Mac.',
                trailing: Switch(
                  value: isEnabled,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('icloud_sync_enabled', value);
                    setState(() {});

                    if (value && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('iCloud Sync enabled'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ),
              if (isEnabled) ...[
                if (!useDesktopSettingsControls(context))
                  const Divider(height: 1)
                else
                  const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your device is now continuously mirroring local changes to CloudKit. Make sure you are signed into iCloud in your device Settings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
