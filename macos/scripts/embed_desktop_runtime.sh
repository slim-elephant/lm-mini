#!/usr/bin/env bash
# Xcode Run Script phase: copy bundled runtime into the .app Resources.
set -euo pipefail

SRC="${SRCROOT}/Runner/Resources/runtime"
DST="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/runtime"
ENTITLEMENTS="${SRCROOT}/Runner/Runtime.entitlements"

mkdir -p "$DST"

if [[ ! -d "$SRC" ]]; then
  echo "note: no desktop runtime folder at $SRC"
  exit 0
fi

# Copy executables / support files; skip docs used only in-repo.
rsync -a \
  --exclude '.gitkeep' \
  --exclude 'README.md' \
  "$SRC/" "$DST/"

sign_lib() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]]; then
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
      --options runtime \
      --timestamp=none \
      "$path"
  fi
}

sign_exec() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  if [[ -z "${EXPANDED_CODE_SIGN_IDENTITY:-}" || "${EXPANDED_CODE_SIGN_IDENTITY}" == "-" ]]; then
    echo "warning: no code signing identity; skipping sign of $path" >&2
    return 0
  fi
  if [[ ! -f "$ENTITLEMENTS" ]]; then
    echo "error: missing $ENTITLEMENTS (required for Mac App Store sandbox)" >&2
    exit 1
  fi
  # MAS: every executable must carry com.apple.security.app-sandbox.
  codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    --timestamp=none \
    "$path"
}

if [[ -f "$DST/llama-server" ]]; then
  chmod +x "$DST/llama-server"
  # Sign dylibs first, then the executable with sandbox entitlements.
  shopt -s nullglob
  for lib in "$DST"/*.dylib "$DST"/*.so; do
    sign_lib "$lib"
  done
  shopt -u nullglob
  sign_exec "$DST/llama-server"

  if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]]; then
    echo "Signed desktop runtime with ${EXPANDED_CODE_SIGN_IDENTITY} (+ Runtime.entitlements)"
    codesign -d --entitlements :- "$DST/llama-server" 2>/dev/null | plutil -p - 2>/dev/null || true
  fi
  echo "Embedded desktop runtime: $DST/llama-server"
else
  echo "warning: llama-server not found in $SRC — store users will not get fast desktop GGUF." >&2
  echo "warning: maintainers: run ./macos/scripts/vendor_llama_server.sh before Archive." >&2
fi
