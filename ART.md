# Pixalorien: art direction

What the game looks like, and what it should look like: the world,
the team, the creatures, the HUD, the menus, the tutorial's voice, the
marketing pictures. It is the brief for the image model too (at the
end, with the screenshots to send along). DESIGN.md says what the game
does; this file says how it looks and sounds.

Decided so far (2026-10-28):

- The look goes in this file; the image model is asked for general art
  first (key art, characters, creatures, palette). Whether it is good
  at small pixel art too is tried after, with a prompt of its own.
- The tutorial is text only, in a drill sergeant's voice.
- Menus (start, load and save, settings, credits) are dummies for now:
  screens with the right buttons that do little.
- Music and sound effects: later, not in this pass.
- The font: an open source pixel font (candidates below), or one the
  image model picks from those.

## The look in one paragraph

A lone-gunslinger space western, told in pixels that are matter. Above:
a hot orange sky with two suns, striped sandstone mesas, dunes, a
battered ship. Below: the dark, which the team's lamps cut open,
rock that gets cooler and darker the deeper it goes, water, crystal that
glows cyan, lava that glows orange. Three armoured hunters, small and
readable against all of it. The mood is quiet and dry like a western,
with sudden noise when the planet bites back. The vibe is the
Mandalorian's; nothing in the game copies it (no Star Wars names, words,
logos, helmet shapes or ships).

## Pillars

1. **Matter is readable.** The player has to tell sand from sandstone,
   rock from hard rock, gas from smoke, at a glance, because the tools
   and the danger depend on it. Colour and texture of each matter
   carry meaning; prettier is welcome, less readable is not.
2. **Light is the game.** Unseen is black, remembered is dim, seen is
   in full. Lamps, flares, crystal, lava and fire are the only colour
   underground. The art leans on that contrast, not against it.
3. **One grid.** Every world pixel is a cell. Sprites (team, creatures,
   ship, chest) sit on the same grid, a sprite pixel the size of a cell,
   so the world and what lives in it look like one thing (no finer
   pixels on sprites than on the ground).
4. **Small but clear.** A soldier is a handful of cells; it has to read
   by silhouette and one accent colour, at 3 to 6 screen pixels a cell.
5. **Warm above, cold below, hot at the bottom.** The surface is orange
   and sand; the middle is brown-grey rock, damp and blue-grey near
   water; the deep is dark, with lava and obsidian.
6. **Colours that mean something stay reserved** (below), so the
   player learns them once.

## Where it is now

The screenshots in `build/shots/` (made by `check/shots.ent`, seed 1,
1440 by 810 points at 2 pixels a point, so 2880 by 1620 pictures):

| file | what it shows |
|---|---|
| world.png | the whole 2048 by 1024 world in full light |
| ship.png | the ship, the mine's head frame and the surface, 4 points a cell |
| team.png | the team beside the ship, 14 points a cell (the sprites' size) |
| play.png, play_10/20/30.png | the team as the player sees it: fog, lamps, the turn bar, the order path, 4 points a cell |
| lit.png, lit_10/20/30.png | the same places in full light |
| vault.png | the vault and the chest |
| crawler, bat, borer, hound, spitter .png | each kind of creature close, 12 points a cell |

What works already: the surface (sky, the two suns, striped sandstone,
dunes) and the hues of rock, water, lava and crystal.

What does not:

- The team and the creatures are boxes: a soldier is 3 by 7 cells, two
  greys and a cyan visor; a creature is a coloured rectangle with an
  eye (crawler and bat 3 by 2, spitter 4 by 4, borer 5 by 5, hound 5 by
  3).
- The remembered parts of the caves are a flat blue-grey; the edges of
  caves have no light or outline, so in fog the shapes are hard to
  read.
- The cave air is a coarse brown checker that reads as a texture of the
  wall rather than as empty space.
- The ship is a few grey slabs.
- The HUD is a line of text and a bar at the bottom; there are no icons,
  no buttons, nothing to click but the world.

## Scale

- The world: 2048 by 1024 cells; the camera shows it at 3 to 6 points
  a cell in play (one view), less when the team splits.
- A soldier today: 3 cells wide, 7 tall. The game's moves (climbing a
  step of 2 to 3 cells, the tunnels' width, the ladders) are built for
  that size, so a new sprite should stay near it. Proposal: a sprite of
  **5 by 9 cells** (one cell of margin each side over the body the game
  moves), drawn one sprite pixel a cell.
- Creatures keep their sizes in the game; their sprites may grow by a
  cell or two each way (legs, wings, a tail) as the soldier's does.
- The ship: about 40 by 16 cells today; it can be redrawn at any size
  that still fits the landing flat (about 60 by 24).
- The chest: 5 by 3 cells.

So the image model is asked first for art at any size (to agree on the
look), and then for sprites at exactly these sizes, to see whether it
can do them, or whether we redraw its designs at the size ourselves.

## Palette

The matter colours as they are (`matter.ent`, each cell varies by its
shade); the art may move them, but keeps their order of light and dark
and the reserved meanings.

| matter | colour | meaning to keep |
|---|---|---|
| sand | `#c89058` | loose, falls; lighter than sandstone |
| sandstone | `#9a5a34` (striped) | soft, easy to cut |
| rock | `#4a3c36` | the bulk; plain |
| warm rock | `#5e3a2c` | near lava: a warning |
| damp rock | `#343a3e` | near water: a warning |
| crumble | `#5e4a3e` | breaks under weight |
| bedrock | `#221c1e` | cannot be cut |
| obsidian | `#1e1828` | hard, near lava |
| water | `#2a5cb8` | |
| lava | `#d03a08` | glows; burns |
| gas | `#4a5a30` | burns, explodes |
| crystal | `#40b8d8` | glows; soft |
| metal | `#70767e` | the vault, the ship; cannot be cut |
| treasure | `#d8a420` | the goal |
| wood, ladder | `#6a4424`, `#1c1610` | the mine |
| sky | `#d07a3a` to `#e8b878` | two suns, `#fff0c8` and white |

Reserved colours (nothing else in the world or the HUD uses them):

- **Cyan** `#40e0ff`: the team (visors, orders, paths, selection).
- **Gold** `#ffd040`: the treasure and the way to it.
- **Red** `#ff3020`: danger: a hunting creature's eye, harm, armour low.
- **Acid green** `#a0ff40`: the spitter's spit, poison.
- **Amber** `#ffc040`: sound (what is heard but not seen).

## Characters

### The Pixaloriens

Three bounty hunters in worn armour, helmeted, faces never seen. Their
own design: not the T-shaped visor, not any armour from the films. The
game treats the three the same (same tools, same armour), but they
look different, so the player can tell them apart at a glance:

1. **The scout**: light, a long scarf or cape that trails, a visor slit
   narrow and wide. Accent: cyan visor, sand-coloured cloth.
2. **The heavy**: broad shoulders, a big pack (the charges), a short
   helmet. Accent: a rust-red shoulder plate.
3. **The tech**: an antenna or a lamp on the helmet, a tool belt (the
   grapple). Accent: an amber lamp.

All three: a jetpack on the back (short flames when it fires), a
grapple, a lamp whose light the game already draws, and the tools of
the game: a blaster, a flamer, a cutting torch, a scanner, charges and
flares.

Animations, a few frames each at the sprite size:

| move | frames | note |
|---|---|---|
| stand | 2 | breathing, scarf moving |
| walk | 4 | |
| climb (ladder, wall) | 2 | |
| fly (jetpack) | 2 | flame flicker |
| fall | 1 | arms up |
| land hard | 1 | crouch |
| grapple | 2 | throw, pulled |
| shoot (blaster, flamer) | 2 | flash at the barrel; the flamer's fire is matter |
| cut (torch), scan | 2 | sparks; a sweep of light |
| throw (charge, flare) | 2 | |
| carry the chest | 4 | the walk, slower, chest held |
| hurt | 1 | white flash |
| down | 1 | lying |
| look (before a move into the dark) | 1 | lamp raised |

### The creatures

What they do is set (DESIGN.md, creatures); how they look is open:

| creature | where | size today | look to try |
|---|---|---|---|
| crawler | cave floors, packs | 3 by 2 | a pale beetle or tick, many legs; the pack moves together |
| bat | under roofs, flees light | 3 by 2 | leathery, purple-grey, eyes that shine in the lamp |
| borer | inside rock | 5 by 5 | a worm or mole with a drill mouth; leaves a tunnel |
| hound | in lava pools | 5 by 3 | a molten dog or lizard, glowing cracks |
| spitter | on ledges, still | 4 by 4 | a plant or barnacle that spits acid green |

Each: idle (2), move (2 to 4), attack (2), hurt (1), dead (1). The
eyes: pale when calm, red when hunting (the reserved red).

### Props

The ship (worn, patched, one landing leg bent), the chest (iron bands,
gold), the vault's metal doors, the mine's head frame and ladders, the
flare, the charge.

## The world, polished

- **Sky**: the gradient and two suns stay; add far mesas as a still
  background layer behind the surface (drawn once, not cells), and
  heat shimmer only on the title screen.
- **Cave air**: a dark, nearly flat colour (no checker), slightly
  warmer near the surface and cooler deep down, so open space reads as
  space.
- **Cave edges**: rock cells next to open air one step lighter (where
  the lamp falls), so tunnels read in fog.
- **Remembered places**: a desaturated, darker copy of the colours
  (like an old photograph or a map), not a flat blue.
- **Glow**: lava, crystal, fire and flares tint the cells around them
  (the light the game already computes, shown in colour).
- **Particles**: dust when sand falls, sparks when a bolt hits rock,
  smoke and steam already exist as matter.

Applied 2026-10-28 (view.ent's `paint_view`, goal.ent's `draw_ship`,
turns.ent's `tool_effect`):

- Far mesas: two ridges in the haze, flat tops, steep sides, faint
  strata, on the horizon at the ship's ground, moving at 0.6 and 0.3 of
  the camera's pace. (No heat shimmer yet.)
- Cave air: one dark colour, warmer near the surface, cooler deep down;
  the checker is gone.
- Cave edges: rock beside open space (as the team knows it) a step
  lighter.
- Remembered places: faded (mostly grey, darker, a little warm); open
  space remembered one dark tone, apart from the black of the unknown.
- Light under the ground a little warm, as it grows (lamps, flares,
  fire). The light is one number per cell, so crystals do not glow cyan.
- The ship: a sprite over its cells (made by art/sprites.py from the
  same shape): plates and rivets, rust, the team's cyan stripe, the
  canopy's glint, a strut under the fin, the nozzle glowing and
  flickering. The bent leg is not done (the cells' legs are straight).
- The team: a red flash when hurt; the blaster's flash as a bolt
  leaves; the torch's sparks at the cut; the scanner's beam sweeping.
- The scan and the cries heard (2026-10-29, effects.ent): sonar
  pulses in blocks, a ring that fills as the scan goes, a sweep with
  glints when done (team cyan); amber ripples ( ) where a creature
  cried, an amber arrow at the view's edge when it is out of view.
- Particles (2026-10-29, particles.ent): cells on the grid, fading
  as they age. Sparks white to yellow to red with a two-cell streak;
  debris in the colour of what broke, on a dark edge; dust a puff
  growing to 3 cells; embers flickering; a charge's flash a disc of
  cells, white in the middle, growing for 8 ticks (was a cream circle).
- Not yet: the creatures' attack,
  hurt and dead frames, the soldiers' throw, land and look poses.
- Cost: drawing a frame 0.74 ms with one view (was 0.55), 0.90 with
  two (was 0.58).

## HUD and UI

The HUD is designed in its own step (next, with mock-ups); its look is
set here:

- Chunky pixel panels in dark brown-black with a thin warm edge, like a
  worn ship console; text in the pixel font; icons drawn on the same
  pixel grid.
- Cyan for everything that is the team's (cards, buttons for orders,
  paths); gold for the treasure; red for danger.
- Mouse first: every order a button with an icon and its hotkey on it;
  every soldier a card (portrait, armour, fuel, charges, flares, what it
  is doing); the 5 second turn a clock that empties; the strategy a
  three-way switch; hover tells what a cell, a creature or a soldier is.

## Menus (dummies for now)

Start (new game, tutorial, load, settings, credits, quit), load and
save (slots with a picture of the world), settings (window size and
fullscreen, UI scale, turn length, autosave; volume once there is sound),
credits (the fonts' and other assets' licences go here). For now each
is a screen with its buttons that go back; the title screen gets the key
art when there is some.

Built 2026-10-28 (`menus.ent`, check/menuclicks.ent, pictures in
`build/shots/menu_*.png`): the game opens on the title (round 2 key art
behind, darkened to the left; PIXALORIEN in Jersey 10, buttons in the
HUD's plates: Continue (once a game is begun), New game, Tutorial, Load,
Settings, Credits, Quit). Escape in play (no button's key being told) pauses: the
world stops and is drawn darkened behind Resume, Save, Load, Settings,
Title screen, Quit. Load and save show three empty slots with a place
for a picture; settings show fullscreen (works), UI scale, turn length,
autosave, sound (kept, not used yet: a "not yet" says so); the tutorial
screen is the sergeant saying there is none yet. A second New game
makes the next seed's world, as N does. Buttons act on release over the
button they were pressed on; Escape goes back.

## The tutorial (built 2026-10-28)

`tutorial.ent`: Tutorial on the title builds a training ground (the
ship at the left, then samples of sand, sandstone, rock, crumbling
rock, ice, glass and a pool; a rock wall to grapple; a pit with a
ladder and a glass tower to fly; walls of sandstone, rock and rock with
an ice door, too high to fly, to torch, blow and melt; a hill with a
dark cave and one crawler; the vault). The sergeant's panel at the top
gives 19 lessons: welcome, matter (point at five kinds), choosing,
walking, all three, the turn, the grapple, ladder and jetpack, torch,
charge, flamer, scanner, get in, flares, blaster, the chest, the
autopilot, home (the game won), dismissed. Each has a task checked as
play goes (a flag marks where to go); NEXT or Enter goes on, SKIP while
the task is not done; all down: RESTART. Manual play until the
autopilot lesson. check/tutor.ent plays it through: 19 of 19.

## The tutorial's voice

Text only, a drill sergeant on the ship's radio: loud, short sentences,
dry jokes, never mean to the player, a little mean to the soldiers.
The lessons follow the plan in the HUD step. A few lines to set the
tone:

- "LISTEN UP, MAGGOTS. That orange stuff is sand. It falls. You will
  too, if you stand on it like a tourist."
- "You get FIVE seconds a turn. That is four more than this squad
  needs to walk into a wall."
- "This is a charge. It makes holes. In rock, preferably."
- "Cautious means one goes first and two stay alive. Brute force means
  all three find out together."

Whether the sergeant has a face (a small portrait beside the text) is
for the image model to try.

Done 2026-10-28: the portrait from round 1 (the 96 panel) reduced to
real pixels, `art/sergeant.png`, 64 by 80, 28 colours:

    magick art/round1/drill-sergeant.png -crop 760x950+820+220 +repage \
      -filter box -resize 64x80! +dither -colors 28 PNG32:art/sergeant.png

drawn at 2 points a pixel at the left of the lesson panel, jolting as
each lesson begins (shouting). A placeholder like the key art (in the
credits as such).

## Fonts

Open source pixel fonts to choose from (licences as published; check
the file that comes with the download before shipping):

| font | by | licence | note |
|---|---|---|---|
| [m5x7](https://managore.itch.io/m5x7) | Daniel Linssen | CC0 | small, readable; credit asked, not required |
| [m6x11](https://managore.itch.io/m6x11) | Daniel Linssen | free with credit (licence to check) | a larger sibling of m5x7, good for headings |
| [monogram](https://datagoblin.itch.io/monogram) | datagoblin | CC0 | monospace, 5 by 7; an extended version with accents |
| [Pixel Operator](https://www.dafont.com/pixel-operator.font) | Jayvee Enaguas | CC0 | several styles (bold, mono, small caps) |
| [Kenney Fonts](https://kenney.nl/assets/kenney-fonts) | Kenney | CC0 | Kenney Pixel, Mini, Square and more |
| [Pixelify Sans](https://fonts.google.com/specimen/Pixelify+Sans) | Stefie Justprince | SIL OFL 1.1 | rounder, has weights; good for titles |
| [Silkscreen](https://fonts.google.com/specimen/Silkscreen) | Jason Kottke | SIL OFL 1.1 | small caps only, for labels |
| [Tiny5](https://fonts.google.com/specimen/Tiny5) | Stefan Schmidt | SIL OFL 1.1 | very small, 5 pixels |

A first proposal: m6x11 or Pixelify Sans for titles, m5x7 or monogram
for the HUD and the tutorial (the window library loads .ttf files with
`font`, and draws them with `write`). CC0 needs nothing; OFL needs the
licence shipped with the game and the font's name kept.

## Music and sound

First sounds 2026-10-29 (sfx.ent): the scan's ping and chime, the
growl of a cry heard; tones made up on the spot, no files. Then the
effects (E3, same day): a mixer of our own streamed to the device, all
made up from tones and noise: the blaster's zap, a bolt's knock, a
landing's thud, a charge's crack and boom, a cave-in's rumble, gas's
whoosh into a boom, steps, the flamer's roar, the torch's hiss, the
jetpack's rumble, the alarm card's two notes; loud by how near the
views (one channel: no left and right yet). Music is not in this pass.
When it comes: a dry western guitar and wind on the
surface, low drones underground, the creatures heard before seen
(DESIGN.md already has sound markers in the game).

## The image model brief

Each prompt below goes with the screenshots named under it, and with
this file's "The look in one paragraph" and "Pillars" pasted at the top.
Every prompt also carries the rule: original designs only; no Star Wars
names, words, logos, characters, helmets, armour or ships.

### 1. Key art and mood

> Key art for a side-view pixel game called Pixalorien: three armoured
> bounty hunters stand beside their battered small spaceship on an
> orange desert planet with two suns, striped sandstone mesas behind.
> Below the surface, cut away like an ant farm, dark caves lit by their
> helmet lamps, glowing cyan crystal, a lava lake at the bottom, and a
> golden chest in a metal vault deep down. Lone-gunslinger space
> western mood: quiet, dry, dangerous. Pixel art, limited palette,
> crisp, no anti-aliasing. Wide format (16:9), and a tall version
> (2:3) for a store page.

Attach: world.png, ship.png, vault.png, lit_20.png.

### 2. The three Pixaloriens

> A character sheet of three original armoured bounty hunters for a
> pixel game: a light scout with a long scarf and a narrow wide visor;
> a heavy with broad shoulders, a big pack and a rust-red shoulder
> plate; a tech with a lamp on the helmet and a tool belt with a
> grappling hook. All three wear worn, dusty armour, a jetpack and a
> helmet lamp; the visors glow cyan. Front, side and back views, and a
> silhouette of each in black, so that they read apart when tiny. Not
> the T-shaped visor; no armour from any film.

Attach: team.png, play_20.png.

### 3. The creatures

> Five original creatures that live under a desert planet, for a pixel
> game, each shown large and as a black silhouette: a pale crawler like
> a tick, in packs; a leathery purple-grey bat that hates light; a
> borer, a worm with a drill mouth that eats through rock; a hound made
> of cooling lava, with glowing cracks, that lives in lava pools; a
> spitter, a still plant or barnacle on a ledge that spits acid green.
> Eyes pale when calm and red when hunting.

Attach: crawler.png, bat.png, borer.png, hound.png, spitter.png.

### 4. The world's palette

> A palette and matter sheet for a falling-sand pixel game: swatches
> and a small textured square (16 by 16 pixels) for each of sand,
> sandstone (striped), rock, warm rock near lava, damp rock near water,
> crumbling rock, bedrock, obsidian, water, lava, gas, crystal, metal,
> wood and gold, each readable from the others; then the same squares
> as remembered (darker, desaturated, like an old photograph), and lit
> by a lamp. Keep the reserved colours free: cyan for the team, gold
> for the treasure, red for danger, acid green for poison, amber for
> sound.

Attach: world.png, lit.png, play.png, lit_10.png.

### 5. HUD and title mood

> The user interface mood for the same game: chunky pixel panels like
> a worn ship console, dark brown-black with a thin warm edge; three
> soldier cards (portrait, armour, fuel, charges, flares); a row of
> order buttons with icons (go, wait, follow, blaster, flamer, charge,
> torch, scan, flare, carry); a turn clock of five seconds; a three-way switch
> (manual, cautious, brute force); a title screen with the logo
> "PIXALORIEN". Pick a pixel font from: m5x7, m6x11, monogram, Pixel
> Operator, Kenney Pixel, Pixelify Sans, Silkscreen, Tiny5.

Attach: play.png, play_20.png, play_30.png.

### 6. The drill sergeant

> A portrait of an original grizzled drill sergeant on a starship's
> radio, for a pixel game's tutorial: helmet off, scarred, shouting,
> funny rather than scary. Head and shoulders, readable at 48 by 48
> pixels, and the same at 96 by 96.

### 7. Small pixel art (after 1 to 3 look right)

> The three hunters from the sheet as game sprites, each exactly 5
> pixels wide and 9 tall on a transparent background, one pixel a
> cell, no anti-aliasing, at most 6 colours each: standing, 4 frames of
> walking, flying with the jetpack. Then each creature at its exact
> size: crawler 5 by 3, bat 5 by 3, borer 7 by 7, hound 7 by 5,
> spitter 6 by 6. Show them also enlarged 8 times.

Attach: team.png, the chosen sheets from 2 and 3.

### Reviewing what comes back

For each answer: does it read at the game's size (shrink it to 4
points a cell next to team.png), does it keep the reserved colours,
is it ours and not the films'. What we like goes into this file
(palette, shapes, the font), and then into the game.

## Round 1 (2026-10-28): what came back

The seven answers are in `art/round1/` (all RGB, no transparency; the
checkerboard of the sprite sheet is painted on).

| file | prompt | verdict |
|---|---|---|
| marketing-art.png | 1, key art | the mood is right; the hunters are not ours yet |
| characters.png | 2, the three | keep the three ideas; the helmets must change |
| creatures.png | 3, creatures | keep, nearly all of it |
| matter-palette.png | 4, palette | ideas for textures; the sheet itself is muddled |
| ui-art.png | 5, HUD and title | keep the style; the layout is a poster, not a HUD |
| drill-sergeant.png | 6, sergeant | keep |
| character-sprites.png | 7, small sprites | failed the size test |

**Key art.** Right: the cut-away (surface above, caves below, lava at
the bottom), the sky and the two suns, the mesas, the ship (it is the
game's own ship, worn), the mine's head frame, cyan crystal, the chest.
Wrong: the hunters wear cowboy hats, ponchos and bandoliers over a
helmet with a T-shaped visor, which is the film's look, not ours; the
lamps hang from the cave roofs (light comes only from the team, crystal
and lava); the vault is a crate with cross braces, not a room of metal.
Use: the composition for the title screen and the store picture, redone
with our hunters.

**The three hunters.** Right: three silhouettes that read apart (slim
with a scarf, broad with a rust shoulder plate and a big pack, a
blue-grey engineer with a coiled grapple and hook); worn, dusty armour;
the jetpacks' cyan flames. Wrong: all three helmets have a T-shaped
visor (a slit across and one down): too near the film; the sheet's
lower row mixes the heavy into the scout's column. To change: a visor of
our own (proposal: a single wide slit that glows cyan, no vertical bar;
the tech's twin lamps already make its helmet different).

**Creatures.** Right: a pale tick-like crawler in packs; a purple
"duskbat" (a good name to keep); a segmented borer with a ring of
teeth; the lava hound of black crust with glowing cracks (the best of
the sheet); the spitter as a green tentacled barnacle among shells
that spits acid green. The borer is drawn twice. The sprite sheet's
creatures differ (its spitter is a dog): this sheet is the reference.

**Matter.** The sheet does not hold to its own columns (the lit column
shows other matters, water is grey in one place and blue in another),
so it is not a palette to copy. Ideas worth taking, as patterns the
renderer makes from a cell's place (each cell is still one matter):
rock as plates with darker seams, warm rock with orange flecks, damp
rock with blue flecks, lava as a network of bright cracks over dark
crust, crystal as facets with a light edge, wood as planks, metal with
diagonal glints. Its rock is grey where ours is brown: an open choice.

**HUD and title.** Right: the worn console look (dark panels, rust and
amber edges, rivets), soldier cards with a portrait and bars, square
order buttons with an icon and a word, the strategy as a three-way
switch with the active one in cyan, the turn clock as five blocks (one
a second, emptying), the title "PIXALORIEN" in a heavy pixel face.
Wrong: it fills the screen, where the game needs a strip; "follow" and
"scan" twice; a status line of things the game does not have (O2, heat,
radiation). Its font is a heavy square pixel face like m6x11.

**Sergeant.** Funny, scarred, shouting, a headset and a radio that says
COMMS OPEN: right. It is painted at a high resolution, not 48 by 48; it
has to be shrunk and cleaned to the size the tutorial uses.

**Small sprites.** The prompt asked for 5 by 9 pixels; the answer is
about 40 by 50 with shading, the heavy's and tech's walks are the
scout's, the flight frames are the same picture. So the model does not
do sprites at the game's size. The sprites get drawn by hand at the
size, from the character and creature sheets (its walk poses and the
jetpack flame are still a useful guide).

### Decided from round 1 (proposals, the user decides)

1. Hunters: the three of characters.png, with a new visor (one wide
   slit), no hats, ponchos or bandoliers.
2. Creatures: creatures.png as it is; "duskbat" for the bat.
3. Sprites: drawn at the game's size from the sheets, not by the model.
4. HUD: ui-art.png's style, laid out as a strip at the bottom (cards,
   order buttons, switch, clock); the layout is the next step's work.
5. Font: a heavy square face for titles (m6x11 once its licence is
   confirmed, else Pixelify Sans), a small one for the HUD (m5x7).
6. Key art: redone with our hunters, the lamps on their helmets, a
   vault of metal walls.

### Round 2 prompts (to run next)

> 2b. The same three hunters as characters.png, with one change to all
> three helmets: the visor is a single wide horizontal slit that glows
> cyan, with no vertical bar, no T shape. Front, side, back and
> silhouette of each, in one row per hunter, each row only that hunter.

> 1b. The key art again, same composition, with the hunters from 2b (no
> hats, ponchos or bandoliers); no lamps on the cave roofs: the only
> light underground is the hunters' helmet lamps, the cyan crystal and
> the lava; the vault is a small room of riveted metal walls with the
> chest inside.

> 4b. A matter sheet for a falling-sand game in which every pixel is one
> cell of one matter: for each of sand, sandstone, rock, warm rock,
> damp rock, crumbling rock, bedrock, obsidian, water, lava, gas,
> crystal, metal, wood and gold, one 32 by 32 square as it looks at one
> pixel a cell, then the same square enlarged 8 times; three columns
> only: normal, remembered (darker, desaturated), lit by a lamp; the
> same matter in every column of a row.

## Round 2 (2026-10-28)

The user's choices on round 1: the slit visor, brown rock (not the
model's grey), the HUD strip next. The two answers are in `art/round2/`.

**Key art (1b).** Better: no hats, ponchos or bandoliers; each helmet
has a wide cyan slit, like goggles, with no bar down; the lamps are on
the helmets only; the vault is a room of riveted plates. Still off:
the three wear the same brown armour (not the scout's sand and scarf,
the heavy's rust, the tech's blue-grey), and the chest glows cyan, the
team's colour, where the treasure's is gold. Good enough as the title
screen's placeholder.

**Characters (2b).** Hardly changed (about 5 % of its pixels): the slit
is there, but under it the faceplate still comes to a point with a seam
down the middle, so the T is still read; the rows still mix the heavy
into the scout's column. The key art's helmets are the better
reference. The sprites get drawn by hand anyway (round 1), so the
helmet is settled there: a wide slit, a round dome, no faceplate
point.

**Key art (1c, 2026-10-29).** In `art/round3/marketing-art.png`, from
the user: now the three are ours, the scout in sand with the scarf, the
heavy in rust with the jet pack, the tech in blue-grey with the cable
coil; the slit helmets and the helmet lamps as in 1b. The title screen
shows it (the tagline is set in two lines so it stays left of the
three). The chest still glows cyan. The credits name the art direction
as created by Meta's Muse Image model 1.0.

**The sergeant talks (2026-10-29).** A six-frame talk cycle from the
user (`art/round3/sergeant-talk.png`, 1920×1280, frames 580×543 at
x 63 + 607c, y 87 + 568r) is cut to `art/sergeant_talk.png`, six frames
of 80×75 side by side with one 32-colour palette:

    for each frame: magick sergeant-talk.png -crop 570x533+(68+607c)+(92+568r) +repage -filter box -resize 80x75! fRC.png
    magick f00 f01 f02 f10 f11 f12 +append +dither -colors 32 PNG32:art/sergeant_talk.png

Drawn at 2 points a pixel (160×150) left of the lesson text. When a
lesson begins (or the squad is lost) he talks: the cycle at 6 game
frames a picture, for 45 frames per line of the text; then he rests on
the first frame, the mouth nearly shut. The jolt is gone, and
`art/sergeant.png` (the round 1 cut) is no longer used.

## The HUD (built as a mock-up, 2026-10-28)

`hud.ent`, drawn from the game's state; `check/hudshots.ent` takes
`build/shots/hud_<turn>.png` (seed 1, cautious, the mouse moved by the
check). A strip of 140 points along the bottom; the views end above it.

- **Cards** (one for each of the three): a 12 by 12 face in the role's
  colours (sand, rust, blue-grey; greyed and crossed out when down),
  "1 SCOUT" in Silkscreen, what it does (MOVING, WAITING, CARRYING,
  DOWN...), armour and fuel as numbers and bars (armour red under
  30), charges and flares as icons with counts. The chosen have a cyan
  edge; the card under the mouse a lighter one.
- **Orders**: ten buttons of 70 by 44 (go, wait, follow, blaster,
  flamer, charge, torch, scan, flare, carry), each a 9 by 9 icon, the
  word and the key; grey when nobody chosen can (no charges, no flares,
  the chest carried already); cyan when it is what all the chosen do;
  lit under the mouse.
- **Turn**: the number, the state (RUNNING, PAUSED, GIVE ORDERS
  blinking in manual, GOING BACK, WON, LOST), the clock as five amber
  blocks that empty a second at a time, the strategy switch (the one
  in force cyan, the next turn's amber), where the treasure is (gold).
- **Tip** over the world: one of the team ("click: choose"), a
  creature in sight (red HUNTING when it hunts), the matter remembered
  under the mouse and what it means ("soft: the torch cuts it fast"),
  "unknown" where nobody has looked.
- Fonts: m5x7 (CC0) for text, Silkscreen Bold (OFL) for names and
  headings; Jersey 10 (OFL) is kept for the title. All in `fonts/` with
  their licences; credits must name Silkscreen and Jersey 10 and ship
  their OFL texts.

Wired the same day (README, "The HUD"): cards choose, buttons give or
arm their order (armed: the button blinks, its icon by the mouse, the
tip says what a click does; since 2026-10-31 orders with a place are
given by key where the mouse points, and a button only tells its key),
the switch and the clock click, tips on
the strip explain each part. Not yet: the mini map has no panel of its
own; the strip's places are fixed for a window 1440 points wide (wider
windows give the right panel the rest); no sounds.

## The sprites (drawn by hand, 2026-10-28)

The image model could not hold a 5×9 sprite, so the sprites are drawn as
text in `art/sprites.py`: each frame is rows of letters, each letter a
palette colour. `python3 art/sprites.py` writes `art/sprites.png`
(180×104, the sheet the game loads) and `art/sprites_x8.png` (a preview
eight times larger). The game loads the sheet in `load_fonts()`
(`Sheet.id`); without it (id 0) everything is drawn as boxes, as before.

Sheet layout:

- Soldiers: row `(soldier*2 + facing)*10`, 18 poses 10 px apart, each 5×9
  (drawn at the foot point minus 2,8). Poses: stand 0-1 (blink), walk 2-5,
  climb 6-7, fly 8-9 (jet flame), fall 10, shoot 11, haul 12 (the grapple
  line is drawn from the hand), carry 13-16 (chest held, walking), down 17
  (9×3, lying).
- Creatures: y = 60 + kind*8, x = (facing*2 + frame)*8; sizes crawler 5×3,
  duskbat 5×3, hound 7×7, borer 7×5, spitter 6×6. Two frames, faster for
  the duskbat; a red eye is drawn over a hunting creature.
- The chest: 6×4 at (0,100), drawn when lifted and not carried.

The scout has a scarf and a sand coat, the heavy a rust shoulder plate and
a pack, the tech blue-grey with lamps on top and the grapple; all three
have the cyan slit visor. Chosen soldiers get cyan corner brackets.
Looked at in shots/team.png, the creature shots and a run of the moves
course at 8 points a cell (walk cycle and jet flame visible).
