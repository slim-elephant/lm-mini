#!/usr/bin/env bash
# Bundles a self-contained Metal-capable llama-server into
# macos/Runner/Resources/runtime/ for Mac App Store builds.
# Maintainers / CI only — not for end users.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="$ROOT/macos/Runner/Resources/runtime"
mkdir -p "$OUT_DIR"

# Clear previous vendored bits (keep docs).
find "$OUT_DIR" -maxdepth 1 \( -type f -o -type l \) ! -name 'README.md' ! -name '.gitkeep' -delete

ARCH="$(uname -m)"
if ! command -v brew >/dev/null 2>&1; then
  echo "error: Homebrew required to vendor llama-server." >&2
  exit 1
fi

if ! brew list llama.cpp >/dev/null 2>&1; then
  brew install llama.cpp
fi

LLAMA_PREFIX="$(brew --prefix llama.cpp)"
GGML_PREFIX="$(brew --prefix ggml)"
OPENSSL_PREFIX="$(brew --prefix openssl@3)"
SRC_BIN="$LLAMA_PREFIX/bin/llama-server"

if [[ ! -x "$SRC_BIN" ]]; then
  echo "error: llama-server not found at $SRC_BIN" >&2
  exit 1
fi

copy_real() {
  local src="$1"
  local dest_name="$2"
  local resolved
  resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$src")"
  cp -f "$resolved" "$OUT_DIR/$dest_name"
  chmod u+w "$OUT_DIR/$dest_name"
}

echo "Vendoring llama-server + dylibs from Homebrew ($ARCH)…"
copy_real "$SRC_BIN" "llama-server"
chmod +x "$OUT_DIR/llama-server"

# llama.cpp libs used by llama-server
copy_real "$LLAMA_PREFIX/lib/libllama-server-impl.dylib" "libllama-server-impl.dylib"
copy_real "$LLAMA_PREFIX/lib/libllama-common.0.dylib" "libllama-common.0.dylib"
copy_real "$LLAMA_PREFIX/lib/libmtmd.0.dylib" "libmtmd.0.dylib"
copy_real "$LLAMA_PREFIX/lib/libllama.0.dylib" "libllama.0.dylib"

# ggml
copy_real "$GGML_PREFIX/lib/libggml.0.dylib" "libggml.0.dylib"
copy_real "$GGML_PREFIX/lib/libggml-base.0.dylib" "libggml-base.0.dylib"

# ggml dynamically loaded backends (Metal / CPU / BLAS). Homebrew compiles
# GGML_BACKEND_DIR to Cellar/libexec, which App Sandbox cannot read.
BACKEND_DIR="$GGML_PREFIX/libexec"
if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "error: ggml backends not found at $BACKEND_DIR" >&2
  exit 1
fi
shopt -s nullglob
backend_sos=("$BACKEND_DIR"/libggml-*.so)
shopt -u nullglob
if [[ ${#backend_sos[@]} -eq 0 ]]; then
  echo "error: no libggml-*.so backends in $BACKEND_DIR" >&2
  exit 1
fi
for so in "${backend_sos[@]}"; do
  copy_real "$so" "$(basename "$so")"
done

# OpenMP (ggml-base links this; App Sandbox cannot load Homebrew's copy)
OMP_PREFIX="$(brew --prefix libomp 2>/dev/null || true)"
if [[ -z "$OMP_PREFIX" || ! -f "$OMP_PREFIX/lib/libomp.dylib" ]]; then
  echo "error: libomp is required (ggml-base links it). brew install libomp" >&2
  exit 1
fi
copy_real "$OMP_PREFIX/lib/libomp.dylib" "libomp.dylib"

# OpenSSL (HTTPS for llama-server)
copy_real "$OPENSSL_PREFIX/lib/libssl.3.dylib" "libssl.3.dylib"
copy_real "$OPENSSL_PREFIX/lib/libcrypto.3.dylib" "libcrypto.3.dylib"

rewrite_deps() {
  local file="$1"
  local changes=(
    "@rpath/libllama-server-impl.dylib|@loader_path/libllama-server-impl.dylib"
    "@rpath/libllama-common.0.dylib|@loader_path/libllama-common.0.dylib"
    "@rpath/libmtmd.0.dylib|@loader_path/libmtmd.0.dylib"
    "@rpath/libllama.0.dylib|@loader_path/libllama.0.dylib"
    "@rpath/libggml.0.dylib|@loader_path/libggml.0.dylib"
    "@rpath/libggml-base.0.dylib|@loader_path/libggml-base.0.dylib"
    "/opt/homebrew/opt/ggml/lib/libggml.0.dylib|@loader_path/libggml.0.dylib"
    "/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib|@loader_path/libggml-base.0.dylib"
    "/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib|@loader_path/libssl.3.dylib"
    "/opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib|@loader_path/libcrypto.3.dylib"
    "/opt/homebrew/opt/llama.cpp/lib/libllama-common.0.dylib|@loader_path/libllama-common.0.dylib"
    "/opt/homebrew/opt/llama.cpp/lib/libllama.0.dylib|@loader_path/libllama.0.dylib"
    "/opt/homebrew/opt/llama.cpp/lib/libmtmd.0.dylib|@loader_path/libmtmd.0.dylib"
    "/opt/homebrew/opt/llama.cpp/lib/libllama-server-impl.dylib|@loader_path/libllama-server-impl.dylib"
    "/opt/homebrew/opt/libomp/lib/libomp.dylib|@loader_path/libomp.dylib"
    "/usr/local/opt/libomp/lib/libomp.dylib|@loader_path/libomp.dylib"
  )

  # Also rewrite any absolute Cellar paths that may appear.
  while IFS= read -r line; do
    local dep
    dep="$(echo "$line" | awk '{print $1}')"
    case "$dep" in
      /opt/homebrew/*|/usr/local/*)
        local base
        base="$(basename "$dep")"
        if [[ -f "$OUT_DIR/$base" ]]; then
          changes+=("${dep}|@loader_path/${base}")
        fi
        ;;
    esac
  done < <(otool -L "$file" | tail -n +2)

  local pair old new
  for pair in "${changes[@]}"; do
    old="${pair%%|*}"
    new="${pair#*|}"
    if otool -L "$file" | grep -F "$old" >/dev/null 2>&1; then
      install_name_tool -change "$old" "$new" "$file" 2>/dev/null || true
    fi
  done
}

# Set dylib ids to @loader_path so peers resolve next to the binary.
for lib in \
  libllama-server-impl.dylib \
  libllama-common.0.dylib \
  libmtmd.0.dylib \
  libllama.0.dylib \
  libggml.0.dylib \
  libggml-base.0.dylib \
  libomp.dylib \
  libssl.3.dylib \
  libcrypto.3.dylib
do
  [[ -f "$OUT_DIR/$lib" ]] || continue
  install_name_tool -id "@loader_path/$lib" "$OUT_DIR/$lib"
  rewrite_deps "$OUT_DIR/$lib"
done

for so in "$OUT_DIR"/libggml-*.so; do
  [[ -f "$so" ]] || continue
  install_name_tool -id "@loader_path/$(basename "$so")" "$so"
  rewrite_deps "$so"
  install_name_tool -add_rpath "@loader_path" "$so" 2>/dev/null || true
done

rewrite_deps "$OUT_DIR/llama-server"
# Ensure the executable searches its own directory.
install_name_tool -add_rpath "@loader_path" "$OUT_DIR/llama-server" 2>/dev/null || true

# Homebrew ggml compiles GGML_BACKEND_DIR to Cellar/.../libexec. App Sandbox can
# stat that path but cannot list it, and libc++ directory_iterator throws
# (uncaught → abort -6). Neutralize the string so discovery uses the bundled
# libggml-*.so next to llama-server.
python3 - "$OUT_DIR" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
patched = 0
for path in root.glob("libggml*.dylib"):
    data = bytearray(path.read_bytes())
    changed = False
    for needle in (b"/opt/homebrew/Cellar/ggml/", b"/usr/local/Cellar/ggml/"):
        start = 0
        while True:
            i = data.find(needle, start)
            if i < 0:
                break
            end = data.find(0, i)
            if end < 0:
                break
            blob = bytes(data[i:end])
            if b"/libexec" in blob:
                replacement = b"/var/empty/.lmmini-no-ggml-backend"
                if len(replacement) > end - i:
                    replacement = replacement[: end - i]
                data[i:end] = replacement + b"\0" * (end - i - len(replacement))
                changed = True
                print(f"neutralized GGML_BACKEND_DIR in {path.name}: {blob.decode()}")
            start = i + 1
    if changed:
        path.write_bytes(data)
        patched += 1
if patched == 0:
    print("note: no Homebrew GGML_BACKEND_DIR string found to neutralize", file=sys.stderr)
PY

echo "llama.cpp (Homebrew) + ggml + OpenSSL" > "$OUT_DIR/LICENSE.llama.cpp"

echo "Vendored self-contained runtime → $OUT_DIR"
ls -lh "$OUT_DIR" | sed -n '1,20p'
echo "--- dependency check (llama-server) ---"
otool -L "$OUT_DIR/llama-server"
echo "--- ad-hoc sign (install_name_tool invalidates brew signatures) ---"
for f in "$OUT_DIR"/*.dylib "$OUT_DIR"/*.so "$OUT_DIR/llama-server"; do
  [[ -f "$f" ]] || continue
  codesign --force -s - "$f" >/dev/null 2>&1 || true
done

echo "--- smoke test ---"
set +e
"$OUT_DIR/llama-server" --version >/tmp/llama-server-version.txt 2>&1
rc=$?
# Discovery uses the executable dir + cwd after GGML_BACKEND_DIR is neutralized.
"$OUT_DIR/llama-server" --list-devices >/tmp/llama-server-devices.txt 2>&1 || true
set -e
if grep -qi 'dyld\|Library not loaded' /tmp/llama-server-version.txt; then
  cat /tmp/llama-server-version.txt >&2
  echo "error: vendored llama-server failed to load dylibs" >&2
  exit 1
fi
head -10 /tmp/llama-server-version.txt || true
echo "--- devices ---"
cat /tmp/llama-server-devices.txt || true
echo "(exit $rc — Xcode will re-sign for App Store)"

lipo -info "$OUT_DIR/llama-server" || true
