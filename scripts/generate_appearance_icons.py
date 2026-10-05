#!/usr/bin/env python3
"""
Generate Dark and Tinted (iOS 18 "glass") variants of the LM Mini app icon
from the existing 1024x1024 light icon, then rewrite the iOS AppIcon set so
the system can pick the right variant based on the user's Home Screen mode.

Outputs (overwritten each run):
  ios/Runner/Assets.xcassets/AppIcon.appiconset/
    Icon-App-Light-1024.png   # original light icon (copied verbatim)
    Icon-App-Dark-1024.png    # dark-mode variant (dark gradient bg)
    Icon-App-Tinted-1024.png  # grayscale luminance map for tinting
    Contents.json             # rewritten to the iOS-18 single-size schema

Why a luminance map for Tinted?
  Per Apple's "Configure App Icons" guidance, the system replaces the icon
  with the user's chosen tint applied to a grayscale image where white maps
  to full intensity and black/transparent maps to none. We collapse the
  light icon to per-pixel luminance and feather the result with alpha so the
  tint blends cleanly on the system-supplied dark background.
"""
from __future__ import annotations

import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ICON_SET = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
SOURCE = ICON_SET / "Icon-App-1024x1024@1x.png"

LIGHT_OUT = ICON_SET / "Icon-App-Light-1024.png"
DARK_OUT = ICON_SET / "Icon-App-Dark-1024.png"
TINTED_OUT = ICON_SET / "Icon-App-Tinted-1024.png"


def _ensure_rgba(img: Image.Image) -> Image.Image:
    return img.convert("RGBA") if img.mode != "RGBA" else img


def build_light() -> None:
    """Copy the existing icon verbatim as the light variant."""
    shutil.copy2(SOURCE, LIGHT_OUT)


def build_dark() -> None:
    """Re-tint the icon for dark mode by swapping the lavender background
    for a deep gradient while keeping the speech bubble + text intact.

    Strategy: any pixel close to the original lavender gets remapped onto a
    near-black gradient. White elements are preserved. We work in RGBA so
    rounded corners stay smooth. Vectorized with numpy for speed.
    """
    src = _ensure_rgba(Image.open(SOURCE))
    arr = np.asarray(src, dtype=np.int16)  # H x W x 4
    h, w, _ = arr.shape

    # Vertical dark gradient (slate -> near-black).
    top = np.array([28, 28, 42], dtype=np.float32)
    bottom = np.array([10, 10, 16], dtype=np.float32)
    t = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]  # H x 1
    grad = (top[None, :] * (1 - t) + bottom[None, :] * t).astype(np.uint8)
    bg = np.repeat(grad[:, None, :], w, axis=1)  # H x W x 3

    # Build a "keep foreground" mask: pixels far from the lavender baseline
    # are preserved (speech bubble + text); pixels near it are dropped to
    # reveal the dark gradient underneath.
    base = np.array([120, 115, 235], dtype=np.int16)
    diff = arr[..., :3] - base[None, None, :]
    dist2 = (diff * diff).sum(axis=-1)
    alpha = arr[..., 3]
    keep = np.where(dist2 > 80 * 80, alpha, 0).astype(np.uint8)
    keep_img = Image.fromarray(keep, mode="L").filter(
        ImageFilter.GaussianBlur(radius=0.6)
    )

    out = Image.fromarray(np.dstack([bg, np.full((h, w), 255, np.uint8)]),
                           mode="RGBA")
    fg = Image.fromarray(arr.astype(np.uint8), mode="RGBA")
    out.paste(fg, mask=keep_img)
    # Restore original outer alpha so the rounded corners match the light
    # icon exactly (Xcode will apply the system corner mask on top).
    out.putalpha(Image.fromarray(alpha.astype(np.uint8), mode="L"))
    out.save(DARK_OUT, format="PNG")


def build_tinted() -> None:
    """Produce a grayscale luminance map for iOS 18 Tinted icons.

    Apple expects a single-layer image; brighter pixels receive more of the
    user-selected tint. We collapse the light icon to perceived luminance,
    soft-feather the result, and emit it as L+A so rounded corners survive.
    """
    src = _ensure_rgba(Image.open(SOURCE))
    rgb = src.convert("RGB")
    alpha = src.getchannel("A")

    # Standard Rec. 709 luminance weights.
    lum = rgb.convert("L")

    # Boost contrast a bit so the white speech bubble + text dominate while
    # the lavender background recedes (it ends up near-mid-gray).
    lum = ImageChops.multiply(lum, lum)  # squares luminance, deepens darks

    # Re-stretch to use the full 0..255 range without crushing whites.
    minv, maxv = lum.getextrema()
    if maxv > minv:
        scale = 255.0 / (maxv - minv)
        lum = lum.point(lambda p: int(min(255, max(0, (p - minv) * scale))))

    # Feather slightly to avoid aliasing when the system rescales.
    lum = lum.filter(ImageFilter.GaussianBlur(radius=0.4))

    out = Image.merge("LA", (lum, alpha))
    out.save(TINTED_OUT, format="PNG")


# iOS 18 single-size universal AppIcon schema. Replacing the older
# per-idiom set lets Xcode auto-generate every smaller variant from the
# 1024x1024 source while still picking Light / Dark / Tinted at runtime.
CONTENTS = {
    "images": [
        {
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
            "filename": LIGHT_OUT.name,
        },
        {
            "appearances": [
                {"appearance": "luminosity", "value": "dark"}
            ],
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
            "filename": DARK_OUT.name,
        },
        {
            "appearances": [
                {"appearance": "luminosity", "value": "tinted"}
            ],
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
            "filename": TINTED_OUT.name,
        },
    ],
    "info": {"author": "xcode", "version": 1},
}


def write_contents() -> None:
    (ICON_SET / "Contents.json").write_text(
        json.dumps(CONTENTS, indent=2) + "\n"
    )
    # Note: legacy per-size Icon-App-*@2x.png files are intentionally NOT
    # deleted. They sit unused alongside the new universal entries so this
    # change is reversible via `git checkout` if anything regresses.


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Source icon not found: {SOURCE}")
    build_light()
    build_dark()
    build_tinted()
    write_contents()
    print(f"Wrote {LIGHT_OUT.name}, {DARK_OUT.name}, {TINTED_OUT.name}")
    print("Updated Contents.json to the iOS-18 universal schema.")


if __name__ == "__main__":
    main()
