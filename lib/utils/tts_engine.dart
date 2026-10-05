import '../pro/pro_features.dart';

/// TTS engine ids stored on [AppSettings.voiceTtsProvider].
abstract final class TtsEngine {
  static const native = 'native';
  static const kokoro = 'kokoro';
  static const kokoroRemote = 'kokoro_remote';
  static const elevenLabs = 'elevenlabs';
  static const grok = 'grok';

  /// Engine id to dispatch on. Public builds have no cloud TTS, so a stored
  /// ElevenLabs / Grok choice falls back to the system voice; the official
  /// build returns [id] unchanged. Settings UI and persistence keep [id].
  static String effective(String id) =>
      (!ProFeatures.included && (id == elevenLabs || id == grok)) ? native : id;

  static bool usesSentenceStreaming(String provider) =>
      provider == kokoro ||
      provider == kokoroRemote ||
      provider == elevenLabs ||
      provider == grok;
}
