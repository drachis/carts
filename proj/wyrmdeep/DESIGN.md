# Wyrmdeep

Dynasty Warriors meets Rampage, as played by Smaug at Lake Town. A dragon
flies side-on through the shire, the town, the castle and Camelot, tearing
down what stands, eating what runs, and devouring the mounted legend who
rides out when enough has fallen. One PICO-8 cart, 8192 tokens.

It began as a metroidvania, then became a screen-ratcheting shmup. Playtests
and a pacing map against Wyrmfire (below) said the fun is in crowds,
destruction that spirals, and room to stay and fight; git history has the
earlier shapes.

## Rules of the build

Wyrmfire's rules carry over (see `../wyrmfire/DESIGN.md`): data is strings
parsed at boot; behaviour is named by data (`unit_ai[name]`); objects inherit
from their data rows; named constants are globals in `_ENV`; readable names;
no comments in the Lua (notes go in `CODE_NOTES.md`, and `run_tests.py` fails
on a comment); PICO-8 is the only token counter.

New here:

1. **The world is built as it is played.** The map holds only each stage's
   ground and lair. Towns, castles and keeps are stamped into it block by
   block by `build_block`, from `stamps` and `blocks` in `data.lua`. A new
   building is a line of data.
2. **Measure pacing against Wyrmfire.** `py feel_map.py` plays thirty seconds
   of each with a scripted dragon and prints enemies on screen, kills, fires,
   shots and health, second by second. It measures how much is happening and
   whether it rises, not fun.

## Memory map

| Where | Holds |
|---|---|
| Map, 128x64 | Four stages of 16 rows, one under the other. Rows 32..63 share memory with sprites 128..255, so sprites stop at 127 and `gen_cart.py` writes those rows into the bottom of `__gfx__` |
| Sprite flags | bit 0 solid, 1 flammable, 2 brittle (the dragon breaks it by moving into it), 4 stone (only a charge breaks it) |
| Sprite sheet | What is left of a tile that burns or breaks is 16 ids later |
| Sfx memory | The hurt sound's volume is rewritten per blow |
| `cartdata` slot 0 | Best time, in seconds |

The map is the only world state; `reload()` restores it when the dragon dies
or a new game starts.

## The game

- **Controls:** arrows fly, O breathes fire (the aim locks while held), X
  charges, O+X spends a full fury meter.
- **Movement:** free flight with a slow sink, anywhere in the stage, back as
  well as forward. On the ground the dragon runs faster on its legs.
- **A stage is three blocks** with open country between: a town, then a
  castle, then a keep, sterner by stage (`blocks`). A holy barrier stands at
  the end of each block and falls when `raze_goal` of the block's buildings
  have. When the last block has fallen that far, the stage's legend rides.
- **Buildings crumble.** A tile that loses what it stood on falls, and so
  does whatever leaned on it: knock the foot out of a tower and it comes
  down floor by floor; burn a wall and its roof drops.
- **Nothing wooden stops the dragon:** it breaks timber and thatch by flying
  into them. Stone and brick need the charge.
- **The kingdom responds.** The director sends bands from the screen's
  edges, bigger and faster as the block burns (`heat`) and as stages pass,
  with archers and crossbowmen among them (`hordes`). It also builds the next
  block, spaced wider if the dragon is hurt.
- **Scale:** people are five pixels tall; anything with 1 health dies to any
  hit. The dragon grows with every full belly and every age.
- **Legends:** Kay, Gawain and Arthur on warhorses, Merlin a small figure in
  a large glow. Each has bubbles that turn fire aside: charge to pop them,
  and the last one popped staggers the legend so it burns. Devouring one
  gives an age: a longer charge, a standing guard, seeking fire.
- **Gold** is the score; it rains when a legend falls and is heaped in the
  lair where the next stage begins.
- **Death** restarts the stage, rebuilt afresh; gold, growth and powers are
  kept.

## Tests

    py run_tests.py      # must exit 0
    py count_tokens.py
    py feel_map.py       # the pacing map; not a pass or fail

`run_tests.py` runs `gen_cart.py`, then five carts. The game leaves a cart
only a few hundred tokens, so all but `test_boot` include `tests/lean_main.lua`, a
generated copy of `main.lua` with the title, endings, HUD and music emptied.

- `test_data` (headless): every name the data uses exists; every stamp is
  well formed.
- `test_boot`: the real cart, nothing emptied, from the title screen through
  ten seconds of play and both endings. The only cart that draws the title,
  the HUD and the endings; a missing value there once crashed the game on
  its first frame while every other test passed.
- `test_powers`: one thing at a time, with what happened printed: flying
  through timber, charging through stone nose-first, a tower collapsing,
  burning a staggered legend.
- `test_bosses`: each legend alone through its whole fight.
- `test_soak`: every stage, all three blocks built, at every age.

All but the first run in a window, because headless PICO-8 died on one once
with the access violation described in `../wyrmfire/DESIGN.md`. A cart that
is too large fails silently in a window: check it with `count_tokens.py`.

## Not built yet, or not checked

- Nobody has played this shape yet. The pacing map says its crowd now matches
  Wyrmfire's opening; it says nothing about whether it is fun.
- Fire on the pacing map is still a tenth of Wyrmfire's.
- Boss lengths are untimed.
- Sound and music are Wyrmfire's, unchanged. No saving between sessions.
