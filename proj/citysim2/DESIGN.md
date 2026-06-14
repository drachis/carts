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

- **8192-token ceiling is the design budget.** Plan the **cart split up front**:
  - **cart 0 (sim):** params, map, net, power, sim (broadcast/offer/match), econ.
  - **cart 1 (shell):** render, hud, inspector, input, gen_gfx art.
  - Share state through **map RAM** + a fixed memory region; cart 1 `reload`s the
    sim cart's data, or use `cstore`/`reload` hand-offs. Validate the split early
    with a token spike before building UI polish.
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

## 6. Module layout & token budgets (targets, cart 0 unless noted)

| module        | owns                                                      | ~budget |
|---------------|-----------------------------------------------------------|---------|
| params        | all tuning constants                                      | 150     |
| map           | grid in map RAM, tile helpers, terrain gen, BFS over road | 700     |
| net           | road **component labeling** + per-component offer index    | 500     |
| power         | power flood-fill reachability + capacity budget           | 300     |
| sim           | needs/offers, the broadcast→match→contract tick, growth/decay | 1200|
| agents        | pooled trip agents realizing contracts (`path_step`)      | 500     |
| econ          | taxes, upkeep, money (in $k), time                        | 350     |
| render (c1)   | world draw, agents, overlays                              | 700     |
| hud+inspector (c1) | hud, tool menu, minimap, **tile inspector panel**    | 900     |
| input/tools (c1)   | cursor, zoning, building, bulldoze                    | 700     |

Keep cart 0 (sim) well under 8192 so the simulation can deepen without a UI tax.

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
8. **Cart split** when cart 0 approaches budget; move render/ui/inspector to
   cart 1.
9. **Polish:** day/night, disasters, congestion visuals, sound.

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
  visible traffic or an inspectable cause; aggregate the rest.
- **Single-cart MVP or split from the start?** Likely single-cart through step 4,
  then split — but keep the module boundaries clean so the split is mechanical.
