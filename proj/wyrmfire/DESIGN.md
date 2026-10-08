# Wyrmfire

A top-down dragon burns a medieval realm: Dynasty Warriors crowds, Rampage
destruction, an escalating response that ends with Arthur defending Camelot.

The project is also an experiment: **how much game, and how good a game, fits
in one PICO-8 cart's 8192 tokens.** Every design choice below serves that.

## Rules of the build

1. **Data is strings, not tables.** A table constructor costs ~3 tokens per
   field; a string costs 1 whatever its length. All tuning lives in `data.lua`
   as text parsed once at boot (`parse_table`, `parse_record`). Adding a unit,
   building, legend, settlement or wrath level should be a new line of data.
2. **Behaviour is named by data.** A unit row names its `ai`; the function is
   `unit_ai[name]`. New behaviour is one function, reused by any number of rows.
3. **Cart memory before Lua memory.** If state fits in map, sprite flags or
   user memory, it goes there (see the memory map).
4. **Readable names are free.** A token is a token whether it is `u` or
   `building`, so nothing is abbreviated. Savings come from structure.
5. **PICO-8 is the only token counter.** `py count_tokens.py` asks PICO-8.
6. Module functions and state are globals: all includes share one chunk, which
   allows only 200 `local`s. Use `local` inside functions.

## Memory map

| Where | Holds |
|---|---|
| Map, x 0..63 | Ground sprite per tile (64x64 world) |
| Map, x 64..127 | State byte per tile: `0` nothing, `1..127` burning with that many fire visits left, `128+id` a building (`all_buildings[id]`) |
| Sprite flags | Ground fuel: high nibble = fire visits it burns for, low nibble = chance in 16 of catching from a neighbour |
| Sprite sheet | A ground tile's burnt form is 16 ids later (one row down) |
| Sprites 128..255 | Not available: shared with map rows 32..63 |
| `0x4300..0x5dff` | Free (6.9k of user memory) |
| `cartdata` slot 0 | High score; slots 1..63 free |

Fire is a cellular automaton over the state bytes: 4 rows are visited per
frame, so each tile is visited every 16 frames. There is no fire list and no
cap on how much of the realm burns.

## Modules

| File | Owns |
|---|---|
| `data.lua` | Parsers and every data table |
| `core.lua` | Maths, particles, text |
| `world.lua` | Tile state, fire, buildings, world generation |
| `units.lua` | Defenders, `unit_ai` behaviours, shots |
| `dragon.lua` | The player: movement, breath, charge, drawing |
| `main.lua` | States, wrath director, HUD, `_init/_update/_draw` |

`gen_gfx.py` writes sprites, sprite flags and sfx into the carts.
`run_tests.py` regenerates art, runs the headless soak test (which also checks
every name the data refers to exists) and saves `shot.png`.

## Workflow

    py run_tests.py      # must print "ok"
    py count_tokens.py   # budget, straight from PICO-8

Commit after each working step, with the token count when it changed.

## Ideas not built yet

- Dragon growth and upgrades (stats are already a mutable record).
- A many-headed Tiamat form: breath types per head.
- Walls and gates around Camelot; siege camps on the roads.
- Music; a hoard/meta-progression in the spare `cartdata` slots.
