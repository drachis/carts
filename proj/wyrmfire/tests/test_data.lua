-- test_data.lua : checks the data tables against the code, and whatever
-- else can be tested without a world. included by test_data.p8 after every
-- module but world.lua, which leaves room for the checks themselves.

function sfx() end

-- the globals main.lua would have set up
units,particles={},{}
shake,freeze,flash,frame,fury_time,belly=0,0,0,0,0,0

-- every name the data refers to must exist
for spec in all(unit_specs) do
 assert(unit_ai[spec.ai],"no ai for "..spec.name)
 assert(not spec.shot or shot_specs[spec.shot],"no shot for "..spec.name)
end
for spec in all(building_specs) do
 for kind in all(list(spec.spawns)) do
  assert(unit_specs[kind],spec.name.." spawns unknown "..kind)
 end
 assert(not spec.guardian or unit_specs[spec.guardian],"unknown guardian")
 assert(not spec.survivor or unit_specs[spec.survivor],"unknown survivor")
end
for level in all(wrath_levels) do
 for kind in all(list(level.pool)) do
  assert(unit_specs[kind],level.name.." sends unknown "..kind)
 end
 assert(not level.legend or unit_specs[level.legend],"unknown legend")
end
for spec in all(settlement_specs) do
 for kind in all(list(spec.muster)) do
  assert(unit_specs[kind],spec.name.." musters unknown "..kind)
 end
 for kind in all(list(spec.buildings)) do
  assert(building_specs[kind],spec.name.." builds unknown "..kind)
 end
end
for entry in all(realm) do
 local kind,name,hero=unpack(split(entry,":"))
 assert(settlement_specs[kind],"unknown settlement "..entry)
 assert(not hero or unit_specs[hero],"unknown hero in "..entry)
end
-- how many blows of its lunge each legend needs at each age
for spec in all(unit_specs) do
 if spec.ai=="legend" and spec.color then
  local lunge=spec.damage*3
  printh(spec.name.." lunge "..lunge)
 end
end

-- boons and ages may only change stats the dragon has
new_dragon()
for boon in all(boons) do
 for key in pairs(parse_record(boon.stats,"/")) do
  assert(dragon[key],boon.name.." boosts unknown stat "..key)
 end
end
for key in pairs(parse_record(fury_stats)) do
 assert(dragon[key],"fury sets unknown stat "..key)
end

-- grow through every age, reporting what the dragon becomes
local function report()
 printh(ages[age].name..": size "..dragon.size.." hp "..dragon.max_hp
  .." top speed "..dragon.accel/(1-dragon.friction)
  .." turn "..dragon.turn_rate.." breath "..dragon.breath_range
  .." x"..dragon.breath_damage.." charge "..dragon.charge_damage)
end
report()
for step=2,#ages do
 for key in pairs(parse_record(ages[step].stats,"/")) do
  assert(dragon[key],ages[step].name.." grows unknown stat "..key)
 end
 grow()
 report()
end
assert(dragon.accel>0 and dragon.turn_rate>0 and dragon.friction<1,
 "the last age cannot fly")

-- spin the boon reel until every boon has landed at least once
local landed={}
for spin=1,80 do
 reel_time=config.reel_frames
 while reel_time>0 do update_reel() end
 landed[reel.name]=true
end
for boon in all(boons) do
 assert(landed[boon.name],boon.name.." never came up on the reel")
end

printh("ok data")
extcmd("shutdown")
