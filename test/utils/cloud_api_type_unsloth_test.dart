import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/group_participant_backend.dart';
import 'package:lm_mini/utils/param_preset_key.dart';
import 'package:lm_mini/utils/remote_host_backends.dart';
import 'package:lm_mini/utils/server_model_memory.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

void main() {
  group('CloudApiType.unsloth', () {
    test('is a free local OpenAI-compatible server that requires a key', () {
      const unsloth = CloudApiType.unsloth;
      expect(unsloth.isPremium, isFalse);
      expect(unsloth.isFreeLocalServer, isTrue);
      expect(unsloth.providerKind, 'unsloth');
      expect(unsloth.isLocalOpenAiCompatible, isTrue);
      expect(unsloth.usesNativeChatApi, isFalse);
      expect(unsloth.allowsEmptyApiKey, isFalse);
      expect(unsloth.supportsUnslothThinking, isTrue);
      expect(unsloth.defaultBaseUrl, 'http://localhost:8888');
      expect(unsloth.chatPath, '/v1/chat/completions');
      expect(unsloth.modelsPath, '/v1/models');
      expect(unsloth.displayName, 'Unsloth');
    });

    test('forProviderKind maps unsloth and not Home QR kinds', () {
      expect(
        CloudApiType.forProviderKind('unsloth'),
        CloudApiType.unsloth,
      );
      expect(CloudApiType.isFreeLocalKind('unsloth'), isTrue);
      expect(CloudApiType.isFreeLocalKind('lmStudio'), isFalse);
      expect(RemoteHostBackends.llmKinds.contains('unsloth'), isTrue);
    });
  });

  test('Unsloth memory and param keys stay on the cloud slot', () {
    expect(
      ServerModelMemory.key(
        providerKind: 'unsloth',
        isRemoteActive: false,
        usbModeEnabled: false,
        serverUrl: 'http://192.168.1.10:8888',
      ),
      'cloud:unsloth',
    );
    expect(ParamPresetKey.usesCloudProviderId('unsloth'), isTrue);
    expect(GroupParticipantBackend.knownKinds.contains('unsloth'), isTrue);
    expect(RemoteHostBackends.displayName('unsloth'), 'Unsloth');
  });
}
