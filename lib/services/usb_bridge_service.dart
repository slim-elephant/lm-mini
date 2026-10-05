// usb_bridge_service.dart
//
// In-flight / cable-only LM Studio access.
//
// On iOS, this service stands up two local sockets, both bound to the
// loopback interface (127.0.0.1) so iOS treats them as exempt from the
// "Local Network" usage prompt:
//
//   • Port 2347 — a plain HTTP server. The app's `LMStudioService` is pointed
//     at `http://127.0.0.1:2347/v1` (or just /api/...) when USB Mode is on,
//     and every LM Studio request flows here exactly as if a real LM Studio
//     were running on-device.
//
//   • Port 2348 — a raw TCP control socket. The Mac-side LM Mini Connect
//     companion app dials this port through Apple's `usbmuxd` USB tunnel,
//     and uses it as a bidirectional JSON-RPC channel to:
//       1. receive framed HTTP requests from us, and
//       2. stream back the response chunks from the actual LM Studio.
//
// Wire format on port 2348 (newline-delimited JSON, one object per line):
//   App  -> Mac:
//     { "type": "request",
//       "id": "<uuid>",
//       "method": "POST",
//       "path": "/v1/chat/completions",
//       "headers": { ... },
//       "body": "<utf8 string>" }
//     { "type": "ping" }
//
//   Mac -> App:
//     { "type": "hello", "server": "lm-mini-connect", "version": "1.4.0" }
//     { "type": "response-start", "id": "...", "status": 200, "headers": { ... } }
//     { "type": "response-chunk", "id": "...", "data": "..." }
//     { "type": "response-chunk", "id": "...", "data": "<base64>", "encoding": "base64" }
//     { "type": "response-end",   "id": "..." }
//     { "type": "response-error", "id": "...", "status": 502, "error": "..." }
//     { "type": "pong" }
//
// Lifecycle: call [start] to bring up both sockets, [stop] to tear down.
// [connectionStream] emits true whenever a Mac is attached over USB,
// false otherwise. [connectedAppName] holds the most recent peer name.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

const String kUsbBridgeHost = '127.0.0.1';
const int kUsbBridgeHttpPort = 2347;
const int kUsbBridgeControlPort = 2348;

class _PendingRequest {
  _PendingRequest(this.response);
  final HttpResponse response;
  bool started = false;
}

class UsbBridgeService {
  UsbBridgeService._();
  static final UsbBridgeService instance = UsbBridgeService._();

  HttpServer? _httpServer;
  ServerSocket? _controlServer;
  Socket? _controlPeer;

  final Map<String, _PendingRequest> _pending = {};
  int _idCounter = 0;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Stream of `true` whenever a Mac peer is currently attached to the USB
  /// control socket; `false` when no peer is connected.
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isPeerConnected => _controlPeer != null;

  /// Free-form descriptive name of the Mac side reported via the `hello`
  /// frame, or `null` if no Mac is currently attached.
  String? _connectedAppName;
  String? get connectedAppName => _connectedAppName;

  /// HTTP base URL the rest of the app should target when USB mode is on.
  /// Example: `http://127.0.0.1:2347`.
  static String get baseUrl => 'http://$kUsbBridgeHost:$kUsbBridgeHttpPort';

  bool _starting = false;
  bool _running = false;
  bool get isRunning => _running;

  Future<void> start() async {
    if (_running || _starting) return;
    _starting = true;
    try {
      _httpServer = await HttpServer.bind(kUsbBridgeHost, kUsbBridgeHttpPort,
          shared: false);
      _httpServer!.listen(_handleHttpRequest, onError: (e) {
        debugPrint('UsbBridgeService: HTTP listen error: $e');
      });

      _controlServer = await ServerSocket.bind(
          kUsbBridgeHost, kUsbBridgeControlPort,
          shared: false);
      _controlServer!.listen(_handleControlConnection, onError: (e) {
        debugPrint('UsbBridgeService: control listen error: $e');
      });

      _running = true;
      debugPrint(
          'UsbBridgeService: started on http://$kUsbBridgeHost:$kUsbBridgeHttpPort  control=$kUsbBridgeControlPort');
    } catch (e) {
      debugPrint('UsbBridgeService: failed to start: $e');
      await stop();
      rethrow;
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    _running = false;
    try {
      await _httpServer?.close(force: true);
    } catch (_) {}
    _httpServer = null;
    try {
      await _controlServer?.close();
    } catch (_) {}
    _controlServer = null;
    try {
      _controlPeer?.destroy();
    } catch (_) {}
    _controlPeer = null;
    _connectedAppName = null;
    _failAllPending('USB bridge stopped');
    _connectionController.add(false);
  }

  // ─── Control socket (Mac peer) ────────────────────────────────────────

  void _handleControlConnection(Socket socket) {
    // Only allow one Mac peer at a time.
    if (_controlPeer != null) {
      try {
        _controlPeer!.destroy();
      } catch (_) {}
    }
    _controlPeer = socket;
    _connectionController.add(true);
    debugPrint(
        'UsbBridgeService: control peer connected from ${socket.remoteAddress.address}:${socket.remotePort}');

    final buffer = BytesBuilder();

    socket.listen((Uint8List chunk) {
      buffer.add(chunk);
      var bytes = buffer.toBytes();
      var idx = bytes.indexOf(0x0a);
      while (idx != -1) {
        final lineBytes = bytes.sublist(0, idx);
        bytes = bytes.sublist(idx + 1);
        if (lineBytes.isNotEmpty) {
          try {
            final line = utf8.decode(lineBytes);
            final msg = jsonDecode(line) as Map<String, dynamic>;
            _handleControlMessage(msg);
          } catch (e) {
            debugPrint('UsbBridgeService: bad control frame: $e');
          }
        }
        idx = bytes.indexOf(0x0a);
      }
      buffer
        ..clear()
        ..add(bytes);
    }, onError: (e) {
      debugPrint('UsbBridgeService: control socket error: $e');
    }, onDone: () {
      debugPrint('UsbBridgeService: control peer disconnected');
      if (_controlPeer == socket) {
        _controlPeer = null;
        _connectedAppName = null;
        _failAllPending('Mac disconnected');
        _connectionController.add(false);
      }
    });
  }

  void _handleControlMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    switch (type) {
      case 'hello':
        _connectedAppName =
            (msg['server'] as String?) ?? 'LM Mini Connect';
        debugPrint(
            'UsbBridgeService: hello from $_connectedAppName v${msg['version']}');
        break;
      case 'pong':
        break;
      case 'response-start':
        _onResponseStart(msg);
        break;
      case 'response-chunk':
        _onResponseChunk(msg);
        break;
      case 'response-end':
        _onResponseEnd(msg);
        break;
      case 'response-error':
        _onResponseError(msg);
        break;
      default:
        debugPrint('UsbBridgeService: unknown control msg type: $type');
    }
  }

  void _send(Map<String, dynamic> obj) {
    final peer = _controlPeer;
    if (peer == null) return;
    try {
      peer.add(utf8.encode('${jsonEncode(obj)}\n'));
    } catch (e) {
      debugPrint('UsbBridgeService: control send failed: $e');
    }
  }

  // ─── HTTP server (in-process callers) ─────────────────────────────────

  Future<void> _handleHttpRequest(HttpRequest req) async {
    final res = req.response;

    if (_controlPeer == null) {
      res.statusCode = 503;
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({
        'error':
            'USB Mode is on but LM Mini Connect is not attached. Plug your iPhone into the Mac running LM Mini Connect.',
      }));
      await res.close();
      return;
    }

    final body = await _readBody(req);

    final id = (++_idCounter).toString();
    _pending[id] = _PendingRequest(res);

    final headers = <String, String>{};
    req.headers.forEach((name, values) {
      // Drop hop-by-hop / size-related headers; the proxy will add them again.
      if (name == 'host' || name == 'content-length') return;
      headers[name] = values.join(',');
    });

    final path = req.uri.hasQuery
        ? '${req.uri.path}?${req.uri.query}'
        : req.uri.path;

    _send({
      'type': 'request',
      'id': id,
      'method': req.method,
      'path': path,
      'headers': headers,
      'body': body,
    });
  }

  Future<String> _readBody(HttpRequest req) async {
    final builder = BytesBuilder();
    await for (final chunk in req) {
      builder.add(chunk);
    }
    if (builder.isEmpty) return '';
    return utf8.decode(builder.toBytes(), allowMalformed: true);
  }

  // ─── Response demuxing ────────────────────────────────────────────────

  void _onResponseStart(Map<String, dynamic> msg) {
    final id = msg['id']?.toString();
    final pending = id == null ? null : _pending[id];
    if (pending == null) return;
    final res = pending.response;
    res.statusCode = (msg['status'] as int?) ?? 200;
    final hdrs = msg['headers'];
    if (hdrs is Map) {
      hdrs.forEach((k, v) {
        if (k == null) return;
        try {
          res.headers.set(k.toString(), v.toString());
        } catch (_) {}
      });
    }
    pending.started = true;
  }

  void _onResponseChunk(Map<String, dynamic> msg) {
    final id = msg['id']?.toString();
    final pending = id == null ? null : _pending[id];
    if (pending == null || !pending.started) return;
    final data = msg['data'];
    if (data == null) return;
    try {
      if (msg['encoding'] == 'base64') {
        pending.response.add(base64Decode(data as String));
      } else {
        pending.response.add(utf8.encode(data.toString()));
      }
    } catch (e) {
      debugPrint('UsbBridgeService: chunk write failed: $e');
    }
  }

  void _onResponseEnd(Map<String, dynamic> msg) {
    final id = msg['id']?.toString();
    final pending = id == null ? null : _pending.remove(id);
    if (pending == null) return;
    pending.response.close().catchError((_) {});
  }

  void _onResponseError(Map<String, dynamic> msg) {
    final id = msg['id']?.toString();
    final pending = id == null ? null : _pending.remove(id);
    if (pending == null) return;
    final res = pending.response;
    final error = (msg['error'] as String?) ?? 'USB bridge error';
    final status = (msg['status'] as int?) ?? 502;
    try {
      if (!pending.started) {
        res.statusCode = status;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'error': error}));
      }
    } catch (_) {}
    res.close().catchError((_) {});
  }

  void _failAllPending(String reason) {
    final ids = _pending.keys.toList();
    for (final id in ids) {
      final pending = _pending.remove(id);
      if (pending == null) continue;
      try {
        if (!pending.started) {
          pending.response.statusCode = 503;
          pending.response.headers.contentType = ContentType.json;
          pending.response.write(jsonEncode({'error': reason}));
        }
      } catch (_) {}
      pending.response.close().catchError((_) {});
    }
  }
}
