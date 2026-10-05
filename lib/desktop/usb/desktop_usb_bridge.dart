import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../desktop_platform.dart';
import '../host/desktop_relay_client.dart';
import '../host/desktop_request_proxy.dart';
import 'usbmuxd_client.dart';

/// Mac host that dials the phone's USB control port (2348) via usbmuxd.
///
/// Phone already implements [UsbBridgeService]. Protocol matches Connect.
/// Unavailable under Mac App Store sandbox — [isAvailable] reports that.
class DesktopUsbBridge extends ChangeNotifier {
  DesktopUsbBridge._();
  static final DesktopUsbBridge instance = DesktopUsbBridge._();

  static const int iosControlPort = 2348;
  static const Duration probeInterval = Duration(milliseconds: 2500);

  DesktopRelayBackends _backends = const DesktopRelayBackends();
  String _serverVersion = '2.0.0';

  bool _running = false;
  bool? _available;
  String? _lastError;
  UsbmuxdDeviceListener? _listener;
  StreamSubscription? _listenSub;

  final Map<int, _DeviceSlot> _devices = {};

  bool get isRunning => _running;
  bool? get isAvailable => _available;
  String? get lastError => _lastError;
  bool get hasConnectedPeer =>
      _devices.values.any((s) => s.socket != null);

  List<DesktopUsbDeviceStatus> get devices => _devices.entries
      .map((e) => DesktopUsbDeviceStatus(
            deviceId: e.key,
            connected: e.value.socket != null,
            deviceName: e.value.device.deviceName,
            serial: e.value.device.serialNumber,
          ))
      .toList();

  void updateBackends(DesktopRelayBackends backends) {
    _backends = backends;
  }

  void setServerVersion(String v) => _serverVersion = v;

  Future<bool> checkAvailable() async {
    if (!DesktopPlatform.isMacOS) {
      _available = false;
      notifyListeners();
      return false;
    }
    _available = await UsbmuxdClient.isAvailable();
    notifyListeners();
    return _available!;
  }

  Future<void> start() async {
    if (!DesktopPlatform.isMacOS) {
      _lastError = 'USB host is macOS-only.';
      notifyListeners();
      return;
    }
    if (_running) return;

    final ok = await checkAvailable();
    if (!ok) {
      _lastError =
          'Sandboxed App Store build — USB unavailable. '
          'Use Share with phone (QR), or download LM Mini from lmmini.com for USB.';
      notifyListeners();
      return;
    }

    try {
      _listener = await UsbmuxdClient.listenForDevices();
    } catch (e) {
      _lastError = 'usbmuxd unavailable: $e';
      _available = false;
      notifyListeners();
      return;
    }

    _running = true;
    _lastError = null;
    _listenSub = _listener!.events.listen((ev) {
      if (ev.isAttached && ev.device != null) {
        _onAttached(ev.device!);
      } else {
        _onDetached(ev.deviceId);
      }
    }, onError: (e) {
      debugPrint('🖥️ USB listen error: $e');
      _lastError = e.toString();
      notifyListeners();
    }, onDone: () {
      if (_running) {
        // usbmuxd dropped — restart shortly
        _running = false;
        Future<void>.delayed(const Duration(seconds: 1), () {
          if (!_running) unawaited(start());
        });
      }
    });
    notifyListeners();
  }

  Future<void> stop() async {
    _running = false;
    await _listenSub?.cancel();
    _listenSub = null;
    await _listener?.stop();
    _listener = null;
    for (final id in _devices.keys.toList()) {
      _tearDown(id);
    }
    _devices.clear();
    notifyListeners();
  }

  void _onAttached(UsbmuxdDevice device) {
    if (_devices.containsKey(device.deviceId)) return;
    _devices[device.deviceId] = _DeviceSlot(device);
    notifyListeners();
    _scheduleProbe(device.deviceId, Duration.zero);
  }

  void _onDetached(int deviceId) {
    _tearDown(deviceId);
    _devices.remove(deviceId);
    notifyListeners();
  }

  void _tearDown(int deviceId) {
    final slot = _devices[deviceId];
    if (slot == null) return;
    slot.probeTimer?.cancel();
    slot.probeTimer = null;
    try {
      slot.socket?.destroy();
    } catch (_) {}
    slot.socket = null;
  }

  void _scheduleProbe(int deviceId, Duration delay) {
    final slot = _devices[deviceId];
    if (slot == null || !_running) return;
    slot.probeTimer?.cancel();
    slot.probeTimer = Timer(delay, () => unawaited(_probe(deviceId)));
  }

  Future<void> _probe(int deviceId) async {
    final slot = _devices[deviceId];
    if (slot == null || !_running || slot.socket != null) return;

    try {
      final tunnel = await UsbmuxdClient.connectToDevice(
        deviceId,
        iosControlPort,
      );
      slot.socket = tunnel.socket;
      notifyListeners();
      _wireSocket(deviceId, tunnel.socket, tunnel.leftover);
      _send(tunnel.socket, {
        'type': 'hello',
        'server': 'LM Mini',
        'version': _serverVersion,
      });
      debugPrint('🖥️ USB: connected to device $deviceId');
    } catch (_) {
      // Phone USB mode off — normal; retry.
      _scheduleProbe(deviceId, probeInterval);
    }
  }

  void _wireSocket(int deviceId, Socket sock, Uint8List leftover) {
    var buf = BytesBuilder(copy: false)..add(leftover);

    void handleLine(String line) {
      if (line.isEmpty) return;
      Map<String, dynamic> msg;
      try {
        msg = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
      final type = msg['type'] as String?;
      if (type == 'request') {
        unawaited(DesktopRequestProxy.instance.handleRelayStyleRequest(
          msg: msg,
          backends: _backends,
          send: (frame) => _send(sock, frame),
        ));
      } else if (type == 'ping') {
        _send(sock, {'type': 'pong'});
      }
    }

    void drain() {
      var data = buf.takeBytes();
      while (true) {
        final idx = data.indexOf(0x0a);
        if (idx < 0) {
          if (data.isNotEmpty) buf.add(data);
          break;
        }
        handleLine(utf8.decode(data.sublist(0, idx)));
        data = data.sublist(idx + 1);
      }
    }

    if (leftover.isNotEmpty) drain();

    sock.listen((chunk) {
      buf.add(chunk);
      drain();
    }, onDone: () {
      final slot = _devices[deviceId];
      if (slot != null && identical(slot.socket, sock)) {
        slot.socket = null;
        notifyListeners();
        _scheduleProbe(deviceId, probeInterval);
      }
    }, onError: (_) {}, cancelOnError: true);
  }

  void _send(Socket sock, Map<String, dynamic> obj) {
    try {
      sock.add(utf8.encode('${jsonEncode(obj)}\n'));
    } catch (_) {}
  }
}

class DesktopUsbDeviceStatus {
  const DesktopUsbDeviceStatus({
    required this.deviceId,
    required this.connected,
    this.deviceName,
    this.serial,
  });

  final int deviceId;
  final bool connected;
  final String? deviceName;
  final String? serial;
}

class _DeviceSlot {
  _DeviceSlot(this.device);
  final UsbmuxdDevice device;
  Socket? socket;
  Timer? probeTimer;
}
