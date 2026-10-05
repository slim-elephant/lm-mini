# Bundled desktop runtime (Windows Home)

Place a Vulkan-enabled `llama-server.exe` here before `flutter build windows`.

```bash
python3 windows/scripts/vendor_llama_server.py
```

Maintainers / CI only. End users never run it — the binary ships next to `LMMini.exe`.

| File | Purpose |
|------|---------|
| `llama-server.exe` | Executable (gitignored — too large) |
| `*.dll` | ggml / llama / Vulkan backends |
| `LICENSE.llama.cpp` | License notice for redistributed binary |

CMake copies this folder into:

`build/windows/x64/runner/Release/runtime/`
