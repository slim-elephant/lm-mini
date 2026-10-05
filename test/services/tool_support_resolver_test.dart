import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/lm_studio_model.dart';
import 'package:lm_mini/services/tool_support_resolver.dart';

LMStudioModel _model(String id, {bool? tools}) {
  return LMStudioModel(
    id: id,
    object: 'model',
    type: 'llm',
    publisher: 'Ollama',
    arch: '',
    compatibilityType: 'gguf',
    quantization: '',
    state: 'loaded',
    maxContextLength: 4096,
    toolUseCapability: tools,
    capabilities: [
      if (tools == true) 'tool_use',
    ],
  );
}

void main() {
  final resolver = ToolSupportResolver.instance;

  test('Ollama deepseek-coder does not advertise tools', () {
    final settings = AppSettings(
      activeProviderKind: 'ollama',
      selectedModel: 'deepseek-coder:6.7b',
      enableToolUse: true,
    );
    expect(resolver.currentModelSupportsTools(settings), isFalse);
  });

  test('Ollama catalog toolUseCapability overrides the name heuristic', () {
    final settings = AppSettings(
      activeProviderKind: 'ollama',
      selectedModel: 'deepseek-coder:6.7b',
      enableToolUse: true,
    );
    expect(
      resolver.currentModelSupportsTools(
        settings,
        availableModels: [_model('deepseek-coder:6.7b', tools: true)],
      ),
      isTrue,
    );
    expect(
      resolver.currentModelSupportsTools(
        settings,
        availableModels: [_model('deepseek-coder:6.7b', tools: false)],
      ),
      isFalse,
    );
  });

  test('Ollama qwen2.5 is treated as tools-capable without a catalog hit', () {
    final settings = AppSettings(
      activeProviderKind: 'ollama',
      selectedModel: 'qwen2.5:7b',
      enableToolUse: true,
    );
    expect(resolver.currentModelSupportsTools(settings), isTrue);
  });
}
