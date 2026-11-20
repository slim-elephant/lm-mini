import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/desktop/host/desktop_relay_backends.dart';
import 'package:lm_mini/desktop/host/desktop_relay_client.dart';
import 'package:lm_mini/desktop/host/desktop_request_proxy.dart';

void main() {
  _comfyMiniRoutingTests();
  group('DesktopRequestProxy path helpers', () {
    test('rewriteSidecarPath maps LM Studio REST to OpenAI /v1/models', () {
      expect(
        DesktopRequestProxy.rewriteSidecarPath('/api/v0/models'),
        '/v1/models',
      );
      expect(
        DesktopRequestProxy.rewriteSidecarPath('/api/v1/models'),
        '/v1/models',
      );
      expect(
        DesktopRequestProxy.rewriteSidecarPath('/api/v1/models?foo=1'),
        '/v1/models?foo=1',
      );
      expect(
        DesktopRequestProxy.rewriteSidecarPath('/v1/chat/completions'),
        '/v1/chat/completions',
      );
    });

    test('pairing probes do not include per-model info paths', () {
      expect(DesktopRequestProxy.isPairingProbePath('/api/v0/models'), isTrue);
      expect(DesktopRequestProxy.isPairingProbePath('/api/v1/models'), isTrue);
      expect(DesktopRequestProxy.isPairingProbePath('/v1/models'), isTrue);
      expect(
          DesktopRequestProxy.isHostStatusPath('/lm-mini/host-status'), isTrue);
      expect(DesktopRequestProxy.isSyncPath('/lm-mini/sync'), isTrue);
      expect(DesktopRequestProxy.isPairingProbePath('/lm-mini/sync'), isFalse);
      expect(
        DesktopRequestProxy.isPairingProbePath('/api/v0/models/foo'),
        isFalse,
      );
    });

    test('openaiModelsToLmStudioV1 prefers data over ollama-style models', () {
      final v1 = DesktopRequestProxy.openaiModelsToLmStudioV1({
        'models': [
          {
            'name': 'qwen2.5-vl',
            'capabilities': ['completion', 'vision'],
          },
        ],
        'object': 'list',
        'data': [
          {'id': 'qwen2.5-vl', 'object': 'model', 'owned_by': 'llamacpp'},
        ],
      });
      final models = v1['models'] as List;
      expect(models, hasLength(1));
      expect((models.first as Map)['key'], 'qwen2.5-vl');
      expect((models.first as Map)['type'], 'vlm');
    });

    test('openaiModelsToLmStudioV1 maps llama-server list to V1 keys', () {
      final v1 = DesktopRequestProxy.openaiModelsToLmStudioV1({
        'object': 'list',
        'data': [
          {'id': 'qwen2.5-3b', 'object': 'model', 'owned_by': 'llamacpp'},
        ],
      });
      final models = v1['models'] as List;
      expect(models, hasLength(1));
      expect((models.first as Map)['key'], 'qwen2.5-3b');
    });

    test(
        'openaiModelsToLmStudioV1 uses /props vision when capabilities omit it',
        () {
      final v1 = DesktopRequestProxy.openaiModelsToLmStudioV1(
        {
          'object': 'list',
          'data': [
            {
              'id': 'Qwen3.6-27B.gguf',
              'object': 'model',
              'owned_by': 'llamacpp',
            },
          ],
        },
        visionFromProps: true,
      );
      final models = v1['models'] as List;
      expect((models.first as Map)['type'], 'vlm');
      expect((models.first as Map)['capabilities'], {'vision': true});
    });

    test('cold model list names the model the Mac is about to load', () {
      const path = '/Users/me/models/Qwen3.5-9B-Q4_K_M.gguf';
      final openai =
          DesktopRequestProxy.syntheticProbeBody('/v1/models', modelId: path);
      expect(((openai['data'] as List).single as Map)['id'], path);
      final v1 = DesktopRequestProxy.syntheticProbeBody('/api/v1/models',
          modelId: path);
      expect((v1['models'] as List), isNotEmpty);
    });

    test('synthetic probe bodies are 200-ok JSON the phone can accept', () {
      expect(
        DesktopRequestProxy.syntheticProbeBody('/api/v1/models')['models'],
        isEmpty,
      );
      expect(
        DesktopRequestProxy.syntheticProbeBody('/lm-mini/host-status')['ok'],
        isTrue,
      );
    });

    test('advertisedBackendNames follows share toggles', () {
      const backends = DesktopRelayBackends(
        advertiseBuiltin: true,
        advertiseLmStudio: false,
        advertiseOllama: true,
        advertiseOmlx: false,
        advertiseJan: true,
        advertiseUnsloth: false,
      );
      expect(
        DesktopRequestProxy.advertisedBackendNames(backends),
        ['lmMiniDesktop', 'ollama', 'jan'],
      );
    });

    test('pathOnlyOf strips a forwarded /s/{session} prefix', () {
      expect(
        DesktopRequestProxy.pathOnlyOf('/s/abc123/lm-mini/sync'),
        '/lm-mini/sync',
      );
      expect(
        DesktopRequestProxy.pathOnlyOf('/lm-mini/host-status'),
        '/lm-mini/host-status',
      );
      expect(DesktopRequestProxy.isSyncPath('/s/abc123/lm-mini/sync'), isTrue);
    });

    test('hostStatusPayload includes reachable backends', () {
      final payload = DesktopRequestProxy.hostStatusPayload(
        const DesktopRelayBackends(
          advertiseBuiltin: true,
          advertiseLmStudio: true,
          advertiseOllama: false,
          reachable: {
            'lmMiniDesktop': true,
            'lmStudio': true,
            'kokoro': false,
          },
        ),
      );
      expect(payload['ok'], isTrue);
      expect(payload['host'], 'lmMiniDesktop');
      final reachable = payload['reachable'] as Map;
      expect(reachable['lmMiniDesktop'], isTrue);
      expect(reachable['lmStudio'], isTrue);
      expect(payload['kokoroReady'], isFalse);
      expect(payload['platform'], isNotEmpty);
    });

    test('hostStatusPayload treats enabled Kokoro as ready on demand', () {
      final payload = DesktopRequestProxy.hostStatusPayload(
        const DesktopRelayBackends(
          advertiseBuiltin: true,
          kokoroEnabled: true,
          reachable: {'lmStudio': true},
        ),
      );
      expect(payload['kokoroReady'], isTrue);
      final reachable = payload['reachable'] as Map;
      expect(reachable['kokoro'], isTrue);
    });
    test('resolveTarget routes JAN and Unsloth headers', () {
      const backends = DesktopRelayBackends(
        advertiseJan: true,
        advertiseUnsloth: true,
        janPort: 1337,
        unslothPort: 8888,
        unslothApiToken: 'sk-unsloth-test',
      );
      final jan = DesktopRequestProxy.instance.resolveTarget(
        '/v1/models',
        {'X-LM-Mini-Backend': 'jan'},
        backends,
      );
      expect(jan?.kind, 'jan');
      expect(jan?.port, 1337);
      final unsloth = DesktopRequestProxy.instance.resolveTarget(
        '/v1/chat/completions',
        {'x-lm-mini-backend': 'unsloth'},
        backends,
      );
      expect(unsloth?.kind, 'unsloth');
      expect(unsloth?.port, 8888);
      expect(unsloth?.apiToken, 'sk-unsloth-test');
    });
  });
}

void _comfyMiniRoutingTests() {
  const image = DesktopRelayBackends(
    comfyUiHost: '127.0.0.1',
    comfyUiPort: 8188,
    a1111Host: '127.0.0.1',
    a1111Port: 7860,
    lmStudioApiToken: 'sk-lm-secret',
  );
  final proxy = DesktopRequestProxy.instance;

  group('Comfy Mini routing by X-LM-Mini-Backend', () {
    const comfyPaths = [
      '/free',
      '/experiment/models/checkpoints',
      '/experiment/models/preview/checkpoints/0/sd.safetensors',
      '/v2/manager/version',
      '/v2/customnode/getmappings?mode=cache',
      '/customnode/getmappings?mode=cache',
      '/v2/manager/queue/task',
      '/v2/manager/queue/install_model',
      '/v2/manager/queue/start',
      '/v2/manager/queue/history?ui_id=abc',
      '/v2/manager/queue/status',
      '/v2/manager/reboot',
      '/v2/externalmodel/getlist',
      '/externalmodel/getlist',
      '/api/v2/manager/version',
    ];

    test('header comfyui sends every path to ComfyUI, no bearer', () {
      for (final path in comfyPaths) {
        final t = proxy.resolveTarget(
          path,
          {'X-LM-Mini-Backend': 'comfyui'},
          image,
        );
        expect(t?.kind, 'comfyui', reason: path);
        expect(t?.port, 8188, reason: path);
        expect(t?.apiToken, '', reason: path);
      }
      // Both header casings, trimmed and case-insensitive value.
      expect(
        proxy
            .resolveTarget('/free', {'x-lm-mini-backend': ' ComfyUI '}, image)
            ?.kind,
        'comfyui',
      );
    });

    test('header a1111 sends ControlNet routes to A1111, no bearer', () {
      for (final path in [
        '/controlnet/control_types',
        '/controlnet/model_list',
        '/controlnet/module_list',
        '/sdapi/v1/txt2img',
      ]) {
        final t =
            proxy.resolveTarget(path, {'X-LM-Mini-Backend': 'a1111'}, image);
        expect(t?.kind, 'a1111', reason: path);
        expect(t?.port, 7860, reason: path);
        expect(t?.apiToken, '', reason: path);
      }
    });

    test('header comfyui without a ComfyUI host is null, not LM Studio', () {
      const noComfy = DesktopRelayBackends(a1111Host: '127.0.0.1');
      expect(
        proxy.resolveTarget('/free', {'X-LM-Mini-Backend': 'comfyui'}, noComfy),
        isNull,
      );
      expect(
        proxy.resolveTarget(
          '/controlnet/model_list',
          {'X-LM-Mini-Backend': 'a1111'},
          const DesktopRelayBackends(comfyUiHost: '127.0.0.1'),
        ),
        isNull,
      );
    });

    test('no header keeps today\'s behaviour', () {
      // Unknown path without a header still falls back to LM Studio.
      expect(proxy.resolveTarget('/free', {}, image)?.kind, 'lmStudio');
      expect(
        proxy.resolveTarget('/v2/manager/version', {}, image)?.kind,
        'lmStudio',
      );
      expect(
        proxy.resolveTarget('/controlnet/model_list', {}, image)?.kind,
        'lmStudio',
      );
      // Existing allowlist paths are unchanged.
      for (final path in [
        '/prompt',
        '/history/abc',
        '/view?filename=a.png',
        '/object_info',
        '/system_stats',
        '/queue',
        '/interrupt',
        '/upload/image',
        '/api/prompt',
      ]) {
        expect(proxy.resolveTarget(path, {}, image)?.kind, 'comfyui',
            reason: path);
      }
      expect(
          proxy.resolveTarget('/sdapi/v1/txt2img', {}, image)?.kind, 'a1111');
      // Image paths with no host configured are still refused.
      expect(
        proxy.resolveTarget('/prompt', {}, const DesktopRelayBackends()),
        isNull,
      );
    });

    test('LLM headers are unchanged', () {
      final lm = proxy.resolveTarget(
        '/v1/chat/completions',
        {'X-LM-Mini-Backend': 'lmstudio'},
        image,
      );
      expect(lm?.kind, 'lmStudio');
      expect(lm?.apiToken, 'sk-lm-secret');
      expect(
        proxy
            .resolveTarget(
                '/tts/v1/audio/speech',
                {'X-LM-Mini-Backend': 'comfyui'},
                image.copyWith(kokoroEnabled: true))
            ?.kind,
        'kokoro',
      );
    });
  });

  group('ComfyUI install gate', () {
    const gated = [
      '/v2/manager/queue/task',
      '/v2/manager/queue/install_model',
      '/v2/manager/queue/batch',
      '/v2/manager/reboot',
      '/v2/customnode/install/git_url',
      '/v2/customnode/install/pip',
      '/v2/manager/queue/update_all',
      '/v2/manager/queue/update_comfyui',
      '/v2/comfyui_manager/comfyui_switch_version',
      '/v2/snapshot/restore',
      '/v2/snapshot/remove',
      '/api/v2/manager/reboot',
      '/manager/reboot',
    ];
    const open = [
      '/free',
      '/v2/manager/queue/start',
      '/v2/manager/queue/history?ui_id=1',
      '/v2/manager/queue/status',
      '/v2/manager/version',
      '/v2/customnode/getmappings?mode=cache',
      '/prompt',
      '/upload/image',
    ];

    test('isComfyUiInstallPath', () {
      for (final p in gated) {
        expect(DesktopRequestProxy.isComfyUiInstallPath('POST', p), isTrue,
            reason: p);
        // GET on the same path is read-only and never gated.
        expect(DesktopRequestProxy.isComfyUiInstallPath('GET', p), isFalse,
            reason: p);
      }
      for (final p in open) {
        expect(DesktopRequestProxy.isComfyUiInstallPath('POST', p), isFalse,
            reason: p);
      }
    });

    Future<List<Map<String, dynamic>>> handle(
      String path,
      DesktopRelayBackends backends, {
      Map<String, String> headers = const {'X-LM-Mini-Backend': 'comfyui'},
    }) async {
      final frames = <Map<String, dynamic>>[];
      await proxy.handleRelayStyleRequest(
        msg: {
          'id': 'req-$path',
          'method': 'POST',
          'path': path,
          'headers': headers,
          'body': '{}',
        },
        backends: backends,
        send: frames.add,
        channel: 'test',
      );
      return frames;
    }

    test('off by default: 403 with a JSON error, ComfyUI not contacted',
        () async {
      // Port 1 is closed: a forwarded request would come back as a 502.
      const closed =
          DesktopRelayBackends(comfyUiHost: '127.0.0.1', comfyUiPort: 1);
      expect(closed.allowComfyUiInstall, isFalse);
      for (final p in gated) {
        final frames = await handle(p, closed);
        expect(frames.first['type'], 'response-start', reason: p);
        expect(frames.first['status'], 403, reason: p);
        final body = jsonDecode(frames[1]['data'] as String) as Map;
        expect(body['error'], DesktopRequestProxy.comfyUiInstallBlockedMessage);
        expect(frames.last['type'], 'response-end');
      }
    });

    test('on: gated routes are forwarded', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final seen = <String>[];
      server.listen((req) async {
        seen.add(
            '${req.method} ${req.uri} ${req.headers.contentType?.mimeType} '
            'auth=${req.headers.value('authorization')}');
        await utf8.decodeStream(req);
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"ok":true}');
        await req.response.close();
      });
      try {
        final backends = DesktopRelayBackends(
          comfyUiHost: '127.0.0.1',
          comfyUiPort: server.port,
          lmStudioApiToken: 'sk-lm-secret',
          allowComfyUiInstall: true,
        );
        final frames = await handle('/v2/manager/reboot', backends, headers: {
          'X-LM-Mini-Backend': 'comfyui',
          'Content-Type': 'application/json',
        });
        expect(frames.first['status'], 200);
        expect(seen, ['POST /v2/manager/reboot application/json auth=null']);
        // And a non-gated route reaches ComfyUI even with the gate off.
        final free = await handle(
            '/free', backends.copyWith(allowComfyUiInstall: false));
        expect(free.first['status'], 200);
        expect(seen.last, startsWith('POST /free'));
      } finally {
        await server.close(force: true);
      }
    });

    test('ComfyUI gone (restart) answers 502, no exception', () async {
      const closed = DesktopRelayBackends(
        comfyUiHost: '127.0.0.1',
        comfyUiPort: 1,
        allowComfyUiInstall: true,
      );
      final frames = await handle('/v2/manager/reboot', closed);
      expect(frames.single['type'], 'response-error');
      expect(frames.single['status'], 502);
      expect(frames.single['error'], contains('ComfyUI'));
    });
  });

  group('binary passthrough', () {
    test('isBinaryResponse', () {
      const b = DesktopRequestProxy.isBinaryResponse;
      expect(b('video/mp4', '/view?filename=out.mp4'), isTrue);
      expect(b('', '/api/view?filename=out.mp4'), isTrue);
      expect(
          b('image/png', '/experiment/models/preview/checkpoints/0/x'), isTrue);
      expect(b('', '/experiment/models/preview/checkpoints/0/x'), isTrue);
      expect(b('application/octet-stream', '/anything'), isTrue);
      expect(b('image/webp', '/anything'), isTrue);
      expect(b('application/json', '/v2/customnode/getmappings'), isFalse);
      expect(b('application/json; charset=utf-8', '/object_info'), isFalse);
      expect(b('text/event-stream', '/v1/chat/completions'), isFalse);
      expect(b('text/html', '/'), isFalse);
      expect(b('', '/v1/models'), isFalse);
      expect(b('audio/mpeg', '/tts/v1/audio/speech'), isTrue);
    });

    test('a binary body is forwarded byte-exact in base64 chunks', () async {
      final bytes =
          Uint8List.fromList(List.generate(70000, (i) => (i * 7) % 256));
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        req.response.headers.contentType = ContentType('video', 'mp4');
        req.response.contentLength = bytes.length;
        req.response.add(bytes);
        await req.response.close();
      });
      try {
        final frames = <Map<String, dynamic>>[];
        await proxy.handleRelayStyleRequest(
          msg: {
            'id': 'bin',
            'method': 'GET',
            'path': '/experiment/models/preview/checkpoints/0/x.mp4',
            'headers': {'X-LM-Mini-Backend': 'comfyui'},
          },
          backends: DesktopRelayBackends(
            comfyUiHost: '127.0.0.1',
            comfyUiPort: server.port,
          ),
          send: frames.add,
          channel: 'test',
        );
        expect(frames.first['status'], 200);
        final out = <int>[];
        for (final f in frames.where((f) => f['type'] == 'response-chunk')) {
          expect(f['encoding'], 'base64');
          out.addAll(base64Decode(f['data'] as String));
        }
        expect(out, bytes);
      } finally {
        await server.close(force: true);
      }
    });
  });
}
