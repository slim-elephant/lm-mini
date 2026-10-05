# Agent guide (LM Mini open-source build)

LM Mini is a Flutter chat client for LM Studio, Ollama, oMLX, Jan, Unsloth and
other OpenAI-compatible servers, plus on-device models (llama.cpp and MLX).
This repository is an exported snapshot of the app. The free features are
complete here; LM Mini Pro implementations are not included and are replaced
by stubs. Human contributors: see [CONTRIBUTING.md](CONTRIBUTING.md).

## Build and check

```bash
# Firebase placeholders (or run `flutterfire configure` for your own project)
cp lib/firebase_options.example.dart lib/firebase_options.dart
cp ios/Runner/GoogleService-Info.example.plist ios/Runner/GoogleService-Info.plist
cp macos/Runner/GoogleService-Info.example.plist macos/Runner/GoogleService-Info.plist
# Optional on Android: the Google Services plugin is applied only when this file exists
cp android/app/google-services.example.json android/app/google-services.json

flutter pub get
flutter analyze
flutter test
flutter run
```

macOS desktop runtime (optional): `./macos/scripts/vendor_llama_server.sh`
fetches the llama.cpp server binaries, which are not in the repository.

## Layout

- `lib/`: the app (`models/`, `providers/`, `screens/`, `services/`,
  `widgets/`, `desktop/`; strings in `lib/l10n/*.arb`).
- `lib/pro/`: public stubs for Pro features. Line 1 of each file is
  `// LM-MINI-PRO-STUB`. Keep their public signatures and keep them inert.
- `lib/pro/pro_features.dart`: the `ProFeatures` build switch. In this build
  `ProFeatures.included`, `ProFeatures.isPro` and `ProFeatures.showUpsell` are
  all `false`.
- `packages/premium_stub/`: the no-op `lm_mini_premium` entitlement API
  (`SubscriptionService().isPremium` is always `false`). It also holds the
  shared OpenAI-compatible HTTP client (`CloudApiService`).
- `test/`: unit and widget tests.
- `ios/`, `macos/`, `android/`, `windows/`, `linux/`, `web/`: platform
  runners. `ios/LMMiniWatch/` is the Apple Watch companion.

## Rules

- Do not implement Pro behavior in `lib/pro/` or `packages/premium_stub/`, and
  do not change their public signatures; the official app compiles against the
  same API. Pull requests that implement Pro features in the stubs are closed.
- Free features must work with the stubs. Never crash on a Pro entry point.
- New Pro-adjacent UI must be gated with `ProFeatures`: hide it when
  `ProFeatures.included` is `false`. Do not add upgrade prompts; use
  `ProFeatures.showUpsell` if a prompt already exists.
- Keep provider-specific logic behind the existing service abstractions
  (the LM Studio, Ollama and OpenAI-compatible paths), and preserve message
  `stats`/`usage` fields when copying messages.
- Add user-facing strings to `lib/l10n/app_en.arb` (other locales fall back to
  English).
- UI follows the existing glass style: reuse the shared widgets and theme
  tokens instead of hard-coding colors.
- Never commit API keys, Firebase configs (`lib/firebase_options.dart`,
  `GoogleService-Info.plist`, `google-services.json`) or signing material.
- Run `flutter analyze` and `flutter test` before finishing a change.

## License

MIT, see [LICENSE](LICENSE). The LM Mini name and icon are not licensed for
forks, see [TRADEMARK.md](TRADEMARK.md).
