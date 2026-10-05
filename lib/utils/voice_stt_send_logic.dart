import 'dart:async';

import '../models/stt_recognition_result.dart';
import 'whisper_transcript_stabilizer.dart';

/// Buffers STT text and only triggers [onSend] after [pauseForSeconds] of
/// **no speech activity** (no interim or final results).
///
/// iOS ends each mic session after ~10–20s of continuous audio (Apple's
/// SFSpeechRecognizer limit). The app restarts the mic and commits interim
/// text across sessions. Send timing must NOT follow iOS phrase finals or
/// the plugin's OS-level pauseFor — only user-configured silence.
class VoiceSttSendLogic {
  VoiceSttSendLogic({
    required this.onSend,
    required this.onDisplayTextChanged,
  });

  final void Function(String text) onSend;
  final void Function(String displayText) onDisplayTextChanged;

  String _committed = '';
  String _sessionInterim = '';
  Timer? _sendTimer;
  bool _sessionJustCommitted = false;

  String get committedText => _committed;

  String get displayText {
    if (_sessionInterim.isEmpty) return _committed;
    if (_committed.isEmpty) return _sessionInterim;
    if (_sessionJustCommitted &&
        !_interimContinuesCommitted(_committed, _sessionInterim)) {
      return _committed;
    }
    return _mergePhrase(_committed, _sessionInterim);
  }

  bool get hasPendingSend => _sendTimer?.isActive ?? false;

  bool get hasBufferedSpeech =>
      _committed.trim().isNotEmpty || _sessionInterim.trim().isNotEmpty;

  void handleResult(
    SttRecognitionResult result,
    int pauseForSeconds,
  ) {
    final phrase = result.recognizedWords.trim();

    if (result.finalResult) {
      _sessionInterim = '';
      if (phrase.isNotEmpty) {
        if (_sessionJustCommitted &&
            _isLikelyRestartArtifact(_committed, phrase)) {
          _sessionJustCommitted = false;
          _emitDisplay();
          _scheduleSendAfterSilence(pauseForSeconds);
          return;
        }
        _sessionJustCommitted = false;
        _committed = _mergePhrase(_committed, phrase);
      }
    } else if (phrase.isNotEmpty) {
      if (_sessionInterim.isEmpty ||
          WhisperTranscriptStabilizer.shouldAcceptInterimUpdate(
            _sessionInterim,
            phrase,
          )) {
        _sessionInterim = phrase;
      }
      if (_sessionJustCommitted &&
          _interimContinuesCommitted(_committed, phrase)) {
        _sessionJustCommitted = false;
      }
    }

    _emitDisplay();
    if (!hasBufferedSpeech) return;

    // Any speech activity resets the silence countdown — including iOS phrase
    // finals mid-utterance and new interims after a mic session restart.
    _scheduleSendAfterSilence(pauseForSeconds);
  }

  /// Preserve in-progress speech when the OS ends a mic session without final.
  void commitSession() {
    if (_sessionInterim.isNotEmpty) {
      _committed = _mergePhrase(_committed, _sessionInterim);
      _sessionInterim = '';
      _sessionJustCommitted = true;
    }
    cancelPendingSend();
    _emitDisplay();
  }

  /// Call when the amplitude monitor detects speech activity (even before
  /// any text is decoded).  This keeps the send timer alive so a slow
  /// decode cycle can't race the countdown while the user is mid-sentence.
  void notifySpeechActivity(int pauseForSeconds) {
    if (!hasBufferedSpeech && !(_sendTimer?.isActive ?? false)) return;
    _scheduleSendAfterSilence(pauseForSeconds);
  }

  void cancelPendingSend() {
    _sendTimer?.cancel();
    _sendTimer = null;
  }

  void flushNow() {
    commitSession();
    cancelPendingSend();
    final text = _committed.trim();
    if (text.isNotEmpty) {
      onSend(text);
    }
  }

  void reset() {
    cancelPendingSend();
    _committed = '';
    _sessionInterim = '';
    _sessionJustCommitted = false;
    _emitDisplay();
  }

  void dispose() {
    cancelPendingSend();
  }

  void _scheduleSendAfterSilence(int pauseForSeconds) {
    cancelPendingSend();
    final pause = pauseForSeconds.clamp(1, 300);
    _sendTimer = Timer(Duration(seconds: pause), () {
      _sendTimer = null;
      if (_sessionInterim.isNotEmpty) {
        _committed = _mergePhrase(_committed, _sessionInterim);
        _sessionInterim = '';
      }
      final text = _committed.trim();
      if (text.isNotEmpty) {
        onSend(text);
      }
    });
  }

  void _emitDisplay() {
    onDisplayTextChanged(displayText);
  }

  static String _mergePhrase(String base, String phrase) {
    if (base.isEmpty) return phrase;
    if (phrase.isEmpty) return base;
    if (phrase == base) return base;

    final b = base.trim();
    final p = phrase.trim();
    if (p.startsWith(b)) return p;
    if (b.endsWith(p)) return b;

    final normB = _normalize(b);
    final normP = _normalize(p);
    // Same content re-decoded with different punctuation/casing —
    // appending it would duplicate the phrase ("Hello. Hello").
    if (normB == normP) return b;
    if (normP.startsWith(normB)) return p;
    if (normB.endsWith(normP)) return b;

    return WhisperTranscriptStabilizer.collapseRepeats('$b $p');
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Short unrelated final after a long commit — typical iOS restart noise.
  static bool _isLikelyRestartArtifact(String committed, String phrase) {
    if (committed.length < 30) return false;
    if (phrase.length > committed.length * 0.4) return false;

    final tailWords = committed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .reversed
        .take(10)
        .toSet();
    for (final word in phrase.toLowerCase().split(RegExp(r'\s+'))) {
      if (word.length >= 3 && tailWords.contains(word)) {
        return false;
      }
    }
    return true;
  }

  static bool _interimContinuesCommitted(String committed, String interim) {
    if (committed.isEmpty) return true;
    if (interim.length >= committed.length * 0.45) return true;

    final lowerInterim = interim.toLowerCase();
    final lowerCommitted = committed.toLowerCase();
    if (lowerInterim.startsWith(lowerCommitted)) return true;

    final tailWords = committed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .reversed
        .take(8)
        .toSet();
    for (final word in interim.toLowerCase().split(RegExp(r'\s+'))) {
      if (word.length >= 3 && tailWords.contains(word)) {
        return true;
      }
    }
    return false;
  }
}
