import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Loads audio files as 16 kHz mono PCM for Whisper.
class AudioFileLoader {
  AudioFileLoader._();
  static final AudioFileLoader instance = AudioFileLoader._();

  static const _channel = MethodChannel('net.neuro9.lmmini/audio_decode');

  static bool _bindingsReady = false;

  /// Supported extensions for the file picker.
  static const supportedExtensions = [
    'wav',
    'mp3',
    'm4a',
    'aac',
    'caf',
    'aiff',
    'aif',
    'flac',
    'ogg',
  ];

  Future<Float32List> load16kMono(String path) async {
    if (!_bindingsReady) {
      sherpa.initBindings();
      _bindingsReady = true;
    }

    final ext = p.extension(path).toLowerCase();
    String wavPath = path;

    if (ext != '.wav') {
      if (!Platform.isIOS && !Platform.isAndroid && !Platform.isMacOS) {
        throw UnsupportedError(
          'Non-WAV audio conversion is supported on iOS, Android, and macOS. '
          'Please use a .wav file on this platform.',
        );
      }
      wavPath = await _convertToWav(path);
    }

    final wave = sherpa.readWave(wavPath);
    if (wave.samples.isEmpty || wave.sampleRate <= 0) {
      throw Exception('Could not read audio from $path');
    }

    if (wave.sampleRate == 16000) {
      return wave.samples;
    }
    return _resample(wave.samples, wave.sampleRate, 16000);
  }

  Future<int> durationMs(String path) async {
    try {
      final samples = await load16kMono(path);
      return (samples.length / 16).round();
    } catch (_) {
      return 0;
    }
  }

  Future<String> copyToTranscriptionStorage(String sourcePath) async {
    final dir = await _storageDir();
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
    final dest = p.join(dir.path, name);
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<Directory> _storageDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'transcriptions', 'audio'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<String> _convertToWav(String sourcePath) async {
    if (!Platform.isIOS && !Platform.isAndroid && !Platform.isMacOS) {
      throw UnsupportedError(
        'Non-WAV audio conversion is supported on iOS, Android, and macOS only.',
      );
    }
    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(
      tempDir.path,
      'decode_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    final result = await _channel.invokeMethod<String>('convertToWav', {
      'sourcePath': sourcePath,
      'outputPath': outPath,
      'sampleRate': 16000,
    });
    if (result == null || !File(result).existsSync()) {
      throw Exception('Audio conversion failed for ${p.basename(sourcePath)}');
    }
    return result;
  }

  static Float32List _resample(
    Float32List input,
    int fromRate,
    int toRate,
  ) {
    if (fromRate == toRate) return input;
    final ratio = fromRate / toRate;
    final outLen = (input.length / ratio).floor();
    final out = Float32List(outLen);
    for (var i = 0; i < outLen; i++) {
      final src = i * ratio;
      final idx = src.floor();
      final frac = src - idx;
      if (idx + 1 < input.length) {
        out[i] = input[idx] * (1 - frac) + input[idx + 1] * frac;
      } else if (idx < input.length) {
        out[i] = input[idx];
      }
    }
    return out;
  }
}
