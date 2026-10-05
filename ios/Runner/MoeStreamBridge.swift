import Flutter
import Foundation

/// Flutter bridge for GGUF MoE expert streaming (BigMoeOnEdge).
///
/// Channels:
///   • MethodChannel("lm_mini/moe_stream") → available / load / unload / cancel
///   • EventChannel ("lm_mini/moe_stream/stream") → token pieces
final class MoeStreamBridge: NSObject {
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let streamHandler = MoeStreamHandler()

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "lm_mini/moe_stream", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(
      name: "lm_mini/moe_stream/stream", binaryMessenger: messenger)
    super.init()
    eventChannel.setStreamHandler(streamHandler)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "available":
      result(moe_stream_available())
    case "load":
      guard let args = call.arguments as? [String: Any],
            let path = args["modelPath"] as? String else {
        result(FlutterError(code: "bad_args", message: "modelPath required", details: nil))
        return
      }
      let nCtx = (args["nCtx"] as? NSNumber)?.intValue ?? 2048
      let nThreads = (args["nThreads"] as? NSNumber)?.intValue ?? 4
      let cacheMb = (args["cacheMb"] as? NSNumber)?.intValue ?? 0
      DispatchQueue.global(qos: .userInitiated).async {
        var err = [CChar](repeating: 0, count: 4096)
        let rc = moe_stream_open(
          path, Int32(nCtx), Int32(nThreads), Int32(cacheMb),
          &err, Int32(err.count))
        DispatchQueue.main.async {
          if rc == 0 {
            result(nil)
          } else {
            let msg = String(cString: err)
            result(FlutterError(code: "moe_load_failed", message: msg, details: nil))
          }
        }
      }
    case "unload":
      moe_stream_close()
      result(nil)
    case "cancel":
      moe_stream_cancel()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

private final class MoeStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var workItem: DispatchWorkItem?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    guard let args = arguments as? [String: Any],
          let prompt = args["prompt"] as? String else {
      events(FlutterError(code: "bad_args", message: "prompt required", details: nil))
      return nil
    }
    let maxTokens = (args["maxTokens"] as? NSNumber)?.intValue ?? 128
    let temperature = (args["temperature"] as? NSNumber)?.floatValue ?? 0
    let topP = (args["topP"] as? NSNumber)?.floatValue ?? 0.95

    let item = DispatchWorkItem { [weak self] in
      var err = [CChar](repeating: 0, count: 2048)
      let rc = moe_stream_generate(
        prompt,
        Int32(maxTokens),
        temperature,
        topP,
        { piece, user in
          guard let piece, let user else { return }
          let handler = Unmanaged<MoeStreamHandler>.fromOpaque(user)
            .takeUnretainedValue()
          let text = String(cString: piece)
          DispatchQueue.main.async {
            handler.sink?(text)
          }
        },
        Unmanaged.passUnretained(self!).toOpaque(),
        &err,
        Int32(err.count))
      DispatchQueue.main.async { [weak self] in
        if rc != 0 {
          let msg = String(cString: err)
          self?.sink?(FlutterError(code: "moe_generate_failed", message: msg, details: nil))
        }
        self?.sink?(FlutterEndOfEventStream)
        self?.sink = nil
      }
    }
    workItem = item
    DispatchQueue.global(qos: .userInitiated).async(execute: item)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    moe_stream_cancel()
    workItem?.cancel()
    sink = nil
    return nil
  }
}
