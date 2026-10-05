import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/semver.dart';

void main() {
  group('compareSemver', () {
    test('orders dotted versions', () {
      expect(compareSemver('1.9.0', '1.8.25'), greaterThan(0));
      expect(compareSemver('1.8.25', '1.9.0'), lessThan(0));
      expect(compareSemver('1.8.25', '1.8.25'), 0);
    });

    test('ignores build and prerelease suffixes', () {
      expect(compareSemver('1.9.0+117', '1.9.0'), 0);
      expect(compareSemver('1.8.25-beta', '1.8.25'), 0);
    });
  });

  group('semverLess', () {
    test('is true only when left is older', () {
      expect(semverLess('1.8.25', '1.9.0'), isTrue);
      expect(semverLess('1.9.0', '1.8.25'), isFalse);
      expect(semverLess('1.9.0', '1.9.0+116'), isFalse);
    });
  });
}
