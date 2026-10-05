import AVFoundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WatchKit

private enum WatchTitle {
  static let size: CGFloat = 13
  static let color = Color(red: 79 / 255, green: 70 / 255, blue: 229 / 255)
}

private enum PersonaShelf {
  static let shown = "watch.personaRow.shown"
  static let hidden = "watch.personaRow.hidden"

  static func ids(_ raw: String) -> Set<String> {
    Set(raw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
  }

  static func raw(_ ids: Set<String>) -> String {
    ids.sorted().joined(separator: ",")
  }
}

struct ContentView: View {
  @ObservedObject private var link = WatchLink.shared
  @AppStorage(PersonaShelf.shown) private var personasShown = true
  @AppStorage(PersonaShelf.hidden) private var hiddenPersonas = ""
  @State private var path = NavigationPath()
  @State private var showFolders = false
  @State private var profile: WatchPersona?
  @State private var showHidden = false

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        if showFolders {
          folderList
        } else {
          chatList(link.chats, empty: link.chats.isEmpty ? link.status : nil)
        }
      }
      .navigationTitle {
        Text(showFolders ? "Folders" : "Chats")
          .font(.system(size: WatchTitle.size, weight: .semibold))
          .foregroundStyle(WatchTitle.color)
      }
      .refreshable { link.refreshChats() }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showFolders.toggle()
          } label: {
            Image(systemName: showFolders ? "bubble.left.and.bubble.right" : "folder")
          }
          .accessibilityLabel(showFolders ? "Chats" : "Folders")
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: startNewChat) {
            Image(systemName: "square.and.pencil")
          }
          .accessibilityLabel("New chat")
        }
      }
      .navigationDestination(for: WatchRoute.self) { route in
        switch route {
        case .folder(let id):
          FolderChatsView(folderId: id)
        case .newChat, .chat:
          ThreadView(route: route)
        }
      }
    }
    .onAppear { link.start() }
    .sheet(item: $profile) { persona in
      NavigationStack {
        PersonaProfileSheet(
          persona: persona,
          group: false,
          canChat: true,
          hidden: PersonaShelf.ids(hiddenPersonas).contains(persona.id),
          onChat: {
            profile = nil
            link.beginPersona(persona)
            path.append(WatchRoute.newChat)
          },
          onHide: { toggleHidden(persona.id) }
        )
      }
    }
    .sheet(isPresented: $showHidden) {
      NavigationStack {
        hiddenList
      }
    }
  }

  private var visiblePersonas: [WatchPersona] {
    let hidden = PersonaShelf.ids(hiddenPersonas)
    return link.personas.filter { !hidden.contains($0.id) }
  }

  private var hiddenPersonaList: [WatchPersona] {
    let hidden = PersonaShelf.ids(hiddenPersonas)
    return link.personas.filter { hidden.contains($0.id) }
  }

  @ViewBuilder
  private var personaStrip: some View {
    if !link.showPersonas || link.personas.isEmpty {
      EmptyView()
    } else if !personasShown {
      Button {
        personasShown = true
      } label: {
        Label("Personas", systemImage: "eye")
          .font(.system(size: 12, weight: .semibold))
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 6)
      .padding(.bottom, 2)
      .accessibilityLabel("Show personas")
    } else {
      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach(visiblePersonas) { persona in
            Button {
              profile = persona
            } label: {
              PersonaBubble(name: persona.name, avatar: persona.avatar, color: persona.color)
            }
            .buttonStyle(.plain)
          }
          if !hiddenPersonaList.isEmpty {
            Button {
              showHidden = true
            } label: {
              PersonaActionBubble(title: "Hidden", systemImage: "eye")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hidden personas")
          }
          Button {
            personasShown = false
          } label: {
            PersonaActionBubble(title: "Hide", systemImage: "eye.slash")
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Hide personas")
        }
        .padding(.horizontal, 4)
      }
      .frame(height: 58)
    }
  }

  private var hiddenList: some View {
    List {
      if hiddenPersonaList.isEmpty {
        Text("No hidden personas")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }
      ForEach(hiddenPersonaList) { persona in
        Button {
          toggleHidden(persona.id)
        } label: {
          HStack(spacing: 8) {
            PersonaBubble(name: persona.name, avatar: persona.avatar, color: persona.color)
            Text("Unhide")
              .font(.system(size: 12, weight: .semibold))
          }
        }
      }
    }
    .navigationTitle("Hidden")
  }

  private func toggleHidden(_ id: String) {
    guard !id.isEmpty else { return }
    var ids = PersonaShelf.ids(hiddenPersonas)
    if ids.contains(id) {
      ids.remove(id)
    } else {
      ids.insert(id)
    }
    hiddenPersonas = PersonaShelf.raw(ids)
  }

  private var folderList: some View {
    List {
      if link.folders.isEmpty {
        Text(link.chats.isEmpty ? link.status : "No folders")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }
      ForEach(link.folders) { folder in
        NavigationLink(value: WatchRoute.folder(folder.id)) {
          VStack(alignment: .leading, spacing: 1) {
            Text(folder.name)
              .font(.system(size: 14))
              .lineLimit(1)
            Text(folder.count == 1 ? "1 chat" : "\(folder.count) chats")
              .font(.system(size: 9))
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }

  private func chatList(_ chats: [WatchChat], empty: String?) -> some View {
    List {
      if !link.personas.isEmpty {
        personaStrip
          .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 6, trailing: 0))
          .listRowBackground(Color.clear)
      }
      if let empty, chats.isEmpty {
        Text(empty)
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }
      ForEach(chats) { chat in
        NavigationLink(value: WatchRoute.chat(chat.id)) {
          WatchChatLabel(chat: chat)
        }
      }
    }
  }

  private func startNewChat() {
    link.beginNewChat()
    path.append(WatchRoute.newChat)
  }
}

private struct FolderChatsView: View {
  @ObservedObject private var link = WatchLink.shared
  let folderId: String

  private var folderName: String {
    link.folders.first { $0.id == folderId }?.name ?? "Folder"
  }

  private var chats: [WatchChat] {
    link.chats.filter { $0.folderId == folderId }
  }

  var body: some View {
    List {
      if chats.isEmpty {
        Text("No chats")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }
      ForEach(chats) { chat in
        NavigationLink(value: WatchRoute.chat(chat.id)) {
          WatchChatLabel(chat: chat)
        }
      }
    }
    .navigationTitle(folderName)
  }
}

private struct WatchChatLabel: View {
  let chat: WatchChat

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .center, spacing: 8) {
        ChatFace(
          title: chat.title,
          avatar: chat.avatar,
          avatar2: chat.avatar2,
          color: chat.color,
          group: chat.group
        )
        VStack(alignment: .leading, spacing: 0) {
          HStack(spacing: 3) {
            if chat.branch {
              Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Branch")
            }
            Text(chat.title)
              .font(.system(size: 12))
              .lineLimit(1)
          }
          if !when.isEmpty {
            Text(when)
              .font(.system(size: 9))
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
      }
      if !chat.preview.isEmpty {
        Text(chat.preview)
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(.horizontal, 1)
    .padding(.vertical, 8)
  }

  private var when: String {
    guard chat.updatedMs > 0 else { return "" }
    let date = Date(timeIntervalSince1970: TimeInterval(chat.updatedMs) / 1000)
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      let format = DateFormatter()
      format.dateFormat = "hh:mm a"
      return format.string(from: date).lowercased()
    }
    if calendar.isDateInYesterday(date) { return "Yesterday" }
    let start = calendar.startOfDay(for: date)
    let today = calendar.startOfDay(for: Date())
    let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
    if days > 1 { return "\(days) days ago" }
    let format = DateFormatter()
    format.dateFormat = "MMM d"
    return format.string(from: date)
  }
}

private struct ChatFace: View {
  let title: String
  let avatar: Data?
  let avatar2: Data?
  let color: Int?
  let group: Bool

  var body: some View {
    ZStack {
      if let avatar2, group {
        face(avatar2, fallback: secondInitial)
          .frame(width: 26, height: 26)
          .offset(x: 8, y: 7)
        face(avatar, fallback: initial)
          .frame(width: 26, height: 26)
          .offset(x: -6, y: -5)
      } else {
        face(avatar, fallback: initial)
          .frame(width: 40, height: 40)
      }
    }
    .frame(width: 42, height: 42)
  }

  private func face(_ data: Data?, fallback: String) -> some View {
    Group {
      if let data, let image = UIImage(data: data) {
        Image(uiImage: image)
          .interpolation(.high)
          .resizable()
          .scaledToFill()
      } else {
        Text(fallback)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(fill)
      }
    }
    .clipShape(Circle())
    .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
  }

  private var initial: String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
  }

  private var secondInitial: String {
    let parts = title.split(separator: " ")
    guard parts.count > 1 else { return initial }
    return String(parts[1].prefix(1)).uppercased()
  }

  private var fill: Color {
    guard let color else { return Color.white.opacity(0.22) }
    let red = Double((color >> 16) & 0xFF) / 255
    let green = Double((color >> 8) & 0xFF) / 255
    let blue = Double(color & 0xFF) / 255
    return Color(red: red, green: green, blue: blue)
  }
}

private struct ThreadView: View {
  @ObservedObject private var link = WatchLink.shared
  @StateObject private var speaker = WatchSpeaker()
  @State private var draft = ""
  @State private var showImage = false
  @State private var imageStart = ""
  @State private var editId: String?
  @State private var editDraft = ""
  @State private var pendingDelete: WatchLine?
  @State private var menuLine: WatchLine?
  @State private var shareText: String?
  @State private var showAdd = false
  @State private var showPhotos = false
  @State private var photo: PhotosPickerItem?
  @State private var attachment: Data?
  @State private var followLatest = true
  @State private var revealedUsers: Set<String> = []
  @State private var showProfile = false
  @State private var fullPhoto: WatchPhoto?
  @State private var showCompose = false
  @State private var transcriptFill: CGFloat = 0
  @AppStorage(PersonaShelf.hidden) private var hiddenPersonas = ""
  let route: WatchRoute

  private let composerHeight: CGFloat = 34
  /// Room under the field so a short scroll lifts the clipped bottom onto the screen.
  private var fieldUnder: CGFloat { composerHeight * 0.10 + 28 }

  private var canSend: Bool {
    !link.busy
      && (attachment != nil
        || !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  private var outgoingBlue: Color {
    Color(red: 0.0, green: 0.48, blue: 1.0)
  }

  var body: some View {
    ScrollViewReader { proxy in
      messageList
        .containerBackground(for: .navigation) { backdrop }
        .navigationTitle {
          Text(link.threadTitle)
            .font(.system(size: WatchTitle.size, weight: .semibold))
            .foregroundStyle(WatchTitle.color)
            .lineLimit(1)
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              showProfile = true
            } label: {
              avatar
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Persona")
          }
        }
        .onAppear {
          openIfNeeded()
          revealField(proxy)
        }
        .onChange(of: transcriptFill) { _, height in
          if height > 0 { revealField(proxy) }
        }
        .onDisappear {
          speaker.stop()
          revealedUsers = []
        }
        .onChange(of: link.busy) { _, busy in
          if busy { speaker.stop() }
        }
        .onChange(of: link.messages.count) { _, _ in
          if followLatest { revealField(proxy) }
        }
        .onChange(of: link.reply) { _, _ in
          if followLatest { revealField(proxy) }
        }
        .onChange(of: photo) { _, item in
          guard let item else { return }
          Task { await takePhoto(item, proxy: proxy) }
        }
        .sheet(item: $fullPhoto) { photo in
          WatchImageViewer(image: photo.image)
        }
        .sheet(isPresented: $showCompose) {
          NavigationStack {
            ComposeSheet(hasAttachment: attachment != nil) { text in
              sendDraft(text)
            }
          }
        }
        .sheet(isPresented: $showProfile) {
          NavigationStack {
            PersonaProfileSheet(
              persona: threadPersona,
              group: link.groupChat,
              canChat: false,
              hidden: PersonaShelf.ids(hiddenPersonas).contains(link.personaId),
              onChat: { showProfile = false },
              onHide: {
                var ids = PersonaShelf.ids(hiddenPersonas)
                let id = link.personaId
                guard !id.isEmpty else { return }
                if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
                hiddenPersonas = PersonaShelf.raw(ids)
              }
            )
          }
        }
        .sheet(isPresented: $showImage) {
          NavigationStack {
            ImagePromptSheet(start: imageStart)
          }
        }
        .sheet(isPresented: Binding(
          get: { editId != nil },
          set: { if !$0 { editId = nil } }
        )) {
          NavigationStack {
            EditLineSheet(draft: $editDraft) {
              if let editId {
                link.edit(editId, editDraft)
              }
              editId = nil
            }
          }
        }
        .confirmationDialog(
          "Delete this message?",
          isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
          ),
          titleVisibility: .visible
        ) {
          Button("Delete", role: .destructive) {
            if let pendingDelete {
              link.delete(pendingDelete.id)
            }
            pendingDelete = nil
          }
        }
        .sheet(isPresented: Binding(
          get: { shareText != nil },
          set: { if !$0 { shareText = nil } }
        )) {
          if let shareText {
            ShareLink(item: shareText) {
              Text("Share")
                .frame(maxWidth: .infinity)
            }
            .padding()
          }
        }
    }
  }

  private var showsGreeting: Bool {
    link.conversationId == nil
      && link.messages.isEmpty
      && link.reply.isEmpty
      && link.replyThinking.isEmpty
  }

  private func greeting(height: CGFloat) -> some View {
    VStack(spacing: 4) {
      Text("Greetings!")
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(.white)
        .legible()
      Text("How may I assist you today?")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Color(red: 0.953, green: 0.925, blue: 1))
        .multilineTextAlignment(.center)
        .legible()
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
  }

  private func revealField(_ proxy: ScrollViewProxy) {
    proxy.scrollTo("rest", anchor: .bottom)
    DispatchQueue.main.async {
      proxy.scrollTo("rest", anchor: .bottom)
    }
  }

  private var messageList: some View {
    GeometryReader { geo in
      let fill = geo.size.height + geo.safeAreaInsets.bottom
      ScrollView {
        VStack(spacing: 0) {
          VStack(alignment: .leading, spacing: 6) {
            if showsGreeting {
              greeting(height: max(72, fill - composerHeight))
            } else {
            ForEach(link.messages) { line in
              lineView(line)
                .id(line.id)
            }
            if !link.reply.isEmpty || !link.replyThinking.isEmpty {
              VStack(alignment: .leading, spacing: 2) {
                if !link.replyThinking.isEmpty {
                  ThoughtBlock(text: link.replyThinking)
                }
                if !link.reply.isEmpty {
                  messageText(link.reply, outgoing: false)
                  speakButton(WatchMarkup.plain(link.reply))
                }
              }
            }
            if link.busy && link.reply.isEmpty && !link.messages.isEmpty {
              ProgressView()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            }
            composer
              .padding(.bottom, -composerHeight * 0.10)
          }
          .padding(.horizontal, 2)
          .padding(.top, 4)
          .frame(maxWidth: .infinity, minHeight: fill, alignment: .bottom)
          .id("rest")
          Color.clear.frame(height: fieldUnder)
        }
      }
      .ignoresSafeArea(edges: .bottom)
      .watchFollowLatest($followLatest)
      .onAppear { transcriptFill = fill }
      .onChange(of: fill) { _, height in
        transcriptFill = height
      }
    }
  }

  private var backdrop: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black
        if let data = link.wallpaper, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(Color.black.opacity(link.wallpaperDim))
            .clipped()
        }
      }
    }
  }

  private var threadPersona: WatchPersona {
    WatchPersona(
      id: link.personaId,
      name: link.personaName.isEmpty ? link.threadTitle : link.personaName,
      prompt: link.personaPrompt,
      model: link.personaModel,
      provider: link.personaProvider,
      modelPinned: link.personaModelPinned,
      providerPinned: link.personaProviderPinned,
      avatar: link.avatar,
      color: link.avatarColor
    )
  }

  private var avatar: some View {
    Group {
      if let data = link.avatar, let image = UIImage(data: data) {
        Image(uiImage: image)
          .interpolation(.high)
          .resizable()
          .scaledToFill()
      } else {
        Text(initial)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(avatarFill)
      }
    }
    .frame(width: 30, height: 30)
    .clipShape(Circle())
    .accessibilityLabel(link.threadTitle)
  }

  private var initial: String {
    let trimmed = link.threadTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
  }

  private var avatarFill: Color {
    guard let color = link.avatarColor else { return Color.white.opacity(0.22) }
    let red = Double((color >> 16) & 0xFF) / 255
    let green = Double((color >> 8) & 0xFF) / 255
    let blue = Double(color & 0xFF) / 255
    return Color(red: red, green: green, blue: blue)
  }

  private var composer: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let attachment, let image = UIImage(data: attachment) {
        HStack(spacing: 6) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
          Button {
            self.attachment = nil
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 11, weight: .bold))
          }
          .watchGlassCircle(diameter: 28)
          .accessibilityLabel("Remove photo")
        }
      }
      HStack(alignment: .center, spacing: 8) {
        Button {
          showAdd = true
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 34, height: 34)
        }
        .watchGlassCircle(diameter: 34)
        .accessibilityLabel("Add")
        .confirmationDialog("Add", isPresented: $showAdd, titleVisibility: .hidden) {
          Button("Image gen") {
            DispatchQueue.main.async { showImage = true }
          }
          Button("Attach image") {
            DispatchQueue.main.async { showPhotos = true }
          }
        }
        .photosPicker(isPresented: $showPhotos, selection: $photo, matching: .images)
        HStack(spacing: 4) {
          Button {
            openMessageInput()
          } label: {
            Text(draft.isEmpty ? "Message" : draft)
              .font(.footnote)
              .foregroundStyle(.white.opacity(draft.isEmpty ? 0.55 : 1))
              .lineLimit(1)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
          }
          .buttonStyle(.borderless)
          .accessibilityLabel("Message")
          if canSend {
            Button {
              sendDraft()
            } label: {
              Image(systemName: "arrow.up")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(outgoingBlue, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Send")
          }
        }
        .padding(.leading, 12)
        .padding(.trailing, canSend ? 6 : 12)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .watchGlassCapsule()
      }
    }
  }

  @ViewBuilder
  private func lineView(_ line: WatchLine) -> some View {
    let picture = line.attachment ?? (line.id == lastImageId ? link.imagePreview : nil)
    let bitmap = picture.flatMap { UIImage(data: $0) }
    VStack(alignment: line.role == "user" ? .trailing : .leading, spacing: 2) {
      if line.role != "user", !line.thinking.isEmpty {
        ThoughtBlock(text: line.thinking)
      }
      if !line.text.isEmpty {
        if line.role == "user" {
          Button {
            revealedUsers = revealedUsers.union([line.id])
          } label: {
            messageText(line.text, outgoing: true)
          }
          .buttonStyle(.plain)
        } else {
          messageText(line.text, outgoing: false)
        }
      }
      if let bitmap {
        Button {
          fullPhoto = WatchPhoto(image: bitmap)
        } label: {
          Image(uiImage: bitmap)
            .interpolation(.high)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 120, maxHeight: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open image")
      } else if line.hasImage {
        Text("Image")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      if line.role == "user" {
        let visible = WatchMarkup.withoutImagePrompt(line.text)
        if revealedUsers.contains(line.id) || visible.isEmpty {
          userActions(line)
        }
      } else if isLatestReply(line) || hasMessageActions(line) {
        HStack(spacing: 8) {
          if isLatestReply(line) {
            speakButton(WatchMarkup.plain(line.text))
          }
          if hasMessageActions(line) {
            messageMenu(line)
          }
        }
      }
    }
    .listRowBackground(Color.clear)
  }

  @ViewBuilder
  private func messageText(_ text: String, outgoing: Bool) -> some View {
    let cleaned = WatchMarkup.withoutImagePrompt(text)
    let plain = !outgoing && link.fullWidth
    if !cleaned.isEmpty {
      messageBody(cleaned, outgoing: outgoing)
      .font(.system(size: 14, weight: .regular))
      .foregroundStyle(.white)
      .multilineTextAlignment(outgoing ? .trailing : .leading)
      .padding(.horizontal, plain ? 2 : 10)
      .padding(.vertical, plain ? 1 : 6)
      .background {
        if plain {
          Color.clear
        } else {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(outgoing ? outgoingBlue : Color.white.opacity(0.28))
        }
      }
      .frame(maxWidth: plain ? .infinity : 136, alignment: outgoing ? .trailing : .leading)
      .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
    }
  }

  @ViewBuilder
  private func messageBody(_ text: String, outgoing: Bool) -> some View {
    if outgoing {
      Text(text)
    } else {
      WatchMarkupView(source: text)
    }
  }

  private func openIfNeeded() {
    switch route {
    case .newChat:
      if link.conversationId == nil, link.messages.isEmpty, link.pendingPersonaId == nil {
        link.beginNewChat()
      }
    case .chat(let id):
      guard link.conversationId != id,
            let chat = link.chats.first(where: { $0.id == id })
      else { return }
      link.openChat(chat)
    case .folder:
      break
    }
  }

  /// A `TextField` inside the transcript scroll view never receives the tap.
  /// The system input controller does. When that controller is missing, a
  /// sheet with its own field is the fallback.
  private func openMessageInput() {
    guard let controller = WKApplication.shared().visibleInterfaceController else {
      showCompose = true
      return
    }
    controller.presentTextInputController(
      withSuggestions: nil,
      allowedInputMode: .allowEmoji
    ) { results in
      guard let results else { return }
      let text = (results.first as? String) ?? ""
      DispatchQueue.main.async {
        let ready = self.attachment != nil
          || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if ready { self.sendDraft(text) }
      }
    }
  }

  private func sendDraft(_ text: String? = nil) {
    let message = text ?? draft
    let image = attachment
    draft = ""
    attachment = nil
    followLatest = true
    link.send(message, image: image)
  }

  private func takePhoto(_ item: PhotosPickerItem, proxy: ScrollViewProxy) async {
    let picked = try? await item.loadTransferable(type: PickedPhoto.self)
    let image = picked.flatMap { UIImage(data: $0.data) }
    let jpeg = image.flatMap { jpegAttachment($0) }
    await MainActor.run {
      photo = nil
      guard let jpeg else { return }
      attachment = jpeg
      followLatest = true
      revealField(proxy)
    }
  }

  /// Small enough to ride along in one watch message.
  private func jpegAttachment(_ image: UIImage) -> Data? {
    guard let source = image.cgImage else {
      return image.jpegData(compressionQuality: 0.4)
    }
    var edge: CGFloat = 512
    var quality: CGFloat = 0.55
    var best: Data?
    for _ in 0..<5 {
      let longest = max(CGFloat(source.width), CGFloat(source.height))
      let scale = longest > 0 ? min(1, edge / longest) : 1
      let width = max(1, Int((CGFloat(source.width) * scale).rounded()))
      let height = max(1, Int((CGFloat(source.height) * scale).rounded()))
      guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else { return best }
      context.interpolationQuality = .medium
      context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
      guard let scaled = context.makeImage() else { return best }
      guard let data = UIImage(cgImage: scaled).jpegData(compressionQuality: quality) else {
        return best
      }
      best = data
      if data.count <= 24_000 { return data }
      quality *= 0.7
      edge *= 0.75
    }
    guard let best, best.count <= 28_000 else { return nil }
    return best
  }

  private var lastImageId: String? {
    link.messages.last { $0.hasImage }?.id
  }

  private func isLatestReply(_ line: WatchLine) -> Bool {
    guard link.reply.isEmpty, line.role != "user", !line.text.isEmpty else { return false }
    return link.messages.last { $0.role != "user" && !$0.text.isEmpty }?.id == line.id
  }

  private func hasMessageActions(_ line: WatchLine) -> Bool {
    !line.text.isEmpty || !line.imagePrompt.isEmpty || !line.id.isEmpty
  }

  private func imagePrompt(for line: WatchLine) -> String {
    let stored = line.imagePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    if !stored.isEmpty { return stored }
    return line.text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func canImagine(_ line: WatchLine) -> Bool {
    link.imageGen && line.role != "user" && !imagePrompt(for: line).isEmpty
  }

  private func isLastAssistant(_ line: WatchLine) -> Bool {
    guard line.role != "user", !line.text.isEmpty, link.reply.isEmpty else { return false }
    return link.messages.last { $0.role != "user" && !$0.text.isEmpty }?.id == line.id
  }

  private var transcript: String {
    link.messages
      .map { line in
        let who = line.role == "user" ? "You" : link.threadTitle
        return "\(who): \(WatchMarkup.withoutImagePrompt(line.text))"
      }
      .filter { !$0.hasSuffix(": ") }
      .joined(separator: "\n\n")
  }

  @ViewBuilder
  private func messageMenu(_ line: WatchLine) -> some View {
    let text = WatchMarkup.withoutImagePrompt(line.text)
    Button {
      menuLine = line
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(WatchTitle.color)
        .frame(width: 22, height: 22)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Message actions")
    .confirmationDialog("Message", isPresented: Binding(
      get: { menuLine?.id == line.id },
      set: { if !$0 { menuLine = nil } }
    ), titleVisibility: .hidden) {
      if line.role != "user", !text.isEmpty {
        Button(speaker.speaking ? "Stop" : "Speak") {
          speaker.toggle(text)
        }
      }
      if !text.isEmpty {
        Button("Copy") {
          link.copyToPhone(text)
        }
        Button("Share") {
          DispatchQueue.main.async { shareText = text }
        }
      }
      if link.messages.count > 1, !transcript.isEmpty {
        Button("Share chat") {
          let chat = transcript
          DispatchQueue.main.async { shareText = chat }
        }
      }
      if canImagine(line) {
        Button("Image gen") {
          let prompt = imagePrompt(for: line)
          DispatchQueue.main.async {
            imageStart = prompt
            showImage = true
          }
        }
      }
      if isLastAssistant(line), !link.busy {
        Button("Regenerate") {
          followLatest = true
          link.regenerate(line.id)
        }
      }
      if line.role == "user", !text.isEmpty, !link.busy {
        Button("Edit") {
          let id = line.id
          let current = text
          DispatchQueue.main.async {
            editId = id
            editDraft = current
          }
        }
      }
      if !link.groupChat, link.canBranch, !link.busy {
        Button("Branch") {
          link.branch(line.id)
        }
      }
      if !link.busy {
        Button("Delete", role: .destructive) {
          DispatchQueue.main.async { pendingDelete = line }
        }
      }
    }
  }

  private func userActions(_ line: WatchLine) -> some View {
    let text = WatchMarkup.withoutImagePrompt(line.text)
    return HStack(spacing: 10) {
      if !text.isEmpty {
        iconAction("doc.on.doc", "Copy") {
          link.copyToPhone(text)
        }
        iconAction("square.and.arrow.up", "Share") {
          DispatchQueue.main.async { shareText = text }
        }
      }
      if !text.isEmpty, !link.busy {
        iconAction("pencil", "Edit") {
          let id = line.id
          let current = text
          DispatchQueue.main.async {
            editId = id
            editDraft = current
          }
        }
      }
      if !link.groupChat, link.canBranch, !link.busy {
        iconAction("arrow.triangle.branch", "Branch") {
          link.branch(line.id)
        }
      }
      if !link.busy {
        iconAction("trash", "Delete") {
          DispatchQueue.main.async { pendingDelete = line }
        }
      }
    }
  }

  private func iconAction(
    _ system: String,
    _ label: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: system)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(WatchTitle.color)
        .frame(width: 22, height: 22)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private func speakButton(_ text: String) -> some View {
    Button {
      speaker.toggle(text)
    } label: {
      Image(systemName: speaker.speaking ? "stop.fill" : "speaker.wave.2.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(WatchTitle.color)
        .frame(width: 22, height: 22)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(speaker.speaking ? "Stop speaking" : "Speak reply")
  }
}

/// Collapsed thinking. The answer stays in the bubble; the thought opens on tap.
private struct ThoughtBlock: View {
  let text: String
  @State private var open = false

  var body: some View {
    let cleaned = WatchMarkup.withoutImagePrompt(text)
    if !cleaned.isEmpty {
      VStack(alignment: .leading, spacing: 2) {
        Button {
          open.toggle()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: open ? "chevron.down" : "chevron.right")
              .font(.system(size: 9, weight: .bold))
            Text("Thought")
              .font(.system(size: 12, weight: .semibold))
          }
          .foregroundStyle(.white.opacity(0.65))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(open ? "Hide thought" : "Show thought")
        if open {
          Text(cleaned)
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}

private struct ImagePromptSheet: View {
  @ObservedObject private var link = WatchLink.shared
  var start = ""
  @State private var draft = ""

  private var canSend: Bool {
    !link.imageBusy && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        TextField("Prompt", text: $draft)
          .textFieldStyle(.plain)
        Button(action: send) {
          Text(link.imageBusy ? "Sending" : "Send")
            .frame(maxWidth: .infinity)
        }
        .disabled(!canSend)
        if !link.imageStatus.isEmpty {
          Text(link.imageStatus)
            .font(.footnote)
            .foregroundStyle(link.imageState == "failed" ? .red : .secondary)
        }
        if link.imageBusy {
          ProgressView()
            .frame(maxWidth: .infinity)
        }
        if let data = link.imagePreview, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
      }
    }
    .navigationTitle {
      Text("Image")
        .font(.system(size: WatchTitle.size, weight: .semibold))
        .foregroundStyle(WatchTitle.color)
    }
    .onAppear {
      if draft.isEmpty { draft = start }
    }
    .onChange(of: link.imageState) { _, state in
      if state == "ready" { draft = "" }
    }
  }

  private func send() {
    link.imagine(draft)
  }
}

private struct PickedPhoto: Transferable {
  let data: Data

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(importedContentType: .image) { data in
      PickedPhoto(data: data)
    }
  }
}

private struct ComposeSheet: View {
  var hasAttachment: Bool
  var onSend: (String) -> Void
  @Environment(\.dismiss) private var dismiss
  @FocusState private var focused: Bool
  @State private var text = ""

  private var canSend: Bool {
    hasAttachment || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        TextField("Message", text: $text)
          .focused($focused)
          .textFieldStyle(.plain)
          .onSubmit { send() }
        Button(action: send) {
          Text("Send")
            .frame(maxWidth: .infinity)
        }
        .disabled(!canSend)
      }
    }
    .navigationTitle {
      Text("Message")
        .font(.system(size: WatchTitle.size, weight: .semibold))
        .foregroundStyle(WatchTitle.color)
    }
    .onAppear {
      DispatchQueue.main.async { focused = true }
    }
  }

  private func send() {
    guard canSend else { return }
    onSend(text)
    dismiss()
  }
}

private struct EditLineSheet: View {
  @Binding var draft: String
  var onSave: () -> Void

  private var canSave: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        TextField("Message", text: $draft)
          .textFieldStyle(.plain)
        Button(action: onSave) {
          Text("Save")
            .frame(maxWidth: .infinity)
        }
        .disabled(!canSave)
      }
    }
    .navigationTitle {
      Text("Edit")
        .font(.system(size: WatchTitle.size, weight: .semibold))
        .foregroundStyle(WatchTitle.color)
    }
  }
}

/// Reads the latest reply with the watch's system voice.
private final class WatchSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
  private let synth = AVSpeechSynthesizer()
  @Published private(set) var speaking = false

  override init() {
    super.init()
    synth.delegate = self
  }

  func toggle(_ raw: String) {
    let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    if synth.isSpeaking {
      stop()
      return
    }
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
    synth.speak(utterance)
    speaking = true
  }

  func stop() {
    if synth.isSpeaking {
      synth.stopSpeaking(at: .immediate)
    }
    speaking = false
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { self.speaking = false }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { self.speaking = false }
  }
}

private struct WatchPhoto: Identifiable {
  let id = UUID()
  let image: UIImage
}

private struct WatchImageViewer: View {
  let image: UIImage
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.black.ignoresSafeArea()
      Image(uiImage: image)
        .interpolation(.high)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 8)
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 28, height: 28)
          .background(.ultraThinMaterial, in: Circle())
      }
      .buttonStyle(.plain)
      .padding(.leading, 4)
      .padding(.top, 2)
      .accessibilityLabel("Close")
    }
  }
}

private struct PersonaBubble: View {
  let name: String
  let avatar: Data?
  let color: Int?

  var body: some View {
    VStack(spacing: 2) {
      face
        .frame(width: 34, height: 34)
      if !name.isEmpty {
        Text(name)
          .font(.system(size: 9))
          .lineLimit(1)
          .frame(width: 48)
      }
    }
  }

  private var face: some View {
    Group {
      if let avatar, let image = UIImage(data: avatar) {
        Image(uiImage: image)
          .interpolation(.high)
          .resizable()
          .scaledToFill()
      } else {
        Text(initial)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(fill)
      }
    }
    .clipShape(Circle())
  }

  private var initial: String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
  }

  private var fill: Color {
    guard let color else { return Color.white.opacity(0.22) }
    let red = Double((color >> 16) & 0xFF) / 255
    let green = Double((color >> 8) & 0xFF) / 255
    let blue = Double(color & 0xFF) / 255
    return Color(red: red, green: green, blue: blue)
  }
}

private struct PersonaActionBubble: View {
  let title: String
  let systemImage: String

  var body: some View {
    VStack(spacing: 2) {
      Image(systemName: systemImage)
        .font(.system(size: 14, weight: .semibold))
        .frame(width: 34, height: 34)
        .background(Circle().fill(Color.white.opacity(0.16)))
      Text(title)
        .font(.system(size: 9))
        .lineLimit(1)
        .frame(width: 48)
    }
  }
}

private struct PersonaProfileSheet: View {
  let persona: WatchPersona
  let group: Bool
  var canChat: Bool
  var hidden: Bool
  var onChat: () -> Void
  var onHide: () -> Void

  var body: some View {
    ZStack {
      hero
      edgeWash
        .allowsHitTesting(false)
      ScrollView {
        VStack(alignment: .leading, spacing: 8) {
          Text(persona.name.isEmpty ? "Persona" : persona.name)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(2)
            .legible()
          Capsule()
            .fill(accent)
            .frame(width: 28, height: 3)
          if group {
            Text("Group chat")
              .font(.system(size: 11))
              .foregroundStyle(.white.opacity(0.8))
              .legible()
          }
          detail("Provider", persona.provider, pinned: persona.providerPinned)
          detail("Model", persona.model, pinned: persona.modelPinned)
          if persona.prompt.isEmpty && persona.model.isEmpty && persona.provider.isEmpty {
            Text("No persona on this chat.")
              .font(.system(size: 12))
              .foregroundStyle(.white.opacity(0.75))
              .legible()
          }
          if !persona.prompt.isEmpty {
            Text("System prompt")
              .font(.system(size: 11, weight: .semibold))
              .foregroundStyle(accent)
              .legible()
            Text(persona.prompt)
              .font(.system(size: 12))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity, alignment: .leading)
              .legible()
          }
          if canChat {
            Button("Chat", action: onChat)
              .buttonStyle(.borderedProminent)
              .tint(accent)
          }
          if !persona.id.isEmpty {
            Button(hidden ? "Unhide" : "Hide", action: onHide)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.top, 28)
        .padding(.bottom, 8)
      }
    }
    .navigationTitle(persona.name.isEmpty ? "Persona" : persona.name)
    .toolbarBackground(.hidden, for: .navigationBar)
  }

  private var hero: some View {
    GeometryReader { proxy in
      ZStack {
        accent
        if let data = persona.avatar, let image = UIImage(data: data) {
          Image(uiImage: image)
            .interpolation(.high)
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
      }
    }
    .ignoresSafeArea()
  }

  private var edgeWash: some View {
    ZStack {
      LinearGradient(colors: [accent.opacity(0.55), .clear], startPoint: .top, endPoint: .center)
      LinearGradient(colors: [secondary.opacity(0.5), .clear], startPoint: .bottom, endPoint: .center)
      LinearGradient(colors: [accent.opacity(0.38), .clear], startPoint: .leading, endPoint: .center)
      LinearGradient(colors: [secondary.opacity(0.38), .clear], startPoint: .trailing, endPoint: .center)
    }
    .ignoresSafeArea()
  }

  private var rgb: (Double, Double, Double) {
    let color = persona.color ?? 0x4F46E5
    return (
      Double((color >> 16) & 0xFF) / 255,
      Double((color >> 8) & 0xFF) / 255,
      Double(color & 0xFF) / 255
    )
  }

  private var accent: Color {
    Color(red: rgb.0, green: rgb.1, blue: rgb.2)
  }

  private var secondary: Color {
    Color(
      red: min(1, rgb.0 * 0.45 + 0.55),
      green: min(1, rgb.1 * 0.45 + 0.55),
      blue: min(1, rgb.2 * 0.45 + 0.55)
    )
  }

  @ViewBuilder
  private func detail(_ title: String, _ value: String, pinned: Bool) -> some View {
    if !value.isEmpty {
      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(accent)
          .legible()
        Text(value)
          .font(.system(size: 12))
          .foregroundStyle(.white)
          .legible()
        if !pinned {
          Text("Current on the iPhone")
            .font(.system(size: 9))
            .foregroundStyle(.white.opacity(0.7))
            .legible()
        }
      }
    }
  }
}

/// Assistant text uses the same Markdown the iPhone renders. SwiftUI's single
/// `Text` drops paragraph and list breaks, so each block is its own row.
private struct WatchMarkupView: View {
  let source: String

  var body: some View {
    let blocks = WatchMarkup.blocks(source)
    VStack(alignment: .leading, spacing: 0) {
      ForEach(blocks) { block in
        WatchMarkup.row(block)
          .padding(.bottom, block.gap)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private enum WatchMarkup {
  struct Block: Identifiable {
    enum Kind: Equatable {
      case paragraph
      case heading(Int)
      case numbered(String)
      case bullet
      case quote
      case code
      case rule
    }

    let id: Int
    let kind: Kind
    let text: String

    var gap: CGFloat {
      switch kind {
      case .numbered, .bullet: return 6
      case .rule: return 8
      default: return 10
      }
    }
  }

  private static var inlineOptions: AttributedString.MarkdownParsingOptions {
    AttributedString.MarkdownParsingOptions(
      interpretedSyntax: .inlineOnlyPreservingWhitespace,
      failurePolicy: .returnPartiallyParsedIfPossible
    )
  }

  static func withoutImagePrompt(_ raw: String) -> String {
    guard raw.contains("IMG_PROMPT") else { return raw }
    var text = raw
    let patterns = [
      #"\[IMG_PROMPT:\s*[\s\S]*?\]"#,
      #"\[IMG_PROMPT:[\s\S]*"#,
    ]
    for pattern in patterns {
      guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
      let range = NSRange(text.startIndex..., in: text)
      text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static func plain(_ raw: String) -> String {
    let cleaned = withoutImagePrompt(raw).replacingOccurrences(of: "\r\n", with: "\n")
    guard let attributed = try? AttributedString(markdown: cleaned, options: inlineOptions) else {
      return cleaned
    }
    return String(attributed.characters)
  }

  static func blocks(_ raw: String) -> [Block] {
    let lines = withoutImagePrompt(raw)
      .replacingOccurrences(of: "\r\n", with: "\n")
      .components(separatedBy: "\n")
    var result: [Block] = []
    var index = 0
    func add(_ kind: Block.Kind, _ text: String) {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty, kind != .rule { return }
      result.append(Block(id: result.count, kind: kind, text: trimmed))
    }
    while index < lines.count {
      let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty {
        index += 1
        continue
      }
      if trimmed == "---" || trimmed == "***" || trimmed == "___" {
        add(.rule, "")
        index += 1
        continue
      }
      if trimmed.hasPrefix("```") {
        index += 1
        var code: [String] = []
        while index < lines.count,
              !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
          code.append(lines[index])
          index += 1
        }
        if index < lines.count { index += 1 }
        add(.code, code.joined(separator: "\n"))
        continue
      }
      if trimmed.hasPrefix(">") {
        var quote: [String] = []
        while index < lines.count {
          let line = lines[index].trimmingCharacters(in: .whitespaces)
          guard line.hasPrefix(">") else { break }
          var rest = String(line.dropFirst())
          if rest.hasPrefix(" ") { rest.removeFirst() }
          quote.append(rest)
          index += 1
        }
        add(.quote, quote.joined(separator: " "))
        continue
      }
      if let heading = heading(trimmed) {
        add(.heading(heading.level), heading.text)
        index += 1
        continue
      }
      if let item = listItem(trimmed) {
        var body = item.body
        index += 1
        while index < lines.count {
          let next = lines[index].trimmingCharacters(in: .whitespaces)
          if next.isEmpty { break }
          if listItem(next) != nil || heading(next) != nil { break }
          if next.hasPrefix("```") || next.hasPrefix(">") { break }
          if next == "---" || next == "***" || next == "___" { break }
          body += " " + next
          index += 1
        }
        add(item.kind, body)
        continue
      }
      var paragraph = trimmed
      index += 1
      while index < lines.count {
        let next = lines[index].trimmingCharacters(in: .whitespaces)
        if next.isEmpty { break }
        if listItem(next) != nil || heading(next) != nil { break }
        if next.hasPrefix("```") || next.hasPrefix(">") { break }
        if next == "---" || next == "***" || next == "___" { break }
        paragraph += " " + next
        index += 1
      }
      add(.paragraph, paragraph)
    }
    return result
  }

  @ViewBuilder
  static func row(_ block: Block) -> some View {
    switch block.kind {
    case .rule:
      Rectangle()
        .fill(Color.white.opacity(0.35))
        .frame(height: 1)
        .padding(.vertical, 2)
    case .code:
      inline(block.text, monospaced: true)
    case .quote:
      HStack(alignment: .top, spacing: 6) {
        RoundedRectangle(cornerRadius: 1)
          .fill(Color.white.opacity(0.45))
          .frame(width: 2)
        inline(block.text)
          .italic()
      }
    case .heading(let level):
      inline(block.text)
        .font(.system(size: level <= 2 ? 17 : 15, weight: .bold))
    case .numbered(let number):
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text("\(number).")
          .font(.system(size: 14, weight: .semibold))
        inline(block.text)
      }
    case .bullet:
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text("•")
          .font(.system(size: 14, weight: .semibold))
        inline(block.text)
      }
    case .paragraph:
      inline(block.text)
    }
  }

  private static func inline(_ raw: String, monospaced: Bool = false) -> some View {
    let cleaned = raw.replacingOccurrences(of: "\r\n", with: "\n")
    let body: Text
    if monospaced {
      body = Text(cleaned)
    } else if let attributed = try? AttributedString(markdown: cleaned, options: inlineOptions) {
      body = Text(attributed)
    } else {
      body = Text(cleaned)
    }
    return body
      .lineSpacing(2)
      .frame(maxWidth: .infinity, alignment: .leading)
      .fixedSize(horizontal: false, vertical: true)
  }

  private static func heading(_ line: String) -> (level: Int, text: String)? {
    var level = 0
    for character in line {
      if character == "#" {
        level += 1
      } else {
        break
      }
    }
    guard (1...6).contains(level) else { return nil }
    let rest = line.dropFirst(level)
    guard rest.first == " " else { return nil }
    let text = rest.dropFirst().trimmingCharacters(in: .whitespaces)
    guard !text.isEmpty else { return nil }
    return (level, text)
  }

  private static func listItem(_ line: String) -> (kind: Block.Kind, body: String)? {
    var digits = ""
    var cursor = line.startIndex
    while cursor < line.endIndex, line[cursor].isNumber {
      digits.append(line[cursor])
      cursor = line.index(after: cursor)
    }
    if !digits.isEmpty, cursor < line.endIndex, line[cursor] == "." || line[cursor] == ")" {
      let afterMark = line.index(after: cursor)
      if afterMark < line.endIndex, line[afterMark] == " " || line[afterMark] == "\t" {
        let body = line[line.index(after: afterMark)...].trimmingCharacters(in: .whitespaces)
        if !body.isEmpty { return (.numbered(digits), body) }
      }
    }
    if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
      let body = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
      if !body.isEmpty { return (.bullet, body) }
    }
    return nil
  }
}

private extension View {
  /// Dark shadow so light text stays readable on a photo.
  func legible() -> some View {
    shadow(color: .black.opacity(0.9), radius: 1.5, y: 1)
      .shadow(color: .black.opacity(0.7), radius: 8)
  }

  /// Glass in a fixed circle. The glass button style grows into a pill on watchOS.
  @ViewBuilder
  func watchGlassCircle(diameter: CGFloat) -> some View {
    if #available(watchOS 26.0, *) {
      self
        .buttonStyle(.plain)
        .frame(width: diameter, height: diameter)
        .glassEffect(.regular, in: Circle())
    } else {
      self
        .buttonStyle(.plain)
        .frame(width: diameter, height: diameter)
        .background { Circle().fill(.ultraThinMaterial) }
    }
  }

  @ViewBuilder
  func watchGlassCapsule() -> some View {
    if #available(watchOS 26.0, *) {
      self.glassEffect(.regular, in: Capsule())
    } else {
      self
        .background { Capsule().fill(.ultraThinMaterial) }
        .clipShape(Capsule())
    }
  }

  /// True while the composer row is still on screen, so a streaming reply
  /// does not pull the thread back down after the reader has scrolled up.
  @ViewBuilder
  func watchFollowLatest(_ follow: Binding<Bool>) -> some View {
    if #available(watchOS 11.0, *) {
      onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentSize.height <= geometry.containerSize.height + 1
          || geometry.visibleRect.maxY >= geometry.contentSize.height - 48
      } action: { _, near in
        follow.wrappedValue = near
      }
    } else {
      self
    }
  }
}

