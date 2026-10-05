import Combine
import Foundation
import WatchConnectivity

struct WatchChat: Identifiable, Hashable {
  let id: String
  let title: String
  let preview: String
  let folderId: String?
  let group: Bool
  let branch: Bool
  let avatar: Data?
  let avatar2: Data?
  let color: Int?
  let updatedMs: Int
}

struct WatchLine: Identifiable {
  let id: String
  let role: String
  let text: String
  let hasImage: Bool
  var attachment: Data? = nil
  var imagePrompt: String = ""
  var thinking: String = ""
}

struct WatchFolder: Identifiable, Hashable {
  let id: String
  let name: String
  let count: Int
}

struct WatchPersona: Identifiable, Hashable {
  let id: String
  let name: String
  let prompt: String
  let model: String
  let provider: String
  let modelPinned: Bool
  let providerPinned: Bool
  let avatar: Data?
  let color: Int?

  static let empty = WatchPersona(
    id: "",
    name: "",
    prompt: "",
    model: "",
    provider: "",
    modelPinned: false,
    providerPinned: false,
    avatar: nil,
    color: nil
  )
}

enum WatchRoute: Hashable {
  case newChat
  case chat(String)
  case folder(String)
}

final class WatchLink: NSObject, ObservableObject, WCSessionDelegate {
  static let shared = WatchLink()

  @Published var status = "Starting…"
  @Published var model: String?
  @Published var busy = false
  @Published var chats: [WatchChat] = []
  @Published var personas: [WatchPersona] = []
  @Published var folders: [WatchFolder] = []
  @Published var personaId = ""
  @Published var personaName = ""
  @Published var personaPrompt = ""
  @Published var personaModel = ""
  @Published var personaProvider = ""
  @Published var personaModelPinned = false
  @Published var personaProviderPinned = false
  @Published var messages: [WatchLine] = []
  @Published var reply = ""
  @Published var replyThinking = ""
  @Published var threadTitle = "New chat"
  @Published var conversationId: String?
  @Published var fullWidth = false
  /// Phone setting. Off removes the persona row, including the local show button.
  @Published var showPersonas = true
  @Published var wallpaper: Data?
  @Published var avatar: Data?
  @Published var avatarColor: Int?
  @Published var wallpaperDim = 0.15
  @Published var imageGen = false
  @Published var groupChat = false
  /// Phone capability. False in builds without branching (the open-source build).
  @Published var canBranch = true
  @Published var imageBusy = false
  @Published var imageState = ""
  @Published var imageStatus = ""
  @Published var imagePreview: Data?

  private var requestId: String?
  private var imageRequestId: String?
  private var imagePrompt = ""
  private var listToken = 0
  private var outbox: [[String: Any]] = []
  private var sending = false
  private var homeWallpaper: Data?
  private var homeAvatar: Data?
  private var homeColor: Int?
  private var homeFullWidth = false
  private var homeDim = 0.15
  private var homePersona = WatchPersona.empty
  private(set) var pendingPersonaId: String?
  private var didLoadSnapshot = false
  /// The phone has not yet returned the new conversation id for Branch.
  private var pendingBranch = false

  func start() {
    if !didLoadSnapshot {
      didLoadSnapshot = true
      WatchSnapshot.load(into: self)
    }
    guard WCSession.isSupported() else {
      status = "This watch cannot reach an iPhone."
      return
    }
    let session = WCSession.default
    if session.delegate == nil || session.activationState == .notActivated {
      session.delegate = self
      session.activate()
    } else {
      session.delegate = self
    }
  }

  /// Move [id] to the top of the chat list. The phone's database order
  /// matches this after the next launch; the watch keeps its own copy.
  private func promote(_ id: String, preview: String? = nil) {
    guard let index = chats.firstIndex(where: { $0.id == id }) else { return }
    let current = chats.remove(at: index)
    let nextPreview = preview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let chat = WatchChat(
      id: current.id,
      title: current.title,
      preview: nextPreview.isEmpty ? current.preview : String(nextPreview.prefix(80)),
      folderId: current.folderId,
      group: current.group,
      branch: current.branch,
      avatar: current.avatar,
      avatar2: current.avatar2,
      color: current.color,
      updatedMs: Int(Date().timeIntervalSince1970 * 1000)
    )
    chats.insert(chat, at: 0)
    WatchSnapshot.saveChats(chats)
  }

  private static func oneLine(_ text: String) -> String {
    text
      .replacingOccurrences(of: "\n", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func refreshChats() {
    guard ready() else { return }
    listToken += 1
    let token = listToken
    if chats.isEmpty { status = "Loading chats…" }
    post(["name": "listChats"])
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
      guard self.listToken == token, self.status == "Loading chats…" else { return }
      self.status = "Open LM Mini on the iPhone, then try again."
    }
  }

  func beginNewChat() {
    conversationId = nil
    pendingPersonaId = nil
    messages = []
    reply = ""
    threadTitle = "New chat"
    wallpaper = homeWallpaper
    avatar = homeAvatar
    avatarColor = homeColor
    fullWidth = homeFullWidth
    wallpaperDim = homeDim
    apply(homePersona)
    if !busy { status = "iPhone nearby." }
  }

  func beginPersona(_ persona: WatchPersona) {
    conversationId = nil
    pendingPersonaId = persona.id
    messages = []
    reply = ""
    threadTitle = persona.name.isEmpty ? "New chat" : persona.name
    wallpaper = homeWallpaper
    fullWidth = homeFullWidth
    wallpaperDim = homeDim
    avatar = persona.avatar ?? homeAvatar
    avatarColor = persona.color ?? homeColor
    apply(persona)
    if !busy { status = "iPhone nearby." }
    guard ready() else { return }
    post(["name": "persona", "personaId": persona.id])
  }

  func openChat(_ chat: WatchChat) {
    conversationId = chat.id
    threadTitle = chat.title
    reply = ""
    replyThinking = ""
    if let saved = WatchSnapshot.thread(chat.id), !saved.isEmpty {
      messages = saved
      status = ready() ? "iPhone nearby." : "Saved on this watch."
    } else {
      messages = []
      status = "Loading…"
    }
    post(["name": "openChat", "conversationId": chat.id])
  }

  func send(_ raw: String, image: Data? = nil) {
    let text = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(800))
    guard !text.isEmpty || image != nil, !busy else { return }
    guard ready() else { return }
    let id = UUID().uuidString
    requestId = id
    messages.append(
      WatchLine(id: id, role: "user", text: text, hasImage: image != nil, attachment: image)
    )
    if conversationId == nil, pendingPersonaId == nil {
      threadTitle = text.isEmpty ? "Photo" : String(text.prefix(32))
    }
    reply = ""
    busy = true
    status = "Asking…"
    var body: [String: Any] = ["name": "send", "text": text, "requestId": id]
    if let image {
      body["image"] = image.base64EncodedString()
    }
    if let conversationId, !conversationId.isEmpty {
      body["conversationId"] = conversationId
    } else if let pendingPersonaId, !pendingPersonaId.isEmpty {
      body["personaId"] = pendingPersonaId
    }
    post(body)
  }

  func regenerate(_ messageId: String) {
    guard !busy else { return }
    guard ready() else { return }
    if let index = messages.lastIndex(where: { $0.role != "user" && !$0.text.isEmpty }) {
      messages.remove(at: index)
    }
    let id = UUID().uuidString
    requestId = id
    reply = ""
    busy = true
    status = "Regenerating…"
    var body: [String: Any] = ["name": "regenerate", "requestId": id, "messageId": messageId]
    if let conversationId, !conversationId.isEmpty {
      body["conversationId"] = conversationId
    }
    post(body)
  }

  func edit(_ messageId: String, _ raw: String) {
    let text = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(800))
    guard !text.isEmpty, !busy else { return }
    guard ready() else { return }
    if let index = messages.firstIndex(where: { $0.id == messageId }) {
      let line = messages[index]
      messages[index] = WatchLine(
        id: line.id,
        role: line.role,
        text: text,
        hasImage: line.hasImage,
        attachment: line.attachment,
        imagePrompt: line.imagePrompt
      )
      if index + 1 < messages.count {
        messages.removeSubrange((index + 1)...)
      }
    }
    let id = UUID().uuidString
    requestId = id
    reply = ""
    busy = true
    status = "Asking…"
    var body: [String: Any] = [
      "name": "edit",
      "requestId": id,
      "messageId": messageId,
      "text": text,
    ]
    if let conversationId, !conversationId.isEmpty {
      body["conversationId"] = conversationId
    }
    post(body)
  }

  func branch(_ messageId: String) {
    guard !busy else { return }
    guard ready() else { return }
    let id = UUID().uuidString
    requestId = id
    pendingBranch = true
    busy = true
    status = "Branching…"
    var body: [String: Any] = ["name": "branch", "requestId": id, "messageId": messageId]
    if let conversationId, !conversationId.isEmpty {
      body["conversationId"] = conversationId
    }
    post(body)
  }

  func delete(_ messageId: String) {
    guard !busy else { return }
    guard ready() else { return }
    let id = UUID().uuidString
    requestId = id
    var body: [String: Any] = ["name": "delete", "requestId": id, "messageId": messageId]
    if let conversationId, !conversationId.isEmpty {
      body["conversationId"] = conversationId
    }
    post(body)
  }

  func copyToPhone(_ raw: String) {
    let text = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(3500))
    guard !text.isEmpty else { return }
    guard ready() else { return }
    status = "Copied to the iPhone."
    post(["name": "copy", "text": text])
  }

  func imagine(_ raw: String) {
    let text = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(800))
    guard !text.isEmpty, !imageBusy else { return }
    guard ready() else {
      imageState = "failed"
      imageStatus = status
      return
    }
    let id = UUID().uuidString
    imageRequestId = id
    imagePrompt = text
    imagePreview = nil
    imageBusy = true
    imageState = "starting"
    imageStatus = "Starting…"
    var body: [String: Any] = ["name": "imagine", "prompt": text, "requestId": id]
    if let conversationId, !conversationId.isEmpty {
      body["conversationId"] = conversationId
    }
    post(body)
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any]
  ) {
    DispatchQueue.main.async {
      self.apply(message)
    }
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    DispatchQueue.main.async {
      if let error {
        self.status = error.localizedDescription
        return
      }
      if activationState == .activated {
        self.status = session.isReachable ? "iPhone nearby." : "Waiting for the iPhone."
        if session.isReachable { self.refreshChats() }
      } else {
        self.status = "Not connected."
      }
    }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async {
      guard session.activationState == .activated else { return }
      if session.isReachable {
        if self.chats.isEmpty { self.refreshChats() }
        else if self.status == "Waiting for the iPhone."
          || self.status == "Starting…"
          || self.status == "Still connecting to the iPhone."
        {
          self.status = "iPhone nearby."
        }
      } else if self.status == "iPhone nearby." || self.status == "Loading chats…" {
        self.status = "Waiting for the iPhone."
      }
    }
  }

  private func apply(_ message: [String: Any]) {
    let name = message["name"] as? String
    let incoming = message["requestId"] as? String
    if name == "imagineStatus" || name == "imaginePreview" {
      if let incoming, incoming != imageRequestId { return }
    } else if name == "removed" {
      if let incoming, incoming != requestId { return }
    } else if let incoming, incoming != requestId,
              name != "chats", name != "messages", name != "look" {
      return
    }
    switch name {
    case "chats":
      listToken += 1
      if let error = message["error"] as? String, !error.isEmpty {
        status = error
        return
      }
      let faces = Self.faceMap(message["faces"])
      chats = Self.chats(from: message["items"], faces: faces)
      personas = Self.personas(from: message["personas"], faces: faces)
      folders = Self.folders(from: message["folders"])
      applyLook(message, home: true)
      WatchSnapshot.saveChats(chats)
      status = chats.isEmpty ? "No chats yet." : "iPhone nearby."
    case "messages":
      let cid = message["conversationId"] as? String
      if cid != conversationId {
        if pendingBranch, let cid, !cid.isEmpty {
          conversationId = cid
          pendingBranch = false
        } else {
          return
        }
      }
      if let error = message["error"] as? String, !error.isEmpty {
        status = error
        return
      }
      messages = Self.lines(from: message["items"])
      if let title = (message["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
         !title.isEmpty {
        threadTitle = title
      }
      if let cid {
        WatchSnapshot.saveThread(cid, messages)
        promote(cid)
      }
      applyLook(message, home: false)
      status = "iPhone nearby."
    case "opened":
      if let cid = message["conversationId"] as? String, !cid.isEmpty {
        conversationId = cid
        promote(cid)
      }
      let branched = message["branch"] as? Bool == true
        || (message["branch"] as? NSNumber)?.boolValue == true
      if branched {
        let cid = conversationId
        let alreadyLoaded = !pendingBranch && cid != nil && !messages.isEmpty
        pendingBranch = false
        busy = false
        if !alreadyLoaded {
          messages = []
          reply = ""
          replyThinking = ""
          status = "Loading…"
        }
        refreshChats()
      }
    case "delta":
      if let thinking = message["thinking"] as? String {
        replyThinking = thinking
      }
      let chunk = message["text"] as? String ?? ""
      if chunk.isEmpty {
        if !replyThinking.isEmpty { status = "Answering…" }
        return
      }
      if message["replace"] as? Bool == true {
        reply = chunk
      } else {
        reply += chunk
      }
      status = "Answering…"
    case "done":
      busy = false
      if let cid = message["conversationId"] as? String, !cid.isEmpty {
        conversationId = cid
        if threadTitle == "New chat" { threadTitle = "Chat" }
      }
      if let error = message["error"] as? String, !error.isEmpty {
        pendingBranch = false
        status = error
        reply = ""
        replyThinking = ""
        return
      }
      let savedUser = (message["userMessageId"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let localUserId = (message["requestId"] as? String) ?? requestId
      if !savedUser.isEmpty,
         let index = messages.firstIndex(where: { $0.id == localUserId && $0.role == "user" }) {
        let line = messages[index]
        messages[index] = WatchLine(
          id: savedUser,
          role: line.role,
          text: line.text,
          hasImage: line.hasImage,
          attachment: line.attachment,
          imagePrompt: line.imagePrompt,
          thinking: line.thinking
        )
      }
      let full = (message["fullText"] as? String) ?? reply
      let thought = (message["thinking"] as? String) ?? replyThinking
      if !full.isEmpty || !thought.isEmpty {
        let savedId = (message["messageId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        messages.append(
          WatchLine(
            id: savedId.isEmpty ? UUID().uuidString : savedId,
            role: "assistant",
            text: full,
            hasImage: false,
            imagePrompt: message["imagePrompt"] as? String ?? "",
            thinking: thought
          )
        )
      }
      reply = ""
      replyThinking = ""
      if let cid = conversationId {
        if chats.contains(where: { $0.id == cid }) {
          promote(cid, preview: Self.oneLine(full))
        } else {
          refreshChats()
        }
        WatchSnapshot.saveThread(cid, messages)
      }
      status = "iPhone replied."
    case "imagineStatus":
      let state = message["state"] as? String ?? ""
      imageState = state
      switch state {
      case "starting":
        imageBusy = true
        imageStatus = "Starting…"
      case "generating":
        imageBusy = true
        imageStatus = "Generating…"
      case "ready":
        imageBusy = false
        imageStatus = "Ready"
        if let cid = message["conversationId"] as? String, !cid.isEmpty {
          conversationId = cid
        }
      case "failed":
        imageBusy = false
        let error = (message["error"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        imageStatus = error.isEmpty ? "Image generation failed." : error
      default:
        break
      }
    case "imaginePreview":
      imagePreview = Self.imageData(message["preview"])
      if let cid = message["conversationId"] as? String, !cid.isEmpty {
        conversationId = cid
      }
      let prompt = imagePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
      messages.append(
        WatchLine(
          id: UUID().uuidString,
          role: "assistant",
          text: "",
          hasImage: true,
          imagePrompt: prompt
        )
      )
      imagePrompt = ""
      imageBusy = false
      imageState = "ready"
      imageStatus = "Ready"
    case "personaReady":
      pendingPersonaId = nil
      if let error = message["error"] as? String, !error.isEmpty {
        status = error
        return
      }
      if let cid = message["conversationId"] as? String, !cid.isEmpty {
        conversationId = cid
      }
      applyLook(message, home: false)
      if !personaName.isEmpty { threadTitle = personaName }
      status = "iPhone nearby."
    case "look":
      applyWatchPrefs(message)
    case "removed":
      let messageId = message["messageId"] as? String ?? ""
      if !messageId.isEmpty {
        messages.removeAll { $0.id == messageId }
      }
      status = "iPhone nearby."
    default:
      break
    }
  }

  private func applyLook(_ message: [String: Any], home: Bool) {
    var nextFull = fullWidth
    var nextDim = wallpaperDim
    var nextWall = wallpaper
    var nextAvatar = avatar
    var nextColor = avatarColor
    if let flag = message["fullWidth"] as? Bool {
      nextFull = flag
    } else if let flag = message["fullWidth"] as? NSNumber {
      nextFull = flag.boolValue
    }
    if let dim = message["dim"] as? NSNumber {
      nextDim = min(1, max(0, dim.doubleValue / 100))
    }
    if message["wallpaper"] != nil {
      nextWall = Self.imageData(message["wallpaper"])
    }
    if message["avatar"] != nil {
      nextAvatar = Self.imageData(message["avatar"])
      if nextAvatar == nil { nextColor = nil }
    }
    if let color = message["color"] as? NSNumber {
      nextColor = color.intValue
    }
    if message["watchPersonas"] != nil {
      showPersonas = Self.flag(message["watchPersonas"])
    }
    if let flag = message["imageGen"] as? Bool {
      imageGen = flag
    } else if let flag = message["imageGen"] as? NSNumber {
      imageGen = flag.boolValue
    }
    if let flag = message["group"] as? Bool {
      groupChat = flag
    } else if let flag = message["group"] as? NSNumber {
      groupChat = flag.boolValue
    }
    if let flag = message["canBranch"] as? Bool {
      canBranch = flag
    } else if let flag = message["canBranch"] as? NSNumber {
      canBranch = flag.boolValue
    }
    let nextPersona = WatchPersona(
      id: message["personaId"] as? String ?? "",
      name: message["personaName"] as? String ?? "",
      prompt: message["prompt"] as? String ?? "",
      model: message["model"] as? String ?? "",
      provider: message["provider"] as? String ?? "",
      modelPinned: Self.flag(message["modelPinned"]),
      providerPinned: Self.flag(message["providerPinned"]),
      avatar: nextAvatar,
      color: nextColor
    )
    if home {
      homeWallpaper = nextWall
      homeAvatar = nextAvatar
      homeColor = nextColor
      homeFullWidth = nextFull
      homeDim = nextDim
      homePersona = nextPersona
      fullWidth = nextFull
      guard conversationId == nil, pendingPersonaId == nil else { return }
    }
    fullWidth = nextFull
    wallpaperDim = nextDim
    wallpaper = nextWall
    avatar = nextAvatar
    avatarColor = nextColor
    apply(nextPersona)
  }

  /// Live toggles from the iPhone. Leaves wallpaper and the open persona alone.
  private func applyWatchPrefs(_ message: [String: Any]) {
    if message["watchPersonas"] != nil {
      showPersonas = Self.flag(message["watchPersonas"])
    }
    var nextFull: Bool?
    if let flag = message["fullWidth"] as? Bool {
      nextFull = flag
    } else if let flag = message["fullWidth"] as? NSNumber {
      nextFull = flag.boolValue
    }
    if let nextFull {
      fullWidth = nextFull
      homeFullWidth = nextFull
    }
  }

  private func apply(_ persona: WatchPersona) {
    personaId = persona.id
    personaName = persona.name
    personaPrompt = persona.prompt
    personaModel = persona.model
    personaProvider = persona.provider
    personaModelPinned = persona.modelPinned
    personaProviderPinned = persona.providerPinned
  }

  private static func flag(_ value: Any?) -> Bool {
    if let flag = value as? Bool { return flag }
    if let flag = value as? NSNumber { return flag.boolValue }
    return false
  }

  private static func imageData(_ value: Any?) -> Data? {
    guard let text = value as? String, !text.isEmpty,
          let data = Data(base64Encoded: text), !data.isEmpty
    else { return nil }
    return data
  }

  private func ready() -> Bool {
    let session = WCSession.default
    guard session.activationState == .activated else {
      status = "Still connecting to the iPhone."
      return false
    }
    guard session.isReachable else {
      status = "Open LM Mini on the iPhone, then try again."
      return false
    }
    return true
  }

  private func post(_ body: [String: Any]) {
    outbox.append(body)
    pump()
  }

  private func pump() {
    guard !sending, !outbox.isEmpty else { return }
    let body = outbox.removeFirst()
    let session = WCSession.default
    guard session.activationState == .activated, session.isReachable else {
      sending = false
      status = "Open LM Mini on the iPhone, then try again."
      busy = false
      return
    }
    sending = true
    let isImage = (body["name"] as? String) == "imagine"
    session.sendMessage(body, replyHandler: { reply in
      DispatchQueue.main.async {
        self.sending = false
        if let error = reply["error"] as? String, !error.isEmpty {
          if isImage {
            self.imageBusy = false
            self.imageState = "failed"
            self.imageStatus = error
          } else {
            self.busy = false
            self.status = error
          }
        }
        let model = (reply["model"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !model.isEmpty { self.model = model }
        self.pump()
      }
    }, errorHandler: { error in
      DispatchQueue.main.async {
        self.sending = false
        if isImage {
          self.imageBusy = false
          self.imageState = "failed"
          self.imageStatus = error.localizedDescription
        } else {
          self.busy = false
          self.status = error.localizedDescription
        }
        self.pump()
      }
    })
  }

  private static func faceMap(_ raw: Any?) -> [String: String] {
    guard let raw = raw as? [String: Any] else { return [:] }
    var faces: [String: String] = [:]
    for (key, value) in raw {
      if let text = value as? String, !text.isEmpty { faces[key] = text }
    }
    return faces
  }

  private static func face(_ value: Any?, faces: [String: String]) -> Data? {
    guard let key = value as? String, !key.isEmpty else { return nil }
    if let encoded = faces[key] { return imageData(encoded) }
    if faces.isEmpty { return imageData(key) }
    return nil
  }

  private static func chats(from raw: Any?, faces: [String: String] = [:]) -> [WatchChat] {
    let items = raw as? [[String: Any]] ?? (raw as? [Any])?.compactMap { $0 as? [String: Any] } ?? []
    return items.compactMap { item in
      let id = item["id"] as? String ?? ""
      guard !id.isEmpty else { return nil }
      let title = (item["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let preview = (item["preview"] as? String) ?? ""
      let folderId = (item["folderId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let group = (item["group"] as? Bool)
        ?? (item["group"] as? NSNumber)?.boolValue
        ?? false
      let color = (item["color"] as? NSNumber)?.intValue
      return WatchChat(
        id: id,
        title: (title?.isEmpty == false) ? title! : "New Chat",
        preview: preview,
        folderId: (folderId?.isEmpty == false) ? folderId : nil,
        group: group,
        branch: flag(item["branch"]),
        avatar: Self.face(item["avatar"], faces: faces),
        avatar2: Self.face(item["avatar2"], faces: faces),
        color: color,
        updatedMs: (item["updated"] as? NSNumber)?.intValue ?? 0
      )
    }
  }

  private static func personas(from raw: Any?, faces: [String: String]) -> [WatchPersona] {
    let items = raw as? [[String: Any]] ?? (raw as? [Any])?.compactMap { $0 as? [String: Any] } ?? []
    return items.compactMap { item in
      let id = (item["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !id.isEmpty else { return nil }
      let name = (item["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      return WatchPersona(
        id: id,
        name: name.isEmpty ? "Persona" : name,
        prompt: item["prompt"] as? String ?? "",
        model: item["model"] as? String ?? "",
        provider: item["provider"] as? String ?? "",
        modelPinned: flag(item["modelPinned"]),
        providerPinned: flag(item["providerPinned"]),
        avatar: face(item["avatar"], faces: faces),
        color: (item["color"] as? NSNumber)?.intValue
      )
    }
  }

  private static func folders(from raw: Any?) -> [WatchFolder] {
    let items = raw as? [[String: Any]] ?? (raw as? [Any])?.compactMap { $0 as? [String: Any] } ?? []
    return items.compactMap { item in
      let id = item["id"] as? String ?? ""
      guard !id.isEmpty else { return nil }
      let name = (item["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let count = (item["count"] as? NSNumber)?.intValue ?? (item["count"] as? Int) ?? 0
      return WatchFolder(
        id: id,
        name: (name?.isEmpty == false) ? name! : "Folder",
        count: count
      )
    }
  }

  private static func lines(from raw: Any?) -> [WatchLine] {
    let items = raw as? [[String: Any]] ?? (raw as? [Any])?.compactMap { $0 as? [String: Any] } ?? []
    return items.map { item in
      let serverId = (item["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      return WatchLine(
        id: serverId.isEmpty ? UUID().uuidString : serverId,
        role: item["role"] as? String ?? "assistant",
        text: item["text"] as? String ?? "",
        hasImage: item["hasImage"] as? Bool ?? false,
        attachment: imageData(item["image"]),
        imagePrompt: item["imagePrompt"] as? String ?? "",
        thinking: item["thinking"] as? String ?? ""
      )
    }
  }
}

/// Recent chats and the last few messages, so opening a thread does not
/// wait on the iPhone. Pictures in a thread come back with the refresh.
private enum WatchSnapshot {
  private static let key = "watch.snapshot.v1"
  private static let threadLimit = 8
  private static let lineLimit = 12

  private struct Store: Codable {
    var chats: [Chat] = []
    var order: [String] = []
    var threads: [String: [Line]] = [:]
  }

  private struct Chat: Codable {
    var id: String
    var title: String
    var preview: String
    var folderId: String?
    var group: Bool
    var branch: Bool
    var avatar: Data?
    var avatar2: Data?
    var color: Int?
    var updatedMs: Int
  }

  private struct Line: Codable {
    var id: String
    var role: String
    var text: String
    var hasImage: Bool
    var imagePrompt: String
    var thinking: String
  }

  static func load(into link: WatchLink) {
    guard let data = UserDefaults.standard.data(forKey: key),
          let store = try? JSONDecoder().decode(Store.self, from: data)
    else { return }
    if link.chats.isEmpty {
      link.chats = store.chats.map { chat in
        WatchChat(
          id: chat.id,
          title: chat.title,
          preview: chat.preview,
          folderId: chat.folderId,
          group: chat.group,
          branch: chat.branch,
          avatar: chat.avatar,
          avatar2: chat.avatar2,
          color: chat.color,
          updatedMs: chat.updatedMs
        )
      }
    }
    if link.chats.isEmpty {
      link.status = "Open LM Mini on the iPhone, then try again."
    } else if link.status == "Starting…" {
      link.status = "Saved on this watch."
    }
  }

  static func thread(_ id: String) -> [WatchLine]? {
    guard let data = UserDefaults.standard.data(forKey: key),
          let store = try? JSONDecoder().decode(Store.self, from: data),
          let lines = store.threads[id]
    else { return nil }
    return lines.map { line in
      WatchLine(
        id: line.id,
        role: line.role,
        text: line.text,
        hasImage: line.hasImage,
        imagePrompt: line.imagePrompt,
        thinking: line.thinking
      )
    }
  }

  static func saveChats(_ chats: [WatchChat]) {
    var store = read()
    store.chats = chats.map { chat in
      Chat(
        id: chat.id,
        title: chat.title,
        preview: chat.preview,
        folderId: chat.folderId,
        group: chat.group,
        branch: chat.branch,
        avatar: chat.avatar,
        avatar2: chat.avatar2,
        color: chat.color,
        updatedMs: chat.updatedMs
      )
    }
    write(store)
  }

  static func saveThread(_ id: String, _ messages: [WatchLine]) {
    guard !id.isEmpty else { return }
    var store = read()
    let tail = messages.suffix(lineLimit)
    store.threads[id] = tail.map { line in
      Line(
        id: line.id,
        role: line.role,
        text: line.text,
        hasImage: line.hasImage,
        imagePrompt: line.imagePrompt,
        thinking: line.thinking
      )
    }
    store.order.removeAll { $0 == id }
    store.order.insert(id, at: 0)
    if store.order.count > threadLimit {
      let drop = store.order.suffix(from: threadLimit)
      for old in drop { store.threads.removeValue(forKey: old) }
      store.order = Array(store.order.prefix(threadLimit))
    }
    write(store)
  }

  private static func read() -> Store {
    guard let data = UserDefaults.standard.data(forKey: key),
          let store = try? JSONDecoder().decode(Store.self, from: data)
    else { return Store() }
    return store
  }

  private static func write(_ store: Store) {
    guard let data = try? JSONEncoder().encode(store) else { return }
    UserDefaults.standard.set(data, forKey: key)
  }
}
