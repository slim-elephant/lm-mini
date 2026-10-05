// LM-MINI-PRO-STUB
/// Build-level switch for Pro features (open-source build).
///
/// Pro implementations are not part of this build, so Pro entry points and
/// upgrade prompts stay hidden.
abstract final class ProFeatures {
  /// Whether the Pro implementations are compiled into this build.
  static const bool included = false;

  /// Whether the Pro entitlement is active in this build.
  static bool get isPro => false;

  /// Whether upgrade prompts (Pro buttons, nudges, upsell tiles) may be shown.
  static bool get showUpsell => false;
}
