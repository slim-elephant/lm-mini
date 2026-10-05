#!/usr/bin/env python3
"""Download a Vulkan llama.cpp Windows build into windows/runner/resources/runtime/.

Maintainers / CI only — end users never run this. The exe and DLLs ship inside
LM Mini Home (gitignored; too large for git).

Usage:
  python3 windows/scripts/vendor_llama_server.py
  LLAMA_CPP_TAG=b10453 python3 windows/scripts/vendor_llama_server.py
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
import zipfile
from pathlib import Path

REPO = "ggml-org/llama.cpp"
ASSET_NEEDLE = "bin-win-vulkan-x64.zip"
UA = "lm-mini-home-vendor/1.0"


def root_dir() -> Path:
    return Path(__file__).resolve().parents[2]


def out_dir() -> Path:
    return root_dir() / "windows" / "runner" / "resources" / "runtime"


def github_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def latest_release() -> dict:
    tag = os.environ.get("LLAMA_CPP_TAG", "").strip()
    if tag:
        url = f"https://api.github.com/repos/{REPO}/releases/tags/{tag}"
    else:
        url = f"https://api.github.com/repos/{REPO}/releases/latest"
    return github_json(url)


def pick_asset(release: dict) -> dict:
    assets = release.get("assets") or []
    matches = [a for a in assets if str(a.get("name", "")).endswith(ASSET_NEEDLE)]
    if not matches:
        names = ", ".join(str(a.get("name")) for a in assets[:12])
        raise SystemExit(f"No {ASSET_NEEDLE} asset in {release.get('tag_name')}. Saw: {names}")
    return matches[0]


def download(url: str, dest: Path) -> None:
    last_err: Exception | None = None
    curl = shutil.which("curl")
    for attempt in range(1, 5):
        try:
            if curl:
                subprocess.check_call(
                    [curl, "-L", "--fail", "--retry", "3", "--retry-delay", "2",
                     "-A", UA, "-o", str(dest), url],
                )
            else:
                req = urllib.request.Request(
                    url, headers={"User-Agent": UA, "Accept": "*/*"}
                )
                with urllib.request.urlopen(req, timeout=300) as resp, dest.open("wb") as out:
                    shutil.copyfileobj(resp, out)
            if dest.exists() and dest.stat().st_size > 1_000_000:
                return
            last_err = RuntimeError(f"download too small: {dest.stat().st_size if dest.exists() else 0} bytes")
        except Exception as err:  # noqa: BLE001 — retry then raise
            last_err = err
            time.sleep(1.5 * attempt)
    raise SystemExit(f"Failed to download {url}: {last_err}")


def keep_runtime_file(name: str) -> bool:
    lower = name.lower()
    if lower == "llama-server.exe":
        return True
    if lower.startswith("llama-server") and lower.endswith(".dll"):
        return True
    if lower in {"llama.dll", "llama-common.dll", "mtmd.dll"}:
        return True
    if lower.startswith("ggml") and lower.endswith(".dll"):
        return True
    if lower.startswith("libomp") and lower.endswith(".dll"):
        return True
    if lower.startswith("license"):
        return True
    return False


def copy_runtime_files(extract_root: Path, dest: Path) -> list[Path]:
    copied: list[Path] = []
    for path in extract_root.rglob("*"):
        if not path.is_file() or not keep_runtime_file(path.name):
            continue
        target = dest / path.name
        shutil.copy2(path, target)
        copied.append(target)
    return copied


def main() -> int:
    dest = out_dir()
    dest.mkdir(parents=True, exist_ok=True)
    for stale in dest.iterdir():
        if stale.name in {"README.md", ".gitkeep"}:
            continue
        if stale.is_file():
            stale.unlink()

    release = latest_release()
    tag = release.get("tag_name", "unknown")
    asset = pick_asset(release)
    name = asset["name"]
    url = asset["browser_download_url"]
    print(f"Vendoring {name} from llama.cpp {tag}…")

    with tempfile.TemporaryDirectory(prefix="lmmini-llama-") as tmp:
        tmp_path = Path(tmp)
        zip_path = tmp_path / name
        download(url, zip_path)
        extract_dir = tmp_path / "extract"
        extract_dir.mkdir()
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(extract_dir)
        copied = copy_runtime_files(extract_dir, dest)

    exe = dest / "llama-server.exe"
    if not exe.exists():
        raise SystemExit(f"error: llama-server.exe missing after extract of {name}")

    license_path = dest / "LICENSE.llama.cpp"
    license_path.write_text(
        f"llama.cpp {tag} Windows Vulkan build ({name})\n"
        f"https://github.com/{REPO}/releases/tag/{tag}\n"
        "MIT License — see upstream repository.\n",
        encoding="utf-8",
    )
    print(f"Vendored {len(copied)} files → {dest}")
    for path in sorted(dest.iterdir()):
        if path.is_file() and path.name not in {"README.md", ".gitkeep"}:
            print(f"  {path.name}  ({path.stat().st_size / (1024 * 1024):.1f} MiB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
