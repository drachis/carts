# citysim — learnings & research (project retrospective)

Written at the close of **citysim** (a PICO-8 SimCity-2000-style RCI builder,
`proj/citysim`, ~19 commits over rounds 1–10). The project worked and taught a
lot, but it repeatedly hit PICO-8's 8192-token code ceiling as features piled
up. This document captures what we learned and the SimCity research, to seed a
successor — **citysim2** — built around an agent/market simulation instead of a
scripted one.

There is also an earlier, abandoned agent prototype at
`explorations/city-sim/` (2024: `agents.lua`, `demand.lua`, `pathfinding.lua`).
citysim2 is really the third pass at this idea — the lineage is worth keeping.

---

## 1. Why we're closing citysim

- **We hit the token wall, over and over.** The cart sat at ~8157/8192 with the
  core game. Every new system (fire engines, garbage truck, richer smoke, money
  overflow fix, minimap views) forced an optimization scramble to claw back
  30–250 tokens. That tax is now the dominant cost of any change.
- **We were fixing edge cases, not improving the simulation.** Slower fire
  spread, decay tuning, "cars shouldn't commute to rubble", drag-build skip,
  bulldoze-restore — all real, but whack-a-mole on a fundamentally *scripted*
  sim (random growth sampling + demand formulas). The interesting part —
  emergent behavior from agents on the road/power network — was underdeveloped
  because there was no budget left for it.
- **Conclusion:** a better *simulation core* is worth more than more patches.
  Start fresh with that core as the foundation, carrying forward the hard-won
  PICO-8 craft below.

---

## 2. PICO-8 technical learnings (carry all of these forward)

### Token budget is the real constraint
- **8192 tokens, hard.** PICO-8's own counter is the **sole authority**; a cart
  may use the full 8192 and still run at 100%. Check with `pico8 -x cart.p8`:
  it prints `program too large N/8192` only when **over**; under budget it just
  runs (kill it after a few seconds).
- **Token rules** (from `pico-8_manual.txt`): each word or operator = 1; a
  bracket *pair* = 1; a string = 1. Free: commas, periods, colons, semicolons,
  `local`, `end`, comments. `..` = 1. Negative literals fold into the number.
- `count_tokens.py` is a fast **approximation** (within ~6 tokens, tends to
  *under*-count). Use it to iterate; trust PICO-8 for the final call. Do **not**
  pad against a fake lower ceiling — but do leave real headroom for the next
  feature.

### Token-savers that actually moved the needle
- **`split"a,b,c"` for data tables.** Returns a table; numeric tokens
  auto-convert to numbers. A 16-element lookup drops from ~17 tokens to ~2.
  Used for colour tables, month names, tile-name strings, `zone_base`, etc.
- **Byte-form `fset(n, bitfield)`** (omit the flag index to set all 8 flags at
  once: 1=road bit0, 6=zone bits1+2, 4=conducts bit2, 5=crossing, 8=buildable).
  Halves the flag-setup boilerplate in test carts.
- **Factor repeated structure into helpers**: one `nmask(x,y,pred)` for the
  road/wire autotile bitmask; one `find_tile(pred)` scan shared by all agent
  dispatch; one `path_step` shared by every vehicle. Generalizing the fire
  engine + garbage truck into a single "service vehicle" (colour + target +
  arrival-action are the only differences) was leaner than two systems.
- **`#include` shares one global scope** (textual inclusion). A top-level
  `local` is only visible to files *after* it in include order — plan ordering,
  or use globals for cross-module helpers.

### Numbers are 16.16 fixed-point — plan for it from day one
- Range is roughly **±32767.99**. Integers above 32767 **flip sign**.
- **Money** overflowed (taxes at the cap flipped +$32k ↔ −$32k). Fix: store
  money in **thousands of dollars**; keep costs/income in dollars and scale
  ÷1000 at the econ boundary; format with a `mfmt` that shows dollars / k / m.
- **Population will hit the same wall** for a large enough city (pop is just a
  number too). On a 48×48 grid it's borderline, but in citysim2 **store any
  potentially-large quantity in scaled units (k) from the start**, and abbreviate
  on display. Don't wait for the overflow bug.
- Beware fixed-point **equality** in tests: `0.5 - 0.1 == 0.4` is not reliable.
  Assert against the *same* expression (`money == 1 - cost.blast/1000`) or use
  values that are exact in binary (halves, whole numbers).

### Map RAM is your state store (and your save file)
- The grid lives in **PICO-8 map memory**: `mget/mset`, and **the sprite id IS
  the tile state**. No parallel grid array. Encodes zone kind+density, roads
  (autotile mask), rubble type, etc. directly — survives save/load for free.
- **Scalar state rides in unused map cells** (e.g. row 0, x≥49, outside the
  48×48 play area). One `cstore`/`reload` of the map region saves/loads the
  whole game — no serialization code.
- Map rows 32–63 overlap sprite banks 128–255; if you don't draw those sprites,
  those map rows are free for data. Know which banks/rows you're actually using.
- **Multicart** is the escape hatch we never took: a second cart gives another
  ~8192 tokens of code + its own banks. If citysim2 will keep growing,
  **design the cart split up front** (e.g. sim core in cart 0, UI/render in
  cart 1) instead of fighting the ceiling per-feature.

### Art/sound out of the token budget
- `gen_gfx.py` authors sprites, sprite flags (`__gff__`), sfx and music in
  Python and **patches the `.p8`** in place. Art costs **zero code tokens**, is
  diff-able, and is reproducible. Keep this pattern — it was one of the best
  decisions in citysim.

---

## 3. Testing learnings

- **Trust the engine.** Anything in `pico-8_manual.txt` — `spr`, `map`, `split`,
  `fset`, fixed-point math, `cstore` — is rock solid. The one caveat is **raw
  memory poking** (`poke`/`peek` into hardware/RAM), which can get spicy. Do
  **not** write tests that prove PICO-8 works; if a documented primitive
  misbehaves we have far bigger problems than a red assert.
- **Test our logic, not "does it crash."** We deleted a "ui draws without error"
  smoke test — it only verified that calling documented draw functions doesn't
  throw, i.e. it tested PICO-8, not us. Removing it also let the test cart drop
  `ui.lua` (~940 tokens). Prefer asserting a *computed result* over asserting
  "it ran".
- **Test carts hit 8192 too.** We burned real time keeping the test suite under
  budget (the full suite includes nearly every module). Better approaches for
  citysim2:
  - **Split tests per system** so each cart includes only its module + deps and
    stays small. Each system should be independently testable.
  - **Use a saved minimal city fixture** (`reload` a tiny prebuilt `.p8` map)
    instead of building the test world in-code. Setup is most of the test
    tokens; a fixture moves that into map data (free) and makes tests read like
    assertions, not world-construction.
- Headless run: `& "…/pico8.exe" -x tests/test_x.p8`, asserts via `printh`,
  end with a `pass`/`fail` summary line the lead greps.

---

## 4. Architecture learnings

- **A written module contract pays off.** `DESIGN.md` defined sprite ids, flags,
  shared globals, per-module budgets, and the "call these helpers, don't
  reinvent" rules. It let work be split into single-file modules (some written
  by sub-agents) without collisions. Keep this for citysim2.
- **Globals are the API; prefix module-private helpers** (`pw_`, `gr_`, `ec_`,
  `dz_`, `tr_`) to avoid clashes in the shared scope.
- **Agents on the network were the soul of the game.** Traffic, fire engines,
  and the wrecking crew all reused one BFS (`tr_path`) over road tiles and one
  `path_step` mover. Seeing trucks actually *drive* the roads is what made it
  feel alive. citysim2 should lean **all the way** into this.
- **One tuning file** (`params.lua`, global `p`) for every constant — never
  shadow it with a local. Made balancing painless.

---

## 5. Game-design / simulation learnings

What worked, and the formulas we landed on (in `growth.lua` / `landval.lua`):

- **RCI demand** from simple balances, clamped to [−1, 1]:
  - `demand.r = (jobs + 16 − pop)/32 − taxPenalty`
  - `demand.c = (pop·0.5 − commercialJobs)/24 − taxPenalty`
  - `demand.i = (pop·0.7 − industrialJobs)/24 − taxPenalty`
  - tax penalty = `(tax−2)·k`, plus a debt penalty while in the red.
- **Growth gating:** a zone densifies only with **power + road access + a
  network match** (`net_ok`: residential needs nearby jobs; commercial needs
  residents + industry; industrial needs residents). Density-0 plots grow 2×
  faster to fill quickly; growth probability scales with **land value**.
- **Land value = desirability ≈ inverse pollution:** parks/services raise it,
  industry/plants lower it; it feeds growth odds and doubles as the "pollution"
  map view. A cheap proxy that read well.
- **Decay/abandonment** on loss of power or sustained negative demand — power
  loss decays faster. Buildings going dark is good feedback.
- **Day/night commute waves** (R→C/I at dawn, back at dusk) plus daytime
  errand/delivery trips made the road network visibly purposeful.
- **Fire** as the disaster: spread ramps from a low to high probability over
  time, with a delay before the first spread so engines can respond; engines
  suppress burn + spread while spraying.

The gap: all of this is **driven by formulas and random sampling**, not by the
agents. Demand is computed top-down and growth is rolled on random tiles. The
agents (cars) are a *consequence* of state, not a *cause* of it. That's the
thing to invert in citysim2.

---

## 6. citysim2 — the pitch (agent/market simulation)

The core idea (user's framing, captured verbatim in spirit):

> Zones/buildings **broadcast their need** through the road / power network and
> get back an **offer** to fulfill it. If a need and an offer match, both sides
> **take an action** — spawn a building, dispatch a commuter, ship freight. The
> same broadcast→offer→match logic drives residential, commercial, and
> industrial alike, so the whole economy **bubbles up as visible traffic** and
> can be **inspected** to understand *why* something happened.

Design principles:

1. **Agents are the cause, not the decoration.** A house with workers broadcasts
   "labor available"; a shop broadcasts "jobs available, goods needed". They
   find each other *over the actual network*, and the matched trip *is* the
   commuter you see driving. Demand emerges from unmet/met broadcasts rather
   than a global formula.
2. **Everything travels.** Labor, goods, freight, power, services — model them as
   things that flow over roads/lines. Congestion, distance, and connectivity
   become first-class, the way SimCity 4's trip simulator made them.
3. **Inspectable causality.** Click any tile and see its open needs, its current
   offers/contracts, and the trips it generates. The sim should *explain itself*.
4. **Budget-first construction.** Assume the token ceiling from day one: sim core
   small and pure; rendering/UI in a second cart if needed; data in map RAM and
   `split`-packed tables; quantities in scaled units; tests via saved fixtures.

A minimal viable loop to prototype first (before any art polish):
`broadcast(need) → query network for offers → match best offer → commit
(spawn/move/upgrade) → render the resulting trip`. Get *one* need type
(residential labor → commercial jobs) emerging correctly, then reuse the same
machinery for goods and freight.

---

## 7. Research — SimCity 2000 / SimCity 4 mechanics

Background that motivated the agent approach.

### RCI demand (SimCity 2000 → 4)
- The **RCI meter** shows demand for Residential, Commercial, Industrial as
  positive/negative bars. Zoning where demand is positive yields growth; where
  negative, stagnation/abandonment.
- Demand is interdependent: industry & commerce create jobs that pull in
  residents; residents create demand for commerce; commerce/industry need labor
  and customers. It's a feedback loop, not three independent dials.
- Modifiers: **taxes** (high tax suppresses demand, per-type), **neighbor
  connections** (regional trade in SC4), **education/health** (shifts demand
  from dirty industry toward high-tech / commercial offices), **pollution and
  land value** (push residential away from industry).

### SimCity 4's agent-based engine (the key inspiration)
- SC4 replaced SC2000's aggregate formulas with an **agent simulation**. Sims,
  jobs, goods, and power/water are modeled as **agents that path through the
  network** looking to satisfy a need.
- A residential Sim is "born" needing a **job**; it pathfinds over roads/transit
  to a commercial/industrial building with an opening. **Commute time** (not just
  distance) gates whether the match succeeds — bad connectivity = unfilled jobs =
  abandonment, *emergently*.
- **Freight** agents carry goods from industry to commerce/exports; **power and
  water** propagate as network agents. Traffic you see is the *literal* movement
  of these agents — congestion is real and feeds back into desirability.
- This is exactly the **broadcast → pathfind → match → act** model. The trips are
  the simulation, not a visualization of it. That emergent, legible causality is
  what made SC4 compelling to poke at.

### Supporting systems worth modeling (cheaply) in citysim2
- **Service coverage** (fire/police/school/health) as a radius or
  network-distance falloff that raises desirability and unlocks density.
- **Land value / desirability** as the scalar that growth and Sim "happiness"
  read from — raised by services/parks/views, lowered by pollution/crime/traffic.
- **Density thresholds:** low→medium→high zoning caps; a plot only upgrades when
  demand + desirability + connectivity all clear the next tier.
- **Networks as gating:** no road access or no power = no growth, full stop. Keep
  this — it's cheap and it makes the network matter.

### PICO-8-scale simplifications (so it fits)
- One agent per *trip*, pooled and short-lived, not one per Sim. Broadcast on a
  slow tick; cache matches as short contracts so you're not pathfinding every
  frame.
- Network-distance via the existing BFS over road tiles; treat power as a
  flood-fill reachability set (we already have both).
- Aggregate where the player can't see the difference; simulate individually
  only what becomes *visible traffic* or *inspectable cause*.

---

## 8. Concrete carry-over checklist for citysim2

- [ ] Sim core first: `broadcast → offer → match → act`, one need type end-to-end.
- [ ] Cart split (multicart) decided up front if growth is expected.
- [ ] All large quantities (money, pop, goods) in scaled units + abbreviated UI.
- [ ] `gen_gfx.py`-style asset pipeline (art = zero code tokens).
- [ ] State in map RAM; save/load via one `cstore`/`reload`.
- [ ] `split"…"` data tables; byte-form `fset`; shared `path_step`/BFS for agents.
- [ ] Tests: per-system carts + a saved minimal-city fixture; assert results, not
      "it ran"; trust documented PICO-8 calls.
- [ ] `DESIGN.md` contract + single `params` tuning file from commit one.
- [ ] Inspector UI: click a tile, see its needs/offers/trips — make the sim
      explain itself.
