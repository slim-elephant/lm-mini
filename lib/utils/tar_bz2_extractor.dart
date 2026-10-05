import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// Extract a `.tar.bz2` archive without loading the whole archive into RAM.
///
/// [onProgress] receives 0–1 for the extract phase only:
/// - ~0–40%: bzip2 decompress (by compressed bytes read)
/// - ~40–100%: tar write-out (by uncompressed entry bytes)
Future<void> extractTarBz2Archive({
  required String archivePath,
  required String targetDir,
  void Function(double progress)? onProgress,
}) async {
  final receive = ReceivePort();
  final errorPort = ReceivePort();
  final exitPort = ReceivePort();

  final isolate = await Isolate.spawn(
    _extractWorker,
    _ExtractRequest(
      sendPort: receive.sendPort,
      archivePath: archivePath,
      targetDir: targetDir,
    ),
    onError: errorPort.sendPort,
    onExit: exitPort.sendPort,
    errorsAreFatal: true,
  );

  final done = Completer<void>();
  StreamSubscription? sub;
  StreamSubscription? errSub;
  StreamSubscription? exitSub;

  errSub = errorPort.listen((msg) {
    if (!done.isCompleted) {
      final parts = msg is List ? msg : [msg];
      done.completeError(
        StateError('Extract failed: ${parts.isNotEmpty ? parts.first : msg}'),
      );
    }
  });

  exitSub = exitPort.listen((_) {
    if (!done.isCompleted) {
      done.completeError(StateError('Extract isolate exited unexpectedly'));
    }
  });

  sub = receive.listen((message) {
    if (message is double) {
      onProgress?.call(message.clamp(0.0, 1.0));
    } else if (message == 'done') {
      if (!done.isCompleted) done.complete();
    } else if (message is String && message.startsWith('error:')) {
      if (!done.isCompleted) {
        done.completeError(StateError(message.substring(6)));
      }
    }
  });

  try {
    await done.future;
  } finally {
    await sub.cancel();
    await errSub.cancel();
    await exitSub.cancel();
    receive.close();
    errorPort.close();
    exitPort.close();
    isolate.kill(priority: Isolate.immediate);
  }
}

class _ExtractRequest {
  final SendPort sendPort;
  final String archivePath;
  final String targetDir;

  _ExtractRequest({
    required this.sendPort,
    required this.archivePath,
    required this.targetDir,
  });
}

void _extractWorker(_ExtractRequest req) {
  Directory? tempDir;
  try {
    req.sendPort.send(0.0);

    final compressedLen = File(req.archivePath).lengthSync();
    tempDir = Directory.systemTemp.createTempSync('lm_mini_tar_');
    final tarPath = p.join(tempDir.path, 'temp.tar');

    // Phase 1: stream bzip2 → temp.tar (disk-to-disk).
    final bzInput = InputFileStream(req.archivePath);
    final progressInput = _ProgressInput(
      bzInput,
      compressedLen,
      (frac) => req.sendPort.send(frac * 0.40),
    );
    final tarOut = OutputFileStream(tarPath);
    try {
      BZip2Decoder().decodeStream(progressInput, tarOut);
    } finally {
      tarOut.closeSync();
      progressInput.closeSync();
    }
    req.sendPort.send(0.40);

    // Phase 2: stream tar entries one-by-one to the target directory.
    Directory(req.targetDir).createSync(recursive: true);
    _extractTarStreamingFromPath(
      tarPath,
      req.targetDir,
      (frac) => req.sendPort.send(0.40 + frac * 0.60),
    );

    req.sendPort.send(1.0);
    req.sendPort.send('done');
  } catch (e, st) {
    req.sendPort.send('error:$e\n$st');
  } finally {
    try {
      tempDir?.deleteSync(recursive: true);
    } catch (_) {}
  }
}

void _extractTarStreamingFromPath(
  String tarPath,
  String outputPath,
  void Function(double fraction) onFraction,
) {
  // Pass 1: measure total file payload bytes without storing contents.
  var totalBytes = 0;
  final measure = InputFileStream(tarPath);
  try {
    while (!measure.isEOS) {
      final endCheck = measure.peekBytes(2).toUint8List();
      if (endCheck.length < 2 || (endCheck[0] == 0 && endCheck[1] == 0)) {
        break;
      }
      final tf = TarFile.read(measure, storeData: false);
      if (tf.isFile &&
          tf.typeFlag != TarFile.TYPE_EX_HEADER &&
          tf.typeFlag != TarFile.TYPE_EX_HEADER2 &&
          tf.typeFlag != TarFile.TYPE_G_EX_HEADER &&
          tf.typeFlag != TarFile.TYPE_G_EX_HEADER2 &&
          tf.filename != '././@LongLink') {
        totalBytes += tf.fileSize;
      }
    }
  } finally {
    measure.closeSync();
  }

  if (totalBytes <= 0) totalBytes = 1;

  // Pass 2: extract one entry at a time.
  var written = 0;
  final extract = InputFileStream(tarPath);
  String? nextName;
  try {
    while (!extract.isEOS) {
      final endCheck = extract.peekBytes(2).toUint8List();
      if (endCheck.length < 2 || (endCheck[0] == 0 && endCheck[1] == 0)) {
        break;
      }

      final tf = TarFile.read(extract, storeData: true);

      if (tf.filename == '././@LongLink') {
        nextName = tf.rawContent?.readString();
        continue;
      }
      if (tf.typeFlag == TarFile.TYPE_G_EX_HEADER ||
          tf.typeFlag == TarFile.TYPE_G_EX_HEADER2 ||
          tf.typeFlag == TarFile.TYPE_EX_HEADER ||
          tf.typeFlag == TarFile.TYPE_EX_HEADER2) {
        continue;
      }
      if (nextName != null) {
        tf.filename = nextName;
        nextName = null;
      }

      final filePath = p.join(outputPath, p.normalize(tf.filename));
      if (!_isWithin(outputPath, filePath)) {
        continue;
      }

      if (!tf.isFile) {
        Directory(filePath).createSync(recursive: true);
        continue;
      }

      if (tf.isSymLink) {
        continue;
      }

      final out = OutputFileStream(filePath);
      try {
        final raw = tf.rawContent;
        if (raw != null) {
          out.writeInputStream(raw);
        }
      } finally {
        out.closeSync();
      }

      written += tf.fileSize;
      onFraction((written / totalBytes).clamp(0.0, 1.0));
    }
  } finally {
    extract.closeSync();
  }

  onFraction(1.0);
}

bool _isWithin(String outputDir, String filePath) {
  final root = p.canonicalize(outputDir);
  final child = p.canonicalize(filePath);
  return p.isWithin(root, child) || root == child;
}

/// Wraps [InputFileStream] so bzip2 decode can report compressed-byte progress.
class _ProgressInput extends InputStreamBase {
  final InputFileStream _inner;
  final int totalBytes;
  final void Function(double fraction) onFraction;
  int _lastBucket = -1;

  _ProgressInput(this._inner, this.totalBytes, this.onFraction);

  void _report() {
    if (totalBytes <= 0) return;
    final bucket = (_inner.position * 200) ~/ totalBytes; // ~0.5% steps
    if (bucket == _lastBucket) return;
    _lastBucket = bucket;
    onFraction((_inner.position / totalBytes).clamp(0.0, 1.0));
  }

  @override
  int get position => _inner.position;

  @override
  set position(int v) => _inner.position = v;

  @override
  int get length => _inner.length;

  @override
  bool get isEOS => _inner.isEOS;

  @override
  Future<void> close() => _inner.close();

  @override
  void closeSync() => _inner.closeSync();

  @override
  void reset() => _inner.reset();

  @override
  void rewind([int length = 1]) {
    _inner.rewind(length);
    _report();
  }

  @override
  void skip(int length) {
    _inner.skip(length);
    _report();
  }

  @override
  InputStreamBase peekBytes(int count, [int offset = 0]) =>
      _inner.peekBytes(count, offset);

  @override
  int readByte() {
    final b = _inner.readByte();
    _report();
    return b;
  }

  @override
  InputStreamBase readBytes(int count) {
    final bytes = _inner.readBytes(count);
    _report();
    return bytes;
  }

  @override
  InputStreamBase subset([int? position, int? length]) =>
      _inner.subset(position, length);

  @override
  String readString({int? size, bool utf8 = true}) {
    final s = _inner.readString(size: size, utf8: utf8);
    _report();
    return s;
  }

  @override
  int readUint16() {
    final v = _inner.readUint16();
    _report();
    return v;
  }

  @override
  int readUint24() {
    final v = _inner.readUint24();
    _report();
    return v;
  }

  @override
  int readUint32() {
    final v = _inner.readUint32();
    _report();
    return v;
  }

  @override
  int readUint64() {
    final v = _inner.readUint64();
    _report();
    return v;
  }

  @override
  Uint8List toUint8List([Uint8List? bytes]) => _inner.toUint8List(bytes);
}
