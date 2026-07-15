#!/usr/bin/env python3
"""Generate the cc-pet AppIcon.icns from drawn primitives."""
import os
import subprocess
from PIL import Image, ImageDraw

PROJECT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RES_DIR = os.path.join(PROJECT, "Resources")
ICONSET = os.path.join(RES_DIR, "AppIcon.iconset")
ICNS    = os.path.join(RES_DIR, "AppIcon.icns")

HEAD_YELLOW = (255, 214, 13, 255)
EAR_YELLOW  = (245, 194, 5, 255)
EYE_BLACK   = (26, 26, 31, 255)
SNOUT_PINK  = (255, 168, 184, 255)
NOSTRIL     = (199, 82, 107, 255)


def draw_pig(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size / 1024.0  # scale factor

    # Head (yellow round ellipse, slightly wider than tall)
    head_box = (160 * s, 240 * s, 864 * s, 820 * s)
    d.ellipse(head_box, fill=HEAD_YELLOW)

    # Ears — rounded triangles via polygon (head sits at z above ears)
    # Left ear
    left_ear = [
        (300 * s, 280 * s),
        (370 * s, 90 * s),
        (440 * s, 280 * s),
    ]
    # Right ear
    right_ear = [
        (584 * s, 280 * s),
        (654 * s, 90 * s),
        (724 * s, 280 * s),
    ]
    d.polygon(left_ear, fill=EAR_YELLOW)
    d.polygon(right_ear, fill=EAR_YELLOW)
    # Re-draw head over ear bases so they look attached
    d.ellipse(head_box, fill=HEAD_YELLOW)

    # Left eye — solid filled ellipse
    eye_w, eye_h = 70 * s, 90 * s
    le_cx, le_cy = 400 * s, 500 * s
    d.ellipse(
        (le_cx - eye_w / 2, le_cy - eye_h / 2,
         le_cx + eye_w / 2, le_cy + eye_h / 2),
        fill=EYE_BLACK,
    )

    # Right eye — winking arc "︵" drawn as a thick stroked arc
    re_cx, re_cy = 624 * s, 510 * s
    arc_w, arc_h = 110 * s, 80 * s
    # Top half of an ellipse → upside-down U arc
    d.arc(
        (re_cx - arc_w / 2, re_cy - arc_h,
         re_cx + arc_w / 2, re_cy + arc_h),
        start=200, end=340,
        fill=EYE_BLACK, width=int(18 * s),
    )

    # Snout — pink ellipse
    snout_w, snout_h = 320 * s, 210 * s
    sn_cx, sn_cy = 512 * s, 660 * s
    d.ellipse(
        (sn_cx - snout_w / 2, sn_cy - snout_h / 2,
         sn_cx + snout_w / 2, sn_cy + snout_h / 2),
        fill=SNOUT_PINK,
    )

    # Nostrils
    nos_w, nos_h = 50 * s, 70 * s
    for nx in (sn_cx - 55 * s, sn_cx + 55 * s):
        d.ellipse(
            (nx - nos_w / 2, sn_cy - nos_h / 2,
             nx + nos_w / 2, sn_cy + nos_h / 2),
            fill=NOSTRIL,
        )

    return img


def main():
    os.makedirs(ICONSET, exist_ok=True)

    # Render at the largest (supersampled) size and downscale for crispness
    master = draw_pig(2048).resize((1024, 1024), Image.LANCZOS)

    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for name, sz in sizes:
        out = os.path.join(ICONSET, name)
        master.resize((sz, sz), Image.LANCZOS).save(out, "PNG")
        print(f"  wrote {name} ({sz}x{sz})")

    # Pack iconset → icns
    subprocess.run(
        ["iconutil", "-c", "icns", ICONSET, "-o", ICNS],
        check=True,
    )
    print(f"\n✅ {ICNS}")


if __name__ == "__main__":
    main()
