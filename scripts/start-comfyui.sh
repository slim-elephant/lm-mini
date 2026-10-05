#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMFY_DIR="$ROOT_DIR/comfyui"

if [[ ! -x "$COMFY_DIR/.venv/bin/python" ]]; then
  echo "Missing ComfyUI venv at $COMFY_DIR/.venv/bin/python" >&2
  exit 1
fi

if [[ ! -f "$COMFY_DIR/models/checkpoints/sd_turbo.safetensors" ]]; then
  echo "Missing checkpoint at $COMFY_DIR/models/checkpoints/sd_turbo.safetensors" >&2
  exit 1
fi

cd "$COMFY_DIR"
CERT_BUNDLE="$(./.venv/bin/python -c 'import certifi; print(certifi.where())')"
export SSL_CERT_FILE="$CERT_BUNDLE"
export REQUESTS_CA_BUNDLE="$CERT_BUNDLE"
exec ./.venv/bin/python main.py --listen 127.0.0.1 --port 8188 --enable-manager "$@"