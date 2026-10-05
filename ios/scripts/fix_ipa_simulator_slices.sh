#!/bin/sh
# fix_ipa_simulator_slices.sh <path/to/foo.ipa>
#
# Post-archive emergency fix. Unzips the supplied .ipa, strips simulator
# slices from every embedded framework, re-signs each modified framework
# and the .app, then re-zips.
#
# Use this when an IPA was archived BEFORE the build-phase fix was wired
# in (which Apple's Transporter would otherwise reject with ITMS-90087 /
# Validation 409 "references an unsupported platform in the x86_64 slice").
#
# Requires:
#   - An installed Apple Distribution / iOS Distribution code-signing
#     identity matching the IPA's existing provisioning profile.
#   - `codesign`, `lipo`, `unzip`, `zip` (preinstalled on macOS).
#
# Usage:
#   IDENTITY="Apple Distribution: Your Name (TEAMID)" \
#     ios/scripts/fix_ipa_simulator_slices.sh build/ios/ipa/Runner.ipa
#
# Output: rewrites the file in place. A `.bak` copy is kept next to it.

set -eu

IPA="${1:-}"
if [ -z "${IPA}" ] || [ ! -f "${IPA}" ]; then
  echo "Usage: $0 <path/to/foo.ipa>" >&2
  exit 2
fi

IDENTITY="${IDENTITY:-}"
if [ -z "${IDENTITY}" ]; then
  echo "Set IDENTITY env var to your Apple Distribution identity (run 'security find-identity -v -p codesigning')." >&2
  exit 2
fi

WORK=$(mktemp -d)
trap 'rm -rf "${WORK}"' EXIT

cp "${IPA}" "${IPA}.bak"
unzip -q "${IPA}" -d "${WORK}"

APP_BUNDLE=$(find "${WORK}/Payload" -maxdepth 2 -name '*.app' -type d | head -1)
if [ -z "${APP_BUNDLE}" ]; then
  echo "No .app inside Payload/ — aborting." >&2
  exit 1
fi
echo "Patching ${APP_BUNDLE}"

CHANGED=0
find "${APP_BUNDLE}" -name '*.framework' -type d | while IFS= read -r FW; do
  NAME=$(basename "${FW}" .framework)
  EXE="${FW}/${NAME}"
  [ -f "${EXE}" ] || continue
  ARCHS=$(lipo -archs "${EXE}" 2>/dev/null || echo "")
  MOD=0
  for A in ${ARCHS}; do
    case "${A}" in
      x86_64|i386|armv7s)
        echo "  removing ${A} from ${EXE}"
        lipo -remove "${A}" -output "${EXE}" "${EXE}"
        MOD=1
        ;;
    esac
  done
  if [ "${MOD}" = "1" ]; then
    codesign --force --sign "${IDENTITY}" --preserve-metadata=identifier,entitlements,flags "${FW}"
    CHANGED=1
  fi
done

# Re-sign the .app itself so its CodeResources hashes line up with the
# modified framework binaries.
echo "Re-signing app bundle"
codesign --force --sign "${IDENTITY}" --preserve-metadata=identifier,entitlements,flags --deep "${APP_BUNDLE}"

# Repack the IPA. Note: must be a zip with no extra metadata directories.
rm -f "${IPA}"
( cd "${WORK}" && zip -qr "${IPA}" Payload )

echo "Done. Original at ${IPA}.bak — verify the new IPA with:"
echo "  unzip -p \"${IPA}\" 'Payload/*.app/Frameworks/fllama.framework/fllama' | file -"
echo "  xcrun altool --validate-app -f \"${IPA}\" -t ios -u YOUR_APPLE_ID --apiKey ..."
