import 'dart:io';

import 'package:flutter/material.dart';

/// Platform-aware subtitles for the On-Device engine picker (fllama / MLX).
class OnDeviceEngineLabels {
  OnDeviceEngineLabels._();

  /// Server-list subtitle when on-device is listed but not the active engine.
  static String get serverIdleSubtitle {
    if (Platform.isMacOS) return 'Works offline on this Mac';
    if (Platform.isWindows) return 'Works offline on this PC';
    if (Platform.isLinux) return 'Works offline on this computer';
    return 'Works offline — no computer needed';
  }

  static IconData get serverListIcon {
    if (Platform.isMacOS) return Icons.laptop_mac_rounded;
    if (Platform.isWindows || Platform.isLinux) {
      return Icons.computer_rounded;
    }
    return Icons.phone_iphone_rounded;
  }

  static String get fllamaSubtitle {
    if (Platform.isMacOS || Platform.isIOS) {
      return 'Cross-platform • GGUF';
    }
    return 'Cross-platform';
  }

  static String mlxSubtitle({required bool supported}) {
    if (supported) {
      return 'Apple Silicon • faster';
    }
    return 'Requires Apple Silicon';
  }
}
