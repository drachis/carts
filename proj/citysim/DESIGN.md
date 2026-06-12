# citysim — pico-8 rci city builder (simcity-2000-esque)

Top-down 48x48 tile city. Place R/C/I zones, roads, power lines, power plants.
Zones grow in density when they have demand + road access + power. Taxes fund it.

## hard pico-8 rules for every module
- all code and string literals lowercase.
- no `math.*` (no `math.huge` — use 32767). use `flr abs min max mid rnd sqrt`.
- string concat `..`, convert with `tostr()`. tables 1-indexed; use `add del all foreach pairs`.
- no `continue` keyword.
- do NOT define `_init/_update/_draw` — `citysim.p8` owns them.
- globals are the api; prefix module-private helpers with a module tag (e.g. `pw_`, `gr_`, `ec_`, `ui_`) to avoid collisions.
- stay within your token budget (see module list). human-readable > golfed, but be lean.
- debug via `printh(...)` only; strip before done unless asked.

## world state (single source of truth)
The grid lives in pico-8 map memory: `mget(x,y)` / `mset(x,y,s)` for x,y in 0..47.
The sprite id IS the tile state. (rows 32..47 of map ram overlap sprites 128..255,
which we never use — safe.)

### sprite ids
| id      | meaning                          |
|---------|----------------------------------|
| 1       | grass (buildable)                |
| 2       | trees (buildable)                |
| 3       | water (not buildable)            |
| 16..31  | road; id = 16 + mask (n=1 e=2 s=4 w=8 of connected road neighbors) |
| 32..35  | residential density 0..3         |
| 36..39  | commercial density 0..3          |
| 40..43  | industrial density 0..3          |
| 48      | power plant                      |
| 49/50/51| power line horiz / vert / cross  |
| 52      | "no power" bolt overlay icon     |
| 53/54   | line crossing h-road / v-road (flags: road + conducts) |

### sprite flags (already set in __gff__)
- flag 0: road
- flag 1: zone (any r/c/i, any density)
- flag 2: conducts power (zones, lines, plant)
- flag 3: buildable terrain (grass, trees)

### map.lua helpers (lead-owned — call these, don't reinvent)
```
gridw, gridh = 48, 48
in_bounds(x,y) -> bool
tile(x,y) -> sprite id (0 if out of bounds)
set_tile(x,y,s)
is_road(x,y)  is_zone(x,y)  conducts(x,y)  is_buildable(x,y)
zone_kind(x,y) -> 1 r, 2 c, 3 i, or nil
zone_density(x,y) -> 0..3 (nil if not zone)
set_zone(x,y,kind,density)
has_road_access(x,y) -> true if any of the 8 neighbors is road
neighbors4(x,y) -> iterator-free: returns table of {x,y} orth neighbors in bounds
```

### shared globals
```
money            -- econ.lua owns
pop, jobs        -- growth.lua recomputes each demand pass
demand           -- {r=,c=,i=} each -1..1, growth.lua owns
powered          -- set: powered[x+y*64]=true, power.lua owns
is_powered(x,y)  -- power.lua
month, year      -- econ.lua owns (year starts 1900, month 1..12)
camx, camy       -- camera px, map.lua/tools own
cur              -- {x=,y=} cursor tile, tools.lua owns
mode             -- "play" | "menu" | "map", tools.lua owns
tool             -- index into tools_list, tools.lua owns
tools_list       -- see tools section
msg, msg_t       -- status line text + ttl frames; anyone may set (ui draws)
```

## modules + budgets (~3800 tokens total target, cart limit 8192)
| file       | owner | tokens | provides |
|------------|-------|--------|----------|
| citysim.p8 | lead  | ~200   | _init/_update/_draw dispatch |
| map.lua    | lead  | ~450   | grid helpers, terrain gen (grass+tree clumps+river), draw_world(), update_camera() |
| tools.lua  | lead  | ~700   | input, cursor, tool menu state, placement/bulldoze, road+line autotile refresh |
| power.lua  | agent | ~300   | init_power(), update_power(), is_powered(x,y) |
| growth.lua | agent | ~500   | init_growth(), update_growth() (demand pass + growth tick) |
| econ.lua   | agent | ~350   | init_econ(), update_econ(), cost table, try_spend(n) |
| ui.lua     | agent | ~900   | draw_hud(), draw_menu(), draw_minimap(), draw_msg() |
| traffic.lua| agent | ~350   | init_traffic(), update_traffic(), draw_traffic() — ambient cars on roads |

## module specs

### power.lua
- `init_power()` sets `powered={}`.
- `update_power()`: clear set; bfs from every power-plant tile through 4-neighbors
  whose sprite has the conducts flag (power travels through zones, lines, plants —
  classic simcity). mark each reached conductive tile powered. plants unlimited
  capacity in v1. called by main loop every 16 frames and after any placement
  (tools calls it via global name).
- `is_powered(x,y)` -> bool via the set, key `x+y*64`.
- full-grid scan to find plants is fine (48x48 once per call).

### growth.lua
- density payloads: r density d -> d*8 residents; c -> d*6 jobs; i -> d*8 jobs.
- `update_growth()` runs every frame but does work on a stride:
  - every 32 frames: demand pass. scan grid, recompute `pop`, `jobs` (c+i),
    then: `demand.r = mid((jobs+16-pop)/32, -1, 1)`
          `demand.c = mid((pop*0.5-cjobs)/24, -1, 1)`
          `demand.i = mid((pop*0.7-ijobs)/24, -1, 1)`
  - every 16 frames: growth tick. sample 24 random cells; for each zone cell:
    let d = demand[kind]. if powered + road access + density<3 and rnd()<d*0.5
    -> density+1. if (not powered or d<-0.5) and density>0 and rnd()<0.08
    -> density-1.
- growing to a new density just calls set_zone (sprite swap = visual progression).

### econ.lua
- `cost = {road=10, zone=50, line=5, plant=300, dozer=1}` (zone covers r/c/i).
- `try_spend(n)`: if money>=n deduct + return true, else set msg="not enough money",
  msg_t=60, return false.
- `init_econ()`: money=2000, month=1, year=1900, frame counter.
- `update_econ()`: month = 300 frames. on month rollover: advance month/year;
  income = pop*2 + jobs; upkeep = (#roads + #lines)*1 + #plants*10 via one grid
  scan; money += income-upkeep; set msg to "+$n" or "-$n" summary, msg_t=90.

### ui.lua
- screen: hud is rows 0..7, world view is y 8..127.
- `draw_hud()`: black bar, money (e.g. "$2000"), pop, "jan 1900" (3-letter months),
  rci demand as 3 tiny bars (4px wide each, green up / red down from a midline)
  labeled r c i. keep it tight — 128px wide total.
- `draw_menu()`: when mode=="menu", a horizontal icon strip near the bottom:
  one 10x10 slot per tool in tools_list, current selection highlighted box +
  tool name + cost printed above. icons: draw the tile sprite (use spr ids:
  road 18, r 33, c 37, i 41, line 49, plant 48; bulldoze: draw an x; map tool:
  draw 3x3 checker).
- `draw_minimap()`: when mode=="map", dim background (rectfill), centered 96x96
  panel: each tile = 2x2 px. colors: water 12, grass/trees 3, road 5, r 11,
  c 12→use 14 for c to avoid water clash, i 9, plant 8, line 6. draw white rect
  showing current camera viewport. title "city map - ❎ close".
- `draw_msg()`: if msg_t>0, print msg centered at y 110 with dark outline box,
  decrement msg_t (ok to mutate in draw).
- `tools_list` (owned by tools.lua, ui reads): each entry
  `{name=, costkey=, spr=}` — see tools.lua; ui must not assume length.

### tools.lua (lead, listed so agents know the contract)
- play mode: dpad moves cursor (camera follows, hud-aware), ❎ (btn 5) applies
  tool at cursor, 🅾️ (btn 4) opens menu.
- menu mode: ⬅️➡️ select tool, ❎ or 🅾️ confirm/close. "map" entry switches to
  map mode; any button leaves map mode.
- placement validates terrain buildable (or road/line/zone for bulldoze),
  charges via try_spend, refreshes road/line autotiles on cell+4 neighbors,
  then calls update_power().

## testing
`tests/test_sim.p8` includes the lua modules, stubs what it must, runs headless:
`& "O:\AI\Claude\AI w Pico8\PICO-8\pico8.exe" -x tests\test_sim.p8`
asserts print "ok ..." / "FAIL ..." via printh. agents: you don't run pico-8;
lead runs tests. write code that parses (balanced end/then) — that's on you.
