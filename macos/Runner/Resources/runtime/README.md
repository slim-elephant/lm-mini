# Bundled desktop runtime (Mac App Store)

Place a Metal-enabled `llama-server` binary here before Archive / store upload.

```bash
./macos/scripts/vendor_llama_server.sh
```

That script is for **maintainers/CI only**. End users never run it — the binary ships inside the app.

| File | Purpose |
|------|---------|
| `llama-server` | Executable (gitignored — too large) |
| `libggml-*.so` | Metal / CPU / BLAS backends (`GGML_BACKEND_PATH`) |
| `LICENSE.llama.cpp` | License notice for redistributed binary |

Xcode phase **Embed Desktop Runtime** copies this folder into:

`LM Mini.app/Contents/Resources/runtime/`
