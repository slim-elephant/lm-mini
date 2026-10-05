import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/media_gallery.dart';

void main() {
  test('missing file does not save', () async {
    final result = await MediaGallery.save(
      '/tmp/lm-mini-missing-${DateTime.now().microsecondsSinceEpoch}.png',
    );
    expect(result, MediaSaveOutcome.failed);
  });
}
