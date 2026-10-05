import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../models/voice_catalog_entry.dart';
import 'kokoro_model_manager.dart';
import 'model_download_service.dart';

/// Result of inspecting a downloaded voice pack on disk.
class VoicePackInspectResult {
  final String stagingDir;
  final String engine; // vits | kokoro
  final String suggestedId;
  final String suggestedName;
  final String language;
  final String? locale;
  final String? modelPath;
  final String? tokensPath;
  final String? voicesPath;
  final String? dataDir;
  final String? lexiconPath;
  final int sizeBytes;

  const VoicePackInspectResult({
    required this.stagingDir,
    required this.engine,
    required this.suggestedId,
    required this.suggestedName,
    required this.language,
    this.locale,
    this.modelPath,
    this.tokensPath,
    this.voicesPath,
    this.dataDir,
    this.lexiconPath,
    required this.sizeBytes,
  });
}

/// Admin helper: download a GitHub (or any HTTP) voice archive, inspect it,
/// preview TTS, then either discard or publish metadata to Firestore.
class VoicePackImportService {
  VoicePackImportService._();
  static final VoicePackImportService instance = VoicePackImportService._();

  AudioPlayer? _player;
  VoicePackInspectResult? _current;
  String? _lastUrl;

  AudioPlayer get _audio {
    return _player ??= AudioPlayer();
  }

  VoicePackInspectResult? get current => _current;
  String? get lastUrl => _lastUrl;

  bool get isDownloading {
    final id = _jobIdFor(_lastUrl);
    return ModelDownloadService.instance.isJobActive(id);
  }

  double get downloadProgress {
    final id = _jobIdFor(_lastUrl);
    return ModelDownloadService.instance.job(id)?.progress ?? 0;
  }

  String _jobIdFor(String? url) {
    if (url == null || url.isEmpty) return 'voice-import:none';
    return 'voice-import:${url.hashCode.abs()}';
  }

  /// Normalize pasted URLs (GitHub blob → release download, etc.).
  String normalizeUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    // github.com/.../blob/... → raw.githubusercontent.com (rare for releases)
    if (url.contains('github.com/') && url.contains('/blob/')) {
      url = url
          .replaceFirst('github.com/', 'raw.githubusercontent.com/')
          .replaceFirst('/blob/', '/');
    }
    return url;
  }

  /// Download + extract archive into a staging folder, then inspect.
  Future<VoicePackInspectResult> importFromUrl(
    String rawUrl, {
    void Function(double progress)? onProgress,
  }) async {
    final url = normalizeUrl(rawUrl);
    if (url.isEmpty || !url.startsWith('http')) {
      throw Exception('Paste a valid http(s) download URL');
    }
    _lastUrl = url;

    final appDir = await getApplicationSupportDirectory();
    final stagingRoot = Directory(p.join(appDir.path, 'tts_models', '_staging'));
    if (!stagingRoot.existsSync()) {
      stagingRoot.createSync(recursive: true);
    }

    // Clear previous staging so admins don't mix packs.
    await discardStaging();

    final fileName = p.basename(Uri.parse(url).path);
    final baseName = fileName
        .replaceAll(RegExp(r'\.tar\.bz2$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.tar\.gz$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
    final extractDir = Directory(p.join(stagingRoot.path, baseName));
    extractDir.createSync(recursive: true);

    final archivePath = p.join(stagingRoot.path, fileName);
    final jobId = _jobIdFor(url);

    final ok = await ModelDownloadService.instance.runArchive(
      id: jobId,
      displayName: 'Voice pack import',
      url: url,
      archivePath: archivePath,
      extractDir: extractDir.path,
      onProgress: (job) => onProgress?.call(job.progress),
      validateReady: () async => extractDir.existsSync(),
    );

    if (!ok) {
      final job = ModelDownloadService.instance.job(jobId);
      throw Exception(job?.errorMessage ?? 'Download failed');
    }

    // If archive nested a single top folder, use that as root.
    final root = _resolvePackRoot(extractDir);
    final inspected = await inspectDirectory(root, sourceUrl: url);
    _current = inspected;
    return inspected;
  }

  Directory _resolvePackRoot(Directory extractDir) {
    final kids = extractDir
        .listSync()
        .whereType<Directory>()
        .where((d) => !p.basename(d.path).startsWith('.'))
        .toList();
    final hasModelHere = _findOnnx(extractDir) != null ||
        File(p.join(extractDir.path, 'model.onnx')).existsSync();
    if (!hasModelHere && kids.length == 1) {
      return kids.first;
    }
    return extractDir;
  }

  Future<VoicePackInspectResult> inspectDirectory(
    Directory root, {
    required String sourceUrl,
  }) async {
    final base = p.basename(root.path);
    final hasVoices = File(p.join(root.path, 'voices.bin')).existsSync();
    final modelOnnx = File(p.join(root.path, 'model.onnx'));
    final String? onnx = modelOnnx.existsSync()
        ? modelOnnx.path
        : _findOnnx(root)?.path;

    if (onnx == null) {
      throw Exception('No .onnx model found in archive');
    }

    final tokens = File(p.join(root.path, 'tokens.txt'));
    if (!tokens.existsSync()) {
      throw Exception('tokens.txt missing — not a sherpa-onnx TTS pack');
    }

    String? dataDir;
    final espeak = Directory(p.join(root.path, 'espeak-ng-data'));
    if (espeak.existsSync()) {
      dataDir = espeak.path;
    } else {
      // Fall back to bundled Kokoro espeak if available.
      final kokoroReady = await KokoroModelManager().isModelReady();
      if (kokoroReady) {
        dataDir = p.join(await KokoroModelManager().getModelPath(), 'espeak-ng-data');
      }
    }

    final lexicon = File(p.join(root.path, 'lexicon.txt'));
    final engine = hasVoices && modelOnnx.existsSync() ? 'kokoro' : 'vits';

    final meta = _guessMetaFromName(base);
    var size = 0;
    await for (final e in root.list(recursive: true)) {
      if (e is File) size += await e.length();
    }

    return VoicePackInspectResult(
      stagingDir: root.path,
      engine: engine,
      suggestedId: meta.id,
      suggestedName: meta.name,
      language: meta.language,
      locale: meta.locale,
      modelPath: onnx,
      tokensPath: tokens.path,
      voicesPath:
          hasVoices ? p.join(root.path, 'voices.bin') : null,
      dataDir: dataDir,
      lexiconPath: lexicon.existsSync() ? lexicon.path : null,
      sizeBytes: size,
    );
  }

  File? _findOnnx(Directory root) {
    try {
      final files = root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.onnx'))
          .where((f) => !f.path.contains('espeak'))
          .toList();
      if (files.isEmpty) return null;
      // Prefer non-int8 if both exist? keep first by path length (root closer)
      files.sort((a, b) => a.path.length.compareTo(b.path.length));
      return files.first;
    } catch (_) {
      return null;
    }
  }

  ({String id, String name, String language, String? locale}) _guessMetaFromName(
      String base) {
    // e.g. vits-piper-en_US-amy-low → en_US, Amy
    var id = base
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (id.isEmpty) {
      id = 'voice-${DateTime.now().millisecondsSinceEpoch}';
    }

    String? locale;
    var language = 'en';
    final localeMatch =
        RegExp(r'([a-z]{2})[_-]([A-Z]{2})').firstMatch(base);
    if (localeMatch != null) {
      language = localeMatch.group(1)!;
      locale = '${localeMatch.group(1)}_${localeMatch.group(2)}';
    } else {
      final langOnly = RegExp(r'(?:^|[-_])([a-z]{2})(?:[-_]|$)').firstMatch(base);
      if (langOnly != null) language = langOnly.group(1)!;
    }

    // Name: take last meaningful token before quality suffix
    var namePart = base;
    namePart = namePart.replaceFirst(
        RegExp(r'^(vits-piper-|vits-coqui-|vits-|kokoro-|sherpa-onnx-)'), '');
    if (locale != null) {
      namePart = namePart.replaceFirst(RegExp('${locale.replaceAll('_', '[_-]')}[-_]?'), '');
    }
    namePart = namePart.replaceFirst(RegExp(r'[-_](low|medium|high|x_low|int8|fp16)$'), '');
    namePart = namePart.replaceAll(RegExp(r'[-_]+'), ' ').trim();
    if (namePart.isEmpty) namePart = base;
    final name = namePart
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return (id: id, name: name, language: language, locale: locale);
  }

  /// Generate a short sample with the staged pack and play it.
  Future<void> preview({
    String text = 'Hello! This is a voice preview from LM Mini.',
    int sid = 0,
    double speed = 1.0,
  }) async {
    final pack = _current;
    if (pack == null) throw Exception('Import a pack first');
    if (pack.modelPath == null || pack.tokensPath == null) {
      throw Exception('Pack incomplete');
    }
    if (pack.dataDir == null || !Directory(pack.dataDir!).existsSync()) {
      throw Exception(
          'espeak-ng-data missing. Download Kokoro once, or use a pack that includes it.');
    }

    sherpa.initBindings();

    final modelConfig = pack.engine == 'kokoro'
        ? sherpa.OfflineTtsModelConfig(
            kokoro: sherpa.OfflineTtsKokoroModelConfig(
              model: pack.modelPath!,
              voices: pack.voicesPath ?? '',
              tokens: pack.tokensPath!,
              dataDir: pack.dataDir!,
              lengthScale: 1.0,
            ),
            numThreads: 2,
            debug: false,
          )
        : sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: pack.modelPath!,
              tokens: pack.tokensPath!,
              dataDir: pack.dataDir!,
              lexicon: pack.lexiconPath ?? '',
              lengthScale: 1.0,
            ),
            numThreads: 2,
            debug: false,
          );

    final tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(model: modelConfig));
    try {
      final audio = tts.generate(text: text, sid: sid, speed: speed);
      if (audio.samples.isEmpty) {
        throw Exception('Empty audio — wrong engine or missing lexicon?');
      }
      final tmp = await getTemporaryDirectory();
      final wavPath = p.join(
          tmp.path, 'voice_preview_${DateTime.now().millisecondsSinceEpoch}.wav');
      _writeWav(wavPath, audio.samples, audio.sampleRate);
      await _audio.stop();
      await _audio.setFilePath(wavPath);
      await _audio.play();
    } finally {
      tts.free();
    }
  }

  Future<void> stopPreview() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  VoiceCatalogEntry buildCatalogEntry({
    required String name,
    required String language,
    String? locale,
    bool isPro = true,
    String? previewNote,
  }) {
    final pack = _current;
    final url = _lastUrl;
    if (pack == null || url == null) {
      throw Exception('Nothing imported');
    }
    return VoiceCatalogEntry(
      id: pack.suggestedId,
      name: name.trim().isEmpty ? pack.suggestedName : name.trim(),
      engine: pack.engine,
      language: language,
      locale: locale ?? pack.locale,
      downloadUrl: url,
      sizeBytes: pack.sizeBytes,
      isPro: isPro,
      published: true,
      previewNote: previewNote,
      createdAt: DateTime.now(),
    );
  }

  /// Delete local staging files (keep catalog untouched).
  Future<void> discardStaging() async {
    await stopPreview();
    final appDir = await getApplicationSupportDirectory();
    final stagingRoot = Directory(p.join(appDir.path, 'tts_models', '_staging'));
    if (stagingRoot.existsSync()) {
      try {
        stagingRoot.deleteSync(recursive: true);
      } catch (e) {
        debugPrint('VoicePackImport: discard failed: $e');
      }
    }
    _current = null;
  }

  static void _writeWav(String path, Float32List samples, int sampleRate) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;
    final int16Data = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      int16Data[i] = (clamped * 32767).round();
    }
    final dataSize = int16Data.length * 2;
    const headerSize = 44;
    final fileSize = headerSize + dataSize;
    final buffer = ByteData(fileSize);
    var offset = 0;
    void writeStr(String s) {
      for (final c in s.codeUnits) {
        buffer.setUint8(offset++, c);
      }
    }

    writeStr('RIFF');
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;
    writeStr('WAVE');
    writeStr('fmt ');
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;
    buffer.setUint16(offset, numChannels, Endian.little);
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    buffer.setUint16(offset, blockAlign, Endian.little);
    offset += 2;
    buffer.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;
    writeStr('data');
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;
    for (var i = 0; i < int16Data.length; i++) {
      buffer.setInt16(offset, int16Data[i], Endian.little);
      offset += 2;
    }
    File(path).writeAsBytesSync(buffer.buffer.asUint8List());
  }
}
