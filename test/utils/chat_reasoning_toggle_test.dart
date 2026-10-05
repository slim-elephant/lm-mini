import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/lm_studio_model.dart';
import 'package:lm_mini/services/reasoning_support_service.dart';
import 'package:lm_mini/utils/chat_reasoning_toggle.dart';
import 'package:lm_mini/utils/param_preset_resolver.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

LMStudioModel _model(
  String id, {
  List<String>? reasoningAllowedOptions,
  List<String>? capabilities,
}) {
  return LMStudioModel(
    id: id,
    object: 'model',
    type: 'llm',
    publisher: '',
    arch: '',
    compatibilityType: 'gguf',
    quantization: '',
    state: 'not-loaded',
    maxContextLength: 4096,
    reasoningAllowedOptions: reasoningAllowedOptions,
    capabilities: capabilities,
  );
}

void main() {
  setUp(() {
    ReasoningSupportService.instance.ingestCatalog([]);
  });
  tearDown(() {
    ReasoningSupportService.instance.ingestCatalog([]);
  });

  group('shouldShow', () {
    test('hides for on-device engines', () {
      final settings = AppSettings(
        activeProviderKind: 'onDeviceGguf',
        selectedLocalModelId: 'qwen3-4b',
        selectedModel: 'qwen3-4b',
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isFalse);
    });

    test('shows for LM Studio reasoning-style ids', () {
      final settings = AppSettings(
        activeProviderKind: 'lmStudio',
        selectedModel: 'qwen3-8b',
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isTrue);
    });

    test('hides for LM Studio non-reasoning ids without catalog caps', () {
      final settings = AppSettings(
        activeProviderKind: 'lmStudio',
        selectedModel: 'llama-3-8b',
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isFalse);
    });

    test('shows for Ollama Qwen 3.5 filesystem ids', () {
      const id = '/Users/me/.lmstudio/models/lmstudio-community/'
          'Qwen3.5-4B-GGUF/Qwen3.5-4B-Q4_K_M.gguf';
      final settings = AppSettings(
        activeProviderKind: 'ollama',
        selectedModel: id,
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isTrue);
      expect(ChatReasoningToggle.canControl(settings: settings), isTrue);
    });

    test('hides for Ollama non-reasoning ids without catalog caps', () {
      final settings = AppSettings(
        activeProviderKind: 'ollama',
        selectedModel: 'llama3.1:8b',
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isFalse);
    });

    test('shows for Ollama when catalog reports thinking capability', () {
      final settings = AppSettings(
        activeProviderKind: 'ollama',
        selectedModel: 'custom-thinker:latest',
      );
      expect(
        ChatReasoningToggle.shouldShow(
          settings: settings,
          availableModels: [
            _model('custom-thinker:latest', capabilities: const ['thinking']),
          ],
        ),
        isTrue,
      );
    });

    test('shows Unsloth thinking control even for generic model ids', () {
      final settings = AppSettings(
        activeProviderKind: 'unsloth',
        selectedModel: 'default',
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isTrue);
    });

    test('shows for oMLX Qwen 3.5 ids', () {
      final settings = AppSettings(
        activeProviderKind: 'omlx',
        selectedModel: 'Qwen3.5-4B',
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isTrue);
    });

    test('native think backends are ollama, omlx, jan, unsloth, and openai-compat', () {
      expect(
        ChatReasoningToggle.requestTypeSupportsNativeThink(CloudApiType.ollama),
        isTrue,
      );
      expect(
        ChatReasoningToggle.requestTypeSupportsNativeThink(CloudApiType.omlx),
        isTrue,
      );
      expect(
        ChatReasoningToggle.requestTypeSupportsNativeThink(CloudApiType.jan),
        isTrue,
      );
      expect(
        ChatReasoningToggle.requestTypeSupportsNativeThink(
            CloudApiType.unsloth),
        isTrue,
      );
      expect(
        ChatReasoningToggle.requestTypeSupportsNativeThink(
            CloudApiType.openaiCompatible),
        isTrue,
      );
      expect(
        ChatReasoningToggle.requestTypeSupportsNativeThink(
            CloudApiType.mistral),
        isFalse,
      );
      expect(
        ChatReasoningToggle.requestTypeSupportsThinkingUi(CloudApiType.openai),
        isTrue,
      );
    });

    test('shows when LM Studio catalog lists reasoning options', () {
      ReasoningSupportService.instance.ingestCatalog([
        _model('llama-3-8b', reasoningAllowedOptions: const ['off', 'on']),
      ]);
      final settings = AppSettings(
        activeProviderKind: 'lmStudio',
        selectedModel: 'llama-3-8b',
      );
      expect(ChatReasoningToggle.shouldShow(settings: settings), isTrue);
    });
  });

  group('applyToChatSettings', () {
    test('stores override when it differs from global', () {
      final next = ChatReasoningToggle.applyToChatSettings(
        {'isDraft': true},
        enabled: true,
        globalReasoningOn: false,
        canControl: true,
      );
      expect(next['reasoningEnabled'], isTrue);
      expect(next['isDraft'], isTrue);
    });

    test('removes key when it matches global', () {
      final next = ChatReasoningToggle.applyToChatSettings(
        {'reasoningEnabled': false, 'isDraft': true},
        enabled: true,
        globalReasoningOn: true,
        canControl: true,
      );
      expect(next.containsKey('reasoningEnabled'), isFalse);
      expect(next['isDraft'], isTrue);
    });

    test('does not persist when the model cannot control reasoning', () {
      final next = ChatReasoningToggle.applyToChatSettings(
        {'reasoningEnabled': false},
        enabled: false,
        globalReasoningOn: true,
        canControl: false,
      );
      expect(next.containsKey('reasoningEnabled'), isFalse);
    });
  });

  group('ParamPreset overlay', () {
    test('reasoningEnabled false maps effective reasoning to off', () {
      final global = AppSettings(reasoning: 'medium');
      final chat = ChatReasoningToggle.applyToChatSettings(
        const {},
        enabled: false,
        globalReasoningOn: true,
        canControl: true,
      );
      final effective = ParamPresetResolver.overlay(
        global: global,
        isPremium: false,
        chatSettings: chat,
      );
      expect(effective.reasoning, 'off');
      expect(effective.isReasoningEnabled, isFalse);
    });
  });
}
