import 'dart:async';
import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';

/// Parsed QR code payload from LM Mini Connect companion app.
class RemoteConnectionInfo {
  /// Active relay URL the app should use (always set).
  /// On v≥4 QRs we prefer the new tunnel URL; on older QRs this is whatever
  /// `url` Connect provided.
  final String url;

  /// Legacy Cloud Run URL (only set when the QR includes both endpoints).
  /// Kept around so we can warn the user that they're on the deprecated relay.
  final String? legacyUrl;

  final String token;
  final int version;
  final String? encryptionKey;

  /// Connect app semver from QR v5+ (e.g. `1.5.0`).
  final String? connectVersion;

  /// Minimum LM Mini app version required by this Connect build (QR v5+).
  final String? minAppVersion;

  /// Backends the host can route to (`lmStudio`, `ollama`, `omlx`, `lmMiniDesktop`).
  /// Empty on old QRs (LM Studio only).
  final List<String> backends;

  /// Host is serving Kokoro TTS over the relay (`/tts/*`).
  final bool kokoroReady;

  /// Live reachability from `/lm-mini/host-status`.
  final Map<String, bool> reachable;

  /// Host OS from QR / host-status (`macos`, `windows`, `linux`).
  final String? hostPlatform;

  /// True when `/lm-mini/host-status` returned 200 for this object.
  final bool hostStatusOk;

  /// Relay / host error when [hostStatusOk] is false.
  final String? hostStatusError;

  RemoteConnectionInfo({
    required this.url,
    required this.token,
    required this.version,
    this.legacyUrl,
    this.encryptionKey,
    this.connectVersion,
    this.minAppVersion,
    this.backends = const [],
    this.kokoroReady = false,
    this.reachable = const {},
    this.hostPlatform,
    this.hostStatusOk = false,
    this.hostStatusError,
  });

  /// True when [url] is the legacy Cloud Run host (deprecated 2026-05-10).
  bool get isLegacyRelay {
    final lower = url.toLowerCase();
    return lower.contains('lm-mini-relay-') &&
        RegExp(r'run\.app/').hasMatch(lower);
  }

  /// Connect builds before v5 only route to LM Studio.
  bool get supportsMultiBackend => version >= 5;

  bool supportsBackend(String kind) {
    if (backends.isEmpty) {
      // Old Connect: LM Studio only.
      return kind == 'lmStudio';
    }
    return backends.contains(kind);
  }

  factory RemoteConnectionInfo.fromJson(Map<String, dynamic> json) {
    final urlRaw = json['url'] as String?;
    final tunnelUrlRaw = json['tunnelUrl'] as String?; // new in QR v4
    final token = json['token'] as String?;
    final version = json['v'] as int? ?? 1;
    final encryptionKey = json['ek'] as String?;
    final connectVersion = json['connectVersion'] as String?;
    final minAppVersion = json['minAppVersion'] as String?;
    final backendsRaw = json['backends'];
    final backends = <String>[];
    if (backendsRaw is List) {
      for (final b in backendsRaw) {
        if (b is String && b.trim().isNotEmpty) backends.add(b.trim());
      }
    }

    if (token == null || token.isEmpty) {
      throw const FormatException('Missing or empty "token" in QR payload');
    }

    // Prefer the tunnel URL when present (new Connect builds always set it).
    // Falls back to `url` for older Connect builds (v≤3).
    final preferred = (tunnelUrlRaw != null && tunnelUrlRaw.isNotEmpty)
        ? tunnelUrlRaw
        : urlRaw;
    if (preferred == null || preferred.isEmpty) {
      throw const FormatException('Missing or empty "url" in QR payload');
    }

    // Validate URL format
    final uri = Uri.parse(preferred);
    if (!uri.hasScheme || (!uri.isScheme('https') && !uri.isScheme('http'))) {
      throw const FormatException('URL must use http or https scheme');
    }

    // Track the legacy URL only if it differs from the chosen one.
    final legacy = (urlRaw != null && urlRaw != preferred) ? urlRaw : null;

    return RemoteConnectionInfo(
      url: preferred,
      legacyUrl: legacy,
      token: token,
      version: version,
      encryptionKey: encryptionKey,
      connectVersion: connectVersion,
      minAppVersion: minAppVersion,
      backends: backends,
      kokoroReady: json['kokoroReady'] == true,
      hostPlatform: json['platform'] as String?,
    );
  }
}

/// Compatibility helpers for Connect ↔ app version gating.
class ConnectCompatibility {
  /// Phone needs this Connect version (or newer) for Ollama/oMLX remote.
  static const minConnectVersionForMultiBackend = '1.5.0';

  static int compareSemver(String a, String b) {
    List<int> parts(String v) {
      final cleaned = v.split('+').first.split('-').first;
      return cleaned
          .split('.')
          .map((p) => int.tryParse(p) ?? 0)
          .toList();
    }

    final pa = parts(a);
    final pb = parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final ai = i < pa.length ? pa[i] : 0;
      final bi = i < pb.length ? pb[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }
    return 0;
  }

  /// Whether [connectVersion] is too old for multi-backend remote.
  static bool connectNeedsUpgrade(String? connectVersion) {
    if (connectVersion == null || connectVersion.isEmpty) return true;
    return compareSemver(connectVersion, minConnectVersionForMultiBackend) < 0;
  }

  /// Whether the phone app is older than Connect's [minAppVersion].
  static Future<bool> appNeedsUpgrade(String? minAppVersion) async {
    if (minAppVersion == null || minAppVersion.isEmpty) return false;
    final pkg = await PackageInfo.fromPlatform();
    return compareSemver(pkg.version, minAppVersion) < 0;
  }
}

class RemoteConnectionStatus {
  final bool isConnected;
  final String? error;
  final int? latencyMs;

  RemoteConnectionStatus({
    required this.isConnected,
    this.error,
    this.latencyMs,
  });
}

/// Pure relay / host HTTP helpers shared by the Remote Access client and the
/// public code paths (Home sync host, model probes).
abstract final class RemoteRelayHttp {
  /// Pairing link from LM Mini Home, e.g.
  /// `https://relay.lmmini.com/s/{session}#t={token}&ek={key}&b=lmMiniDesktop,lmStudio`
  /// A path-only URL (no token) uses the session id as a fallback token.
  static RemoteConnectionInfo? parseRelayUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
      return null;
    }
    final match = RegExp(r'/s/([A-Za-z0-9_-]+)').firstMatch(uri.path);
    if (match == null) return null;
    final sessionId = match.group(1)!;
    if (sessionId.isEmpty) return null;

    final params = <String, String>{...uri.queryParameters};
    if (uri.fragment.isNotEmpty) {
      params.addAll(Uri.splitQueryString(uri.fragment));
    }

    final token = (params['t'] ?? params['token'] ?? '').trim();
    final resolvedToken = token.isNotEmpty ? token : sessionId;
    final host = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    final url = '${uri.scheme}://$host/s/$sessionId';

    final backends = <String>[];
    final backendsRaw = params['b'] ?? params['backends'] ?? '';
    for (final part in backendsRaw.split(',')) {
      final kind = part.trim();
      if (kind.isNotEmpty) backends.add(kind);
    }

    final ek = (params['ek'] ?? '').trim();
    return RemoteConnectionInfo(
      url: url,
      token: resolvedToken,
      version: 5,
      encryptionKey: ek.isEmpty ? null : ek,
      backends: backends,
      kokoroReady: params['kokoro'] == '1' || params['kokoro'] == 'true',
      hostPlatform: params['platform'] ?? params['os'],
    );
  }

  /// Path used to probe a host. Desktop LM Mini answers `/lm-mini/host-status`
  /// immediately (no sidecar boot). LM Studio uses V1 `/api/v1/models`.
  static String probePathForBackend(String backend) {
    return switch (backend) {
      'ollama' => '/api/tags',
      'omlx' => '/v1/models',
      'jan' => '/v1/models',
      'unsloth' => '/v1/models',
      'lmMiniDesktop' => '/lm-mini/host-status',
      _ => '/api/v1/models',
    };
  }

  static String friendlyConnectionError(Object e) {
    if (e is TimeoutException) {
      return 'The computer did not answer in time. On the Mac, wait until '
          'Share with phone shows Connected, then scan again.';
    }
    final text = e.toString();
    if (text.contains('TimeoutException') || text.contains('timed out')) {
      return 'The computer did not answer in time. On the Mac, wait until '
          'Share with phone shows Connected, then scan again.';
    }
    return text;
  }

  /// Human-readable error from a relay / host HTTP body.
  static String httpErrorMessage(int status, String body) {
    String? fromJson;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map && err['message'] is String) {
          fromJson = (err['message'] as String).trim();
        } else if (err is String && err.trim().isNotEmpty) {
          fromJson = err.trim();
        } else if (decoded['message'] is String) {
          fromJson = (decoded['message'] as String).trim();
        }
      }
    } catch (_) {}
    var message = (fromJson == null || fromJson.isEmpty)
        ? 'Server returned $status'
        : fromJson;
    message = message.replaceAll('LM Mini Connect', 'LM Mini Home');
    message = message.replaceAll('Open LM Mini Home on your computer.',
        'Open Share with phone in LM Mini Home and wait until it says Connected.');
    if (status == 502 || status == 503) {
      if (!message.toLowerCase().contains('share with phone') &&
          !message.toLowerCase().contains('not connected')) {
        return 'Can\'t reach your Mac ($status). Open Share with phone in '
            'LM Mini Home and wait until it says Connected.';
      }
    }
    return message;
  }
}
