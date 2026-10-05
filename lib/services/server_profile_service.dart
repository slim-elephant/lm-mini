import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/server_profile.dart';

/// Persists named server profiles and which one is active.
class ServerProfileService extends ChangeNotifier {
  static final ServerProfileService instance = ServerProfileService._();
  ServerProfileService._();

  static const _profilesKey = 'server_profiles_v1';
  static const _activeKey = 'server_profile_active_id';
  static const _migratedKey = 'server_profiles_v1_migrated';

  final _uuid = const Uuid();
  List<ServerProfile> _profiles = [];
  String? _activeId;
  bool _loaded = false;

  List<ServerProfile> get profiles => List.unmodifiable(_profiles);
  String? get activeId => _activeId;
  bool get isLoaded => _loaded;

  ServerProfile? get activeProfile {
    final id = _activeId;
    if (id == null) return null;
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Most recently used profiles (active first), capped at [limit].
  List<ServerProfile> recent({int limit = 3}) {
    // Collapse any leftover duplicates from earlier migration/onboarding.
    final before = _profiles.length;
    _dedupeProfiles();
    if (_profiles.length != before) {
      // Fire-and-forget persist; UI still gets the collapsed list this frame.
      _persist();
    }
    final sorted = [..._profiles]..sort((a, b) {
        if (a.id == _activeId) return -1;
        if (b.id == _activeId) return 1;
        return b.lastUsedAt.compareTo(a.lastUsedAt);
      });
    if (sorted.length <= limit) return sorted;
    return sorted.take(limit).toList();
  }

  Future<void> load({
    required AppSettings settings,
    CloudApiService? cloud,
  }) async {
    cloud ??= CloudApiService();
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_migratedKey) ?? false;

    if (!migrated) {
      await _migrateFromLegacy(settings, cloud, prefs);
    } else {
      final raw = prefs.getString(_profilesKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = json.decode(raw) as List<dynamic>;
          _profiles = list
              .map((e) => ServerProfile.fromMap(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('ServerProfileService: failed to parse profiles: $e');
          _profiles = [];
        }
      }
      _activeId = prefs.getString(_activeKey);
    }

    _ensureOnDevice();
    if (settings.usbModeEnabled &&
        !_profiles.any((p) => p.id == ServerProfile.usbId)) {
      _profiles.add(ServerProfile.usb());
    }
    _dedupeProfiles();
    if (_activeId == null || !_profiles.any((p) => p.id == _activeId)) {
      _activeId = _inferActiveId(settings, cloud);
    }
    await _persist(prefs);

    _loaded = true;
    notifyListeners();
  }

  /// Collapse duplicate LM Studio / cloud rows created by migration + onboarding.
  void _dedupeProfiles() {
    final kept = <ServerProfile>[];
    for (final p in _profiles) {
      if (p.isOnDevice) {
        if (!kept.any((k) => k.isOnDevice)) kept.add(p);
        continue;
      }
      final key = _identityKey(p);
      final existingIndex = kept.indexWhere((k) => _identityKey(k) == key);
      if (existingIndex < 0) {
        kept.add(p);
        continue;
      }
      final existing = kept[existingIndex];
      // Prefer the active id, then the newer lastUsedAt.
      final preferNew = p.id == _activeId ||
          (existing.id != _activeId &&
              p.lastUsedAt.isAfter(existing.lastUsedAt));
      if (preferNew) {
        kept[existingIndex] = p.copyWith(
          name: p.name.isNotEmpty ? p.name : existing.name,
          apiKey: p.apiKey ?? existing.apiKey,
          customHeaders: p.customHeaders ?? existing.customHeaders,
          customHeadersEnabled:
              p.customHeadersEnabled || existing.customHeadersEnabled,
        );
      }
    }
    _profiles = kept;
    if (_activeId != null && !_profiles.any((p) => p.id == _activeId)) {
      _activeId = _profiles.firstOrNull?.id;
    }
  }

  String _identityKey(ServerProfile p) {
    if (p.isOnDevice) return 'onDevice';
    if (p.isUsb) return 'usb';
    final url = normalizeServerUrl(p.baseUrl);
    if (p.kind == ServerProfileKind.lmStudio) return 'lmStudio|$url';
    return 'cloud|${p.cloudType?.name}|$url|${p.id}';
  }

  /// Normalize URL for identity comparisons.
  static String normalizeServerUrl(String? url) {
    var trimmed = (url ?? '').trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Find an existing profile that represents the same server endpoint.
  ServerProfile? findDuplicateOf(ServerProfile profile) {
    if (profile.isOnDevice) {
      return _profiles.where((p) => p.isOnDevice).firstOrNull;
    }
    if (profile.isUsb) {
      return _profiles.where((p) => p.isUsb).firstOrNull;
    }
    final url = normalizeServerUrl(profile.baseUrl);
    if (profile.kind == ServerProfileKind.lmStudio) {
      return _profiles
          .where((p) =>
              p.kind == ServerProfileKind.lmStudio &&
              normalizeServerUrl(p.baseUrl) == url)
          .firstOrNull;
    }
    // Same cloud type + same base URL (empty URL → match by type only for
    // keyed cloud APIs that share a default host would still create multiples
    // by id — only collapse when URL matches).
    if (url.isEmpty) return null;
    return _profiles
        .where((p) =>
            p.kind == ServerProfileKind.cloud &&
            p.cloudType == profile.cloudType &&
            normalizeServerUrl(p.baseUrl) == url)
        .firstOrNull;
  }

  Future<void> _migrateFromLegacy(
    AppSettings settings,
    CloudApiService cloud,
    SharedPreferences prefs,
  ) async {
    final now = DateTime.now();
    final profiles = <ServerProfile>[
      ServerProfile.onDevice(lastUsedAt: now.subtract(const Duration(days: 1))),
    ];

    final url = settings.serverUrl.trim();
    final looksLocal = url.isNotEmpty &&
        !url.contains('lm-mini-relay') &&
        !url.contains('connect.lmmini.com') &&
        !url.contains('relay.lmmini.com');
    // Skip the stock default so onboarding doesn't create a second LM Studio.
    final isDefaultLocalhost =
        normalizeServerUrl(url) == 'http://localhost:1234' ||
            normalizeServerUrl(url) == 'http://127.0.0.1:1234';
    final shouldImportLmStudio = looksLocal &&
        settings.hasCompletedOnboarding &&
        settings.activeProviderKind == 'lmStudio' &&
        !isDefaultLocalhost;
    if (shouldImportLmStudio) {
      profiles.add(ServerProfile(
        id: _uuid.v4(),
        name: 'LM Studio',
        kind: ServerProfileKind.lmStudio,
        baseUrl: url,
        apiKey: settings.apiToken,
        customHeaders: settings.customRequestHeaders,
        customHeadersEnabled: settings.customHeadersEnabled,
        lastUsedAt: now,
      ));
    }

    for (final p in cloud.providers) {
      profiles.add(ServerProfile(
        id: p.id,
        name: p.name,
        kind: ServerProfileKind.cloud,
        cloudType: p.type,
        baseUrl: p.baseUrl,
        apiKey: p.apiKey,
        customHeaders: p.customHeaders,
        customHeadersEnabled: p.customHeadersEnabled,
        lastUsedAt: now,
      ));
    }

    _profiles = profiles;
    _activeId = _inferActiveId(settings, cloud);
    await prefs.setBool(_migratedKey, true);
    await _persist(prefs);
  }

  String _inferActiveId(AppSettings settings, CloudApiService cloud) {
    if (settings.usbModeEnabled) {
      return ServerProfile.usbId;
    }
    final kind = settings.activeProviderKind;
    if (kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return ServerProfile.onDeviceId;
    }
    if (kind == 'lmStudio') {
      final lm = _profiles
          .where((p) => p.kind == ServerProfileKind.lmStudio)
          .firstOrNull;
      if (lm != null) return lm.id;
    }
    if (SettingsProviderKinds.isCloud(kind)) {
      final active = cloud.activeProvider;
      if (active != null && _profiles.any((p) => p.id == active.id)) {
        return active.id;
      }
      final match = _profiles.where((p) {
        if (p.kind != ServerProfileKind.cloud) return false;
        return p.cloudType?.providerKind == kind ||
            (kind == 'cloud' && (p.cloudType?.isPremium ?? false));
      }).firstOrNull;
      if (match != null) return match.id;
    }
    return ServerProfile.onDeviceId;
  }

  void _ensureOnDevice() {
    final i = _profiles.indexWhere((p) => p.id == ServerProfile.onDeviceId);
    if (i < 0) {
      _profiles.insert(
        0,
        ServerProfile.onDevice(
          lastUsedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      );
      return;
    }
    // Keep the friendly label even if an older install stored "On-Device".
    final current = _profiles[i];
    if (current.name == 'On-Device' || current.name.trim().isEmpty) {
      _profiles[i] = current.copyWith(name: 'Run AI on this device');
    }
  }

  Future<void> _persist([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    final encoded =
        json.encode(_profiles.map((p) => p.toMap()).toList(growable: false));
    await prefs.setString(_profilesKey, encoded);
    if (_activeId == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, _activeId!);
    }
  }

  Future<ServerProfile> upsert(ServerProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      _profiles[index] = profile;
    } else {
      _profiles.add(profile);
    }
    await _persist();
    notifyListeners();
    return profile;
  }

  Future<ServerProfile> add({
    required String name,
    required ServerProfileKind kind,
    CloudApiType? cloudType,
    String? baseUrl,
    String? apiKey,
    Map<String, String>? customHeaders,
    bool customHeadersEnabled = false,
    String? id,
  }) async {
    final profile = ServerProfile(
      id: id ?? _uuid.v4(),
      name: name.trim().isEmpty ? _defaultName(kind, cloudType) : name.trim(),
      kind: kind,
      cloudType: cloudType,
      baseUrl: baseUrl,
      apiKey: apiKey,
      customHeaders: customHeaders,
      customHeadersEnabled: customHeadersEnabled,
      lastUsedAt: DateTime.now(),
    );
    return upsert(profile);
  }

  String _defaultName(ServerProfileKind kind, CloudApiType? cloudType) {
    switch (kind) {
      case ServerProfileKind.onDevice:
        return 'Run AI on this device';
      case ServerProfileKind.lmStudio:
        return 'LM Studio';
      case ServerProfileKind.usb:
        return 'LM Studio via USB';
      case ServerProfileKind.cloud:
        return cloudType?.displayName ?? 'Server';
    }
  }

  /// Ensure the USB profile exists (e.g. after enabling USB Mode).
  Future<ServerProfile> ensureUsbProfile() async {
    final existing = byId(ServerProfile.usbId);
    if (existing != null) {
      return upsert(existing.copyWith(lastUsedAt: DateTime.now()));
    }
    return upsert(ServerProfile.usb());
  }

  Future<void> rename(String id, String name) async {
    final i = _profiles.indexWhere((p) => p.id == id);
    if (i < 0) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _profiles[i] = _profiles[i].copyWith(name: trimmed);
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    if (id == ServerProfile.onDeviceId) return;
    _profiles.removeWhere((p) => p.id == id);
    if (_activeId == id) {
      _activeId = ServerProfile.onDeviceId;
    }
    await _persist();
    notifyListeners();
  }

  /// Marks [id] active and bumps lastUsedAt. Does not apply settings —
  /// call [SettingsProvider.activateServerProfile] for that.
  Future<ServerProfile?> markActive(String id) async {
    final i = _profiles.indexWhere((p) => p.id == id);
    if (i < 0) return null;
    _activeId = id;
    _profiles[i] = _profiles[i].copyWith(lastUsedAt: DateTime.now());
    await _persist();
    notifyListeners();
    return _profiles[i];
  }

  ServerProfile? byId(String id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Small helper to avoid importing SettingsProvider from the service file.
class SettingsProviderKinds {
  static bool isCloud(String kind) =>
      kind == 'cloud' || CloudApiType.isFreeLocalKind(kind);
}
