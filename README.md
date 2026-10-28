# LM Mini

<p>
  <a href="https://apps.apple.com/app/lm-mini/id6751125309"><img alt="Download on the App Store" src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" width="162"></a>
  &nbsp;
  <a href="https://play.google.com/store/apps/details?id=net.neuro9.lmmini"><img alt="Get it on Google Play" src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" width="182"></a>
</p>

[![Website](https://img.shields.io/badge/Website-lmmini.com-7C4DFF)](https://lmmini.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

**[Website](https://lmmini.com)** ·
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

## What's in this repo

Everything below is free and builds from this tree.

**Chat with your own models**
- LM Studio, Ollama, oMLX, Jan, Unsloth and other OpenAI-compatible servers on your network
- Finds LM Studio on your Wi-Fi automatically
- USB mode: chat with your Mac over a cable, no network needed
- Custom headers and Cloudflare Access for servers behind a proxy
- API keys and tokens kept in the Keychain (iOS) and Keystore (Android)
- Clear connection status: offline, mobile data and unreachable-server messages, with tap-to-retry for unsent messages

**On-device AI**
- Six starter GGUF models (Qwen 3.5, Gemma 4, Bonsai 1-bit, LFM 2.5, MiniCPM 5) plus one imported GGUF (llama.cpp)
- Apple Intelligence on supported devices (iOS 26 / macOS 26), no download

**Conversations**
- Personas, including SillyTavern character card import (PNG, JSON, CHARX)
- Folders, themes, image and file attachments, and vision models
- Thinking / reasoning controls and global model parameters
- iCloud sync
- Export to PDF (Latin, Greek and Cyrillic), TXT and ZIP

**Tools**
- SearXNG web search
- MCP servers (LM Studio integrations and your own MCP URLs)

**Voice**
- Speech-to-text with Whisper
- System voices, plus on-device Kokoro (English, Spanish, French, Chinese) and Piper (German, Russian) voices
- Hands-free voice conversation

**Image generation**
- AUTOMATIC1111 and ComfyUI
- On-device Stable Diffusion with the starter model

**Everywhere you are**
- iPhone, iPad, Android, Mac and Windows
- Apple Watch companion
- Home-screen widgets
- Siri and Apple Shortcuts, including your LM Studio MCP tools
- Arena: race models on built-in prompts or your own, compare answers side by side, and keep a history of your races

**Languages:** English, German, Spanish, French, Russian and Chinese.

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

## Special thanks

- [@illava](https://github.com/illava) for reviewing and polishing the
  Chinese translation ([#1](https://github.com/slim-elephant/lm-mini/pull/1)).
