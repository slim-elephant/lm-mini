import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/lm_studio_download_cancel.dart';

void main() {
  group('lmStudioDownloadCancelAttempts', () {
    test('tries cancel POST then DELETE status then status/cancel', () {
      final attempts = lmStudioDownloadCancelAttempts('job_abc');
      expect(attempts, hasLength(4));
      expect(attempts[0].method, 'POST');
      expect(attempts[0].path, '/api/v1/models/download/cancel');
      expect(attempts[0].body, {
        'job_id': 'job_abc',
        'jobIdentifier': 'job_abc',
      });
      expect(attempts[1].method, 'DELETE');
      expect(attempts[1].path, '/api/v1/models/download/status/job_abc');
      expect(attempts[2].path, '/api/v1/models/download/status/job_abc/cancel');
      expect(attempts[3].path, '/api/v1/models/download/job_abc/cancel');
    });

    test('accepts 200/202/204 and retries 404/405', () {
      expect(lmStudioCancelHttpAccepted(200), isTrue);
      expect(lmStudioCancelHttpAccepted(204), isTrue);
      expect(lmStudioCancelHttpTryNext(404), isTrue);
      expect(lmStudioCancelHttpTryNext(500), isFalse);
    });
  });

  group('lmStudioDownloadStatusIsTerminal', () {
    test('treats cancelled as finished so the FAB can dismiss', () {
      expect(lmStudioDownloadStatusIsTerminal('cancelled'), isTrue);
      expect(lmStudioDownloadStatusIsTerminal('canceled'), isTrue);
      expect(lmStudioDownloadStatusIsTerminal('failed'), isTrue);
      expect(lmStudioDownloadStatusIsTerminal('downloading'), isFalse);
      expect(lmStudioDownloadStatusIsTerminal('paused'), isFalse);
    });
  });
}
