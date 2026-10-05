import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Actions that can be triggered from widgets or deep links
enum DeepLinkAction {
  newChat,
  newChatWithCamera,
  openChat,        // arg: conversationId
  openFolder,      // arg: folderId
  startPersonaChat, // arg: personaId
  openNewsWidget,
  runShortcut,     // arg: full lmmini://shortcut/... URL (parsed by ShortcutsHandler)
}

/// Service to handle deep links from iOS widgets and other sources
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static const _channel = MethodChannel('net.neuro9.lmmini/deeplink');

  final _actionController =
      StreamController<DeepLinkActionEvent>.broadcast();
  Stream<DeepLinkActionEvent> get actionStream => _actionController.stream;

  // Store pending action if app was launched from widget
  DeepLinkActionEvent? _pendingAction;
  DeepLinkActionEvent? get pendingAction => _pendingAction;

  void clearPendingAction() {
    _pendingAction = null;
  }

  Future<void> initialize() async {
    // Set up method channel to receive actions from native code
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Check for initial launch action
    try {
      final String? initialAction = await _channel.invokeMethod('getInitialAction');
      if (initialAction != null) {
        final action = _parseAction(initialAction);
        if (action != null) {
          _pendingAction = action;
          if (kDebugMode) {
            print('DeepLinkService: Initial action: $action');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkService: Error getting initial action: $e');
      }
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'handleAction':
        final String actionString = call.arguments as String;
        final action = _parseAction(actionString);
        if (action != null) {
          if (kDebugMode) {
            print('DeepLinkService: Received action: $action');
          }
          // If no one is listening yet (e.g. splash screen showing),
          // store as pending so HomeScreen picks it up on mount.
          if (!_actionController.hasListener) {
            if (kDebugMode) {
              print('DeepLinkService: No listener — storing as pending');
            }
            _pendingAction = action;
          } else {
            _actionController.add(action);
          }
        }
        break;
    }
  }

  DeepLinkActionEvent? _parseAction(String actionString) {
    // Action strings can be a bare token (e.g. "newChat") or a token with
    // an argument separated by a colon (e.g. "openChat:1716592834010" or
    // "personaChat:abc-123").
    final colon = actionString.indexOf(':');
    final token =
        colon < 0 ? actionString : actionString.substring(0, colon);
    final arg = colon < 0 ? null : actionString.substring(colon + 1);

    DeepLinkAction? action;
    switch (token) {
      case 'newChat':
        action = DeepLinkAction.newChat;
        break;
      case 'newChatWithCamera':
        action = DeepLinkAction.newChatWithCamera;
        break;
      case 'openChat':
        action = DeepLinkAction.openChat;
        break;
      case 'openFolder':
        action = DeepLinkAction.openFolder;
        break;
      case 'personaChat':
        action = DeepLinkAction.startPersonaChat;
        break;
      case 'openNews':
        action = DeepLinkAction.openNewsWidget;
        break;
      case 'shortcut':
        // Carries the full lmmini://shortcut/<path>?query URL so the
        // ShortcutsHandler can parse path + query items itself.
        action = DeepLinkAction.runShortcut;
        break;
      default:
        if (kDebugMode) {
          print('DeepLinkService: Unknown action: $actionString');
        }
        return null;
    }
    return DeepLinkActionEvent(action, arg);
  }

  void dispose() {
    _actionController.close();
  }
}

/// Carries a [DeepLinkAction] plus an optional argument string (e.g. the
/// conversation/folder/persona id) so listeners can route appropriately.
class DeepLinkActionEvent {
  final DeepLinkAction action;
  final String? arg;
  const DeepLinkActionEvent(this.action, [this.arg]);

  @override
  String toString() =>
      arg == null ? action.toString() : '${action.name}:$arg';
}
