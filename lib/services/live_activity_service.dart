// dart:io and lm_mini_premium are used only by the Pro part; the public stub
// part does not reference them.
// ignore: unused_import
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';

part '../pro/live_activity/live_activity_native.dart';

const kLiveActivityKindChat = 'chat';
const kLiveActivityKindImage = 'image';

/// Lock-screen / notification copy for image generation.
String imageGenerationLiveActivityStatusText(double progress) {
  final clamped = progress.clamp(0.0, 1.0);
  if (clamped >= 0.05) {
    return 'Generating image · ${(clamped * 100).toInt()}%';
  }
  return 'Generating image...';
}

String imageGenerationLiveActivityModelName(AppSettings settings) {
  final selected = settings.imageGenSelectedModel?.trim();
  if (selected != null && selected.isNotEmpty) return selected;
  switch (settings.imageGenProvider) {
    case 'comfyui':
      return 'ComfyUI';
    case 'onDevice':
      return 'On-device image';
    default:
      return 'Image generation';
  }
}

/// iOS ends Live Activities when the app becomes active. Recreate on
/// background if a generation hold is still open and nothing is showing.
bool liveActivityShouldReassert({
  required int holdCount,
  required bool currentlyShowing,
}) =>
    holdCount > 0 && !currentlyShowing;

/// Flutter bridge to generation progress while the user is outside the app.
///
/// - **iOS 16.2+**: Live Activity on Lock Screen and Dynamic Island.
/// - **Android**: Low-priority foreground-service notification for all chat
///   providers (on-device, LM Studio, cloud). Keeps the app process and HTTP
///   stream alive when the user backgrounds the app during generation.
///
/// Chat and image generation share one session (ref-counted) so auto-image
/// after a reply can reuse the same banner. Live Activity UI is Pro-only
/// ([AppSettings.liveActivityEnabled] + premium). Wake lock is held for every
/// user so the HTTP/WebSocket job is not killed when the screen sleeps.
class LiveActivityService {
  // Pro part only; unused with the public stub part.
  // ignore: unused_field
  static const _channel = MethodChannel('net.neuro9.lmmini/liveactivity');

  static final LiveActivityService instance = LiveActivityService._();

  factory LiveActivityService() => instance;

  // ignore: unused_field
  DateTime? _activityStartTime;
  DateTime? _lastImageUpdate;
  // Written only by the Pro part.
  // ignore: prefer_final_fields
  bool _active = false;
  int _holdCount = 0;
  bool _wakeLockHeld = false;
  String _modelName = 'AI Model';
  String _kind = kLiveActivityKindChat;
  String _chatTitle = 'Chat';
  double _lastProgress = 0;
  AppSettings? _lastSettings;

  bool get isActive => _active;
  String get kind => _kind;

  LiveActivityService._() {
    _proAttachChannelHandler();
  }

  /// Pro users who enabled Live Activity in Settings.
  static bool isEnabledFor(AppSettings settings) =>
      instance._proIsEnabledFor(settings);

  /// Whether generation progress is supported and enabled on this device.
  Future<bool> get isAvailable => _proIsAvailable();

  /// Hold wake lock (everyone) and start/reuse Live Activity (Pro + setting).
  ///
  /// [holdCount] is incremented synchronously so a fire-and-forget image job
  /// can attach before the chat `finally` releases.
  Future<void> acquire({
    required AppSettings settings,
    required String modelName,
    String chatTitle = 'Chat',
    String kind = kLiveActivityKindChat,
  }) async {
    _holdCount++;
    _modelName = modelName;
    _chatTitle = chatTitle;
    _kind = kind;
    _lastSettings = settings;
    if (kind != kLiveActivityKindImage) {
      _lastProgress = 0;
    }
    try {
      if (!_wakeLockHeld) {
        await WakelockPlus.enable();
        _wakeLockHeld = true;
        debugPrint('🔒 Wake lock enabled – screen will stay on');
      }
    } catch (e) {
      debugPrint('⚠️ Could not enable wake lock: $e');
    }
    if (!isEnabledFor(settings)) return;
    if (!_active) {
      await startActivity(
        modelName: modelName,
        chatTitle: chatTitle,
        kind: kind,
      );
    }
    if (kind == kLiveActivityKindImage && _active) {
      _lastImageUpdate = null;
      await updateActivity(
        status: 'imaging',
        statusText: imageGenerationLiveActivityStatusText(0),
        modelName: modelName,
        kind: kind,
        progress: 0,
      );
    }
  }

  Future<void> updateImageProgress(double progress) async {
    final clamped = progress.clamp(0.0, 1.0);
    _lastProgress = clamped;
    if (!_active) return;
    final now = DateTime.now();
    if (_lastImageUpdate != null &&
        now.difference(_lastImageUpdate!).inMilliseconds < 400 &&
        progress < 0.99) {
      return;
    }
    _lastImageUpdate = now;
    await updateActivity(
      status: 'imaging',
      statusText: imageGenerationLiveActivityStatusText(clamped),
      modelName: _modelName,
      kind: kLiveActivityKindImage,
      progress: clamped,
    );
  }

  /// Drop one hold, or [force] all holds (cancel / error UI teardown).
  Future<void> release({bool force = false}) async {
    if (force) {
      _holdCount = 0;
    } else if (_holdCount > 0) {
      _holdCount--;
    }
    if (_holdCount > 0) {
      if (_kind == kLiveActivityKindImage) {
        _kind = kLiveActivityKindChat;
      }
      return;
    }
    _lastImageUpdate = null;
    _kind = kLiveActivityKindChat;
    _lastProgress = 0;
    _lastSettings = null;
    await endActivity();
    if (_wakeLockHeld) {
      try {
        await WakelockPlus.disable();
        debugPrint('🔓 Wake lock disabled');
      } catch (e) {
        debugPrint('⚠️ Could not disable wake lock: $e');
      }
      _wakeLockHeld = false;
    }
  }

  /// Recreate the banner after iOS dismissed it because the app was opened.
  Future<void> reassertIfNeeded() async {
    if (!liveActivityShouldReassert(
      holdCount: _holdCount,
      currentlyShowing: _active,
    )) {
      return;
    }
    final settings = _lastSettings;
    if (settings == null || !isEnabledFor(settings)) return;
    await startActivity(
      modelName: _modelName,
      chatTitle: _chatTitle,
      kind: _kind,
      progress: _lastProgress,
    );
  }

  /// Start showing generation progress for the current chat turn.
  Future<bool> startActivity({
    required String modelName,
    String chatTitle = 'Chat',
    String kind = kLiveActivityKindChat,
    double progress = 0.0,
  }) =>
      _proStartActivity(
        modelName: modelName,
        chatTitle: chatTitle,
        kind: kind,
        progress: progress,
      );

  /// Update generation progress (throttled by the caller).
  Future<void> updateActivity({
    required String status,
    required String statusText,
    required String modelName,
    int tokenCount = 0,
    double tokensPerSecond = 0.0,
    String kind = kLiveActivityKindChat,
    double progress = 0.0,
  }) =>
      _proUpdateActivity(
        status: status,
        statusText: statusText,
        modelName: modelName,
        tokenCount: tokenCount,
        tokensPerSecond: tokensPerSecond,
        kind: kind,
        progress: progress,
      );

  /// Stop showing generation progress.
  Future<void> endActivity() => _proEndActivity();
}
