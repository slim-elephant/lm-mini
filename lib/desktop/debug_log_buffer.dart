import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../utils/log_redaction.dart';

/// App-wide ring buffer of [debugPrint] lines for the Nerds console.
///
/// Install once at startup via [install]; Nerds reads [lines] without needing
/// to re-hook [debugPrint] per screen.
class DebugLogBuffer {
  DebugLogBuffer._();
  static final DebugLogBuffer instance = DebugLogBuffer._();

  static const int capacity = 800;
  final ListQueue<String> _lines = ListQueue<String>(capacity);
  final List<VoidCallback> _listeners = [];
  void Function(String?, {int? wrapWidth})? _original;
  bool _installed = false;

  List<String> get lines => List<String>.unmodifiable(_lines);

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void clear() {
    _lines.clear();
    _notify();
  }

  /// Append a line without going through [debugPrint] (used by error capture).
  void addLine(String message) {
    if (message.isEmpty) return;
    final sanitized = redactLogSecrets(message);
    if (sanitized.isEmpty) return;
    if (_lines.length >= capacity) _lines.removeFirst();
    _lines.add(sanitized);
    _notify();
  }

  void install() {
    if (_installed) return;
    _installed = true;
    _original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      final sanitized = message == null ? null : redactLogSecrets(message);
      _original?.call(sanitized, wrapWidth: wrapWidth);
      if (sanitized == null || sanitized.isEmpty) return;
      addLine(sanitized);
    };
  }

  void _notify() {
    for (final l in List<VoidCallback>.from(_listeners)) {
      l();
    }
  }
}
