# Crestbeat

You are a giant red robot at the foot of a hill in a city. Angry green
hexagon aliens pour over the crest down three lanes of road. It is a rhythm
game: aim at an alien, shoot it on two beats, switch lane, shoot the next on
two beats, "like a frenetic english country dance". An alien that reaches the
bottom of the hill hurts you; a few of those and you fall.

The run is meant to be about 90 seconds, paced like the arcade Godzilla VR
game: a swarm for 10 to 15 seconds, fly up the road to the crest, a titan
bug crunching through the skyscrapers with hot spots to shoot, another
swarm, and so on to a boss. A pickup swaps the gun (Unreal Tournament and
Doom guns). The user's sketch is layout, not art; an art direction pass
comes later.

What it takes from where:

- **hivefall:** the robot (its mech sprite, recoloured red), sparks, rings,
  popups and shake.
- **The arcade Godzilla VR game:** the pacing of small clusters, a big
  enemy, clusters again, a boss at about 90 seconds.
- **Rhythm games:** shots are judged against the beat (perfect, good,
  miss), and a NecroDancer-style beat bar at the bottom shows the beats
  closing on the centre.

## Rules of the build

1. Tuning and content are data strings in `data.lua`: a wave is a chart
   string, a judgement is a row.
2. Art, sound and music are text in `gen_cart.py`, which rewrites every
   cart's `__gfx__` and on. Look at `sheet.png`.
3. PICO-8 is the only token counter (`py count_tokens.py crestbeat.p8`).
4. 60fps (`_update60`); test carts wrap `_update60`.
5. No comments in the Lua; notes in `notes/<module>.md` (`CODE_NOTES.md`).
6. The game is one cart. Test carts may be split.

## The beat

`clock` is the song position in beats. It advances `1/frames_per_beat` a
frame. The music is 120 BPM at sfx speed 15, a note a quarter beat, 32 notes
(8 beats) a pattern. While music plays, each time channel 0's note number
(`stat(50)`) changes, `clock` is pulled halfway toward where that note says
it should be, so the game cannot drift from the drums. With music stubbed
(the tests) the clock runs on frames alone. `frames_per_beat` (29.88)
assumes a speed-1 note lasts 183 samples at 22050Hz; the manual does not
give a note's length, so this is an assumption the sync covers.

Every whole beat `on_beat` runs: it reads the wave's chart (one character a
beat: `1` `2` `3` a lane to send an alien down, `.` nothing) and pulses the
lane dashes and the beat bar.

## Shooting

Left/right moves between three lanes. O or X fires. A shot is judged by its
distance from the nearest beat: within `perfect_window` frames is perfect,
within `good_window` is good, and anything else, or a second shot on a beat
already shot, is a miss. Perfect and good hit the front alien in the
robot's lane for one point of health and knock it back up the hill
(perfect further); a miss does nothing and ends the combo. Every fourth
beat in a row raises the multiplier, to x4. `score` is kept in tens (a
perfect is 10, shown as 100) so a run cannot pass PICO-8's 32767.

## Aliens

An alien is sent on a beat, rises over the crest on that beat, and then
hops down the lane one hop a beat for `walk_beats` beats. `t` is its
depth: 0 at the crest, 1 at the bottom of the hill. A hit knocks it back by
moving its start later (`born`). At `t>=1` it is gone and the robot loses a
point of `hp`; at 0 the run is lost.

## Stages

The run is a list of stages (`stages` in `data.lua`), each with a chart
read one character a beat from the beat it starts on:

| Character | Meaning |
|---|---|
| `1` `2` `3` | send an alien down the left, middle, right lane |
| `q` `w` `e` | open the titan's hot spot over that lane for 2.5 beats |
| `a` `s` `d` | the titan spits down that lane; it lands two beats later |
| anything else | a rest |

A swarm stage is done when its chart is played and no alien is left. A
stage with `fly` lifts the robot on its jets and slides the city toward it
(`fly_speed`): the road's dashes and the buildings run past, and buildings
that pass the robot come round again at the crest, standing. A stage with
`spot_hp` is a titan: its chart loops until all three hot spots are gone,
then it sinks in flames for 1.5 seconds and the next stage starts. The
last stage done is the win. Each stage shows its `title` as a banner, and
a stage with `heal` gives back that many hearts when it starts.

The run now: the hill swarm, a climb, the titan, the streets swarm (one
heart back), a climb, the crest swarm (clusters: two aliens down one lane
in a row), a climb, and the hive queen (a pink titan with four hits a hot
spot, sending aliens and spit between hot spots; one heart back). The bot,
which never misses, wins in 154 beats, 77 seconds; a person who misses
takes longer, since only a hit moves things on.

## The titan

A great bug standing on the crest, swaying, drawn from ovals and lines in
`draw_titan` (art direction later). As it arrives, every building on the
far third of the hill gets a moment to collapse at, so it crunches through
the skyline. Its three hot spots sit over the three lanes. A shot (on the
beat, as ever) at an open hot spot in the robot's lane hurts it, if no
alien is in front; closed spots are dark and cannot be hurt. Spit is
telegraphed by a flashing red bar where it will land and a glob that
travels down the lane; it lands on the beat, and hurts the robot if it is
still in that lane.

## The picture

`project(lane,t)` is the whole perspective: lanes close up toward the
crest and the road falls away more steeply near the robot. Draw order: sky
and skyline, aliens still behind the crest, the ground, the road and its
dashes, the titan (clipped while it rises), the buildings far to near, aliens far to near, beams, the robot,
effects, HUD, beat bar.

## Modules

| File | Owns |
|---|---|
| `data.lua` | Parsers, constants, judgements, charts |
| `world.lua` | Projection, sky, road, buildings, effects |
| `aliens.lua` | Sending, hopping, hurting, drawing aliens |
| `titan.lua` | The titan, its hot spots, its spit |
| `robot.lua` | Lanes, shooting, judging, drawing the robot |
| `main.lua` | Modes, the beat clock, the wave, HUD, beat bar |

## Tests

    py run_tests.py --no-comments
    py count_tokens.py crestbeat.p8

- `test_boot`: the real cart from frame one, input and sound stubbed. A bot
  that stands in the most urgent alien's lane and fires on every beat wins
  the whole run (`boot_play`, `boot_climb`, `boot_titan`, `boot_queen`,
  `boot_won`), dodging spit and shooting open hot spots; then a run with no input
  loses it; then a restart. It prints each stage's start beat and hp. Screens are
  dumped (`boot_*.png`).
- `test_rhythm`: judging at the beat, a few frames off and far off; a
  second shot on the same beat; that perfect and good hurt the front alien
  and push it back and a miss does not; that a leaking alien costs a point
  of hp; open and closed hot spots; spit in and out of its lane; when a
  swarm and a titan stage are done.

## Not built yet, or not checked

- No gun pickups yet.
- The music has not been heard, and whether `stat(50)` keeps the clock on
  the drums on the user's machine is untested (the tests stub music).
- Whether the windows feel fair to a person; 4 and 8 frames are guesses.
