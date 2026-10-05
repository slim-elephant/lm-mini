import 'package:flutter/widgets.dart';

/// Reverse ListView: offset 0 is the latest messages (visual bottom).
const double kChatPinnedToLatestEpsilon = 0.5;

/// Distance from offset 0 at which we treat the user as back on the latest
/// messages and resume following.
const double kChatResumeFollowPixels = 50;

bool isPinnedToLatest(double pixels) =>
    pixels.abs() <= kChatPinnedToLatestEpsilon;

/// True when the outer chat list — not a nested code block / thinking pane —
/// started a pointer drag. Android overscroll and child scrollables must not
/// count, or follow-new-replies stops for the rest of the stream.
bool isUserDragOnChatList(ScrollNotification notification) {
  if (notification.depth != 0) return false;
  if (notification is ScrollStartNotification) {
    return notification.dragDetails != null;
  }
  if (notification is ScrollUpdateNotification) {
    return notification.dragDetails != null;
  }
  return false;
}

/// Pin back to offset 0 when content growth (streaming markdown) corrects the
/// reverse list away from the latest tokens, unless the user scrolled away.
bool shouldRepinToLatest({
  required bool autoScrollEnabled,
  required bool userScrolled,
  required double pixels,
}) {
  return autoScrollEnabled && !userScrolled && !isPinnedToLatest(pixels);
}
