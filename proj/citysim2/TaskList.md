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
  (connected R+C grow to density 3 + cars run). ⚠ evt_cap overflow drops events
  (fine small; revisit at scale). TODO later: arrive-events, real `powered()`.

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
- ☐ hud.lua (500) — RCI demand bars + minimap (split from the glue's inline hud)
- ☑ inspector.lua (300→**108**) — panel over the cursor tile: kind+density +
  no road/starved/thriving. Opaque bg (avoids the citysim no-bg bug). header→agent.
- ☐ econ.lua (200) — money($k), tax, time; revenue read from sim

## Polish (HELD — do not start until base game playtested; reserve ~820)
- ☐ daynight.lua (50) — sprite-bank swap
- ☐ fx.lua (200) — particles
- ☐ save.lua (220) — cstore/reload grid + 0x8000 planes to companion cart
- ☐ sfx/music hooks (60)

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
| cart total | 8192 | 3359 |

Note: agents under-estimate their own token cost (map agent guessed ~390, real
577). The lead's `count_tokens.py` is the gate before integrating.
