import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../desktop_platform.dart';
import '../runtime/desktop_runtime_manager.dart';
import '../../models/lm_studio_model.dart';
import '../../services/home_sync_service.dart';
import '../../utils/home_lan.dart';
import 'desktop_host_capabilities.dart';
import 'desktop_relay_client.dart';

/// Shared localhost HTTP proxy used by relay and USB host (Connect parity).
class DesktopRequestProxy {
  DesktopRequestProxy._() {
    // The runtime must not swap models under a phone's live generation.
    DesktopRuntimeManager.instance.isBusy = () => isBusy;
  }
  static final DesktopRequestProxy instance = DesktopRequestProxy._();

  static const _lmStudioLoadPath = '/api/v1/models/load';
  static const _lmStudioUnloadPath = '/api/v1/models/unload';

  /// Phone pairing / health probes that must not wait on sidecar boot.
  static const hostStatusPath = '/lm-mini/host-status';
  static const syncPath = HomeSyncService.syncPath;

  /// Upstream clients for requests still streaming, keyed `channel:id`, so a
  /// phone-side Stop (`cancel` frame) can abort generation on this machine.
  final Map<String, _Inflight> _inflight = {};
  final Set<String> _cancelled = {};

  static String _key(String channel, String id) => '$channel:$id';

  /// No upstream bytes for this long ends a response that already started
  /// (a hung backend). Reset by every chunk, and not counted while the relay
  /// has the request paused (the phone is slow, not the backend).
  @visibleForTesting
  static Duration upstreamIdleTimeout = const Duration(minutes: 10);

  /// Wait for the backend's response headers once the request is sent. The
  /// built-in runtime's model load happens before this and is not counted.
  @visibleForTesting
  static Duration upstreamFirstByteTimeout = const Duration(minutes: 10);

  /// Streaming chat to the built-in runtime: when the reply can't start
  /// right away (model loading / switching, or a long prompt), send
  /// `200 text/event-stream` plus `: loading` comments so Cloudflare
  /// (~100 s without a byte → 524) and the phone keep waiting.
  @visibleForTesting
  static Duration keepAliveEvery = const Duration(seconds: 15);

  /// Warm runtime: start the keep-alive only if the reply hasn't started
  /// after this long (a quick answer or a quick error keeps its real status).
  @visibleForTesting
  static Duration keepAliveGrace = const Duration(seconds: 5);

  /// Target kinds that get the loading keep-alive.
  @visibleForTesting
  static Set<String> keepAliveTargetKinds = {'lmMiniDesktop'};

  /// Aborts one in-flight request (phone pressed Stop or went away).
  void cancel(String id, {String channel = 'relay'}) {
    final key = _key(channel, id);
    final entry = _inflight.remove(key);
    if (entry == null) return;
    _cancelled.add(key);
    debugPrint('🖥️ DesktopProxy: cancelled $key');
    entry.keepAlive?.stop();
    // abort() destroys the socket even mid-response, so LM Studio / Ollama
    // see the disconnect and stop generating. close(force) alone did not.
    entry.request?.abort();
    entry.client?.close(force: true);
    // A paused subscription would never see the abort: end the pipe here.
    entry.stopPipe?.call(const SocketException('Cancelled'));
  }

  /// Relay flow control: the phone is reading slower than this machine
  /// sends, so stop reading the backend for request [id] until [resume].
  /// The backend is held back by TCP; nothing piles up in memory here.
  void pause(String id, {String channel = 'relay'}) {
    final entry = _inflight[_key(channel, id)];
    if (entry == null || entry.paused) return;
    entry.paused = true;
    entry.subscription?.pause();
  }

  /// Undoes [pause].
  void resume(String id, {String channel = 'relay'}) {
    final entry = _inflight[_key(channel, id)];
    if (entry == null || !entry.paused) return;
    entry.paused = false;
    entry.subscription?.resume();
  }

  /// Aborts every in-flight request on [channel] (its connection dropped).
  void cancelAll({String channel = 'relay'}) {
    final prefix = '$channel:';
    for (final key in _inflight.keys.toList()) {
      if (key.startsWith(prefix)) {
        cancel(key.substring(prefix.length), channel: channel);
      }
    }
  }

  @visibleForTesting
  int inflightCount({String channel = 'relay'}) =>
      _inflight.keys.where((k) => k.startsWith('$channel:')).length;

  /// True while any phone request is talking to the built-in runtime
  /// (relay or USB). Requests still waiting for the runtime to boot don't
  /// count — only ones the sidecar is actually answering.
  bool get isBusy => _inflight.values.any((e) => e.builtin && e.active);

  Future<List<String>> _downloadedModels() async {
    try {
      return await DesktopRuntimeManager.instance.builtinModelLister?.call() ??
          const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }

  /// Resolve a target from path + `X-LM-Mini-Backend`, then stream the response
  /// via [send] using Connect wire frames (`response-start` / `chunk` / `end`).
  Future<void> handleRelayStyleRequest({
    required Map<String, dynamic> msg,
    required DesktopRelayBackends backends,
    required void Function(Map<String, dynamic> frame) send,
    String channel = 'relay',
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

    // Installing node packs / models and restarting ComfyUI run code on this
    // computer: only when the user turned it on. Answered here, without
    // contacting ComfyUI; the phone shows `error` as is.
    if (target.kind == 'comfyui' &&
        !backends.allowComfyUiInstall &&
        isComfyUiInstallPath(method, pathOnly)) {
      _sendJson(send, id, 403, {'error': comfyUiInstallBlockedMessage});
      return;
    }

    // Registered before any wait (the built-in runtime can take 15 s+ to
    // boot) so a Stop during that wait is not lost.
    final key = _key(channel, id);
    final entry = _Inflight();
    _inflight[key] = entry;
    bool stoppedEarly() {
      if (!_cancelled.remove(key)) return false;
      _inflight.remove(key);
      entry.keepAlive?.stop();
      return true;
    }

    final keepAlive = keepAliveTargetKinds.contains(target.kind) &&
            isStreamingChatRequest(method, pathOnly, body, bodyEncoding)
        ? LoadingKeepAlive(id: id, send: send, every: keepAliveEvery)
        : null;
    entry.keepAlive = keepAlive;

    var forwardPath = path.startsWith('/') ? path : '/$path';
    if (target.kind == 'lmMiniDesktop') {
      forwardPath = rewriteSidecarPath(forwardPath);
      final isProbe = _isSafeMethod(method) && isPairingProbePath(pathOnly);
      final runtime = DesktopRuntimeManager.instance;
      // Cold, or still loading (llama-server lists no models until healthy).
      if (isProbe && (!runtime.isRunning || runtime.isStarting)) {
        _inflight.remove(key);
        unawaited(runtime.ensureBuiltinRunning());
        if (method == 'HEAD') {
          _sendEmpty(send, id, 200);
        } else {
          // List the model the runtime is about to load (same id llama-server
          // reports: its file path) so a phone that pairs while the Mac is
          // cold doesn't get an empty model list.
          String? coldModel = runtime.startingModelPath;
          if (coldModel == null) {
            try {
              coldModel = await runtime.builtinModelResolver?.call();
            } catch (_) {}
          }
          _sendJson(
            send,
            id,
            200,
            syntheticProbeBody(
              pathOnly,
              modelId: coldModel,
              otherModelIds: await _downloadedModels(),
            ),
          );
        }
        return;
      }
      final requested = method == 'POST'
          ? requestedModelOf(body, bodyEncoding)
          : null;
      final isLoad = method == 'POST' && pathOnly == _lmStudioLoadPath;
      final isUnload = method == 'POST' && pathOnly == _lmStudioUnloadPath;
      if (isUnload) {
        _inflight.remove(key);
        // llama-server has no unload; stop it unless a phone is mid-answer.
        if (runtime.isServing) {
          _sendJson(send, id, 409, {
            'error': '${DesktopPlatform.thisMachine} is answering another '
                'request. Try again when it finishes.',
          });
        } else {
          final loaded = runtime.loadedModelPath;
          await runtime.stop();
          _sendJson(send, id, 200, {'instance_id': loaded ?? ''});
        }
        return;
      }
      if (!isProbe) {
        final available = await _downloadedModels();
        final switchTo = modelSwitchTarget(
          requested: requested,
          loaded: runtime.loadedModelPath ?? runtime.startingModelPath,
          available: available,
          otherBusy: runtime.isServing,
        );
        if (isLoad && requested != null) {
          final match = matchDownloadedModel(requested, available);
          if (match == null) {
            _inflight.remove(key);
            _sendJson(send, id, 404, {
              'error': 'Model is not downloaded on '
                  '${DesktopPlatform.thisMachine}: $requested',
            });
            return;
          }
          if (switchTo == null &&
              match != (runtime.loadedModelPath ?? runtime.startingModelPath) &&
              runtime.isServing) {
            _inflight.remove(key);
            _sendJson(send, id, 409, {
              'error': '${DesktopPlatform.thisMachine} is answering another '
                  'request. Try again when it finishes.',
            });
            return;
          }
        }
        // Cold start or model switch: this can take minutes, longer than
        // Cloudflare waits for a first byte. Open the stream now.
        if (switchTo != null || !runtime.isRunning || runtime.isStarting) {
          keepAlive?.start();
        } else {
          keepAlive?.startAfter(keepAliveGrace);
        }
        var started = false;
        if (switchTo != null) {
          debugPrint('🖥️ DesktopProxy: phone asked for $switchTo — switching');
          started = await runtime.ensureStarted(modelPath: switchTo);
          // Another phone request grabbed the runtime meanwhile: answer with
          // the loaded model instead of failing.
          if (!started && !isLoad && runtime.isRunning) {
            started = await runtime.ensureBuiltinRunning();
          }
        } else {
          started = await runtime.ensureBuiltinRunning();
        }
        if (stoppedEarly()) return;
        if (isLoad) {
          _inflight.remove(key);
          if (started) {
            _sendJson(send, id, 200, {
              'type': 'llm',
              'instance_id': runtime.loadedModelPath ?? requested ?? '',
              'status': 'loaded',
            });
          } else {
            _sendJson(send, id, 503, {
              'error': runtime.lastError ?? 'Could not load the model.',
            });
          }
          return;
        }
        if (!started) {
          _inflight.remove(key);
          if (keepAlive != null && keepAlive.stop()) {
            // Headers are out: report the failure inside the stream.
            keepAlive.finishWithError(runtime.lastError ??
                'The model on ${DesktopPlatform.thisMachine} could not start.');
            return;
          }
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

    // Warm runtime / other backends with a keep-alive: a long prompt can
    // also keep the first byte away for minutes.
    if (keepAlive != null && !keepAlive.started && !keepAlive.scheduled) {
      keepAlive.startAfter(keepAliveGrace);
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    // Only for pooled idle connections; the active response has its own
    // idle timeout in [_pipe].
    client.idleTimeout = const Duration(minutes: 10);
    entry.client = client;
    entry.builtin = target.kind == 'lmMiniDesktop';
    entry.active = true;
    // The runtime may have moved to a fallback port during the start.
    final targetPort = entry.builtin
        ? DesktopRuntimeManager.instance.port
        : target.port;

    try {
      final uri = Uri.parse('http://${target.host}:$targetPort$forwardPath');
      final req = await client.openUrl(method, uri);
      entry.request = req;
      if (_cancelled.contains(key)) req.abort();
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

      final res = await req.close().timeout(upstreamFirstByteTimeout);
      // The reply is here: no more loading comments. True when the stream
      // is already open (status + headers were sent).
      final streamOpen = keepAlive?.stop() ?? false;
      if (streamOpen) {
        if (res.statusCode != 200) {
          final errBody = await _readCapped(res, 64 * 1024);
          keepAlive!.finishWithError(
            sseErrorMessage(res.statusCode, errBody),
            upstreamBody: errBody,
          );
          return;
        }
        await _pipe<String>(
          res.transform(const Utf8Decoder(allowMalformed: true)),
          entry,
          (text) {
            if (text.isEmpty) return;
            send({'type': 'response-chunk', 'id': id, 'data': text});
          },
        );
        send({'type': 'response-end', 'id': id});
        return;
      }
      final responseHeaders = <String, String>{};
      res.headers.forEach((name, values) {
        final lower = name.toLowerCase();
        if (lower == 'transfer-encoding' || lower == 'connection') return;
        responseHeaders[name] = values.join(',');
      });

      final toLmStudioV1 = target.kind == 'lmMiniDesktop' &&
          method == 'GET' &&
          needsLmStudioModelsTransform(pathOnly);
      // Every downloaded GGUF, not just the loaded one, so the phone can pick.
      final transformModels = toLmStudioV1 ||
          (target.kind == 'lmMiniDesktop' &&
              method == 'GET' &&
              pathOnly == '/v1/models');

      if (transformModels) {
        final chunks = <int>[];
        await for (final chunk in res) {
          chunks.addAll(chunk);
        }
        var payload = utf8.decode(chunks, allowMalformed: true);
        if (res.statusCode == 200) {
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic> && !toLmStudioV1) {
              payload = jsonEncode(mergeDownloadedModels(
                decoded,
                await _downloadedModels(),
              ));
            } else if (decoded is Map<String, dynamic>) {
              bool? propsVision;
              try {
                final propsReq = await client.getUrl(
                  Uri.parse('http://${target.host}:$targetPort/props'),
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
                mergeDownloadedModels(decoded, await _downloadedModels()),
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
      final isBinary = isBinaryResponse(contentType, pathOnly);

      if (isBinary) {
        await _pipe<List<int>>(res, entry, (chunk) {
          send({
            'type': 'response-chunk',
            'id': id,
            'data': base64Encode(chunk),
            'encoding': 'base64',
          });
        });
      } else {
        // Streaming decoder: an emoji or CJK character split across two
        // TCP chunks must not turn into two U+FFFD halves.
        await _pipe<String>(
          res.transform(const Utf8Decoder(allowMalformed: true)),
          entry,
          (text) {
            if (text.isEmpty) return;
            send({'type': 'response-chunk', 'id': id, 'data': text});
          },
        );
      }
      send({'type': 'response-end', 'id': id});
    } catch (e) {
      // Stopped from the phone: the relay already dropped this request.
      if (_cancelled.contains(key)) return;
      debugPrint('🖥️ DesktopProxy: ${target.kind} error $e');
      if (keepAlive != null && keepAlive.stop()) {
        // The phone already has a 200 event stream: end it with an error
        // event it shows, instead of a dropped connection.
        keepAlive.finishWithError(_friendlyBackendError(target.kind, e));
        return;
      }
      send({
        'type': 'response-error',
        'id': id,
        'status': 502,
        'error': _friendlyBackendError(target.kind, e),
      });
    } finally {
      keepAlive?.stop();
      _inflight.remove(key);
      _cancelled.remove(key);
      client.close(force: true);
    }
  }

  /// Forwards [source] through [onData], honouring relay `pause` / `resume`
  /// and failing after [upstreamIdleTimeout] without a chunk (paused time
  /// excluded). Completes when the source ends; errors with its error.
  Future<void> _pipe<T>(
    Stream<T> source,
    _Inflight entry,
    void Function(T data) onData,
  ) {
    final done = Completer<void>();
    Timer? idle;
    late final StreamSubscription<T> sub;
    void finish([Object? error, StackTrace? st]) {
      idle?.cancel();
      if (done.isCompleted) return;
      entry.subscription = null;
      entry.stopPipe = null;
      if (error == null) {
        done.complete();
      } else {
        done.completeError(error, st);
      }
    }

    void arm() {
      idle?.cancel();
      idle = Timer(upstreamIdleTimeout, () {
        if (done.isCompleted) return;
        if (entry.paused) {
          arm();
          return;
        }
        unawaited(sub.cancel());
        finish(TimeoutException('No upstream data', upstreamIdleTimeout));
      });
    }

    sub = source.listen(
      (data) {
        arm();
        onData(data);
      },
      onError: finish,
      onDone: finish,
      cancelOnError: true,
    );
    entry.subscription = sub;
    entry.stopPipe = (error) {
      unawaited(sub.cancel());
      finish(error);
    };
    if (entry.paused) sub.pause();
    arm();
    return done.future;
  }

  static Future<String> _readCapped(Stream<List<int>> res, int cap) async {
    final bytes = <int>[];
    try {
      await for (final chunk in res.timeout(const Duration(seconds: 30))) {
        final room = cap - bytes.length;
        if (room <= 0) continue;
        bytes.addAll(chunk.length <= room ? chunk : chunk.sublist(0, room));
      }
    } catch (_) {}
    return utf8.decode(bytes, allowMalformed: true);
  }

  static const _chatStreamPaths = {
    '/v1/chat/completions',
    '/chat/completions',
  };

  /// A phone chat request that will be answered as SSE (`"stream": true` to
  /// an OpenAI chat path), so a 200 `text/event-stream` can be opened before
  /// the backend answers.
  ///
  /// LM Studio `/api/v1/chat` is left out on purpose: llama-server answers
  /// it 404 and the phone then retries on `/v1/chat/completions`. That
  /// fallback needs the real status, which an open stream would hide.
  static bool isStreamingChatRequest(
    String method,
    String path,
    Object? body,
    String? bodyEncoding,
  ) {
    if (method != 'POST') return false;
    if (!_chatStreamPaths.contains(pathOnlyOf(path))) return false;
    try {
      String? text;
      if (body is String && body.isNotEmpty) {
        text = bodyEncoding == 'base64'
            ? utf8.decode(base64Decode(body), allowMalformed: true)
            : body;
      } else if (body is List) {
        text = utf8.decode(body.cast<int>(), allowMalformed: true);
      }
      if (text == null || !text.trimLeft().startsWith('{')) return false;
      final decoded = jsonDecode(text);
      return decoded is Map && decoded['stream'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Phone-facing message for a backend that answered [status] with [body]
  /// after the stream was already opened.
  static String sseErrorMessage(int status, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (err is String && err.isNotEmpty) return err;
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}
    final text = body.trim();
    if (text.isNotEmpty && text.length <= 500) return text;
    return 'The model server on ${DesktopPlatform.thisMachine} answered '
        'HTTP $status.';
  }

  /// OpenAI-style SSE error event. Keeps the backend's own error `type`
  /// (e.g. llama.cpp `exceed_context_size_error`) so the phone can still
  /// recognise it; otherwise `runtime_error`.
  static String sseErrorEvent(String message, {String? upstreamBody}) {
    final error = <String, dynamic>{
      'message': message,
      'type': 'runtime_error',
    };
    if (upstreamBody != null) {
      try {
        final decoded = jsonDecode(upstreamBody);
        final err = decoded is Map ? decoded['error'] : null;
        if (err is Map) {
          for (final e in err.entries) {
            error.putIfAbsent(e.key.toString(), () => e.value);
          }
          final type = err['type'];
          if (type is String && type.isNotEmpty) error['type'] = type;
        }
      } catch (_) {}
    }
    return 'data: ${jsonEncode({'error': error})}\n\n';
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
    if (e is TimeoutException) {
      return '$label stopped responding on ${DesktopPlatform.thisMachine} '
          '(no data for ${_humanDuration(e.duration)}).';
    }
    return '$label not reachable: $e';
  }

  static String _humanDuration(Duration? d) {
    if (d == null) return 'a long time';
    if (d.inMinutes >= 1) {
      return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'}';
    }
    return '${d.inSeconds} s';
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

    final header = (fwdHeaders['x-lm-mini-backend'] ??
            fwdHeaders['X-LM-Mini-Backend'] ??
            '')
        .trim()
        .toLowerCase();

    // An image backend named by the phone gets every path (ComfyUI-Manager,
    // ControlNet, … have no shared prefix), same as LM Mini Connect. The
    // path heuristics below stay as the fallback for phones that send no
    // header.
    if (header == 'comfyui') {
      if (!backends.hasComfyUi) return null;
      return DesktopProxyTarget(
        kind: 'comfyui',
        host: backends.comfyUiHost,
        port: backends.comfyUiPort,
        apiToken: '',
      );
    }

    if (header == 'a1111') {
      if (!backends.hasA1111) return null;
      return DesktopProxyTarget(
        kind: 'a1111',
        host: backends.a1111Host,
        port: backends.a1111Port,
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

  /// Shown by the phone (Comfy Mini prints a 403's `error` as is).
  static const comfyUiInstallBlockedMessage =
      'Installing from your phone is turned off. On your computer, open '
      'LM Mini Home > Share with phone and turn on '
      "'Let my phone install nodes and models'.";

  static const _comfyUiInstallPaths = {
    '/manager/queue/task',
    '/manager/queue/install_model',
    '/manager/queue/batch',
    '/manager/queue/update_all',
    '/manager/queue/update_comfyui',
    '/manager/reboot',
    '/customnode/install/git_url',
    '/customnode/install/pip',
    '/comfyui_manager/comfyui_switch_version',
    '/snapshot/restore',
    '/snapshot/remove',
  };

  /// ComfyUI-Manager routes that install code or models on this computer or
  /// restart ComfyUI. Matched with or without the `/api` and `/v2` prefixes
  /// (older Manager versions serve the same routes without `/v2`). Read-only
  /// Manager routes and `/free` are never gated.
  static bool isComfyUiInstallPath(String method, String path) {
    if (_isSafeMethod(method.toUpperCase())) return false;
    var p = pathOnlyOf(path);
    if (p.startsWith('/api/')) p = p.substring(4);
    if (p.startsWith('/v2/')) p = p.substring(3);
    return _comfyUiInstallPaths.contains(p);
  }

  /// Whether a backend reply must travel as base64 frames. Text (JSON, SSE,
  /// HTML, XML, …) is streamed decoded; everything else — images, video,
  /// audio, model previews, downloads — byte-exact.
  static bool isBinaryResponse(String contentType, String path) {
    final ct = contentType.toLowerCase();
    final p = pathOnlyOf(path);
    final pNoApi = p.startsWith('/api/') ? p.substring(4) : p;
    if (pNoApi.startsWith('/view') ||
        pNoApi.startsWith('/experiment/models/preview') ||
        p.startsWith('/tts/')) {
      return true;
    }
    if (ct.isEmpty) return false;
    final isText = ct.startsWith('text/') ||
        ct.contains('json') ||
        ct.contains('xml') ||
        ct.contains('javascript') ||
        ct.contains('event-stream') ||
        ct.contains('x-www-form-urlencoded');
    return !isText;
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
      // The host sets this from "a GGUF is downloaded and the runtime binary
      // exists" — never assume it can serve.
      reachable.putIfAbsent('lmMiniDesktop', () => false);
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
      'connectVersion': desktopHostVersion,
      'capabilities': desktopHostCapabilities,
      // Direct Wi‑Fi: phones that know these fields try the LAN first
      // (certificate pinned to the fingerprint); older phones ignore them.
      // An empty list tells a new phone the direct path is off right now.
      kLanJsonKey: backends.lanUrls,
      if (backends.lanFingerprint?.isNotEmpty ?? false)
        kLanFingerprintJsonKey: backends.lanFingerprint,
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

  static Map<String, dynamic> syntheticProbeBody(
    String path, {
    String? modelId,
    List<String> otherModelIds = const [],
  }) {
    final p = pathOnlyOf(path);
    final hasModel = modelId != null && modelId.isNotEmpty;
    if (p == hostStatusPath) {
      return {
        'ok': true,
        'host': 'lmMiniDesktop',
        'runtimeRunning': false,
      };
    }
    if (p == '/health') return {'status': 'ok'};
    final openai = mergeDownloadedModels(<String, dynamic>{
      'object': 'list',
      'data': <dynamic>[
        if (hasModel) {'id': modelId, 'object': 'model', 'owned_by': 'llamacpp'},
      ],
    }, otherModelIds);
    if (p == '/api/v1/models' || p == '/api/v0/models') {
      return (openai['data'] as List).isNotEmpty
          ? openaiModelsToLmStudioV1(openai)
          : {'models': <dynamic>[]};
    }
    return openai;
  }

  /// Appends downloaded GGUFs llama-server doesn't list (it only reports the
  /// loaded one) as `status: unloaded`. Ids are full file paths — the same id
  /// llama-server uses — so the phone can name one in a chat request.
  static Map<String, dynamic> mergeDownloadedModels(
    Map<String, dynamic> openai,
    List<String> downloaded,
  ) {
    final data = openai['data'];
    final list = data is List ? List<dynamic>.from(data) : <dynamic>[];
    final have = <String>{
      for (final item in list)
        if (item is Map && item['id'] != null) item['id'].toString(),
    };
    for (final path in downloaded) {
      if (path.isEmpty || have.contains(path)) continue;
      have.add(path);
      list.add({
        'id': path,
        'object': 'model',
        'owned_by': 'llamacpp',
        'status': {'value': 'unloaded'},
      });
    }
    return {...openai, 'object': openai['object'] ?? 'list', 'data': list};
  }

  /// The downloaded path [requested] names: exact path, else same file name.
  static String? matchDownloadedModel(String? requested, List<String> paths) {
    final r = requested?.trim();
    if (r == null || r.isEmpty) return null;
    if (paths.contains(r)) return r;
    String base(String s) => s.split(RegExp(r'[\\/]')).last.toLowerCase();
    final name = base(r);
    for (final p in paths) {
      if (base(p) == name) return p;
    }
    return null;
  }

  /// Which model to (re)start the sidecar with for a phone request naming
  /// [requested], or `null` to use what is loaded. Never switches while
  /// another phone request is being answered ([otherBusy]).
  static String? modelSwitchTarget({
    required String? requested,
    required String? loaded,
    required List<String> available,
    required bool otherBusy,
  }) {
    final match = matchDownloadedModel(requested, available);
    if (match == null || match == loaded) return null;
    if (otherBusy && loaded != null) return null;
    return match;
  }

  /// `model` from an OpenAI / LM Studio JSON request body, if any.
  static String? requestedModelOf(Object? body, String? bodyEncoding) {
    try {
      String? text;
      if (body is String && body.isNotEmpty) {
        text = bodyEncoding == 'base64'
            ? utf8.decode(base64Decode(body), allowMalformed: true)
            : body;
      } else if (body is List) {
        text = utf8.decode(body.cast<int>(), allowMalformed: true);
      }
      if (text == null || !text.trimLeft().startsWith('{')) return null;
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      final m = decoded['model'];
      return m is String && m.trim().isNotEmpty ? m.trim() : null;
    } catch (_) {
      return null;
    }
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
        final status = item['status'];
        final unloaded = status is Map && status['value'] == 'unloaded';
        // /props describes the loaded model only.
        final vision = (unloaded ? null : visionFromProps) ??
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
          'loaded_instances': unloaded
              ? <dynamic>[]
              : [
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

class _Inflight {
  HttpClient? client;
  HttpClientRequest? request;

  /// The upstream body being forwarded (paused by relay flow control).
  StreamSubscription<dynamic>? subscription;
  void Function(Object error)? stopPipe;
  bool paused = false;
  LoadingKeepAlive? keepAlive;

  /// Targets the built-in llama-server.
  bool builtin = false;

  /// Upstream request opened (past any runtime start wait).
  bool active = false;
}

/// Opens a `200 text/event-stream` reply before the backend answers and
/// sends `: loading` SSE comments every [every] until [stop]. SSE clients
/// ignore comment lines; the bytes keep Cloudflare and the phone waiting.
class LoadingKeepAlive {
  LoadingKeepAlive({
    required this.id,
    required this.send,
    required this.every,
  });

  static const comment = ': loading\n\n';

  final String id;
  final void Function(Map<String, dynamic> frame) send;
  final Duration every;

  Timer? _grace;
  Timer? _ticker;
  bool _started = false;
  bool _stopped = false;

  /// Headers + first comment went out.
  bool get started => _started;

  /// [startAfter] is pending.
  bool get scheduled => _grace != null;

  void start() {
    _grace?.cancel();
    _grace = null;
    if (_started || _stopped) return;
    _started = true;
    send({
      'type': 'response-start',
      'id': id,
      'status': 200,
      'headers': {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
      },
    });
    _comment();
    _ticker = Timer.periodic(every, (_) => _comment());
  }

  void startAfter(Duration delay) {
    if (_started || _stopped || _grace != null) return;
    _grace = Timer(delay, start);
  }

  void _comment() {
    if (_stopped) return;
    send({'type': 'response-chunk', 'id': id, 'data': comment});
  }

  /// Stops the comments. Returns whether the stream was opened ([started]).
  bool stop() {
    _stopped = true;
    _grace?.cancel();
    _grace = null;
    _ticker?.cancel();
    _ticker = null;
    return _started;
  }

  /// Ends an opened stream with an OpenAI-style error event and `[DONE]`.
  void finishWithError(String message, {String? upstreamBody}) {
    stop();
    final event = DesktopRequestProxy.sseErrorEvent(
      message,
      upstreamBody: upstreamBody,
    );
    send({
      'type': 'response-chunk',
      'id': id,
      'data': '${event}data: [DONE]\n\n',
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
