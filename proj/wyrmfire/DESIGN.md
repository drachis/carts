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
| Sfx 16..18 | The music. Their speed bytes (`0x3241 + n*68`) are poked to raise the tempo with wrath |
| `0x4300..0x5dff` | Free (6.9k of user memory) |
| `cartdata` slot 0 | High score; slots 1..63 free |

Fire is a cellular automaton over the state bytes: 4 rows are visited per
frame, so each tile is visited every 16 frames. There is no fire list and no
cap on how much of the realm burns.

## The loop, and where the excitement comes from

- **Beats:** fly to a settlement (compass points at the nearest standing
  one) -> it sounds the alarm and its militia turns out -> raze every building
  for a bounty and a heal -> move on. Camelot is the last and hardest.
- **Combo:** every kill and ruin goes through `add_score`. Hits within
  `combo_frames` of each other chain; every 5 raise the multiplier, and
  `streaks` call out milestones.
- **Fury:** score fills a meter. Charging with fire held when it is full is an
  inferno: a nova, then `fury_stats` laid over the dragon for a while.
- **Wrath:** total score raises the realm's response and sends legends; the
  music speeds up with it.
- **Shmup handling:** flight is near-instant (`accel`, `friction`). Holding
  breath locks the facing and slows the dragon, so fire is strafed across
  targets. Only the heart (radius 5, shown while breathing) can be hit by
  shots; a hit gives `mercy` frames of safety and a charge is untouchable.
- **Polarity:** orange (wooden) shots burn up in the breath and feed fury;
  blue (holy) shots must be dodged. Near misses graze, which also feeds fury.
  Volleys and fans are data (`volley` on the unit, `fan` on the shot).
- **Coins and boons:** ruins and kills pay out coins that home to the dragon
  and keep the combo alive; razing a settlement spins the boon reel.
- **Juice:** hit-stop and shake via `jolt`, white `flash` frames, shockwave
  rings, score popups, bodies flung by charges, knockback, look-ahead camera.

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
