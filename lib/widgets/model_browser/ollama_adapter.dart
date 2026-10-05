import '../../models/lm_studio_model.dart';
import '../../models/pickable_model.dart';
import 'lm_studio_adapter.dart';

/// Ollama models arrive as [LMStudioModel] via SettingsProvider.
PickableModel mapOllamaModel({
  required LMStudioModel model,
  required String? selectedModelId,
}) {
  return mapLmStudioModel(
    model: model,
    selectedModelId: selectedModelId,
    isPinned: false,
    kind: ModelProviderKind.ollama,
  );
}
