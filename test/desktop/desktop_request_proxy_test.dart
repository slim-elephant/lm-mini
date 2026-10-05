import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/desktop/host/desktop_relay_client.dart';
import 'package:lm_mini/desktop/host/desktop_request_proxy.dart';

void main() {
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
          reachable: {'lmStudio': true, 'kokoro': false},
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
