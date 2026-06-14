# citysim2 — design contract (agent/market city sim)

Successor to `proj/citysim`. Same genre (PICO-8 SimCity-style RCI builder), but
the simulation is **agent- and market-driven** instead of formula-driven. The
goal is **legible emergence**: you can watch the city run as traffic, and click
anything to understand *why* it's happening.

Read `proj/citysim/LEARNINGS.md` first — it has the PICO-8 craft, the citysim
post-mortem, and the SimCity research this builds on. This doc is the contract.

---

## 1. The one idea

Buildings don't read a global demand number. They **broadcast needs** and
**answer with offers** over the road / power network. When a need and an offer
match, both sides act and a **visible agent** travels the network to fulfill it.

```
        broadcast(need)  ->  collect offers over the network
                         ->  match best offer (capacity + commute cost)
                         ->  commit a contract  ->  spawn the trip (agent)
                         ->  satisfied need = grow ; unmet over time = decay
```

The same loop drives residential, commercial, and industrial. Demand (the RCI
meter) is **read out of** the simulation (count unmet broadcasts), never fed in.
Traffic **is** the contracts being fulfilled. Congestion raises commute cost,
which makes far matches fail, which shapes where the city grows — all emergent.

This is SimCity 4's trip-based simulator, shrunk to fit 8192 tokens.

---

## 2. Entities, needs, offers

Every developed tile is a producer and/or consumer of a few **resources** that
flow over a **channel** (road or power):

| tile          | produces (offer)     | needs (broadcast)              | channel |
|---------------|----------------------|--------------------------------|---------|
| residential   | labor                | jobs, goods, services          | road    |
| commercial    | jobs, goods (retail) | labor, goods (wholesale)       | road    |
| industrial    | jobs, goods (freight)| labor                          | road    |
| power plant   | power                | —                              | power   |
| service bldg  | coverage (fire/edu…) | power                          | both    |

Resource ids are small ints: `1 labor  2 jobs  3 goods  4 power  5 coverage`.
A need and an offer match only on the same resource + a path on its channel.

**Match cost** = commute/haul cost = network distance (BFS hops) scaled by
congestion on the path. Lower is better; beyond a max cost the match fails.

---

## 3. The tick (round-robin, not every-frame)

Per sim tick, sample `N` tiles (like citysim's growth sampling) and for each:

1. **Broadcast.** For each unmet need on the tile, BFS its channel network for
   reachable tiles that offer that resource with spare capacity.
2. **Offer / match.** Pick the lowest-cost offer with capacity. (Cache the
   per-tile network component so "who can I reach" is a lookup, not a fresh BFS
   every time — see `net`.)
3. **Commit.** Reserve capacity on the supplier; record a **contract**
   `{res, from, to, cost, ttl}` on both tiles. Spawn one pooled **agent** that
   drives the path (reuse citysim's `path_step`).
4. **Resolve over time.** A tile whose core needs are under contract is *served*
   → density may rise. A tile with needs unmet for `decay_t` → density falls /
   abandons, releasing its offers.

Contracts have a `ttl`; on expiry they re-validate (cheap) or dissolve. Agents
are short-lived (one trip), pooled, and capped (`agent_cap`) so a big city stays
within CPU. The visible car/truck count ≈ active contracts being traveled.

Power is special: model it as a flood-fill reachability set + capacity budget
(citysim's `power.lua` already does this); "power need" is just "am I in a
powered, non-over-capacity set".

---

## 4. Emergence & inspectability (the point)

- **RCI meter is derived:** demand.r = normalized count of unmet *labor offers*
  (residents who can't find jobs) vs unmet *labor needs* (businesses short of
  workers), etc. The bars report the sim; they don't drive it.
- **Land value / desirability emerges:** desirability of a tile = how cheaply its
  needs get matched (short commutes, served by coverage, low congestion/pollution
  nearby). High desirability → faster growth & higher density caps. No separate
  hand-tuned land-value pass required — it falls out of match costs.
- **Inspector is a first-class feature.** Click any tile → panel shows: its open
  needs, its current contracts (who it's matched with and the commute cost), the
  agents it has on the road, and its served/unserved status. The sim must
  *explain itself*; if we can't show why a tile is decaying, the model is wrong.

---

## 5. PICO-8 constraints (hard rules — from LEARNINGS.md)

- **One cart, 8192 tokens. No multicart.** Multicart trades tokens for
  complexity that grows faster than the context window — hand-offs, duplicated
  state, two build loops. The design goal is **depth and polish inside 8k**, not
  horizontal expansion. Every system below has a token budget (§6); the sim must
  fit *with room to polish*. If something doesn't fit, make it leaner or cut it —
  do not reach for a second cart.
- **Spend the budget on simulation, not surface.** citysim spent ~1900 tokens on
  formula growth + land value + achievements + a disaster system. citysim2
  **reinvests that** into the agent/market core, the offer index, and the
  inspector. Keep the rest lean.
- **State lives in map RAM**; sprite id = tile state. Per-tile *dynamic* data
  (needs/contracts) lives in a sparse table keyed `x+y*W`, rebuilt as needed so
  it never has to be serialized — save/load is one `cstore`/`reload` of the map.
- **Scaled units from day one.** Money, population, goods volumes — anything that
  can exceed ~32000 — stored in `k` units (16.16 fixed-point flips sign past
  32767). Abbreviate on display (`mfmt`-style).
- **Data tables via `split"a,b,c"`**; flags via byte-form `fset(n,bitfield)`.
- **Art via a `gen_gfx.py`-style pipeline** — zero code tokens, reproducible.
- **Globals are the API; prefix privates** (`sim_`, `net_`, `pw_`, `ag_`, `ui_`).
- One `params` table (`p`) for every constant; never shadow it.

---

## 6. Single-cart token budget

Estimates are **grounded in citysim's measured per-module costs** (this is the
main reason citysim was worth building). citysim's totals, for reference:
map 1638, tools 1297, disaster 1101, traffic 899, ui 860, growth 469, network
307, econ 288, power 249, savegame 233, effects 220, achievements 212, params
170, daynight 163, landval 159 → ~8157 in the cart.

citysim2 reuses the cheap, proven parts (power, BFS, econ, save, day/night,
effects) and spends the freed budget (no formula-growth, no land-value pass, no
achievements, no disaster in MVP) on the sim core + offer index + inspector.

| system                  | est. | grounded in / notes                                   |
|-------------------------|-----:|-------------------------------------------------------|
| params                  |  150 | citysim params 170                                    |
| map: grid + RAM state + tile/zone helpers + autotile | 450 | subset of citysim map |
| map: terrain gen (kept simple) |  200 | citysim terrain ~250, trimmed             |
| map: world draw + overlays     |  350 | citysim draw_world ~350                    |
| camera (smooth, per-pixel)     |   90 | citysim camera ~80                         |
| bfs: road pathfind (shared)    |  200 | citysim tr_path ~200                       |
| net: road components + **per-component offer index** | 450 | citysim network 307 + index |
| power: flood-fill reach + capacity budget | 250 | citysim power 249              |
| **sim: broadcast→offer→match→contract + grow/decay** | **1100** | new; cf. growth 469 (this is the heart — guard it) |
| **agents: pooled trips, path_step, draw** | **550** | citysim traffic 899 minus the BFS |
| econ: tax/upkeep/money($k)/time |  300 | citysim econ 288                          |
| tools/input: cursor, zone, build, bulldoze, tool_put | 950 | citysim tools 1297, trimmed |
| hud + minimap                  |  550 | citysim ui hud+minimap ~550               |
| **inspector panel (needs/contracts/agents)** | **350** | new — the legibility feature  |
| effects / particles            |  180 | citysim effects 220                        |
| save / load (one cstore of map RAM) | 200 | citysim savegame 233                  |
| day / night                    |  130 | citysim daynight 163                       |
| sfx / music hooks (art via gen_gfx = 0 code) | 60 | citysim ~                       |
| main glue (_init/_update/_draw) | 120 | citysim ~120                             |
| **MVP subtotal**               | **~6630** |                                                  |
| **headroom for polish + contingency** | **~1560** | to the 8192 ceiling                  |

**Risk flags.** Two systems are the likely overrun sources — watch them:
- **sim core (1100):** matching, contracts and grow/decay can balloon. Keep the
  offer index doing the heavy lifting (matching = lookup + nearest), cap contract
  bookkeeping to per-building, and reuse `params` for every threshold.
- **tools/input (950):** citysim's tools hit 1297 on placement/autotile/crossing
  logic. Fewer tile variants and a tighter `tool_put` keep this down.

**The polish budget (~1560) is real but finite.** Disasters (citysim fire+engine
was ~1100; a lean version ~500), congestion visuals, extra service types, and a
soundtrack all draw from it. Add them deliberately, re-measuring with
`pico8 -x` (authoritative) after each — not `count_tokens.py`, which only
approximates.

---

## 7. Key data structures

```lua
-- per-tile dynamic state (sparse, keyed k = x + y*W), rebuilt from map RAM:
need[k]   = bitfield or small list of resource ids this tile currently wants
offer[k]  = { res -> spare_capacity }     -- what it can supply right now
ctr[k]    = { contracts: {res,from,to,cost,ttl} }  -- active matches

-- network reach (rebuilt on a slow tick, like citysim's nt_flood):
rcomp[k]  = road-component id            -- same id == reachable by road
roffer[id]= { res -> list of supplier tiles in that component }  -- offer index
pset[k]   = true if in a powered, in-budget set

-- agents (pooled, capped):
agents = { {path,i,px,py,res,from,to,ttl,col}, ... }
```

The **offer index per network component** is the trick that keeps matching cheap:
broadcasting a need = look up `roffer[rcomp[k]][res]` and pick the nearest with
capacity, instead of a fresh BFS per need.

---

## 8. Build order (MVP first, polish last)

1. **Skeleton:** map grid + road/power in map RAM; reuse citysim's terrain,
   `power.lua`, and road BFS. Headless test the grid + flood-fill.
2. **Net:** road-component labeling + the per-component offer index. Test that
   "reachable suppliers" is correct on a hand-built map.
3. **One need end-to-end:** residential **labor → jobs** at commercial. Broadcast,
   match, contract, spawn a commuter agent that drives the path. Building grows
   when matched, decays when not. *This is the proof of concept — get it feeling
   alive before anything else.*
4. **Inspector:** click a tile, see needs/contracts/agents. (Validates the model
   is legible; build it early, not last.)
5. **Goods chain:** industry → commercial → residential, reusing the same
   broadcast/match/agent machinery (freight agents).
6. **Gating:** power and service coverage as needs that block growth.
7. **Derived RCI + econ:** compute the demand meter from unmet broadcasts; taxes
   fund services; money in $k.
8. **Polish, deliberately:** day/night, congestion visuals, sound, then a lean
   disaster — each drawn from the ~1560-token polish budget (§6), re-measuring
   with `pico8 -x` after every addition. When the cart tightens, lean out an
   existing system (§6 risk flags) rather than dropping polish.

Stop and playtest after step 3 and step 4 — if the commuter loop isn't legible
and satisfying, fix the model before adding resources.

---

## 9. Testing (per LEARNINGS.md)

- Trust documented PICO-8 calls; test **our** logic (matching, growth/decay,
  network reach, derived demand), not "does it draw".
- **Per-system test carts** (map/net, sim, agents, econ) so no cart nears 8192.
- Use a **saved minimal-city fixture** (`reload` a tiny prebuilt map) for setup
  instead of building worlds in test code — setup was most of citysim's test
  tokens.

---

## 10. Open design questions (decide before/at step 3)

- **Sampling vs. event-driven:** round-robin sample tiles (simple, citysim-proven)
  or a work-queue of tiles whose state changed (more correct, more tokens)?
- **Contract granularity:** one contract per building, or per unit of capacity?
  Per-building is far cheaper and probably enough at this resolution.
- **Congestion model:** per-road-tile agent count feeding back into commute cost
  — how cheaply can we track it without a per-tile counter every frame?
- **How much aggregation is invisible?** Simulate individually only what becomes
  visible traffic or an inspectable cause; aggregate the rest. This is also the
  main token lever — the more we can aggregate without the player noticing, the
  more sim depth fits in 8k.
- **Where does the polish budget go first?** ~1560 tokens after MVP — likely
  congestion visuals (they reinforce the core loop) before disasters or sound.

---

## 11. Delegation units (one file = one agent task)

The budget in §6 is also the **work breakdown**. Workflow proven in citysim: the
lead owns this contract, the test carts, and integration; each module is a
**single file** handed to a short-lived agent (often on another model) scoped by
its row below. The estimates will shift as we build — treat them as targets, not
limits — but they're accurate enough to scope a task and to know early when a
module is overrunning.

**Conventions every agent gets:** globals are the API; prefix module-private
helpers (`net_`, `pw_`, `sim_`, `ag_`, `ec_`, `ui_`). One `p` table for
constants — never shadow it. Modules do **not** define `_init/_update/_draw`
(the main glue owns those) and do **not** run PICO-8 — the lead measures tokens
with `pico8 -x` (authoritative) and runs the tests. Write code that *parses*
(balanced `end`/`then`) and matches the **defines** column exactly so siblings
can call it.

| file (budget) | defines — callable API out | calls — API in | proves (lead's test) |
|---|---|---|---|
| params (150) | `p`, `cost` | — | keys present |
| map (1000) | `tile`/`set_tile`/`is_road`/`is_zone`/`zone_kind`/`zone_density`, `neighbors4`, `nmask`, `road_path`, `init_map`, `draw_world`, `update_camera` | `p` | autotile mask; `road_path` finds & returns nil when disconnected |
| power (250) | `is_powered`, `update_power`, `power_short` | map, `p` | flood reach + capacity cap |
| net (450) | `update_net`, `reach_offers(x,y,res)`, `rcomp` | map, `p` | reachable suppliers correct on a hand-built map |
| **sim (1100)** | `update_sim`, `need`/`offer`/`ctr`, `demand`, `pop`, `jobs`, `tile_info(x,y)` | net, power, map, agents, `p` | a labor↔jobs need forms a contract; unmet need decays a building |
| **agents (550)** | `spawn_agent(from,to,res)`, `update_agents`, `draw_agents`, `agents` | map (`road_path`/`path_step`), `p` | a spawned trip drives source→dest staying on roads |
| econ (300) | `money` ($k), `mfmt`, `try_spend`, `tax_rate`, `update_econ` | `p` | `mfmt` formats; debt ceiling; no sign-flip at scale |
| tools (950) | `cur`, `tool`, `update_tools`, `apply_tool`, `tool_put` | map, econ, sim, `p` | place / zone / bulldoze transitions |
| ui (900) | `draw_hud`, `draw_minimap`, **`draw_inspector`** | reads all state | inspector lists a tile's needs/contracts/agents |
| fx (180) | `add_fx`, `update_fx`, `draw_fx` | — | particles spawn + expire |
| save (200) | `save_city`, `load_city` | map, econ | scalars + grid restore via one `cstore`/`reload` |
| daynight (130) | `dn_phase`, `dn_dark` | `p` | phase boundaries |
| main glue (120) | `_init`/`_update`/`_draw` | every `init_*`/`update_*`/`draw_*` | — |

A complete cold-start task = **the row's file + budget + its `defines` (must
provide) + its `calls` (already built, may use) + the `proves` assertion the lead
will run.** Build order (§8) is the order to hand these out: params → map →
power → net → sim+agents (the core loop) → inspector → econ/tools/ui → polish.
