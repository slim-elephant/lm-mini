import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/param_preset.dart';
import 'package:lm_mini/models/system_prompt.dart';
import 'package:lm_mini/utils/param_preset_key.dart';
import 'package:lm_mini/utils/param_preset_resolver.dart';

ParamPreset _preset({
  double temperature = 0.8,
  int maxTokens = 2048,
  String reasoning = 'off',
}) {
  return ParamPreset(
    temperature: temperature,
    maxTokens: maxTokens,
    contextWindow: 4096,
    topP: 0.9,
    topK: 40,
    minP: 0.05,
    repeatPenalty: 1.1,
    frequencyPenalty: 0,
    presencePenalty: 0,
    reasoning: reasoning,
    verbosity: 'medium',
    contextFitMode: 'off',
    loadFlashAttention: true,
    loadOffloadKvCache: true,
  );
}

SystemPrompt _persona({
  bool useCustomParams = false,
  ParamPreset? customParams,
}) {
  final now = DateTime(2026, 1, 1);
  return SystemPrompt(
    id: 'p1',
    name: 'Test',
    content: 'Hi',
    createdAt: now,
    updatedAt: now,
    useCustomParams: useCustomParams,
    customParams: customParams,
  );
}

void main() {
  group('ParamPresetKey', () {
    test('local providers use kind::modelId', () {
      expect(
        ParamPresetKey.build(
          providerKind: 'lmStudio',
          modelId: 'llama-3',
        ),
        'lmStudio::llama-3',
      );
      expect(
        ParamPresetKey.build(
          providerKind: 'onDeviceGguf',
          modelId: 'qwen2.5',
        ),
        'onDeviceGguf::qwen2.5',
      );
    });

    test('cloud providers include cloudProviderId', () {
      expect(
        ParamPresetKey.build(
          providerKind: 'cloud',
          modelId: 'gpt-4o',
          cloudProviderId: 'openai-1',
        ),
        'cloud::openai-1::gpt-4o',
      );
      expect(
        ParamPresetKey.build(
          providerKind: 'ollama',
          modelId: 'llama3',
          cloudProviderId: 'ollama-local',
        ),
        'ollama::ollama-local::llama3',
      );
    });

    test('empty model id returns null', () {
      expect(
        ParamPresetKey.build(providerKind: 'lmStudio', modelId: '  '),
        isNull,
      );
    });

    test('fromSettings uses on-device id', () {
      final settings = AppSettings(
        activeProviderKind: 'onDeviceGguf',
        selectedModel: 'server-model',
        selectedLocalModelId: 'local-gguf',
      );
      expect(
        ParamPresetKey.fromSettings(settings),
        'onDeviceGguf::local-gguf',
      );
    });
  });

  group('ParamPresetResolver', () {
    test('chat sampler wins over global for free users', () {
      final global = AppSettings(temperature: 0.2, maxTokens: 100);
      final settings = global.copyWith(
        modelParamPresets: {
          'lmStudio::m1': _preset(temperature: 0.4, maxTokens: 200),
        },
      );
      final result = ParamPresetResolver.overlay(
        global: settings,
        isPremium: false,
        modelKey: 'lmStudio::m1',
        persona: _persona(
          useCustomParams: true,
          customParams: _preset(temperature: 0.6, maxTokens: 300),
        ),
        chatSettings: {'temperature': 0.9},
      );
      expect(result.temperature, 0.9);
      expect(result.maxTokens, 100);
    });

    test('missing model preset falls back to global', () {
      final global = AppSettings(temperature: 0.2);
      final result = ParamPresetResolver.overlay(
        global: global,
        isPremium: true,
        modelKey: 'lmStudio::missing',
      );
      expect(result.temperature, 0.2);
    });

    test('free users skip model and persona overlays', () {
      final global = AppSettings(temperature: 0.2);
      final settings = global.copyWith(
        modelParamPresets: {'lmStudio::m1': _preset(temperature: 0.4)},
      );
      final result = ParamPresetResolver.overlay(
        global: settings,
        isPremium: false,
        modelKey: 'lmStudio::m1',
        persona: _persona(
          useCustomParams: true,
          customParams: _preset(temperature: 0.6),
        ),
        chatSettings: {'temperature': 0.9},
      );
      expect(result.temperature, 0.9);
    });

    test('free users without chat override stay on global', () {
      final global = AppSettings(temperature: 0.2);
      final settings = global.copyWith(
        modelParamPresets: {'lmStudio::m1': _preset(temperature: 0.4)},
      );
      final result = ParamPresetResolver.overlay(
        global: settings,
        isPremium: false,
        modelKey: 'lmStudio::m1',
        persona: _persona(
          useCustomParams: true,
          customParams: _preset(temperature: 0.6),
        ),
      );
      expect(result.temperature, 0.2);
    });
  });

  group('persistence', () {
    test('ParamPreset json round-trips', () {
      final preset = _preset(temperature: 0.55, maxTokens: 111)
          .copyWith(loadEvalBatchSize: 512, contextFitMode: 'roll');
      final restored = ParamPreset.fromJson(preset.toJson());
      expect(restored, preset);
    });

    test('AppSettings persists modelParamPresets', () {
      final settings = AppSettings(
        temperature: 0.3,
        modelParamPresets: {'lmStudio::m1': _preset(temperature: 0.7)},
      );
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.modelParamPresets['lmStudio::m1']?.temperature, 0.7);
      expect(restored.temperature, 0.3);
    });

    test('copyWith preserves modelParamPresets', () {
      final settings = AppSettings(
        modelParamPresets: {'lmStudio::m1': _preset(temperature: 0.7)},
      );
      final updated = settings.copyWith(voiceTtsProvider: 'kokoro');
      expect(updated.modelParamPresets['lmStudio::m1']?.temperature, 0.7);
    });

    test('applying a global snapshot does not rewrite model presets', () {
      final settings = AppSettings(
        temperature: 0.2,
        modelParamPresets: {'lmStudio::m1': _preset(temperature: 0.7)},
      );
      final globalEdit = ParamPreset.fromSettings(settings).copyWith(
        temperature: 0.5,
      );
      final updated = globalEdit.applyTo(settings);
      expect(updated.temperature, 0.5);
      expect(updated.modelParamPresets['lmStudio::m1']?.temperature, 0.7);
    });

    test('repairListFields keeps modelParamPresets', () {
      final settings = AppSettings(
        modelParamPresets: {'lmStudio::m1': _preset(temperature: 0.7)},
      );
      expect(
        settings
            .repairListFields()
            .modelParamPresets['lmStudio::m1']
            ?.temperature,
        0.7,
      );
    });

    test('SystemPrompt custom params round-trip', () {
      final persona = _persona(
        useCustomParams: true,
        customParams: _preset(temperature: 0.42),
      );
      final restored = SystemPrompt.fromJson(persona.toJson());
      expect(restored.useCustomParams, isTrue);
      expect(restored.customParams?.temperature, 0.42);
    });

    test('legacy SystemPrompt json defaults custom params off', () {
      final restored = SystemPrompt.fromJson({
        'id': 'x',
        'name': 'n',
        'content': 'c',
        'createdAt': DateTime(2026).toIso8601String(),
        'updatedAt': DateTime(2026).toIso8601String(),
      });
      expect(restored.useCustomParams, isFalse);
      expect(restored.customParams, isNull);
    });
  });
}
