-- test_data.lua : every name and stat the data refers to exists.
-- included by test_data.p8 after the game's modules; nothing is run but this.

local stats=parse_record(dragon_stats)

local function check_stats(owner,text)
 for key,value in pairs(parse_record(text,"/")) do
  assert(type(stats[key])=="number",owner.." changes an unknown stat: "..key)
  assert(type(value)=="number",owner.." sets "..key.." to something that is not a number")
 end
end

for unit in all(unit_specs) do
 assert(unit_ai[unit.ai],unit.name.." has an unknown ai: "..tostr(unit.ai))
 if unit.shot then
  assert(shot_specs[unit.shot],unit.name.." fires an unknown shot: "..unit.shot)
 end
 if unit.ai=="ranged" then
  assert(unit.shot and unit.range and unit.keep_away,unit.name.." is ranged but lacks shot, range or keep_away")
 end
 if unit.ai=="legend" or unit.ai=="melee" then
  assert(unit.knock,unit.name.." strikes but has no knock")
 end
end
assert(shot_specs.rebuke,"a guard throws back a shot named rebuke")

for i=2,#ages do
 assert(ages[i].tip,ages[i].name.." has no tip")
 check_stats(ages[i].name,ages[i].stats)
end
for relic in all(relic_specs) do
 check_stats(relic.name,relic.stats)
end
for key in pairs(parse_record(fury_stats)) do
 assert(stats[key],"fury changes an unknown stat: "..key)
end

local placed,grants,crowns=0,0,0
for row in all(split(spawn_text,"\n")) do
 local name=split(row)[1]
 if name!="" then
  placed+=1
  local unit=unit_specs[name]
  assert(unit or relic_specs[name],"the level places something unknown: "..name)
  if unit and unit.grants then grants+=1 end
  if unit and unit.crown then crowns+=1 end
 end
end
printh(placed.." placed, "..grants.." legends that grant an age, "..crowns.." crowned")
printh("ok data")
extcmd("shutdown")
