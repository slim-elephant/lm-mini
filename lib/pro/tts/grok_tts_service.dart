// LM-MINI-PRO-STUB
import 'package:flutter/foundation.dart';

import '../../models/grok_voice.dart';

/// Public-build stub: Grok (xAI) cloud TTS is part of LM Mini Pro.
///
/// Mirrors the API that public code calls. [initialize] and [speak] return
/// false so callers fall back to the system voice; callbacks are never invoked.
class GrokTtsService {
  static final GrokTtsService _instance = GrokTtsService._internal();
  factory GrokTtsService() => _instance;
  GrokTtsService._internal();

  static const defaultVoiceId = GrokVoices.defaultId;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onError;
  VoidCallback? onPlaybackStart;

  bool get isInitialized => false;
  bool get isSpeaking => false;
  bool get isStreaming => false;
  String? get voiceId => null;
  double get speed => 1.0;
  List<GrokVoice> get cachedVoices => const [];

  void setApiKey(String? key) {}

  void setVoiceId(String? id) {}

  void setLanguage(String? locale) {}

  void setSpeed(double speed) {}

  String? displayNameFor(String? voiceId) => null;

  Future<bool> initialize({
    String? apiKey,
    String? voiceId,
    String? language,
    double? speed,
  }) async =>
      false;

  Future<List<GrokVoice>> listVoices({String? apiKey}) async => const [];

  Future<bool> speak(String text) async => false;

  Future<void> stop() async {}

  void startStreaming() {}

  void feedText(String chunk) {}

  void finishStreaming() {}

  Future<void> dispose() async {}
}
