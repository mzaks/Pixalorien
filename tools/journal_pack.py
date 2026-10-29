# Writes journal.ent's pack() and unpack(): the world's small state (what
# is not one of the four big planes) as words, and back. Run it after a
# change to what the world holds (a field, a buffer, a unique that is
# not transient) and put what it prints in place of the two systems and
# the constants WORDS, FLOATS, WAY0 and WAYS in journal.ent.
#   python3 tools/journal_pack.py
uniques = [("Now", "tick i"), ("Sim", "tick i"), ("Sight", "round i, seen i, flare b"),
  ("Dangers", "lava i, gas i"), ("Routes", "search i, expanded i, cut i, caught i"),
  ("Plan", "strategy i, turn i, safe i, backed i"), ("Loot", "by i, x i, y i, lifted b, dropped i"),
  ("Game", "over i, at i"), ("Tools", "bolts i, broken i, blasts i, bx i, by i, bt i, scanned i, cut i"),
  ("Fauna", "habitats i, placed i, next i, attacks i, harm i, killed i, hunts i, dug i, spits i, knocks i, guards i"),
  ("Harms", "fall i, blast i, burn i, crush i")]
buffers = [("Orders", 3, "set b, order i, gx i, gy i, lead i, auto b"),
  ("Feet", 3, "x i, y i, dx f, dy f, len i, down b"), ("Hurt", 3, "hp i, knock i"),
  ("Beasts", 64, "x i, y i, alive b, state i, kind Beast"), ("Wound", 64, "hp i"),
  ("Noises", 64, "x i, y i, loud i, until i, from i, heard b"),
  ("Spits", 16, "on b, x f, y f, ux f, uy f, left i"),
  ("Shots", 32, "on b, kind i, x f, y f, ux f, uy f, left i, fuse i, stuck b"),
  ("Team", 3, "x f, y f, fx f, fy f"),
  ("Trail", 512, "x i, y i"), ("Stir", 512, "s u8, on u8, bang u8, fell i, went i, ran i"),
  ("Fresh", 512, "d u8"), ("Sky", 2048, "top i"), ("Way", 24576, "n i, kind u8, cost i")]
comps = [("Pixalorien", "p", 3, "id", "id i, x i, y i, ex i, ey i, t i, fx f, fy f, fall i, fuel i, order i, gx i, gy i, cy i, lead i, len i, k i, due b, planned i, searched i, looked i, tx i, ty i, busy b, work i, cool i, charges i, flares i, hp i, down b, guard i, struck i, stuck b, mine b, drop i, bruise i, peek i"),
  ("Creature", "c", 64, "id", "id i, kind Beast, alive b, x i, y i, hx i, hy i, hp i, state i, tx i, ty i, prey i, lost i, cool i, wait i, up i, stuck i, fled i"),
  ("Chunk", "ch", 512, "k", "n i, calm i")]

def fields(s): return [tuple(f.split()) for f in s.split(", ")]
def to_word(e, k):
    if k == "i": return e
    if k == "b": return f"if {e} {{ 1 }} else {{ 0 }}"
    return f"{e} as i32"
def from_word(e, k):
    if k == "i": return e
    if k == "b": return f"{e} != 0"
    return f"{e} as {k}"

pack, unpack = [], []
wo, fo = 0, 0
def wslot(n):
    global wo; b = wo; wo += n; return b
def fslot(n):
    global fo; b = fo; fo += n; return b
for u, fs in uniques:
    for f, k in fields(fs):
        o = wslot(1)
        pack.append(f"  Wd[{o}].w = {to_word(u+'.'+f, k)}")
        unpack.append(f"  {u}.{f} = {from_word(f'Wd[{o}].w', k)}")
for b, n, fs in buffers:
    fl = fields(fs)
    ints = [x for x in fl if x[1] != "f"]; flts = [x for x in fl if x[1] == "f"]
    pl, ul = [], []
    if ints:
        wb = wslot(n * len(ints))
        for j, (f, k) in enumerate(ints):
            pl.append(f"    Wd[{wb} + i * {len(ints)} + {j}].w = {to_word(f'{b}[i].{f}', k)}")
            ul.append(f"    {b}[i].{f} = {from_word(f'Wd[{wb} + i * {len(ints)} + {j}].w', k)}")
    if flts:
        fb = fslot(n * len(flts))
        for j, (f, k) in enumerate(flts):
            pl.append(f"    Fl[{fb} + i * {len(flts)} + {j}].f = {b}[i].{f}")
            ul.append(f"    {b}[i].{f} = Fl[{fb} + i * {len(flts)} + {j}].f")
    if b == "Way":
        way0 = wb
        pack += ["  // (The ways only when they changed, or when all is packed.)", "  if Undo.way {", f"    for i in 0..{n} {{"] + ["  " + x for x in pl] + ["    }", "  }"]
        unpack += ["  if Undo.way {", f"    for i in 0..{n} {{"] + ["  " + x for x in ul] + ["    }", "  }"]
    else:
        pack += [f"  for i in 0..{n} {{"] + pl + ["  }"]
        unpack += [f"  for i in 0..{n} {{"] + ul + ["  }"]
for c, v, n, idf, fs in comps:
    fl = fields(fs)
    ints = [x for x in fl if x[1] != "f"]; flts = [x for x in fl if x[1] == "f"]
    pl, ul = [], []
    wb = wslot(n * len(ints))
    for j, (f, k) in enumerate(ints):
        pl.append(f"    Wd[{wb} + {v}.{idf} * {len(ints)} + {j}].w = {to_word(f'{v}.{f}', k)}")
        if f != idf: ul.append(f"    {v}.{f} = {from_word(f'Wd[{wb} + {v}.{idf} * {len(ints)} + {j}].w', k)}")
    if flts:
        fb = fslot(n * len(flts))
        for j, (f, k) in enumerate(flts):
            pl.append(f"    Fl[{fb} + {v}.{idf} * {len(flts)} + {j}].f = {v}.{f}")
            ul.append(f"    {v}.{f} = Fl[{fb} + {v}.{idf} * {len(flts)} + {j}].f")
    pack += [f"  for {v}: {c} in turn by {v}.{idf} {{"] + pl + ["  }"]
    unpack += [f"  for {v}: mut {c} in turn by {v}.{idf} {{"] + ul + ["  }"]
print(f"const WORDS = {wo}\nconst FLOATS = {fo}\nconst WAY0 = {way0}\nconst WAYS = {24576 * 3}\n")
print("// The small state as words (`Wd`, `Fl`).\nsystem pack() {")
print("  Undo.way = !Back.ready || Serial.way != Undo.way_at\n  Undo.way_at = Serial.way")
print("\n".join(pack)); print("}\n")
print("// And back.\nsystem unpack() {"); print("\n".join(unpack)); print("}")
