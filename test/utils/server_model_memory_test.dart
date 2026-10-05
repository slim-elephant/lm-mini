import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/utils/server_model_memory.dart';

void main() {
  group('ServerModelMemory.key', () {
    test('keys remote backends by kind, not relay URL', () {
      const url = 'https://lm-mini-relay-abc.run.app';
      expect(
        ServerModelMemory.key(
          providerKind: 'lmMiniDesktop',
          isRemoteActive: true,
          usbModeEnabled: false,
          serverUrl: url,
        ),
        'remote:lmMiniDesktop',
      );
      expect(
        ServerModelMemory.key(
          providerKind: 'lmStudio',
          isRemoteActive: true,
          usbModeEnabled: false,
          serverUrl: url,
        ),
        'remote:lmStudio',
      );
    });

    test('keys local LM Studio by server URL', () {
      expect(
        ServerModelMemory.key(
          providerKind: 'lmStudio',
          isRemoteActive: false,
          usbModeEnabled: false,
          serverUrl: 'http://192.168.1.10:1234',
        ),
        'local:http://192.168.1.10:1234',
      );
    });

    test('keys USB and on-device separately', () {
      expect(
        ServerModelMemory.key(
          providerKind: 'lmStudio',
          isRemoteActive: false,
          usbModeEnabled: true,
          serverUrl: 'http://127.0.0.1:1234',
        ),
        'usb:lmStudio',
      );
      expect(
        ServerModelMemory.key(
          providerKind: 'onDeviceMlx',
          isRemoteActive: false,
          usbModeEnabled: false,
          serverUrl: 'http://localhost:1234',
        ),
        'onDevice:onDeviceMlx',
      );
    });
  });

  group('ServerModelMemory.pick', () {
    test('restores remembered id when it is in the new catalog', () {
      expect(
        ServerModelMemory.pick(
          remembered: 'home-model',
          current: 'ii-search-4b',
          availableIds: const ['home-model', 'other'],
        ),
        'home-model',
      );
    });

    test('clears a foreign model that is not in the new catalog', () {
      expect(
        ServerModelMemory.pick(
          remembered: null,
          current: 'ii-search-4b',
          availableIds: const ['home-model'],
        ),
        isNull,
      );
    });

    test('keeps current when it is in the catalog and nothing is remembered',
        () {
      expect(
        ServerModelMemory.pick(
          remembered: null,
          current: 'home-model',
          availableIds: const ['home-model'],
        ),
        'home-model',
      );
    });

    test('does not keep a foreign current when the catalog failed to load', () {
      expect(
        ServerModelMemory.pick(
          remembered: null,
          current: 'ii-search-4b',
          availableIds: const [],
        ),
        isNull,
      );
    });
  });

  test('selectedModelByServer survives JSON round-trip', () {
    final settings = AppSettings(
      selectedModel: 'home-model',
      selectedModelByServer: const {
        'remote:lmMiniDesktop': 'home-model',
        'remote:lmStudio': 'ii-search-4b',
      },
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.selectedModel, 'home-model');
    expect(restored.selectedModelByServer['remote:lmStudio'], 'ii-search-4b');
    expect(
      restored.copyWith(voiceTtsProvider: 'kokoro').selectedModelByServer,
      restored.selectedModelByServer,
    );
  });
}
