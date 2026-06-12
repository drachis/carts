-- params.lua : every tuning knob in one place. edit freely.
p={
 -- economy
 start_money=2000,
 debt_limit=1000,    -- how far below zero spending may go
 interest=0.02,      -- monthly rate charged on debt
 month_frames=300,   -- 10 seconds at 30fps
 tax_demand=0.15,    -- demand lost per tax point above 2
 debt_demand=0.2,    -- demand lost while in debt
 upkeep={road=1,line=1,crossing=2,pylon=1,plant=10,svc=5},
 cost={road=10,zone=50,line=5,plant=300,park=10,bridge=50,svc=100,dozer=1},

 -- growth
 road_radius=1,      -- chebyshev distance a zone may sit from a road
 grow_rate=0.5,      -- demand -> growth chance multiplier
 decay_rate=0.08,
 growth_samples=24,  -- cells considered per growth tick
 r_per_density=8,    -- residents per residential density step
 c_per_density=6,    -- jobs per commercial density step
 i_per_density=8,    -- jobs per industrial density step
 ranks={{50,"town"},{150,"city"},{400,"metropolis"}},

 -- power
 plant_cap=40,       -- tiles powered per plant

 -- fire
 fire_frames=900,    -- frames between random ignition rolls
 fire_chance=0.2,
 burn_t=150,         -- frames a tile burns
 station_burn_t=60,  -- burn time near a fire station
 station_radius=4,   -- chebyshev coverage of a fire station

 -- traffic
 car_cap=12,
 car_pop=12,         -- one extra car per this much population

 -- day/night
 day_frames=1800,    -- full day cycle length (60s at 30fps)
}
cost=p.cost -- modules address costs through this alias
