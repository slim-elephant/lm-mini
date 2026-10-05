import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/vision_physical_batch.dart';

void main() {
  test('a full photo exceeds the default physical batch', () {
    expect(VisionPhysicalBatch.exceeds(4032, 3024), isTrue);
    expect(VisionPhysicalBatch.exceeds(1200, 1200), isTrue);
  });

  test('a 768px square stays under the safe budget', () {
    expect(VisionPhysicalBatch.exceeds(768, 768), isFalse);
  });

  test('target edge brings a large photo under the pixel budget', () {
    const w = 4032;
    const h = 3024;
    final edge = VisionPhysicalBatch.targetLongestEdge(w, h);
    final scale = edge / w;
    final pixels = (w * scale) * (h * scale);
    expect(pixels, lessThanOrEqualTo(VisionPhysicalBatch.safeMaxPixels + 1));
    expect(edge, lessThan(w));
  });
}
