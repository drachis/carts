# citysim2 — ideas & backlog

Running list of things that could make the game richer once the base loop is fun.
Nothing here is committed; it's a parking lot. Tag with a rough cost feel
(cheap / medium / spendy) and whether it leans on the polish reserve.

## Carried-over feedback from citysim (the predecessor)
The final citysim was "fun and rewarding, playable and entertaining." Two bugs
the player hit — make sure citysim2 doesn't repeat them:
- **Subtracting numbers didn't display right.** Likely the `$k` money formatting
  (`mfmt`) on negatives, or a demand subtraction shown raw. → In citysim2, unit-
  test signed formatting and any on-screen subtraction (the `econ`/`hud` `proves`).
- **The map overview panel had no background.** The minimap summary text drew over
  the world with no backing rect. → In citysim2, every HUD/overlay panel draws an
  opaque (or dithered) background first. Bake into the `hud`/`inspector` contract.

## Mechanics that fit the agent/market core cheaply
- **Inspector "follow an agent"** — click a car, watch its trip + see its contract
  endpoints highlight. Reuses elog + agents; strong legibility payoff. (cheap)
- **Demand/desirability heat overlay** from match cost (already computed). (cheap)
- **Mixed-use / upgrade chains** — a tile that satisfies more needs upgrades to a
  denser sprite; pure data + the existing grow path. (medium)
- **Freight as its own visible trip color** (goods vs commuters) — one res_col
  lookup, already in data.lua. (cheap)
- **Strikes / shortages surfaced as events** ("no workers reached factory") in the
  ticker, straight from unmet `eval`s. (cheap)

## Bigger swings (post-launch maybe)
- **Regions via Voronoi** — districts/biomes as a second layer (DESIGN notes it).
- **Transit** — a second network channel (rail/bus) the router treats as a
  cheaper edge; agents prefer it; congestion still applies. (spendy)
- **Disasters** as event chains (fire→dispatch→clear) — citysim proved the feel;
  lean version ~500 tokens, draws the reserve. (spendy — reserve)
- **Day/night styling** via the sprite-bank swap once art time exists. (medium)
- **Scenario seeds / challenges** for itch.io replayability. (medium)

## itch.io launch checklist (later)
- Playtest for "feels correct" at ~50 and ~500 pop; tune `p.show`.
- Title/menu screen, brief how-to, a couple of sfx.
- Web export; verify cart runs at full 8192 with margin.
