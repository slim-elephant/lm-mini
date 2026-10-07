// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

import '../../models/system_prompt.dart';

/// Sprite generation is part of LM Mini Pro (official app). The open-source
/// build imports and shows sprites but does not generate them.
class ProSpriteGeneration {
  ProSpriteGeneration._();

  static Widget generateButton({
    required BuildContext context,
    required SystemPrompt persona,
  }) =>
      const SizedBox.shrink();
}
