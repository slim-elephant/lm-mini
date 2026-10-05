/// Store-agnostic fallback prices when RevenueCat offerings are not loaded yet.
///
/// Keep in sync with App Store Connect / Play Console list prices for **new**
/// subscribers. RevenueCat [SubscriptionPackageInfo.priceString] overrides
/// these when available.
class SubscriptionPricing {
  SubscriptionPricing._();

  /// Default monthly for new subscribers (after price increase).
  static const fallbackMonthlyUsd = r'$4.99';

  /// Default annual for new subscribers.
  static const fallbackAnnualUsd = r'$29.99';

  /// Win-back / comeback monthly (one promotional period in ASC / Play offers).
  static const fallbackWinBackMonthlyUsd = r'$1.99';

  /// One-time lifetime unlock for new subscribers.
  static const fallbackLifetimeUsd = r'$119.99';

  /// Best-effort parse of a leading decimal amount from a localized price string.
  static double? parseAmount(String? priceString) {
    if (priceString == null || priceString.isEmpty) return null;
    final match = RegExp(r'(\d+[.,]\d{2})').firstMatch(priceString);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  /// e.g. monthly \$4.99 × 12 vs annual \$29.99 → "-50%".
  static String? annualSavingsBadge({
    required String? monthlyPrice,
    required String? annualPrice,
  }) {
    final monthly = parseAmount(monthlyPrice);
    final annual = parseAmount(annualPrice);
    if (monthly == null || annual == null || monthly <= 0) return null;
    final fullYear = monthly * 12;
    if (annual >= fullYear) return null;
    final pct = ((1 - annual / fullYear) * 100).round();
    if (pct <= 0) return null;
    return '-$pct%';
  }

  /// Discount of win-back vs standard monthly, e.g. "-60%".
  static String? winBackSavingsBadge({
    required String? standardMonthlyPrice,
    required String? winBackPrice,
  }) {
    final standard = parseAmount(standardMonthlyPrice);
    final offer = parseAmount(winBackPrice);
    if (standard == null || offer == null || standard <= 0 || offer >= standard) {
      return null;
    }
    final pct = ((1 - offer / standard) * 100).round();
    if (pct <= 0) return null;
    return '-$pct%';
  }
}
