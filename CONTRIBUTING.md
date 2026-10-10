# Contributing to LM Mini

Thanks for helping. This repository is an exported snapshot of the LM Mini
app source. The free features are complete here. LM Mini Pro implementations
are not included: `lib/pro/` holds public stubs and `packages/premium_stub/`
is a no-op entitlement API, so Pro entry points stay hidden in this build.
See [README.md](README.md) for what is open source and what is Pro.

## Scope

Issues and pull requests are welcome for:

- free features and bug fixes,
- platform fixes (iOS, Android, macOS, Windows, Linux, Apple Watch),
- support for more local or OpenAI-compatible providers,
- translations.

Pro features, billing, hosted services and store releases are maintained
privately and are out of scope here.

## Build

1. Install the Flutter SDK (stable channel).
2. Copy the Firebase placeholders, or run `flutterfire configure` against your
   own Firebase project:
   ```bash
   cp lib/firebase_options.example.dart lib/firebase_options.dart
   cp ios/Runner/GoogleService-Info.example.plist ios/Runner/GoogleService-Info.plist
   cp macos/Runner/GoogleService-Info.example.plist macos/Runner/GoogleService-Info.plist
   # optional on Android (the Google Services plugin is applied only when it exists)
   cp android/app/google-services.example.json android/app/google-services.json
   ```
3. `flutter pub get && flutter analyze && flutter test`
4. `flutter run`
5. macOS desktop runtime (optional): `./macos/scripts/vendor_llama_server.sh`

## Layout

- `lib/`: the app (models, providers, screens, services, widgets; strings in
  `lib/l10n/*.arb`).
- `lib/pro/`: public stubs for Pro features, plus `pro_features.dart`
  (`ProFeatures.included` is `false` in this build).
- `packages/premium_stub/`: the no-op `lm_mini_premium` entitlement API and the
  shared OpenAI-compatible HTTP client.
- `test/`: tests.
- `ios/`, `macos/`, `android/`, `windows/`, `linux/`, `web/`: platform runners.

## Rules for pull requests

- Free features must work with the stubs; never crash on a Pro entry point.
- Keep the public signatures in `lib/pro/` and `packages/premium_stub/`
  unchanged, and do not implement Pro behavior there; the official app relies
  on the same API. Pull requests that do are closed.
- Gate new Pro-adjacent UI with `ProFeatures` so it stays hidden in this build
  (no upgrade prompts).
- Add user-facing strings to `lib/l10n/app_en.arb`.
- Never commit API keys, Firebase configs or signing material.
- Run `flutter analyze` and `flutter test` before opening a pull request.

## Security

Report security issues privately to support@lmmini.com rather than in a
public issue.

## License

By contributing you agree that your contribution is licensed under the MIT
license in [LICENSE](LICENSE). The LM Mini name and app icon are not covered
by it, see [TRADEMARK.md](TRADEMARK.md). Coding agents: see
[AGENTS.md](AGENTS.md).
