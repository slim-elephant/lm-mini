import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_settings.dart';
import '../../models/local_model_spec.dart';
import '../../pro/desktop_host/relay_endpoints.dart';
import '../../pro/pro_features.dart';
import '../../services/local_model_download_service.dart';
import '../../services/on_device_llm_service.dart';
import '../desktop_platform.dart';
import '../runtime/desktop_runtime_manager.dart';
import '../tray/desktop_tray_service.dart';
import '../usb/desktop_usb_bridge.dart';
import 'desktop_host_url.dart';
import 'desktop_kokoro_server.dart';
import 'desktop_relay_client.dart';

/// Live reachability of a local backend the host can share with phones.
enum DesktopServiceState { unknown, checking, online, offline, disabled }

/// A shareable service and whether it is reachable on this machine right now.
class DesktopServiceStatus {
  const DesktopServiceStatus({
    required this.key,
    required this.label,
    required this.state,
    this.detail,
    this.readyOnDemand = false,
  });

  final String key;
  final String label;
  final DesktopServiceState state;
  final String? detail;

  /// When offline but the backend boots itself on the first phone request
  /// (the builtin sidecar). The UI shows "Ready" rather than "Not running".
  final bool readyOnDemand;

  bool get isOnline => state == DesktopServiceState.online;
}

/// Connect-compatible host session for the desktop app (QR + relay).
class DesktopHostService extends ChangeNotifier {
  DesktopHostService._();
  static final DesktopHostService instance = DesktopHostService._();

  static const String relayBaseUrl = RelayEndpoints.baseUrl;
  static const String relayWsUrl = RelayEndpoints.wsUrl;
  static const String minAppVersion = '1.8.0';
  static const String hostVersion = '2.0.0';

  static const _prefsPrefix = 'desktop_host_';

  final _relay = DesktopRelayClient.instance;
  final _usb = DesktopUsbBridge.instance;

  Completer<void>? _loadCompleter;
  bool _enabled = false;
  bool _resumingShare = false;
  bool _usbEnabled = true;
  String? _sessionId;
  String? _authToken;
  String? _encryptionKey;
  bool _advertiseBuiltin = true;
  bool _advertiseLmStudio = true;
  bool _advertiseOllama = false;
  bool _advertiseOmlx = false;
  bool _advertiseJan = false;
  bool _advertiseUnsloth = false;

  String _a1111Host = '';
  int _a1111Port = 7860;
  String _comfyUiHost = '';
  int _comfyUiPort = 8188;
  bool _kokoroEnabled = true;
  String _kokoroHost = '127.0.0.1';
  int _kokoroPort = 9998;

  String? _statusMessage;
  bool _relayListenerAttached = false;

  AppSettings? _cachedSettings;
  List<DesktopServiceStatus> _services = const [];
  bool _probing = false;
  bool _reprobeQueued = false;

  bool get isEnabled => _enabled;
  String? get sessionId => _sessionId;
  String? get authToken => _authToken;
  String? get encryptionKey => _encryptionKey;
  bool get advertiseBuiltin => _advertiseBuiltin;
  bool get advertiseLmStudio => _advertiseLmStudio;
  bool get advertiseOllama => _advertiseOllama;
  bool get advertiseOmlx => _advertiseOmlx;
  bool get advertiseJan => _advertiseJan;
  bool get advertiseUnsloth => _advertiseUnsloth;
  String get a1111Host => _a1111Host;
  int get a1111Port => _a1111Port;
  String get comfyUiHost => _comfyUiHost;
  int get comfyUiPort => _comfyUiPort;
  bool get kokoroEnabled => _kokoroEnabled;
  bool get isKokoroServerRunning => DesktopKokoroServer.instance.isRunning;
  String? get kokoroServerError => DesktopKokoroServer.instance.lastError;
  String get kokoroHost => _kokoroHost;
  int get kokoroPort => _kokoroPort;
  String? get statusMessage => _statusMessage;
  List<DesktopServiceStatus> get services => _services;
  bool get isProbing => _probing;
  bool get isRelayConnected => _relay.isConnected;
  bool get isRelayConnecting => _relay.isConnecting;
  bool get usbEnabled => _usbEnabled;
  bool get isUsbRunning => _usb.isRunning;
  bool get isUsbPeerConnected => _usb.hasConnectedPeer;
  bool? get isUsbAvailable => _usb.isAvailable;
  String? get usbLastError => _usb.lastError;
  List<DesktopUsbDeviceStatus> get usbDevices => _usb.devices;

  String get a1111Url =>
      _a1111Host.isEmpty ? '' : formatHostPort(_a1111Host, _a1111Port);
  String get comfyUiUrl =>
      _comfyUiHost.isEmpty ? '' : formatHostPort(_comfyUiHost, _comfyUiPort);
  String get kokoroUrl => formatHostPort(_kokoroHost, _kokoroPort);

  String? get phoneUrl {
    final id = _sessionId;
    if (id == null) return null;
    return '$relayBaseUrl/s/$id';
  }

  /// Copy-paste pairing link. Fragment keeps the token off relay access logs.
  String? get pairingUrl {
    final base = phoneUrl;
    final token = _authToken;
    if (base == null || token == null || token.isEmpty) return null;
    final backends = <String>[];
    if (_advertiseBuiltin) backends.add('lmMiniDesktop');
    if (_advertiseLmStudio) backends.add('lmStudio');
    if (_advertiseOllama) backends.add('ollama');
    if (_advertiseOmlx) backends.add('omlx');
    if (_advertiseJan) backends.add('jan');
    if (_advertiseUnsloth) backends.add('unsloth');
    final params = <String, String>{
      't': token,
      if (_encryptionKey != null && _encryptionKey!.isNotEmpty)
        'ek': _encryptionKey!,
      if (backends.isNotEmpty) 'b': backends.join(','),
      if (_kokoroEnabled) 'kokoro': '1',
      'platform': Platform.operatingSystem,
    };
    return Uri.parse(base)
        .replace(fragment: Uri(queryParameters: params).query)
        .toString();
  }

  Future<void> ensureLoaded() async {
    if (!DesktopPlatform.supportsHostMode) return;
    if (_loadCompleter != null) return _loadCompleter!.future;
    final done = Completer<void>();
    _loadCompleter = done;
    try {
      _ensureRelayListener();
      final prefs = await SharedPreferences.getInstance();
      _advertiseBuiltin = prefs.getBool('${_prefsPrefix}adv_builtin') ?? true;
      _advertiseLmStudio = prefs.getBool('${_prefsPrefix}adv_lmstudio') ?? true;
      _advertiseOllama = prefs.getBool('${_prefsPrefix}adv_ollama') ?? false;
      _advertiseOmlx = prefs.getBool('${_prefsPrefix}adv_omlx') ?? false;
      _advertiseJan = prefs.getBool('${_prefsPrefix}adv_jan') ?? false;
      _advertiseUnsloth = prefs.getBool('${_prefsPrefix}adv_unsloth') ?? false;
      _a1111Host = prefs.getString('${_prefsPrefix}a1111_host') ?? '';
      _a1111Port = prefs.getInt('${_prefsPrefix}a1111_port') ?? 7860;
      _comfyUiHost = prefs.getString('${_prefsPrefix}comfy_host') ?? '';
      _comfyUiPort = prefs.getInt('${_prefsPrefix}comfy_port') ?? 8188;
      _kokoroEnabled = prefs.getBool('${_prefsPrefix}kokoro_enabled') ?? true;
      _kokoroHost =
          prefs.getString('${_prefsPrefix}kokoro_host') ?? '127.0.0.1';
      _kokoroPort = prefs.getInt('${_prefsPrefix}kokoro_port') ?? 9998;
      _sessionId = prefs.getString('${_prefsPrefix}session_id');
      _authToken = prefs.getString('${_prefsPrefix}auth_token');
      _encryptionKey = prefs.getString('${_prefsPrefix}encryption_key');
      if (_sessionId == null ||
          _sessionId!.isEmpty ||
          _authToken == null ||
          _authToken!.isEmpty ||
          _encryptionKey == null ||
          _encryptionKey!.isEmpty) {
        await _restoreSessionFromFile();
        if ((_sessionId?.isNotEmpty ?? false) &&
            (_authToken?.isNotEmpty ?? false) &&
            (_encryptionKey?.isNotEmpty ?? false)) {
          await _persistSession();
        }
      }
      _usbEnabled = prefs.getBool('${_prefsPrefix}usb_enabled') ?? true;
      final hasSession = (_sessionId?.isNotEmpty ?? false) &&
          (_authToken?.isNotEmpty ?? false) &&
          (_encryptionKey?.isNotEmpty ?? false);
      // Older builds did not persist sharing_enabled. If a pairing session
      // already exists, resume sharing so a reboot does not drop phones.
      final resumeShare =
          prefs.getBool('${_prefsPrefix}sharing_enabled') ?? hasSession;
      _usb.setServerVersion(hostVersion);
      _usb.addListener(_onUsbChanged);
      // Let the on-demand sidecar boot when a phone asks for the builtin backend.
      DesktopRuntimeManager.instance.builtinModelResolver =
          _resolveBuiltinModelPath;
      _syncBackendFlags();
      await _usb.checkAvailable();
      if (!done.isCompleted) done.complete();
      notifyListeners();
      unawaited(probeServices());
      if (resumeShare && !_enabled && !_resumingShare) {
        _resumingShare = true;
        unawaited(setEnabled(true).whenComplete(() => _resumingShare = false));
      }
    } catch (e, st) {
      _loadCompleter = null;
      if (!done.isCompleted) done.completeError(e, st);
      rethrow;
    }
  }

  /// Prefill image/TTS hosts from app settings when host fields are empty.
  void syncFromAppSettings(AppSettings settings) {
    _cachedSettings = settings;
    if (_a1111Host.isEmpty && settings.imageGenServerUrl.trim().isNotEmpty) {
      final provider = settings.imageGenProvider;
      final parsed = parseHostPort(
        settings.imageGenServerUrl,
        defaultPort: provider == 'comfyui' ? 8188 : 7860,
      );
      if (parsed != null) {
        if (provider == 'comfyui') {
          _comfyUiHost = parsed.host;
          _comfyUiPort = parsed.port;
        } else {
          _a1111Host = parsed.host;
          _a1111Port = parsed.port;
        }
      }
    }
    final kokoro = settings.voiceRemoteKokoroUrl;
    if (kokoro != null && kokoro.trim().isNotEmpty) {
      final parsed = parseHostPort(kokoro, defaultPort: 9998);
      if (parsed != null) {
        _kokoroHost = parsed.host;
        _kokoroPort = parsed.port;
      }
    }
    _syncBackendFlags();
  }

  void _ensureRelayListener() {
    if (_relayListenerAttached) return;
    _relayListenerAttached = true;
    _relay.addListener(_onRelayChanged);
  }

  /// Status line of the public build, which shares over USB only (internet
  /// pairing through the relay ships in the official app).
  String _usbOnlyStatus() {
    if (!_usbEnabled) return 'USB sharing is off';
    return _usb.hasConnectedPeer
        ? 'Sharing over USB — iPhone connected'
        : 'Waiting for an iPhone over USB';
  }

  void _onRelayChanged() {
    if (!_enabled) {
      unawaited(_refreshTray());
      return;
    }
    if (!ProFeatures.included) {
      _statusMessage = _usbOnlyStatus();
    } else if (_relay.isConnected) {
      _statusMessage = _usb.hasConnectedPeer
          ? 'Connected (relay + USB)'
          : 'Connected — phones can use ${DesktopPlatform.thisMachine}';
    } else if (_relay.isConnecting) {
      _statusMessage = 'Connecting to relay…';
    } else {
      _statusMessage = _relay.lastError ?? 'Reconnecting to relay…';
    }
    notifyListeners();
    unawaited(_refreshTray());
  }

  void _onUsbChanged() {
    if (_enabled && !ProFeatures.included) _statusMessage = _usbOnlyStatus();
    notifyListeners();
    unawaited(_refreshTray());
  }

  Future<void> setEnabled(bool value) async {
    if (!DesktopPlatform.supportsHostMode) {
      _statusMessage = 'Host mode is only available on desktop.';
      notifyListeners();
      return;
    }
    await ensureLoaded();
    if (value) {
      await _ensureSession(persist: true);
      _enabled = true;
      await _saveBool('sharing_enabled', true);
      _statusMessage =
          ProFeatures.included ? 'Connecting to relay…' : _usbOnlyStatus();
      notifyListeners();
      await DesktopTrayService.instance.setKeepAlive(true);
      if (_kokoroEnabled) {
        await _ensureKokoroServer();
      }
      await _connectRelay();
      if (_usbEnabled) await _usb.start();
      if (!ProFeatures.included) {
        _statusMessage = _usbOnlyStatus();
        notifyListeners();
      }
      unawaited(probeServices());
      // Warm the builtin sidecar so the first phone request is instant
      // instead of racing a cold start.
      if (_advertiseBuiltin) {
        unawaited(DesktopRuntimeManager.instance.ensureBuiltinRunning());
      }
    } else {
      _enabled = false;
      await _saveBool('sharing_enabled', false);
      await _relay.disconnect();
      await _usb.stop();
      await DesktopKokoroServer.instance.stop();
      _statusMessage = 'Host sharing is off.';
      await DesktopTrayService.instance.setKeepAlive(false);
      notifyListeners();
    }
    await _refreshTray();
  }

  Future<void> setUsbEnabled(bool value) async {
    _usbEnabled = value;
    await _saveBool('usb_enabled', value);
    if (_enabled && value) {
      await _usb.start();
    } else if (!value) {
      await _usb.stop();
    }
    if (_enabled && !ProFeatures.included) _statusMessage = _usbOnlyStatus();
    notifyListeners();
    await _refreshTray();
  }

  Future<void> setAdvertiseBuiltin(bool v) async {
    _advertiseBuiltin = v;
    await _saveBool('adv_builtin', v);
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setAdvertiseLmStudio(bool v) async {
    _advertiseLmStudio = v;
    await _saveBool('adv_lmstudio', v);
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setAdvertiseOllama(bool v) async {
    _advertiseOllama = v;
    await _saveBool('adv_ollama', v);
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setAdvertiseOmlx(bool v) async {
    _advertiseOmlx = v;
    await _saveBool('adv_omlx', v);
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setAdvertiseJan(bool v) async {
    _advertiseJan = v;
    await _saveBool('adv_jan', v);
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setAdvertiseUnsloth(bool v) async {
    _advertiseUnsloth = v;
    await _saveBool('adv_unsloth', v);
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setA1111Url(String url) async {
    final parsed = parseHostPort(url, defaultPort: 7860);
    if (parsed == null) {
      _a1111Host = '';
      _a1111Port = 7860;
    } else {
      _a1111Host = parsed.host;
      _a1111Port = parsed.port;
    }
    await _persistImageTts();
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setComfyUiUrl(String url) async {
    final parsed = parseHostPort(url, defaultPort: 8188);
    if (parsed == null) {
      _comfyUiHost = '';
      _comfyUiPort = 8188;
    } else {
      _comfyUiHost = parsed.host;
      _comfyUiPort = parsed.port;
    }
    await _persistImageTts();
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> setKokoroEnabled(bool v) async {
    _kokoroEnabled = v;
    await _saveBool('kokoro_enabled', v);
    _syncBackendFlags();
    if (v && _enabled) {
      await _ensureKokoroServer();
    } else if (!v) {
      await DesktopKokoroServer.instance.stop();
    }
    notifyListeners();
    unawaited(probeServices());
  }

  Future<bool> ensureKokoroShared() => _ensureKokoroServer();

  Future<bool> _ensureKokoroServer() async {
    final ok = await DesktopKokoroServer.instance.start(port: _kokoroPort);
    if (ok) {
      _kokoroHost = '127.0.0.1';
    }
    return ok;
  }

  Future<void> setKokoroUrl(String url) async {
    final parsed = parseHostPort(url, defaultPort: 9998);
    if (parsed == null) {
      _kokoroHost = '127.0.0.1';
      _kokoroPort = 9998;
    } else {
      _kokoroHost = parsed.host;
      _kokoroPort = parsed.port;
    }
    await _persistImageTts();
    _syncBackendFlags();
    notifyListeners();
    unawaited(probeServices());
  }

  Future<void> rotateSession() async {
    await _relay.disconnect();
    _sessionId = null;
    _authToken = null;
    _encryptionKey = null;
    await _ensureSession(persist: true);
    if (_enabled) {
      _statusMessage = 'Connecting to relay…';
      notifyListeners();
      await _connectRelay();
    } else {
      notifyListeners();
    }
    await _refreshTray();
  }

  Future<void> _connectRelay() async {
    _syncBackendFlags();
    await _relay.connect(
      sessionId: _sessionId!,
      authToken: _authToken!,
      relayWsUrl: relayWsUrl,
      backends: _currentBackends(),
    );
    _onRelayChanged();
  }

  /// Re-open the persisted Share-with-phone session on the same relay.
  Future<void> reconnectRelay({bool force = true}) async {
    if (!DesktopPlatform.supportsHostMode || !_enabled) return;
    if (_sessionId == null || _authToken == null) return;
    if (force || !_relay.isConnected) {
      _statusMessage = 'Connecting to relay…';
      notifyListeners();
    }
    await _relay.reconnectNow(force: force);
    _onRelayChanged();
  }

  /// Laptop sleep/lid-close drops the relay WebSocket. Reuse the same session
  /// instead of waiting for a manual refresh. [fromSuspend] is true after
  /// `hidden`/`paused` (sleep) so a half-open socket is replaced immediately.
  Future<void> onAppResumed({bool fromSuspend = false}) async {
    if (!DesktopPlatform.supportsHostMode || !_enabled) return;
    await reconnectRelay(force: fromSuspend);
    if (fromSuspend) unawaited(probeServices());
  }

  void _syncBackendFlags() {
    final backends = _currentBackends();
    _relay.updateBackends(backends);
    _usb.updateBackends(backends);
  }

  DesktopRelayBackends _currentBackends() => DesktopRelayBackends(
        advertiseBuiltin: _advertiseBuiltin,
        advertiseLmStudio: _advertiseLmStudio,
        advertiseOllama: _advertiseOllama,
        advertiseOmlx: _advertiseOmlx,
        advertiseJan: _advertiseJan,
        advertiseUnsloth: _advertiseUnsloth,
        a1111Host: _a1111Host,
        a1111Port: _a1111Port,
        comfyUiHost: _comfyUiHost,
        comfyUiPort: _comfyUiPort,
        kokoroEnabled: _kokoroEnabled,
        kokoroHost: _kokoroHost,
        kokoroPort: _kokoroPort,
        reachable: _reachableMap(),
      );

  Map<String, bool> _reachableMap() {
    final map = <String, bool>{};
    for (final s in _services) {
      final kind = switch (s.key) {
        'builtin' => 'lmMiniDesktop',
        _ => s.key,
      };
      map[kind] = s.isOnline || s.readyOnDemand;
    }
    if (_advertiseBuiltin) {
      map['lmMiniDesktop'] = true;
    }
    return map;
  }

  /// Replace the pairing encryption key. Empty input generates a new key.
  Future<void> setEncryptionKey(String value) async {
    await ensureLoaded();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      final rng = Random.secure();
      _encryptionKey = List<int>.generate(32, (_) => rng.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    } else {
      _encryptionKey = trimmed;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsPrefix}encryption_key', _encryptionKey!);
    notifyListeners();
  }

  Future<void> _ensureSession({required bool persist}) async {
    final rng = Random.secure();
    String hex(int bytes) {
      final data = List<int>.generate(bytes, (_) => rng.nextInt(256));
      return data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    }

    var changed = false;
    if (_sessionId == null || _sessionId!.isEmpty) {
      _sessionId = hex(16);
      changed = true;
    }
    if (_authToken == null || _authToken!.isEmpty) {
      _authToken = hex(24);
      changed = true;
    }
    if (_encryptionKey == null || _encryptionKey!.isEmpty) {
      _encryptionKey = hex(32);
      changed = true;
    }
    if (persist && changed) await _persistSession();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsPrefix}session_id', _sessionId!);
    await prefs.setString('${_prefsPrefix}auth_token', _authToken!);
    await prefs.setString('${_prefsPrefix}encryption_key', _encryptionKey!);
    await _persistSessionFile();
  }

  Future<File> _sessionFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/desktop_host_session.json');
  }

  Future<void> _persistSessionFile() async {
    final id = _sessionId;
    final token = _authToken;
    final key = _encryptionKey;
    if (id == null || token == null || key == null) return;
    try {
      final file = await _sessionFile();
      await file.writeAsString(
        jsonEncode({
          'session_id': id,
          'auth_token': token,
          'encryption_key': key,
        }),
        flush: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Desktop host session file save failed: $e');
    }
  }

  Future<void> _restoreSessionFromFile() async {
    try {
      final file = await _sessionFile();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      final id = decoded['session_id'] as String?;
      final token = decoded['auth_token'] as String?;
      final key = decoded['encryption_key'] as String?;
      if (id != null && id.isNotEmpty) _sessionId = id;
      if (token != null && token.isNotEmpty) _authToken = token;
      if (key != null && key.isNotEmpty) _encryptionKey = key;
    } catch (e) {
      if (kDebugMode) debugPrint('Desktop host session file load failed: $e');
    }
  }

  Future<void> _persistImageTts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsPrefix}a1111_host', _a1111Host);
    await prefs.setInt('${_prefsPrefix}a1111_port', _a1111Port);
    await prefs.setString('${_prefsPrefix}comfy_host', _comfyUiHost);
    await prefs.setInt('${_prefsPrefix}comfy_port', _comfyUiPort);
    await prefs.setString('${_prefsPrefix}kokoro_host', _kokoroHost);
    await prefs.setInt('${_prefsPrefix}kokoro_port', _kokoroPort);
  }

  Future<void> _saveBool(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix$key', v);
  }

  Future<void> _refreshTray() async {
    final usbOn = _usb.hasConnectedPeer;
    final relayOn = _relay.isConnected;
    final connected = relayOn || usbOn;
    String tooltip = 'LM Mini Home';
    if (_enabled) {
      if (relayOn && usbOn) {
        tooltip = 'LM Mini Home — Relay + USB';
      } else if (usbOn) {
        tooltip = 'LM Mini Home — iPhone via USB';
      } else if (relayOn) {
        tooltip = 'LM Mini Home — Sharing with phone';
      } else if (!ProFeatures.included) {
        tooltip = 'LM Mini Home — Waiting for USB';
      } else {
        tooltip = 'LM Mini Home — Connecting…';
      }
    }
    await DesktopTrayService.instance.updateStatus(
      sharing: _enabled,
      connected: connected,
      usbConnected: usbOn,
      tooltip: tooltip,
    );
  }

  /// Resolve a GGUF path the builtin sidecar can load. Prefers the model the
  /// user selected on this machine; falls back to any downloaded GGUF.
  Future<String?> _resolveBuiltinModelPath() async {
    try {
      await LocalModelDownloadService.instance.init();
      LocalModelEntry? entry;
      final settings = _cachedSettings;
      if (settings != null) {
        final spec = OnDeviceLLMService.instance.specForSettings(settings);
        if (spec != null && spec.engine == LocalEngine.fllama) {
          entry = LocalModelDownloadService.instance.entryById(spec.id);
        }
      }
      if (entry == null || entry.status != LocalModelStatus.ready) {
        entry = _firstReadyGgufEntry();
      }
      if (entry == null) return null;
      return _ggufPathFromEntry(entry);
    } catch (_) {
      return null;
    }
  }

  LocalModelEntry? _firstReadyGgufEntry() {
    for (final e in LocalModelDownloadService.instance.readyEntries) {
      if (e.spec.engine == LocalEngine.fllama && e.localPath != null) {
        return e;
      }
    }
    return null;
  }

  Future<String?> _ggufPathFromEntry(LocalModelEntry entry) async {
    final path = entry.localPath;
    if (path == null) return null;
    if (path.toLowerCase().endsWith('.gguf')) return path;
    final dir = Directory(path);
    if (await dir.exists()) {
      await for (final e in dir.list()) {
        if (e.path.toLowerCase().endsWith('.gguf')) return e.path;
      }
    }
    return null;
  }

  /// Probe the advertised/configured local backends so the UI can show which
  /// services phones will actually be able to reach.
  Future<void> probeServices() async {
    if (!DesktopPlatform.supportsHostMode) return;
    if (_probing) {
      _reprobeQueued = true;
      return;
    }
    _probing = true;
    // Seed a "checking" snapshot so the UI reflects work immediately.
    _services = _buildServiceList(probe: null);
    notifyListeners();
    if (_enabled && !_relay.isConnected && !_relay.isConnecting) {
      unawaited(_relay.reconnectNow(force: true));
    }

    final probe = <String, DesktopServiceState>{};

    Future<void> check(String key, String host, int port) async {
      probe[key] = await _isPortOpen(host, port)
          ? DesktopServiceState.online
          : DesktopServiceState.offline;
    }

    final checks = <Future<void>>[];
    // Builtin is on-demand: "online" once running, otherwise ready-to-start.
    if (_advertiseBuiltin) {
      probe['builtin'] = DesktopRuntimeManager.instance.isRunning
          ? DesktopServiceState.online
          : DesktopServiceState.offline;
    }
    if (_advertiseLmStudio) checks.add(check('lmStudio', '127.0.0.1', 1234));
    if (_advertiseOllama) checks.add(check('ollama', '127.0.0.1', 11434));
    if (_advertiseOmlx) checks.add(check('omlx', '127.0.0.1', 8000));
    if (_advertiseJan) checks.add(check('jan', '127.0.0.1', 1337));
    if (_advertiseUnsloth) checks.add(check('unsloth', '127.0.0.1', 8888));
    if (_a1111Host.isNotEmpty) {
      checks.add(check('a1111', _a1111Host, _a1111Port));
    }
    if (_comfyUiHost.isNotEmpty) {
      checks.add(check('comfyui', _comfyUiHost, _comfyUiPort));
    }
    if (_kokoroEnabled) {
      if (DesktopKokoroServer.instance.isRunning) {
        probe['kokoro'] = DesktopServiceState.online;
      } else if (_enabled) {
        await _ensureKokoroServer();
        probe['kokoro'] = DesktopKokoroServer.instance.isRunning
            ? DesktopServiceState.online
            : DesktopServiceState.offline;
        if (probe['kokoro'] != DesktopServiceState.online) {
          checks.add(check('kokoro', _kokoroHost, _kokoroPort));
        }
      } else {
        checks.add(check('kokoro', _kokoroHost, _kokoroPort));
      }
    }

    await Future.wait(checks);

    _services = _buildServiceList(probe: probe);
    _probing = false;
    _syncBackendFlags();
    notifyListeners();

    if (_reprobeQueued) {
      _reprobeQueued = false;
      unawaited(probeServices());
    }
  }

  List<DesktopServiceStatus> _buildServiceList({
    required Map<String, DesktopServiceState>? probe,
  }) {
    DesktopServiceState stateFor(String key, bool advertised) {
      if (!advertised) return DesktopServiceState.disabled;
      if (probe == null) return DesktopServiceState.checking;
      return probe[key] ?? DesktopServiceState.offline;
    }

    final builtinState = !_advertiseBuiltin
        ? DesktopServiceState.disabled
        : (probe == null
            ? DesktopServiceState.checking
            : (DesktopRuntimeManager.instance.isRunning
                ? DesktopServiceState.online
                : DesktopServiceState.offline));

    return [
      DesktopServiceStatus(
        key: 'builtin',
        label: 'LM Mini Home',
        state: builtinState,
        readyOnDemand: true,
        detail: builtinState == DesktopServiceState.online
            ? 'Model loaded'
            : 'Starts automatically on first request',
      ),
      DesktopServiceStatus(
        key: 'lmStudio',
        label: 'LM Studio',
        state: stateFor('lmStudio', _advertiseLmStudio),
        detail: 'localhost:1234',
      ),
      DesktopServiceStatus(
        key: 'ollama',
        label: 'Ollama',
        state: stateFor('ollama', _advertiseOllama),
        detail: 'localhost:11434',
      ),
      DesktopServiceStatus(
        key: 'omlx',
        label: 'oMLX',
        state: stateFor('omlx', _advertiseOmlx),
        detail: 'localhost:8000',
      ),
      DesktopServiceStatus(
        key: 'jan',
        label: 'JAN AI',
        state: stateFor('jan', _advertiseJan),
        detail: 'localhost:1337',
      ),
      DesktopServiceStatus(
        key: 'unsloth',
        label: 'Unsloth',
        state: stateFor('unsloth', _advertiseUnsloth),
        detail: 'localhost:8888',
      ),
      DesktopServiceStatus(
        key: 'imageGen',
        label: _comfyUiHost.isNotEmpty ? 'ComfyUI' : 'AUTOMATIC1111 / Forge',
        state: _comfyUiHost.isNotEmpty
            ? stateFor('comfyui', true)
            : (_a1111Host.isNotEmpty
                ? stateFor('a1111', true)
                : DesktopServiceState.disabled),
        detail: _comfyUiHost.isNotEmpty
            ? comfyUiUrl
            : (_a1111Host.isNotEmpty ? a1111Url : 'No image server set'),
      ),
      DesktopServiceStatus(
        key: 'kokoro',
        label: 'Kokoro TTS',
        state: stateFor('kokoro', _kokoroEnabled),
        readyOnDemand: _kokoroEnabled,
        detail: _kokoroEnabled ? kokoroUrl : null,
      ),
    ];
  }

  Future<bool> _isPortOpen(String host, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 900),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
  }

  Map<String, dynamic> buildQrPayload() {
    final backends = <String>[];
    if (_advertiseBuiltin) backends.add('lmMiniDesktop');
    if (_advertiseLmStudio) backends.add('lmStudio');
    if (_advertiseOllama) backends.add('ollama');
    if (_advertiseOmlx) backends.add('omlx');
    if (_advertiseJan) backends.add('jan');
    if (_advertiseUnsloth) backends.add('unsloth');

    final url = phoneUrl ?? '';
    return {
      'v': 5,
      'url': url,
      'tunnelUrl': url,
      'token': _authToken ?? '',
      'ek': _encryptionKey ?? '',
      'connectVersion': hostVersion,
      'minAppVersion': minAppVersion,
      'backends': backends,
      'host': 'lmMiniDesktop',
      'builtinReady': DesktopRuntimeManager.instance.isRunning,
      'imageReady': _a1111Host.isNotEmpty || _comfyUiHost.isNotEmpty,
      'kokoroReady': _kokoroEnabled,
      'platform': Platform.operatingSystem,
    };
  }

  String buildQrPayloadJson() => jsonEncode(buildQrPayload());
}
