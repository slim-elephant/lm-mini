import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/comfyui_catalog.dart';

void main() {
  test('skips SD config YAML — those are not models', () {
    expect(isComfyWeightFilename('v1-inference.yaml'), isFalse);
    expect(isComfyWeightFilename('anything_v3.yaml'), isFalse);
    expect(isComfyWeightFilename('configs/v1-inference_fp16.yml'), isFalse);
    expect(isComfyWeightFilename('z_image_turbo_bf16.safetensors'), isTrue);
    expect(isComfyWeightFilename('models/checkpoints/model.ckpt'), isTrue);
    expect(isComfyWeightFilename('qwen_3_4b.safetensors'), isTrue);
  });

  test('parses model folder lists and maps', () {
    expect(
      parseComfyModelFolderResponse(['z_image_turbo_bf16.safetensors']),
      ['z_image_turbo_bf16.safetensors'],
    );
    expect(
      parseComfyModelFolderResponse({
        'models': [
          {'name': 'a.safetensors'},
        ],
      }),
      ['a.safetensors'],
    );
  });

  test('reads UNET combo options from object_info', () {
    final info = {
      'UNETLoader': {
        'input': {
          'required': {
            'unet_name': [
              ['z_image_turbo_bf16.safetensors'],
              {},
            ],
          },
        },
      },
    };
    expect(
      extractComfyInputEnum(info['UNETLoader'], 'unet_name'),
      ['z_image_turbo_bf16.safetensors'],
    );
    expect(
      scanComfyObjectInfoForInput(info, 'unet_name'),
      ['z_image_turbo_bf16.safetensors'],
    );
  });

  test('extracts the API graph from /history', () {
    const history = {
      'abc': {
        'prompt': [
          3,
          'abc',
          {
            '1': {
              'class_type': 'UNETLoader',
              'inputs': {'unet_name': 'z_image_turbo_bf16.safetensors'},
            },
          },
          {},
          ['9'],
        ],
      },
    };
    final graphs = parseComfyHistory(history);
    expect(graphs, hasLength(1));
    expect(graphs.first.loaderLabel, 'z_image_turbo_bf16.safetensors');
    expect(isComfyLastRunWorkflowPath(kComfyLastRunWorkflowPath), isTrue);
  });

  test('detects interrupted Comfy history entries', () {
    expect(
      comfyHistoryWasInterrupted({
        'status': {
          'status_str': 'error',
          'completed': false,
          'messages': [
            ['execution_start', {}],
            [
              'execution_interrupted',
              {'prompt_id': 'abc'}
            ],
          ],
        },
      }),
      isTrue,
    );
    expect(comfyHistoryWasInterrupted({'outputs': {}}), isFalse);
  });

  test('converts a Z-Image canvas save into an API graph', () {
    const ui = {
      'nodes': [
        {
          'id': 66,
          'type': 'UNETLoader',
          'inputs': [],
          'widgets_values': ['z_image_turbo_bf16.safetensors', 'default'],
        },
        {
          'id': 62,
          'type': 'CLIPLoader',
          'inputs': [],
          'widgets_values': ['qwen_3_4b.safetensors', 'lumina2', 'default'],
        },
        {
          'id': 68,
          'type': 'EmptySD3LatentImage',
          'inputs': [],
          'widgets_values': [1024, 768, 1],
        },
        {
          'id': 70,
          'type': 'KSampler',
          'inputs': [
            {'name': 'latent_image', 'link': 1},
          ],
          'widgets_values': [42, 'fixed', 8, 1, 'res_multistep', 'simple', 1],
        },
      ],
      'links': [
        [1, 68, 0, 70, 3, 'LATENT'],
      ],
    };
    final graph = convertComfyUiWorkflowToApi(ui);
    expect(graph, isNotNull);
    expect(graph!['66']['class_type'], 'UNETLoader');
    expect(
        graph['66']['inputs']['unet_name'], 'z_image_turbo_bf16.safetensors');
    expect(graph['62']['inputs']['clip_name'], 'qwen_3_4b.safetensors');
    expect(graph['62']['inputs']['type'], 'lumina2');
    expect(graph['68']['inputs']['width'], 1024);
    expect(graph['68']['inputs']['height'], 768);
    expect(graph['70']['inputs']['seed'], 42);
    expect(graph['70']['inputs']['sampler_name'], 'res_multistep');
    expect(graph['70']['inputs']['latent_image'], ['68', 0]);
    expect(
        graph['70']['inputs'].containsKey('control_after_generate'), isFalse);
  });

  test('does not slide cfg onto a linked seed widget', () {
    const ui = {
      'nodes': [
        {
          'id': 70,
          'type': 'KSampler',
          'inputs': [
            {'name': 'seed', 'link': 5},
            {'name': 'steps', 'link': 6},
          ],
          'widgets_values': [
            0,
            'randomize',
            8,
            1,
            'res_multistep',
            'simple',
            1
          ],
        },
      ],
      'links': [
        [5, 1, 0, 70, 4, 'INT'],
        [6, 1, 0, 70, 5, 'INT'],
      ],
    };
    final graph = convertComfyUiWorkflowToApi(ui);
    expect(graph!['70']['inputs']['seed'], ['1', 0]);
    expect(graph['70']['inputs']['steps'], ['1', 0]);
    expect(graph['70']['inputs']['cfg'], 1);
    expect(graph['70']['inputs']['sampler_name'], 'res_multistep');
    expect(graph['70']['inputs']['scheduler'], 'simple');
  });

  test('keeps the positive prompt when negative is ConditioningZeroOut', () {
    final graph = <String, dynamic>{
      '27': {
        'class_type': 'CLIPTextEncode',
        'inputs': <String, dynamic>{
          'text': ['-10', 0],
          'clip': ['30', 0],
        },
      },
      '33': {
        'class_type': 'ConditioningZeroOut',
        'inputs': <String, dynamic>{
          'conditioning': ['27', 0],
        },
      },
      '3': {
        'class_type': 'KSampler',
        'inputs': <String, dynamic>{
          'positive': ['27', 0],
          'negative': ['33', 0],
        },
      },
    };

    applyComfyConditioningPrompts(
      graph,
      positiveNodeId: comfyLinkNodeId(graph['3']['inputs']['positive']),
      negativeNodeId: comfyLinkNodeId(graph['3']['inputs']['negative']),
      positivePrompt: 'a red bicycle on a beach',
      negativePrompt: '',
    );

    expect(graph['27']['inputs']['text'], 'a red bicycle on a beach');
  });

  test('still writes a separate negative text encoder', () {
    final graph = <String, dynamic>{
      '67': {
        'class_type': 'CLIPTextEncode',
        'inputs': {'text': 'old positive'},
      },
      '71': {
        'class_type': 'CLIPTextEncode',
        'inputs': {'text': 'old negative'},
      },
    };

    applyComfyConditioningPrompts(
      graph,
      positiveNodeId: '67',
      negativeNodeId: '71',
      positivePrompt: 'a ceramic cup',
      negativePrompt: '',
    );

    expect(graph['67']['inputs']['text'], 'a ceramic cup');
    expect(graph['71']['inputs']['text'], '');
  });

  test('inlines a Z-Image subgraph and does not blank the prompt', () {
    final ui = {
      'nodes': [
        {
          'id': 35,
          'type': 'MarkdownNote',
          'widgets_values': ['ignore'],
        },
        {
          'id': 9,
          'type': 'SaveImage',
          'inputs': [
            {'name': 'images', 'link': 62},
          ],
          'widgets_values': ['z-image-turbo'],
        },
        {
          'id': 57,
          'type': 'sg-z-image',
          'inputs': [
            {'name': 'text', 'type': 'STRING', 'link': null},
          ],
          'widgets_values': ['a teapot'],
        },
      ],
      'links': [
        [62, 57, 0, 9, 0, 'IMAGE'],
      ],
      'definitions': {
        'subgraphs': [
          {
            'id': 'sg-z-image',
            'inputs': [
              {'name': 'text', 'type': 'STRING'},
            ],
            'outputs': [
              {'name': 'IMAGE', 'type': 'IMAGE'},
            ],
            'nodes': [
              {
                'id': 27,
                'type': 'CLIPTextEncode',
                'inputs': [
                  {'name': 'clip', 'type': 'CLIP', 'link': 28},
                  {'name': 'text', 'type': 'STRING', 'link': 34},
                ],
                'widgets_values': ['baked prompt'],
              },
              {
                'id': 33,
                'type': 'ConditioningZeroOut',
                'inputs': [
                  {'name': 'conditioning', 'link': 32},
                ],
              },
              {
                'id': 30,
                'type': 'CLIPLoader',
                'inputs': [],
                'widgets_values': [
                  'qwen_3_4b.safetensors',
                  'lumina2',
                  'default',
                ],
              },
              {
                'id': 8,
                'type': 'VAEDecode',
                'inputs': [
                  {'name': 'samples', 'link': 14},
                ],
              },
              {
                'id': 3,
                'type': 'KSampler',
                'inputs': [
                  {'name': 'positive', 'link': 30},
                  {'name': 'negative', 'link': 33},
                  {'name': 'seed', 'link': 71},
                ],
                'widgets_values': [
                  0,
                  'randomize',
                  8,
                  1,
                  'res_multistep',
                  'simple',
                  1,
                ],
              },
            ],
            'links': [
              {
                'id': 28,
                'origin_id': 30,
                'origin_slot': 0,
                'target_id': 27,
                'target_slot': 0,
                'type': 'CLIP',
              },
              {
                'id': 32,
                'origin_id': 27,
                'origin_slot': 0,
                'target_id': 33,
                'target_slot': 0,
                'type': 'CONDITIONING',
              },
              {
                'id': 30,
                'origin_id': 27,
                'origin_slot': 0,
                'target_id': 3,
                'target_slot': 1,
                'type': 'CONDITIONING',
              },
              {
                'id': 33,
                'origin_id': 33,
                'origin_slot': 0,
                'target_id': 3,
                'target_slot': 2,
                'type': 'CONDITIONING',
              },
              {
                'id': 14,
                'origin_id': 3,
                'origin_slot': 0,
                'target_id': 8,
                'target_slot': 0,
                'type': 'LATENT',
              },
              {
                'id': 16,
                'origin_id': 8,
                'origin_slot': 0,
                'target_id': -20,
                'target_slot': 0,
                'type': 'IMAGE',
              },
              {
                'id': 34,
                'origin_id': -10,
                'origin_slot': 0,
                'target_id': 27,
                'target_slot': 1,
                'type': 'STRING',
              },
              {
                'id': 71,
                'origin_id': -10,
                'origin_slot': 3,
                'target_id': 3,
                'target_slot': 4,
                'type': 'INT',
              },
            ],
          },
        ],
      },
    };

    final graph = convertComfyUiWorkflowToApi(ui);
    expect(graph, isNotNull);
    expect(graph!.containsKey('35'), isFalse);
    expect(graph.containsKey('57'), isFalse);
    expect(graph['57_27']['inputs']['text'], 'a teapot');
    expect(graph['57_27']['inputs']['clip'], ['57_30', 0]);
    expect(graph['57_30']['inputs']['type'], 'lumina2');
    expect(graph['57_3']['inputs']['cfg'], 1);
    expect(graph['57_3']['inputs']['sampler_name'], 'res_multistep');
    expect(graph['57_3']['inputs']['positive'], ['57_27', 0]);
    expect(graph['57_3']['inputs']['negative'], ['57_33', 0]);
    expect(graph['9']['inputs']['images'], ['57_8', 0]);

    applyComfyConditioningPrompts(
      graph,
      positiveNodeId: comfyLinkNodeId(graph['57_3']['inputs']['positive']),
      negativeNodeId: comfyLinkNodeId(graph['57_3']['inputs']['negative']),
      positivePrompt: 'a ceramic cup of tea',
      negativePrompt: '',
    );
    expect(graph['57_27']['inputs']['text'], 'a ceramic cup of tea');
  });

  test('official Z-Image template encodes the user prompt', () {
    final raw = jsonDecode(
      File('test/fixtures/image_z_image_turbo.json').readAsStringSync(),
    );
    final graph = convertComfyUiWorkflowToApi(raw);
    expect(graph, isNotNull);

    String? samplerId;
    for (final entry in graph!.entries) {
      final node = entry.value;
      if (node is Map && node['class_type'] == 'KSampler') {
        samplerId = entry.key;
      }
      expect(node['class_type'], isNot(startsWith('f2fdebf6')));
    }
    expect(samplerId, isNotNull);
    final sampler = graph[samplerId]!['inputs'] as Map;
    expect(sampler['cfg'], 1);
    expect(sampler['sampler_name'], 'res_multistep');

    final positiveId = comfyLinkNodeId(sampler['positive']);
    final negativeId = comfyLinkNodeId(sampler['negative']);
    applyComfyConditioningPrompts(
      graph,
      positiveNodeId: positiveId,
      negativeNodeId: negativeId,
      positivePrompt: 'a red bicycle on a beach',
      negativePrompt: '',
    );

    final text = graph[positiveId]!['inputs']['text'];
    expect(text, 'a red bicycle on a beach');
    expect(
      graph.values.any(
        (node) =>
            node is Map &&
            node['class_type'] == 'CLIPLoader' &&
            node['inputs']['type'] == 'lumina2',
      ),
      isTrue,
    );
  });

  test('writes steps onto a sampler and keeps a linked width', () {
    final graph = <String, dynamic>{
      '3': {
        'class_type': 'KSampler',
        'inputs': <String, dynamic>{
          'steps': ['9', 0],
          'cfg': 1.0,
          'sampler_name': 'exp_heun_2_x0_sde',
          'scheduler': 'simple',
          'width': ['2', 0],
          'height': ['2', 1],
        },
      },
    };

    applyComfyGenerationControls(
      graph,
      steps: 30,
      cfg: 1,
      samplerName: 'exp_heun_2_x0_sde',
      schedulerName: 'simple',
      width: 512,
      height: 512,
    );

    expect(graph['3']['inputs']['steps'], 30);
    expect(graph['3']['inputs']['sampler_name'], 'exp_heun_2_x0_sde');
    expect(graph['3']['inputs']['width'], ['2', 0]);
    expect(graph['3']['inputs']['height'], ['2', 1]);
  });

  test('reads sampler, scheduler, and other widgets from a workflow', () {
    final controls = extractComfyWorkflowControls({
      '1': {
        'class_type': 'QwenImage',
        'inputs': {
          'cfg': 1.0,
          'steps': 25,
          'sampler': 'exp_heun_2_x0_sde',
          'scheduler': 'simple',
          'seed': 7654693,
          'unet_name': 'qwen-image-2.1-UC-Q8_0.gguf',
          'clip_name': 'qwen3vl_8b.safetensors',
          'vae_name': 'qwen_image_vae.safetensors',
        },
      },
      '2': {
        'class_type': 'ResolutionSelector',
        'inputs': {
          'aspect_ratio': '1:1 (Square)',
          'megapixels': 1.0,
          'multiple': 8,
        },
      },
    });

    expect(controls.steps, 25);
    expect(controls.cfg, 1);
    expect(controls.sampler, 'exp_heun_2_x0_sde');
    expect(controls.scheduler, 'simple');
    expect(controls.seed, 7654693);
    expect(controls.modelName, 'qwen-image-2.1-UC-Q8_0.gguf');
    expect(
      controls.fields.map((field) => field.name),
      containsAll([
        'clip_name',
        'vae_name',
        'aspect_ratio',
        'megapixels',
        'multiple',
      ]),
    );
  });

  test('writes extra workflow fields and leaves wires alone', () {
    final graph = <String, dynamic>{
      '30': {
        'class_type': 'CLIPLoader',
        'inputs': <String, dynamic>{
          'clip_name': 'old.safetensors',
          'type': 'lumina2',
        },
      },
    };

    applyComfyWorkflowFields(graph, [
      {
        'nodeId': '30',
        'name': 'clip_name',
        'value': 'qwen3vl.safetensors',
      },
      {
        'nodeId': '30',
        'name': 'type',
        'value': ['1', 0],
      },
    ]);

    expect(graph['30']['inputs']['clip_name'], 'qwen3vl.safetensors');
    expect(graph['30']['inputs']['type'], 'lumina2');
  });

  test('reads sampler progress from Comfy /ws events', () {
    expect(
      parseComfyProgressEvent({
        'type': 'progress',
        'data': {'value': 3, 'max': 8, 'prompt_id': 'abc'},
      }, promptId: 'abc')
          ?.samplerFraction,
      0.375,
    );
    expect(
      parseComfyProgressEvent({
        'type': 'progress',
        'data': {'value': 1, 'max': 1, 'node': 'clip'},
      }),
      isNull,
    );
    expect(
      parseComfyProgressEvent({
        'type': 'progress',
        'data': {'value': 4, 'max': 8, 'prompt_id': 'other'},
      }, promptId: 'abc'),
      isNull,
    );

    final state = parseComfyProgressEvent({
      'type': 'progress_state',
      'data': {
        'prompt_id': 'abc',
        'nodes': {
          'clip': {'value': 1, 'max': 1},
          'sampler': {'value': 2, 'max': 8},
        },
      },
    }, promptId: 'abc');
    expect(state?.samplerFraction, 0.25);
    expect(state?.finished, isFalse);

    expect(
      parseComfyProgressEvent({
        'type': 'executing',
        'data': {'node': null, 'prompt_id': 'abc'},
      }, promptId: 'abc')
          ?.finished,
      isTrue,
    );
    expect(
      parseComfyProgressEvent({
        'type': 'executing',
        'data': {'node': '3', 'prompt_id': 'abc'},
      }, promptId: 'abc'),
      isNull,
    );
    expect(comfyDisplayProgressFromSampler(0), closeTo(0.06, 0.0001));
    expect(comfyDisplayProgressFromSampler(1), closeTo(0.90, 0.0001));
  });

  test('named workflow path reuses the same file stem', () {
    expect(
      comfyNamedWorkflowPath('Qwen Image', const []),
      'workflows/Qwen Image.json',
    );
    expect(
      comfyNamedWorkflowPath(
        'qwen image.json',
        const ['user/default/workflows/Qwen Image.json'],
      ),
      'user/default/workflows/Qwen Image.json',
    );
    expect(
      comfyNamedWorkflowPath('a/b:c', const []),
      'workflows/a b c.json',
    );
    expect(
      comfyNamedWorkflowPath(
        'Mini built-in',
        const [kComfyZImageTurboWorkflowPath],
      ),
      'workflows/Mini built-in.json',
    );
    expect(comfyWorkflowDisplayName('Qwen Image.json'), 'Qwen Image');
  });

  test('a workflow file name is not the workflow graph', () {
    expect(comfyWorkflowNameOnly('"workflows/Qwen Image.json"'),
        'workflows/Qwen Image.json');
    expect(comfyWorkflowNameOnly('workflows/Qwen Image.json'),
        'workflows/Qwen Image.json');
    expect(comfyUsableWorkflowText('"workflows/Qwen Image.json"'), isNull);
    expect(
      comfyUsableWorkflowText(
        '{"3":{"class_type":"KSampler","inputs":{"seed":1}}}',
      ),
      contains('"class_type":"KSampler"'),
    );
    expect(
      comfyWorkflowNameOnly(
        '{"3":{"class_type":"KSampler","inputs":{"seed":1}}}',
      ),
      isNull,
    );
  });
}
