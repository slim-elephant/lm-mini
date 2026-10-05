import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/group_participant_backend.dart';
import 'package:lm_mini/utils/param_preset_key.dart';
import 'package:lm_mini/utils/remote_host_backends.dart';
import 'package:lm_mini/utils/server_model_memory.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

void main() {
  group('CloudApiType.jan', () {
    test('is a free local OpenAI-compatible server', () {
      const jan = CloudApiType.jan;
      expect(jan.isPremium, isFalse);
      expect(jan.isFreeLocalServer, isTrue);
      expect(jan.providerKind, 'jan');
      expect(jan.isLocalOpenAiCompatible, isTrue);
      expect(jan.usesNativeChatApi, isFalse);
      expect(jan.allowsEmptyApiKey, isTrue);
      expect(jan.defaultBaseUrl, 'http://localhost:1337');
      expect(jan.chatPath, '/v1/chat/completions');
      expect(jan.modelsPath, '/v1/models');
      expect(jan.displayName, 'JAN AI');
    });

    test('forProviderKind maps jan and not Home QR kinds', () {
      expect(CloudApiType.forProviderKind('jan'), CloudApiType.jan);
      expect(CloudApiType.isFreeLocalKind('jan'), isTrue);
      expect(CloudApiType.isFreeLocalKind('lmStudio'), isFalse);
      expect(RemoteHostBackends.llmKinds.contains('jan'), isTrue);
    });
  });

  test('Jan memory and param keys stay on the cloud slot', () {
    expect(
      ServerModelMemory.key(
        providerKind: 'jan',
        isRemoteActive: false,
        usbModeEnabled: false,
        serverUrl: 'http://192.168.1.10:1337',
      ),
      'cloud:jan',
    );
    expect(ParamPresetKey.usesCloudProviderId('jan'), isTrue);
    expect(GroupParticipantBackend.knownKinds.contains('jan'), isTrue);
    expect(RemoteHostBackends.displayName('jan'), 'JAN AI');
  });
}
