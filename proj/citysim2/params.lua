-- params.lua : every tuning knob lives in the global p. never shadow it.
-- keep this lean; modules add their own keys as they land.
p={
 grid=32,            -- city is grid x grid tiles (<=32 rows frees the sprite bank)

 -- event loop (sim, see DESIGN s3)
 evt_h=256,          -- timewheel horizon in ticks
 evt_cap=96,         -- events processed per tick (storm guard)
 eval_iv=90,         -- ticks between a tile re-evaluating its needs
 decay_miss=4,       -- consecutive unmet evals before a tile downgrades

 -- agents / visibility (the lively-city knob, DESIGN s10)
 agent_cap=80,       -- max live visible agents
 show=1,             -- visible cars per filled capacity unit (1=all; lower=sample)
 trip_life=600,      -- ticks before a stuck agent gives up

 -- congestion (router cost feedback, DESIGN s10)
 cong_k=3,           -- router cost added per agent sharing a road tile

 -- economy (money in THOUSANDS of dollars, see LEARNINGS)
 start_money=2,      -- $2k
 tax_rate=2,
 day_frames=1800,    -- full day/night cycle (60s @ 30fps)
}
