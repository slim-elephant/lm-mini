/// Runtime Google Fonts fetches (or missing bundled variants) are not crashes.
///
/// `google_fonts` loads files in an unawaited future. A blocked
/// fonts.gstatic.com used to surface as Send to support.
abstract final class GoogleFontLoadError {
  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    return s.contains('fonts.gstatic.com') ||
        s.contains('failed to load font with url') ||
        s.contains('google_fonts was unable to load font') ||
        s.contains('allowruntimefetching is false but font');
  }
}
