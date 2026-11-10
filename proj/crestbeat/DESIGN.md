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
- **Unreal Tournament and Doom:** the guns: a minigun, a shock rifle that
  pierces, rockets that splash.
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

Every whole beat `on_beat` reads the stage's chart and pulses the lane
dashes.

## Guns

X is the next gun, O the one before; left/right change street. There is no
fire button. The gun in hand fires each time `clock` crosses a multiple of
its `every`:

| Gun | Fires | Damage | Special |
|---|---|---|---|
| minigun | every half beat (8 a bar) | 1 | |
| shock rifle | every beat (4 a bar) | 2 | pierces every alien in the street |
| rockets | every other beat (2 a bar) | 4 | 2 to the front alien in each street beside |

An alien has 4 health, so every gun kills a lone alien in two beats: the
user's "shoot shoot, 2 beats". The guns differ in what else they reach and
in when the robot must be in the street. The shock rifle is the starting
gun.

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

The beat bar along the bottom is a timeline: ticks flow in from the right to
the box at the left, one a half beat. The active gun's shots are tall ticks
in its colour, white just before they land; the other half beats are short
ticks, brighter on whole beats. The gun's name is at the right of the bar.

## Aliens

An alien is sent on a beat, rises over the crest on that beat, and then
hops down the street one hop a beat for `walk_beats` beats. `t` is its
depth: 0 at the crest, 1 at the bottom of the hill. A hit knocks it back by
moving its start later (`born`). At `t>=1` it is gone and the robot loses a
heart; at 0 the run is lost. The reticle (yellow brackets with a red pip a
point of health) is on the target in the robot's street, alien or hot spot.

## Stages

The run is a list of stages (`stages` in `data.lua`), each with a chart
read one character a beat from the beat it starts on:

| Character | Meaning |
|---|---|
| `1` `2` `3` | send an alien down the left, middle, right street |
| `q` `w` `e` | open the titan's hot spot over that street for 2.5 beats |
| `a` `s` `d` | the titan spits down that street; it lands two beats later |
| anything else | a rest |

A swarm stage is done when its chart is played and no alien is left. A
stage with `fly` lifts the robot on its jets and slides the city toward it
(`fly_speed`); buildings that pass the robot come round again at the crest,
standing. A stage with `spot_hp` is a titan: its chart loops until its
three hot spots are gone, then it sinks in flames for 1.5 seconds. The last
stage done is the win. Each stage shows its `title` as a banner; `heal`
gives back hearts.

The run: the hill swarm, a climb, the titan, the streets swarm (one heart
back), a climb, the crest swarm (clusters: two aliens down one street in a
row), a climb, and the hive queen (pink, eight health a hot spot, aliens and
spit between; one heart back). The bot, which steers perfectly, wins in 149
beats, 74 seconds; a person takes longer, since only hits move things on.

## The titan

A great bug standing behind the crest, swaying, drawn from ovals and lines
in `draw_titan`. As it arrives, every building on the far part of the hill
gets a moment to collapse at, so it crunches through the skyline. Its three
hot spots sit over the three streets; an open one glows orange and can be
hit, a closed one is dark. Spit is telegraphed by a flashing red bar where
it will land and a glob travelling down the street; it lands on the beat
and hurts the robot if it is still in that street.

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

- `test_boot`: the real cart from frame one, input and sound stubbed. A bot
  that steers to the most urgent target and away from spit wins the whole
  run (`boot_play`, `boot_climb`, `boot_titan`, `boot_queen`, `boot_won`)
  and presses X then O once each; then a run with no input loses; then a
  restart. It prints each stage's start beat and hp.
- `test_rhythm`: each gun's shots a bar; a hit on the beat and its
  knockback; a late arrival inside and outside `good_window`; nothing fired
  and the glow on an empty beat; minigun, pierce and splash damage; a leak;
  the chart; open and closed hot spots; spit in and out of its street; when
  a swarm and a titan stage are done; the titan and rising aliens read off
  the screen.

## Still to do, or not checked

- During titan and queen stages, the road should take a third of the screen
  rather than two thirds, so more of the titan shows against the sky.
- The art pass, which the user asked to leave to the end: the titan as a
  kaiju lizard-dragon of our own, the small enemies Tyranid-like, sprites
  for each distance, the same readable colours.
- The music has not been heard, and whether `stat(50)` keeps the clock on
  the drums on the user's machine is untested (the tests stub music).
- Every number (alien health, window, cadences, charts) is tuned only
  against the bot.
