# Witchcap

"Witches looking for mushrooms in the forest to make potions." A side
scroller and a scavenger hunt: a witch has a recipe to fill and limited time
to fill it. There are "no enemies, but there are tricky ingredients which
can ruin the potion and may poison you". The cauldron is in the centre of
the level and she gathers from all around it. The forest is different on
each play, and she races her own earlier brews.

The feeling it is after: hurrying through a swamp wood at night, reading
mushrooms at a glance, and being punished only by her own haste, with Baba
Yaga's hut lumbering along behind for company.

## Rules of the build

1. Tuning is text parsed at boot (`data.lua`), including the three rows
   that define the nine levels.
2. Art, sound and music are drawn as text in `gen_cart.py`, which rewrites
   every cart's `__gfx__`, `__gff__`, `__sfx__` and `__music__`. Look at
   `sheet.png`.
3. Mushrooms are kinds 1 to 16: four families of four forms, kind
   `family*4+form+1`, sprite `95+kind`, with the leaning dance step in the
   sprite below. No form is the good one; the recipe names its own.
4. PICO-8 is the only token counter (`py count_tokens.py witchcap.p8`).
5. The game runs at 60fps (`_update60`). Counters that only count down are
   clamped with `max()`.
6. Colours are kept apart: the hut's legs are pink, the cauldron black,
   the witch lavender, and no mushroom shares them.
7. The forest is a cylinder. Places are plain numbers that are never
   wrapped; only reading and drawing the map wraps (`tile_at`), and
   `near(x)` gives the copy of a place nearest the witch.

## Memory map

| Where | Holds |
|---|---|
| Map rows 0..15 | The forest, written by `make_forest` at the start of a run |
| Sprites 16..20 | Ground tiles, the branch, two bat frames |
| Sprites 32..46 | The witch's seven frames, and the cauldron |
| Sprites 96..127 | The 16 mushrooms and their leaning steps |
| Sprites 128 on | The hut's side and front, the potion bottle, three foot poses. The map's lower half shares this memory and is not used |
| Sprite flags | 0: solid ground. 1: a branch, stood on but jumped up through |
| `cartdata` slot 1 | The highest level unlocked |
| `cartdata` slots 11..19 | The fastest brew of each level, in frames; 0 when there is none |

## Files

| File | Owns |
|---|---|
| `data.lua` | Tuning numbers and the level rows |
| `forest.lua` | `make_forest`, the mushroom list, the backdrop (stars, trees, far bats), the foreground (creepers, near bats), the moon, drawing the level |
| `witch.lua` | The witch: running, jumping, landing, the broom, the cackle, her frames |
| `hut.lua` | Baba Yaga's hut: following, gait, balance, turning, drawing |
| `potion.lua` | The recipe, picking, poison, regrowth, delivering to the cauldron |
| `effects.lua` | Sparks, the shake of the view, mushrooms flying to the pot |
| `main.lua` | Modes, the loop, levels, title, HUD, victory and failure screens |

## The game

- **Controls:** left and right run, O jumps (hold for height), X picks the
  mushroom she is standing at, up flies the broom, down cackles.
- **The forest** is 128 tiles round, eight screens, with no edges. It is
  cut into cells five columns wide; the ground changes height only
  between cells, by two tiles at most, and sits low on the screen. Half
  the cells have a branch three tiles above their ground. Every cell
  outside the clearing has one mushroom, on the ground or on its branch:
  22 in all.
- **The clearing** is three cells, flat and bare, with the cauldron at its
  centre. She starts there.
- **The mushrooms** are redcaps, bluecaps, goldcups and moonpuffs, each in
  four forms a pixel or two apart. They dance between two sprites.
- **Levels:** nine. The recipe wants 1, 2, 3, 4, then 5 different
  mushrooms. Imposters, which are other forms of the wanted mushrooms'
  families, number 0, 2, 4, 7, 10, 13, then 17. The rest of the 22 are
  of families the recipe does not use. The clocks are 20, 35, 45, 55,
  60, 60, 55, 50 and 45 seconds. Brewing the highest level unlocked
  unlocks the next, and X goes on to it. On the title and after a
  failure, left and right choose among the unlocked levels.
- **The recipe** never asks twice for a kind, takes at most two from a
  family, and never uses one family, picked afresh each run. It runs
  along the bottom of the screen; a slot is boxed yellow once that
  mushroom is in her basket or in the air, green once it is in the pot.
- **Picking** a mushroom the recipe still wants puts it in the basket, in
  a burst of gold. Picking a wanted kind she already has does nothing.
  Picking anything else poisons her for three seconds (half speed, a
  green sky, the view swaying, no broom), in a green cloud that jolts
  the view, and spoils one mushroom from the basket. A spoiled mushroom
  grows again where something was picked, away from her if it can.
- **The cauldron:** when she stands at it her basket empties, each
  mushroom flying from her to the pot in an arc. What has left the basket
  cannot be spoiled. The potion is brewed when the last one lands.
- **The broom** carries her a screen's width the way she faces, skimming
  the ground and clearing any step, then rests four seconds. A small
  broom by the clock shows how rested it is.
- **Victory:** the pot boils over in the potion's colour, bursts, and a
  bottle rises to the middle of the screen: one of eight potions, named
  and coloured by what went in, with the time taken and the level's best.
- **Failure:** "the pot went cold", how many were in the pot, the level
  picker, and X to try.
- **The clock** is the moon, top right and in front of everything, waning
  like the moon with the rest of its disc in shadow. The seconds are
  also a number, bottom right.
- **The way to the pot**, when it is off the screen, is a small cauldron
  in a green glow with an arrow.
- **Baba Yaga's hut** is the big picture of the game: a giant in the
  backdrop, taller than the screen, that walks after the witch on chicken
  legs. It is slower than she is, so she leaves it behind and it catches
  up while she picks. It touches nothing.
  - It is a box at three quarters: its long side, and at the end it walks
    towards, its front with the door and skull, narrowed by the angle. As
    it turns the front widens to face the camera and the other side
    opens out.
  - Its feet lift once a stride each, half a stride apart. Its body stays
    over its feet, shifting onto the planted foot as the other swings.
    Stopped, it brings its feet back under itself. Its toes curl as a
    foot lifts and clench in the air.
  - Its legs are drawn solid, as rows of circles: a thick brown thigh and
    a pink shank, meeting at a knee worked out from the hip and ankle.
- **The backdrop:** stars; mossy swamp trees, dead trees and toadstools
  the size of trees, sliding at half the camera's speed and repeating
  once a lap; small black bats flying through.
- **The foreground:** leaves and creepers along the top 18 pixels, at one
  and a half times the camera's speed, and two larger bats.
- **Music:** a looping tune in A minor on three channels; sounds use the
  fourth.

## Tests

    py run_tests.py
    py run_tests.py tests/pace.p8
    py count_tokens.py witchcap.p8

`run_tests.py` starts every `tests/test_*.p8` at once, each in a PICO-8
window of its own with a log of its own, and takes about 17 seconds. A
test cart runs its frame as a coroutine (`run_frame` in `tests/dump.lua`),
so a runtime error is printed to the log and fails the run at once with
PICO-8's message. A cart that never prints "started" has not loaded, and
fails after 20 seconds. The case runner in `tests/harness.lua` plays four
frames of the game for each frame PICO-8 shows.

- `test_boot`: the real cart from the title, through a press, six seconds
  of a bot running, jumping, picking, flying and cackling (poisoned for
  part of it), then the victory sequence, a restart and the failure
  screen, all drawn. It does not play the game.
- `test_forest`: generates 100 forests across the nine levels and walks
  each from the cauldron, round the join as well, with a model of her
  movement (the next column, anything up to three tiles higher). Fails
  if a mushroom is out of reach or in the clearing, or if the recipe's
  length, the one-of-each rule or the imposter count is not what the
  level says. Dumps four screens of one forest, with the moon at four
  ages.
- `test_witch`: the real witch on flat ground, one case each: ledges of
  three and four tiles, jumps, running, stopping dead, poison, the broom,
  the world going round, and the recipe's rules for picking, spoiling,
  regrowth, the flight to the pot, brewing, unlocking, the level picker
  and running out of time.
- `test_hut`: the hut on flat ground: falling behind, stepping in turn,
  staying over its feet, turning, showing its front, catching up and
  standing square, its walls meeting with no gap, and 60 frames a second
  with it on the screen.
- `pace.p8` is not a test. A bot that never picks wrongly plays every
  level, and the times it takes are printed. It takes over a minute, at
  sixteen frames of the game to each one PICO-8 shows.

## Not built yet, or not checked

- Nobody has played the build with levels, the broom, the cylinder or
  the victory sequence. Whether the one-pixel differences can be read at
  a run, and whether the clocks are fair, is unknown: the clocks come
  from a bot that never misreads.
- The music and sounds have never been heard by their author.
- A score board; levelling up into abilities (the broom is simply given).
- Levels 7 to 9 differ only in their clocks.
- The green sky when poisoned is a screen palette change, which the test
  screenshots cannot show.
- With the hut on screen a frame costs about 0.3 of what `stat(1)` calls
  1.0, and `stat(7)` reports 60.
