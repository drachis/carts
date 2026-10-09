# Wyrmfire

A top-down dragon burns a medieval realm: Dynasty Warriors crowds, Rampage
destruction, shmup handling, and a whelp that eats its way up to something
that fills the screen. It ends with Arthur defending Camelot.

The project is also an experiment: **how much game, and how good a game, fits
in one PICO-8 cart's 8192 tokens.** Every choice below serves that.

## Rules of the build

1. **Data is strings, not tables.** A table constructor costs about 3 tokens
   per field; a string costs 1 whatever its length. All tuning lives in
   `data.lua` as text parsed once at boot (`parse_table`, `parse_record`).
   A new unit, shot, building, settlement, age, boon or wrath level is a new
   line of data and costs nothing.
2. **Behaviour is named by data.** A unit row names its `ai`; the function is
   `unit_ai[name]`. New behaviour is one function, shared by any number of rows.
3. **Objects inherit from their data rows.** Every row `parse_table` makes is a
   prototype (its `__index` is itself). Units, shots, buildings and settlements
   are made with `setmetatable(object,row)`, so `unit.speed` reads the row
   unless the unit has set its own. The object's table holds only what differs
   from one to the next. Columns are named so they cannot be mistaken for an
   object's own state (`max_hp` beside `hp`, `reload` beside `cooldown`,
   `tiles` beside `size`).
4. **Named constants are globals.** `parse_record` fills the global table
   (`_ENV`) with the tile ids, sound slots and tuning values, so `snd_roar`
   costs one token where `sound.roar` cost two.
5. **Cart memory before Lua memory.** If state fits in the map, sprite flags,
   sfx memory or user memory, it goes there (see the memory map).
6. **Readable names are free.** A token is a token whether it is `u` or
   `building`, so nothing is abbreviated. Savings come from structure.
7. **No comments in the Lua.** PICO-8 counts every character of source against
   a second limit of 65,535, and comments were a third of it. Notes on the code
   live in `CODE_NOTES.md`, filed by module and function; `run_tests.py` fails
   if a comment appears in a module. (The two comment lines at the top of
   `wyrmfire.p8` stay: PICO-8 uses them as the cart's title and author.)
8. **PICO-8 is the only token counter.** `py count_tokens.py` asks PICO-8 and
   reports both budgets.
9. Module functions and state are globals: all includes share one chunk, which
   allows only 200 `local`s. Use `local` inside functions.

## Memory map

| Where | Holds |
|---|---|
| Map, x 0..63 | Ground sprite per tile (64x64 world) |
| Map, x 64..127 | State byte per tile: `0` nothing, `1..127` burning with that many fire visits left, `128+id` a building (`all_buildings[id]`) |
| Sprite flags | Ground fuel: high nibble = fire visits it burns for, low nibble = chance in 16 of catching from a neighbour |
| Sprite sheet | A ground tile's burnt form is 16 ids later (one row down) |
| Sprites 128..255 | Not available: shared with map rows 32..63 |
| Sfx memory | Rewritten in play: the hurt sound's volume per blow, the coin's pitch per coin, the roar's five pitches as the dragon gains weight |
| `0x4300..0x52ff` | Unit grid: a byte per tile, cleared each frame, so units do not stack |
| `0x5300..0x5dff` | Free (2.8k of user memory) |
| `cartdata` slot 0 | High score, in tens; slots 1..63 free |

Fire is a cellular automaton over the state bytes: 4 rows are visited per
frame, so each tile is visited every 16 frames. There is no fire list and no
cap on how much of the realm burns.

## The game

**The run**

- **Spine:** a shielded settlement is under a dome. Nothing in it can be
  harmed or lit, the dragon is pushed back out, and its flames slide off. Each
  town's dome holds while its hero (named in `realm`) lives; the hero comes out
  at the alarm. With the hero slain the town's church, a `ward`, can burn.
  Camelot's dome holds while any ward stands. The compass points to the nearest
  ward, then to Camelot.
- **Finale:** the last ward falling sets wrath to its final level, which brings
  Lancelot, Merlin and the heaviest reinforcements. Mordred and Morgan le Fay
  defend Camelot's minster and wizard tower; Arthur defends the keep. Razing
  the keep wins.
- **Side roads:** the hamlet, village, abbey and fort are optional. They are
  where the dragon eats, and razing any settlement pays a bounty, a heal, a
  spin of the boon reel and a rest.
- **Peaks and rests:** being at a standing settlement is a `battle`:
  reinforcements come `battle_rush` times faster and the battle track plays.
  Open country has the roaming track. Razing a settlement buys `lull_frames`
  with no reinforcements.
- **Wrath:** six levels by score, each with its own pool of reinforcements,
  some sending a legend. Score alone cannot reach the last.

**The dragon**

- **Growing:** it grows by eating. Every unit has a `meal` value (sheep 10, a
  cow 18, a serf 1). The eaten thing flies to the sheep gauge as meat, and at
  each `meals` threshold in `ages` the dragon comes of age and gains that row's
  stats. There are ten ages, whelp to doom of kings.
- **Size, weight, momentum:** `size` scales the whole body, its reach and its
  jaws (`draw_dragon` scales its forward and sideways vectors, so every offset
  follows). `weight` is heft: wingbeats shake the screen, buildings beneath are
  crushed, its roar is retuned lower, and the not-`brave` flee on sight. Top
  speed stays the same across ages while `accel` and `turn_rate` fall and
  `friction` rises, which is what makes the late dragon feel massive.
- **Handling:** flight is near-instant. Holding breath locks the facing and
  slows the dragon, so fire is strafed across targets. The body is a chain of
  circles (`update_body`) that is both what is drawn and what can be hit. A
  hit gives `mercy` frames of safety. A charge coils for a moment, then bursts
  forward, untouchable, and is the answer to a raised guard.
- **Breath:** one long exhale, strongest on full lungs, with a kick on the
  first gasp; then it must be released to breathe in. It burns wooden shots.
- **Fury:** score, coins, grazes and burnt shots fill a meter. Charging with
  fire held when it is full is an inferno: a nova, then `fury_stats` laid over
  the dragon for a while (`rage` multiplies the breath's power at any age).
- **Being a dragon:** `roar` strikes the not-`brave` with fear on big moments.
  The jaws snap up anything not brave that passes under the head.

**The realm's defenders**

- **Polarity:** orange (wooden) shots burn up in the breath and feed fury;
  blue, green and violet ones cannot be burned and must be dodged. A near miss
  is a graze, which also feeds fury. Volleys, fans and seeking are data
  (`volley` on the unit; `fan` and `seek` on the shot).
- **Legends have a rhythm** (`unit_ai.legend`, shared by lancers and paladins):
  press the attack, raise a guard that throws fire back (charge it), flash
  white while gathering, then lunge for triple damage and a long knockback
  (dodge it, or charge through). Their damage is set by how late they are met:
  Arthur's lunge fells a whelp in one blow and a calamity in four.

**Score and feel**

- **Combo:** every kill and ruin goes through `add_score`. Hits within
  `combo_frames` chain; every `combo_step` raise the multiplier, up to
  `max_multiplier`, and `streaks` call out milestones.
- **Coins:** ruins and kills pay out coins that fly to the dragon and keep the
  combo alive; burning buildings and slow-burning ground drip them, so a realm
  left alight keeps paying.
- **Livestock:** flocks are restocked slowly while fewer than `min_livestock`
  animals are alive, so growth is never lost for good.
- **Reading the screen:** the dragon flies over everyone; only shots are drawn
  above it. Melee fighters stop at the edge of its body. Units never share a
  tile. Popups are only for prizes of 100 or more. The HUD is one top bar of
  upward-filling gauges (heart, spark, star, sheep) with the wards left and the
  compass as a dial; a boss has a named bar along the bottom.
- **Juice:** shake and hit-stop via `jolt`, scaled to the blow; white `flash`
  frames; shockwave rings; blood; a death sequence; knockback; a camera that
  leads by half the breath's reach.

## Modules

| File | Owns |
|---|---|
| `data.lua` | Parsers and every data table |
| `core.lua` | Maths, particles, text |
| `world.lua` | Tile state, fire, domes, buildings, world generation |
| `units.lua` | Defenders, `unit_ai` behaviours, shots |
| `dragon.lua` | The player: growth, movement, breath, charge, drawing |
| `main.lua` | States, score, wrath director, HUD, `_init/_update/_draw` |
| `CODE_NOTES.md` | Every note on the code, by module and function |

`gen_gfx.py` writes sprites, sprite flags, sfx and music into the carts.

## Tests

    py run_tests.py      # must exit 0
    py count_tokens.py   # both budgets, straight from PICO-8

`run_tests.py` regenerates the art, saves `sheet.png`, and runs three carts.
There are three because the game leaves no room in a cart for a harness:

- `tests/test_data.p8` (headless): every name and stat the data refers to
  exists; the dragon at each age; every boon comes up on the reel.
- `tests/test_title.p8` (headless): the title and game-over screens, saved as
  `title.png` and `won.png`.
- `tests/test_run.p8` (in a window): a scripted dragon plays whole games for
  4500 frames; one frame is saved as `shot.png`.

The title and soak carts include generated copies of the modules
(`tests/gen_*.lua`), and each swaps one for a copy with functions it never
needs emptied, to make room. Carts print screens as text and the runner writes
the PNGs. `tests/reset_best.p8` zeroes the saved high score.

Commit after each working step, with the token count when it changed.

## An unexplained crash in headless PICO-8

Headless PICO-8 (`-x`) sometimes dies with an access violation (exit code
`0xC0000005`) part-way through the soak: rarely when run alone, in most runs
when a dozen run at once. **The cause is not known.** What is known, from
about twenty batches of `tests/crash_hunt.py` (parallel soaks with parts of
the game switched off or edited):

- It needs the game's drawing: with `_draw` empty it never happens. Harmless
  drawing of similar cost does not cause it, and Lua memory stays flat.
- Removing any one of several unrelated things stops it, while removing other
  things of similar size does not. So it depends on the exact shape of the
  program rather than on anything the game does.

Causes proposed and then disproved: PICO-8 start-up, `cstore`, frames running
late, `circ` with a fractional radius, `circ` reaching off the screen. In
windowed play the user reports no crashes over many hours and builds, so the
soak now runs in a window, where it has not been seen.

## Ideas not built yet

- A many-headed Tiamat form: a breath type per head.
- Walls and gates around Camelot; siege camps on the roads.
- Meta-progression in the spare `cartdata` slots.
- Baking the world into the cart's map data instead of generating it: about
  500 tokens back, at the cost of the same realm every game.
