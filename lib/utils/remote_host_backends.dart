import 'package:flutter/material.dart';

import '../desktop/desktop_platform.dart';
import '../models/app_settings.dart';
import '../services/lm_studio_service.dart';

/// LLM backends a QR / USB host can advertise to the phone.
class RemoteHostBackends {
  RemoteHostBackends._();

  static const lmMiniDesktop = 'lmMiniDesktop';
  static const lmStudio = 'lmStudio';
  static const ollama = 'ollama';
  static const omlx = 'omlx';
  static const jan = 'jan';
  static const unsloth = 'unsloth';
  static const a1111 = 'a1111';
  static const comfyui = 'comfyui';

  static const llmKinds = [
    lmMiniDesktop,
    lmStudio,
    ollama,
    omlx,
    jan,
    unsloth,
  ];

  /// Chat backends Connect always offers, even if an older QR omitted them.
  static const connectChatKinds = [
    lmStudio,
    ollama,
    jan,
    unsloth,
  ];

  /// Image backends Connect / Home proxy by path (`/sdapi/`, ComfyUI routes).
  static const connectImageKinds = [
    a1111,
    comfyui,
  ];

  static String displayName(String kind) {
    switch (kind) {
      case lmMiniDesktop:
        return 'LM Mini Home';
      case lmStudio:
        return 'LM Studio';
      case ollama:
        return 'Ollama';
      case omlx:
        return 'oMLX';
      case 'jan':
        return 'JAN AI';
      case 'unsloth':
        return 'Unsloth';
      case a1111:
        return 'AUTOMATIC1111 / Forge';
      case comfyui:
        return 'ComfyUI';
      case 'onDeviceGguf':
      case 'onDeviceMlx':
        return 'On-device';
      default:
        return kind;
    }
  }

  static IconData iconFor(String kind) {
    switch (kind) {
      case lmMiniDesktop:
        return Icons.home_rounded;
      case lmStudio:
        return Icons.desktop_windows_rounded;
      case ollama:
        return Icons.terminal_rounded;
      case omlx:
        return Icons.memory_rounded;
      case 'jan':
        return Icons.bolt_rounded;
      case 'unsloth':
        return Icons.science_rounded;
      case a1111:
        return Icons.image_rounded;
      case comfyui:
        return Icons.account_tree_rounded;
      default:
        return Icons.computer_rounded;
    }
  }

  static bool isHomeHost(AppSettings settings) =>
      advertisedOf(settings).contains(lmMiniDesktop);

  /// Paired with LM Mini Home (QR still saved), even if a local server is active.
  static bool isPairedHome(AppSettings settings) {
    final url = settings.remoteServerUrl?.trim() ?? '';
    final token = settings.remoteAuthToken?.trim() ?? '';
    if (url.isEmpty || token.isEmpty) return false;
    return isHomeHost(settings);
  }

  static bool isLlmKind(String kind) => llmKinds.contains(kind);

  /// QR advertised backends without the Home sidecar — LM Mini Connect.
  static bool isConnectHost(AppSettings settings) =>
      advertisedOf(settings).isNotEmpty && !isHomeHost(settings);

  static String transportLabel(AppSettings settings) =>
      isHomeHost(settings) ? 'Home' : 'Connect';

  /// Servers-list title while a QR host is paired (`LM Studio via Connect`).
  static String remoteListLabel(String kind, AppSettings settings) {
    if (kind == lmMiniDesktop) return displayName(kind);
    return '${displayName(kind)} via ${transportLabel(settings)}';
  }

  /// Chat backends the phone should offer while remote is on.
  ///
  /// Connect always offers LM Studio, Ollama, JAN AI, and Unsloth (plus oMLX
  /// when the QR advertised it). Home hides unreachable extras. Local LAN
  /// servers are hidden separately in Settings.
  static List<String> visibleOf(
    AppSettings settings, {
    required bool hostStatusOk,
    required bool Function(String kind) reachable,
  }) {
    final advertised = advertisedOf(settings);
    if (isConnectHost(settings)) {
      return [
        for (final kind in connectChatKinds) kind,
        if (advertised.contains(omlx)) omlx,
      ];
    }
    if (!hostStatusOk) {
      return [for (final kind in advertised) if (kind == lmMiniDesktop) kind];
    }
    return [
      for (final kind in advertised)
        if (kind == lmMiniDesktop || reachable(kind)) kind,
    ];
  }

  /// Backend to probe when turning the relay on or testing from Remote Access.
  /// If Home is paired, always hit Home itself — not the phone's local LM Studio.
  static String probeKind(AppSettings settings) {
    if (isPairedHome(settings)) return lmMiniDesktop;
    final kind = settings.activeProviderKind;
    if (isLlmKind(kind) && kind != lmStudio) return kind;
    return lmStudio;
  }

  static bool usesLmStudioHttp(String kind) =>
      kind == lmStudio || kind == lmMiniDesktop;

  /// Backends listed on the last scanned QR. Empty means legacy Connect
  /// (LM Studio only).
  static List<String> advertisedOf(AppSettings settings) {
    final raw = settings.remoteBackends
        .where((b) => b.trim().isNotEmpty)
        .map((b) => b.trim())
        .toList();
    if (raw.isEmpty) return const [lmStudio];
    return [
      for (final kind in llmKinds)
        if (raw.contains(kind)) kind,
    ];
  }

  static String connectedViaLabel(AppSettings settings) {
    if (!settings.isRemoteActive) return 'Using local server';
    return 'Connected via ${displayName(settings.activeProviderKind)}';
  }

  static String connectedToast(String kind) =>
      'Connected to ${displayName(kind)}';

  /// Title for the Home reachability card on the phone.
  static String homeLocationTitle(String? platform) {
    switch (platform) {
      case 'windows':
        return 'LM Mini Home on your Windows PC';
      case 'linux':
        return 'LM Mini Home on your Linux PC';
      default:
        return 'LM Mini Home on your Mac';
    }
  }

  /// Server-list subtitle for a QR / USB host backend.
  ///
  /// On the phone this is a remote computer — never "this Mac".
  static String remoteStatusSubtitle({
    required bool reachable,
    bool? onThisDevice,
  }) {
    final local = onThisDevice ?? DesktopPlatform.isDesktop;
    if (local) {
      final here = DesktopPlatform.thisMachine;
      return reachable ? 'On $here' : 'Not reachable on $here';
    }
    return reachable ? 'On your computer' : "Can't reach your computer";
  }

  /// Copy relay auth + backend routing onto any [LMStudioService] instance.
  static void configureLmStudioClient(
    LMStudioService client,
    AppSettings settings, {
    String? backend,
  }) {
    final remote = settings.isRemoteActive &&
        (settings.remoteAuthToken?.isNotEmpty ?? false);
    client.remoteAuthToken = remote ? settings.remoteAuthToken : null;
    // Relay headers are only attached to requests under this URL.
    client.remoteRelayBaseUrl = remote ? settings.remoteServerUrl : null;
    if (!remote) {
      client.remoteBackend = null;
      client.customHeaders = settings.effectiveExtraHeaders;
      return;
    }
    final kind = backend ?? settings.activeProviderKind;
    client.remoteBackend = usesLmStudioHttp(kind) ? kind : lmStudio;
    client.customHeaders = settings.effectiveExtraHeaders;
  }
}
