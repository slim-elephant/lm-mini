import 'package:flutter/material.dart';

import '../../models/pickable_model.dart';

/// Nerdy ⓘ bottom sheet for a [PickableModel].
Future<void> showModelDetailsSheet(
  BuildContext context,
  PickableModel model,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final details = model.details;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scroll) {
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              Text(
                model.displayName,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                model.id,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
              if (model.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  model.subtitle!,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              if (details.isEmpty)
                Text(
                  'No extra details for this model.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                ...details.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              row.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.value,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          );
        },
      );
    },
  );
}
