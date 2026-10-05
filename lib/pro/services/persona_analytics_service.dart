// LM-MINI-PRO-STUB
import 'package:flutter/foundation.dart';

/// Public-build stub: per-persona usage stats (the persona profile analytics
/// strip) are part of LM Mini Pro, so nothing is recorded or stored.
class PersonaAnalyticsService extends ChangeNotifier {
  static final PersonaAnalyticsService instance = PersonaAnalyticsService._();
  PersonaAnalyticsService._();

  Future<void> load() async {}

  Future<void> recordAssistantTurn({
    required String? personaId,
    required String assistantText,
    double? tokensPerSecond,
  }) async {}
}
