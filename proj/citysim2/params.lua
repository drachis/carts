-- params.lua : every tuning knob lives in the global p. never shadow it.
-- keep this lean; modules add their own keys as they land.
p={
 grid=32,            -- city is grid x grid tiles (<=32 rows frees the sprite bank)

 -- event loop (sim, see DESIGN s3)
 evt_h=256,          -- timewheel horizon in ticks
 evt_cap=96,         -- events processed per tick (storm guard)
 eval_iv=90,         -- ticks between a tile re-evaluating its needs
 decay_miss=4,       -- consecutive unmet evals before a tile downgrades

 -- zone economy (capacity per density step)
 r_per=4,            -- residents per residential density
 c_per=3,            -- jobs per commercial density
 i_per=4,            -- jobs per industrial density
 grow_rate=0.25,     -- chance a fully-served zone densifies on an eval
 decay_rate=0.15,    -- chance a starved zone downgrades on an eval

 -- agents / visibility (the lively-city knob, DESIGN s10)
 agent_cap=80,       -- max live visible agents
 show=1,             -- visible cars per filled capacity unit (1=all; lower=sample)
 trip_life=600,      -- ticks before a stuck agent gives up

 -- congestion (router cost feedback, DESIGN s10)
 cong_k=3,           -- router cost added per agent sharing a road tile

 -- economy (money in THOUSANDS of dollars, see LEARNINGS)
 start_money=2,      -- $2k
 tax_rate=2,         -- tax points; income scales with this
 month_frames=600,   -- frames per month (20s @ 30fps)
 road_up=1,          -- $ per road tile per month (upkeep, in dollars)
 job_tax=0.5,        -- jobs taxed at this fraction of the pop rate
 debt_k=-1,          -- debt floor in $k (try_spend won't go below)
 money_cap=32000,    -- $k ceiling (keeps 16.16 fixed-point from flipping)
 start_year=1950,

 -- demand / census (derived rci meter, sim.lua)
 census_iv=30,       -- ticks between census + demand recompute
 dem_rdiv=32,        -- residential demand divisor
 dem_div=24,         -- commercial/industrial demand divisor
 dem_c=0.5,          -- target jobs per resident (commercial)
 dem_i=0.7,          -- target jobs per resident (industrial)

 -- terrain (terrain.lua)
 sea_pct=0.14,       -- fraction of the map below sea level (water)
 mtn_pct=0.9,        -- elevation percentile above which is mountain
 terr_blur=2,        -- heightmap smoothing passes
 river_jit=28,       -- river meander jitter

 -- desirability / land value (landval.lua); 128 = neutral
 val_rad=3,          -- influence radius (tiles) for water/pollution
 val_water=6,        -- desirability per nearby water tile (waterfront +)
 val_pol=10,         -- desirability lost per nearby polluter (industry/plant)
 val_cong=2,         -- desirability lost per agent on nearby roads
 val_park=24,        -- desirability per nearby park (service +)

 -- render (render.lua)
 cong_show=2,        -- agents on a road before it reads as congested

 day_frames=1800,    -- full day/night cycle (60s @ 30fps)
}

-- build costs in DOLLARS (charged via econ.try_spend, which scales to $k)
cost={road=10,power=5,plant=150,zone=50,dozer=2}
