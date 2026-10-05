import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/lm_studio_model.dart';
import '../models/model_load_config.dart';

/// Prompts when [model] is already loaded in LM Studio with params that differ
/// from LM Mini's Model Loading Config.
Future<ModelLoadConflictAction?> showModelLoadParamsConflictDialog(
  BuildContext context, {
  required LMStudioModel model,
  required ModelLoadConfigDiff diff,
}) {
  final l10n = AppLocalizations.of(context);

  return showDialog<ModelLoadConflictAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: Icon(
          Icons.tune_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(l10n.loadParamsConflictTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.loadParamsConflictBody(model.displayName),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.loadParamsConflictTableHeader,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...diff.mismatches.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.loadParamsLmStudio}: ${m.loadedDisplay}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${l10n.loadParamsLmMini}: ${m.desiredDisplay}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loadParamsConflictHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  ModelLoadConflictAction.useExistingLoaded,
                ),
                child: Text(l10n.loadParamsUseExisting),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(
                  ModelLoadConflictAction.reloadWithMiniParams,
                ),
                child: Text(l10n.loadParamsReloadWithMini),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(
                  ModelLoadConflictAction.loadParallelWithMiniParams,
                ),
                child: Text(l10n.loadParamsLoadParallel),
              ),
            ],
          ),
        ],
      );
    },
  );
}
