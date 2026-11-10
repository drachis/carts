# Crestbeat

You are a giant red robot at the foot of a hill in a city. Aliens pour over
the crest down three streets. Your guns fire themselves on the beat; your
job is to have the robot and its reticle on the right street when each beat
lands, and to pick the gun. It is a demake of a motion-tracked arcade
shooter, where the player points at things to shoot them: here the pointing
is choosing a street, and the beats are the guns' cool-down. The user: "like
a frenetic english country dance", and, watching it, "more a shooting
gallery than a shmup".

**This is the `crestbeat-smooth` branch**, the user's "insane thing": the
hard beats smoothed out, while the game stays about beat matching. Shots
still land on the beat; everything else moves as a continuous function of
song time (see "Smooth motion"). `crestbeat` is the beat-snapping version.

The run is about 75 to 90 seconds, paced like **Godzilla Kaiju Wars VR**
(Raw Thrills): small clusters, a big enemy, clusters again, a boss. The
user's sketch was layout, not art; the art is described under "The art".

What it takes from where:

- **hivefall:** the robot's look (redrawn at full size), the swarm's skitter, sparks, rings,
  popups and shake.
- **Unreal Tournament and Doom:** the guns: a minigun, a shock rifle,
  rockets that splash.
- **Godzilla Kaiju Wars VR:** the pacing, and a giant to fight at the crest.

## Rules of the build

1. Tuning and content are data strings in `data.lua`: a stage is a chart
   string, a gun is a row.
2. Art, sound and music are text in `gen_cart.py`, which rewrites every
   cart's `__gfx__` and on. Look at `sheet.png`.
3. PICO-8 is the only token counter (`py count_tokens.py crestbeat.p8`).
4. 30fps (`_update`), as the user asked; test carts wrap `_update`.
5. No comments in the Lua; notes in `notes/<module>.md` (`CODE_NOTES.md`).
6. The game is one cart. Test carts may be split.
7. Lua is edited with the edit tool, not shell scripts.

## The music

The user asked for drum and bass or synthwave, and for it to follow the
run's emotional beats: verse and chorus matching the game's sections,
building toward the boss. `gen_cart.py` writes a synthwave song in A minor
(Am F C G, with F G, Em, Dm and E for the builds) at the game's 120 BPM, a
section per stage, each looping for as long as its stage lasts:

| Stage | Section |
|---|---|
| hill | verse one: an intro (kick and a held sine bass), then the lead over a pumping saw bass |
| climbs 1 and 2 | a build: half-time drums, a rising arp, a snare roll |
| titan | chorus one: a drum-and-bass two-step breakbeat, the chorus lead |
| streets | verse two: new chords (Dm, E) and arps |
| behemoth | chorus two: an amen-style break and stabbing leads |
| crest | verse three: the bridge's chords, tension toward the end |
| last climb | the breakdown: hats only, held bass, a slow sine lead |
| queen | the last chorus: the amen break, every lead up an octave |

38 patterns from 48 sfx (all the slots the game's own sounds leave; four were freed for the guns by letting a few patterns share parts).
`start_stage` queues its section (`stage_music`, which `gen_cart.py` checks
against the song) and `on_beat` starts it on the next 8-beat boundary,
where the old section's pattern ends, so the beat clock stays on the drums.
Channel 0 is drums in every pattern, the breakdown too (soft hats). Drum and
bass runs near 174 BPM; here its breaks play at the game's 120, which the
beat clock needs. A recording (`itch/crestbeat_music.wav`, verse one then
chorus one) measured the verse's strongest pulse at 1 s (kicks on 1 and 3)
and the chorus's at 0.5 s; it has not been listened to by anyone yet.

## The beat

`clock` is the song position in beats. It advances `1/frames_per_beat` a
frame (14.94 at 30fps). The music is 120 BPM in 4/4 at sfx speed 15, a note
a quarter beat, 32 notes (8 beats) a pattern. While music plays, each time
channel 0's note number (`stat(50)`) changes, `clock` is pulled halfway
toward where that note says it should be, so the game cannot drift from the
drums. With music stubbed (the tests) the clock runs on frames alone.
`frames_per_beat` assumes a speed-1 note lasts 183 samples at 22050Hz; the
manual does not give a note's length, so this is an assumption the sync
covers.

Every whole beat `on_beat` reads the stage's chart.

## Guns

X is the next gun, O the one before; left/right change street. There is no
fire button. Each gun's `pattern` is a 4/4 bar in eighth notes, an `x` for
each eighth it fires on, to mix up the rhythm:

| Gun | Pattern | Special |
|---|---|---|
| minigun | `xxxxxxxx` every eighth | |
| shock rifle | `x.x.x.x.` every beat | no pierce (the user found it looked and felt wrong) |
| rockets | `x...x...` beats 1 and 3 | half a shot's damage to the aliens close behind its target, same street only |
| flak cannon | `x.x.x...` the user's 3/4, `123_` | |
| plasma rifle | `x.x.xxx.` the user's `12_123`: two long, three short | |

**Health is in bars**, as the user asked: an enemy's `bars` is how long it
lives under fire, whatever the gun. Health is `bars*8`, and a gun's shot
does `8/shots`, its shots being the `x`s in its pattern, so every gun does
one bar of health a bar. A swarm alien lives half a bar (two beats, the
user's "shoot shoot, 2 beats"); with a gun that fires off the bar's grid
(flak, plasma) a kill rounds up to the next shot. The shock rifle is the
starting gun; X/O cycle through the list in this order.

- **On the beat:** if there is a target in the robot's street (the front
  alien, or the titan's open hot spot), the shot lands, white.
- **Nothing to shoot:** nothing fires; the robot's lights glow in the gun's
  colour as the beat's acknowledgement. If the robot reaches a street with
  a target within `good_window` (10 frames, 1/3s, as the user said is
  okay), the shot lands late: yellow, half score, half knockback. A beat
  with nothing to shoot while aliens are on the hill ends the combo.
- Every eighth hit in a row raises the multiplier, to x4. `score` is kept in
  tens (shown with a 0) so it cannot pass PICO-8's 32767.
- A hit knocks an alien back up the hill by `knock_per_damage` beats a
  point of damage.

The beat is background, for pacing: the user asked for the NecroDancer feel
softened. What carries it is the music, the aliens hopping on the beat, the
robot's one-pixel bob and the shots themselves. Along the bottom a thin dim
timeline shows the gun's next shots as short ticks in its colour flowing to
a grey mark at the left, with dark dots on whole beats and the gun's name at
the right. Nothing in it flashes, and the dashes no longer flash either.

## Aliens

Each kind of enemy is a row of `kinds` (chart keys, health, how it moves,
bonus, colours); the user's shooting-gallery ideas are being built in as
kinds, so that the enemies' movement makes the player pick a street with
intention.

- **alien** (`123`): sent on a beat, rises over the crest on that beat, then
  hops down the street one hop a beat for `walk` (8) beats. `t` is its
  depth: 0 at the crest, 1 at the bottom of the hill. At `t>=1` it is gone
  and the robot loses a heart; at 0 the run is lost. Lives half a bar.
- **brute** (`456`) and **hulk** (`789`): the same walk, living 1 and 1.5
  bars, shown at 1.25 and 1.5 times the size (a larger sprite, not a
  scaled one) in darker greens, mixed into the swarms.
- **weaver** (`rty`), the gallery's moving track: walks down like an alien
  but sweeps across the streets as it comes, a street every two beats
  (`weave`), left, centre, right, centre, starting from its chart street.
  The player has to read where it will be on the next shot. Purple rim.
- **golden alien** (`zxc`), the gallery's golden duck: lives 2 bars (8
  shock rifle shots), pays the big tickets. It comes in from the side its
  key names, halfway up the hill (`depth`), and slides across the streets
  a street every 4 beats (`track`): 12 beats on the streets, so its 8 shots
  fit with a little room. Aliens nearer in its street shield it, and
  knockback does not slow it (it is on a track). Getting away costs nothing.
- **civilian** (`jkl`), the gallery's don't-shoot target: flees down a
  street twice as fast as an alien (`walk` 4), so it overtakes aliens and
  blocks the street for about two seconds; the reticle on it is red with a
  "!". A shot on the beat into it costs `penalty` (shown 500) and the combo
  and spares it; a late shot never lands on one, so passing through its
  street is safe. Reaching the bottom costs nothing. The streets stage
  mixes them in, so the player shifts to the other streets while one
  passes, then dives in behind it.

A hit knocks an enemy back by moving its start later (`born`). A kill
tips it over backwards like a gallery target (`draw_fallen`), with a hard
clack. The reticle (yellow brackets with a red pip a point of health) is on
the target in the robot's street, alien or hot spot.

## Stages

The stages are designed in `levels.py`, which writes `levels.lua` (never
edited by hand). A stage is designed as its **plan**: the intended route of
targets, a window of beats for each, in which the shock rifle (the starting
gun) is in the target's street. The generator works out when each enemy is
sent so it is on the hill for its window, and writes the chart and the plan
as strings a character a beat. There is always a designated street: hold
**down** in the game to see it, a green chevron for the next shot and dimmer
ones for the two after. It checks, and fails the build, if a civilian or
the golden alien would stand in the plan's way, or a spit would land on
the plan's street.

**Slack** is how many beats an enemy's last planned shot comes before it
would reach the bottom. It shrinks level by level (5, 3, 1), so the
**survival margin**, how many beats behind the plan a player can be and
still clear the stage, shrinks too. The stage carts measure it by playing
each stage at 0 to 8 beats behind the plan, and fail if it moves from the
design (`margin` in `levels.py`); the generator asserts it never grows from
one street stage to the next, nor from one giant to the next:

| Stage | Survival margin | Golden route costs |
|---|---|---|
| hill | 6 beats | nothing (it comes in a lull) |
| titan | 8 (one spit) | |
| streets | 4 | up to 2 hearts |
| behemoth | 2 | |
| crest | 2 | up to 2 hearts |
| queen | 1 | |

So most players get through the first titan and into the streets, about
30 seconds; few get through the crest and the queen.

**The golden route.** Each golden alien has a second plan, `golden`, that
takes it: from its arrival the gun is on it whenever it is in front in its
street, shooting the alien that shields it out of turn when one does, and
the rest of the plan waits. Early, a lull pays for it; later, the delay
pushes aliens past the bottom: the user's "each gold uses some of the early
margin and is a health trade off later". The generator works out the
hearts (`gold_cost`, an upper bound: it leaves knockback out) and asserts
they are 0 first and grow; the stage carts play the golden route and check
it gets the gold within that cost. Down shows the golden route as a gold
chevron where it parts from the plan.

The chart the game plays reads one character a beat from the beat the
stage starts on:

| Character | Meaning |
|---|---|
| `1` `2` `3` | send an alien down the left, middle, right street |
| `z` `x` `c` | a golden alien: `z` enters from the left, `x` and `c` from the right |
| `j` `k` `l` | a fleeing civilian down that street |
| `r` `t` `y` | a weaver starting in that street |
| `4` `5` `6`, `7` `8` `9` | a brute, a hulk |
| `q` `w` `e` | open the titan's hot spot over that street for 2.5 beats |
| `a` `s` `d` | the titan spits down that street; it lands two beats later, counting down |
| anything else | a rest |

A swarm stage is done when its chart is played and no alien is left. A
stage with `fly` lifts the robot on its jets and slides the city toward it
(`fly_speed`); buildings that pass the robot come round again at the crest,
standing. A stage with `bars` is a titan: it lives that many bars of fire
(the titan 4, the queen 6), shared between its three hot spots, and its
chart loops until they are gone; then it sinks in flames for 1.5 seconds.
Each spot rounds up to whole shots, so with the shock rifle the titan takes
4.5 bars and the queen exactly 6. The last stage done is the win. Each stage
shows its `title` as a banner; `heal` gives back hearts.

The run is three streets, two giants and the queen, as the user asked:
the hill (a golden alien in a lull), a climb, the titan, the streets
(civilians, a brute, a weaver, a golden alien; one heart back), a climb,
the behemoth, the crest (a hulk, a civilian, a weaver, a golden alien), a
climb, and the hive queen (one heart back). On the plan: 27, 7, 22, 32, 7,
28, 36, 7 and 39 beats, about 100 seconds; the golden aliens hold a stage
open until they have crossed.

**Points** scale with the level: each payout row's `each` is multiplied by
the stage's `tickets` (1 the hill, 2, 3, 4 the queen). **Tickets** follow
an exponential curve of the points, as the user asked: with `p` the share
of `perfect_points`, `500*(2^(2p)-1)/3`, so only a perfect run pays 500
(99% of it pays 490, half of it 166). `perfect_points` (601) is what every
stage's golden or bell route scores (the stage carts print `points N
golden`). A clean plan win scores 284 and pays 154; the three bells on top
pay 271; a golden alien or two on top of that, with hearts lost on the way,
pass 300: the user's "300 with mistakes". Dying at 30 seconds pays about 10.

**Body block** (the user's rule): an alien reaching the bottom in the
robot's street costs a heart but counts as downed and scores; one reaching
the bottom in another street leaks, a heart and no points. So chasing a
golden alien can trade hearts for points by blocking what it lets through.

## The titan

A kaiju lizard-dragon of our own standing behind the crest (see "The art");
the titan green, the behemoth lavender, the queen pink. As it arrives, every building on the far part of the hill
gets a moment to collapse at, so it crunches through the skyline. Its three
hot spots sit over the three streets, each behind its third of a blue honeycomb
force field standing in front of the body; when a spot opens its cells
flash and fall away over half a beat, and it can be hit (rings on the chest still read as nipples). A shot into a
shielded street sparks off the shield and does nothing (the user found the
old glowing orange spots looked like nipples; the shields are a look
change only, what can be hit is the same). Over its head, one segmented
health bar a street, a segment per bar of its health (4 for the titans, 6
for the queen), the open street's blinking yellow; a destroyed street's
bar is empty and its shield gone. A destroyed street is a damage state:
a black crack with a flickering red edge, smoke and embers rising from it,
and on a side street that arm hangs limp (the user asked). The bell's lamps
are the bars' frames, yellow when lit: the old round lamps on the chest and
the torso's dark scale dots read as nipples, and are gone. Spit is the user's "get out of this lane by beat
x": it goes down the street the plan is in, telegraphed by a flashing red
bar with a beat countdown and a glob travelling down, and lands two beats
later, by when the plan has moved on; it hurts the robot if it is still
there. And the giant spits at anyone idling: a robot that has stood in one
street for `idle_beats` (4) is spat at where it stands, so no one can sit
in a street waiting for its hot spot to reopen (the user: "spit should force
the player to keep moving"). The generator asserts the plan never holds a
street long enough to draw it, counting round the chart's loop.

**Ring the bell** (the user's exploration): three lamps above the giant's
head, one for each hot spot. One shot on a spot lights its lamp; a second
shot on a lit spot puts all the lamps out; all three lit rings the bell
for its tickets, once a giant. Destroying any spot before the bell rings
takes the bell away and its lamps go dark (the user's rule). So it asks for a different dance from
knocking the giant down: one shot on each spot and move on, which costs
damage. The plan does not ring it (it shoots each window twice); ringing
is the player's choice. Each giant has a **bell route** (`bell_route` in
`levels.py`, in the stage's `golden` column, so down shows it in gold
chevrons): the first time each spot opens it takes one shot and moves to
the next window's street a beat early, skipping any reopening of a spot
already lit, until the bell rings; then the plan. The stage carts play it:
on every giant it rings the bell for no hearts, the giant just takes a
little longer to fell.

While a titan stands, the horizon (`crest_y`) eases down from `horizon` (40)
to `titan_horizon` (82), so the road is the bottom third of the screen and
the titan, lifted with it, stands whole against the sky; it eases back up
as the titan falls. The road always ends at `hill_bottom` (100).

## The picture

`project(lane,t)` is the whole perspective: streets close up toward the
crest and the road falls away more steeply near the robot. Draw order: sky
and skyline, the ground, the road and its dashes, buildings behind the
crest, the titan (clipped at `crest_y+6`, so it stands on the crest),
aliens still behind the crest (clipped at `crest_y`, so they rise in front
of the titan), the other buildings far to near, spit, aliens far to near,
the aim, the robot, effects, HUD, beat bar. `test_rhythm` reads both clips
off the screen.

## Smooth motion

The one rule of this branch: nothing snaps on a beat except the shots. A
sine with a one-beat period is 0 on every whole beat, so motion can surge
and ease within a beat and still be exactly where the hopping version was
when a shot lands; that keeps `levels.py`'s plans, margins and routes true.

- **Walkers** move `beats - surge*sin(beats)` (surge 0.12): a push forward on
  each beat easing off between, never stopping, with a smooth arc of a bob.
- **Weavers** sweep along a cosine, -1, 0, 1, 0, instead of stepping.
- **The golden alien** glides across at a constant speed, its street
  boundaries put mid-beat (it enters at 2.125 streets out) so a shot on the
  beat is never on a boundary. While it straddles two streets it can be
  shot from either (`straddle` 0.7): an option, not the plan.
- **Knockback** is a spring, a quarter of the push a frame.
- **The robot** slides between streets on a damped spring (`robot_spring`,
  `robot_damping` 0.45): about 1.5px past the street and settled in 10
  frames. Its street changes at once for the guns; only the picture glides.
- **The reticle** glides from target to target.
- **The camera leans** with the robot: `cam_x` is a quarter of its offset
  (`camera_lean`), following its spring, and each thing moves by its depth:
  the skyline 15%, the giant at the crest 30%, the road and everything on
  it from 30% at the crest to all of it at the bottom, the robot and its
  shots all of it. The city seems to turn as it moves.
- **The giants** stomp each foot through a smooth half-sine, one a beat,
  landing on the beat; their shields shrink away and grow back over a
  quarter of a beat.
- `test_screen` measures it: an alien's depth frame by frame over eight
  beats must always move forward, and no frame's step be more than three
  times the mean (it is 0.0021 to 0.0146 against 0.0084; the hop stood
  still two thirds of each beat).
- **The pulse** is a smooth wave, `(1+cos(clock))/2`, 1 on the beat and 0
  between, never a jump; the robot's and the giant's bobs follow it.
- Each frame the enemies move before the guns fire, so a shot on the beat
  sees where everything is on the beat.

## The title

The user asked for a very 1980s title with the robot flying down the street
towards the fight: a synthwave sky (navy to purple, dithered), stars, a
striped sunset sun whose slats widen toward the bottom and scroll, the titan
in black silhouette rising over the horizon in front of it, a neon grid of
pink lines rolling toward the player with the street's edges in blue, the
robot on its jets swaying down the street, and a chrome logo in banded
white, blue and grey. It draws no HUD.

**The play screens share it** (the crestbeat-synth branch: the user loved
the title and wished the whole game had its art direction). `sunset` draws
the same sky and sun at the crest, so the giants stand in front of the
setting sun; the skyline is black silhouettes; the buildings are navy with
neon outlines and lit windows; the ground is black with a dim purple grid,
pink road edges and blue lane dashes. In a giant fight the sun glides up
behind the giant's head as it rises, a halo like an old religious painting,
and throws Loretta's god rays across the sky (the user asked).

**Juice** (the user: "a thousand tokens left? Go wild"):

- Shots are neon: a coloured beam a pixel wider each side with a white
  core, and a small ring at the muzzle; every kill throws a pink ring.
- Stage banners are chrome, in the title logo's banded white, blue and
  grey (`chrome`, tall letters); the title logo is the same function, wide.
- Switching streets leaves neon afterimages of the robot: blue, then pink,
  then purple as they fade over six frames.
- **Fever** at the top multiplier (x4): the grid turns hot pink, the sun
  throws its god rays on any stage, and "fever x4" blinks in the HUD.
- A giant's death: a half-white flash for two frames, a chrome "giant
  down!", pink and blue shockwave rings, and the halo's rays flaring out as
  it sinks.
- A saved city gets neon fireworks over the payout.
- **Each gun has its own character** (the user: "weapons need some
  character"), a `style` and a sound of its own: the minigun a dry brrt and
  brass casings flying off both pods; the shock rifle a sliding zap and a
  crackling lightning bolt with a white core; rockets a smoke trail that
  drifts up and a blast ring; the flak cannon a chunky boom and a spread of
  pellets round the target; the plasma rifle a wobbling phaser and balls of
  plasma riding the beam.
- **The payout rains tickets** over everything, panel and HUD included
  (the user: "shimmering multi color tickets"): each flutters down, turning
  (its width is the cosine of its spin), cycling through six colours and
  flashing white when it faces you. Every other ticket chimes: a click, a
  bell and its fifth, its pitch poked into the sfx before it plays so the
  chimes climb a two-octave pentatonic scale (`chime`) and start again;
  the last ticket out plays the fanfare.
- A hit flashes a dithered red frame round the screen and tears a few
  screen rows sideways, like a VHS tape's tracking.
- A white scan line sweeps down the giants' hex shields.
- The title has a VCR's "play" in its corner.
- The sun is reflected in the road as dithered glints below the crest, and
  the climb stages throw warp streaks out of the sun. The aliens' green, the golden alien
and the robot's red stay as they were: they read clearly on black.

## The art

The figures are drawn from shapes by `art.py` (run by `gen_cart.py`), at
the size they are shown: the user prefers many sprites to scaled ones. The
colours stay readable: the swarm green (11 on 3), the golden alien gold,
civilians white and brown, the robot red, the giants their own colours.

- **The swarm** is a Tyranid-like bug (after hivefall's skitter): scything
  talons up, a dark carapace over a green body, red eyes, grey legs, and a
  second frame with the talons raised and the legs stepped. It is drawn at
  ten sizes, 8 to 32 pixels, two frames each, filling the top of the sheet
  (`swarm_sprites` in `data.lua` says where each is). An enemy is drawn 1:1
  with the largest that fits the size its depth asks for; brutes and hulks
  reach the larger ones. A kind's colours are swapped in with `pal`.
- **The robot** is drawn 1:1 at 36x36 (art.py's `robot`): red armour seen
  from behind, gun pods up on its shoulders with lit tips, a visor, a back
  plate with two thrusters, armoured legs. The sheet is full, so, as the
  user suggested, it lives in the map's top half (0x2000), which this game
  has no map for: `from_map` copies its rows over the sheet's top-left
  corner (saved in upper memory, 0x8000) just to draw it, then puts the
  corner back. The manual lets the sheet be remapped only to 0x00 or the
  screen, so copying is the way. There is room in the map for 128x64
  pixels more.
- **Civilians** are drawn the same way at 8, 12, 16 and 24 pixels
  (`civilian_sprites`): arms thrown up, brown hair, a white shirt, blue
  trousers; they bob a pixel as they run.
- **The giant** is a set of parts, after witchcap's hut: a torso (40x32), a
  head with its jaw shut or open (24x20, open just after it spits), hands
  and feet (8x8, 16x8), all drawn 1:1, and arms and legs as solid limbs
  between them, rows of filled circles with one outline (`draw_limb`). Its
  feet stand on the road at the crest and stomp in turn on the beat, its
  arms swing, it bobs on the beat and its head turns a little toward the
  robot. Its wings are drawn as the wyrm games draw theirs (wyrmdeep): an
  arm out to a wrist, four finger bones fanning from it in the body's
  colour, and the membrane as lines from the wrist to scalloped points
  between them, flapping once every two beats; they sit further back,
  moving less as it sways. Its body colour is swapped per giant. The hot
  spots sit on its chest and shoulders, with the bell's lamps above them.
- **The hive queen** (`crown` in `levels.py`) is the same frame given a
  queen-of-the-swarm look of our own, as the user asked for one with a
  crown: her own head (24x24 at 88,96: a narrow face with glowing green
  eyes and cheek ridges, dark spined tendrils sweeping to her shoulders, a
  gold chitin crown with red gems), and bone blade-wings in place of the
  membrane: the four finger bones drawn long, tapering and white.

## The ticket payout

The game is meant to be installed as a ticket arcade cabinet. When a run is
won or lost, the payout runs, after bal8tro's cash-out (the user: "that
game does it super well"): a panel springs up from below the screen and
settles; one line at a time arrives with a tick and counts up its tickets
(aliens downed 1 each, golden aliens 10, bells rung 5, giants felled 10,
civilians hit -2, city saved 25); then the ticket total rolls up in big
digits while paper tickets are thrown out of a slot at the bottom with a
ka-chunk. A run always pays at least one ticket. A press starts a new run
only once every ticket is out. The rows are `payouts` in `data.lua`.

## Modules

| File | Owns |
|---|---|
| `data.lua` | Parsers, constants, stages, enemy kinds, guns, payouts |
| `world.lua` | Projection, sky, road, buildings, effects |
| `aliens.lua` | Enemy kinds: walking, tracks, weaving, hits, knockdowns |
| `titan.lua` | The titan, its hot spots, its spit, the bell |
| `robot.lua` | Streets, gun patterns, firing, drawing the robot |
| `payout.lua` | The ticket payout |
| `main.lua` | Modes, the beat clock, stages, aim, HUD, beat bar |

## Tests

**Test builds.** Every test cart includes the whole game, and the game is
past 7600 tokens, so `gen_cart.py` writes three stubbed copies of the
modules into `tests/` (git-ignored): `lite.lua` without the screens no
logic test reads (the logic carts: rhythm, rhythm2, giant, giant2, kinds,
margin_*), `play.lua` without the title and the payout (the stage and screen carts; test_boot films both payouts), and
`boot.lua` without the giant fight's rules and the aim and plan (test_boot, whose title screen
is the cart's label). The itch recorder has two more, `capture_play.lua` and `capture_menus.lua`. A stub is an empty function of the same name. The
margin checks (`test_margin.lua`) are carts of their own beside each
stage's plan run.


    py run_tests.py --no-comments
    py count_tokens.py crestbeat.p8

The whole suite takes about 8 seconds: ten carts in ten PICO-8 windows at
once (the user: "no harm in running a few dozen pico8 instances", and
wants all of it in 10s). The boot and stage carts run the game
`updates_per_frame` (8) times for each frame PICO-8 shows, and draw only
the last, or when they dump a screen. `tests/bot.lua` stubs the buttons and
sound and holds the bot.

- `test_boot`: the real cart from its title, X then O once each, a run with
  no input until it is lost, a restart, and the win payout, where a press
  before it is done must not restart (`boot_*.png`).
- `test_stage_1` to `test_stage_9`: each starts a run at one stage
  (`first_stage`) and lets the bot follow the plan (`tests/bot.lua`) to its
  end, which must cost no heart; the last must end in the win and play the
  payout out (`stage_payout_counting`, `stage_won`). Then it plays the stage
  0 to 8 beats behind the plan and checks the survival margin, and plays the
  golden route, which must get the golden alien within its designed cost.
  Each prints its beats, hearts and tickets and dumps a screen, and the
  first sight of each special kind (`stage_*.png`). A heart lost prints
  where.
- `test_screen`: what is read off the screen: the queen and rising aliens, the wings flapping, the robot drawn from the map and the sheet restored, the robot's spring; a shot blocked by a shield, the health bars and the shields read off the screen (`screen_shields.png`).
- `test_rhythm`: each gun fires on exactly its pattern's eighths; a hit on the beat and its
  knockback; a late arrival inside and outside `good_window`; nothing fired
  and the glow on an empty beat; minigun, front-only and splash damage; that
  every kind lives exactly its bars under every gun; a leak;
  the chart; when a swarm is done.
- `test_kinds` (split when the god rays passed the others over 8192 tokens): golden aliens, the queen's health, weavers, the payout's rows, curve, dispensing and spring.
- `test_giant` (split from test_rhythm when the title passed it over 8192
  tokens): open and closed hot spots, spit in and out of its street, the
  idle spit, when a titan stage is done, the road coming down and back up,
  a destroyed street's crack and smoke; civilians; the bell.

## Still to do, or not checked

- The music has not been heard by the user, and whether `stat(50)` keeps the clock on
  the drums on the user's machine is untested (the tests stub music).
- Every number (alien health, window, cadences, charts) is tuned only
  against the bot.
