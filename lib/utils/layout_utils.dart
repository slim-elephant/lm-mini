import 'dart:io';

import 'package:flutter/material.dart';

/// True when the viewport should use the iPad-style multi-column layout
/// (master/detail chat, two-column settings sidebar).
bool isTabletClassLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (Platform.isMacOS) {
    // macOS uses the same split-view layout as iPad when the window is wide
    // enough. Default window is 1024×768 so this is true out of the box.
    return size.width >= 760;
  }
  return size.shortestSide >= 600;
}

/// True when the chat home should use master/detail (list | conversation).
///
/// Includes tablets (any orientation) and phones in landscape when the
/// width is wide enough for a comfortable Messages-style split.
bool prefersMasterDetailLayout(BuildContext context) {
  if (isTabletClassLayout(context)) return true;
  return isPhoneLandscapeSplit(context);
}

/// Phone (non-tablet) landscape wide enough for Messages-style split.
/// iPad is never true here — tablets use the normal sticky-header split.
bool isPhoneLandscapeSplit(BuildContext context) {
  if (isTabletClassLayout(context)) return false;
  final size = MediaQuery.sizeOf(context);
  return size.width > size.height && size.width >= 700;
}

/// True when the window is large enough for the 3-column desktop shell.
///
/// Mac ≥ 900px or iPad ≥ 900px. False on iPhone and all Android.
bool prefersDesktopShell(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (Platform.isMacOS) {
    return size.width >= 900;
  }
  if (Platform.isIOS) {
    return size.shortestSide >= 600 && size.width >= 900;
  }
  return false;
}

/// Mac (wide window) or iPad — settings content max-width + dialog modals.
///
/// **False on iPhone and all Android** (including Android tablets), so phone
/// settings stay single-column with bottom sheets.
bool prefersWideSettingsLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (Platform.isMacOS) {
    return size.width >= 760;
  }
  if (Platform.isIOS) {
    return size.shortestSide >= 600;
  }
  return false;
}
