import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lm_studio_model.dart';

/// Tracks which LM Studio models reject the `reasoning` API parameter so we
/// stop sending it and can disable the control in settings UI.
class ReasoningSupportService {
  static const _prefsKey = 'models_without_reasoning';
  static const _onOffOnlyPrefsKey = 'models_reasoning_on_off_only';
  static const allOptions = ['off', 'low', 'medium', 'high', 'on'];

  static final ReasoningSupportService instance = ReasoningSupportService._();
  ReasoningSupportService._();

  Set<String> _blockedModelIds = {};
  Set<String> _onOffOnlyModelIds = {};
  Map<String, List<String>> _catalogOptions = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    _blockedModelIds = raw?.toSet() ?? {};
    _onOffOnlyModelIds =
        prefs.getStringList(_onOffOnlyPrefsKey)?.toSet() ?? {};
    _loaded = true;
  }

  /// Seed from `/api/v1/models` so the toggle matches the model before a 400.
  void ingestCatalog(Iterable<LMStudioModel> models) {
    final next = <String, List<String>>{};
    for (final m in models) {
      final opts = m.reasoningAllowedOptions;
      if (opts != null) {
        next[m.id] = List<String>.from(opts);
      }
    }
    _catalogOptions = next;
  }

  /// Allowed `reasoning` values for [modelId].
  /// `null` = unknown; empty = omit the field; otherwise send only these.
  List<String>? allowedOptionsSync(String modelId) {
    if (modelId.isEmpty) return null;
    if (_loaded && _blockedModelIds.contains(modelId)) return const [];
    final catalog = _catalogFor(modelId);
    if (catalog != null) return catalog;
    if (_loaded && _onOffOnlyModelIds.contains(modelId)) {
      return const ['off', 'on'];
    }
    return null;
  }

  bool exposesReasoningApiSync(String modelId) {
    final opts = allowedOptionsSync(modelId);
    return opts == null || opts.isNotEmpty;
  }

  bool canTurnOffReasoningSync(String modelId) {
    final opts = allowedOptionsSync(modelId);
    if (opts == null) return true;
    return opts.contains('off');
  }

  List<String> dropdownOptionsSync(String modelId) {
    return allowedOptionsSync(modelId) ?? allOptions;
  }

  List<String>? _catalogFor(String modelId) {
    final direct = _catalogOptions[modelId];
    if (direct != null) return direct;
    if (modelId.contains('/')) {
      final short = modelId.split('/').last;
      final shortHit = _catalogOptions[short];
      if (shortHit != null) return shortHit;
    }
    for (final e in _catalogOptions.entries) {
      if (e.key.endsWith('/$modelId') || e.key.endsWith(':$modelId')) {
        return e.value;
      }
    }
    return null;
  }

  Future<bool> isSupported(String modelId) async {
    if (modelId.isEmpty) return true;
    await _ensureLoaded();
    return isSupportedSync(modelId);
  }

  bool isSupportedSync(String modelId) {
    if (modelId.isEmpty) return true;
    final opts = allowedOptionsSync(modelId);
    return opts == null || opts.isNotEmpty;
  }

  Future<void> markUnsupported(String modelId) async {
    if (modelId.isEmpty) return;
    await _ensureLoaded();
    _catalogOptions[modelId] = const [];
    if (_blockedModelIds.contains(modelId)) return;
    _blockedModelIds.add(modelId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _blockedModelIds.toList());
  }

  bool isOnOffOnlySync(String modelId) {
    final opts = allowedOptionsSync(modelId);
    if (opts == null) return false;
    return isOnOffOnlyList(opts);
  }

  /// Learned from `Supported settings: 'off', 'on'` — later requests map
  /// `low`/`medium`/`high` to `on` instead of 400ing every send.
  Future<void> markOnOffOnly(String modelId) async {
    if (modelId.isEmpty) return;
    await _ensureLoaded();
    _catalogOptions[modelId] = const ['off', 'on'];
    if (_onOffOnlyModelIds.contains(modelId)) return;
    _onOffOnlyModelIds.add(modelId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _onOffOnlyPrefsKey,
      _onOffOnlyModelIds.toList(),
    );
  }

  static bool isOnOffOnlyList(List<String> supported) {
    if (supported.isEmpty) return false;
    return supported.every((s) => s == 'off' || s == 'on');
  }

  /// Map a user setting onto what the model actually accepts.
  /// `null` means omit the request field.
  static String? coerceApiValue(String requested, List<String>? allowed) {
    final want = switch (requested) {
      'true' => 'low',
      'false' => 'off',
      final v => v,
    };
    if (allowed != null && allowed.isEmpty) return null;
    if (allowed == null) return want;
    if (allowed.contains(want)) return want;
    if (want == 'off') return allowed.contains('off') ? 'off' : null;
    if (allowed.contains('on')) return 'on';
    if (allowed.contains('medium')) return 'medium';
    if (allowed.contains('high')) return 'high';
    if (allowed.contains('low')) return 'low';
    return allowed.first;
  }

  static String dropdownValue(String requested, List<String> items) {
    if (items.isEmpty) return 'off';
    final mapped = coerceApiValue(requested, items);
    if (mapped != null && items.contains(mapped)) return mapped;
    return items.first;
  }

  /// True when LM Studio rejected the `reasoning` request parameter.
  static bool isReasoningConfigError(dynamic error) {
    final message = extractMessage(error)?.toLowerCase() ?? '';
    if (message.contains('does not expose reasoning')) return true;
    if (message.contains('reasoning configuration')) return true;
    if (message.contains('reasoning setting') &&
        message.contains('not supported')) {
      return true;
    }
    if (message.contains('supported settings') &&
        message.contains('reasoning')) {
      return true;
    }
    return message.contains('reasoning') &&
        message.contains('invalid') &&
        message.contains('param');
  }

  /// Parses `Supported settings: 'off', 'on'.` from an LM Studio 400.
  static List<String> parseSupportedSettings(dynamic error) {
    final message = extractMessage(error) ?? '';
    final match = RegExp(
      r"Supported settings:\s*([^\n]+)",
      caseSensitive: false,
    ).firstMatch(message);
    if (match == null) return const [];
    final listed = match.group(1)!;
    final quoted = RegExp("'(off|on|low|medium|high)'")
        .allMatches(listed)
        .map((m) => m.group(1)!)
        .toList();
    if (quoted.isNotEmpty) return quoted;
    return RegExp(r'\b(off|on|low|medium|high)\b')
        .allMatches(listed.toLowerCase())
        .map((m) => m.group(1)!)
        .toList();
  }

  /// Value to send on retry. `null` means omit the field (model has no
  /// reasoning API). Otherwise a supported `off` / `on` / level.
  static String? retryApiValue(String requested, dynamic error) {
    final supported = parseSupportedSettings(error);
    return coerceApiValue(requested, supported);
  }

  static String? extractMessage(dynamic error) {
    if (error == null) return null;
    if (error is String) return error;
    if (error is Map) {
      final msg = error['message'];
      if (msg is String) return msg;
      final nested = error['error'];
      if (nested is Map && nested['message'] is String) {
        return nested['message'] as String;
      }
      if (nested is String) return nested;
    }
    return error.toString();
  }

  /// Parse a JSON HTTP error body from LM Studio.
  static String? messageFromHttpBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return extractMessage(decoded) ?? extractMessage(decoded['error']);
      }
    } catch (_) {}
    return null;
  }

  static bool isReasoningConfigHttpBody(String body) {
    final msg = messageFromHttpBody(body);
    if (msg == null) return false;
    return isReasoningConfigError(msg);
  }
}
