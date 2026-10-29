# Loretta: Corgi Quest

Loretta, a corgi, trots and hops through Los Feliz at sunset on her way up
to the Griffith Observatory: grassy ledges, palm trees against a pink and
orange sky, paw coins to snatch, bones to munch, squirrels to bark at, and
neighbours who will pet a good girl who sits. The game is guessed from a
title-screen picture the user gave (three hearts, a seven-digit score, a
"Los Feliz" sign, a player card with SPEED, JUMP, BARK and CHARM bars).
The feeling is **charming**: everything she does should look like a happy
little dog doing it. Short legs, big ears, a wagging nub of a tail.

## What each borrowed mechanic is for

| Mechanic | From | Why it fits |
|---|---|---|
| Run speed builds up, skids on a turn, coyote time, a buffered jump, hold for a higher jump, a flush collision box | dustroom (the user's movement room) | already tuned and tested; the base of any good platformer feel |
| Camera eases after her and leads where she is running | dustroom | the same, and it shows what is coming |
| Hold jump while falling: her short legs paddle and she hangs in the air for a moment, once a jump | Yoshi's Island's flutter jump | the JUMP stat's own verb, and a corgi paddling at the air is the most charming thing in the game |
| Land on a squirrel to bonk it; more bonks without touching the ground score more | Super Mario Bros. stomp and chain | the core enemy rule everyone already knows |
| Hurt: lose a heart, bounce back, blink and cannot be hurt for a moment | Super Mario Bros. / most platformers | forgiving; three hearts is three mistakes |
| Paw coins in lines and arcs, showing the way to go | Super Mario Bros. coins | they draw the path and reward the jump |
| Bones restore a heart | Zelda hearts, Castlevania wall meat | the dog version of a health pickup |
| Bark (X): a WOOF rolls forward and spooks every squirrel it reaches, which flees | Kirby's / Mega Man's short ranged shot | the BARK stat's verb; a way to clear a squirrel without jumping on it |
| Sit (down): next to a neighbour she gets petted, and her hearts fill | Animal Crossing / Untitled Goose's people who react to you | the CHARM stat's verb; the softest moment in the level |
| Branches and awnings she can jump up through and land on; down+jump drops through | Super Mario Bros. 3 semisolids | more ways up and down a level without new controls |
| Fire hydrants are checkpoints: sniff one and it sparkles; falling in the water costs a heart and sends her back to the last one | Sonic's starposts | a dog's checkpoint |
| Reach the observatory: she sits and howls at the stars, and the score is counted | Super Mario Bros. flagpole | a happy ending that is its own little show |
| Stats SPEED, JUMP, BARK, CHARM on a player card | the title picture | each stat sets one verb's numbers, so a later upgrade is a line of data |

## Rules of the build

1. Every tuning value is a named global in data.lua's record; the four
   stats choose values from it (`run_max` from SPEED, and so on).
2. Levels are text in gen_cart.py, stamped into the map, with letters for
   coins, squirrels, hydrants and the rest; the game turns those tiles into
   things at the level's start. A level is checked completable by a bot.
3. Art, sound and music are data in gen_cart.py; it also writes sheet.png
   and level.png to look at.
4. Nothing in an update reads `rnd` or the clock, so tests replay exactly.
   Scenery that twinkles uses the frame count in the draw.
5. No comments in the Lua; notes in notes/<module>.md (CODE_NOTES.md).
6. PICO-8 is the only token counter (`py count_tokens.py loretta.p8`).
7. Colours kept for what the player must pick out: Loretta orange 9 and
   white 7; coins yellow 10; squirrels brown 4; hearts red 8; water blue 12.
   The backdrop uses dark blue 1, dark purple 2, pink 14, orange 9 only
   as large sky bands far behind, and black 0 for silhouettes.

## Scale and look

- The view is close, as in the picture: Loretta is 32x16 (a fifth of the
  screen's width), squirrels, coins and hydrants 16x16. Tiles stay 8x8, so
  the ground and set pieces are finer than she is.
- She trots: 1.3 pixels a frame, a screen in about 98 frames. The user:
  "it's about charm, not really about platforming excellence".
- Her body moves like a corgi, built from parts after witchcap's hut (the
  user: the body movement "will be really important"): four drawn legs
  trotting in diagonal pairs with paws planted on the ground, a rump that
  rocks against her chest, a bobbing body and a head that bobs after it,
  ears back at speed, a flapping tongue, blinks; front paws reach in a
  jump. Sitting and napping are whole pictures.
- Neighbours are seen from a corgi's height: shoes and trouser legs that go
  up off the screen, and a hand that comes down to pat her.
- The palette swaps slots 1, 2, 5 and 15 for navy, plum, mauve and salmon.
  Hills are layers of haze that clear (salmon, pink, lavender towards plum
  and navy) as she nears the observatory, while dusk falls: the sky slides
  down, stars come out, the sun sets, the far observatory grows and lights
  up. Every dither is screen-locked.

## Memory map

| Where | Holds |
|---|---|
| Map rows 0..15 | level columns 0..127 (sections 1-4) |
| Map rows 16..31 | level columns 128..255 (sections 5-8) |
| Sprite flags | 0 solid, 1 semisolid (stand on its top row only), 2 water, 3 slope rising right, 4 slope rising left |
| Sprites 0..255 | written by gen_cart.py; its SPRITES dict names each (the lower half is free: the map uses only rows 0..31) |
| `cartdata` | 0: the high score (in tens) |

## The game

- Title: the level's first screen, the LORETTA logo, a menu (START,
  HIGH SCORE) and Loretta's player card with her four stats. O starts.
- Controls: left and right run; O jumps (hold for higher; hold while
  falling to paddle); X barks; down sits (down+O drops through a branch).
- One level, eight sections, each a Los Feliz or Griffith Park place:
  1. Vermont/Hillhurst: a movie palace (STAR blade sign, a marquee reading
     "now: good girl" that she can stand on), a bookshop under a striped
     awning, street lamps, a sidewalk.
  2. The lawns: Spanish bungalows, a jacaranda dropping petals on a hill.
  3. Fern Dell: plank footbridges with rails over the stream, ferns, a
     sycamore, its wooden sign.
  4. A yard: a Craftsman bungalow whose porch roof she stands on, a picket
     fence, a mailbox, a neighbour.
  5. The trailhead: the griffith park sign, chaparral up the slopes.
  6. The ravine and the old zoo's barred stone enclosures.
  7. A switchback: a split-rail fence, a hiker resting by a bench.
  8. The observatory lawn: the Astronomers Monument, lamps, a coin-op
     viewer, the observatory.
  The Hollywood sign stands on its own far peak through the climb.
  Squirrels, coins, bones, three hydrants.
- Set pieces are data: a line of drawing steps each in data.lua's shapes,
  placed by a letter in the level text (gen_cart.py LETTER_TILES).
- HUD: three hearts, the paw coin count, and the score in seven digits.
- Loses: every heart gone, she lies down for a nap: game over, back to the
  title. Wins: at the observatory she sits and howls, the hearts left are
  counted into the score, O goes back to the title.

## Tests

    py run_tests.py --no-comments
    py count_tokens.py loretta.p8

- test_boot: the real cart from the title, through a start, play, a bark, a
  win and a game over, each dumped as a picture.
- test_moves: each verb alone on the real level with its measurement
  printed: run speed, tap, held and paddled jumps, the lawn's slopes without
  leaving the ground, up through and down through an awning, stomp, being
  hurt, bark reach, coin, bone, petting, water and respawn, the win, and
  the backdrop's dither holding still as the camera moves, her paws
  planted while she trots in diagonal pairs (a slip of 0.1px a frame
  fails), and a film strip of her trot (gait_1..4).
- test_scenes: two pictures of every section (scene_1..16), to look at the
  set pieces; it checks only that each draws.
- test_level: a bot that cannot be hurt runs right, jumping at walls and
  gaps, and must reach the observatory. It proves the level can be
  crossed, not that it is fair or fun.

## Not built yet, or not checked

- Nobody has played it. No one has heard the sounds or music.
- The level is short: a bot runs it in 24 seconds. Its shapes have not
  been tuned for fun, only checked crossable.
- In the high sections (6-8) the bottom half of the screen is solid dirt.
  A ridge with the city's lights below it would show where she has come
  from.
- Upgrading stats (golden bones as the currency, chosen after a level).
- Acorn-throwing squirrels on branches.
