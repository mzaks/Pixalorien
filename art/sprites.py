#!/usr/bin/env python3
# Pixalorien's sprites, drawn as text: one letter a pixel, '.' none.
# Writes art/sprites.png (the sheet the game reads) and
# art/sprites_x8.png (a preview, 8 times, on the cave's dark).
# Run from the game's folder: python3 art/sprites.py (needs magick).
#
# The sheet: the soldiers, a row of 10 pixels each for (soldier * 2 +
# facing) (facing 0 right, 1 left), a pose every 10 pixels across (5 by
# 9; down 9 by 3); the creatures from y 60, a row of 8 each by kind, at
# x (facing * 2 + frame) * 8; the chest at 0,100 (6 by 4).
import os, subprocess, sys

def rgb(h): return ((h >> 16) & 255, (h >> 8) & 255, h & 255)

COMMON = {'v': 0x40e0ff, 'l': 0xd8fcff, 'L': 0x7ab8c8, 'j': 0x6a6e74, 'J': 0x4a4c50,
          'f': 0x40e0ff, 'F': 0xe8ffff, 'g': 0x2a2c30, 'c': 0xd8a420, 'C': 0x7a5010,
          'b': 0x3a2c22}
SOLDIERS = [
  ({'m': 0xd8b878, 'd': 0x9a7a48, 's': 0xb8642c},
   ["..l..",
    ".mmm.",
    ".mvv.",
    "ssdd.",
    "jmmm.",
    "jmmm.",
    ".ddd."]),
  ({'m': 0xb85a34, 'd': 0x7a3a22, 'r': 0xe8905a, 'p': 0x5a4632},
   [".....",
    ".mmm.",
    ".mvv.",
    "prrmm",
    "prmmm",
    "pmmm.",
    ".ddd."]),
  ({'m': 0x7a98b0, 'd': 0x4e6478, 'h': 0xd8b040},
   [".ll..",
    ".mmm.",
    ".mvv.",
    ".ddd.",
    "jmmm.",
    "jmmmh",
    ".ddh."]),
]
LEGS = {
  'stand': [".m.m.", ".b.b."],
  'walk0': [".d.m.", "b...b"],
  'walk1': ["..dm.", "..bb."],
  'walk2': [".m.d.", "b...b"],
  'walk3': ["..md.", "..bb."],
  'climb0': [".m.d.", ".b..."],
  'climb1': [".d.m.", "...b."],
  'fly': ["..mm.", ".bb.."],
  'fall': [".m.m.", "b...b"],
}
POSES = ['stand0', 'stand1', 'walk0', 'walk1', 'walk2', 'walk3', 'climb0', 'climb1', 'fly0', 'fly1',
         'fall', 'shoot', 'haul', 'carry0', 'carry1', 'carry2', 'carry3', 'down']

def put(rows, r, c, ch):
    rows[r] = rows[r][:c] + ch + rows[r][c + 1:]

def soldier(top, pose):
    if pose == 'down':
        return [".........", "bmmdmmmmv", "bmmdjjmmm"]
    rows = list(top)
    legs = 'stand'
    if pose.startswith('walk'): legs = pose
    elif pose.startswith('carry'): legs = 'walk' + pose[-1]
    elif pose.startswith('climb'): legs = pose
    elif pose.startswith('fly'): legs = 'fly'
    elif pose == 'fall': legs = 'fall'
    rows = rows + LEGS[legs]
    if pose == 'stand1':
        rows = [r.replace('l', 'L') for r in rows]
    if pose == 'shoot':
        put(rows, 4, 4, 'g')
    if pose == 'climb0':
        put(rows, 0, 4, 'm'); put(rows, 1, 4, 'm')
    if pose == 'climb1':
        put(rows, 2, 4, 'm'); put(rows, 3, 4, 'm')
    if pose.startswith('fly'):
        put(rows, 6, 0, 'F'); put(rows, 7, 0, 'f')
        if pose == 'fly1': put(rows, 8, 0, 'f')
    if pose == 'fall':
        put(rows, 0, 0, 'm'); put(rows, 0, 4, 'm'); put(rows, 1, 0, 'm'); put(rows, 1, 4, 'm')
    if pose == 'haul':
        put(rows, 0, 4, 'm'); put(rows, 1, 4, 'm')
    if pose.startswith('carry'):
        put(rows, 4, 3, 'c'); put(rows, 4, 4, 'c'); put(rows, 5, 3, 'C'); put(rows, 5, 4, 'c')
    return rows

CREATURES = [
  ({'p': 0xd8d0b0, 'd': 0x8a8470, 'e': 0xf0f0a0},
   [["..pp.", ".pppe", "d.d.d"],
    ["..pp.", ".pppe", ".d.d."]]),
  ({'w': 0x5a3e7a, 'b': 0x8a64b8, 'e': 0xf0f0a0},
   [["w...w", "wwbew", "..b.."],
    [".....", "wwbew", "w...w"]]),
  ({'p': 0xb09068, 'd': 0x7a6048, 't': 0xf0ead8, 'k': 0x2a1810, 'e': 0xf0f0a0},
   [["..dpd..", ".dpppd.", "dppptkt", "dppekkk", "dppptkt", ".dpppd.", "..dpd.."],
    ["..dpd..", ".dpppd.", "dpppttt", "dppetkt", "dpppttt", ".dpppd.", "..dpd.."]]),
  ({'k': 0x2a2224, 'o': 0xff6a20, 'O': 0xffc040, 'e': 0xffe080},
   [["o....kk", "okkkkke", ".kokokO", ".kkkkk.", ".k.k.k."],
    ["o....kk", "okkkkke", ".kokokO", ".kkkkk.", "k.k.k.."]]),
  ({'g': 0x70b040, 'G': 0x4a7a2a, 'w': 0xe0d8c0, 'k': 0x1a2a10, 'e': 0xf0f0a0},
   [["..gg..", ".gGgg.", "gggeGk", "ggGgkk", "wwggww", "wwwwww"],
    ["..gg..", ".gGgg.", "gggeGg", "ggGggg", "wwggww", "wwwwww"]]),
]
# The eye of each kind, facing right (the game reddens it when it hunts).
EYES = [(4, 1), (3, 1), (3, 3), (6, 1), (3, 2)]
CHEST = ({'c': 0xd8a420, 'C': 0x7a5010, 'y': 0xfff0a0},
         [".CCCC.", "CccccC", "CCyCCC", "CccccC"])

W, H = 180, 186
px = [[None] * W for _ in range(H)]

def blit(rows, pal, x0, y0, mirror=False):
    for r, line in enumerate(rows):
        if mirror: line = line[::-1]
        for c, ch in enumerate(line):
            if ch == '.': continue
            col = pal.get(ch, COMMON.get(ch))
            if col is None: sys.exit("no colour for %r" % ch)
            px[y0 + r][x0 + c] = rgb(col)

for s, (pal, top) in enumerate(SOLDIERS):
    for face in range(2):
        for i, pose in enumerate(POSES):
            rows = soldier(top, pose)
            blit(rows, pal, i * 10, (s * 2 + face) * 10, face == 1)
for k, (pal, frames) in enumerate(CREATURES):
    ex, ey = EYES[k]
    assert frames[0][ey][ex] == 'e', k
    for face in range(2):
        for f, rows in enumerate(frames):
            blit(rows, pal, (face * 2 + f) * 8, 60 + k * 8, face == 1)
blit(CHEST[1], CHEST[0], 0, 100)

# The ship, over its cells (gen.ent's `ship`, side 1): the same shape
# from the same sums, coloured: plates and rivets, rust, the team's cyan
# stripe, the canopy's glint, the nozzle, scorched underneath, outlined.
# 68 by 41 from (sx - 34, ground - 37); at (0, 104) facing right, at
# (0, 145) facing left.
SHIP_W, SHIP_H = 68, 41
def ship_sprite():
    kind = {}
    def tdiv(a, b): return int(a / b)
    for dx in range(-32, 33):
        f = dx
        half = 9 - tdiv(f * 9, 33) if f > 0 else 9 - tdiv(-f, 8)
        for dy in range(-half, half + 1):
            glass = 10 < f < 24 and dy < -1 and dy > -half + 1
            kind[(dx, -16 + dy)] = ('glass' if glass else 'hull', dy, half, f)
    for k in range(10):
        x = -(24 + k)
        for dy in range(10 - k):
            kind[(x, -26 - dy)] = ('fin', dy, 10 - k, k)
    # A strut from the fin down to the hull (drawn only).
    for x in (-25, -26, -27):
        for y in range(-25, -21):
            kind.setdefault((x, y), ('strut', 0, 0, 0))
    for leg in range(2):
        lx = (leg * 2 - 1) * 18
        for y in range(-8, 3):
            for d in range(2):
                kind[(lx + d + ((leg * 2 - 1) if y > -3 else 0), y)] = ('leg', y, 0, 0)
    rust = [(-20, -12, 3), (5, -20, 2), (-8, -9, 2), (16, -14, 2), (-27, -17, 2)]
    def mixc(a, b, t):
        ra, ga, ba = rgb(a); rb, gb, bb = rgb(b)
        return (int(ra + (rb - ra) * t), int(ga + (gb - ga) * t), int(ba + (bb - ba) * t))
    img = [[None] * SHIP_W for _ in range(SHIP_H)]
    for (x, y), (k, a, b, c) in kind.items():
        col = None
        if k == 'hull':
            dy, half, f = a, b, c
            base = mixc(0xa8b0b8, 0x5c636b, (dy + half) / max(1, 2 * half))
            col = base
            if (x + 40) % 9 == 0: col = mixc(0x000000, 0x5c636b, 0.0) if False else tuple(int(v * 0.72) for v in base)
            if (x + 40) % 9 == 0 and dy % 3 == 0: col = rgb(0xd8dee4)
            if dy == 0: col = rgb(0x40464c)
            for (rx, ry, rr) in rust:
                if (x - rx) ** 2 + (y - ry) ** 2 <= rr * rr:
                    col = rgb(0x9a5230 if (x + y) % 2 else 0x7e4024)
            if dy == -3 and -28 <= f <= 9: col = rgb(0x40e0ff)
            if dy > 0 and x < -18: col = mixc(0x2a2a2c, 0x5c636b, 0.45)
            if f <= -31 and abs(dy) <= 3: col = rgb(0x2a2e34)
            if f == -32 and abs(dy) <= 1: col = rgb(0xffa040)
            if dy == -half: col = rgb(0xd0d8de)
            if dy == half: col = rgb(0x30363c)
        elif k == 'glass':
            col = rgb(0xb8f0ff) if (x - y) % 7 in (0, 1) else rgb(0x3a8ab4)
        elif k == 'fin':
            dy, n, kk = a, b, c
            col = rgb(0x7a828a) if dy < n - 1 else rgb(0x9a5230)
            if kk == 0: col = rgb(0xb0b8c0)
        elif k == 'strut':
            col = rgb(0x4e545c) if x != -25 else rgb(0x7a828a)
        elif k == 'leg':
            col = rgb(0x30353a) if a >= 1 else rgb(0x4e545c)
        img[y + 37][x + 34] = col
    out = [row[:] for row in img]
    for r in range(SHIP_H):
        for c in range(SHIP_W):
            if img[r][c] is None:
                for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    rr, cc = r + dr, c + dc
                    if 0 <= rr < SHIP_H and 0 <= cc < SHIP_W and img[rr][cc] is not None:
                        out[r][c] = rgb(0x1e2226)
    return out

img = ship_sprite()
for r in range(SHIP_H):
    for c in range(SHIP_W):
        if img[r][c] is not None:
            px[104 + r][c] = img[r][c]
            px[145 + r][SHIP_W - 1 - c] = img[r][c]

here = os.path.dirname(os.path.abspath(__file__))
pam = os.path.join(here, "sprites.pam")
with open(pam, "wb") as out:
    out.write(b"P7\nWIDTH %d\nHEIGHT %d\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n" % (W, H))
    for row in px:
        for p in row:
            out.write(bytes(p + (255,)) if p else b"\0\0\0\0")
subprocess.check_call(["magick", pam, os.path.join(here, "sprites.png")])
subprocess.check_call(["magick", pam, "-background", "#1a1210", "-flatten", "-filter", "point",
                       "-resize", "800%", os.path.join(here, "sprites_x8.png")])
os.remove(pam)
print("sprites.png %dx%d" % (W, H))
