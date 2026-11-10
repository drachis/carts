function parse_table(text)
 local rows,fields={}
 for line in all(split(text,"\n")) do
  local values=split(line)
  if not fields then
   fields=values
  elseif line!="" then
   local row={}
   row.__index=row
   for i,field in ipairs(fields) do
    if values[i]!="" then row[field]=values[i] end
   end
   add(rows,row)
   rows[row.name]=row
  end
 end
 return rows
end

function parse_record(text,separator,into)
 local record=into or {}
 for line in all(split(text,separator or "\n")) do
  local pair=split(line,"=")
  if pair[2] then record[pair[1]]=pair[2] end
 end
 return record
end

parse_record([[
frames_per_beat=14.94
good_window=10
walk_beats=8
alien_hp=4
knock_per_damage=0.25
max_hp=4
crest_y=40
hill_span=60
max_sparks=200
fly_speed=0.024
start_gun=2
]],nil,_ENV)

stages=parse_table[[
name,chart,spot_hp,colour,fly,heal,title
hill,....1.2.3.2.1...3.1.2.3.1.2.3,,,,,they're over the hill!
climb,........,,,1,,up the hill!
titan,..q.w.e.a.w.q.s.e.w.d.,4,3,,,titan! shoot its hot spots
streets,..1.3.2.1.1.3.2.3.1.2.2.1.3.,,,,1,another swarm!
climb,........,,,1,,to the crest!
crest,..1.2.3.3.1.2.1.3.3.2.1.1.2.3.,,,,,they keep coming!
climb,........,,,1,,the hive queen awaits
queen,..q.w.1.e.a.3.w.q.s.2.e.d.w.1.,8,14,,1,the hive queen!
]]

guns=parse_table[[
name,colour,damage,every,pierce,splash,sound
minigun,10,1,0.5,,,1
shock rifle,13,2,1,1,,0
rockets,9,4,2,,2,12
]]

judgements=parse_table[[
name,colour,knock,points
perfect,7,1,10
late,10,0.5,5
]]
