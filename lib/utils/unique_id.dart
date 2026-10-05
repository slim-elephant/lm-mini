/// Wall-clock milliseconds, bumped when two callers land in the same ms.
///
/// Conversation and message primary keys used `DateTime.now().millisecondsSinceEpoch`
/// directly, so two New Chat taps (or split-pane auto-fill + FAB) in the same
/// millisecond hit SQLite `UNIQUE conversations.id`. Dart is single-isolate, so
/// this increment is enough — no two `_uid()` calls can return the same value.
int _lastMs = 0;

String uniqueTimeId() {
  var ms = DateTime.now().millisecondsSinceEpoch;
  if (ms <= _lastMs) ms = _lastMs + 1;
  _lastMs = ms;
  return ms.toString();
}

bool isSqliteUniqueConstraint(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('unique constraint') ||
      s.contains('sqlite_constraint_primarykey') ||
      s.contains('code 1555');
}
