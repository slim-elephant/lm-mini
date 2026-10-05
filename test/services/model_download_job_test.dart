import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/model_download_job.dart';

void main() {
  test('ModelDownloadJob serializes and deserializes', () {
    final job = ModelDownloadJob(
      id: ModelDownloadJobIds.kokoro,
      displayName: 'Kokoro TTS',
      kind: ModelDownloadJobKind.archive,
      sourceUrl: 'https://example.com/model.tar.bz2',
      destPath: '/tmp/model.tar.bz2',
      extractDir: '/tmp/tts_models',
      status: ModelDownloadJobStatus.downloading,
      progress: 0.42,
      bytesDownloaded: 42000,
      bytesTotal: 100000,
    );

    final restored = ModelDownloadJob.fromJson(job.toJson());
    expect(restored.id, job.id);
    expect(restored.kind, ModelDownloadJobKind.archive);
    expect(restored.status, ModelDownloadJobStatus.downloading);
    expect(restored.progress, 0.42);
    expect(restored.partialPath, '${job.destPath}.part');
  });

  test('isActive covers queued downloading extracting', () {
    final job = ModelDownloadJob(
      id: 'test',
      displayName: 'Test',
      kind: ModelDownloadJobKind.singleFile,
      sourceUrl: 'https://example.com/a.bin',
      destPath: '/tmp/a.bin',
      status: ModelDownloadJobStatus.extracting,
    );
    expect(job.isActive, isTrue);
  });
}
