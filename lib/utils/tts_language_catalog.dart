import 'dart:io';

import 'package:path/path.dart' as p;

enum TtsEngineKind { kokoro, vits }

class TtsAssetSpec {
  const TtsAssetSpec({
    required this.id,
    required this.engine,
    required this.url,
    required this.name,
    required this.sizeMB,
    required this.requiredFiles,
    this.lexiconFiles = const [],
    this.ruleFstFiles = const [],
  });

  final String id;
  final TtsEngineKind engine;
  final String url;
  final String name;
  final int sizeMB;
  final List<String> requiredFiles;
  final List<String> lexiconFiles;
  final List<String> ruleFstFiles;

  String get jobId => 'asset:$id';
}

class TtsLanguageSpec {
  const TtsLanguageSpec({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.assetId,
    this.fallbackAssetId,
    this.kokoroLang,
    required this.defaultSid,
    required this.voiceLabel,
  });

  final String id;
  final String name;
  final String nativeName;
  final String flag;
  final String assetId;
  final String? fallbackAssetId;
  final String? kokoroLang;
  final int defaultSid;
  final String voiceLabel;

  bool get sharesKokoroPack => assetId == TtsLanguageCatalog.multiLangId;
}

/// Same language packs as LM Mini Connect (app locales: en, es, de, fr, ru, zh).
abstract final class TtsLanguageCatalog {
  static const multiLangId = 'kokoro-multi-lang-v1_0';
  static const englishId = 'kokoro-en-v0_19';
  static const piperDeId = 'vits-piper-de_DE-thorsten-medium-fp16';
  static const piperRuId = 'vits-piper-ru_RU-irina-medium-fp16';

  /// English UI ids 0–10. [mapSpeakerId] remaps these onto the multilingual
  /// pack (0 = Alloy, not the legacy `af` dump name).
  static const englishSpeakers = <Map<String, dynamic>>[
    {'id': 0, 'code': 'af_alloy', 'name': 'Alloy', 'gender': 'female'},
    {'id': 1, 'code': 'af_bella', 'name': 'Bella', 'gender': 'female'},
    {'id': 2, 'code': 'af_nicole', 'name': 'Nicole', 'gender': 'female'},
    {'id': 3, 'code': 'af_sarah', 'name': 'Sarah', 'gender': 'female'},
    {'id': 4, 'code': 'af_sky', 'name': 'Sky', 'gender': 'female'},
    {'id': 5, 'code': 'am_adam', 'name': 'Adam', 'gender': 'male'},
    {'id': 6, 'code': 'am_michael', 'name': 'Michael', 'gender': 'male'},
    {'id': 7, 'code': 'bf_emma', 'name': 'Emma (British)', 'gender': 'female'},
    {
      'id': 8,
      'code': 'bf_isabella',
      'name': 'Isabella (British)',
      'gender': 'female',
    },
    {
      'id': 9,
      'code': 'bm_george',
      'name': 'George (British)',
      'gender': 'male',
    },
    {
      'id': 10,
      'code': 'bm_lewis',
      'name': 'Lewis (British)',
      'gender': 'male',
    },
  ];

  static const assets = <String, TtsAssetSpec>{
    multiLangId: TtsAssetSpec(
      id: multiLangId,
      engine: TtsEngineKind.kokoro,
      url:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-multi-lang-v1_0.tar.bz2',
      name: 'Kokoro multilingual',
      sizeMB: 400,
      requiredFiles: [
        'model.onnx',
        'voices.bin',
        'tokens.txt',
        'lexicon-us-en.txt',
        'lexicon-zh.txt',
      ],
      lexiconFiles: ['lexicon-us-en.txt', 'lexicon-zh.txt'],
      ruleFstFiles: ['phone-zh.fst', 'date-zh.fst', 'number-zh.fst'],
    ),
    englishId: TtsAssetSpec(
      id: englishId,
      engine: TtsEngineKind.kokoro,
      url:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-en-v0_19.tar.bz2',
      name: 'Kokoro English (legacy)',
      sizeMB: 335,
      requiredFiles: ['model.onnx', 'voices.bin', 'tokens.txt'],
    ),
    piperDeId: TtsAssetSpec(
      id: piperDeId,
      engine: TtsEngineKind.vits,
      url:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-de_DE-thorsten-medium-fp16.tar.bz2',
      name: 'Piper German (Thorsten)',
      sizeMB: 34,
      requiredFiles: ['tokens.txt'],
    ),
    piperRuId: TtsAssetSpec(
      id: piperRuId,
      engine: TtsEngineKind.vits,
      url:
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-ru_RU-irina-medium-fp16.tar.bz2',
      name: 'Piper Russian (Irina)',
      sizeMB: 34,
      requiredFiles: ['tokens.txt'],
    ),
  };

  static const languages = <TtsLanguageSpec>[
    TtsLanguageSpec(
      id: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
      assetId: multiLangId,
      fallbackAssetId: englishId,
      kokoroLang: 'en-us',
      defaultSid: 0,
      voiceLabel: '11 Kokoro voices',
    ),
    TtsLanguageSpec(
      id: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      assetId: multiLangId,
      kokoroLang: 'es',
      defaultSid: 28,
      voiceLabel: 'Dora · Alex',
    ),
    TtsLanguageSpec(
      id: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      assetId: piperDeId,
      defaultSid: 0,
      voiceLabel: 'Thorsten',
    ),
    TtsLanguageSpec(
      id: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      assetId: multiLangId,
      kokoroLang: 'fr',
      defaultSid: 30,
      voiceLabel: 'Siwis',
    ),
    TtsLanguageSpec(
      id: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
      assetId: piperRuId,
      defaultSid: 0,
      voiceLabel: 'Irina',
    ),
    TtsLanguageSpec(
      id: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
      assetId: multiLangId,
      kokoroLang: 'zh',
      defaultSid: 47,
      voiceLabel: 'Xiaoxiao · Yunxi',
    ),
  ];

  static TtsLanguageSpec? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    final key = id.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    for (final lang in languages) {
      if (lang.id == key) return lang;
    }
    return null;
  }

  static TtsAssetSpec? assetById(String? id) => assets[id];

  static String get sharedKokoroNativeNames => languages
      .where((lang) => lang.sharesKokoroPack)
      .map((lang) => lang.nativeName)
      .join(', ');

  static bool hasChinese(String text) =>
      RegExp(r'[\u3400-\u9FFF\uF900-\uFAFF]').hasMatch(text);

  static String detect(String text, {String? requested}) {
    final asked = byId(requested);
    if (asked != null) return asked.id;

    if (RegExp(r'[\u3400-\u9FFF\uF900-\uFAFF]').hasMatch(text)) return 'zh';
    if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) return 'ru';

    final scores = <String, int>{'de': 0, 'es': 0, 'fr': 0};
    if (RegExp(r'[äöüß]', caseSensitive: false).hasMatch(text)) {
      scores['de'] = scores['de']! + 6;
    }
    if (RegExp(r'[ñ¿¡]', caseSensitive: false).hasMatch(text)) {
      scores['es'] = scores['es']! + 6;
    }
    if (RegExp(r'[àâæçéèêëïîôœùûÿ]', caseSensitive: false).hasMatch(text)) {
      scores['fr'] = scores['fr']! + 6;
    }
    if (RegExp(r'\b(der|die|das|und|nicht|ich|ein|ist|sie|mit)\b',
            caseSensitive: false)
        .hasMatch(text)) {
      scores['de'] = scores['de']! + 2;
    }
    if (RegExp(r'\b(el|los|las|una|qué|más|pero|está|como|para)\b',
            caseSensitive: false)
        .hasMatch(text)) {
      scores['es'] = scores['es']! + 2;
    }
    if (RegExp(r'\b(le|la|les|une|est|que|pas|pour|dans|avec|vous)\b',
            caseSensitive: false)
        .hasMatch(text)) {
      scores['fr'] = scores['fr']! + 2;
    }

    var best = 'en';
    var bestScore = 0;
    scores.forEach((id, score) {
      if (score > bestScore) {
        best = id;
        bestScore = score;
      }
    });
    return bestScore >= 2 ? best : 'en';
  }

  /// Prefer [preferred] if that pack is on disk, then [detected], then any
  /// ready language (catalog order). Returns null when nothing is downloaded.
  static String? pickReadyLanguage({
    String? preferred,
    String? detected,
    required Set<String> readyIds,
  }) {
    if (readyIds.isEmpty) return null;
    final order = <String>[];
    void add(String? raw) {
      final id = byId(raw)?.id;
      if (id != null && !order.contains(id)) order.add(id);
    }

    add(preferred);
    add(detected);
    for (final lang in languages) {
      add(lang.id);
    }
    for (final id in order) {
      if (readyIds.contains(id)) return id;
    }
    return null;
  }

  /// Sample line spoken by Test Voice, in the language of the ready pack.
  static String testPhraseFor(String langId) {
    switch (byId(langId)?.id) {
      case 'es':
        return 'Hola. Así es como sueno ahora.';
      case 'de':
        return 'Hallo. So klinge ich jetzt.';
      case 'fr':
        return 'Bonjour. Voici comment je sonne maintenant.';
      case 'ru':
        return 'Привет. Вот как я сейчас звучу.';
      case 'zh':
        return '你好。这就是我现在的声音。';
      default:
        return 'Hello. This is how I sound now.';
    }
  }

  /// Speakers a picker / `/tts/voices` should show for [langId].
  static List<Map<String, dynamic>> speakersFor(String? langId) {
    switch (byId(langId)?.id) {
      case 'es':
        return const [
          {'id': 28, 'code': 'ef_dora', 'name': 'Dora', 'gender': 'female'},
          {'id': 29, 'code': 'em_alex', 'name': 'Alex', 'gender': 'male'},
        ];
      case 'fr':
        return const [
          {'id': 30, 'code': 'ff_siwis', 'name': 'Siwis', 'gender': 'female'},
        ];
      case 'zh':
        return const [
          {
            'id': 45,
            'code': 'zf_xiaobei',
            'name': 'Xiaobei',
            'gender': 'female',
          },
          {
            'id': 46,
            'code': 'zf_xiaoni',
            'name': 'Xiaoni',
            'gender': 'female',
          },
          {
            'id': 47,
            'code': 'zf_xiaoxiao',
            'name': 'Xiaoxiao',
            'gender': 'female',
          },
          {
            'id': 48,
            'code': 'zf_xiaoyi',
            'name': 'Xiaoyi',
            'gender': 'female',
          },
          {
            'id': 49,
            'code': 'zm_yunjian',
            'name': 'Yunjian',
            'gender': 'male',
          },
          {'id': 50, 'code': 'zm_yunxi', 'name': 'Yunxi', 'gender': 'male'},
          {'id': 51, 'code': 'zm_yunxia', 'name': 'Yunxia', 'gender': 'male'},
          {
            'id': 52,
            'code': 'zm_yunyang',
            'name': 'Yunyang',
            'gender': 'male',
          },
        ];
      case 'de':
        return const [
          {'id': 0, 'code': 'thorsten', 'name': 'Thorsten', 'gender': 'male'},
        ];
      case 'ru':
        return const [
          {'id': 0, 'code': 'irina', 'name': 'Irina', 'gender': 'female'},
        ];
      default:
        return englishSpeakers;
    }
  }

  static String speakerDisplayName(int speakerId, {String? language}) {
    for (final s in speakersFor(language)) {
      if (s['id'] == speakerId) return s['name'] as String;
    }
    for (final lang in languages) {
      for (final s in speakersFor(lang.id)) {
        if (s['id'] == speakerId) return s['name'] as String;
      }
    }
    return 'Speaker $speakerId';
  }

  /// Payload for Home / Connect `/tts/voices`. Always includes `voices` (English
  /// UI list) so the phone picker can parse it; `languages` lists ready packs.
  static Map<String, dynamic> voicesApiPayload(Set<String> readyIds) {
    final languagePayload = <Map<String, dynamic>>[];
    for (final lang in languages) {
      if (!readyIds.contains(lang.id)) continue;
      languagePayload.add({
        'id': lang.id,
        'name': lang.name,
        'nativeName': lang.nativeName,
        'voices': speakersFor(lang.id),
      });
    }
    return {
      'modelId': readyIds.contains('en') || readyIds.contains('es')
          ? multiLangId
          : (languagePayload.isNotEmpty
              ? languagePayload.first['id']
              : englishId),
      'voices': englishSpeakers,
      'languages': languagePayload,
    };
  }

  static int mapSpeakerId(String langId, int requestedSid) {
    final lang = byId(langId);
    final sid = requestedSid;
    if (langId == 'en') {
      const map = {
        0: 0,
        1: 2,
        2: 6,
        3: 9,
        4: 10,
        5: 11,
        6: 16,
        7: 21,
        8: 22,
        9: 26,
        10: 27,
      };
      if (sid <= 10 && map.containsKey(sid)) return map[sid]!;
      return sid;
    }
    if (langId == 'zh') {
      if (sid >= 45 && sid <= 52) return sid;
      return lang?.defaultSid ?? 47;
    }
    if (langId == 'es') {
      if (sid == 28 || sid == 29) return sid;
      return 28;
    }
    if (langId == 'fr') return 30;
    return 0;
  }

  /// espeak-ng voice for Kokoro multilingual. Chinese leaves this empty so
  /// CJK goes through the lexicon; English must be `en-us` (not `en`).
  static String kokoroEspeakVoice(String langId) {
    switch (byId(langId)?.id) {
      case 'en':
        return 'en-us';
      case 'es':
        return 'es';
      case 'fr':
        return 'fr';
      default:
        return '';
    }
  }

  /// Chinese date/phone/number FSTs. Never attach these for English — they
  /// normalize Latin text to an empty string and sherpa then logs
  /// `Failed to convert '' to token IDs`.
  static bool kokoroUsesChineseRuleFsts(String langId) =>
      byId(langId)?.id == 'zh';

  /// Spanish / French use espeak + an empty lexicon file (no US/ZH lexicon).
  static bool kokoroUsesEmptyLexicon(String langId) {
    final id = byId(langId)?.id;
    return id == 'es' || id == 'fr';
  }

  static String engineGroup(String langId, {bool usingLegacyEnglish = false}) {
    if (usingLegacyEnglish) return 'kokoro:en-legacy';
    final lang = byId(langId);
    if (lang == null) return langId;
    if (lang.sharesKokoroPack) return 'kokoro:${lang.id}';
    return lang.assetId;
  }

  static String? findOnnxFile(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;
    try {
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.onnx')) {
          return entity.path;
        }
      }
    } catch (_) {}
    return null;
  }

  static bool looksLikeModelDir(String dirPath, TtsAssetSpec spec) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return false;
    if (!Directory(p.join(dirPath, 'espeak-ng-data')).existsSync()) {
      return false;
    }
    for (final file in spec.requiredFiles) {
      final f = File(p.join(dirPath, file));
      if (!f.existsSync()) return false;
      // sherpa-onnx aborts the whole app on a truncated model, so an
      // interrupted download must not count as installed.
      if (f.lengthSync() < (_minBytes[file] ?? 1)) return false;
    }
    if (spec.engine == TtsEngineKind.vits) {
      final onnx = findOnnxFile(dirPath);
      return onnx != null && File(onnx).lengthSync() >= 5 * 1024 * 1024;
    }
    return true;
  }

  /// Smallest plausible size per pack file (real files are far larger:
  /// Kokoro model.onnx is 310+ MB, voices.bin 5+ MB).
  static const Map<String, int> _minBytes = {
    'model.onnx': 50 * 1024 * 1024,
    'voices.bin': 512 * 1024,
  };

  static String joinExisting(String modelPath, List<String> names) {
    return names
        .map((name) => p.join(modelPath, name))
        .where((path) => File(path).existsSync())
        .join(',');
  }
}
