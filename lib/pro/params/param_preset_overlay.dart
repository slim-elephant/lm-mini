// LM-MINI-PRO-STUB
import '../../models/app_settings.dart';
import '../../models/system_prompt.dart';

/// Open-source build: model presets and persona custom params are not
/// overlaid; generation always uses Global settings (plus per-chat sampler
/// overrides applied by ParamPresetResolver).
abstract final class ProParamOverlay {
  static AppSettings apply({
    required AppSettings global,
    String? modelKey,
    SystemPrompt? persona,
  }) =>
      global;
}
