import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/chat_message.dart';

void main() {
  test('copyWith attaches generated image paths without dropping content', () {
    final original = ChatMessage(
      id: 'msg-1',
      content: 'A sunset over water',
      role: 'assistant',
      timestamp: DateTime.utc(2026, 9, 14),
      imagePrompt: 'sunset, ocean, cinematic',
    );

    final updated = original.copyWith(
      generatedImagePath: '/docs/generated_images/a.png',
      generatedImagePaths: const ['/docs/generated_images/a.png'],
      generatedImageInfo: '{"provider":"comfyui"}',
    );

    expect(updated.id, original.id);
    expect(updated.content, original.content);
    expect(updated.imagePrompt, original.imagePrompt);
    expect(updated.hasGeneratedImages, isTrue);
    expect(updated.allGeneratedImagePaths, ['/docs/generated_images/a.png']);
  });
}
