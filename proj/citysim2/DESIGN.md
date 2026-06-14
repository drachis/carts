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

## 3. The update — event-driven

The machine can afford a richer update than citysim's per-frame sampling, and
**events buy legibility**: every state change is a message one tile sends another,
so the event stream *is* the explanation. (Resolves the old "sampling vs.
event-driven" question — event-driven wins.)

The loop **drains an event queue** each tick. An event is a small record
`{k=type, x, y, ...payload}` scheduled for a future tick; its handler mutates
state (byte planes + Lua) and **schedules follow-up events**. Nothing polls —
work happens only where something changed.

- **Scheduling is a timewheel**, not a sorted heap: a ring of buckets
  `evq[t % H]`, O(1) to schedule and drain, cheap in tokens. `schedule(dt, ev)`
  drops `ev` in bucket `(now+dt) % H`; each tick processes `evq[now % H]` and
  clears it. Horizon `H` covers the longest delay (commute, ttl); longer waits
  just re-arm.
- **A requests, B updates from the event.** A tile's recurring `eval` event finds
  an unmet need, queries the offer index (§2), matches **B**, and **schedules an
  `arrive` event at B** `commute` ticks out (carrying `from=A`). When `arrive`
  fires, B's handler fills the job / counts the resident and A is satisfied — the
  agent you watched driving *was* that pending event, made visible.
- **Timers are just scheduled events** — no per-frame countdowns: fire `spread`
  at +delay, contract `expire` at +ttl, commute `arrive`, and each tile's own
  periodic `eval` re-broadcast. **Decay** = an `eval` that finds the need still
  unmet and downgrades the tile, then re-arms.
- **The examples are all one mechanism** — a type + a handler: `arrive@work`,
  `student@school`, `ignite → dispatch wrecking crew → arrive → clear`. Adding a
  behavior = adding an event type to the dispatch table.

Bootstrap: on init/load, schedule a **staggered `eval` for every developed tile**;
they self-perpetuate from there (each `eval` re-arms its own next one). Guard
against storms: cap cascades processed per tick, and hold **at most one pending
`eval` per tile**. Agents stay pooled + capped (`agent_cap`); visible traffic ≈
in-flight `arrive` events. Power is just a channel: "powered" = reachable from a
plant with capacity (offer index over the power network), no special case.

---

## 4. Emergence & inspectability (the point)

- **RCI meter is derived:** demand.r = normalized count of unmet *labor offers*
  (residents who can't find jobs) vs unmet *labor needs* (businesses short of
  workers), etc. The bars report the sim; they don't drive it.
- **Land value / desirability emerges:** desirability of a tile = how cheaply its
  needs get matched (short commutes, served by coverage, low congestion/pollution
  nearby). High desirability → faster growth & higher density caps. No separate
  hand-tuned land-value pass required — it falls out of match costs.
- **Inspector is a first-class feature, and events make it nearly free.** Click
  any tile → panel shows its open needs, current contracts (who it's matched with
  + commute cost), agents on the road, served/unserved status — **and a short log
  of its recent events** (`ignited → crew dispatched → arrived → cleared`). Since
  every change already arrives as an event, keeping a tiny per-tile ring of the
  last few is the whole feature: the sim literally narrates its own causality. If
  we can't show why a tile is decaying, the model is wrong.

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
- **The match/route/agent engine is substrate-agnostic.** Its network and
  resource set are *parameters* — road, power, or the open grid — and the economy
  (money, contracts, growth) is a separate layer that *consumes* matches. This is
  what lets one engine drive terrain gen, traffic, freight, and power, and lets
  terrain (§6) reuse the core loop before roads exist. Write the pipeline this way
  from the first commit; don't bake "road" into it.
- **State lives in map RAM** (sprite id = tile state). A **32×32 city** uses 1024
  of the dedicated map region's 4096 bytes, leaving room for **three 32×32
  byte-"planes"** of dense per-tile sim data (elevation, component id, packed
  need/offer) accessed by `mget/mset` — no Lua tables, no GC, and **saved for
  free** by the one `cstore`/`reload` of `0x2000–0x2fff`. Because tile + 3 planes
  fit the dedicated region, the shared bank stays free for night sprites (§6, §7).
  Rich/sparse data (contracts, offer index, agents) stays in Lua. **32×32 is the
  load-bearing size** here — a bigger grid trades away planes or the sprite bank.
- **Scaled units from day one.** Money, population, goods volumes — anything that
  can exceed ~32000 — stored in `k` units (16.16 fixed-point flips sign past
  32767). Abbreviate on display (`mfmt`-style).
- **Data tables via `split"a,b,c"`**; flags via byte-form `fset(n,bitfield)`.
- **Art via a `gen_gfx.py`-style pipeline** — zero code tokens, reproducible.
- **Globals are the API; prefix privates** (`sim_`, `net_`, `pw_`, `ag_`, `ui_`).
- One `params` table (`p`) for every constant; never shadow it.

---

## 6. Single-cart token budget

Estimates are **grounded in citysim's measured per-module costs**. For reference:
map 1638, tools 1297, disaster 1101, traffic 899, ui 860, growth 469, network
307, econ 288, power 249, savegame 233, effects 220, achievements 212, params
170, daynight 163, landval 159 → ~8157 in the cart.

Three structural decisions shape this budget (see notes below the table):
1. **"map" is split.** citysim's 1638-token map was a kitchen sink (grid +
   terrain + render + camera). Here those are separate units so map-core is ~550.
2. **Power and econ are not bespoke subsystems** — they fall out of the agent/
   market core. Power is just a resource on the power channel (the same offer
   index that matches labor matches power); money emerges as accounting over
   contracts. So no 250-token power flood + 300-token econ; a thin econ remains
   only for the player-facing money/tax/time.
3. **sim and ui share a data layer.** A `res`/tile metadata table drives both
   matching and display; the inspector is a generic renderer of `tile_info(x,y)`,
   not bespoke logic. Adding a resource touches data, not render code.

These are **generous targets** (build rich, trim if a system overruns), with a
**10% reserve (~820)** held back for polish + contingency — not the big cushion
from before. If a system runs over, iterate it down rather than spending reserve.

| system                  | est. | notes                                                |
|-------------------------|-----:|------------------------------------------------------|
| params                  |  150 | all tuning constants                                 |
| data: `res` + tile metadata (shared sim↔ui) |  100 | resource id→name/colour/channel; drives matching AND labels |
| map core: grid in RAM, tile/zone helpers, autotile (`nmask`), camera | 550 | the cohesive "map" — no terrain/render/bfs |
| terrain: noise heightmap → threshold; rivers by **reusing the match/agent pipeline** over the open grid (noise-seeded source/sink goals) | 150 | gen-specific code = noise seed + paint; routing reused from sim/agents |
| router: **weighted** (cost-aware) path + `flood` reach | 300 | one weighted search serves meandering rivers AND commute/congestion cost (citysim `tr_path` was plain BFS ~200) |
| net: road **+ power** component labels + per-component offer index | 500 | power is just another channel |
| **sim core: event loop (timewheel + dispatch) → broadcast→match→contract, grow/decay; power & money as resources** | **1800** | the heart; event-driven (§3). Replaces sampling + per-frame countdowns, so not purely additive — but the richer update draws on the reserve |
| **agents: pooled trips realizing contracts, draw** | **550** | citysim traffic minus the BFS |
| econ (thin): money ($k), tax policy, time — revenue emerges from contracts | 200 | mostly accounting + UI, not a sim |
| tools/input: cursor, zone, build, bulldoze, `tool_put` | 1000 | citysim tools 1297, trimmed |
| render: `draw_world`, tiles, agents, overlays | 550 | split out of citysim's map |
| hud + minimap                  |  500 | citysim hud+minimap ~550                  |
| **inspector: generic `tile_info` renderer** | **300** | data-driven; reads the shared layer |
| fx / particles                 |  200 | citysim effects 220                       |
| save / load (one `cstore` of map RAM) | 220 | citysim savegame 233                 |
| day / night: **sprite-bank swap** (art-driven) |  50 | needs a free sprite bank — see note     |
| sfx / music hooks (art via gen_gfx = 0 code) | 60 | citysim ~                       |
| main glue (`_init`/`_update`/`_draw`) | 150 | wires modules; owns the 3 callbacks   |
| **systems subtotal**           | **~7330** |                                                 |
| **reserve (~10%)**             | **~820** | polish + contingency; iterate systems down if over |
| **total target**               | **~8150 / 8192** | ~40 hard margin (tightening — trim a system before adding) |

**Terrain is generated, period — no authoring.** A small generator makes
hand-authored maps unnecessary. The base, DF-style: build an **elevation field**
with cheap fractal noise — **fBm value noise** or **diamond-square** (wants a
`2^n+1` grid, so 33×33 suits a 32-tile map) — then **threshold** it into
sea / coast / land / mountain. The elevation field is the point: the **sim reads
it** (waterfront desirable, slopes costlier), and it gives rivers a gradient and
moisture a source. Map-core (~550) excludes this; the generator is its own
~150-token unit.

**Generation reuses the market — seed goals with noise, then route them.**
Earlier this doc claimed gen could only borrow low-level primitives because
"there's no road network at gen time." Too timid: **seed the empty grid with
source/sink goals from noise** (springs *offer* drainage; the sea / map edges
*need* it), then run the *same broadcast→match→agent-path pipeline* with the
**open grid as a noise-weighted network** — per-tile routing cost comes from the
noise/elevation field, so the carved path **meanders**. (Route over a *flat*,
uniform grid and you get a dead-straight rectilinear path — the noise weighting is
exactly what turns a shortest-path into a river.) Each spring matches its sea and
that wandering path **is** the river; ridges and erosion can be seeded the same
way. Terrain
thus **dogfoods and validates the core loop before any roads exist** — the best
possible early test of the engine. What's reused: the substrate-agnostic
**match + route + agent** layer. What isn't: the economic bookkeeping (money, ttl
contracts, growth/decay) — gen is one-shot. (This is the clean split in §5: the
pipeline takes its network + resources as *parameters*; the economy consumes its
output.)

Build note: MVP terrain can be the plain noise heightmap + a downhill-walker
river to unblock early steps, then swap the carving (and later ridges/erosion,
**Voronoi region patches** — Voronoi is for regions, not elevation) onto the
reused pipeline once it exists. citysim's bloat (tributary, full-grid highland
scan, lone mesa) is what we don't re-add.

**Day/night as a sprite swap.** With a smaller map (e.g. 32×32 uses only map rows
0–31), the shared sprite bank (sprites 128–255 / map rows 32–63) is **free**. So
day/night can be a **spritesheet bank swap** (a cheap `memcpy`/`reload`, ~50
tokens of code) with **hand-authored night sprites** (lit windows, warm glows) —
art costs zero code tokens via `gen_gfx`. This replaces citysim's per-frame
palette manipulation and, more importantly, lets us **style each tile per state**
once the game plays well. Cost is sprite *space*, which the smaller map frees.

**Risk flags.** The sim core (1800) and tools (1000) are the likely overruns, and
the **event loop tightens the margin** (~40 hard + the 820 reserve). The machine
can afford the CPU; tokens are the constraint. Keep it lean: a timewheel (not a
heap), a small integer-keyed dispatch table, per-building contracts, the offer
index doing the matching (lookup + nearest, not per-need search), and few tile
variants. Re-measure with `pico8 -x` (authoritative) after each addition — not
`count_tokens.py` — and trim a system before growing the cart.

---

## 7. Key data structures

**Memory layout — sim data lives in spare map RAM ("data planes").** A map cell
is just an 8-bit value (0–255); `map()` only draws the cells we ask it to, so the
rest is free byte storage. With a **32×32 city**, the tile grid is 1024 of the
dedicated map region's 4096 bytes (`0x2000–0x2fff`), leaving **3072 bytes = three
32×32 byte-planes** for dense per-tile sim fields:

```
0x2000 map region (128 x 32):
  cols  0..31 : tile plane     -- the map we draw (sprite id = tile state)
  cols 32..63 : plane A = elev(x,y)   = mget(32+x,y)   -- elevation 0..255
  cols 64..95 : plane B = comp(x,y)   = mget(64+x,y)   -- road/power component id
  cols 96..127: plane C = noff(x,y)   = mget(96+x,y)   -- packed need/offer bits
```

Because tile + 3 planes fit the *dedicated* region, the **shared bank
`0x1000–0x1fff` (sprites 128–255) stays free for the day/night night-sprites** —
both, no conflict. A bigger city or a 4th plane starts eating that bank: an
explicit trade. **Save/load is free:** one `cstore`/`reload` of `0x2000–0x2fff`
carries the city *and* all planes (citysim's trick, extended to the sim). Planes
are 8-bit; a field needing more range splits across two.

```lua
-- DENSE per-tile scalar fields -> map-RAM byte planes (mget/mset, 0..255):
--   elev(x,y), comp(x,y) [component id], noff(x,y) [need bits | offer bits],
--   moisture/desirability if a 4th plane is worth the shared bank.
-- no Lua tables, no GC, saved for free.

-- SPARSE / RICH structures -> Lua tables (don't fit a byte plane):
ctr     = { [k] = {res,from,to,cost,ttl}, ... }   -- active contracts per tile
roffer  = { [compid] = { res -> list of supplier tiles } }  -- the offer index
agents  = { {path,i,px,py,res,from,to,ttl,col}, ... }       -- pooled, capped

-- TRANSIENT event state (Lua; not saved — rebuilt by the bootstrap on load):
evq     = { [t % H] = { {k,x,y,...}, ... } }   -- timewheel of scheduled events
elog[k] = small ring of recent event types on tile k   -- powers the inspector
```

The **offer index per component** is the trick that keeps matching cheap:
broadcasting a need = `roffer[comp(x,y)][res]`, pick the nearest with capacity —
no fresh search per need. Component id comes straight from a byte plane.

---

## 8. Build order (MVP first, polish last)

1. **Skeleton:** map grid in RAM, `router` (weighted path + `flood`), and a **plain noise
   heightmap → threshold** with a simple downhill-walker river. (Plain so terrain
   doesn't block on the pipeline that doesn't exist yet.) Headless-test grid +
   flood + that an `elev` field exists.
2. **Engine:** the **event loop** (timewheel `schedule`/drain) + the substrate-
   agnostic match/route/agent pipeline with the **network passed in** (start with
   the open grid), plus `net` component labeling + the per-component offer index.
   Test "reachable suppliers" on a hand map and that a scheduled event fires on
   time.
3. **Reroute the river through the engine:** noise-seed source/sink goals and
   carve the river by routing them over the open grid — the first real exercise of
   the engine, before any roads. (Optional but high-value dogfood.)
4. **One need end-to-end:** residential **labor → jobs** over roads. Broadcast,
   match, contract, spawn a commuter agent that drives the path; grow when
   matched, decay when not. *Proof of concept — get it alive before anything else.*
5. **Inspector:** click a tile, see needs/contracts/agents. Build it here, not last.
6. **Goods chain:** industry → commercial → residential on the same engine
   (freight agents).
7. **Gating:** power (same engine, power channel) + service coverage block growth.
8. **Derived RCI + econ:** demand meter from unmet broadcasts; taxes; money in $k.
9. **Polish, deliberately:** day/night (sprite swap), congestion visuals, sound,
   then a lean disaster — each drawn from the ~820 reserve (§6), re-measuring with
   `pico8 -x` after every addition. When the cart tightens, lean out a system (§6
   risk flags) rather than dropping polish.

Stop and playtest after step 4 and step 5 — if the commuter loop isn't legible
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

- **Sampling vs. event-driven — DECIDED: event-driven** (§3). Remaining knobs:
  timewheel horizon `H` (max direct delay before re-arming), the per-tick cascade
  cap (storm guard), and the `eval` re-arm interval. The event queue is transient
  — *not* saved; the bootstrap reschedules a staggered `eval` per developed tile
  on load.
- **Contract granularity:** one contract per building, or per unit of capacity?
  Per-building is far cheaper and probably enough at this resolution.
- **Congestion model:** per-road-tile agent count feeding back into commute cost
  — how cheaply can we track it without a per-tile counter every frame?
- **How much aggregation is invisible?** Simulate individually only what becomes
  visible traffic or an inspectable cause; aggregate the rest. This is also the
  main token lever — the more we can aggregate without the player noticing, the
  more sim depth fits in 8k.
- **Where does the polish reserve go first?** Only ~820 is held back (10%), so
  spend it deliberately — likely congestion visuals (they reinforce the core
  loop) before disasters or sound. If it's not enough, trim a system, don't grow
  the cart.

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
| data (100) | `res` (id→name/colour/channel), tile-class table | — | lookups correct |
| map (550) | `tile`/`set_tile`/`is_road`/`is_zone`/`zone_kind`/`zone_density`, `neighbors4`, `nmask`, `update_camera` | data, `p` | autotile mask; tile helpers |
| terrain (150) | `gen_terrain` — noise heightmap → threshold; noise-seed source/sink goals + drive the match/agent pipeline over the **noise-weighted** open grid to carve meandering rivers; `elev(x,y)` | map, router, sim/agents | elevation field present; a seeded spring carves a *meandering* river to the sea |
| router (300) | `path(from,to,costfn)` — **weighted** search; `flood(x,y,pred)` | map | weighted path meanders on a noisy cost field; straight on flat cost; nil when disconnected |
| net (500) | `update_net`, `reach_offers(x,y,res)`, `powered(x,y)`, `rcomp` | map, router, `p` | reachable suppliers + power reach correct on a hand map |
| **sim (1800)** | `update_sim` (drains the event queue), `schedule(dt,ev)`, `ctr`, `elog`, `demand`, `pop`, `jobs`, `tile_info(x,y)` | net, router, map, agents, data, `p` | a scheduled event fires on time; labor↔jobs `arrive` forms a contract; unmet `eval` decays; power gates growth |
| **agents (550)** | `spawn_agent(from,to,res)`, `update_agents`, `agents` | router, map, `p` | a spawned trip drives source→dest staying on roads |
| econ (200) | `money` ($k), `mfmt`, `try_spend`, `tax_rate`, `update_econ` | sim, `p` | `mfmt`; debt ceiling; no sign-flip at scale |
| tools (1000) | `cur`, `tool`, `update_tools`, `apply_tool`, `tool_put` | map, econ, sim, `p` | place / zone / bulldoze transitions |
| render (550) | `draw_world`, `draw_agents`, overlays | map, agents, net, data | (lead smoke-checks; logic tested in sources) |
| hud (500) | `draw_hud`, `draw_minimap` | reads state, data | demand bars; minimap colours |
| **inspector (300)** | `draw_inspector` | sim `tile_info`, data | renders a tile's needs/contracts/agents |
| fx (200) | `add_fx`, `update_fx`, `draw_fx` | — | particles spawn + expire |
| save (220) | `save_city`, `load_city` | map, econ | scalars + grid restore via one `cstore`/`reload` |
| daynight (50) | `dn_apply` (sprite-bank swap by phase) | — (authored art) | swaps bank at dusk/dawn |
| main glue (150) | `_init`/`_update`/`_draw` | every `init_*`/`update_*`/`draw_*` | — |

Note: no standalone `power` unit — `net.powered(x,y)` is the same offer-index
machinery over the power channel. `econ` is thin (player-facing money/tax/time);
revenue and "demand" are read out of `sim`, not computed by a separate model.

A complete cold-start task = **the row's file + budget + its `defines` (must
provide) + its `calls` (already built, may use) + the `proves` assertion the lead
will run.** Build order (§8) is the order to hand these out: params → map →
power → net → sim+agents (the core loop) → inspector → econ/tools/ui → polish.
