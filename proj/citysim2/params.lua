-- params.lua : every tuning knob lives in the global p. never shadow it.
-- keep this lean; modules add their own keys as they land.
p={
 grid=32,            -- city is grid x grid tiles (<=32 rows frees the sprite bank)

 -- event loop (sim, see DESIGN s3)
 evt_h=256,          -- timewheel horizon in ticks
 evt_cap=96,         -- events processed per tick (storm guard)
 eval_iv=45,         -- ticks between a tile re-evaluating its needs
 decay_miss=4,       -- consecutive unmet evals before a tile downgrades

 -- zone economy (capacity per density step)
 r_per=4,            -- residents per residential density
 c_per=3,            -- jobs per commercial density
 i_per=4,            -- jobs per industrial density
 grow_rate=0.45,     -- chance a fully-served zone densifies on an eval
 decay_rate=0.15,    -- chance a starved zone downgrades on an eval
 grace=160,          -- evals a NEW building is "settling" before it can starve
                     --   (~1 in-game year; gives agents time to find work)

 -- agents / visibility (the lively-city knob, DESIGN s10)
 agent_cap=80,       -- max live visible agents
 show=1,             -- visible cars per filled capacity unit (1=all; lower=sample)
 trip_life=600,      -- ticks before a stuck agent gives up
 commute_max=12,     -- max tiles to a job/home before a zone won't grow (commute)

 -- congestion (router cost feedback, DESIGN s10)
 cong_k=3,           -- router cost added per agent sharing a road tile
 road_reach=2,       -- a zone reaches a road within this many tiles (chebyshev)

 -- economy (money in THOUSANDS of dollars, see LEARNINGS)
 start_money=2,      -- $2k
 tax_rate=2,         -- tax points; income scales with this
 month_frames=600,   -- frames per month (20s @ 30fps)
 road_up=1,          -- $ per road tile per month (upkeep, in dollars)
 plant_up=8,         -- $ per plant per month; a big plant costs 4x this
 plant_sup=60,       -- power UNITS a plant feeds its network
 bigplant_sup=180,   -- a big plant feeds far more units
 brownout_iv=20,     -- frames between rolling-brownout rotations when over capacity
 -- per-zone draw = (density+1) * kind_draw(time)/10. kind_draw lerps day->night
 -- by day_phase: R sips most at night, C most by day, I steady (R,C,I order).
 pwr_day=split"4,11,9",   -- midday draw x10 per kind
 pwr_night=split"11,4,9", -- midnight draw x10 per kind
 pwr_cap=7,          -- a building's power battery (drains 1 per pwr_iv "hour")
 pwr_pkt=4,          -- energy packet size; grabbed only when there's room for one
 pwr_iv=30,          -- frames per power hour (battery drains/refills on this tick)
 res_dist=6,         -- a delivered packet loses 1 charge per this many tiles from
                     --   the nearest plant (line resistance; far buildings dim first)
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
 dem_seed=16,        -- baseline external R demand (lets an empty city bootstrap)

 -- terrain (terrain.lua)
 sea_pct=0.08,       -- fraction of the map below sea level (water)
 mtn_pct=0.9,        -- elevation percentile above which is mountain
 terr_blur=2,        -- heightmap smoothing passes

 -- desirability / land value (landval.lua); 128 = neutral
 val_rad=3,          -- influence radius (tiles) for water/pollution
 val_water=6,        -- desirability per nearby water tile (waterfront +)
 val_pol=10,         -- desirability lost per nearby polluter (industry/plant)
 val_cong=2,         -- desirability lost per agent on nearby roads
 val_park=24,        -- desirability per nearby park (service +)
 val_div=30,         -- drain 1/val_div of the dirty land-value queue per frame
                     --   (so the backlog always clears within ~val_div frames)

 -- fire / disasters (disaster.lua)
 fire_chance=0.0006, -- per-frame odds a random developed zone ignites
 fire_int=45,        -- frames between a fire's burn ticks
 burn_ttl=6,         -- burn ticks before a tile collapses to rubble
 fire_spread=0.45,   -- odds a burn tick spreads to a neighbour zone
 fire_rad=4,         -- fire-station coverage radius (chebyshev)
 fire_cover=0.12,    -- spread odds inside station coverage (suppressed)
 wreck_delay=120,    -- frames after rubble forms before a crew is dispatched

 -- render (render.lua)
 cong_show=2,        -- agents on a road before it reads as congested

 day_frames=1800,    -- full day/night cycle (60s @ 30fps)
}

-- build costs in DOLLARS (charged via econ.try_spend, which scales to $k)
cost={road=10,power=5,plant=150,zone=50,park=20,dozer=2,fire=60,recycle=250,bigplant=500}
