import ActivityKit
import Flutter
import Foundation

struct LMDownloadActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var displayName: String
    var progress: Double
    var statusText: String
  }

  var displayName: String
}

/// Background URLSession downloads with progress callbacks to Flutter.
final class BackgroundDownloadManager: NSObject, URLSessionDownloadDelegate {
  static let shared = BackgroundDownloadManager()
  static let sessionIdentifier = "net.neuro9.lmmini.model-download"

  private var channel: FlutterMethodChannel?
  private var backgroundCompletionHandler: (() -> Void)?
  private var taskMeta: [Int: [String: Any]] = [:]
  private var downloadActivity: Any?
  private var isRequestingDownloadActivity = false
  private var lastLiveActivityUpdate: Date = .distantPast
  private var lastSpeedBytes: Int64 = 0
  private var lastSpeedAt: Date = .distantPast
  private var lastBytesPerSecond: Int = 0

  private lazy var session: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
    config.isDiscretionary = false
    config.sessionSendsLaunchEvents = true
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }()

  func bind(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "net.neuro9.lmmini/model_download",
      binaryMessenger: messenger,
    )
    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Download manager gone", details: nil))
        return
      }
      switch call.method {
      case "isAvailable":
        result(true)
      case "startDownload":
        guard let args = call.arguments as? [String: Any],
              let jobId = args["jobId"] as? String,
              let url = args["url"] as? String,
              let partialPath = args["partialPath"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing download args", details: nil))
          return
        }
        let displayName = args["displayName"] as? String ?? "Download"
        let showLiveActivity = args["showLiveActivity"] as? Bool ?? true
        let updateExistingLiveActivity =
          args["updateExistingLiveActivity"] as? Bool ?? false
        self.startDownload(
          jobId: jobId,
          displayName: displayName,
          url: url,
          partialPath: partialPath,
          showLiveActivity: showLiveActivity,
          updateExistingLiveActivity: updateExistingLiveActivity,
        )
        result(nil)
      case "cancelDownload":
        guard let args = call.arguments as? [String: Any],
              let jobId = args["jobId"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "jobId required", details: nil))
          return
        }
        self.cancelDownload(jobId: jobId)
        result(nil)
      case "startDownloadLiveActivity":
        if #available(iOS 16.2, *) {
          let args = call.arguments as? [String: Any] ?? [:]
          self.startDownloadLiveActivity(
            displayName: args["displayName"] as? String ?? "Download",
            progress: args["progress"] as? Double ?? 0,
            statusText: args["statusText"] as? String ?? "Starting…",
            completion: { result(nil) },
          )
        } else {
          result(nil)
        }
      case "updateDownloadLiveActivity":
        if #available(iOS 16.2, *) {
          let args = call.arguments as? [String: Any] ?? [:]
          self.updateDownloadLiveActivity(
            displayName: args["displayName"] as? String ?? "Download",
            progress: args["progress"] as? Double ?? 0,
            statusText: args["statusText"] as? String ?? "",
          )
        }
        result(nil)
      case "endDownloadLiveActivity":
        if #available(iOS 16.2, *) {
          let success = (call.arguments as? [String: Any])?["success"] as? Bool ?? true
          self.endDownloadLiveActivity(success: success)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func setBackgroundCompletionHandler(_ handler: @escaping () -> Void) {
    backgroundCompletionHandler = handler
  }

  func startDownload(
    jobId: String,
    displayName: String,
    url: String,
    partialPath: String,
    showLiveActivity: Bool = true,
    updateExistingLiveActivity: Bool = false,
  ) {
    guard let downloadURL = URL(string: url) else {
      notifyError(jobId: jobId, message: "Invalid URL")
      return
    }

    var request = URLRequest(url: downloadURL)
    let partialURL = URL(fileURLWithPath: partialPath)
    let existingBytes: Int64
    if FileManager.default.fileExists(atPath: partialPath),
       let attrs = try? FileManager.default.attributesOfItem(atPath: partialPath),
       let size = attrs[.size] as? NSNumber {
      existingBytes = size.int64Value
      if existingBytes > 0 {
        request.setValue("bytes=\(existingBytes)-", forHTTPHeaderField: "Range")
      }
    } else {
      existingBytes = 0
      try? FileManager.default.createDirectory(
        at: partialURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
      )
    }

    if #available(iOS 16.2, *), showLiveActivity, downloadActivity == nil {
      startDownloadLiveActivity(displayName: displayName)
    }

    lastSpeedBytes = 0
    lastSpeedAt = .distantPast
    lastBytesPerSecond = 0

    let task = session.downloadTask(with: request)
    taskMeta[task.taskIdentifier] = [
      "jobId": jobId,
      "displayName": displayName,
      "partialPath": partialPath,
      "existingBytes": existingBytes,
      "showLiveActivity": showLiveActivity,
      "updateExistingLiveActivity": updateExistingLiveActivity,
    ]
    task.resume()
  }

  func cancelDownload(jobId: String) {
    session.getAllTasks { tasks in
      for task in tasks {
        guard let meta = self.taskMeta[task.taskIdentifier],
              meta["jobId"] as? String == jobId else { continue }
        task.cancel()
        let showLA = meta["showLiveActivity"] as? Bool ?? true
        self.taskMeta.removeValue(forKey: task.taskIdentifier)
        self.notifyCancelled(jobId: jobId)
        if showLA, #available(iOS 16.2, *) {
          self.endDownloadLiveActivity(success: false)
        }
      }
    }
  }

  // MARK: - URLSessionDownloadDelegate

  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64,
  ) {
    guard let meta = taskMeta[downloadTask.taskIdentifier],
          let jobId = meta["jobId"] as? String else { return }
    let existing = meta["existingBytes"] as? Int64 ?? 0
    let downloaded = existing + totalBytesWritten
    let total = existing + max(totalBytesExpectedToWrite, 0)
    let progress = total > 0 ? Double(downloaded) / Double(total) : 0

    let now = Date()
    let elapsed = now.timeIntervalSince(lastSpeedAt)
    if elapsed >= 0.4, lastSpeedAt != .distantPast {
      let delta = downloaded - lastSpeedBytes
      if delta > 0 {
        lastBytesPerSecond = Int(Double(delta) / elapsed)
      }
      lastSpeedBytes = downloaded
      lastSpeedAt = now
    } else if lastSpeedAt == .distantPast {
      lastSpeedBytes = downloaded
      lastSpeedAt = now
    }

    notifyProgress(
      jobId: jobId,
      bytesDownloaded: downloaded,
      bytesTotal: total > 0 ? total : nil,
      bytesPerSecond: lastBytesPerSecond,
    )

    let showLA = meta["showLiveActivity"] as? Bool ?? true
    let updateExisting = meta["updateExistingLiveActivity"] as? Bool ?? false
    if showLA || updateExisting, #available(iOS 16.2, *) {
      let now = Date()
      guard now.timeIntervalSince(lastLiveActivityUpdate) >= 0.4 else { return }
      lastLiveActivityUpdate = now
      let displayName = meta["displayName"] as? String ?? "Download"
      updateDownloadLiveActivity(
        displayName: displayName,
        progress: progress,
        statusText: "Downloading…",
      )
    }
  }

  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL,
  ) {
    guard let meta = taskMeta[downloadTask.taskIdentifier],
          let jobId = meta["jobId"] as? String,
          let partialPath = meta["partialPath"] as? String else { return }

    let dest = URL(fileURLWithPath: partialPath)
    let existingBytes = meta["existingBytes"] as? Int64 ?? 0
    do {
      if existingBytes > 0 {
        let handle = try FileHandle(forWritingTo: dest)
        defer { try? handle.close() }
        try handle.seekToEnd()
        let data = try Data(contentsOf: location)
        try handle.write(contentsOf: data)
      } else {
        if FileManager.default.fileExists(atPath: partialPath) {
          try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: location, to: dest)
      }
      notifyComplete(jobId: jobId)
      let showLA = meta["showLiveActivity"] as? Bool ?? true
      if showLA, #available(iOS 16.2, *) {
        endDownloadLiveActivity(success: true)
      }
    } catch {
      notifyError(jobId: jobId, message: error.localizedDescription)
      let showLA = meta["showLiveActivity"] as? Bool ?? true
      if showLA, #available(iOS 16.2, *) {
        endDownloadLiveActivity(success: false)
      }
    }
    taskMeta.removeValue(forKey: downloadTask.taskIdentifier)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error else { return }
    guard let meta = taskMeta[task.taskIdentifier],
          let jobId = meta["jobId"] as? String else { return }
    if (error as NSError).code == NSURLErrorCancelled {
      notifyCancelled(jobId: jobId)
    } else {
      notifyError(jobId: jobId, message: error.localizedDescription)
    }
    taskMeta.removeValue(forKey: task.taskIdentifier)
    let showLA = meta["showLiveActivity"] as? Bool ?? true
    if showLA, #available(iOS 16.2, *) {
      endDownloadLiveActivity(success: false)
    }
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async {
      self.backgroundCompletionHandler?()
      self.backgroundCompletionHandler = nil
    }
  }

  // MARK: - Flutter callbacks

  private func notifyProgress(
    jobId: String,
    bytesDownloaded: Int64,
    bytesTotal: Int64?,
    bytesPerSecond: Int,
  ) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod(
        "onProgress",
        arguments: [
          "jobId": jobId,
          "bytesDownloaded": bytesDownloaded,
          "bytesTotal": bytesTotal as Any,
          "bytesPerSecond": bytesPerSecond,
        ],
      )
    }
  }

  private func notifyComplete(jobId: String) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onComplete", arguments: ["jobId": jobId])
    }
  }

  private func notifyError(jobId: String, message: String) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onError", arguments: ["jobId": jobId, "message": message])
    }
  }

  private func notifyCancelled(jobId: String) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onCancelled", arguments: jobId)
    }
  }

  // MARK: - Download Live Activity

  func forgetDownloadLiveActivity() {
    downloadActivity = nil
  }

  @available(iOS 16.2, *)
  func startDownloadLiveActivity(
    displayName: String,
    progress: Double = 0,
    statusText: String = "Starting…",
    completion: (() -> Void)? = nil,
  ) {
    if isRequestingDownloadActivity {
      completion?()
      return
    }
    isRequestingDownloadActivity = true
    let attributes = LMDownloadActivityAttributes(displayName: displayName)
    let state = LMDownloadActivityAttributes.ContentState(
      displayName: displayName,
      progress: progress,
      statusText: statusText,
    )
    Task {
      defer { self.isRequestingDownloadActivity = false }
      for activity in Activity<LMDownloadActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      do {
        let activity = try Activity.request(
          attributes: attributes,
          content: .init(state: state, staleDate: nil),
          pushType: nil,
        )
        self.downloadActivity = activity
      } catch {
        debugPrint("Download LiveActivity start failed: \(error)")
      }
      completion?()
    }
  }

  @available(iOS 16.2, *)
  func updateDownloadLiveActivity(displayName: String, progress: Double, statusText: String) {
    guard let activity = downloadActivity as? Activity<LMDownloadActivityAttributes> else {
      return
    }
    let state = LMDownloadActivityAttributes.ContentState(
      displayName: displayName,
      progress: progress,
      statusText: statusText,
    )
    Task {
      await activity.update(.init(state: state, staleDate: nil))
    }
  }

  @available(iOS 16.2, *)
  func endDownloadLiveActivity(success: Bool) {
    Task {
      for activity in Activity<LMDownloadActivityAttributes>.activities {
        let final = LMDownloadActivityAttributes.ContentState(
          displayName: activity.content.state.displayName,
          progress: success ? 1.0 : activity.content.state.progress,
          statusText: success ? "Complete" : "Failed",
        )
        await activity.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate)
      }
      downloadActivity = nil
    }
  }
}
