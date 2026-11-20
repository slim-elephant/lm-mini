import Flutter
import UIKit
import ActivityKit
import AVFoundation

// Duplicate of the struct in LMWidgetExtension — must match exactly.
struct LMChatActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var statusText: String
        var modelName: String
        var tokenCount: Int
        var tokensPerSecond: Double
        var elapsedSeconds: Int
        var kind: String = "chat"
        var progress: Double = 0
    }
    
    var chatTitle: String
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var deepLinkChannel: FlutterMethodChannel?
  private var liveActivityChannel: FlutterMethodChannel?
  private var audioSessionChannel: FlutterMethodChannel?
  private var audioDecodeChannel: FlutterMethodChannel?
  private var pendingAction: String?
  private var currentActivity: Any? // Activity<LMChatActivityAttributes> stored as Any for availability
  private var mlxBridge: MLXBridge?
  private var appleAIBridge: AppleIntelligenceBridge?
  private var moeStreamBridge: MoeStreamBridge?
  private var onDeviceSdBridge: OnDeviceSdBridge?
  private var lanHostnameLookup: LanHostnameLookup?
  private var mlxFolderImport: MlxFolderImport?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    WatchPhoneBridge.shared.start()
    
    // Set up deep link method channel
    if let controller = window?.rootViewController as? FlutterViewController {
      deepLinkChannel = FlutterMethodChannel(
        name: "net.neuro9.lmmini/deeplink",
        binaryMessenger: controller.binaryMessenger
      )
      
      deepLinkChannel?.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "getInitialAction" {
          result(self?.pendingAction)
          self?.pendingAction = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      
      // Set up Live Activity method channel
      liveActivityChannel = FlutterMethodChannel(
        name: "net.neuro9.lmmini/liveactivity",
        binaryMessenger: controller.binaryMessenger
      )
      
      liveActivityChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleLiveActivityCall(call: call, result: result)
      }
      
      // Set up Audio Session method channel for CallKit voice chat
      audioSessionChannel = FlutterMethodChannel(
        name: "net.neuro9.lmmini/audio_session",
        binaryMessenger: controller.binaryMessenger
      )
      
      audioSessionChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleAudioSessionCall(call: call, result: result)
      }

      audioDecodeChannel = FlutterMethodChannel(
        name: "net.neuro9.lmmini/audio_decode",
        binaryMessenger: controller.binaryMessenger
      )
      audioDecodeChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleAudioDecodeCall(call: call, result: result)
      }

      // Register the MLX-Swift on-device LLM bridge. When the MLX SPM
      // packages are absent this falls back to a stub that returns a
      // descriptive error to the Dart side.
      mlxBridge = MLXBridge(messenger: controller.binaryMessenger)
      appleAIBridge = AppleIntelligenceBridge(messenger: controller.binaryMessenger)
      moeStreamBridge = MoeStreamBridge(messenger: controller.binaryMessenger)

      // On-device Core ML Stable Diffusion (optional SPM — see
      // ios/scripts/add_stable_diffusion_to_runner.rb).
      onDeviceSdBridge = OnDeviceSdBridge(messenger: controller.binaryMessenger)

      lanHostnameLookup = LanHostnameLookup(messenger: controller.binaryMessenger)
      mlxFolderImport = MlxFolderImport(
        messenger: controller.binaryMessenger, presenter: controller)

      BackgroundDownloadManager.shared.bind(messenger: controller.binaryMessenger)

      let siriChannel = FlutterMethodChannel(
        name: "net.neuro9.lmmini/siri",
        binaryMessenger: controller.binaryMessenger
      )
      siriChannel.setMethodCallHandler { call, result in
        LMMiniSiriChannel.handle(call: call, result: result)
      }

      WatchPhoneBridge.shared.bind(messenger: controller.binaryMessenger)
    }
    
    // Check if app was launched with a URL
    if let url = launchOptions?[.url] as? URL {
      handleDeepLink(url: url)
    }
    
    // Check for pending action from widget (App Groups UserDefaults)
    checkWidgetAction()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void,
  ) {
    if identifier == BackgroundDownloadManager.sessionIdentifier {
      BackgroundDownloadManager.shared.setBackgroundCompletionHandler(completionHandler)
    } else {
      completionHandler()
    }
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // Check for widget action when app becomes active (in case user tapped widget while app was backgrounded)
    checkWidgetAction()
    
    // Dismiss any Live Activity when user returns to the app —
    // the in-app UI already shows progress. Recreate on background if
    // the job is still running (Flutter reassertIfNeeded).
    if #available(iOS 16.2, *) {
      Task {
        for activity in Activity<LMChatActivityAttributes>.activities {
          await activity.end(nil, dismissalPolicy: .immediate)
        }
        for activity in Activity<LMDownloadActivityAttributes>.activities {
          await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
        BackgroundDownloadManager.shared.forgetDownloadLiveActivity()
      }
      // Also sync the Flutter-side flag
      liveActivityChannel?.invokeMethod("activityDismissed", arguments: nil)
    }
  }
  
  /// The watch queues the same shortcut Siri uses, then calls this so Dart
  /// runs it while Mini is already open.
  func deliverPendingWatchAsk() {
    checkWidgetAction()
  }

  private func checkWidgetAction() {
    guard let defaults = UserDefaults(suiteName: "group.net.neuro9.lmmini") else {
      return
    }

    // 1. Widget-button-style action ("newChat", "openChat:<id>", …).
    if let action = defaults.string(forKey: "pendingAction") {
      defaults.removeObject(forKey: "pendingAction")
      pendingAction = action
      deepLinkChannel?.invokeMethod("handleAction", arguments: action)
    }

    // 2. App Intents (iOS 16+) drop a `lmmini://shortcut/...` URL into
    // `pendingShortcut`. Reuse the same deep-link plumbing so the Dart
    // ShortcutsHandler runs the request.
    if let shortcutUrl = defaults.string(forKey: "pendingShortcut") {
      defaults.removeObject(forKey: "pendingShortcut")
      let action = "shortcut:\(shortcutUrl)"
      pendingAction = action
      deepLinkChannel?.invokeMethod("handleAction", arguments: action)
    }
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    handleDeepLink(url: url)
    return true
  }
  
  private func handleDeepLink(url: URL) {
    guard url.scheme == "lmmini" else { return }

    // Parse query items once for host-based actions like
    // lmmini://chat?id=... or lmmini://folder?id=...
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let queryItems = components?.queryItems ?? []
    func query(_ name: String) -> String? {
      return queryItems.first(where: { $0.name == name })?.value
    }

    let action: String?
    switch url.host {
    case "newchat":
      action = "newChat"
    case "camera":
      action = "newChatWithCamera"
    case "chat":
      if let persona = query("persona") {
        action = "personaChat:\(persona)"
      } else if let id = query("id") {
        action = "openChat:\(id)"
      } else {
        action = "newChat"
      }
    case "folder":
      if let id = query("id") {
        action = "openFolder:\(id)"
      } else {
        action = nil
      }
    case "news":
      action = "openNews"
    case "shortcut":
      // Carry the full URL through so the Dart side can parse the
      // `/ask`, `/summarize`, `/translate`, `/news` path plus query
      // parameters itself. Encoding as `shortcut:<url>` keeps the
      // existing colon-separated token:arg convention.
      action = "shortcut:\(url.absoluteString)"
    default:
      action = nil
    }

    if let action = action {
      // If Flutter is ready, send immediately
      if let channel = deepLinkChannel {
        channel.invokeMethod("handleAction", arguments: action)
      } else {
        // Store for later when Flutter is ready
        pendingAction = action
      }
    }
  }
  
  // MARK: - Live Activity
  
  private func handleLiveActivityCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(FlutterError(code: "UNAVAILABLE", message: "Live Activities require iOS 16.2+", details: nil))
      return
    }
    
    switch call.method {
    case "startActivity":
      startLiveActivity(call: call, result: result)
    case "updateActivity":
      updateLiveActivity(call: call, result: result)
    case "endActivity":
      endLiveActivity(result: result)
    case "isAvailable":
      if #available(iOS 16.2, *) {
        result(ActivityAuthorizationInfo().areActivitiesEnabled)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  @available(iOS 16.2, *)
  private func startLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary arguments", details: nil))
      return
    }
    
    let modelName = args["modelName"] as? String ?? "AI Model"
    let chatTitle = args["chatTitle"] as? String ?? "Chat"
    let kind = args["kind"] as? String ?? "chat"
    let isImage = kind == "image"
    let progress = args["progress"] as? Double ?? 0
    let statusText = args["statusText"] as? String
      ?? (isImage ? "Generating image..." : "Starting...")
    
    let attributes = LMChatActivityAttributes(chatTitle: chatTitle)
    let initialState = LMChatActivityAttributes.ContentState(
      status: isImage ? "imaging" : "loading",
      statusText: statusText,
      modelName: modelName,
      tokenCount: 0,
      tokensPerSecond: 0.0,
      elapsedSeconds: 0,
      kind: kind,
      progress: progress
    )
    
    Task {
      // End ALL existing activities first to prevent duplicates
      for activity in Activity<LMChatActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      currentActivity = nil
      
      do {
        let activity = try Activity.request(
          attributes: attributes,
          content: .init(state: initialState, staleDate: nil),
          pushType: nil
        )
        currentActivity = activity
        result(true)
      } catch {
        debugPrint("LiveActivity: Failed to start: \(error)")
        result(false)
      }
    }
  }
  
  @available(iOS 16.2, *)
  private func updateLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let activity = currentActivity as? Activity<LMChatActivityAttributes>,
          let args = call.arguments as? [String: Any] else {
      result(nil)
      return
    }
    
    let updatedState = LMChatActivityAttributes.ContentState(
      status: args["status"] as? String ?? "generating",
      statusText: args["statusText"] as? String ?? "Generating...",
      modelName: args["modelName"] as? String ?? "AI Model",
      tokenCount: args["tokenCount"] as? Int ?? 0,
      tokensPerSecond: args["tokensPerSecond"] as? Double ?? 0.0,
      elapsedSeconds: args["elapsedSeconds"] as? Int ?? 0,
      kind: args["kind"] as? String ?? "chat",
      progress: args["progress"] as? Double ?? 0
    )
    
    Task {
      await activity.update(.init(state: updatedState, staleDate: nil))
      result(nil)
    }
  }
  
  @available(iOS 16.2, *)
  private func endLiveActivity(result: @escaping FlutterResult) {
    Task {
      // End ALL activities to prevent orphans
      for activity in Activity<LMChatActivityAttributes>.activities {
        let state = activity.content.state
        let isImage = state.kind == "image" || state.status == "imaging"
        let finalState = LMChatActivityAttributes.ContentState(
          status: "complete",
          statusText: isImage ? "Image ready" : "Complete",
          modelName: state.modelName,
          tokenCount: state.tokenCount,
          tokensPerSecond: state.tokensPerSecond,
          elapsedSeconds: state.elapsedSeconds,
          kind: state.kind,
          progress: isImage ? 1 : state.progress
        )
        await activity.end(
          .init(state: finalState, staleDate: nil),
          dismissalPolicy: .immediate
        )
      }
      currentActivity = nil
      result(nil)
    }
  }
  
  // MARK: - Audio session (single owner)
  //
  // LM Mini is the only code that decides how the shared AVAudioSession is
  // set up. Two modes:
  //   - listening (read aloud): `.playback`
  //   - voice (mic + replies): `.playAndRecord`
  // The speech-recognition and recorder plugins set `.playAndRecord` with
  // the same options as `voiceOptions` on every listen, so nothing flips
  // between turns. Flipping made iOS renegotiate the Bluetooth profile each
  // turn, and with `.defaultToSpeaker` a missed negotiation sent the reply
  // to the loudspeaker while AirPods stayed connected.

  private enum AudioMode: String { case listening, dictation, voiceChat }

  /// What Dart last asked for. Re-applied by `reassert`.
  private var desiredAudioMode: AudioMode = .listening
  private var routeObserverInstalled = false
  private var lastRouteRecovery = Date.distantPast
  private var routeRecoveries = 0

  /// Same set the speech_to_text plugin uses, so a listen changes nothing.
  private let voiceOptions: AVAudioSession.CategoryOptions = [
    .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers,
  ]

  private func handleAudioSessionCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    installRouteObserverIfNeeded()
    switch call.method {
    case "configureForVoiceChat":
      applyAudioMode(.voiceChat, activate: true, result: result)
    case "configureForDictation":
      applyAudioMode(.dictation, activate: true, result: result)
    case "configureForPlayback":
      applyAudioMode(.listening, activate: true, result: result)
    case "activateForRecording", "reassert":
      // Recording needs a voice mode; keep call mode if that is what is on.
      let mode: AudioMode =
        desiredAudioMode == .listening ? .dictation : desiredAudioMode
      applyAudioMode(mode, activate: true, result: result)
    case "deactivate":
      deactivateAudioSession(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func audioSettings(for mode: AudioMode)
    -> (AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions)
  {
    switch mode {
    case .listening:
      return (.playback, .default, [.mixWithOthers])
    case .dictation:
      // `.default` mode: the processing Apple's Dictation uses, for accuracy.
      return (.playAndRecord, .default, voiceOptions)
    case .voiceChat:
      // `.voiceChat`: echo cancellation so the mic does not hear the reply.
      return (.playAndRecord, .voiceChat, voiceOptions)
    }
  }

  /// Sets the session for [mode]. Does nothing when it is already set that
  /// way, so the Bluetooth route is not renegotiated for no reason.
  private func applyAudioMode(_ mode: AudioMode, activate: Bool, result: FlutterResult?) {
    let session = AVAudioSession.sharedInstance()
    let (category, sessionMode, options) = audioSettings(for: mode)
    desiredAudioMode = mode
    do {
      let same =
        session.category == category && session.mode == sessionMode
        && session.categoryOptions == options
      if !same {
        try session.setCategory(category, mode: sessionMode, options: options)
        reportAudio("set \(mode.rawValue)")
      }
      if activate {
        try session.setActive(true, options: [])
      }
      result?(true)
    } catch {
      reportAudio("failed to set \(mode.rawValue): \(error.localizedDescription)")
      result?(
        FlutterError(
          code: "AUDIO_SESSION_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  /// Voice mode ended: let other apps resume, and go back to listening mode
  /// so read aloud does not keep running in mic mode.
  private func deactivateAudioSession(result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(false, options: [.notifyOthersOnDeactivation])
    } catch {
      // Still playing or recording: not critical.
      reportAudio("deactivate skipped: \(error.localizedDescription)")
    }
    applyAudioMode(.listening, activate: false, result: nil)
    result(true)
  }

  private func installRouteObserverIfNeeded() {
    if routeObserverInstalled { return }
    routeObserverInstalled = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(audioRouteChanged(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
  }

  private func portNames(_ ports: [AVAudioSessionPortDescription]) -> String {
    if ports.isEmpty { return "none" }
    return ports.map { $0.portType.rawValue }.joined(separator: "+")
  }

  private func routeReasonName(_ raw: UInt?) -> String {
    guard let raw = raw, let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else {
      return "unknown"
    }
    switch reason {
    case .newDeviceAvailable: return "newDevice"
    case .oldDeviceUnavailable: return "deviceGone"
    case .categoryChange: return "categoryChange"
    case .override: return "override"
    case .wakeFromSleep: return "wake"
    case .noSuitableRouteForCategory: return "noRoute"
    case .routeConfigurationChange: return "configChange"
    default: return "unknown"
    }
  }

  /// Sends one line to the Dart log, so error reports show what the audio
  /// route did.
  private func reportAudio(_ message: String) {
    let session = AVAudioSession.sharedInstance()
    let line =
      "\(message) | out=\(portNames(session.currentRoute.outputs)) "
      + "in=\(portNames(session.currentRoute.inputs)) "
      + "category=\(session.category.rawValue) mode=\(session.mode.rawValue) "
      + "options=\(session.categoryOptions.rawValue) want=\(desiredAudioMode.rawValue)"
    DispatchQueue.main.async { [weak self] in
      self?.audioSessionChannel?.invokeMethod("log", arguments: line)
    }
  }

  @objc private func audioRouteChanged(_ note: Notification) {
    let reasonRaw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
    let previous =
      note.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
    let reason = routeReasonName(reasonRaw)
    reportAudio("route \(reason), was \(portNames(previous?.outputs ?? []))")
    DispatchQueue.main.async { [weak self] in
      self?.returnToHeadsetIfDropped(reason: reason)
    }
  }

  /// In voice mode, a category change can leave the reply on the built-in
  /// speaker while a Bluetooth or wired headset is still connected. Pick
  /// the headset again. Not done when the user chose the speaker themselves
  /// (that arrives as `override`).
  private func returnToHeadsetIfDropped(reason: String) {
    guard reason == "categoryChange" || reason == "configChange" else { return }
    let session = AVAudioSession.sharedInstance()
    guard session.category == .playAndRecord else { return }
    let builtIn: Set<AVAudioSession.Port> = [.builtInSpeaker, .builtInReceiver]
    let outputs = session.currentRoute.outputs
    guard !outputs.isEmpty, outputs.allSatisfy({ builtIn.contains($0.portType) }) else { return }
    let headsetInputs: Set<AVAudioSession.Port> = [.bluetoothHFP, .bluetoothLE, .headsetMic, .usbAudio]
    guard
      let headset = session.availableInputs?.first(where: { headsetInputs.contains($0.portType) })
    else { return }
    // Never loop: at most one attempt every 3 seconds, 5 per app run.
    let now = Date()
    guard now.timeIntervalSince(lastRouteRecovery) > 3, routeRecoveries < 5 else { return }
    lastRouteRecovery = now
    routeRecoveries += 1
    do {
      try session.setPreferredInput(headset)
      reportAudio("returned to \(headset.portType.rawValue)")
    } catch {
      reportAudio("could not return to headset: \(error.localizedDescription)")
    }
  }

  // MARK: - Audio file decode (MP3/M4A → 16 kHz mono WAV)

  private func handleAudioDecodeCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
