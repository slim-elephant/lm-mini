import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/voice_catalog_entry.dart';
import 'package:lm_mini/services/voice_pack_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoicePackImportService.normalizeUrl', () {
    final svc = VoicePackImportService.instance;

    test('trims whitespace', () {
      expect(
        svc.normalizeUrl('  https://example.com/a.tar.bz2  '),
        'https://example.com/a.tar.bz2',
      );
    });

    test('rewrites github blob URLs to raw', () {
      expect(
        svc.normalizeUrl(
          'https://github.com/org/repo/blob/main/path/vits.tar.bz2',
        ),
        'https://raw.githubusercontent.com/org/repo/main/path/vits.tar.bz2',
      );
    });
  });

  group('VoiceCatalogEntry', () {
    test('round-trips json', () {
      const e = VoiceCatalogEntry(
        id: 'vits-piper-en_us-amy-low',
        name: 'Amy',
        engine: 'vits',
        language: 'en',
        locale: 'en_US',
        downloadUrl:
            'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-low.tar.bz2',
        sizeBytes: 12345,
        isPro: true,
      );
      final back = VoiceCatalogEntry.fromJson(e.toJson());
      expect(back.id, e.id);
      expect(back.name, e.name);
      expect(back.engine, 'vits');
      expect(back.locale, 'en_US');
      expect(back.downloadUrl, e.downloadUrl);
      expect(back.isPro, true);
    });
  });
}
