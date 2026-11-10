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
frames_per_beat=29.88
perfect_window=4
good_window=8
walk_beats=8
alien_hp=2
max_hp=4
crest_y=40
hill_span=60
max_sparks=200
fly_speed=0.012
]],nil,_ENV)

stages=parse_table[[
name,chart,spot_hp,colour,fly,heal,title
hill,....1.2.3.2.1...3.1.5.3.1.2.3,,,,,they're over the hill!
climb,........,,,1,,up the hill!
titan,..q.w.e.a.w.q.s.e.w.d.,2,3,,,titan! shoot its hot spots
streets,..1.3.2.1.1.3.4.3.1.2.2.1.3.,,,,1,another swarm!
climb,........,,,1,,to the crest!
crest,..1.2.3.3.1.2.6.3.3.2.1.1.2.3.,,,,,they keep coming!
climb,........,,,1,,the hive queen awaits
queen,..q.w.1.e.a.3.w.q.s.5.e.d.w.1.,4,14,,1,the hive queen!
]]

guns=parse_table[[
name,colour,damage,pierce,splash,ammo,label
pulse,12,1,,,,pulse
flak,9,2,,,12,flak cannon
shock,13,1,1,,16,shock rifle
rocket,8,2,,1,10,rocket launcher
]]

judgements=parse_table[[
name,colour,knock,points,sound
perfect,7,1,10,0
good,10,0.5,5,1
miss,8,0,0,2
]]
