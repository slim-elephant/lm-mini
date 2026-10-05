import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/services/live_activity_service.dart';

void main() {
  test('image Live Activity copy stays indeterminate until sampler progress',
      () {
    expect(imageGenerationLiveActivityStatusText(0), 'Generating image...');
    expect(imageGenerationLiveActivityStatusText(0.04), 'Generating image...');
    expect(
        imageGenerationLiveActivityStatusText(0.45), 'Generating image · 45%');
    expect(imageGenerationLiveActivityStatusText(1), 'Generating image · 100%');
  });

  test('image Live Activity title prefers the selected checkpoint', () {
    expect(
      imageGenerationLiveActivityModelName(
        AppSettings(imageGenProvider: 'comfyui'),
      ),
      'ComfyUI',
    );
    expect(
      imageGenerationLiveActivityModelName(
        AppSettings(
          imageGenProvider: 'comfyui',
          imageGenSelectedModel: 'z_image_turbo_bf16.safetensors',
        ),
      ),
      'z_image_turbo_bf16.safetensors',
    );
    expect(
      imageGenerationLiveActivityModelName(
        AppSettings(imageGenProvider: 'onDevice'),
      ),
      'On-device image',
    );
  });

  test('Live Activity is recreated after foreground dismiss if a job is held',
      () {
    expect(
      liveActivityShouldReassert(holdCount: 1, currentlyShowing: false),
      isTrue,
    );
    expect(
      liveActivityShouldReassert(holdCount: 1, currentlyShowing: true),
      isFalse,
    );
    expect(
      liveActivityShouldReassert(holdCount: 0, currentlyShowing: false),
      isFalse,
    );
  });
}
