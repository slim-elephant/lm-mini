import 'locale_display_names.dart';

/// Human-readable labels for native TTS voices across Android, iOS, and macOS.
class TtsVoiceDisplay {
  TtsVoiceDisplay._();

  static final RegExp _androidLocalVoice = RegExp(
    r'^([a-z]{2})-([a-z]{2})-x-([a-z0-9]+)(?:-local)?$',
    caseSensitive: false,
  );

  static final RegExp _androidHashVoice = RegExp(
    r'^([a-z]{2})-([a-z]{2})-x-([a-z0-9]+)#',
    caseSensitive: false,
  );

  /// Primary label shown in voice pickers and settings subtitles.
  static String title({
    required String name,
    String? locale,
    int? indexWithinLocale,
  }) {
    if (name.contains('.')) {
      final parts = name.split('.');
      final last = parts.last;
      if (RegExp(r'^[A-Z][a-zA-Z]+$').hasMatch(last)) {
        return last;
      }
    }

    final androidMatch =
        _androidLocalVoice.firstMatch(name) ?? _androidHashVoice.firstMatch(name);
    if (androidMatch != null) {
      final lang = androidMatch.group(1)!;
      final region = androidMatch.group(2)!.toUpperCase();
      final localeCode = locale?.isNotEmpty == true
          ? locale!
          : '$lang-${region.toLowerCase()}';
      final languageLabel = LocaleDisplayNames.displayName(localeCode);
      if (indexWithinLocale != null) {
        return '$languageLabel · Voice ${indexWithinLocale + 1}';
      }
      return '$languageLabel · ${_variantLabel(androidMatch.group(3)!)}';
    }

    if (name.contains('#')) {
      final tail = name.split('#').last;
      return tail
          .replaceAll(RegExp(r'[-_]'), ' ')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }

    if (name.contains('-') && locale != null && locale.isNotEmpty) {
      return LocaleDisplayNames.displayName(locale);
    }

    return name
        .replaceAll(RegExp(r'[-_]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Secondary line under the title — avoids repeating raw Android IDs.
  static String subtitle({
    required String name,
    String? locale,
    String? qualityLabel,
  }) {
    final parts = <String>[];
    if (qualityLabel != null && qualityLabel.isNotEmpty) {
      parts.add(qualityLabel);
    }

    if (_androidLocalVoice.hasMatch(name) ||
        _androidHashVoice.hasMatch(name)) {
      parts.add('On-device');
    } else if (locale != null && locale.isNotEmpty) {
      parts.add(LocaleDisplayNames.displayName(locale));
    }

    return parts.isEmpty ? name : parts.join(' · ');
  }

  static String _variantLabel(String code) {
    if (code.isEmpty) return 'Voice';
    final last = code[code.length - 1].toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(last)) {
      return 'Voice $last';
    }
    return 'Voice ${code.toUpperCase()}';
  }

  /// Assign stable Voice 1 / Voice 2 labels per locale for Android lists.
  static Map<String, int> indexMapForVoices(List<Map<String, String>> voices) {
    final counts = <String, int>{};
    final indices = <String, int>{};
    for (final voice in voices) {
      final name = voice['name'] ?? '';
      final locale = (voice['locale'] ?? name).toLowerCase();
      final idx = counts[locale] ?? 0;
      indices[name] = idx;
      counts[locale] = idx + 1;
    }
    return indices;
  }
}
