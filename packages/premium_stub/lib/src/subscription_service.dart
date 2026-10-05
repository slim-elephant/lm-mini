import 'package:flutter/foundation.dart';

import 'subscription_pricing.dart';

/// Stub subscription service — always reports free tier.
///
/// In the real premium package, this integrates with RevenueCat
/// and Firebase Auth for subscription management.
class SubscriptionService extends ChangeNotifier {
  // Singleton
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // ─── Constants ─────────────────────────────────────────────────────
  static const entitlementId = 'premium';
  static const monthlyProductId = 'lmmini_pro_monthly';
  static const yearlyProductId = 'lmmini_pro_yearly';
  static const lifetimeProductId = 'lmmini_pro_lifetime';

  // ─── State ─────────────────────────────────────────────────────────
  bool _initialized = false;
  DateTime? _promotionalExpiresAt;
  PurchaseAnalyticsInfo? _lastPurchaseAnalytics;

  /// Open-source builds are always free. There is no developer unlock.
  bool get isPremium {
    if (_promotionalExpiresAt != null &&
        DateTime.now().isBefore(_promotionalExpiresAt!)) {
      return true;
    }
    return false;
  }

  /// The public stub never shows "Enable Developer Premium".
  bool get offersDeveloperPremium => false;

  /// When complimentary premium was granted by an admin (null if none / expired).
  DateTime? get promotionalExpiresAt => _promotionalExpiresAt;
  bool get isInitialized => _initialized;

  /// Always false in stub — RevenueCat not configured.
  bool get isConfigured => false;

  /// Always false in stub — no real API keys.
  bool get hasValidApiKeys => false;

  /// Always false in stub — RevenueCat not configured.
  bool get hasActiveSubscription => false;

  /// Always false in stub — RevenueCat not configured.
  bool get hasLifetimePurchase => false;

  /// Always false in stub — RevenueCat not configured.
  bool get hasBothSubscriptionAndLifetime => false;

  /// Always false in stub — RevenueCat not configured.
  bool get canUpgradeToLifetime => false;

  /// Always null in stub.
  String? get subscriptionManagementUrl => null;

  String? get error => null;

  /// Details from the most recent successful [purchasePackage] (null in stub).
  PurchaseAnalyticsInfo? get lastPurchaseAnalytics => _lastPurchaseAnalytics;

  // ─── Initialization ────────────────────────────────────────────────

  Future<void> initialize() async {
    _initialized = true;
    notifyListeners();
  }

  /// No-op. Real package also no longer collects IDFA/ATT device IDs.
  Future<void> collectDeviceIdentifiersForAds() async {}

  /// Applies or clears an admin-granted promotional premium window.
  void applyPromotionalGrant(DateTime? expiresAt) {
    _promotionalExpiresAt = expiresAt;
    notifyListeners();
  }

  // ─── Purchase Operations (no-op) ──────────────────────────────────

  /// No-op in stub. Real implementation purchases via RevenueCat.
  Future<bool> purchasePackage(dynamic package) async => false;

  /// No-op in stub.
  Future<bool> restorePurchases() async => false;

  /// No-op in stub.
  Future<String?> getAuthToken() async => null;

  /// No-op in the public stub. Pro features stay locked.
  Future<void> setDevPremiumOverride(bool enabled) async {}

  // ─── Offering Helpers (always null in stub) ────────────────────────

  /// No offerings available in stub.
  SubscriptionPackageInfo? get monthlyPackage => null;

  /// No offerings available in stub.
  SubscriptionPackageInfo? get annualPackage => null;

  /// One-time lifetime Pro package (non-subscription IAP).
  SubscriptionPackageInfo? get lifetimePackage => null;

  /// Win-back / promotional monthly package (RevenueCat offering package).
  /// Null in stub — real package resolves from ASC win-back or Play offer.
  SubscriptionPackageInfo? get winBackMonthlyPackage => null;

  /// True when the user previously subscribed and is eligible for a comeback offer.
  bool get isChurnedUser => false;

  /// Monthly price shown on the paywall (win-back when churned, else standard).
  String get displayMonthlyPrice {
    if (isChurnedUser) {
      return winBackMonthlyPackage?.priceString ??
          SubscriptionPricing.fallbackWinBackMonthlyUsd;
    }
    return monthlyPackage?.priceString ??
        SubscriptionPricing.fallbackMonthlyUsd;
  }

  /// Standard monthly list price (never the win-back rate).
  String get displayStandardMonthlyPrice =>
      monthlyPackage?.priceString ?? SubscriptionPricing.fallbackMonthlyUsd;

  /// Annual price for the paywall.
  String get displayAnnualPrice =>
      annualPackage?.priceString ?? SubscriptionPricing.fallbackAnnualUsd;

  /// Lifetime one-time price for the paywall.
  String get displayLifetimePrice =>
      lifetimePackage?.priceString ?? SubscriptionPricing.fallbackLifetimeUsd;

  /// Savings badge for annual vs monthly, from store prices when available.
  String? get annualSavingsBadge => SubscriptionPricing.annualSavingsBadge(
        monthlyPrice: displayStandardMonthlyPrice,
        annualPrice: displayAnnualPrice,
      );

  /// Badge when a churned user sees a discounted comeback monthly price.
  String? get winBackSavingsBadge => isChurnedUser
      ? SubscriptionPricing.winBackSavingsBadge(
          standardMonthlyPrice: displayStandardMonthlyPrice,
          winBackPrice: displayMonthlyPrice,
        )
      : null;

  /// Package to purchase for the selected plan type (`monthly` / `yearly` / `lifetime`).
  SubscriptionPackageInfo? packageForPlan(String plan) {
    if (plan == 'lifetime') return lifetimePackage;
    if (plan == 'yearly') return annualPackage;
    if (isChurnedUser && winBackMonthlyPackage != null) {
      return winBackMonthlyPackage;
    }
    return monthlyPackage;
  }

  /// Whether the paywall should deep-link to Apple's win-back flow instead of
  /// in-app purchase (fallback when no RevenueCat win-back package is loaded).
  bool get shouldUseAppleWinBackUrl =>
      isChurnedUser && winBackMonthlyPackage == null;

  // ─── Auth (stub defaults) ──────────────────────────────────────────

  bool get isAnonymousUser => true;
  String get signInMethod => 'Anonymous';

  Future<bool> upgradeWithApple() async => false;
  Future<bool> upgradeWithGoogle() async => false;
  Future<void> syncAccountAfterLink() async {}
  Future<bool> upgradeWithEmail(String email, String password) async => false;
}

/// Snapshot of the last successful store purchase for Ads / analytics.
///
/// Populated by the real premium package after [SubscriptionService.purchasePackage]
/// succeeds. Always null in the stub.
class PurchaseAnalyticsInfo {
  final String plan; // monthly | yearly | lifetime
  final double? value;
  final String? currencyCode;
  final String? transactionId;
  final String? productId;

  const PurchaseAnalyticsInfo({
    required this.plan,
    this.value,
    this.currencyCode,
    this.transactionId,
    this.productId,
  });
}

/// Information about a subscription package (monthly/annual).
///
/// In the real premium package, this wraps RevenueCat's Package type.
/// In the stub, instances are never created (getters return null).
class SubscriptionPackageInfo {
  final String priceString;
  final String identifier;
  final String packageType; // 'monthly', 'annual', or 'lifetime'

  /// Numeric price from the store (for Ads `purchase` value). Null in stub.
  final double? price;

  /// ISO currency code from the store (e.g. USD). Null in stub.
  final String? currencyCode;

  /// Opaque reference to the native package object (RevenueCat Package).
  /// Only used internally by the real premium package.
  final Object? nativeRef;

  const SubscriptionPackageInfo({
    required this.priceString,
    required this.identifier,
    required this.packageType,
    this.price,
    this.currencyCode,
    this.nativeRef,
  });
}
