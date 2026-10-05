import Flutter
import Foundation
import dnssd

/// Reverse-mDNS (PTR) for LAN IPv4 addresses via Bonjour / dns_sd.
/// Does not need the multicast entitlement — unlike raw UDP to 224.0.0.251.
final class LanHostnameLookup: NSObject {
  static let channelName = "lm_mini/lan_hostname"

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler { call, result in
      guard call.method == "reverseIpv4", let ip = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      Self.queryPtr(ipv4: ip, completion: result)
    }
  }

  private static func queryPtr(ipv4: String, completion: @escaping FlutterResult) {
    let parts = ipv4.split(separator: ".").compactMap { UInt8($0) }
    guard parts.count == 4 else {
      completion(nil)
      return
    }
    let ptrName =
      "\(parts[3]).\(parts[2]).\(parts[1]).\(parts[0]).in-addr.arpa"

    DispatchQueue.global(qos: .userInitiated).async {
      let name = _LanPtrQuery.resolve(ptrName: ptrName, timeout: 2.0)
      DispatchQueue.main.async {
        completion(name)
      }
    }
  }
}

private final class _LanPtrQuery {
  private var name: String?
  private var ref: DNSServiceRef?
  private let lock = NSCondition()
  private var done = false

  static func resolve(ptrName: String, timeout: TimeInterval) -> String? {
    let query = _LanPtrQuery()
    return query.run(ptrName: ptrName, timeout: timeout)
  }

  private func finish(_ value: String?) {
    lock.lock()
    if !done {
      name = value
      done = true
      lock.broadcast()
    }
    lock.unlock()
    if let ref {
      DNSServiceRefDeallocate(ref)
      self.ref = nil
    }
  }

  private func run(ptrName: String, timeout: TimeInterval) -> String? {
    let retained = Unmanaged.passRetained(self)

    let callback: DNSServiceQueryRecordReply = { _, _, _, errorCode, _, _, _, rdlen, rdata, _, context in
      guard let context else { return }
      let query = Unmanaged<_LanPtrQuery>.fromOpaque(context).takeUnretainedValue()
      guard errorCode == kDNSServiceErr_NoError, let rdata, rdlen > 0 else {
        query.finish(nil)
        return
      }
      let bytes = rdata.bindMemory(to: UInt8.self, capacity: Int(rdlen))
      query.finish(_dnsName(from: bytes, length: Int(rdlen)))
    }

    var serviceRef: DNSServiceRef?
    let err = DNSServiceQueryRecord(
      &serviceRef,
      0,
      0,
      ptrName,
      UInt16(kDNSServiceType_PTR),
      UInt16(kDNSServiceClass_IN),
      callback,
      retained.toOpaque()
    )

    guard err == kDNSServiceErr_NoError, let service = serviceRef else {
      retained.release()
      return nil
    }
    ref = service

    let queueErr = DNSServiceSetDispatchQueue(
      service,
      DispatchQueue.global(qos: .userInitiated)
    )
    if queueErr != kDNSServiceErr_NoError {
      finish(nil)
      retained.release()
      return nil
    }

    lock.lock()
    let deadline = Date().addingTimeInterval(timeout)
    while !done {
      let remaining = deadline.timeIntervalSinceNow
      if remaining <= 0 { break }
      _ = lock.wait(until: Date().addingTimeInterval(min(remaining, 0.25)))
    }
    let result = done ? name : nil
    lock.unlock()
    if !done {
      finish(nil)
    }
    retained.release()
    return result
  }
}

private func _dnsName(from bytes: UnsafePointer<UInt8>, length: Int) -> String? {
  var labels: [String] = []
  var i = 0
  while i < length {
    let len = Int(bytes[i])
    if len == 0 { break }
    if len & 0xC0 == 0xC0 { break }
    i += 1
    guard i + len <= length else { return nil }
    let buf = UnsafeBufferPointer(start: bytes + i, count: len)
    labels.append(String(bytes: buf, encoding: .utf8) ?? "")
    i += len
  }
  let joined = labels.filter { !$0.isEmpty }.joined(separator: ".")
  return joined.isEmpty ? nil : joined
}
