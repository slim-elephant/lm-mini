import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/tts_language_catalog.dart';

void main() {
  test('app languages match Settings order', () {
    expect(
      TtsLanguageCatalog.languages.map((l) => l.id).toList(),
      ['en', 'es', 'de', 'fr', 'ru', 'zh'],
    );
  });

  test('detects script and requested locale', () {
    expect(TtsLanguageCatalog.detect('Hello world'), 'en');
    expect(TtsLanguageCatalog.detect('你好世界'), 'zh');
    expect(TtsLanguageCatalog.detect('Hello 你好'), 'zh');
    expect(TtsLanguageCatalog.detect('Привет, как дела?'), 'ru');
    expect(TtsLanguageCatalog.detect('Das ist sehr schön'), 'de');
    expect(TtsLanguageCatalog.detect('Bonjour, ça va ?'), 'fr');
    expect(TtsLanguageCatalog.detect('¿Dónde está la estación?'), 'es');
    expect(TtsLanguageCatalog.detect('Hello', requested: 'fr-FR'), 'fr');
  });

  test('picks a ready language instead of English when en is missing', () {
    expect(
      TtsLanguageCatalog.pickReadyLanguage(
        preferred: 'en-US',
        detected: 'en',
        readyIds: {'de'},
      ),
      'de',
    );
    expect(
      TtsLanguageCatalog.pickReadyLanguage(
        preferred: 'de',
        detected: 'en',
        readyIds: {'de', 'en'},
      ),
      'de',
    );
    expect(
      TtsLanguageCatalog.pickReadyLanguage(
        preferred: 'en',
        detected: 'en',
        readyIds: {'en', 'de'},
      ),
      'en',
    );
    expect(
      TtsLanguageCatalog.pickReadyLanguage(
        preferred: 'fr',
        detected: 'zh',
        readyIds: {'zh'},
      ),
      'zh',
    );
    expect(
      TtsLanguageCatalog.pickReadyLanguage(preferred: 'en', readyIds: {}),
      isNull,
    );
  });

  test('test phrase matches the ready language', () {
    expect(TtsLanguageCatalog.testPhraseFor('de'), contains('Hallo'));
    expect(TtsLanguageCatalog.testPhraseFor('en'), contains('Hello'));
  });

  test('maps speakers and engine groups', () {
    expect(TtsLanguageCatalog.engineGroup('zh'), 'kokoro:zh');
    expect(TtsLanguageCatalog.engineGroup('en'), 'kokoro:en');
    expect(TtsLanguageCatalog.engineGroup('fr'), 'kokoro:fr');
    expect(TtsLanguageCatalog.engineGroup('es'), 'kokoro:es');
    expect(TtsLanguageCatalog.kokoroEspeakVoice('en'), 'en-us');
    expect(TtsLanguageCatalog.kokoroEspeakVoice('es'), 'es');
    expect(TtsLanguageCatalog.kokoroEspeakVoice('zh'), isEmpty);
    expect(TtsLanguageCatalog.kokoroUsesChineseRuleFsts('zh'), isTrue);
    expect(TtsLanguageCatalog.kokoroUsesChineseRuleFsts('en'), isFalse);
    expect(TtsLanguageCatalog.kokoroUsesEmptyLexicon('fr'), isTrue);
    expect(TtsLanguageCatalog.kokoroUsesEmptyLexicon('en'), isFalse);
    expect(TtsLanguageCatalog.engineGroup('de'), TtsLanguageCatalog.piperDeId);
    expect(
      TtsLanguageCatalog.engineGroup('en', usingLegacyEnglish: true),
      'kokoro:en-legacy',
    );

    expect(TtsLanguageCatalog.mapSpeakerId('fr', 3), 30);
    expect(TtsLanguageCatalog.mapSpeakerId('es', 0), 28);
    expect(TtsLanguageCatalog.mapSpeakerId('zh', 47), 47);
    expect(TtsLanguageCatalog.englishSpeakers.first['name'], 'Alloy');
    expect(TtsLanguageCatalog.speakersFor('de').first['name'], 'Thorsten');
    expect(TtsLanguageCatalog.speakerDisplayName(0), 'Alloy');
    expect(
        TtsLanguageCatalog.speakerDisplayName(0, language: 'de'), 'Thorsten');
    final payload = TtsLanguageCatalog.voicesApiPayload({'en', 'de'});
    expect(payload['voices'], TtsLanguageCatalog.englishSpeakers);
    final langs = payload['languages'] as List;
    expect(langs.map((e) => (e as Map)['id']).toList(), ['en', 'de']);
    expect(TtsLanguageCatalog.mapSpeakerId('zh', 1), 47);
    expect(TtsLanguageCatalog.mapSpeakerId('en', 1), 2);
  });
}
