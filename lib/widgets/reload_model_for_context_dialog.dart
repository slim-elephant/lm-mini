import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/model_load_config.dart';

/// Asks to unload & reload the LM Studio instance after Context Length changes.
Future<bool?> showReloadModelForContextDialog(
  BuildContext context, {
  required String modelName,
  required int loadedContextLength,
  required int desiredContextLength,
}) {
  final l10n = AppLocalizations.of(context);
  final loaded = ModelLoadConfigHelper.formatTokenCount(loadedContextLength);
  final desired = ModelLoadConfigHelper.formatTokenCount(desiredContextLength);

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: Icon(
          Icons.memory_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(l10n.reloadModelForContextTitle),
        content: Text(
          l10n.reloadModelForContextBody(modelName, loaded, desired),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.reloadModelForContextLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.reloadModelForContextNow),
          ),
        ],
      );
    },
  );
}
