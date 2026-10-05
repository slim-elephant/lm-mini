import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/file_picker_path_error.dart';

void main() {
  group('FilePickerPathError', () {
    test('matches transcribe picker support log', () {
      const raw =
          'PlatformException(unknown_path, Failed to retrieve path., null, null)';
      expect(FilePickerPathError.matches(raw), isTrue);
    });

    test('does not match unrelated errors', () {
      expect(
        FilePickerPathError.matches('Cannot connect to LM Studio'),
        isFalse,
      );
    });

    test('matches the friendly copy snackbar', () {
      expect(
        FilePickerPathError.matches(FilePickerPathError.userMessage),
        isTrue,
      );
    });
  });
}
