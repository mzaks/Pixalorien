#!/usr/bin/env python3
# The macOS icon, made from art/app-icon.png: Apple's icon grid on a
# canvas of 1024 has the shape 824 square in its middle (100 round it)
# with the corners of a squircle and a soft shadow under it; Finder and
# the Dock draw the canvas as it is. app-icon.png fills nearly all of
# its canvas (its picture 1008 by 949, white over and under it), so on a
# Mac it stood out bigger than every other icon, its white showing.
#
# Writes art/app-icon-mac.png: the picture's middle square (949, from
# 37,37) scaled to 824, cut to a squircle (|x|^5 + |y|^5 <= 1, which is
# close to Apple's corners), a shadow (black at 30%, blurred 14, 10
# down), on a clear 1024 canvas. tools/build_release.sh makes the .icns
# from it; tools/build_release_linux.sh puts it in the AppImage and the
# archive (the white showed there too). Run from the game's folder: python3 art/mac_icon.py (needs
# magick and numpy).
import os, subprocess, tempfile
import numpy as np

CANVAS = 1024
SHAPE = 824
CROP = (949, 37, 37)          # the picture's square: size, left, top
N = 5.0                        # the squircle's power
SS = 4                         # samples a pixel, each way, for its edge

def mask(size):
    """The squircle, 0 to 255, its edge smoothed by sampling."""
    k = size * SS
    c = (np.arange(k) + 0.5) / k * 2.0 - 1.0
    x, y = np.meshgrid(c, c)
    inside = (np.abs(x) ** N + np.abs(y) ** N <= 1.0).astype(np.float64)
    m = inside.reshape(size, SS, size, SS).mean(axis=(1, 3))
    return (m * 255.0 + 0.5).astype(np.uint8)

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    src = os.path.join(here, "app-icon.png")
    out = os.path.join(here, "app-icon-mac.png")
    with tempfile.TemporaryDirectory() as tmp:
        art = os.path.join(tmp, "art.png")
        cut = os.path.join(tmp, "mask.png")
        shaped = os.path.join(tmp, "shaped.png")
        size, left, top = CROP
        subprocess.run(["magick", src, "-crop", f"{size}x{size}+{left}+{top}", "+repage",
                        "-alpha", "off", "-filter", "Lanczos", "-resize", f"{SHAPE}x{SHAPE}!", art],
                       check=True)
        subprocess.run(["magick", "-size", f"{SHAPE}x{SHAPE}", "-depth", "8", "gray:-", cut],
                       input=mask(SHAPE).tobytes(), check=True)
        subprocess.run(["magick", art, cut, "-compose", "CopyOpacity", "-composite", shaped],
                       check=True)
        off = (CANVAS - SHAPE) // 2
        subprocess.run(["magick", "-size", f"{CANVAS}x{CANVAS}", "xc:none",
                        "(", shaped, "-background", "black", "-shadow", "30x14+0+0", ")",
                        "-geometry", f"+{off - 28}+{off - 28 + 10}", "-compose", "Over", "-composite",
                        shaped, "-geometry", f"+{off}+{off}", "-compose", "Over", "-composite",
                        "-depth", "8", "-define", "png:color-type=6", out], check=True)
    print("wrote", out)

main()
