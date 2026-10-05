import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/image_gen_unreachable_error.dart';

void main() {
  group('ImageGenUnreachableError', () {
    test('matches friendly ComfyUI copy', () {
      const err = ImageGenUnreachableError(
        providerLabel: 'ComfyUI',
        url: 'http://192.168.1.10:8188',
      );
      expect(ImageGenUnreachableError.matches(err), isTrue);
      expect(ImageGenUnreachableError.matches(err.userMessage), isTrue);
      expect(err.userMessage, contains('192.168.1.10:8188'));
    });

    test('parses URL out of the user message', () {
      const err = ImageGenUnreachableError(
        providerLabel: 'AUTOMATIC1111',
        url: 'http://192.168.1.20:7860',
      );
      final parsed = ImageGenUnreachableError.parse(err.toString());
      expect(parsed, isNotNull);
      expect(parsed!.providerLabel, 'AUTOMATIC1111');
      expect(parsed.url, 'http://192.168.1.20:7860');
    });

    test('does not match unrelated chat errors', () {
      expect(
        ImageGenUnreachableError.matches('Cannot connect to LM Studio'),
        isFalse,
      );
    });

    test('matches a non-A1111 options body', () {
      expect(
        ImageGenUnreachableError.matches(
          ImageGenUnreachableError.wrongServerUserMessage,
        ),
        isTrue,
      );
      expect(
        ImageGenUnreachableError.parse(
          ImageGenUnreachableError.wrongServerUserMessage,
        )?.kind,
        ImageGenUnreachableKind.wrongServer,
      );
    });

    test('matches a txt2img response with no images', () {
      expect(
        ImageGenUnreachableError.matches(
          ImageGenUnreachableError.noImageUserMessage,
        ),
        isTrue,
      );
    });
  });
}
