import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/changelog_service.dart';
import 'package:lm_mini/services/version_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChangelogEntry _entry({
  String version = '1.9.0',
  String title = 'App Lock, JAN AI & Persona Voices',
  List<String> changes = const ['Added App Lock (Pro)'],
  String? appStoreUrl,
  String? playStoreUrl,
}) {
  return ChangelogEntry(
    id: 'doc1',
    version: version,
    title: title,
    changes: changes,
    createdAt: DateTime(2026, 9, 8),
    appStoreUrl: appStoreUrl,
    playStoreUrl: playStoreUrl,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    VersionCheckService.instance.debugReset();
  });

  group('AppVersionInfo.fromChangelog', () {
    test('shows an update when changelog is newer than the install', () {
      final info = AppVersionInfo.fromChangelog(_entry(), '1.8.25');
      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '1.9.0');
      expect(info.notes, 'App Lock, JAN AI & Persona Voices. Added App Lock (Pro)');
    });

    test('hides the banner when the user already has that version', () {
      final info = AppVersionInfo.fromChangelog(_entry(), '1.9.0');
      expect(info.hasUpdate, isFalse);
    });

    test('uses the App Store URL on iOS', () {
      final info = AppVersionInfo.fromChangelog(
        _entry(appStoreUrl: 'https://apps.apple.com/app/lm-mini'),
        '1.8.25',
        platform: TargetPlatform.iOS,
      );
      expect(info.downloadUrl, 'https://apps.apple.com/app/lm-mini');
    });

    test('uses the Play URL on Android', () {
      final info = AppVersionInfo.fromChangelog(
        _entry(playStoreUrl: 'https://play.google.com/store/apps/details?id=net.neuro9.lmmini'),
        '1.8.25',
        platform: TargetPlatform.android,
      );
      expect(info.downloadUrl, contains('play.google.com'));
    });
  });

  group('VersionCheckService.check', () {
    test('builds info from the latest Firebase changelog', () async {
      final info = await VersionCheckService.instance.check(
        minInterval: Duration.zero,
        currentVersion: '1.8.25',
        fetchLatest: () async => _entry(),
      );
      expect(info, isNotNull);
      expect(info!.hasUpdate, isTrue);
      expect(info.latestVersion, '1.9.0');
    });

    test('does not treat a matching changelog as an update', () async {
      final info = await VersionCheckService.instance.check(
        minInterval: Duration.zero,
        currentVersion: '1.9.0',
        fetchLatest: () async => _entry(),
      );
      expect(info!.hasUpdate, isFalse);
    });

    test('leaves the banner off when Firestore has no changelog', () async {
      final info = await VersionCheckService.instance.check(
        minInterval: Duration.zero,
        currentVersion: '1.8.25',
        fetchLatest: () async => null,
      );
      expect(info, isNull);
    });
  });
}
