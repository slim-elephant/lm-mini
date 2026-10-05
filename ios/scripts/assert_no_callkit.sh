#!/bin/sh
# Fail if an iOS binary still links CallKit or contains CX* / CallKit strings.
# Usage:
#   ios/scripts/assert_no_callkit.sh path/to/Runner.app/Runner
#   ios/scripts/assert_no_callkit.sh build/ios/ipa/lm_mini.ipa
set -eu

target="${1:-}"
if [ -z "$target" ]; then
  echo "usage: $0 <Runner binary | Runner.app | .ipa>" >&2
  exit 2
fi

tmp=""
cleanup() {
  if [ -n "$tmp" ] && [ -d "$tmp" ]; then
    rm -rf "$tmp"
  fi
}
trap cleanup EXIT

binary="$target"
if [ -d "$target" ]; then
  binary="$target/Runner"
fi
case "$target" in
  *.ipa)
    tmp="$(mktemp -d)"
    unzip -q "$target" -d "$tmp"
    binary="$(find "$tmp/Payload" -name Runner -type f | head -n 1)"
    ;;
esac

if [ ! -f "$binary" ]; then
  echo "error: Runner binary not found: $binary" >&2
  exit 1
fi

fail=0

if otool -L "$binary" | grep -qi CallKit; then
  echo "FAIL: still links CallKit:" >&2
  otool -L "$binary" | grep -i CallKit >&2
  fail=1
fi

if nm -u "$binary" 2>/dev/null | grep -E 'CXProvider|CXCallController|CXHandle' >/dev/null; then
  echo "FAIL: undefined CallKit symbols still referenced:" >&2
  nm -u "$binary" | grep -E 'CXProvider|CXCallController|CXHandle' >&2
  fail=1
fi

# User-facing / review strings (plugin class names may still appear until
# flutter_callkit_incoming is removed from pubspec).
if strings "$binary" | grep -F 'CallKit.framework' >/dev/null; then
  echo "FAIL: CallKit.framework string in binary" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "OK: no CallKit.framework / CXProvider in $binary"
