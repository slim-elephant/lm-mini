#!/usr/bin/env bash
# Resize source PNGs to 512×512 WebP for assets/images/persona_pack/.
# Usage:
#   ./tool/compress_persona_pack.sh "/path/to/source/folder"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$HOME/Downloads/untitled folder}"
DEST="$ROOT/assets/images/persona_pack"

if [[ ! -d "$SRC" ]]; then
  echo "Source folder not found: $SRC" >&2
  exit 1
fi
if ! command -v sips >/dev/null || ! command -v cwebp >/dev/null; then
  echo "Need sips and cwebp on PATH." >&2
  exit 1
fi

mkdir -p "$DEST"
count=0
for f in "$SRC"/*.png; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f" .png)"
  id="$(echo "$base" | tr '[:upper:]' '[:lower:]')"
  tmp="$(mktemp -t persona_pack).png"
  sips -z 512 512 "$f" --out "$tmp" >/dev/null
  cwebp -q 82 "$tmp" -o "$DEST/${id}.webp" >/dev/null
  rm -f "$tmp"
  echo "ok $id"
  count=$((count + 1))
done

echo "Wrote $count WebP files to $DEST ($(du -sh "$DEST" | awk '{print $1}'))"
