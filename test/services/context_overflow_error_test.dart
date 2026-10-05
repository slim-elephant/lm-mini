import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/lm_studio_service.dart';

const _lmStudio500Body = r'''
{
  "error": {
    "message": "Engine protocol predict request returned 400: {\"error\":{\"code\":400,\"message\":\"request (608 tokens) exceeds the available context size (512 tokens), try increasing it\",\"type\":\"exceed_context_size_error\",\"n_prompt_tokens\":608,\"n_ctx\":512}}",
    "type": "internal_error",
    "code": "unknown",
    "param": null
  }
}
''';

const _innerEngineMessage =
    'request (608 tokens) exceeds the available context size (512 tokens), try increasing it';

void main() {
  group('isContextOverflowError', () {
    test('matches LM Studio HTTP 500 wrapping engine 400', () {
      expect(LMStudioService.isContextOverflowError(_lmStudio500Body), isTrue);
    });

    test('matches inner llama.cpp message without n_ctx key', () {
      expect(
        LMStudioService.isContextOverflowError(_innerEngineMessage),
        isTrue,
      );
    });

    test('matches typed error maps', () {
      expect(
        LMStudioService.isContextOverflowError({
          'type': 'exceed_context_size_error',
          'message': 'too big',
          'n_prompt_tokens': 608,
          'n_ctx': 512,
        }),
        isTrue,
      );
    });

    test('matches tagged stream chunks', () {
      expect(
        LMStudioService.isContextOverflowError({
          'error': _innerEngineMessage,
          'error_type': LMStudioService.contextOverflowType,
        }),
        isTrue,
      );
    });

    test('does not match unrelated errors', () {
      expect(
        LMStudioService.isContextOverflowError(
          'Model returned empty response. Try disabling tools.',
        ),
        isFalse,
      );
      expect(
        LMStudioService.isContextOverflowError({
          'type': 'mcp_connection_error',
          'message': 'remote MCP server failed',
        }),
        isFalse,
      );
    });
  });

  group('contextOverflowUserMessage', () {
    test('includes token counts from the engine payload', () {
      final msg = LMStudioService.contextOverflowUserMessage(_lmStudio500Body);
      expect(msg.toLowerCase(), contains('context ran out'));
      expect(msg, contains('608'));
      expect(msg, contains('512'));
      expect(msg.toLowerCase(), isNot(contains('empty response')));
    });

    test('includes token counts from the inner message', () {
      final msg =
          LMStudioService.contextOverflowUserMessage(_innerEngineMessage);
      expect(msg.toLowerCase(), contains('context ran out'));
      expect(msg, contains('608 tokens'));
      expect(msg, contains('512'));
    });

    test('includes loaded context when only n_ctx is known', () {
      final msg = LMStudioService.contextOverflowUserMessage({
        'n_ctx': 512,
        'error_type': LMStudioService.contextOverflowType,
      });
      expect(msg.toLowerCase(), contains('context ran out'));
      expect(msg, contains('512 tokens'));
      expect(msg.toLowerCase(), isNot(contains('empty response')));
    });

    test('mentions a large attached image', () {
      final msg = LMStudioService.contextOverflowUserMessage(
        {
          'n_ctx': 32768,
          'error_type': LMStudioService.contextOverflowType,
        },
        largeImageBytes: 3 * 1024 * 1024,
      );
      expect(msg.toLowerCase(), contains('context ran out'));
      expect(msg, contains('3.0 MB'));
      expect(msg.toLowerCase(), contains('attached image'));
    });
  });

  group('errorChunkFromV1Json', () {
    test('tags a bare exceed payload even after chat.start', () {
      final chunk = LMStudioService.errorChunkFromV1Json(
        {
          'type': 'exceed_context_size_error',
          'message': _innerEngineMessage,
          'n_prompt_tokens': 608,
          'n_ctx': 512,
        },
        eventType: 'chat.start',
      );
      expect(chunk, isNotNull);
      expect(chunk!['error_type'], LMStudioService.contextOverflowType);
      expect(chunk['error'], contains('608 tokens'));
    });

    test('unwraps LM Studio HTTP 500 wrapper', () {
      final chunk = LMStudioService.errorChunkFromV1Json(
        {
          'error': {
            'message':
                'Engine protocol predict request returned 400: {"error":{"code":400,"message":"$_innerEngineMessage","type":"exceed_context_size_error","n_prompt_tokens":608,"n_ctx":512}}',
            'type': 'internal_error',
            'code': 'unknown',
          },
        },
      );
      expect(chunk, isNotNull);
      expect(chunk!['error_type'], LMStudioService.contextOverflowType);
    });
  });

  group('streamClosedAfterChatStartChunk', () {
    test('is not classified as exceed_context_size_error', () {
      final chunk =
          LMStudioService.streamClosedAfterChatStartChunk(contextTokens: 512);
      expect(LMStudioService.isStreamClosedAfterStart(chunk), isTrue);
      expect(LMStudioService.isContextOverflowError(chunk), isFalse);
      expect(chunk['error_type'], LMStudioService.streamClosedAfterStartType);
    });

    test('user message says context ran out', () {
      final msg = LMStudioService.streamClosedAfterStartUserMessage(
        contextTokens: 32768,
      );
      expect(msg.toLowerCase(), contains('context ran out'));
      expect(msg, contains('32768 tokens'));
      expect(msg.toLowerCase(), isNot(contains('without a response')));
      expect(msg, isNot(contains('608')));
    });

    test('user message blames a large attached image', () {
      final msg = LMStudioService.streamClosedAfterStartUserMessage(
        contextTokens: 32768,
        largeImageBytes: 1800 * 1024,
      );
      expect(msg.toLowerCase(), contains('context ran out'));
      expect(msg.toLowerCase(), contains('attached image'));
      expect(msg, contains('1.8 MB'));
    });
  });

  group('isIngestOnlyStream', () {
    test('matches chat.start then prompt_processing', () {
      expect(
        LMStudioService.isIngestOnlyStream([
          'chat.start',
          'prompt_processing.start',
          'prompt_processing.progress',
        ]),
        isTrue,
      );
    });

    test('does not match a stream that produced output', () {
      expect(
        LMStudioService.isIngestOnlyStream([
          'chat.start',
          'prompt_processing.end',
          'message.delta',
        ]),
        isFalse,
      );
    });
  });

  group('error type isolation', () {
    test('does not treat MCP errors as context overflow', () {
      expect(
        LMStudioService.isContextOverflowError({
          'error': 'remote MCP server failed',
          'error_type': 'mcp_connection_error',
        }),
        isFalse,
      );
      expect(
        LMStudioService.isStreamClosedAfterStart({
          'error': 'remote MCP server failed',
          'error_type': 'mcp_connection_error',
        }),
        isFalse,
      );
    });
  });
}
