import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/feature_request.dart';
import 'package:lm_mini/services/error_report_service.dart';
import 'package:lm_mini/services/feature_attachment_service.dart';
import 'package:lm_mini/utils/image_gen_unreachable_error.dart';

void main() {
  group('ErrorReportService.capture', () {
    test('does not treat a Google Font fetch failure as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'Exception: Failed to load font with url https://fonts.gstatic.com/s/a/abc.ttf',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a LAN socket drop as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'ClientException with SocketException: Bad file descriptor '
        '(OS Error: Bad file descriptor, errno = 9), address = 192.168.0.2, '
        'uri=http://192.168.0.2:1234/api/v1/models',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat iOS audio session busy as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'PlatformException(561017449, The operation couldn’t be completed. '
        '(OSStatus error 561017449.), null, null)',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a missing-model 404 as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        '{"error":{"message":"File Not Found","type":"not_found_error","code":404}}',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat output-token exhaustion as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'MCP tools ran successfully but the model ran out of output tokens '
        'before writing a response. Try increasing max tokens in settings.',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a ComfyUI checkpoint validation as the last crash',
        () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'Exception: ComfyUI /prompt failed: HTTP 400 — '
        '{"error":{"type":"prompt_outputs_failed_validation"},'
        '"node_errors":{"4":{"errors":[{"details":"ckpt_name: \'\' not in []",'
        '"extra_info":{"input_name":"ckpt_name","received_value":""}}],'
        '"class_type":"CheckpointLoaderSimple"}}}',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat image-gen unreachable as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        "Can't reach ComfyUI at http://192.168.1.10:8188. Start it on your "
        'computer and stay on the same Wi‑Fi.',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat Firebase Storage unauthenticated as the last crash',
        () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        '[firebase_storage/unauthenticated] User is unauthenticated. '
        'Authenticate and try again.',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat context-window overflow as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'Context ran out. This prompt is larger than the loaded window '
        '(32768 tokens). A large attached image (3.2 MB) is the likely cause.',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a Connect 502 as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'Exception: Failed to load models: 502',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a dropped chat body as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        '{"error":"\'messages\' field is required"}',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat LM Studio terminated as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture('{"error":"terminated"}', null);
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a llama.cpp scheduler crash as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'llama-server process has terminated: '
        'GGML_ASSERT(n_inputs < GGML_SCHED_MAX_SPLIT_INPUTS) failed',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat Firestore unavailable as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        '[cloud_firestore/unavailable] The service is currently unavailable. '
        'This is a most likely a transient condition and may be corrected by '
        'retrying with a backoff.',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat file picker unknown_path as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        'PlatformException(unknown_path, Failed to retrieve path., null, null)',
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a named MCP connection failure as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        "Unable to connect to remote MCP server 'rss-reader' at url "
        "'https://your-rss-reader-api.com'",
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });

    test('does not treat a non-A1111 image-gen URL as the last crash', () {
      ErrorReportService.instance.capture('Cannot connect to LM Studio', null);
      ErrorReportService.instance.capture(
        ImageGenUnreachableError.wrongServerUserMessage,
        null,
      );
      expect(
        ErrorReportService.instance.lastException,
        'Cannot connect to LM Studio',
      );
    });
  });

  group('ErrorReportService.suggestedTitle', () {
    test('prefixes Error and trims to one line', () {
      expect(
        ErrorReportService.suggestedTitle('Cannot connect to LM Studio.\nmore'),
        'Error: Cannot connect to LM Studio.',
      );
    });

    test('strips Exception prefix', () {
      expect(
        ErrorReportService.suggestedTitle('Exception: boom'),
        'Error: boom',
      );
    });

    test('caps at 100 characters', () {
      final long = 'x' * 200;
      final title = ErrorReportService.suggestedTitle(long);
      expect(title.length, lessThanOrEqualTo(100));
      expect(title.startsWith('Error: '), isTrue);
    });
  });

  group('ErrorReportService.errorFingerprint', () {
    const refused8080 =
        'ClientException with SocketException: Connection refused '
        '(OS Error: Connection refused, errno = 61), address = 127.0.0.1, '
        'port = 8080';
    const refused8741 =
        'ClientException with SocketException: Connection refused '
        '(OS Error: Connection refused, errno = 61), address = 127.0.0.1, '
        'port = 8741';

    test('ignores port and IP so the same crash fingerprints equally', () {
      expect(
        ErrorReportService.errorFingerprint(refused8080),
        ErrorReportService.errorFingerprint(refused8741),
      );
    });

    test('does not collide unrelated errors', () {
      expect(
        ErrorReportService.errorFingerprint(refused8080),
        isNot(ErrorReportService.errorFingerprint(
            'Null check operator used on a null value')),
      );
    });

    test('matches an existing ticket by stored fingerprint', () {
      final fp = ErrorReportService.errorFingerprint(refused8080);
      expect(
        ErrorReportService.looksLikeSameOpenBug(
          incomingFingerprint: fp,
          storedFingerprint: fp,
          ticketTitle: 'unrelated title',
        ),
        isTrue,
      );
    });

    test('matches legacy tickets by truncated title', () {
      final title = ErrorReportService.suggestedTitle(refused8080);
      expect(
        ErrorReportService.looksLikeSameOpenBug(
          incomingFingerprint: ErrorReportService.errorFingerprint(refused8080),
          storedFingerprint: null,
          ticketTitle: title,
          incomingTitle: title,
        ),
        isTrue,
      );
    });

    test('does not match a completed-style different title', () {
      expect(
        ErrorReportService.looksLikeSameOpenBug(
          incomingFingerprint: ErrorReportService.errorFingerprint(refused8080),
          storedFingerprint: null,
          ticketTitle: 'Dark mode for settings',
          incomingTitle: ErrorReportService.suggestedTitle(refused8080),
        ),
        isFalse,
      );
    });
  });

  group('ErrorReportService.buildLogBody', () {
    test('includes error, detail, stack, and recent logs', () {
      final body = ErrorReportService.buildLogBody(
        error: 'Cannot connect',
        detail: 'SocketException: failed',
        stack: '#0 foo',
        recentLogs: ['line1', 'line2'],
        platform: 'macos',
        appVersion: '1.8.23+112',
        time: DateTime.utc(2026, 9, 3, 12),
      );
      expect(body, contains('LM Mini error log'));
      expect(body, contains('Platform: macos'));
      expect(body, contains('App version: 1.8.23+112'));
      expect(body, contains('--- Error ---'));
      expect(body, contains('Cannot connect'));
      expect(body, contains('--- Detail ---'));
      expect(body, contains('SocketException: failed'));
      expect(body, contains('--- Stack ---'));
      expect(body, contains('#0 foo'));
      expect(body, contains('--- Recent logs ---'));
      expect(body, contains('line1'));
      expect(body, contains('line2'));
    });

    test('strips Bearer JWTs from recent logs', () {
      const jwt =
          'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.fakesig';
      final body = ErrorReportService.buildLogBody(
        error: 'Pro Search unavailable',
        recentLogs: [
          '"Authorization": "Bearer $jwt"',
        ],
        platform: 'ios',
        appVersion: '1.8.25+114',
      );
      expect(body, isNot(contains(jwt)));
      expect(body, isNot(contains('eyJ')));
      expect(body, contains('[redacted]'));
    });

    test('trims huge chat prompts in recent logs', () {
      final prompt = 'You are Mini. ${'RP' * 4000}';
      final dumped = jsonEncode({
        'model': 'google/gemma-4-12b',
        'system_prompt': prompt,
        'input': 'hi',
      });
      final body = ErrorReportService.buildLogBody(
        error: '[firebase_storage/unauthenticated] User is unauthenticated.',
        recentLogs: [dumped],
        platform: 'ios',
        appVersion: '1.9.1+118',
      );
      expect(body, contains('google/gemma-4-12b'));
      expect(body, contains('chars trimmed'));
      expect(body, isNot(contains('RP' * 50)));
    });

    test('omits duplicate detail', () {
      final body = ErrorReportService.buildLogBody(
        error: 'same',
        detail: 'same',
        recentLogs: const [],
      );
      expect(body, isNot(contains('--- Detail ---')));
      expect(body, contains('(none)'));
    });

    test('truncates old logs to stay under maxLogChars', () {
      final huge = List.generate(5000, (i) => 'log line $i ${'x' * 80}');
      final body = ErrorReportService.buildLogBody(
        error: 'boom',
        recentLogs: huge,
      );
      expect(
          body.length, lessThanOrEqualTo(ErrorReportService.maxLogChars + 40));
      expect(body, contains('[truncated older logs]'));
      expect(body, contains('--- Error ---'));
      expect(body, contains('boom'));
    });
  });

  group('FeatureAttachmentService path helpers', () {
    test('recognizes log files', () {
      expect(
          FeatureAttachmentService.isLogPath('/tmp/lm-mini-error.log'), isTrue);
      expect(FeatureAttachmentService.isLogPath('/tmp/notes.txt'), isTrue);
      expect(FeatureAttachmentService.isLogPath('/tmp/shot.png'), isFalse);
      expect(FeatureAttachmentService.isImagePath('/tmp/shot.png'), isTrue);
      expect(FeatureAttachmentService.isVideoPath('/tmp/clip.mp4'), isTrue);
    });

    test('FeatureAttachment.isLog follows content type', () {
      expect(
        const FeatureAttachment(url: 'https://x', contentType: 'text/plain')
            .isLog,
        isTrue,
      );
      expect(
        const FeatureAttachment(url: 'https://x', contentType: 'image/png')
            .isLog,
        isFalse,
      );
      expect(
        const FeatureAttachment(url: 'https://x', contentType: 'video/mp4')
            .isVideo,
        isTrue,
      );
    });

    test('visibleForViewer hides logs unless admin', () {
      const log = FeatureAttachment(
        url: '',
        contentType: 'text/plain',
        storagePath: 'feature_requests/u/r/1.log',
      );
      const photo = FeatureAttachment(
        url: 'https://x',
        contentType: 'image/png',
      );
      const mixed = [log, photo];
      expect(
        FeatureAttachment.visibleForViewer(mixed, isAdmin: false),
        [photo],
      );
      expect(
        FeatureAttachment.visibleForViewer(mixed, isAdmin: true),
        mixed,
      );
      expect(
        FeatureAttachment.visibleForViewer([log], isAdmin: false),
        isEmpty,
      );
    });

    test('log attachments omit public url when serialized', () {
      const log = FeatureAttachment(
        url: '',
        contentType: 'text/plain',
        storagePath: 'feature_requests/u/r/1.log',
      );
      expect(log.toMap().containsKey('url'), isFalse);
      expect(log.toMap()['storagePath'], 'feature_requests/u/r/1.log');
    });
  });
}
