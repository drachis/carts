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

1. Tuning is text parsed at boot (`data.lua`).
2. Art, sound and music are drawn as text in `gen_cart.py`, which rewrites
   every cart's `__gfx__`, `__gff__`, `__sfx__` and `__music__`. Look at
   `sheet.png`.
3. Mushrooms are kinds 1 to 16: four families of four forms, kind
   `family*4+form+1`, sprite `95+kind`, with the leaning dance step in the
   sprite below. No form is the good one; the recipe names one each run.
4. PICO-8 is the only token counter (`py count_tokens.py witchcap.p8`).
5. The game runs at 60fps (`_update60`). Counters that only count down are
   clamped with `max()`.
6. Colours are kept apart: the hut's legs are pink, the cauldron black,
   the witch lavender, and no mushroom shares them.

## Memory map

| Where | Holds |
|---|---|
| Map rows 0..15 | The forest, written by `make_forest` at the start of a run |
| Map rows 16..18 | The hut's thigh (column 0) and shank (column 1), for `tline` |
| Sprites 16..20 | Ground tiles, the branch, two bat frames |
| Sprites 32..46 | The witch's seven frames, and the cauldron |
| Sprites 96..127 | The 16 mushrooms and their leaning steps |
| Sprites 128 on | The hut: side, front, foot, thigh, shank. The map's lower half shares this memory and is not used |
| Sprite flags | 0: solid ground. 1: a branch, stood on but jumped up through |
| `cartdata` slot 0 | The fastest brew, in frames; 0 when there is none |

## Files

| File | Owns |
|---|---|
| `data.lua` | Tuning numbers |
| `forest.lua` | `make_forest`, the mushroom list, the backdrop (stars, moon, trees, bats), drawing the level |
| `witch.lua` | The witch: running, jumping, landing, her frames |
| `hut.lua` | Baba Yaga's hut: following, gait, balance, turning, drawing |
| `potion.lua` | The recipe, picking, poison, delivering to the cauldron |
| `main.lua` | Modes, the loop, title, HUD and endings, the saved best |

## The game

- **Controls:** left and right run, O jumps (hold for height), X picks the
  mushroom she is standing at.
- **The forest** is 128 tiles wide, eight screens. It is cut into cells
  five columns wide; the ground changes height only between cells, by two
  tiles at most, and sits low on the screen (rows 11 to 14). Half the
  cells have a branch three tiles above their ground. Every cell outside
  the clearing and the two ends has one mushroom, on the ground or on its
  branch: 21 in all.
- **The clearing** is the middle three cells, flat and bare, with the
  cauldron at its centre. She starts there.
- **The mushrooms** are redcaps, bluecaps, goldcups and moonpuffs, each in
  four forms a pixel or two apart (a spot moved, a ring on the stem, a
  dimple more). They dance between two sprites.
- **The recipe** is five mushrooms: one particular form from each of
  three families, and two more of those. Which forms are wanted changes
  every run, so the recipe along the top has to be read. A slot is boxed
  yellow once that mushroom is in her basket, green once it is in the pot.
- **What grows:** everything the recipe wants, one spare of each kind it
  wants, and for the rest (13 of the 21) other forms of the same families.
- **Picking** a mushroom the recipe still wants puts it in the basket.
  Picking a wanted kind she has enough of does nothing. Picking anything
  else poisons her for three seconds (half speed, a green sky, the view
  swaying from side to side) and spoils one mushroom from the basket.
- **The cauldron** takes the basket whenever she stands at it. What is in
  the pot cannot be spoiled. The potion is brewed when all five are in.
- **Time:** 60 seconds. **The moon is the clock:** it wanes like the
  moon, lit from the left, with the rest of the disc in shadow. The
  seconds are also a number, top right. Brewed in time shows the time
  taken against the saved best; out of time, "the pot went cold".
- **Baba Yaga's hut** is the big picture of the game: a giant in the
  backdrop, taller than the screen, that walks after the witch on chicken
  legs. It is slower than she is, so she leaves it behind and it catches
  up while she picks. It touches nothing.
  - Its feet lift once a stride each, half a stride apart, and land 32
    pixels beyond one another. Its body stays over its feet, shifting
    onto the planted foot as the other swings. Stopped, it brings its
    feet back under itself.
  - It turns to face the way it walks: side on, then its front with the
    door and skull, then the other side.
  - Its legs are a feathered thigh and a scaly shank, sprites turned to
    lie along their bones with `tline`, meeting at a knee worked out from
    the hip and the ankle.
- **The backdrop:** stars, black swamp trees hung with moss sliding at
  half the camera's speed, three bats crossing.
- **The witch** has seven frames: standing, a four-step walk, rising and
  falling, her hat's point and hair flapping.
- **Music:** a looping tune in A minor on three channels (melody, bass,
  and a wavering voice on the repeat); sounds use the fourth.

## Tests

    py run_tests.py
    py count_tokens.py witchcap.p8

Each cart opens a PICO-8 window; the three take about a minute.

- `test_boot`: the real cart from the title, through a press, six seconds
  of a bot running, jumping and pressing pick (poisoned for part of it),
  then both endings and a restart, all drawn. It does not play the game.
- `test_forest`: generates 100 forests and walks each from the cauldron
  with a model of her movement (the next column, anything up to three
  tiles higher). Fails if a mushroom is out of reach or in the clearing,
  if a wanted kind does not grow exactly once more than it is wanted, or
  if something grows from a family the recipe does not use. Dumps four
  screens of one forest, with the moon at four ages.
- `test_witch`: the real witch and hut on flat ground, one case each.
  She climbs a three-tile ledge and cannot climb a four-tile one, which
  is what the model in `test_forest` assumes; jump height, short hop, run
  speed, poisoned speed; the poison sway never shows under the ground;
  the hut falls behind, steps in turn, stays over its feet, turns, shows
  its front mid-turn, catches up and stands square, at 60 frames a
  second; and the recipe's rules for picking, spoiling, delivering and
  running out of time.

## Not built yet, or not checked

- Nobody has played the build with the 16 mushrooms. Whether five
  mushrooms in 60 seconds among 13 lookalikes is a fair challenge, or
  the one-pixel differences are readable at all at a run, is unknown.
- The music has never been heard by its author: it loads and the cart
  runs, and that is all that is checked.
- The bats have not been seen in a screenshot.
- Levelling up, the broom and other mobility, levels after the first, a
  score board.
- A run can become unwinnable: only one spare of each wanted kind grows,
  and each spoiling costs one. The clock ends it; nothing says so.
- The green sky when poisoned is a screen palette change, which the test
  screenshots cannot show.
- With the hut on screen a frame costs about half of what `stat(1)`
  calls 1.0, and `stat(7)` reports 60. The trees and the hut's legs are
  the expensive parts.
