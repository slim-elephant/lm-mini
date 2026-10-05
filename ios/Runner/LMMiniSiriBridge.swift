// LMMiniSiriBridge.swift
//
// App Group wait-and-return + native OpenAI-compatible HTTP for Siri.
//
// Ask / Summarize / Translate try a background URLSession first (LM Studio
// LAN or cloud). If that is not eligible (on-device, USB, loopback, no
// model), the intent queues a `lmmini://shortcut/...?waitId=` URL, brings
// Flutter forward, and waits for Dart to post the answer.

import AppIntents
import Flutter
import Foundation
import Network

enum LMMiniSiriStore {
  static let appGroup = "group.net.neuro9.lmmini"
  static let snapshotKey = "siriInferenceSnapshot"
  static let activeWaitIdKey = "siriActiveWaitId"
  static let pendingShortcutKey = "pendingShortcut"

  static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroup)
  }

  static func resultKey(_ waitId: String) -> String { "siriResult.\(waitId)" }
  static func errorKey(_ waitId: String) -> String { "siriError.\(waitId)" }

  @discardableResult
  static func queueShortcut(path: String, query: [String: String]) -> URL {
    var comps = URLComponents()
    comps.scheme = "lmmini"
    comps.host = "shortcut"
    comps.path = path.hasPrefix("/") ? path : "/\(path)"
    comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
    let url = comps.url!
    defaults?.set(url.absoluteString, forKey: pendingShortcutKey)
    return url
  }

  static func writeSnapshot(_ map: [String: Any]) {
    guard JSONSerialization.isValidJSONObject(map),
          let data = try? JSONSerialization.data(withJSONObject: map),
          let json = String(data: data, encoding: .utf8)
    else { return }
    defaults?.set(json, forKey: snapshotKey)
  }

  static func complete(waitId: String, text: String) {
    defaults?.set(text, forKey: resultKey(waitId))
    defaults?.removeObject(forKey: errorKey(waitId))
  }

  static func fail(waitId: String, error: String) {
    defaults?.set(error, forKey: errorKey(waitId))
  }

  static func peekResult(waitId: String) -> (text: String?, error: String?) {
    (
      defaults?.string(forKey: resultKey(waitId)),
      defaults?.string(forKey: errorKey(waitId))
    )
  }

  static func clearResult(waitId: String) {
    defaults?.removeObject(forKey: resultKey(waitId))
    defaults?.removeObject(forKey: errorKey(waitId))
  }
}

struct LMMiniSiriSnapshot {
  let eligible: Bool
  let chatUrl: String?
  let model: String?
  let headers: [String: String]
  let temperature: Double
  let maxTokens: Int
  let ineligibleReason: String?

  static var current: LMMiniSiriSnapshot? {
    guard let json = LMMiniSiriStore.defaults?.string(forKey: LMMiniSiriStore.snapshotKey),
          let data = json.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    var headers: [String: String] = [:]
    if let raw = obj["headers"] as? [String: Any] {
      for (k, v) in raw { headers[k] = "\(v)" }
    }
    return LMMiniSiriSnapshot(
      eligible: obj["eligible"] as? Bool ?? false,
      chatUrl: obj["chatUrl"] as? String,
      model: obj["model"] as? String,
      headers: headers,
      temperature: (obj["temperature"] as? NSNumber)?.doubleValue ?? 0.7,
      maxTokens: (obj["maxTokens"] as? NSNumber)?.intValue ?? 512,
      ineligibleReason: obj["ineligibleReason"] as? String
    )
  }
}

/// HTTP/1.1 over TCP for `http://` model servers.
///
/// A background Shortcut's URLSession still applies App Transport Security
/// even when the app allows insecure loads, which is the "secure connection"
/// error on Ask LM Mini. Network.framework is not covered by that policy.
enum LMMiniPlainHTTP {
  struct Result {
    let status: Int
    let body: Data
  }

  static func post(
    url: URL,
    headers: [String: String],
    body: Data,
    timeout: TimeInterval
  ) async throws -> Result {
    guard url.scheme?.lowercased() == "http",
          let host = url.host, !host.isEmpty,
          let port = NWEndpoint.Port(rawValue: UInt16(url.port ?? 80))
    else { throw URLError(.badURL) }

    let connection = NWConnection(
      host: NWEndpoint.Host(host),
      port: port,
      using: .tcp)
    let box = ConnectionBox(connection)
    defer { connection.cancel() }

    do {
      return try await withThrowingTimeout(seconds: timeout, onTimeout: {
        box.connection?.cancel()
      }) {
        do {
          return try await exchange(
            connection: connection, url: url, headers: headers, body: body)
        } catch let urlError as URLError where urlError.code == .cancelled {
          throw URLError(.timedOut)
        }
      }
    } catch {
      throw Self.transportError(error)
    }
  }

  private static func transportError(_ error: Error) -> Error {
    if error is CancellationError { return error }
    if error is URLError { return error }
    let ns = error as NSError
    if ns.domain == NSURLErrorDomain { return error }
    if ns.domain == NSPOSIXErrorDomain && ns.code == Int(ETIMEDOUT) {
      return URLError(.timedOut)
    }
    return URLError(.cannotConnectToHost)
  }

  private static func exchange(
    connection: NWConnection,
    url: URL,
    headers: [String: String],
    body: Data
  ) async throws -> Result {
    try await waitUntilReady(connection)
    let payload = requestBytes(url: url, headers: headers, body: body)
    try await send(connection, payload)
    let raw = try await receive(connection)
    guard let parsed = parse(raw, connectionClosed: true) else {
      throw URLError(.badServerResponse)
    }
    return parsed
  }

  private static func requestBytes(
    url: URL,
    headers: [String: String],
    body: Data
  ) -> Data {
    let host = url.host ?? ""
    var hostHeader = host.contains(":") ? "[\(host)]" : host
    if let port = url.port, port != 80 {
      hostHeader += ":\(port)"
    }
    var path = url.path
    if path.isEmpty { path = "/" }
    if let query = url.query, !query.isEmpty {
      path += "?\(query)"
    }
    var lines = [
      "POST \(path) HTTP/1.1",
      "Host: \(hostHeader)",
      "Content-Length: \(body.count)",
      "Connection: close",
    ]
    var seen = Set(["host", "content-length", "connection"])
    for (key, value) in headers {
      let name = key.trimmingCharacters(in: .whitespaces)
      if name.isEmpty || seen.contains(name.lowercased()) { continue }
      seen.insert(name.lowercased())
      lines.append("\(name): \(value)")
    }
    if !seen.contains("content-type") {
      lines.append("Content-Type: application/json")
    }
    var data = Data(lines.joined(separator: "\r\n").utf8)
    data.append(Data("\r\n\r\n".utf8))
    data.append(body)
    return data
  }

  private static func waitUntilReady(_ connection: NWConnection) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
      let gate = ResumeOnce()
      connection.stateUpdateHandler = { state in
        switch state {
        case .ready:
          connection.stateUpdateHandler = nil
          gate.resume { cont.resume() }
        case .failed(let error):
          connection.stateUpdateHandler = nil
          gate.resume { cont.resume(throwing: error) }
        case .cancelled:
          connection.stateUpdateHandler = nil
          gate.resume { cont.resume(throwing: URLError(.cancelled)) }
        default:
          break
        }
      }
      connection.start(queue: .global(qos: .userInitiated))
    }
  }

  private static func send(_ connection: NWConnection, _ data: Data) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
      connection.send(content: data, completion: .contentProcessed { error in
        if let error {
          cont.resume(throwing: error)
        } else {
          cont.resume()
        }
      })
    }
  }

  private static func receive(_ connection: NWConnection) async throws -> Data {
    var buffer = Data()
    while buffer.count < 2_000_000 {
      let (chunk, done) = try await withCheckedThrowingContinuation {
        (cont: CheckedContinuation<(Data?, Bool), Error>) in
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) {
          data, _, isComplete, error in
          if let error {
            cont.resume(throwing: error)
          } else {
            cont.resume(returning: (data, isComplete))
          }
        }
      }
      if let chunk, !chunk.isEmpty { buffer.append(chunk) }
      if parse(buffer, connectionClosed: false) != nil || done { break }
    }
    return buffer
  }

  private static func parse(_ data: Data, connectionClosed: Bool) -> Result? {
    guard let split = data.range(of: Data("\r\n\r\n".utf8)),
          let head = String(data: data.subdata(in: 0..<split.lowerBound), encoding: .utf8)
    else { return nil }
    var body = data.subdata(in: split.upperBound..<data.count)
    let lines = head.split(separator: "\r\n", omittingEmptySubsequences: false)
    guard let statusLine = lines.first else { return nil }
    let parts = statusLine.split(separator: " ")
    guard parts.count >= 2, let status = Int(parts[1]) else { return nil }
    var headers: [String: String] = [:]
    for line in lines.dropFirst() {
      guard let colon = line.firstIndex(of: ":") else { continue }
      let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
      let value = line[line.index(after: colon)...]
        .trimmingCharacters(in: .whitespaces)
      headers[key] = value
    }
    if headers["transfer-encoding"]?.lowercased().contains("chunked") == true {
      guard let decoded = decodeChunks(body, connectionClosed: connectionClosed) else {
        return nil
      }
      body = decoded
    } else if let length = headers["content-length"].flatMap(Int.init) {
      if body.count < length && !connectionClosed { return nil }
      if body.count > length { body = body.prefix(length) }
    } else if !connectionClosed {
      return nil
    }
    return Result(status: status, body: body)
  }

  private static func decodeChunks(_ data: Data, connectionClosed: Bool) -> Data? {
    var out = Data()
    var rest = data
    let crlf = Data("\r\n".utf8)
    while true {
      guard let lineEnd = rest.range(of: crlf) else {
        return connectionClosed ? out : nil
      }
      let sizeLine = rest.subdata(in: 0..<lineEnd.lowerBound)
      guard let sizeText = String(data: sizeLine, encoding: .utf8)?
        .split(separator: ";").first,
            let size = Int(sizeText.trimmingCharacters(in: .whitespaces), radix: 16)
      else { return connectionClosed ? out : nil }
      rest.removeSubrange(0..<lineEnd.upperBound)
      if size == 0 { return out }
      if rest.count < size + 2 {
        return connectionClosed ? out : nil
      }
      out.append(rest.prefix(size))
      rest.removeSubrange(0..<(size + 2))
    }
  }

  private static func withThrowingTimeout<T>(
    seconds: TimeInterval,
    onTimeout: @escaping @Sendable () -> Void,
    _ operation: @escaping @Sendable () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        onTimeout()
        throw URLError(.timedOut)
      }
      guard let first = try await group.next() else {
        throw URLError(.unknown)
      }
      group.cancelAll()
      return first
    }
  }
}

private final class ConnectionBox: @unchecked Sendable {
  var connection: NWConnection?
  init(_ connection: NWConnection) { self.connection = connection }
}

private final class ResumeOnce: @unchecked Sendable {
  private let lock = NSLock()
  private var done = false
  func resume(_ body: () -> Void) {
    lock.lock()
    let first = !done
    if first { done = true }
    lock.unlock()
    if first { body() }
  }
}

enum LMMiniSiriNativeChat {
  /// Returns the model answer, or nil when the snapshot cannot serve this
  /// request (caller should fall through to Flutter). Throws when the server
  /// was reached but refused / timed out — do not double-submit via Dart.
  static func complete(
    system: String,
    user: String,
    timeout: TimeInterval = 22
  ) async throws -> String? {
    guard let snap = LMMiniSiriSnapshot.current, snap.eligible,
          let urlString = snap.chatUrl, let url = URL(string: urlString),
          let model = snap.model, !model.isEmpty
    else { return nil }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = timeout
    for (k, v) in snap.headers {
      request.setValue(v, forHTTPHeaderField: k)
    }
    if request.value(forHTTPHeaderField: "Content-Type") == nil {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    let body: [String: Any] = [
      "model": model,
      "messages": [
        ["role": "system", "content": system],
        ["role": "user", "content": user],
      ],
      "temperature": snap.temperature,
      "max_tokens": snap.maxTokens,
      "stream": false,
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let data: Data
    let status: Int
    do {
      // Shortcuts runs this intent in the background. URLSession there still
      // enforces ATS, so http:// to LM Studio dies before Speak gets a reply.
      // Plain TCP is not subject to that policy.
      if url.scheme?.lowercased() == "http" {
        let result = try await LMMiniPlainHTTP.post(
          url: url,
          headers: snap.headers,
          body: request.httpBody ?? Data(),
          timeout: timeout)
        data = result.body
        status = result.status
      } else {
        let (bytes, response) = try await URLSession.shared.data(for: request)
        data = bytes
        status = (response as? HTTPURLResponse)?.statusCode ?? 0
      }
    } catch {
      let ns = error as NSError
      if ns.domain == NSURLErrorDomain &&
          (ns.code == NSURLErrorTimedOut ||
           ns.code == NSURLErrorCannotConnectToHost ||
           ns.code == NSURLErrorNetworkConnectionLost ||
           ns.code == NSURLErrorNotConnectedToInternet ||
           ns.code == NSURLErrorCannotFindHost ||
           ns.code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
        return nil
      }
      throw LMMiniSiriFailure(ns.localizedDescription)
    }

    let raw = String(data: data, encoding: .utf8) ?? ""
    if status == 200 {
      if let answer = parseOpenAIContent(data) {
        return answer
      }
      throw LMMiniSiriFailure("The model returned an empty reply.")
    }
    if let server = parseErrorMessage(data) {
      throw LMMiniSiriFailure(server)
    }
    throw LMMiniSiriFailure("The model server returned HTTP \(status). \(raw.prefix(180))")
  }

  /// Streams an OpenAI-style completion. Returns nil when the snapshot cannot
  /// serve the request. Throws when the server was reached but failed.
  /// `onDelta` receives short chunks, not single tokens.
  static func stream(
    system: String,
    user: String,
    timeout: TimeInterval = 45,
    maxTokensCap: Int = 256,
    onDelta: @escaping (String) -> Void
  ) async throws -> String? {
    guard let snap = LMMiniSiriSnapshot.current, snap.eligible,
          let urlString = snap.chatUrl, let url = URL(string: urlString),
          let model = snap.model, !model.isEmpty
    else { return nil }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = timeout
    for (k, v) in snap.headers {
      request.setValue(v, forHTTPHeaderField: k)
    }
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

    let maxTokens = min(max(snap.maxTokens, 16), maxTokensCap)
    let body: [String: Any] = [
      "model": model,
      "messages": [
        ["role": "system", "content": system],
        ["role": "user", "content": user],
      ],
      "temperature": snap.temperature,
      "max_tokens": maxTokens,
      "stream": true,
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (bytes, response): (URLSession.AsyncBytes, URLResponse)
    do {
      (bytes, response) = try await URLSession.shared.bytes(for: request)
    } catch {
      let ns = error as NSError
      if ns.domain == NSURLErrorDomain &&
          (ns.code == NSURLErrorTimedOut ||
           ns.code == NSURLErrorCannotConnectToHost ||
           ns.code == NSURLErrorNetworkConnectionLost ||
           ns.code == NSURLErrorNotConnectedToInternet ||
           ns.code == NSURLErrorCannotFindHost) {
        return nil
      }
      throw LMMiniSiriFailure(ns.localizedDescription)
    }

    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    if status != 200 {
      var data = Data()
      for try await byte in bytes {
        data.append(byte)
        if data.count >= 2000 { break }
      }
      if let server = parseErrorMessage(data) {
        throw LMMiniSiriFailure(server)
      }
      let raw = String(data: data, encoding: .utf8) ?? ""
      throw LMMiniSiriFailure("The model server returned HTTP \(status). \(raw.prefix(180))")
    }

    var full = ""
    var pending = ""
    var raw = ""
    var sawEvent = false
    func emit(_ piece: String) {
      guard !piece.isEmpty else { return }
      full += piece
      pending += piece
      if pending.count >= 32 {
        let chunk = pending
        pending = ""
        onDelta(chunk)
      }
    }

    do {
      for try await line in bytes.lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { continue }
        if trimmed.hasPrefix("data:") {
          sawEvent = true
          let payload = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
          if payload == "[DONE]" { break }
          if let piece = deltaText(String(payload)) {
            emit(piece)
          }
          continue
        }
        if !sawEvent {
          raw += line
          raw += "\n"
        }
      }
    } catch {
      if full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain { return nil }
        throw LMMiniSiriFailure(ns.localizedDescription)
      }
    }

    if !sawEvent, let data = raw.data(using: .utf8), let answer = parseOpenAIContent(data) {
      emit(answer)
    }
    if !pending.isEmpty {
      onDelta(pending)
    }
    let trimmed = full.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      throw LMMiniSiriFailure("The model returned an empty reply.")
    }
    return trimmed
  }

  private static func deltaText(_ payload: String) -> String? {
    guard let data = payload.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let choices = obj["choices"] as? [[String: Any]],
          let first = choices.first
    else { return nil }
    if let delta = first["delta"] as? [String: Any] {
      if let content = delta["content"] as? String, !content.isEmpty { return content }
      if let text = delta["text"] as? String, !text.isEmpty { return text }
    }
    if let message = first["message"] as? [String: Any],
       let content = message["content"] as? String, !content.isEmpty {
      return content
    }
    return nil
  }

  private static func parseOpenAIContent(_ data: Data) -> String? {
    guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }
    if let choices = obj["choices"] as? [[String: Any]],
       let first = choices.first,
       let message = first["message"] as? [String: Any] {
      if let content = message["content"] as? String, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
    if let content = obj["content"] as? String,
       !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return nil
  }

  private static func parseErrorMessage(_ data: Data) -> String? {
    guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }
    if let err = obj["error"] as? [String: Any], let msg = err["message"] as? String {
      return msg
    }
    if let err = obj["error"] as? String { return err }
    if let msg = obj["message"] as? String { return msg }
    return nil
  }
}

struct LMMiniSiriFailure: Error, CustomLocalizedStringResourceConvertible {
  let message: String
  init(_ message: String) { self.message = message }
  var localizedStringResource: LocalizedStringResource {
    LocalizedStringResource(stringLiteral: message)
  }
}

enum LMMiniSiriDialog {
  static func make(_ answer: String) -> IntentDialog {
    let spoken = String(answer.prefix(1500))
    if #available(iOS 26.0, *) {
      return dialogIOS26(full: spoken, supporting: String(answer.prefix(280)))
    }
    return IntentDialog(loc(spoken))
  }

  static func failure(_ message: String) -> IntentDialog {
    if #available(iOS 26.0, *) {
      return dialogIOS26(full: message, supporting: "LM Mini")
    }
    return IntentDialog(loc(message))
  }

  @available(iOS 26.0, *)
  private static func dialogIOS26(full: String, supporting: String) -> IntentDialog {
    IntentDialog(full: loc(full), supporting: loc(supporting))
  }

  private static func loc(_ text: String) -> LocalizedStringResource {
    LocalizedStringResource(stringLiteral: text)
  }
}

enum LMMiniSiriRun {
  static let dartTimeout: TimeInterval = 90

  static func execute(
    path: String,
    query: [String: String],
    nativeSystem: String?,
    nativeUser: String?,
    allowNative: Bool,
    requestForeground: () async throws -> Void
  ) async throws -> String {
    if let existing = LMMiniSiriStore.defaults?.string(forKey: LMMiniSiriStore.activeWaitIdKey),
       !existing.isEmpty {
      return try await waitForDart(waitId: existing)
    }

    if allowNative, let system = nativeSystem, let user = nativeUser {
      if let answer = try await LMMiniSiriNativeChat.complete(system: system, user: user) {
        return answer
      }
    }

    let waitId = UUID().uuidString
    LMMiniSiriStore.defaults?.set(waitId, forKey: LMMiniSiriStore.activeWaitIdKey)
    var queued = query
    queued["waitId"] = waitId
    LMMiniSiriStore.queueShortcut(path: path, query: queued)

    do {
      try await requestForeground()
    } catch {
      // `needsToContinueInForegroundError` must propagate so iOS re-invokes
      // `perform()` after the app is open. Other errors (foreground denied)
      // still wait — Dart may already be generating.
      let typeName = String(describing: type(of: error))
      if typeName.contains("NeedsToContinueInForeground") {
        throw error
      }
    }

    return try await waitForDart(waitId: waitId)
  }

  private static func waitForDart(waitId: String) async throws -> String {
    let deadline = Date().addingTimeInterval(dartTimeout)
    while Date() < deadline {
      let taken = LMMiniSiriStore.peekResult(waitId: waitId)
      if let text = taken.text {
        LMMiniSiriStore.clearResult(waitId: waitId)
        LMMiniSiriStore.defaults?.removeObject(forKey: LMMiniSiriStore.activeWaitIdKey)
        if text.isEmpty {
          throw LMMiniSiriFailure("The model returned an empty reply.")
        }
        return text
      }
      if let error = taken.error, !error.isEmpty {
        LMMiniSiriStore.clearResult(waitId: waitId)
        LMMiniSiriStore.defaults?.removeObject(forKey: LMMiniSiriStore.activeWaitIdKey)
        throw LMMiniSiriFailure(error)
      }
      try await Task.sleep(nanoseconds: 200_000_000)
    }
    LMMiniSiriStore.defaults?.removeObject(forKey: LMMiniSiriStore.activeWaitIdKey)
    throw LMMiniSiriFailure("LM Mini took too long to answer. Try a shorter question, or open the app and ask there.")
  }
}

enum LMMiniSiriChannel {
  static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "syncSnapshot":
      if let map = call.arguments as? [String: Any] {
        LMMiniSiriStore.writeSnapshot(map)
        result(true)
      } else {
        result(false)
      }
    case "complete":
      guard let args = call.arguments as? [String: Any],
            let waitId = args["waitId"] as? String,
            let text = args["text"] as? String
      else {
        result(false)
        return
      }
      LMMiniSiriStore.complete(waitId: waitId, text: text)
      result(true)
    case "fail":
      guard let args = call.arguments as? [String: Any],
            let waitId = args["waitId"] as? String,
            let error = args["error"] as? String
      else {
        result(false)
        return
      }
      LMMiniSiriStore.fail(waitId: waitId, error: error)
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
