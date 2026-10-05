// LMMiniAppIntents.swift
//
// App Intents (iOS 16+) that expose LM Mini to Shortcuts, Siri, the Action
// Button, and Spotlight.
//
// Ask / Summarize / Translate / Search / News wait for a string and return
// `ProvidesDialog` so Siri speaks the answer (iOS 16 IntentDialog, iOS 26
// full/supporting). Background native HTTP is attempted first when the
// saved snapshot is a LAN LM Studio or cloud URL; otherwise the intent
// continues in the foreground and Dart posts the answer through the App Group.

import AppIntents
import Foundation

@available(iOS 16.0, *)
private enum LMMiniSiriIntentSupport {
  static var opensAppLegacy: Bool {
    if #available(iOS 16.4, *) { return false }
    return true
  }

  @available(iOS 26.0, *)
  static var dynamicModes: IntentModes {
    [.background, .foreground(.dynamic)]
  }
}

@available(iOS 16.4, *)
private extension ForegroundContinuableIntent {
  func lmMiniRequestForeground() async throws {
    if #available(iOS 26.0, *) {
      try await continueInForeground(alwaysConfirm: false)
      return
    }
    throw needsToContinueInForegroundError(
      "Opening LM Mini to finish your request."
    )
  }
}

// MARK: - Ask LM Mini

@available(iOS 16.0, *)
struct AskLMMiniIntent: AppIntent {
  static var title: LocalizedStringResource = "Ask LM Mini"
  static var description = IntentDescription(
    "Send a one-shot prompt to your active LM Mini model and get a spoken answer.",
    categoryName: "Conversation"
  )
  static var openAppWhenRun: Bool { LMMiniSiriIntentSupport.opensAppLegacy }

  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { LMMiniSiriIntentSupport.dynamicModes }

  @Parameter(
    title: "Prompt",
    description: "What you want to ask.",
    requestValueDialog: IntentDialog("What should I ask your model?")
  )
  var prompt: String

  @Parameter(
    title: "Use on-device model",
    description: "Force the downloaded on-device model even if a cloud provider is currently selected.",
    default: false
  )
  var useOnDevice: Bool

  @Parameter(
    title: "Speak answer aloud",
    description: "Also read the response with LM Mini's voice after the answer is ready. Usually leave this off.",
    default: false
  )
  var speakAloud: Bool

  static var parameterSummary: some ParameterSummary {
    Summary("Ask LM Mini \(\.$prompt), on-device: \(\.$useOnDevice), speak: \(\.$speakAloud)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let answer = try await LMMiniSiriRun.execute(
      path: "/ask",
      query: [
        "prompt": prompt,
        "onDevice": useOnDevice ? "1" : "0",
        "speak": speakAloud ? "1" : "0",
      ],
      nativeSystem: "You are a helpful assistant. Reply concisely.",
      nativeUser: prompt,
      allowNative: !useOnDevice,
      requestForeground: {
        if #available(iOS 16.4, *) {
          try await self.lmMiniRequestForeground()
        }
      }
    )
    return .result(value: answer, dialog: LMMiniSiriDialog.make(answer))
  }
}

@available(iOS 16.4, *)
extension AskLMMiniIntent: ForegroundContinuableIntent {}

// MARK: - Summarize

@available(iOS 16.0, *)
enum LMMiniSummaryStyle: String, AppEnum {
  case bullets
  case paragraph
  case tweet

  static var typeDisplayRepresentation: TypeDisplayRepresentation =
    "Summary Style"
  static var caseDisplayRepresentations: [LMMiniSummaryStyle: DisplayRepresentation] = [
    .bullets:   "Bullet points",
    .paragraph: "Single paragraph",
    .tweet:     "Tweet (≤240 chars)",
  ]

  var systemInstruction: String {
    switch self {
    case .paragraph: return "as a single tight paragraph (~3 sentences)"
    case .tweet: return "as one tweet under 240 characters"
    case .bullets: return "as 3–5 short bullet points"
    }
  }
}

@available(iOS 16.0, *)
struct SummarizeWithLMMiniIntent: AppIntent {
  static var title: LocalizedStringResource = "Summarize with LM Mini"
  static var description = IntentDescription(
    "Summarize any text using your active LM Mini model and get a spoken summary.",
    categoryName: "Conversation"
  )
  static var openAppWhenRun: Bool { LMMiniSiriIntentSupport.opensAppLegacy }

  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { LMMiniSiriIntentSupport.dynamicModes }

  @Parameter(title: "Text")
  var text: String

  @Parameter(title: "Style", default: .bullets)
  var style: LMMiniSummaryStyle

  static var parameterSummary: some ParameterSummary {
    Summary("Summarize \(\.$text) as \(\.$style)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let system = "You are an expert summarizer. Summarize the user's text "
      + "\(style.systemInstruction). Use plain language. Do not add commentary."
    let answer = try await LMMiniSiriRun.execute(
      path: "/summarize",
      query: [
        "text": text,
        "style": style.rawValue,
      ],
      nativeSystem: system,
      nativeUser: text,
      allowNative: true,
      requestForeground: {
        if #available(iOS 16.4, *) {
          try await self.lmMiniRequestForeground()
        }
      }
    )
    return .result(value: answer, dialog: LMMiniSiriDialog.make(answer))
  }
}

@available(iOS 16.4, *)
extension SummarizeWithLMMiniIntent: ForegroundContinuableIntent {}

// MARK: - Translate

@available(iOS 16.0, *)
struct TranslateWithLMMiniIntent: AppIntent {
  static var title: LocalizedStringResource = "Translate with LM Mini"
  static var description = IntentDescription(
    "Translate text into any language using your active LM Mini model and get a spoken translation.",
    categoryName: "Conversation"
  )
  static var openAppWhenRun: Bool { LMMiniSiriIntentSupport.opensAppLegacy }

  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { LMMiniSiriIntentSupport.dynamicModes }

  @Parameter(title: "Text")
  var text: String

  @Parameter(
    title: "Target language",
    description: "Free-form: 'Spanish', 'Brazilian Portuguese', 'Hindi', etc."
  )
  var targetLanguage: String

  static var parameterSummary: some ParameterSummary {
    Summary("Translate \(\.$text) to \(\.$targetLanguage)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let system = "You are a professional translator. Translate the user's "
      + "text into \(targetLanguage). Output ONLY the translation — no notes, no "
      + "quotation marks, no explanations."
    let answer = try await LMMiniSiriRun.execute(
      path: "/translate",
      query: [
        "text": text,
        "to": targetLanguage,
      ],
      nativeSystem: system,
      nativeUser: text,
      allowNative: true,
      requestForeground: {
        if #available(iOS 16.4, *) {
          try await self.lmMiniRequestForeground()
        }
      }
    )
    return .result(value: answer, dialog: LMMiniSiriDialog.make(answer))
  }
}

@available(iOS 16.4, *)
extension TranslateWithLMMiniIntent: ForegroundContinuableIntent {}

// MARK: - Web search

@available(iOS 16.0, *)
struct SearchWithLMMiniIntent: AppIntent {
  static var title: LocalizedStringResource = "Search with LM Mini"
  static var description = IntentDescription(
    "Search the web using your active LM Mini provider and get a spoken answer.",
    categoryName: "Conversation"
  )
  static var openAppWhenRun: Bool { LMMiniSiriIntentSupport.opensAppLegacy }

  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { LMMiniSiriIntentSupport.dynamicModes }

  @Parameter(
    title: "Query",
    description: "What to search for.",
    requestValueDialog: IntentDialog("What should I search for?")
  )
  var query: String

  @Parameter(
    title: "Speak answer aloud",
    description: "Also read the response with LM Mini's voice. Usually leave this off — the system already speaks the answer.",
    default: false
  )
  var speakAloud: Bool

  static var parameterSummary: some ParameterSummary {
    Summary("Search the web for \(\.$query), speak: \(\.$speakAloud)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let answer = try await LMMiniSiriRun.execute(
      path: "/search",
      query: [
        "query": query,
        "speak": speakAloud ? "1" : "0",
      ],
      nativeSystem: nil,
      nativeUser: nil,
      allowNative: false,
      requestForeground: {
        if #available(iOS 16.4, *) {
          try await self.lmMiniRequestForeground()
        }
      }
    )
    return .result(value: answer, dialog: LMMiniSiriDialog.make(answer))
  }
}

@available(iOS 16.4, *)
extension SearchWithLMMiniIntent: ForegroundContinuableIntent {}

// MARK: - Voice chat

@available(iOS 16.0, *)
struct StartVoiceChatIntent: AppIntent {
  static var title: LocalizedStringResource = "Start Voice Chat"
  static var description = IntentDescription(
    "Open LM Mini in hands-free voice conversation mode.",
    categoryName: "Conversation"
  )
  static var openAppWhenRun: Bool = true

  @Parameter(
    title: "First message",
    description: "Optional — send this as your first message when voice mode opens.",
    default: ""
  )
  var prompt: String

  @Parameter(
    title: "Use on-device model",
    description: "Force the downloaded on-device model for this session.",
    default: false
  )
  var useOnDevice: Bool

  @Parameter(
    title: "Persona ID",
    description: "Optional persona id from Settings → Personas.",
    default: ""
  )
  var personaId: String

  @Parameter(
    title: "Conversation ID",
    description: "Optional — resume an existing chat in voice mode.",
    default: ""
  )
  var conversationId: String

  static var parameterSummary: some ParameterSummary {
    Summary("Voice chat with LM Mini, on-device: \(\.$useOnDevice)")
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    var query: [String: String] = [
      "onDevice": useOnDevice ? "1" : "0",
    ]
    if !prompt.isEmpty { query["prompt"] = prompt }
    if !personaId.isEmpty { query["persona"] = personaId }
    if !conversationId.isEmpty { query["conversationId"] = conversationId }
    LMMiniSiriStore.queueShortcut(path: "/voice", query: query)
    return .result()
  }
}

// MARK: - News brief (Pro)

@available(iOS 16.0, *)
struct GenerateNewsBriefIntent: AppIntent {
  static var title: LocalizedStringResource = "Generate News Brief"
  static var description = IntentDescription(
    "Refresh the LM Mini news widget with a fresh briefing. Requires LM Mini Pro. The brief is read aloud.",
    categoryName: "Content"
  )
  static var openAppWhenRun: Bool { LMMiniSiriIntentSupport.opensAppLegacy }

  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { LMMiniSiriIntentSupport.dynamicModes }

  @Parameter(
    title: "Topics",
    description: "Comma-separated: 'AI, science, baseball'.",
    default: ""
  )
  var topics: String

  static var parameterSummary: some ParameterSummary {
    Summary("Brief me on \(\.$topics)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let answer = try await LMMiniSiriRun.execute(
      path: "/news",
      query: [
        "topics": topics,
      ],
      nativeSystem: nil,
      nativeUser: nil,
      allowNative: false,
      requestForeground: {
        if #available(iOS 16.4, *) {
          try await self.lmMiniRequestForeground()
        }
      }
    )
    return .result(value: answer, dialog: LMMiniSiriDialog.make(answer))
  }
}

@available(iOS 16.4, *)
extension GenerateNewsBriefIntent: ForegroundContinuableIntent {}

// MARK: - Siri phrases + Shortcuts app discovery

@available(iOS 16.0, *)
struct LMMiniAppShortcuts: AppShortcutsProvider {
  static var shortcutTileColor: ShortcutTileColor = .lightBlue

  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AskLMMiniIntent(),
      phrases: [
        "Ask \(.applicationName)",
        "Ask my \(.applicationName) model",
        "Send a prompt to \(.applicationName)",
      ],
      shortTitle: "Ask LM Mini",
      systemImageName: "bubble.left.and.text.bubble.right"
    )
    AppShortcut(
      intent: StartVoiceChatIntent(),
      phrases: [
        "Talk to \(.applicationName)",
        "Voice chat with \(.applicationName)",
        "Start a voice call with \(.applicationName)",
      ],
      shortTitle: "Voice Chat",
      systemImageName: "mic.fill"
    )
    AppShortcut(
      intent: SearchWithLMMiniIntent(),
      phrases: [
        "Search with \(.applicationName)",
        "Search the web with \(.applicationName)",
        "Look up with \(.applicationName)",
      ],
      shortTitle: "Search",
      systemImageName: "magnifyingglass"
    )
    AppShortcut(
      intent: SummarizeWithLMMiniIntent(),
      phrases: [
        "Summarize with \(.applicationName)",
        "Have \(.applicationName) summarize this",
      ],
      shortTitle: "Summarize",
      systemImageName: "text.alignleft"
    )
    AppShortcut(
      intent: TranslateWithLMMiniIntent(),
      phrases: [
        "Translate with \(.applicationName)",
        "Have \(.applicationName) translate this",
      ],
      shortTitle: "Translate",
      systemImageName: "character.book.closed"
    )
    AppShortcut(
      intent: GenerateNewsBriefIntent(),
      phrases: [
        "Brief me with \(.applicationName)",
        "Refresh \(.applicationName) news",
      ],
      shortTitle: "News Brief",
      systemImageName: "newspaper"
    )
  }
}
