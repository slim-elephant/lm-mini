import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../desktop_platform.dart';
import '../runtime/desktop_runtime_manager.dart';
import '../../models/lm_studio_model.dart';
import '../../services/home_sync_service.dart';
import 'desktop_relay_client.dart';

/// Shared localhost HTTP proxy used by relay and USB host (Connect parity).
class DesktopRequestProxy {
  DesktopRequestProxy._();
  static final DesktopRequestProxy instance = DesktopRequestProxy._();

  /// Phone pairing / health probes that must not wait on sidecar boot.
  static const hostStatusPath = '/lm-mini/host-status';
  static const syncPath = HomeSyncService.syncPath;

  /// Resolve a target from path + `X-LM-Mini-Backend`, then stream the response
  /// via [send] using Connect wire frames (`response-start` / `chunk` / `end`).
  Future<void> handleRelayStyleRequest({
    required Map<String, dynamic> msg,
    required DesktopRelayBackends backends,
    required void Function(Map<String, dynamic> frame) send,
  }) async {
    final id = msg['id']?.toString();
    if (id == null) return;

    final method = (msg['method'] as String?)?.toUpperCase() ?? 'GET';
    final path = msg['path'] as String? ?? '/';
    final pathOnly = pathOnlyOf(path);
    final fwdHeaders = <String, String>{};
    final rawHeaders = msg['headers'];
    if (rawHeaders is Map) {
      for (final e in rawHeaders.entries) {
        fwdHeaders[e.key.toString()] = e.value.toString();
      }
    }
    final body = msg['body'];
    final bodyEncoding = msg['bodyEncoding'] as String?;

    if (isSyncPath(pathOnly)) {
      String? bodyStr;
      if (body is String && body.isNotEmpty) {
        bodyStr =
            bodyEncoding == 'base64' ? utf8.decode(base64Decode(body)) : body;
      }
      final result = await HomeSyncService.instance.handleHostHttp(
        method: method,
        body: bodyStr,
      );
      _sendJson(send, id, result.status, result.body);
      return;
    }

    // Pairing must succeed as soon as the Mac is on the relay — never wait
    // for llama-server (that boot can exceed the phone's 15s test timeout).
    if (_isSafeMethod(method) && isHostStatusPath(pathOnly)) {
      if (backends.advertiseBuiltin) {
        unawaited(DesktopRuntimeManager.instance.ensureBuiltinRunning());
      }
      if (method == 'HEAD') {
        _sendEmpty(send, id, 200);
      } else {
        _sendJson(send, id, 200, hostStatusPayload(backends));
      }
      return;
    }

    final target = resolveTarget(path, fwdHeaders, backends);
    if (target == null) {
      send({
        'type': 'response-error',
        'id': id,
        'status': 502,
        'error': 'No local backend available for this request.',
      });
      return;
    }

    var forwardPath = path.startsWith('/') ? path : '/$path';
    if (target.kind == 'lmMiniDesktop') {
      forwardPath = rewriteSidecarPath(forwardPath);
      final isProbe = _isSafeMethod(method) && isPairingProbePath(pathOnly);
      final runtime = DesktopRuntimeManager.instance;
      if (isProbe && !runtime.isRunning) {
        unawaited(runtime.ensureBuiltinRunning());
        if (method == 'HEAD') {
          _sendEmpty(send, id, 200);
        } else {
          _sendJson(send, id, 200, syntheticProbeBody(pathOnly));
        }
        return;
      }
      if (!isProbe) {
        final started = await runtime.ensureBuiltinRunning();
        if (!started) {
          send({
            'type': 'response-error',
            'id': id,
            'status': 503,
            'error': runtime.lastError ??
                'Mac model runtime is starting. Try again in a moment.',
          });
          return;
        }
      }
    }

    final headers = Map<String, String>.from(fwdHeaders);
    headers.remove('x-lm-mini-token');
    headers.remove('X-LM-Mini-Token');
    headers.remove('x-lm-mini-backend');
    headers.remove('X-LM-Mini-Backend');
    headers.remove('content-length');
    headers.remove('Content-Length');
    headers.remove('host');
    headers.remove('Host');
    final applyBearer = target.kind != 'a1111' &&
        target.kind != 'comfyui' &&
        target.kind != 'kokoro';
    if (applyBearer && target.apiToken.isNotEmpty) {
      headers['authorization'] = 'Bearer ${target.apiToken}';
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(minutes: 10);

    try {
      final uri = Uri.parse('http://${target.host}:${target.port}$forwardPath');
      final req = await client.openUrl(method, uri);
      headers.forEach(req.headers.set);

      if (body != null) {
        if (body is String && body.isNotEmpty) {
          if (bodyEncoding == 'base64') {
            req.add(base64Decode(body));
          } else {
            req.add(utf8.encode(body));
          }
        } else if (body is List) {
          req.add(Uint8List.fromList(body.cast<int>()));
        }
      }

      final res = await req.close().timeout(const Duration(minutes: 10));
      final responseHeaders = <String, String>{};
      res.headers.forEach((name, values) {
        final lower = name.toLowerCase();
        if (lower == 'transfer-encoding' || lower == 'connection') return;
        responseHeaders[name] = values.join(',');
      });

      final transformModels = target.kind == 'lmMiniDesktop' &&
          method == 'GET' &&
          needsLmStudioModelsTransform(pathOnly);

      if (transformModels) {
        final chunks = <int>[];
        await for (final chunk in res) {
          chunks.addAll(chunk);
        }
        var payload = utf8.decode(chunks, allowMalformed: true);
        if (res.statusCode == 200) {
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic>) {
              bool? propsVision;
              try {
                final propsReq = await client.getUrl(
                  Uri.parse('http://${target.host}:${target.port}/props'),
                );
                final propsRes =
                    await propsReq.close().timeout(const Duration(seconds: 2));
                if (propsRes.statusCode == 200) {
                  final propsBody = await utf8.decodeStream(propsRes);
                  final propsJson = jsonDecode(propsBody);
                  if (propsJson is Map) {
                    propsVision = LMStudioModel.visionFromProps(
                      Map<String, dynamic>.from(propsJson),
                    );
                  }
                }
              } catch (_) {}
              payload = jsonEncode(openaiModelsToLmStudioV1(
                decoded,
                visionFromProps: propsVision,
              ));
            }
          } catch (_) {}
        }
        responseHeaders['content-type'] = 'application/json';
        responseHeaders.remove('Content-Length');
        responseHeaders.remove('content-length');
        send({
          'type': 'response-start',
          'id': id,
          'status': res.statusCode,
          'headers': responseHeaders,
        });
        send({
          'type': 'response-chunk',
          'id': id,
          'data': payload,
        });
        send({'type': 'response-end', 'id': id});
        return;
      }

      send({
        'type': 'response-start',
        'id': id,
        'status': res.statusCode,
        'headers': responseHeaders,
      });

      final contentType =
          (res.headers.contentType?.mimeType ?? '').toLowerCase();
      final isBinary = contentType.startsWith('audio/') ||
          contentType.startsWith('image/') ||
          contentType.startsWith('video/') ||
          contentType == 'application/octet-stream' ||
          path.startsWith('/view') ||
          path.startsWith('/tts/');

      await for (final chunk in res) {
        if (isBinary) {
          send({
            'type': 'response-chunk',
            'id': id,
            'data': base64Encode(chunk),
            'encoding': 'base64',
          });
        } else {
          send({
            'type': 'response-chunk',
            'id': id,
            'data': utf8.decode(chunk, allowMalformed: true),
          });
        }
      }
      send({'type': 'response-end', 'id': id});
    } catch (e) {
      debugPrint('🖥️ DesktopProxy: ${target.kind} error $e');
      send({
        'type': 'response-error',
        'id': id,
        'status': 502,
        'error': _friendlyBackendError(target.kind, e),
      });
    } finally {
      client.close(force: true);
    }
  }

  /// Turns a raw socket exception into a phone-facing message that names the
  /// backend and how to fix it, instead of a bare "SocketException" 502.
  String _friendlyBackendError(String kind, Object e) {
    final label = switch (kind) {
      'lmMiniDesktop' => 'LM Mini Home',
      'lmStudio' => 'LM Studio',
      'ollama' => 'Ollama',
      'omlx' => 'oMLX',
      'a1111' => 'AUTOMATIC1111 / Forge',
      'comfyui' => 'ComfyUI',
      'kokoro' => 'Kokoro TTS',
      _ => kind,
    };
    final refused = e is SocketException &&
        (e.osError?.errorCode == 61 /* macOS ECONNREFUSED */ ||
            e.osError?.errorCode == 111 /* Linux ECONNREFUSED */ ||
            e.osError?.errorCode == 10061 /* Windows WSAECONNREFUSED */ ||
            e.message.toLowerCase().contains('refused'));
    if (refused) {
      return '$label isn\'t running on ${DesktopPlatform.thisMachine}. '
          'Start it (or turn it off in Share with phone), then try again.';
    }
    return '$label not reachable: $e';
  }

  DesktopProxyTarget? resolveTarget(
    String path,
    Map<String, String> fwdHeaders,
    DesktopRelayBackends backends,
  ) {
    if (path.startsWith('/tts/')) {
      if (!backends.kokoroEnabled) return null;
      return DesktopProxyTarget(
        kind: 'kokoro',
        host: backends.kokoroHost,
        port: backends.kokoroPort,
        apiToken: '',
      );
    }

    if (path.startsWith('/sdapi/')) {
      if (!backends.hasA1111) return null;
      return DesktopProxyTarget(
        kind: 'a1111',
        host: backends.a1111Host,
        port: backends.a1111Port,
        apiToken: '',
      );
    }

    if (_isComfyUiPath(path)) {
      if (!backends.hasComfyUi) return null;
      return DesktopProxyTarget(
        kind: 'comfyui',
        host: backends.comfyUiHost,
        port: backends.comfyUiPort,
        apiToken: '',
      );
    }

    final header = (fwdHeaders['x-lm-mini-backend'] ??
            fwdHeaders['X-LM-Mini-Backend'] ??
            '')
        .trim()
        .toLowerCase();

    final isOllamaPath = path.startsWith('/api/chat') ||
        path.startsWith('/api/tags') ||
        path.startsWith('/api/show') ||
        path.startsWith('/api/generate') ||
        path.startsWith('/api/pull') ||
        path.startsWith('/api/ps') ||
        path.startsWith('/api/embed');

    if (header == 'lmminidesktop' || header == 'builtin') {
      if (!backends.advertiseBuiltin) return null;
      final rt = DesktopRuntimeManager.instance;
      return DesktopProxyTarget(
        kind: 'lmMiniDesktop',
        host: DesktopRuntimeManager.defaultHost,
        port: rt.port,
        apiToken: '',
      );
    }

    if (header == 'ollama' || (header.isEmpty && isOllamaPath)) {
      if (!backends.advertiseOllama && header == 'ollama') return null;
      return DesktopProxyTarget(
        kind: 'ollama',
        host: backends.ollamaHost,
        port: backends.ollamaPort,
        apiToken: backends.ollamaApiToken,
      );
    }

    if (header == 'omlx') {
      if (!backends.advertiseOmlx) return null;
      return DesktopProxyTarget(
        kind: 'omlx',
        host: backends.omlxHost,
        port: backends.omlxPort,
        apiToken: backends.omlxApiToken,
      );
    }

    if (header == 'jan') {
      if (!backends.advertiseJan) return null;
      return DesktopProxyTarget(
        kind: 'jan',
        host: backends.janHost,
        port: backends.janPort,
        apiToken: backends.janApiToken,
      );
    }

    if (header == 'unsloth') {
      if (!backends.advertiseUnsloth) return null;
      return DesktopProxyTarget(
        kind: 'unsloth',
        host: backends.unslothHost,
        port: backends.unslothPort,
        apiToken: backends.unslothApiToken,
      );
    }

    if (header == 'lmstudio' || header.isEmpty) {
      if (backends.advertiseLmStudio) {
        return DesktopProxyTarget(
          kind: 'lmStudio',
          host: backends.lmStudioHost,
          port: backends.lmStudioPort,
          apiToken: backends.lmStudioApiToken,
        );
      }
      if (backends.advertiseBuiltin) {
        final rt = DesktopRuntimeManager.instance;
        return DesktopProxyTarget(
          kind: 'lmMiniDesktop',
          host: DesktopRuntimeManager.defaultHost,
          port: rt.port,
          apiToken: '',
        );
      }
    }

    return null;
  }

  static bool _isComfyUiPath(String path) {
    var p = path;
    if (p.startsWith('/api/')) p = p.substring(4);
    return p == '/prompt' ||
        p.startsWith('/prompt?') ||
        p.startsWith('/history') ||
        p.startsWith('/view') ||
        p.startsWith('/object_info') ||
        p.startsWith('/models') ||
        p.startsWith('/userdata') ||
        p.startsWith('/v2/userdata') ||
        p.startsWith('/system_stats') ||
        p.startsWith('/queue') ||
        p == '/interrupt' ||
        p == '/ws' ||
        p.startsWith('/ws?') ||
        p.startsWith('/upload/');
  }

  static bool _isSafeMethod(String method) =>
      method == 'GET' || method == 'HEAD';

  static String pathOnlyOf(String path) {
    final q = path.indexOf('?');
    var raw = q >= 0 ? path.substring(0, q) : path;
    if (raw.isEmpty) return '/';
    if (!raw.startsWith('/')) raw = '/$raw';
    // If a proxy forwards the full /s/{session}/… path, strip the session prefix.
    final stripped = RegExp(r'^/s/[^/]+(/.*)$').firstMatch(raw);
    if (stripped != null) return stripped.group(1)!;
    return raw;
  }

  static bool isHostStatusPath(String path) =>
      pathOnlyOf(path) == hostStatusPath;

  static bool isSyncPath(String path) => pathOnlyOf(path) == syncPath;

  /// GET/HEAD paths the phone uses to test that the Mac is reachable.
  static bool isPairingProbePath(String path) {
    final p = pathOnlyOf(path);
    return p == hostStatusPath ||
        p == '/health' ||
        p == '/v1/models' ||
        p == '/api/v0/models' ||
        p == '/api/v1/models';
  }

  /// llama-server is OpenAI-compatible (`/v1/models`), not LM Studio REST.
  static String rewriteSidecarPath(String path) {
    final qIndex = path.indexOf('?');
    final p = pathOnlyOf(path);
    final query = qIndex >= 0 ? path.substring(qIndex) : '';
    if (p == '/api/v0/models' || p == '/api/v1/models') {
      return '/v1/models$query';
    }
    return path.startsWith('/') ? path : '/$path';
  }

  static bool needsLmStudioModelsTransform(String path) {
    final p = pathOnlyOf(path);
    return p == '/api/v0/models' || p == '/api/v1/models';
  }

  static Map<String, dynamic> hostStatusPayload(DesktopRelayBackends backends) {
    final reachable = <String, bool>{...backends.reachable};
    if (backends.advertiseBuiltin) {
      reachable['lmMiniDesktop'] = reachable['lmMiniDesktop'] ?? true;
    }
    if (backends.advertiseLmStudio) {
      reachable.putIfAbsent('lmStudio', () => false);
    }
    if (backends.advertiseOllama) {
      reachable.putIfAbsent('ollama', () => false);
    }
    if (backends.advertiseOmlx) {
      reachable.putIfAbsent('omlx', () => false);
    }
    if (backends.advertiseJan) {
      reachable.putIfAbsent('jan', () => false);
    }
    if (backends.advertiseUnsloth) {
      reachable.putIfAbsent('unsloth', () => false);
    }
    if (backends.kokoroEnabled) {
      // Kokoro is started on demand (and on Share with phone). Treat it as
      // ready whenever the host toggle is on so the phone does not show
      // "Not running" during the first probe.
      reachable['kokoro'] = true;
    }
    return {
      'ok': true,
      'host': 'lmMiniDesktop',
      'platform': Platform.operatingSystem,
      'backends': advertisedBackendNames(backends),
      'reachable': reachable,
      'kokoroReady': backends.kokoroEnabled,
      'runtimeRunning': DesktopRuntimeManager.instance.isRunning,
    };
  }

  static List<String> advertisedBackendNames(DesktopRelayBackends backends) {
    final names = <String>[];
    if (backends.advertiseBuiltin) names.add('lmMiniDesktop');
    if (backends.advertiseLmStudio) names.add('lmStudio');
    if (backends.advertiseOllama) names.add('ollama');
    if (backends.advertiseOmlx) names.add('omlx');
    if (backends.advertiseJan) names.add('jan');
    if (backends.advertiseUnsloth) names.add('unsloth');
    return names;
  }

  static Map<String, dynamic> syntheticProbeBody(String path) {
    final p = pathOnlyOf(path);
    if (p == hostStatusPath) {
      return {
        'ok': true,
        'host': 'lmMiniDesktop',
        'runtimeRunning': false,
      };
    }
    if (p == '/health') return {'status': 'ok'};
    if (p == '/api/v1/models' || p == '/api/v0/models') {
      return {'models': <dynamic>[]};
    }
    return {'object': 'list', 'data': <dynamic>[]};
  }

  /// Convert llama-server `/v1/models` JSON to LM Studio V1 `{models:[{key}]}`.
  /// llama.cpp also includes an Ollama-style `models` list — prefer OpenAI `data`.
  static Map<String, dynamic> openaiModelsToLmStudioV1(
    Map<String, dynamic> openai, {
    bool? visionFromProps,
  }) {
    final data = openai['data'];
    if (data is List) {
      final capById = <String, List<String>>{};
      final ollamaModels = openai['models'];
      if (ollamaModels is List) {
        for (final item in ollamaModels) {
          if (item is! Map) continue;
          final id =
              (item['name'] ?? item['model'] ?? item['id'] ?? '').toString();
          final caps = item['capabilities'];
          if (id.isEmpty || caps is! List) continue;
          capById[id] = [
            for (final c in caps) c.toString().toLowerCase(),
          ];
        }
      }
      final models = <Map<String, dynamic>>[];
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) continue;
        final vision = visionFromProps ??
            (capById[id]?.contains('vision') == true ||
                capById[id]?.contains('multimodal') == true);
        models.add({
          'key': id,
          'type': vision ? 'vlm' : 'llm',
          'publisher': item['owned_by'] ?? '',
          'architecture': '',
          'format': 'gguf',
          'quantization': <String, dynamic>{},
          'capabilities': {'vision': vision},
          'loaded_instances': [
            {'id': '0', 'config': <String, dynamic>{}},
          ],
        });
      }
      return {'models': models};
    }
    if (openai['models'] is List) return openai;
    return {'models': <dynamic>[]};
  }

  static void _sendJson(
    void Function(Map<String, dynamic> frame) send,
    String id,
    int status,
    Map<String, dynamic> body,
  ) {
    final payload = jsonEncode(body);
    send({
      'type': 'response-start',
      'id': id,
      'status': status,
      'headers': {'content-type': 'application/json'},
    });
    send({
      'type': 'response-chunk',
      'id': id,
      'data': payload,
    });
    send({'type': 'response-end', 'id': id});
  }

  static void _sendEmpty(
    void Function(Map<String, dynamic> frame) send,
    String id,
    int status,
  ) {
    send({
      'type': 'response-start',
      'id': id,
      'status': status,
      'headers': const <String, String>{},
    });
    send({'type': 'response-end', 'id': id});
  }
}

class DesktopProxyTarget {
  const DesktopProxyTarget({
    required this.kind,
    required this.host,
    required this.port,
    required this.apiToken,
  });

  final String kind;
  final String host;
  final int port;
  final String apiToken;
}
