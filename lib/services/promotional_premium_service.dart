import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show firebaseInitialized;
import '../models/premium_grant.dart';
import 'community_admin_service.dart';
import 'widget_data_service.dart';

/// Syncs Firestore premium grants to [SubscriptionService] and exposes UI state
/// for welcome banners and notifications.
class PromotionalPremiumService extends ChangeNotifier {
  PromotionalPremiumService._();
  static final PromotionalPremiumService instance =
      PromotionalPremiumService._();

  final CommunityAdminService _adminService = CommunityAdminService.instance;
  StreamSubscription<PremiumGrant?>? _grantSub;

  PremiumGrant? _activeGrant;
  PremiumGrant? _pendingWelcomeGrant;

  PremiumGrant? get activeGrant =>
      _activeGrant != null && _activeGrant!.isActive ? _activeGrant : null;

  /// Grant that should show a welcome banner/dialog (not yet acknowledged).
  PremiumGrant? get pendingWelcomeGrant => _pendingWelcomeGrant;

  /// Active grant with banner not yet dismissed.
  PremiumGrant? get pendingBannerGrant => _pendingWelcomeGrant;

  bool get hasPendingBanner => _pendingWelcomeGrant != null;

  Future<bool> shouldShowWelcomeDialog() async {
    final grant = _pendingWelcomeGrant;
    if (grant == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('premium_grant_dialog_seen') != grant.grantId;
  }

  Future<void> markWelcomeDialogShown() async {
    final grant = _pendingWelcomeGrant;
    if (grant == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('premium_grant_dialog_seen', grant.grantId);
  }

  Future<void> initialize() async {
    if (!firebaseInitialized) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _grantSub?.cancel();
    _grantSub = _adminService.watchPremiumGrant(uid).listen(
      _onGrantChanged,
      onError: (Object e) {
        debugPrint('PromotionalPremiumService: grant stream error: $e');
      },
    );
  }

  void _onGrantChanged(PremiumGrant? grant) {
    _activeGrant = grant;

    if (grant != null && grant.isActive) {
      SubscriptionService().applyPromotionalGrant(grant.expiresAt);
      if (!grant.bannerAcknowledged) {
        _pendingWelcomeGrant = grant;
      } else if (_pendingWelcomeGrant?.grantId == grant.grantId) {
        _pendingWelcomeGrant = null;
      }
    } else {
      SubscriptionService().applyPromotionalGrant(null);
      _pendingWelcomeGrant = null;
    }

    unawaited(WidgetDataService.syncPremiumStatus());
    notifyListeners();
  }

  Future<void> acknowledgeWelcome() async {
    final grant = _pendingWelcomeGrant;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (grant == null || uid == null) return;

    await _adminService.acknowledgePremiumBanner(uid, grant.grantId);
    _pendingWelcomeGrant = null;
    notifyListeners();
  }

  Future<void> markNotificationHandled() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _adminService.markPremiumNotificationSent(uid);
  }

  @override
  void dispose() {
    _grantSub?.cancel();
    super.dispose();
  }
}
