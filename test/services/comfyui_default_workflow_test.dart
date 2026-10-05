import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/comfyui_service.dart';
import 'package:lm_mini/utils/comfyui_catalog.dart';

void main() {
  test('built-in workflow is a CheckpointLoaderSimple SD graph', () {
    expect(kDefaultComfyUiWorkflow, contains('CheckpointLoaderSimple'));
    expect(kDefaultComfyUiWorkflow, contains('%CHECKPOINT%'));
    expect(kDefaultComfyUiWorkflow, isNot(contains('UNETLoader')));
    expect(isComfyDefaultWorkflowJson(kDefaultComfyUiWorkflow), isTrue);
    expect(isComfyDefaultWorkflowJson('  $kDefaultComfyUiWorkflow  '), isTrue);
    expect(isComfyDefaultWorkflowJson('{"3":{}}'), isFalse);
  });

  test('Z-Image Turbo built-in is a UNET + Qwen CLIP graph', () {
    expect(kZImageTurboComfyUiWorkflow, contains('UNETLoader'));
    expect(kZImageTurboComfyUiWorkflow, contains('qwen_3_4b.safetensors'));
    expect(kZImageTurboComfyUiWorkflow, contains('EmptySD3LatentImage'));
    expect(kZImageTurboComfyUiWorkflow, contains('%WIDTH%'));
    expect(kZImageTurboComfyUiWorkflow, contains('%SEED%'));
    expect(kZImageTurboComfyUiWorkflow, contains('%CHECKPOINT%'));
    expect(isComfyDefaultWorkflowJson(kZImageTurboComfyUiWorkflow), isTrue);
    expect(
        isComfyZImageTurboWorkflowPath(kComfyZImageTurboWorkflowPath), isTrue);
  });
}
