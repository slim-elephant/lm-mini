import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

enum DiscoveredServerKind { lmStudio, ollama, unsloth }

class DiscoveredLmStudioServer {
  final String host;
  final int port;
  final DiscoveredServerKind kind;
  final bool requiresApiKey;
  final String? note;
  final bool thisMachine;

  /// Reverse-DNS / mDNS name when the resolver has one (e.g. `studio.local`).
  final String? hostname;

  const DiscoveredLmStudioServer({
    required this.host,
    required this.port,
    this.kind = DiscoveredServerKind.lmStudio,
    this.requiresApiKey = false,
    this.note,
    this.thisMachine = false,
    this.hostname,
  });

  String get url => 'http://$host:$port';

  String get kindLabel => switch (kind) {
        DiscoveredServerKind.ollama => 'Ollama',
        DiscoveredServerKind.unsloth => 'Unsloth',
        DiscoveredServerKind.lmStudio => 'LM Studio',
      };

  String get locationLabel => thisMachine ? 'This Mac' : kindLabel;

  bool get hasHostname {
    final name = hostname?.trim() ?? '';
    return name.isNotEmpty && name.toLowerCase() != host.toLowerCase();
  }

  /// List row title: hostname when we have one, otherwise the URL.
  String get listTitle => hasHostname ? hostname!.trim() : url;

  /// List row subtitle: kind plus IP:port when the title is a hostname.
  String get listSubtitle {
    final bits = <String>[
      if (thisMachine) 'This Mac',
      requiresApiKey ? 'Needs API key' : kindLabel,
      if (hasHostname) url,
    ];
    return bits.join(' · ');
  }

  DiscoveredLmStudioServer copyWith({String? hostname}) {
    return DiscoveredLmStudioServer(
      host: host,
      port: port,
      kind: kind,
      requiresApiKey: requiresApiKey,
      note: note,
      thisMachine: thisMachine,
      hostname: hostname ?? this.hostname,
    );
  }
}

/// Best-effort LAN scanner for local LLM servers (LM Studio, llama.cpp, Ollama, Unsloth).
///
/// This Mac is probed first (loopback + the machine's own LAN IP) so Home can
/// find LM Studio / llama-server even when they share this computer's IP.
/// Nearby /24 hosts are scanned afterwards.
class LmStudioDiscoveryService {
  LmStudioDiscoveryService._();
  static final LmStudioDiscoveryService instance = LmStudioDiscoveryService._();

  static const _hostnameChannel = MethodChannel('lm_mini/lan_hostname');

  Future<List<DiscoveredLmStudioServer>> scanLocalNetwork({
    List<int>? preferredPorts,
    Duration socketTimeout = const Duration(milliseconds: 220),
    int concurrency = 48,
    void Function(List<DiscoveredLmStudioServer> soFar)? onFound,
  }) async {
    final ports = <int>{
      if (preferredPorts != null) ...preferredPorts,
      1234, // LM Studio
      11434, // Ollama
      8888, // Unsloth Studio
      8080, // llama.cpp / OpenAI-compatible
      8000, // oMLX
      8741, // LM Mini Home bundled llama-server
    }.where((p) => p > 0 && p <= 65535).toList()
      ..sort();

    final hits = <String, DiscoveredLmStudioServer>{};
    final ptrJobs = <String, Future<void>>{};

    List<DiscoveredLmStudioServer> snapshot() => _sortHits(hits.values);

    void emit() => onFound?.call(snapshot());

    void applyHostname(String ip, String? name) {
      if (name == null || name.isEmpty) return;
      var changed = false;
      for (final entry in hits.entries.toList()) {
        if (entry.value.host != ip || entry.value.hostname == name) continue;
        hits[entry.key] = entry.value.copyWith(hostname: name);
        changed = true;
      }
      if (changed) emit();
    }

    void resolveHostname(
      String host, {
      required bool thisMachine,
    }) {
      ptrJobs[host] ??= () async {
        final name = await _lookupHostname(host, thisMachine: thisMachine);
        applyHostname(host, name);
      }();
    }

    Future<void> probeHost(
      String host, {
      required bool thisMachine,
      Duration? timeout,
    }) async {
      for (final port in ports) {
        final candidate = await _probeHostPort(
          host: host,
          port: port,
          socketTimeout: timeout ?? socketTimeout,
          thisMachine: thisMachine,
        );
        if (candidate != null) {
          hits[candidate.url] = candidate;
          resolveHostname(host, thisMachine: thisMachine);
        }
      }
    }

    final local = await _findPrivateIpv4();
    final onPhone = Platform.isIOS || Platform.isAndroid;
    final probeLoopback = !onPhone || await _shouldProbeLoopback();

    // Desktop (and iOS/Android simulators) can reach LM Studio on localhost.
    // A physical phone's loopback is the phone itself — skip it there.
    if (probeLoopback) {
      await probeHost(
        '127.0.0.1',
        thisMachine: true,
        timeout: const Duration(milliseconds: 700),
      );
      emit();
    }

    if (local != null && !onPhone) {
      await probeHost(
        local,
        thisMachine: true,
        timeout: const Duration(milliseconds: 700),
      );
      emit();
    }

    final scanLan = Platform.isIOS ||
        Platform.isAndroid ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux;

    if (local != null && scanLan) {
      final octets = local.split('.');
      if (octets.length == 4) {
        final prefix = '${octets[0]}.${octets[1]}.${octets[2]}';
        var hostSuffix = 1;

        Future<void> worker() async {
          while (true) {
            final current = hostSuffix++;
            if (current > 254) break;

            final host = '$prefix.$current';
            if (host == local) continue;

            await probeHost(host, thisMachine: false);
          }
        }

        final workers = List.generate(
          concurrency.clamp(1, 128),
          (_) => worker(),
        );
        await Future.wait(workers);
        emit();
      }
    }

    if (ptrJobs.isNotEmpty) {
      await Future.wait(ptrJobs.values);
    }

    return snapshot();
  }

  /// Reverse PTR (and Apple mDNS `.local`) for a numeric IPv4 host.
  ///
  /// Home routers almost never have unicast PTRs. On iOS we ask dns_sd
  /// (Bonjour) first; elsewhere we use `getnameinfo` with a longer timeout.
  Future<String?> _lookupHostname(
    String host, {
    required bool thisMachine,
  }) async {
    if (thisMachine) {
      try {
        final local = Platform.localHostname.trim();
        final cleaned = sanitizePtrName(host, local);
        if (cleaned != null) return cleaned;
      } catch (_) {}
    }

    if (Platform.isIOS) {
      try {
        final name = await _hostnameChannel
            .invokeMethod<String>('reverseIpv4', host)
            .timeout(const Duration(seconds: 3));
        final cleaned = sanitizePtrName(host, name);
        if (cleaned != null) return cleaned;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LMStudioDiscovery: iOS mDNS PTR failed for $host: $e');
        }
      }
    }

    try {
      final reversed = await InternetAddress(host)
          .reverse()
          .timeout(const Duration(seconds: 2));
      return sanitizePtrName(host, reversed.host);
    } catch (_) {
      return null;
    }
  }

  /// iOS/Android simulators share the host's network and can use 127.0.0.1.
  Future<bool> _shouldProbeLoopback() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        return !(await plugin.iosInfo).isPhysicalDevice;
      }
      if (Platform.isAndroid) {
        return !(await plugin.androidInfo).isPhysicalDevice;
      }
    } catch (_) {}
    return false;
  }

  @visibleForTesting
  static String? sanitizePtrName(String ip, String? ptr) {
    if (ptr == null) return null;
    var name = ptr.trim();
    if (name.endsWith('.')) {
      name = name.substring(0, name.length - 1);
    }
    if (name.isEmpty) return null;
    final lower = name.toLowerCase();
    if (lower == ip.toLowerCase()) return null;
    if (lower.endsWith('.in-addr.arpa') || lower.endsWith('.ip6.arpa')) {
      return null;
    }
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(name)) return null;
    return name;
  }

  @visibleForTesting
  static bool isLoopbackHost(String host) {
    final h = host.trim().toLowerCase();
    return h == '127.0.0.1' || h == 'localhost' || h == '::1' || h == '[::1]';
  }

  static List<DiscoveredLmStudioServer> _sortHits(
    Iterable<DiscoveredLmStudioServer> values,
  ) {
    final out = values.toList()
      ..sort((a, b) {
        if (a.thisMachine != b.thisMachine) return a.thisMachine ? -1 : 1;
        final aLocal = isLoopbackHost(a.host);
        final bLocal = isLoopbackHost(b.host);
        if (aLocal != bLocal) return aLocal ? -1 : 1;
        final hostCmp = a.host.compareTo(b.host);
        if (hostCmp != 0) return hostCmp;
        return a.port.compareTo(b.port);
      });
    return out;
  }

  Future<DiscoveredLmStudioServer?> _probeHostPort({
    required String host,
    required int port,
    required Duration socketTimeout,
    required bool thisMachine,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: socketTimeout);
      socket.destroy();
    } catch (_) {
      try {
        socket?.destroy();
      } catch (_) {}
      return null;
    }

    final httpTimeout =
        thisMachine ? const Duration(seconds: 4) : const Duration(seconds: 2);

    // Unsloth answers /api/health without a key. Check that before the
    // OpenAI models path, which Unsloth also serves and would look like
    // LM Studio.
    final unsloth = await _probeUnsloth(
      host: host,
      port: port,
      timeout: httpTimeout,
      thisMachine: thisMachine,
    );
    if (unsloth != null) return unsloth;

    // LM Studio's native models API, then OpenAI-compatible / llama.cpp,
    // then Ollama tags. Do not abort on a 404 from the first path.
    final native = await _probeHttp(
      host: host,
      port: port,
      path: '/api/v1/models',
      timeout: httpTimeout,
    );
    if (native != null) {
      return DiscoveredLmStudioServer(
        host: host,
        port: port,
        kind: DiscoveredServerKind.lmStudio,
        requiresApiKey: native.needsKey,
        thisMachine: thisMachine,
      );
    }

    final openAi = await _probeHttp(
      host: host,
      port: port,
      path: '/v1/models',
      timeout: httpTimeout,
    );
    if (openAi != null) {
      return DiscoveredLmStudioServer(
        host: host,
        port: port,
        kind: port == 11434
            ? DiscoveredServerKind.ollama
            : DiscoveredServerKind.lmStudio,
        requiresApiKey: openAi.needsKey,
        thisMachine: thisMachine,
      );
    }

    final ollama = await _probeHttp(
      host: host,
      port: port,
      path: '/api/tags',
      timeout: httpTimeout,
    );
    if (ollama != null) {
      return DiscoveredLmStudioServer(
        host: host,
        port: port,
        kind: DiscoveredServerKind.ollama,
        requiresApiKey: ollama.needsKey,
        thisMachine: thisMachine,
      );
    }
    return null;
  }

  Future<DiscoveredLmStudioServer?> _probeUnsloth({
    required String host,
    required int port,
    required Duration timeout,
    required bool thisMachine,
  }) async {
    final health = await _probeJson(
      host: host,
      port: port,
      path: '/api/health',
      timeout: timeout,
    );
    if (!isUnslothHealthBody(health)) return null;

    final models = await _probeHttp(
      host: host,
      port: port,
      path: '/v1/models',
      timeout: timeout,
    );
    return DiscoveredLmStudioServer(
      host: host,
      port: port,
      kind: DiscoveredServerKind.unsloth,
      requiresApiKey: models?.needsKey ?? false,
      thisMachine: thisMachine,
    );
  }

  /// `/api/health` from Unsloth Studio. Other local servers do not use this name.
  @visibleForTesting
  static bool isUnslothHealthBody(Object? body) {
    if (body is! Map) return false;
    final service = body['service']?.toString().toLowerCase() ?? '';
    return service.contains('unsloth');
  }

  Future<Map<String, dynamic>?> _probeJson({
    required String host,
    required int port,
    required String path,
    required Duration timeout,
  }) async {
    try {
      final response =
          await http.get(Uri.parse('http://$host:$port$path')).timeout(timeout);
      if (response.statusCode != 200) return null;
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
    } catch (_) {}
    return null;
  }

  Future<({bool needsKey})?> _probeHttp({
    required String host,
    required int port,
    required String path,
    required Duration timeout,
  }) async {
    try {
      final response =
          await http.get(Uri.parse('http://$host:$port$path')).timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        return (needsKey: true);
      }
      if (response.statusCode != 200) return null;
      final body = json.decode(response.body);
      if (body is Map &&
          (body.containsKey('models') || body.containsKey('data'))) {
        return (needsKey: false);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _findPrivateIpv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final ranked = <({int score, String name, String ip})>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!_isPrivateIpv4(ip)) continue;
          ranked.add((
            score: interfaceScanScore(iface.name),
            name: iface.name,
            ip: ip,
          ));
        }
      }
      ranked.sort((a, b) => a.score.compareTo(b.score));
      if (ranked.isEmpty) return null;
      final best = ranked.first;
      if (kDebugMode) {
        debugPrint(
            'LMStudioDiscovery: using interface ${best.name} -> ${best.ip}'
            '${ranked.length > 1 ? ' (skipped ${ranked.length - 1} other private IPs)' : ''}');
      }
      return best.ip;
    } catch (_) {}
    return null;
  }

  /// Lower is better. Prefer Wi‑Fi (`en0` / `wlan0`) over VPN `utun` / `tun`
  /// so a phone with WireGuard does not scan the VPN /24.
  @visibleForTesting
  static int interfaceScanScore(String name) {
    final n = name.toLowerCase();
    if (n == 'en0' || n == 'wlan0' || n == 'wlan1' || n.startsWith('wifi')) {
      return 0;
    }
    if (n.startsWith('en')) return 1;
    if (n.startsWith('eth') || n.startsWith('wlan')) return 2;
    if (n.startsWith('utun') ||
        n.startsWith('tun') ||
        n.startsWith('wg') ||
        n.startsWith('ipsec') ||
        n.startsWith('ppp') ||
        n.startsWith('awdl') ||
        n.startsWith('llw') ||
        n.contains('vpn')) {
      return 9;
    }
    return 5;
  }

  bool _isPrivateIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    if (a == null || b == null) return false;

    if (a == 10) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 192 && b == 168) return true;
    return false;
  }
}
