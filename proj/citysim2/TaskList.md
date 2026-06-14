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
- ◐ router.lua (300) — weighted path(from,to,costfn) + flood; congestion-aware
- ☐ net.lua (500) — road+power components + per-component offer index; powered()
- ☐ agents.lua (550) — pooled trips realizing contracts; cong +/- in path_step
- ☐ sim.lua (1800) — event loop (timewheel) + broadcast→match→contract + grow/decay
  - proof of concept: residential labor → commercial jobs, one commuter loop alive

## Generation
- ☐ terrain.lua (150) — noise heightmap → threshold; rivers via reused pipeline

## Shell
- ☐ tools.lua (1000) — cursor, zone, build, bulldoze, tool_put
- ☐ render.lua (550) — draw_world, agents, overlays
- ☐ hud.lua (500) — hud + minimap
- ☐ inspector.lua (300) — generic tile_info renderer (needs/contracts/agents/elog)
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

### Actual tokens (fill as modules land)
| module | budget | actual |
|--------|-------:|-------:|
| params | 150 | 39 |
| data   | 100 | 36 |
| map    | 550 | 577 |
| cart total | 8192 | 705 |

Note: agents under-estimate their own token cost (map agent guessed ~390, real
577). The lead's `count_tokens.py` is the gate before integrating.
