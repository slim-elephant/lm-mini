#!/bin/sh
# strip_simulator_slices.sh
#
# Removes simulator-only architectures (x86_64, i386, armv7s) from every
# embedded .framework executable in the built .app bundle, then re-signs
# each modified framework so App Store Connect accepts the IPA.
#
# Why this exists:
#   App Store Connect rejects IPAs whose embedded frameworks contain a
#   simulator slice with "Invalid executable … references an unsupported
#   platform" (ITMS-90087 / Validation failed 409).
#
#   Flutter 3.41 shares build/native_assets/ios between the simulator and
#   the device. After a simulator run, an archive can embed
#   objective_c.framework built for the simulator. On Apple Silicon that
#   binary is arm64, so removing x86_64 is not enough: the arm64 slice is
#   still tagged IOSSIMULATOR. This script drops simulator architectures
#   and, when the remaining binary is still a simulator build, replaces it
#   with the device dylib from .dart_tool/hooks_runner.
#
# Wired in by ios/Podfile post_install AND directly into Runner.xcodeproj
# as a "Strip simulator slices from embedded frameworks" Run Script phase.
# Must run AFTER the "Thin Binary" phase so every framework is already in
# place inside the .app bundle.

set -eu
# macOS /bin/sh is bash 3.2 in POSIX mode — pipefail lets a failure inside
# `find | while` fail the Xcode Run Script phase.
set -o pipefail 2>/dev/null || true

if [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  echo "strip_simulator_slices: skipping (PLATFORM_NAME=${PLATFORM_NAME:-unset})"
  exit 0
fi

# Collect every place Xcode may have put the .app for this build.
# CODESIGNING_FOLDER_PATH is the most reliable for archive builds — it
# points at the actual .app currently being signed. Fall back to the
# generic TARGET_BUILD_DIR/BUILT_PRODUCTS_DIR.
APP_PATHS=""
if [ -n "${CODESIGNING_FOLDER_PATH:-}" ] && [ -d "${CODESIGNING_FOLDER_PATH}" ]; then
  APP_PATHS="${CODESIGNING_FOLDER_PATH}"
fi
if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${WRAPPER_NAME:-}" ] && [ -d "${TARGET_BUILD_DIR}/${WRAPPER_NAME}" ]; then
  APP_PATHS="${APP_PATHS}
${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
fi
if [ -n "${BUILT_PRODUCTS_DIR:-}" ] && [ -n "${WRAPPER_NAME:-}" ] && [ -d "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}" ]; then
  APP_PATHS="${APP_PATHS}
${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}"
fi

if [ -z "${APP_PATHS}" ]; then
  echo "strip_simulator_slices: no app bundle locations found — skipping"
  exit 0
fi

# Deduplicate while preserving order.
APP_PATHS=$(printf "%s" "${APP_PATHS}" | awk 'NF && !seen[$0]++')

IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:-${CODE_SIGN_IDENTITY:-}}"

# First platform line from LC_BUILD_VERSION. Empty if this is not a Mach-O.
macho_platform() {
  xcrun vtool -show-build "$1" 2>/dev/null | awk '/platform /{print $2; exit}'
}

macho_has_simulator_platform() {
  xcrun vtool -show-build "$1" 2>/dev/null | grep -q 'platform IOSSIMULATOR'
}

# Device (iphoneos) build of a native-asset library, if a previous device
# hook run left one in the shared hooks cache.
find_device_dylib() {
  name="$1"
  root="${SRCROOT}/../.dart_tool/hooks_runner/shared/${name}/build"
  if [ ! -d "${root}" ]; then
    return 1
  fi
  best=""
  best_mtime=0
  list=$(mktemp)
  find "${root}" -type f \( -name '*.dylib' -o -name "${name}" \) > "${list}"
  while IFS= read -r cand; do
    [ -f "${cand}" ] || continue
    plat=$(macho_platform "${cand}")
    [ "${plat}" = "IOS" ] || continue
    archs=$(lipo -archs "${cand}" 2>/dev/null || echo "")
    case " ${archs} " in
      *" arm64 "*) ;;
      *) continue ;;
    esac
    mt=$(stat -f %m "${cand}")
    if [ "${mt}" -gt "${best_mtime}" ]; then
      best="${cand}"
      best_mtime=${mt}
    fi
  done < "${list}"
  rm -f "${list}"
  if [ -z "${best}" ]; then
    return 1
  fi
  printf '%s\n' "${best}"
}

printf "%s\n" "${APP_PATHS}" | while IFS= read -r APP_PATH; do
  [ -z "${APP_PATH}" ] && continue
  echo "strip_simulator_slices: scanning ${APP_PATH}"

  find "${APP_PATH}" -name '*.framework' -type d | while IFS= read -r FRAMEWORK; do
    FRAMEWORK_NAME=$(basename "${FRAMEWORK}" .framework)
    EXECUTABLE="${FRAMEWORK}/${FRAMEWORK_NAME}"
    if [ ! -f "${EXECUTABLE}" ]; then
      EXECUTABLE_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "${FRAMEWORK}/Info.plist" 2>/dev/null || echo "")
      if [ -n "${EXECUTABLE_NAME}" ] && [ -f "${FRAMEWORK}/${EXECUTABLE_NAME}" ]; then
        EXECUTABLE="${FRAMEWORK}/${EXECUTABLE_NAME}"
      else
        continue
      fi
    fi

    ARCHS=$(lipo -archs "${EXECUTABLE}" 2>/dev/null || echo "")
    SIM_ARCHS=""
    DEVICE_ARCHS=""
    for ARCH in ${ARCHS}; do
      case "${ARCH}" in
        x86_64|i386|armv7s)
          SIM_ARCHS="${SIM_ARCHS} ${ARCH}"
          ;;
        *)
          DEVICE_ARCHS="${DEVICE_ARCHS} ${ARCH}"
          ;;
      esac
    done

    MODIFIED=0
    # A simulator-only binary has no device slice to keep. lipo -remove
    # would empty the file. Leave it in place and replace it below.
    if [ -z "${SIM_ARCHS}" ] || [ -n "${DEVICE_ARCHS}" ]; then
      for ARCH in ${SIM_ARCHS}; do
        echo "strip_simulator_slices: removing ${ARCH} from ${EXECUTABLE}"
        lipo -remove "${ARCH}" -output "${EXECUTABLE}" "${EXECUTABLE}"
        MODIFIED=1
      done
    fi

    # arm64 tagged IOSSIMULATOR survives the lipo step. Swap in the
    # iphoneos build from the hooks cache.
    if macho_has_simulator_platform "${EXECUTABLE}"; then
      DEVICE_DYLIB=$(find_device_dylib "${FRAMEWORK_NAME}" || true)
      if [ -z "${DEVICE_DYLIB}" ]; then
        echo "strip_simulator_slices: ERROR: ${FRAMEWORK_NAME}.framework is an iOS Simulator binary (${ARCHS})."
        echo "Flutter copied a Simulator native-assets build into this device archive,"
        echo "and no iphoneos build of it is in .dart_tool/hooks_runner."
        echo "Run: flutter build ios --release --no-codesign"
        echo "then archive again."
        exit 1
      fi
      echo "strip_simulator_slices: replacing simulator ${FRAMEWORK_NAME} with ${DEVICE_DYLIB}"
      rm -f "${EXECUTABLE}"
      cp "${DEVICE_DYLIB}" "${EXECUTABLE}"
      chmod u+w "${EXECUTABLE}"
      codesign --remove-signature "${EXECUTABLE}" 2>/dev/null || true
      install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${EXECUTABLE}"
      MODIFIED=1
    fi

    # Re-sign the framework whenever we modified its binary. Without this
    # the IPA's code signature is invalid and the App Store rejects the
    # upload with a CMS signing error before it even checks slices.
    if [ "${MODIFIED}" = "1" ] && [ -n "${IDENTITY}" ]; then
      echo "strip_simulator_slices: re-signing ${FRAMEWORK} with ${IDENTITY}"
      codesign --force --sign "${IDENTITY}" --preserve-metadata=identifier,entitlements,flags "${FRAMEWORK}" \
        || echo "strip_simulator_slices: WARN re-sign failed for ${FRAMEWORK}"
    fi
  done
done

echo "strip_simulator_slices: done"
