-- params.lua : every tuning knob in one place. edit freely.
p={
 -- economy
 start_money=2000,
 debt_limit=1000,    -- how far below zero spending may go
 interest=0.02,      -- monthly rate charged on debt
 month_frames=300,   -- 10 seconds at 30fps
 tax_demand=0.15,    -- demand lost per tax point above 2
 debt_demand=0.2,    -- demand lost while in debt
 -- monthly upkeep per tile, keyed by class id:
 -- 6 road, 8 crossing, 9 bridge, 10 pylon, 11 line, 12 plant, 13 service
 upkeep={[6]=1,[8]=2,[9]=1,[10]=1,[11]=1,[12]=10,[13]=5},
 cost={road=10,zone=50,line=5,plant=300,park=10,bridge=50,svc=100,
  dozer=1,blast=25},

 -- terrain
 ocean_chance=0.4,   -- odds one map edge is open sea
 ranges=2,           -- mountain ranges (plus 0-1 random extra)

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
 car_cap=24,
 car_pop=8,          -- one extra car per this much population
 eng_radius=2,       -- tiles from road where fire engine can respond

 -- day/night
 day_frames=1800,    -- full day cycle length (60s at 30fps)
}
cost=p.cost -- modules address costs through this alias
