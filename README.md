# LM Mini (open-source build)

[![App Store](https://img.shields.io/badge/App_Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/app/lm-mini/id6751125309)
[![Google Play](https://img.shields.io/badge/Google_Play-Download-414141?logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=net.neuro9.lmmini)
[![Website](https://img.shields.io/badge/Website-lmmini.com-7C4DFF)](https://lmmini.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

**[Website](https://lmmini.com)** ·
[App Store (iPhone, iPad, Mac)](https://apps.apple.com/app/lm-mini/id6751125309) ·
[Google Play](https://play.google.com/store/apps/details?id=net.neuro9.lmmini) ·
[Desktop downloads](https://lmmini.com/download.html) ·
[Docs](https://lmmini.com/docs.html)

Chat with local and on-device AI from your phone, tablet, watch or desktop.

LM Mini is a Flutter chat client for LM Studio, Ollama, oMLX, Jan, Unsloth and
other OpenAI-compatible servers, plus on-device models (llama.cpp and MLX).
It runs on iOS, iPadOS, Android, macOS and Windows, with an Apple Watch
companion.

## Open core

This repository is an exported snapshot of the [LM Mini](https://lmmini.com)
app source. The free features are complete here and build from this tree.

LM Mini Pro implementations are not in this repository:

- `lib/pro/` holds public stubs (line 1 of each file is
  `// LM-MINI-PRO-STUB`). They keep the signatures the app calls and do
  nothing else. `ProFeatures.included` is `false` in this build.
- `packages/premium_stub/` is the no-op entitlement API (`isPremium` is always
  `false`).

So Pro entry points and upgrade prompts are hidden in this build. Pro is
available in the official LM Mini app:

- App Store: https://apps.apple.com/app/lm-mini/id6751125309
- Google Play: https://play.google.com/store/apps/details?id=net.neuro9.lmmini

More about the open-source build: https://lmmini.com/open-source.html

| Open source (this repo) | Pro (official app only) |
| --- | --- |
| Chat with LM Studio, Ollama, oMLX, Jan and Unsloth over your LAN | Pro Search and URL reader |
| On-device models: the free catalog slot plus one imported GGUF | Code Sandbox |
| Personas | Memory |
| Image generation: ComfyUI, AUTOMATIC1111, on-device Stable Diffusion (free slot) | Group Chat |
| Voice: system TTS, Kokoro, Whisper speech-to-text | Remote Access and Home sync |
| SearXNG web search and MCP tools | Cloud Backup |
| Arena "find your model" | Analytics |
| Widgets and Siri Shortcuts | App Lock |
| Apple Watch companion | Compact and Branching |
| Desktop apps with USB mode | Arena history |
| iCloud sync | Model and persona parameter presets, Context Fit |
| PDF, TXT and ZIP export | ElevenLabs and Grok voices |
| | News widget and Live Activity |
| | MLX folder import and Hugging Face on-device downloads |
| | The full on-device model catalog |
| | Paid cloud providers |
| | Markdown, JSON and Obsidian export |

## Build

You need the Flutter SDK (stable channel).

1. Firebase configuration. The app expects Firebase config files, which are
   not in the repository. Copy the placeholders, or run
   `flutterfire configure` against your own Firebase project (sign-in, sync
   and feedback only work with a real project):

   ```bash
   cp lib/firebase_options.example.dart lib/firebase_options.dart
   # iOS and macOS (the Xcode projects reference these files)
   cp ios/Runner/GoogleService-Info.example.plist ios/Runner/GoogleService-Info.plist
   cp macos/Runner/GoogleService-Info.example.plist macos/Runner/GoogleService-Info.plist
   # Android (optional: the Google Services plugin is applied only when
   # android/app/google-services.json exists)
   cp android/app/google-services.example.json android/app/google-services.json
   ```

   Google Sign-In is optional. To use it with your own project, replace the
   placeholder `GIDClientID` and the two `CFBundleURLSchemes` entries
   (`com.googleusercontent.apps.…` and `app-1-…`) in `ios/Runner/Info.plist`
   with the values from your `GoogleService-Info.plist`, and pass your web
   client ID on Android with
   `--dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=<id>.apps.googleusercontent.com`.

2. Fetch packages and check the tree:

   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```

3. Run it: `flutter run` (pick a device with `-d`).

   Native builds without running:

   ```bash
   # Android: works with or without android/app/google-services.json
   flutter build apk --debug
   # iOS Simulator: the Apple Watch companion target makes Flutter require a
   # simulator id (list them with `flutter devices` or
   # `xcrun simctl list devices available`)
   flutter build ios --simulator --debug --no-codesign -d <simulator-id>
   ```

   The first iOS or macOS build runs `pod install`, which can take several
   minutes. Device and macOS builds are signed: in Xcode, set the Runner
   (and, for iOS, the watch) targets to your own team and bundle identifier.

4. macOS desktop runtime (optional). The vendored llama.cpp server binaries
   are not in the repository; fetch them with:

   ```bash
   ./macos/scripts/vendor_llama_server.sh
   ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Coding agents: see
[AGENTS.md](AGENTS.md). Release notes: [CHANGELOG.md](CHANGELOG.md).
Privacy policy: [privacy_policy.html](privacy_policy.html).

## License

The code is MIT licensed, see [LICENSE](LICENSE). The LM Mini name and app
icon are not covered by that license, see [TRADEMARK.md](TRADEMARK.md).
