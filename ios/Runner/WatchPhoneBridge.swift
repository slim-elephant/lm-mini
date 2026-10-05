import Flutter
import Foundation
import UIKit
import WatchConnectivity

/// iPhone side of the watch link.
///
/// Ping answers with the model name from the Siri snapshot. A `send` tries
/// the same native LAN/cloud request Siri uses and streams short chunks
/// back. If that snapshot cannot answer, Mini runs the normal ask shortcut.
final class WatchPhoneBridge: NSObject, WCSessionDelegate {
  static let shared = WatchPhoneBridge()

  private let lock = NSLock()
  private var activeRequestId = ""
  private var jpegCache: [String: String] = [:]
  private var statusWaiters: [CheckedContinuation<[String: Bool], Never>] = []
  private let dart = WatchDartClient()

  func bind(messenger: FlutterBinaryMessenger) {
    dart.bind(messenger: messenger) { [weak self] method, args in
      self?.forwardFromDart(method: method, args: args)
    }
  }

  private static let systemPrompt = "You are a helpful assistant. Reply concisely, in one short paragraph."

  private static func flags(_ session: WCSession) -> [String: Bool] {
    let paired = session.activationState == .activated && session.isPaired
    return [
      "paired": paired,
      "installed": paired && session.isWatchAppInstalled,
    ]
  }

  private func finishStatusWaiters() {
    let deliver = { [weak self] in
      guard let self, !self.statusWaiters.isEmpty else { return }
      let waiters = self.statusWaiters
      self.statusWaiters.removeAll()
      let flags = Self.flags(WCSession.default)
      for waiter in waiters {
        waiter.resume(returning: flags)
      }
    }
    if Thread.isMainThread {
      deliver()
    } else {
      DispatchQueue.main.async(execute: deliver)
    }
  }

  func start() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  /// `isPaired` is only meaningful after the session has activated.
  func watchStatus() async -> [String: Bool] {
    guard WCSession.isSupported() else {
      return ["paired": false, "installed": false]
    }
    let session = WCSession.default
    if session.activationState == .activated {
      return Self.flags(session)
    }
    session.delegate = self
    return await withCheckedContinuation { continuation in
      statusWaiters.append(continuation)
      session.activate()
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        self?.finishStatusWaiters()
      }
    }
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    finishStatusWaiters()
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    switch message["name"] as? String {
    case "ping":
      replyHandler([
        "name": "pong",
        "model": Self.savedModelName() ?? "",
      ])
    case "listChats":
      replyHandler(["name": "accepted"])
      Task { await self.listChats() }
    case "persona":
      let personaId = (message["personaId"] as? String) ?? ""
      replyHandler(["name": "accepted"])
      Task { await self.openPersona(personaId) }
    case "openChat":
      let conversationId = (message["conversationId"] as? String) ?? ""
      replyHandler(["name": "accepted"])
      Task { await self.openChat(conversationId) }
    case "send":
      let text = (message["text"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let image = (message["image"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let requestId = (message["requestId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        ?? UUID().uuidString
      let conversationId = (message["conversationId"] as? String) ?? ""
      guard !text.isEmpty || !image.isEmpty else {
        replyHandler([
          "name": "done",
          "requestId": requestId,
          "error": "Type a message first.",
        ])
        return
      }
      claim(requestId)
      replyHandler([
        "name": "accepted",
        "requestId": requestId,
        "model": Self.savedModelName() ?? "",
      ])
      Task {
        await self.answer(
          text: text,
          image: image,
          requestId: requestId,
          conversationId: conversationId
        )
      }
    case "regenerate":
      let requestId = (message["requestId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        ?? UUID().uuidString
      let conversationId = (message["conversationId"] as? String) ?? ""
      let messageId = (message["messageId"] as? String) ?? ""
      claim(requestId)
      replyHandler(["name": "accepted", "requestId": requestId])
      Task {
        await self.turn(
          method: "regenerate",
          requestId: requestId,
          conversationId: conversationId,
          messageId: messageId
        )
      }
    case "edit":
      let text = (message["text"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let requestId = (message["requestId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        ?? UUID().uuidString
      let conversationId = (message["conversationId"] as? String) ?? ""
      let messageId = (message["messageId"] as? String) ?? ""
      guard !text.isEmpty, !messageId.isEmpty else {
        replyHandler([
          "name": "done",
          "requestId": requestId,
          "error": "That message could not be edited.",
        ])
        return
      }
      claim(requestId)
      replyHandler(["name": "accepted", "requestId": requestId])
      Task {
        await self.turn(
          method: "edit",
          requestId: requestId,
          conversationId: conversationId,
          messageId: messageId,
          text: text
        )
      }
    case "delete":
      let requestId = (message["requestId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        ?? UUID().uuidString
      let conversationId = (message["conversationId"] as? String) ?? ""
      let messageId = (message["messageId"] as? String) ?? ""
      claim(requestId)
      replyHandler(["name": "accepted", "requestId": requestId])
      Task {
        await self.turn(
          method: "delete",
          requestId: requestId,
          conversationId: conversationId,
          messageId: messageId
        )
      }
    case "branch":
      let requestId = (message["requestId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        ?? UUID().uuidString
      let conversationId = (message["conversationId"] as? String) ?? ""
      let messageId = (message["messageId"] as? String) ?? ""
      claim(requestId)
      replyHandler(["name": "accepted", "requestId": requestId])
      Task {
        await self.turn(
          method: "branch",
          requestId: requestId,
          conversationId: conversationId,
          messageId: messageId
        )
      }
    case "imagine":
      let prompt = (message["prompt"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let requestId = (message["requestId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        ?? UUID().uuidString
      let conversationId = (message["conversationId"] as? String) ?? ""
      guard !prompt.isEmpty else {
        replyHandler([
          "name": "imagineStatus",
          "requestId": requestId,
          "state": "failed",
          "error": "Type a prompt first.",
        ])
        return
      }
      replyHandler(["name": "accepted", "requestId": requestId])
      Task {
        await self.imagine(
          prompt: prompt,
          requestId: requestId,
          conversationId: conversationId
        )
      }
    case "copy":
      let text = (message["text"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !text.isEmpty else {
        replyHandler(["name": "done", "error": "Nothing to copy."])
        return
      }
      UIPasteboard.general.string = text
      replyHandler(["name": "accepted"])
    default:
      replyHandler(["name": "unknown"])
    }
  }

  private func listChats() async {
    do {
      let value = try await dart.invoke("listChats", arguments: nil)
      var body: [String: Any] = ["name": "chats"]
      if let map = value as? [String: Any] {
        let packed = packFaces(chats: map["chats"], personas: map["personas"])
        body["items"] = packed.items
        body["personas"] = packed.personas
        if !packed.faces.isEmpty { body["faces"] = packed.faces }
        if let folders = map["folders"] { body["folders"] = folders }
        attachLook(map["look"], to: &body)
      } else if let value {
        body["items"] = value
      }
      sendToWatch(body)
    } catch {
      sendToWatch([
        "name": "chats",
        "error": Self.message(from: error),
      ])
    }
  }

  private func openPersona(_ personaId: String) async {
    do {
      let value = try await dart.invoke("persona", arguments: ["personaId": personaId])
      var body: [String: Any] = ["name": "personaReady"]
      if let map = value as? [String: Any] {
        if let conversationId = map["conversationId"] {
          body["conversationId"] = conversationId
        }
        attachLook(map["look"], to: &body)
      }
      sendToWatch(body)
    } catch {
      sendToWatch([
        "name": "personaReady",
        "error": Self.message(from: error),
      ])
    }
  }

  private func openChat(_ conversationId: String) async {
    do {
      let value = try await dart.invoke(
        "openChat",
        arguments: ["conversationId": conversationId]
      )
      var body: [String: Any] = [
        "name": "messages",
        "conversationId": conversationId,
      ]
      if let map = value as? [String: Any], map["items"] != nil {
        body["items"] = packMessageImages(map["items"])
        if let title = map["title"] as? String, !title.isEmpty {
          body["title"] = title
        }
        attachLook(map["look"], to: &body)
      } else if let value {
        body["items"] = value
      }
      sendToWatch(body)
    } catch {
      sendToWatch([
        "name": "messages",
        "conversationId": conversationId,
        "error": Self.message(from: error),
      ])
    }
  }

  private func turn(
    method: String,
    requestId: String,
    conversationId: String,
    messageId: String = "",
    text: String = ""
  ) async {
    do {
      var arguments: [String: Any] = [
        "requestId": requestId,
        "conversationId": conversationId,
        "messageId": messageId,
      ]
      if !text.isEmpty { arguments["text"] = text }
      let result = try await dart.invoke(method, arguments: arguments)
      guard isCurrent(requestId) else { return }
      let savedId = (result as? [String: Any])?["conversationId"] as? String ?? ""
      if method == "branch", !savedId.isEmpty {
        sendToWatch([
          "name": "opened",
          "requestId": requestId,
          "conversationId": savedId,
          "branch": true,
        ])
        await openChat(savedId)
        return
      }
      if !savedId.isEmpty, method != "delete" {
        sendToWatch([
          "name": "opened",
          "requestId": requestId,
          "conversationId": savedId,
        ])
      }
    } catch {
      guard isCurrent(requestId) else { return }
      sendToWatch([
        "name": "done",
        "requestId": requestId,
        "error": Self.message(from: error),
      ])
    }
  }

  private func answer(
    text: String,
    image: String,
    requestId: String,
    conversationId: String
  ) async {
    do {
      var arguments: [String: Any] = [
        "text": text,
        "requestId": requestId,
        "conversationId": conversationId,
      ]
      if !image.isEmpty {
        arguments["image"] = image
      }
      let result = try await dart.invoke("send", arguments: arguments)
      guard isCurrent(requestId) else { return }
      let savedId = (result as? [String: Any])?["conversationId"] as? String ?? ""
      if !savedId.isEmpty {
        sendToWatch([
          "name": "opened",
          "requestId": requestId,
          "conversationId": savedId,
        ])
      }
      return
    } catch let failure as WatchDartFailure where failure.code == "unavailable" {
      if image.isEmpty {
        await answerWithoutSaving(text: text, requestId: requestId)
      } else if isCurrent(requestId) {
        sendToWatch([
          "name": "done",
          "requestId": requestId,
          "error": "Open LM Mini on the iPhone, then try again.",
        ])
      }
    } catch {
      guard isCurrent(requestId) else { return }
      sendToWatch([
        "name": "done",
        "requestId": requestId,
        "error": Self.message(from: error),
      ])
    }
  }

  private func imagine(prompt: String, requestId: String, conversationId: String) async {
    do {
      let result = try await dart.invoke("imagine", arguments: [
        "prompt": prompt,
        "requestId": requestId,
        "conversationId": conversationId,
      ])
      let map = result as? [String: Any]
      let savedId = map?["conversationId"] as? String ?? ""
      let path = (map?["path"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let preview = path.isEmpty ? "" : jpeg(path: path, maxEdge: 300, maxBytes: 40_000)
      guard !preview.isEmpty else {
        sendToWatch([
          "name": "imagineStatus",
          "requestId": requestId,
          "state": "failed",
          "conversationId": savedId,
          "error": "The image is on the iPhone, but the preview could not be sent.",
        ])
        return
      }
      var previewBody: [String: Any] = [
        "name": "imaginePreview",
        "requestId": requestId,
        "preview": preview,
      ]
      if !savedId.isEmpty { previewBody["conversationId"] = savedId }
      sendToWatch(previewBody)
      var ready: [String: Any] = [
        "name": "imagineStatus",
        "requestId": requestId,
        "state": "ready",
      ]
      if !savedId.isEmpty { ready["conversationId"] = savedId }
      sendToWatch(ready)
    } catch {
      sendToWatch([
        "name": "imagineStatus",
        "requestId": requestId,
        "state": "failed",
        "error": Self.message(from: error),
      ])
    }
  }

  /// Dart pushes these while a saved send is running.
  private func forwardFromDart(method: String, args: Any?) {
    guard var body = args as? [String: Any] else { return }
    let requestId = body["requestId"] as? String ?? ""
    if method == "imagineStatus" {
      body["name"] = method
      sendToWatch(body)
      return
    }
    guard requestId.isEmpty || isCurrent(requestId) else { return }
    body["name"] = method
    if method == "done", let full = body["fullText"] as? String, full.count > 3500 {
      body["fullText"] = String(full.prefix(3500)) + "…"
    }
    sendToWatch(body)
  }

  private func answerWithoutSaving(text: String, requestId: String) async {
    do {
      if let streamed = try await LMMiniSiriNativeChat.stream(
        system: Self.systemPrompt,
        user: text,
        onDelta: { [weak self] chunk in
          guard let self, self.isCurrent(requestId) else { return }
          self.sendToWatch([
            "name": "delta",
            "requestId": requestId,
            "text": chunk,
          ])
        }
      ) {
        guard isCurrent(requestId) else { return }
        sendToWatch([
          "name": "done",
          "requestId": requestId,
          "fullText": streamed,
        ])
        return
      }
    } catch {
      guard isCurrent(requestId) else { return }
      sendToWatch([
        "name": "done",
        "requestId": requestId,
        "error": Self.message(from: error),
      ])
      return
    }

    do {
      let answer = try await LMMiniSiriRun.execute(
        path: "/ask",
        query: [
          "prompt": text,
          "onDevice": "0",
          "speak": "0",
        ],
        nativeSystem: nil,
        nativeUser: nil,
        allowNative: false,
        requestForeground: {
          await MainActor.run {
            (UIApplication.shared.delegate as? AppDelegate)?.deliverPendingWatchAsk()
          }
        }
      )
      guard isCurrent(requestId) else { return }
      sendToWatch([
        "name": "delta",
        "requestId": requestId,
        "text": answer,
      ])
      sendToWatch([
        "name": "done",
        "requestId": requestId,
        "fullText": answer,
      ])
    } catch {
      guard isCurrent(requestId) else { return }
      sendToWatch([
        "name": "done",
        "requestId": requestId,
        "error": Self.message(from: error),
      ])
    }
  }

  /// One JPEG per picture, shared by every chat that uses it.
  ///
  /// A 40-pixel face squeezed under 700 bytes was soft at the size the
  /// home row draws. These stay near 128 pixels, and repeat paths are
  /// sent once so the list still fits in a watch message.
  private func packFaces(chats: Any?, personas: Any?) -> (
    items: Any?,
    personas: Any?,
    faces: [String: String]
  ) {
    var faces: [String: String] = [:]
    var pathToId: [String: String] = [:]
    var budget = 48_000
    func bind(_ value: Any?) -> String {
      let path = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !path.isEmpty else { return "" }
      if let id = pathToId[path] { return id }
      let encoded = jpeg(path: path, maxEdge: 128, maxBytes: 4_500, qualityStart: 0.82)
      guard !encoded.isEmpty, encoded.count <= budget else { return "" }
      budget -= encoded.count
      let id = "\(pathToId.count)"
      pathToId[path] = id
      faces[id] = encoded
      return id
    }
    func rewrite(_ rows: Any?) -> Any? {
      guard let rows = rows as? [[String: Any]] else { return rows }
      return rows.map { row in
        var next = row
        let avatar = bind(row["avatar"])
        let avatar2 = bind(row["avatar2"])
        if avatar.isEmpty { next.removeValue(forKey: "avatar") } else { next["avatar"] = avatar }
        if avatar2.isEmpty { next.removeValue(forKey: "avatar2") } else { next["avatar2"] = avatar2 }
        return next
      }
    }
    return (rewrite(chats), rewrite(personas), faces)
  }

  /// Small JPEGs for photos that belong to the open chat. Newest first,
  /// and only a handful, so the transcript still fits in one watch message.
  private func packMessageImages(_ items: Any?) -> Any? {
    guard var rows = items as? [[String: Any]] else { return items }
    var budget = 36_000
    for index in rows.indices.reversed() {
      let path = (rows[index]["image"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      rows[index].removeValue(forKey: "image")
      guard !path.isEmpty, budget > 2_000 else { continue }
      let encoded = jpeg(
        path: path,
        maxEdge: 200,
        maxBytes: min(8_000, budget),
        qualityStart: 0.72
      )
      guard !encoded.isEmpty else { continue }
      budget -= encoded.count
      rows[index]["image"] = encoded
    }
    return rows
  }

  private func attachLook(_ look: Any?, to body: inout [String: Any]) {
    guard let look = look as? [String: Any] else { return }
    if let fullWidth = look["fullWidth"] { body["fullWidth"] = fullWidth }
    if let watchPersonas = look["watchPersonas"] {
      body["watchPersonas"] = watchPersonas
    }
    if let dim = look["dim"] { body["dim"] = dim }
    if let color = look["color"] { body["color"] = color }
    if let imageGen = look["imageGen"] { body["imageGen"] = imageGen }
    if let group = look["group"] { body["group"] = group }
    for key in ["personaId", "personaName", "prompt", "model", "provider"] {
      if let value = look[key] { body[key] = value }
    }
    if let modelPinned = look["modelPinned"] { body["modelPinned"] = modelPinned }
    if let providerPinned = look["providerPinned"] { body["providerPinned"] = providerPinned }
    let wallpaper = (look["wallpaper"] as? String) ?? ""
    body["wallpaper"] = wallpaper.isEmpty
      ? ""
      : jpeg(path: wallpaper, maxEdge: 280, maxBytes: 18_000)
    let avatar = (look["avatar"] as? String) ?? ""
    body["avatar"] = avatar.isEmpty
      ? ""
      : jpeg(path: avatar, maxEdge: 180, maxBytes: 14_000, qualityStart: 0.8)
  }

  private func jpeg(
    path: String,
    maxEdge: CGFloat,
    maxBytes: Int,
    qualityStart: CGFloat = 0.75
  ) -> String {
    let key = "\(path)|\(Int(maxEdge))|\(maxBytes)|\(Int(qualityStart * 100))"
    if let cached = jpegCache[key] { return cached }
    guard let image = UIImage(contentsOfFile: path) else { return "" }
    var edge = maxEdge
    var quality = qualityStart
    var encoded = ""
    let format = UIGraphicsImageRendererFormat()
    // The default scale follows the iPhone screen, so a 40-point face became
    // a huge bitmap crushed into a tiny JPEG. maxEdge is pixels.
    format.scale = 1
    for _ in 0..<4 {
      let longest = max(image.size.width, image.size.height)
      let scale = longest > 0 ? min(1, edge / longest) : 1
      let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
      let scaled = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
        renderer.cgContext.interpolationQuality = .high
        image.draw(in: CGRect(origin: .zero, size: size))
      }
      guard let data = scaled.jpegData(compressionQuality: quality) else { break }
      encoded = data.base64EncodedString()
      if data.count <= maxBytes { break }
      quality *= 0.65
      edge *= 0.8
    }
    jpegCache[key] = encoded
    return encoded
  }

  private func sendToWatch(_ body: [String: Any]) {
    let session = WCSession.default
    guard session.activationState == .activated, session.isReachable else { return }
    session.sendMessage(body, replyHandler: nil) { error in
      NSLog("LMMini watch push failed: \(error.localizedDescription)")
    }
  }

  private func claim(_ requestId: String) {
    lock.lock()
    activeRequestId = requestId
    lock.unlock()
  }

  private func isCurrent(_ requestId: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return activeRequestId == requestId
  }

  private static func message(from error: Error) -> String {
    if let failure = error as? WatchDartFailure {
      return failure.message
    }
    if let failure = error as? LMMiniSiriFailure {
      return failure.message
    }
    return error.localizedDescription
  }

  private static func savedModelName() -> String? {
    guard let defaults = UserDefaults(suiteName: "group.net.neuro9.lmmini"),
          let json = defaults.string(forKey: "siriInferenceSnapshot"),
          let data = json.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    let model = object["model"] as? String
    let trimmed = model?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
  }
}

struct WatchDartFailure: Error {
  let code: String
  let message: String
}

/// Calls into `WatchBridge` on the Flutter side.
final class WatchDartClient {
  private var channel: FlutterMethodChannel?

  func bind(
    messenger: FlutterBinaryMessenger,
    onPush: @escaping (String, Any?) -> Void
  ) {
    let channel = FlutterMethodChannel(
      name: "net.neuro9.lmmini/watch",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "delta", "done", "imagineStatus", "look":
        onPush(call.method, call.arguments)
        result(nil)
      case "watchStatus":
        Task {
          let status = await WatchPhoneBridge.shared.watchStatus()
          result(status)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  func invoke(_ method: String, arguments: Any?) async throws -> Any? {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.main.async {
        guard let channel = self.channel else {
          continuation.resume(
            throwing: WatchDartFailure(
              code: "unavailable",
              message: "Open LM Mini on the iPhone, then try again."
            )
          )
          return
        }
        channel.invokeMethod(method, arguments: arguments) { value in
          if let error = value as? FlutterError {
            continuation.resume(
              throwing: WatchDartFailure(
                code: error.code,
                message: error.message ?? error.code
              )
            )
            return
          }
          if let value,
             (value as AnyObject) === (FlutterMethodNotImplemented as AnyObject) {
            continuation.resume(
              throwing: WatchDartFailure(
                code: "unavailable",
                message: "Open LM Mini on the iPhone, then try again."
              )
            )
            return
          }
          continuation.resume(returning: value)
        }
      }
    }
  }
}
