/// Android/iOS file_picker failing to resolve a content URI is not a Mini crash.
///
/// Typical: `PlatformException(unknown_path, Failed to retrieve path., null, null)`
/// after cancel, a permission deny, or a provider that has no filesystem path.
abstract final class FilePickerPathError {
  static const userMessage =
      "Couldn't copy that file. Save it on this phone (not Drive or Recents) "
      'and pick it again.';

  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    if (s.contains('unknown_path')) return true;
    if (s.contains("couldn't copy that file")) return true;
    return s.contains('failed to retrieve path');
  }
}
