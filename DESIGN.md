# Pixalorien

Three armoured bounty hunters land on a desert planet to bring back a
treasure buried deep below it. Every pixel is matter that moves, as in
EntSourcery (`../EntSourcery`), whose falling-sand automaton, routes,
deterministic turns, preview and order list this game builds on. The
look is a lone-gunslinger space western: mesas and dunes under two
suns, old mine shafts, lava tubes, glowing crystal, a battered ship.

(The vibe is the Mandalorian's; the names in the game are our own, so
that it can be shown and shared without trouble: no Star Wars names,
words or logos.)

## The game in one paragraph

A single-player game: one team, which the player follows and instructs.
There is no other team; what stands against it is the planet and its
creatures. (Several players are for later, if at all; nothing in this
design depends on them.)

The ship lands. A mini map shows where the team is and where the
treasure is, nothing more: the land between is unknown until someone
sees it. The team goes down into the caves by one of several entrances,
finds or breaks a way to the treasure, and carries it back to the ship.
Time runs on, and the player can pause it at any moment, run it faster,
or take it back. The team runs itself as carefully as the player says
(and that can change at any moment), or does only what it is told. The
world is not forgiving: soldiers die often, and going back to before it
went wrong is part of playing. The whole game can be watched again from
the landing. It ends when the treasure is on the ship, or when nobody
is left.

## Time

Turns of five seconds (taken from Frozen Synapse, where both players
plan at once) are gone (2026-10-29): with no opponent planning, a stop
every five seconds was artificial, an order waited for the turn's end,
and the autopilot could only decide as a turn began.

- The world runs a tick at a time (60 a second), deterministic: the
  same world and the same orders at the same ticks give the same game.
- Orders take effect at once. Space pauses and goes on; orders can be
  given while paused. Speeds 1, 2 and 4 times.
- The game pauses itself when something happens, each kind switched on
  or off in the settings (check boxes): a creature seen, a soldier hurt,
  falling, down, idle, dangerous matter found, the treasure lifted or
  dropped, a catastrophe. The pause shows a card in the middle of the
  screen, big, that says what happened and to whom, with the camera on
  it: go on, go back, or look.
- Every order the player gives (and every change of strategy) is logged
  with its tick, from the landing on. The world is saved at the landing,
  every 30 seconds for good, and every 5 seconds in a ring of the last
  six (a saved world is 28.8 MB). Going to any earlier moment loads the
  saved world before it and plays the log up to it, without drawing.
- A timeline: the game so far as a bar, the moment shown on it, marks
  where soldiers went down and where it paused itself. Behind the end,
  the log is played (watching); an order given there drops what came
  after and the game goes on from there. So the whole game can be
  watched from the start, at any speed, and taken over at any moment.
- Played backwards (a later step): each tick also keeps what it
  overwrote (an undo log of the awake chunks' cells and the rows of the
  team, creatures and shots), for the last 30 to 60 seconds; going
  backwards puts those back, a tick a frame, with everything drawn.

## Strategies

The player chooses one when the team lands, and can change it at any
time (it takes effect at once):

- **Manual**: nothing is done that the player did not order; soldiers
  fire back at what attacks them, and nothing else.
- **Cautious**: one scout ahead, the others one or two turns behind on
  the same way; a sealed rock face is listened to before it is broken
  (the scan, below); known ways before unknown ones; noise kept low
  (cutting torch rather than charges, walking rather than jetpack);
  back off from creatures, fight only when cornered; the treasure
  carrier escorted on both sides.
- **Brute force**: everybody on the shortest way, breaking what is in
  it with charges, jetpack where it is faster, fight what comes. Fast,
  loud, and it walks into what it cannot see.

In manual mode instructions are few, on purpose: **go** (to a place,
the way found), **break** (fire or set a charge at a place), **scan** (a
rock face), **wait**, **follow** (another of the team), **carry**
(the treasure). A selection of one or several gets the same order; a
group keeps its spacing.

## The Pixaloriens

Three, each 3 cells wide and 7 high. Armour, a helmet lamp, and:

| What | Does | Numbers |
|---|---|---|
| Walking | steps up to 5 cells | 1/3 cell a tick: 100 cells a turn on flat ground |
| Grapple | a hook shot up at the edge of a ledge, then pulled up onto it; holds only on rock-hard matter, wood or a ladder and for now sandstone (not sand, crumbling rock, ice, glass, crystal, nor air; sandstone to be thought over); catches a fall that would harm when the jetpack cannot brake | reach 64 cells, 1/2 cell a tick |
| Jetpack | flight while fuel lasts, refills on the ground | 1 cell a tick, 90 ticks of fuel (a hop of ~60 cells), refilled in 300 ticks |
| Blaster | a bolt; chips rock, sets gas alight, melts ice; at an open place (a creature) a burst of 3 | reach 300, every 20 ticks |
| Wrist flamer | short flame; burns, melts ice (and the team, in its way) | reach 40, used from 16 |
| Charges | a blast that breaks rock (not bedrock) | 4 each; radius 12; very loud |
| Cutting torch | cuts a body-wide hole, slowly and quietly; aimed into a wall, on through it | 1 cell of rock a tick ahead, up to 40 past the place |
| Scan | tells what is behind a rock face: air, water, gas, lava | depth 24 cells; takes a whole turn |
| Flares | thrown, light the cave around them | 3 each; radius 48 cells; 20 turns |

The route search of EntSourcery (a distance field backward from the
goal over every place) gets three more kinds of move: a grapple pull
(from a place to a ceiling or ledge in reach, then onto it), a jetpack
hop (straight up as far as the fuel goes, then aside onto a ledge), and,
for brute force, cutting (through breakable rock, at the cost of time
and noise). Fuel makes a hop a move of its own rather than a search
over fuel levels: a hop is allowed where the soldier has a full tank.

## The world and its size

**Size: 2048 by 1024 cells** (a cell is about 30 cm: some 600 m across
and 300 m deep). The view at 4 points a cell on a 1440 by 810 window is
360 by 200 cells, so the world is about 6 views across and 5 deep.

The surface: mesas, dunes and rock arches over the upper fifth; the
ship lands on one side, the treasure lies in a vault in the lower third
on the other side or under the middle. Under the surface:

- **Entrances: 3 to 4**: a cave mouth at a mesa's foot, a sinkhole from a
  mesa top, an old mine shaft with ladders and rotten wooden floors, a
  lava tube on the far side. Each leads into one of 2 or 3 cave systems;
  they join in a few places and around the vault.
- **Caves**: worm tunnels (as the island's tunnels in EntSourcery),
  chambers, shafts, ledges, underground lakes and rivers, crystal
  grottos, bedrock nobody breaks. Between the systems, breakable rock:
  the shortcuts.
- **Sealed pockets: about 40**, each a cave nobody can see into until it
  is breached or scanned: 40% empty, 25% water (floods what is under
  it), 20% gas (poisons, and explodes with fire or a blaster bolt), 15%
  lava (flows, burns, turns water to steam and itself to obsidian).
  Small hints for the careful: rock near lava is warmer in colour, rock
  near water darker and damp.
- **Unstable rock: 6 to 10 areas**: crumbling rock that falls when walked
  on, shaken by blasts, or undermined (cave-ins, which block a way back
  and bury what is under).
- **Creature habitats: 5 to 8**, each with 3 to 8 creatures.
- **Events: 3 to 5 a game**, on timers or set off: an inner lake bursts
  through, lava rises in a tube, a gas vent opens, a cave-in. Mostly away
  from the team when they happen; what the team sees on the way back is
  what it remembers, not what is there now.

Hazards a team meets on its way, roughly: 8 to 12 sealed pockets within
reach of its tools, of which brute force breaches 3 to 5 and caution 0
to 2; 1 to 3 unstable areas; 2 or 3 habitats near the way.

## How long a game takes

| Leg | Route length | Speed | Turns |
|---|---|---|---|
| Surface to an entrance | 300 to 600 cells | 100 cells a turn (walking, hops) | 3 to 6 |
| Down to the treasure | 1500 to 2500 cells (winding 1.6 times the straight line) | 40 to 70 cells a turn (climbing, scanning, breaking, fighting) | 25 to 55 |
| Back to the ship | 1500 to 2500 cells, known way | 60 to 90 cells a turn (carrier slower, surprises) | 20 to 40 |

So 50 to 100 turns: 4 to 8 minutes of play without stopping, 15 to 30
minutes with pauses, rewinds and manual stretches. Brute force should
be the fastest when it works and lose people more often; cautious the
slowest and the safest; a good player switching between them does
better than either alone.

Balancing is done by letting the autopilot play: headless runs of
each strategy on many generated worlds, as fast as
they go, counting turns to win, turns lost to rewinds, deaths, and where
they happened. Targets: brute force wins about half its games, cautious
about four in five, and neither ever stalls (a world where no strategy
reaches the treasure is a generator bug).

## Splitting up

Not required, but worth it, and the strategies use it:

- The scout ahead (cautious) sees and hears first; the others keep out
  of trouble behind.
- The treasure is heavy: whoever carries it walks at half speed and
  cannot use the jetpack. The others go ahead to see the way back and
  behind to guard.
- Some ways need two: one holds a grapple line or a door while the
  other passes (old mine machinery).
- A trapped soldier (cave-in, flood) is dug out from the other side.

## Sight and sound

- **Sight** goes in straight lines through air, gas and water (dimmer),
  as in EntSourcery, but only as far as there is light. On the surface,
  daylight: 180 cells. Underground: the helmet lamp, a cone of 32 cells
  the way the soldier faces and 10 cells around it; flares (48); lava
  (glows 20); crystal (8); fire. What a light falls on and a soldier
  sees is seen.
- **The remembered map**: every cell the team has seen is remembered as
  it was then (drawn dimmer when not seen now). The route search uses
  what is remembered, and treats the unknown as passable but costly. So
  a way back can be blocked by what changed unseen, and the team finds
  out when it gets there.
- **Sound**: walking, the jetpack, bolts, charges, cave-ins, creatures
  make noise of a loudness; it spreads through air and water (and
  weakly through rock), and fades with distance. Creatures hear it and
  come; the team hears it too (a sound marker at the edge of the view).

## Creatures

Each has a habitat it patrols, and leaves it when it hears something
loud enough, to find the source; it goes back when it has lost it.

| Kind | Moves | Habitat | Danger |
|---|---|---|---|
| Rock borer | digs through earth and soft rock, slowly | deep rock | ambushes through walls, makes new tunnels |
| Cave crawler | runs and climbs walls and ceilings, packs of 4 to 8 | dark caves | fast, many |
| Gloom bat | flies, flocks; avoids light | high chambers | swarms, knocks soldiers off ledges |
| Magma hound | runs, swims in lava, burns | lava tubes | sets gas and wood alight |
| Spitter | still, spits acid | lakes, crystal grottos | eats armour and rock |

## The view

- The world drawn with the light: unseen black, remembered dim, seen in
  full; the mini map in a corner (the whole world, what is remembered,
  the ship, the treasure's place, the team, sound markers).
- One view while the whole team fits in it at a sensible scale (at
  least 3 points a cell). Where it does not, a view for each group of
  soldiers close together, up to three. A soldier told to wait gets no
  view of its own unless something important happens near it:
  something hostile in its sight, a loud noise nearby, the ground moving
  under it, damage. Then its view opens until that is over.
- Selection: click, shift-click, a box; the order then goes to all
  chosen.

## Beyond the first game

- **Landing**: a short game first, where the player flies the ship down
  (thrust, fuel, the terrain as it is, wind), and where it comes down is
  where the team starts. A rough landing damages the ship; a ship that
  cannot take off loses the game. Cheap to add once the world exists.
- **Voxels, turned by 45 degrees**: the same world with depth, seen from
  the side but able to turn. The automaton's cost grows with the cells:
  the 2048 by 1024 world is 2 million cells and takes 11 ms a tick on
  all cores today (50 ms on one); 32 cells deep would be 67 million.
  Not before the game works in 2D; then a thin slab (8 to 16 deep, turned
  by 90 degrees, or drawn at 45) is the experiment worth trying.

## The engine work it needs

- **Sleeping chunks.** Measured on this machine: the EntSourcery
  automaton on a 2048 by 1024 world takes 11 ms a tick on all cores and
  50 ms on one. Playing a turn in real time fits, but the preview,
  rewinding and the autopilot's looking ahead play turns in one frame:
  3.4 s a turn. Most of the world is still most of the time, so the
  world goes in chunks of 64 by 64 cells and only chunks where
  something moved (and their neighbours) are worked; still ones sleep.
  At one chunk in twenty awake, a turn ahead is about 0.2 s. This is
  the first thing to build, and possibly a language feature rather than
  game code.
- A view (camera) over a world larger than the window, and the mini
  map.
- Light and the remembered map, sound spreading.

## Plan

1. **The world**: 2048 by 1024, sleeping chunks, the generator (surface,
   entrances, cave systems, sealed pockets, unstable rock, the vault,
   the ship), the camera and the mini map; measured. **Done 2026-10-27**
   (README: measured). Water levels (no heaps). Open: the fixed cost of
   a parallel loop while few chunks are awake, the cost of the water
   rules, lakes that drain for minutes through narrow tunnels.
2. **Sight**: light, the remembered map, drawing it. **Done 2026-10-27**
   (README: step 2). Open: light costs about two flow passes a tick
   (could run where the light can change only); a lamp lights only for
   its own eye; flares fall as a powder (throwing them is step 4); the
   surface known from the landing is only its top cells.
3. **The Pixaloriens**: walking, grapple, jetpack, routes over them,
   orders (go, wait, follow), turns of five seconds without stopping,
   pause. **Done 2026-10-27** (README: step 3). Open: the Pixaloriens
   walk through each other; searches through much unknown are dear at
   the start (27 ms at worst); the generator's narrow tunnels (under
   about 8 high) do not fit a body; falls do no harm yet.
4. **Tools and matter**: blaster, flamer, charges, torch, scan, flares;
   rock kinds, crumbling rock, lava, obsidian, explosive gas, ice,
   crystal; cave-ins. **Done 2026-10-27** (README: step 4). Open: tools do no
   harm to the team yet (step 8); no noise yet (step 5); the cutting
   move in routes is for brute force (step 6); a gas explosion is a
   flash that spreads, with no push; ice plugs only on side branches.
5. **Creatures**: the five kinds, habitats, patrols, hearing, attacks. **Done
   2026-10-27** (README: step 5). Open: the team fires back at anything
   hunting (manual mode should only answer attacks: done in step 6); creatures
   steer greedily (a step to the best neighbour, a random one when
   stuck), so they lose their way round corners; hounds that fall down
   a shaft stay below; balance (step 8): the team wins its fights
   easily one against a pack.
6. **The strategies** and rewinding. **Done 2026-10-27** (README: step 6).
   Open: the autopilot decides only as a turn begins, so a cautious
   scout walks into creatures alone and takes most of the harm;
   followers lose the scout's trail where it went down by jetpack or
   a fall (cautious took 39 turns on seed 1, manual 23, brute 17); the
   scan before cutting is wired but the scout rarely gets stuck; a
   saved world is 28.8 MB (the cells, Known and Nav, 2M rows each);
   the rewind keys are not yet tried by hand.
7. **The view**: selection, split views by importance. **Done 2026-10-28**
   (README: step 7). Open: views are only columns (a group far below
   another might be better in rows); the mini map lies over the right
   view; a waiting soldier's view only opens for what is near it, not
   what it sees; the rewind and view keys are not yet tried by hand.
8. **The goal and balance**: carrying the treasure, the ship, dying;
   headless runs of the strategies on many worlds. **Done 2026-10-28**
   (README: step 8). Open: brute force wins too often (8 of 12) and
   cautious loses more of the team (its scout alone meets the
   creatures; the autopilot decides only as a turn begins); 3 of 24
   games stall (vault doors not found from outside; a carrier that
   does not get back); the autopilot sets no charges and never scans
   much; carrying is one chest, no help from a second; falls are the
   second cause of harm (moves planned through the unknown).
Before landing: the look and the way in (ART.md): art direction and the
image model's brief with screenshots (`check/shots.ent`); then the HUD
(mouse first), the menus (dummies first), the tutorial (text, a drill
sergeant), and the art applied as it comes back. Music and sound later.

Time, not turns (2026-10-29, before landing):

T1 and T2 done 2026-10-29 (c4266b1).

- T1. **Time**: no turns; orders at once; pause and speeds; the
  autopilot decides every second; the log of orders by tick, saved
  worlds, going to any moment, watching from the start, taking over;
  the checks moved from turns to seconds.
- T2. **The time bar**: pause, play, speeds, back 5 and 30 seconds, the
  timeline with its marks, dragged to go anywhere; the end screen and
  the pause menu: watch the game from the start. Tips on everything.
- T3. **Pausing itself**: the events, the check boxes in the settings,
  the card in the middle of the screen. **Done 2026-10-29** (README:
  "Stopping by itself").
- T4. **An unforgiving world**: falls, lava, creatures and cave-ins kill
  more readily; catastrophes (a cave-in brought down by noise, a gas
  pocket that goes up, lava breaking into a cave) that are worth going
  back from. Measured: how often each strategy loses without going back.
- T5. **The tutorial**: pause, speeds, the timeline, a self-pause, and a
  catastrophe staged so that the squad is lost, then going back to
  before it and choosing otherwise.
- T6. **Backwards**: the undo log (in the game; as an ent feature later,
  open topic 51), measured (bytes a tick), and played backwards on the
  time bar.

9. Landing.
10. Voxels, as an experiment.
