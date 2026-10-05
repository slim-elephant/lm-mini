import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/kokoro_model_manager.dart';
import '../../services/kokoro_tts_service.dart';
import '../../utils/tts_language_catalog.dart';
import '../desktop_platform.dart';

/// Local HTTP wrapper around [KokoroTtsService] so phones can reach the same
/// Voice Settings model over QR relay (`/tts/*`), matching LM Mini Connect.
class DesktopKokoroServer {
  DesktopKokoroServer._();
  static final DesktopKokoroServer instance = DesktopKokoroServer._();

  static const int defaultPort = 9998;

  HttpServer? _server;
  int _port = defaultPort;
  String? _lastError;
  bool _starting = false;

  bool get isRunning => _server != null;
  int get port => _port;
  String? get lastError => _lastError;

  Future<bool> start({int port = defaultPort}) async {
    if (_server != null && _port == port) return true;
    if (_starting) return _server != null;
    _starting = true;
    _lastError = null;
    try {
      if (_server != null) await stop();

      final ready = await KokoroModelManager().isModelReady();
      if (!ready) {
        _lastError = 'Download Kokoro in Voice Settings first.';
        return false;
      }

      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      } on SocketException catch (e) {
        // Port already taken (e.g. Connect). If that process speaks Kokoro,
        // sharing still works — we just don't own the listener.
        if (await _healthOk(port)) {
          _port = port;
          _lastError = null;
          debugPrint('🖥️ Kokoro: port $port already serving TTS');
          return true;
        }
        try {
          _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
          debugPrint('🖥️ Kokoro: LAN bind failed, using loopback: $e');
        } on SocketException catch (e2) {
          _lastError = 'Port $port is in use: $e2';
          return false;
        }
      }

      _port = port;
      _server!.listen(_handle, onError: (Object e) {
        debugPrint('🖥️ Kokoro HTTP error: $e');
      });
      final addr = _server!.address;
      final lan = addr == InternetAddress.anyIPv4 || addr.address == '0.0.0.0';
      debugPrint(
        lan
            ? '🖥️ Kokoro TTS listening on 0.0.0.0:$port'
            : '🖥️ Kokoro TTS listening on ${addr.address}:$port (LAN unavailable)',
      );
      unawaited(KokoroTtsService().initialize());
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('🖥️ Kokoro start failed: $e');
      return false;
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<bool> _healthOk(int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/tts/health'),
      );
      final res = await req.close().timeout(const Duration(seconds: 2));
      await res.drain<void>();
      client.close(force: true);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handle(HttpRequest req) async {
    req.response.headers.set('Access-Control-Allow-Origin', '*');
    req.response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
    req.response.headers
        .set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

    if (req.method == 'OPTIONS') {
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }

    final path = req.uri.path;
    final route = path.startsWith('/tts') ? path.substring(4) : path;
    final normalized = route.isEmpty ? '/' : route;

    try {
      if (req.method == 'GET' &&
          (normalized == '/' || normalized == '/health')) {
        await _writeJson(req.response, 200, {
          'status': 'ok',
          'service': 'kokoro-tts',
          'activeModel': 'on-device',
          'engineReady': KokoroTtsService().isInitialized,
        });
        return;
      }
      if (req.method == 'GET' && normalized == '/voices') {
        final readyMap = await KokoroModelManager().languageReadyMap();
        final readyIds = {
          for (final e in readyMap.entries)
            if (e.value) e.key,
        };
        await _writeJson(
          req.response,
          200,
          TtsLanguageCatalog.voicesApiPayload(readyIds),
        );
        return;
      }
      if (req.method == 'POST' &&
          (normalized == '/generate' || normalized == '/generate-stream')) {
        final body = await utf8.decoder.bind(req).join();
        Map<String, dynamic> json = const {};
        if (body.trim().isNotEmpty) {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) json = decoded;
        }
        final text = json['text']?.toString() ?? '';
        if (text.trim().isEmpty) {
          await _writeJson(req.response, 400, {
            'error': 'Missing or invalid "text" field',
          });
          return;
        }
        final speakerId = (json['speakerId'] as num?)?.toInt() ?? 0;
        final speed = (json['speed'] as num?)?.toDouble() ?? 1.0;
        final language =
            json['language']?.toString() ?? json['model']?.toString();
        final wav = await KokoroTtsService().synthesizeWav(
          text: text,
          speakerId: speakerId,
          speed: speed,
          language: language,
        );
        if (wav == null || wav.isEmpty) {
          await _writeJson(req.response, 503, {
            'error':
                'Kokoro model is not ready on ${DesktopPlatform.thisMachine}.',
          });
          return;
        }
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType('audio', 'wav');
        req.response.headers.contentLength = wav.length;
        req.response.add(wav);
        await req.response.close();
        return;
      }

      await _writeJson(req.response, 404, {'error': 'Not found'});
    } catch (e) {
      debugPrint('🖥️ Kokoro request failed: $e');
      if (req.response.headers.persistentConnection) {
        try {
          await _writeJson(req.response, 500, {'error': e.toString()});
        } catch (_) {}
      }
    }
  }

  Future<void> _writeJson(
    HttpResponse res,
    int status,
    Map<String, dynamic> body,
  ) async {
    final bytes = utf8.encode(jsonEncode(body));
    res.statusCode = status;
    res.headers.contentType = ContentType.json;
    res.headers.contentLength = bytes.length;
    res.add(bytes);
    await res.close();
  }
}
