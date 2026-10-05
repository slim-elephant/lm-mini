// MacSpeechBridge.swift
//
// Native macOS speech-to-text via Apple's on-device SFSpeechRecognizer,
// exposed to Flutter (lib/services/mac_system_stt_service.dart).
//
// Why this exists:
//   The `speech_to_text` Flutter plugin calls SFSpeechRecognizer without the
//   guards macOS needs, and hard-crashes (SIGABRT) under sandboxed / IDE
//   launches because of the "responsible process" TCC rule. This bridge is a
//   controlled path that:
//     • Only reports itself available when the app is a *real* launched app
//       (parent == launchd), never under `flutter run` / Xcode debugging,
//       where the responsible process (the IDE) lacks a speech usage string.
//     • Verifies NSSpeechRecognitionUsageDescription is present before it ever
//       touches SFSpeechRecognizer.
//     • Prefers on-device recognition so it works offline and is fast.
//
// Channels (mirrors MLXBridge):
//   • MethodChannel("lm_mini/macos_stt")        → isAvailable / authStatus /
//                                                  requestAuth / stop / cancel /
//                                                  locales
//   • EventChannel ("lm_mini/macos_stt/events") → recognition event stream
//
// Event payloads (maps):
//   {"event":"status","status":"listening"|"done"}
//   {"event":"result","text": String, "isFinal": Bool}
//   {"event":"level","level": Double}          // 0..1 mic amplitude
//   {"event":"error","message": String}

import AVFoundation
import FlutterMacOS
import Foundation
import Speech

final class MacSpeechBridge: NSObject {
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let streamHandler = MacSpeechStreamHandler()

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "lm_mini/macos_stt", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(
      name: "lm_mini/macos_stt/events", binaryMessenger: messenger)
    super.init()
    eventChannel.setStreamHandler(streamHandler)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(MacSpeechEngine.shared.isAvailable())
    case "authStatus":
      result(MacSpeechEngine.shared.authStatusString())
    case "requestAuth":
      MacSpeechEngine.shared.requestAuthorization { status in
        result(status)
      }
    case "locales":
      result(MacSpeechEngine.shared.supportedLocales())
    case "stop":
      MacSpeechEngine.shared.stop(finishRequest: true)
      result(nil)
    case "cancel":
      MacSpeechEngine.shared.stop(finishRequest: false)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - Event stream handler

private final class MacSpeechStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?,
                eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    let args = arguments as? [String: Any]
    let localeId = (args?["localeId"] as? String) ?? "en_US"
    let onDevice = (args?["onDevice"] as? Bool) ?? true
    MacSpeechEngine.shared.start(localeId: localeId, onDevice: onDevice, sink: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // Dropping the subscription must not tear down an active session that is
    // being replaced; explicit teardown uses the "stop"/"cancel" methods.
    MacSpeechEngine.shared.detachSink()
    return nil
  }
}

// MARK: - Recognition engine

private final class MacSpeechEngine: NSObject {
  static let shared = MacSpeechEngine()

  private let audioEngine = AVAudioEngine()
  private var recognizer: SFSpeechRecognizer?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var sink: FlutterEventSink?
  private var isRunning = false

  /// True only when this process was launched by launchd (Finder / Dock / a
  /// real .app), not by a developer tool. Under `flutter run` or Xcode the
  /// parent is dart/flutter_tools/debugserver, and calling SFSpeechRecognizer
  /// would be attributed to that tool (no speech usage string) → SIGABRT.
  private func launchedByLaunchd() -> Bool {
    return getppid() == 1
  }

  private func hasUsageString() -> Bool {
    let usage = Bundle.main.object(
      forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String
    return !(usage ?? "").isEmpty
  }

  /// Safe to expose native speech? Must be a real launch, have the usage
  /// string, and have a usable recognizer.
  func isAvailable() -> Bool {
    guard launchedByLaunchd(), hasUsageString() else { return false }
    guard let rec = SFSpeechRecognizer() else { return false }
    return rec.isAvailable
  }

  func authStatusString() -> String {
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "unknown"
    }
  }

  func requestAuthorization(_ completion: @escaping (String) -> Void) {
    // Never trigger the Speech framework if we can't do so safely.
    guard launchedByLaunchd(), hasUsageString() else {
      completion("unavailable")
      return
    }
    let status = SFSpeechRecognizer.authorizationStatus()
    if status == .notDetermined {
      SFSpeechRecognizer.requestAuthorization { new in
        DispatchQueue.main.async {
          completion(MacSpeechEngine.string(for: new))
        }
      }
    } else {
      completion(MacSpeechEngine.string(for: status))
    }
  }

  private static func string(for status: SFSpeechRecognizerAuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "unknown"
    }
  }

  func supportedLocales() -> [String] {
    return SFSpeechRecognizer.supportedLocales().map { $0.identifier }
  }

  func detachSink() {
    // Only forget the sink; keep the session running so a stream re-subscribe
    // (common when Flutter swaps listeners) doesn't kill recognition.
    sink = nil
  }

  func start(localeId: String, onDevice: Bool, sink: @escaping FlutterEventSink) {
    self.sink = sink

    guard isAvailable() else {
      emit(["event": "error", "message": "native_speech_unavailable"])
      end()
      return
    }
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
      emit(["event": "error", "message": "speech_not_authorized"])
      end()
      return
    }

    // Reset any prior session.
    stop(finishRequest: false)

    let locale = Locale(identifier: localeId.replacingOccurrences(of: "_", with: "-"))
    let rec = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer()
    guard let recognizer = rec, recognizer.isAvailable else {
      emit(["event": "error", "message": "recognizer_unavailable"])
      end()
      return
    }
    self.recognizer = recognizer

    let req = SFSpeechAudioBufferRecognitionRequest()
    req.shouldReportPartialResults = true
    if onDevice, recognizer.supportsOnDeviceRecognition {
      req.requiresOnDeviceRecognition = true
    }
    self.request = req

    let input = audioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    input.removeTap(onBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      self?.request?.append(buffer)
      self?.emitLevel(from: buffer)
    }

    audioEngine.prepare()
    do {
      try audioEngine.start()
    } catch {
      emit(["event": "error", "message": "audio_engine_failed: \(error.localizedDescription)"])
      end()
      return
    }

    isRunning = true
    emit(["event": "status", "status": "listening"])

    task = recognizer.recognitionTask(with: req) { [weak self] result, error in
      guard let self = self else { return }
      if let result = result {
        self.emit([
          "event": "result",
          "text": result.bestTranscription.formattedString,
          "isFinal": result.isFinal,
        ])
        if result.isFinal {
          self.stop(finishRequest: false)
          self.end()
        }
      }
      if let error = error {
        // A cancelled/ended session surfaces here too; only report if we were
        // actively running.
        if self.isRunning {
          self.emit(["event": "error", "message": error.localizedDescription])
        }
        self.stop(finishRequest: false)
        self.end()
      }
    }
  }

  func stop(finishRequest: Bool) {
    if audioEngine.isRunning {
      audioEngine.stop()
    }
    audioEngine.inputNode.removeTap(onBus: 0)
    if finishRequest {
      request?.endAudio()
    }
    task?.cancel()
    task = nil
    request = nil
    isRunning = false
  }

  private func emitLevel(from buffer: AVAudioPCMBuffer) {
    guard let channel = buffer.floatChannelData?[0] else { return }
    let frames = Int(buffer.frameLength)
    if frames == 0 { return }
    var sum: Float = 0
    for i in 0..<frames {
      let s = channel[i]
      sum += s * s
    }
    let rms = sqrtf(sum / Float(frames))
    // Map RMS (~0..0.3 for speech) to a 0..1 level for the UI.
    let level = min(1.0, Double(rms) * 3.5)
    emit(["event": "level", "level": level])
  }

  private func emit(_ payload: [String: Any]) {
    let sink = self.sink
    DispatchQueue.main.async { sink?(payload) }
  }

  private func end() {
    let sink = self.sink
    DispatchQueue.main.async {
      sink?(["event": "status", "status": "done"])
      sink?(FlutterEndOfEventStream)
    }
  }
}
