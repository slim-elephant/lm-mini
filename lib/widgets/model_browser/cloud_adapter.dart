import '../../models/lm_studio_model.dart';
import '../../models/pickable_model.dart';
import 'lm_studio_adapter.dart';

/// Cloud providers reuse the LM Studio list shape with [ModelProviderKind.cloud].
PickableModel mapCloudModel({
  required LMStudioModel model,
  required String? selectedModelId,
}) {
  return mapLmStudioModel(
    model: model,
    selectedModelId: selectedModelId,
    isPinned: false,
    kind: ModelProviderKind.cloud,
  );
}
