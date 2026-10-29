# Pixalorien

Three Pixaloriens land on a desert planet to bring a treasure back from
a vault deep under its surface. A single-player game of real time
with pause (and going back) over a world of falling sand, in ent-lang. The design is in
[DESIGN.md](DESIGN.md).

## Step 1: the world (done)

- `matter.ent`: the automaton on 2048 by 1024 cells, kept in 512 chunks
  of 64 by 64 that sleep while nothing in them or beside them moves.
  Phases: fall (twice), slide (Margolus blocks), flow (four times), react,
  wake. Each phase works every awake chunk's cells from the cells as they
  were (gather-style), so one core and all cores give the same world.
- `gen.ent`: the world from a seed: dunes and mesas, sandstone strata over
  rock over bedrock, chambers and ridge tunnels, lakes at mid depth, lava
  at the bottom, four entrances (mine shaft, cave mouth, sinkhole, lava
  tube) with worm tunnels on to the vault, the vault and its treasure, 40
  sealed pockets (air, water, gas, lava) with warm or damp rock round
  lava and water, crumbling rock over tunnels, crystals, the ship.
- `view.ent`: the camera and the mini map.
- `pixalorien.ent`: the program.

## Step 2: sight (done)

- `matter.ent`: light. `Sky` is the first cell down each column that is
  not air or gas, and the open cells above it are in daylight. Lava,
  fire, crystal, the treasure and flares (a new powder that burns down
  in about 6000 ticks) glow. `glow` spreads light a cell a tick through
  what light passes (air, gas, water and smoke at double cost, glass,
  ladders), in a field of two copies read and written in turn, so it
  goes out as fast as it spread. It runs in the awake chunks like the
  other phases and stirs its chunk when the light changes, so a chunk
  sleeps once its light is settled.
- `sight.ent`: each of the three eyes (placeholders for the Pixaloriens
  of step 3) casts 1440 rays up to 180 cells (water and smoke count
  three a cell); a chunk near an eye then checks each of its cells
  against the ray toward it, and a cell in reach is seen where it is lit
  by the world's light or the eye's helmet lamp (a cone of 32 cells the
  way it faces, 10 cells all round). `Known` remembers each cell as it
  was when last seen; the surface is known from the landing.
- `view.ent`: unseen cells black, remembered ones dim as they were,
  those seen now in full, darker the less light falls on them; the sky
  over known ground always. The mini map shows what is known, the ship,
  the vault and the team.

## Step 3: the Pixaloriens (done)

- `team.ent`: three Pixaloriens, bodies 3 wide and 7 high. They walk a
  third of a cell a tick and step up to 5 cells; they climb ladders,
  swim, drop, pull themselves up on the grapple (reach 64, half a cell a
  tick) and fly on the jetpack (a cell a tick, 90 ticks of fuel, full
  again in 300 on the ground; a hop only from a full tank). Routes are
  A* over `Nav`, a map of where a body is free, can stand, holds a rung
  or swims, made from what is *known*, chunk by chunk where something
  new was seen. The unknown counts as passable but dear. From every
  place a body can stand the search tries walking both ways, the
  grapple to the first ledge above, and slants (1:3 to 3:1 and level)
  for the jetpack. A grapple pull only goes up, onto a place whose
  edge its hook holds on (rock-hard matter, wood, a ladder, for now
  sandstone; 2026-10-28);
  across a gap or onto soft matter only the jetpack goes. Each move is checked against the real cells as it is
  made; when the world is not as remembered the Pixalorien learns the
  cells round it and searches again. Gravity is real: a fall that lands
  where a planned drop would have continues the way. A fall not planned
  that would harm, with no fuel to brake, is caught by the grapple: shot
  at the nearest ledge above it holds on, pulled up there
  (check/grapple.ent).
- `turns.ent`: time, a tick at a time (60 a second; turns of five
  seconds until 2026-10-29, see "Time, not turns"). Orders are taken at
  the next tick: go (to a place, the team spread out), wait, follow.
  Space pauses, `,` and `.` slower and faster (1, 2, 4 times).
- `pixalorien.ent`: the bodies with visor, the way each one will take
  (dots coloured by move), the goals, the time bar and each one's order
  and fuel.

Keys (besides those above): 1, 2, 3 choose a Pixalorien (Shift adds),
4 chooses all, a click on one chooses it; a left click in the world
sends the chosen there; T makes them follow the one under the mouse,
H makes them wait, F drops a flare, V shows the whole world.

## Step 4: tools and matter (done)

- `matter.ent`: new matter: ice (melts by heat, clear to light),
  rubble (a heavy powder: broken rock), the flash of burning gas (gas
  touched by fire, lava or a bolt goes up a cell a tick, gone in a few
  ticks) and crystal shards (a glowing powder). Every kind has a
  hardness: soft (sandstone, crumbling rock, ice, wood, sand), rock,
  obsidian, never (bedrock, metal, the treasure). Crumbling rock that
  is shaken (by a blast, a bolt, feet, or rubble or a flash beside it)
  falls as rubble while nothing holds it from below, and shakes what is
  beside it: undermined, a patch caves in.
- `gen.ent`: some lakes frozen over (a crust of ice), ice plugs across
  four side tunnels.
- `tools.ent`: an order with a tool is aimed at a place; the
  Pixalorien goes toward it until it can use the tool from where it
  stands (the line from its eye reaches the place within the tool's
  reach), then stays and uses it:
  - blaster: a bolt every 20 ticks until the place is open (15 at
    most); a bolt sets gas off on its way, and chips rock where it hits
    (soft rock 2 cells round, rock 1, obsidian now and then), shakes
    crumbling rock, melts ice, shatters crystal, sets wood alight;
  - wrist flamer: fire 40 cells long for a second, used from 16 cells
    or closer (it walks up; a place inside ice is fine);
  - charge (4 each): thrown up to 80 cells, sticks, goes off after 2
    seconds: everything breakable 12 cells round broken, crumbling rock
    shaken 28 round;
  - cutting torch: a hole a body wide from where it is toward the
    place, a cell of rock a tick, held in the cut; stops at bedrock;
  - scan: a whole turn at a face within 16 cells, then everything 24
    cells round the place is known;
  - flare (3 each): thrown up to 80 cells, burns where it lands.
- `team.ent`: a move through the unknown is counted dear in the search
  (to keep to what is known) but takes the time it takes (step 3 made
  it as slow as it was counted).

Keys (besides those above), with the mouse on a place: B the chosen
fire their blasters at it, E their flamers, X cut toward it, Q scan
it; C the first chosen throws a charge there, F a flare.

## Step 5: creatures (done)

- `creatures.ent`: five kinds, each in its habitats (6 to 8 a world,
  placed on the tunnels away from the ship, 34 to 45 creatures):
  - crawlers (packs of 4 to 8) run along walls and ceilings in dark
    caves, a cell a tick;
  - gloom bats (5 to 8) hang under the roofs of high chambers, fly
    (two cells a tick when hunting, fluttering), keep out of light (a
    flare drives them off) and knock a Pixalorien aside;
  - rock borers (3) dig through soft rock and rock deep down, making
    tunnels, and come through walls;
  - magma hounds (3) run and swim in lava and set gas and wood alight;
  - spitters (3 or 4) sit by lakes and spit acid, which eats armour
    and rock.
- Sound: what the team does is loud (walking 60, the jetpack 140, a
  bolt 160, a charge 500), and so are gas going up and rock caving in.
  A creature hears a noise whose loudness is more than the way to it
  costs (a cell through air or water, four through rock), sees one of
  the team within 50 cells in a clear line, and crawlers and borers
  feel one within 24 through rock. It hunts what it heard or saw (and
  cries out: the team hears it, a mark at the edge of the view); with
  nothing for 6 seconds it goes home and patrols.
- The team has armour (100); at 0 a Pixalorien is down. It fires back
  at the nearest creature hunting within 100 cells that it has a line
  to, aimed in a hurry (the farther, the more it misses).

## Step 6: strategies and going back (done)

- Three strategies (`turns.ent`, `autopilot`), chosen with F5 manual,
  F6 cautious, F7 brute force; a new choice holds at once. The game
  starts cautious.
  - Manual: each Pixalorien's way is drawn, and an outline where it
    will be in five seconds. Nothing is done unless ordered, and the
    team fires back only at what attacks it.
  - Cautious: the autopilot gives orders every second (to whom
    has none of the player's). The first one up is the scout and goes
    to the treasure; the others follow its trail (a point every five
    seconds), one and two points behind (where it stood, not where it flew). The search pays more
    for the unknown and for the jetpack, and cuts only through rock
    it knows (not liquid, not bedrock). A scout with no way scans the
    rock toward the goal. With a creature hunting near, all back off
    for five seconds to where the scout was before it came, then go on.
    They fire back only when cornered (within 40 cells) or hurt in the
    last 5 seconds.
  - Brute force: all go the shortest way, cutting through rock (a new
    move in the search, its ticks by the rock's hardness), the jetpack
    wherever it is quicker, firing at anything hunting.
- Going back (since 2026-10-29, "Time, not turns"): R 5 seconds,
  Shift+R 30, Home to the landing (and plays on: the game watched
  again), End to the furthest moment. The world is saved
  (`devices/world.ent`) at the landing and every 30 seconds for good
  (`pix_k<n>.sav`), every 5 seconds in a ring of 6 (`pix_r<n>.sav`);
  every order of the player's and every change of strategy is logged
  with its tick (`OrderLog`), apart from the world. Going to a moment
  loads the saved world at or before it and plays the log up to it, as
  quickly as it can (50 ms of it each frame, drawn as it goes). Behind
  the furthest moment the log plays (watching); an order or a strategy
  given there drops the rest of the log and the saved worlds after it,
  and the game goes on from there.
- For a replay to be the run again, all that steers the world is in it
  (the strategy's trail, the creatures, the search marks are a
  counter that is never set back), and the frame is split: `sim()`
  (in `turns.ent`) is a tick of the world, run by the frame when not
  going back and by the quick passes when going back.

## Step 7: the views and choosing (done)

- `views.ent`: one view while the whole team fits in it at 3 points a
  cell or more (with 30 cells round it). Otherwise there is a view for
  each group of those close together, up to three, side by side, left
  to right as they are in the world, each named (1, 2, 3) and with
  its frame on the mini map. Views follow their groups smoothly, at
  most as near as the wheel sets. Two views are joined only when they
  fit with 45 cells to spare, and the views change at most every 45
  frames, so they do not flicker.
- One told to wait (H) gets no view of its own. It gets one while
  something happens near it: a creature hunting within 70 cells, a
  noise within 60, the ground moving (rubble, a flash, lava by it),
  harm. The view stays open until 3 seconds after, labelled with why.
  The player's orders now hold under the autopilot until they are
  done (a wait until another order), so one can be left behind.
- Panning (keys, a drag, the mini map) frees the camera: one view, as
  before. Tab follows the team again.
- Choosing: a click on one of the team chooses it (Shift adds), a drag
  with the left button draws a box and chooses those in it (Shift
  adds), a click elsewhere sends the chosen there (now on the button's
  release). Orders and keys act in the view the mouse is in.

## Step 8: the goal, dying, balance (done)

- `goal.ent`: the chest lies on the vault's floor. G sends the first
  chosen to carry it: it goes there and lifts it (the chest's cells
  are gone from the floor). The carrier walks at half the pace and
  cannot fly; the search gives it grapple pulls only. If it goes down,
  the chest lies where it fell and another can lift it. The game is
  won when the carrier stands by the ship (80 cells from its middle
  at most) and lost when nobody is left. Either way play stops with a
  banner; R goes back from there.
- What harms the team besides creatures (`creatures.ent`, `wounds`):
  - falls of more than 64 cells (an armour point for every 3 cells
    more); the jetpack brakes a fall to a cell a tick while it has
    fuel, except the carrier's;
  - a charge going off within 20 cells (60 at its middle);
  - lava (3 a tick) and fire or a flash (1) touching the body.
  The search counts a harmful drop dear, cautious three times as dear.
- The autopilot, homeward: once one of them is within 40 cells of the
  chest, the nearest up lifts it. The others wait by it, then all go
  to the ship, on the side the carrier is on (it cannot fly over the
  hull). Cautious sends one ahead and has the last follow behind the
  carrier. A cautious soldier whose last search found no way searches
  once as brute force would, cutting through rock not yet known.
- The player's orders hold under the autopilot until they are done.

Run from `build/`:

    ENT_PARALLEL_MIN=64 ../../ent-lang/tools/ent run --parallel -I .. ../pixalorien.ent

(`ENT_PARALLEL_MIN` must be set when building: there are only 512 chunks.)

Keys: WASD or the arrows pan, the wheel zooms, a right or middle drag
pans, a click on the mini map goes there, Space runs or stops the world,
F3 shows the awake chunks, N makes a new world from the next seed,
F5/F6/F7 the strategy, R and Shift+R go back, G carry the treasure, Tab follows the team
(the views), a left drag chooses those in a box. See step 3 for the keys
of the team.

## The HUD (2026-10-28)

`hud.ent` (ART.md, "The HUD"): a strip along the bottom with a card for
each of the team, the ten orders as buttons, the clock, the
strategy switch and where the treasure is; a tip by the mouse says what
it points at (on the strip: what a click does). The mouse alone plays:

- a click on a card chooses (Shift+click adds or takes away);
- wait and carry act at once on the chosen; the other buttons arm
  their order (the button blinks, its icon follows the mouse): the
  next click in the world uses it there (follow: on one of the team);
  Shift keeps it armed; a second click on the button, the right button
  or Escape disarms; go disarms (a click in the world sends the
  chosen there, as before);
- a click on the switch sets the strategy, on the clock runs or stops
  the world;
- the time band above the strip (2026-10-29): START (watch the game
  again from the landing), -30S, -5S, RUN/STOP, the speeds 1X 2X 4X,
  the timeline (the game so far; the moment shown in white; red marks
  where one went down, small cyan ones where orders were given; a
  click or a drag goes there, stopped), the time, and NOW (on to where
  the game stands). Behind that, the strip's clock says REPLAY: an
  order takes over there. The pause menu has WATCH FROM THE START.

The keys still work as before. Escape now belongs to the game (it no
longer shuts the window). Fonts: m5x7 and Silkscreen Bold (`fonts/`).


Sprites: the soldiers, creatures and the chest are drawn from `art/sprites.png`, made by `python3 art/sprites.py` (see ART.md, "The sprites").

## The menus (2026-10-28, dummies)

`menus.ent`: the game opens on the title screen; Escape in play pauses
(with an order armed it disarms first). Load, save, the tutorial and
all settings but fullscreen are there to click and say they come later.
See ART.md, "Menus".

## The tutorial (2026-10-28)

`tutorial.ent`: Tutorial on the title screen builds the training ground
and the sergeant takes the player through 24 lessons (ART.md, "The
tutorial"). The flamer's lesson is staged (2026-10-29): the sergeant
sends all three to the ice door close together and has the tech at
the back flame it; the squad catches fire, the world stops, and the
next lesson (FRIENDLY FIRE) is going back with R and doing it right
(the staged orders are logged as the player's: going back and doing
nothing burns them again; an order of one's own drops them).

Time is taught (2026-10-29, T5): TIME (the time bar's RUN, five
seconds run), FASTER (1X 2X 4X, comma and period; run at 4X), THE
TIMELINE (drag the marker back, watch to NOW, the cyan ticks of one's
orders; back two seconds or more, then at NOW again). And a
catastrophe, staged as the flamer's: THE ROOF (the cave in the hill
has a roof of crumbling rock; the sergeant wants a skylight, sends the
three under it close together and has the heavy throw a charge
straight up into it; the roof comes down on them and the game stops
by itself, the first card the player sees: CAVE-IN) and GOING BACK
(what the card is, BACK 30 S or the timeline to just before the bang,
then three quarters of the roof down with nobody crushed: no roof left
to fall on anybody later). The game stops by itself from THE ROOF on
(until then it is quiet); in the tutorial the card sits below the
sergeant's panel. Made for it, and kept for the game: only falling
rubble crushes (open below it; rubble at rest does no harm), and one
buried by a heap climbs out of it a cell a tick (it stood in it for
ever: a carrier was stuck in the cave-in's heap). Whole games after it
(`check/balance.ent`): cautious won 4, lost 5, stalled 3 (25 down, as
in T4); brute force won 8, lost 4 (15 down; T4: 7, 5, 18).

Made for the earlier lessons, and kept for the game: the torch aimed into a
wall cuts on through it (to 40 cells past the place); the blaster aimed
at an open place (a creature) fires a burst of 3 (before, it fired
none); a new world (N, New game) forgets the old one before the
surface is known, not after (the surface was forgotten). `Marker` (a
flag in every view) and `Shield` (a box where a click is no order) are
in view.ent.
## Stopping by itself (2026-10-29, T3)

`alarms.ent`: when something happens at the game's reach (not while
watching it again or going to a moment), the world stops and a card in
the middle of the screen, over the dimmed world, says what and to whom:
GO ON (Space), BACK 5 S (R), LOOK (L: the card goes, the world stays
stopped), and a check box: stop the game when this happens. The kinds,
each a check box in the settings too: a creature hunts one of the team
(a hunt begun), one is hurt (its armour falls into a lower quarter),
one falls far enough to be hurt, one goes down, one waits with its
order done (manual only), lava or gas seen for the first time (off at
first: it can come often), the chest lifted or dropped, a catastrophe
(T4). The same kind about the same one stops it at most every 10
seconds (a fall counts as the hurt that comes of it); going down and
the chest every time. Found from the world's own counts (hunts begun,
the chest, lava and gas first seen: `Dangers` in sight.ent) and from
each one's armour, fall and order as last tick. Each stop is a mark on
the timeline. Quiet in the tutorial until its cave-in (T5).

## An unforgiving world (2026-10-29, T4)

Harm (creatures.ent `wounds`): lava 25 a tick (4 ticks and one is
down; was 3), a flash 6, a flame 2 (was 1 both); a fall past 64 cells
the cells past it (3 times what it was); rubble above the feet crushes,
3 a cell, 15 a tick at most. Known lava is no way for the paths (it was
swum through, like water); lava unseen is still there.

The world (gen.ent): pockets 30 empty, 25 water, 25 gas, 20 lava (was
40, 25, 20, 15); gas pockets wrapped in sour rock (olive: "gas is
near"), as lava's in warm rock and water's in damp; 16 patches of
crumbling rock (was 8). Shaken crumbling rock shivers (its shade anew
each tick) for 18 ticks before it can fall.

Catastrophes (alarms.ent `perils`): each chunk counts the cells of
crumbling rock fallen, gas gone up and lava come where there was none
(`Stir.fell`, `went`, `ran`, counted in `react`, `fall` and `flow`).
Every 15 ticks the chunks within 40 cells of each of the team are
summed: 24 fallen is a CAVE-IN, 40 gone up a GAS EXPLOSION, 60 run a
LAVA BREACH (the worst by how far over). It stops the game (on by
default) with a card whose back button goes 30 seconds (what brought
it on is older than 5), and is pinned on the timeline (a diamond), once
in 10 seconds.

Measured (`check/balance.ent`, the autopilot alone, seeds 1 to 12, no
going back):

| strategy    | T3: won / lost / stalled | went down | T4: won / lost / stalled | went down |
|-------------|--------------------------|-----------|--------------------------|-----------|
| cautious    | 4 / 3 / 5                | 19 of 36  | 4 / 5 / 3                | 25 of 36  |
| brute force | 9 / 2 / 1                | 9 of 36   | 7 / 5 / 0                | 18 of 36  |

Losses double (5 to 10 of 24 games). Falls are now the cautious
team's killer (up to 240 a game); brute force cuts into lava pockets
(seeds 7 and 10 lost to a breach in the first 20 turns, seed 9 won with
one left). Catastrophes near the team: 14 looks over the lava mark (11
of them one long breach), one cave-in, one gas explosion, in 24 games.
`check/perils.ent`: seed 10 brute force stops on its LAVA BREACH at
0:51; BACK 30 S and cautious from 0:21: all three standing 40 seconds
past it.

Known flake: `check/tutor.ent`'s friendly-fire lesson failed twice
(the squad stuck in the ice doorway) when run beside two balance runs
and builds; passed alone and four times side by side. Its seeks are
cut into frames by time, so its script sees them at other frames under
load.

## Backwards (2026-10-29, T6)

`journal.ent`, the undo log: after every tick, what the tick changed is
written down with what it was before; a tick back puts the old values
back. REWIND on the time bar (Backspace) plays the world backwards at
the speed chosen (1, 2, 4 ticks back a frame); RUN, Space or an order
stops it. -5S, -30S, the alarm card's BACK and the timeline go back by
the log as far as it reaches (a thin cyan line under the timeline), and
by a saved world and a quick replay before that. A world loaded or made
anew starts the log again.

What changed is found by comparing the world with a shadow of it, only
where something could have changed: the cells and the light of chunks
awake in the tick or stirred (every change by hand stirs its chunk);
what is remembered within 190 cells of an eye, the feet (`Nav`) within
282. A cell seen in this round that was seen in the last one too is not
written down (a tick back, every cell of this round's is of the last
one's unless a row says else): without that rule a tick wrote 804 KB,
88 thousand rows of "seen again". The rest of the world (the team, the
creatures, what flies, counts, uniques: 83709 words and 216 floats,
the ways only when a search or a caught fall changed them) is packed
into words and compared the same way. The chunks count their rows on
all cores, each is given its place in one log (a prefix over the
chunks), and they write them on all cores; a tick's rows are together.
A row is 8 bytes (where, the old value); the log holds 16.7 million
(128 MB, with a 32 MB shadow).

Measured (`check/undo.ent`, seed 1, cautious, the first minute):

| per tick                         | rows | bytes |
|----------------------------------|------|-------|
| cells                            | 72   | 576   |
| what is remembered               | 1    | 8     |
| stamps (seen first, or again)    | 64   | 512   |
| light and feet                   | 2    | 16    |
| the rest (words, floats)         | 178  | 1424  |
| all (most in a tick: 3869 rows)  | 319  | 2557  |

2.5 KB a tick, 150 KB a second: the log holds about 14 minutes of play
(when full it drops its oldest half).
Logging costs 0.7 ms a tick (counting and writing the rows 0.48 ms,
packing the rest 0.17 ms, comparing its words 0.05), about a quarter of
a tick; a tick back 0.27 ms, 3700 ticks a second, where a quick replay
after loading a saved world goes 300 a second. The check goes back from
3600 ticks to the landing and forward again, every tick's digests (the
four planes, the words) the same; to tick 2700 by the log (no world
loaded); an order there, on to 3600, back across the order and forward
again; and through the time bar's buttons: REWIND, RUN, -5S.

Open: going forward again is replayed, not redone (the rows keep only
the old values; a row swapped on the way back would keep the new one,
but "seen again" stamps are not in rows); the log could become an ent
feature (open topic 51): journaled buffers, written down where they
are written instead of found by comparing.

## Effects and sound (2026-10-29, E1)

`effects.ent` draws the scan and the cries the team hears in blocks a
cell big, on the cells' grid, from the world and its tick alone (so
they play backwards too):

- The scan: two pulses out from the place scanned every second, bright
  where they cross rock and dim in open space; a dashed ring at the
  scan's reach (24 cells) that fills in, clockwise from the top, as the
  five seconds go; a core that beats with the pulses. Done: a ring
  sweeps out over what was made known, glints lighting behind it and
  twinkling out (`Tools.sx`, `sy`, `st`: where and when the last scan
  was done; was a filled green disc growing).
- A creature's cry the team heard: three amber ripples, ( and ), going
  out from where it cried, fading over the 90 ticks it is heard; out of
  the view, a solid amber arrow on a dark edge at the view's edge,
  pointing at it, ripples going out behind it (was a small amber dot).

`sfx.ent` (the game only): a soft ping for each pulse, a two-note chime
when a scan is done, a low growl over a hiss when a cry is heard; tones
made up by devices/sound, for ticks played forward only.
`check/fxshots.ent` pictures them (`build/shots/fx_*.png`).

## Particles (2026-10-29, E2)

`particles.ent`: a pool of 1024 motes (`Motes`, transient), moved and
made by `motes_step` at the end of each tick of the world (not in a
replay), so they stop when time stops; going back or to another tick
empties the pool. Made from:

- `Puffs` (matter.ent), pushed by the world as things happen: a bolt
  hitting (tools.ent: 12 sparks and 3 chips in the colour of what it
  hit, taken before it broke), one of the team landing after a fall of
  12 cells or more (team.ent: dust).
- The torch: 3 sparks a tick at the cut while it cuts.
- A charge going off: a flash, 40 pieces of debris, 20 sparks, 16 puffs
  of dust.
- Sand and rubble coming to rest, read from this tick's rows of the
  undo log (journal.ent): a puff of dust, at most 12 a tick.
- Fire and lava in view: embers rising (40 tries a view a tick).

Drawn in each view after the effects, as cells on the grid.
`check/fxshots.ent` pictures a bolt, the torch, a charge (1, 9 and 40
ticks after) and the flamer.

## Checks

- `check/worlds.ent`: worlds of seeds 1 to 4: making time, 600 ticks of
  settling (ms a tick, chunks awake), tunnel points still open, pockets
  by kind, a digest of the cells, and pictures (`world_<seed>_*.png`:
  the whole world with the awake chunks, the ship, the vault, the four
  entrances).
- `check/seeing.ent`: sight on seed 1: the light's cost, a round of
  sight with the team by the ship, down the mine shaft, with a flare,
  back at the ship after the shaft was filled with sand unseen (still
  remembered open), and one of them back to look; pictures
  (`sight_*.png`) and digests of the cells and of what is known.
- `check/moves.ent`: a built course (walls 30 and 75 high, a pit 100
  deep with a ladder, a pool), everything known, one Pixalorien sent
  across: one search, uses walking, the ladder, the grapple and the
  jetpack, arrives at about tick 3000.
- `check/expedition.ent`: seed 1, the team lands by the ship and is
  sent to the vault knowing only the surface; a report each turn,
  pictures every ten turns (`expedition_*.png`), a digest of where
  they end.
- `check/gear.ent`: a station for each tool on a built course; the
  first of the team is put at each in turn and given the order, and two
  turns later what it did is counted (`gear_<n>.png`), with a digest of
  the cells at the end.
- `check/beasts.ent`: the habitats of seeds 1 to 4
  (`beasts_world_<seed>.png`), then an arena with a station for each
  kind (`beasts_<n>_a.png`, `_b.png`).
- `check/hunted.ent`: the expedition of seed 1 with the creatures, in
  manual play: each turn where the team is and its armour, the
  creatures alive, hunting and killed, attacks; a digest of where all
  end.
- `check/strategies.ent`: the same start (saved once, loaded for
  each) played manual, cautious and brute force: the turn all are at
  the treasure, armour, kills, cells cut, scans, a digest
  (`strategies_<n>.png`).
- `check/splits.ent`: seed 1, cautious: each change of the views
  (`splits_<k>.png`); a box dragged round the team and a click with
  a mouse the check moves; the third told to wait, then a noise by
  it; last the three put far apart (three views); what drawing costs.
- `check/balance.ent`: headless (no window), the autopilot plays whole
  games on the worlds of seeds 1 to 12, cautious and brute force: how
  each ended and when, who went down where, the treasure dropped,
  harm by cause (creatures, falls, blasts, burns, crushing), the
  catastrophes near the team (and the most cells in a look), cells cut;
  then won, lost and stalled (150 turns) for each strategy.
- `check/perils.ent`: seed 10 brute force to its lava breach: the card
  and the pin; BACK 30 S on the card, cautious from there, all three
  standing 40 seconds past it (`shots/peril.png`).
- `check/rewind.ent`: cautious to tick 4200 with orders and changes of
  strategy on given ticks, a digest of the world every second; then to
  4000 (ring), 2000 (kept), 1000 with a new order at 1100 (the rest
  dropped), 2500 (a file saved after that order) and 500, on to 4200
  each time: every digest must be what it was; the time to save and
  load, and how fast the quick passes are.
- `check/fxshots.ent`: the effects pictured (`fx_*.png`): the scan at
  30% and 80%, 8 and 22 ticks after it is done, a cry beside the team
  and one outside the view; then the particles: a bolt hitting, the
  torch, a charge 1, 9 and 40 ticks after, the flamer; and how many
  motes of each kind were made.
- `check/undo.ent`: the undo log (T6): cautious to tick 3600 with the
  log on and every tick's digests (cells, what is known, stamps, light
  and feet, the rest as words); back to the landing and forward again,
  by the log to 2700, an order there and back across it, then REWIND,
  RUN and -5S clicked on the time bar: every digest must be what it
  was, no world loaded; rows and bytes a tick, the time a tick costs.
- `check/shots.ent`: screenshots for the art direction (ART.md), in
  `build/shots/`: the whole world, the ship, the team close, the vault,
  each creature close (full light), and the team in play (fog, the turn
  bar) and in full light every 10 turns on the way to the vault.
- `check/hudshots.ent`: the HUD in play (seed 1, cautious, the mouse
  moved by the check): `build/shots/hud_<turn>.png` at turns 2, 8, 14,
  20 (over the ground, over a button, over one of the team, over the
  sky).
- `check/hudclicks.ent`: the strip's clicks with a mouse the check
  moves: a card, the blaster armed and used in the world, follow, the
  switch, the clock, wait, a charge disarmed by the right button; 11 of
  11 steps right; `build/shots/hud_armed.png`.
- `check/menuclicks.ent`: the menus clicked through (title, settings, credits,
  tutorial, new game, Escape to pause, save, back, resume, title,
  continue; the tutorial begun, a new game after it); 18 of 18 steps
  right; `build/shots/menu_<screen>.png`.
- `check/tutor.ent`: the tutorial played as a player would (the mouse over
  the samples, a card clicked, orders where clicks would give them, the
  world run, 4X, 3 seconds back on the timeline, brute force, Enter, R
  after the staged fire, BACK 30 S on the cave-in's card and forward
  to 2 seconds before the charge, the roof brought down from its door
  by charges, other cards gone on from); 24 of 24 lessons done, the
  game won;
  `build/shots/tutor_<lesson>.png`.
- `check/stops.ent`: seed 1, cautious, every kind on, to 2:30: each
  stop (tick, what, to whom), the first card of each kind pictured
  (`build/shots/alarm_<kind>.png`), GO ON pressed, the third time BACK
  5 S: watched back up to where it stood, it must not stop again, and
  the world must be what it was (a digest a second).
- `check/grapple.ent`: the grapple's rules: up a rock ledge by a pull,
  up a glass one by the jetpack (the hook does not hold), a fall
  down a shaft with an empty tank caught and pulled up unharmed; 5 of 5
  right; `build/grapple.png` (the pull, the line to the edge).
- `check/long.ent`: one world for 3000 ticks, until it sleeps.
- `check/level.ent`: a tower of water and one of sand let go in basins:
  water must end level, sand heaped.
- `check/block.ent`: a small block of water, cell by cell as it runs out.
- `check/tick.ent`: sand, water and lava poured into a basin.

## Measured (2026-10-27, native, all cores = 23 threads)

| | all cores | one core |
|---|---|---|
| making a world | 30 to 36 ms | 170 to 185 ms |
| a tick, 47 to 160 chunks awake (first 100 ticks) | 3.3 to 7.5 ms | 11 to 37 ms |
| a tick, 0 to 103 awake (ticks 500 to 600) | 0.9 to 6.8 ms | 1.5 to 28 ms |
| a tick, all asleep | 0.15 ms | |

- One core and all cores give the same digest for all four seeds.
- Water finds its level: a block of 20 by 20 is level a second after
  it is let go; a tower 200 high levels in about 1200 ticks (20 s). The
  rules that do it (`flow`, `press` in matter.ent) cost: a tick with
  some 95 chunks awake went from 15 to 25 ms on one core.
- Seed 1 sleeps entirely from about tick 1500. Seed 2 still has 66
  chunks awake at tick 2400: lakes draining through narrow tunnels into
  the caves below.
- Threads are only about a third busy: a fixed cost for each of the
  parallel loops in a tick, paid whenever any chunk is awake, and
  `--tune` keeps them `static`. Chunks are spawned in a scattered order
  so neighbours go to different threads (10 to 20%).

## Measured with sight (2026-10-27, native, all cores = 23 threads)

| | all cores | one core |
|---|---|---|
| a tick, 47 to 160 chunks awake (first 100 ticks) | 6.6 to 11.7 ms | 27 to 58 ms |
| a tick, 0 to 103 awake (ticks 500 to 600) | 1.2 to 8.8 ms | 2.1 to 35 ms |
| a tick, all asleep | 0.19 ms | |
| a round of sight, three eyes | 0.8 to 1.2 ms | 2.6 to 4 ms |

- Light costs about 17% of a tick over 3000 ticks (one pass of `glow`
  costs about two of `flow`), and the skyline 0.04 ms a tick on all
  cores (0.23 on one). The digests of the cells are the same as without
  light, and the worlds still fall asleep (seed 1 by tick 1500).
- A round of sight: by the ship about 45,600 cells seen; down the mine
  shaft about 1,100 (only what the lamps light); with a flare 1,600.
- After the shaft is filled unseen, 363 of its 520 cells are
  remembered wrong; one of the team back above it sees the sand's top
  (12 cells), and the rest stays remembered wrong, hidden under it.
- One core and all cores give the same digests of the cells and of
  what is known.

## Measured with the team (2026-10-27, native, all cores = 23 threads)

- Seed 1, knowing everything: the way from the ship to the vault is
  1285 places, found in 1.1 ms.
- Knowing only the surface: the team walks east, goes down the
  sinkhole and through the caves and stands by the treasure in turns
  22 to 25, after 187 searches in all (each new sight that breaks a
  way means a new search). A search takes under 2 ms on average and
  27 ms at worst (a search that floods the unknown, capped at 150,000
  places). The `Nav` map costs 0.5 to 0.9 ms in a tick where much was
  seen.
- One core and all cores give the same digest of where the team ends
  (and the same 187 searches).

## Measured with the tools (2026-10-27, native, all cores = 23 threads)

- `check/gear.ent`: a bolt breaks 8 cells of sandstone, 4 of rock,
  none of bedrock; a bolt through a hole into a pocket of 2016 cells of
  gas sets it all off; a charge at a rock face breaks 198 cells (88
  left as rubble), not the bedrock in it; a second of the flamer melts
  241 of 400 cells of ice; the torch cuts 80 cells through rock in 560
  ticks (7 a column); a scan makes 1793 cells known (a lake in the rock
  as water); walking over a slab of crumbling rock over a pit, 103
  cells of it fall in behind. One core and all cores give the same
  digest of the cells.
- A tick of the world costs as in step 2 (seeds 1 to 4, first 600
  ticks: 1.1 to 11.4 ms).
- The expedition (step 3) still reaches the vault, in turns 22 to 24.

## Measured with the creatures (2026-10-27, native, all cores = 23 threads)

- Arena (`check/beasts.ent`), one Pixalorien against: 6 crawlers, 7
  bites (28 armour) before all are shot; 6 bats, 2 knocks; a borer
  digs 89 cells through rock to it and bites once (20); a hound comes
  out of its lava, bites twice (24) and sets 20 of 72 cells of a wood
  floor alight; a spitter spits 3 times, hits once (10). A flare among
  bats under a roof: 150 ticks later half have left, none is in its
  light.
- Seed 1's expedition with the creatures (`check/hunted.ent`): bats
  and crawlers find the team in the caves in turns 14 to 17 (21
  attacks, 14 knocks, 70 armour lost; 15 creatures killed); the team
  still stands by the treasure in turn 20 (armour 43, 100, 87). The
  creatures cost 0.01 to 0.04 ms a frame (2.8 ms at most). One core and
  all cores give the same digest of where everything ends.

## Measured with the strategies (2026-10-27, native, all cores = 23 threads)

- Seed 1 with its creatures (`check/strategies.ent`), from the same
  start:

  | strategy    | all at the treasure | armour      | killed | cells cut |
  |-------------|---------------------|-------------|--------|-----------|
  | manual (all sent there) | turn 25 | 100, 75, 84 | 15     | 0         |
  | cautious    | turn 35 (lifted)    | 11, 89, 89  | 6      | 12        |
  | brute force | turn 19             | 82, 70, 97  | 15     | 2223      |

  (With step 8: falls harm, the jetpack brakes, a look before a pull
  or flight into the unknown. Before the fix of 2026-10-28 below: 23,
  39 and 17 turns.)

  Cautious keeps two of the three whole but is slowest. The scout
  walks into creatures alone (orders are only given as a turn
  begins). The others lose its trail where it went down by
  jetpack or a fall, and wait. Brute force cuts its own way and is
  quickest, at the most harm. One core and all cores give the same
  digests.
- Going back (`check/rewind.ent`): 49 turn starts after going back
  (to 12 from the ring, to 6 from the kept 5, to 3 from the kept 0)
  are all as they were, on one core and on all cores. A saved world is
  28.8 MB. Saving takes 3 to 7 ms and loading 4 to 6 ms (the page
  cache). The quick passes play 320 to 560 ticks a second on all
  cores (110 on one), so a turn of 300 ticks comes back in 0.5 to 1
  s, and Shift+R (up to 4 turns played again) in at most about 4 s.

## Fixed: jumping back (2026-10-28)

The two following the scout were drawn jumping back now and then (the
player saw it). A new order taken while a step was under way set the
way back to its start, so the step ended at the old way's first place,
where that way had begun. The autopilot gives the followers a new
order every turn, so they jumped, up to 73 cells (15 times in the
cautious run). A step under way is now finished first, and the new way
is searched from where it ends. A creature's knock likewise put a
Pixalorien beside where its step had begun; it is now knocked from
where it is drawn. `check/strategies.ent` counts the jumps (drawn more
than 4 cells in a tick): 0 for all three strategies, which also go
quicker (cautious in 36 turns, not 39).

## Measured with the views (2026-10-28, native, all cores = 23 threads)

- `check/splits.ent`, seed 1, cautious, 40 turns: one view until the
  followers fall behind (turn 19: the scout and the second in two
  views; the third, told to wait at turn 6, has none). A noise by it at
  turn 8 brought it back into the shared view (it fit), with the label
  "waiting: a noise", for 240 ticks. 7 changes of the views in 40
  turns, none flickering. The box chose all three, a click the second
  alone. Put far apart, three views.
- Drawing a frame (the views, the mini map, the HUD): 0.55 ms with one
  view, 0.58 ms with two.
  After the art (far mesas, edges, faded memory, the ship sprite;
  2026-10-28): 0.74 ms with one view, 0.90 ms with two.

## Measured: whole games (2026-10-28, native, all cores = 23 threads)

`check/balance.ent`, the autopilot alone on the worlds of seeds 1 to 12:

| strategy    | won | lost | stalled (150 turns) | turns to win (mean) | went down |
|-------------|-----|------|---------------------|---------------------|-----------|
| cautious    | 9   | 2    | 1                   | 79                  | 12 of 36  |
| brute force | 8   | 2    | 2                   | 67                  | 8 of 36   |

- Games take 62 to 129 turns when won (the design's 50 to 100), 35 to
  100 s each headless (seed 2 brute force, stalled: 560 s, its
  searches long).
- Harm, by cause: creatures most (up to 270 a game); falls 0 to 120;
  burns (lava, fire) mostly in brute force, which cuts into them (up
  to 190); blasts none (the autopilot sets no charges).
- Stalls: seed 2 brute force wanders outside the vault for 130 turns
  (cutting 4200 cells) without finding its doors. Seed 3 cautious
  never reaches the treasure. Seed 10 brute force lifts it and does
  not get back.
- Against the design's targets (brute force wins about half, cautious
  four in five, nothing stalls): cautious is near (9 of 12), brute
  force wins more than it should (8 of 12), and cautious loses more
  of the team than brute force (its scout meets the creatures alone).

Bugs found on the way (fixed):
- The landing put the team inside a dune beside the ship's site on 4
  of 8 worlds (the ground was looked for under the middle of the body
  only, from the site's height): it never moved.
- `tool()` counted every order from SHOOT on, so the new CARRY was
  taken for a tool and never walked.
- Pulls and flights went into the unknown and ended in the air: now a
  look there first, and only within the lamp's reach (32 cells).
- On a ladder or swimming the tank never filled, so a flight from
  there waited for ever.
- One waiting by the treasure 26 cells from it (the third's place) did
  not count as by it: alone, it waited for ever.
- N (a new world) kept what the team knew of the last one (`forget`).
