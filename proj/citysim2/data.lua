-- data.lua : static lookup tables shared by sim + ui. packed with split()
-- so each is ~2 tokens instead of one-per-entry (see LEARNINGS).

-- resources (the things that flow over networks):
--   1 labor  2 jobs  3 goods  4 power  5 coverage
res_name=split"labor,jobs,goods,power,coverage"
-- index 6 (red) is the fire engine's colour (not a real resource, just reuses
-- the agent colour table). 1 R-green 2 C-blue 3 I-orange 4 yellow 5 pink 6 red.
res_col=split"11,12,9,10,14,8"

-- channel: 1 = travels as a VISIBLE road trip (an agent + congestion);
--          0 = resolved abstractly over its network (no car, no congestion).
-- power(4) and coverage(5) are off-road -> the implicit "reserved lanes".
res_road=split"1,1,1,0,0"

-- 0x8000 user-RAM data planes (per-tile bytes, index = x + y*p.grid).
-- one base address per plane; helpers live in map.lua. (DESIGN s7 / manual 6.7)
pl_elev=0x8000      -- elevation 0..255
pl_comp=0x8400      -- road/power network component id
pl_cap=0x8800       -- building capacity N (caps at 255)
pl_fill=0x8c00      -- capacity currently served
pl_cong=0x9000      -- agents currently on this road tile (saturates at 255)
pl_need=0x9400      -- packed need bits | offer bits
pl_val=0x9800       -- desirability 0..255 (128 neutral); land value
pl_fire=0x9c00      -- burn ticks remaining (>0 = on fire); 0 = not burning
pl_cov=0xa000       -- service coverage (>0 = a station/park serves this tile)
pl_wire=0xa400      -- power-line overlay (>0 = a wire crosses this road tile)
pl_grace=0xa800     -- "settling" evals left for a new building before it starves
pl_pow=0xac00       -- power-network component id per carrier tile (supply/demand)
pl_chg=0xb000       -- per-building power battery charge (0..pwr_cap)
pl_pdist=0xb400     -- power-network distance to the nearest plant (hops; 255=none)
