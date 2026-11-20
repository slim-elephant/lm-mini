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

  /// One-time lifetime unlock for new subscribers.
  static const fallbackLifetimeUsd = r'$119.99';

  static final _number = RegExp(r"\d(?:[\d.,'\u00a0\u202f ]*\d)?");

  /// Amount in a store price string: "$29.99", "29,99 €", "Rs 8,900",
  /// "1.299,00 kr", "¥4,500". A separator followed by exactly two digits at
  /// the end is the decimal point; every other separator groups thousands.
  static double? parseAmount(String? priceString) {
    final m = _number.firstMatch(priceString ?? '');
    if (m == null) return null;
    final (whole, cents, _, _) = _split(m[0]!);
    return double.tryParse('$whole.${cents ?? '0'}');
  }

  /// The yearly price as a monthly amount in the same currency and style:
  /// "$29.99" → "$2.50", "Rs 8,900" → "Rs 742", "29,99 €" → "2,50 €".
  /// [amount] is the store's numeric price, used when it's known.
  static String? perMonth(String annualPrice, {double? amount}) {
    final m = _number.firstMatch(annualPrice);
    if (m == null) return null;
    final (_, cents, decimalSep, groupSep) = _split(m[0]!);
    final annual = amount ?? parseAmount(annualPrice);
    if (annual == null || annual <= 0) return null;
    final monthly = annual / 12;
    final String text;
    if (cents != null) {
      final fixed = ((monthly * 100).round() / 100).toStringAsFixed(2);
      final parts = fixed.split('.');
      text = '${_group(parts[0], groupSep)}$decimalSep${parts[1]}';
    } else {
      text = _group(monthly.round().toString(), groupSep);
    }
    return annualPrice.replaceRange(m.start, m.end, text);
  }

  /// (whole digits, cents or null, decimal separator, grouping separator).
  static (String, String?, String, String) _split(String number) {
    final dec = RegExp(r'[.,](\d{2})$').firstMatch(number);
    final wholePart = dec == null ? number : number.substring(0, dec.start);
    final groupMatch = RegExp(r"[.,'\u00a0\u202f ]").firstMatch(wholePart);
    final decimalSep = dec == null ? '.' : number[dec.start];
    final groupSep = groupMatch?[0] ?? (decimalSep == ',' ? '.' : ',');
    return (
      wholePart.replaceAll(RegExp(r'\D'), ''),
      dec?[1],
      decimalSep,
      groupSep,
    );
  }

  static String _group(String digits, String sep) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(sep);
      out.write(digits[i]);
    }
    return out.toString();
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
