// Restore file — not under lib/, so it is never compiled into the IPA.
//
// Restore: agent.md → “Restore CallKit”. Copy this class into
// lib/services/call_service.dart (or import it from there).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

/// Plugin-backed session used when CallKit is restored.
class CallKitIncomingBridge {
  CallKitIncomingBridge();

  static const _uuid = Uuid();

  String? currentCallId;
  StreamSubscription<CallEvent?>? eventSubscription;
  VoidCallback? onCallEnded;

  Future<void> startCall({String callerName = 'AI Voice Chat'}) async {
    if (currentCallId != null) return;

    final callId = _uuid.v4();
    currentCallId = callId;
    listenEvents();

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'LM Mini',
      handle: 'LM Mini Call Mode',
      type: 0,
      duration: 0,
      extra: <String, dynamic>{'source': 'voice_mode'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: '',
        backgroundColor: '#1a1a2e',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Voice Chat',
        isShowCallID: false,
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: '',
      ),
    );

    await FlutterCallkitIncoming.startCall(params);
    await FlutterCallkitIncoming.setCallConnected(callId);
  }

  Future<void> endCall() async {
    final callId = currentCallId;
    if (callId == null) return;
    currentCallId = null;
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('CallKitIncomingBridge: error ending call: $e');
    }
  }

  Future<void> endAllCalls() async {
    currentCallId = null;
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('CallKitIncomingBridge: error ending all calls: $e');
    }
  }

  void listenEvents() {
    eventSubscription?.cancel();
    eventSubscription =
        FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallEnded:
        case Event.actionCallDecline:
          currentCallId = null;
          onCallEnded?.call();
          break;
        default:
          break;
      }
    });
  }

  void dispose() {
    eventSubscription?.cancel();
    eventSubscription = null;
    currentCallId = null;
  }
}
