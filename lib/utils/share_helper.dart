import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// iPad/macOS share sheets require a non-zero [sharePositionOrigin] for popovers.
Rect shareOriginFor(BuildContext anchorContext) {
  final box = anchorContext.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return const Rect.fromLTWH(0, 0, 1, 1);
}

Future<void> shareTextFromContext(
  BuildContext anchorContext,
  String text, {
  String? subject,
}) async {
  await Share.share(
    text,
    subject: subject,
    sharePositionOrigin: shareOriginFor(anchorContext),
  );
}

Future<void> shareFileFromContext(
    BuildContext anchorContext, String path) async {
  await Share.shareXFiles(
    [XFile(path)],
    sharePositionOrigin: shareOriginFor(anchorContext),
  );
}
