import 'package:flutter/material.dart';

import '../utils/layout_utils.dart';

/// Shows a bottom sheet on phone/Android, or a centered dialog on Mac/iPad.
///
/// Use for settings pickers and editors. Confirm [showDialog]s can stay as-is.
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  double? dialogMaxWidth,
  double dialogMaxHeightFraction = 0.85,
  BorderRadius? dialogBorderRadius,
}) {
  if (!prefersWideSettingsLayout(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor ??
          (showDragHandle ? null : Colors.transparent),
      shape: shape,
      builder: builder,
    );
  }

  final size = MediaQuery.sizeOf(context);
  final maxW = dialogMaxWidth ?? 600;
  final maxH = size.height * dialogMaxHeightFraction;
  final radius = dialogBorderRadius ?? BorderRadius.circular(24);
  final theme = Theme.of(context);
  final bg = backgroundColor == Colors.transparent
      ? theme.colorScheme.surface
      : (backgroundColor ?? theme.colorScheme.surface);

  return showDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: isDismissible,
    builder: (ctx) {
      return Dialog(
        backgroundColor: bg,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxW,
            maxHeight: maxH,
            minWidth: 320,
          ),
          child: builder(ctx),
        ),
      );
    },
  );
}
