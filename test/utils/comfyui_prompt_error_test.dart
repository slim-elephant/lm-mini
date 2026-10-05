import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/comfyui_prompt_error.dart';

void main() {
  const emptyCkptDump = 'Exception: ComfyUI /prompt failed: HTTP 400 — '
      '{"error":{"type":"prompt_outputs_failed_validation",'
      '"message":"Prompt outputs failed validation","details":"","extra_info":{}},'
      '"node_errors":{"4":{"errors":[{"type":"value_not_in_list",'
      '"message":"Value not in list","details":"ckpt_name: \'\' not in []",'
      '"extra_info":{"input_name":"ckpt_name","input_config":[[]],'
      '"received_value":""}}],"dependent_outputs":["9"],'
      '"class_type":"CheckpointLoaderSimple"}}}';

  group('ComfyUiPromptError', () {
    test('empty ckpt_name and empty ComfyUI list is noCheckpoints', () {
      final parsed = ComfyUiPromptError.parse(emptyCkptDump);
      expect(parsed, isNotNull);
      expect(parsed!.kind, ComfyUiPromptErrorKind.noCheckpoints);
      expect(parsed.isCheckpointSetup, isTrue);
      expect(
        ComfyUiPromptError.userMessageFor(emptyCkptDump),
        ComfyUiPromptError.noCheckpointsUserMessage,
      );
    });

    test('empty ckpt_name with available models is noCheckpointSelected', () {
      const dump = 'ComfyUI /prompt failed: HTTP 400 — '
          '{"error":{"type":"prompt_outputs_failed_validation"},'
          '"node_errors":{"4":{"errors":[{"type":"value_not_in_list",'
          '"details":"ckpt_name: \'\' not in [\'a.safetensors\']",'
          '"extra_info":{"input_name":"ckpt_name",'
          '"input_config":[["a.safetensors"]],"received_value":""}}],'
          '"class_type":"CheckpointLoaderSimple"}}}';
      expect(
        ComfyUiPromptError.parse(dump)?.kind,
        ComfyUiPromptErrorKind.noCheckpointSelected,
      );
    });

    test('unknown checkpoint name', () {
      const dump = 'ComfyUI /prompt failed: HTTP 400 — '
          '{"error":{"type":"prompt_outputs_failed_validation"},'
          '"node_errors":{"4":{"errors":[{"type":"value_not_in_list",'
          '"details":"ckpt_name: \'missing.safetensors\' not in [\'a.safetensors\']",'
          '"extra_info":{"input_name":"ckpt_name",'
          '"input_config":[["a.safetensors"]],'
          '"received_value":"missing.safetensors"}}],'
          '"class_type":"CheckpointLoaderSimple"}}}';
      final parsed = ComfyUiPromptError.parse(dump);
      expect(parsed?.kind, ComfyUiPromptErrorKind.unknownCheckpoint);
      expect(parsed?.checkpointName, 'missing.safetensors');
      expect(
        parsed?.userMessage,
        contains('missing.safetensors'),
      );
    });

    test('other node validation is workflowRejected', () {
      const dump = 'ComfyUI /prompt failed: HTTP 400 — '
          '{"error":{"type":"prompt_outputs_failed_validation"},'
          '"node_errors":{"3":{"errors":[{"type":"value_not_in_list",'
          '"details":"sampler_name: \'foo\' not in [\'euler\']",'
          '"extra_info":{"input_name":"sampler_name","received_value":"foo"}}],'
          '"class_type":"KSampler"}}}';
      expect(
        ComfyUiPromptError.parse(dump)?.kind,
        ComfyUiPromptErrorKind.workflowRejected,
      );
    });

    test('matches rewritten user copy', () {
      expect(
        ComfyUiPromptError.matches(ComfyUiPromptError.noCheckpointsUserMessage),
        isTrue,
      );
      expect(
        ComfyUiPromptError.matches(
          ComfyUiPromptError.unknownCheckpointUserMessageFor('x.safetensors'),
        ),
        isTrue,
      );
    });

    test('diffusion-only UNET setups are not treated as empty checkpoints', () {
      expect(
        ComfyUiPromptError.parse(ComfyUiPromptError.diffusionOnlyUserMessage)
            ?.kind,
        ComfyUiPromptErrorKind.diffusionOnly,
      );
    });

    test('does not match unrelated errors', () {
      expect(
        ComfyUiPromptError.matches('Cannot connect to LM Studio'),
        isFalse,
      );
      expect(ComfyUiPromptError.matches(null), isFalse);
    });
  });
}
