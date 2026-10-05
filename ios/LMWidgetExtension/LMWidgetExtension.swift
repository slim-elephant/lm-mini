//
//  LMWidgetExtension.swift
//  LMWidgetExtension
//
//  Control Center widgets for LM Mini
//

import WidgetKit
import SwiftUI
import AppIntents

let sharedDefaults = UserDefaults(suiteName: "group.net.neuro9.lmmini")

// MARK: - App Intents with URL Opening (iOS 18+)

@available(iOS 18.0, *)
struct NewChatIntent: AppIntent {
    static var title: LocalizedStringResource = "New Chat"
    static var description = IntentDescription("Start a new AI chat conversation")
    
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "lmmini://newchat")!))
    }
}

@available(iOS 18.0, *)
struct CameraChatIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Camera"
    static var description = IntentDescription("Take a photo and chat about it")
    
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "lmmini://camera")!))
    }
}

// MARK: - Control Center Widgets (iOS 18+)

@available(iOS 18.0, *)
struct NewChatControl: ControlWidget {
    static let kind: String = "NewChatControl"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: NewChatIntent()) {
                Label("New Chat", systemImage: "plus.message.fill")
            }
        }
        .displayName("New Chat")
        .description("Start a new AI chat")
    }
}

@available(iOS 18.0, *)
struct CameraChatControl: ControlWidget {
    static let kind: String = "CameraChatControl"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: CameraChatIntent()) {
                Label("Quick Camera", systemImage: "camera.fill")
            }
        }
        .displayName("Quick Camera")
        .description("Take a photo and chat about it")
    }
}

// MARK: - Home Screen Widget

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Persona: Codable, Identifiable {
    let id: String
    let name: String
    let color: String?
}

// MARK: - Widget Views

struct LMWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    func getPersonas() -> [Persona] {
        guard let jsonString = sharedDefaults?.string(forKey: "personas_json"),
              let jsonData = jsonString.data(using: .utf8) else {
            return []
        }
        do {
            let personasDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] ?? []
            return personasDict.compactMap { dict in
                if let id = dict["id"] as? String, let name = dict["name"] as? String {
                    return Persona(id: id, name: name, color: dict["color"] as? String)
                }
                return nil
            }
        } catch {
            return []
        }
    }

    func color(from hex: String?) -> Color {
        guard let hex = hex else { return .purple }
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return .purple
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return Color(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0
        )
    }

    var body: some View {
        if family == .systemMedium {
            // Stats Layout for Medium Widget
            let msgCount = sharedDefaults?.integer(forKey: "total_messages") ?? 0
            let inTokens = sharedDefaults?.integer(forKey: "total_tokens_in") ?? 0
            let outTokens = sharedDefaults?.integer(forKey: "total_tokens_out") ?? 0
            let isPremium = sharedDefaults?.bool(forKey: "is_premium") ?? false

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "chart.bar.fill").foregroundColor(.purple)
                        Text("App Stats").font(.headline)
                        if isPremium {
                            Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 10))
                        }
                    }
                    Divider()
                    Text("Messages: \(msgCount)").font(.caption).bold()
                    Text("Tokens In: \(inTokens / 1000)k").font(.caption).foregroundColor(.secondary)
                    Text("Tokens Out: \(outTokens / 1000)k").font(.caption).foregroundColor(.secondary)
                }
                .padding(.all, 8)
                Spacer()
                Link(destination: URL(string: "lmmini://newchat")!) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        } else if family == .systemLarge {
            let personas = getPersonas()
            VStack {
                Text("Personas")
                    .font(.headline)
                    .padding(.top, 8)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(personas.prefix(4))) { persona in
                        Link(destination: URL(string: "lmmini://chat?persona=\(persona.id)")!) {
                            VStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(color(from: persona.color))
                                Text(persona.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                Spacer()
            }
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            // Small Widget - Personas / Default
            Link(destination: URL(string: "lmmini://newchat")!) {
                VStack(spacing: 8) {
                    let promptLabel = sharedDefaults?.string(forKey: "automated_prompt") ?? "Tap to chat"
                    Image(systemName: "message.fill")
                        .font(.system(size: family == .systemSmall ? 28 : 36))
                        .foregroundColor(.purple)
                    Text("LM Mini")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(promptLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct LMWidget: Widget {
    let kind: String = "LMWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LMWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LM Mini")
        .description("Quick access to AI chat")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct LMWidgetBundle: WidgetBundle {
    var body: some Widget {
        LMWidget()
        PersonasWidget()
        TopFoldersWidget()
        RecentConversationsWidget()
        if #available(iOS 18.0, *) {
            NewChatControl()
            CameraChatControl()
        }
        if #available(iOS 16.2, *) {
            LMChatLiveActivity()
            LMDownloadLiveActivity()
        }
    }
}

// MARK: - Shared helpers for home widgets

fileprivate func lmColor(from hex: String?) -> Color {
    guard let hex = hex else { return .purple }
    var c = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if c.hasPrefix("#") { c.remove(at: c.startIndex) }
    guard c.count == 6 else { return .purple }
    var rgb: UInt64 = 0
    Scanner(string: c).scanHexInt64(&rgb)
    return Color(
        red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgb & 0x0000FF) / 255.0
    )
}

fileprivate func lmRelative(from ms: Int?) -> String {
    guard let ms = ms, ms > 0 else { return "" }
    let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
    let seconds = Int(Date().timeIntervalSince(date))
    if seconds < 60 { return "just now" }
    if seconds < 3600 { return "\(seconds / 60)m ago" }
    if seconds < 86_400 { return "\(seconds / 3600)h ago" }
    return "\(seconds / 86_400)d ago"
}

// MARK: - News Widget (Pro)

struct NewsEntry: TimelineEntry {
    let date: Date
    let title: String
    let body: String
    let generatedAt: Int
    let isPremium: Bool
    let hasPrompt: Bool
}

struct NewsProvider: TimelineProvider {
    func placeholder(in context: Context) -> NewsEntry {
        NewsEntry(date: Date(), title: "Your daily brief", body: "Set a prompt in LM Mini to see fresh content here.", generatedAt: 0, isPremium: true, hasPrompt: true)
    }
    func getSnapshot(in context: Context, completion: @escaping (NewsEntry) -> Void) {
        completion(currentEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsEntry>) -> Void) {
        let entry = currentEntry()
        // Re-render hourly so the relative timestamp stays fresh.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func currentEntry() -> NewsEntry {
        let title = sharedDefaults?.string(forKey: "news_title") ?? ""
        let body = sharedDefaults?.string(forKey: "news_content") ?? ""
        let generatedAt = sharedDefaults?.integer(forKey: "news_generated_at") ?? 0
        let isPremium = sharedDefaults?.bool(forKey: "is_premium") ?? false
        let prompt = sharedDefaults?.string(forKey: "news_prompt") ?? ""
        return NewsEntry(date: Date(), title: title, body: body, generatedAt: generatedAt, isPremium: isPremium, hasPrompt: !prompt.isEmpty)
    }
}

/// Pulls numbered article headlines from the stored briefing body
/// (e.g. `1. Title…` lines). Returns bare titles (no numbers) so the UI
/// can renumber 1…n. Skips summaries and `Source:` / URL lines.
fileprivate func newsHeadlines(from body: String, limit: Int) -> [String] {
    var out: [String] = []
    let pattern = try? NSRegularExpression(
        pattern: #"^\s*(\d+)\.\s+(.+?)\s*$"#,
        options: []
    )
    for raw in body.components(separatedBy: .newlines) {
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty { continue }
        let lower = line.lowercased()
        if lower.hasPrefix("source:") { continue }
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") { continue }
        guard let pattern else { continue }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = pattern.firstMatch(in: line, options: [], range: range),
              match.numberOfRanges >= 3,
              let titleRange = Range(match.range(at: 2), in: line)
        else { continue }
        var title = String(line[titleRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if title.count > 72 {
            title = String(title.prefix(71)).trimmingCharacters(in: .whitespaces) + "…"
        }
        out.append(title)
        if out.count >= limit { break }
    }
    return out
}

/// If `title` was mistakenly saved as `1. Headline`, recover that headline.
fileprivate func newsTitleAsHeadline(_ title: String) -> String? {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let regex = try? NSRegularExpression(pattern: #"^\s*\d+\.\s+(.+?)\s*$"#),
          let match = regex.firstMatch(
            in: t,
            options: [],
            range: NSRange(t.startIndex..<t.endIndex, in: t)
          ),
          match.numberOfRanges >= 2,
          let r = Range(match.range(at: 1), in: t)
    else { return nil }
    return String(t[r]).trimmingCharacters(in: .whitespacesAndNewlines)
}

struct NewsWidgetEntryView: View {
    var entry: NewsEntry
    @Environment(\.widgetFamily) var family

    private var headlineLimit: Int {
        family == .systemSmall ? 4 : 5
    }

    private var headlines: [String] {
        var fromBody = newsHeadlines(from: entry.body, limit: headlineLimit)
        // Recover item 1 when an older save put "1. …" into news_title.
        if let recovered = newsTitleAsHeadline(entry.title) {
            let already = fromBody.contains {
                $0.caseInsensitiveCompare(recovered) == .orderedSame
            }
            if !already {
                fromBody.insert(recovered, at: 0)
            }
        }
        if !fromBody.isEmpty {
            return Array(fromBody.prefix(headlineLimit))
        }
        let t = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? [] : [t]
    }

    var body: some View {
        Link(destination: URL(string: "lmmini://news")!) {
            Group {
                if !entry.isPremium {
                    VStack(alignment: .leading, spacing: 6) {
                        newsHeader
                        Spacer(minLength: 0)
                        Label("Pro feature", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Upgrade in LM Mini for AI briefings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        Spacer(minLength: 0)
                    }
                } else if !entry.hasPrompt {
                    VStack(alignment: .leading, spacing: 6) {
                        newsHeader
                        Spacer(minLength: 0)
                        Text("Tap to set up")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Add a prompt in Widget settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        Spacer(minLength: 0)
                    }
                } else if headlines.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        newsHeader
                        Spacer(minLength: 0)
                        Text("Refreshing…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        newsHeader
                        ForEach(Array(headlines.enumerated()), id: \.offset) { idx, title in
                            HStack(alignment: .center, spacing: 6) {
                                Text("\(idx + 1)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 15, height: 15)
                                    .background(
                                        Circle().fill(Color.accentColor.opacity(0.9))
                                    )
                                Text(title)
                                    .font(.system(
                                        size: family == .systemSmall ? 11 : 12,
                                        weight: .medium
                                    ))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        Spacer(minLength: 0)
                        if entry.generatedAt > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 8))
                                Text(lmRelative(from: entry.generatedAt))
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.vertical, 2)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var newsHeader: some View {
        HStack(spacing: 6) {
            Image("LMLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text("LM Mini")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Image(systemName: "newspaper.fill")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 2)
    }
}

struct NewsWidget: Widget {
    let kind: String = "NewsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewsProvider()) { entry in
            NewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LM News (Pro)")
        .description("AI-generated briefing using your custom prompt.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Personas Widget

struct PersonasEntry: TimelineEntry {
    let date: Date
    let personas: [Persona]
}

struct PersonasProvider: TimelineProvider {
    private func load() -> [Persona] {
        guard let jsonString = sharedDefaults?.string(forKey: "personas_json"),
              let data = jsonString.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return arr.compactMap { dict in
            guard let id = dict["id"] as? String, let name = dict["name"] as? String else { return nil }
            return Persona(id: id, name: name, color: dict["color"] as? String)
        }
    }
    func placeholder(in context: Context) -> PersonasEntry {
        PersonasEntry(date: Date(), personas: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (PersonasEntry) -> Void) {
        completion(PersonasEntry(date: Date(), personas: load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PersonasEntry>) -> Void) {
        let entry = PersonasEntry(date: Date(), personas: load())
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21_600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct PersonasWidgetEntryView: View {
    var entry: PersonasEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").foregroundColor(.purple)
                Text("Start a chat").font(.headline)
                Spacer()
            }
            Divider()
            if entry.personas.isEmpty {
                Spacer()
                Link(destination: URL(string: "lmmini://newchat")!) {
                    Text("Create a persona in LM Mini to see it here.")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(Array(entry.personas.prefix(6))) { persona in
                        Link(destination: URL(string: "lmmini://chat?persona=\(persona.id)")!) {
                            VStack(spacing: 4) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(lmColor(from: persona.color))
                                Text(persona.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(lmColor(from: persona.color).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct PersonasWidget: Widget {
    let kind: String = "PersonasWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PersonasProvider()) { entry in
            PersonasWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Personas")
        .description("Quick access to your saved personas.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Top Folders Widget

struct FolderItem: Codable, Identifiable {
    let id: String
    let name: String
    let count: Int
    let color: String?
}

struct FoldersEntry: TimelineEntry {
    let date: Date
    let folders: [FolderItem]
}

struct FoldersProvider: TimelineProvider {
    private func load() -> [FolderItem] {
        guard let jsonString = sharedDefaults?.string(forKey: "folders_json"),
              let data = jsonString.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return arr.compactMap { dict in
            guard let id = dict["id"] as? String, let name = dict["name"] as? String else { return nil }
            let count = (dict["count"] as? Int) ?? 0
            return FolderItem(id: id, name: name, count: count, color: dict["color"] as? String)
        }
    }
    func placeholder(in context: Context) -> FoldersEntry {
        FoldersEntry(date: Date(), folders: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (FoldersEntry) -> Void) {
        completion(FoldersEntry(date: Date(), folders: load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FoldersEntry>) -> Void) {
        let entry = FoldersEntry(date: Date(), folders: load())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct TopFoldersEntryView: View {
    var entry: FoldersEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill").foregroundColor(.blue)
                Text("Folders").font(.headline)
                Spacer()
            }
            Divider()
            if entry.folders.isEmpty {
                Spacer()
                Text("Organize chats into folders to see them here.")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(entry.folders.prefix(4))) { folder in
                        Link(destination: URL(string: "lmmini://folder?id=\(folder.id)")!) {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(lmColor(from: folder.color))
                                    .frame(width: 4, height: 22)
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(lmColor(from: folder.color))
                                Text(folder.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(folder.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .monospacedDigit()
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct TopFoldersWidget: Widget {
    let kind: String = "TopFoldersWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FoldersProvider()) { entry in
            TopFoldersEntryView(entry: entry)
        }
        .configurationDisplayName("Top Folders")
        .description("Your most-used chat folders.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Recent Conversations Widget

struct ConversationItem: Codable, Identifiable {
    let id: String
    let title: String
    let updatedAt: Int
}

struct RecentsEntry: TimelineEntry {
    let date: Date
    let conversations: [ConversationItem]
}

struct RecentsProvider: TimelineProvider {
    private func load() -> [ConversationItem] {
        guard let jsonString = sharedDefaults?.string(forKey: "recent_conversations_json"),
              let data = jsonString.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return arr.compactMap { dict in
            guard let id = dict["id"] as? String, let title = dict["title"] as? String else { return nil }
            let updatedAt = (dict["updatedAt"] as? Int) ?? 0
            return ConversationItem(id: id, title: title, updatedAt: updatedAt)
        }
    }
    func placeholder(in context: Context) -> RecentsEntry {
        RecentsEntry(date: Date(), conversations: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (RecentsEntry) -> Void) {
        completion(RecentsEntry(date: Date(), conversations: load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentsEntry>) -> Void) {
        let entry = RecentsEntry(date: Date(), conversations: load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct RecentConversationsEntryView: View {
    var entry: RecentsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill").foregroundColor(.green)
                Text("Recent Chats").font(.headline)
                Spacer()
                Link(destination: URL(string: "lmmini://newchat")!) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                }
            }
            Divider()
            if entry.conversations.isEmpty {
                Spacer()
                Text("Your recent chats will appear here.")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(entry.conversations.prefix(3))) { convo in
                        Link(destination: URL(string: "lmmini://chat?id=\(convo.id)")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(convo.title.isEmpty ? "Untitled" : convo.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(lmRelative(from: convo.updatedAt))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct RecentConversationsWidget: Widget {
    let kind: String = "RecentConversationsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentsProvider()) { entry in
            RecentConversationsEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Chats")
        .description("Jump back into your latest conversations.")
        .supportedFamilies([.systemMedium])
    }
}
