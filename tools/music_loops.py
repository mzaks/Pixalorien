#!/usr/bin/env python3
"""Cuts "Mist City" by Section7 (OpenGameArt, CC-BY 4.0) into the pieces
music.ent plays: bar-aligned loops (130 beats a minute, the first bar
line at 1.837 s, both found from the onsets), some filtered, and two
endings heard once. A loop's last 40 ms are faded into its head, so it
goes round without a seam. Needs numpy and ffmpeg.

  python3 tools/music_loops.py music/mist_city.ogg music/loops
"""
import subprocess, sys
import numpy as np

SR = 44100
BEAT = 60 / 130.002
BAR = 4 * BEAT
FIRST = 0.452 + 3 * BEAT
SEAM = int(0.04 * SR)

FILTERS = {
    "dry": None,
    # Underground: muffled, an echo off the walls.
    "under": "lowpass=f=900:p=2,lowpass=f=1400,aecho=0.8:0.6:277:0.35,volume=1.3",
    # Deep down: darker, two echoes.
    "deep": "lowpass=f=500:p=2,aecho=0.8:0.7:415|692:0.4|0.25,volume=1.6",
    # The bright part, thinned (no deep bass, no hiss).
    "thin": "highpass=f=180,lowpass=f=5000,volume=0.9",
}

# name, filter, first bar, bars, looped (or once, with a fade of seconds)
PIECES = [
    ("title", "dry", 23, 16, None),
    ("land", "dry", 7, 8, None),
    ("calm", "dry", 15, 8, None),
    ("open", "thin", 39, 16, None),
    ("under", "under", 15, 8, None),
    ("deep", "deep", 79, 8, None),
    ("danger", "dry", 55, 16, None),
    ("win", "dry", 87, 8, 3.0),
    ("lost", "deep", 71, 4, 2.5),
]


def decode(path, af):
    cmd = ["ffmpeg", "-v", "error", "-i", path]
    if af:
        cmd += ["-af", af]
    cmd += ["-f", "f32le", "-ac", "2", "-ar", str(SR), "-"]
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2)


def at(bar):
    return int(round((FIRST + bar * BAR) * SR))


def encode(path, x):
    peak = np.abs(x).max()
    if peak > 0.98:
        x = x * 0.98 / peak
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ac", "2", "-ar", str(SR), "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "5", path],
                   input=x.astype(np.float32).tobytes(), check=True)


def main():
    src, out = sys.argv[1], sys.argv[2]
    songs = {k: decode(src, af) for k, af in FILTERS.items()}
    for name, f, first, bars, fade in PIECES:
        x = songs[f]
        i = at(first)
        n = min(at(first + bars) - i, len(x) - i)
        piece = x[i:i + n].copy()
        if fade is None:
            # What follows the last bar, faded into the first.
            t = np.linspace(0, np.pi / 2, SEAM)[:, None]
            piece[:SEAM] = piece[:SEAM] * np.sin(t) + x[i + n:i + n + SEAM] * np.cos(t)
            jump = np.abs(piece[0] - piece[-1]).max()
            step = np.abs(np.diff(piece, axis=0)).mean(axis=0).max()
            how = "loop, seam %.4f (a step %.4f)" % (jump, step)
        else:
            k = int(fade * SR)
            piece[-k:] *= np.linspace(1, 0, k)[:, None] ** 2
            how = "once"
        encode("%s/%s.ogg" % (out, name), piece)
        print("%-7s bars %2d-%2d %5.2f s %s" % (name, first, first + bars - 1, n / SR, how))


main()
