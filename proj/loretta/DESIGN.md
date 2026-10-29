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

## Memory map

| Where | Holds |
|---|---|
| Map rows 0..15 | the level, 128 tiles wide at most |
| Sprite flags | 0 solid, 1 semisolid (stand on its top row only), 2 water |
| Sprites | written by gen_cart.py; its SPRITES dict names each |
| `cartdata` | 0: the high score (in tens) |

## The game

- Title: the level's sunset backdrop, the LORETTA logo, a menu (START,
  HIGH SCORE) and Loretta's player card with her four stats. O starts.
- Controls: left and right run; O jumps (hold for higher; hold while
  falling to paddle); X barks; down sits (down+O drops through a branch).
- One level for now: from the "Los Feliz" sign to the observatory.
- HUD: three hearts, the paw coin count, and the score in seven digits.
- Loses: every heart gone, she lies down for a nap: game over, back to the
  title. Wins: at the observatory, a howl, the score counted, the title.

## Tests

    py run_tests.py --no-comments
    py count_tokens.py loretta.p8

- test_boot: the real cart from the title, through a start, play, a win and
  a game over, each dumped as a picture.
- test_moves: each verb alone in a cleared arena, with its measurement
  printed.
- test_level: a bot that cannot be hurt runs the level from the start and
  must reach the observatory.

## Not built yet, or not checked

- Nobody has played it.
- Upgrading stats (golden bones as the currency, chosen after a level).
- More levels (Griffith Park trails, the observatory's lawn at night).
- Acorn-throwing squirrels on branches.
