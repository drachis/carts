# Wyrmdeep

Wyrmfire turned on its side: a side-scrolling shoot-'em-up at Rampage scale.
A dragon flies left to right through the shire, the town, the castle and
Camelot, burning and smashing what stands, eating what runs, and devouring
the mounted legend at the end of each. One PICO-8 cart, 8192 tokens.

It began as a metroidvania (caves, jumping, nests, sealed doors). Playtests
said the fun was in flying, crowds and destruction, so that structure is gone;
git history has it.

## Rules of the build

Wyrmfire's rules carry over (see `../wyrmfire/DESIGN.md`): data is strings
parsed at boot; behaviour is named by data (`unit_ai[name]`); objects inherit
from their data rows; named constants are globals in `_ENV`; readable names;
no comments in the Lua (notes go in `CODE_NOTES.md`, and `run_tests.py` fails
on a comment); PICO-8 is the only token counter.

New here:

1. **Stages are scripts.** `stages.py` lays each stage out as a list of
   (column, stamp): huts, barns, towers, walls, crowds. `gen_cart.py` turns
   them into the map and writes everything that is placed rather than drawn
   (units, spawn points, relics) to `level.lua` as one data string.
2. **Stages must pass their check.** `level.check` floods each stage from its
   start and fails the build if anything placed cannot be reached, or a stage
   does not end with exactly its legend. The first stage must be passable
   without the ram.

## Memory map

| Where | Holds |
|---|---|
| Map, 128x64 | Four stages of 16 rows, one under the other. Rows 32..63 share memory with sprites 128..255, so sprites stop at 127 and `gen_cart.py` writes those rows into the bottom of `__gfx__` |
| Sprite flags | bit 0 solid, 1 flammable, 2 brittle (any charge breaks it), 4 stone (only the ram does) |
| Sprite sheet | What is left of a tile that burns or breaks is 16 ids later |
| Sfx memory | The hurt sound's volume is rewritten per blow |
| `cartdata` slot 0 | Best time, in seconds |

The map is the only world state; `reload()` restores it when the dragon dies
or a new game starts.

## The game

- **Controls:** arrows fly, O breathes fire (the aim locks while held), X
  charges, O+X spends a full fury meter.
- **Movement:** free flight with a slow sink. On the ground the dragon runs
  faster on its legs, kicks up dust and cannot aim downward.
- **The screen** follows the dragon rightward and never goes back. Linger and
  it creeps on by itself, and being pinned against its left edge hurts.
- **Scale:** people and livestock are five pixels tall; the whelp is already
  twice their length and every meal and age makes it bigger.
- **Destruction:** wood and thatch burn (fire spreads tile to tile) and fall
  to a charge; stone and brick need the ram. Everything broken pays gold.
- **Spawn points** (hovels, barracks, roosts) pour out defenders until
  destroyed, up to a crowd limit that rises with age.
- **Eating:** a charge or the jaws send meat to the belly gauge; it heals,
  and each full belly grows the dragon (`growth`).
- **Legends** hold the last screen of each stage: Kay, Gawain and Arthur on
  warhorses, Merlin a small figure in a large glow. Each has bubbles (one to
  four) that turn fire aside: charge to pop them, and the last one popped
  staggers the legend so it burns. They wind up visibly, lunge,
  rage at half health, and from Gawain
  on call for help. Devouring one gives an age: the ram, a standing guard,
  seeking fire.
- **Gold** is the score: it rains at the end of a stage and is heaped in the
  lair where the next one begins.
- **Death** restarts the stage with its map restored; gold, growth and powers
  are kept.

## Tests

    py run_tests.py      # must exit 0
    py count_tokens.py

`run_tests.py` runs `gen_cart.py` (the stage check, `world.png`,
`sheet.png`), then five carts, because the game leaves no room for one big
harness: `test_data` (headless) checks every name the data uses;
`test_powers` tries one ability at a time and prints what happened (a charge
through a wall from nose-to-wall, burning a staggered legend, flying until
spent); `test_bosses` puts each legend alone through its whole fight (bar,
bubbles, wind-up, staying on screen, stagger, burning, bubbles returning,
what its fall gives); `test_play` has a bot play the shire with no cheats and reports
times and health; `test_soak` moves the dragon to everything placed in every
stage at every age. A cart that is too large fails silently in a window:
check `py count_tokens.py tests/test_play.p8` if one prints nothing.

They run in a window because headless PICO-8 died on one once with the
access violation described in `../wyrmfire/DESIGN.md`; the cause is unknown.

## Not built yet, or not checked

- Boss fight lengths are set by guesswork (health 140, 280, 420, 600); nobody
  has timed them.
- Sound and music are Wyrmfire's, unchanged.
- No saving between sessions.
