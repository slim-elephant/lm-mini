// LM-MINI-PRO-STUB
import 'package:flutter/foundation.dart';

import '../../models/elevenlabs_voice.dart';

/// Public-build stub: ElevenLabs cloud TTS is part of LM Mini Pro.
///
/// Mirrors the API that public code calls. [initialize] and [speak] return
/// false so callers fall back to the system voice; callbacks are never invoked.
class ElevenLabsTtsService {
  static final ElevenLabsTtsService _instance =
      ElevenLabsTtsService._internal();
  factory ElevenLabsTtsService() => _instance;
  ElevenLabsTtsService._internal();

  static const defaultModelId = ElevenLabsTtsModels.defaultId;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onError;
  VoidCallback? onPlaybackStart;

  bool get isInitialized => false;
  bool get isSpeaking => false;
  bool get isStreaming => false;
  String? get voiceId => null;
  String get modelId => defaultModelId;
  double get speed => 1.0;
  List<ElevenLabsVoice> get cachedVoices => const [];

  void setApiKey(String? key) {}

  void setVoiceId(String? id) {}

  void setModelId(String? id) {}

  void setSpeed(double speed) {}

  String? displayNameFor(String? voiceId) => null;

  Future<bool> initialize({
    String? apiKey,
    String? voiceId,
    String? modelId,
    double? speed,
  }) async =>
      false;

  Future<List<ElevenLabsVoice>> listVoices({String? apiKey}) async => const [];

  Future<bool> speak(String text) async => false;

  Future<void> stop() async {}

  void startStreaming() {}

  void feedText(String chunk) {}

  void finishStreaming() {}

  Future<void> dispose() async {}
}
