# Witchcap

"Witches looking for mushrooms in the forest to make potions." A side
scroller and a scavenger hunt: a witch has a recipe to fill and limited time
to fill it. There are "no enemies, but there are tricky ingredients which
can ruin the potion and may poison you". The cauldron is in the centre of
the level and she gathers from all around it. The forest is different on
each play, and she races her own earlier brews.

The feeling it is after: hurrying through a wood, reading mushrooms at a
glance, and being punished only by her own haste.

## Rules of the build

1. Tuning is text parsed at boot (`data.lua`).
2. Art and sound are drawn as text in `gen_cart.py`, which rewrites every
   cart's `__gfx__`, `__gff__` and `__sfx__`. Look at `sheet.png`.
3. A mushroom's kind is its sprite number, 1 to 6. Odd kinds are true
   ingredients; each even kind is the lookalike of the one before it.
4. PICO-8 is the only token counter (`py count_tokens.py witchcap.p8`).
5. The game runs at 60fps (`_update60`). Counters that only count down are
   clamped with `max()`.

## Memory map

| Where | Holds |
|---|---|
| Map, 128 by 16 | The forest, written by `make_forest` at the start of a run |
| Sprite flags | 0: solid ground. 1: a branch, stood on but jumped up through |
| `cartdata` slot 0 | The fastest brew, in frames; 0 when there is none |

## Files

| File | Owns |
|---|---|
| `data.lua` | Tuning numbers |
| `forest.lua` | `make_forest`, the mushroom list, drawing the level |
| `witch.lua` | The witch: running, jumping, landing |
| `potion.lua` | The recipe, picking, poison, delivering to the cauldron |
| `main.lua` | Modes, the loop, title, HUD and endings, the saved best |

## The game

- **Controls:** left and right run, O jumps (hold for height), X picks the
  mushroom she is standing at.
- **The forest** is 128 tiles wide, eight screens. It is cut into cells
  five columns wide; the ground changes height only between cells, by two
  tiles at most. Half the cells have a branch three tiles above their
  ground. Every cell outside the clearing and the two ends has one
  mushroom, on the ground or on its branch: 21 in all.
- **The clearing** is the middle three cells, flat and bare, with the
  cauldron at its centre. She starts there.
- **The mushrooms** are four of each true kind and three of each
  lookalike. The pairs differ in one detail: the redcap has white spots,
  the bluecap a pale stem, the goldcup is a funnel where its lookalike is
  a dome.
- **The recipe** is four mushrooms: one of each true kind and one more.
  It is shown along the top; a slot is boxed yellow once that mushroom is
  in her basket and green once it is in the pot.
- **Picking** a mushroom the recipe still wants puts it in the basket.
  Picking a true kind she has enough of does nothing. Picking a lookalike
  poisons her for three seconds (half speed, a green sky, swaying ground)
  and spoils one mushroom from the basket, which must be found again.
- **The cauldron** takes the basket whenever she stands at it. What is in
  the pot cannot be spoiled. The potion is brewed when all four are in.
- **The look:** night, and black swamp trees hung with moss, drawn in
  code and sliding at half the camera's speed. The mushrooms dance. The
  witch is two sprites square, with a tall hat whose point trails behind.
- **Baba Yaga's hut** is the big picture of the game: a giant in the
  backdrop, taller than the screen, that walks after the witch on chicken
  legs and turns to face the way it goes. It is slower than she is, so
  she leaves it behind and it catches up while she picks. It touches
  nothing. Its body, feet and leg feathers are sprites at double size;
  the legs between are lines (`hut.lua`).
- **The moon is the clock**, waning from full to nothing over the level.
  The seconds are also shown as a number, top right.
- **Poison** sways the view from side to side.
- **Time:** 60 seconds. Brewed in time shows the time taken against the
  saved best; out of time, "the pot went cold".

## Tests

    py run_tests.py
    py count_tokens.py witchcap.p8

- `test_boot`: the real cart from the title, through a press, six seconds
  of a bot running, jumping and pressing pick (poisoned for part of it),
  then both endings and a restart, all drawn. It does not play the game.
- `test_forest`: generates 100 forests and walks each from the cauldron
  with a model of her movement (the next column, anything up to three
  tiles higher). Fails if a mushroom is out of reach or in the clearing,
  or the counts are wrong. Dumps four screens of one forest to look at.
- `test_witch`: the real witch on flat ground. She climbs a three-tile
  ledge and cannot climb a four-tile one, which is what the model in
  `test_forest` assumes; jump height, short hop, run speed, poisoned
  speed; and the recipe's rules for picking, spoiling, delivering and
  running out of time.

## Not built yet, or not checked

- Nobody has played this build. Whether 60 seconds, 21 mushrooms and the
  jump feel right is unknown.
- Levelling up, the broom and other mobility, further recipes and levels,
  a score board, music.
- A run can become unwinnable: the recipe wants up to two of a kind, four
  grow, and each spoiling costs one. The clock ends it; nothing says so.
- The green sky when poisoned is a screen palette change, which the test
  screenshots cannot show.
