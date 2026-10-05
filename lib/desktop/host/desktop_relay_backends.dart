/// Local backend targets the host may proxy to (Connect parity + builtin sidecar).
class DesktopRelayBackends {
  const DesktopRelayBackends({
    this.lmStudioHost = '127.0.0.1',
    this.lmStudioPort = 1234,
    this.lmStudioApiToken = '',
    this.ollamaHost = '127.0.0.1',
    this.ollamaPort = 11434,
    this.ollamaApiToken = '',
    this.omlxHost = '127.0.0.1',
    this.omlxPort = 8000,
    this.omlxApiToken = '',
    this.janHost = '127.0.0.1',
    this.janPort = 1337,
    this.janApiToken = '',
    this.unslothHost = '127.0.0.1',
    this.unslothPort = 8888,
    this.unslothApiToken = '',
    this.a1111Host = '',
    this.a1111Port = 7860,
    this.comfyUiHost = '',
    this.comfyUiPort = 8188,
    this.kokoroHost = '127.0.0.1',
    this.kokoroPort = 9998,
    this.kokoroEnabled = false,
    this.advertiseBuiltin = true,
    this.advertiseLmStudio = true,
    this.advertiseOllama = false,
    this.advertiseOmlx = false,
    this.advertiseJan = false,
    this.advertiseUnsloth = false,
    this.reachable = const {},
  });

  final String lmStudioHost;
  final int lmStudioPort;
  final String lmStudioApiToken;
  final String ollamaHost;
  final int ollamaPort;
  final String ollamaApiToken;
  final String omlxHost;
  final int omlxPort;
  final String omlxApiToken;
  final String janHost;
  final int janPort;
  final String janApiToken;
  final String unslothHost;
  final int unslothPort;
  final String unslothApiToken;
  final String a1111Host;
  final int a1111Port;
  final String comfyUiHost;
  final int comfyUiPort;
  final String kokoroHost;
  final int kokoroPort;
  final bool kokoroEnabled;
  final bool advertiseBuiltin;
  final bool advertiseLmStudio;
  final bool advertiseOllama;
  final bool advertiseOmlx;
  final bool advertiseJan;
  final bool advertiseUnsloth;

  /// Live reachability keyed by phone backend id (`lmMiniDesktop`, `lmStudio`, …).
  final Map<String, bool> reachable;

  bool get hasA1111 => a1111Host.trim().isNotEmpty;
  bool get hasComfyUi => comfyUiHost.trim().isNotEmpty;

  DesktopRelayBackends copyWith({
    String? lmStudioHost,
    int? lmStudioPort,
    String? lmStudioApiToken,
    String? ollamaHost,
    int? ollamaPort,
    String? ollamaApiToken,
    String? omlxHost,
    int? omlxPort,
    String? omlxApiToken,
    String? janHost,
    int? janPort,
    String? janApiToken,
    String? unslothHost,
    int? unslothPort,
    String? unslothApiToken,
    String? a1111Host,
    int? a1111Port,
    String? comfyUiHost,
    int? comfyUiPort,
    String? kokoroHost,
    int? kokoroPort,
    bool? kokoroEnabled,
    bool? advertiseBuiltin,
    bool? advertiseLmStudio,
    bool? advertiseOllama,
    bool? advertiseOmlx,
    bool? advertiseJan,
    bool? advertiseUnsloth,
    Map<String, bool>? reachable,
  }) {
    return DesktopRelayBackends(
      lmStudioHost: lmStudioHost ?? this.lmStudioHost,
      lmStudioPort: lmStudioPort ?? this.lmStudioPort,
      lmStudioApiToken: lmStudioApiToken ?? this.lmStudioApiToken,
      ollamaHost: ollamaHost ?? this.ollamaHost,
      ollamaPort: ollamaPort ?? this.ollamaPort,
      ollamaApiToken: ollamaApiToken ?? this.ollamaApiToken,
      omlxHost: omlxHost ?? this.omlxHost,
      omlxPort: omlxPort ?? this.omlxPort,
      omlxApiToken: omlxApiToken ?? this.omlxApiToken,
      janHost: janHost ?? this.janHost,
      janPort: janPort ?? this.janPort,
      janApiToken: janApiToken ?? this.janApiToken,
      unslothHost: unslothHost ?? this.unslothHost,
      unslothPort: unslothPort ?? this.unslothPort,
      unslothApiToken: unslothApiToken ?? this.unslothApiToken,
      a1111Host: a1111Host ?? this.a1111Host,
      a1111Port: a1111Port ?? this.a1111Port,
      comfyUiHost: comfyUiHost ?? this.comfyUiHost,
      comfyUiPort: comfyUiPort ?? this.comfyUiPort,
      kokoroHost: kokoroHost ?? this.kokoroHost,
      kokoroPort: kokoroPort ?? this.kokoroPort,
      kokoroEnabled: kokoroEnabled ?? this.kokoroEnabled,
      advertiseBuiltin: advertiseBuiltin ?? this.advertiseBuiltin,
      advertiseLmStudio: advertiseLmStudio ?? this.advertiseLmStudio,
      advertiseOllama: advertiseOllama ?? this.advertiseOllama,
      advertiseOmlx: advertiseOmlx ?? this.advertiseOmlx,
      advertiseJan: advertiseJan ?? this.advertiseJan,
      advertiseUnsloth: advertiseUnsloth ?? this.advertiseUnsloth,
      reachable: reachable ?? this.reachable,
    );
  }
}

/// Delay before retrying a dropped Share-with-phone relay socket.
Duration desktopRelayBackoff(int failedAttempt) {
  const seconds = [1, 2, 4, 8, 15];
  if (failedAttempt <= 0) return Duration(seconds: seconds.first);
  final i = failedAttempt >= seconds.length ? seconds.length - 1 : failedAttempt;
  return Duration(seconds: seconds[i]);
}

/// Whether the current WebSocket should be replaced.
///
/// Sleep/lid-close often leaves a half-open socket (`connected` still true).
/// [force] is for resume-after-suspend. Otherwise only replace when the
/// socket is down or has been silent longer than [staleAfter].
bool desktopRelayShouldReplaceSocket({
  required bool force,
  required bool connected,
  required bool socketOpen,
  DateTime? lastMessageAt,
  required DateTime now,
  Duration staleAfter = const Duration(seconds: 60),
}) {
  if (force) return true;
  if (!connected || !socketOpen) return true;
  final last = lastMessageAt;
  if (last == null) return true;
  return now.difference(last) >= staleAfter;
}
