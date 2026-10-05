import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../models/app_settings.dart';
import 'siri_inference_snapshot.dart';

/// Dart half of the iOS Siri wait-and-return bridge.
///
/// Native `AskLMMiniIntent` writes a `waitId` into the shortcut URL, waits on
/// App Group UserDefaults, and speaks whatever we post here. Snapshot sync
/// lets a background App Intent call LM Studio / cloud without Flutter.
class SiriIntentBridge {
  SiriIntentBridge._();

  static const channelName = 'net.neuro9.lmmini/siri';
  static const waitIdParam = 'waitId';
  static const MethodChannel _channel = MethodChannel(channelName);

  static bool get _supported => !kIsWeb && Platform.isIOS;

  static Future<void> syncFromSettings(
    AppSettings settings, {
    CloudApiProvider? cloud,
  }) async {
    if (!_supported) return;
    var provider = cloud;
    if (provider == null) {
      final kind = settings.activeProviderKind;
      if (kind == 'cloud' || CloudApiType.isFreeLocalKind(kind)) {
        try {
          provider = CloudApiService().activeProvider;
        } catch (_) {
          provider = null;
        }
      }
    }
    final snap = SiriInferenceSnapshot.from(
      settings: settings,
      cloud: provider,
    );
    try {
      await _channel.invokeMethod('syncSnapshot', snap.toMap());
    } catch (e) {
      if (kDebugMode) debugPrint('SiriIntentBridge.syncFromSettings: $e');
    }
  }

  static String? waitIdOf(Uri uri) {
    final id = (uri.queryParameters[waitIdParam] ?? '').trim();
    return id.isEmpty ? null : id;
  }

  static bool isWaiting(Uri uri) => waitIdOf(uri) != null;

  static Future<void> complete({
    required String waitId,
    required String text,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('complete', {
        'waitId': waitId,
        'text': text,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('SiriIntentBridge.complete: $e');
    }
  }

  static Future<void> fail({
    required String waitId,
    required String error,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('fail', {
        'waitId': waitId,
        'error': error,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('SiriIntentBridge.fail: $e');
    }
  }

  static Future<void> completeUri(Uri uri, String text) async {
    final id = waitIdOf(uri);
    if (id == null) return;
    await complete(waitId: id, text: text);
  }

  static Future<void> failUri(Uri uri, Object error) async {
    final id = waitIdOf(uri);
    if (id == null) return;
    await fail(waitId: id, error: error.toString());
  }
}
