/// Image generation never started, or A1111 answered with the wrong payload.
///
/// Setup help, not a Mini crash. Do not Send to support.
enum ImageGenUnreachableKind { down, noUrl, wrongServer, noImage }

class ImageGenUnreachableError implements Exception {
  final String providerLabel;
  final String url;
  final String? detail;
  final ImageGenUnreachableKind kind;

  const ImageGenUnreachableError({
    required this.providerLabel,
    required this.url,
    this.detail,
    this.kind = ImageGenUnreachableKind.down,
  });

  static const noUrlUserMessage =
      'No image generation server is set. Add ComfyUI or AUTOMATIC1111 in '
      'Image Generation settings.';

  static const wrongServerUserMessage =
      'Image Generation is pointed at a server that is not AUTOMATIC1111. '
      'Open Image Generation settings and set the A1111 address, or switch '
      'to ComfyUI — not LM Studio.';

  static const noImageUserMessage =
      'AUTOMATIC1111 returned no image. Load a checkpoint in A1111, then try '
      'again from Image Generation settings.';

  String get userMessage {
    switch (kind) {
      case ImageGenUnreachableKind.noUrl:
        return noUrlUserMessage;
      case ImageGenUnreachableKind.wrongServer:
        return wrongServerUserMessage;
      case ImageGenUnreachableKind.noImage:
        return noImageUserMessage;
      case ImageGenUnreachableKind.down:
        final host = url.trim();
        if (host.isEmpty) return noUrlUserMessage;
        return "Can't reach $providerLabel at $host. Start it on your computer "
            'and stay on the same Wi‑Fi.';
    }
  }

  @override
  String toString() {
    final extra = detail?.trim();
    if (extra == null || extra.isEmpty) return userMessage;
    return '$userMessage\n$extra';
  }

  static final _reach = RegExp(
    r"can't reach (.+?) at (\S+)",
    caseSensitive: false,
  );

  static bool matches(Object? error) {
    if (error is ImageGenUnreachableError) return true;
    final s = (error?.toString() ?? '').toLowerCase();
    if (s.isEmpty) return false;
    return s.contains("can't reach comfyui") ||
        s.contains("can't reach automatic1111") ||
        s.contains("can't reach a1111") ||
        s.contains('no image generation server is set') ||
        s.contains('ensure comfyui is running') ||
        s.contains('ensure a1111 is running') ||
        s.contains('is not automatic1111') ||
        s.contains('returned no image') ||
        s.contains('did not return an image');
  }

  static ImageGenUnreachableError? parse(Object? error) {
    if (error is ImageGenUnreachableError) return error;
    if (!matches(error)) return null;
    final s = error?.toString() ?? '';
    final lower = s.toLowerCase();
    if (lower.contains('no image generation server is set')) {
      return const ImageGenUnreachableError(
        providerLabel: 'ComfyUI',
        url: '',
        kind: ImageGenUnreachableKind.noUrl,
      );
    }
    if (lower.contains('is not automatic1111')) {
      return const ImageGenUnreachableError(
        providerLabel: 'AUTOMATIC1111',
        url: '',
        kind: ImageGenUnreachableKind.wrongServer,
      );
    }
    if (lower.contains('returned no image') ||
        lower.contains('did not return an image')) {
      return const ImageGenUnreachableError(
        providerLabel: 'AUTOMATIC1111',
        url: '',
        kind: ImageGenUnreachableKind.noImage,
      );
    }
    final m = _reach.firstMatch(s);
    if (m != null) {
      var parsedUrl = m.group(2)!.trim();
      if (parsedUrl.endsWith('.') && !parsedUrl.endsWith('..')) {
        parsedUrl = parsedUrl.substring(0, parsedUrl.length - 1);
      }
      return ImageGenUnreachableError(
        providerLabel: m.group(1)!.trim(),
        url: parsedUrl,
      );
    }
    return const ImageGenUnreachableError(providerLabel: 'ComfyUI', url: '');
  }
}
