import Cocoa
import FlutterMacOS
import AVFoundation
import Speech
import Darwin

@_silgen_name("proc_pidpath")
private func lmMiniProcPidPath(_ pid: pid_t, _ buffer: UnsafeMutableRawPointer?, _ buffersize: UInt32) -> Int32

@main
class AppDelegate: FlutterAppDelegate {
  private var menuChannel: FlutterMethodChannel?
  private var audioDecodeChannel: FlutterMethodChannel?
  private var trayChannel: FlutterMethodChannel?
  private var privacyChannel: FlutterMethodChannel?
  private var statusItem: NSStatusItem?
  private var trayLogoOutline: NSImage?
  private var trayLogoFilled: NSImage?
  /// Last llama-server pid Dart reported. Cmd-Q reparents the child to
  /// launchd unless we kill it here while this process is still alive.
  private var sidecarPid: pid_t = 0

  /// Hide to the menu bar (and drop the Dock tile) whenever the status item exists.
  var shouldHideToTray: Bool { statusItem != nil }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return !shouldHideToTray
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      showMainWindow()
      return false
    }
    return true
  }

  /// Accessory policy removes the Dock tile while the window is hidden in tray mode.
  func setDockVisible(_ visible: Bool) {
    if visible {
      NSApp.setActivationPolicy(.regular)
    } else {
      NSApp.setActivationPolicy(.accessory)
    }
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Kill the sidecar before Flutter tears down Dart — `detached` is too late.
  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    terminateOwnedSidecar()
    return super.applicationShouldTerminate(sender)
  }

  /// Dart-spawned llama-server is reparented to launchd on quit unless we
  /// kill it here — otherwise it keeps GPU/RAM after the user Cmd-Q's.
  override func applicationWillTerminate(_ notification: Notification) {
    terminateOwnedSidecar()
    super.applicationWillTerminate(notification)
  }

  private func terminateOwnedSidecar() {
    Self.terminateLlamaSidecar(pid: sidecarPid, port: 8741)
    sidecarPid = 0
  }

  /// Home's sidecar always binds 127.0.0.1:8741. Do not scan other ports.
  static func terminateLlamaSidecar(pid: pid_t = 0, port: Int = 8741) {
    var pids = Set<pid_t>()
    if pid > 1, Self.shouldKillReportedSidecar(pid: pid) {
      pids.insert(pid)
    }
    for extra in pidsListening(on: port) {
      pids.insert(extra)
    }
    for target in pids {
      kill(target, SIGTERM)
    }
    if !pids.isEmpty {
      usleep(300_000)
      for target in pids {
        kill(target, SIGKILL)
      }
    }
  }

  /// Kill the Dart-reported child unless we can prove it is a different process
  /// (PID reuse). If the path cannot be read (sandbox), still kill it.
  static func shouldKillReportedSidecar(pid: pid_t) -> Bool {
    if pid <= 1 { return false }
    var path = [CChar](repeating: 0, count: Int(4 * 1024))
    let n = path.withUnsafeMutableBytes { buf -> Int32 in
      lmMiniProcPidPath(pid, buf.baseAddress, UInt32(buf.count))
    }
    if n <= 0 { return true }
    return String(cString: path).contains("llama-server")
  }

  static func pidsListening(on port: Int) -> [pid_t] {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    proc.arguments = ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN", "-t"]
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = Pipe()
    do {
      try proc.run()
      proc.waitUntilExit()
    } catch {
      return []
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else { return [] }
    return text.split(whereSeparator: { $0.isNewline || $0.isWhitespace })
      .compactMap { pid_t($0) }
      .filter { $0 > 1 }
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    setupMenuChannel()
    setupAudioDecodeChannel()
    setupTrayChannel()
    setupPrivacyChannel()
  }

  private func setupMenuChannel(retry: Int = 0) {
    guard let controller = flutterController() else {
      if retry < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          self.setupMenuChannel(retry: retry + 1)
        }
      }
      return
    }

    menuChannel = FlutterMethodChannel(
      name: "lm_mini/macos_menu",
      binaryMessenger: controller.engine.binaryMessenger
    )
  }

  private func setupAudioDecodeChannel(retry: Int = 0) {
    guard let controller = flutterController() else {
      if retry < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          self.setupAudioDecodeChannel(retry: retry + 1)
        }
      }
      return
    }

    audioDecodeChannel = FlutterMethodChannel(
      name: "net.neuro9.lmmini/audio_decode",
      binaryMessenger: controller.engine.binaryMessenger
    )
    audioDecodeChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleAudioDecodeCall(call, result: result)
    }
  }

  private func setupTrayChannel(retry: Int = 0) {
    guard let controller = flutterController() else {
      if retry < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          self.setupTrayChannel(retry: retry + 1)
        }
      }
      return
    }
    registerTrayChannel(with: controller)
  }

  /// Called from MainFlutterWindow as soon as the Flutter engine is ready so
  /// Dart never hits MissingPluginException before AppDelegate retries finish.
  func registerTrayChannel(with controller: FlutterViewController) {
    if trayChannel != nil { return }
    trayChannel = FlutterMethodChannel(
      name: "lm_mini/desktop_tray",
      binaryMessenger: controller.engine.binaryMessenger
    )
    trayChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleTrayCall(call, result: result)
    }
  }

  /// Triggers TCC dialogs for Microphone + Speech Recognition purpose strings
  /// (App Store Review Guideline 2.1). Must run when the user taps the mic —
  /// sandboxed MAS builds use Whisper and previously skipped these prompts.
  private func setupPrivacyChannel(retry: Int = 0) {
    guard let controller = flutterController() else {
      if retry < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          self.setupPrivacyChannel(retry: retry + 1)
        }
      }
      return
    }
    registerPrivacyChannel(with: controller)
  }

  /// Called from MainFlutterWindow as soon as the Flutter engine is ready so
  /// Dart never hits MissingPluginException before AppDelegate retries finish.
  func registerPrivacyChannel(with controller: FlutterViewController) {
    if privacyChannel != nil { return }
    privacyChannel = FlutterMethodChannel(
      name: "lm_mini/macos_privacy",
      binaryMessenger: controller.engine.binaryMessenger
    )
    privacyChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handlePrivacyCall(call, result: result)
    }
  }

  private func handlePrivacyCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestVoicePermissions":
      let args = call.arguments as? [String: Any]
      // Whisper-only (sandboxed Mac) needs mic, not Speech framework.
      // Calling SFSpeechRecognizer under Cursor/VS Code aborts the process
      // (responsible-process TCC; IDE lacks NSSpeechRecognitionUsageDescription).
      let requestSpeech = (args?["requestSpeech"] as? Bool) ?? true
      requestVoicePermissions(requestSpeech: requestSpeech, result: result)
    case "getVoicePermissionStatus":
      result(currentVoicePermissionStatus())
    case "requestCameraPermission":
      requestCameraPermission(result: result)
    case "getCameraPermissionStatus":
      result(currentCameraPermissionStatus())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func speechStatusString(_ status: SFSpeechRecognizerAuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "unknown"
    }
  }

  private func currentVoicePermissionStatus() -> [String: Any] {
    let micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    // Do not call SFSpeechRecognizer here — even reading status can contribute
    // to IDE-attributed TCC aborts. Status is reported only after an explicit
    // speech request.
    return [
      "microphone": micGranted,
      "speechRecognition": "unknown",
    ]
  }

  private func currentCameraPermissionStatus() -> [String: Any] {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    let granted = status == .authorized
    let label: String
    switch status {
    case .authorized: label = "authorized"
    case .denied: label = "denied"
    case .restricted: label = "restricted"
    case .notDetermined: label = "notDetermined"
    @unknown default: label = "unknown"
    }
    return ["camera": granted, "status": label]
  }

  private func requestVoicePermissions(requestSpeech: Bool, result: @escaping FlutterResult) {
    // Mic first on the main thread. Speech only when the Dart side opts in
    // (system STT). Never call SFSpeechRecognizer without a usage string in
    // *this* process's responsible bundle — SIGABRT under IDE launches.
    DispatchQueue.main.async {
      let finish: (Bool, String) -> Void = { micGranted, speech in
        result([
          "microphone": micGranted,
          "speechRecognition": speech,
        ])
      }

      let maybeRequestSpeech: (Bool) -> Void = { micGranted in
        guard requestSpeech else {
          finish(micGranted, "skipped")
          return
        }
        let usage = Bundle.main.object(
          forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription"
        ) as? String
        guard let usage, !usage.isEmpty else {
          NSLog("LM Mini: skipping speech permission — missing NSSpeechRecognitionUsageDescription")
          finish(micGranted, "unavailable")
          return
        }
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        if speechStatus == .notDetermined {
          SFSpeechRecognizer.requestAuthorization { newStatus in
            DispatchQueue.main.async {
              finish(micGranted, Self.speechStatusString(newStatus))
            }
          }
        } else {
          finish(micGranted, Self.speechStatusString(speechStatus))
        }
      }

      let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
      switch micStatus {
      case .authorized:
        maybeRequestSpeech(true)
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .audio) { granted in
          DispatchQueue.main.async {
            maybeRequestSpeech(granted)
          }
        }
      default:
        maybeRequestSpeech(false)
      }
    }
  }

  private func requestCameraPermission(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let status = AVCaptureDevice.authorizationStatus(for: .video)
      switch status {
      case .authorized:
        result(["camera": true, "status": "authorized"])
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async {
            result([
              "camera": granted,
              "status": granted ? "authorized" : "denied",
            ])
          }
        }
      case .denied:
        result(["camera": false, "status": "denied"])
      case .restricted:
        result(["camera": false, "status": "restricted"])
      @unknown default:
        result(["camera": false, "status": "unknown"])
      }
    }
  }

  private func flutterController() -> FlutterViewController? {
    return NSApplication.shared.keyWindow?.contentViewController as? FlutterViewController
      ?? NSApplication.shared.windows.compactMap({ $0.contentViewController as? FlutterViewController }).first
  }

  @objc func showPreferences(_ sender: Any) {
    menuChannel?.invokeMethod("openSettings", arguments: nil)
  }

  // MARK: - Menu bar tray

  private func handleTrayCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "ensureTray":
      ensureStatusItem()
      result(nil)
    case "setStatus":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "expected map", details: nil))
        return
      }
      let sharing = args["sharing"] as? Bool ?? false
      let connected = args["connected"] as? Bool ?? false
      let usbConnected = args["usbConnected"] as? Bool ?? false
      let tooltip = args["tooltip"] as? String ?? "LM Mini"
      ensureStatusItem()
      updateTrayAppearance(
        sharing: sharing,
        connected: connected,
        usbConnected: usbConnected,
        tooltip: tooltip
      )
      result(nil)
    case "setKeepAlive":
      let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
      if enabled {
        ensureStatusItem()
      }
      result(nil)
    case "showMainWindow":
      showMainWindow()
      result(nil)
    case "terminate":
      setDockVisible(true)
      NSApp.terminate(nil)
      result(nil)
    case "setSidecarPid":
      let args = call.arguments as? [String: Any]
      let raw: Int
      if let n = args?["pid"] as? Int {
        raw = n
      } else if let n = args?["pid"] as? NSNumber {
        raw = n.intValue
      } else {
        raw = 0
      }
      sidecarPid = pid_t(raw)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func ensureStatusItem() {
    if statusItem != nil { return }
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = item.button {
      button.image = trayImage(filled: false)
      button.image?.isTemplate = true
      button.toolTip = "LM Mini"
    }
    statusItem = item
    rebuildTrayMenu(sharing: false, connected: false, usbConnected: false)
  }

  private func updateTrayAppearance(
    sharing: Bool,
    connected: Bool,
    usbConnected: Bool,
    tooltip: String
  ) {
    statusItem?.button?.toolTip = tooltip
    // Filled bubble when a phone is connected; outline otherwise — same mark as the app icon.
    statusItem?.button?.image = trayImage(filled: connected)
    statusItem?.button?.image?.isTemplate = true
    rebuildTrayMenu(sharing: sharing, connected: connected, usbConnected: usbConnected)
  }

  private func trayImage(filled: Bool) -> NSImage {
    if filled {
      if trayLogoFilled == nil { trayLogoFilled = Self.makeMenuBarLogo(filled: true) }
      return trayLogoFilled!
    }
    if trayLogoOutline == nil { trayLogoOutline = Self.makeMenuBarLogo(filled: false) }
    return trayLogoOutline!
  }

  /// Template speech-bubble mark (chat bubble + text lines + sparkle), matching the LM Mini app icon.
  private static func makeMenuBarLogo(filled: Bool) -> NSImage {
    let point = NSSize(width: 18, height: 18)
    let scale: CGFloat = 2
    let pxW = Int(point.width * scale)
    let pxH = Int(point.height * scale)
    guard let rep = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: pxW,
      pixelsHigh: pxH,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    ) else {
      return NSImage(systemSymbolName: "bubble.left", accessibilityDescription: "LM Mini")
        ?? NSImage()
    }
    rep.size = point
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.current?.shouldAntialias = true

    let bubble = NSBezierPath(roundedRect: NSRect(x: 1.15, y: 4.7, width: 15.5, height: 11.6), xRadius: 3.4, yRadius: 3.4)
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: 4.05, y: 5.15))
    tail.line(to: NSPoint(x: 2.05, y: 1.05))
    tail.line(to: NSPoint(x: 7.35, y: 5.15))
    tail.close()

    func line(at y: CGFloat, width: CGFloat) -> NSBezierPath {
      NSBezierPath(roundedRect: NSRect(x: 4.05, y: y, width: width, height: 1.25), xRadius: 0.62, yRadius: 0.62)
    }
    let lines = [line(at: 12.85, width: 9.1), line(at: 10.55, width: 7.2), line(at: 8.25, width: 5.1)]

    func sparkle(at c: NSPoint, r: CGFloat) -> NSBezierPath {
      let p = NSBezierPath()
      p.move(to: NSPoint(x: c.x, y: c.y + r))
      p.line(to: NSPoint(x: c.x + r * 0.22, y: c.y + r * 0.22))
      p.line(to: NSPoint(x: c.x + r, y: c.y))
      p.line(to: NSPoint(x: c.x + r * 0.22, y: c.y - r * 0.22))
      p.line(to: NSPoint(x: c.x, y: c.y - r))
      p.line(to: NSPoint(x: c.x - r * 0.22, y: c.y - r * 0.22))
      p.line(to: NSPoint(x: c.x - r, y: c.y))
      p.line(to: NSPoint(x: c.x - r * 0.22, y: c.y + r * 0.22))
      p.close()
      return p
    }

    NSColor.black.set()
    if filled {
      bubble.fill()
      tail.fill()
      NSGraphicsContext.current?.compositingOperation = .destinationOut
      NSColor.black.setFill()
      lines.forEach { $0.fill() }
      NSGraphicsContext.current?.compositingOperation = .sourceOver
      NSColor.black.setFill()
      sparkle(at: NSPoint(x: 15.15, y: 15.55), r: 1.55).fill()
      sparkle(at: NSPoint(x: 16.55, y: 13.85), r: 0.85).fill()
    } else {
      bubble.lineWidth = 1.35
      bubble.lineJoinStyle = .round
      bubble.stroke()
      tail.lineWidth = 1.2
      tail.lineJoinStyle = .round
      tail.stroke()
      NSColor.black.setFill()
      lines.forEach { $0.fill() }
      sparkle(at: NSPoint(x: 15.15, y: 15.55), r: 1.55).fill()
      sparkle(at: NSPoint(x: 16.55, y: 13.85), r: 0.85).fill()
    }

    NSGraphicsContext.restoreGraphicsState()
    let image = NSImage(size: point)
    image.addRepresentation(rep)
    image.isTemplate = true
    return image
  }

  private func rebuildTrayMenu(sharing: Bool, connected: Bool, usbConnected: Bool) {
    let menu = NSMenu()
    let statusTitle: String
    if connected {
      statusTitle = "Status: Connected"
    } else if sharing {
      statusTitle = "Status: Connecting…"
    } else {
      statusTitle = "Status: Idle"
    }
    let statusRow = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
    statusRow.isEnabled = false
    menu.addItem(statusRow)
    if usbConnected {
      let usbRow = NSMenuItem(title: "iPhone connected via USB", action: nil, keyEquivalent: "")
      usbRow.isEnabled = false
      menu.addItem(usbRow)
    }
    menu.addItem(NSMenuItem.separator())

    let showItem = NSMenuItem(title: "Show LM Mini", action: #selector(trayShowWindow(_:)), keyEquivalent: "")
    showItem.target = self
    menu.addItem(showItem)

    let hostItem = NSMenuItem(title: "Share with Phone…", action: #selector(trayOpenHost(_:)), keyEquivalent: "")
    hostItem.target = self
    menu.addItem(hostItem)

    let settingsItem = NSMenuItem(title: "Settings…", action: #selector(trayOpenSettings(_:)), keyEquivalent: ",")
    settingsItem.target = self
    menu.addItem(settingsItem)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "Quit LM Mini", action: #selector(trayQuit(_:)), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem?.menu = menu
  }

  @objc private func trayShowWindow(_ sender: Any?) {
    showMainWindow()
    trayChannel?.invokeMethod("showWindow", arguments: nil)
  }

  @objc private func trayOpenHost(_ sender: Any?) {
    showMainWindow()
    trayChannel?.invokeMethod("openHost", arguments: nil)
  }

  @objc private func trayOpenSettings(_ sender: Any?) {
    showMainWindow()
    trayChannel?.invokeMethod("openSettings", arguments: nil)
  }

  @objc private func trayQuit(_ sender: Any?) {
    setDockVisible(true)
    NSApp.terminate(nil)
  }

  func showMainWindow() {
    setDockVisible(true)
    NSApp.activate(ignoringOtherApps: true)
    if let window = NSApp.windows.first(where: { $0.contentViewController is FlutterViewController }) {
      window.makeKeyAndOrderFront(nil)
    } else {
      for window in NSApp.windows {
        window.makeKeyAndOrderFront(nil)
      }
    }
  }

  // MARK: - Audio decode

  private func handleAudioDecodeCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "convertToWav" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
          let sourcePath = args["sourcePath"] as? String,
          let outputPath = args["outputPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "sourcePath and outputPath required", details: nil))
      return
    }
    let sampleRate = args["sampleRate"] as? Int ?? 16000
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try self.convertAudioToWav(sourcePath: sourcePath, outputPath: outputPath, sampleRate: sampleRate)
        DispatchQueue.main.async { result(outputPath) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "DECODE_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func convertAudioToWav(sourcePath: String, outputPath: String, sampleRate: Int) throws {
    let url = URL(fileURLWithPath: sourcePath)
    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first else {
      throw NSError(domain: "AudioDecode", code: 1, userInfo: [NSLocalizedDescriptionKey: "No audio track"])
    }

    let reader = try AVAssetReader(asset: asset)
    let outputSettings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: 1,
    ]
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
    reader.add(output)
    guard reader.startReading() else {
      throw reader.error ?? NSError(domain: "AudioDecode", code: 2, userInfo: [NSLocalizedDescriptionKey: "Reader failed"])
    }

    var pcmData = Data()
    while reader.status == .reading {
      guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
      guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
      var length = 0
      var dataPointer: UnsafeMutablePointer<Int8>?
      let status = CMBlockBufferGetDataPointer(
        blockBuffer,
        atOffset: 0,
        lengthAtOffsetOut: nil,
        totalLengthOut: &length,
        dataPointerOut: &dataPointer
      )
      if status == kCMBlockBufferNoErr, let dataPointer = dataPointer, length > 0 {
        pcmData.append(UnsafeRawPointer(dataPointer).assumingMemoryBound(to: UInt8.self), count: length)
      }
    }

    if pcmData.isEmpty {
      throw NSError(domain: "AudioDecode", code: 3, userInfo: [NSLocalizedDescriptionKey: "Empty PCM output"])
    }

    try writeWavFile(pcm: pcmData, sampleRate: sampleRate, channels: 1, bitsPerSample: 16, to: outputPath)
  }

  private func writeWavFile(pcm: Data, sampleRate: Int, channels: Int, bitsPerSample: Int, to path: String) throws {
    let byteRate = sampleRate * channels * bitsPerSample / 8
    let blockAlign = channels * bitsPerSample / 8
    let dataSize = pcm.count
    var header = Data()
    header.append(contentsOf: "RIFF".utf8)
    header.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Data($0) })
    header.append(contentsOf: "WAVE".utf8)
    header.append(contentsOf: "fmt ".utf8)
    header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
    header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })
    header.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Data($0) })
    header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) })
    header.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Data($0) })
    header.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Data($0) })
    header.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Data($0) })
    header.append(contentsOf: "data".utf8)
    header.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })

    let outUrl = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: outUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
    try (header + pcm).write(to: outUrl)
  }
}
