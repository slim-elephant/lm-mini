import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/firebase_firestore_error.dart';

void main() {
  group('FirebaseFirestoreError', () {
    test('matches Voice-settings support log', () {
      const raw =
          '[cloud_firestore/unavailable] The service is currently unavailable. '
          'This is a most likely a transient condition and may be corrected by '
          'retrying with a backoff.';
      expect(FirebaseFirestoreError.matches(raw), isTrue);
    });

    test('does not match unrelated errors', () {
      expect(
        FirebaseFirestoreError.matches('Cannot connect to LM Studio'),
        isFalse,
      );
      expect(
        FirebaseFirestoreError.matches(
          '[firebase_storage/unauthenticated] User is unauthenticated.',
        ),
        isFalse,
      );
    });
  });
}
