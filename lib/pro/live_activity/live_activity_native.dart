// LM-MINI-PRO-STUB
part of '../../services/live_activity_service.dart';

/// Public build: no Live Activity / foreground notification. The wake lock in
/// [LiveActivityService] still keeps the screen on during generation.
extension _ProLiveActivity on LiveActivityService {
  void _proAttachChannelHandler() {}

  bool _proIsEnabledFor(AppSettings settings) => false;

  Future<bool> _proIsAvailable() async => false;

  Future<bool> _proStartActivity({
    required String modelName,
    required String chatTitle,
    required String kind,
    required double progress,
  }) async =>
      false;

  Future<void> _proUpdateActivity({
    required String status,
    required String statusText,
    required String modelName,
    required int tokenCount,
    required double tokensPerSecond,
    required String kind,
    required double progress,
  }) async {}

  Future<void> _proEndActivity() async {}
}
