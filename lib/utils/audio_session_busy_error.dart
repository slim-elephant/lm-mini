/// iOS refused to activate playback because another session (usually the mic)
/// is still active. `just_audio` / `audio_session` surfaces this as
/// OSStatus 561017449 (`CannotInterruptOthers`).
///
/// Not a crash — the sentence may skip. Do not Send to support.
abstract final class AudioSessionBusyError {
  static bool matches(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    return s.contains('561017449') ||
        s.contains('cannotinterruptothers') ||
        s.contains('osstatus error 561017449');
  }
}
