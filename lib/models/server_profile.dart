import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../utils/on_device_engine_labels.dart';

/// Unified configured server / provider entry shown in Settings → Servers.
enum ServerProfileKind {
  onDevice,
  lmStudio,
  /// LM Studio over USB cable (iOS → Mac via LM Mini Connect).
  usb,
  cloud,
}

class ServerProfile {
  static const String onDeviceId = 'on_device';
  static const String usbId = 'lm_studio_usb';

  final String id;
  final String name;
  final ServerProfileKind kind;

  /// Set when [kind] is [ServerProfileKind.cloud].
  final CloudApiType? cloudType;

  final String? baseUrl;
  final String? apiKey;
  final Map<String, String>? customHeaders;
  final bool customHeadersEnabled;
  final DateTime lastUsedAt;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.kind,
    this.cloudType,
    this.baseUrl,
    this.apiKey,
    this.customHeaders,
    this.customHeadersEnabled = false,
    required this.lastUsedAt,
  });

  bool get isOnDevice => kind == ServerProfileKind.onDevice;
  bool get isUsb => kind == ServerProfileKind.usb;
  bool get isDeletable => !isOnDevice;
  bool get supportsHeaders =>
      kind == ServerProfileKind.lmStudio || kind == ServerProfileKind.cloud;

  bool get isPremium {
    if (kind == ServerProfileKind.cloud) {
      return cloudType?.isPremium ?? true;
    }
    return false;
  }

  String get typeLabel {
    switch (kind) {
      case ServerProfileKind.onDevice:
        return 'Run AI on this device';
      case ServerProfileKind.lmStudio:
        return 'LM Studio';
      case ServerProfileKind.usb:
        return 'LM Studio via USB';
      case ServerProfileKind.cloud:
        return cloudType?.displayName ?? 'Cloud';
    }
  }

  /// User-facing title (keeps custom names for other servers).
  String get displayTitle =>
      (isOnDevice || isUsb) ? typeLabel : name;

  String get subtitle {
    switch (kind) {
      case ServerProfileKind.onDevice:
        return OnDeviceEngineLabels.serverIdleSubtitle;
      case ServerProfileKind.usb:
        return 'Cable to Mac — no Wi‑Fi needed';
      case ServerProfileKind.lmStudio:
      case ServerProfileKind.cloud:
        final url = baseUrl?.trim();
        if (url != null && url.isNotEmpty) return url;
        if (kind == ServerProfileKind.cloud && cloudType != null) {
          return cloudType!.displayName;
        }
        return typeLabel;
    }
  }

  ServerProfile copyWith({
    String? name,
    ServerProfileKind? kind,
    CloudApiType? cloudType,
    Object? baseUrl = _unset,
    Object? apiKey = _unset,
    Object? customHeaders = _unset,
    bool? customHeadersEnabled,
    DateTime? lastUsedAt,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      cloudType: cloudType ?? this.cloudType,
      baseUrl: identical(baseUrl, _unset) ? this.baseUrl : baseUrl as String?,
      apiKey: identical(apiKey, _unset) ? this.apiKey : apiKey as String?,
      customHeaders: identical(customHeaders, _unset)
          ? this.customHeaders
          : customHeaders as Map<String, String>?,
      customHeadersEnabled:
          customHeadersEnabled ?? this.customHeadersEnabled,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'cloudType': cloudType?.name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'customHeaders': customHeaders,
        'customHeadersEnabled': customHeadersEnabled,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  factory ServerProfile.fromMap(Map<String, dynamic> map) {
    final kindName = map['kind'] as String? ?? 'lmStudio';
    final kind = ServerProfileKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => ServerProfileKind.lmStudio,
    );
    CloudApiType? cloudType;
    final cloudName = map['cloudType'] as String?;
    if (cloudName != null) {
      cloudType = CloudApiType.values.firstWhere(
        (t) => t.name == cloudName,
        orElse: () => CloudApiType.openaiCompatible,
      );
    }
    Map<String, String>? headers;
    final rawHeaders = map['customHeaders'];
    if (rawHeaders is Map) {
      headers = rawHeaders.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    return ServerProfile(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Server',
      kind: kind,
      cloudType: cloudType,
      baseUrl: map['baseUrl'] as String?,
      apiKey: map['apiKey'] as String?,
      customHeaders: headers,
      customHeadersEnabled: map['customHeadersEnabled'] as bool? ?? false,
      lastUsedAt: DateTime.tryParse(map['lastUsedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static ServerProfile onDevice({DateTime? lastUsedAt}) {
    return ServerProfile(
      id: onDeviceId,
      name: 'Run AI on this device',
      kind: ServerProfileKind.onDevice,
      lastUsedAt: lastUsedAt ?? DateTime.now(),
    );
  }

  static ServerProfile usb({DateTime? lastUsedAt}) {
    return ServerProfile(
      id: usbId,
      name: 'LM Studio via USB',
      kind: ServerProfileKind.usb,
      lastUsedAt: lastUsedAt ?? DateTime.now(),
    );
  }
}

const Object _unset = Object();
