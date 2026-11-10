# Crestbeat

You are a giant red robot at the foot of a hill in a city. Aliens pour over
the crest down three streets. Your guns fire themselves on the beat; your
job is to have the robot and its reticle on the right street when each beat
lands, and to pick the gun. It is a demake of a motion-tracked arcade
shooter, where the player points at things to shoot them: here the pointing
is choosing a street, and the beats are the guns' cool-down. The user: "like
a frenetic english country dance", and, watching it, "more a shooting
gallery than a shmup".

The run is about 75 to 90 seconds, paced like **Godzilla Kaiju Wars VR**
(Raw Thrills): small clusters, a big enemy, clusters again, a boss. The
user's sketch was layout, not art; the art is described under "The art".

What it takes from where:

- **hivefall:** the robot (its mech sprite, recoloured red), sparks, rings,
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
| rockets | `x...x...` beats 1 and 3 | half a shot's damage to the front alien in each street beside |
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

**Tickets** scale with the level: each payout row's `each` is multiplied by
the stage's `tickets` (1 the hill, 2, 3, 4 the queen). On the plan, with
no golden alien and no bell, a whole run pays about 284 tickets, 124 of them
by the end of the crest (about 75 seconds); one golden alien on top makes
the user's "150 at 75s, hard but doable". Every bell rung adds about 135;
every golden alien about 173. So a flawless run without the golden aliens
reaches about 420, and 500 takes going for every golden alien and winning,
as the user asked.

## The titan

A kaiju lizard-dragon of our own standing behind the crest (see "The art");
the titan green, the behemoth lavender, the queen pink. As it arrives, every building on the far part of the hill
gets a moment to collapse at, so it crunches through the skyline. Its three
hot spots sit over the three streets; an open one glows orange and can be
hit, a closed one is dark. Spit is the user's "get out of this lane by beat
x": it goes down the street the plan is in, telegraphed by a flashing red
bar with a beat countdown and a glob travelling down, and lands two beats
later, by when the plan has moved on; it hurts the robot if it is still
there.

**Ring the bell** (the user's exploration): three lamps above the giant's
head, one for each hot spot. One shot on a spot lights its lamp; a second
shot on a lit spot puts all the lamps out; all three lit rings the bell
for its tickets, once a giant. So it asks for a different dance from
knocking the giant down: one shot on each spot and move on, which costs
damage. The plan does not ring it (it shoots each window twice); ringing
is the player's choice.

While a titan stands, the horizon (`crest_y`) eases down from `horizon` (40)
to `titan_horizon` (82), so the road is the bottom third of the screen and
the titan, lifted with it, stands whole against the sky; it eases back up
as the titan falls. The road always ends at `hill_bottom` (100).

## The picture

`project(lane,t)` is the whole perspective: streets close up toward the
crest and the road falls away more steeply near the robot. Draw order: sky
and skyline, the ground, the road and its dashes, buildings behind the
crest, the titan (clipped at `crest_y+4`, so it stands behind the crest),
aliens still behind the crest (clipped at `crest_y`, so they rise in front
of the titan), the other buildings far to near, spit, aliens far to near,
the aim, the robot, effects, HUD, beat bar. `test_rhythm` reads both clips
off the screen.

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
- **The giant** is a set of parts, after witchcap's hut: a torso (40x32), a
  head with its jaw shut or open (24x20, open just after it spits), wings
  behind (16x24, the right one mirrored), hands and feet (8x8, 16x8), all
  drawn 1:1, and arms and legs as solid limbs between them, rows of filled
  circles with one outline (`draw_limb`). Its feet stomp in turn on the
  beat, its arms swing, it bobs on the beat, its head turns a little toward
  the robot, and its wings sit further back, moving less as it sways. Its
  body colour is swapped per giant. The hot spots sit on its chest and
  shoulders, with the bell's lamps above them.

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
- `test_rhythm`: each gun fires on exactly its pattern's eighths; a hit on the beat and its
  knockback; a late arrival inside and outside `good_window`; nothing fired
  and the glow on an empty beat; minigun, front-only and splash damage; that
  every kind lives exactly its bars under every gun; a leak;
  the chart; open and closed hot spots; spit in and out of its street; when
  a swarm and a titan stage are done; the titan and rising aliens read off
  the screen; golden aliens, civilians and weavers; the bell; the payout's
  rows, total, dispensing and spring.

## Still to do, or not checked

- The robot is still hivefall's 24px mech drawn at 1.5x, and the civilian
  one 16px sprite scaled by distance; the user prefers sprites drawn at
  their size to scaled ones, so these are next if the art goes further.
- A bell route through a giant (one shot on each spot) is possible by hand
  but not designed in `levels.py` or played by a test.
- The music has not been heard, and whether `stat(50)` keeps the clock on
  the drums on the user's machine is untested (the tests stub music).
- Every number (alien health, window, cadences, charts) is tuned only
  against the bot.
