# Wyrmdeep

A side-scrolling metroidvania built from Wyrmfire: a whelp hatches in a lair
under Camelot, devours the knights of the Round Table for their strength, and
climbs to the throne. Same experiment as Wyrmfire: one PICO-8 cart, 8192
tokens.

## Rules of the build

Wyrmfire's rules carry over unchanged (see `../wyrmfire/DESIGN.md`): data is
strings parsed at boot; behaviour is named by data (`unit_ai[name]`); objects
inherit from their data rows; named constants are globals in `_ENV`; readable
names; no comments in the Lua (notes go in `CODE_NOTES.md`, and
`run_tests.py` fails on a comment); PICO-8 is the only token counter.

Two rules are new:

1. **The world is drawn as text.** `level.py` holds 32 rooms of 16x16
   characters. `gen_cart.py` turns them into the map, picks tile variants
   (tops, buried rock) for free, and writes everything that is placed rather
   than drawn (the dragon, units, relics) to `level.lua` as one data string.
2. **The world must pass its check.** `level.check` walks the map with a
   deliberately weak dragon at each age and fails the build unless Kay,
   Gawain, Merlin and Arthur can each be reached at their age and not before.

## Memory map

| Where | Holds |
|---|---|
| Map, all 128x64 | The world. Rows 32..63 share memory with sprites 128..255, so sprites stop at 127 and `gen_cart.py` writes those rows into the bottom of `__gfx__` |
| Sprite flags | bit 0 solid, 1 flammable, 2 brittle (a charge breaks it), 3 hazard |
| Sprite sheet | Row 0 is what can be destroyed; what is left of a tile is 16 ids later |
| Sfx memory | The hurt sound's volume is rewritten per blow |
| `cartdata` slot 0 | Best time, in seconds |

The map is the only world state: burning swaps a tile for the fire tile and
then its remains, a charge swaps brittle tiles for theirs, a fallen legend's
seal tiles are cleared. `reload()` restores it for a new game.

## The game

- **Controls:** arrows move, up jumps (hold to glide), O breathes fire (the
  aim locks while held), X charges, O+X spends a full fury meter.
- **Ages** are the abilities, in `ages`, gained by devouring a legend with
  `grants` set: drake (charge: rams brittle tiles, dashes across gaps), wyrm
  (two flaps in the air), great wyrm (free flight, Wyrmfire's handling).
- **Gates:** flammable tiles burn and spread fire to their neighbours;
  brittle tiles need the charge; ledges need wings; Camelot's gate is three
  seals, each a `ward` tile named by its legend's row.
- **Nests** heal, respawn everything but the fallen legends, and are where
  the dragon wakes after dying. Relics raise health or fire for good.
- **Units** move under gravity through the same `slide` as the dragon.
  Only those near the screen are updated. Walkers patrol their ledge until
  they see the dragon; `flies` exempts a unit from gravity.

## The world

| | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| heights | eyrie | sky rock | Merlin | sky | wall | wall walk | upper hall | throne |
| surface | Gawain | shaft top | tower | village | gate | courtyard | great hall | armoury |
| under | | mine shaft | mines | crypt door | Kay | | dungeon | |
| deep | back cave | lair | caverns | chasm | lava | lava lake | old hoard | |

## Tests

    py run_tests.py      # must exit 0
    py count_tokens.py

`run_tests.py` runs `gen_cart.py` (which runs the level check and writes
`world.png` and `sheet.png`), then two carts: `test_data` (headless) checks
every name the data uses; `test_run` (in a window) measures the whelp's jump
and glide, burns the lair door, then moves a scripted dragon to everything
the level places at every age. Screens are saved as `fire.png` and `shot.png`.

`test_run` runs in a window because headless PICO-8 died on it once with the
access violation described in `../wyrmfire/DESIGN.md`. The cause is as
unknown here as there; it passed three runs of three in a window.

The level check trusts a jump of 2 tiles and 2 more per flap; the cart
measures about 2.6. If `jump` or `gravity` change, compare the two.

## Not built yet

- Saving progress between sessions (cartdata has 63 free slots).
- The meat-to-gauge and combo juice from Wyrmfire.
- Rooms (0,2), (5,2), (7,2), (7,3) are solid rock.
