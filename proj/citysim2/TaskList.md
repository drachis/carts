# citysim2 — task list

Tracks build progress. Each module = one delegable agent task (see DESIGN.md §11
for the per-module contract: file · budget · defines · calls · proves). Lead
verifies tokens with `count_tokens.py <file>` and runs the test cart with
`pico8 -x`. Budgets are targets; PICO-8 `-x` is the authority.

Status: ☐ todo · ◐ in progress · ☑ done · ⚠ over budget / needs trim

## Foundation
- ☑ DESIGN.md contract + budget + resolved decisions (§10)
- ☑ count_tokens.py (whole cart or single file)
- ☑ citysim2.p8 cart skeleton + glue
- ☑ params.lua (150) — tuning knobs
- ☑ data.lua (100) — res tables + 0x8000 plane addresses

## Core (critical path — build in order)
- ☑ map.lua (550→**577**) — grid, tile/zone helpers, autotile, camera, plane
  accessors (`peekp`/`pokep`/`pclr`). Integrated, compiles. Encoding: 0 water /
  1 grass / 2 mountain · roads 16..31 · power 32..47 · R/C/I 48/52/56 +density.
- ☑ router.lua (300→**368**) — `path(x0,y0,x1,y1,pass,cost)` weighted Dijkstra
  (lazy/stale-skip) + `flood(x0,y0,pass,visit)`. Substrate-agnostic. Integrated.
- ☑ net.lua (500→**143**) — road components → `pl_comp`; `rcomp`/`connected`;
  `powered()` STUB (true) until power tiles+sim. Offer index deferred to sim.
- ☑ agents.lua (550→**388**) — pool, `spawn_agent`, `update_agents` (path_step +
  cong ±1 per tile), `draw_agents`. Congestion invariant verified in smoke test.
- ☑ sim.lua (1800→**733**) — timewheel event loop; eval-driven grow/decay gated
  by road access + a reachable complement (via the **offer index** `idx[comp][kind]`,
  built here); spawns commuters (p.show); derived census. **Core loop ALIVE**
  (connected R+C grow to density 3 + cars run). Growth now also gated by
  `powered()` (real: net floods from plant tiles over power lines). ⚠ evt_cap
  overflow drops events (fine small; revisit at scale). TODO: arrive-events.

## Generation
- ☑ terrain.lua (220→**384**) — box-blur fBM heightmap → **percentile** thresholds
  (~13% water, ~11% mtn, rest grass) + greedy downhill river. (Fixed a flat-map
  bug the smoke test caught.)

## Shell
- ☑ tools.lua (1000→**398**) — cursor/camera + tool palette + placement
  (road/power autotile, R/C/I zones, bulldoze; hooks update_net + sim eval).
  Built as a HEADER by lead, placement fleshed out by an agent (the pattern works).
- ☑ gen_gfx.py (art, 0 code tok) — sprite sheet for the tile encoding (water/
  grass/mountain, autotile roads+power, R/C/I buildings by density). sprite id ==
  tile id so map() renders the city directly.
- ☑ render.lua (550→**111**) — draw_world: camera + map() + congestion overlay
  (red on busy roads) + agents + cursor. Built header→agent-fleshed.
- ☑ hud.lua (500→**170**) — top bar (money/pop/jobs/date) + RCI demand bars. header→agent.
- ☑ inspector.lua (300→**108**) — panel over the cursor tile: kind+density +
  no road/starved/thriving. Opaque bg (avoids the citysim no-bg bug). header→agent.
- ☑ econ.lua (200→**230**) — money($k), mfmt, try_spend (debt floor), tax, monthly
  tick (income from pop/jobs, road upkeep). header→agent.
- ☑ minimap.lua (300→**203**) — whole-city overview (3px/tile, opaque bg, camera
  viewport rect), toggled from the pause menu. header→agent.
- ☑ save.lua (220→**138**) — save/load: scalars in spare map cells + cstore/reload
  grid (0x2000) + planes (0x8000) to companion cart; rebuilds transient state.
  header→agent. round-trip verified in smoke.

## Disasters
- ☑ disaster.lua (428) — fire. Zones ignite (random p.fire_chance or "start fire"
  menu), burn over timewheel **k=2 events via ev_hook** (sim stays decoupled),
  spread to neighbours, collapse to rubble (tile 63, blocks growth until dozed).
  Fire station (tile 62, "fire" tool, cost.fire) suppresses within p.fire_rad.
  pl_fire plane (0x9c00) = burn ticks; fires[] mirrors it for draw_fire flames.

## Legibility ("the sim explains itself")
- ☑ notify.lua — event log. notify(msg,col,x,y) ring (cap 8); draw_log fades a
  bottom-left ticker. Sim emits "district booming"/"zone abandoned"; disaster
  emits "fire!"/"burned to rubble". Calls guarded (`if notify then`) so modules
  stay decoupled. Each notice keeps its tile for future location-flagging.

## Polish
- ☑ daynight.lua (66) — day/night cycle. Dithered darkness over the world scaled
  by time of day (sim `tick`, period p.day_frames); zone lit windows glow through
  the dither. day_phase() 0=noon..1=midnight. Cheaper than a sprite-bank swap.
- ☐ fx.lua (200) — particles (plant/fire smoke, construction dust)
- ☐ sfx/music hooks (60)

## Method
- ☑ skill `delegate-module` written (~/.claude/skills/) — codifies header→agent→
  verify loop used for tools/render/inspector/econ/hud/save/minimap.

## Lead loop
1. Hand a module's §11 contract to an agent (other model).
2. Agent writes the file; lead runs `count_tokens.py <file>` (under budget?).
3. Lead adds the `#include` to citysim2.p8, runs `pico8 -x` test cart.
4. Tick it here; record actual tokens vs budget.
5. **Screenshot each iteration** (the player is remote): `_shot.p8` lays a test
   city + `cstore`s the 0x6000 framebuffer to `shot_fb.p8` under `pico8 -x`, then
   `fb_to_png.py shot_fb.p8 shot.png 3` decodes it → upload `shot.png`.
   (Headless `-x` can't screenshot directly; this captures the real framebuffer.)

### Actual tokens (fill as modules land)
| module | budget | actual |
|--------|-------:|-------:|
| params | 150 | 39 |
| data   | 100 | 36 |
| map    | 550 | 577 |
| router | 300 | 368 |
| net    | 500 | 143 |
| agents | 550 | 388 |
| terrain| 220 | 384 |
| sim    | 1800 | 733 |
| tools  | 1000 | 398 |
| render | 550 | 111 |
| inspector | 300 | 108 |
| econ | 200 | 230 |
| hud | 500 | 170 |
| minimap | 300 | 203 |
| save | 220 | 138 |
| landval | 200 | 134 |
| disaster | 200 | 428 |
| notify | 150 | 122 |
| daynight | 50 | 66 |
| cart total | 8192 | 5365 |

## Research depth built (this session, autonomous)
- ☑ economy loop — placement costs money (try_spend), denied when broke.
- ☑ power gating — plant tile + real powered() flood; growth needs power.
- ☑ land value / desirability — pl_val field (water/parks +, industry/plants/
  congestion −) weights growth; shown in inspector.
- ☑ park service building (raises desirability); name-based tool dispatch.
- ☑ goods chain + freight — C<->I trade goods (orange freight) vs R commuters.
- ☑ congestion moved from world tint to minimap.
- ☑ all gameplay constants centralized in params.lua.
- ☑ `delegate-module` skill (~/.claude/skills/).

## Remaining = polish reserve (HELD until playtest) or a fork
- disasters (fire chain), day/night swap, fx, sound — all draw the ~820 reserve.
- optional non-reserve depth: arrive-events + per-tile event log (legibility).

Note: agents under-estimate their own token cost (map agent guessed ~390, real
577). The lead's `count_tokens.py` is the gate before integrating.
