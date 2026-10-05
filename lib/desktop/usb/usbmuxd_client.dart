import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Pure-Dart client for Apple's usbmuxd (`/var/run/usbmuxd`).
///
/// Same protocol as LM Mini Connect's `usbmuxd-client.js`.
/// **Mac App Store sandbox blocks this socket** — works in notarized /
/// sandbox-off builds (and local debug if sandbox allows the path).
class UsbmuxdClient {
  UsbmuxdClient._();

  static const String socketPath = '/var/run/usbmuxd';
  static const int msgTypePlist = 8;
  static const int protocolVersion = 1;

  static int _tag = 1;
  static int _nextTag() => _tag++;

  /// True if the usbmuxd Unix socket is reachable (false under MAS sandbox).
  static Future<bool> isAvailable() async {
    if (!Platform.isMacOS) return false;
    try {
      final socket = await Socket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      ).timeout(const Duration(milliseconds: 500));
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('🖥️ usbmuxd unavailable: $e');
      return false;
    }
  }

  static Future<Socket> _open() async {
    final completer = Completer<Socket>();
    final future = Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );
    future.then(completer.complete).catchError(completer.completeError);
    return completer.future.timeout(const Duration(seconds: 3));
  }

  static Uint8List buildPlistMessage(Map<String, Object?> fields, {int? tag}) {
    final t = tag ?? _nextTag();
    final xml = _buildXml({
      'ClientVersionString': 'lm-mini',
      'ProgName': 'lm-mini',
      'kLibUSBMuxVersion': 3,
      ...fields,
    });
    final payload = utf8.encode(xml);
    final header = ByteData(16);
    header.setUint32(0, payload.length + 16, Endian.little);
    header.setUint32(4, protocolVersion, Endian.little);
    header.setUint32(8, msgTypePlist, Endian.little);
    header.setUint32(12, t, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...payload]);
  }

  static String _buildXml(Map<String, Object?> fields) {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
          '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">')
      ..writeln('<plist version="1.0"><dict>');
    for (final e in fields.entries) {
      buf.writeln('<key>${_esc(e.key)}</key>');
      final v = e.value;
      if (v is int) {
        buf.writeln('<integer>$v</integer>');
      } else if (v is String) {
        buf.writeln('<string>${_esc(v)}</string>');
      } else if (v is bool) {
        buf.writeln(v ? '<true/>' : '<false/>');
      }
    }
    buf.writeln('</dict></plist>');
    return buf.toString();
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Long-lived Listen for USB attach/detach.
  static Future<UsbmuxdDeviceListener> listenForDevices() async {
    final socket = await _open();
    final listener = UsbmuxdDeviceListener._(socket);
    socket.add(buildPlistMessage({'MessageType': 'Listen'}));
    return listener;
  }

  /// Connect to [port] on [deviceId]. Port is host-endian; converted to
  /// network order for usbmuxd.
  static Future<UsbmuxdTunnel> connectToDevice(int deviceId, int port) async {
    final socket = await _open();
    final portNetwork = ((port & 0xff) << 8) | ((port >> 8) & 0xff);
    final framer = _PlistFramer(socket);
    final completer = Completer<UsbmuxdTunnel>();

    late StreamSubscription sub;
    sub = framer.messages.listen((msg) {
      final type = msg['MessageType'] as String?;
      if (type != 'Result') return;
      final number = msg['Number'] as int? ?? -1;
      if (number == 0) {
        final leftover = framer.detach();
        sub.cancel();
        if (!completer.isCompleted) {
          completer.complete(UsbmuxdTunnel(socket: socket, leftover: leftover));
        }
      } else {
        sub.cancel();
        framer.detach();
        socket.destroy();
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('usbmuxd Connect failed: code $number'),
          );
        }
      }
    }, onError: (e) {
      if (!completer.isCompleted) completer.completeError(e);
    });

    socket.add(buildPlistMessage({
      'MessageType': 'Connect',
      'DeviceID': deviceId,
      'PortNumber': portNetwork,
    }));

    return completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
      framer.detach();
      socket.destroy();
      throw TimeoutException('usbmuxd Connect timeout');
    });
  }
}

class UsbmuxdDevice {
  UsbmuxdDevice({
    required this.deviceId,
    required this.serialNumber,
    this.deviceName,
    this.connectionType,
  });

  final int deviceId;
  final String serialNumber;
  final String? deviceName;
  final String? connectionType;
}

class UsbmuxdTunnel {
  UsbmuxdTunnel({required this.socket, required this.leftover});
  final Socket socket;
  final Uint8List leftover;
}

class UsbmuxdDeviceListener {
  UsbmuxdDeviceListener._(this._socket) {
    _framer = _PlistFramer(_socket);
    _sub = _framer.messages.listen(_onMessage, onError: (e) {
      _controller.addError(e);
    }, onDone: () {
      _controller.close();
    });
  }

  final Socket _socket;
  late final _PlistFramer _framer;
  late final StreamSubscription _sub;
  final _controller = StreamController<UsbmuxdDeviceEvent>.broadcast();

  Stream<UsbmuxdDeviceEvent> get events => _controller.stream;

  void _onMessage(Map<String, dynamic> obj) {
    final type = obj['MessageType'] as String?;
    if (type == 'Attached') {
      final props = (obj['Properties'] as Map?)?.cast<String, dynamic>() ?? {};
      final conn = props['ConnectionType']?.toString();
      if (conn != null && conn != 'USB') return;
      final id = obj['DeviceID'] as int? ?? props['DeviceID'] as int?;
      if (id == null) return;
      _controller.add(UsbmuxdDeviceEvent.attached(UsbmuxdDevice(
        deviceId: id,
        serialNumber: props['SerialNumber']?.toString() ?? '$id',
        deviceName: props['EscapedFullServiceName']?.toString() ??
            props['SerialNumber']?.toString(),
        connectionType: conn,
      )));
    } else if (type == 'Detached') {
      final id = obj['DeviceID'] as int?;
      if (id != null) {
        _controller.add(UsbmuxdDeviceEvent.detached(id));
      }
    } else if (type == 'Result') {
      final n = obj['Number'] as int? ?? 0;
      if (n != 0) {
        _controller.addError(StateError('usbmuxd Listen failed: $n'));
      }
    }
  }

  Future<void> stop() async {
    await _sub.cancel();
    try {
      await _socket.close();
    } catch (_) {}
    await _controller.close();
  }
}

class UsbmuxdDeviceEvent {
  UsbmuxdDeviceEvent._(this.kind, this.device, this.deviceId);
  factory UsbmuxdDeviceEvent.attached(UsbmuxdDevice d) =>
      UsbmuxdDeviceEvent._('attached', d, d.deviceId);
  factory UsbmuxdDeviceEvent.detached(int id) =>
      UsbmuxdDeviceEvent._('detached', null, id);

  final String kind;
  final UsbmuxdDevice? device;
  final int deviceId;
  bool get isAttached => kind == 'attached';
}

/// Framed plist reader over a usbmuxd socket.
class _PlistFramer {
  _PlistFramer(this.socket) {
    _sub = socket.listen(_onData, onError: (e) {
      if (!_detached) _controller.addError(e);
    }, onDone: () {
      if (!_detached) _controller.close();
    });
  }

  final Socket socket;
  final _buf = BytesBuilder(copy: false);
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _sub;
  bool _detached = false;

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void _onData(List<int> chunk) {
    if (_detached) return;
    _buf.add(chunk);
    var data = _buf.takeBytes();
    while (data.length >= 16) {
      final total = ByteData.sublistView(Uint8List.fromList(data))
          .getUint32(0, Endian.little);
      if (total < 16 || total > 5 * 1024 * 1024) {
        _controller.addError(StateError('usbmuxd: invalid frame length $total'));
        socket.destroy();
        return;
      }
      if (data.length < total) {
        _buf.add(data);
        return;
      }
      final type = ByteData.sublistView(Uint8List.fromList(data))
          .getUint32(8, Endian.little);
      final payload = data.sublist(16, total);
      data = data.sublist(total);
      if (type == UsbmuxdClient.msgTypePlist) {
        try {
          _controller.add(_parsePlist(utf8.decode(payload)));
        } catch (e) {
          _controller.addError(e);
        }
      }
    }
    if (data.isNotEmpty) _buf.add(data);
  }

  /// Stop framing; return leftover tunnel bytes.
  Uint8List detach() {
    if (_detached) return Uint8List(0);
    _detached = true;
    _sub?.cancel();
    final leftover = _buf.takeBytes();
    return Uint8List.fromList(leftover);
  }

  /// Minimal XML plist parser for usbmuxd Result / Attached / Detached.
  static Map<String, dynamic> _parsePlist(String xml) {
    final out = <String, dynamic>{};
    final keyRe = RegExp(r'<key>([^<]+)</key>\s*(<[^>]+>.*?</[^>]+>|<[^>]+/>)',
        dotAll: true);
    for (final m in keyRe.allMatches(xml)) {
      final key = m.group(1)!;
      final valXml = m.group(2)!;
      if (key == 'Properties' && valXml.contains('<dict>')) {
        out[key] = _parseDictInner(valXml);
      } else {
        out[key] = _parseValue(valXml);
      }
    }
    // DeviceID sometimes appears before Properties as sibling.
    final deviceId = RegExp(r'<key>DeviceID</key>\s*<integer>(\d+)</integer>')
        .firstMatch(xml);
    if (deviceId != null) {
      out['DeviceID'] = int.parse(deviceId.group(1)!);
    }
    return out;
  }

  static Map<String, dynamic> _parseDictInner(String xml) {
    final out = <String, dynamic>{};
    final keyRe = RegExp(r'<key>([^<]+)</key>\s*(<[^>]+>.*?</[^>]+>|<[^>]+/>)',
        dotAll: true);
    for (final m in keyRe.allMatches(xml)) {
      out[m.group(1)!] = _parseValue(m.group(2)!);
    }
    return out;
  }

  static Object? _parseValue(String xml) {
    final s = xml.trim();
    final intM = RegExp(r'<integer>(-?\d+)</integer>').firstMatch(s);
    if (intM != null) return int.parse(intM.group(1)!);
    final strM = RegExp(r'<string>([^<]*)</string>').firstMatch(s);
    if (strM != null) return strM.group(1);
    if (s.contains('<true')) return true;
    if (s.contains('<false')) return false;
    return s;
  }
}
