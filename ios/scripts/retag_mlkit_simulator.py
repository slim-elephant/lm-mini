#!/usr/bin/env python3
"""Copy ML Kit's arm64 slices and tag them as iOS Simulator.

Google's ML Kit 6 binaries ship an arm64 slice marked as a device build.
Xcode then refuses an arm64 iPhone simulator, and the only remaining
simulator slice is x86_64. watchOS 26 simulators are arm64-only, so Watch
Connectivity never activates across that gap.

The copies land in ios/build/mlkit-sim and are searched only for the
simulator (see ios/Flutter/Debug.xcconfig). Device builds keep the pods.
"""

import shutil
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PODS = ROOT / "Pods"
OUT = ROOT / "build" / "mlkit-sim"

FRAMEWORKS = (
    PODS / "MLKitVision" / "Frameworks" / "MLKitVision.framework",
    PODS / "MLKitCommon" / "Frameworks" / "MLKitCommon.framework",
    PODS / "MLImage" / "Frameworks" / "MLImage.framework",
)

MH_MAGIC_64 = 0xFEEDFACF
LC_BUILD_VERSION = 0x32
PLATFORM_IOS = 2
PLATFORM_IOSSIMULATOR = 7


def patch_macho(buf: bytearray, start: int, end: int) -> int:
    if end - start < 32:
        return 0
    magic, _, _, _, ncmds, sizeofcmds, _, _ = struct.unpack_from("<IIIIIIII", buf, start)
    if magic != MH_MAGIC_64:
        return 0
    if start + 32 + sizeofcmds > end:
        return 0
    offset = start + 32
    changed = 0
    for _ in range(ncmds):
        if offset + 8 > end:
            break
        cmd, cmdsize = struct.unpack_from("<II", buf, offset)
        if cmdsize < 8 or offset + cmdsize > end:
            break
        if cmd == LC_BUILD_VERSION and cmdsize >= 24:
            platform = struct.unpack_from("<I", buf, offset + 8)[0]
            if platform == PLATFORM_IOS:
                struct.pack_into("<I", buf, offset + 8, PLATFORM_IOSSIMULATOR)
                changed += 1
        offset += cmdsize
    return changed


def patch_archive(data: bytearray) -> int:
    if not data.startswith(b"!<arch>\n"):
        return patch_macho(data, 0, len(data))
    changed = 0
    offset = 8
    while offset + 60 <= len(data):
        header = data[offset : offset + 60]
        name = header[:16]
        try:
            size = int(header[48:58].strip() or b"0")
        except ValueError:
            break
        payload = offset + 60
        if name.startswith(b"#1/"):
            namelen = int(name[3:].strip() or b"0")
            member = payload + namelen
            member_end = payload + size
        else:
            member = payload
            member_end = payload + size
        if member_end > len(data):
            break
        changed += patch_macho(data, member, member_end)
        offset = member_end + (member_end & 1)
    return changed


def lipo_thin(src: Path, arch: str, dest: Path) -> None:
    subprocess.run(
        ["lipo", str(src), "-thin", arch, "-output", str(dest)],
        check=True,
    )


def retag(framework: Path) -> None:
    binary = framework / framework.stem
    if not binary.is_file():
        raise SystemExit(f"missing binary: {binary}")
    work = OUT / ".work"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    arm = work / "arm64"
    intel = work / "x86_64"
    lipo_thin(binary, "arm64", arm)
    lipo_thin(binary, "x86_64", intel)
    blob = bytearray(arm.read_bytes())
    changed = patch_archive(blob)
    if changed == 0:
        raise SystemExit(f"no device arm64 slices retagged in {binary}")
    arm.write_bytes(blob)
    dest_framework = OUT / framework.name
    if dest_framework.exists():
        shutil.rmtree(dest_framework)
    shutil.copytree(framework, dest_framework, symlinks=True)
    dest_bin = dest_framework / framework.stem
    subprocess.run(
        ["lipo", "-create", str(intel), str(arm), "-output", str(dest_bin)],
        check=True,
    )
    print(f"{framework.name}: retagged {changed} arm64 objects")
    shutil.rmtree(work)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for framework in FRAMEWORKS:
        if not framework.is_dir():
            raise SystemExit(f"missing framework: {framework}")
        retag(framework)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        sys.exit(exc.returncode)
