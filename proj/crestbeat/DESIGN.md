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
user's sketch was layout, not art; the art pass is still to come (see the
end).

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
  bars, drawn 1.25 and 1.5 times the size in darker greens (art to come),
  mixed into the swarms.
- **weaver** (`rty`), the gallery's moving track: walks down like an alien
  but sweeps across the streets as it comes, a street every two beats
  (`weave`), left, centre, right, centre, starting from its chart street.
  The player has to read where it will be on the next shot. Purple rim.
- **golden alien** (`zxc`), the gallery's golden duck: lives 2 bars,
  pays `bonus` (shown 1000). It appears halfway up the hill (`depth`) at the
  side its key names and slides across the streets, one street every 3
  beats (`track`), on screen for 12 beats, so there is time to clear the
  aliens in front of it. Aliens nearer in its street shield it. Getting
  away costs nothing.
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

The run is a list of stages (`stages` in `data.lua`), each with a chart
read one character a beat from the beat it starts on:

| Character | Meaning |
|---|---|
| `1` `2` `3` | send an alien down the left, middle, right street |
| `z` `x` `c` | a golden alien: `z` enters from the left, `x` and `c` from the right |
| `j` `k` `l` | a fleeing civilian down that street |
| `r` `t` `y` | a weaver starting in that street |
| `4` `5` `6`, `7` `8` `9` | a brute, a hulk |
| `q` `w` `e` | open the titan's hot spot over that street for 2.5 beats |
| `a` `s` `d` | the titan spits down that street; it lands two beats later |
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

The run: the hill swarm (one brute), a climb, the titan, the streets swarm
with civilians, a brute and a golden alien (one heart back), a climb, the
crest swarm (clusters, a hulk, a brute, two golden aliens), a climb, and
the hive queen (pink, aliens and spit between hot spots; one heart back).
The bot, which steers perfectly, takes 31, 7, 31, 37, 7, 38, 7 and 43 beats,
about 100 seconds, and loses two hearts in the crest swarm; a person takes
longer, since only hits move things on.

## The titan

A great bug standing behind the crest, swaying, drawn from ovals and lines
in `draw_titan`. As it arrives, every building on the far part of the hill
gets a moment to collapse at, so it crunches through the skyline. Its three
hot spots sit over the three streets; an open one glows orange and can be
hit, a closed one is dark. Spit is telegraphed by a flashing red bar where
it will land and a glob travelling down the street; it lands on the beat
and hurts the robot if it is still in that street.

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

## Modules

| File | Owns |
|---|---|
| `data.lua` | Parsers, constants, stages, guns, judgements |
| `world.lua` | Projection, sky, road, buildings, effects |
| `aliens.lua` | Sending, hopping, hurting, drawing aliens |
| `titan.lua` | The titan, its hot spots, its spit |
| `robot.lua` | Streets, guns, firing, drawing the robot |
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
  no input until it is lost, a restart, and the win screen (`boot_*.png`).
- `test_stage_1` to `test_stage_8`: each starts a run at one stage
  (`first_stage`) and lets the bot (steer to the most urgent target, away
  from spit) play it to its end; the last must end in the win. Each prints
  its beats and hearts and dumps a screen (`stage_*.png`). The bot never
  loses a heart: 29, 7, 10, 27, 7, 29, 7 and 26 beats, 71 seconds.
- `test_rhythm`: each gun fires on exactly its pattern's eighths; a hit on the beat and its
  knockback; a late arrival inside and outside `good_window`; nothing fired
  and the glow on an empty beat; minigun, front-only and splash damage; that
  every kind lives exactly its bars under every gun; a leak;
  the chart; open and closed hot spots; spit in and out of its street; when
  a swarm and a titan stage are done; the titan and rising aliens read off
  the screen.

## Still to do, or not checked

- The art pass, which the user asked to leave to the end: the titan as a
  kaiju lizard-dragon of our own, the small enemies Tyranid-like, sprites
  for each distance, the same readable colours.
- The music has not been heard, and whether `stat(50)` keeps the clock on
  the drums on the user's machine is untested (the tests stub music).
- Every number (alien health, window, cadences, charts) is tuned only
  against the bot.
