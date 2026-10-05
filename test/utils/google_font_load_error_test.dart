import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lm_mini/utils/bundled_google_fonts.dart';
import 'package:lm_mini/utils/google_font_load_error.dart';

void main() {
  group('GoogleFontLoadError', () {
    test('matches the fonts.gstatic fetch exception from support logs', () {
      const raw =
          'Exception: Failed to load font with url https://fonts.gstatic.com/s/a/abc.ttf: ClientException with SocketException: No route to host';
      expect(GoogleFontLoadError.matches(raw), isTrue);
    });

    test('matches disabled runtime fetching', () {
      expect(
        GoogleFontLoadError.matches(
          'GoogleFonts.config.allowRuntimeFetching is false but font Poppins-Light was not found',
        ),
        isTrue,
      );
    });

    test('does not match unrelated errors', () {
      expect(
        GoogleFontLoadError.matches('Cannot connect to LM Studio'),
        isFalse,
      );
    });
  });

  test('disableRuntimeFetching turns off HTTP font loads', () {
    GoogleFonts.config.allowRuntimeFetching = true;
    BundledGoogleFonts.disableRuntimeFetching();
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });
}
