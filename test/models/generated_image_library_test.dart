import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/models/generated_image_library_item.dart';
import 'package:lm_mini/utils/generated_image_info.dart';

void main() {
  test('parseGeneratedImageInfo reads ComfyUI fields', () {
    const raw = '''
{
  "provider": "comfyui",
  "prompt": "a red bicycle",
  "negative_prompt": "blur",
  "seed": 42,
  "steps": 8,
  "cfg_scale": 1,
  "width": 1024,
  "height": 1024,
  "checkpoint": "z_image_turbo.safetensors",
  "lora_name": "style.safetensors",
  "lora_weight": 0.8,
  "sampler_name": "res_multistep",
  "scheduler": "simple",
  "workflow_path": "built-in/z-image.json"
}''';
    final info = parseGeneratedImageInfo(raw);
    expect(info.isComfyUi, isTrue);
    expect(info.providerLabel, 'ComfyUI');
    expect(info.prompt, 'a red bicycle');
    expect(info.checkpoint, 'z_image_turbo.safetensors');
    expect(info.loraLabel, 'style.safetensors @ 0.8');
    expect(info.sizeLabel, '1024×1024');
    expect(isComfyGeneratedImageInfo(raw), isTrue);
  });

  test('parseGeneratedImageInfo reads AUTOMATIC1111 and on-device', () {
    final a1111 = parseGeneratedImageInfo(
      '{"sd_model_name":"sdxl.safetensors","seed":9,"prompt":"cat"}',
    );
    expect(a1111.isAutomatic1111, isTrue);
    expect(a1111.checkpoint, 'sdxl.safetensors');

    final device = parseGeneratedImageInfo('{"seed":3,"on_device":true}');
    expect(device.isOnDevice, isTrue);
    expect(device.seed, '3');
  });

  test('library flatten includes swipe alternatives', () {
    final alt = ChatMessage(
      id: 'alt-1',
      content: 'older',
      role: 'assistant',
      timestamp: DateTime.utc(2026, 9, 1),
      generatedImagePaths: const ['/docs/generated_images/old.png'],
      imagePrompt: 'older prompt',
    );
    final msg = ChatMessage(
      id: 'msg-1',
      content: 'newer',
      role: 'assistant',
      timestamp: DateTime.utc(2026, 9, 20),
      generatedImagePaths: const ['/docs/generated_images/new.png'],
      imagePrompt: 'newer prompt',
      generatedImageInfo: '{"provider":"comfyui"}',
      alternatives: [alt],
    );
    final items = libraryItemsFromMessage(
      message: msg,
      conversationId: 'c1',
      conversationTitle: 'Bike chat',
    );
    expect(items.map((i) => i.fileName).toList(), ['new.png', 'old.png']);
    expect(items.first.conversationTitle, 'Bike chat');
    expect(items.first.parsed.isComfyUi, isTrue);
  });

  test('messagesHaveGeneratedImages looks at swipe alternatives', () {
    expect(
      messagesHaveGeneratedImages([
        ChatMessage(
          id: 'plain',
          content: 'hi',
          role: 'assistant',
          timestamp: DateTime.utc(2026, 9, 20),
        ),
      ]),
      isFalse,
    );
    expect(
      messagesHaveGeneratedImages([
        ChatMessage(
          id: 'msg',
          content: 'hi',
          role: 'assistant',
          timestamp: DateTime.utc(2026, 9, 20),
          alternatives: [
            ChatMessage(
              id: 'alt',
              content: 'older',
              role: 'assistant',
              timestamp: DateTime.utc(2026, 9, 19),
              generatedImagePaths: const ['/docs/generated_images/old.png'],
            ),
          ],
        ),
      ]),
      isTrue,
    );
  });

  test('stripGeneratedImageFiles clears matching files and alternatives', () {
    final msg = ChatMessage(
      id: 'msg-1',
      content: 'keep me',
      role: 'assistant',
      timestamp: DateTime.utc(2026, 9, 20),
      generatedImagePaths: const [
        '/docs/generated_images/a.png',
        '/docs/generated_images/b.png',
      ],
      generatedImageInfo: '{"provider":"comfyui"}',
      alternatives: [
        ChatMessage(
          id: 'alt',
          content: 'alt',
          role: 'assistant',
          timestamp: DateTime.utc(2026, 9, 19),
          generatedImagePaths: const ['/elsewhere/a.png'],
        ),
      ],
    );
    final stripped = stripGeneratedImageFiles(msg, {'a.png'});
    expect(stripped, isNotNull);
    expect(stripped!.content, 'keep me');
    expect(stripped.allGeneratedImagePaths, ['/docs/generated_images/b.png']);
    expect(stripped.generatedImageInfo, isNotNull);
    expect(stripped.alternatives!.first.hasGeneratedImages, isFalse);
  });
}
