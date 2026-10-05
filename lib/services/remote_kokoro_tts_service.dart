import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:convert';
import '../utils/just_audio_play.dart';
import '../utils/response_parser.dart';
import '../utils/tts_language_catalog.dart';

/// Remote TTS service that connects to Kokoro TTS running on a PC
/// via LM Mini Home (Share with phone) or legacy Connect (LAN or relay).
///
/// Mirrors the callback interface of KokoroTtsService so callers
/// can swap between on-device and remote transparently.
class RemoteKokoroTtsService {
  static final RemoteKokoroTtsService _instance =
      RemoteKokoroTtsService._internal();
  factory RemoteKokoroTtsService() => _instance;
  RemoteKokoroTtsService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _playerBusy = false;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _tempDir;

  // Server config
  String? _serverUrl; // e.g. "http://192.168.1.100:9998" or relay base URL
  String? _authToken; // X-LM-Mini-Token for relay mode

  // Callbacks — matching KokoroTtsService interface
  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onError;
  VoidCallback? onPlaybackStart;

  // Settings (same as on-device Kokoro)
  int _speakerId = 0;
  double _speed = 1.0;
  String? _language;

  // Streaming TTS state
  bool _isStreaming = false;
  bool _streamingFinished = false;
  String _sentenceBuffer = '';
  final List<String> _pendingSentences = [];
  final List<String> _audioQueue = [];
  final List<String> _streamWavFiles = [];
  bool _isGeneratingChunk = false;
  bool _isPlayingFromQueue = false;
  int _streamChunkIndex = 0;
  int _chunksGenerated = 0;
  StreamSubscription? _playerCompleteSub;
  Timer? _playbackSafetyTimer;

  // HTTP client for cancellation
  http.Client? _activeClient;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isStreaming => _isStreaming;
  int get speakerId => _speakerId;
  double get speed => _speed;

  /// Available speakers (same English UI ids as on-device Kokoro).
  static const List<Map<String, dynamic>> speakers =
      TtsLanguageCatalog.englishSpeakers;

  void setSpeakerId(int id) => _speakerId = id;
  void setSpeed(double speed) => _speed = speed;
  void setLanguage(String? language) {
    if (language == null || language.trim().isEmpty) {
      _language = null;
      return;
    }
    _language = language.split(RegExp(r'[-_]')).first.toLowerCase();
  }

  /// Initialize - test connection to remote Kokoro TTS server.
  /// [serverUrl] is the base URL (direct or relay).
  /// [authToken] is the relay auth token (null for direct LAN).
  Future<bool> initialize({
    String? serverUrl,
    String? authToken,
    String? language,
  }) async {
    if (language != null) setLanguage(language);
    if (_isInitialized && serverUrl == _serverUrl && authToken == _authToken) {
      return true;
    }

    if (serverUrl != null) _serverUrl = serverUrl;
    if (authToken != null) _authToken = authToken;

    if (_serverUrl == null || _serverUrl!.isEmpty) {
      debugPrint('RemoteKokoroTtsService: No server URL configured');
      return false;
    }

    _tempDir = (await getTemporaryDirectory()).path;

    try {
      final healthUrl = _buildUrl('/tts/health');
      final response = await http
          .get(Uri.parse(healthUrl), headers: _buildHeaders())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Set up audio player completion listener
        _playerCompleteSub?.cancel();
        _playerCompleteSub = _player.processingStateStream.listen((state) {
          if (state == ProcessingState.completed) {
            _playbackSafetyTimer?.cancel();
            _playbackSafetyTimer = null;
            _playerBusy = false;
            if (_isStreaming || _audioQueue.isNotEmpty || _streamingFinished) {
              _isPlayingFromQueue = false;
              _playNextFromQueue();
            } else if (_isSpeaking) {
              _isSpeaking = false;
              _disableWakeLock();
              onComplete?.call();
            }
          }
        });

        _isInitialized = true;
        debugPrint('RemoteKokoroTtsService: Connected to $_serverUrl');
        return true;
      } else {
        debugPrint(
            'RemoteKokoroTtsService: Health check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('RemoteKokoroTtsService: Connection failed: $e');
      return false;
    }
  }

  /// Generate speech and play it.
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call();
        return false;
      }
    }

    final cleaned = _cleanForTts(text);
    if (cleaned.isEmpty) return false;

    await stop();

    try {
      _isSpeaking = true;
      _enableWakeLock();
      onStart?.call();

      final wavPath = p.join(_tempDir!,
          'remote_kokoro_${DateTime.now().millisecondsSinceEpoch}.wav');

      final wavBytes = await _generateRemote(cleaned);

      if (!_isSpeaking) return false;

      if (wavBytes == null || wavBytes.isEmpty) {
        debugPrint('RemoteKokoroTtsService: Empty audio response');
        _isSpeaking = false;
        _disableWakeLock();
        onError?.call();
        return false;
      }

      final file = File(wavPath);
      await file.writeAsBytes(wavBytes);

      await _player.setFilePath(wavPath);
      onPlaybackStart?.call();
      unawaited(playTtsClip(_player));

      _cleanupTempFiles(wavPath);

      return true;
    } catch (e) {
      debugPrint('RemoteKokoroTtsService: Speak failed: $e');
      _isSpeaking = false;
      _disableWakeLock();
      onError?.call();
      return false;
    }
  }

  Future<void> stop() async {
    final wasStreaming = _isStreaming;

    _isSpeaking = false;
    _isStreaming = false;
    _streamingFinished = false;
    _isGeneratingChunk = false;
    _isPlayingFromQueue = false;
    _sentenceBuffer = '';
    _pendingSentences.clear();
    _audioQueue.clear();
    _streamChunkIndex = 0;
    _chunksGenerated = 0;
    _playbackSafetyTimer?.cancel();
    _playbackSafetyTimer = null;

    _activeClient?.close();
    _activeClient = null;

    try {
      await _player.stop();
      _playerBusy = false;
    } catch (_) {}

    if (wasStreaming) {
      for (final path in _streamWavFiles) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      _streamWavFiles.clear();
    }

    _disableWakeLock();
  }

  // ── Streaming Interface ──

  void startStreaming() {
    if (!_isInitialized) return;

    stop();
    _isStreaming = true;
    _streamingFinished = false;
    _sentenceBuffer = '';
    _pendingSentences.clear();
    _audioQueue.clear();
    _streamWavFiles.clear();
    _isGeneratingChunk = false;
    _isPlayingFromQueue = false;
    _streamChunkIndex = 0;
    _chunksGenerated = 0;

    _isSpeaking = true;
    _enableWakeLock();
    onStart?.call();
  }

  void feedText(String chunk) {
    if (!_isStreaming) return;
    _sentenceBuffer += chunk;
    _processSentenceBuffer();
  }

  void finishStreaming() {
    if (!_isStreaming) return;
    _streamingFinished = true;

    // Flush remaining buffer as final sentence
    final remaining = _sentenceBuffer.trim();
    if (remaining.isNotEmpty) {
      _pendingSentences.add(remaining);
      _sentenceBuffer = '';
    }

    _generateNextChunk();
  }

  // ── Internal ──

  String _buildUrl(String path) {
    final base = _serverUrl!.replaceAll(RegExp(r'/+$'), '');
    return '$base$path';
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['X-LM-Mini-Token'] = _authToken!;
    }
    return headers;
  }

  Future<Uint8List?> _generateRemote(String text) async {
    final client = http.Client();
    _activeClient = client;

    try {
      final url = _buildUrl('/tts/generate');
      final response = await client
          .post(
            Uri.parse(url),
            headers: _buildHeaders(),
            body: json.encode({
              'text': text,
              'speakerId': _speakerId,
              'speed': _speed,
              if (_language != null) 'language': _language,
            }),
          )
          .timeout(const Duration(seconds: 30));

      _activeClient = null;

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint(
            'RemoteKokoroTtsService: Generate failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      _activeClient = null;
      if (e is! http.ClientException || _isSpeaking) {
        debugPrint('RemoteKokoroTtsService: Generate error: $e');
      }
      return null;
    } finally {
      client.close();
    }
  }

  void _processSentenceBuffer() {
    // Extract complete sentences
    final sentenceEnders = RegExp(r'[.!?;]\s');
    while (true) {
      final match = sentenceEnders.firstMatch(_sentenceBuffer);
      if (match == null) break;

      final sentence = _sentenceBuffer.substring(0, match.end).trim();
      _sentenceBuffer = _sentenceBuffer.substring(match.end);

      if (sentence.isNotEmpty) {
        _pendingSentences.add(sentence);
      }
    }

    _generateNextChunk();
  }

  void _generateNextChunk() {
    if (!_isStreaming && !_streamingFinished) return;
    if (_isGeneratingChunk) return;
    if (_pendingSentences.isEmpty) {
      if (_streamingFinished && _audioQueue.isEmpty && !_isPlayingFromQueue) {
        // All done
        _isStreaming = false;
        _streamingFinished = false;
        _isSpeaking = false;
        _disableWakeLock();
        onComplete?.call();
      }
      return;
    }

    _isGeneratingChunk = true;
    _chunksGenerated++;

    // Adaptive batching: first 2 chunks = 1 sentence, then 2-3
    int sentenceCount;
    if (_chunksGenerated <= 2) {
      sentenceCount = 1;
    } else {
      sentenceCount = _pendingSentences.length >= 3 ? 3 : 2;
    }
    sentenceCount = sentenceCount.clamp(1, _pendingSentences.length);

    final batch = _pendingSentences.take(sentenceCount).join(' ');
    _pendingSentences.removeRange(0, sentenceCount);

    _generateAndEnqueue(batch);
  }

  Future<void> _generateAndEnqueue(String text) async {
    try {
      final wavBytes = await _generateRemote(text);

      if (!_isStreaming && !_streamingFinished) {
        _isGeneratingChunk = false;
        return;
      }

      if (wavBytes != null && wavBytes.isNotEmpty) {
        final wavPath = p.join(
            _tempDir!, 'remote_kokoro_stream_${_streamChunkIndex++}.wav');
        final file = File(wavPath);
        await file.writeAsBytes(wavBytes);
        _streamWavFiles.add(wavPath);
        _audioQueue.add(wavPath);
      }
    } catch (e) {
      debugPrint('RemoteKokoroTtsService: Stream generate error: $e');
    }

    _isGeneratingChunk = false;
    _playNextFromQueue();
    _generateNextChunk();
  }

  void _playNextFromQueue() {
    if (_isPlayingFromQueue || _playerBusy) return;
    if (_audioQueue.isEmpty) {
      if (_streamingFinished &&
          !_isGeneratingChunk &&
          _pendingSentences.isEmpty) {
        _isStreaming = false;
        _streamingFinished = false;
        _isSpeaking = false;
        _disableWakeLock();
        onComplete?.call();
      }
      return;
    }

    _isPlayingFromQueue = true;
    final wavPath = _audioQueue.removeAt(0);

    _playWavFile(wavPath);
  }

  Future<void> _playWavFile(String wavPath) async {
    try {
      _playerBusy = true;
      await _player.setFilePath(wavPath);

      if (_chunksGenerated == 1) {
        onPlaybackStart?.call();
      }

      // Safety timer in case player completion doesn't fire
      _playbackSafetyTimer?.cancel();
      _playbackSafetyTimer = Timer(const Duration(seconds: 30), () {
        debugPrint('RemoteKokoroTtsService: Playback safety timer fired');
        _playerBusy = false;
        _isPlayingFromQueue = false;
        _playNextFromQueue();
      });

      await playTtsClip(_player);
    } catch (e) {
      debugPrint('RemoteKokoroTtsService: Play failed: $e');
      _playerBusy = false;
      _isPlayingFromQueue = false;
      _playNextFromQueue();
    }
  }

  String _cleanForTts(String text) {
    var cleaned = ResponseParser.cleanForTts(text)
        .replaceAll(RegExp(r'[*_~>|]'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Limit length for single requests
    if (cleaned.length > 2000) {
      cleaned = cleaned.substring(0, 2000);
    }
    return cleaned;
  }

  void _cleanupTempFiles(String keepPath) {
    if (_tempDir == null) return;
    try {
      final dir = Directory(_tempDir!);
      for (final file in dir.listSync()) {
        if (file is File &&
            file.path != keepPath &&
            file.path.contains('remote_kokoro_') &&
            file.path.endsWith('.wav')) {
          file.deleteSync();
        }
      }
    } catch (_) {}
  }

  void _enableWakeLock() {
    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  void _disableWakeLock() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
  }

  /// Fetch available voices from the remote server.
  Future<List<Map<String, dynamic>>?> getRemoteVoices() async {
    if (!_isInitialized) return null;
    try {
      final url = _buildUrl('/tts/voices');
      final response = await http
          .get(Uri.parse(url), headers: _buildHeaders())
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseVoices(data);
      }
    } catch (e) {
      debugPrint('RemoteKokoroTtsService: Get voices failed: $e');
    }
    return null;
  }

  static List<Map<String, dynamic>>? _parseVoices(dynamic data) {
    if (data is! Map) return null;
    final top = _mapsFrom(data['voices']);
    if (top != null && top.isNotEmpty) return top;
    final langs = data['languages'];
    if (langs is! List) return null;
    final out = <Map<String, dynamic>>[];
    for (final lang in langs) {
      if (lang is! Map) continue;
      final nested = _mapsFrom(lang['voices']);
      if (nested != null) out.addAll(nested);
    }
    return out.isEmpty ? null : out;
  }

  static List<Map<String, dynamic>>? _mapsFrom(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    if (raw.first is! Map) return null;
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  /// Test connection to the remote Kokoro server.
  Future<bool> testConnection(String serverUrl, {String? authToken}) async {
    try {
      final base = serverUrl.replaceAll(RegExp(r'/+$'), '');
      final url = '$base/tts/health';
      final headers = <String, String>{};
      if (authToken != null && authToken.isNotEmpty) {
        headers['X-LM-Mini-Token'] = authToken;
      }
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    await stop();
    _playerCompleteSub?.cancel();
    _player.dispose();
    _isInitialized = false;
  }
}
