import 'package:shared_preferences/shared_preferences.dart';

/// Default transcription options (separate from voice-chat settings).
class TranscriptionPreferences {
  TranscriptionPreferences._();

  static const _kIncludeTimestamps = 'transcription_include_timestamps';
  static const _kTimestampGranularity = 'transcription_timestamp_granularity';
  static const _kLanguage = 'transcription_language';

  static Future<bool> includeTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIncludeTimestamps) ?? true;
  }

  static Future<String> timestampGranularity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTimestampGranularity) ?? 'phrase';
  }

  static Future<String> language() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguage) ?? 'auto';
  }

  static Future<void> setIncludeTimestamps(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncludeTimestamps, value);
  }

  static Future<void> setTimestampGranularity(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTimestampGranularity, value);
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
  }
}
