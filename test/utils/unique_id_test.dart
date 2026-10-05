import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/unique_id.dart';

void main() {
  test('uniqueTimeId never collides in a tight loop', () {
    const n = 10000;
    final ids = <String>{};
    for (var i = 0; i < n; i++) {
      ids.add(uniqueTimeId());
    }
    expect(ids.length, n);
  });

  test('isSqliteUniqueConstraint matches the Android ticket fingerprint', () {
    const raw =
        "Failed to create conversation: DatabaseException(UNIQUE constraint failed: conversations.id (code 1555 SQLITE_CONSTRAINT_PRIMARYKEY)) sql 'INSERT INTO conversations";
    expect(isSqliteUniqueConstraint(raw), isTrue);
    expect(isSqliteUniqueConstraint('connection refused'), isFalse);
  });
}
