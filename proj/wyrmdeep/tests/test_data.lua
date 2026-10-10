-- test_data.lua : every name and stat the data refers to exists.
-- included by test_data.p8 after the game's modules; nothing is run but this.

local stats=parse_record(dragon_stats)

local function check_stats(owner,text)
 for key,value in pairs(parse_record(text,"/")) do
  assert(type(stats[key])=="number",owner.." changes an unknown stat: "..key)
  assert(type(value)=="number",owner.." sets "..key.." to something that is not a number")
 end
end

local function check_pool(owner,pool)
 for name in all(split(pool,"/")) do
  assert(unit_specs[name],owner.." calls for an unknown unit: "..name)
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
 if unit.pool then check_pool(unit.name,unit.pool) end
end
assert(shot_specs.rebuke,"a guard throws back a shot named rebuke")

for i=2,#ages do
 assert(ages[i].tip,ages[i].name.." has no tip")
 check_stats(ages[i].name,ages[i].stats)
end
check_stats("growth",growth)
for relic in all(relic_specs) do
 check_stats(relic.name,relic.stats)
end
for key in pairs(parse_record(fury_stats)) do
 assert(stats[key],"fury changes an unknown stat: "..key)
end

-- a stamp is rows of one width, of characters that are a tile, something
-- placed, or a space
for stamp in all(stamps) do
 local rows=split(stamp.rows,":",false)
 assert(#rows<=13,stamp.name.." is taller than the sky")
 for row in all(rows) do
  assert(#row==#rows[1],stamp.name.." has rows of different widths")
  for c=1,#row do
   local char=row[c]
   local name=placed[char]
   assert(char==" " or tiles[char] or unit_specs[name] or relic_specs[name],
    stamp.name.." uses an unknown character: "..char)
  end
 end
end
for kind in all(blocks) do
 for name in all(split(kind.stamps,"+")) do
  assert(stamps[name],kind.name.." is built of an unknown stamp: "..name)
 end
end
assert(#hordes==#split(stage_names),"every stage needs a horde")
for horde in all(hordes) do
 check_pool(horde.name,horde.pool)
end
for name in all(split(legends)) do
 assert(unit_specs[name] and unit_specs[name].color,"unknown legend: "..name)
end
assert(#split(legends)==#split(stage_names),"every stage needs a legend")
printh(#stamps.." stamps, "..#blocks.." kinds of block, "..#hordes.." hordes")
printh("ok data")
extcmd("shutdown")
