import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/desktop/desktop_platform.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/services/home_sync_service.dart';
import 'package:lm_mini/utils/remote_host_backends.dart';

void main() {
  test('display names for QR backends', () {
    expect(RemoteHostBackends.displayName('lmMiniDesktop'), 'LM Mini Home');
    expect(RemoteHostBackends.displayName('lmStudio'), 'LM Studio');
    expect(RemoteHostBackends.displayName('ollama'), 'Ollama');
    expect(RemoteHostBackends.displayName('jan'), 'JAN AI');
    expect(RemoteHostBackends.displayName('unsloth'), 'Unsloth');
  });

  test('remoteListLabel uses Connect vs Home', () {
    final connect = AppSettings(
      isRemoteActive: true,
      remoteBackends: const ['lmStudio', 'jan'],
    );
    expect(
      RemoteHostBackends.remoteListLabel('lmStudio', connect),
      'LM Studio via Connect',
    );
    expect(
      RemoteHostBackends.remoteListLabel('jan', connect),
      'JAN AI via Connect',
    );
    final home = AppSettings(
      isRemoteActive: true,
      remoteBackends: const ['lmMiniDesktop', 'lmStudio'],
    );
    expect(
      RemoteHostBackends.remoteListLabel('lmStudio', home),
      'LM Studio via Home',
    );
    expect(
      RemoteHostBackends.remoteListLabel('lmMiniDesktop', home),
      'LM Mini Home',
    );
  });

  test('isConnectHost is true when QR has backends but not Home', () {
    expect(
      RemoteHostBackends.isConnectHost(
        AppSettings(
          isRemoteActive: true,
          remoteBackends: const ['lmStudio', 'jan', 'unsloth'],
        ),
      ),
      isTrue,
    );
    expect(
      RemoteHostBackends.isConnectHost(
        AppSettings(
          isRemoteActive: true,
          remoteBackends: const ['lmMiniDesktop', 'lmStudio'],
        ),
      ),
      isFalse,
    );
  });

  test('visibleOf on Connect always offers LM Studio, Ollama, JAN, Unsloth', () {
    final settings = AppSettings(
      isRemoteActive: true,
      remoteBackends: const ['lmStudio'],
    );
    expect(
      RemoteHostBackends.visibleOf(
        settings,
        hostStatusOk: true,
        reachable: (_) => false,
      ),
      ['lmStudio', 'ollama', 'jan', 'unsloth'],
    );
  });

  test('visibleOf on Home hides unreachable advertised backends', () {
    final settings = AppSettings(
      isRemoteActive: true,
      remoteBackends: const ['lmMiniDesktop', 'lmStudio', 'ollama'],
    );
    expect(
      RemoteHostBackends.visibleOf(
        settings,
        hostStatusOk: true,
        reachable: (kind) => kind == 'lmStudio',
      ),
      ['lmMiniDesktop', 'lmStudio'],
    );
  });

  test('visibleOf on legacy Connect without host-status still offers QR backends', () {
    final settings = AppSettings(
      isRemoteActive: true,
      remoteBackends: const ['lmStudio', 'ollama'],
    );
    expect(
      RemoteHostBackends.visibleOf(
        settings,
        hostStatusOk: false,
        reachable: (_) => false,
      ),
      ['lmStudio', 'ollama', 'jan', 'unsloth'],
    );
  });

  test('advertisedOf keeps QR order of known LLM backends', () {
    final settings = AppSettings(
      isRemoteActive: true,
      remoteBackends: const [
        'ollama',
        'lmMiniDesktop',
        'lmStudio',
        'jan',
        'unsloth',
        'unknown',
      ],
    );
    expect(
      RemoteHostBackends.advertisedOf(settings),
      ['lmMiniDesktop', 'lmStudio', 'ollama', 'jan', 'unsloth'],
    );
  });

  test('legacy QR with empty backends is LM Studio only', () {
    expect(
      RemoteHostBackends.advertisedOf(AppSettings(isRemoteActive: true)),
      ['lmStudio'],
    );
  });

  test('isHomeHost is true when QR advertised lmMiniDesktop', () {
    expect(
      RemoteHostBackends.isHomeHost(
        AppSettings(
          isRemoteActive: true,
          remoteBackends: const ['lmMiniDesktop', 'lmStudio'],
        ),
      ),
      isTrue,
    );
    expect(
      RemoteHostBackends.isHomeHost(
        AppSettings(isRemoteActive: true, remoteBackends: const ['lmStudio']),
      ),
      isFalse,
    );
  });

  test('isPairedHome is true after pairing even when a local server is selected', () {
    expect(
      RemoteHostBackends.isPairedHome(
        AppSettings(
          isRemoteActive: false,
          remoteServerUrl: 'https://relay.example/s/abc',
          remoteAuthToken: 'tok',
          remoteBackends: const ['lmMiniDesktop', 'lmStudio'],
        ),
      ),
      isTrue,
    );
    expect(
      RemoteHostBackends.isPairedHome(
        AppSettings(isRemoteActive: false, remoteServerUrl: 'https://relay.example/s/abc'),
      ),
      isFalse,
    );
  });

  test('shouldPrompt is true only until the user answers', () {
    final paired = AppSettings(
      remoteServerUrl: 'https://relay.example/s/abc',
      remoteAuthToken: 'tok',
      remoteBackends: const ['lmMiniDesktop'],
    );
    expect(HomeSyncService.shouldPrompt(paired), isTrue);
    expect(
      HomeSyncService.shouldPrompt(paired.copyWith(homeSyncPrompted: true)),
      isFalse,
    );
    expect(
      HomeSyncService.shouldPrompt(paired.copyWith(homeSyncEnabled: true)),
      isFalse,
    );
    expect(HomeSyncService.shouldPrompt(AppSettings()), isFalse);
  });

  test('homeLocationTitle follows host platform', () {
    expect(
      RemoteHostBackends.homeLocationTitle(null),
      'LM Mini Home on your Mac',
    );
    expect(
      RemoteHostBackends.homeLocationTitle('macos'),
      'LM Mini Home on your Mac',
    );
    expect(
      RemoteHostBackends.homeLocationTitle('windows'),
      'LM Mini Home on your Windows PC',
    );
    expect(
      RemoteHostBackends.homeLocationTitle('linux'),
      'LM Mini Home on your Linux PC',
    );
  });

  test('remoteStatusSubtitle never says this Mac on the phone', () {
    expect(
      RemoteHostBackends.remoteStatusSubtitle(
        reachable: false,
        onThisDevice: false,
      ),
      "Can't reach your computer",
    );
    expect(
      RemoteHostBackends.remoteStatusSubtitle(
        reachable: true,
        onThisDevice: false,
      ),
      'On your computer',
    );
    expect(
      RemoteHostBackends.remoteStatusSubtitle(
        reachable: false,
        onThisDevice: true,
      ),
      isNot(contains('your computer')),
    );
  });

  test('remoteStatusSubtitle on this device uses thisMachine', () {
    expect(
      RemoteHostBackends.remoteStatusSubtitle(
        reachable: true,
        onThisDevice: true,
      ),
      'On ${DesktopPlatform.thisMachine}',
    );
  });

  test('probeKind uses Home when paired, even if local LM Studio is selected', () {
    expect(
      RemoteHostBackends.probeKind(
        AppSettings(
          isRemoteActive: false,
          activeProviderKind: 'lmStudio',
          remoteServerUrl: 'https://relay.example/s/abc',
          remoteAuthToken: 'tok',
          remoteBackends: const ['lmMiniDesktop', 'lmStudio'],
        ),
      ),
      RemoteHostBackends.lmMiniDesktop,
    );
  });
}
