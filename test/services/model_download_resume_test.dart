import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/model_download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves [body] like Hugging Face: `/resolve/model.gguf` redirects (relative
/// Location) to `/cdn/model.gguf`, which honours `Range` and answers 416 with
/// no size when the range starts at the end of the file.
class _FakeHub {
  _FakeHub(this.body);

  final Uint8List body;
  late final HttpServer server;
  final ranges = <String?>[];
  int requests = 0;
  int bytesServed = 0;

  String get url => 'http://127.0.0.1:${server.port}/resolve/model.gguf';

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests++;
      final res = req.response;
      if (req.uri.path == '/resolve/model.gguf') {
        res.statusCode = HttpStatus.found;
        res.headers.set(HttpHeaders.locationHeader, '/cdn/model.gguf');
        await res.close();
        return;
      }
      final range = req.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);
      var start = 0;
      var end = body.length - 1;
      if (range != null) {
        final m = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range)!;
        start = int.parse(m.group(1)!);
        if (m.group(2)!.isNotEmpty) end = int.parse(m.group(2)!);
        if (start >= body.length) {
          res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          res.contentLength = 0;
          await res.close();
          return;
        }
        res.statusCode = HttpStatus.partialContent;
        res.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/${body.length}',
        );
      }
      final chunk = body.sublist(start, end + 1);
      res.contentLength = chunk.length;
      bytesServed += chunk.length;
      res.add(chunk);
      await res.close();
    });
  }
}

void main() {
  late Directory dir;
  late _FakeHub hub;
  final body = Uint8List.fromList(List.generate(200000, (i) => i % 251));

  setUpAll(() {
    // The service checks for the native downloader over a platform channel;
    // the test binding provides one (no native side → in-process download).
    TestWidgetsFlutterBinding.ensureInitialized();
    // The test binding blocks real HTTP; these tests use a local server.
    HttpOverrides.global = null;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('dl_resume_');
    hub = _FakeHub(body);
    await hub.start();
  });

  tearDown(() async {
    await hub.server.close(force: true);
    await dir.delete(recursive: true);
  });

  Future<bool> run(String id, String dest) =>
      ModelDownloadService.instance.runSingleFile(
        id: id,
        displayName: 'Test model',
        url: hub.url,
        destPath: dest,
      );

  test('fresh download through the redirect', () async {
    final dest = '${dir.path}/fresh.gguf';
    expect(await run('fresh', dest), isTrue);
    expect(await File(dest).readAsBytes(), body);
    expect(File('$dest.part').existsSync(), isFalse);
  });

  test('resume keeps Range across the redirect', () async {
    final dest = '${dir.path}/resume.gguf';
    await File('$dest.part').writeAsBytes(body.sublist(0, 80000));
    expect(await run('resume', dest), isTrue);
    expect(await File(dest).readAsBytes(), body);
    expect(hub.ranges.first, 'bytes=80000-');
    expect(hub.bytesServed, body.length - 80000);
  });

  test('already complete partial finishes without downloading again',
      () async {
    final dest = '${dir.path}/complete.gguf';
    await File('$dest.part').writeAsBytes(body);
    expect(await run('complete', dest), isTrue);
    expect(await File(dest).readAsBytes(), body);
    // 416, then a one-byte size probe; never the whole file.
    expect(hub.bytesServed, lessThanOrEqualTo(1));
  });

  test('Android marker: finished while the app was closed, no network',
      () async {
    final dest = '${dir.path}/marked.gguf';
    final part = '$dest.part';
    await File(part).writeAsBytes(body);
    await File(ModelDownloadService.completeMarkerPath(part))
        .writeAsString('${body.length}');
    expect(await run('marked', dest), isTrue);
    expect(await File(dest).readAsBytes(), body);
    expect(hub.requests, 0);
    expect(File(ModelDownloadService.completeMarkerPath(part)).existsSync(),
        isFalse);
  });

  test('marker for a different size is ignored and the download resumes',
      () async {
    final dest = '${dir.path}/stale.gguf';
    final part = '$dest.part';
    await File(part).writeAsBytes(body.sublist(0, 50000));
    await File(ModelDownloadService.completeMarkerPath(part))
        .writeAsString('${body.length}');
    expect(await run('stale', dest), isTrue);
    expect(await File(dest).readAsBytes(), body);
    expect(hub.ranges.first, 'bytes=50000-');
    expect(File(ModelDownloadService.completeMarkerPath(part)).existsSync(),
        isFalse);
  });
}
