import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';

void main() {
  test('copyWith preserves modelsPreferLoadedParams when changing voice TTS',
      () {
    final settings =
        AppSettings.fromJson({'serverUrl': 'http://localhost:1234'});
    expect(settings.modelsPreferLoadedParams, isEmpty);

    final updated = settings.copyWith(voiceTtsProvider: 'kokoro');
    expect(updated.voiceTtsProvider, 'kokoro');
    expect(updated.modelsPreferLoadedParams, isEmpty);
  });

  test(
      'copyWith with explicit null modelsPreferLoadedParams keeps existing list',
      () {
    final settings = AppSettings(
      modelsPreferLoadedParams: const ['model-a'],
    );

    final updated = settings.copyWith(
      voiceTtsProvider: 'kokoro',
      modelsPreferLoadedParams: null,
    );
    expect(updated.modelsPreferLoadedParams, ['model-a']);
  });

  test('repairListFields normalizes list fields', () {
    final settings = AppSettings(
      voiceTtsProvider: 'kokoro',
      modelsPreferLoadedParams: const ['model-a'],
      pinnedModels: const ['pinned-a'],
    );
    final repaired = settings.repairListFields();
    expect(repaired.modelsPreferLoadedParams, ['model-a']);
    expect(repaired.pinnedModels, ['pinned-a']);
  });

  test('glassEffectsEnabled defaults on and round-trips through json', () {
    final fresh = AppSettings.fromJson({'serverUrl': 'http://localhost:1234'});
    expect(fresh.glassEffectsEnabled, isTrue);
    expect(fresh.lowBatteryMode, isFalse);
    expect(fresh.glassEffectsActive, isTrue);

    final off = AppSettings.fromJson({
      'serverUrl': 'http://localhost:1234',
      'glassEffectsEnabled': false,
    });
    expect(off.glassEffectsEnabled, isFalse);
    expect(off.copyWith(glassEffectsEnabled: true).glassEffectsEnabled, isTrue);

    final saver = AppSettings.fromJson({
      'serverUrl': 'http://localhost:1234',
      'lowBatteryMode': true,
    });
    expect(saver.lowBatteryMode, isTrue);
    expect(saver.glassEffectsEnabled, isTrue);
    expect(saver.glassEffectsActive, isFalse);
    expect(
      AppSettings.fromJson(saver.toJson()).lowBatteryMode,
      isTrue,
    );
  });

  test('contextFitMode defaults off and round-trips', () {
    final fresh = AppSettings.fromJson({'serverUrl': 'http://localhost:1234'});
    expect(fresh.contextFitMode, 'off');
    final rolled = fresh.copyWith(contextFitMode: 'roll');
    expect(rolled.contextFitMode, 'roll');
    expect(
      AppSettings.fromJson(rolled.toJson()).contextFitMode,
      'roll',
    );
    expect(
      AppSettings.fromJson({'contextFitMode': null}).contextFitMode,
      'off',
    );
    // copyWith on unrelated fields must not require contextFitMode to be set
    // (hot-reload / older saved maps).
    expect(fresh.copyWith(aiExperienceLevel: 'power').contextFitMode, 'off');
  });

  test('fullWidthAssistant defaults on for new installs, off in saved json',
      () {
    expect(AppSettings().fullWidthAssistant, isTrue);
    expect(AppSettings().hideAvatars, isTrue);
    final fresh = AppSettings.fromJson({'serverUrl': 'http://localhost:1234'});
    expect(fresh.fullWidthAssistant, isFalse);
    expect(fresh.fullWidthAssistantNudgeShown, isFalse);
    expect(fresh.watchShowPersonas, isTrue);
    expect(fresh.watchAssistantInBubble, isTrue);
    final watch = fresh.copyWith(
      watchShowPersonas: false,
      watchAssistantInBubble: false,
    );
    final roundTrip = AppSettings.fromJson(watch.toJson());
    expect(roundTrip.watchShowPersonas, isFalse);
    expect(roundTrip.watchAssistantInBubble, isFalse);
    final on = fresh.copyWith(fullWidthAssistant: true);
    expect(on.fullWidthAssistant, isTrue);
    expect(
      AppSettings.fromJson(on.toJson()).fullWidthAssistant,
      isTrue,
    );
  });
}
